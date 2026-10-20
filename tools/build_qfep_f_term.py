"""Reconstruct F Term from its printed tutorial and declared inherited files."""
import argparse
import hashlib
import json
from build_qfep_introduction import ROOT, STUDY, CARRIED, extract, code

OUT = ROOT/'doc/book/iterations/2026-10-12-qfep-change-the-guess'
HALL = ROOT/'commons/maps/QFEP_F_Term'
NEW = ['prediction.gd','f_term_study.gd','prediction_checks.gd']

def tutorial():
    return '''# Change the guess; keep the grid

**Learning elements**

- Seeded samples and probability thresholds
- Constant predictors
- Counting observed mistakes
- Expected error and binary source entropy
- Holding the evidence fixed during a comparison

We are in the F Term hall of Endless Museum. Introduction kept the inputs behind a total. Here we keep the evidence behind a prediction. Start at the existing Shannon workbench: leave p near 0.9, press EXPECT 0, then EXPECT 1. The amber mistake marks change while the bits stay put. Our working copy reconstructs that experiment with the same sphere and bench, and a smaller 8-by-8 sample that we can inspect cell by cell.

## What we carry

Continue in `res://doc/book/studies/qfep-lineage/`, inside the prepared Ada project. Keep `point_body.gd`, `line_skin.gd` and `bench.gd` unchanged from [Introduction](../QFEP_Introduction/tutorial.md). Their printed sources remain [Euclid](../Euclid_Parallel/tutorial.md#carried-files-complete) and [Russell](../Russell_Paradox/tutorial.md). The sphere, initialized labels, button scene and local hand-height mapping are already familiar. We add a prediction model rather than modifying the previous four-input calculation.

Randomness gave us seeded draws; Arrays gave us indices and loops; Introduction gave us a retained reading. Each returns here for a specific comparison. There is no new point class. XRTools and `res://commons/interactables/push_button.tscn` remain supplied museum dependencies.

## Store a source, then choose a guess

Create `prediction.gd`. The seed produces 64 stored numbers once. A probability p turns each number into a bit. Moving p changes the threshold applied to those same numbers; it does not ask the generator for another sample. This lets you revisit a setting and recover its grid in this run.

''' + code('prediction.gd') + '''
`bits()` returns a fresh array: 1 when the stored draw is below p, otherwise 0. The explicit p = 1 case makes that certain source all ones even if a generator supplies the endpoint 1.0. At p = 0 every bit is zero. Intermediate values describe a probability, not a promise that a finite grid contains exactly p times 64 ones.

`prediction` is one constant guess, either 0 or 1, used for every cell. `reading()` counts its mismatches with the current bits. **Expected error** is different: under the source model, guessing 0 is wrong with probability p, while guessing 1 is wrong with probability 1−p. A predicted error rate of 10% does not require this particular sample to have exactly 6.4 mistakes; a count is an integer.

`entropy()` computes H(p) = −p log₂ p − (1−p) log₂(1−p), in bits per symbol. Godot's `log` is the natural logarithm, so dividing by `log(2.0)` converts to base two. The endpoint branch avoids taking log(0). H is zero for a certain source and one at p = 0.5. It is calculated from the chosen p, not estimated by counting the displayed grid, and it does not depend on our chosen predictor.

These are three different readings: source entropy, expected error for a particular guess, and observed mistakes in a finite sample. **None is named F in this code.** We are making a bounded prediction experiment in the F hall, not calculating variational free energy or proving that a predictable world is lifeless.

`keep()` stores a fresh reading and a fresh bit array. Later source or predictor edits do not overwrite them. This continues Introduction's habit of retaining what a score refers to. KEEP lasts for this run; it is not a disk save.

## Let the sphere control p

Create `f_term_study.gd`. The inherited `start` initializes the labels and sphere before we use them. The grid's boxes and amber marks are made once. Later changes recolour the boxes and show or hide the existing marks; we do not recreate geometry every time the hand moves.

''' + code('f_term_study.gd') + '''
Each flat tile is one observed bit: dark for 0, cyan for 1. An amber strip means that the bit differs from the selected guess. `% 8` finds a cell's column; integer division by 8 finds its row. The fixed grid uses 64 cells; the installed workbench normally uses 256. Comparing their mistake counts requires stating those different sample sizes.

Lift the familiar sphere to change p. As before, `to_local` places the hand in the bench's frame, and the 0.48-metre travel maps to 0..1. The P .1 and P .9 buttons make an exact paired comparison easy. Release the sphere before using a button, so a preset cannot compete with the held hand's position.

`expect` changes only the guess. Neither it nor KEEP regenerates `draws` or changes p. The number of visible amber marks must always equal `reading().mistakes`. When you switch guesses, every binary cell changes from right to wrong or wrong to right, so the two mistake counts add to 64. That is a useful invariant to test independently of the selected seed.

## Build and investigate in the hall

Open `res://doc/book/studies/qfep-lineage/f_term.tscn` and press F6. The supplied `f_term_museum.gd` adapter loads the existing F Term hall, with its player, lighting and original workbench, then mounts this learner copy in a checked bay. The adapter and scene are included beside your scripts. This lesson runs in that prepared museum project, not an empty project without its XRTools and button dependencies.

1. Press P .1 and EXPECT 0. Before reading the marks, predict whether few or many cells will disagree. Press KEEP.
2. Press P .9, keeping EXPECT 0. H should match the kept H, but expected error rises from 10% to 90%. Count some of the new amber marks. Similar entropy has not made these sources equally easy for this particular guess.
3. Leave p at .9 and press EXPECT 1. The bit colours must stay fixed while the amber marks reverse. The expected error falls to 10%. The observed count need not equal exactly 10% of 64.
4. Use the sphere to choose another probability, away from the two presets. Predict which constant guess should have fewer expected mistakes, then try both. Verify that their observed counts add to 64. Explain any difference between the expected rate and this finite count. At p = .5 their expected rates tie, even if their observed counts do not.

This is a chosen predictor. There is no training algorithm here. Choosing the better of two guesses on this sample is also not an independent test of performance on future samples. The object of the lesson is to change the expectation while holding the current evidence still.

## Assertions against the printed model

Create `prediction_checks.gd`. The four-draw fixture deliberately gives one mistake out of four at p = .1: its observed 25% is different from its expected 10%. This deterministic case tests the distinction without relying on a lucky random discrepancy.

''' + code('prediction_checks.gd') + '''
From the project root, run `python tools/test_qfep_f_term.py`. The supplied harness extracts these three printed files and the same three inherited files, then runs Godot assertions and synthetic hand/button interactions. It checks visible marks against counted mistakes, unchanged bit colours when a guess changes, retained evidence, bounds, replay and the same sphere's identity. A script error or failed assertion fails the run. These checks do not establish headset comfort or an independent student's understanding.

## Carry onward

Keep the distinction between a source, a prediction and a particular observation. The next hall, E Term, changes the question: what alternatives did we allow into the model in the first place? Its branching fan counts endings. Entropy over those endings needs a stated probability assumption before the count can become an entropy value.

**Short instruction:** Carry PointBody + Russell Bench; seeded draws once, p thresholds same draws. One sphere edits p. Guess 0/1 changes marks only. Keep p, guess, H, expected error, observed count and bits distinct. Assert entropy symmetry, fixed evidence, complementary mistake counts, finite-sample mismatch. No F calculation or learned predictor. Carry explicit outcomes to E Term.
'''

