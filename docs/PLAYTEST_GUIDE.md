# Playtest Guide

## Setup

Use Godot 4.7.x, open the repository-root `project.godot`, and run the main scene at or above 1280×720. Ask the participant to think aloud. Do not explain hazard answers beyond what the in-game briefing and Settings → Rules / Help provide.

Target session length: 25–35 minutes.

## Test procedure

1. Start a fresh session and record whether the player finds Settings and opens Rules / Help.
2. For a first-time session, record whether the player starts or skips the guided tour and whether each highlighted action is understood without facilitator help.
3. Observe whether they inspect district vulnerabilities before warning.
4. On Day One, note whether the complete Sparkstorm pattern is understood without intervention.
5. After Day One, record whether the outlook leads them to install a Farm sensor, and whether they understand that evidence still requires collection on Day Two.
6. At every overnight desk, note whether the player acts, skips, or tries to take a second maintenance action.
7. On Day Three, note whether they recognize the charge conflict and whether they accept a late warning for more confidence.
8. Before Day Four, ask whether they repair High Ridge, build the Industrial alternate route, or defer the outage, and record why.
9. On Day Five, note whether they recognize how accumulated maintenance changes their available evidence routes.
10. During Day Two or Three, close the game after a completed action, relaunch it, and ask the player to choose Resume. Verify the day, phase, evidence, resources, warning draft, and network match their recollection.
11. Open Settings with `F1`, enable reduced motion, larger text, and high contrast, then complete one phase using only the keyboard. Record any clipped text, unclear focus, or color-dependent state.
12. Use `Ctrl+S`, then verify Save Progress and both quit choices are understandable from Settings without facilitator explanation.
13. After each report, ask the player to explain why trust, budget, and damage changed before they continue.
14. At the final report, ask them to restart and verify that the session returns to Day One without offering the completed week or automatically replaying a completed tour.

## Observation sheet

- Completion time:
- Help opened and when:
- Day One choice and reasoning:
- Overnight actions/skips and outlook interpretation:
- Day Two request, warning, and reasoning:
- Day Three requests, warning timing, and reasoning:
- Day Four recovery/reroute choice and reasoning:
- Day Five evidence route, warning, and reasoning:
- Any action whose availability or cost was unclear:
- Any result calculation the player could not restate:
- Moment of highest tension:
- Moment of boredom or confusion:
- Bugs or layout issues:

## Follow-up questions

- Which evidence felt most trustworthy, and why?
- Did the hazard rules feel learnable or like guessing?
- Did network requests feel meaningfully scarce?
- Was the separation between overnight construction and daily evidence collection clear?
- Did the next-day outlook provide useful direction without revealing the answer?
- Did warning markers, network colors/labels, and footer feedback make state changes immediately understandable?
- Could the player distinguish an effective, partial, late, missed, or incorrect result from the report heading?
- Was the Day Three time tradeoff understandable before confirming?
- Did the pre-Day Four outage make repair and alternate routing feel meaningfully different?
- Did Day Five make prior construction feel useful rather than mandatory?
- Was the Resume/Start New choice clear, and did the resumed desk match the state you expected?
- Could you find all accessibility, help, save, and quit actions under Settings?
- Did reduced motion, larger text, and high contrast behave as their labels promised?
- Was keyboard focus always visible, and could you finish a phase without the mouse?
- Did district vulnerabilities affect who you warned?
- Were trust and budget consequences fair and legible?
- Would you want a second week? What new decision should it add?

## Success criteria

- Most first-time players finish in 25–35 minutes without facilitator correction.
- At least 80% correctly identify Day One from the complete evidence.
- Players can articulate the overnight maintenance limit, Day Two collection tradeoff, Day Three confidence-versus-time tradeoff, and pre-Day Four repair-versus-reroute choice.
- Players can identify at least one way their network state changed the Day Five evidence options.
- Players understand why they lost or gained trust and budget after reading each report.
- At least half of players make a materially different resource or warning choice from another participant.
- Restart works and no invalid action fails silently.
- Relaunching midweek offers resume, restores the expected state, and does not duplicate costs or actions.
- Settings remain within 1280×720 at larger text, accessibility preferences survive relaunch, and every Settings/modal action is reachable with visible keyboard focus.

## Validation baseline

As of 2026-08-16, the automated suite passes 110 checks with exit code 0, including accessibility persistence, reduced motion, larger text, high contrast, keyboard Settings flow, manual save/quit requests, save validation and resume, scenario validation, the five-day coordinator path, network consequences, guided-tour persistence, and restart. The main scene runs under Godot 4.7.1; eight GPU captures verify Day Four recovery, maintenance, warning selection, daily results, onboarding, resume, Settings, and large-text/high-contrast gameplay at 1280×720. The first-week, maintenance, interface-feedback, scenario-authoring, save/resume, and accessibility/settings milestones are complete; human fun, pacing, comprehension, balance, resume clarity, and accessibility usability remain unvalidated until structured playtesting occurs.
