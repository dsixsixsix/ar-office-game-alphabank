@tool
extends EditorPlugin
## Adds the OfficeGameAndroid AAR and its Maven dependencies to Android exports.
## The AAR is built from native/android (`tools/build-android.ps1` or `gradlew assembleDebug assembleRelease`).
## Android exports must use the Gradle build ("Use Gradle Build") for the dependencies to resolve.

var _export_plugin: AndroidExportPlugin


func _enter_tree() -> void:
	_export_plugin = AndroidExportPlugin.new()
	add_export_plugin(_export_plugin)


func _exit_tree() -> void:
	remove_export_plugin(_export_plugin)
	_export_plugin = null


class AndroidExportPlugin:
	extends EditorExportPlugin

	const PLUGIN_NAME: String = "OfficeGameAndroid"
	## Keep in sync with native/android/plugin/build.gradle.kts.
	const DEPENDENCIES: PackedStringArray = [
		"androidx.camera:camera-core:1.4.2",
		"androidx.camera:camera-camera2:1.4.2",
		"androidx.camera:camera-lifecycle:1.4.2",
		"com.google.mlkit:barcode-scanning:17.3.0",
		"com.google.mlkit:face-detection:16.1.7",
		"com.google.mlkit:image-labeling:17.0.9",
		"com.google.mlkit:pose-detection:18.0.0-beta5",
		"org.opencv:opencv:4.12.0",
	]

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _get_android_libraries(_platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		var build_type: String = "debug" if debug else "release"
		return PackedStringArray(["office_game_android/bin/%s/office-game-android-%s.aar" % [build_type, build_type]])

	func _get_android_dependencies(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return DEPENDENCIES

	func _get_name() -> String:
		return PLUGIN_NAME
