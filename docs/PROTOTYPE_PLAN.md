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
- Added a persistent fixed-site sensor/relay network with selectable nodes, graph connectivity, equipment installation, alternate routing, damage, repairs, and network-driven readings.
- Added scroll-safe district and network panels after owner testing identified 720px overflow defects.
- Expanded to 38 dependency-free automated checks and a graphics-backed 1280×720 Day Two network-planning regression capture.
- Added actual implementation documentation.

## Current work

Owner decision: defer structured external playtesting until the prototype has progressed beyond the original three-day loop. Current technical work should extend the persistent network into a contained first-week milestone without adding out-of-scope production systems.

## Remaining milestones

- Add a contained five-day first week that gives construction, damage, repair, and alternate routing more room to matter.
- Add between-day network planning only if the daily capacity model proves too restrictive for readable construction decisions.
- Conduct at least five observed playtests using `PLAYTEST_GUIDE.md` after that milestone.
- Decide whether evidence language, network costs, and warning-time pressure produce meaningful uncertainty.

## Deferred

Final art/audio, save/load, longer campaign structure, procedural scenarios, staff systems, Steam integration, achievements, localization, accessibility narration, multiplayer, external services, monetization, and commercial production.

## Risks

- Fixed scenarios may create memorization after one playthrough.
- The deterministic numeric economy is explainable but not yet playtest-balanced.
- The current district board communicates vulnerability but does not test spatial network routing.
- A single UI coordinator is appropriate for this prototype but should be split if the number of screens or systems grows materially.
