"""Generate revised proposals and canonical tasks without resetting execution progress."""
from pathlib import Path
import json

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
GOAL = "randomness_research"
WRITING_GOAL = "randomness_research_writing"
BOOK = ROOT / "doc/book"
COMPANION = BOOK / "experiments/random-definition/seed-bench-001"
RANDOMNESS = ["Random_Definition", "Random_Entropy", "Random_Cubes", "Random_Gaussian", "Random_Remove",
              "Randomness_10_PRINT_Algorithm", "Random_Rotate_Random_XYZ", "Random_Walk", "Random_Mushrooms",
              "Random_Space_Geometry", "Randomness_Examples_of_Randomness", "Random_Pheromone", "Random_Space", "Random_Game"]
NOISE = ["Random_Noise_Types", "Noise_Columns", "Noise_One", "Noise_Voxel", "Noise_6_Wall", "Noise_Inside_Noise",
         "Noise_Cellular", "Noise_Box", "Noise_Space_10", "Noise_Perlin_Simplex", "Lab_Path"]
PARTICLES = ["Particles_SingleAndArrays", "Particles_Emitters", "Particles_Forces", "Particles_LifetimeAndTypes", "Particles_Collision"]
DEFERRED = ["Random_Source_Lab", "Random_Sensitivity_Lab", "Random_Rule_Workshop", "Particles_Field_Lab"]
OPTIONAL_TASKS = {12, 16, 17, 18, 19}
MOVEMENTS = ["Return and source", "Likelihood and eligibility", "Marks and neighbours", "Field and place",
             "Memory and feedback", "Measurement and omission", "Sensitivity and selection", "Revise the possible"]
EXISTING_TASKS = {5: ["book_randomness.018", "book_randomness.019", "book_randomness.026", "book_randomness.044"],
                  6: ["book_randomness.001", "book_randomness.017", "book_randomness.020", "book_randomness.021"],
                  7: ["book_noise.014", "book_noise.017", "book_noise.019", "book_noise.020"],
                  15: ["book_randomness.030"], 16: ["book_randomness.028", "book_randomness.029"],
                  18: ["book_randomness.028", "book_randomness.029"],
                  20: ["book_randomness.017", "book_randomness.018", "book_randomness.019", "book_randomness.020",
                       "book_randomness.028", "book_randomness.029", "book_randomness.030", "book_noise.020"]}

