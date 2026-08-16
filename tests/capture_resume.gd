extends SceneTree

const SAVE_PATH: String = "user://storm_desk_capture_resume.cfg"
const SETTINGS_PATH: String = "user://storm_desk_capture_resume_settings.cfg"

var frame_count: int = 0

func _init() -> void:
	remove_test_save()
	var packed: PackedScene = load("res://scenes/main/main.tscn") as PackedScene
	var seed_main: Node = packed.instantiate()
	seed_main.set("save_path", SAVE_PATH)
	seed_main.set("settings_path", SETTINGS_PATH)
	root.add_child(seed_main)

func remove_test_save() -> void:
	var absolute_path: String = ProjectSettings.globalize_path(SAVE_PATH)
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(absolute_path)
	if FileAccess.file_exists(SETTINGS_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))

func _process(_delta: float) -> bool:
	frame_count += 1
	if frame_count == 2:
		var seed_main: Node = root.get_child(0)
		seed_main.call("close_modal")
		seed_main.call("set_phase", 2)
		seed_main.call("select_network_site", &"farmland")
		root.remove_child(seed_main)
		seed_main.free()
		var packed: PackedScene = load("res://scenes/main/main.tscn") as PackedScene
		var resumed_main: Node = packed.instantiate()
		resumed_main.set("save_path", SAVE_PATH)
		resumed_main.set("settings_path", SETTINGS_PATH)
		root.add_child(resumed_main)
	if frame_count < 10:
		return false
	var main: Node = root.get_child(0)
	var modal_layer: Control = main.get("modal_layer") as Control
	if not node_contains_text(modal_layer, "CONTINUE FIRST WEEK"):
		push_error("Resume capture did not open the saved-session choice.")
		quit(1)
		return true
	if not node_contains_text(modal_layer, "Day 1 of 5") or not node_contains_text(modal_layer, "Network Planning"):
		push_error("Resume capture does not summarize the saved day and phase.")
		quit(1)
		return true
	var modal_bottom_right: Vector2 = modal_layer.global_position + modal_layer.size
	var viewport_size: Vector2 = root.get_visible_rect().size
	if modal_bottom_right.x > viewport_size.x or modal_bottom_right.y > viewport_size.y:
		push_error("Resume modal extends beyond the viewport.")
		quit(1)
		return true
	var image: Image = root.get_texture().get_image()
	if image == null:
		push_error("The active display driver does not expose a viewport image.")
		quit(1)
		return true
	var error: Error = image.save_png("res://.godot/resume-capture.png")
	if error != OK:
		push_error("Could not save resume capture: %s" % error_string(error))
		quit(1)
		return true
	print("Saved resume capture: res://.godot/resume-capture.png")
	remove_test_save()
	quit(0)
	return true

func node_contains_text(node: Node, expected: String) -> bool:
	if node is Label and (node as Label).text.contains(expected):
		return true
	for child: Node in node.get_children():
		if node_contains_text(child, expected):
			return true
	return false
