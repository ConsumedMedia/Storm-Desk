extends Control

signal phase_changed(phase_value: int)
signal district_inspected
signal hazard_selection_made
signal district_warning_changed

enum Phase { MORNING_BRIEFING, OBSERVATION, NETWORK_PLANNING, WARNING_DECISION, WARNING_CONFIRMATION, STORM_RESOLUTION, DAILY_REPORT, FINAL_REPORT }

const COLOR_BG := Color("101925")
const COLOR_PANEL := Color("1a2a3a")
const COLOR_PANEL_ALT := Color("22384a")
const COLOR_ACCENT := Color("55c2b5")
const COLOR_WARNING := Color("f0b45a")
const COLOR_TEXT := Color("eaf1f5")
const COLOR_MUTED := Color("aebfca")

var hazards: Array[HazardDefinition] = []
var districts: Array[DistrictDefinition] = []
var scenarios: Array[Dictionary] = []
var network_model: NetworkModel
var scenario: Dictionary = {}
var readings: Array[Dictionary] = []
var day_index: int = 0
var phase: Phase = Phase.MORNING_BRIEFING
var budget: int = 30
var trust: int = 50
var observations_used: int = 0
var observation_spend: int = 0
var selected_hazard: StringName = &""
var selected_severity: int = 2
var warned_districts: Array[StringName] = []
var reports: Array[Dictionary] = []
var tutorial_controller: TutorialController

var header_panel: PanelContainer
var status_panel: PanelContainer
var map_panel: PanelContainer
var readings_panel: PanelContainer
var actions_panel: PanelContainer
var log_panel: PanelContainer
var day_label: Label
var phase_label: Label
var budget_label: Label
var trust_label: Label
var capacity_label: Label
var instruction_label: Label
var reading_box: VBoxContainer
var network_scroll: ScrollContainer
var network_box: VBoxContainer
var warning_box: VBoxContainer
var selected_network_site: StringName = &"ridge"
var district_detail: Label
var event_log: TextEdit
var continue_button: Button
var help_button: Button
var hazard_option: OptionButton
var severity_option: OptionButton
var district_checks: Dictionary = {}
var modal_layer: Control

func _ready() -> void:
	hazards = ScenarioCatalog.hazards()
	districts = ScenarioCatalog.districts()
	scenarios = ScenarioCatalog.days()
	network_model = NetworkModel.new()
	build_interface()
	tutorial_controller = TutorialController.new()
	add_child(tutorial_controller)
	tutorial_controller.setup(self, tutorial_target)
	restart_session()

func build_interface() -> void:
	var background := ColorRect.new()
	background.color = COLOR_BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)

	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 10)
	margin.add_child(page)

	header_panel = PanelContainer.new()
	header_panel.add_theme_stylebox_override("panel", panel_style(COLOR_PANEL, 10))
	header_panel.custom_minimum_size.y = 64
	page.add_child(header_panel)
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 12)
	header_panel.add_child(header_row)
	var title := make_label("STORM DESK", 23, COLOR_ACCENT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(title)
	day_label = make_label("DAY 1 / 5", 16, COLOR_TEXT)
	header_row.add_child(day_label)
	budget_label = make_label("BUDGET 30", 16, COLOR_TEXT)
	header_row.add_child(budget_label)
	trust_label = make_label("TRUST 50", 16, COLOR_TEXT)
	header_row.add_child(trust_label)
	capacity_label = make_label("CAPACITY 0", 16, COLOR_TEXT)
	header_row.add_child(capacity_label)
	help_button = make_button("Rules / Help")
	help_button.pressed.connect(show_help)
	header_row.add_child(help_button)

	status_panel = PanelContainer.new()
	status_panel.add_theme_stylebox_override("panel", panel_style(COLOR_PANEL_ALT, 8))
	page.add_child(status_panel)
	var status_row := HBoxContainer.new()
	status_panel.add_child(status_row)
	phase_label = make_label("PHASE", 17, COLOR_WARNING)
	phase_label.custom_minimum_size.x = 230
	status_row.add_child(phase_label)
	instruction_label = make_label("", 16, COLOR_TEXT)
	instruction_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_row.add_child(instruction_label)

	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 10)
	page.add_child(columns)
	columns.add_child(build_map_panel())
	columns.add_child(build_readings_panel())
	columns.add_child(build_actions_panel())

	log_panel = PanelContainer.new()
	log_panel.custom_minimum_size.y = 112
	log_panel.add_theme_stylebox_override("panel", panel_style(COLOR_PANEL, 8))
	page.add_child(log_panel)
	event_log = TextEdit.new()
	event_log.editable = false
	event_log.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	event_log.add_theme_font_size_override("font_size", 14)
	event_log.add_theme_color_override("font_readonly_color", COLOR_MUTED)
	event_log.placeholder_text = "Operations log"
	log_panel.add_child(event_log)

	var footer := HBoxContainer.new()
	page.add_child(footer)
	var change_note := make_label("Choices remain editable until you confirm a warning.", 14, COLOR_MUTED)
	change_note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(change_note)
	continue_button = make_button("Continue")
	continue_button.custom_minimum_size = Vector2(240, 44)
	continue_button.pressed.connect(on_continue_pressed)
	footer.add_child(continue_button)

	modal_layer = Control.new()
	modal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(modal_layer)

