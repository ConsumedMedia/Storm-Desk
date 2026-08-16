class_name HazardDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var evidence_summary: String
@export_multiline var threat_summary: String
@export var evidence_keys: Array[StringName] = []

