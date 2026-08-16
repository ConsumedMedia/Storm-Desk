class_name ScenarioDefinition
extends Resource

@export_range(1, 99, 1) var day: int = 1
@export var title: String
@export_multiline var outlook: String
@export_multiline var briefing: String
@export_multiline var tutorial: String
@export var hazard: StringName
@export_range(1, 3, 1) var severity: int = 1
@export var threatened: Array[StringName] = []
@export_range(0, 9, 1) var capacity: int = 0
@export_range(0, 9, 1) var safe_actions: int = 0
@export var readings: Array[Dictionary] = []
@export var actions: Array[Dictionary] = []
@export var opening_damage: Array[Dictionary] = []
@export_multiline var outcome_note: String

func to_runtime_dictionary() -> Dictionary:
	return {
		"day": day,
		"title": title,
		"outlook": outlook,
		"briefing": briefing,
		"tutorial": tutorial,
		"hazard": hazard,
		"severity": severity,
		"threatened": threatened.duplicate(),
		"capacity": capacity,
		"safe_actions": safe_actions,
		"readings": readings.duplicate(true),
		"actions": actions.duplicate(true),
		"opening_damage": opening_damage.duplicate(true),
		"outcome_note": outcome_note,
	}
