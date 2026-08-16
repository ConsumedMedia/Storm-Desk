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
- Added an optional 12-step guided tour with live target cutouts, input masking, phase-aware action requirements, persistent completion/skip preference, and Rules/Help replay.
- Expanded the campaign into a five-day first week: Day Four opens with a High Ridge outage and repair-versus-reroute choice; Day Five makes prior routes affect a severe final forecast.
- Added an Industrial alternate path to both Farm Spire and Harbor, authored opening damage through `NetworkModel`, dynamic five-day reporting, and first-week performance thresholds.
- Expanded to 62 dependency-free automated checks plus graphics-backed 1280×720 Day Four network-planning and tutorial regression captures.
- Added actual implementation documentation.

## Current work

The contained first-week milestone is complete. The next product task is structured external playtesting and balance iteration unless the owner chooses another contained development milestone first.

## Remaining milestones

- Add between-day network planning only if the daily capacity model proves too restrictive for readable construction decisions.
- Conduct at least five observed playtests using `PLAYTEST_GUIDE.md`.
- Decide whether evidence language, network costs, and warning-time pressure produce meaningful uncertainty.

## Deferred

Final art/audio, save/load, longer campaign structure, procedural scenarios, staff systems, Steam integration, achievements, localization, accessibility narration, multiplayer, external services, monetization, and commercial production.

## Risks

- Fixed scenarios may create memorization after one playthrough.
- The deterministic numeric economy is explainable but not yet playtest-balanced.
- The current district board communicates vulnerability but does not test spatial network routing.
- A single UI coordinator is appropriate for this prototype but should be split if the number of screens or systems grows materially.
