"""Print and freshly reconstruct the Edge hall's equal-time experiment."""
import argparse
import hashlib
import json
from build_qfep_introduction import ROOT, STUDY, CARRIED, extract, code

OUT = ROOT/'doc/book/iterations/2026-10-12-qfep-same-time-different-steps'
HALL = ROOT/'commons/maps/QFEP_Edge_Of_Chaos'
NEW = ['timed_field.gd','step_comparison.gd','edge_study.gd','step_checks.gd']

def tutorial():
    return '''# Same start, different steps

**Learning elements**

- Old state and next state, with an explicit timestep
- A local reaction and exchange with neighbours
- Equal model time at different step counts
- Repeatable seeds and controlled comparisons
- Field differences measured separately from their palette

We are inside Endless Museum's Edge of Chaos hall. Find the paired screens labelled SAME START / SAME TIME. They begin with the same concentrations and use the same coefficients. The right-hand calculation takes two smaller steps for each step on the left. This is a question we can investigate: which features survive a change in how we calculate the evolution?

Phi distinguished a difference from its rate and interval. Here the interval enters the update itself. We carry the sphere and bench, then bring back the retained field from Shaders and neighbour exchange from Cellular Automata. Our miniature advances only when you press +6 TIME. That keeps each comparison still long enough to inspect.

## What we carry, and what changes

Continue in `res://doc/book/studies/qfep-lineage/` in the prepared Ada project. Keep `point_body.gd`, `line_skin.gd` and `bench.gd` unchanged; their full printed sources remain [Euclid](../Euclid_Parallel/tutorial.md#carried-files-complete) and [Russell](../Russell_Paradox/tutorial.md). Bench initializes the labels, drawing node, familiar sphere and the supplied `res://commons/interactables/push_button.tscn`. The museum supplies the player and XRTools.

[A field kept](../Shader_10_ReactionDiffusion/tutorial.md) introduced previous-state textures. [What a neighbour offers](../CA_SoftRules/tutorial.md) made that operation explicit in CPU arrays. Keep those studies. This chapter adapts the latter's `index`, `laplacian`, reset and old-to-new update pattern into a new `timed_field.gd`, matching the current QFEP exhibit. A/B here are the same roles previously called U/V; these names are not the left and right screens.

Three differences matter. The neighbour operator is now their **average minus the centre**, one quarter of the earlier sum-minus-four-centres operator. The coefficients follow this hall's authored lambda path. Finally, the update has an explicit dt and does not clip concentrations to the palette's range. These changes define this model; they are not merely a more precise rendering of the old CA field. Both sides of our new comparison use exactly the same definition.

Our field has 32 × 32 addresses. The installed screens use 64 × 64. Compare the two sides within either experiment; matching seed numbers across different grid sizes does not make the initial arrays or physical domain identical. The boundary wraps to the opposite side as before. The lesson's field and the exhibit's field are separate records.

## Make one complete update

Create `timed_field.gd`:

''' + code('timed_field.gd') + '''
`reset` uses a numbered random generator to place twelve small patches in the centre region. A starts at one and B at zero; a seeded patch has A = 0.5 and B = 1. Overlapping patches overwrite the same values. RESTART can therefore reproduce an entire beginning. Changing the seed changes that beginning without changing the rule.

`index` wraps coordinates. At x = 0, the left neighbour is x = 31. `laplacian` returns zero for a uniform field and otherwise returns the four neighbours' mean minus the centre. Diffusion uses that difference to exchange concentration. The supplied Gray–Scott reaction consumes A and produces B through A×B×B. Feed replenishes A; feed plus removal reduces B.[^model]

Lambda is a route through four numbers: feed 0.01–0.08, removal 0.08–0.03, diffusion A 0.8–1.2 and diffusion B 0.3–0.7. It is an authored convenience, not an entropy measurement or the location of a universal “edge”. Moving it changes four coefficients together. To isolate just feed would require a different control and comparison.

For each cell, `step` calculates **old value + change rate × dt**. This is a forward Euler update. Every rate reads the unchanged old arrays. Only after all cells have valid results do the new arrays become the present. Updating in place would instead make the scan order part of the operation. Like our earlier CA example, this small class allocates fresh next arrays for clarity; the installed artifact reuses spare buffers.

At lambda 0.4, feed is 0.038 and removal is 0.060. In a uniform patch with A = 0.5 and B = 1, diffusion contributes zero. A dt of 0.3 gives A = 0.3557 and B = 1.1206 after one step. B exceeding one is possible here. The model retains it. The palette will saturate separately; clipping the stored B would change the next reaction.

The allowed dt range is a bound chosen for this study, not a proof that every possible concentration remains valid. A negative or non-finite answer stops the run and records a fault. No partially calculated next field is published. Do not repair such a fault by silently clipping values. Restart, then inspect the start, coefficients and timestep.

## Keep the comparison fair

Create `step_comparison.gd`:

''' + code('step_comparison.gd') + '''
`coarse` and `fine` are separate instances. Both receive the same numbered seed and lambda. One coarse step of dt = 0.3 is paired with two fine steps of dt = 0.15. The fine calculation evaluates the reaction and neighbours again at the intermediate state. Consequently, two half steps need not equal one full step.

The advance loop requests six model-time units. With the first pair that means 20 coarse steps and 40 fine steps. DT / 2 selects 0.15 and 0.075 and restarts the same seed: now six units need 40 and 80 steps. Model time is ticks × dt. It is not visitor time, and these six units are not a promise that the operation takes six seconds.

`difference` calculates the root mean square of corresponding B differences. Subtract each pair, square, average, then take the square root. Zero means that these B arrays agree. A small nonzero number summarizes disagreement in this observable; it does not measure entropy or assign artistic value. A local feature can matter to you without dominating a whole-field average.

KEEP records the settings, both step counts and times, RMS, and copied B arrays. Those arrays need `duplicate`: unlike Phi's scalar record, these fields are mutable collections. Restart and later evolution preserve the kept evidence. This record lasts for the current run, not across closing the project. It keeps the compared B fields, not a resumable A/B checkpoint or a history of lambda edits. Seed, fixed setting and duration can reconstruct a fixed-setting run; if you intervene midway, record when and how the setting changed as well.

Changing lambda does not reset or advance either field. The new coefficients will apply to the next update. That permits an intervention in an existing history. For a comparison between fixed settings, change lambda and then RESTART. For a timestep comparison, DT / 2 already restarts both copies. If a solver faults, stop comparing its images as if their times still agreed; the display shows the individual clocks and a fault until restart.

## Return the arrays to a surface

Create `edge_study.gd`:

''' + code('edge_study.gd') + '''
The same sphere now edits lambda using bench-local height. It never advances the fields. The five nearby buttons advance time, replay the current seed, select another seed, change the timestep pair, or keep a record. They wait for release so the held point cannot compete with a button action.

Each screen gets its own texture and material. A QuadMesh maps the whole image onto one front-facing surface; the default box atlas would show only part of it on each face. `redraw` paints B into RGB pixels and updates the existing textures. `tint` clamps only the colour lookup, leaving the arrays untouched. The screens and sphere are constructed once; changes to the field do not recreate them. The printed readout is initialized in `_ready`, after the screens exist.

The installed exhibit also has SIM SPEED and HOLD / RUN. SIM SPEED requests more or fewer model-time units per visitor second, with bounded work per frame. It does not select a finer dt. Our miniature leaves out automatic scheduling so the timestep experiment can be carried out with explicit batches. Both versions report the time actually calculated.

## Build and investigate

Open `res://doc/book/studies/qfep-lineage/edge.tscn` and press F6. Its supplied `edge_museum.gd` adapter loads the existing hall and adds this learner bench in a checked location. The ordinary hall retains its installed work and controls.

1. Read both clocks at zero. The seeded fields agree and RMS is zero. Press +6 TIME once. Predict the counters before reading them: 20 and 40, both at time 6. Neither side should have advanced farther simply because it took more steps.
2. Continue to time 60 with ten presses in total. Choose a boundary or small island in the image. Describe its location and shape, then press KEEP. Write down the RMS as well; the number and your description answer different questions.
3. Press DT / 2. Both fields return to the same beginning; KEEP remains. Take ten more batches to reach time 60 again. The counters should now be 400 and 800. Compare the RMS values and the chosen feature. For the published seed at lambda 0.4 our test checks that this refinement reduces B disagreement. Repeat with your own setting; do not assume that one successful comparison proves convergence everywhere.
4. Choose lambda 0.7 with the point. Check that the fields and clocks have not changed yet. Press RESTART, then repeat the time-60 experiment. State which four coefficients moved. Use NEW SEED as a separate comparison, not halfway through the one you meant to repeat.
5. Independent task: at the finer pair, reach time 18 from a restart. Predict 120 coarse and 240 fine steps. Explain why comparing 120 steps on each side would answer a different question. Try the same experiment from another seed while retaining your first evidence.
6. Return to the installed paired screens. Try HOLD / RUN, SIM SPEED and DT .3 / .15 separately. Identify which changes the visitor's waiting time, which changes numerical resolution, and which restarts the data. The separate lambda rail near the door is not a receiver connection to this solver.

No ants are spawned by crossing a preferred band in this lesson. No creature disappears because your setting was “outside the edge”. The visible pattern is the outcome of the declared field update. Give a feature time to become evidence before naming the whole field ordered or chaotic.

## Test what the text asks you to build

Create `step_checks.gd`:

''' + code('step_checks.gd') + '''
Run `python tools/test_qfep_edge.py` from the project root. The supplied harness extracts these four new files and the three unchanged carried files from their printed sources. It runs the assertions and synthetic point/button interactions, including the independent time-18 task. It also compares a 32 × 32 instance of the installed solver with this reconstruction from the same seed and coefficients. That is a matched numerical check, not a comparison between differently sized screenshots.

A separate rendered run loads the existing museum, exercises its real console signals and mounts the extracted learner code. Tests check time accounting, restart, seed changes, state retention, palette separation and the local hand mapping. They do not establish headset comfort, independent learner understanding, physical chemistry or universal criticality.

## Carry onward

Retain enough of an experiment to repeat it: seed, model definition, parameters, timestep and duration. The next hall, Sandbox, asks whether a parameter reaches its intended receiver at all. Similar labels on two objects do not make a connection between them.

**Short instruction:** Carry PointBody + Bench + LineSkin. Adapt CA field to periodic mean-minus-centre exchange, explicit Euler dt, unclipped Float32 concentrations; match current installed solver, not old clipped trajectory. Same seed/coefficients; one coarse step, two half steps; +6 model time at either pair. Sphere edits coupled lambda only. Restart for fixed-setting comparison; DT restarts; KEEP copies fields/settings/times. Assert cell arithmetic, synchronous update, wrap, no hidden clipping, equal clocks, restart, measured refinement, held-point mapping and installed-solver agreement. No universal optimum. Next: explicit sender/receiver connections.

[^model]: John E. Pearson, [“Complex Patterns in a Simple System”](https://arxiv.org/abs/patt-sol/9304003), *Science* 261 (1993), 189–192. This lesson supplies its own discrete grid, seeded start and parameter route; it is not a reproduction of Pearson's experiments.
'''


