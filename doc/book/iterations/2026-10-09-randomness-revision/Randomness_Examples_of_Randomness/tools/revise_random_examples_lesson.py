"""Write one focused, reconstructable Monte Carlo lesson; preserve museum sources."""
from pathlib import Path
import hashlib,json,shutil
ROOT=Path(__file__).resolve().parents[1]
MAP='Randomness_Examples_of_Randomness'
HERE=ROOT/'doc/book/iterations/2026-10-09-randomness-revision'/MAP
STUDY=ROOT/'doc/book/studies/randomness-lineage'

def main():
    HERE.mkdir(parents=True,exist_ok=True)
    paths=[f'commons/maps/{MAP}/{n}' for n in ['tutorial.md','final.md','map_data.json']]+['algorithms/randomness/monte_carlo_dartboard/monte_carlo_dartboard.gd','algorithms/randomness/monte_carlo_dartboard/monte_carlo_dartboard.tscn','commons/maps/sequences/randomness.json','doc/book/studies/randomness-lineage/point_body.gd']
    if not (HERE/'before-manifest.json').exists():
        manifest={}
        for p in paths:
            dest=HERE/'before'/p;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/p,dest)
            manifest[p]=hashlib.sha256((ROOT/p).read_bytes()).hexdigest()
        (HERE/'before-manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf8')
    tutorial='''# A draw estimates

**Learning elements**

- Uniform samples in a square
- Circle membership and hit counts
- A running Monte Carlo estimate
- Finite-sample fluctuation and sampling bias

In Space Geometry you compared independent heights with values from a spatial field. Here the sampling rule has a different responsibility: it supplies evidence for an estimate. Keep the point, arrays and counters. Draw two coordinates, record the position, and ask whether it falls inside a circle.

First visit the Monte Carlo board already in this gallery. Press REPLAY, then THROW. A mark inside the circle increases both the inside count and the total; an outside mark increases only the total. Predict how the estimate will change before requesting another point. THROW requests a generated position; you are not aiming a physical dart. The BUDGET dial chooses 100, 500, 2000 or 8000 samples and restarts the same seed; FILL reaches that count. +100 extends the current run. NEXT SEED starts another run; 8 SEEDS compares eight runs without changing the displayed one.

## Reconstruct the counting rule

In your local copy of the prepared Endless Museum, add a Node3D at hall-local **(10.5, 0, 13), Y rotation 180 degrees**, with unit scale. Save the two files below together and attach `11_a_draw_estimates.gd` to it. The museum supplies the player, camera, floor, lighting and installed XR Tools. This temporary learner board creates its own geometry and labels beside the existing works. Its front is local positive Z; the geometry is visual only, and the museum floor supports you.

Reuse PointBody from the earlier lessons. Hold it over a labelled third of the board and press its trigger: REPLAY clears the record and rewinds the seed; ONE adds a sample; BATCH adds sixteen. Moving or releasing the point changes no samples. These are the familiar local-X zones, not touch buttons or snapping. The installed board uses rectangular buttons and a budget dial; our reconstruction keeps the counting lesson small.

Read `add_samples()` first. Each position lies in a square from −1 to 1 on both axes. The circle has radius 1 and area π; the square has area 4. With uniform sampling over this square, the proportion inside estimates π/4. Multiplying by four estimates π. The squared-distance test avoids a square root; it makes the same inside/outside decision.

The left panel retains every sample: teal inside, pink outside. Its circle outline uses 64 short cylinders; the equation decides membership, not collisions with that drawn edge. On the right, each black dot records the estimate after that sample. Horizontal position is sample number, vertical position is the estimate from 0 to 4. The gold line marks π for comparison; it never enters the counting calculation. Before any sample, the label shows `--` because there is no ratio yet.

## The complete study

<!-- student-code:11_a_draw_estimates.gd -->
```gdscript
__MAIN__
```

## The carried point

Keep your existing `point_body.gd` beside the study. This is the unchanged class, included so the printed lesson has no missing code dependency beyond the declared XR Tools installation. The small sample marks are visual spheres; they do not each need pickup behaviour.

<!-- student-code:point_body.gd -->
```gdscript
__POINT__
```

## Follow the record

`samples` keeps the positions. `inside` counts those accepted by the circle test. `estimates` keeps one ratio per position, so the graph retains how the answer changed. The expression starts with `4.0` to produce a floating-point ratio. Display helpers build familiar spheres, cylinders, boxes and labels; none of them draws a random value.

Add sixteen points individually. REPLAY, then request one BATCH. The positions, counts and estimate history should match exactly in this engine version. The loop groups requests; it does not choose a different sampling procedure. A new seed can produce a different run, but resetting only the counters would not replay the old one.

There is room for 256 samples. At that limit another request does nothing and spends no random draws. All 256 samples remain visible. The installed artwork has a selectable budget up to 8000 and shows only its latest 300 marks; its counts include the whole run. Both versions rewind their local generator on REPLAY. The same seed with the same sampling procedure lets you compare the same finite sample; a seed alone does not specify the whole experiment.

## Test a change you can explain

1. Change `BATCH` from 16 to 32. After replay, eight batches should reproduce the same 256 positions as sixteen batches did before. Predict the whole record, not only a number close to π.
2. Change `sample_seed` from 42 to 43. Fill the board again. A different estimate is not a failed program. Watch the history: a later point can move the estimate farther from π. A larger independent uniform sample reduces sampling uncertainty in general; it does not guarantee a better answer at every step.
3. Restore seed 42 and change `x_span` from 1.0 to 0.2. Leave the circle test and factor four alone. The points now occupy only a central strip. The program still runs, but `4 × inside / total` no longer estimates π under the original square-area argument. The source of the error is visible before you inspect the final number. More draws from the same strip do not restore the missing coverage. Restore 1.0 afterward.

For a calculation you can check by hand, imagine the first four records are `(0,0)`, `(1,1)`, `(0.5,0.5)` and `(-1,-1)`. Two are inside. The estimates after each record would be 4, 2, 8/3 and 2. More samples did not make this particular history steadily more accurate. This fixture checks the arithmetic; it is not itself a random experiment.

## What travels onward

You have separated drawing, classification and interpretation. The seed can replay the evidence; it cannot certify that the evidence suits the question. Keep that distinction as you inspect the painting, pipes and particle study: their random choices serve different purposes and do not all need to estimate an area.

In Pheromone, a recorded visit will enter a later choice. Samples there will depend on a changing field. We will follow that feedback explicitly instead of assuming each new position was drawn independently from the same square.
'''
    tutorial=tutorial.replace('__MAIN__',(STUDY/'11_a_draw_estimates.gd').read_text(encoding='utf8').rstrip()).replace('__POINT__',(STUDY/'point_body.gd').read_text(encoding='utf8').rstrip())
    (ROOT/f'commons/maps/{MAP}/tutorial.md').write_text(tutorial,encoding='utf8')
    final=(HERE/f'before/commons/maps/{MAP}/final.md').read_text(encoding='utf8')
    final=final.replace('The dartboard waits to the right, the pipes farther along to the left,','The dartboard and pipes wait farther along,')
    final=final.replace("Move to the dartboard's console on the right.","Move to the dartboard's console.").replace('Cross to the pipe study on the left.','Cross to the pipe study.').replace('The particle study occupies the last bay on the right.','The particle study occupies the last bay.')
    final=final.replace('Estimating by sampling is what the name on this bench, Monte Carlo, has meant since 1949.[^monte-carlo]','This is a Monte Carlo estimate: a quantity approached through sampled trials.')
    final=final.replace('Press RESET. If new marks appear, press AUTO to pause them and RESET again.','Press REPLAY.').replace('Add a few more points individually before using AUTO to build a larger sample.','Add a few more points individually before using +100 or FILL to build a larger sample.')
    final=final.replace('Pause AUTO and RESET to compare another run. The counters stop at 500 darts, so RESET also begins a new sample once the count has filled. The board itself shows only the newest 300 marks: past that, the picture forgets points the numbers still include.','REPLAY clears the record and returns to the same seed. NEXT SEED begins a different run. Turn BUDGET to choose 100, 500, 2000 or 8000 samples, then FILL; changing the budget starts that seed again, so larger budgets extend the same opening sequence. The board itself shows only the newest 300 marks: past that, the picture forgets points the numbers still include. Press 8 SEEDS to compare several estimates without replacing your current run. A comparison gives you more evidence, not a promise that every increase in budget improves every result.')
    final=final.replace('Here chance chooses the evidence.',"The small reconstruction lets you narrow the sample to a strip without moving the circle. The number can become steady while answering a different question. The failure is in the agreement between the places sampled and the area the number claims to describe.\n\nHere chance chooses the evidence.")
    final=final.split('\n[^monte-carlo]:')[0].rstrip()+'\n'
    (ROOT/f'commons/maps/{MAP}/final.md').write_text(final,encoding='utf8')

if __name__=='__main__':main()
