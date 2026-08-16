class_name TutorialOverlay
extends Control

signal target_clicked
signal skip_requested

const DIM_COLOR := Color(0.015, 0.025, 0.04, 0.78)
const ACCENT := Color("f0b45a")
const PANEL_COLOR := Color("22384a")

var target: Control
var dimmers: Array[ColorRect] = []
var highlight: Panel
var focus_label: Label
var target_catcher: Button
var popup: PanelContainer
var title_label: Label
var progress_label: Label
var body_label: Label
var instruction_label: Label
var skip_button: Button
var informational: bool = true
var text_scale: float = 1.0
var high_contrast: bool = false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	for index: int in range(4):
		var dimmer := ColorRect.new()
		dimmer.color = DIM_COLOR
		dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(dimmer)
		dimmers.append(dimmer)
	highlight = Panel.new()
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var highlight_style := StyleBoxFlat.new()
	highlight_style.bg_color = Color(0.94, 0.70, 0.35, 0.08)
	highlight_style.border_color = ACCENT
	highlight_style.set_border_width_all(3)
	highlight_style.set_corner_radius_all(8)
	highlight.add_theme_stylebox_override("panel", highlight_style)
	add_child(highlight)
	focus_label = Label.new()
	focus_label.text = "FOCUS"
	focus_label.add_theme_font_size_override("font_size", 12)
	focus_label.add_theme_color_override("font_color", ACCENT)
	focus_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(focus_label)
	target_catcher = Button.new()
	target_catcher.flat = true
	target_catcher.text = ""
	target_catcher.tooltip_text = "Inspect highlighted area"
	target_catcher.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	target_catcher.pressed.connect(func() -> void: target_clicked.emit())
	add_child(target_catcher)
	build_popup()
	hide()

func build_popup() -> void:
	popup = PanelContainer.new()
	popup.custom_minimum_size = Vector2(380, 0)
	popup.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.border_color = Color("55c2b5")
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(16)
	popup.add_theme_stylebox_override("panel", style)
	add_child(popup)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	popup.add_child(box)
	var heading := HBoxContainer.new()
	box.add_child(heading)
	title_label = Label.new()
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color("55c2b5"))
	heading.add_child(title_label)
	progress_label = Label.new()
	progress_label.add_theme_font_size_override("font_size", 13)
	progress_label.add_theme_color_override("font_color", Color("aebfca"))
	heading.add_child(progress_label)
	body_label = Label.new()
	body_label.custom_minimum_size.x = 340
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_font_size_override("font_size", 16)
	body_label.add_theme_color_override("font_color", Color("eaf1f5"))
	box.add_child(body_label)
	instruction_label = Label.new()
	instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction_label.add_theme_font_size_override("font_size", 14)
	instruction_label.add_theme_color_override("font_color", ACCENT)
	box.add_child(instruction_label)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	box.add_child(actions)
	skip_button = Button.new()
	skip_button.text = "Skip guided tour"
	skip_button.add_theme_font_size_override("font_size", 14)
	skip_button.pressed.connect(func() -> void: skip_requested.emit())
	actions.add_child(skip_button)

func set_accessibility(scale_value: float, use_high_contrast: bool) -> void:
	text_scale = scale_value
	high_contrast = use_high_contrast
	if not is_node_ready():
		return
	focus_label.add_theme_font_size_override("font_size", roundi(12.0 * text_scale))
	title_label.add_theme_font_size_override("font_size", roundi(20.0 * text_scale))
	progress_label.add_theme_font_size_override("font_size", roundi(13.0 * text_scale))
	body_label.add_theme_font_size_override("font_size", roundi(16.0 * text_scale))
	instruction_label.add_theme_font_size_override("font_size", roundi(14.0 * text_scale))
	skip_button.add_theme_font_size_override("font_size", roundi(14.0 * text_scale))
	body_label.custom_minimum_size.x = 380.0 if text_scale > 1.0 else 340.0
	popup.custom_minimum_size.x = 420.0 if text_scale > 1.0 else 380.0
	var popup_style := StyleBoxFlat.new()
	popup_style.bg_color = Color("07111c") if high_contrast else PANEL_COLOR
	popup_style.border_color = Color("67fff0") if high_contrast else Color("55c2b5")
	popup_style.set_border_width_all(3 if high_contrast else 2)
	popup_style.set_corner_radius_all(10)
	popup_style.set_content_margin_all(16)
	popup.add_theme_stylebox_override("panel", popup_style)
	for dimmer: ColorRect in dimmers:
		dimmer.color = Color(0.005, 0.01, 0.018, 0.88) if high_contrast else DIM_COLOR
	title_label.add_theme_color_override("font_color", Color("67fff0") if high_contrast else Color("55c2b5"))
	body_label.add_theme_color_override("font_color", Color.WHITE if high_contrast else Color("eaf1f5"))
	progress_label.add_theme_color_override("font_color", Color("d8e4ec") if high_contrast else Color("aebfca"))
	update_layout()

