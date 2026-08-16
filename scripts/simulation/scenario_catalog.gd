class_name ScenarioCatalog
extends RefCounted

const HAZARD_PATHS: Array[String] = [
	"res://resources/hazards/sparkstorm.tres",
	"res://resources/hazards/glasswind.tres",
	"res://resources/hazards/cloudburst.tres",
]

const DISTRICT_PATHS: Array[String] = [
	"res://resources/districts/farmland.tres",
	"res://resources/districts/industrial.tres",
	"res://resources/districts/harbor.tres",
]

static func hazards() -> Array[HazardDefinition]:
	var result: Array[HazardDefinition] = []
	for path: String in HAZARD_PATHS:
		result.append(load(path) as HazardDefinition)
	return result

static func districts() -> Array[DistrictDefinition]:
	var result: Array[DistrictDefinition] = []
	for path: String in DISTRICT_PATHS:
		result.append(load(path) as DistrictDefinition)
	return result

static func days() -> Array[Dictionary]:
	return [day_one(), day_two(), day_three()]

static func day_one() -> Dictionary:
	return {
		"day": 1,
		"title": "A Clean Signal",
		"briefing": "A compact front is forming west of the inhabited islands. All essential desk instruments are working. Use the rules card, compare the readings, then warn the district in serious danger.",
		"tutorial": "Teaching day: Sparkstorms combine rising charge, falling pressure, and eastward clouds. The Industrial District is especially vulnerable.",
		"hazard": &"sparkstorm",
		"severity": 2,
		"threatened": [&"industrial"],
		"capacity": 0,
		"safe_actions": 0,
		"readings": [
			reading(&"charge", "Aethermeter", "Electrical charge: RISING", "clear", &"sparkstorm", true, false),
			reading(&"pressure", "Barometer", "Air pressure: FALLING", "clear", &"sparkstorm", true, false),
			reading(&"cloud_motion", "Cloudscope", "Cloud movement: EASTWARD", "clear", &"sparkstorm", true, false),
		],
		"actions": [],
		"outcome_note": "The rising charge, falling pressure, and eastward cloud track form the complete Sparkstorm pattern.",
	}

static func day_two() -> Dictionary:
	return {
		"day": 2,
		"title": "A Missing Crystal Trace",
		"briefing": "The southern sensor mast is intermittent. You have capacity for only one network request. Two districts lie along the projected wind corridor, but their vulnerabilities differ.",
		"tutorial": "Incomplete day: gather the reading that best separates Glasswind from other hazards. You cannot request both available observations.",
		"hazard": &"glasswind",
		"severity": 2,
		"threatened": [&"farmland", &"harbor"],
		"capacity": 1,
		"safe_actions": 1,
		"readings": [
			reading(&"wind_shift", "Vane Array", "Wind direction: RAPIDLY SHIFTING", "clear", &"glasswind", true, false),
			reading(&"humidity", "Hygrometer", "Humidity: LOW", "clear", &"glasswind", true, false),
			reading(&"crystal", "Crystal Spectrometer", "Crystal density: UNAVAILABLE", "missing", &"glasswind", true, false),
		],
		"actions": [
			{"id": &"crystal_scan", "label": "Query crystal sensor", "cost": 4, "reveals": &"crystal", "value": "Crystal density: HIGH", "quality": "clear", "log": "Remote crystal sensor reports a high atmospheric crystal count."},
			{"id": &"wind_history", "label": "Route wind-history relay", "cost": 3, "reveals": &"history", "value": "Wind history: shifts accelerating", "quality": "clear", "supports": &"glasswind", "log": "The relay confirms that wind shifts are accelerating."},
		],
		"outcome_note": "Rapid wind shifts, high crystal density, and low humidity identify Glasswind. Farmland is highly vulnerable; Harbor is moderately exposed.",
	}

static func day_three() -> Dictionary:
	return {
		"day": 3,
		"title": "Noise Over Deepwater",
		"briefing": "A dense bank has stalled over the eastern basin. One desk instrument is producing a suspicious signal. Three network requests are available, but capacity allows only two—and the second request makes any warning late.",
		"tutorial": "Conflicting day: seek corroboration, but balance confidence against preparation time. The result will identify faulty evidence.",
		"hazard": &"cloudburst",
		"severity": 3,
		"threatened": [&"harbor", &"farmland"],
		"capacity": 2,
		"safe_actions": 1,
		"readings": [
			reading(&"moisture", "Hygrometer", "Moisture: HIGH", "clear", &"cloudburst", true, false),
			reading(&"cloud_motion", "Cloudscope", "Clouds: DENSE and SLOW-MOVING", "clear", &"cloudburst", true, false),
			reading(&"charge", "Aethermeter", "Electrical charge: RISING", "faulty", &"sparkstorm", true, true),
			reading(&"condensation", "Reservoir Gauge", "Condensation: UNAVAILABLE", "missing", &"cloudburst", true, false),
		],
		"actions": [
			{"id": &"reservoir", "label": "Query reservoir gauge", "cost": 4, "reveals": &"condensation", "value": "Condensation: RISING FAST", "quality": "clear", "log": "The remote reservoir gauge confirms rapidly rising condensation."},
			{"id": &"charge_check", "label": "Cross-check charge mast", "cost": 3, "reveals": &"charge_check", "value": "Backup charge mast: NORMAL", "quality": "clear", "supports": &"cloudburst", "log": "The backup mast contradicts the desk aethermeter; the charge signal is likely faulty."},
			{"id": &"altitude", "label": "Survey cloud altitude", "cost": 3, "reveals": &"altitude", "value": "Cloud base: LOW over eastern basin", "quality": "imprecise", "supports": &"cloudburst", "log": "The relay gives an imprecise but concerning low cloud-base estimate."},
		],
		"outcome_note": "High moisture, slow dense clouds, and rising condensation form the Cloudburst pattern. The rising-charge reading was faulty; the backup mast remained normal.",
	}

static func reading(id: StringName, instrument: String, value: String, quality: String, supports: StringName, visible: bool, faulty: bool) -> Dictionary:
	return {"id": id, "instrument": instrument, "value": value, "quality": quality, "supports": supports, "visible": visible, "faulty": faulty}
