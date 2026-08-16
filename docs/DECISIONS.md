# Decision Log

## 2026-08-15 — Keep the runtime dependency-free

Decision: use Godot Resources, typed GDScript, standard Controls, and a dependency-free SceneTree test runner.

Reason: the prototype must be easy for a solo developer new to Godot to open, inspect, and run. No approved need justified plugins or third-party frameworks.

Alternatives considered: a GDScript test addon, external content pipeline, or UI framework. These would add setup cost before the loop is proven.

## 2026-08-15 — Use deterministic authored days

Decision: centralize three fixed scenario records in `ScenarioCatalog` and keep hazards/districts as custom `.tres` Resources.

Reason: reproducibility and legible teaching progression matter more than content scale for this prototype. The data boundary allows a later move to scenario Resources without changing outcome logic.

Alternative considered: procedural generation. Deferred because it would obscure whether failures came from design or generated combinations.

## 2026-08-15 — Pure outcome calculation, stateful coordinator

Decision: keep hazard scoring and outcome/economy calculations in independent scripts; let `main_controller.gd` own phase and presentation state.

Reason: important math is testable without UI scenes while the prototype retains a simple runtime composition.

Alternative considered: a large autoload game manager. Rejected because only one scene currently needs session state.

## 2026-08-15 — Make warning time an action threshold

Decision: each network request consumes capacity; on Day Three, more than one request makes the warning late. Timely correct warnings reduce 75% of damage and late correct warnings reduce 40%.

Reason: this creates an explicit confidence-versus-preparation tradeoff with a calculation players can understand.

Alternative considered: a real-time countdown. Rejected because reading speed should not be punished in this deduction prototype.

## 2026-08-15 — Use a structured district board as the placeholder map

Decision: represent the region with labeled district cards and vulnerability detail rather than coordinates or pathfinding.

Reason: the acceptance question concerns evidence, prioritization, and warnings. The board communicates all decision-relevant spatial entities without introducing a map editor or movement simulation.

Alternative considered: a freeform 2D island map with relay edges. Deferred until playtests show stronger spatial routing is the next valuable experiment.

## 2026-08-15 — Explain every consequence

Decision: reports expose the actual pattern, faulty Day Three evidence, raw/reduced district damage, trust changes, and the full budget equation.

Reason: a player must never lose to an arbitrary hidden answer, and explainable outcomes are necessary to evaluate whether the rules are learnable.

## 2026-08-15 — Build network foundations as a fixed graph

Decision: add five authored sites, explicit graph edges, independent relay and sensor slots, persistent equipment health, and diagram-based selection. Keep terrain routing and free placement deferred.

Reason: the observation buttons proved the deduction flow but did not test the intended building/network-planning component. A fixed graph adds meaningful connectivity, redundancy, costs, and damage while remaining explainable and feasible for the prototype.

Alternatives considered: freeform placement, grid routing, and a full map editor. Deferred because their interface and path-validation costs would expand scope before fixed-node planning is proven.

## 2026-08-15 — Make network consequences persistent

Decision: correct timely warnings protect relevant network equipment; missed or late protection can damage the Industrial sensor, High Ridge relay, or Harbor sensor. Repairs and alternate relay routes consume the same limited daily action capacity as observations.

Reason: construction choices need consequences across days, and repair-versus-evidence decisions reinforce the existing confidence/time/budget loop.

Alternative considered: automatic between-day repairs. Rejected because it would remove the primary reason for persistent network state.

## 2026-08-15 — Use a state-aware, skippable guided tour

Decision: introduce first-time onboarding after the Day One briefing with 12 live steps across Observation, Network Planning, and Warning Decision. Informational targets advance when inspected; district, phase, hazard, and warning-district steps require the real host action. Completion or skip is stored as one local preference and can be reset from Rules/Help.

Reason: owner testing showed that the interface benefits from explicit focus guidance, while a static slideshow would not teach where controls live or how phase transitions work. Signal-gated steps teach interaction without selecting answers or consuming resources for the player.

Alternatives considered: permanently embedded callouts, video onboarding, and hard-coded coordinate highlights. Rejected because they would add clutter, external assets, or break under container/layout changes.

## 2026-08-15 — Extend the prototype to a five-day first week

