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
		main.call("set_phase", 3)
	if frame_count < 10:
		return false
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
