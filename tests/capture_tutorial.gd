extends SceneTree

var frame_count: int = 0

func _init() -> void:
	var packed: PackedScene = load("res://scenes/main/main.tscn") as PackedScene
	root.add_child(packed.instantiate())

func _process(_delta: float) -> bool:
	frame_count += 1
	if frame_count == 2:
		var main: Node = root.get_child(0)
		var tutorial: TutorialController = main.get("tutorial_controller") as TutorialController
		tutorial.persistence_enabled = false
		main.call("close_modal")
		main.call("set_phase", 1)
		tutorial.start()
	if frame_count < 12:
		return false
	var main: Node = root.get_child(0)
	var tutorial: TutorialController = main.get("tutorial_controller") as TutorialController
	var overlay: TutorialOverlay = tutorial.overlay
	var viewport_size: Vector2 = root.get_visible_rect().size
	var popup_bottom_right: Vector2 = overlay.popup.position + overlay.popup.size
	var highlight_bottom_right: Vector2 = overlay.highlight.position + overlay.highlight.size
	if not overlay.visible or popup_bottom_right.x > viewport_size.x or popup_bottom_right.y > viewport_size.y:
		push_error("Tutorial popup is missing or extends beyond the viewport.")
		quit(1)
		return true
	if highlight_bottom_right.x > viewport_size.x or highlight_bottom_right.y > viewport_size.y:
		push_error("Tutorial highlight extends beyond the viewport.")
		quit(1)
		return true
	var image: Image = root.get_texture().get_image()
	if image == null:
		push_error("The active display driver does not expose a viewport image.")
		quit(1)
		return true
	var error: Error = image.save_png("res://.godot/tutorial-capture.png")
	if error != OK:
		push_error("Could not save tutorial capture: %s" % error_string(error))
		quit(1)
		return true
	print("Saved tutorial capture: res://.godot/tutorial-capture.png")
	quit(0)
	return true

