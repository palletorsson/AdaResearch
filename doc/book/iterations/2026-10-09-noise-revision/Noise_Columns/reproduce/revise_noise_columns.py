"""Write one Noise lesson; retain the reflection's encounters and the installed hall."""
from pathlib import Path
import json, re, shutil

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-09-noise-revision/Noise_Columns'
MAP=ROOT/'commons/maps/Noise_Columns'
STUDY=ROOT/'doc/book/studies/noise-lineage'

def block(name):
    return f'<!-- student-code:{name} -->\n```gdscript\n{(STUDY/name).read_text(encoding="utf8").rstrip()}\n```\n'

def main():
    before=OUT/'before';before.mkdir(parents=True,exist_ok=True)
    for name in ['tutorial.md','final.md','map_data.json']:
        if not (before/name).exists():shutil.copy2(MAP/name,before/name)
    plan=json.loads((ROOT/'doc/book/course/execution-plan/plan.json').read_text(encoding='utf8'))
    if not (before/'plan-entry.json').exists():
        (before/'plan-entry.json').write_text(json.dumps(next(x for x in plan['lessons'] if x['id']=='Noise_Columns'),indent=2)+'\n')
    tutorial='''# Noise Columns — one body, three drivers

## Learning elements

- Scalar driver and receiving function.
- A fixed value, a periodic value and a coherent field sample.
- Time used as a sampling address.
- Local clock; holding a displayed state.
- Rest positions and repeatable deformation.

## Look before naming

The three columns are already in the museum. Watch them before pressing REVEAL. Which holds? Which seems to return? FREEZE holds their clock. SPIN turns the held shapes; MARBLE changes the shaft's surface. These are separate operations.

From Wavefunctions you bring the twisted shaft: rings of positions, joined by triangle faces. From Randomness you bring a named seed and a repeatable recipe. Here the new operation is small: **send different sources through the same receiving function**. Noise supplies a number; the shaft decides what it changes.

## Continue the construction

Use one empty Node3D in your existing museum learner space, at floor level with unit scale. Give it about four metres of width and stand on its local +Z side. Attach `02_column_drivers.gd`. Save `shaft.gd` and your existing `point_body.gd` beside it. All three files are printed below. Day Zero's XR Tools, player, camera, lighting and grip/trigger actions remain supplied by the museum.

This is a small reconstruction beside the installed work. It carries Bernini's ring-and-face construction with a narrower profile and fixed half-turn. It isolates the vertical drop; the installed shafts also have ribs, bulges and other offsets. It does not reconstruct the marble shader, capitals or their supports. These display shafts have no colliders. The sphere is our earlier pickable PointBody: hold it and press the trigger to pause or resume this study. Its initial position is set before it enters the physics tree.

### The new script

The three kinds keep the same order: held, sine, field. Every shaft has the same rest positions, faces and material. Only its incoming value differs.

'''+block('02_column_drivers.gd')+'''
`time` counts seconds only while this local clock runs. In `sin(seconds * 0.9)`, 0.9 is radians per second; a cycle takes `TAU / 0.9`, about seven seconds. Multiplying the signed result by 0.5 and adding 0.5 maps it to 0–1. This output is an amount, not an angle.

The field branch turns time into an address: `(seconds * 0.55, 0)`. The first coordinate advances 0.55 field units per second; the second stays fixed. Frequency scales that address inside FastNoiseLite. The seed selects a repeatable field. Nearby addresses give related values. Asking again at the same address gives the same value; it does not spend another random draw.

The study explicitly uses Simplex without fractal layers. The installed trio uses Simplex with the resource's layered defaults. Their numerical paths differ; both hand one bounded value to a whole shaft. Layering is a later subject. Neither branch samples independently at every vertex.

The display updates at most twelve times per second. Between updates it holds its last mesh and values. Pausing preserves that displayed shape; it stops this clock without pausing the museum. The held driver remains 0.10 even when the clock runs.

### The carried shaft, with a receiver

The loops and face indices return from Bernini. `rest` keeps the undeformed positions. `weights` records how much of the drop each height receives: zero at the foot, one at the top, the square root of relative height between. Only `receive()` adds the new deformation. The maximum drop is measured in local metres because the study has unit scale.

'''+block('shaft.gd')+'''
Every update starts from `rest`. It does not subtract another amount from yesterday's altered position. At value 1 the top drops 0.70 metres; at 0.5 it drops 0.35 metres. The foot stays at zero. Face indices and vertex count stay the same. That does not make this a simulation of stone under load, nor guarantee that arbitrary parameter changes will avoid folds or self-intersection.

### The point we already know

This is the unchanged PointBody from the previous hall, included so the printed example is complete. Its frozen release keeps the control where you leave it. The lesson supplies its black material and connects its existing action signal; pickup itself is not a new subject here.

'''+block('point_body.gd')+'''
## Make a prediction, then change the receiver

1. Before editing, predict the sine column at time zero, a quarter-cycle and a half-cycle. Its incoming values are 0.5, 1 and 0.5; the top heights should be 2.05, 1.70 and 2.05 metres. Watch a complete return. Pause it and walk around.
2. Change only `top_drop` from 0.70 to 0.35. Predict what stays: driver values, repeat period, field addresses, number of vertices and face connections. Every vertical displacement should halve; the top at a quarter-cycle should now be 2.05 metres. Compare at the same times, not at two unrelated moments.
3. Call the receiver twice with the same value. It must give the same positions. If the column sinks farther on the second call, find where the original positions were lost.

The visible result should support your explanation of the change. A passing script alone does not show that you can distinguish its source from its receiver.

## Carry onward

Leave the columns frozen and look at the installed dark sphere. Its own clock continues. A sine changes brightness and emission there, without rebuilding the mesh. You already know those material properties from Colour. Noise One will take one retained field sample and send it to two receivers: height and colour.
'''
    (MAP/'tutorial.md').write_text(tutorial,encoding='utf8')
    final=(before/'final.md').read_text(encoding='utf8')
    final=final.replace('Behind us, a number found a height in a wall. An opening moved, and the view changed.', 'Behind us, a proposed position had to find room among the points already admitted. Elsewhere in that hall, a number found a height in a wall: an opening moved, and the view changed.')
    final=re.sub(r'```gdscript\n.*?\n```\n\n','',final,flags=re.S)
    final=final.replace('The walls behind us gave each arriving value an opening.', 'The wall in the previous hall gave each arriving value an opening.')
    final=final.replace('`v` marks progress up the shaft, from zero to one.', 'Progress up the shaft is measured from zero to one.')
    final=final.replace('This body uses another local clock. Its script also contains a sine:\n\nThis time', 'This body uses another local clock and another sine. This time')
    final=final.replace('The stand chooses `presence = hush` and `body = swarm` before the scene builds. The first setting makes the presence smaller and quieter. The second chooses a construction with six members.', 'The stand chooses a quieter presence and a construction with six members before the scene builds.')
    (MAP/'final.md').write_text(final,encoding='utf8')
    print('Wrote',MAP/'tutorial.md')

if __name__=='__main__':main()