def prepare(write=False):
    OUT.mkdir(parents=True,exist_ok=True)
    for name,hall in CARRIED.items():
        content=extract((ROOT/'commons/maps'/hall/'tutorial.md').read_text(encoding='utf8'),name)
        assert (STUDY/name).read_text(encoding='utf8')==content,name
    if write:
        before=OUT/'before';before.mkdir(exist_ok=True)
        for name in ['tutorial.md','final.md']:
            if not (before/name).exists():(before/name).write_bytes((HALL/name).read_bytes())
        (HALL/'tutorial.md').write_text(tutorial(),encoding='utf8')
        baseline=OUT/'preserved-sources.json'
        if not baseline.exists():
            paths=[HALL/'map_data.json',ROOT/'commons/maps/sequences/qfeplaboratory.json',ROOT/'commons/artifacts/edge_of_chaos_unlocked/edge_of_chaos_unlocked.gd']
            baseline.write_text(json.dumps({p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in paths},indent=2),encoding='utf8')
    learner=OUT/'learner';learner.mkdir(exist_ok=True)
    manifest={'scope':'Fresh printed Edge lesson and three declared inherited files. Hashes use UTF-8 with LF newlines.','files':{}}
    for name in list(CARRIED)+NEW:
        source=ROOT/'commons/maps'/CARRIED[name]/'tutorial.md' if name in CARRIED else HALL/'tutorial.md'
        text=extract(source.read_text(encoding='utf8'),name)
        assert text==(STUDY/name).read_text(encoding='utf8'),name
        (learner/name).write_text(text,encoding='utf8')
        manifest['files'][name]={'source':source.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(text.encode()).hexdigest(),'carried':name in CARRIED}
    (OUT/'extraction.json').write_text(json.dumps(manifest,indent=2),encoding='utf8')
    return learner

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write-tutorial',action='store_true')
    print(prepare(parser.parse_args().write_tutorial))