Decision: retain the three established hazard rules and add two deterministic authored days. Day Four applies a clearly briefed High Ridge outage and offers repair, Industrial rerouting, or evidence-only recovery. Day Five uses route-dependent Cloudburst evidence and a severe two-district threat. The fixed graph gains an Industrial-to-Farm edge so one Industrial relay can redundantly serve both downstream districts.

Reason: three days introduced construction and damage but ended before repair and redundancy could influence later decisions. A contained five-day arc gives persistent infrastructure time to produce consequences without adding procedural generation, a separate maintenance economy, or new production systems.

Alternatives considered: add new hazard types, procedural weeks, or a between-day maintenance phase immediately. Deferred because authored reuse keeps the fictional rules learnable and lets playtests determine whether a separate planning phase is necessary.

## 2026-08-16 — Separate overnight infrastructure from daily observations

Decision: after Days One through Four, show a broad next-day outlook and allow one optional installation or repair. Charge its budget cost immediately, but do not consume the following day's observation capacity or affect warning lateness. Daily Network Planning is limited to connected-reading collection and surveys. Apply a forecast opening outage when its preceding maintenance desk opens so the player can react before that day begins.

Reason: the five-day campaign made construction strategically relevant, but charging installation, repair, and evidence collection against one daily pool compressed infrastructure planning into the forecast itself. A one-action overnight phase gives persistent network choices a readable home while retaining budget scarcity and requiring a daily action to collect actual evidence.

This supersedes the action-pool portion of “Make network consequences persistent”; equipment damage and manual repair remain persistent, but installations and repairs no longer consume observation capacity.

Alternatives considered: unlimited overnight work, free automatic repairs, retaining all construction during daily Network Planning, or adding a larger between-day economy. Rejected because they would remove scarcity, erase consequences, preserve the clarity problem, or expand scope before balance testing.

## 2026-08-16 — Use labeled state feedback before final art

Decision: improve the placeholder interface with code-drawn atmosphere, phase accents, quality borders, a network legend, damaged-state colors plus text tags, labeled WARNING/PROTECTED/MISSED/FALSE district cards, live warning summaries, persistent footer feedback, outcome assessments, explicit keyboard focus styling, and short Control-property tweens. Keep all visuals replaceable and retain text labels wherever color communicates state.

Reason: the five-day and maintenance systems are mechanically complete, but players need to notice selections, resource spending, connectivity, warning coverage, and outcomes without repeatedly consulting the event log. These changes improve comprehension and tone while preserving the tested simulation.

Alternatives considered: final illustration, downloaded assets, particle-heavy storm scenes, or a UI framework. Deferred or rejected because the prototype still needs balance evidence, must remain dependency-free, and should not lock presentation before the core loop is validated.

## 2026-08-16 — Move scenario authoring into validated Resources

Decision: represent each fixed day as a `ScenarioDefinition` `.tres` Resource, load paths in chronological order through `ScenarioCatalog`, validate authored content before play, and preserve the established runtime Dictionary passed to the evaluator, calculator, network model, and UI.

Reason: adding or revising days should not require editing a large GDScript catalog, but flexible nested evidence and action records still need descriptive safeguards. The Resource exposes top-level fields in Godot's Inspector while the validator catches broken ordering, unknown IDs, invalid qualities/routes/timing, duplicate records, and evidence that initially contradicts the authored answer.

This supersedes the storage portion of “Use deterministic authored days”; scenarios remain deterministic and fixed, but their source records are now custom Resources rather than catalog functions.

Alternatives considered: separate Resource classes for every nested reading/action, JSON files, a custom editor plugin, or procedural generation. Deferred because the current hybrid stays dependency-free, compact, Inspector-editable, and compatible with the proven runtime boundary.

## 2026-08-16 — Use one validated local autosave

Decision: autosave the active first week after completed actions and phase changes to a versioned `ConfigFile`. On launch, offer Resume or Start New; validate all session, authored-ID, and network fields before mutating runtime state; clear the resumable file when the final report opens; and create a fresh save when the player restarts.

Reason: a 25–35 minute campaign should survive an interrupted session without adding account infrastructure or a save-management screen. Reconstructing authored scenario truth from the current catalog keeps content updates authoritative, while persisting transient evidence, costs, warning choices, reports, outage history, and network health prevents duplicated actions or lost consequences.

Alternatives considered: manual checkpoints, multiple named slots, binary serialization, cloud storage, or persisting complete scenario records. Deferred because a single transparent local slot covers the prototype need with readable built-in tooling and a smaller compatibility surface.
