# Prototype Plan

Last updated: 2026-08-15

## Completed

- Normalized the Godot project into the Git repository root; preserved `.git`.
- Configured the 1280×720 GL Compatibility main scene.
- Implemented custom hazard/district Resources and deterministic scenario content.
- Implemented independent hazard evaluation and outcome/economy calculations.
- Implemented the complete Day One teaching loop and validated it before final acceptance.
- Added Day Two capacity prioritization and Day Three faulty evidence/time pressure.
- Added explicit phases, map/district detail, readings, network controls, warning editing and confirmation, event log, help, daily reports, final report, and restart.
- Added 28 dependency-free automated checks and graphics-backed 1280×720 captures of briefing, Observation, and Warning Decision layouts.
- Added actual implementation documentation.

## Current work

Run structured player sessions and collect comprehension, pacing, and decision-quality observations. Avoid feature expansion until playtest evidence identifies the highest-value change.

## Remaining milestones

- Conduct at least five observed playtests using `PLAYTEST_GUIDE.md`.
- Decide whether the evidence language, costs, and late-warning threshold produce meaningful uncertainty.
- Iterate tutorial copy and balance from observed failures.
- Replace or refactor scenario authoring only if iteration speed becomes a real constraint.

## Deferred

Final art/audio, save/load, longer campaign structure, procedural scenarios, staff systems, Steam integration, achievements, localization, accessibility narration, multiplayer, external services, monetization, and commercial production.

## Risks

- Fixed scenarios may create memorization after one playthrough.
- The deterministic numeric economy is explainable but not yet playtest-balanced.
- The current district board communicates vulnerability but does not test spatial network routing.
- A single UI coordinator is appropriate for this prototype but should be split if the number of screens or systems grows materially.

