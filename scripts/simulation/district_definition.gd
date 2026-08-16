class_name DistrictDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var vulnerability: Dictionary = {}
@export var base_damage: int = 12

func vulnerability_for(hazard_id: StringName) -> float:
	return float(vulnerability.get(hazard_id, 1.0))

