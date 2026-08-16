extends Control

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

var day_label: Label
var phase_label: Label
var budget_label: Label
var trust_label: Label
var capacity_label: Label
var instruction_label: Label
var reading_box: VBoxContainer
var network_box: VBoxContainer
var warning_box: VBoxContainer
var district_detail: Label
var event_log: TextEdit
var continue_button: Button
var hazard_option: OptionButton
var severity_option: OptionButton
var district_checks: Dictionary = {}
var modal_layer: Control

func _ready() -> void:
	hazards = ScenarioCatalog.hazards()
	districts = ScenarioCatalog.districts()
	scenarios = ScenarioCatalog.days()
	build_interface()
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

	var header := PanelContainer.new()
	header.add_theme_stylebox_override("panel", panel_style(COLOR_PANEL, 10))
	header.custom_minimum_size.y = 64
	page.add_child(header)
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 12)
	header.add_child(header_row)
	var title := make_label("STORM DESK", 23, COLOR_ACCENT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(title)
	day_label = make_label("DAY 1 / 3", 16, COLOR_TEXT)
	header_row.add_child(day_label)
	budget_label = make_label("BUDGET 30", 16, COLOR_TEXT)
	header_row.add_child(budget_label)
	trust_label = make_label("TRUST 50", 16, COLOR_TEXT)
	header_row.add_child(trust_label)
	capacity_label = make_label("CAPACITY 0", 16, COLOR_TEXT)
	header_row.add_child(capacity_label)
	var help_button := make_button("Rules / Help")
	help_button.pressed.connect(show_help)
	header_row.add_child(help_button)

	var status_panel := PanelContainer.new()
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

	var log_panel := PanelContainer.new()
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
	district_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(district_detail)
	return panel

func build_readings_panel() -> Control:
	var panel := PanelContainer.new()
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
	panel.custom_minimum_size.x = 385
	panel.add_theme_stylebox_override("panel", panel_style(COLOR_PANEL, 8))
	var box := VBoxContainer.new()
	panel.add_child(box)
	box.add_child(make_label("NETWORK / WARNING DESK", 20, COLOR_ACCENT))
	network_box = VBoxContainer.new()
	network_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	network_box.add_theme_constant_override("separation", 8)
	box.add_child(network_box)
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
	set_phase(Phase.MORNING_BRIEFING)
	show_modal(
		"MORNING BRIEFING — DAY %d" % int(scenario["day"]),
		"%s\n\n%s" % [str(scenario["briefing"]), str(scenario["tutorial"])],
		"Begin observations",
		func() -> void: set_phase(Phase.OBSERVATION)
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
	network_box.visible = phase != Phase.WARNING_DECISION and phase != Phase.WARNING_CONFIRMATION
	warning_box.visible = phase == Phase.WARNING_DECISION or phase == Phase.WARNING_CONFIRMATION
	refresh_all()

func refresh_all() -> void:
	day_label.text = "DAY %d / 3" % int(scenario.get("day", 1))
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
	if phase == Phase.OBSERVATION:
		network_box.add_child(make_label("Network controls unlock after the initial instrument review.", 15, COLOR_MUTED))
		return
	var actions: Array = scenario.get("actions", []) as Array
	if actions.is_empty():
		network_box.add_child(make_label("No remote request is needed today. All essential evidence is already available.", 15, COLOR_MUTED))
		return
	var capacity: int = int(scenario["capacity"])
	network_box.add_child(make_label("Each request uses 1 capacity and delays warning preparation.", 15, COLOR_MUTED))
	for action: Dictionary in actions:
		var button := make_button("%s  —  cost %d" % [str(action["label"]), int(action["cost"])])
		button.disabled = phase != Phase.NETWORK_PLANNING or observations_used >= capacity or bool(action.get("used", false)) or budget < int(action["cost"])
		if bool(action.get("used", false)):
			button.text = "%s  —  RECEIVED" % str(action["label"])
		button.pressed.connect(request_observation.bind(action))
		network_box.add_child(button)
	if observations_used >= capacity:
		network_box.add_child(make_label("CAPACITY EXHAUSTED — remaining requests are unavailable.", 14, COLOR_WARNING))

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
	action["used"] = true
	observations_used += 1
	observation_spend += cost
	budget -= cost
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
	if trust >= 58 and total_damage <= 35:
		rating = "Trusted island forecaster"
	elif trust >= 45:
		rating = "Steady desk operator"
	var body := "%s\n\nFinal trust: %d   Final budget: %d\nCorrect hazard calls: %d / 3\nDistricts protected: %d\nTotal damage: %d\n\n%s\n\nRestart resets all deterministic scenarios without closing the application." % [rating, trust, budget, correct_days, protected, total_damage, "\n".join(lines)]
	show_modal("THREE-DAY PERFORMANCE REPORT", body, "Restart prototype", restart_session)

func on_hazard_selected(index: int) -> void:
	selected_hazard = StringName(hazard_option.get_item_metadata(index))
	severity_option.disabled = selected_hazard == &""
	for check: CheckBox in district_checks.values():
		check.disabled = selected_hazard == &""
		if selected_hazard == &"":
			check.set_pressed_no_signal(false)
	if selected_hazard == &"":
		warned_districts.clear()

func on_district_toggled(enabled: bool, district_id: StringName) -> void:
	if enabled and not warned_districts.has(district_id):
		warned_districts.append(district_id)
	elif not enabled:
		warned_districts.erase(district_id)

func show_district(district: DistrictDefinition) -> void:
	district_detail.text = "%s\n\n%s\n\nVulnerability multipliers\nSparkstorm %.1fx  /  Glasswind %.1fx  /  Cloudburst %.1fx" % [district.display_name, district.description, district.vulnerability_for(&"sparkstorm"), district.vulnerability_for(&"glasswind"), district.vulnerability_for(&"cloudburst")]
	log_event("Map selected: %s" % district.display_name)

func show_help() -> void:
	var lines: Array[String] = []
	for hazard: HazardDefinition in hazards:
		lines.append("%s\nEvidence: %s\nThreat: %s" % [hazard.display_name, hazard.evidence_summary, hazard.threat_summary])
	var body := "FICTIONAL WEATHER RULES\n\n%s\n\nDAILY LOOP\nBriefing → Observation → Network Planning → Warning → Resolution. Network requests cost budget and capacity. On Day 3, a second request makes the warning late.\n\nWarnings require a hazard, severity, and districts. False warnings cost trust; useful timely warnings reduce damage. Missing a threatened district causes full damage." % "\n\n".join(lines)
	show_modal("RULES / HELP", body, "Close", func() -> void: pass)

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