func build_map_panel() -> Control:
	var panel := PanelContainer.new()
	map_panel = panel
	panel.custom_minimum_size.x = 335
	panel.add_theme_stylebox_override("panel", panel_style(COLOR_PANEL, 8))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	panel.add_child(box)
	box.add_child(make_label("REGIONAL MAP", 20, COLOR_ACCENT))
	box.add_child(make_label("WESTERN FRONT  →  INHABITED ISLANDS", 13, COLOR_MUTED))
	for district: DistrictDefinition in districts:
		var button := make_button("◆  %s" % district.display_name)
		button.custom_minimum_size.y = 58
		button.tooltip_text = district.description
		button.pressed.connect(show_district.bind(district))
		box.add_child(button)
	district_detail = make_label("Select a district for vulnerability details.", 14, COLOR_MUTED)
	district_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	district_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var detail_scroll := ScrollContainer.new()
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_scroll.add_child(district_detail)
	box.add_child(detail_scroll)
	return panel

func build_readings_panel() -> Control:
	var panel := PanelContainer.new()
	readings_panel = panel
	panel.custom_minimum_size.x = 420
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", panel_style(COLOR_PANEL, 8))
	var box := VBoxContainer.new()
	panel.add_child(box)
	box.add_child(make_label("INSTRUMENT READINGS", 20, COLOR_ACCENT))
	var subtitle := make_label("Quality tags: CLEAR / MISSING / IMPRECISE / SUSPECT", 13, COLOR_MUTED)
	box.add_child(subtitle)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	reading_box = VBoxContainer.new()
	reading_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reading_box.add_theme_constant_override("separation", 7)
	scroll.add_child(reading_box)
	return panel

func build_actions_panel() -> Control:
	var panel := PanelContainer.new()
	actions_panel = panel
	panel.custom_minimum_size.x = 385
	panel.add_theme_stylebox_override("panel", panel_style(COLOR_PANEL, 8))
	var box := VBoxContainer.new()
	panel.add_child(box)
	box.add_child(make_label("NETWORK / WARNING DESK", 20, COLOR_ACCENT))
	network_scroll = ScrollContainer.new()
	network_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	network_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(network_scroll)
	network_box = VBoxContainer.new()
	network_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	network_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	network_box.add_theme_constant_override("separation", 8)
	network_scroll.add_child(network_box)
	warning_box = VBoxContainer.new()
	warning_box.visible = false
	warning_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	warning_box.add_theme_constant_override("separation", 8)
	box.add_child(warning_box)
	build_warning_controls()
	return panel

