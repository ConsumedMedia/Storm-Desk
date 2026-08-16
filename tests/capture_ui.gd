extends SceneTree

var frame_count: int = 0

func _init() -> void:
	var packed: PackedScene = load("res://scenes/main/main.tscn") as PackedScene
	root.add_child(packed.instantiate())

func _process(_delta: float) -> bool:
	frame_count += 1
	if frame_count == 2:
		var main: Node = root.get_child(0)
		main.call("close_modal")
		main.call("set_phase", 2)
		main.call("show_district", load("res://resources/districts/harbor.tres"))
	if frame_count < 10:
		return false
	var main: Node = root.get_child(0)
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
	quit(0)
	return true
