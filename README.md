# Storm Desk

Storm Desk is a playable five-day Godot prototype about operating a weather bureau for floating islands. Each day asks the player to interpret fictional weather evidence, decide whether limited sensor requests are worth their budget and warning-time cost, classify the hazard, and warn selected districts. The result explains the true evidence and every trust, budget, and damage change.

## Requirements and launch

- Godot 4.7.x (implemented and validated with 4.7.1 stable)
- GL Compatibility renderer
- 1280×720 reference resolution; window scaling uses `canvas_items`

Open the repository-root `project.godot` in Godot and press F6/F5, or run from a terminal:

```text
godot --path .
```

No dependencies, plugins, asset downloads, autoloads, or external services are required.

Progress autosaves locally after completed actions and phase changes. If an unfinished first week exists, the next launch offers **Resume saved week** or **Start new week**. Completing the final report clears the finished save.

## How to play

1. Read the morning briefing and open Rules / Help for the three learnable hazard patterns.
2. On the first run, start or skip the guided tour. It highlights the current focus area and requires the relevant interface action before advancing.
3. Select district map cards to review vulnerabilities.
4. Inspect each instrument value and its quality tag.
5. Continue to Network Planning. Collect readings from connected sensors or commission a relay survey. These actions cost budget and observation capacity.
6. Continue to the Warning Desk. Choose a hazard (or stand down), severity, and districts.
7. Review and confirm the warning. Choices can be changed until confirmation.
8. After Days One through Four, review the next-day outlook and optionally install or repair one piece of equipment during overnight maintenance. This costs budget but not observation capacity.
9. Begin the next briefing. After Day Five, review the first-week report or restart without closing the application.

Mouse and keyboard focus navigation are supported by standard Godot Controls. The interface does not rely on color alone: phases, qualities, disabled actions, and warnings are labeled in text.

## Current prototype scope

- Day One: complete Sparkstorm teaching loop with all essential evidence
- Day Two: Glasswind scenario with one request available from two network options
- Day Three: Cloudburst scenario with a faulty charge reading, two requests available from three options, and a warning-time tradeoff
- Day Four: Glasswind recovery scenario with an opening relay outage and a repair-versus-reroute decision
- Day Five: severe Cloudburst finale whose evidence options reflect the network routes built during the week
- Three distinct data-driven districts and hazards
- Five Inspector-editable scenario Resources with startup validation for ordering, references, evidence, actions, and timing limits
- Persistent five-site sensor/relay graph with fixed build locations, selectable nodes, one relay and one sensor slot per remote site, alternate routing, and labeled connection state
- Electrical, crystal, and moisture sensor installation; relay installation; connected reading collection; damaged-equipment repair
- Network equipment that persists between days and can be damaged by unprotected Sparkstorm, Glasswind, or Cloudburst outcomes
- A dedicated overnight maintenance phase with a broad next-day outlook and one optional installation or repair separate from daily observation capacity
- A 12-step, state-aware guided tour with dimmed input masking, labeled highlights, required district/phase/warning interactions, persistent skip/completion state, and replay from Rules/Help
- Correct, false, missed, exaggerated, underestimated, timely, and late warning outcomes
- Trust, budget, damage, vulnerability, observation, warning-operation, and repair calculations
- Daily evidence explanations, calculation breakdowns, final summary, and in-app restart
- Versioned local autosave and resume for the complete session, including revealed evidence, warning drafts, reports, maintenance limits, outages, and network equipment health
- Code-drawn atmospheric backdrop, phase-colored status, resource feedback, accessible network legend, warning/protected/missed district markers, and assessment-led reports
- Local placeholder interface made only from Godot Controls, draw calls, and built-in fonts

Out of scope: multiplayer, networking, accounts, Steam integration, multiple save slots, cloud saves, achievements, final art, realistic fluid simulation, characters, staff systems, localization, and external services.

## Validation

Run the repository-native checks without installing a test framework:

```text
godot --headless --path . --script res://tests/run_tests.gd
```

The suite validates save creation, corrupt/version/state rejection, network snapshot round-trips, launch prompting, exact mid-day restoration, save clearing, scenario-resource loading and malformed-content rejection, hazard evaluation, district vulnerability, warning timing, damage reduction, trust and budget changes, deterministic scenarios, network behavior, warning feedback, guided-tour progression, all five coordinator-driven days, final-report transition, and restart. The last full run on 2026-08-16 passed 98 checks with exit code 0 under Godot 4.7.1.

Six graphics-backed visual-QA helpers cover the dense Day Four recovery screen, first overnight desk, warning draft, daily result, guided onboarding, and resume prompt. Run `tests/capture_ui.gd`, `tests/capture_maintenance.gd`, `tests/capture_warning.gd`, `tests/capture_result.gd`, `tests/capture_tutorial.gd`, and `tests/capture_resume.gd` with a graphics display (not `--headless`); they save ignored captures under `.godot/` and assert critical states and bounds.

## Repository structure

- `scenes/main/` — launch scene
- `scripts/ui/` — state-driven interface coordinator
- `scripts/simulation/` — resource schemas, deterministic content catalog and validator, save service, network model, evaluator, and outcome calculation
- `resources/hazards/`, `resources/districts/`, and `resources/scenarios/` — editable `.tres` content
- `tests/` — dependency-free checks and capture helper
- `docs/` — concept, architecture, plan, playtest guide, and decision log

## Known limitations

- The prototype uses five fixed scenarios and one automatically managed local session slot; there is no manual slot selection, save naming, or cloud synchronization.
- Scenario days are fixed custom Resources. Their nested reading, action, and opening-damage records remain Inspector-editable Dictionaries protected by startup validation rather than separate Resource types.
- The district map remains a structured board; network construction uses a fixed-node graph rather than free placement or terrain simulation.
- The UI is tuned for a 1280×720 reference window; very small windows are not a target.
- Audio, full production animation, final art, accessibility narration, and localization are deferred.
- Guided-tour completion remains a separate preference in `user://settings.cfg`. The active first week is stored in `user://storm_desk_session.cfg`; finished weeks are not retained as history.