func build_warning_controls() -> void:
	warning_box.add_child(make_label("Hazard classification", 15, COLOR_MUTED))
	hazard_option = OptionButton.new()
	hazard_option.add_theme_font_size_override("font_size", 16)
	hazard_option.add_item("No warning / stand down")
	hazard_option.set_item_metadata(0, &"")
	for hazard: HazardDefinition in hazards:
		hazard_option.add_item(hazard.display_name)
		hazard_option.set_item_metadata(hazard_option.item_count - 1, hazard.id)
	hazard_option.item_selected.connect(on_hazard_selected)
	warning_box.add_child(hazard_option)
	warning_box.add_child(make_label("Declared severity", 15, COLOR_MUTED))
	severity_option = OptionButton.new()
	for severity: int in [1, 2, 3]:
		severity_option.add_item("Level %d" % severity)
		severity_option.set_item_metadata(severity_option.item_count - 1, severity)
	severity_option.select(1)
	severity_option.item_selected.connect(func(index: int) -> void: selected_severity = int(severity_option.get_item_metadata(index)))
	warning_box.add_child(severity_option)
	warning_box.add_child(make_label("Districts to warn", 15, COLOR_MUTED))
	for district: DistrictDefinition in districts:
		var check := CheckBox.new()
		check.text = district.display_name
		check.add_theme_font_size_override("font_size", 16)
		check.toggled.connect(on_district_toggled.bind(district.id))
		district_checks[district.id] = check
		warning_box.add_child(check)

func restart_session() -> void:
	budget = 30
	trust = 50
	day_index = 0
	selected_network_site = &"ridge"
	network_model.reset()
	reports.clear()
	event_log.text = ""
	load_day()

func load_day() -> void:
	scenario = scenarios[day_index].duplicate(true)
	readings.clear()
	for item: Dictionary in scenario["readings"]:
		readings.append(item.duplicate(true))
	observations_used = 0
	observation_spend = 0
	selected_hazard = &""
	selected_severity = 2
	warned_districts.clear()
	hazard_option.select(0)
	severity_option.select(1)
	for check: CheckBox in district_checks.values():
		check.set_pressed_no_signal(false)
	on_hazard_selected(0)
	log_event("Day %d opened: %s" % [int(scenario["day"]), str(scenario["title"])])
	var opening_damage: Array = scenario.get("opening_damage", []) as Array
	for event: String in network_model.apply_opening_damage(opening_damage):
		log_event(event)
	set_phase(Phase.MORNING_BRIEFING)
	show_modal(
		"MORNING BRIEFING — DAY %d" % int(scenario["day"]),
		"%s\n\n%s" % [str(scenario["briefing"]), str(scenario["tutorial"])],
		"Begin observations",
		begin_observations
	)

func begin_observations() -> void:
	set_phase(Phase.OBSERVATION)
	if day_index == 0 and tutorial_controller.should_offer():
		show_modal(
			"WELCOME TO STORM DESK",
			"A short guided tour can introduce the bureau interface while you perform the real Day One flow. It highlights one required area at a time and never chooses a warning for you.\n\nYou can skip it now or replay it later from Rules / Help.",
			"Start guided tour",
			tutorial_controller.start,
			"Skip tour",
			tutorial_controller.skip_permanently
		)

func set_phase(next_phase: Phase) -> void:
	phase = next_phase
	var phase_names: Dictionary = {
		Phase.MORNING_BRIEFING: "MORNING BRIEFING",
		Phase.OBSERVATION: "OBSERVATION",
		Phase.NETWORK_PLANNING: "NETWORK PLANNING",
		Phase.WARNING_DECISION: "WARNING DECISION",
		Phase.WARNING_CONFIRMATION: "WARNING CONFIRMATION",
		Phase.STORM_RESOLUTION: "STORM RESOLUTION",
		Phase.DAILY_REPORT: "DAILY REPORT",
		Phase.FINAL_REPORT: "FINAL REPORT",
	}
	phase_label.text = "PHASE  /  %s" % str(phase_names[phase])
	match phase:
		Phase.MORNING_BRIEFING:
			instruction_label.text = "Required: read the briefing."
			continue_button.text = "Briefing open"
			continue_button.disabled = true
		Phase.OBSERVATION:
			instruction_label.text = "Required: inspect the available evidence, then continue."
			continue_button.text = "Plan network use"
			continue_button.disabled = false
		Phase.NETWORK_PLANNING:
			instruction_label.text = "Optional: buy observations. Required: decide when evidence is sufficient."
			continue_button.text = "Proceed to warning desk"
			continue_button.disabled = false
		Phase.WARNING_DECISION:
			instruction_label.text = "Required: classify the hazard, severity, and districts—or explicitly stand down."
			continue_button.text = "Review warning"
			continue_button.disabled = false
		Phase.WARNING_CONFIRMATION:
			instruction_label.text = "Required: confirm or return to edit."
			continue_button.disabled = true
		Phase.STORM_RESOLUTION:
			instruction_label.text = "The actual weather is being resolved."
			continue_button.disabled = true
		_:
			continue_button.disabled = true
	network_scroll.visible = phase != Phase.WARNING_DECISION and phase != Phase.WARNING_CONFIRMATION
	warning_box.visible = phase == Phase.WARNING_DECISION or phase == Phase.WARNING_CONFIRMATION
	refresh_all()
	phase_changed.emit(int(phase))

