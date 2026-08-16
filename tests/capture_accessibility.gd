extends SceneTree

const SAVE_PATH: String = "user://storm_desk_capture_accessibility.cfg"
const SETTINGS_PATH: String = "user://storm_desk_capture_accessibility_preferences.cfg"

var frame_count: int = 0

func _init() -> void:
	remove_test_files()
	var packed: PackedScene = load("res://scenes/main/main.tscn") as PackedScene
	var main: Node = packed.instantiate()
	main.set("save_path", SAVE_PATH)
	main.set("settings_path", SETTINGS_PATH)
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
		main.call("update_accessibility_setting", true, &"reduced_motion")
		main.call("update_accessibility_setting", true, &"large_text")
		main.call("update_accessibility_setting", true, &"high_contrast")
		main.call("set_phase", 3)
		(main.get("hazard_option") as OptionButton).select(1)
		main.call("on_hazard_selected", 1)
		var district_checks: Dictionary = main.get("district_checks") as Dictionary
		(district_checks[&"industrial"] as CheckBox).set_pressed_no_signal(true)
		main.call("on_district_toggled", true, &"industrial")
	if frame_count < 10:
		return false
	var atmosphere: Control = main.get("atmosphere") as Control
	if atmosphere.is_processing() or not bool(atmosphere.get("high_contrast")):
		push_error("Accessibility capture did not apply reduced motion and high contrast.")
		quit(1)
		return true
	var day_label: Label = main.get("day_label") as Label
	if day_label.get_theme_font_size("font_size") <= 16:
		push_error("Accessibility capture did not apply larger text.")
		quit(1)
		return true
	var viewport_size: Vector2 = root.get_visible_rect().size
	var continue_button: Control = main.get("continue_button") as Control
	if continue_button.global_position.y + continue_button.size.y > viewport_size.y:
		push_error("Large-text footer extends below the viewport: %.1f > %.1f." % [continue_button.global_position.y + continue_button.size.y, viewport_size.y])
		quit(1)
		return true
	var warning_box: Control = main.get("warning_box") as Control
	if warning_box.global_position.x + warning_box.size.x > viewport_size.x:
		push_error("Large-text warning desk extends beyond the viewport.")
		quit(1)
		return true
	var image: Image = root.get_texture().get_image()
	if image == null:
		push_error("The active display driver does not expose a viewport image.")
		quit(1)
		return true
	var error: Error = image.save_png("res://.godot/accessibility-capture.png")
	if error != OK:
		push_error("Could not save accessibility capture: %s" % error_string(error))
		quit(1)
		return true
	print("Saved accessibility capture: res://.godot/accessibility-capture.png")
	remove_test_files()
	quit(0)
	return true
