extends SceneTree

const SAVE_PATH: String = "user://storm_desk_capture_document_frames.cfg"
const SETTINGS_PATH: String = "user://storm_desk_capture_document_frames_preferences.cfg"

var frame_count: int = 0

func _init() -> void:
	remove_test_files()
	var packed: PackedScene = load("res://scenes/main/main.tscn") as PackedScene
	var main: Node = packed.instantiate()
	main.set("save_path", SAVE_PATH)
	main.set("settings_path", SETTINGS_PATH)
	main.set("quitting_enabled", false)
	root.add_child(main)

func remove_test_files() -> void:
	for path: String in [SAVE_PATH, SETTINGS_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _process(_delta: float) -> bool:
	frame_count += 1
	var main: Node = root.get_child(0)
	if frame_count == 10:
		if not capture_document(main, &"briefing", "res://.godot/document-briefing-capture.png"):
			return true
		main.call("close_modal")
		main.call("set_phase", 3)
		main.call("on_hazard_selected", 1)
		main.call("on_district_toggled", true, &"industrial")
		main.call("show_warning_confirmation")
	if frame_count == 20:
		if not capture_document(main, &"warning", "res://.godot/document-warning-capture.png"):
			return true
		main.call("confirm_warning")
	if frame_count == 30:
		if not capture_document(main, &"daily_report", "res://.godot/document-daily-capture.png"):
			return true
		main.call("show_final_report")
	if frame_count == 40:
		if not capture_document(main, &"final_report", "res://.godot/document-final-capture.png"):
			return true
		main.call("update_accessibility_setting", true, &"large_text")
		main.call("update_accessibility_setting", true, &"high_contrast")
		main.call("restart_session")
	if frame_count == 50:
		if not capture_document(main, &"briefing", "res://.godot/document-accessibility-capture.png"):
			return true
		print("Saved five artwork-native document captures under res://.godot/.")
		remove_test_files()
		quit(0)
		return true
	return false

func capture_document(main: Node, expected_kind: StringName, path: String) -> bool:
	var modal_layer: Control = main.get("modal_layer") as Control
	var document_frame: Control = find_document_frame(modal_layer)
	if document_frame == null or StringName(document_frame.get_meta("art_document_frame", &"")) != expected_kind:
		push_error("Missing artwork-native %s document frame." % expected_kind)
		quit(1)
		return false
	var viewport_size: Vector2 = root.get_visible_rect().size
	var frame_end: Vector2 = document_frame.global_position + document_frame.size
	if document_frame.global_position.x < 0.0 or document_frame.global_position.y < 0.0 or frame_end.x > viewport_size.x or frame_end.y > viewport_size.y:
		push_error("%s document frame extends beyond the viewport." % expected_kind)
		quit(1)
		return false
	var image: Image = root.get_texture().get_image()
	if image == null:
		push_error("The active display driver does not expose a viewport image.")
		quit(1)
		return false
	var error: Error = image.save_png(path)
	if error != OK:
		push_error("Could not save %s: %s" % [path, error_string(error)])
		quit(1)
		return false
	return true

func find_document_frame(node: Node) -> Control:
	if node is Control and node.has_meta("art_document_frame"):
		return node as Control
	for child: Node in node.get_children():
		var found: Control = find_document_frame(child)
		if found != null:
			return found
	return null
