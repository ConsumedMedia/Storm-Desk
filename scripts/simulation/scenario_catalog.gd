class_name ScenarioCatalog
extends RefCounted

const SCENARIO_DEFINITION_SCRIPT: Script = preload("res://scripts/simulation/scenario_definition.gd")
const SCENARIO_VALIDATOR_SCRIPT: Script = preload("res://scripts/simulation/scenario_validator.gd")

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

const SCENARIO_PATHS: Array[String] = [
	"res://resources/scenarios/day_01_clean_signal.tres",
	"res://resources/scenarios/day_02_missing_crystal_trace.tres",
	"res://resources/scenarios/day_03_noise_over_deepwater.tres",
	"res://resources/scenarios/day_04_broken_ridge.tres",
	"res://resources/scenarios/day_05_weeks_last_wall.tres",
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

static func scenario_definitions() -> Array[Resource]:
	var result: Array[Resource] = []
	for path: String in SCENARIO_PATHS:
		result.append(load(path) as Resource)
	return result

static func validation_errors(definitions: Array[Resource] = scenario_definitions()) -> Array[String]:
	return SCENARIO_VALIDATOR_SCRIPT.validate(definitions, hazards(), districts()) as Array[String]

static func days() -> Array[Dictionary]:
	var definitions: Array[Resource] = scenario_definitions()
	var errors: Array[String] = validation_errors(definitions)
	for error: String in errors:
		push_error("Scenario validation: %s" % error)
	if not errors.is_empty():
		return []
	var result: Array[Dictionary] = []
	for definition: Resource in definitions:
		if definition != null and definition.get_script() == SCENARIO_DEFINITION_SCRIPT:
			result.append(definition.call("to_runtime_dictionary") as Dictionary)
	return result
