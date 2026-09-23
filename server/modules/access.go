package main

import (
	"context"
	"encoding/json"

	"github.com/heroiclabs/nakama-common/api"
	"github.com/heroiclabs/nakama-common/runtime"
)

// Roles live in the account metadata, which only the server can write.
const (
	roleAdmin  = "admin"
	rolePlayer = "player"
)

type accountMetadata struct {
	Role         string `json:"role,omitempty"`
	DepartmentID string `json:"department,omitempty"`
}

func (m accountMetadata) toMap() map[string]any {
	result := map[string]any{"role": m.Role}
	if m.DepartmentID != "" {
		result["department"] = m.DepartmentID
	}
	return result
}

func parseMetadata(raw string) accountMetadata {
	var metadata accountMetadata
	if raw != "" {
		// Malformed metadata means no role, which denies access.
		_ = json.Unmarshal([]byte(raw), &metadata)
	}
	return metadata
}

func callerID(ctx context.Context) (string, error) {
	userID, _ := ctx.Value(runtime.RUNTIME_CTX_USER_ID).(string)
	if userID == "" {
		return "", errUnauthenticated
	}
	return userID, nil
}

func callerAccount(ctx context.Context, nk runtime.NakamaModule) (*api.Account, accountMetadata, error) {
	userID, err := callerID(ctx)
	if err != nil {
		return nil, accountMetadata{}, err
	}
	account, err := nk.AccountGetId(ctx, userID)
	if err != nil {
		return nil, accountMetadata{}, errUnauthenticated
	}
	return account, parseMetadata(account.GetUser().GetMetadata()), nil
}

func requireAdmin(ctx context.Context, nk runtime.NakamaModule) error {
	_, metadata, err := callerAccount(ctx, nk)
	if err != nil {
		return err
	}
	if metadata.Role != roleAdmin {
		return errNotAdmin
	}
	return nil
}
