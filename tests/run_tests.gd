extends SceneTree

const SESSION_SAVE_SCRIPT: Script = preload("res://scripts/simulation/session_save.gd")
const MAIN_TEST_SAVE_PATH: String = "user://storm_desk_main_test.cfg"
const INVALID_TEST_SAVE_PATH: String = "user://storm_desk_invalid_test.cfg"

var failures: int = 0
var checks: int = 0

func _init() -> void:
	call_deferred("run_all")

func run_all() -> void:
	var hazards: Array[HazardDefinition] = ScenarioCatalog.hazards()
	var districts: Array[DistrictDefinition] = ScenarioCatalog.districts()
	var days: Array[Dictionary] = ScenarioCatalog.days()
	var scenario_definitions: Array[Resource] = ScenarioCatalog.scenario_definitions()
	check(scenario_definitions.size() == 5, "Five Inspector-editable scenario resources load from the catalog")
	check(ScenarioCatalog.validation_errors(scenario_definitions).is_empty(), "Authored scenario resources pass schema and reference validation")

	var malformed_definitions: Array[Resource] = duplicate_resources(scenario_definitions)
	malformed_definitions[1].set("day", 4)
	malformed_definitions[1].set("hazard", &"unknown_hazard")
	var invalid_threatened: Array[StringName] = [&"unknown_district"]
	malformed_definitions[1].set("threatened", invalid_threatened)
	var malformed_readings: Array = malformed_definitions[0].get("readings") as Array
	var duplicate_reading: Dictionary = malformed_readings[1] as Dictionary
	duplicate_reading["id"] = &"charge"
	var malformed_actions: Array = malformed_definitions[1].get("actions") as Array
	var malformed_action: Dictionary = malformed_actions[0] as Dictionary
	malformed_action["cost"] = 0
	malformed_action["requires_relay"] = &"unknown_site"
	var malformed_errors: Array[String] = ScenarioCatalog.validation_errors(malformed_definitions)
	check(errors_contain(malformed_errors, "sequential day order"), "Validator rejects out-of-order scenario days")
	check(errors_contain(malformed_errors, "unknown hazard"), "Validator rejects unknown hazard references")
	check(errors_contain(malformed_errors, "unknown district"), "Validator rejects unknown district references")
	check(errors_contain(malformed_errors, "duplicates reading id"), "Validator rejects duplicate reading IDs")
	check(errors_contain(malformed_errors, "cost must be greater than zero") and errors_contain(malformed_errors, "unknown required relay site"), "Validator rejects malformed reveal actions")

	var contradictory_definitions: Array[Resource] = duplicate_resources(scenario_definitions)
	var contradictory_readings: Array = contradictory_definitions[0].get("readings") as Array
	for reading_value: Variant in contradictory_readings:
		var contradictory_reading: Dictionary = reading_value as Dictionary
		contradictory_reading["supports"] = &"glasswind"
	var contradictory_errors: Array[String] = ScenarioCatalog.validation_errors(contradictory_definitions)
	check(errors_contain(contradictory_errors, "initially visible evidence favors"), "Validator rejects initially contradictory evidence")

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
	check(HazardEvaluator.best_match(days[3]["readings"], hazards) == &"glasswind", "Day Four remains classifiable before optional recovery evidence")
	check(HazardEvaluator.best_match(days[4]["readings"], hazards) == &"cloudburst", "Day Five's corroborating readings outweigh its contaminated crystal signal")

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
	check(days.size() == 5 and int(days[0]["day"]) == 1 and int(days[4]["day"]) == 5, "Five fixed scenarios load in order")
	check(not str(days[1].get("outlook", "")).is_empty() and not str(days[4].get("outlook", "")).is_empty(), "Upcoming forecast days provide non-solution maintenance outlooks")

	var network := NetworkModel.new()
	check(network.online_relays().has(&"ridge") and network.is_site_covered(&"harbor"), "Starter High Ridge relay covers downstream sites")
	check(network.has_online_sensor(&"industrial", &"electrical"), "Starter Industrial electrical sensor has an HQ path")
	check(network.install_sensor(&"farmland", &"crystal").is_empty() and network.has_online_sensor(&"farmland", &"crystal"), "Installed Farm Spire sensor becomes available through the relay graph")
	network.damage_relay(&"ridge")
	check(not network.has_online_sensor(&"farmland", &"crystal"), "Damaged relay disconnects its downstream sensor")
	check(not network.repair_site(&"ridge").is_empty() and network.has_online_sensor(&"farmland", &"crystal"), "Relay repair restores downstream readings")
	var alternate_network := NetworkModel.new()
	alternate_network.install_relay(&"industrial")
	alternate_network.install_sensor(&"harbor", &"moisture")
	alternate_network.install_sensor(&"farmland", &"crystal")
	alternate_network.damage_relay(&"ridge")
	check(alternate_network.has_online_sensor(&"harbor", &"moisture"), "Industrial relay provides an alternate Harbor route")
	check(alternate_network.has_online_sensor(&"farmland", &"crystal"), "Industrial relay provides an alternate Farm Spire route")
	var network_snapshot: Dictionary = alternate_network.snapshot()
	var restored_network := NetworkModel.new()
	check(restored_network.restore_snapshot(network_snapshot) and str(restored_network.snapshot()) == str(network_snapshot), "Network equipment and health round-trip through a save snapshot")
	var malformed_network_snapshot: Dictionary = network_snapshot.duplicate(true)
	(malformed_network_snapshot["equipment"] as Array).pop_back()
	check(not restored_network.restore_snapshot(malformed_network_snapshot), "Network restoration rejects incomplete site data")
	var opening_network := NetworkModel.new()
	var opening_events: Array[String] = opening_network.apply_opening_damage(days[3]["opening_damage"] as Array)
	check(not opening_events.is_empty() and not opening_network.online_relays().has(&"ridge"), "Day Four opening damage disables High Ridge deterministically")
	opening_network.install_relay(&"industrial")
	check(opening_network.is_site_covered(&"farmland") and opening_network.is_site_covered(&"harbor"), "Industrial construction restores both downstream routes")
	var exposed_network := NetworkModel.new()
	var no_warnings: Array[StringName] = []
	var network_damage: Array[String] = exposed_network.resolve_hazard(&"glasswind", &"sparkstorm", no_warnings, false)
	check(not network_damage.is_empty() and not exposed_network.online_relays().has(&"ridge"), "Unprotected Glasswind damage persists on High Ridge")

	var day_two_warned: Array[StringName] = [&"farmland", &"harbor"]
	var optimal_two: Dictionary = OutcomeCalculator.calculate(days[1], districts, &"glasswind", 2, day_two_warned, 1, 4)
	check(int(optimal_two["protected"]) == 2 and bool(optimal_two["correct_hazard"]), "Day Two can resolve with two protected districts")
	check(int(timely["protected"]) == 2 and bool(timely["correct_hazard"]), "Day Three can resolve with two protected districts")
	var day_four_warned: Array[StringName] = [&"farmland"]
	var optimal_four: Dictionary = OutcomeCalculator.calculate(days[3], districts, &"glasswind", 2, day_four_warned, 1, 5)
	check(int(optimal_four["damage"]) == 10 and not bool(optimal_four["late"]), "Day Four supports a timely one-action network recovery")
	var day_five_warned: Array[StringName] = [&"industrial", &"harbor"]
	var optimal_five: Dictionary = OutcomeCalculator.calculate(days[4], districts, &"cloudburst", 3, day_five_warned, 1, 1)
	check(int(optimal_five["damage"]) == 21 and int(optimal_five["protected"]) == 2, "Day Five's correct severe warning protects both threatened districts")

	var main_scene: PackedScene = load("res://scenes/main/main.tscn") as PackedScene
	var main: Control = main_scene.instantiate() as Control
	SESSION_SAVE_SCRIPT.delete(MAIN_TEST_SAVE_PATH)
	main.set("save_path", MAIN_TEST_SAVE_PATH)
	root.add_child(main)
	var initial_save_result: Dictionary = SESSION_SAVE_SCRIPT.read(MAIN_TEST_SAVE_PATH) as Dictionary
	check(bool(initial_save_result.get("ok", false)), "Starting a new first week creates a local autosave")
	var incompatible_config := ConfigFile.new()
	incompatible_config.set_value("meta", "format_version", 999)
	incompatible_config.set_value("session", "state", initial_save_result.get("state", {}))
	incompatible_config.save(INVALID_TEST_SAVE_PATH)
	var incompatible_result: Dictionary = SESSION_SAVE_SCRIPT.read(INVALID_TEST_SAVE_PATH) as Dictionary
	check(not bool(incompatible_result.get("ok", false)) and str(incompatible_result.get("error", "")).contains("unsupported format"), "Save loader rejects incompatible format versions safely")
	SESSION_SAVE_SCRIPT.delete(INVALID_TEST_SAVE_PATH)
	var corrupt_file: FileAccess = FileAccess.open(INVALID_TEST_SAVE_PATH, FileAccess.WRITE)
	corrupt_file.store_string("[this is not a valid ConfigFile")
	corrupt_file.close()
	var corrupt_result: Dictionary = SESSION_SAVE_SCRIPT.read(INVALID_TEST_SAVE_PATH) as Dictionary
	check(not bool(corrupt_result.get("ok", false)) and not bool(corrupt_result.get("missing", true)), "Save loader rejects unreadable files without treating them as absent")
	SESSION_SAVE_SCRIPT.delete(INVALID_TEST_SAVE_PATH)
	var malformed_state: Dictionary = (initial_save_result.get("state", {}) as Dictionary).duplicate(true)
	malformed_state["day_index"] = 99
	var malformed_save_errors: Array[String] = main.call("validate_saved_state", malformed_state) as Array[String]
	check(errors_contain(malformed_save_errors, "outside the current scenario catalog"), "Save validator rejects out-of-range campaign state")
	var original_budget: int = int(main.get("budget"))
	var original_used: int = int(main.get("observations_used"))
	main.call("set_phase", 1) # Observation: network requests are invalid here.
	main.call("request_observation", {"cost": 1, "reveals": &"invalid", "value": "invalid", "quality": "clear", "log": "invalid"})
	check(int(main.get("budget")) == original_budget and int(main.get("observations_used")) == original_used, "Invalid network action fails without changing state")
	main.call("set_phase", 2)
	main.call("select_network_site", &"farmland")
	var crystal_selector := OptionButton.new()
	crystal_selector.add_item("Crystal Sensor")
	crystal_selector.set_item_metadata(0, &"crystal")
	main.call("install_network_equipment", crystal_selector)
	check(StringName((main.get("network_model") as NetworkModel).equipment_at(&"farmland").get("sensor", &"")) == &"" and int(main.get("budget")) == original_budget, "Infrastructure installation is rejected outside overnight maintenance")

	# Drive the actual coordinator through the complete deterministic first week.
	main.call("set_phase", 3)
	main.call("on_hazard_selected", 1) # Sparkstorm
	main.call("on_district_toggled", true, &"industrial")
	var district_buttons: Dictionary = main.get("district_buttons") as Dictionary
	check((district_buttons[&"industrial"] as Button).text.contains("WARNING"), "Warning selection adds a labeled district-map marker")
	var warning_summary: Label = main.get("warning_summary_label") as Label
	check(warning_summary.text.contains("SPARKSTORM") and warning_summary.text.contains("Industrial"), "Warning desk presents a live hazard and district summary")
	var feedback_label: Label = main.get("action_feedback_label") as Label
	check(feedback_label.text.contains("Added warning marker"), "Footer provides immediate warning-selection feedback")
	var draft_save_result: Dictionary = SESSION_SAVE_SCRIPT.read(MAIN_TEST_SAVE_PATH) as Dictionary
	var draft_save_state: Dictionary = draft_save_result.get("state", {}) as Dictionary
	check(StringName(draft_save_state.get("selected_hazard", &"")) == &"sparkstorm" and (draft_save_state.get("warned_districts", []) as Array).has(&"industrial"), "Autosave records the editable warning draft")
	main.call("confirm_warning")
	check((main.get("reports") as Array).size() == 1 and int(main.get("day_index")) == 0, "Coordinator resolves Day One and records its report")
	check(node_contains_text(main.get("modal_layer") as Node, "ASSESSMENT: EFFECTIVE WARNING"), "Daily report opens with a plain-language outcome assessment")
	check((district_buttons[&"industrial"] as Button).text.contains("PROTECTED"), "Resolved warning leaves a labeled protected-district marker")
	main.call("open_maintenance")
	main.call("close_modal")
	check(int(main.get("phase")) == 8 and int(main.get("maintenance_actions_used")) == 0, "Day One report opens the separate overnight maintenance phase")
	var pre_maintenance_collection_budget: int = int(main.get("budget"))
	main.call("collect_connected_readings")
	check(int(main.get("observations_used")) == 0 and int(main.get("budget")) == pre_maintenance_collection_budget, "Daily reading collection is rejected during overnight maintenance")
	main.call("select_network_site", &"farmland")
	main.call("install_network_equipment", crystal_selector)
	check(int(main.get("maintenance_actions_used")) == 1 and int(main.get("observations_used")) == 0, "Overnight construction uses maintenance without consuming daily observation capacity")
	var maintenance_save_result: Dictionary = SESSION_SAVE_SCRIPT.read(MAIN_TEST_SAVE_PATH) as Dictionary
	var maintenance_save_state: Dictionary = maintenance_save_result.get("state", {}) as Dictionary
	var saved_maintenance_network := NetworkModel.new()
	var maintenance_network_restored: bool = saved_maintenance_network.restore_snapshot(maintenance_save_state.get("network", {}) as Dictionary)
	check(int(maintenance_save_state.get("maintenance_actions_used", 0)) == 1 and maintenance_network_restored and saved_maintenance_network.has_online_sensor(&"farmland", &"crystal"), "Autosave records overnight action use and installed equipment")
	var budget_after_first_maintenance: int = int(main.get("budget"))
	main.call("select_network_site", &"industrial")
	var relay_selector := OptionButton.new()
	relay_selector.add_item("Relay")
	relay_selector.set_item_metadata(0, &"relay")
	main.call("install_network_equipment", relay_selector)
	check(int(main.get("budget")) == budget_after_first_maintenance and not (main.get("network_model") as NetworkModel).online_relays().has(&"industrial"), "A second infrastructure action is rejected during the same night")
	main.call("on_continue_pressed")
	main.call("set_phase", 2)
	main.call("collect_connected_readings")
	check(int(main.get("observations_used")) == 1, "Day Two spends daily capacity collecting from the overnight sensor")
	check(str(reading_by_id(main.get("readings") as Array, &"crystal").get("quality", "missing")) == "clear", "Connected Crystal Sensor reveals the missing Day Two evidence")
	var day_two_save_result: Dictionary = SESSION_SAVE_SCRIPT.read(MAIN_TEST_SAVE_PATH) as Dictionary
	var day_two_save_state: Dictionary = day_two_save_result.get("state", {}) as Dictionary
	var resumed_main: Control = main_scene.instantiate() as Control
	resumed_main.set("save_path", MAIN_TEST_SAVE_PATH)
	root.add_child(resumed_main)
	check(node_contains_text(resumed_main.get("modal_layer") as Node, "CONTINUE FIRST WEEK"), "A later launch offers Resume and Start New for a valid autosave")
	resumed_main.call("close_modal")
	resumed_main.call("restore_session", day_two_save_state)
	var resumed_network: NetworkModel = resumed_main.get("network_model") as NetworkModel
	check(int(resumed_main.get("day_index")) == 1 and int(resumed_main.get("phase")) == 2 and int(resumed_main.get("observations_used")) == 1, "Resume restores the exact Day Two phase and spent observation capacity")
	check(str(reading_by_id(resumed_main.get("readings") as Array, &"crystal").get("quality", "missing")) == "clear" and resumed_network.has_online_sensor(&"farmland", &"crystal"), "Resume restores revealed evidence and persistent network equipment")
	resumed_main.queue_free()
	main.call("set_phase", 3)
	main.call("on_hazard_selected", 2) # Glasswind
	main.call("on_district_toggled", true, &"farmland")
	main.call("on_district_toggled", true, &"harbor")
	main.call("confirm_warning")
	check((main.get("reports") as Array).size() == 2 and int(main.get("day_index")) == 1, "Coordinator resolves Day Two and records its report")
	var session_network: NetworkModel = main.get("network_model") as NetworkModel
	main.call("open_maintenance")
	main.call("close_modal")
	main.call("select_network_site", &"harbor")
	var moisture_selector := OptionButton.new()
	moisture_selector.add_item("Moisture Sensor")
	moisture_selector.set_item_metadata(0, &"moisture")
	main.call("install_network_equipment", moisture_selector)
	main.call("on_continue_pressed")
	check(session_network.has_online_sensor(&"farmland", &"crystal"), "Constructed sensor persists into Day Three")
	check(session_network.has_online_sensor(&"harbor", &"moisture"), "Second-night Harbor sensor persists into Day Three")
	main.call("set_phase", 2)
	main.call("collect_connected_readings")
	check(str(reading_by_id(main.get("readings") as Array, &"condensation").get("quality", "missing")) == "clear", "Day Three collects Harbor condensation from overnight infrastructure")
	main.call("set_phase", 3)
	main.call("on_hazard_selected", 3) # Cloudburst
	main.set("selected_severity", 3)
	main.call("on_district_toggled", true, &"farmland")
	main.call("on_district_toggled", true, &"harbor")
	main.call("confirm_warning")
	check((main.get("reports") as Array).size() == 3 and int(main.get("day_index")) == 2, "Coordinator completes the original three-day arc")
	main.call("open_maintenance")
	main.call("close_modal")
	check(int(main.get("phase")) == 8 and not session_network.online_relays().has(&"ridge"), "Day Four's forecast outage is applied when the preceding maintenance desk opens")
	main.call("select_network_site", &"industrial")
	main.call("install_network_equipment", relay_selector)
	check(int(main.get("maintenance_actions_used")) == 1 and session_network.online_relays().has(&"industrial"), "Pre-Day Four maintenance can build the alternate relay")
	check(session_network.has_online_sensor(&"farmland", &"crystal"), "Industrial alternate route reconnects the persistent Farm Spire sensor")
	main.call("on_continue_pressed")
	check(int((main.get("scenario") as Dictionary)["day"]) == 4 and not session_network.online_relays().has(&"ridge"), "The briefed High Ridge outage persists into Day Four")
	main.call("set_phase", 2)
	main.call("collect_connected_readings")
	check(str(reading_by_id(main.get("readings") as Array, &"crystal").get("quality", "missing")) == "clear", "Restored routing immediately delivers Day Four crystal evidence")
	main.call("set_phase", 3)
	main.call("on_hazard_selected", 2) # Glasswind
	main.call("on_district_toggled", true, &"farmland")
	main.call("confirm_warning")
	check((main.get("reports") as Array).size() == 4 and int(main.get("day_index")) == 3, "Coordinator resolves the Day Four recovery scenario")
	main.call("open_maintenance")
	main.call("close_modal")
	main.call("select_network_site", &"ridge")
	main.call("repair_selected_site")
	check(int(main.get("maintenance_actions_used")) == 1 and session_network.online_relays().has(&"ridge"), "Final-night maintenance can repair High Ridge without spending forecast capacity")
	main.call("on_continue_pressed")
	check(int((main.get("scenario") as Dictionary)["day"]) == 5 and session_network.online_relays().has(&"industrial"), "Alternate construction persists into the final day")
	main.call("set_phase", 2)
	main.call("collect_connected_readings")
	check(str(reading_by_id(main.get("readings") as Array, &"condensation").get("quality", "missing")) == "clear", "Day Five collects final evidence from persistent Harbor infrastructure")
	main.call("set_phase", 3)
	main.call("on_hazard_selected", 3) # Cloudburst
	main.set("selected_severity", 3)
	main.call("on_district_toggled", true, &"industrial")
	main.call("on_district_toggled", true, &"harbor")
	main.call("confirm_warning")
	check((main.get("reports") as Array).size() == 5 and int(main.get("day_index")) == 4, "Coordinator completes all five first-week scenarios")
	main.call("show_final_report")
	check(int(main.get("phase")) == 7, "Coordinator reaches the five-day performance report")
	check(not SESSION_SAVE_SCRIPT.exists(MAIN_TEST_SAVE_PATH), "Completing the first week clears its resumable autosave")
	main.set("budget", 1)
	main.set("trust", 2)
	main.call("restart_session")
	check(int(main.get("budget")) == 30 and int(main.get("trust")) == 50 and int(main.get("day_index")) == 0, "Restart resets the session without restarting the application")
	check(StringName((main.get("network_model") as NetworkModel).equipment_at(&"farmland").get("sensor", &"")) == &"", "Restart resets persistent network construction")
	check(SESSION_SAVE_SCRIPT.exists(MAIN_TEST_SAVE_PATH), "Restart creates a fresh Day One autosave")

	var tutorial: TutorialController = main.get("tutorial_controller") as TutorialController
	tutorial.persistence_enabled = false
	main.call("close_modal")
	main.call("set_phase", 1)
	tutorial.start()
	check(tutorial.active and tutorial.current_step == 0 and tutorial.overlay.visible, "Guided tour starts on the Day One Observation interface")
	tutorial.on_target_clicked()
	main.call("show_district", district_by_id(districts, &"farmland"))
	check(tutorial.current_step == 2, "Tour requires a real district inspection before advancing")
	tutorial.on_target_clicked() # Readings
	tutorial.on_target_clicked() # Help
	tutorial.on_target_clicked() # Event log
	check(tutorial.current_step == 5, "Informational highlights advance in the intended order")
	main.call("set_phase", 2)
	check(tutorial.current_step == 6, "Network Planning phase action advances to the network highlight")
	tutorial.on_target_clicked()
	main.call("set_phase", 3)
	main.call("on_hazard_selected", 1)
	tutorial.on_target_clicked() # Severity
	main.call("on_district_toggled", true, &"industrial")
	check(tutorial.current_step == 11, "Warning tour requires real hazard and district interactions")
	main.call("set_phase", 4)
	check(not tutorial.active and not tutorial.overlay.visible, "Tour completes at Warning Review and removes its input mask")
	tutorial.start()
	tutorial.skip_permanently()
	check(not tutorial.active and not tutorial.overlay.visible, "Skip immediately dismisses an active tour")

	var persistence_test := TutorialController.new()
	root.add_child(persistence_test)
	persistence_test.config_path = "user://storm_desk_tutorial_test.cfg"
	persistence_test.reset_completion()
	check(persistence_test.should_offer(), "Reset tutorial preference makes onboarding available")
	persistence_test.finish(true)
	check(not persistence_test.should_offer(), "Completed or skipped tour persists its dismissal preference")
	var tutorial_test_path: String = ProjectSettings.globalize_path(persistence_test.config_path)
	if FileAccess.file_exists(tutorial_test_path):
		DirAccess.remove_absolute(tutorial_test_path)
	persistence_test.queue_free()
	main.queue_free()
	SESSION_SAVE_SCRIPT.delete(MAIN_TEST_SAVE_PATH)
	SESSION_SAVE_SCRIPT.delete(INVALID_TEST_SAVE_PATH)

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

func reading_by_id(readings: Array, id: StringName) -> Dictionary:
	for reading: Dictionary in readings:
		if StringName(reading.get("id", &"")) == id:
			return reading
	return {}

func node_contains_text(node: Node, expected: String) -> bool:
	if node is Label and (node as Label).text.contains(expected):
		return true
	for child: Node in node.get_children():
		if node_contains_text(child, expected):
			return true
	return false

func duplicate_resources(resources: Array[Resource]) -> Array[Resource]:
	var result: Array[Resource] = []
	for resource: Resource in resources:
		result.append(resource.duplicate(true) as Resource)
	return result

func errors_contain(errors: Array[String], expected: String) -> bool:
	for error: String in errors:
		if error.contains(expected):
			return true
	return false

func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS  %s" % description)
	else:
		failures += 1
		push_error("FAIL  %s" % description)
