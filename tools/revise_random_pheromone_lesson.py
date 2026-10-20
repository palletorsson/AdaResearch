"""Replace the incomplete sketch with the installed choice rule, made small."""
from pathlib import Path
import hashlib,json,shutil
ROOT=Path(__file__).resolve().parents[1]
MAP='Random_Pheromone'
HERE=ROOT/'doc/book/iterations/2026-10-09-randomness-revision'/MAP
STUDY=ROOT/'doc/book/studies/randomness-lineage'

def main():
    HERE.mkdir(parents=True,exist_ok=True)
    paths=[f'commons/maps/{MAP}/{n}' for n in ['tutorial.md','final.md','map_data.json']]+['algorithms/randomness/pheromone_terrain/pheromone_terrain.gd','algorithms/randomness/pheromone_terrain/pheromone_terrain.tscn','commons/maps/sequences/randomness.json','doc/book/studies/randomness-lineage/point_body.gd']
    if not (HERE/'before-manifest.json').exists():
        manifest={}
        for p in paths:
            dest=HERE/'before'/p;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/p,dest)
            manifest[p]=hashlib.sha256((ROOT/p).read_bytes()).hexdigest()
        (HERE/'before-manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf8')
    text='''# A visit enters the next choice

**Learning elements**

- A signal stored at grid addresses
- Deposition and fixed-step decay
- Signal-guided choice mixed with random movement
- Feedback, boundaries and tie-breaking

The Random Walk point kept a trail, but never read it. The Monte Carlo board counted samples without letting a previous hit choose the next position. Here a visit changes a field that later movement reads. The record becomes part of the mechanism.

At the installed terrain, press ATTRACT, then +1 STEP. The four cyan markers move; places they leave gain scent and height. After several +20 STEPS, select AVOID and advance to the same step count. Each rule starts from the same seeded positions. The caption's 40% means a chance of taking the signal-guided branch on each decision. It does not promise that exactly 40% of a short run used that branch.

## One walker, two records

Build a small study in your local copy of this museum hall. Add a Node3D at hall-local **(10.1, 0, 6.2), Y rotation -90 degrees**, with unit scale. Put the two printed files together and attach `12_a_visit_guides.gd` to it. The prepared museum supplies the working player, camera, light, floor and XR Tools. The study creates all its own geometry. Its front is local positive Z; the table and columns are visual only.

The familiar PointBody supplies four trigger zones along the front: REPLAY, STEP, +20 and RULE. Hold it over the label and press. RULE switches ATTRACT/AVOID and resets the experiment. REPLAY keeps the selected rule. Moving or releasing the point does not advance anything.

There is one simulated walker, shown by a cyan sphere on both grids. Left: current scent, coloured pink. Right: accumulated visits, displayed as column heights. `field`, `visits` and `path` are separate arrays. The grid address is an integer pair; `index()` folds it into the familiar one-dimensional list. Test both coordinates before indexing: a valid flat index alone would not prevent a step from wrapping into another row.

Each step takes this order: **fade → deposit at the current address → count the visit → choose → move**. The starting position enters `path` immediately. A completed step adds one departure visit and one destination to the path, so after twenty steps there are twenty visits and twenty-one recorded positions. The latest position has not necessarily received a deposit yet.

## The complete study

Read `advance()` and `choose()` first. The remaining functions build the display and reuse the point's trigger action.

<!-- student-code:12_a_visit_guides.gd -->
```gdscript
__MAIN__
```

## The carried point

Keep the same `point_body.gd` from earlier lessons. It is repeated here only to make the printed dependency complete. The cyan markers are two visual views of one simulated walker; they do not need separate pickup behaviour.

<!-- student-code:point_body.gd -->
```gdscript
__POINT__
```

## Read the decision

The walker considers eight directions in the listed order. A random draw selects the branch. With `guidance = 0.4`, the signal-guided branch chooses the strongest sensed neighbour for ATTRACT, or the weakest for AVOID. Otherwise another draw selects a direction. This is not a weighted lottery among scent values: the guided branch takes an extreme value.

On an empty field every neighbour has the same value. The strict comparisons, `>` and `<`, leave a tie with the first valid direction. Away from an edge that is positive X. A preference can therefore come from the order of the list, even before any scent is present. Diagonal steps also travel farther than cardinal steps; these are grid moves, not equal-length physical strides.

The guided branch skips sensed addresses outside the grid. A random move is clamped to the edge; it can stay at the same address. It still counts as a step and can add another visit there. Reversals and revisits are allowed. No goal, nest, food source or shortest-path test is hidden in the program.

`fade(DT)` removes 0.04 scent from each positive cell at the default settings, stopping at zero. A departure then adds 0.6 to its address. Scent is not capped in the data. The colour saturates at 3.0; height saturates after ten visits, while the visit count keeps growing. The display compresses the record without changing what the walker reads. There is no entropy calculation here.

The clock advances only when you request steps. Twenty STEP presses and one +20 request therefore agree under the same seed and rule. Waiting between presses changes neither scent nor movement. One request for twenty steps represents four simulated seconds; it does not require four seconds of waiting.

## What was reduced from the hall

The installed artifact has four walkers and 81 × 81 stored vertices, sensing two addresses ahead. It raises a visual surface as visits accumulate. Our reconstruction has one walker on 8 × 8 addresses, senses one address ahead and shows visits separately. It preserves the source's eight-direction branch rule, strict tie order, deposit-before-choice and linear decay. It uses the same seeded random-call pattern for this reduced configuration.

The hall also has a border band: a walker outside its interior is corrected without depositing or choosing on that turn. The small study uses the edge policy stated above and no such band. A full museum run and this reconstruction should not produce identical paths. Nor should ATTRACT and AVOID be expected to keep spending corresponding random draws in the full terrain once their boundary encounters diverge.

## Try a change, then account for it

1. Keep seed 42. Advance ATTRACT to step 100, replay, then reach 100 with five +20 requests. The field, visits and complete path should match. Switch to AVOID and repeat the same number of steps. Explain which comparison changed; do not call either path optimal.
2. Change `guidance` to 1.0. Every decision now uses the signal. Predict the first move on blank ground from the order of `DIRS`. Then change it to 0.0: movement still deposits scent, but never reads that scent. The marks have returned to observer-only history.
3. Restore 0.4 and change `decay_rate` to 0.0. After 100 steps the total stored scent should be 60, allowing for floating-point rounding: one hundred deposits of 0.6 and no loss. The column heights cannot report that total, because their display saturates.

For a separate intervention, temporarily add these two lines immediately after `path.append(at)`:

```gdscript
        fade(20.0)
        # visits and path are deliberately retained
```

Leave decay at 0.2. Each new 0.6 deposit is then erased before the next decision. What still survives on the right? What no longer survives on the left? The current step already chose its destination before this extra fade. That order matters. This is an edited experiment, not an extra twenty seconds on the study's normal step clock.

## What travels onward

A field can remember a visit without storing its whole story, and its influence can outlast or fade before the visible trace. You now have an explicit feedback loop: movement changes the signal; the signal can change movement. In Random Space, we will return to fields formed by combining contributions at different scales. Those values can look like land without having a history of visits at all.
'''
    text=text.replace('__MAIN__',(STUDY/'12_a_visit_guides.gd').read_text(encoding='utf8').rstrip()).replace('__POINT__',(STUDY/'point_body.gd').read_text(encoding='utf8').rstrip())
    (ROOT/f'commons/maps/{MAP}/tutorial.md').write_text(text,encoding='utf8')
    final=(HERE/f'before/commons/maps/{MAP}/final.md').read_text(encoding='utf8')
    final=final.replace('The mark has become part of the mechanism.','The mark has become part of the mechanism. In the small reconstruction, the same walker appears twice: beside its fading scent and beside the visits that remain counted. Two pictures can belong to one history without keeping the same part of it.')
    final=final.replace('The signal and the raised terrain do not keep identical histories.','The signal and the raised terrain do not keep identical histories. In the reconstruction, let the scent disappear while retaining the visits. The columns still show where the point has been. What survives for us is no longer what can guide it.')
    (ROOT/f'commons/maps/{MAP}/final.md').write_text(final,encoding='utf8')

if __name__=='__main__':main()
