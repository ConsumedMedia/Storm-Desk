extends SceneTree

const SAVE_PATH: String = "user://storm_desk_capture_settings.cfg"
const SETTINGS_PATH: String = "user://storm_desk_capture_settings_preferences.cfg"

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
	if frame_count == 2:
		main.call("close_modal")
		main.call("show_settings")
	if frame_count < 10:
		return false
	var modal_layer: Control = main.get("modal_layer") as Control
	for expected: String in ["SETTINGS", "Reduced motion", "Larger interface text", "High contrast", "Rules / Help", "Save Progress", "Save & Quit", "Quit to Desktop"]:
		if not node_contains_control_text(modal_layer, expected):
			push_error("Settings capture is missing control text: %s" % expected)
			quit(1)
			return true
	var viewport_size: Vector2 = root.get_visible_rect().size
	if modal_layer.global_position.x + modal_layer.size.x > viewport_size.x or modal_layer.global_position.y + modal_layer.size.y > viewport_size.y:
		push_error("Settings modal extends beyond the viewport.")
		quit(1)
		return true
	var image: Image = root.get_texture().get_image()
	if image == null:
		push_error("The active display driver does not expose a viewport image.")
		quit(1)
		return true
	var error: Error = image.save_png("res://.godot/settings-capture.png")
	if error != OK:
		push_error("Could not save Settings capture: %s" % error_string(error))
		quit(1)
		return true
	print("Saved Settings capture: res://.godot/settings-capture.png")
	remove_test_files()
	quit(0)
	return true

func node_contains_control_text(node: Node, expected: String) -> bool:
	if node is Label and (node as Label).text.contains(expected):
		return true
	if node is Button and (node as Button).text.contains(expected):
		return true
	for child: Node in node.get_children():
		if node_contains_control_text(child, expected):
			return true
	return false
