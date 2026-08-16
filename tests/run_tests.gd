extends SceneTree

var failures: int = 0
var checks: int = 0

func _init() -> void:
	call_deferred("run_all")

func run_all() -> void:
	var hazards: Array[HazardDefinition] = ScenarioCatalog.hazards()
	var districts: Array[DistrictDefinition] = ScenarioCatalog.districts()
	var days: Array[Dictionary] = ScenarioCatalog.days()

	# Day One is intentionally validated first as the vertical slice.
	var day_one_warned: Array[StringName] = [&"industrial"]
	var day_one: Dictionary = OutcomeCalculator.calculate(days[0], districts, &"sparkstorm", 2, day_one_warned, 0, 0)
	check(bool(day_one["correct_hazard"]), "Day One identifies the correct hazard")
	check(int(day_one["protected"]) == 1, "Day One protects Industrial District")
	check(int(day_one["damage"]) == 11, "Day One timely warning reduces rounded damage to 11")
	check(int(day_one["trust_delta"]) == 3, "Day One useful warning gains 3 trust")
	check(int(day_one["budget_delta"]) == 3, "Day One economy calculation is reproducible")

	check(HazardEvaluator.best_match(days[0]["readings"], hazards) == &"sparkstorm", "Clear readings score Sparkstorm highest")
	check(HazardEvaluator.best_match(days[2]["readings"], hazards) == &"cloudburst", "Two corroborating Day Three readings outweigh one faulty signal")

	var farmland: DistrictDefinition = district_by_id(districts, &"farmland")
	var industrial: DistrictDefinition = district_by_id(districts, &"industrial")
	var harbor: DistrictDefinition = district_by_id(districts, &"harbor")
	check(farmland.vulnerability_for(&"glasswind") > industrial.vulnerability_for(&"glasswind"), "Farmland is most vulnerable to Glasswind")
	check(industrial.vulnerability_for(&"sparkstorm") > harbor.vulnerability_for(&"sparkstorm"), "Industrial is most vulnerable to Sparkstorms")
	check(harbor.vulnerability_for(&"cloudburst") > farmland.vulnerability_for(&"cloudburst"), "Harbor is most vulnerable to Cloudbursts")

	var day_three_warned: Array[StringName] = [&"farmland", &"harbor"]
	var timely: Dictionary = OutcomeCalculator.calculate(days[2], districts, &"cloudburst", 3, day_three_warned, 1, 4)
	var late: Dictionary = OutcomeCalculator.calculate(days[2], districts, &"cloudburst", 3, day_three_warned, 2, 7)
	check(not bool(timely["late"]) and bool(late["late"]), "Warning timing changes after the safe action limit")
	check(int(late["damage"]) > int(timely["damage"]), "Late warnings reduce less damage")
	check(int(late["trust_delta"]) < int(timely["trust_delta"]), "Late warnings gain less trust")

	var wrong_warned: Array[StringName] = [&"farmland"]
	var wrong: Dictionary = OutcomeCalculator.calculate(days[0], districts, &"glasswind", 2, wrong_warned, 0, 0)
	check(int(wrong["missed"]) == 1 and int(wrong["false_warnings"]) == 1, "Wrong warning produces both a miss and false warning")
	check(int(wrong["trust_delta"]) < 0, "Wrong warning loses trust")
	check(int(wrong["budget_delta"]) < int(day_one["budget_delta"]), "Damage and false operations worsen budget")

	var no_districts: Array[StringName] = []
	var missed: Dictionary = OutcomeCalculator.calculate(days[0], districts, &"", 2, no_districts, 0, 0)
	check(int(missed["damage"]) == 42 and int(missed["trust_delta"]) == -4, "Standing down causes full vulnerable-district damage and trust loss")

	var fresh_days: Array[Dictionary] = ScenarioCatalog.days()
	check(str(days) == str(fresh_days), "Scenario catalog is deterministic across loads")
	check(days.size() == 3 and int(days[0]["day"]) == 1 and int(days[2]["day"]) == 3, "Three fixed scenarios load in order")

	var day_two_warned: Array[StringName] = [&"farmland", &"harbor"]
	var optimal_two: Dictionary = OutcomeCalculator.calculate(days[1], districts, &"glasswind", 2, day_two_warned, 1, 4)
	check(int(optimal_two["protected"]) == 2 and bool(optimal_two["correct_hazard"]), "Day Two can resolve with two protected districts")
	check(int(timely["protected"]) == 2 and bool(timely["correct_hazard"]), "Day Three can resolve with two protected districts")

	var main_scene: PackedScene = load("res://scenes/main/main.tscn") as PackedScene
	var main: Control = main_scene.instantiate() as Control
	root.add_child(main)
	var original_budget: int = int(main.get("budget"))
	var original_used: int = int(main.get("observations_used"))
	main.call("set_phase", 1) # Observation: network requests are invalid here.
	main.call("request_observation", {"cost": 1, "reveals": &"invalid", "value": "invalid", "quality": "clear", "log": "invalid"})
	check(int(main.get("budget")) == original_budget and int(main.get("observations_used")) == original_used, "Invalid network action fails without changing state")

	# Drive the actual coordinator through all three deterministic days.
	main.call("set_phase", 3)
	main.call("on_hazard_selected", 1) # Sparkstorm
	main.call("on_district_toggled", true, &"industrial")
	main.call("confirm_warning")
	check((main.get("reports") as Array).size() == 1 and int(main.get("day_index")) == 0, "Coordinator resolves Day One and records its report")
	main.call("advance_day")
	main.call("set_phase", 2)
	var day_two_action: Dictionary = ((main.get("scenario") as Dictionary)["actions"] as Array)[0]
	main.call("request_observation", day_two_action)
	check(int(main.get("observations_used")) == 1, "Day Two coordinator reveals one paid network observation")
	main.call("set_phase", 3)
	main.call("on_hazard_selected", 2) # Glasswind
	main.call("on_district_toggled", true, &"farmland")
	main.call("on_district_toggled", true, &"harbor")
	main.call("confirm_warning")
	check((main.get("reports") as Array).size() == 2 and int(main.get("day_index")) == 1, "Coordinator resolves Day Two and records its report")
	main.call("advance_day")
	main.call("set_phase", 2)
	var day_three_action: Dictionary = ((main.get("scenario") as Dictionary)["actions"] as Array)[0]
	main.call("request_observation", day_three_action)
	main.call("set_phase", 3)
	main.call("on_hazard_selected", 3) # Cloudburst
	main.call("on_district_toggled", true, &"farmland")
	main.call("on_district_toggled", true, &"harbor")
	main.call("confirm_warning")
	check((main.get("reports") as Array).size() == 3 and int(main.get("day_index")) == 2, "Coordinator completes all three prototype days")
	main.call("show_final_report")
	check(int(main.get("phase")) == 7, "Coordinator reaches the final performance report")
	main.set("budget", 1)
	main.set("trust", 2)
	main.call("restart_session")
	check(int(main.get("budget")) == 30 and int(main.get("trust")) == 50 and int(main.get("day_index")) == 0, "Restart resets the session without restarting the application")
	main.queue_free()

	if failures == 0:
		print("PASS: %d checks" % checks)
		quit(0)
	else:
		push_error("FAIL: %d of %d checks failed" % [failures, checks])
		quit(1)

func district_by_id(districts: Array[DistrictDefinition], id: StringName) -> DistrictDefinition:
	for district: DistrictDefinition in districts:
		if district.id == id:
			return district
	return districts[0]

func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS  %s" % description)
	else:
		failures += 1
		push_error("FAIL  %s" % description)
