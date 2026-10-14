"""Generate the proposal manifest and a local task issue in the repository schema."""
from pathlib import Path
import json

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
GOAL = "randomness_research"
MOVEMENTS = [
    ("I", "An arrival and a return", ["Random_Definition", "Random_Source_Lab"]),
    ("II", "Likelihood and permission", ["Random_Gaussian", "Random_Remove"]),
    ("III", "Marks become relations", ["Randomness_10_PRINT_Algorithm", "Random_Space_Geometry"]),
    ("IV", "A field becomes a place", ["Random_Noise_Types", "Noise_One", "Noise_Voxel", "Noise_Cellular"]),
    ("V", "The past enters the next choice", ["Random_Walk", "Random_Pheromone"]),
    ("VI", "An account and its omissions", ["Random_Entropy", "Randomness_Examples_of_Randomness"]),
    ("VII", "Sensitivity and persistence", ["Random_Sensitivity_Lab", "PG_Genetic_Evolution"]),
    ("VIII", "Revise the possible", ["Random_Rule_Workshop", "QFEP_Sandbox"]),
]
PARTICLES = ["Particles_SingleAndArrays", "Particles_Emitters", "Particles_LifetimeAndTypes",
             "Particles_Forces", "Particles_Field_Lab", "Particles_Collision", "Random_Rule_Workshop"]
NEW = ["Random_Source_Lab", "Random_Sensitivity_Lab", "Random_Rule_Workshop", "Particles_Field_Lab"]
SIDES = {
    "Random_Cubes": [1, 3], "Random_Rotate_Random_XYZ": [6, 11],
    "Random_Mushrooms": [3, 4, 16, 17], "Random_Space": [6, 8], "Random_Game": [4, 11],
    "Noise_Columns": [7, 8], "Noise_6_Wall": [8, 10], "Noise_Inside_Noise": [8, 10],
    "Noise_Box": [9, 10], "Noise_Space_10": [9, 10], "Noise_Perlin_Simplex": [6, 8],
    "Lab_Path": [10, 18], "Biome_Cage": [4, 17],
}

