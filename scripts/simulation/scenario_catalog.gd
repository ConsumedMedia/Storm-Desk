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
	return [day_one(), day_two(), day_three(), day_four(), day_five()]

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
		"outlook": "Dry, unstable air is approaching Farm Spire. Crystal and wind coverage may be useful, but the exact hazard remains uncertain.",
		"briefing": "The overnight maintenance window has closed. If you installed a Crystal Sensor at Farm Spire, today's single action can collect its reading; otherwise the High Ridge wind-history survey remains available. Two districts lie along the projected corridor.",
		"tutorial": "Collection day: use the prepared Farm Spire sensor or choose the wind-history survey. Daily capacity permits only one evidence action.",
		"hazard": &"glasswind",
		"severity": 2,
		"threatened": [&"farmland", &"harbor"],
		"capacity": 1,
		"safe_actions": 1,
		"readings": [
			reading(&"wind_shift", "Vane Array", "Wind direction: RAPIDLY SHIFTING", "clear", &"glasswind", true, false),
			reading(&"humidity", "Hygrometer", "Humidity: LOW", "clear", &"glasswind", true, false),
			network_reading(&"crystal", "Crystal Spectrometer", "Crystal density: UNAVAILABLE", &"glasswind", &"crystal", &"farmland", "Crystal density: HIGH", "clear"),
		],
		"actions": [
			{"id": &"wind_history", "label": "Route wind-history survey", "cost": 3, "requires_relay": &"ridge", "reveals": &"history", "value": "Wind history: shifts accelerating", "quality": "clear", "supports": &"glasswind", "log": "The High Ridge relay confirms that wind shifts are accelerating."},
		],
		"outcome_note": "Rapid wind shifts, high crystal density, and low humidity identify Glasswind. Farmland is highly vulnerable; Harbor is moderately exposed.",
	}

static func day_three() -> Dictionary:
	return {
		"day": 3,
		"title": "Noise Over Deepwater",
		"outlook": "A dense bank is gathering over the eastern basin. Harbor moisture coverage and a reliable eastern transmission path may be useful.",
		"briefing": "A dense bank has stalled over the eastern basin. One desk instrument is producing a suspicious signal. Prepared network equipment persists from prior nights; capacity allows two evidence actions, and the second makes any warning late.",
		"tutorial": "Conflicting day: collect from connected sensors or commission a survey, then balance confidence against preparation time. The result will identify faulty evidence.",
		"hazard": &"cloudburst",
		"severity": 3,
		"threatened": [&"harbor", &"farmland"],
		"capacity": 2,
		"safe_actions": 1,
		"readings": [
			reading(&"moisture", "Hygrometer", "Moisture: HIGH", "clear", &"cloudburst", true, false),
			reading(&"cloud_motion", "Cloudscope", "Clouds: DENSE and SLOW-MOVING", "clear", &"cloudburst", true, false),
			reading(&"charge", "Aethermeter", "Electrical charge: RISING", "faulty", &"sparkstorm", true, true),
			network_reading(&"condensation", "Reservoir Gauge", "Condensation: UNAVAILABLE", &"cloudburst", &"moisture", &"harbor", "Condensation: RISING FAST", "clear"),
			network_reading(&"charge_check", "Backup Charge Mast", "Backup charge mast: NOT POLLED", &"cloudburst", &"electrical", &"industrial", "Backup charge mast: NORMAL", "clear"),
		],
		"actions": [
			{"id": &"altitude", "label": "Relay cloud-altitude survey", "cost": 3, "requires_relay": &"ridge", "reveals": &"altitude", "value": "Cloud base: LOW over eastern basin", "quality": "imprecise", "supports": &"cloudburst", "log": "The High Ridge relay gives an imprecise but concerning low cloud-base estimate."},
		],
		"outcome_note": "High moisture, slow dense clouds, and rising condensation form the Cloudburst pattern. The rising-charge reading was faulty; the backup mast remained normal.",
	}