func refresh_all() -> void:
	day_label.text = "DAY %d / %d" % [int(scenario.get("day", 1)), scenarios.size()]
	budget_label.text = "BUDGET %d" % budget
	trust_label.text = "TRUST %d" % trust
	var capacity: int = int(scenario.get("capacity", 0))
	capacity_label.text = "CAPACITY %d / %d" % [maxi(0, capacity - observations_used), capacity]
	refresh_readings()
	refresh_network_actions()

func refresh_readings() -> void:
	clear_children(reading_box)
	for reading: Dictionary in readings:
		if not bool(reading.get("visible", false)):
			continue
		var quality: String = str(reading.get("quality", "clear"))
		var tag: String = quality.to_upper()
		if quality == "faulty":
			tag = "SUSPECT"
		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", panel_style(COLOR_PANEL_ALT, 5))
		var row_box := VBoxContainer.new()
		row.add_child(row_box)
		row_box.add_child(make_label("%s  [%s]" % [str(reading.get("instrument", "Instrument")), tag], 14, COLOR_WARNING if quality != "clear" else COLOR_MUTED))
		row_box.add_child(make_label(str(reading.get("value", "No reading")), 17, COLOR_TEXT))
		reading_box.add_child(row)

func refresh_network_actions() -> void:
	clear_children(network_box)
	var diagram := NetworkDiagram.new()
	diagram.set_model(network_model)
	diagram.set_selected_site(selected_network_site)
	diagram.site_selected.connect(select_network_site)
	network_box.add_child(diagram)
	var site_selector := OptionButton.new()
	for site: Dictionary in network_model.sites:
		site_selector.add_item(str(site["label"]))
		site_selector.set_item_metadata(site_selector.item_count - 1, site["id"])
		if StringName(site["id"]) == selected_network_site:
			site_selector.select(site_selector.item_count - 1)
	site_selector.item_selected.connect(func(index: int) -> void: select_network_site(StringName(site_selector.get_item_metadata(index))))
	network_box.add_child(site_selector)
	network_box.add_child(make_wrapped_label(network_model.status_text(selected_network_site), 14, COLOR_MUTED))
	if phase == Phase.OBSERVATION:
		network_box.add_child(make_wrapped_label("Network controls unlock after the initial instrument review.", 15, COLOR_MUTED))
		return
	var capacity: int = int(scenario.get("capacity", 0))
	var no_capacity: bool = observations_used >= capacity
	var equipment_selector := OptionButton.new()
	equipment_selector.add_item("Relay — cost 5")
	equipment_selector.set_item_metadata(0, &"relay")
	for sensor_type: StringName in [&"electrical", &"crystal", &"moisture"]:
		equipment_selector.add_item("%s — cost 4" % str(NetworkModel.SENSOR_LABELS[sensor_type]))
		equipment_selector.set_item_metadata(equipment_selector.item_count - 1, sensor_type)
	network_box.add_child(equipment_selector)
	var install_button := make_button("Install selected equipment")
	install_button.disabled = phase != Phase.NETWORK_PLANNING or no_capacity or selected_network_site == &"hq" or budget < 4
	install_button.pressed.connect(install_network_equipment.bind(equipment_selector))
	network_box.add_child(install_button)
	var repair_button := make_button("Repair selected site — cost 3")
	repair_button.disabled = phase != Phase.NETWORK_PLANNING or no_capacity or not network_model.has_damage(selected_network_site) or budget < 3
	repair_button.pressed.connect(repair_selected_site)
	network_box.add_child(repair_button)
	var collect_button := make_button("Collect connected readings — cost 1")
	collect_button.disabled = phase != Phase.NETWORK_PLANNING or no_capacity or not has_collectable_network_reading() or budget < 1
	collect_button.pressed.connect(collect_connected_readings)
	network_box.add_child(collect_button)
	var actions: Array = scenario.get("actions", []) as Array
	if actions.is_empty() and capacity == 0:
		network_box.add_child(make_wrapped_label("No remote request is needed today. All essential evidence is already available.", 15, COLOR_MUTED))
		return
	network_box.add_child(make_wrapped_label("Each installation, repair, collection, or survey uses 1 capacity and delays warning preparation.", 15, COLOR_MUTED))
	for action: Dictionary in actions:
		var button := make_button("%s  —  cost %d" % [str(action["label"]), int(action["cost"])])
		var required_relay: StringName = StringName(action.get("requires_relay", &""))
		var relay_unavailable: bool = required_relay != &"" and not network_model.online_relays().has(required_relay)
		button.disabled = phase != Phase.NETWORK_PLANNING or no_capacity or bool(action.get("used", false)) or budget < int(action["cost"]) or relay_unavailable
		if relay_unavailable:
			button.tooltip_text = "%s relay is offline." % network_model.site_label(required_relay)
		if bool(action.get("used", false)):
			button.text = "%s  —  RECEIVED" % str(action["label"])
		button.pressed.connect(request_observation.bind(action))
		network_box.add_child(button)
	if observations_used >= capacity:
		network_box.add_child(make_wrapped_label("CAPACITY EXHAUSTED — remaining requests are unavailable.", 14, COLOR_WARNING))