# Number, title, skill, dependencies, maps, artifacts, brief, acceptance.
WORK = [
    (1, "Establish the sequence, museum and artifact baseline", "read", [], [], [],
     "Snapshot every artifact cell in randomness/noise/particle sequence maps plus museum-only Biome_Cage. Resolve registry candidates and direct scene scripts; record hashes and distinguish sequence from museum membership. Preserve the supplied research text and publish inventory and scoped findings.",
     "Static coverage includes 31 maps; every selected name/scene resolves at the snapshot. Duplicates and runtime/learner limits remain visible. No scene is certified by execution."),
    (2, "Record the author's decision on the concrete route and first pilot", "design", [1], [], [],
     "Present HALLS.md, PARTICLE_PATH.md and FINAL.md against the baseline. Record accepted or revised hall order, side visits, later-return prerequisites, new halls and the seed-bench pilot. The seven-step cycle and three test levels are already accepted: do not ask to reconfirm them. Keep alternatives labelled proposals and unblock only selected implementation scopes.",
     "A decision record distinguishes author choices from alternatives. This review changes no live hall order. The first build is one complete bounded experiment."),
    (3, "Complete one seed-bench experiment cycle and record adapter", "build", [2],
     ["Random_Definition"], ["seed_replay_demo", "random_return"],
     "Extend the accepted pilot with baseline, one interpretation change, an independent kept result, replay and a small complete tutorial reconstruction. SAME RECORD changes colour/height interpretation without drawing again. Record draw roles/order, seed/captured state, values, procedure version, observation and next-change proposal. Build only record fields needed now. Preserve the atmospheric record, sphere and +1 DRAW encounter. Supply a native behaviour probe and exact printed-code reconstruction.",
     "Data replay matches under the declared build. Presentation changes consume no draws. A shared-reference mutation is rejected. The cycle ends with observation and a further question/change. Human reconstruction remains not tested until a person performs it."),
    (4, "Build an honest source recorder and Source Lab", "build", [3],
     ["Random_Definition", "Random_Source_Lab"], ["trng_vs_prng", "hardware_entropy_decay", "seed_replay_demo"],
     "Correct simulated physical-source and body-weathering claims while retaining the artworks. Build the accepted recorder with a seeded stream, engine secure bytes and separately labelled timing measurements. Preserve the saved atmospheric response offline. Persist acquisitions/provenance. Implement X1: REPLAY RECORD cannot acquire again; NEW ACQUISITION is separate. Report platform/source failures without fabricated fallback.",
     "Replay needs no fresh source call. Acquisition records an event/provenance rather than just a changed picture. Failures stay explicit. The display makes no untested entropy-quality or quantum-hardware claim."),
    (5, "Connect distribution, birth and eligibility experiments", "build", [3],
     ["Random_Gaussian", "Random_Remove", "Random_Cubes", "Random_Mushrooms"],
     ["distribution_sampler", "remove_random", "sampling_hoppers", "mushrooms"],
     "Preserve uniform/Gaussian/rebinning and candidate-set lessons. Add the record adapter and law/parameters/birth-table export for X2. Keep clipping/bins separate from raw values. Retain exclusions and the empty-set outcome. Review physical throws and fixed recipes as side visits. Extended laws need individually defined follow-ons; equal seeds alone do not imply matched samples.",
     "Rebinning preserves samples/RNG state. Empty sets do not draw invalid indices. Birth IDs/law metadata round-trip. Saved die outcomes are not presented as exact physical trajectory replay."),
    (6, "Carry decisions through marks and neighbours", "build", [5],
     ["Randomness_10_PRINT_Algorithm", "Random_Space_Geometry"], ["ten_print", "ten_print_structure", "perlin_noise_bridge"],
     "Retain input and receiver versions in the marks and matched-field studies. Compare independent heights and a correlated field at matched addresses. Separate sampling scale from physical spacing. Keep visual marks distinct from navigable connectivity. Stage revised prerequisite/handover paragraphs for the proposed order.",
     "Receivers use the retained decision grid without new draws. Field queries are stable. Neighbour/count measures use declared fixtures. Maze appearance is not connectivity proof."),
    (7, "Make field receivers and spatial decisions reconstructable", "build", [6],
     ["Random_Noise_Types", "Noise_One", "Noise_Voxel", "Noise_Cellular", "Noise_Box", "Noise_Columns", "Noise_Inside_Noise", "Noise_6_Wall", "Noise_Space_10", "Noise_Perlin_Simplex"],
     ["randompoints", "geometry_noise", "related_weather", "noisetorus", "voxelnoise", "cellular_atrium_space"],
     "Work one selected noise encounter at a time using its current author focus. Preserve rejection/minimum-distance and Related Weather. Add field/receiver retention in Noise One, threshold/occupancy in Voxel and separate field/render/collision policies in Cellular. Define X3/X5 exports without treating scalar noise as force. Review side visits. Resolve tutorials marked proposed before declaring them reconstructable.",
     "Receiver/threshold changes preserve field data. Attempt/refusal records are visible. Collision checks distinguish support from visible displacement. Each selected printed lesson reconstructs from declared incoming state."),
    (8, "Write particle P1: one state becomes a population", "build", [3],
     ["Particles_SingleAndArrays"], ["example_4_1_single_particle_vr", "example_4_2_array_particles_vr"],
     "Build the small learner reference from the continuing point: explicit state, IDs, fixed tick, kept copies and bounded population. Production Particle is inspected comparison material, not a hidden dependency. Write the initial complete tutorial and behaviour probe. Provide STEP/RUN/PAUSE/KEEP/RESET in desktop and VR.",
     "Zero-force displacement, empty population, simultaneous retirement and independent copies pass. Render cadence does not alter fixed-tick state. Omitting the copy fails ordinary checks. Distinguish synthetic from physical input evidence."),
    (9, "Write particle P2: replayable births and emitters", "build", [8, 5],
     ["Particles_Emitters"], ["example_4_3_particle_emitter_vr", "example_4_4_multiple_emitters_vr", "example_particle_body"],
     "Continue exact P1 output with emission schedule/accumulator, source IDs, independent streams or birth tables and a full-cap policy. Implement X2. Moving the emitter affects future births in a stated coordinate frame without silently moving old particles. Print exact edits and retain the assembled program.",
     "Zero rate/capacity/skipped births behave as declared. Independent emitters do not consume each other's draws. Replay restores accumulator/IDs/streams. Imports preserve existing live state."),
    (10, "Write particle P3: lifetime, kinds and bounded children", "build", [9],
     ["Particles_LifetimeAndTypes", "Particles_Emitters"], ["lifetime_curves", "example_4_5_inheritance_polymorphism_vr", "sub_emitters"],
     "Continue P2 with normalized age, appearance curves, a second update behaviour and retirement. Separate appearance from dynamics. Add bounded parent-child emission only after lifetime/identity. Preserve source attribution. A code type is not automatically a biological lineage.",
     "Curve edits preserve trajectory/RNG. Simultaneous deaths work; child emission occurs once per event and respects depth/count budgets. Retained parents stay unchanged."),
    (11, "Write particle P4: forces with recorded input", "build", [10],
     ["Particles_Forces"], ["force_fields", "example_2_6_single_attractor_vr"],
     "Continue P3 with force law, distance clamp, mass convention and recorded hand/desktop targets. Distinguish assigned velocity from integrated force. Define damping per second or per fixed tick rather than inheriting update-dependent drag. Print exact continuation edits.",
     "Independent fixtures cover zero/opposite force, mass and coincident positions. Rotated/scaled hosts preserve coordinates. Replay uses recorded input, not the wall clock."),
    (12, "Build particle P5 Field Lab and repair curl-flow claims", "build", [11, 7],
     ["Particles_Field_Lab", "Random_Space_Geometry"], ["curl_noise_particles", "related_weather"],
     "Continue P4 with matched births and independent-kick versus frozen-field modes. Build Field Lab and define scalar-to-vector/receiver mappings. Correct curl labels to the sine-potential finite-difference implementation. Localize reference respawn draws and record boundary exits. Implement X3 and incompatibility handling. Scope any divergence/incompressibility claim numerically.",
     "Static queries repeat without draws; appearance edits do not move particles. Respawn differs from wrap. Phase/ticks/stochastic events replay. Matched comparisons expose each changed condition."),
    (13, "Write particle P6: boundaries, contact and composition", "build", [12],
     ["Particles_Collision"], ["example_4_6_particle_repeller_vr", "particle_campfire"],
     "Continue P5 with absorb/reflect/wrap on matched trajectories and a small pair-contact case before scaling. Separate repulsion from collision. Record hand input/event order. Offer campfire as a visual composition with physical omissions stated. Prepare X6 export using stable IDs.",
     "Reflection changes the specified component; wrapping retains identity; absorption retires once; contacts remain finite. Measure approximation gain/loss. Test budgets on named hardware, without combustion claims."),
    (14, "Connect measurement to preserved arrangements and trials", "build", [6],
     ["Random_Entropy", "Randomness_Examples_of_Randomness"], ["shannon_entropy_meter", "entropy_axiom", "monte_carlo_dartboard"],
     "Resolve the selected duplicate entropy_axiom registration before asserting the loaded scene. Retain equal-count/different-arrangement fixtures and the existing Monte Carlo sample-budget study. Add comparison records with explicit variable, log units, order/reference. Implement the entropy side of X5 with task .007.",
     "Rearrangement preserves counts while a declared neighbour measure changes. Rebinning spends no draws. Monte Carlo records trial count/error without requiring monotonic improvement. Selected registry resolution is unambiguous."),
    (15, "Follow a walk into feedback and retain the difference", "build", [12, 14],
     ["Random_Walk", "Random_Pheromone"], ["random_walk_terrarium", "random_position_rails", "pheromone_terrain"],
     "Preserve assignment versus accumulated step versus deposited-signal distinctions. Implement X4 and matched CUT/CONNECT comparisons. Feedback creates a branch rather than replaying the old trajectory. Brownian, bounded long-step and Markov extensions remain individually defined optional studies.",
     "The baseline trace has no influence when guidance is cut. Feedback acts only through the declared path. Replay includes history and update order. Record an observed difference or an inconclusive question."),
    (16, "Build the deterministic Sensitivity Lab", "build", [14, 15],
     ["Random_Sensitivity_Lab"], ["lyapunov_bench", "percolation_ca"],
     "Build one paired deterministic experiment with nearby starts, the same rule/fixed ticks, explicit precision/build and separation record. Keep Lyapunov landscape as companion. Percolation is a separate later connectivity study after preparation; thresholding alone is not criticality.",
     "Identical starts match under the reference. Epsilon changes only the stated initial condition. The deterministic run spends no new draws. A step-size comparison and bounded interval clarify numerical effects."),
    (17, "Extend selection into one recorded mutation experiment", "build", [16],
     ["PG_Genetic_Evolution", "Random_Mushrooms"], ["mushrooms"],
     "Keep the six-candidate target/ranking witness first. Add bounded mutation/offspring with parent IDs, retained genes and a selection/viability criterion. Permit visitor selection distinct from score. Preserve later-return prerequisites rather than moving all Procedural Generation forward.",
     "Evaluator changes do not mutate candidates. Mutation changes only declared fields and preserves parents. Selection/preference are distinct. The tutorial actually reconstructs offspring."),
    (18, "Build the shared Rule Workshop and particle P7", "build", [13, 17],
     ["Random_Rule_Workshop"], ["example_particle_body", "mushrooms", "textile_comparison"],
     "Use sixteen entities and the same inputs to compare old/new relation rules. Add one reversible detach/connect/sensor change, versions and rollback. Separate drawn links from force-bearing bonds. Use ParticleBody ideas without teaching its nearest-neighbour fallback as Delaunay. Implement X6 and P7. Defer the sleeve as a further investigation.",
     "A stated relation is impossible under the old fixture and possible under the new rule. Parent state survives, invalid links are handled, each rule replays, and independent reconstruction is separately recorded."),
    (19, "Return an experiment to QFEP and examine AI-assisted revision", "build", [18],
     ["QFEP_Sandbox", "QFEP_Synthesis", "Random_Definition"], [],
     "Reuse CONNECT/CUT and a declared receiver. Build only one accepted explore/retain/revise study with named variable, viability criterion, feedback path and limits. X7 returns a record/provenance, not arbitrary grammar execution in the seed bench. If selected, add offline versioned AI comparisons separating fixed-model samples, prompt revision and model revision; record assistance and visitor judgment.",
     "Offered/used values stay distinct; cut input is not stopped time. Evidence may end in a question without endorsing QFEP. No universal lambda or untested Markov blanket is claimed. X7 preserves lineage and explains incompatible execution."),
    (20, "Integrate route, final writing and three-level evidence", "verify", [4, 7, 14, 19],
     [], [],
     "Reconcile the accepted manifest with sequences, branches, map_authored and museum-plan derivation. Preserve Biome_Cage, account for Lab_Path and add particles only as accepted. Rewrite changed-neighbour prerequisites and prose handovers. Develop staged FINAL.md against actual tested encounters. Verify every named transfer and the complete cycle separately from runtime/performance/headset checks. Publish pass/fail/not-tested evidence.",
     "Accepted stops/transfers are reachable and preserve records. Moved texts agree with their context. Printed programs reconstruct. Missing physical headset/human learner evidence stays open; automation cannot relabel it passed."),
]