# Stable task IDs survive changed lesson numbers and route proposals.
WORK = [(1,
  'Establish the sequence, museum and artifact baseline',
  'read',
  [],
  [],
  [],
  'Snapshot every artifact cell in randomness/noise/particle sequence maps plus museum-only Biome_Cage. '
  'Resolve registry candidates and direct scene scripts; record hashes and distinguish sequence from museum '
  'membership. Preserve the supplied research text and publish inventory and scoped findings.',
  'Static coverage includes 31 maps; every selected name/scene resolves at the snapshot. Duplicates and '
  'runtime/learner limits remain visible. No scene is certified by execution.'),
 (2,
  "Record the author's decision on the concrete route and first pilot",
  'design',
  [1],
  [],
  [],
  'Review the revised HALLS.md, PARTICLE_PATH.md, COMPARISON.md and RESEARCH_RECORD.md against '
  'comparison.json. Select the six-stop early randomness trial, unchanged noise exit and five existing '
  'particle lessons, or record revisions. Four new halls are deferred; optional field/sensitivity/rule '
  'returns need separately selected scope. Existing seven-step verification is already accepted. A later '
  'implementation request may supply the needed authorization; do not demand redundant confirmation. Record '
  'concrete route, host, prose and pilot choices without changing live maps in this task. Include the Text '
  'Simulation Loop, a bounded source-versus-Entropy opening trial, and three pilot outcomes: apparatus '
  'result, revised/competing passage and a task-plan decision. The later supplied texts are methodological '
  'direction, not approval to execute every proposed world.',
  'A decision record distinguishes author choices from alternatives. This review changes no live hall order. '
  'The first build is one complete bounded experiment.'),
 (3,
  'Complete one seed-bench experiment cycle and record adapter',
  'build',
  [2],
  ['Random_Definition'],
  ['seed_replay_demo', 'random_return'],
  'Extend the accepted pilot with baseline, one interpretation change, an independent kept result, replay '
  'and a small complete tutorial reconstruction. SAME RECORD changes colour/height interpretation without '
  'drawing again. Record draw roles/order, seed/captured state, values, procedure version, observation and '
  'next-change proposal. Build only record fields needed now. Preserve the atmospheric record, sphere and +1 '
  'DRAW encounter. Supply a native behaviour probe and exact printed-code reconstruction. Use '
  'RESEARCH_RECORD.md: explicit export/import/clear, parent lineage, replay scope, observation and next '
  'change. Every destination must retain a local baseline. Capture no raw headset/audio stream by default; '
  'minimum relevant target input is separately chosen. Reject invalid/oversized/unknown-version imports '
  'without silently replacing them. Bind a selected passage/interpretation record to this pilot; keep '
  'sampled variation, changed interpretation and revised relation rules distinct. Coordinate with writing '
  '.001-.002 so a passage can initiate a bounded variant and its observation can revise the passage. A '
  'speculative sleeve is not a mandatory pilot. Use the existing local baseline and record what the new '
  'observation proposes to change in the task plan.',
  'Data replay matches under the declared build. Presentation changes consume no draws. A shared-reference '
  'mutation is rejected. The cycle ends with observation and a further question/change. Human reconstruction '
  'remains not tested until a person performs it.'),
 (4,
  'Build an honest source recorder at the existing seed bench',
  'build',
  [3],
  ['Random_Definition', 'Random_Entropy'],
  ['trng_vs_prng', 'hardware_entropy_decay', 'seed_replay_demo'],
  'Correct simulated physical-source and body-weathering claims while retaining the artworks. Build the '
  'accepted recorder with a seeded stream, engine secure bytes and separately labelled timing measurements. '
  'Preserve the saved atmospheric response offline. Persist acquisitions/provenance. Implement X1: REPLAY '
  'RECORD cannot acquire again; NEW ACQUISITION is separate. Report platform/source failures without '
  'fabricated fallback. Host the comparison beside Definition first. New Source Lab is deferred. Timing '
  'acquisition is optional and never certified as entropy by a histogram; preserve the usable offline '
  'baseline.',
  'Replay needs no fresh source call. Acquisition records an event/provenance rather than just a changed '
  'picture. Failures stay explicit. The display makes no untested entropy-quality or quantum-hardware '
  'claim.'),
 (5,
  'Connect distribution, birth and eligibility experiments',
  'build',
  [3],
  ['Random_Gaussian', 'Random_Remove', 'Random_Cubes', 'Random_Mushrooms'],
  ['distribution_sampler', 'remove_random', 'sampling_hoppers', 'mushrooms'],
  'Preserve uniform/Gaussian/rebinning and candidate-set lessons. Add the record adapter and '
  'law/parameters/birth-table export for X2. Keep clipping/bins separate from raw values. Retain exclusions '
  'and the empty-set outcome. Review physical throws and fixed recipes as retained route encounters. '
  'Extended laws need individually defined follow-ons; equal seeds alone do not imply matched samples. Trial '
  'Cubes before Gaussian in the six-stop opening. Preserve the existing sigma control and link completed '
  'book_randomness.044 instead of duplicating it. P2 can complete with a local birth table; X2 is an '
  'explicitly selected integration increment.',
  'Rebinning preserves samples/RNG state. Empty sets do not draw invalid indices. Birth IDs/law metadata '
  'round-trip. Saved die outcomes are not presented as exact physical trajectory replay.'),
 (6,
  'Carry decisions through marks and neighbours',
  'build',
  [5],
  ['Randomness_10_PRINT_Algorithm', 'Random_Space_Geometry'],
  ['ten_print', 'ten_print_structure', 'perlin_noise_bridge'],
  'Retain input and receiver versions in the marks and matched-field studies. Compare independent heights '
  'and a correlated field at matched addresses. Separate sampling scale from physical spacing. Keep visual '
  'marks distinct from navigable connectivity. Stage revised prerequisite/handover paragraphs for the '
  'proposed order. The local textile is already in 10 PRINT; do not move it again. Existing '
  'book_randomness.001 is done: inspect its solution before changing geometry. Reuse geometry_noise; the '
  'imported 0.18 suggestion is not an accepted calibration or instruction to create a duplicate artifact.',
  'Receivers use the retained decision grid without new draws. Field queries are stable. Neighbour/count '
  'measures use declared fixtures. Maze appearance is not connectivity proof.'),
 (7,
  'Make field receivers and spatial decisions reconstructable',
  'build',
  [6],
  ['Random_Noise_Types',
   'Noise_One',
   'Noise_Voxel',
   'Noise_Cellular',
   'Noise_Box',
   'Noise_Columns',
   'Noise_Inside_Noise',
   'Noise_6_Wall',
   'Noise_Space_10',
   'Noise_Perlin_Simplex'],
  ['randompoints', 'geometry_noise', 'related_weather', 'noisetorus', 'voxelnoise', 'cellular_atrium_space'],
  'Work one selected noise encounter at a time using its current author focus. Preserve '
  'rejection/minimum-distance and Related Weather. Add field/receiver retention in Noise One, '
  'threshold/occupancy in Voxel and separate field/render/collision policies in Cellular. Define X3/X5 '
  'exports without treating scalar noise as force. Retain all eleven sequence identities and the optional '
  'Lab Path coda. Resolve tutorials marked proposed before declaring them reconstructable. Preserve the '
  'current Perlin/Simplex handover to Shaders. At Noise Space 10 add a bounded '
  'prediction/change/observation/retained-failure/next-question trial, with passage, collider and '
  'viewer-scale variables separate. Reuse mixer/Worley scenes; do not activate deferred maps or duplicate '
  'them. The local Lab Path/readout/global-input tickets are done; noise .020 remains separate open headset '
  'evidence.',
  'Receiver/threshold changes preserve field data. Attempt/refusal records are visible. Collision checks '
  'distinguish support from visible displacement. Each selected printed lesson reconstructs from declared '
  'incoming state.'),
 (8,
  'Write particle P1: one state becomes a population',
  'build',
  [3],
  ['Particles_SingleAndArrays'],
  ['example_4_1_single_particle_vr', 'example_4_2_array_particles_vr'],
  'Build the small learner reference from the continuing point: explicit state, IDs, fixed tick, kept copies '
  'and bounded population. Production Particle is inspected comparison material, not a hidden dependency. '
  'Write the initial complete tutorial and behaviour probe. Provide STEP/RUN/PAUSE/KEEP/RESET in desktop and '
  'VR. First audit exact code inheritance, core Particle/Emitter/Confetti, scene dependencies, inputs and '
  'source/license notices. P1 teaches a simple fixed lifetime and retirement; curves and types come at P4. '
  'Require a prediction before the comparison and capture any missing reconstruction step as learning debt.',
  'Zero-force displacement, empty population, simultaneous retirement and independent copies pass. Render '
  'cadence does not alter fixed-tick state. Omitting the copy fails ordinary checks. Distinguish synthetic '
  'from physical input evidence.'),
 (9,
  'Write particle P2: replayable births and emitters',
  'build',
  [8],
  ['Particles_Emitters'],
  ['example_4_3_particle_emitter_vr', 'example_4_4_multiple_emitters_vr', 'example_particle_body'],
  'Continue exact P1 output with emission schedule/accumulator, source IDs, independent streams or birth '
  'tables and a full-cap policy. Prepare X2; verify it only after the sender in .005 is available, and keep '
  'the local deterministic birth table usable. Moving the emitter affects future births in a stated '
  'coordinate frame without silently moving old particles. Print exact edits and retain the assembled '
  'program. Compare regular versus burst schedules at equal total births over a stated interval, with '
  'cap/skipped births and event times recorded. Stochastic schedules are a later separate one-condition '
  'trial.',
  "Zero rate/capacity/skipped births behave as declared. Independent emitters do not consume each other's "
  'draws. Replay restores accumulator/IDs/streams. Imports preserve existing live state.'),
 (10,
  'Write particle P4: lifetime, kinds and bounded children',
  'build',
  [11],
  ['Particles_LifetimeAndTypes', 'Particles_Emitters'],
  ['lifetime_curves', 'example_4_5_inheritance_polymorphism_vr', 'sub_emitters'],
  'Continue P3 with normalized age, appearance curves, a second update behaviour and retirement. Separate '
  'appearance from dynamics. Add bounded parent-child emission only after lifetime/identity. Preserve source '
  'attribution. A code type is not automatically a biological lineage. Retain the tested force update and '
  'compare turnover at fixed births. Curves/behaviour types do not replace the already taught fixed '
  'lifetime.',
  'Curve edits preserve trajectory/RNG. Simultaneous deaths work; child emission occurs once per event and '
  'respects depth/count budgets. Retained parents stay unchanged.'),
 (11,
  'Write particle P3: forces with recorded input',
  'build',
  [9],
  ['Particles_Forces'],
  ['force_fields', 'example_2_6_single_attractor_vr'],
  'Continue P2 with force law, distance clamp, mass convention and recorded hand/desktop targets. '
  'Distinguish assigned velocity from integrated force. Define damping per second or per fixed tick rather '
  'than inheriting update-dependent drag. Print exact continuation edits. Field research is optional later '
  'work; completing this force lesson does not require randomness or noise chapters.',
  'Independent fixtures cover zero/opposite force, mass and coincident positions. Rotated/scaled hosts '
  'preserve coordinates. Replay uses recorded input, not the wall clock.'),
 (12,
  'Add optional E1 particle field comparison in existing halls',
  'build',
  [13, 7],
  ['Particles_Forces', 'Random_Space_Geometry', 'Noise_Space_10'],
  ['curl_noise_particles', 'related_weather'],
  'Branch from completed P5 with matched births and independent-kick versus frozen-field modes. Trial a '
  'comparator at Particles Forces and define scalar-to-vector/receiver mappings. Correct curl labels to the '
  'sine-potential finite-difference implementation. Localize reference respawn draws and record boundary '
  'exits. Implement X3 and incompatibility handling. Scope any divergence/incompressibility claim '
  'numerically. A new Field Lab is deferred. Compare fixed motion, independent kicks and frozen field with '
  'the same births/integrator/renderer/boundaries; retain bounded dispersion/path measurements and exits. No '
  'mandatory sixth tutorial or new canonical curl implementation.',
  'Static queries repeat without draws; appearance edits do not move particles. Respawn differs from wrap. '
  'Phase/ticks/stochastic events replay. Matched comparisons expose each changed condition.'),
 (13,
  'Write particle P5 and verify the complete five-lesson chain',
  'build',
  [10],
  ['Particles_Collision'],
  ['example_4_6_particle_repeller_vr', 'particle_campfire'],
  'Continue P4 with absorb/reflect/wrap on matched trajectories and a small pair-contact case before '
  'scaling. Separate repulsion from collision. Record hand input/event order. Offer campfire as a visual '
  'composition with physical omissions stated. Prepare X6 export using stable IDs. No field-lab dependency. '
  'Change one fire/ember/smoke parameter until the composition no longer reads as fire; retain the viewer '
  'judgment without a compulsory aesthetic conclusion. Independently reconstruct all five exact printed '
  'continuations in order P1/P2/P3/P4/P5, with predictions, variants, resets and a further change. Audit '
  'source/license notices. Record automation, human learner and actual headset evidence separately; never '
  'fill tutorial gaps from private context.',
  'Reflection changes the specified component; wrapping retains identity; absorption retires once; contacts '
  'remain finite. Measure approximation gain/loss. Test budgets on named hardware, without combustion '
  'claims. All five lessons have incoming/outgoing code versions, a full cycle record and explicit '
  'not-tested status for unavailable human/headset evidence.'),
 (14,
  'Connect measurement to preserved arrangements and trials',
  'build',
  [3],
  ['Random_Entropy', 'Randomness_Examples_of_Randomness'],
  ['shannon_entropy_meter', 'entropy_axiom', 'monte_carlo_dartboard'],
  'Resolve the selected duplicate entropy_axiom registration before asserting the loaded scene. Retain '
  'equal-count/different-arrangement fixtures and the existing Monte Carlo sample-budget study. Add '
  'comparison records with explicit variable, log units, order/reference. Implement the entropy side of X5 '
  'with task .007. Develop the adjacency companion early at Entropy so the route can meet measurement before '
  'distributions. Do not wait for the optional research extensions to complete this instrument.',
  'Rearrangement preserves counts while a declared neighbour measure changes. Rebinning spends no draws. '
  'Monte Carlo records trial count/error without requiring monotonic improvement. Selected registry '
  'resolution is unambiguous.'),
 (15,
  'Follow a walk into feedback and retain the difference',
  'build',
  [6, 14],
  ['Random_Walk', 'Random_Pheromone'],
  ['random_walk_terrarium', 'random_position_rails', 'pheromone_terrain'],
  'Preserve assignment versus accumulated step versus deposited-signal distinctions. Implement X4 and '
  'matched CUT/CONNECT comparisons. Feedback creates a branch rather than replaying the old trajectory. '
  'Brownian, bounded long-step and Markov extensions remain individually defined optional studies. This uses '
  'current walk/signal lessons, not optional particle E1. Link the open pheromone headset ticket instead of '
  'duplicating or closing it.',
  'The baseline trace has no influence when guidance is cut. Feedback acts only through the declared path. '
  'Replay includes history and update order. Record an observed difference or an inconclusive question.'),
 (16,
  'Trial an optional deterministic pair in Random Space',
  'build',
  [14, 15],
  ['Random_Space'],
  ['lyapunov_bench', 'percolation_ca'],
  'Build one paired deterministic experiment with nearby starts, the same rule/fixed ticks, explicit '
  'precision/build and separation record. Keep Lyapunov landscape as companion. Percolation is a separate '
  'later connectivity study after preparation; thresholding alone is not criticality. Trial the apparatus '
  'inside the existing hall after its path issue is resolved. A new Sensitivity Lab is deferred unless '
  'spatial evidence justifies it.',
  'Identical starts match under the reference. Epsilon changes only the stated initial condition. The '
  'deterministic run spends no new draws. A step-size comparison and bounded interval clarify numerical '
  'effects.'),
 (17,
  'Extend selection into one recorded mutation experiment',
  'build',
  [16],
  ['PG_Genetic_Evolution', 'Random_Mushrooms'],
  ['mushrooms'],
  'Keep the six-candidate target/ranking witness first. Add bounded mutation/offspring with parent IDs, '
  'retained genes and a selection/viability criterion. Permit visitor selection distinct from score. '
  'Preserve later-return prerequisites rather than moving all Procedural Generation forward.',
  'Evaluator changes do not mutate candidates. Mutation changes only declared fields and preserves parents. '
  'Selection/preference are distinct. The tutorial actually reconstructs offspring.'),
 (18,
  'Trial optional E2 rule revision in Random Space',
  'build',
  [13, 17],
  ['Random_Space', 'Random_Game'],
  ['example_particle_body', 'mushrooms', 'textile_comparison'],
  'Use sixteen entities and the same inputs to compare old/new relation rules. Add one reversible '
  'detach/connect/sensor change, versions and rollback. Separate drawn links from force-bearing bonds. Use '
  'ParticleBody ideas without teaching its nearest-neighbour fallback as Delaunay. Implement X6 and optional '
  'E2. Defer the sleeve as a further investigation. A dedicated Rule Workshop is deferred. Keep the '
  'grid-route fixture independent of the particle learner portfolio. This is not a compulsory sixth particle '
  'lesson. Optional E2 can compare a fixed boundary with an explicit contact-count/permeability rule, or '
  'visible links with force-bearing connections, following TEXT_SIMULATION.md. Preserve the paragraph, '
  'interpretation and predecessor; a remembering wall is not installed behaviour.',
  'A stated relation is impossible under the old fixture and possible under the new rule. Parent state '
  'survives, invalid links are handled, each rule replays, and independent reconstruction is separately '
  'recorded.'),
 (19,
  'Return an experiment to QFEP and examine AI-assisted revision',
  'build',
  [18],
  ['QFEP_Sandbox', 'QFEP_Synthesis', 'Random_Definition'],
  [],
  'Reuse CONNECT/CUT and a declared receiver. Build only one accepted explore/retain/revise study with named '
  'variable, viability criterion, feedback path and limits. X7 returns a record/provenance, not arbitrary '
  'grammar execution in the seed bench. If selected, add offline versioned AI comparisons separating '
  'fixed-model samples, prompt revision and model revision; record assistance and visitor judgment.',
  'Offered/used values stay distinct; cut input is not stopped time. Evidence may end in a question without '
  'endorsing QFEP. No universal lambda or untested Markov blanket is claimed. X7 preserves lineage and '
  'explains incompatible execution.'),
 (20,
  'Integrate the selected route and five lessons with scoped evidence',
  'verify',
  [4, 5, 6, 7, 13, 14, 15],
  [],
  [],
  'Reconcile the accepted manifest with sequences, Forces branch, map_authored and museum-plan derivation. '
  'Preserve Biome_Cage, the optional Lab_Path and Perlin/Simplex exit. Do not deploy deferred hall names. '
  'Stage exact before/after map-cell and prose-handover changes with rollback references; preserve unrelated '
  'local edits. Complete the writing subgoal and verify selected transfers, especially X2 with both sender '
  'and receiver available. The five-lesson delivery does not wait for optional .012 or .016-.019. Resolve or '
  'provide an explicitly accepted bypass for the current Random Space path issue before releasing a route '
  'that relies on that passage; keep the existing ticket and its evidence authoritative. Leave their '
  'transfers explicitly deferred/not tested until selected and built. Keep scene load, stability, '
  'performance, headset and independent learner evidence separate; do not expand source checking into '
  'unsupported claims. Include the reciprocal passage/apparatus record and the selected post-pilot plan '
  'revision. A deferred or rejected world remains retrievable and is never automatically promoted into the '
  'museum.',
  'Selected stops and local baselines remain usable with imports absent or incompatible. Both sides of every '
  'selected transfer preserve declared records. Route/handovers agree and all five printed programs '
  'reconstruct within declared evidence scope. Deferred investigations are not reported complete. Existing '
  'book tickets keep their owners/status; human/headset evidence stays open until observed.')]


