# AGENTS.md

## Purpose and phase

This repository contains the playable Storm Desk five-day Godot 4.7.x prototype. Its current purpose is to test whether incomplete fictional weather evidence, scarce observations, persistent network planning, and consequential warnings form an enjoyable 25–35 minute first-week loop. The contained first-week milestone is implemented; the next phase is structured playtesting and iteration, not commercial production.

## Implementation rules

- Use typed GDScript and Godot 4.7.x APIs. Do not change engine versions without owner approval.
- Keep simulation decisions callable independently from UI scenes.
- Keep network topology, connectivity, equipment health, and hazard damage in `NetworkModel`; the UI diagram must present that state rather than duplicate it.
- Preserve the fixed-node scope unless the owner explicitly approves free placement, terrain routing, or a map editor.
- Prefer composition, signals or explicit coordinator calls, small focused scripts, deterministic inputs, and data-driven content.
- Keep hazard and district facts in custom Resources under `resources/`. Add scenario content through `ScenarioCatalog` until a concrete need justifies a different authoring format.
- Preserve the explicit phase flow in `main_controller.gd`: briefing, observation, network planning, warning decision/confirmation, resolution, daily report, overnight maintenance between days, final report.
- Keep guided-tour sequence/persistence in `TutorialController` and mask/highlight rendering in `TutorialOverlay`. Add target controls through `tutorial_target()` instead of screen coordinates.
- Tutorial steps must never choose an answer, spend resources, or silently alter simulation state. Required gameplay actions must advance through host signals.
- Do not hide action failures. Disable invalid actions and log an explanation when guard code rejects one.
- Avoid autoloads unless a durable cross-scene need exists and document any added autoload in `docs/ARCHITECTURE.md`.

## Scope restrictions

Do not add multiplayer, networking, accounts, external services, Steamworks, achievements, cloud saves, mod/workshop support, console/mobile work, localization, voice acting, branching narrative, characters, staff hiring, pathfinding, realistic fluid/weather simulation, a map editor, a large technology tree, monetization, DLC, or live-service systems without explicit approval.

## Validation expectations

- Run `godot --headless --path . --script res://tests/run_tests.gd` after simulation or coordinator changes.
- Confirm the main scene starts without parser/runtime errors.
- For layout changes, run the relevant graphics helpers under `tests/capture_*.gd` and inspect their `.godot/*.png` output at 1280×720. Current captures cover network planning, maintenance, warning selection, daily results, and onboarding.
- Add or adjust deterministic checks for every material calculation or phase transition.
- Never claim a path works unless it was run. Record anything that could not be validated.

## Placeholder and asset rules

Use Godot Controls, built-in fonts, simple draw calls, ColorRects, panels, polygons, lines, gradients, or particles. Keep placeholders replaceable. Do not download asset packs, imitate artists, add copyrighted media, or present placeholder work as final art.

## Product records

- `docs/CONCEPT.md` defines the intended loop and fictional rules.
- `docs/ARCHITECTURE.md` describes code and content boundaries.
- `docs/PROTOTYPE_PLAN.md` is the work/status ledger.
- `docs/PLAYTEST_GUIDE.md` defines the next evidence to collect.
- `docs/DECISIONS.md` records material decisions and alternatives.

Update these files when implementation reality changes. Preserve user changes and inspect Git status before editing overlapping work.

## Safety and authority

Never push, publish, purchase, install dependencies/plugins, add external services, change Godot versions, create releases, or perform destructive work without explicit owner authorization. Do not touch `.git`. Keep generated `.godot/` data ignored. Local nondestructive validation is expected.
