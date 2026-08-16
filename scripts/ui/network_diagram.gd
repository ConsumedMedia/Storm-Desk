class_name NetworkDiagram
extends Control

signal site_selected(site_id: StringName)

var model: NetworkModel
var selected_site: StringName = &"ridge"
var text_scale: float = 1.0
var high_contrast: bool = false

func _ready() -> void:
	custom_minimum_size = Vector2(330, 165)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func set_model(value: NetworkModel) -> void:
	model = value
	queue_redraw()

func set_selected_site(site_id: StringName) -> void:
	selected_site = site_id
	queue_redraw()

func set_accessibility(scale_value: float, use_high_contrast: bool) -> void:
	text_scale = scale_value
	high_contrast = use_high_contrast
	custom_minimum_size.y = 175.0 if text_scale > 1.0 else 165.0
	queue_redraw()

func _draw() -> void:
	if model == null:
		return
	var online_color: Color = Color("67fff0") if high_contrast else Color("55c2b5")
	var offline_color: Color = Color("8da6b8") if high_contrast else Color("526575")
	var selected_color: Color = Color("ffd166") if high_contrast else Color("f0b45a")
	var legend_size: int = roundi(11.0 * text_scale)
	draw_line(Vector2(10.0, 12.0), Vector2(31.0, 12.0), online_color, 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(37.0, 16.0), "ONLINE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, legend_size, Color("eaf1f5") if high_contrast else Color("aebfca"))
	draw_line(Vector2(98.0, 12.0), Vector2(119.0, 12.0), Color("526575"), 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(125.0, 16.0), "OFFLINE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, legend_size, Color("eaf1f5") if high_contrast else Color("aebfca"))
	draw_arc(Vector2(213.0, 12.0), 7.0, 0.0, TAU, 20, selected_color, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(225.0, 16.0), "SELECTED", HORIZONTAL_ALIGNMENT_LEFT, -1.0, legend_size, Color("eaf1f5") if high_contrast else Color("aebfca"))
	var seen_edges: Dictionary = {}
	for site: Dictionary in model.sites:
		var from_id: StringName = StringName(site["id"])
		var from_pos: Vector2 = diagram_position(site)
		for neighbor_value: Variant in site["neighbors"]:
			var to_id: StringName = StringName(neighbor_value)
			var edge_key: String = "%s:%s" % [mini(str(from_id).hash(), str(to_id).hash()), maxi(str(from_id).hash(), str(to_id).hash())]
			if seen_edges.has(edge_key):
				continue
			seen_edges[edge_key] = true
			var to_site: Dictionary = model.site_by_id(to_id)
			var active: bool = model.is_site_covered(from_id) and model.is_site_covered(to_id)
			draw_line(from_pos, diagram_position(to_site), online_color if active else offline_color, 3.0 if active else 2.0)
	for site: Dictionary in model.sites:
		draw_site(site)

func draw_site(site: Dictionary) -> void:
	var site_id: StringName = StringName(site["id"])
	var position: Vector2 = diagram_position(site)
	var gear: Dictionary = model.equipment_at(site_id)
	var connected: bool = model.is_site_covered(site_id)
	var damaged: bool = model.has_damage(site_id)
	var fill: Color = Color("ff6680") if damaged and high_contrast else Color("8f4f5c") if damaged else Color("178f86") if connected and high_contrast else Color("2f7d78") if connected else Color("785463") if high_contrast else Color("5c4650")
	draw_circle(position, 17.0, fill)
	if site_id == selected_site:
		draw_arc(position, 22.0, 0.0, TAU, 32, Color("ffd166") if high_contrast else Color("f0b45a"), 3.0)
	var tag: String = str(site["short"])
	if bool(gear.get("relay", false)):
		tag += " R" if int(gear.get("relay_health", 0)) > 0 else " R!"
	var sensor: StringName = StringName(gear.get("sensor", &""))
	if sensor != &"":
		tag += " %s" % str(sensor).left(1).to_upper()
		if int(gear.get("sensor_health", 0)) <= 0:
			tag += "!"
	var label_offset := Vector2(-45, -24) if site_id == &"ridge" else Vector2(-45, 35)
	draw_string(ThemeDB.fallback_font, position + label_offset, tag, HORIZONTAL_ALIGNMENT_CENTER, 90.0, roundi(12.0 * text_scale), Color("ff8da1") if damaged and high_contrast else Color("e28a94") if damaged else Color.WHITE if high_contrast else Color("eaf1f5"))

func diagram_position(site: Dictionary) -> Vector2:
	var normalized: Vector2 = site.get("position", Vector2.ZERO) as Vector2
	return Vector2(20.0 + normalized.x * (size.x - 40.0), 32.0 + normalized.y * (size.y - 70.0))

func _gui_input(event: InputEvent) -> void:
	if model == null or not (event is InputEventMouseButton):
		return
	var click: InputEventMouseButton = event as InputEventMouseButton
	if not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	for site: Dictionary in model.sites:
		if diagram_position(site).distance_to(click.position) <= 24.0:
			selected_site = StringName(site["id"])
			queue_redraw()
			site_selected.emit(selected_site)
			accept_event()
			return
