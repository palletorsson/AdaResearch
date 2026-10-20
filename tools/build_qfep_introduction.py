"""Write the first QFEP tutorial on request; extract its actual printed files for tests.

No Godot runtime or map source is replaced. A blank Godot project is not the
declared starting point: the prepared museum supplies XRTools and push_button.
"""
from pathlib import Path
import argparse
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parents[1]
STUDY = ROOT / 'doc/book/studies/qfep-lineage'
OUT = ROOT / 'doc/book/iterations/2026-10-12-qfep-four-inputs'
HALL = ROOT / 'commons/maps/QFEP_Introduction'
CARRIED = {'point_body.gd': 'Euclid_Parallel', 'line_skin.gd': 'Euclid_Parallel', 'bench.gd': 'Russell_Paradox'}
NEW = ['balance.gd', 'introduction_study.gd', 'balance_checks.gd']

def extract(text, name):
    match = re.search(r'<!-- student-code:' + re.escape(name) + r' -->\s*```gdscript\n(.*?)```', text, re.S)
    if not match:
        raise ValueError(f'Missing complete printed file: {name}')
    return match.group(1)

def code(name):
    return f'<!-- student-code:{name} -->\n```gdscript\n{(STUDY/name).read_text(encoding="utf8")}```\n'

def tutorial():
    return '''# Four inputs, one result

**Learning elements**

- Weighted expressions
- Input arrays and scalar results
- Copies of retained state
- Local coordinates for a hand control
- Assertions and the limits of a model

You are in the QFEP Introduction hall of Endless Museum. First use its existing balance workbench: move a rail, press KEEP, and look for a different arrangement with the same total. We will reconstruct that comparison on our small bench with the sphere we already know. We keep four numbers separately even when their calculation returns just one.

## What arrives from earlier halls

Continue in the prepared Ada museum project. Carry `point_body.gd` and `line_skin.gd` unchanged from [Euclid](../Euclid_Parallel/tutorial.md#carried-files-complete), and `bench.gd` from [Russell](../Russell_Paradox/tutorial.md). Euclid already carries the point construction from Points; Russell initializes the table, sphere, drawing container, labels and buttons. We are extending their behaviour, not rebuilding their geometry.

Place those three files beside the three new files printed below in `res://doc/book/studies/qfep-lineage/`. This is one script folder, with relative preloads. The supplied dependencies are `XRToolsPickable` and `res://commons/interactables/push_button.tscn`, both already in the museum project. A blank Godot project does not include them. The inherited bench gives us `start`, `block`, `label`, `clear_drawing`, `point`, `point_home` and an initialized `readout`; none is an unexplained scene reference.

## Keep the inputs

Create `balance.gd`. The array order is F, E, lambda, phi. For this console each input is dimensionless and bounded to 0..1. `CHANGE` is supplied as 0.3. It is not an observed change or a rate. The calculation follows the installed workbench: F minus lambda times E, plus phi times the fixed change.

''' + code('balance.gd') + '''
`total` returns a number without changing its input. Multiplication makes lambda a weight: when it is zero, E contributes nothing to this total, even though E still has a value. `set_term` rejects a nonexistent slot or a nonfinite value and clamps a valid number to the rail's range. `keep` duplicates the array. Assigning `kept = values` would share the same array, so a later element edit could also rewrite the evidence you intended to retain. Numbers need only this shallow copy; nested mutable records would need more care.

There is no simulated organism behind these four inputs. QFEP is the project's research proposal, and this lesson makes its teaching expression inspectable. It does not compute variational free energy, measure entropy, detect a physical phase or decide what makes a life free. Those distinctions matter when we use the same letters in the following halls.

## Give the existing sphere a new job

Create `introduction_study.gd`. Attach it to a Node3D only through the supplied museum scene described below. There is one `_ready`: it calls the inherited bench constructor before using any label or point. TERM selects which input the sphere controls. Lift the sphere to increase that input; lower it to decrease it. The movement spans 0.48 metres, from local height 1.18 to 1.66 metres. Release before pressing a button.

''' + code('introduction_study.gd') + '''
`to_local(point.global_position)` returns the hand's position in the bench's frame. Subtracting LOW and dividing by TRAVEL maps that height to 0..1. The clamp bounds the value, not the physical freedom of your hand. The same calculation works if the bench is moved or rotated in the museum. Horizontal hand movement does not change this particular input.

`redraw` replaces the small bars and their labels. It never replaces `point`. The coloured bar shows the current value; a pale horizontal mark shows the kept value. `point_home` changes to the selected bar's current height. The inherited bench returns the released sphere there. The buttons deliberately refuse to change the selected term or preset while you are holding it, so one gesture cannot unexpectedly switch meanings.

The display prints three decimal places. Differences smaller than half its last displayed unit appear as zero, avoiding a distracting negative zero from floating-point arithmetic. The stored inputs and calculation remain unchanged. Display precision is a choice about what the readout can show, not a proof that two arbitrary arrangements are identical.

## Run in this museum

Open `res://doc/book/studies/qfep-lineage/introduction.tscn` and press F6. This supplied scene uses `introduction_museum.gd` to load QFEP Introduction with the existing museum player, lighting and exhibits, then mounts your `introduction_study.gd` on a small bench beside them. The adapter is included in the study folder; it is museum setup, not a missing part of the calculation. The normal hall and its original workbench remain available. The lesson's KEEP lasts for this run; it is not a disk save.

1. The opening is PAIR A: `[0.4, 0.2, 0.5, 0.5]`, total 0.45. Press KEEP.
2. Press PAIR B: `[0.6, 0.6, 0.5, 0.5]`, total 0.45 again. The pale marks should still show A. The larger F contribution exactly compensates for the more negative weighted E contribution.
3. Press ZERO L, then TERM until E is selected. Predict what lifting the sphere will do. E and its bar should change; the total should stay fixed. Select LAMBDA and lift it above zero; now E has an effect again.
4. Without PAIR A or B, make a third arrangement with total 0.45. KEEP it, change one input, and explain which retained value accounts for the difference. This is the transfer task: the two supplied presets are examples, not the only solutions.

## Test the calculation

Create `balance_checks.gd`. These assertions check the retained values as well as the convenient total. The final case supplies one possible third arrangement; attempt the task above before reading it.

''' + code('balance_checks.gd') + '''
Run the supplied `tools/test_qfep_introduction.py` with Python from the project root. It reconstructs these three files from this tutorial and the three inherited files from their earlier chapters, then runs Godot against that fresh extraction. Its separate input harness moves the actual inherited sphere under a transformed parent and checks the buttons, release position and initialized readout. A failed assertion or Godot script error fails the run. The harness is a synthetic ghost student, not evidence that a person has completed the task in a headset.

## Carry onward

Keep the model, the sphere and the habit of retaining inputs alongside a result. In F Term we will stop supplying an arbitrary F rail and ask a narrower question with observable outcomes: how often does a predictor get a fixed sample wrong? A count of mistakes, its expectation and entropy will need separate names and records.

**Short instruction:** Continue inherited PointBody + Russell Bench. Reconstruct installed weighted expression; inputs F,E,L,PHI in [0,1], fixed change .3. One sphere edits selected local-height rail. KEEP copies tuple. Test equal totals/different tuples, zero weight, independent third tuple. No measured free energy, phase or moral score. Carry separate inputs and result to prediction study.
'''

