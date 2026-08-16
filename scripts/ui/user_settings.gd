class_name UserSettings
extends RefCounted

const FORMAT_VERSION: int = 1
const DEFAULT_PATH: String = "user://settings.cfg"
const SECTION: String = "accessibility"
const STANDARD_TEXT_SCALE: float = 1.0
const LARGE_TEXT_SCALE: float = 1.15

var config_path: String = DEFAULT_PATH
var persistence_enabled: bool = true
var reduced_motion: bool = false
var large_text: bool = false
var high_contrast: bool = false

func load_preferences() -> void:
	reset_defaults()
	if not persistence_enabled:
		return
	var config := ConfigFile.new()
	if config.load(config_path) != OK:
		return
	var version: int = int(config.get_value(SECTION, "format_version", FORMAT_VERSION))
	if version != FORMAT_VERSION:
		return
	reduced_motion = bool(config.get_value(SECTION, "reduced_motion", false))
	large_text = bool(config.get_value(SECTION, "large_text", false))
	high_contrast = bool(config.get_value(SECTION, "high_contrast", false))

func save_preferences() -> Error:
	if not persistence_enabled:
		return OK
	var config := ConfigFile.new()
	config.load(config_path)
	config.set_value(SECTION, "format_version", FORMAT_VERSION)
	config.set_value(SECTION, "reduced_motion", reduced_motion)
	config.set_value(SECTION, "large_text", large_text)
	config.set_value(SECTION, "high_contrast", high_contrast)
	return config.save(config_path)

func reset_defaults() -> void:
	reduced_motion = false
	large_text = false
	high_contrast = false

func text_scale() -> float:
	return LARGE_TEXT_SCALE if large_text else STANDARD_TEXT_SCALE

func as_dictionary() -> Dictionary:
	return {
		"reduced_motion": reduced_motion,
		"large_text": large_text,
		"high_contrast": high_contrast,
	}
