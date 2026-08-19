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
var reduced_motion: bool = false
var high_contrast: bool = false
var art_backdrop_enabled: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func set_phase(value: int) -> void:
	phase_value = value
	queue_redraw()

func set_accessibility(reduce_motion: bool, use_high_contrast: bool) -> void:
	reduced_motion = reduce_motion
	high_contrast = use_high_contrast
	set_process(not reduced_motion)
	queue_redraw()

func set_art_backdrop_enabled(enabled: bool) -> void:
	art_backdrop_enabled = enabled
	queue_redraw()

func _process(delta: float) -> void:
	if reduced_motion:
		return
	motion = fmod(motion + delta * 9.0, 260.0)
	queue_redraw()

func _draw() -> void:
	var bands: int = 12
	for index: int in range(bands):
		var amount: float = float(index) / float(bands - 1)
		var band_rect := Rect2(0.0, size.y * amount, size.x, size.y / float(bands) + 1.0)
		var top: Color = Color("0d1824") if high_contrast else BASE_TOP
		var bottom: Color = Color("03070d") if high_contrast else BASE_BOTTOM
		if art_backdrop_enabled:
			top.a = 0.42 if high_contrast else 0.16
			bottom.a = 0.62 if high_contrast else 0.26
		draw_rect(band_rect, top.lerp(bottom, amount))
	var accent: Color = phase_accent()
	for index: int in range(9):
		var start_x: float = fmod(float(index * 173) + motion, size.x + 260.0) - 130.0
		var start_y: float = 42.0 + float(index * 79)
		var primary_alpha: float = 0.09 if high_contrast else 0.055
		var secondary_alpha: float = 0.06 if high_contrast else 0.035
		draw_line(Vector2(start_x, start_y), Vector2(start_x + 150.0, start_y - 10.0), Color(accent, primary_alpha), 1.0)
		draw_line(Vector2(start_x + 38.0, start_y + 7.0), Vector2(start_x + 112.0, start_y + 2.0), Color(accent, secondary_alpha), 1.0)

func phase_accent() -> Color:
	match phase_value:
		3, 4:
			return ACCENT_WARNING
		5, 6:
			return ACCENT_STORM
		8:
			return ACCENT_NIGHT
	return ACCENT_CALM
