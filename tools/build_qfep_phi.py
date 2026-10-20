"""Print and reconstruct Phi's signed difference, interval and weighting lesson."""
import argparse
import hashlib
import json
from build_qfep_introduction import ROOT, STUDY, CARRIED, extract, code

OUT = ROOT/'doc/book/iterations/2026-10-12-qfep-change-has-a-sign'
HALL = ROOT/'commons/maps/QFEP_Phi_Term'
NEW = ['signed_change.gd','phi_study.gd','change_checks.gd']

def tutorial():
    return '''# Give a difference a weight

**Learning elements**

- Earlier and later readings
- Signed difference and magnitude
- Elapsed interval and average rate
- Multiplication by a signed weight
- Keeping evidence separate from its label

We are inside Endless Museum's Phi Term hall. Move the installed PHI rail to equal distances on either side of zero. The particles change direction and colour. At equal magnitudes, their configured speed is equal; neither sign is given stronger motion. At zero, new emission stops. Particles already emitted can remain for their two-second lifetime. Meanwhile, the nearby transforming pattern continues its own waves.

Lambda separated a weight from a recommendation. Now we separate three more quantities: a difference between readings, the interval between them, and a weight applied to that difference. Continue with our sphere and bench. We will make the arithmetic visible without pretending the sphere controls every changing object in the room.

## What we carry

Work in `res://doc/book/studies/qfep-lineage/` in the prepared Ada project. Keep `point_body.gd`, `line_skin.gd` and `bench.gd` unchanged from the preceding halls. Their complete printed sources are [Euclid](../Euclid_Parallel/tutorial.md#carried-files-complete) and [Russell](../Russell_Paradox/tutorial.md). The point still provides pickup and release. Bench still initializes the table, labels, drawing node and supplied `res://commons/interactables/push_button.tscn` buttons. XRTools remains a project dependency.

From [Introduction](../QFEP_Introduction/tutorial.md) we keep the expression F − lambda×E + phi×Delta E. Its earlier console supplied a fixed Delta E = 0.3. Leave that console intact. This new small model studies only the last contribution and replaces the fixed change with two explicit readings. The lesson does not run Introduction's full score or reuse its 0..1-only setter for phi: this hall needs a signed weight from −1 to +1.

The pair begins at 0.20 and 0.70, with an authored interval of two seconds. These are supplied dimensionless values, chosen for comparison. They are not measurements of the nearby pattern, and they are not E Term's entropy ln(N). Computing entropy would still require a stated outcome set, probabilities and units. Restricting these exercise readings to 0..1 is a display contract, not a claim that entropy always has that range.

## Record the difference before interpreting it

Create `signed_change.gd`:

''' + code('signed_change.gd') + '''
`later - earlier` gives a signed difference: 0.70 − 0.20 = +0.50. Dividing by the positive interval gives the average rate: +0.50 / 2 seconds = +0.25 per second. The rate says nothing about the detailed path between the observations. The value could have risen, fallen, and returned between them.

Our contribution is `phi * difference`, not `phi * rate`. At phi = +1 it is +0.50; at phi = −1 it is −0.50. If the other terms of an objective stayed fixed and we minimized that objective, the positive contribution would raise its cost. The sign alone cannot mean that the system rewards, welcomes or resists change. We would have to state what is being optimized and how the weight reaches a receiver.

`set_pair` validates both values before assigning either. An invalid pair cannot partly overwrite the old one. `set_interval` rejects zero, negative and non-finite intervals; it does not hide an invalid observation behind a tiny denominator. `set_phi` rejects non-finite input, then clamps the allowed range.

`reverse_pair` constructs the opposite comparison, 0.70 then 0.20, keeping time forward and the interval positive. It does not rewind an event in the world. `reading` returns a new dictionary containing the evidence, weight and results. KEEP retains that dictionary. Because all its entries are scalar values, later edits cannot mutate the retained record through nested references. It lasts for this run, as in our preceding benches.

## Give the carried point one job

Create `phi_study.gd`:

''' + code('phi_study.gd') + '''
The sphere controls only phi. Its vertical travel is 0.48 metres in the bench's local frame. `to_local` lets the same script work when the bench moves or turns. The bottom maps to −1, the midpoint to zero, and the top to +1. On release, the inherited bench rests the same sphere at the corresponding height. No new pickup implementation is needed.

The two cyan columns show the supplied earlier and later readings. The pink bar grows above or below a horizontal zero marker according to their weighted difference. This is deliberately a different display from the installed rail's particles: a negative weight multiplied by a negative difference produces a positive contribution. Showing only the weight's direction would hide that relationship.

The five buttons operate after release:

- **REVERSE** swaps the supplied values, making the other comparison.
- **2s / 4s** changes the declared observation interval. The readings and difference stay fixed; the average rate changes. No actual timer is being slowed.
- **KEEP** retains readings, interval, phi, difference, rate and contribution.
- **ZERO PHI** suppresses the contribution without erasing the readings or their difference.
- **LABELS** shows or hides the older words RESIST and EMBRACE. It changes text only.

`redraw` rebuilds these few diagram meshes and labels, not the carried sphere, model or museum. Geometry is a view of the record; the record survives drawing again. The helper `signed` removes negative zero only at the displayed precision. It never rounds the stored values.

## Build and investigate in the museum

Open `res://doc/book/studies/qfep-lineage/phi.tscn` and press F6. The supplied `phi_museum.gd` adapter loads the existing hall and adds this learner bench in its checked bay. The scene and adapter are included alongside the lesson; the museum supplies the player, room and lighting. This working copy is not installed permanently in the normal map.

1. With the opening pair, lift the sphere to the top and release. Predict change +0.500, rate +0.250 per second and contribution +0.500. Press KEEP.
2. Move the sphere to the bottom. The two cyan columns should stay still, while the contribution goes below zero. Press LABELS. The same numbers acquire different words; the calculation does not change.
3. Press 2s / 4s. The difference remains +0.500 and its contribution remains −0.500. The average rate halves to +0.125 per second. KEEP still describes the original two-second comparison.
4. Press REVERSE. With phi still −1, the difference becomes −0.500 and the contribution becomes +0.500. Explain why the negative weight now produces a positive result. Press ZERO PHI: the contribution disappears, but the readings still differ.
5. Make your own test: set the initial pair in `signed_change.gd` to 0.10 and 0.90. Put the sphere three-quarters of the way up, giving phi = +0.5. Predict contribution +0.400. Change the interval to four seconds and predict the average rate separately. Reversing this pair should change both signs without changing their magnitudes. Restore the published defaults before running the supplied checks, which declare those defaults as fixtures.
6. Return to the installed rail. Compare phi = −0.5 and +0.5, then zero. Its particles show the weight, not our product. Use EARLIER LABELS / HIDE and watch the nearby pattern: it should continue its independent animation. The learner bench sends no values to that pattern or to the rail.

Equal endpoint readings would give zero difference and zero average rate. They would not establish that nothing happened between observations. Likewise phi = zero gives a zero contribution even when the readings differ. This distinction follows Trace's lesson: a retained record can answer only the questions for which it kept evidence.

## Assert the distinctions

Create `change_checks.gd`:

''' + code('change_checks.gd') + '''
Run `python tools/test_qfep_phi.py` from the project root. The supplied harness freshly extracts these three printed files and the three declared inherited files. Godot executes the assertions, then synthetic pickup, point movement and button signals under a translated and rotated parent. A separate rendered museum check compares the installed rail's signs, speeds, zero emission and labels, and verifies that the nearby pattern keeps its state across control events and continues afterward. Assertion failures and engine errors fail the run.

This is a reconstruction check, not evidence of independent student understanding or headset comfort. It establishes what the printed code actually does and which relationships it leaves unconnected.

## Carry onward

Keep the earlier reading, later reading and interval together. Keep the weight separate from those observations. In Edge of Chaos we will need this discipline when comparing evolving patterns: a different number of updates is not automatically a fair comparison over time.

**Short instruction:** Carry PointBody + LineSkin + Bench unchanged. New authored pair .2→.7, interval 2s, signed phi −1..1. Same sphere edits phi locally. Compute difference, average rate, weighted difference separately. REVERSE swaps values; INTERVAL changes rate only; ZERO PHI keeps difference; KEEP copies scalar record; LABELS text only. Print all new code and assert boundaries, sign products, independent controls, same point. Existing rail/pattern remain independent. No entropy measurement, moral sign or global coupling. Next: numerical evolution over equal time.
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
            paths=[HALL/'map_data.json',ROOT/'commons/maps/sequences/qfeplaboratory.json',ROOT/'commons/interfaces/qfep/phi_slider.gd',ROOT/'commons/interfaces/qfep/transforming_pattern.gd']
            baseline.write_text(json.dumps({p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in paths},indent=2),encoding='utf8')
    learner=OUT/'learner';learner.mkdir(exist_ok=True)
    manifest={'scope':'Fresh printed Phi lesson and three declared inherited files. Hashes use UTF-8 with LF newlines.','files':{}}
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