def absolute(relative):
    return (ROOT / relative).as_posix()


def main():
    route = {"schema": "ada.randomness-research.proposal.v1", "date": "2026-10-14",
             "status": "proposed", "runtime_installed": False,
             "accepted_verification": "Seven-step cycle and three verification levels; see DECISIONS.md",
             "movements": [{"id": i, "title": t, "maps": ms} for i,t,ms in MOVEMENTS],
             "core_order": [m for _,_,ms in MOVEMENTS for m in ms],
             "new_maps": NEW, "later_returns": ["PG_Genetic_Evolution", "QFEP_Sandbox"],
             "particle_order": PARTICLES, "side_visits": SIDES,
             "transfer_ids": [f"X{i}" for i in range(1,8)]}
    (HERE / "route.json").write_text(json.dumps(route, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
    issue = {
        "goal_id": GOAL, "goal_title": "Randomness as shared experiment: research route and particle path",
        "kind": "spec", "labels": ["ready-for-agent"],
        "label_meaning": "Specification is usable as planning input, not a work order for unreviewed runtime changes.",
        "why": "Develop Ada from explanations toward reconstructable experiments whose observations can change the apparatus, grounded in the author's supplied research map.",
        "specification": (HERE / "SPEC.md").as_posix(),
        "decision_record": (HERE / "DECISIONS.md").as_posix(),
        "implementation_authorization": "Proposed order/hosts require the decision in task .002; this request authorizes the specification and task plan.",
        "success_criteria": [
            "Accepted core/side encounters have explicit prerequisites",
            "Seven-step cycles include observation-led further questions or changes",
            "Particle lessons reconstruct from exact printed changes and declared incoming state",
            "All seven transfer contracts have scoped evidence",
            "Artifact, cycle, integration, runtime, headset and learner evidence stay distinct"],
        "prerequisites": [], "tasks": []}
    for n,title,skill,deps,maps,artifacts,brief,acceptance in WORK:
        output = HERE / "implementation" / f"{n:03}"
        refs = [absolute(f"commons/maps/{m}/map_data.json") for m in maps if m not in NEW]
        refs += [absolute("commons/artifacts/registry/randomness.json"),
                 absolute("commons/artifacts/registry/physics_simulation.json")]
        preamble = f"Work in {ROOT.as_posix()}. Read {HERE.as_posix()}/SPEC.md, HALLS.md, PARTICLE_PATH.md, FINDINGS.md and DECISIONS.md. "
        preamble += "Preserve unrelated working-tree changes. Read inventory.json for exact scene/script registrations and hashes; re-read changed evidence. "
        if n > 2:
            preamble += f"Task {GOAL}.002 must accept this scope before implementation. "
        if n == 1:
            verification = f"python -X utf8 '{HERE.as_posix()}/audit_inventory.py'"
            out = (HERE / "INVENTORY.md").as_posix()+"; "+(HERE / "FINDINGS.md").as_posix()
        elif n == 2:
            verification = f"python -X utf8 '{HERE.as_posix()}/validate_plan.py'"
            out = (HERE / "DECISIONS.md").as_posix()+"; "+(HERE / "route.json").as_posix()
        else:
            verification = f"& 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe' --headless --path '{ROOT.as_posix()}' --script 'res://{output.relative_to(ROOT).as_posix()}/probe.gd'"
            if maps and maps[0] not in NEW:
                verification += f"; python '{absolute('tools/map_pathfinder.py')}' check {maps[0]}"
            out = output.as_posix()+"/REPORT.md, probe.gd, exact reconstruction and evidence.json; accepted runtime/text edits named in the report"
        issue["tasks"].append({
            "id": f"{GOAL}.{n:03}", "title": title,
            "spec": preamble+brief+" Source references: "+"; ".join(refs)+". "
                    +f"Write Markdown and JSON evidence under {output.as_posix()}. "
                    +("Create the named native SceneTree probe as part of this task; its acceptance command is not a claim that it already exists." if n>2 else ""),
            "effort": "half-day" if n<3 else "multi-day", "skill": skill,
            "depends_on": [f"{GOAL}.{d:03}" for d in deps],
            "status": "done" if n==1 else ("open" if n==2 else "blocked"),
            "blocked_reason": None if n<3 else "Depends on route/scope decision and preceding evidence; implementation has not begun.",
            "claimed_by": None, "done_at": "2026-10-14" if n==1 else None,
            "map_refs": maps, "artifact_refs": artifacts,
            "sequence_refs": ["randomness", "noise", "particles"],
            "output": out, "verification": verification, "acceptance": acceptance,
            "verification_levels": ["artifact", "experiment_cycle", "specified_cross_hall"],
            "separate_evidence": ["scene_loading", "runtime_stability", "performance", "physical_VR", "independent_learner"]})
    target = ROOT / "doc/tasks" / f"{GOAL}.json"
    target.write_text(json.dumps(issue, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
    md = ["# Work to undertake", "",
          "Published in the existing local task tracker as randomness_research. The static baseline is complete. "
          "Concrete route review is open; implementation tasks depend on that decision and preceding evidence. "
          "No runtime task is marked complete. Effort fields are rough scale, not delivery promises.", "",
          "[Full task instructions and acceptance criteria](../../../tasks/randomness_research.json)", "",
          "| Task | Work | Depends on | Status |", "| --- | --- | --- | --- |"]
    for t in issue["tasks"]:
        md.append(f"| {t['id'].split('.')[-1]} | {t['title']} | {', '.join(d.split('.')[-1] for d in t['depends_on']) or '—'} | {t['status']} |")
    md += ["", "The visitor route is not the build queue. Complete the seed-bench cycle first, then carry its evidence into another hall. "
           "The particle chain grows through the exact saved learner states. Later rule/QFEP work depends on these capabilities, not simply on scene availability.", "",
           "Every implementation must preserve a meaningful, failed or inconclusive result, record the next question and declare replay scope. "
           "Final integration reviews the writing, the route and the three verification levels with separate runtime/headset/learner evidence."]
    (HERE / "TASKS.md").write_text("\n".join(md)+"\n", encoding="utf-8")
    print(f"Published {len(issue['tasks'])} tasks; {len(route['core_order'])} core stops; {len(PARTICLES)} particle stops.")


if __name__ == "__main__":
    main()
