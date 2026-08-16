class_name HazardEvaluator
extends RefCounted

static func scores(readings: Array, hazards: Array[HazardDefinition]) -> Dictionary:
	var result: Dictionary = {}
	for hazard: HazardDefinition in hazards:
		result[hazard.id] = 0.0
	for reading: Dictionary in readings:
		if not bool(reading.get("visible", false)):
			continue
		if str(reading.get("quality", "missing")) == "missing":
			continue
		var support: StringName = reading.get("supports", &"") as StringName
		if not result.has(support):
			continue
		var weight: float = 1.0
		match str(reading.get("quality", "clear")):
			"imprecise":
				weight = 0.5
			"faulty":
				weight = 1.0
		result[support] = float(result[support]) + weight
	return result

static func best_match(readings: Array, hazards: Array[HazardDefinition]) -> StringName:
	var result: Dictionary = scores(readings, hazards)
	var best_id: StringName = &""
	var best_score: float = -1.0
	for hazard: HazardDefinition in hazards:
		var score: float = float(result.get(hazard.id, 0.0))
		if score > best_score:
			best_score = score
			best_id = hazard.id
	return best_id