WRITING = [
    (1, "Bind a selected passage to interpretations and learning debt", [],
     "Read TEXT_SIMULATION.md, RESEARCH_RECORD.md and text_experiments.json. Choose a passage for the bounded pilot and retain its exact excerpt, source version and companion ID. Extend the existing record with separate interpretation IDs, assumptions, omitted meanings, apparatus versions, evidence and revision links. Permit several worlds per passage and competing accounts per world. Distinguish unverified claims, unfamiliar mechanisms and unresolved interpretations; retain known contributors, uncertain origins and the person responsible for publication. Prose remains literary, not an execution language.",
     "The selected source can be recovered; two interpretations coexist without overwriting it. Unbuilt variants have no invented apparatus path or observation. Known contributions and missing understanding are explicit."),
    (2, "Run a bounded Text Simulation Loop beside the seed-bench pilot", [1],
     "Coordinate with main .003 using the selected scope from .002. Let one passage initiate an explicit bounded interpretation; preserve at least one alternative. Build a small experimental variant and native probe under this task's directory when runtime work is authorized. Compare the source-oriented and Entropy-oriented openings at the available evidence level, without building a Source Lab. Keep apparatus A/B and passage A/B with actual evidence. Return the observation to the writing and propose a further apparatus or task change. A textual simulation is a thought experiment, not executed or headset evidence. Do not wait for the whole noise route or force a sleeve implementation. Preserve failures, rival accounts and noncanonical worlds.",
     "Completion requires a traceable passage → interpretation → apparatus → scoped observation → revised/competing passage → next-change record. If a required stage is missing, leave the task blocked/not tested rather than marking it complete. Predict, compare and keep evidence; a model's imagined outcome cannot close execution or human encounter gates."),
    (3, "Audit reciprocal claims and the five reconstructed lessons", [2],
     "Audit proposed passages, interpretation records and five particle lessons: source/PRNG/hash, distribution/correlation, memory, entropy, chaos and variational free energy remain distinct. Keep source/license notices. Hard claims use primary sources or scoped tests, otherwise unverified labels. Compare the original proposition with the operational assumptions and actual evidence; do not infer one definitive literary meaning from a passing program. Separate code inspection, thought experiment, executed desktop simulation, AI image interpretation, human desktop/VR and independent reconstruction.",
     "Every asserted observation has an observer, method and recoverable source/build; technical correctness and a collaborator's understanding are separate. Five exact continuations and their assistance/evidence are documented."),
    (4, "Record editorial choices across passages and possible worlds", [3, 5],
     "Review concrete versioned passages, observations, competing interpretations, contributions and remaining learning debt. Record accept/revise/defer/abandon decisions with the responsible reviewer and reasons. Preserve predecessor text and noncanonical variants rather than smoothing them into a progress narrative. This is the delivery review; the earlier pilot review in .005 has already made the next work revisable. Do not claim current specification approval establishes runtime findings or publication approval.",
     "Each selected passage and variant has an explicit disposition, evidence basis and next question. Changes in what the book or a collaborator understands are described without a mandatory novelty or learning score."),
    (5, "Let the pilot revise the future task graph", [2],
     "Use the pilot observation and reciprocal record to propose continuing, branching, reprioritizing, replacing or abandoning the next planned work. Preserve the predecessor route/task files and hashes; record affected stable IDs, dependencies, alternatives, trigger evidence and the selection decision in plan_revisions.json. Keep completed/claimed evidence and coordinate any changed active scope. Cancel superseded tasks with a reason; never reuse IDs for unrelated work. For selected changes update both build_plan.py and canonical JSON so regeneration cannot restore a discarded plan. Existing user authorization may cover the change; only genuinely new scope needs another decision. Validate the graph and retain an explicit continue-unchanged decision if warranted.",
     "A traceable evidence-led decision precedes automatic source/distribution expansion. The prior graph survives, changes or continuation have reasons, dependencies resolve without cycles, and a proposed change is not falsely marked applied. The record may redirect work away from the original hall outline."),
]

