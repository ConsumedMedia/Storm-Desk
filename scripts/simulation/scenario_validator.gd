class_name ScenarioValidator
extends RefCounted

const VALID_QUALITIES: Array[String] = ["clear", "missing", "imprecise", "faulty"]
const VALID_DAMAGE_COMPONENTS: Array[StringName] = [&"relay", &"sensor"]
const SCENARIO_DEFINITION_SCRIPT: Script = preload("res://scripts/simulation/scenario_definition.gd")

static func validate(definitions: Array[Resource], hazards: Array[HazardDefinition], districts: Array[DistrictDefinition]) -> Array[String]:
	var errors: Array[String] = []
	var hazard_ids: Array[StringName] = []
	for hazard: HazardDefinition in hazards:
		if hazard == null or hazard.id == &"":
			errors.append("Hazard catalog contains an invalid definition.")
			continue
		hazard_ids.append(hazard.id)
	var district_ids: Array[StringName] = []
	for district: DistrictDefinition in districts:
		if district == null or district.id == &"":
			errors.append("District catalog contains an invalid definition.")
			continue
		district_ids.append(district.id)
	var site_ids: Array[StringName] = []
	for site: Dictionary in NetworkModel.new().sites:
		site_ids.append(StringName(site.get("id", &"")))

	if definitions.is_empty():
		errors.append("Scenario catalog contains no days.")
		return errors

	var used_days: Dictionary = {}
	for index: int in definitions.size():
		var definition: Resource = definitions[index]
		if definition == null or definition.get_script() != SCENARIO_DEFINITION_SCRIPT:
			errors.append("Scenario %d is not a ScenarioDefinition resource." % [index + 1])
			continue
		var scenario: Dictionary = definition.call("to_runtime_dictionary") as Dictionary
		var day_number: int = int(scenario.get("day", 0))
		var prefix: String = "Day %d" % day_number if day_number > 0 else "Scenario %d" % [index + 1]
		if day_number != index + 1:
			errors.append("%s must be authored in sequential day order; expected day %d." % [prefix, index + 1])
		if used_days.has(day_number):
			errors.append("%s duplicates an existing day number." % prefix)
		used_days[day_number] = true
		validate_scenario(scenario, prefix, hazard_ids, district_ids, site_ids, hazards, errors)
	return errors

static func validate_scenario(scenario: Dictionary, prefix: String, hazard_ids: Array[StringName], district_ids: Array[StringName], site_ids: Array[StringName], hazards: Array[HazardDefinition], errors: Array[String]) -> void:
	for field: String in ["title", "briefing", "tutorial", "outcome_note"]:
		if str(scenario.get(field, "")).strip_edges().is_empty():
			errors.append("%s requires non-empty %s text." % [prefix, field])
	if int(scenario.get("day", 0)) > 1 and str(scenario.get("outlook", "")).strip_edges().is_empty():
		errors.append("%s requires an outlook for the preceding maintenance phase." % prefix)

	var actual_hazard: StringName = StringName(scenario.get("hazard", &""))
	if not hazard_ids.has(actual_hazard):
		errors.append("%s references unknown hazard '%s'." % [prefix, actual_hazard])
	var severity: int = int(scenario.get("severity", 0))
	if severity < 1 or severity > 3:
		errors.append("%s severity must be between 1 and 3." % prefix)
	var capacity: int = int(scenario.get("capacity", -1))
	var safe_actions: int = int(scenario.get("safe_actions", -1))
	if capacity < 0:
		errors.append("%s capacity cannot be negative." % prefix)
	if safe_actions < 0 or safe_actions > capacity:
		errors.append("%s safe_actions must be between zero and capacity." % prefix)

	var threatened_value: Variant = scenario.get("threatened", [])
	if not threatened_value is Array or (threatened_value as Array).is_empty():
		errors.append("%s must threaten at least one district." % prefix)
	else:
		var used_districts: Dictionary = {}
		for district_value: Variant in threatened_value as Array:
			var district_id: StringName = StringName(district_value)
			if not district_ids.has(district_id):
				errors.append("%s references unknown district '%s'." % [prefix, district_id])
			elif used_districts.has(district_id):
				errors.append("%s lists district '%s' more than once." % [prefix, district_id])
			used_districts[district_id] = true

	var readings_value: Variant = scenario.get("readings", [])
	var readings: Array = readings_value as Array if readings_value is Array else []
	if readings.is_empty():
		errors.append("%s must contain at least one instrument reading." % prefix)
	var reading_ids: Dictionary = {}
	for index: int in readings.size():
		var reading_value: Variant = readings[index]
		if not reading_value is Dictionary:
			errors.append("%s reading %d must be a Dictionary." % [prefix, index + 1])
			continue
		validate_reading(reading_value as Dictionary, prefix, index, hazard_ids, site_ids, reading_ids, errors)

	var actions_value: Variant = scenario.get("actions", [])
	var actions: Array = actions_value as Array if actions_value is Array else []
	var action_ids: Dictionary = {}
	for index: int in actions.size():
		var action_value: Variant = actions[index]
		if not action_value is Dictionary:
			errors.append("%s action %d must be a Dictionary." % [prefix, index + 1])
			continue
		validate_action(action_value as Dictionary, prefix, index, hazard_ids, site_ids, reading_ids, action_ids, errors)

	var damage_value: Variant = scenario.get("opening_damage", [])
	var damage_entries: Array = damage_value as Array if damage_value is Array else []
	for index: int in damage_entries.size():
		var entry_value: Variant = damage_entries[index]
		if not entry_value is Dictionary:
			errors.append("%s opening damage %d must be a Dictionary." % [prefix, index + 1])
			continue
		validate_damage(entry_value as Dictionary, prefix, index, site_ids, errors)

	if hazard_ids.has(actual_hazard) and not readings.is_empty():
		var best_match: StringName = HazardEvaluator.best_match(readings, hazards)
		if best_match != actual_hazard:
			errors.append("%s initially visible evidence favors '%s' instead of authored hazard '%s'." % [prefix, best_match, actual_hazard])