func present(target_control: Control, title_text: String, body_text: String, progress_text: String, is_informational: bool) -> void:
	target = target_control
	informational = is_informational
	title_label.text = title_text
	body_label.text = body_text
	progress_label.text = progress_text
	instruction_label.text = "Click the highlighted area to continue." if informational else "Use the highlighted control to continue."
	target_catcher.visible = informational
	show()
	move_to_front()
	update_layout()
	if informational:
		target_catcher.grab_focus()
	else:
		target.grab_focus()

func dismiss() -> void:
	target = null
	hide()

func _process(_delta: float) -> void:
	if visible:
		update_layout()

func update_layout() -> void:
	if target == null or not is_instance_valid(target) or not target.is_visible_in_tree():
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var global_rect: Rect2 = target.get_global_rect().grow(6.0)
	var hole := Rect2(global_rect.position - global_position, global_rect.size)
	hole.position.x = clampf(hole.position.x, 0.0, viewport_size.x)
	hole.position.y = clampf(hole.position.y, 0.0, viewport_size.y)
	hole.size.x = minf(hole.size.x, viewport_size.x - hole.position.x)
	hole.size.y = minf(hole.size.y, viewport_size.y - hole.position.y)
	set_control_rect(dimmers[0], Rect2(0.0, 0.0, viewport_size.x, maxf(0.0, hole.position.y)))
	set_control_rect(dimmers[1], Rect2(0.0, hole.end.y, viewport_size.x, maxf(0.0, viewport_size.y - hole.end.y)))
	set_control_rect(dimmers[2], Rect2(0.0, hole.position.y, maxf(0.0, hole.position.x), hole.size.y))
	set_control_rect(dimmers[3], Rect2(hole.end.x, hole.position.y, maxf(0.0, viewport_size.x - hole.end.x), hole.size.y))
	set_control_rect(highlight, hole)
	set_control_rect(target_catcher, hole)
	var focus_y: float = hole.position.y - 20.0 if hole.position.y >= 24.0 else hole.position.y + 4.0
	focus_label.position = Vector2(hole.position.x + 8.0, focus_y)
	position_popup(hole, viewport_size)

func position_popup(hole: Rect2, viewport_size: Vector2) -> void:
	var popup_size: Vector2 = popup.get_combined_minimum_size()
	popup_size.x = maxf(420.0 if text_scale > 1.0 else 380.0, popup_size.x)
	popup.size = popup_size
	var gap: float = 14.0
	var desired: Vector2
	if hole.end.x + gap + popup_size.x <= viewport_size.x - 12.0:
		desired = Vector2(hole.end.x + gap, hole.position.y)
	elif hole.position.x - gap - popup_size.x >= 12.0:
		desired = Vector2(hole.position.x - gap - popup_size.x, hole.position.y)
	elif hole.end.y + gap + popup_size.y <= viewport_size.y - 12.0:
		desired = Vector2(hole.position.x, hole.end.y + gap)
	else:
		desired = Vector2(hole.position.x, hole.position.y - gap - popup_size.y)
	desired.x = clampf(desired.x, 12.0, maxf(12.0, viewport_size.x - popup_size.x - 12.0))
	desired.y = clampf(desired.y, 12.0, maxf(12.0, viewport_size.y - popup_size.y - 12.0))
	popup.position = desired

func set_control_rect(control: Control, rect: Rect2) -> void:
	control.position = rect.position
	control.size = rect.size
