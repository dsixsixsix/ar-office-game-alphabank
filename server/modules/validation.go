package main

import (
	"regexp"
	"strings"
	"unicode"
	"unicode/utf8"
)

const (
	minPasswordLength = 8
	// bcrypt ignores everything after 72 bytes.
	maxPasswordBytes = 72
	maxNameLength    = 60
	// Accounts are created with a synthetic email because Nakama requires one; players sign in
	// with the username only.
	playerEmailDomain = "players.office.local"
	adminEmailDomain  = "admins.office.local"
)

var (
	usernamePattern = regexp.MustCompile(`^[a-z0-9][a-z0-9._-]{2,31}$`)
	uuidPattern     = regexp.MustCompile(`^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$`)
)

func isUUID(text string) bool {
	return uuidPattern.MatchString(text)
}

func normalizeUsername(username string) string {
	return strings.ToLower(strings.TrimSpace(username))
}

func validateUsername(username string) error {
	if !usernamePattern.MatchString(username) {
		return errInvalidUsername
	}
	return nil
}

func validatePassword(password string) error {
	if utf8.RuneCountInString(password) < minPasswordLength || len(password) > maxPasswordBytes {
		return errInvalidPassword
	}
	return nil
}

// normalizeName trims a person or department name and collapses inner whitespace.
func normalizeName(name string) (string, error) {
	cleaned := strings.Join(strings.Fields(name), " ")
	length := utf8.RuneCountInString(cleaned)
	if length == 0 || length > maxNameLength {
		return "", errInvalidName
	}
	for _, r := range cleaned {
		if unicode.IsControl(r) {
			return "", errInvalidName
		}
	}
	return cleaned, nil
}

func playerEmail(username string) string {
	return username + "@" + playerEmailDomain
}

func adminEmail(username string) string {
	return username + "@" + adminEmailDomain
}
