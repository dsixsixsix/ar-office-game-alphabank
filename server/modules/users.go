package main

import (
	"context"
	"database/sql"
	"strings"
	"time"

	"github.com/heroiclabs/nakama-common/runtime"
	"golang.org/x/crypto/bcrypt"
)

// Admin RPCs for player accounts. An account exists only after the admin creates it; creating it
// is the activation. A banned account cannot sign in until it is unbanned.

type userView struct {
	ID           string `json:"id"`
	Username     string `json:"username"`
	DisplayName  string `json:"display_name"`
	Role         string `json:"role"`
	DepartmentID string `json:"department_id"`
	Banned       bool   `json:"banned"`
	CreatedAt    int64  `json:"created_at"`
}

// rpcAdminListUsers: -> {"users": [userView]}, newest first.
func rpcAdminListUsers(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, _ string) (string, error) {
	if err := requireAdmin(ctx, nk); err != nil {
		return "", err
	}
	rows, err := db.QueryContext(ctx, `
		SELECT id, username, display_name, metadata, disable_time, create_time
		FROM users WHERE id <> $1 ORDER BY create_time DESC`, systemUserID)
	if err != nil {
		logger.Error("list users: %v", err)
		return "", errInternal
	}
	defer rows.Close()
	users := []userView{}
	for rows.Next() {
		var (
			user        userView
			displayName sql.NullString
			metadata    string
			disabled    time.Time
			created     time.Time
		)
		if err := rows.Scan(&user.ID, &user.Username, &displayName, &metadata, &disabled, &created); err != nil {
			logger.Error("scan user: %v", err)
			return "", errInternal
		}
		parsed := parseMetadata(metadata)
		user.DisplayName = displayName.String
		user.Role = parsed.Role
		user.DepartmentID = parsed.DepartmentID
		user.Banned = disabled.Unix() > 0
		user.CreatedAt = created.Unix()
		users = append(users, user)
	}
	if err := rows.Err(); err != nil {
		logger.Error("list users: %v", err)
		return "", errInternal
	}
	return encodeResponse(map[string]any{"users": users})
}

// rpcAdminCreateUser: {"username", "password", "display_name", "department_id"} -> userView.
func rpcAdminCreateUser(ctx context.Context, logger runtime.Logger, _ *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
	if err := requireAdmin(ctx, nk); err != nil {
		return "", err
	}
	var request struct {
		Username     string `json:"username"`
		Password     string `json:"password"`
		DisplayName  string `json:"display_name"`
		DepartmentID string `json:"department_id"`
	}
	if err := decodePayload(payload, &request); err != nil {
		return "", err
	}
	username := normalizeUsername(request.Username)
	if err := validateUsername(username); err != nil {
		return "", err
	}
	if err := validatePassword(request.Password); err != nil {
		return "", err
	}
	displayName, err := normalizeName(request.DisplayName)
	if err != nil {
		return "", err
	}
	department, err := findDepartment(ctx, nk, request.DepartmentID)
	if err != nil {
		return "", err
	}
	if existing, err := nk.UsersGetUsername(ctx, []string{username}); err != nil {
		return "", errInternal
	} else if len(existing) > 0 {
		return "", errUsernameTaken
	}
	userID, _, created, err := nk.AuthenticateEmail(ctx, playerEmail(username), request.Password, username, true)
	if err != nil {
		if strings.Contains(strings.ToLower(err.Error()), "username") {
			return "", errUsernameTaken
		}
		logger.Error("create user %q: %v", username, err)
		return "", errInternal
	}
	if !created {
		return "", errUsernameTaken
	}
	metadata := accountMetadata{Role: rolePlayer, DepartmentID: department.ID}
	if err := nk.AccountUpdateId(ctx, userID, "", metadata.toMap(), displayName, "", "", "", ""); err != nil {
		logger.Error("set up user %s: %v", userID, err)
		// A half-made account without a department must not stay.
		if deleteErr := nk.AccountDeleteId(ctx, userID, false); deleteErr != nil {
			logger.Error("delete half-made user %s: %v", userID, deleteErr)
		}
		return "", errInternal
	}
	logger.Info("user %s (%s) created in department %s", userID, username, department.ID)
	return encodeResponse(userView{
		ID: userID, Username: username, DisplayName: displayName, Role: rolePlayer,
		DepartmentID: department.ID, CreatedAt: time.Now().Unix(),
	})
}

// rpcAdminUpdateUser: {"user_id", "display_name"?, "department_id"?} -> {}.
func rpcAdminUpdateUser(ctx context.Context, logger runtime.Logger, _ *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
	if err := requireAdmin(ctx, nk); err != nil {
		return "", err
	}
	var request struct {
		UserID       string `json:"user_id"`
		DisplayName  string `json:"display_name"`
		DepartmentID string `json:"department_id"`
	}
	if err := decodePayload(payload, &request); err != nil {
		return "", err
	}
	metadata, err := playerMetadata(ctx, nk, request.UserID)
	if err != nil {
		return "", err
	}
	displayName := ""
	if request.DisplayName != "" {
		if displayName, err = normalizeName(request.DisplayName); err != nil {
			return "", err
		}
	}
	if request.DepartmentID != "" {
		department, err := findDepartment(ctx, nk, request.DepartmentID)
		if err != nil {
			return "", err
		}
		metadata.DepartmentID = department.ID
	}
	if err := nk.AccountUpdateId(ctx, request.UserID, "", metadata.toMap(), displayName, "", "", "", ""); err != nil {
		logger.Error("update user %s: %v", request.UserID, err)
		return "", errInternal
	}
	return "{}", nil
}

