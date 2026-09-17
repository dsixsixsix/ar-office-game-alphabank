class_name PhraseMatcher
extends RefCounted
## Compares a recognized phrase with the expected tongue twister. Case, punctuation and "ё" are
## ignored; the score is 1 - normalized Levenshtein distance.

const PASS_SCORE: float = 0.8


static func normalize(text: String) -> String:
	var lowered: String = text.to_lower().replace("ё", "е")
	var result: String = ""
	var previous_space: bool = true
	for character: String in lowered:
		if _is_letter_or_digit(character):
			result += character
			previous_space = false
		elif not previous_space:
			result += " "
			previous_space = true
	return result.strip_edges()


static func score(expected: String, heard: String) -> float:
	var a: String = normalize(expected)
	var b: String = normalize(heard)
	var longest: int = maxi(a.length(), b.length())
	if longest == 0:
		return 0.0
	return 1.0 - float(distance(a, b)) / longest


static func matches(expected: String, heard: String) -> bool:
	return score(expected, heard) >= PASS_SCORE


static func distance(a: String, b: String) -> int:
	var previous: PackedInt32Array = PackedInt32Array()
	previous.resize(b.length() + 1)
	for j: int in b.length() + 1:
		previous[j] = j
	var current: PackedInt32Array = PackedInt32Array()
	current.resize(b.length() + 1)
	for i: int in range(1, a.length() + 1):
		current[0] = i
		for j: int in range(1, b.length() + 1):
			var cost: int = 0 if a.unicode_at(i - 1) == b.unicode_at(j - 1) else 1
			current[j] = mini(mini(previous[j] + 1, current[j - 1] + 1), previous[j - 1] + cost)
		var swap: PackedInt32Array = previous
		previous = current
		current = swap
	return previous[b.length()]


static func _is_letter_or_digit(character: String) -> bool:
	var code: int = character.unicode_at(0)
	return (
		(code >= 0x30 and code <= 0x39) or (code >= 0x61 and code <= 0x7A)
		or (code >= 0x430 and code <= 0x44F)
	)
