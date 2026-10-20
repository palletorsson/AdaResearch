# Swarm — reconstruction and evidence

## Scope

The closing lesson teaches an event account. It does not reimplement the ecosystem or add a generic algorithm-interface survey. The supplied source is algorithms/emergentsystems/ecosystemsimulation/ecosystem.gd, Creature.gd and food.gd. Their movement, mating, health, food and balancing rules remain unchanged. The source hash equals the saved before copy. A subclass calls the original operations and emits observations; birth context comes from check_for_mate, later other spawns are supplied, and losses compare membership after each species pass. New arrivals within a pass are included in the removal comparison. Existing queue_free defers destruction until after these receipts. Supplied-creature care callbacks are not counted again. Outside-food and pressure callbacks remain separate.

Loss receipts are emitted at update-pass boundaries; receipt serials are not a proof of exact internal chronology. Compare counts at completed-step boundaries. The record describes population membership, not the cause of every death. It also does not register a player's relocation as a birth or loss. Holding is nevertheless an intervention.

## Runtime

Permanent population_account_walk replaces the old plinth placement in this hall only. The original ecosystem remains on disk for other users and is the live source of this lesson. Map and corresponding em_plan row become 17 × 21, flat and open; artifact cell (8, 10), yaw 180, scale 1. The 12 m model field has control banks at local z±6.9,x∓3.1,y.95. The central walk remains open. Other em_plan rows compare equal to their before snapshot. Sequence metadata changes only this hall's artifact/size description in both lists.

The carried PointBody is unchanged from PSO. Visual sphere and grab shape both enlarge by 3 to 0.51 m diameter, root unscaled. Model display scales x/z by 15 and y by 3 with 0.8 m offset: view size is not contact size. Bodies overlap and wrap at model boundaries. Food is a batched non-grabbable marker; hidden original rendering remains in the supplied model.55 initial creature proxies are created, added or removed to match the actual lists. Gold rings follow supplied organisms; white marks the selected body.

Starts paused. RUN uses 60 fixed updates/second; stalls beyond 0.1 seconds per rendered frame slow the display. The original source has per-update force, pressure and random-food operations, so update rate is part of this demonstrator's declared conditions. The observer does not normalize those existing rules. Holding pauses the whole model, maps the hand through the host transform, and zeros that body's velocity. Release resumes if Run was active. A held trigger selects the readout. Restart waits for release, resets source seed/model and account together. SUPPLY ROW changes only the calculation shown, not care or stored events.

## Executed checks

34 exact printed-code checks pass in a fresh Godot 4.6 process. Every fenced script is extracted from tutorial.md and compared with study and exportable runtime copies. Tests reconstruct 10 + 2 - 3 + 5 = 14; distinguish species and food/pressure; require immutable event copies; exercise actual mating, health loss, predation and both replacement rules. A 40-second / 2,400-update comparison against the unmodified source matches organism positions, velocities, health, DNA, support counts and RNG state while both population equations reconcile after every step. An independent filtered-default edit predicts gap 5. Three executed faulty copies reverse loss sign, double supply and alias mutable history; tests reject each. Synthetic XRTools pickup/release uses a translated and rotated host, verifies pause/local coordinates/selection, then requires stable body identity and count reconciliation after release.

30 saved-museum checks/captures pass. Nineteen centre-route samples and eight control approaches have actual floor and capsule clearance. Both button banks operate the same model. After 1,800 source updates the pictured run has prey 50 + 0 born - 49 lost + 10 supplied = 11, predators 5 + 0 born - 5 lost + 0 supplied = 0. There were no births in that captured interval; the code test exercises valid mating separately. The image does not claim all named processes happened in that run. Filtering changes expected prey to 1 while actual remains 11; restoring the row reconciles them. Gold markers match surviving supplied organisms.

The images are native Godot captures of the permanent placement, including eye-level and overhead before/after. No physical headset, Quest-performance, independent learner or actual player portal-crossing certification. Existing project UID and Jolt solver-bias warnings remain; final logs contain no GDScript errors. No APK built.

## Replay

python tools/write_swarm_account.py
python tools/place_swarm_account.py
python tools/test_swarm_account.py
python tools/run_encounter_probe.py SwarmIntelligence_Swarm_Intelligence_Algorithms --sequence swarmintelligence --render --no-bridges --output-tag account-room --probe tools/probes/swarm_account_room.gd
python tools/publish_swarm_account.py

The review ZIP is a lesson in the prepared museum, not an empty standalone project. It includes the three supplied ecosystem sources for inspection and all four printed scripts. Runtime copies are local because export presets exclude doc/**. Approval decision remains draft. Only this execution-plan row changes; all other rows and baseline/decision fields are preserved.
