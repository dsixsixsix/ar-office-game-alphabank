package main

import (
	"fmt"
	"strconv"
	"strings"
	"time"
)

// Office days. A day number is a local calendar day counted from 1970-01-01 (a Thursday) in the
// office time zone. Monday to Friday are workdays; weekends never break a streak and are never fined.

const secondsPerDay = 86400

func floorDiv(a, b int64) int64 {
	q := a / b
	if (a%b != 0) && ((a < 0) != (b < 0)) {
		q--
	}
	return q
}

// weekday: 0 = Monday ... 6 = Sunday.
func weekday(day int) int {
	return ((day+3)%7 + 7) % 7
}

func isWorkday(day int) bool {
	return weekday(day) < 5
}

func dayOf(unix, utcOffset int64) int {
	return int(floorDiv(unix+utcOffset, secondsPerDay))
}

// unixAt: unix time of a local wall-clock time on `day`.
func unixAt(day, hour, minute int, utcOffset int64) int64 {
	return int64(day)*secondsPerDay - utcOffset + int64(hour)*3600 + int64(minute)*60
}

func dateOf(day int) time.Time {
	return time.Unix(int64(day)*secondsPerDay, 0).UTC()
}

func dayFromDate(year int, month time.Month, dayOfMonth int) int {
	return int(time.Date(year, month, dayOfMonth, 0, 0, 0, 0, time.UTC).Unix() / secondsPerDay)
}

// shortDate: "19.09".
func shortDate(day int) string {
	date := dateOf(day)
	return fmt.Sprintf("%02d.%02d", date.Day(), int(date.Month()))
}

func lastDayOfMonth(day int) int {
	date := dateOf(day)
	return dayFromDate(date.Year(), date.Month()+1, 1) - 1
}

func lastFridayOfMonth(day int) int {
	result := lastDayOfMonth(day)
	for weekday(result) != 4 {
		result--
	}
	return result
}

// parseClock: "09:30" -> 9, 30. Malformed text gives 0, 0.
func parseClock(text string) (int, int) {
	parts := strings.Split(text, ":")
	if len(parts) != 2 {
		return 0, 0
	}
	hour, _ := strconv.Atoi(parts[0])
	minute, _ := strconv.Atoi(parts[1])
	return min(max(hour, 0), 23), min(max(minute, 0), 59)
}

func dayKey(day int) string {
	return strconv.Itoa(day)
}
