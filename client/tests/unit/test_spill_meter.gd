extends GdUnitTestSuite

const FLAT: Vector3 = Vector3(0, 0, -9.81)
const FRAME: float = 1.0 / 60.0


func _tilted(degrees: float) -> Vector3:
	var angle: float = deg_to_rad(degrees)
	return Vector3(9.81 * sin(angle), 0, -9.81 * cos(angle))


func test_tilt_of() -> void:
	assert_float(SpillMeter.tilt_of(FLAT)).is_equal_approx(0.0, 0.01)
	assert_float(SpillMeter.tilt_of(_tilted(30.0))).is_equal_approx(30.0, 0.01)
	assert_float(SpillMeter.tilt_of(Vector3(0, 9.81, 0))).is_equal_approx(90.0, 0.01)


func test_flat_steady_phone_keeps_coffee() -> void:
	var meter: SpillMeter = SpillMeter.new()
	for i: int in 600:
		meter.update(FLAT + Vector3(0.05, -0.05, 0) * (i % 2), FRAME)
	assert_float(meter.level).is_equal(1.0)


func test_small_tilt_is_safe_big_tilt_spills() -> void:
	var meter: SpillMeter = SpillMeter.new()
	for i: int in 60:
		meter.update(_tilted(15.0), FRAME)
	assert_float(meter.level).is_equal(1.0)
	for i: int in 120:
		meter.update(_tilted(60.0), FRAME)
	assert_float(meter.level).is_less(SpillMeter.FAIL_LEVEL)
	assert_bool(meter.is_failed()).is_true()


func test_jerk_spills_a_little() -> void:
	var meter: SpillMeter = SpillMeter.new()
	meter.update(FLAT, FRAME)
	meter.update(FLAT + Vector3(8, 0, 0), FRAME)
	assert_bool(meter.spilled_this_update).is_true()
	# The tilt from the jerk itself also spills a bit on that frame.
	assert_float(meter.level).is_less_equal(1.0 - SpillMeter.JERK_SPILL)
	assert_float(meter.level).is_greater(0.85)


func test_missing_sensor_data_is_ignored() -> void:
	var meter: SpillMeter = SpillMeter.new()
	meter.update(Vector3.ZERO, 1.0)
	assert_float(meter.level).is_equal(1.0)
