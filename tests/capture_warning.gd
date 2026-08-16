extends SceneTree

const SAVE_PATH: String = "user://storm_desk_capture_warning.cfg"
const SETTINGS_PATH: String = "user://storm_desk_capture_warning_settings.cfg"

var frame_count: int = 0

func _init() -> void:
	var packed: PackedScene = load("res://scenes/main/main.tscn") as PackedScene
	remove_test_save()
	var main: Node = packed.instantiate()
	main.set("save_path", SAVE_PATH)
	main.set("settings_path", SETTINGS_PATH)
	root.add_child(main)

func remove_test_save() -> void:
	var absolute_path: String = ProjectSettings.globalize_path(SAVE_PATH)
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(absolute_path)
	if FileAccess.file_exists(SETTINGS_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))

func _process(_delta: float) -> bool:
	frame_count += 1
	if frame_count == 2:
		var main: Node = root.get_child(0)
		main.call("close_modal")
		main.call("set_phase", 3)
		var hazard_option: OptionButton = main.get("hazard_option") as OptionButton
		hazard_option.select(1)
		main.call("on_hazard_selected", 1)
		var district_checks: Dictionary = main.get("district_checks") as Dictionary
		(district_checks[&"industrial"] as CheckBox).set_pressed_no_signal(true)
		main.call("on_district_toggled", true, &"industrial")
		main.call("show_district", load("res://resources/districts/industrial.tres"))
	if frame_count < 12:
		return false
	var main: Node = root.get_child(0)
	var district_buttons: Dictionary = main.get("district_buttons") as Dictionary
	var industrial_button: Button = district_buttons[&"industrial"] as Button
	if not industrial_button.text.contains("WARNING"):
		push_error("Warning capture is missing the district-map marker.")
		quit(1)
		return true
	var warning_summary: Label = main.get("warning_summary_label") as Label
	if not warning_summary.text.contains("SPARKSTORM") or not warning_summary.text.contains("Industrial"):
		push_error("Warning capture is missing the live draft summary: %s" % warning_summary.text)
		quit(1)
		return true
	var feedback: Label = main.get("action_feedback_label") as Label
	if feedback.text.is_empty():
		push_error("Warning capture is missing action feedback.")
		quit(1)
		return true
	var continue_button: Control = main.get("continue_button") as Control
	var footer_bottom: float = continue_button.global_position.y + continue_button.size.y
	if footer_bottom > root.get_visible_rect().size.y:
		push_error("Warning footer extends below the viewport: %.1f" % footer_bottom)
		quit(1)
		return true
	var warning_box: Control = main.get("warning_box") as Control
	var warning_right: float = warning_box.global_position.x + warning_box.size.x
	if warning_right > root.get_visible_rect().size.x:
		push_error("Warning desk extends beyond the viewport: %.1f" % warning_right)
		quit(1)
		return true
	var image: Image = root.get_texture().get_image()
	if image == null:
		push_error("The active display driver does not expose a viewport image.")
		quit(1)
		return true
	var error: Error = image.save_png("res://.godot/warning-capture.png")
	if error != OK:
		push_error("Could not save warning capture: %s" % error_string(error))
		quit(1)
		return true
	print("Saved warning capture: res://.godot/warning-capture.png")
	remove_test_save()
	quit(0)
	return true