// rpcAdminSetPassword: {"user_id", "password"} -> {}. Signs the user out everywhere.
func rpcAdminSetPassword(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
	if err := requireAdmin(ctx, nk); err != nil {
		return "", err
	}
	var request struct {
		UserID   string `json:"user_id"`
		Password string `json:"password"`
	}
	if err := decodePayload(payload, &request); err != nil {
		return "", err
	}
	if _, err := playerMetadata(ctx, nk, request.UserID); err != nil {
		return "", err
	}
	if err := validatePassword(request.Password); err != nil {
		return "", err
	}
	if err := setPassword(ctx, db, request.UserID, request.Password); err != nil {
		logger.Error("set password of %s: %v", request.UserID, err)
		return "", errInternal
	}
	if err := nk.SessionLogout(request.UserID, "", ""); err != nil {
		logger.Warn("sign out %s after password change: %v", request.UserID, err)
	}
	return "{}", nil
}

// rpcAdminSetBanned: {"user_id", "banned"} -> {}. A ban also ends the user's sessions.
// The ban is first written to the game state, so a game RPC already running for the player fails
// its version check and is refused on retry. An unban keeps all progress and excuses the workdays
// of the ban, so the player is not fined and keeps the streak; the player signs in again.
func rpcAdminSetBanned(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
	if err := requireAdmin(ctx, nk); err != nil {
		return "", err
	}
	var request struct {
		UserID string `json:"user_id"`
		Banned bool   `json:"banned"`
	}
	if err := decodePayload(payload, &request); err != nil {
		return "", err
	}
	if _, err := playerMetadata(ctx, nk, request.UserID); err != nil {
		return "", err
	}
	if request.Banned {
		return banPlayer(ctx, logger, db, nk, request.UserID)
	}
	return unbanPlayer(ctx, logger, db, nk, request.UserID)
}

func banPlayer(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, userID string) (string, error) {
	if _, err := setBannedAt(ctx, logger, db, nk, userID, true); err != nil {
		return "", err
	}
	if err := nk.UsersBanId(ctx, []string{userID}); err != nil {
		logger.Error("ban %s: %v", userID, err)
		// The game must not stay blocked while the account looks active in the panel.
		if _, undoErr := setBannedAt(ctx, logger, db, nk, userID, false); undoErr != nil {
			logger.Error("undo game ban of %s: %v", userID, undoErr)
		}
		return "", errInternal
	}
	return "{}", nil
}

// unbanPlayer clears the game ban before the account ban: until the account is unbanned the player
// cannot sign in, and the account's disable_time still gives the ban start if this call is retried.
func unbanPlayer(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, userID string) (string, error) {
	if _, err := setBannedAt(ctx, logger, db, nk, userID, false); err != nil {
		return "", err
	}
	if err := nk.UsersUnbanId(ctx, []string{userID}); err != nil {
		logger.Error("unban %s: %v", userID, err)
		return "", errInternal
	}
	return "{}", nil
}

// setBannedAt records the ban in the player's game state or, on unban, clears it and excuses the
// workdays from the ban day up to yesterday.
func setBannedAt(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, userID string, banned bool) (string, error) {
	return runUserTx(ctx, logger, db, nk, userID, func(tx *gameTx) (any, error) {
		state := tx.me.state
		if banned {
			if state.BannedAt == 0 {
				state.BannedAt = tx.now
			}
			return nil, nil
		}
		if start := tx.me.banStart(); start > 0 {
			excuseDays(state, dayOf(start, tx.offset), tx.today)
		}
		state.BannedAt = 0
		return nil, nil
	})
}

// playerMetadata loads a player account for an admin action. Admin accounts are managed only
// through the server environment.
func playerMetadata(ctx context.Context, nk runtime.NakamaModule, userID string) (accountMetadata, error) {
	if userID == "" || userID == systemUserID {
		return accountMetadata{}, errUserNotFound
	}
	account, err := nk.AccountGetId(ctx, userID)
	if err != nil {
		return accountMetadata{}, errUserNotFound
	}
	metadata := parseMetadata(account.GetUser().GetMetadata())
	if metadata.Role == roleAdmin {
		return accountMetadata{}, errAdminProtected
	}
	metadata.Role = rolePlayer
	return metadata, nil
}

// setPassword replaces the password hash. Nakama has no runtime call for it; it stores bcrypt
// hashes in users.password.
func setPassword(ctx context.Context, db *sql.DB, userID, password string) error {
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return err
	}
	_, err = db.ExecContext(ctx, `UPDATE users SET password = $1, update_time = now() WHERE id = $2`, hash, userID)
	return err
}
