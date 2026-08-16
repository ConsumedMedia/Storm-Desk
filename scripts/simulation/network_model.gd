class_name NetworkModel
extends RefCounted

const SENSOR_LABELS: Dictionary = {
	&"electrical": "Electrical Sensor",
	&"crystal": "Crystal Sensor",
	&"moisture": "Moisture Sensor",
}

var sites: Array[Dictionary] = []
var equipment: Dictionary = {}

func _init() -> void:
	sites = [
		{"id": &"hq", "label": "Bureau HQ", "short": "HQ", "position": Vector2(0.16, 0.50), "neighbors": [&"ridge", &"industrial"]},
		{"id": &"ridge", "label": "High Ridge", "short": "RIDGE", "position": Vector2(0.46, 0.50), "neighbors": [&"hq", &"farmland", &"harbor"]},
		{"id": &"farmland", "label": "Farm Spire", "short": "FARM", "position": Vector2(0.78, 0.20), "neighbors": [&"ridge"]},
		{"id": &"industrial", "label": "Industrial Mast", "short": "IND", "position": Vector2(0.48, 0.84), "neighbors": [&"hq", &"harbor"]},
		{"id": &"harbor", "label": "Harbor Buoy", "short": "HARBOR", "position": Vector2(0.80, 0.70), "neighbors": [&"ridge", &"industrial"]},
	]
	reset()

func reset() -> void:
	equipment.clear()
	for site: Dictionary in sites:
		equipment[site["id"]] = {"relay": false, "relay_health": 0, "sensor": &"", "sensor_health": 0}
	var hq: Dictionary = equipment[&"hq"]
	hq["relay"] = true
	hq["relay_health"] = 1
	var ridge: Dictionary = equipment[&"ridge"]
	ridge["relay"] = true
	ridge["relay_health"] = 1
	var industrial: Dictionary = equipment[&"industrial"]
	industrial["sensor"] = &"electrical"
	industrial["sensor_health"] = 1

func site_by_id(site_id: StringName) -> Dictionary:
	for site: Dictionary in sites:
		if StringName(site["id"]) == site_id:
			return site
	return {}

func site_label(site_id: StringName) -> String:
	return str(site_by_id(site_id).get("label", site_id))

func equipment_at(site_id: StringName) -> Dictionary:
	return equipment.get(site_id, {}) as Dictionary

func online_relays() -> Array[StringName]:
	var online: Array[StringName] = [&"hq"]
	var frontier: Array[StringName] = [&"hq"]
	while not frontier.is_empty():
		var current: StringName = frontier.pop_front()
		var site: Dictionary = site_by_id(current)
		for neighbor_value: Variant in site.get("neighbors", []):
			var neighbor: StringName = StringName(neighbor_value)
			if online.has(neighbor):
				continue
			var gear: Dictionary = equipment_at(neighbor)
			if bool(gear.get("relay", false)) and int(gear.get("relay_health", 0)) > 0:
				online.append(neighbor)
				frontier.append(neighbor)
	return online

func is_site_covered(site_id: StringName) -> bool:
	if site_id == &"hq":
		return true
	var online: Array[StringName] = online_relays()
	if online.has(site_id):
		return true
	var site: Dictionary = site_by_id(site_id)
	for neighbor_value: Variant in site.get("neighbors", []):
		if online.has(StringName(neighbor_value)):
			return true
	return false

func has_online_sensor(site_id: StringName, sensor_type: StringName) -> bool:
	var gear: Dictionary = equipment_at(site_id)
	return StringName(gear.get("sensor", &"")) == sensor_type and int(gear.get("sensor_health", 0)) > 0 and is_site_covered(site_id)

func install_relay(site_id: StringName) -> String:
	if site_id == &"hq":
		return "Bureau HQ already provides the base connection."
	var gear: Dictionary = equipment_at(site_id)
	if gear.is_empty():
		return "Unknown network site."
	if bool(gear.get("relay", false)):
		return "This site already has a relay%s." % (" that needs repair" if int(gear.get("relay_health", 0)) <= 0 else "")
	gear["relay"] = true
	gear["relay_health"] = 1
	return ""

