class_name QrEncoder
extends RefCounted
## Minimal QR Code generator (ISO/IEC 18004): byte mode, error correction level M, versions 1-10.
## Enough for the game's short payloads (room links, profile codes, presence tokens up to 213 bytes).
## Used by the office screen and the profile card; scanning is done by the platform layer.
@warning_ignore_start("integer_division")

const MAX_VERSION: int = 10
## Error correction codewords per block, level M, index = version.
const EC_PER_BLOCK: Array[int] = [0, 10, 16, 26, 18, 24, 16, 18, 22, 22, 26]
## Data codewords per block, level M. Each entry lists [block count, data codewords] groups.
const BLOCKS: Array = [
	[],
	[[1, 16]],
	[[1, 28]],
	[[1, 44]],
	[[2, 32]],
	[[2, 43]],
	[[4, 27]],
	[[4, 31]],
	[[2, 38], [2, 39]],
	[[3, 36], [2, 37]],
	[[4, 43], [1, 44]],
]
const ALIGNMENT: Array = [
	[], [], [6, 18], [6, 22], [6, 26], [6, 30], [6, 34], [6, 22, 38], [6, 24, 42], [6, 26, 46], [6, 28, 50],
]
## Format bits for level M.
const LEVEL_M_BITS: int = 0
const PAD_BYTES: Array[int] = [0xEC, 0x11]
const MASK_COUNT: int = 8


## Square matrix of modules: true = dark. Empty when the text does not fit version 10.
class QrMatrix:
	extends RefCounted

	var size: int = 0
	var version: int = 0
	var mask: int = 0
	var modules: PackedByteArray = PackedByteArray()

	func is_dark(x: int, y: int) -> bool:
		return modules[y * size + x] != 0

	func is_empty() -> bool:
		return size == 0

	## Black-on-white image with a quiet zone, one pixel per module scaled by `scale`.
	func to_image(scale: int = 4, quiet_zone: int = 4, dark: Color = Color.BLACK, light: Color = Color.WHITE) -> Image:
		var side: int = (size + quiet_zone * 2) * scale
		var image: Image = Image.create_empty(side, side, false, Image.FORMAT_RGBA8)
		image.fill(light)
		for y: int in size:
			for x: int in size:
				if is_dark(x, y):
					image.fill_rect(Rect2i((x + quiet_zone) * scale, (y + quiet_zone) * scale, scale, scale), dark)
		return image


static func encode(text: String) -> QrMatrix:
	var data: PackedByteArray = text.to_utf8_buffer()
	var version: int = _pick_version(data.size())
	var result: QrMatrix = QrMatrix.new()
	if version == 0:
		push_error("QR payload of %d bytes is too long" % data.size())
		return result
	var codewords: PackedByteArray = _add_error_correction(_data_codewords(data, version), version)
	var size: int = 17 + version * 4
	var modules: PackedByteArray = PackedByteArray()
	modules.resize(size * size)
	var reserved: PackedByteArray = PackedByteArray()
	reserved.resize(size * size)
	_draw_function_patterns(modules, reserved, size, version)
	_draw_codewords(modules, reserved, size, codewords)
	var best_mask: int = 0
	var best_penalty: int = 1 << 30
	for mask: int in MASK_COUNT:
		var candidate: PackedByteArray = modules.duplicate()
		_apply_mask(candidate, reserved, size, mask)
		_draw_format_bits(candidate, size, mask)
		var penalty: int = _penalty(candidate, size)
		if penalty < best_penalty:
			best_penalty = penalty
			best_mask = mask
	_apply_mask(modules, reserved, size, best_mask)
	_draw_format_bits(modules, size, best_mask)
	result.size = size
	result.version = version
	result.mask = best_mask
	result.modules = modules
	return result


static func capacity(version: int) -> int:
	var total: int = 0
	for group: Array in BLOCKS[version]:
		total += int(group[0]) * int(group[1])
	return total


static func _pick_version(byte_count: int) -> int:
	for version: int in range(1, MAX_VERSION + 1):
		var count_bits: int = 8 if version < 10 else 16
		if 4 + count_bits + byte_count * 8 <= capacity(version) * 8:
			return version
	return 0


