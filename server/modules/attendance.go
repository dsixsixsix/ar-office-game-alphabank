package main

// Office attendance: the streak of office days and the progressive fine for workdays missed in a
// row. `presence` and `excused` are sets of day keys. Excused days (vacation, sick leave, business
// trip) are set by an admin and count as neither present nor missed.

// streak: consecutive office workdays ending today or, when today is not counted yet, on the
// previous workday. Today without a check-in does not break the streak: the player still has time.
func streak(presence, excused map[string]bool, today, firstDay int) int {
	day := today
	if !presence[dayKey(today)] {
		day = today - 1
	}
	count := 0
	for ; day >= firstDay; day-- {
		key := dayKey(day)
		if presence[key] {
			count++
		} else if isWorkday(day) && !excused[key] {
			break
		}
	}
	return count
}

// missedInRow: workdays missed in a row ending with `day` inclusive. Days before `firstDay` never count.
func missedInRow(presence, excused map[string]bool, day, firstDay int) int {
	count := 0
	for current := day; current >= firstDay; current-- {
		key := dayKey(current)
		if presence[key] {
			break
		}
		if isWorkday(current) && !excused[key] {
			count++
		}
	}
	return count
}

// excuseDays marks workdays in [from, to) as excused, skipping office days and days before the
// player's first day. An unban uses it so the ban costs neither coins nor the streak.
func excuseDays(state *PlayerState, from, to int) {
	if state.FirstDay == 0 {
		return
	}
	for day := max(from, state.FirstDay); day < to; day++ {
		key := dayKey(day)
		if isWorkday(day) && !state.PresenceDays[key] {
			state.ExcusedDays[key] = true
		}
	}
}

// finePercent: rate for the n-th workday missed in a row; the last matching tier wins.
func finePercent(missed int, tiers []FineTier) int {
	percent, bestDays := 0, 0
	for _, tier := range tiers {
		if missed >= tier.Days && tier.Days >= bestDays {
			bestDays = tier.Days
			percent = tier.Percent
		}
	}
	return min(max(percent, 0), 100)
}

// fineAmount: `percent` of the balance rounded up, never more than the balance.
func fineAmount(balance int64, percent int) int64 {
	if balance <= 0 || percent <= 0 {
		return 0
	}
	amount := (balance*int64(percent) + 99) / 100
	return min(amount, balance)
}

// streakMultiplier: reward multiplier of the streak as it will be once the player is in the office today.
func streakMultiplier(currentStreak int, presentToday bool, rules *Rules) float64 {
	projected := currentStreak
	if !presentToday {
		projected++
	}
	multiplier := 1.0 + rules.Economy.StreakMultiplierStep*float64(projected-1)
	return min(max(multiplier, 1.0), rules.Economy.MaxStreakMultiplier)
}
