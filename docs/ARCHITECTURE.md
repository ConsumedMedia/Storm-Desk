# Architecture

## Runtime composition

`scenes/main/main.tscn` is a minimal full-window Control root. `scripts/ui/main_controller.gd` creates the container-based interface and coordinates the session. There are no autoloads.

The coordinator owns transient session state: day index, explicit phase enum, budget, trust, observation usage/spend, current readings, warning choices, accumulated reports, and one persistent `NetworkModel`. Modal panels provide briefing, help, confirmation, daily results, and the final report. It exposes named tutorial targets and emits phase/interaction signals, but does not own tour sequencing. Standard Godot controls provide focus and disabled-state behavior.

## State flow

The phase enum is explicit:

1. Morning Briefing
2. Observation
3. Network Planning
4. Warning Decision
5. Warning Confirmation
6. Storm Resolution
7. Daily Report
8. Final Report

`set_phase()` is the single presentation transition point. It updates the phase label, required next action, active panel, and continue-button state. Warning choices remain editable until confirmation. Result and final-report callbacks advance the deterministic session or call `restart_session()`.

## Simulation boundary

- `hazard_definition.gd` and `district_definition.gd` define typed custom Resource schemas.
- `resources/hazards/*.tres` contains names, evidence patterns, and threats.
- `resources/districts/*.tres` contains descriptions, base damage, and per-hazard vulnerability multipliers.
- `scenario_catalog.gd` is deterministic content data for the three prototype days. Scenario dictionaries contain briefing copy, ground truth, readings with quality metadata, network actions, capacity, safe-action timing limits, and evidence explanations.
- `network_model.gd` owns five fixed sites, graph edges, relay reachability, sensor/relay slots, equipment health, installation, alternate routing, repairs, and persistent hazard damage. Bureau HQ and healthy connected relays form the traversal graph; a sensor is available when its site touches that graph.
- `network_diagram.gd` is a replaceable Control view of `NetworkModel`. It draws labeled nodes and edges, accepts site selection, and never owns simulation truth.
- `tutorial_controller.gd` owns the 12-step onboarding sequence, host-signal gating, skip/completion state, and one `ConfigFile` preference at `user://settings.cfg`. It resolves targets through the main controller's `tutorial_target()` callable, so no step contains screen coordinates.
- `tutorial_overlay.gd` owns presentation and input masking. Four blocking rectangles leave a live cutout around the target; a labeled border and popup are clamped to the viewport. Informational targets use a transparent click catcher, while action targets leave the underlying Godot Control interactive.
- `hazard_evaluator.gd` scores visible evidence independently of the UI. Imprecise evidence carries half weight; faulty evidence initially appears plausible until contradicted.
- `outcome_calculator.gd` is a pure calculation boundary for threat coverage, timing, severity, damage, trust, and budget.

## Outcome model

For each threatened district, raw damage is:

`round(base damage × actual severity × district vulnerability)`

A correct timely warning reduces 75%; a correct late warning reduces 40%. Underestimating severity reduces protection to 70% of that reduction. Useful warnings gain trust; late warnings gain less. Misses, false warnings, wrong classifications, and severity errors lose trust.

Each day adds an allocation of 8, then subtracts observation spend, two budget per warned district, and `ceil(total damage / 5)` repairs. Observation costs are deducted at purchase time in the coordinator; the post-result application avoids charging them twice.

## Network model

The starter network contains Bureau HQ, a healthy High Ridge relay, and an Industrial electrical sensor. Farm Spire, Industrial Mast, Harbor Buoy, and High Ridge are fixed construction sites. Each non-HQ site has an independent relay slot and sensor slot. Sensor types are electrical, crystal, and moisture.

Installations, repairs, collections, and scenario surveys each consume one observation-capacity unit and their displayed budget cost. Newly installed sensors immediately deliver a relevant reading when connected. Relay installation or repair synchronizes newly reachable sensors, avoiding order-dependent dead ends. Equipment state persists across days; restart restores only the starter network.

Missed protection has infrastructure consequences: Sparkstorms can damage the Industrial sensor, Glasswind can damage High Ridge, and Cloudbursts can damage Harbor equipment. Correct timely warnings to the relevant district protect that equipment. The daily calculation report records any damage, and the final report lists the remaining network.

## Adding content

Add hazard and district definitions as `.tres` files and register their paths in `ScenarioCatalog`. For a new fixed prototype day, add a deterministic scenario function with quality-tagged readings and explicit reveal actions. If scenario volume grows beyond this prototype, migrate scenario records to custom Resources while preserving the evaluator/calculator input boundary.

## Tests

`tests/run_tests.gd` is a dependency-free SceneTree test runner. It covers simulation calculations, deterministic ordering, graph connectivity, installation, alternate routes, relay outages and repair, persistent hazard damage, network-driven evidence, invalid-action guards, tutorial progression/required actions/skip/persistence, all three coordinator-driven day resolutions, final report, and restart. `tests/capture_ui.gd` renders a graphics-backed 1280×720 Day Two network-planning capture. `tests/capture_tutorial.gd` renders the first guided-tour step. Both save ignored output and assert critical viewport bounds.
