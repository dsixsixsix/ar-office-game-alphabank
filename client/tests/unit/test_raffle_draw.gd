extends GdUnitTestSuite
## Commit-reveal parking draw.

const SEED: String = "00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff"


func test_commitment_is_sha256_of_the_seed() -> void:
	var hashing: HashingContext = HashingContext.new()
	hashing.start(HashingContext.HASH_SHA256)
	hashing.update(SEED.hex_decode())
	assert_str(RaffleDraw.commitment(SEED)).is_equal(hashing.finish().hex_encode())


func test_new_seeds_are_random() -> void:
	var first: String = RaffleDraw.new_seed()
	assert_int(first.length()).is_equal(RaffleDraw.SEED_BYTES * 2)
	assert_str(RaffleDraw.new_seed()).is_not_equal(first)


func test_winner_does_not_depend_on_ticket_order() -> void:
	var winner: String = RaffleDraw.winner(SEED, "parking-2026-09", ["c", "a", "b"])
	assert_str(RaffleDraw.winner(SEED, "parking-2026-09", ["b", "c", "a"])).is_equal(winner)
	assert_array(["a", "b", "c"]).contains([winner])


func test_no_tickets_no_winner() -> void:
	assert_int(RaffleDraw.winner_index(SEED, "parking-2026-09", [])).is_equal(-1)
	assert_str(RaffleDraw.winner(SEED, "parking-2026-09", [])).is_empty()


func test_every_entrant_can_win() -> void:
	var entries: Array = ["a", "b", "c", "d"]
	var wins: Dictionary = {}
	for i: int in 400:
		var winner: String = RaffleDraw.winner(RaffleDraw.new_seed(), "draw-%d" % i, entries)
		wins[winner] = int(wins.get(winner, 0)) + 1
	for entry: String in entries:
		# Expected 100 each; a fair draw stays well within these bounds.
		assert_int(int(wins.get(entry, 0))).is_between(50, 150)
