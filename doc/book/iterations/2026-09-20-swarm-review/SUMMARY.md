# Swarm Intelligence — where coordination lives

20 September 2026. Seven halls reviewed; four chapters retained byte for byte and three revised around strengthened encounters. The order and all original map artifact families remain. The Ant Colony and Ecosystem halls were absent from the museum plan even though they belonged to the manuscript sequence. Both are restored.

[Read the text and image comparison](http://localhost:3003/book-review#swarmintelligence). [Exact manuscript diff](final.diff).

## The thread

The sequence already had a useful progression: a medium remembers traces; a supplied field directs agents; neighbours influence a flock; agent state and shared state interact; two trail channels guide foragers; particles remember evaluations; an ecosystem combines local events with population support.

Its older umbrella description, “no leader, yet coordinated”, obscured these differences. A supplied vector field, an objective function and a population caretaker are consequential arrangements of control. “Where coordination lives” lets the halls disagree about what produced their similar-looking collective pictures. The declaration now supports that progression without asserting that every example is decentralized, optimal or at an edge of chaos.

## Decisions and changes

| Hall | Decision |
| --- | --- |
| Physarum | Keep chapter, placement and primary. Environmental memory already carries the question. |
| Flow Fields | Keep chapter, placement and primary. Distinguish a supplied field from agents writing their own traces. |
| Boids | Keep chapter and map. Point the book hero to the already-primary `flocking_controls`; retain the other book entries. |
| Agent-Based Modeling | Repair repeatability and control height. Extend the existing comparison between replacing agents and clearing shared memory. |
| Ant Colony Optimization | Restore the missing hall around `AntColonyV2`. Keep its chapter: outgoing and returning travellers read different channels. |
| Particle Swarm Optimization | Repair novelty evaluation; make RESET available and the archive visible. Revise the text around remembered places whose value changes. |
| Ecosystem | Restore the missing hall and make its existing population support observable. Replace a proposed intervention record in the text with the working record. |

### Ants can inherit a field

RESET previously made different food and headings, so the manuscript's proposed comparison changed more than evaporation. A local seeded random stream now restores the same beginning. The model advances in fixed 60 Hz simulation steps; the evaporation rate retains its authored meaning across ordinary display update rates. A long frame is capped to prevent unlimited catch-up work.

ANTS deliberately replaces the population without clearing its shared field. RESET clears that history as well. The revision begins with this difference the visitor can observe: new travellers arrive among traces left by absent bodies. It keeps the existing agent-model qualification and the proposed unequal-sensing experiment.

The first museum probe found the control detectors about four metres below the floor. An opt-in `lesson_display` arrangement brings the diagram above ground and the actual button detectors to approximately 1.03 metres. Slider values now initialize from the model. The other artifact families remain.

### Novelty can change yesterday's best

The old empty archive returned a fitness of 10. That became a stored best score larger than any later distance available in this three-metre arena. The baseline test reproduced frozen remembered positions. Even without this initial value, scores from different archives were not comparable.

The starting particle positions now seed the archive. Whenever its contents change, current and saved positions are evaluated against that same record, personal memories are reconsidered and the global best is rebuilt. The archive adds a sampled position every half-second of simulation time, keeps at most 200 entries, and discards the oldest. The colour field and count update with it. A controlled 90-update run changed all 30 personal memories; this supports the repair, not a general claim of optimal exploration.

Switching an objective preserves positions and velocities. RESET restores the same initial scatter and velocities for the selected objective. SPREAD's caption now says distance from the centre; it does not measure diversity between particles. Corporate, Ecological and Artistic remain interpretive labels, which the chapter explicitly invites the reader to question.

The colour plate was below the museum floor and is now three centimetres above it. The secondary pattern display moves to a smaller raised position away from the primary. Existing architecture remains; the paired captures show CONVERGE and NOVELTY after the same 180 updates from the same initial scatter.

### Support can be counted

The ecosystem scene used a Node2D root, so the museum skipped it despite its 3D contents. Its root is now Node3D. Instance colours are read by the materials so prey, predators and food can be distinguished.

The opt-in POPULATION SUPPORT display records supplied prey, supplied predators, outside food, current predator pressure and the latest intervention. Counts are made at the intervention sites; they do not infer causes from population curves. The restored hall enables the display and places the small ecosystem on a plinth. The population rules remain active. The chapter's proposed CARE OFF comparison remains a future experiment, not a promised control.

## Evidence and scope

- [38 model checks](model-checks.json): old failures reproduced; repeatable resets; objective switching; historical revaluation against a changing archive; archive capacity; ant simulations agreeing over one second at 30/60/90 display updates; field inheritance; control initialization; ecosystem instantiation, materials and intervention records.
- [23 navigation checks](navigation.json): production selection and advancement logic visits all seven declared halls in order. This is not a physical seven-portal walkthrough.
- Four actual museum runtime probes instantiated the required primary and passed a selected approach or perimeter walk using the museum collision body. The ABM probe also records detector heights; the ecosystem probe records its live support label.
- [72 content checks](content-checks.json): current route, book heroes, dimensions, encounter hashes, frozen manuscripts, retained tokens and roles, unrelated plan and registry entries, plus the recorded runtime outcomes.
- Screenshots are Godot Vulkan/mobile captures of the actual museum using private probe plans. The PSO pair uses the same camera, initial scatter and update count. Other images show current encounters, not matched software before/after views.
- [Current and frozen input hashes](current-inputs.json) and [original snapshot hashes](before-sha256.json) make this pass identifiable. `before/.gdignore` prevents frozen scripts becoming duplicate live classes.

## Remaining work

Headset reach, readability, comfort and Quest performance still need an actual visit. The probes do not establish learner understanding or continuous traversal through every hall. PSO integration and ecosystem pressure still have frame-dependent aspects; this pass does not claim to normalize those clocks. Test longer novelty trajectories separately before claiming exploration quality.

Potential next iterations remain specific: a repeatable CARE OFF comparison, movable Physarum anchors, a Flow Fields visibility control, and a clearer physical PSO control approach. The legacy PSO `ant_colony_v2` token remains in the map but did not instantiate in this probe and needs a separate lookup audit. No new primary role was assigned to legacy `dark_sphere` placements.

The next spine pass is **Machine Learning**. Carry forward the distinction between inherited traits, a chosen reward and the support that keeps an experiment running. Do not reopen the four retained Swarm chapters without new evidence or author feedback.