# Refine existing work rather than creating a second set of book/pilot tickets.
BOOK_WORK = {
    2: " The supplied concrete book architecture proposes the 4x4, 48-value RGB/height comparison as the first pilot. Record its selected scope using the existing companion; retain the established museum host and the separate opening-order trial.",
    3: " Use doc/book/experiments/random-definition/seed-bench-001 as the companion. Retain sixteen ordered triples (48 scalar values); compare fixed local centre height with 0.10 m + 0.30 m * the triple mean. Keep RGB visible, XZ layout, dimensions, host and lighting fixed; switch only the height rule with no new draws. Read proposition.md for the exact proposed layout and independently calculated fixture. Preserve the shipped vertical grids. The authored text simulation is a hypothesis; attach actual scene/build/run records only when they exist. Prove kept-copy independence and no draw on switching, then supply the exact printed continuation and independent reconstruction evidence.",
    20: " Preserve Read/Reconstruct/Investigate links and the versioned companion sources. The reading route and research graph have different scopes; selected integration must not silently rewrite any frozen edition. Report the actual edition candidate and review status, not an assumed publication.",
}
BOOK_WRITING = {
    1: " Start with the authored seed-bench companion and its archived source binding; verify rather than duplicate it. Keep the six components, separate IDs and Read/Reconstruct/Investigate links. New source versions retain predecessors. The existing sleeve and wall records remain separate design branches. Record source ownership and unknown model/version information honestly.",
    2: " Use the companion's text-simulation.md as an explicit prediction and compare it with an actual selected execution. Fill observations.md and experiment.json only from scoped evidence, then revision.md from the resulting decision. Use the same 48 values for RGB and height, with RGB unchanged in both modes. Keep mapping A/B distinct from the source-versus-Entropy opening trial. Neither a hypothetical trace nor these authored companion documents completes this task.",
    3: " Check all three reader entry modes, source recovery after later edits, and the separation of prediction from observation. Review the blog draft against actual implementation status; not every hall yet has its proposed tutorial. A proposed contribution must carry its source version, method, assistance and limits before editorial acceptance.",
    4: " Prepare a frozen local edition candidate only from the selected, reviewed material: unique edition/parent IDs, ordered chapter and tutorial versions, recoverable snapshots or Git objects with hashes, code/build and asset provenance, contributor decisions, evidence/debt scope, readable output hash and change record. Confirm the readable artifact before freezing. Later corrections create a new edition; model or script updates never silently alter an old one. Draft/frozen/published remain separate. Publication requires its actual decision and is not implied by freezing. Keep open branches navigable outside the curated route.",
    5: " Link the companion's actual observation/revision to the plan decision; the current architecture clarification is not pilot evidence. The supplied architectural text and historical plan must remain recoverable.",
}