static func day_four() -> Dictionary:
	return {
		"day": 4,
		"title": "The Broken Ridge",
		"outlook": "Crystal shear may disrupt High Ridge overnight while unstable air approaches Farm Spire. Repair readiness or a redundant route may matter.",
		"briefing": "Overnight crystal shear disabled the High Ridge relay before today's maintenance decision. Farm Spire can report only if you repaired the ridge or established the Industrial alternate route. Capacity allows two evidence actions, but only one preserves a timely warning.",
		"tutorial": "Recovery consequence: collect through the route prepared overnight, or dispatch a ground sampler and leave network work for the next maintenance window. The falling-pressure signal is marked suspect.",
		"hazard": &"glasswind",
		"severity": 2,
		"threatened": [&"farmland"],
		"capacity": 2,
		"safe_actions": 1,
		"opening_damage": [
			{
				"site": &"ridge",
				"component": &"relay",
				"message": "Network: overnight crystal shear damaged the High Ridge relay.",
				"existing_message": "Network: the High Ridge relay remains damaged from an earlier storm.",
			},
		],
		"readings": [
			reading(&"wind_shift", "Vane Array", "Wind direction: RAPIDLY SHIFTING", "clear", &"glasswind", true, false),
			reading(&"humidity", "Hygrometer", "Humidity: LOW, calibration wavering", "imprecise", &"glasswind", true, false),
			reading(&"pressure", "Barometer", "Air pressure: FALLING ERRATICALLY", "faulty", &"sparkstorm", true, true),
			network_reading(&"crystal", "Farm Spire Spectrometer", "Crystal density: LINK OFFLINE", &"glasswind", &"crystal", &"farmland", "Crystal density: HIGH", "clear"),
		],
		"actions": [
			{"id": &"ground_crystal", "label": "Dispatch ground crystal sampler", "cost": 3, "reveals": &"ground_crystal", "value": "Ground sample: HIGH crystal density", "quality": "clear", "supports": &"glasswind", "log": "The ground team confirms high crystal density but does not restore the relay network."},
		],
		"outcome_note": "Rapid wind shifts, low humidity, and high crystal density identify Glasswind. The erratic pressure reading came from a vibration-damaged barometer.",
	}

static func day_five() -> Dictionary:
	return {
		"day": 5,
		"title": "The Week's Last Wall",
		"outlook": "A severe front is approaching Harbor and Industrial. Moisture coverage and a redundant eastern route may matter for the final forecast.",
		"briefing": "A severe front is pressing into the eastern basin. Harbor and Industrial crews both need an accurate call. Your week-long network choices now determine which corroborating routes are available; a second action will make the warning late.",
		"tutorial": "Final day: use a connected Harbor moisture sensor, the repaired High Ridge route, or an Industrial alternate route. Seek enough confidence without sacrificing preparation time.",
		"hazard": &"cloudburst",
		"severity": 3,
		"threatened": [&"industrial", &"harbor"],
		"capacity": 2,
		"safe_actions": 1,
		"readings": [
			reading(&"moisture", "Hygrometer", "Moisture: HIGH", "clear", &"cloudburst", true, false),
			reading(&"cloud_motion", "Cloudscope", "Clouds: DENSE, movement uncertain", "imprecise", &"cloudburst", true, false),
			reading(&"crystal", "Crystal Spectrometer", "Crystal shimmer: HIGH", "faulty", &"glasswind", true, true),
			network_reading(&"condensation", "Harbor Reservoir Gauge", "Condensation: NETWORK READING PENDING", &"cloudburst", &"moisture", &"harbor", "Condensation: RISING FAST", "clear"),
		],
		"actions": [
			{"id": &"ridge_profile", "label": "Route ridge condensation profile", "cost": 3, "requires_relay": &"ridge", "reveals": &"ridge_profile", "value": "Ridge profile: condensation climbing", "quality": "clear", "supports": &"cloudburst", "log": "The High Ridge route confirms climbing condensation over the eastern basin."},
			{"id": &"industrial_runoff", "label": "Poll Industrial runoff telemetry", "cost": 1, "requires_relay": &"industrial", "reveals": &"industrial_runoff", "value": "Industrial runoff channels: RISING", "quality": "clear", "supports": &"cloudburst", "log": "The Industrial alternate route reports rapidly rising runoff channels."},
		],
		"outcome_note": "High moisture, dense slow clouds, and rising condensation identify a severe Cloudburst. The crystal shimmer was ice contamination, not Glasswind.",
	}

static func reading(id: StringName, instrument: String, value: String, quality: String, supports: StringName, visible: bool, faulty: bool) -> Dictionary:
	return {"id": id, "instrument": instrument, "value": value, "quality": quality, "supports": supports, "visible": visible, "faulty": faulty}

static func network_reading(id: StringName, instrument: String, unavailable_value: String, supports: StringName, sensor_type: StringName, site_id: StringName, network_value: String, network_quality: String) -> Dictionary:
	return {
		"id": id,
		"instrument": instrument,
		"value": unavailable_value,
		"quality": "missing",
		"supports": supports,
		"visible": true,
		"faulty": false,
		"network_sensor": sensor_type,
		"network_site": site_id,
		"network_value": network_value,
		"network_quality": network_quality,
	}
