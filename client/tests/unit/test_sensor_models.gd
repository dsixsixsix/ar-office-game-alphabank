extends GdUnitTestSuite


func test_parse_pose_keeps_known_landmarks() -> void:
	var json: String = JSON.stringify({"landmarks": {"left_knee": [0.5, 0.7, 0.9], "left_ear": [0, 0, 1], "right_hip": [1]}})
	var pose: Dictionary = SensorModels.parse_pose(json)
	assert_dict(pose).has_size(1)
	assert_that(pose[&"left_knee"]).is_equal(Vector3(0.5, 0.7, 0.9))


func test_parse_faces() -> void:
	var json: String = JSON.stringify({"faces": [{"x": 0.1, "y": 0.2, "w": 0.3, "h": 0.4, "smiling": 0.8}, {"x": 0.5}]})
	var faces: Array[SensorModels.Face] = SensorModels.parse_faces(json)
	assert_int(faces.size()).is_equal(2)
	assert_that(faces[0].bounds).is_equal(Rect2(0.1, 0.2, 0.3, 0.4))
	assert_float(faces[0].smiling).is_equal_approx(0.8, 0.0001)
	assert_float(faces[1].smiling).is_equal(-1.0)


func test_parse_markers_and_garbage() -> void:
	assert_array(Array(SensorModels.parse_markers(JSON.stringify({"markers": [3, 1]})))).is_equal([3, 1])
	assert_int(SensorModels.parse_markers("not json").size()).is_equal(0)
	assert_dict(SensorModels.parse_pose("[]")).is_empty()
	assert_int(SensorModels.parse_faces(JSON.stringify({"faces": 5})).size()).is_equal(0)


func test_frame_from_rgb_checks_size() -> void:
	var rgb: PackedByteArray = PackedByteArray()
	rgb.resize(4 * 3 * 3)
	assert_object(SensorModels.frame_from_rgb(4, 3, rgb)).is_not_null()
	assert_object(SensorModels.frame_from_rgb(4, 4, rgb)).is_null()
