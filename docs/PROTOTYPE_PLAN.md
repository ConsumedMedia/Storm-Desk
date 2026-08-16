# Prototype Plan

Last updated: 2026-08-16

## Completed

- Normalized the Godot project into the Git repository root; preserved `.git`.
- Configured the 1280×720 GL Compatibility main scene.
- Implemented custom hazard/district/scenario Resources and deterministic scenario content.
- Implemented independent hazard evaluation and outcome/economy calculations.
- Implemented the complete Day One teaching loop and validated it before final acceptance.
- Added Day Two capacity prioritization and Day Three faulty evidence/time pressure.
- Added explicit phases, map/district detail, readings, network controls, warning editing and confirmation, event log, help, daily reports, final report, and restart.
- Added a persistent fixed-site sensor/relay network with selectable nodes, graph connectivity, equipment installation, alternate routing, damage, repairs, and network-driven readings.
- Added scroll-safe district and network panels after owner testing identified 720px overflow defects.
- Added an optional 12-step guided tour with live target cutouts, input masking, phase-aware action requirements, persistent completion/skip preference, and Rules/Help replay.
- Expanded the campaign into a five-day first week: Day Four opens with a High Ridge outage and repair-versus-reroute choice; Day Five makes prior routes affect a severe final forecast.
- Added an Industrial alternate path to both Farm Spire and Harbor, authored opening damage through `NetworkModel`, dynamic five-day reporting, and first-week performance thresholds.
- Added a dedicated overnight maintenance phase after Days One through Four with next-day outlooks, one separate install-or-repair action, maintenance-first opening outages, and daily collection/survey capacity.
- Added an interface feedback and atmosphere pass: code-drawn weather motion, phase accents, resource pulses, accessible network states, warning/result district markers, draft summaries, assessment-led reports, explicit button focus styling, and keyboard-focused modals.
- Added a scenario-authoring system with five Inspector-editable day Resources, deterministic catalog conversion, and descriptive validation for ordering, references, nested records, timing, and evidence consistency.
- Added a versioned local autosave/resume system for complete coordinator and network state, launch-time Resume/Start New choice, corrupt/incompatible-save rejection, and completion cleanup.
- Added a combined Settings surface with persistent reduced motion, 115% larger text, high-contrast/color assistance, help and guided-tour access, manual save, Save & Quit, Quit to Desktop, keyboard shortcuts, and modal focus cycles.
- Expanded to 110 dependency-free automated checks plus eight graphics-backed 1280×720 regression captures covering Day Four, maintenance, warnings, results, onboarding, resume choice, Settings, and accessible gameplay.
- Added actual implementation documentation.

## Current work

The contained first-week, between-day maintenance, interface feedback, scenario-authoring/validation, save/resume, and accessibility/settings milestones are complete. The next product task is structured external playtesting and balance iteration unless the owner chooses another contained development milestone first.

## Remaining milestones

- Conduct at least five observed playtests using `PLAYTEST_GUIDE.md`.
- Decide whether evidence language, network costs, and warning-time pressure produce meaningful uncertainty.

## Deferred

Final art/audio, multiple save slots, cloud synchronization, longer campaign structure, procedural scenarios, staff systems, Steam integration, achievements, localization, accessibility narration, multiplayer, external services, monetization, and commercial production.

## Risks

- Fixed scenarios may create memorization after one playthrough.
- The deterministic numeric economy is explainable but not yet playtest-balanced.
- The current district board communicates vulnerability but does not test spatial network routing.
- A single UI coordinator is appropriate for this prototype but should be split if the number of screens or systems grows materially.