func select_network_site(site_id: StringName) -> void:
	selected_network_site = site_id
	log_event("Network site selected: %s" % network_model.site_label(site_id))
	refresh_network_actions()

func install_network_equipment(selector: OptionButton) -> void:
	if not can_take_network_action():
		return
	var equipment_type: StringName = StringName(selector.get_item_metadata(selector.selected))
	var cost: int = 5 if equipment_type == &"relay" else 4
	if budget < cost:
		log_event("Installation rejected: insufficient budget (cost %d)." % cost)
		return
	var error_message: String
	if equipment_type == &"relay":
		error_message = network_model.install_relay(selected_network_site)
	else:
		error_message = network_model.install_sensor(selected_network_site, equipment_type)
	if not error_message.is_empty():
		log_event("Installation rejected: %s" % error_message)
		return
	consume_network_action(cost)
	if equipment_type == &"relay":
		log_event("Installed a relay at %s." % network_model.site_label(selected_network_site))
		reveal_network_readings()
	else:
		log_event("Installed a %s at %s." % [NetworkModel.SENSOR_LABELS[equipment_type], network_model.site_label(selected_network_site)])
		reveal_network_readings(selected_network_site, equipment_type)
	refresh_all()

func repair_selected_site() -> void:
	if not can_take_network_action():
		return
	if budget < 3:
		log_event("Repair rejected: insufficient budget (cost 3).")
		return
	var repair_message: String = network_model.repair_site(selected_network_site)
	if repair_message.begins_with("No damaged") or repair_message.begins_with("Unknown"):
		log_event("Repair rejected: %s" % repair_message)
		return
	consume_network_action(3)
	log_event(repair_message)
	reveal_network_readings()
	refresh_all()

func collect_connected_readings() -> void:
	if not can_take_network_action():
		return
	if not has_collectable_network_reading():
		log_event("Collection rejected: no unread connected sensor has relevant evidence today.")
		return
	if budget < 1:
		log_event("Collection rejected: insufficient budget (cost 1).")
		return
	consume_network_action(1)
	var revealed: int = reveal_network_readings()
	log_event("Collected %d connected network reading%s." % [revealed, "" if revealed == 1 else "s"])
	refresh_all()

func can_take_network_action() -> bool:
	if phase != Phase.NETWORK_PLANNING:
		log_event("Action rejected: network changes are only available during Network Planning.")
		return false
	if observations_used >= int(scenario.get("capacity", 0)):
		log_event("Action rejected: no observation capacity remains.")
		return false
	return true

