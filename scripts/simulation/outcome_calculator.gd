class_name OutcomeCalculator
extends RefCounted

static func calculate(
		scenario: Dictionary,
		districts: Array[DistrictDefinition],
		chosen_hazard: StringName,
		chosen_severity: int,
		warned_districts: Array[StringName],
		actions_used: int,
		observation_spend: int
	) -> Dictionary:
	var actual_hazard: StringName = scenario["hazard"] as StringName
	var actual_severity: int = int(scenario["severity"])
	var threatened: Array = scenario["threatened"] as Array
	var correct_hazard: bool = chosen_hazard == actual_hazard
	var late: bool = actions_used > int(scenario.get("safe_actions", 99))
	var trust_delta: int = 0
	var total_damage: int = 0
	var lines: Array[String] = []
	var false_warnings: int = 0
	var protected_count: int = 0
	var missed_count: int = 0

	for district: DistrictDefinition in districts:
		var is_threatened: bool = threatened.has(district.id)
		var was_warned: bool = warned_districts.has(district.id)
		if is_threatened:
			var raw_damage: int = roundi(float(district.base_damage * actual_severity) * district.vulnerability_for(actual_hazard))
			var final_damage: int = raw_damage
			if correct_hazard and was_warned:
				var reduction: float = 0.40 if late else 0.75
				if chosen_severity < actual_severity:
					reduction *= 0.70
				final_damage = roundi(float(raw_damage) * (1.0 - reduction))
				trust_delta += 2 if late else 3
				protected_count += 1
				lines.append("%s: %d raw damage - %d%% preparation = %d damage; trust %+d." % [district.display_name, raw_damage, roundi(reduction * 100.0), final_damage, 2 if late else 3])
			else:
				trust_delta -= 4
				missed_count += 1
				lines.append("%s: %d damage; no useful warning, trust -4." % [district.display_name, final_damage])
			total_damage += final_damage
		elif was_warned:
			false_warnings += 1
			trust_delta -= 2
			lines.append("%s: not threatened; unnecessary warning, trust -2." % district.display_name)

	if correct_hazard and chosen_severity > actual_severity:
		trust_delta -= 2
		lines.append("Severity was exaggerated; trust -2.")
	elif correct_hazard and chosen_severity < actual_severity:
		trust_delta -= 1
		lines.append("Severity was underestimated; trust -1 and protection was reduced.")
	elif chosen_hazard != &"" and not correct_hazard:
		trust_delta -= 2
		lines.append("Wrong hazard classification; trust -2.")

	var warning_cost: int = warned_districts.size() * 2
	var repair_cost: int = ceili(float(total_damage) / 5.0)
	var daily_allocation: int = 8
	var budget_delta: int = daily_allocation - observation_spend - warning_cost - repair_cost
	lines.append("Budget: +%d allocation -%d observations -%d warning operations -%d repairs = %+d." % [daily_allocation, observation_spend, warning_cost, repair_cost, budget_delta])
	return {
		"correct_hazard": correct_hazard,
		"late": late,
		"trust_delta": trust_delta,
		"budget_delta": budget_delta,
		"damage": total_damage,
		"protected": protected_count,
		"missed": missed_count,
		"false_warnings": false_warnings,
		"lines": lines,
	}