static func validate_reading(reading: Dictionary, prefix: String, index: int, hazard_ids: Array[StringName], site_ids: Array[StringName], reading_ids: Dictionary, errors: Array[String]) -> void:
	var label: String = "%s reading %d" % [prefix, index + 1]
	var reading_id: StringName = StringName(reading.get("id", &""))
	if reading_id == &"":
		errors.append("%s requires an id." % label)
	elif reading_ids.has(reading_id):
		errors.append("%s duplicates reading id '%s'." % [label, reading_id])
	reading_ids[reading_id] = str(reading.get("quality", "missing"))
	for field: String in ["instrument", "value"]:
		if str(reading.get(field, "")).strip_edges().is_empty():
			errors.append("%s requires non-empty %s text." % [label, field])
	validate_quality(str(reading.get("quality", "")), "%s quality" % label, errors)
	var support: StringName = StringName(reading.get("supports", &""))
	if not hazard_ids.has(support):
		errors.append("%s references unknown supporting hazard '%s'." % [label, support])
	if not reading.has("visible") or not reading["visible"] is bool:
		errors.append("%s requires a boolean visible flag." % label)
	if not reading.has("faulty") or not reading["faulty"] is bool:
		errors.append("%s requires a boolean faulty flag." % label)

	var has_network_fields: bool = reading.has("network_sensor") or reading.has("network_site") or reading.has("network_value") or reading.has("network_quality")
	if not has_network_fields:
		return
	var sensor_id: StringName = StringName(reading.get("network_sensor", &""))
	if not NetworkModel.SENSOR_LABELS.has(sensor_id):
		errors.append("%s references unknown network sensor '%s'." % [label, sensor_id])
	var site_id: StringName = StringName(reading.get("network_site", &""))
	if not site_ids.has(site_id):
		errors.append("%s references unknown network site '%s'." % [label, site_id])
	if str(reading.get("network_value", "")).strip_edges().is_empty():
		errors.append("%s requires non-empty network_value text." % label)
	validate_quality(str(reading.get("network_quality", "")), "%s network_quality" % label, errors)

static func validate_action(action: Dictionary, prefix: String, index: int, hazard_ids: Array[StringName], site_ids: Array[StringName], reading_ids: Dictionary, action_ids: Dictionary, errors: Array[String]) -> void:
	var label: String = "%s action %d" % [prefix, index + 1]
	var action_id: StringName = StringName(action.get("id", &""))
	if action_id == &"":
		errors.append("%s requires an id." % label)
	elif action_ids.has(action_id):
		errors.append("%s duplicates action id '%s'." % [label, action_id])
	action_ids[action_id] = true
	for field: String in ["label", "value", "log"]:
		if str(action.get(field, "")).strip_edges().is_empty():
			errors.append("%s requires non-empty %s text." % [label, field])
	if int(action.get("cost", 0)) <= 0:
		errors.append("%s cost must be greater than zero." % label)
	var reveal_id: StringName = StringName(action.get("reveals", &""))
	if reveal_id == &"":
		errors.append("%s requires a reveals id." % label)
	elif reading_ids.has(reveal_id) and str(reading_ids[reveal_id]) != "missing":
		errors.append("%s overwrites initially available reading '%s'." % [label, reveal_id])
	validate_quality(str(action.get("quality", "")), "%s quality" % label, errors)
	var support: StringName = StringName(action.get("supports", &""))
	if not hazard_ids.has(support):
		errors.append("%s references unknown supporting hazard '%s'." % [label, support])
	var relay_id: StringName = StringName(action.get("requires_relay", &""))
	if relay_id != &"" and not site_ids.has(relay_id):
		errors.append("%s references unknown required relay site '%s'." % [label, relay_id])

static func validate_damage(entry: Dictionary, prefix: String, index: int, site_ids: Array[StringName], errors: Array[String]) -> void:
	var label: String = "%s opening damage %d" % [prefix, index + 1]
	var site_id: StringName = StringName(entry.get("site", &""))
	if not site_ids.has(site_id):
		errors.append("%s references unknown network site '%s'." % [label, site_id])
	var component: StringName = StringName(entry.get("component", &""))
	if not VALID_DAMAGE_COMPONENTS.has(component):
		errors.append("%s component must be relay or sensor." % label)
	if str(entry.get("message", "")).strip_edges().is_empty():
		errors.append("%s requires a damage message." % label)

static func validate_quality(quality: String, label: String, errors: Array[String]) -> void:
	if not VALID_QUALITIES.has(quality):
		errors.append("%s must be one of: %s." % [label, ", ".join(VALID_QUALITIES)])
