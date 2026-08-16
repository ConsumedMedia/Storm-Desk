# Storm Desk

Storm Desk is a playable three-day Godot prototype about operating a weather bureau for floating islands. Each day asks the player to interpret fictional weather evidence, decide whether limited sensor requests are worth their budget and warning-time cost, classify the hazard, and warn selected districts. The result explains the true evidence and every trust, budget, and damage change.

## Requirements and launch

- Godot 4.7.x (implemented and validated with 4.7.1 stable)
- GL Compatibility renderer
- 1280×720 reference resolution; window scaling uses `canvas_items`

Open the repository-root `project.godot` in Godot and press F6/F5, or run from a terminal:

```text
godot --path .
```

No dependencies, plugins, asset downloads, autoloads, or external services are required.

## How to play

1. Read the morning briefing and open Rules / Help for the three learnable hazard patterns.
2. On the first run, start or skip the guided tour. It highlights the current focus area and requires the relevant interface action before advancing.
3. Select district map cards to review vulnerabilities.
4. Inspect each instrument value and its quality tag.
5. Continue to Network Planning. Select fixed sites on the diagram, install or repair equipment, collect connected readings, or commission a relay survey. Every action costs budget and observation capacity.
6. Continue to the Warning Desk. Choose a hazard (or stand down), severity, and districts.
7. Review and confirm the warning. Choices can be changed until confirmation.
8. Read the calculation-backed daily report, then continue.
9. After Day Three, review the final report or restart without closing the application.

Mouse and keyboard focus navigation are supported by standard Godot Controls. The interface does not rely on color alone: phases, qualities, disabled actions, and warnings are labeled in text.

## Current prototype scope

- Day One: complete Sparkstorm teaching loop with all essential evidence
- Day Two: Glasswind scenario with one request available from two network options
- Day Three: Cloudburst scenario with a faulty charge reading, two requests available from three options, and a warning-time tradeoff
- Three distinct data-driven districts and hazards
- Persistent five-site sensor/relay graph with fixed build locations, selectable nodes, one relay and one sensor slot per remote site, alternate routing, and labeled connection state
- Electrical, crystal, and moisture sensor installation; relay installation; connected reading collection; damaged-equipment repair
- Network equipment that persists between days and can be damaged by unprotected Sparkstorm, Glasswind, or Cloudburst outcomes
- A 12-step, state-aware guided tour with dimmed input masking, labeled highlights, required district/phase/warning interactions, persistent skip/completion state, and replay from Rules/Help
- Correct, false, missed, exaggerated, underestimated, timely, and late warning outcomes
- Trust, budget, damage, vulnerability, observation, warning-operation, and repair calculations
- Daily evidence explanations, calculation breakdowns, final summary, and in-app restart
- Local placeholder interface made only from Godot Controls and built-in fonts

Out of scope: multiplayer, networking, accounts, Steam integration, saves, achievements, final art, realistic fluid simulation, characters, staff systems, localization, and external services.

## Validation

Run the repository-native checks without installing a test framework:

```text
godot --headless --path . --script res://tests/run_tests.gd
```

The suite validates hazard evaluation, district vulnerability, warning timing, damage reduction, trust and budget changes, deterministic scenarios, relay connectivity, sensor installation, alternate routing, outages, repairs, persistent hazard damage, network-driven evidence, guided-tour progression, required interactions, skip, local completion preference, all three coordinator-driven days, final-report transition, and restart. The last full run on 2026-08-15 passed 47 checks with exit code 0 under Godot 4.7.1.

`tests/capture_ui.gd` and `tests/capture_tutorial.gd` are visual-QA helpers. Run them with a graphics display (not `--headless`); they save ignored captures under `.godot/` and assert critical UI bounds.

## Repository structure

- `scenes/main/` — launch scene
- `scripts/ui/` — state-driven interface coordinator
- `scripts/simulation/` — resource types, deterministic content catalog, evaluator, and outcome calculation
- `resources/hazards/` and `resources/districts/` — editable `.tres` content
- `tests/` — dependency-free checks and capture helper
- `docs/` — concept, architecture, plan, playtest guide, and decision log

## Known limitations

- The prototype uses three fixed scenarios and has no save/load.
- Scenario records are centralized in typed GDScript dictionaries; hazards and districts are standalone custom Resources.
- The district map remains a structured board; network construction uses a fixed-node graph rather than free placement or terrain simulation.
- The UI is tuned for a 1280×720 reference window; very small windows are not a target.
- Audio, animation, final art, accessibility narration, and localization are deferred.
- Guided-tour completion is the only persisted preference. It is stored in `user://settings.cfg`; Rules/Help can reset and replay it. No session save/load exists.