func consume_network_action(cost: int) -> void:
	observations_used += 1
	observation_spend += cost
	budget -= cost

func has_collectable_network_reading() -> bool:
	for reading: Dictionary in readings:
		if str(reading.get("quality", "missing")) != "missing" or not reading.has("network_sensor"):
			continue
		if network_model.has_online_sensor(StringName(reading["network_site"]), StringName(reading["network_sensor"])):
			return true
	return false

func reveal_network_readings(site_filter: StringName = &"", sensor_filter: StringName = &"") -> int:
	var revealed: int = 0
	for reading: Dictionary in readings:
		if str(reading.get("quality", "missing")) != "missing" or not reading.has("network_sensor"):
			continue
		var site_id: StringName = StringName(reading["network_site"])
		var sensor_type: StringName = StringName(reading["network_sensor"])
		if site_filter != &"" and site_id != site_filter:
			continue
		if sensor_filter != &"" and sensor_type != sensor_filter:
			continue
		if not network_model.has_online_sensor(site_id, sensor_type):
			continue
		reading["value"] = reading["network_value"]
		reading["quality"] = reading["network_quality"]
		revealed += 1
		log_event("%s delivered: %s" % [network_model.site_label(site_id), str(reading["network_value"])])
	return revealed

func request_observation(action: Dictionary) -> void:
	if phase != Phase.NETWORK_PLANNING:
		log_event("Request rejected: network actions are only available during Network Planning.")
		return
	if observations_used >= int(scenario["capacity"]):
		log_event("Request rejected: no observation capacity remains.")
		return
	var cost: int = int(action["cost"])
	if budget < cost:
		log_event("Request rejected: insufficient budget (cost %d)." % cost)
		return
	var required_relay: StringName = StringName(action.get("requires_relay", &""))
	if required_relay != &"" and not network_model.online_relays().has(required_relay):
		log_event("Request rejected: %s relay is offline." % network_model.site_label(required_relay))
		return
	action["used"] = true
	consume_network_action(cost)
	var reveal_id: StringName = StringName(action["reveals"])
	var found: bool = false
	for reading: Dictionary in readings:
		if StringName(reading["id"]) == reveal_id:
			reading["visible"] = true
			reading["value"] = action["value"]
			reading["quality"] = action["quality"]
			found = true
			break
	if not found:
		readings.append({"id": reveal_id, "instrument": "Remote Network", "value": action["value"], "quality": action["quality"], "supports": action.get("supports", scenario["hazard"]), "visible": true, "faulty": false})
	log_event(str(action["log"]))
	refresh_all()

func on_continue_pressed() -> void:
	match phase:
		Phase.OBSERVATION:
			set_phase(Phase.NETWORK_PLANNING)
		Phase.NETWORK_PLANNING:
			set_phase(Phase.WARNING_DECISION)
		Phase.WARNING_DECISION:
			show_warning_confirmation()

func show_warning_confirmation() -> void:
	set_phase(Phase.WARNING_CONFIRMATION)
	var hazard_name: String = "NO WARNING"
	for hazard: HazardDefinition in hazards:
		if hazard.id == selected_hazard:
			hazard_name = hazard.display_name
	var district_names: Array[String] = []
	for district: DistrictDefinition in districts:
		if warned_districts.has(district.id):
			district_names.append(district.display_name)
	var summary: String
	if selected_hazard == &"":
		summary = "Stand down with no warning. Any actual threats will be unprotected."
	else:
		summary = "%s — Level %d\nWarn: %s\n\nWarning operations cost %d budget. After confirmation, this choice cannot be changed." % [hazard_name, selected_severity, ", ".join(district_names) if not district_names.is_empty() else "no districts", warned_districts.size() * 2]
	show_modal("CONFIRM WARNING", summary, "Confirm and resolve", confirm_warning, "Return to edit", func() -> void: set_phase(Phase.WARNING_DECISION))

