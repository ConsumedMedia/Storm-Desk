# Architecture

## Runtime composition

`scenes/main/main.tscn` is a minimal full-window Control root. `scripts/ui/main_controller.gd` creates the container-based interface and coordinates the session. There are no autoloads.

The coordinator owns transient session state: day index, explicit phase enum, budget, trust, observation usage/spend, nightly maintenance usage, applied opening-event days, current readings, warning choices, resolved district presentation states, accumulated reports, and one persistent `NetworkModel`. It serializes this state through `SessionSave` after completed actions and phase changes. Modal panels provide startup resume/new-week choice, briefing, confirmation, daily results, next-day outlooks, final report, quit confirmation, and one combined Settings surface for accessibility, help, onboarding, save, and quit actions. It exposes named tutorial targets and emits phase/interaction signals, but does not own tour sequencing. Standard Godot controls provide focus and disabled-state behavior.

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

On startup, the coordinator builds a clean Day One presentation without writing it, then reads and validates the local session. A valid save opens a blocking Resume/Start New choice. Resume reconstructs the current scenario from the catalog, applies saved transient fields and network state, synchronizes controls, and reopens any required briefing, confirmation, report, or maintenance modal. Invalid or incompatible data is deleted before a fresh week can begin.

## Simulation boundary

- `hazard_definition.gd` and `district_definition.gd` define typed custom Resource schemas.
- `resources/hazards/*.tres` contains names, evidence patterns, and threats.
- `resources/districts/*.tres` contains descriptions, base damage, and per-hazard vulnerability multipliers.
- `scenario_definition.gd` defines the Inspector-editable top-level day schema. `resources/scenarios/*.tres` contains briefing and outlook copy, ground truth, readings with quality metadata, network actions, capacity, safe-action timing limits, evidence explanations, and optional authored opening damage.
- `scenario_catalog.gd` loads the five scenario paths in deterministic order, validates them, and converts each Resource to the existing runtime Dictionary boundary. `scenario_validator.gd` rejects missing copy, non-sequential or duplicate days, unknown hazards/districts/network references, malformed readings/actions/opening damage, invalid timing limits, and initially visible evidence that favors a different hazard.
- `session_save.gd` owns the versioned `ConfigFile` format at `user://storm_desk_session.cfg`, safe read/write/delete operations, and structural/cross-reference validation. Saves contain only current session state and authored IDs; current scenario definitions always come from `ScenarioCatalog`.
- `user_settings.gd` owns the versioned `accessibility` section of `user://settings.cfg`: reduced motion, 115% larger text, and high contrast. It loads before interface construction and preserves the onboarding section written by `TutorialController`.
- `network_model.gd` owns five fixed sites, graph edges, relay reachability, sensor/relay slots, equipment health, installation, alternate routing, repairs, authored opening outages, and persistent hazard damage. Bureau HQ and healthy connected relays form the traversal graph; a sensor is available when its site touches that graph.
- `network_diagram.gd` is a replaceable Control view of `NetworkModel`. It draws labeled nodes and edges, accepts site selection, scales its labels, applies an assisted high-contrast palette, and never owns simulation truth. The adjacent site selector provides a keyboard-only path.
- `atmosphere_backdrop.gd` is a replaceable, input-transparent Control that draws a subtle phase-colored gradient and wind traces. Reduced motion pauses processing and high contrast darkens the backdrop while strengthening traces. It owns no gameplay state.
- `art_catalog.gd` is the typed presentation boundary for generated preview art under `assets/art/`. It maps districts, instruments, weather phases, report types, and atlas regions to textures without changing simulation state. Hazard-specific observation art is withheld until resolution/report phases so artwork never reveals the authored answer early. Dedicated briefing, warning, daily-report, and final-report images are transparent modal roots with normalized content-safe regions; they provide the visible popup silhouette and border instead of being dimmed inside a generic panel. Settings exposes all 38 assets through a keyboard-accessible gallery; sheets not yet suitable for direct slicing remain gallery-only until their Photoshop pass.
- `tutorial_controller.gd` owns the 12-step onboarding sequence, host-signal gating, skip/completion state, and the `onboarding` section of `user://settings.cfg`. It resolves targets through the main controller's `tutorial_target()` callable, so no step contains screen coordinates.
- `tutorial_overlay.gd` owns presentation and input masking. Four blocking rectangles leave a live cutout around the target; a labeled border and popup are clamped to the viewport. It scales text and contrast with `UserSettings`. Informational targets focus a transparent keyboard-activatable catcher, while action targets focus the underlying Godot Control.
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

`NetworkModel.snapshot()` serializes every fixed site's relay/sensor occupancy and health. `restore_snapshot()` validates all sites and fields into a temporary dictionary before replacing live equipment, so partial or malformed network data cannot mutate the session.

Missed protection has infrastructure consequences: Sparkstorms can damage the Industrial sensor, Glasswind can damage High Ridge, and Cloudbursts can damage Harbor equipment. Day Four's clearly forecast High Ridge outage is applied once when the preceding maintenance desk opens, with `load_day()` as a fallback for direct/test transitions. Correct timely warnings to the relevant district protect hazard-exposed equipment. The daily calculation report records hazard damage, the event log records maintenance spending, and the final report lists the remaining network.

## Adding content

Add hazard and district definitions as `.tres` files and register their paths in `ScenarioCatalog`. For a new fixed day:

1. Duplicate an existing file under `resources/scenarios/` and edit its exported fields in the Inspector.
2. Give the day a sequential number, valid hazard and district IDs, quality-tagged readings, explicit reveal actions, and a safe-action limit no greater than capacity.
3. Add its path to `SCENARIO_PATHS` in chronological order.
4. Run `godot --headless --path . --script res://tests/run_tests.gd`; treat every `Scenario validation:` message as an authoring error.

Nested reading, action, and opening-damage records intentionally remain Dictionaries so they are compact to edit. `ScenarioValidator` is their schema boundary; extend both it and the regression cases whenever a new nested field becomes required.

## Tests

`tests/run_tests.gd` is a dependency-free SceneTree test runner. Its 118 checks cover accessibility persistence and onboarding coexistence, reduced motion, larger text, high contrast, keyboard Settings/gallery flow, all 38 runtime artwork paths, artwork-native document frames, guided-tour scaling, manual save and quit requests, save validation/restoration, scenario authoring, simulation calculations, graph behavior, persistent equipment, UI feedback, all five coordinator-driven day resolutions, final report, and restart. Eleven graphics-backed 1280×720 helpers capture Day Four recovery, maintenance, warning selection, daily results, onboarding, resume, Settings, accessible gameplay, artwork-enhanced gameplay, the Artwork Gallery, all four document formats, and accessible document presentation. Every harness uses isolated `user://` save and settings paths, saves ignored visual output, and asserts critical states or viewport bounds.
