# Architecture

## Runtime composition

`scenes/main/main.tscn` is a minimal full-window Control root. `scripts/ui/main_controller.gd` creates the container-based interface and coordinates the session. There are no autoloads.

The coordinator owns transient session state: day index, explicit phase enum, budget, trust, observation usage/spend, nightly maintenance usage, applied opening-event days, current readings, warning choices, resolved district presentation states, accumulated reports, and one persistent `NetworkModel`. Modal panels provide briefing, help, confirmation, daily results, next-day outlooks, and the final report. It exposes named tutorial targets and emits phase/interaction signals, but does not own tour sequencing. Standard Godot controls provide focus and disabled-state behavior.

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
9. Overnight Maintenance

Overnight Maintenance was appended to preserve the existing tutorial-facing phase identifiers, but it occurs after Daily Report on Days One through Four; Day Five proceeds directly to Final Report. `set_phase()` is the single presentation transition point. It updates the phase label, required next action, active panel, footer note, and continue-button state. Warning choices remain editable until confirmation.

## Simulation boundary

- `hazard_definition.gd` and `district_definition.gd` define typed custom Resource schemas.
- `resources/hazards/*.tres` contains names, evidence patterns, and threats.
- `resources/districts/*.tres` contains descriptions, base damage, and per-hazard vulnerability multipliers.
- `scenario_definition.gd` defines the Inspector-editable top-level day schema. `resources/scenarios/*.tres` contains briefing and outlook copy, ground truth, readings with quality metadata, network actions, capacity, safe-action timing limits, evidence explanations, and optional authored opening damage.
- `scenario_catalog.gd` loads the five scenario paths in deterministic order, validates them, and converts each Resource to the existing runtime Dictionary boundary. `scenario_validator.gd` rejects missing copy, non-sequential or duplicate days, unknown hazards/districts/network references, malformed readings/actions/opening damage, invalid timing limits, and initially visible evidence that favors a different hazard.
- `network_model.gd` owns five fixed sites, graph edges, relay reachability, sensor/relay slots, equipment health, installation, alternate routing, repairs, authored opening outages, and persistent hazard damage. Bureau HQ and healthy connected relays form the traversal graph; a sensor is available when its site touches that graph.
- `network_diagram.gd` is a replaceable Control view of `NetworkModel`. It draws labeled nodes and edges, accepts site selection, and never owns simulation truth.
- `atmosphere_backdrop.gd` is a replaceable, input-transparent Control that draws a subtle phase-colored gradient and moving wind traces. It owns no gameplay state.
- `tutorial_controller.gd` owns the 12-step onboarding sequence, host-signal gating, skip/completion state, and one `ConfigFile` preference at `user://settings.cfg`. It resolves targets through the main controller's `tutorial_target()` callable, so no step contains screen coordinates.
- `tutorial_overlay.gd` owns presentation and input masking. Four blocking rectangles leave a live cutout around the target; a labeled border and popup are clamped to the viewport. Informational targets use a transparent click catcher, while action targets leave the underlying Godot Control interactive.
- `hazard_evaluator.gd` scores visible evidence independently of the UI. Imprecise evidence carries half weight; faulty evidence initially appears plausible until contradicted.
- `outcome_calculator.gd` is a pure calculation boundary for threat coverage, timing, severity, damage, trust, and budget.

## Outcome model

For each threatened district, raw damage is:

`round(base damage × actual severity × district vulnerability)`

A correct timely warning reduces 75%; a correct late warning reduces 40%. Underestimating severity reduces protection to 70% of that reduction. Useful warnings gain trust; late warnings gain less. Misses, false warnings, wrong classifications, and severity errors lose trust.

Each day adds an allocation of 8, then subtracts observation spend, two budget per warned district, and `ceil(total damage / 5)` repairs. Observation costs are deducted at purchase time in the coordinator; the post-result application avoids charging them twice. Maintenance costs are also deducted immediately, remain outside the completed day's calculation, and never affect daily observation use or warning lateness.

## Network model

The starter network contains Bureau HQ, a healthy High Ridge relay, and an Industrial electrical sensor. Farm Spire, Industrial Mast, Harbor Buoy, and High Ridge are fixed construction sites. Each non-HQ site has an independent relay slot and sensor slot. An Industrial relay creates alternate paths to both Farm Spire and Harbor when High Ridge is unavailable. Sensor types are electrical, crystal, and moisture.

Each overnight phase permits at most one installation or repair at its displayed budget cost. It does not consume the following day's capacity, and new sensors do not deliver forecast evidence until the player spends a daily action to collect connected readings. During Network Planning, only collection and scenario surveys consume observation capacity and influence warning timing. Equipment state persists across days; restart restores only the starter network.

Missed protection has infrastructure consequences: Sparkstorms can damage the Industrial sensor, Glasswind can damage High Ridge, and Cloudbursts can damage Harbor equipment. Day Four's clearly forecast High Ridge outage is applied once when the preceding maintenance desk opens, with `load_day()` as a fallback for direct/test transitions. Correct timely warnings to the relevant district protect hazard-exposed equipment. The daily calculation report records hazard damage, the event log records maintenance spending, and the final report lists the remaining network.

## Adding content

Add hazard and district definitions as `.tres` files and register their paths in `ScenarioCatalog`. For a new fixed day:

1. Duplicate an existing file under `resources/scenarios/` and edit its exported fields in the Inspector.
2. Give the day a sequential number, valid hazard and district IDs, quality-tagged readings, explicit reveal actions, and a safe-action limit no greater than capacity.
3. Add its path to `SCENARIO_PATHS` in chronological order.
4. Run `godot --headless --path . --script res://tests/run_tests.gd`; treat every `Scenario validation:` message as an authoring error.

Nested reading, action, and opening-damage records intentionally remain Dictionaries so they are compact to edit. `ScenarioValidator` is their schema boundary; extend both it and the regression cases whenever a new nested field becomes required.

## Tests

`tests/run_tests.gd` is a dependency-free SceneTree test runner. Its 85 checks cover valid scenario resources, malformed authoring rejection, simulation calculations, deterministic ordering, graph connectivity, nightly installation limits, separate action pools, alternate routes, authored and hazard-driven outages, repair, persistent equipment, network-driven evidence, invalid-action guards, labeled warning/protected states, draft summaries, assessment-led reports, tutorial progression/required actions/skip/persistence, all five coordinator-driven day resolutions, final report, and restart. Five graphics-backed 1280×720 helpers capture Day Four recovery, maintenance, warning selection, daily results, and onboarding. All save ignored output and assert critical states or viewport bounds.
