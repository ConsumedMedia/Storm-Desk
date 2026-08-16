extends SceneTree

const SAVE_PATH: String = "user://storm_desk_capture_ui.cfg"

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
		for _day: int in range(3):
			main.call("advance_day")
		main.call("close_modal")
		main.call("set_phase", 2)
		main.call("select_network_site", &"ridge")
		main.call("show_district", load("res://resources/districts/harbor.tres"))
	if frame_count < 10:
		return false
	var main: Node = root.get_child(0)
	var day_label: Label = main.get("day_label") as Label
	if day_label.text != "DAY 4 / 5":
		push_error("Five-day header did not reach the Day Four capture state: %s" % day_label.text)
		quit(1)
		return true
	var network_model: NetworkModel = main.get("network_model") as NetworkModel
	if network_model.online_relays().has(&"ridge"):
		push_error("Day Four capture expected the High Ridge opening outage.")
		quit(1)
		return true
	var continue_button: Control = main.get("continue_button") as Control
	var footer_bottom: float = continue_button.global_position.y + continue_button.size.y
	if footer_bottom > root.get_visible_rect().size.y:
		push_error("Footer extends below the viewport: %.1f" % footer_bottom)
		quit(1)
		return true
	var network_box: Control = main.get("network_box") as Control
	var network_right: float = network_box.global_position.x + network_box.size.x
	if network_right > root.get_visible_rect().size.x:
		push_error("Network desk extends beyond the viewport: %.1f" % network_right)
		quit(1)
		return true
	var image: Image = root.get_texture().get_image()
	if image == null:
		push_error("The active display driver does not expose a viewport image.")
		quit(1)
		return true
	var error: Error = image.save_png("res://.godot/ui-capture.png")
	if error != OK:
		push_error("Could not save UI capture: %s" % error_string(error))
		quit(1)
		return true
	print("Saved UI capture: res://.godot/ui-capture.png")
	remove_test_save()
	quit(0)
	return true
