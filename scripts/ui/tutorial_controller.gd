class_name TutorialController
extends Node

const CONFIG_PATH := "user://settings.cfg"
const CONFIG_SECTION := "onboarding"
const CONFIG_KEY := "completed"

var host: Node
var target_provider: Callable
var overlay: TutorialOverlay
var steps: Array[Dictionary] = []
var current_step: int = -1
var active: bool = false
var persistence_enabled: bool = true
var config_path: String = CONFIG_PATH
var target_retry_count: int = 0

func setup(host_node: Node, provider: Callable) -> void:
	host = host_node
	target_provider = provider
	steps = build_steps()
	overlay = TutorialOverlay.new()
	host.add_child(overlay)
	overlay.target_clicked.connect(on_target_clicked)
	overlay.skip_requested.connect(skip_permanently)
	if host.has_signal("phase_changed"):
		host.connect("phase_changed", on_phase_changed)
	if host.has_signal("district_inspected"):
		host.connect("district_inspected", on_district_inspected)
	if host.has_signal("hazard_selection_made"):
		host.connect("hazard_selection_made", on_hazard_selection_made)
	if host.has_signal("district_warning_changed"):
		host.connect("district_warning_changed", on_district_warning_changed)

func build_steps() -> Array[Dictionary]:
	return [
		{"target": &"header", "title": "Bureau Status", "body": "This header always shows the current day, budget, public trust, and remaining action capacity.", "mode": &"info"},
		{"target": &"district_map", "title": "Know the Districts", "body": "Select any district card to inspect its hazard vulnerabilities and preparation needs.", "mode": &"district"},
		{"target": &"readings", "title": "Read the Evidence", "body": "Instrument cards report values and quality. CLEAR readings are dependable; MISSING, IMPRECISE, and SUSPECT readings require judgment.", "mode": &"info"},
		{"target": &"help", "title": "Weather Rules", "body": "Rules / Help contains the three fictional evidence patterns. You can also replay this guided tour from there.", "mode": &"info"},
		{"target": &"event_log", "title": "Operations Log", "body": "The log confirms selections, network actions, rejected actions, and newly delivered readings.", "mode": &"info"},
		{"target": &"continue", "title": "Advance the Phase", "body": "Use the primary footer button when you have finished the current phase. Move into Network Planning now.", "mode": &"phase", "phase": 2},
		{"target": &"network", "title": "Plan the Network", "body": "Select fixed sites, inspect relay paths, and install, repair, collect, or survey. Every action shows its budget cost and consumes capacity.", "mode": &"info"},
		{"target": &"continue", "title": "Decide When to Stop", "body": "More evidence can improve confidence, but later actions can delay warnings. Proceed when the evidence is sufficient.", "mode": &"phase", "phase": 3},
		{"target": &"hazard", "title": "Classify the Hazard", "body": "Choose the fictional hazard supported by the evidence, or explicitly stand down with no warning.", "mode": &"hazard"},
		{"target": &"severity", "title": "Declare Severity", "body": "Severity affects whether protection matches the actual threat. Exaggeration and underestimation both have consequences.", "mode": &"info"},
		{"target": &"warning_districts", "title": "Choose Who to Warn", "body": "Select at least one district using its exposure and vulnerability. False warnings cost trust; missed districts take full damage.", "mode": &"district_warning"},
		{"target": &"continue", "title": "Review Before Sending", "body": "Review the warning summary. Choices remain editable until you confirm the warning.", "mode": &"phase", "phase": 4},
	]

func should_offer() -> bool:
	if not persistence_enabled:
		return true
	var config := ConfigFile.new()
	if config.load(config_path) != OK:
		return true
	return not bool(config.get_value(CONFIG_SECTION, CONFIG_KEY, false))

func start() -> void:
	active = true
	current_step = 0
	target_retry_count = 0
	show_current_step()

func skip_permanently() -> void:
	finish(true)

func reset_completion() -> void:
	if not persistence_enabled:
		return
	var config := ConfigFile.new()
	config.load(config_path)
	config.set_value(CONFIG_SECTION, CONFIG_KEY, false)
	config.save(config_path)

func finish(save_completion: bool = true) -> void:
	active = false
	current_step = -1
	if overlay != null:
		overlay.dismiss()
	if save_completion:
		save_completed()

func save_completed() -> void:
	if not persistence_enabled:
		return
	var config := ConfigFile.new()
	config.load(config_path)
	config.set_value(CONFIG_SECTION, CONFIG_KEY, true)
	config.save(config_path)

func show_current_step() -> void:
	if not active:
		return
	if current_step >= steps.size():
		finish(true)
		return
	var step: Dictionary = steps[current_step]
	var target: Control = target_provider.call(StringName(step["target"])) as Control
	if target == null or not target.is_visible_in_tree():
		target_retry_count += 1
		if target_retry_count > 5:
			push_warning("Skipping unavailable tutorial target: %s" % str(step["target"]))
			advance()
		else:
			call_deferred("show_current_step")
		return
	target_retry_count = 0
	var informational: bool = StringName(step["mode"]) == &"info"
	overlay.present(target, str(step["title"]), str(step["body"]), "%d / %d" % [current_step + 1, steps.size()], informational)

func advance() -> void:
	if not active:
		return
	current_step += 1
	target_retry_count = 0
	if current_step >= steps.size():
		finish(true)
	else:
		call_deferred("show_current_step")

func on_target_clicked() -> void:
	if active and StringName(steps[current_step]["mode"]) == &"info":
		advance()

func on_district_inspected() -> void:
	if active and StringName(steps[current_step]["mode"]) == &"district":
		advance()

func on_hazard_selection_made() -> void:
	if active and StringName(steps[current_step]["mode"]) == &"hazard":
		advance()

func on_district_warning_changed() -> void:
	if active and StringName(steps[current_step]["mode"]) == &"district_warning":
		advance()

func on_phase_changed(phase_value: int) -> void:
	if not active or current_step < 0 or current_step >= steps.size():
		return
	var step: Dictionary = steps[current_step]
	if StringName(step["mode"]) == &"phase" and int(step["phase"]) == phase_value:
		advance()
