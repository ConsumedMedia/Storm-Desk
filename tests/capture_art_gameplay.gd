extends SceneTree

const SAVE_PATH: String = "user://storm_desk_capture_art_gameplay.cfg"
const SETTINGS_PATH: String = "user://storm_desk_capture_art_gameplay_preferences.cfg"

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
		main.call("set_phase", 1)
		var district_values: Array = main.get("districts") as Array
		var district: DistrictDefinition = district_values[1] as DistrictDefinition
		main.call("show_district", district)
	if frame_count < 10:
		return false
	var bureau_art: TextureRect = main.get("bureau_background") as TextureRect
	var map_art: TextureRect = main.get("regional_map_art") as TextureRect
	var district_art: TextureRect = main.get("district_art") as TextureRect
	if bureau_art.texture == null or map_art.texture == null or district_art.texture == null or not district_art.visible:
		push_error("Gameplay art capture is missing a required runtime texture.")
		quit(1)
		return true
	var viewport_size: Vector2 = root.get_visible_rect().size
	var continue_button: Control = main.get("continue_button") as Control
	if continue_button.global_position.y + continue_button.size.y > viewport_size.y:
		push_error("Artwork integration pushed the footer below the viewport.")
		quit(1)
		return true
	var image: Image = root.get_texture().get_image()
	if image == null:
		push_error("The active display driver does not expose a viewport image.")
		quit(1)
		return true
	var error: Error = image.save_png("res://.godot/art-gameplay-capture.png")
	if error != OK:
		push_error("Could not save gameplay art capture: %s" % error_string(error))
		quit(1)
		return true
	print("Saved gameplay art capture: res://.godot/art-gameplay-capture.png")
	remove_test_files()
	quit(0)
	return true