static func _data_codewords(data: PackedByteArray, version: int) -> PackedByteArray:
	var bits: Array[int] = []
	_append_bits(bits, 0b0100, 4)
	_append_bits(bits, data.size(), 8 if version < 10 else 16)
	for byte: int in data:
		_append_bits(bits, byte, 8)
	var capacity_bits: int = capacity(version) * 8
	_append_bits(bits, 0, mini(4, capacity_bits - bits.size()))
	_append_bits(bits, 0, (8 - bits.size() % 8) % 8)
	var result: PackedByteArray = PackedByteArray()
	for i: int in range(0, bits.size(), 8):
		var byte: int = 0
		for j: int in 8:
			byte = (byte << 1) | bits[i + j]
		result.append(byte)
	var pad: int = 0
	while result.size() < capacity(version):
		result.append(PAD_BYTES[pad % 2])
		pad += 1
	return result


static func _append_bits(bits: Array[int], value: int, count: int) -> void:
	for i: int in range(count - 1, -1, -1):
		bits.append((value >> i) & 1)


static func _add_error_correction(data: PackedByteArray, version: int) -> PackedByteArray:
	var ec_length: int = EC_PER_BLOCK[version]
	var generator: PackedByteArray = _rs_generator(ec_length)
	var data_blocks: Array[PackedByteArray] = []
	var ec_blocks: Array[PackedByteArray] = []
	var offset: int = 0
	for group: Array in BLOCKS[version]:
		for block_index: int in int(group[0]):
			var block: PackedByteArray = data.slice(offset, offset + int(group[1]))
			offset += int(group[1])
			data_blocks.append(block)
			ec_blocks.append(_rs_remainder(block, generator))
	var result: PackedByteArray = PackedByteArray()
	var longest: int = data_blocks[data_blocks.size() - 1].size()
	for i: int in longest:
		for block: PackedByteArray in data_blocks:
			if i < block.size():
				result.append(block[i])
	for i: int in ec_length:
		for block: PackedByteArray in ec_blocks:
			result.append(block[i])
	return result


static func _gf_multiply(a: int, b: int) -> int:
	var result: int = 0
	for i: int in range(7, -1, -1):
		result = (result << 1) ^ ((result >> 7) * 0x11D)
		result ^= ((b >> i) & 1) * a
	return result & 0xFF


## Coefficients of the generator polynomial, highest degree first, leading 1 omitted.
static func _rs_generator(degree: int) -> PackedByteArray:
	var result: PackedByteArray = PackedByteArray()
	result.resize(degree)
	result[degree - 1] = 1
	var root: int = 1
	for i: int in degree:
		for j: int in degree:
			result[j] = _gf_multiply(result[j], root)
			if j + 1 < degree:
				result[j] ^= result[j + 1]
		root = _gf_multiply(root, 0x02)
	return result


static func _rs_remainder(data: PackedByteArray, generator: PackedByteArray) -> PackedByteArray:
	var result: PackedByteArray = PackedByteArray()
	result.resize(generator.size())
	for byte: int in data:
		var factor: int = byte ^ result[0]
		for i: int in range(result.size() - 1):
			result[i] = result[i + 1]
		result[result.size() - 1] = 0
		for i: int in result.size():
			result[i] ^= _gf_multiply(generator[i], factor)
	return result


static func _set_function(modules: PackedByteArray, reserved: PackedByteArray, size: int, x: int, y: int, dark: bool) -> void:
	modules[y * size + x] = 1 if dark else 0
	reserved[y * size + x] = 1


static func _draw_function_patterns(modules: PackedByteArray, reserved: PackedByteArray, size: int, version: int) -> void:
	for i: int in size:
		_set_function(modules, reserved, size, 6, i, i % 2 == 0)
		_set_function(modules, reserved, size, i, 6, i % 2 == 0)
	for center: Vector2i in [Vector2i(3, 3), Vector2i(size - 4, 3), Vector2i(3, size - 4)]:
		for dy: int in range(-4, 5):
			for dx: int in range(-4, 5):
				var x: int = center.x + dx
				var y: int = center.y + dy
				if x < 0 or y < 0 or x >= size or y >= size:
					continue
				var distance: int = maxi(absi(dx), absi(dy))
				_set_function(modules, reserved, size, x, y, distance != 2 and distance != 4)
	var positions: Array = ALIGNMENT[version]
	var last: int = positions.size() - 1
	for i: int in positions.size():
		for j: int in positions.size():
			if (i == 0 and j == 0) or (i == 0 and j == last) or (i == last and j == 0):
				continue
			for dy: int in range(-2, 3):
				for dx: int in range(-2, 3):
					var dark: bool = maxi(absi(dx), absi(dy)) != 1
					_set_function(modules, reserved, size, int(positions[i]) + dx, int(positions[j]) + dy, dark)
	# Reserve the format areas; real bits are drawn after masking.
	_draw_format_bits(modules, size, 0, reserved)
	if version >= 7:
		var remainder: int = version
		for i: int in 12:
			remainder = (remainder << 1) ^ ((remainder >> 11) * 0x1F25)
		var bits: int = (version << 12) | remainder
		for i: int in 18:
			var dark: bool = ((bits >> i) & 1) != 0
			var a: int = size - 11 + i % 3
			var b: int = i / 3
			_set_function(modules, reserved, size, a, b, dark)
			_set_function(modules, reserved, size, b, a, dark)