func install_sensor(site_id: StringName, sensor_type: StringName) -> String:
	if site_id == &"hq":
		return "Sensors must be placed at a remote field site."
	if not SENSOR_LABELS.has(sensor_type):
		return "Unknown sensor type."
	var gear: Dictionary = equipment_at(site_id)
	if gear.is_empty():
		return "Unknown network site."
	var existing: StringName = StringName(gear.get("sensor", &""))
	if existing != &"":
		return "%s already occupies this site's sensor slot%s." % [SENSOR_LABELS.get(existing, "A sensor"), " and needs repair" if int(gear.get("sensor_health", 0)) <= 0 else ""]
	gear["sensor"] = sensor_type
	gear["sensor_health"] = 1
	return ""

func repair_site(site_id: StringName) -> String:
	var gear: Dictionary = equipment_at(site_id)
	if gear.is_empty():
		return "Unknown network site."
	if bool(gear.get("relay", false)) and int(gear.get("relay_health", 0)) <= 0:
		gear["relay_health"] = 1
		return "Repaired the relay at %s." % site_label(site_id)
	if StringName(gear.get("sensor", &"")) != &"" and int(gear.get("sensor_health", 0)) <= 0:
		gear["sensor_health"] = 1
		return "Repaired the %s at %s." % [SENSOR_LABELS.get(gear["sensor"], "sensor"), site_label(site_id)]
	return "No damaged equipment is present at this site."

func has_damage(site_id: StringName) -> bool:
	var gear: Dictionary = equipment_at(site_id)
	return (bool(gear.get("relay", false)) and int(gear.get("relay_health", 0)) <= 0) or (StringName(gear.get("sensor", &"")) != &"" and int(gear.get("sensor_health", 0)) <= 0)

func damage_relay(site_id: StringName) -> bool:
	var gear: Dictionary = equipment_at(site_id)
	if bool(gear.get("relay", false)) and int(gear.get("relay_health", 0)) > 0:
		gear["relay_health"] = 0
		return true
	return false

func damage_sensor(site_id: StringName) -> bool:
	var gear: Dictionary = equipment_at(site_id)
	if StringName(gear.get("sensor", &"")) != &"" and int(gear.get("sensor_health", 0)) > 0:
		gear["sensor_health"] = 0
		return true
	return false

func resolve_hazard(actual_hazard: StringName, chosen_hazard: StringName, warned_districts: Array[StringName], late: bool) -> Array[String]:
	var events: Array[String] = []
	var correct: bool = actual_hazard == chosen_hazard
	match actual_hazard:
		&"sparkstorm":
			if not (correct and warned_districts.has(&"industrial") and not late) and damage_sensor(&"industrial"):
				events.append("Network: the unprotected Sparkstorm damaged the Industrial Mast sensor.")
		&"glasswind":
			if not (correct and warned_districts.has(&"farmland") and not late) and damage_relay(&"ridge"):
				events.append("Network: exposed Glasswind damaged the High Ridge relay; downstream sites are offline until repaired or rerouted.")
		&"cloudburst":
			if not (correct and warned_districts.has(&"harbor") and not late) and damage_sensor(&"harbor"):
				events.append("Network: the Harbor Buoy sensor was damaged by the Cloudburst.")
	return events

func status_text(site_id: StringName) -> String:
	var gear: Dictionary = equipment_at(site_id)
	var parts: Array[String] = []
	if bool(gear.get("relay", false)):
		parts.append("Relay: ONLINE" if int(gear.get("relay_health", 0)) > 0 and online_relays().has(site_id) else "Relay: DAMAGED/OFFLINE")
	var sensor: StringName = StringName(gear.get("sensor", &""))
	if sensor != &"":
		var sensor_state: String = "ONLINE" if has_online_sensor(site_id, sensor) else ("DAMAGED" if int(gear.get("sensor_health", 0)) <= 0 else "NO RELAY PATH")
		parts.append("%s: %s" % [SENSOR_LABELS.get(sensor, "Sensor"), sensor_state])
	if parts.is_empty():
		parts.append("Empty relay and sensor slots")
	return "%s — %s" % [site_label(site_id), " | ".join(parts)]

func summary() -> String:
	var lines: Array[String] = []
	for site: Dictionary in sites:
		if StringName(site["id"]) != &"hq":
			lines.append(status_text(StringName(site["id"])))
	return "\n".join(lines)

