extends PlatformBackend
## Web implementation (v2). Accelerometer (DeviceMotion) and microphone come from the Godot core.
## Camera, QR (getUserMedia + jsQR), MediaPipe and the Web Speech API will be bridged through
## JavaScriptBridge here; until then those features report unsupported and tasks use fallbacks.


func has_feature(feature: PlatformBackend.Feature) -> bool:
	match feature:
		Feature.ACCELEROMETER:
			return OS.has_feature("web_android") or OS.has_feature("web_ios")
		Feature.MICROPHONE:
			return super(feature)
	return false