def prepare(write=False):
    OUT.mkdir(parents=True,exist_ok=True)
    for name,hall in CARRIED.items():
        source=ROOT/'commons/maps'/hall/'tutorial.md'
        content=extract(source.read_text(encoding='utf8'),name)
        assert (STUDY/name).read_text(encoding='utf8')==content, 'Review changed inherited file: '+name
    if write:
        before=OUT/'before';before.mkdir(exist_ok=True)
        for name in ['tutorial.md','final.md']:
            if not (before/name).exists():(before/name).write_bytes((HALL/name).read_bytes())
        (HALL/'tutorial.md').write_text(tutorial(),encoding='utf8')
        baseline=OUT/'preserved-sources.json'
        if not baseline.exists():
            paths=[HALL/'map_data.json',ROOT/'commons/maps/sequences/qfeplaboratory.json',ROOT/'commons/artifacts/shannon_workbench/shannon_workbench.gd']
            baseline.write_text(json.dumps({p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in paths},indent=2),encoding='utf8')
    learner=OUT/'learner';learner.mkdir(exist_ok=True)
    manifest={'scope':'Fresh printed F Term lesson and declared inherited museum files. Hashes use UTF-8 with LF newlines.','files':{}}
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
    args=parser.parse_args()
    print(prepare(args.write_tutorial))
