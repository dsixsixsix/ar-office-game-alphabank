package main

import (
	"context"
	"database/sql"

	"github.com/heroiclabs/nakama-common/api"
	"github.com/heroiclabs/nakama-common/runtime"
	"google.golang.org/protobuf/types/known/wrapperspb"
)

// Players never register themselves: the admin creates every account (rpcAdminCreateUser).
// The only way in is username + password; every other auth method is off.
func registerAuthHooks(initializer runtime.Initializer) error {
	if err := initializer.RegisterBeforeAuthenticateEmail(beforeAuthenticateEmail); err != nil {
		return err
	}
	if err := initializer.RegisterBeforeUpdateAccount(beforeUpdateAccount); err != nil {
		return err
	}
	if err := initializer.RegisterBeforeUnlinkEmail(func(context.Context, runtime.Logger, *sql.DB, runtime.NakamaModule, *api.AccountEmail) (*api.AccountEmail, error) {
		return nil, errAuthMethodDisabled
	}); err != nil {
		return err
	}
	return disableOtherAuthMethods(initializer)
}

// beforeAuthenticateEmail turns every email request into a username login without account
// creation. Nakama logs in by username when the email is empty; unknown usernames get "not found".
func beforeAuthenticateEmail(_ context.Context, _ runtime.Logger, _ *sql.DB, _ runtime.NakamaModule, in *api.AuthenticateEmailRequest) (*api.AuthenticateEmailRequest, error) {
	if in.GetAccount() == nil {
		return nil, errInvalidPayload
	}
	in.Account.Email = ""
	in.Username = normalizeUsername(in.GetUsername())
	in.Create = wrapperspb.Bool(false)
	return in, nil
}

// beforeUpdateAccount keeps the username and the display name under the admin's control.
func beforeUpdateAccount(_ context.Context, _ runtime.Logger, _ *sql.DB, _ runtime.NakamaModule, in *api.UpdateAccountRequest) (*api.UpdateAccountRequest, error) {
	in.Username = nil
	in.DisplayName = nil
	return in, nil
}

func disableOtherAuthMethods(initializer runtime.Initializer) error {
	registrations := []error{
		initializer.RegisterBeforeAuthenticateDevice(func(context.Context, runtime.Logger, *sql.DB, runtime.NakamaModule, *api.AuthenticateDeviceRequest) (*api.AuthenticateDeviceRequest, error) {
			return nil, errAuthMethodDisabled
		}),
		initializer.RegisterBeforeAuthenticateCustom(func(context.Context, runtime.Logger, *sql.DB, runtime.NakamaModule, *api.AuthenticateCustomRequest) (*api.AuthenticateCustomRequest, error) {
			return nil, errAuthMethodDisabled
		}),
		initializer.RegisterBeforeAuthenticateApple(func(context.Context, runtime.Logger, *sql.DB, runtime.NakamaModule, *api.AuthenticateAppleRequest) (*api.AuthenticateAppleRequest, error) {
			return nil, errAuthMethodDisabled
		}),
		initializer.RegisterBeforeAuthenticateFacebook(func(context.Context, runtime.Logger, *sql.DB, runtime.NakamaModule, *api.AuthenticateFacebookRequest) (*api.AuthenticateFacebookRequest, error) {
			return nil, errAuthMethodDisabled
		}),
		initializer.RegisterBeforeAuthenticateFacebookInstantGame(func(context.Context, runtime.Logger, *sql.DB, runtime.NakamaModule, *api.AuthenticateFacebookInstantGameRequest) (*api.AuthenticateFacebookInstantGameRequest, error) {
			return nil, errAuthMethodDisabled
		}),
		initializer.RegisterBeforeAuthenticateGameCenter(func(context.Context, runtime.Logger, *sql.DB, runtime.NakamaModule, *api.AuthenticateGameCenterRequest) (*api.AuthenticateGameCenterRequest, error) {
			return nil, errAuthMethodDisabled
		}),
		initializer.RegisterBeforeAuthenticateGoogle(func(context.Context, runtime.Logger, *sql.DB, runtime.NakamaModule, *api.AuthenticateGoogleRequest) (*api.AuthenticateGoogleRequest, error) {
			return nil, errAuthMethodDisabled
		}),
		initializer.RegisterBeforeAuthenticateSteam(func(context.Context, runtime.Logger, *sql.DB, runtime.NakamaModule, *api.AuthenticateSteamRequest) (*api.AuthenticateSteamRequest, error) {
			return nil, errAuthMethodDisabled
		}),
	}
	for _, err := range registrations {
		if err != nil {
			return err
		}
	}
	return nil
}