func confirm_warning() -> void:
	set_phase(Phase.STORM_RESOLUTION)
	var result: Dictionary = OutcomeCalculator.calculate(scenario, districts, selected_hazard, selected_severity, warned_districts, observations_used, observation_spend)
	var network_events: Array[String] = network_model.resolve_hazard(StringName(scenario["hazard"]), selected_hazard, warned_districts, bool(result["late"]))
	var calculation_lines: Array = result["lines"] as Array
	for event: String in network_events:
		calculation_lines.append(event)
	result["network_events"] = network_events
	trust = maxi(0, trust + int(result["trust_delta"]))
	# Observation spend was paid immediately, so apply the remainder of the daily result here.
	budget += int(result["budget_delta"]) + observation_spend
	var report: Dictionary = result.duplicate(true)
	report["day"] = int(scenario["day"])
	report["hazard"] = scenario["hazard"]
	reports.append(report)
	show_daily_report(result)

func show_daily_report(result: Dictionary) -> void:
	set_phase(Phase.DAILY_REPORT)
	var actual: HazardDefinition = hazard_by_id(StringName(scenario["hazard"]))
	var body: String = "ACTUAL WEATHER: %s — Level %d\n%s\n\n%s\n\n" % [actual.display_name, int(scenario["severity"]), str(scenario["outcome_note"]), "WARNING TIMING: LATE" if bool(result["late"]) else "WARNING TIMING: TIMELY"]
	body += "Damage: %d   Protected: %d   Missed: %d   False warnings: %d\nTrust: %+d → %d   Budget: %+d → %d\n\nCALCULATION\n• %s" % [int(result["damage"]), int(result["protected"]), int(result["missed"]), int(result["false_warnings"]), int(result["trust_delta"]), trust, int(result["budget_delta"]), budget, "\n• ".join(result["lines"])]
	var final_day: bool = day_index >= scenarios.size() - 1
	show_modal("DAY %d REPORT" % int(scenario["day"]), body, "View final report" if final_day else "Continue to next day", show_final_report if final_day else advance_day)

func advance_day() -> void:
	day_index += 1
	load_day()

func show_final_report() -> void:
	set_phase(Phase.FINAL_REPORT)
	var total_damage: int = 0
	var correct_days: int = 0
	var protected: int = 0
	var lines: Array[String] = []
	for report: Dictionary in reports:
		total_damage += int(report["damage"])
		protected += int(report["protected"])
		if bool(report["correct_hazard"]):
			correct_days += 1
		lines.append("Day %d: damage %d, trust %+d, budget %+d%s" % [int(report["day"]), int(report["damage"]), int(report["trust_delta"]), int(report["budget_delta"]), ", late warning" if bool(report["late"]) else ""])
	var rating: String = "Bureau in recovery"
	if trust >= 70 and total_damage <= 90:
		rating = "Trusted island forecaster"
	elif trust >= 50:
		rating = "Steady desk operator"
	var body := "%s\n\nFinal trust: %d   Final budget: %d\nCorrect hazard calls: %d / %d\nDistricts protected: %d\nTotal damage: %d\n\n%s\n\nFINAL NETWORK\n%s\n\nRestart resets all deterministic scenarios and network construction without closing the application." % [rating, trust, budget, correct_days, scenarios.size(), protected, total_damage, "\n".join(lines), network_model.summary()]
	show_modal("FIVE-DAY PERFORMANCE REPORT", body, "Restart first week", restart_session)

func on_hazard_selected(index: int) -> void:
	selected_hazard = StringName(hazard_option.get_item_metadata(index))
	severity_option.disabled = selected_hazard == &""
	for check: CheckBox in district_checks.values():
		check.disabled = selected_hazard == &""
		if selected_hazard == &"":
			check.set_pressed_no_signal(false)
	if selected_hazard == &"":
		warned_districts.clear()
	hazard_selection_made.emit()

func on_district_toggled(enabled: bool, district_id: StringName) -> void:
	if enabled and not warned_districts.has(district_id):
		warned_districts.append(district_id)
	elif not enabled:
		warned_districts.erase(district_id)
	district_warning_changed.emit()

func show_district(district: DistrictDefinition) -> void:
	district_detail.text = "%s\n\n%s\n\nVulnerability multipliers\nSparkstorm %.1fx  /  Glasswind %.1fx  /  Cloudburst %.1fx" % [district.display_name, district.description, district.vulnerability_for(&"sparkstorm"), district.vulnerability_for(&"glasswind"), district.vulnerability_for(&"cloudburst")]
	log_event("Map selected: %s" % district.display_name)
	district_inspected.emit()

