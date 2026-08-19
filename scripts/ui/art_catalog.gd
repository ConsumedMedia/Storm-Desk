class_name ArtCatalog
extends RefCounted

const BUREAU_BACKGROUND: String = "res://assets/art/backgrounds/02_main_bureau_interface_background.png"
const OBSERVATION_CLEAR: String = "res://assets/art/backgrounds/03_observation_clear_morning.png"
const OBSERVATION_SPARKSTORM: String = "res://assets/art/backgrounds/04_observation_sparkstorm.png"
const OBSERVATION_GLASSWIND: String = "res://assets/art/backgrounds/05_observation_glasswind.png"
const OBSERVATION_CLOUDBURST: String = "res://assets/art/backgrounds/06_observation_cloudburst.png"
const OBSERVATION_OVERNIGHT: String = "res://assets/art/backgrounds/07_observation_overnight.png"
const MAINTENANCE_BACKGROUND: String = "res://assets/art/backgrounds/32_overnight_maintenance_background.png"
const TITLE_BACKGROUND: String = "res://assets/art/backgrounds/37_title_screen.png"
const REGIONAL_MAP: String = "res://assets/art/maps/08_regional_floating_island_map.png"
const EMBLEM_SHEET: String = "res://assets/art/ui/34_weather_bureau_emblem.png"
const HAZARD_SYMBOL_SHEET: String = "res://assets/art/ui/35_hazard_symbol_set.png"

const DISTRICT_PATHS: Dictionary = {
	&"farmland": "res://assets/art/districts/09_district_farmland.png",
	&"industrial": "res://assets/art/districts/10_district_industrial.png",
	&"harbor": "res://assets/art/districts/11_district_harbor.png",
}

const INSTRUMENT_PATHS: Dictionary = {
	&"aethermeter": "res://assets/art/instruments/14_instrument_aethermeter.png",
	&"barometer": "res://assets/art/instruments/15_instrument_barometer.png",
	&"cloudscope": "res://assets/art/instruments/16_instrument_cloudscope.png",
	&"vane": "res://assets/art/instruments/17_instrument_vane_array.png",
	&"hygrometer": "res://assets/art/instruments/18_instrument_hygrometer.png",
	&"crystal": "res://assets/art/instruments/19_instrument_crystal_spectrometer.png",
}

const DOCUMENT_PATHS: Dictionary = {
	&"briefing": "res://assets/art/documents/28_document_morning_briefing.png",
	&"warning": "res://assets/art/documents/29_document_warning_bulletin.png",
	&"daily_report": "res://assets/art/documents/30_document_daily_outcome_report.png",
	&"final_report": "res://assets/art/documents/31_document_first_week_report.png",
}

const GALLERY_ENTRIES: Array[Dictionary] = [
	{"name": "01  Master art-direction keyframe", "path": "res://assets/art/reference/01_master_art_direction_keyframe.png"},
	{"name": "02  Main bureau interface background", "path": BUREAU_BACKGROUND},
	{"name": "03  Observation — clear morning", "path": OBSERVATION_CLEAR},
	{"name": "04  Observation — Sparkstorm", "path": OBSERVATION_SPARKSTORM},
	{"name": "05  Observation — Glasswind", "path": OBSERVATION_GLASSWIND},
	{"name": "06  Observation — Cloudburst", "path": OBSERVATION_CLOUDBURST},
	{"name": "07  Observation — overnight", "path": OBSERVATION_OVERNIGHT},
	{"name": "08  Regional floating-island map", "path": REGIONAL_MAP},
	{"name": "09  Farmland District", "path": "res://assets/art/districts/09_district_farmland.png"},
	{"name": "10  Industrial District", "path": "res://assets/art/districts/10_district_industrial.png"},
	{"name": "11  Harbor District", "path": "res://assets/art/districts/11_district_harbor.png"},
	{"name": "12  Bureau Headquarters", "path": "res://assets/art/districts/12_bureau_headquarters.png"},
	{"name": "13  High Ridge relay", "path": "res://assets/art/districts/13_high_ridge_relay.png"},
	{"name": "14  Aethermeter", "path": "res://assets/art/instruments/14_instrument_aethermeter.png"},
	{"name": "15  Barometer", "path": "res://assets/art/instruments/15_instrument_barometer.png"},
	{"name": "16  Cloudscope", "path": "res://assets/art/instruments/16_instrument_cloudscope.png"},
	{"name": "17  Vane Array", "path": "res://assets/art/instruments/17_instrument_vane_array.png"},
	{"name": "18  Hygrometer", "path": "res://assets/art/instruments/18_instrument_hygrometer.png"},
	{"name": "19  Crystal Spectrometer", "path": "res://assets/art/instruments/19_instrument_crystal_spectrometer.png"},
	{"name": "20  Instrument-condition overlays", "path": "res://assets/art/instruments/20_instrument_condition_overlays.png"},
	{"name": "21  Relay tower states", "path": "res://assets/art/network/21_relay_tower_states.png"},
	{"name": "22  Field sensor modules", "path": "res://assets/art/network/22_field_sensor_modules.png"},
	{"name": "23  Network marker and route kit", "path": "res://assets/art/network/23_network_marker_route_kit.png"},
	{"name": "24  Sparkstorm effect", "path": "res://assets/art/effects/24_fx_sparkstorm.png"},
	{"name": "25  Glasswind effect", "path": "res://assets/art/effects/25_fx_glasswind.png"},
	{"name": "26  Cloudburst effect", "path": "res://assets/art/effects/26_fx_cloudburst.png"},
	{"name": "27  District preparation and damage", "path": "res://assets/art/effects/27_district_preparation_damage_overlays.png"},
	{"name": "28  Morning briefing document", "path": "res://assets/art/documents/28_document_morning_briefing.png"},
	{"name": "29  Warning bulletin document", "path": "res://assets/art/documents/29_document_warning_bulletin.png"},
	{"name": "30  Daily outcome report", "path": "res://assets/art/documents/30_document_daily_outcome_report.png"},
	{"name": "31  First-week report", "path": "res://assets/art/documents/31_document_first_week_report.png"},
	{"name": "32  Overnight maintenance background", "path": MAINTENANCE_BACKGROUND},
	{"name": "33  Interface frame texture kit", "path": "res://assets/art/ui/33_ui_frame_texture_kit.png"},
	{"name": "34  Weather bureau emblem", "path": EMBLEM_SHEET},
	{"name": "35  Hazard symbol set", "path": HAZARD_SYMBOL_SHEET},
	{"name": "36  Ambient bureau props", "path": "res://assets/art/ui/36_ambient_bureau_props.png"},
	{"name": "37  Title screen", "path": TITLE_BACKGROUND},
	{"name": "38  Phase-transition illustrations", "path": "res://assets/art/ui/38_phase_transition_illustrations.png"},
]

