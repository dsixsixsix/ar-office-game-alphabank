class_name OfficeObjects
extends RefCounted
## Objects for the "Find the object" task. Every target lists the ML Kit labels that count as a hit;
## only labels from the bundled base model are used, so recognition works offline and needs no
## custom model. One object often produces several labels (a mug is "Cup", "Coffee" or "Cappuccino"),
## so each target accepts a small group of them.

const MIN_CONFIDENCE: float = 0.55


class Target:
	extends RefCounted

	var id: String
	var name_key: String
	var labels: PackedStringArray

	func _init(p_id: String, p_name_key: String, p_labels: PackedStringArray) -> void:
		id = p_id
		name_key = p_name_key
		labels = p_labels

	## Confidence of the best matching label in `labels`, or 0.0 when the object is not in the frame.
	func confidence_in(detected: Array[SensorModels.ObjectLabel]) -> float:
		var best: float = 0.0
		for label: SensorModels.ObjectLabel in detected:
			if labels.has(label.id) and label.confidence > best:
				best = label.confidence
		return best

	func is_recognized(detected: Array[SensorModels.ObjectLabel]) -> bool:
		return confidence_in(detected) >= MIN_CONFIDENCE


static func defaults() -> Array[Target]:
	return [
		Target.new("mug", "OBJ_MUG", PackedStringArray(["Cup", "Coffee", "Cappuccino", "Saucer", "Juice"])),
		Target.new("plant", "OBJ_PLANT", PackedStringArray(["Plant", "Flowerpot", "Flower", "Flora"])),
		Target.new("screen", "OBJ_SCREEN", PackedStringArray(["Computer", "Television", "Screenshot"])),
		Target.new("chair", "OBJ_CHAIR", PackedStringArray(["Chair", "Couch", "Loveseat"])),
		Target.new("clock", "OBJ_CLOCK", PackedStringArray(["Clock"])),
		Target.new("phone", "OBJ_PHONE", PackedStringArray(["Mobile phone", "Telephone"])),
		Target.new("whiteboard", "OBJ_WHITEBOARD", PackedStringArray(["Whiteboard", "Blackboard", "Presentation"])),
		Target.new("papers", "OBJ_PAPERS", PackedStringArray(["Paper", "Newspaper", "Receipt", "Menu", "Book"])),
		Target.new("glasses", "OBJ_GLASSES", PackedStringArray(["Glasses", "Sunglasses", "Goggles"])),
		Target.new("bag", "OBJ_BAG", PackedStringArray(["Bag", "Handbag", "Backpack"])),
	]


## Targets from admin panel data (a list of ids), or the default set when the list is empty.
static func from_ids(ids: Array) -> Array[Target]:
	if ids.is_empty():
		return defaults()
	var result: Array[Target] = []
	for target: Target in defaults():
		if ids.has(target.id):
			result.append(target)
	return result if not result.is_empty() else defaults()


## Every label the game can react to, for the desktop sensor emulator.
static func all_labels() -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for target: Target in defaults():
		for label: String in target.labels:
			if not result.has(label):
				result.append(label)
	return result