def prepare(write=False):
    OUT.mkdir(parents=True, exist_ok=True)
    STUDY.mkdir(parents=True, exist_ok=True)
    for name, hall in CARRIED.items():
        source = ROOT / 'commons/maps' / hall / 'tutorial.md'
        (STUDY/name).write_text(extract(source.read_text(encoding='utf8'), name), encoding='utf8')
    if write:
        before = OUT / 'before'
        before.mkdir(exist_ok=True)
        for name in ['tutorial.md', 'final.md']:
            if not (before/name).exists():
                (before/name).write_bytes((HALL/name).read_bytes())
        (HALL/'tutorial.md').write_text(tutorial(), encoding='utf8')
    learner = OUT / 'learner'
    learner.mkdir(exist_ok=True)
    manifest = {'scope': 'Fresh extraction from canonical printed lessons; current museum dependencies supplied.', 'files': {}}
    for name in list(CARRIED) + NEW:
        source = ROOT/'commons/maps'/CARRIED[name]/'tutorial.md' if name in CARRIED else HALL/'tutorial.md'
        content = extract(source.read_text(encoding='utf8'), name)
        if content != (STUDY/name).read_text(encoding='utf8'):
            raise ValueError(f'Printed code differs from working file: {name}')
        (learner/name).write_text(content, encoding='utf8')
        manifest['files'][name] = {'source': source.relative_to(ROOT).as_posix(), 'sha256': hashlib.sha256(content.encode()).hexdigest(), 'carried': name in CARRIED}
    (OUT/'extraction.json').write_text(json.dumps(manifest, indent=2), encoding='utf8')
    return learner

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write-tutorial', action='store_true')
    args = parser.parse_args()
    print(prepare(args.write_tutorial))