func show_help() -> void:
	var lines: Array[String] = []
	for hazard: HazardDefinition in hazards:
		lines.append("%s\nEvidence: %s\nThreat: %s" % [hazard.display_name, hazard.evidence_summary, hazard.threat_summary])
	var body := "FICTIONAL WEATHER RULES\n\n%s\n\nNETWORK\nSelect fixed sites on the diagram. HQ and healthy connected relays create a transmission path. Each site has one relay slot and one sensor slot. Installations, repairs, collections, and surveys cost budget and capacity; equipment persists between days and can be damaged by an unprotected hazard. R / R! marks healthy or damaged relays; E, C, and M mark sensor types.\n\nDAILY LOOP\nBriefing → Observation → Network Planning → Warning → Resolution. Each briefing states the day's capacity and whether taking a second action will make the warning late.\n\nWarnings require a hazard, severity, and districts. False warnings cost trust; useful timely warnings reduce damage. Missing a threatened district causes full damage.\n\nReplay Guided Tour resets to Day One when necessary; it does not preserve the current run." % "\n\n".join(lines)
	show_modal("RULES / HELP", body, "Close", func() -> void: pass, "Replay guided tour", replay_guided_tour)

func replay_guided_tour() -> void:
	tutorial_controller.reset_completion()
	if day_index == 0 and phase == Phase.OBSERVATION:
		tutorial_controller.start()
	else:
		restart_session()

func tutorial_target(target_id: StringName) -> Control:
	match target_id:
		&"header":
			return header_panel
		&"district_map":
			return map_panel
		&"readings":
			return readings_panel
		&"help":
			return help_button
		&"event_log":
			return log_panel
		&"continue":
			return continue_button
		&"network":
			return actions_panel
		&"hazard":
			return hazard_option
		&"severity":
			return severity_option
		&"warning_districts":
			return warning_box
	return null

func show_modal(title_text: String, body_text: String, primary_text: String, primary_action: Callable, secondary_text: String = "", secondary_action: Callable = Callable()) -> void:
	clear_children(modal_layer)
	modal_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	var scrim := ColorRect.new()
	scrim.color = Color(0.02, 0.04, 0.07, 0.82)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_layer.add_child(scrim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_layer.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(800, 430)
	panel.add_theme_stylebox_override("panel", panel_style(COLOR_PANEL_ALT, 14, 22))
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)
	box.add_child(make_label(title_text, 25, COLOR_ACCENT))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 280
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	var body := make_label(body_text, 16, COLOR_TEXT)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size.x = 720
	scroll.add_child(body)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 10)
	box.add_child(actions)
	if not secondary_text.is_empty():
		var secondary := make_button(secondary_text)
		secondary.pressed.connect(func() -> void:
			close_modal()
			secondary_action.call()
		)
		actions.add_child(secondary)
	var primary := make_button(primary_text)
	primary.custom_minimum_size.x = 210
	primary.pressed.connect(func() -> void:
		close_modal()
		primary_action.call()
	)
	actions.add_child(primary)

func close_modal() -> void:
	clear_children(modal_layer)
	modal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE

func log_event(message: String) -> void:
	if event_log.text.is_empty():
		event_log.text = "OPERATIONS LOG\n• %s" % message
	else:
		event_log.text += "\n• %s" % message
	event_log.scroll_vertical = 99999

func hazard_by_id(id: StringName) -> HazardDefinition:
	for hazard: HazardDefinition in hazards:
		if hazard.id == id:
			return hazard
	return hazards[0]

func make_label(text_value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

func make_wrapped_label(text_value: String, size: int, color: Color) -> Label:
	var label := make_label(text_value, size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label

func make_button(text_value: String) -> Button:
	var button := Button.new()
	button.text = text_value
	button.add_theme_font_size_override("font_size", 15)
	button.focus_mode = Control.FOCUS_ALL
	return button

func panel_style(color: Color, radius: int, padding: int = 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding
	style.content_margin_bottom = padding
	return style

func clear_children(node: Node) -> void:
	for child: Node in node.get_children():
		child.queue_free()