static func _draw_format_bits(modules: PackedByteArray, size: int, mask: int, reserved: PackedByteArray = PackedByteArray()) -> void:
	var data: int = (LEVEL_M_BITS << 3) | mask
	var remainder: int = data
	for i: int in 10:
		remainder = (remainder << 1) ^ ((remainder >> 9) * 0x537)
	var bits: int = ((data << 10) | remainder) ^ 0x5412
	var cells: Array[Vector2i] = []
	var values: Array[bool] = []
	for i: int in 6:
		cells.append(Vector2i(8, i))
	cells.append(Vector2i(8, 7))
	cells.append(Vector2i(8, 8))
	cells.append(Vector2i(7, 8))
	for i: int in range(9, 15):
		cells.append(Vector2i(14 - i, 8))
	for i: int in 15:
		values.append(((bits >> i) & 1) != 0)
	for i: int in 8:
		cells.append(Vector2i(size - 1 - i, 8))
		values.append(((bits >> i) & 1) != 0)
	for i: int in range(8, 15):
		cells.append(Vector2i(8, size - 15 + i))
		values.append(((bits >> i) & 1) != 0)
	cells.append(Vector2i(8, size - 8))
	values.append(true)
	for index: int in cells.size():
		var cell: Vector2i = cells[index]
		modules[cell.y * size + cell.x] = 1 if values[index] else 0
		if not reserved.is_empty():
			reserved[cell.y * size + cell.x] = 1


static func _draw_codewords(modules: PackedByteArray, reserved: PackedByteArray, size: int, codewords: PackedByteArray) -> void:
	var total_bits: int = codewords.size() * 8
	var bit_index: int = 0
	var right: int = size - 1
	while right >= 1:
		if right == 6:
			right = 5
		var upward: bool = ((right + 1) & 2) == 0
		for vertical: int in size:
			var y: int = size - 1 - vertical if upward else vertical
			for j: int in 2:
				var x: int = right - j
				var index: int = y * size + x
				if reserved[index] != 0 or bit_index >= total_bits:
					continue
				modules[index] = (codewords[bit_index >> 3] >> (7 - (bit_index & 7))) & 1
				bit_index += 1
		right -= 2


static func _mask_bit(mask: int, x: int, y: int) -> bool:
	match mask:
		0:
			return (x + y) % 2 == 0
		1:
			return y % 2 == 0
		2:
			return x % 3 == 0
		3:
			return (x + y) % 3 == 0
		4:
			return (x / 3 + y / 2) % 2 == 0
		5:
			return x * y % 2 + x * y % 3 == 0
		6:
			return (x * y % 2 + x * y % 3) % 2 == 0
		_:
			return ((x + y) % 2 + x * y % 3) % 2 == 0


static func _apply_mask(modules: PackedByteArray, reserved: PackedByteArray, size: int, mask: int) -> void:
	for y: int in size:
		for x: int in size:
			var index: int = y * size + x
			if reserved[index] == 0 and _mask_bit(mask, x, y):
				modules[index] ^= 1


## Simplified penalty (runs, 2x2 blocks, dark balance). Any mask decodes; this only improves readability.
static func _penalty(modules: PackedByteArray, size: int) -> int:
	var penalty: int = 0
	var dark: int = 0
	for y: int in size:
		var run_row: int = 1
		var run_column: int = 1
		for x: int in size:
			dark += modules[y * size + x]
			if x > 0:
				if modules[y * size + x] == modules[y * size + x - 1]:
					run_row += 1
					if run_row == 5:
						penalty += 3
					elif run_row > 5:
						penalty += 1
				else:
					run_row = 1
				if modules[x * size + y] == modules[(x - 1) * size + y]:
					run_column += 1
					if run_column == 5:
						penalty += 3
					elif run_column > 5:
						penalty += 1
				else:
					run_column = 1
			if x > 0 and y > 0:
				var value: int = modules[y * size + x]
				if value == modules[y * size + x - 1] and value == modules[(y - 1) * size + x] and value == modules[(y - 1) * size + x - 1]:
					penalty += 3
	var total: int = size * size
	penalty += (absi(dark * 20 - total * 10) + total - 1) / total * 10
	return penalty
