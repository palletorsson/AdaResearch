"""Print and freshly reconstruct Lambda's two independent parameter mappings."""
import argparse
import hashlib
import json
from build_qfep_introduction import ROOT, STUDY, CARRIED as BASE_CARRIED, extract, code

OUT = ROOT/'doc/book/iterations/2026-10-12-qfep-move-the-recommendation'
HALL = ROOT/'commons/maps/QFEP_Lambda_Spectrum'
CARRIED = dict(BASE_CARRIED, **{'balance.gd':'QFEP_Introduction'})
NEW = ['recommendation.gd','lambda_study.gd','recommendation_checks.gd']

def tutorial():
    return '''# Move the recommendation; keep the surroundings

**Learning elements**

- Independent parameters and their effects
- Weighting a term without changing its input
- Mapping a scalar to a local position
- Keeping geometry fixed during a comparison
- Retaining and restoring a recommendation

We are inside Endless Museum's Lambda Spectrum hall. Walk through the installed contrast between repeated and dispersed forms. Then use LIT STRIP at its entrance. The bright strip moves; the cube rows keep their arrangement. RETURN restores the original recommendation. This is our next problem after E Term: available alternatives and the preference expressed about them are different things.

We will reconstruct the separation on our small bench. One control changes lambda in Introduction's calculation. Another moves a recommendation over an unchanged field of cubes. They use the same familiar sphere, but each writes to its own variable. Moving the light does not calculate the best route or reshape the field.

## What we carry

Continue in `res://doc/book/studies/qfep-lineage/` in the prepared Ada project. Keep `point_body.gd`, `line_skin.gd` and `bench.gd` from [E Term](../QFEP_E_Term/tutorial.md). Their printed sources remain [Euclid](../Euclid_Parallel/tutorial.md#carried-files-complete) and [Russell](../Russell_Paradox/tutorial.md). Also reuse the complete `balance.gd` printed in [QFEP Introduction](../QFEP_Introduction/tutorial.md). Its input order is F, E, lambda, phi; `total` returns F − lambda×E + phi×0.3. We do not rewrite that calculation.

The initialized bench, labels, pickup/release sphere, XRTools and `res://commons/interactables/push_button.tscn` keep their earlier roles. Transformation returns as a local position edit; Arrays returns as a fixed collection of cubes; Randomness supplies a seed used only during construction.

E Term's outcome set is not silently inserted into this calculation. The carried console still starts with its supplied dimensionless values [0.4, 0.2, 0.5, 0.5]. Its E = 0.2 is not ln(81), a new measurement from the hall, or an estimate of the cubes' entropy. E Term taught us to state what a number describes; that distinction travels even when the earlier path data is not needed by this exercise.

## Name two controls

Create `recommendation.gd`. `calculation` holds Introduction's model. `route` holds a separate recommendation between 0.20 and 0.80, matching the installed rail's bounds. The default route is 0.35; the carried calculation starts with lambda = 0.5. Different initial numbers help us see that they are not aliases.

''' + code('recommendation.gd') + '''
`set_weight` edits only index 2 in the carried model. With E fixed at 0.2, increasing lambda from 0 to 1 changes −lambda×E from 0 to −0.2. F = 0.4 and phi×0.3 = 0.15 stay fixed, so the total falls from 0.55 to 0.35. At lambda = 0, E is still stored. Its weighted contribution has vanished; its value has not.

`set_route` changes only the recommendation. `strip_x(width)` maps it to a centred local X coordinate: (route − 0.5)×width. At 0.5 the strip is central. At 0.2 and 0.8 it sits 30% of the full width to either side of the centre. Our model uses a width of 1.8 metres; the installed artifact uses 7. The normalized setting can agree while the distances differ.

`return_route` restores only 0.35. It does not reset lambda, rebuild cubes or erase KEEP. `reading` copies the input array before returning it; `keep` retains that record alongside the recommendation. Later edits cannot rewrite the kept inputs through a shared array reference. As before, this is a record in memory for this run.

## Build once; move one strip

Create `lambda_study.gd`. We use familiar cube meshes for a small, static comparison field: six columns and four cubes per column. The seed creates progressively jittered positions and rotations once. These are authored visual differences, not measured entropy levels. This working copy isolates recommendation movement; the full museum artifact also contains moving forms and pulsing materials.

''' + code('lambda_study.gd') + '''
`_ready` initializes the inherited bench, then builds all twenty-four cubes. `redraw` changes the green strip, retained amber marker, point home and text. It never calls the generator or edits a cube. The strip is a mesh without a collider. It can pass under a cube: the recommendation has moved, but the cube has not been cleared away.

WEIGHT and STRIP select what the same sphere edits. As in the preceding halls, `to_local` puts the hand in the bench's frame. A 0.48-metre vertical travel gives a fraction from 0 to 1. WEIGHT sends it to lambda directly; STRIP maps it to 0.20..0.80 with `lerpf`. On release, the sphere rests at the height representing the selected setting. Buttons wait for release, so a held hand does not compete with a preset.

KEEP records both values and the arithmetic result. Its amber line marks the earlier strip position. RETURN returns only the recommendation to 0.35; ZERO L sets only the arithmetic weight to zero. Neither rebuilds the forms. There is no control here that promises to make the middle objectively best.

## Build and investigate in the museum

Open `res://doc/book/studies/qfep-lineage/lambda.tscn` and press F6. The supplied `lambda_museum.gd` adapter loads the existing hall, with its player, lights and original walk-in artifact, and adds this working bench in a checked bay. The scene and adapter are included with the lesson. This is code for the prepared museum project, with the declared XRTools and button dependencies.

1. Leave the point in STRIP mode and press KEEP. Identify two neighbouring cubes. Lift the sphere to move the green recommendation towards 0.8. Watch those cubes: their positions, rotations and colours should stay fixed. The total should stay 0.450 too.
2. Release, press WEIGHT, then lift the sphere to lambda = 1. Predict the new contribution and total before reading them: −0.200 and 0.350. The green strip should remain where you placed it. ZERO L should give total 0.550 while the stored E input stays 0.20.
3. Press RETURN. The recommendation returns to 0.35; the weight you selected remains. The kept record still refers to the earlier pair. Identify exactly which values each button changes.
4. Make an independent comparison: select STRIP and place the sphere a quarter of the way up its travel. Predict route = 0.35 and x = −0.27 on this 1.8-metre field. Try three-quarters travel: route = 0.65 and x = +0.27. Verify that the cubes and score did not change. If those predictions fail, inspect which frame, width or interval you used.
5. Return to the full-size LIT STRIP rail. Try two different recommendations while attending to the same row. Its forms keep their own animation; moving the rail does not restart that animation or rebuild their arrangement. Describe what the light recommends, then what you would actually choose. The code can verify that one variable changed; it cannot decide what you should prefer.

The installed hall's configured `lambda_value` also shaped its original clearance and material emphasis. Its visitor rail now changes only `recommendation_position`. Our two-control working copy makes that independence explicit; it is not connected as a remote control to the installed hall. The miniature is a reconstruction of the comparison, not a replacement for walking through the full encounter.

## Assert what stays still

Create `recommendation_checks.gd`. The important checks cross the boundary between controls: moving a recommendation must not alter the calculation, and changing a weight must not move the recommendation. The remaining assertions cover retained evidence, bounds and the declared coordinate mapping.

''' + code('recommendation_checks.gd') + '''
Run `python tools/test_qfep_lambda.py` from the project root. The supplied harness extracts all seven files from their printed sources, then runs Godot assertions and synthetic point/button interactions. It checks every cube's identity, transform and colour before and after the edits. A separate native run operates the installed LIT STRIP and RETURN controls, compares their mapping with this one, and checks that the surrounding rows are not rebuilt or recoloured and animation time is not reset. Failed assertions and engine errors fail the run.

Those checks establish the operations a learner can perform, not the learner's interpretation or headset comfort. The task is to make a controlled comparison possible. Whether the relocated light persuades someone is a further question for an encounter with a visitor.

## Carry onward

Keep parameter, effect and interpretation separate. A weight changes a contribution. A strip expresses a recommendation. A visitor may accept neither. Phi Term next adds an earlier and a later reading: a signed difference is not yet a rate until the elapsed interval is included.

**Short instruction:** Carry PointBody + Bench + LineSkin + Introduction Balance unchanged. One sphere selects WEIGHT or STRIP. Lambda edits arithmetic only; route maps .2..8 to local x; cubes built once. KEEP copies inputs/route; RETURN restores route only. Assert both directions of independence, zero weight, preserved cube transforms/colours, same point, local hand mapping. Existing hall animates independently. No entropy measurement or universal optimum. Next: difference versus rate.
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
            paths=[HALL/'map_data.json',ROOT/'commons/maps/sequences/qfeplaboratory.json',ROOT/'commons/artifacts/lambda_hall/lambda_hall.gd']
            baseline.write_text(json.dumps({p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in paths},indent=2),encoding='utf8')
    learner=OUT/'learner';learner.mkdir(exist_ok=True)
    manifest={'scope':'Fresh printed Lambda lesson and four declared inherited files. Hashes use UTF-8 with LF newlines.','files':{}}
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