def absolute(relative):
    return (ROOT / relative).as_posix()


def write_json(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")


def preserve_progress(path, tasks):
    if path.exists():
        previous = {t["id"]: t for t in json.loads(path.read_text(encoding="utf-8-sig"))["tasks"]}
        for task in tasks:
            for key in ("status", "claimed_by", "done_at", "blocked_reason", "progress", "evidence", "notes"):
                if key in previous.get(task["id"], {}):
                    task[key] = previous[task["id"]][key]


def base_issue(goal, title):
    return {"goal_id": goal, "goal_title": title, "kind": "spec", "labels": ["ready-for-agent"],
            "label_meaning": "Usable planning input; not authorization for unrequested museum changes.",
            "why": "Develop reconstructable experiments whose observations can change the apparatus and its writing.",
            "specification": str(HERE / "SPEC.md"), "decision_record": str(HERE / "DECISIONS.md"),
            "implementation_authorization": "This request revises the spec. Record selected implementation scope in .002; prior authorization need not be asked again.",
            "prerequisites": [], "tasks": []}


def main():
    route = {"schema": "ada.randomness-research.proposal.v2", "date": "2026-10-14", "status": "proposed",
             "runtime_installed": False, "baseline_commit": "e5414cb18", "revision_basis": "COMPARISON.md",
             "accepted_verification": "Seven-step cycle, three verification levels and separate runtime/headset/learner evidence",
             "movements": MOVEMENTS, "randomness_order": RANDOMNESS, "noise_order": NOISE,
             "particle_order": PARTICLES, "required_new_maps": [], "deferred_new_maps": DEFERRED,
             "optional_stops": ["Lab_Path"], "museum_interludes": ["Biome_Cage"],
             "preserved_exit": {"map": "Noise_Perlin_Simplex", "destination_sequence": "shaders"},
             "later_returns": ["PG_Genetic_Evolution", "QFEP_Sandbox"],
             "research_extensions": {"source": ["Random_Definition"], "sensitivity": ["Random_Space"],
                                     "E1": ["Particles_Forces", "Random_Space_Geometry", "Noise_Space_10"],
                                     "E2": ["Random_Space", "Random_Game"]},
             "transfer_ids": [f"X{i}" for i in range(1,8)], "first_local_transfer": "X1",
             "first_cross_hall_transfer": "X2", "optional_extension_transfers": ["X3", "X6", "X7"],
             "imports_optional": True, "destinations_have_local_baselines": True,
             "book_architecture": {"contract": "doc/book/RECURSIVE_ARCHITECTURE.md",
                                   "pilot_record": "doc/book/experiments/random-definition/seed-bench-001/experiment.json",
                                   "reader_modes": ["read", "reconstruct", "investigate"],
                                   "pilot_status": "proposed_not_run", "edition_status": "not_frozen"},
             "text_simulation_loop": {"contract": "TEXT_SIMULATION.md", "examples": "text_experiments.json",
                                      "writing_cycle": ["generate", "read", "question", "test", "revise", "rediscover"],
                                      "many_to_many": True, "observations_can_revise_plan": True,
                                      "pilot_outcomes": ["apparatus result", "revised or competing passage", "task-plan decision"]},
             "opening_trials": {"status": "proposed_not_run", "A": ["Random_Definition", "source comparison within Random_Definition"],
                                "B": ["Random_Definition", "Random_Entropy"], "requires_new_hall": False}}
    write_json(HERE / "route.json", route)
    comparison = json.loads((HERE / "comparison.json").read_text(encoding="utf-8"))
    issue = base_issue(GOAL, "Randomness as shared experiment: existing halls and five particle lessons")
    issue["success_criteria"] = ["All current hall identities retained with explicit prerequisites",
        "Five particle tutorials complete without optional field/rule extensions", "Seven-step cycles end in a next question/change",
        "Selected transfers preserve records; deferred contracts stay visibly untested", "Runtime, headset and learner evidence remain distinct"]
    for n,title,skill,deps,maps,artifacts,brief,acceptance in WORK:
        brief += BOOK_WORK.get(n, "")
        output = HERE / "implementation" / f"{n:03}"
        refs = [absolute(f"commons/maps/{m}/map_data.json") for m in maps]
        refs += [absolute("commons/artifacts/registry/randomness.json"), absolute("commons/artifacts/registry/physics_simulation.json")]
        if n in {8,9,10,11,12,13,18}:
            refs += [absolute("core/particle.gd"), absolute("core/particle_emitter.gd"), absolute("core/confetti_particle.gd")]
        linked = EXISTING_TASKS.get(n, [])
        refs += [absolute(f"doc/tasks/{g}.json") for g in sorted({x.rsplit('.',1)[0] for x in linked})]
        preamble = f"Work in {ROOT.as_posix()}. Read {HERE.as_posix()}/SPEC.md, HALLS.md, PARTICLE_PATH.md, FINDINGS.md, COMPARISON.md, RESEARCH_RECORD.md, TEXT_SIMULATION.md and DECISIONS.md. "
        preamble += "Preserve unrelated working-tree changes. Read inventory.json and comparison.json for exact sources/hashes; reread changed evidence. "
        if n in BOOK_WORK:
            preamble += f"Read {BOOK.as_posix()}/RECURSIVE_ARCHITECTURE.md and {COMPANION.as_posix()}/proposition.md. "
        if n > 2:
            preamble += f"Record accepted implementation scope in {GOAL}.002 before this work. "
        if n in OPTIONAL_TASKS:
            preamble += "This is an optional research extension; it does not gate the five-lesson delivery. "
        if linked:
            preamble += "Coordinate with existing tickets "+", ".join(linked)+"; re-read their current status and reuse completed work, without duplicating or auto-closing them. "
        if n == 1:
            verification = f"python -X utf8 '{HERE.as_posix()}/audit_inventory.py'; python -X utf8 '{HERE.as_posix()}/compare_package.py'"
            out = (HERE / "INVENTORY.md").as_posix()+"; "+(HERE / "comparison.json").as_posix()
        elif n == 2:
            verification = f"python -X utf8 '{HERE.as_posix()}/validate_plan.py'"
            out = (HERE / "DECISIONS.md").as_posix()+"; "+(HERE / "route.json").as_posix()
        else:
            verification = f"& 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe' --headless --path '{ROOT.as_posix()}' --script 'res://{output.relative_to(ROOT).as_posix()}/probe.gd'"
            if maps:
                verification += f"; python '{absolute('tools/map_pathfinder.py')}' check {maps[0]}"
            out = output.as_posix()+"/REPORT.md, probe.gd, exact reconstruction and evidence.json; accepted edits named in the report"
            if n in {8,9,10,11,13}:
                out += "; "+absolute(f"commons/maps/{maps[0]}/tutorial.md")
        depends = [f"{GOAL}.{d:03}" for d in deps]
        if n in {4, 5}:
            depends.append(f"{WRITING_GOAL}.005")
        if n == 20:
            depends.append(f"{WRITING_GOAL}.004")
        issue["tasks"].append({"id": f"{GOAL}.{n:03}", "title": title,
            "spec": preamble+brief+" Source references: "+"; ".join(refs)+". "
                    +f"Write Markdown and JSON evidence under {output.as_posix()}. "
                    +("Create the named native SceneTree probe as part of this task; this command is not a claim it already exists." if n>2 else ""),
            "effort": "half-day" if n<3 else "multi-day", "skill": skill, "depends_on": depends,
            "status": "done" if n==1 else ("open" if n==2 else "blocked"),
            "blocked_reason": None if n<3 else "Depends on selected scope and preceding evidence; implementation has not begun.",
            "claimed_by": None, "done_at": "2026-10-14" if n==1 else None,
            "map_refs": maps, "artifact_refs": artifacts, "sequence_refs": ["randomness","noise","particles"],
            "existing_task_refs": linked, "optional_extension": n in OPTIONAL_TASKS,
            "imported_task_refs": [t["imported_id"] for t in comparison["imported_task_mapping"] if f"{GOAL}.{n:03}" in t["incorporated_into"]],
            "output": out, "verification": verification, "acceptance": acceptance,
            "verification_levels": ["artifact","experiment_cycle","specified_cross_hall"],
            "separate_evidence": ["scene_loading","runtime_stability","performance","physical_VR","independent_learner"]})
    writing = base_issue(WRITING_GOAL, "Recursive writing: passages, possible worlds and revisable research plans")
    writing["success_criteria"] = ["Tutorial, encounter and field notes have distinct functions", "Claims match versioned evidence",
                                    "Writing can initiate apparatus variants and observations can change the book and task plan",
                                    "Unresolved findings lead to a next test", "Contributions and editorial decisions are accountable"]
    for n,title,deps,brief,acceptance in WRITING:
        brief += BOOK_WRITING.get(n, "")
        if n == 4:
            acceptance += " The selected local edition candidate has a recoverable ordered manifest, verified readable output, parent/change record and explicit editorial decision; publication is not inferred."
        tid = f"{WRITING_GOAL}.{n:03}"
        output = HERE / "implementation/writing" / f"{n:03}"
        dependencies = [f"{WRITING_GOAL}.{d:03}" for d in deps] or [f"{GOAL}.002"]
        if n == 2:
            dependencies.append(f"{GOAL}.003")
        if n == 3:
            dependencies.append(f"{GOAL}.013")
        writing["tasks"].append({"id":tid,"title":title,"skill":"verify" if n>=3 else "edit","effort":"half-day",
            "spec":f"Work in {ROOT.as_posix()}. Read {HERE.as_posix()}/SPEC.md, RESEARCH_RECORD.md, COMPARISON.md, TEXT_SIMULATION.md, text_experiments.json, FINAL.md and PARTICLE_PATH.md. Read {BOOK.as_posix()}/RECURSIVE_ARCHITECTURE.md and {COMPANION.as_posix()}/experiment.json. Preserve unrelated and current hall prose. "+brief+f" Write Markdown/JSON evidence to {output.as_posix()}/REPORT.md and ledger.json; reference the companion's canonical run/evidence records instead of duplicating them. Source paths and versions must be named. Follow plan_revisions.json for before/after task evidence; this pass has not executed these experiments.",
            "depends_on":dependencies,"status":"blocked","claimed_by":None,"done_at":None,
            "blocked_reason":"Depends on selected scope and versioned evidence; implementation has not begun.",
            "output":str(output / "REPORT.md")+"; "+str(output / "ledger.json")+("; "+str(output / "probe.gd") if n == 2 else "")+("; "+str(output / "edition/manifest.json")+"; verified readable artifact and CHANGELOG.md under that edition directory" if n == 4 else ""),
            "verification": (f"& 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe' --headless --path '{ROOT.as_posix()}' --script 'res://{output.relative_to(ROOT).as_posix()}/probe.gd'; then inspect the linked passage and scoped observation in REPORT.md; record human/headset evidence separately" if n == 2 else f"python -X utf8 '{HERE.as_posix()}/validate_plan.py'; then verify each passage/interpretation/evidence/version link against its actual source and record the plan or editorial decision"),
            "acceptance":acceptance,"map_refs":["Random_Definition","Random_Entropy","Random_Space","Noise_Space_10","Particles_Collision"],"artifact_refs":[],
            "imported_task_refs":[t["imported_id"] for t in comparison["imported_task_mapping"] if tid in t["incorporated_into"]],
            "verification_levels":["artifact","experiment_cycle","specified_cross_hall"],
            "separate_evidence":["scene_loading","runtime_stability","performance","physical_VR","independent_learner"]})
    for goal in (issue, writing):
        target = ROOT / "doc/tasks" / f"{goal['goal_id']}.json"
        preserve_progress(target, goal["tasks"])
        write_json(target, goal)
    md = ["# Work to undertake", "", "Revised from the ZIP comparison, recursive-writing texts and concrete book architecture. Twenty stable implementation/planning IDs remain in the main goal; five writing tasks form a linked subgoal. All thirty-four imported IDs map into these canonical tasks in comparison.json. Imported JSON files are archived input, not duplicate live tickets.", "",
          "[Main tracker](../../../tasks/randomness_research.json) · [Writing tracker](../../../tasks/randomness_research_writing.json) · [Comparison](COMPARISON.md) · [Text Simulation Loop](TEXT_SIMULATION.md)", "",
          "The static audit is complete. Task .002 remains open to record selected implementation scope; the user's current request authorizes this specification revision. Existing verification decisions do not need reconfirmation. No runtime task is marked complete.", "",
          "The first build is .003, one complete seed-bench cycle, alongside W001/W002 passage interpretation and reciprocal experiment. W005 then records what the observation changes about future work; proposed source/distribution expansion waits for that review. The five particle lessons build as **.008 → .009 → .011 → .010 → .013**; IDs remain stable although lesson numbers changed. P2 has a local birth table, so it does not wait for the distribution sender. Integration checks X2 after both sides are available.", "",
          "Optional .012 and .016–.019 retain field/sensitivity/selection/rule/QFEP research. They do not gate .020 or the five tutorials. No new hall is required. The writing subgoal begins at the pilot; it no longer waits for noise implementation. W005 may redirect the future graph. Preserve the previous graph and reasons, update generator plus JSON together, and keep claimed/completed evidence. W004 later gates the selected delivery review.", "",
          "The [book architecture](../../RECURSIVE_ARCHITECTURE.md) connects six components and Read/Reconstruct/Investigate entry modes. The [first companion](../../experiments/random-definition/seed-bench-001/proposition.md) is authored design work: .003/W001/W002 must still complete its actual 48-value RGB/height cycle. W003 checks claims and entry links; W004 prepares a reviewed, frozen edition candidate with recoverable source and output versions. No edition is frozen or published by this specification pass. The sleeve remains a later selected experiment.", "",
          "| Task | Work | Depends on | Status | Scope |", "| --- | --- | --- | --- | --- |"]
    for goal in (issue,writing):
        for t in goal["tasks"]:
            short = t["id"].replace(GOAL+".","").replace(WRITING_GOAL+".","W")
            deps = ", ".join(d.replace(GOAL+".","").replace(WRITING_GOAL+".","W") for d in t["depends_on"]) or "—"
            md.append(f"| {short} | {t['title']} | {deps} | {t['status']} | {'optional extension' if t.get('optional_extension') else 'selected delivery'} |")
    md += ["", "Every cycle preserves a difference, inconclusive result or useful question, replay scope and a proposed further change. Scene loading, runtime stability, performance, headset operation and independent human reconstruction require separate evidence. Existing book tickets keep their own status; comparison.json records the inspected snapshot, not authority to close them.", "",
           "build_plan.py preserves execution status/claims/evidence/notes on regeneration. It updates the proposal text and dependencies; review changed scope before continuing a claimed task. Commands for future native probes do not imply those probes already exist."]
    (HERE / "TASKS.md").write_text("\n".join(md)+"\n",encoding="utf-8")
    print(f"Published {len(issue['tasks'])}+{len(writing['tasks'])} tasks; 14 randomness, 11 noise and 5 particle identities; no required new halls.")


if __name__ == "__main__":
    main()
