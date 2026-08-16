extends SceneTree

const SAVE_PATH: String = "user://storm_desk_capture_result.cfg"

var frame_count: int = 0

func _init() -> void:
	var packed: PackedScene = load("res://scenes/main/main.tscn") as PackedScene
	remove_test_save()
	var main: Node = packed.instantiate()
	main.set("save_path", SAVE_PATH)
	root.add_child(main)

func remove_test_save() -> void:
	var absolute_path: String = ProjectSettings.globalize_path(SAVE_PATH)
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(absolute_path)

func _process(_delta: float) -> bool:
	frame_count += 1
	if frame_count == 2:
		var main: Node = root.get_child(0)
		main.call("close_modal")
		main.call("set_phase", 3)
		main.call("on_hazard_selected", 1)
		main.call("on_district_toggled", true, &"industrial")
		main.call("confirm_warning")
	if frame_count < 12:
		return false
	var main: Node = root.get_child(0)
	var modal_layer: Control = main.get("modal_layer") as Control
	if not node_contains_text(modal_layer, "ASSESSMENT: EFFECTIVE WARNING"):
		push_error("Result capture is missing its outcome assessment.")
		quit(1)
		return true
	var district_buttons: Dictionary = main.get("district_buttons") as Dictionary
	if not (district_buttons[&"industrial"] as Button).text.contains("PROTECTED"):
		push_error("Result capture is missing the protected district marker.")
		quit(1)
		return true
	var image: Image = root.get_texture().get_image()
	if image == null:
		push_error("The active display driver does not expose a viewport image.")
		quit(1)
		return true
	var error: Error = image.save_png("res://.godot/result-capture.png")
	if error != OK:
		push_error("Could not save result capture: %s" % error_string(error))
		quit(1)
		return true
	print("Saved result capture: res://.godot/result-capture.png")
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
