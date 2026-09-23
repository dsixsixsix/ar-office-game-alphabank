package main

import (
	"strings"
	"testing"
)

func TestValidateUsername(t *testing.T) {
	valid := []string{"ivanov", "a.petrova", "user_01", "k-9", "abc"}
	for _, username := range valid {
		if err := validateUsername(username); err != nil {
			t.Errorf("validateUsername(%q) = %v, want nil", username, err)
		}
	}
	invalid := []string{"", "ab", "Ivanov", "иванов", "-start", ".dot", "with space", strings.Repeat("a", 33)}
	for _, username := range invalid {
		if err := validateUsername(username); err != errInvalidUsername {
			t.Errorf("validateUsername(%q) = %v, want errInvalidUsername", username, err)
		}
	}
}

func TestNormalizeUsername(t *testing.T) {
	if got := normalizeUsername("  Ivanov.A "); got != "ivanov.a" {
		t.Errorf("normalizeUsername = %q, want %q", got, "ivanov.a")
	}
}

func TestValidatePassword(t *testing.T) {
	cases := map[string]error{
		"1234567":               errInvalidPassword,
		"12345678":              nil,
		"пароль12":              nil,
		strings.Repeat("a", 72): nil,
		strings.Repeat("a", 73): errInvalidPassword,
		strings.Repeat("я", 37): errInvalidPassword, // 74 bytes
	}
	for password, want := range cases {
		if err := validatePassword(password); err != want {
			t.Errorf("validatePassword(%q) = %v, want %v", password, err, want)
		}
	}
}

func TestNormalizeName(t *testing.T) {
	got, err := normalizeName("  Анна   Петрова ")
	if err != nil || got != "Анна Петрова" {
		t.Errorf("normalizeName = %q, %v; want %q", got, err, "Анна Петрова")
	}
	for _, name := range []string{"", "   ", strings.Repeat("я", 61), "bad\u0007name"} {
		if _, err := normalizeName(name); err != errInvalidName {
			t.Errorf("normalizeName(%q) error = %v, want errInvalidName", name, err)
		}
	}
	if _, err := normalizeName(strings.Repeat("я", 60)); err != nil {
		t.Errorf("60-rune name rejected: %v", err)
	}
}

func TestSyntheticEmailsAreValidForNakama(t *testing.T) {
	// Nakama requires 10-255 bytes; the shortest username is 3 characters.
	for _, email := range []string{playerEmail("abc"), adminEmail("abc")} {
		if len(email) < 10 || len(email) > 255 || !strings.Contains(email, "@") {
			t.Errorf("email %q is not accepted by Nakama", email)
		}
	}
}

func TestDecodePayloadRejectsUnknownFields(t *testing.T) {
	var request struct {
		Name string `json:"name"`
	}
	if err := decodePayload(`{"name":"x"}`, &request); err != nil || request.Name != "x" {
		t.Errorf("decodePayload valid = %v, %q", err, request.Name)
	}
	if err := decodePayload(`{"name":"x","role":"admin"}`, &request); err != errInvalidPayload {
		t.Errorf("decodePayload unknown field = %v, want errInvalidPayload", err)
	}
	if err := decodePayload(``, &request); err != errInvalidPayload {
		t.Errorf("decodePayload empty = %v, want errInvalidPayload", err)
	}
}

func TestContentLoads(t *testing.T) {
	content, err := loadContent("../content")
	if err != nil {
		t.Fatalf("server/content does not load: %v", err)
	}
	if len(content.Tasks) == 0 || len(content.Catalog) == 0 || len(content.Wardrobe) == 0 || len(content.Cars) == 0 {
		t.Fatal("content is empty")
	}
	if content.Rules.Office.ID == "" || content.Rules.Economy.DailyCoinCap <= 0 || len(content.Rules.AvatarTemplates) < 2 {
		t.Errorf("game_rules.json is incomplete: %+v", content.Rules)
	}
	if content.task("check_in") == nil || content.task("check_in").Minigame != presenceMinigame {
		t.Error("the check-in task is missing")
	}
	if content.car(starterCar) == nil {
		t.Error("the starter car is missing")
	}
	for _, slot := range content.wardrobeSlots() {
		found := false
		for _, entry := range content.Wardrobe {
			found = found || (entry.Slot == slot && entry.Unlock == nil)
		}
		if !found {
			t.Errorf("slot %s has no free item", slot)
		}
	}
}
