class_name SessionSave
extends RefCounted

const FORMAT_VERSION: int = 1
const DEFAULT_PATH: String = "user://storm_desk_session.cfg"
const VALID_QUALITIES: Array[String] = ["clear", "missing", "imprecise", "faulty"]

static func exists(path: String = DEFAULT_PATH) -> bool:
	return FileAccess.file_exists(path)

static func write(state: Dictionary, path: String = DEFAULT_PATH) -> Error:
	var config := ConfigFile.new()
	config.set_value("meta", "format_version", FORMAT_VERSION)
	config.set_value("meta", "saved_unix_time", int(Time.get_unix_time_from_system()))
	config.set_value("session", "state", state.duplicate(true))
	return config.save(path)

static func read(path: String = DEFAULT_PATH) -> Dictionary:
	if not exists(path):
		return {"ok": false, "missing": true, "error": "No saved first week exists."}
	var config := ConfigFile.new()
	var load_error: Error = config.load(path)
	if load_error != OK:
		return {"ok": false, "missing": false, "error": "The saved first week could not be read (error %d)." % load_error}
	var version_value: Variant = config.get_value("meta", "format_version", -1)
	if not version_value is int or int(version_value) != FORMAT_VERSION:
		return {"ok": false, "missing": false, "error": "The saved first week uses an unsupported format version."}
	var state_value: Variant = config.get_value("session", "state", null)
	if not state_value is Dictionary:
		return {"ok": false, "missing": false, "error": "The saved first week does not contain session data."}
	return {"ok": true, "missing": false, "state": (state_value as Dictionary).duplicate(true), "error": ""}

static func delete(path: String = DEFAULT_PATH) -> Error:
	if not exists(path):
		return OK
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

