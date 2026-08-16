# Playtest Guide

## Setup

Use Godot 4.7.x, open the repository-root `project.godot`, and run the main scene at or above 1280×720. Ask the participant to think aloud. Do not explain hazard answers beyond what the in-game briefing and Rules / Help provide.

Target session length: 15–20 minutes.

## Test procedure

1. Start a fresh session and record whether the player opens Rules / Help.
2. For a first-time session, record whether the player starts or skips the guided tour and whether each highlighted action is understood without facilitator help.
3. Observe whether they inspect district vulnerabilities before warning.
4. On Day One, note whether the complete Sparkstorm pattern is understood without intervention.
5. On Day Two, ask why they selected one network request over the other.
6. On Day Three, note whether they recognize the charge conflict and whether they accept a late warning for more confidence.
7. After each report, ask the player to explain why trust, budget, and damage changed before they continue.
8. At the final report, ask them to restart and verify that the session returns to Day One without automatically replaying a completed tour.

## Observation sheet

- Completion time:
- Help opened and when:
- Day One choice and reasoning:
- Day Two request, warning, and reasoning:
- Day Three requests, warning timing, and reasoning:
- Any action whose availability or cost was unclear:
- Any result calculation the player could not restate:
- Moment of highest tension:
- Moment of boredom or confusion:
- Bugs or layout issues:

## Follow-up questions

- Which evidence felt most trustworthy, and why?
- Did the hazard rules feel learnable or like guessing?
- Did network requests feel meaningfully scarce?
- Was the Day Three time tradeoff understandable before confirming?
- Did district vulnerabilities affect who you warned?
- Were trust and budget consequences fair and legible?
- Would you want a fourth day? What new decision should it add?

## Success criteria

- Most first-time players finish in 15–20 minutes without facilitator correction.
- At least 80% correctly identify Day One from the complete evidence.
- Players can articulate the Day Two observation tradeoff and Day Three confidence-versus-time tradeoff.
- Players understand why they lost or gained trust and budget after reading each report.
- At least half of players make a materially different resource or warning choice from another participant.
- Restart works and no invalid action fails silently.

## Validation baseline

As of 2026-08-15, the automated suite passes 47 checks with exit code 0, including fixed-node connectivity, persistent equipment, guided-tour progression, required interactions, skip, and preference persistence. The main scene runs under Godot 4.7.1; GPU captures verify Day Two network planning and the tutorial overlay at 1280×720. By owner decision, structured external playtesting is deferred until after the next contained development milestone; human fun, pacing, and comprehension therefore remain unvalidated.
