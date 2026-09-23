class_name RaffleDraw
extends RefCounted
## Verifiable prize draw (commit-reveal).
## 1. When ticket sales open, the server takes a secret seed from a CSPRNG and publishes only its
##    SHA-256 commitment, so the seed cannot be changed once tickets are sold.
## 2. At draw time the winner is HMAC-SHA256(seed, "<draw id>|<sorted ticket holders>") taken
##    modulo the number of tickets. Nobody, the server included, can predict or steer it before
##    the seed is revealed, and anyone can recheck the result after the reveal.

const SEED_BYTES: int = 32
## 48 bits of the digest keep the value a positive int; the modulo bias is below 2^-30 for any
## realistic number of tickets.
const DIGEST_BYTES: int = 6


static func new_seed() -> String:
	return Crypto.new().generate_random_bytes(SEED_BYTES).hex_encode()


static func commitment(seed_hex: String) -> String:
	var hashing: HashingContext = HashingContext.new()
	hashing.start(HashingContext.HASH_SHA256)
	hashing.update(seed_hex.hex_decode())
	return hashing.finish().hex_encode()


## Tickets sorted, so the result does not depend on the order in which they were bought.
static func canonical_entries(entries: Array) -> PackedStringArray:
	var sorted: PackedStringArray = PackedStringArray()
	for entry: Variant in entries:
		sorted.append(str(entry))
	sorted.sort()
	return sorted


## Index into canonical_entries(entries), or -1 when there are no tickets.
static func winner_index(seed_hex: String, draw_id: String, entries: Array) -> int:
	var sorted: PackedStringArray = canonical_entries(entries)
	if sorted.is_empty():
		return -1
	var hmac: HMACContext = HMACContext.new()
	hmac.start(HashingContext.HASH_SHA256, seed_hex.hex_decode())
	hmac.update(("%s|%s" % [draw_id, ",".join(sorted)]).to_utf8_buffer())
	var digest: PackedByteArray = hmac.finish()
	var value: int = 0
	for i: int in DIGEST_BYTES:
		value = (value << 8) | digest[i]
	return value % sorted.size()


static func winner(seed_hex: String, draw_id: String, entries: Array) -> String:
	var index: int = winner_index(seed_hex, draw_id, entries)
	return canonical_entries(entries)[index] if index >= 0 else ""