static func validate_state(state: Dictionary, scenarios: Array[Dictionary], hazard_ids: Array[StringName], district_ids: Array[StringName], site_ids: Array[StringName]) -> Array[String]:
	var errors: Array[String] = []
	for field: String in ["day_index", "phase", "budget", "trust", "observations_used", "observation_spend", "selected_severity", "maintenance_actions_used"]:
		if not state.get(field) is int:
			errors.append("Saved field '%s' must be an integer." % field)
	for field: String in ["readings", "warned_districts", "reports", "opening_damage_applied_days", "used_action_ids"]:
		if not state.get(field) is Array:
			errors.append("Saved field '%s' must be an Array." % field)
	for field: String in ["district_outcomes", "network"]:
		if not state.get(field) is Dictionary:
			errors.append("Saved field '%s' must be a Dictionary." % field)
	if not state.get("event_log") is String:
		errors.append("Saved field 'event_log' must be text.")
	if not errors.is_empty():
		return errors

	var day_index: int = int(state["day_index"])
	if day_index < 0 or day_index >= scenarios.size():
		errors.append("Saved day index is outside the current scenario catalog.")
		return errors
	var phase: int = int(state["phase"])
	if phase < 0 or phase > 8 or phase == 5 or phase == 7:
		errors.append("Saved phase is not resumable.")
	if phase == 8 and day_index >= scenarios.size() - 1:
		errors.append("Final-day maintenance is not a valid state.")
	if int(state["budget"]) < -999 or int(state["budget"]) > 9999:
		errors.append("Saved budget is outside supported bounds.")
	if int(state["trust"]) < 0 or int(state["trust"]) > 999:
		errors.append("Saved trust is outside supported bounds.")
	var capacity: int = int(scenarios[day_index].get("capacity", 0))
	var observations_used: int = int(state["observations_used"])
	if observations_used < 0 or observations_used > capacity:
		errors.append("Saved observation use exceeds the current day's capacity.")
	if int(state["observation_spend"]) < 0:
		errors.append("Saved observation spending cannot be negative.")
	if int(state["selected_severity"]) < 1 or int(state["selected_severity"]) > 3:
		errors.append("Saved warning severity must be between 1 and 3.")
	if int(state["maintenance_actions_used"]) < 0 or int(state["maintenance_actions_used"]) > 1:
		errors.append("Saved maintenance use exceeds the nightly limit.")

	var selected_hazard: StringName = StringName(state.get("selected_hazard", &""))
	if selected_hazard != &"" and not hazard_ids.has(selected_hazard):
		errors.append("Saved warning references an unknown hazard.")
	var selected_district: StringName = StringName(state.get("selected_district", &""))
	if selected_district != &"" and not district_ids.has(selected_district):
		errors.append("Saved map selection references an unknown district.")
	var selected_network_site: StringName = StringName(state.get("selected_network_site", &""))
	if not site_ids.has(selected_network_site):
		errors.append("Saved network selection references an unknown site.")
	for warned_value: Variant in state["warned_districts"] as Array:
		if not district_ids.has(StringName(warned_value)):
			errors.append("Saved warning references an unknown district.")
	for day_value: Variant in state["opening_damage_applied_days"] as Array:
		if not day_value is int or int(day_value) < 1 or int(day_value) > scenarios.size():
			errors.append("Saved opening-damage history references an invalid day.")

	var valid_action_ids: Array[StringName] = []
	for action: Dictionary in scenarios[day_index].get("actions", []) as Array:
		valid_action_ids.append(StringName(action.get("id", &"")))
	for action_value: Variant in state["used_action_ids"] as Array:
		if not valid_action_ids.has(StringName(action_value)):
			errors.append("Saved session references an unknown observation action.")

	var readings: Array = state["readings"] as Array
	if readings.is_empty():
		errors.append("Saved session contains no instrument readings.")
	for reading_value: Variant in readings:
		if not reading_value is Dictionary:
			errors.append("Saved instrument reading must be a Dictionary.")
			continue
		var reading: Dictionary = reading_value as Dictionary
		if StringName(reading.get("id", &"")) == &"":
			errors.append("Saved instrument reading requires an id.")
		if not VALID_QUALITIES.has(str(reading.get("quality", ""))):
			errors.append("Saved instrument reading has an invalid quality.")
		if not hazard_ids.has(StringName(reading.get("supports", &""))):
			errors.append("Saved instrument reading references an unknown hazard.")
		if not reading.get("visible") is bool or not reading.get("faulty") is bool:
			errors.append("Saved instrument reading flags must be boolean.")

	var reports: Array = state["reports"] as Array
	var expected_reports: int = day_index + 1 if phase == 6 or phase == 8 else day_index
	if reports.size() != expected_reports:
		errors.append("Saved report count does not match its day and phase.")
	for report_value: Variant in reports:
		if not report_value is Dictionary:
			errors.append("Saved report entry must be a Dictionary.")

	validate_network(state["network"] as Dictionary, site_ids, errors)
	return errors

static func validate_network(snapshot: Dictionary, site_ids: Array[StringName], errors: Array[String]) -> void:
	var equipment_value: Variant = snapshot.get("equipment")
	if not equipment_value is Array:
		errors.append("Saved network equipment must be an Array.")
		return
	var equipment_entries: Array = equipment_value as Array
	if equipment_entries.size() != site_ids.size():
		errors.append("Saved network does not match the current site catalog.")
	var seen_sites: Dictionary = {}
	for entry_value: Variant in equipment_entries:
		if not entry_value is Dictionary:
			errors.append("Saved network entry must be a Dictionary.")
			continue
		var entry: Dictionary = entry_value as Dictionary
		var site_id: StringName = StringName(entry.get("id", &""))
		if not site_ids.has(site_id) or seen_sites.has(site_id):
			errors.append("Saved network contains an unknown or duplicate site.")
		seen_sites[site_id] = true
		if not entry.get("relay") is bool:
			errors.append("Saved relay state must be boolean.")
		if not entry.get("relay_health") is int or int(entry.get("relay_health", -1)) < 0 or int(entry.get("relay_health", -1)) > 1:
			errors.append("Saved relay health must be zero or one.")
		var sensor: StringName = StringName(entry.get("sensor", &""))
		if sensor != &"" and not NetworkModel.SENSOR_LABELS.has(sensor):
			errors.append("Saved network contains an unknown sensor type.")
		if not entry.get("sensor_health") is int or int(entry.get("sensor_health", -1)) < 0 or int(entry.get("sensor_health", -1)) > 1:
			errors.append("Saved sensor health must be zero or one.")
