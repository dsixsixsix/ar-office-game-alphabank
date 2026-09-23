package main

import (
	"context"
	"database/sql"

	"github.com/heroiclabs/nakama-common/runtime"
)

type profileView struct {
	UserID      string     `json:"user_id"`
	Username    string     `json:"username"`
	DisplayName string     `json:"display_name"`
	Department  Department `json:"department"`
}

// rpcGetProfile: the signed-in player's identity. Admin accounts get "not_player".
func rpcGetProfile(ctx context.Context, logger runtime.Logger, _ *sql.DB, nk runtime.NakamaModule, _ string) (string, error) {
	account, metadata, err := callerAccount(ctx, nk)
	if err != nil {
		return "", err
	}
	if metadata.Role != rolePlayer {
		return "", errNotPlayer
	}
	user := account.GetUser()
	department, err := findDepartment(ctx, nk, metadata.DepartmentID)
	if err != nil {
		// The account stays usable; the admin can fix the department later.
		logger.Warn("user %s has unknown department %q", user.GetId(), metadata.DepartmentID)
		department = Department{ID: metadata.DepartmentID}
	}
	return encodeResponse(profileView{
		UserID:      user.GetId(),
		Username:    user.GetUsername(),
		DisplayName: user.GetDisplayName(),
		Department:  department,
	})
}
