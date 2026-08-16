class_name AtmosphereBackdrop
extends Control

const BASE_TOP := Color("142334")
const BASE_BOTTOM := Color("09111c")
const ACCENT_CALM := Color("55c2b5")
const ACCENT_WARNING := Color("f0b45a")
const ACCENT_STORM := Color("bb6f7b")
const ACCENT_NIGHT := Color("7787c7")

var phase_value: int = 0
var motion: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func set_phase(value: int) -> void:
	phase_value = value
	queue_redraw()

func _process(delta: float) -> void:
	motion = fmod(motion + delta * 9.0, 260.0)
	queue_redraw()

func _draw() -> void:
	var bands: int = 12
	for index: int in range(bands):
		var amount: float = float(index) / float(bands - 1)
		var band_rect := Rect2(0.0, size.y * amount, size.x, size.y / float(bands) + 1.0)
		draw_rect(band_rect, BASE_TOP.lerp(BASE_BOTTOM, amount))
	var accent: Color = phase_accent()
	for index: int in range(9):
		var start_x: float = fmod(float(index * 173) + motion, size.x + 260.0) - 130.0
		var start_y: float = 42.0 + float(index * 79)
		draw_line(Vector2(start_x, start_y), Vector2(start_x + 150.0, start_y - 10.0), Color(accent, 0.055), 1.0)
		draw_line(Vector2(start_x + 38.0, start_y + 7.0), Vector2(start_x + 112.0, start_y + 2.0), Color(accent, 0.035), 1.0)

func phase_accent() -> Color:
	match phase_value:
		3, 4:
			return ACCENT_WARNING
		5, 6:
			return ACCENT_STORM
		8:
			return ACCENT_NIGHT
	return ACCENT_CALM
