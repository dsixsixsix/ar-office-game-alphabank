extends GdUnitTestSuite


func _leg(knee_angle: float, likelihood: float = 0.9) -> Dictionary:
	var knee: Vector2 = Vector2(0.5, 0.7)
	var thigh: float = deg_to_rad(180.0 - knee_angle)
	var hip: Vector2 = knee + Vector2(-sin(thigh), -cos(thigh)) * 0.2
	return {
		&"left_hip": Vector3(hip.x, hip.y, likelihood),
		&"left_knee": Vector3(knee.x, knee.y, likelihood),
		&"left_ankle": Vector3(0.5, 0.9, likelihood),
	}


func test_joint_angle() -> void:
	assert_float(SquatCounter.joint_angle(Vector2(0, -1), Vector2.ZERO, Vector2(0, 1))).is_equal_approx(180.0, 0.01)
	assert_float(SquatCounter.joint_angle(Vector2(1, 0), Vector2.ZERO, Vector2(0, 1))).is_equal_approx(90.0, 0.01)
	assert_float(SquatCounter.joint_angle(Vector2.ZERO, Vector2.ZERO, Vector2(0, 1))).is_equal(-1.0)


func test_counts_full_repetitions_only() -> void:
	var counter: SquatCounter = SquatCounter.new()
	for angle: float in [175.0, 140.0, 95.0, 80.0, 120.0, 160.0]:
		counter.update(_leg(angle))
	assert_int(counter.reps).is_equal(1)
	# A half squat does not count.
	for angle: float in [150.0, 120.0, 170.0]:
		counter.update(_leg(angle))
	assert_int(counter.reps).is_equal(1)
	for angle: float in [90.0, 170.0, 85.0, 175.0]:
		counter.update(_leg(angle))
	assert_int(counter.reps).is_equal(3)


func test_ignores_unreliable_landmarks() -> void:
	var counter: SquatCounter = SquatCounter.new()
	counter.update(_leg(80.0, 0.2))
	counter.update(_leg(175.0, 0.2))
	assert_int(counter.reps).is_equal(0)
	assert_float(counter.knee_angle).is_equal(-1.0)


func test_prefers_the_better_visible_leg() -> void:
	var landmarks: Dictionary = _leg(170.0, 0.6)
	var right: Dictionary = _leg(90.0, 0.95)
	landmarks[&"right_hip"] = right[&"left_hip"]
	landmarks[&"right_knee"] = right[&"left_knee"]
	landmarks[&"right_ankle"] = right[&"left_ankle"]
	assert_float(SquatCounter.best_knee_angle(landmarks)).is_equal_approx(90.0, 0.5)
