extends GdUnitTestSuite


func test_normalize() -> void:
	assert_str(PhraseMatcher.normalize("  Шла Саша, по шоссе!  ")).is_equal("шла саша по шоссе")
	assert_str(PhraseMatcher.normalize("Ёжик — ЁЛКА")).is_equal("ежик елка")


func test_distance() -> void:
	assert_int(PhraseMatcher.distance("кот", "кот")).is_equal(0)
	assert_int(PhraseMatcher.distance("кот", "код")).is_equal(1)
	assert_int(PhraseMatcher.distance("", "abc")).is_equal(3)
	assert_int(PhraseMatcher.distance("kitten", "sitting")).is_equal(3)


func test_matches_with_small_recognition_errors() -> void:
	var phrase: String = "Шла Саша по шоссе и сосала сушку"
	assert_bool(PhraseMatcher.matches(phrase, "шла саша по шоссе и сосала сушку")).is_true()
	assert_bool(PhraseMatcher.matches(phrase, "Шла Маша по шоссе и сосала сушку")).is_true()
	assert_bool(PhraseMatcher.matches(phrase, "шла саша")).is_false()
	assert_bool(PhraseMatcher.matches(phrase, "")).is_false()