static func texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path, "Texture2D"):
		return null
	return ResourceLoader.load(path, "Texture2D") as Texture2D

static func district_texture(district_id: StringName) -> Texture2D:
	return texture(str(DISTRICT_PATHS.get(district_id, "")))

static func instrument_texture(instrument_name: String) -> Texture2D:
	var normalized: String = instrument_name.to_lower()
	if normalized.contains("aether") or normalized.contains("charge"):
		return texture(str(INSTRUMENT_PATHS[&"aethermeter"]))
	if normalized.contains("barometer") or normalized.contains("pressure"):
		return texture(str(INSTRUMENT_PATHS[&"barometer"]))
	if normalized.contains("cloud"):
		return texture(str(INSTRUMENT_PATHS[&"cloudscope"]))
	if normalized.contains("vane") or normalized.contains("wind"):
		return texture(str(INSTRUMENT_PATHS[&"vane"]))
	if normalized.contains("hygrometer") or normalized.contains("reservoir") or normalized.contains("moisture"):
		return texture(str(INSTRUMENT_PATHS[&"hygrometer"]))
	if normalized.contains("spectrometer") or normalized.contains("crystal"):
		return texture(str(INSTRUMENT_PATHS[&"crystal"]))
	return null

static func observation_texture(phase_value: int, actual_hazard: StringName) -> Texture2D:
	if phase_value == 8:
		return texture(OBSERVATION_OVERNIGHT)
	if phase_value != 5 and phase_value != 6:
		return texture(OBSERVATION_CLEAR)
	match actual_hazard:
		&"sparkstorm":
			return texture(OBSERVATION_SPARKSTORM)
		&"glasswind":
			return texture(OBSERVATION_GLASSWIND)
		&"cloudburst":
			return texture(OBSERVATION_CLOUDBURST)
	return texture(OBSERVATION_CLEAR)

static func document_texture(title_text: String) -> Texture2D:
	var normalized: String = title_text.to_upper()
	if normalized.contains("MORNING BRIEFING"):
		return texture(str(DOCUMENT_PATHS[&"briefing"]))
	if normalized.contains("CONFIRM WARNING"):
		return texture(str(DOCUMENT_PATHS[&"warning"]))
	if normalized.contains("FIVE-DAY"):
		return texture(str(DOCUMENT_PATHS[&"final_report"]))
	if normalized.contains("REPORT"):
		return texture(str(DOCUMENT_PATHS[&"daily_report"]))
	return null

static func emblem_texture() -> Texture2D:
	var sheet: Texture2D = texture(EMBLEM_SHEET)
	if sheet == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(1448.0, 0.0, 724.0, 724.0)
	return atlas

static func hazard_symbol_texture(hazard_id: StringName) -> Texture2D:
	var sheet: Texture2D = texture(HAZARD_SYMBOL_SHEET)
	if sheet == null:
		return null
	var index: int = {&"sparkstorm": 0, &"glasswind": 1, &"cloudburst": 2}.get(hazard_id, -1)
	if index < 0:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(float(index * 724), 0.0, 724.0, 724.0)
	return atlas

