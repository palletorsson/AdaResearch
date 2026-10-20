"""Preserve the installed hall; write its minimal population lesson and reflection."""
from pathlib import Path
import hashlib,json,re,shutil
ROOT=Path(__file__).resolve().parents[1]
HERE=ROOT/'doc/book/iterations/2026-10-09-randomness-revision/Random_Mushrooms'
STUDY=ROOT/'doc/book/studies/randomness-lineage'
PRODUCTION='algorithms/proceduralgeneration/growth_systems/mushrooms/mushrooms.gd'

def main():
    HERE.mkdir(parents=True,exist_ok=True)
    paths=['commons/maps/Random_Mushrooms/tutorial.md','commons/maps/Random_Mushrooms/final.md','commons/maps/Random_Mushrooms/map_data.json',PRODUCTION,'commons/maps/sequences/randomness.json','doc/book/studies/randomness-lineage/point_body.gd']
    if not (HERE/'before-manifest.json').exists():
        for p in paths:
            dest=HERE/'before'/p;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/p,dest)
        (HERE/'before-manifest.json').write_text(json.dumps({p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in paths},indent=2),encoding='utf8')
        run=ROOT/'ada_run/encounter_pilot/Random_Mushrooms'
        dest=HERE/'museum-before';dest.mkdir(exist_ok=True)
        for p in run.iterdir():
            if p.suffix=='.png' or p.name in ['report.json','engine.log','source_manifest.json']:shutil.copy2(p,dest/p.name)
    tutorial='''# A population kept

**Learning elements**

- A recipe and its instances
- Discrete choice and continuous scale
- Dictionaries as named records
- Changing a property while keeping the sampled record

In Random Gaussian you kept numbers and changed their grouping. Here a number chooses a body recipe, another turns it, and another sets its scale. The same record can produce a different comparison without another draw.

Start at the specimen bed already in Endless Museum. SHOW identifies copies of one recipe. Press SIZE and follow a pair: their extra scaling disappears, while their places and recipe identities remain. Two bodies at scale one can still have different dimensions.

Reconstruct that operation on a small table beside the garden. Keep twelve fixed places, two simple mushroom recipes, and the PointBody you already use. The installed meadow has six recipes, scattered candidates, rings, clusters and a separate ground generator. Our table isolates one question: **what changes when we stop using the sampled scale?**

## Set it beside the existing work

Use your prepared museum project with XR Tools and the working player. In a local copy of this hall, add a Node3D for the study, at hall-local **(3, 0, 7), Y rotation 90 degrees**, with unit scale. Its front is local positive Z. The museum supplies the camera, lighting and floor.

Save `09_a_population_kept.gd` and the unchanged `point_body.gd` in the same folder, then attach the first to that Node3D. No scene-child references or prebuilt mushrooms are required. The script creates its table, labels, bodies and hand control. These specimen meshes and the table are visual only; they do not supply collision or eating behaviour.

Hold the point over the left, middle or right third of the front edge and press its trigger:

| Place | Action | What remains |
|---|---|---|
| Left: REPLAY | Rebuild this seeded population | Recipes, seed, count and current SIZE setting |
| Middle: SIZE | Apply sampled scales or scale one | Records, existing body nodes, positions, turns and generator state |
| Right: NEXT SEED | Add one to the seed and rebuild | Recipes, places and current SIZE setting |

Moving or releasing the point does not sample. These are the same pickup and trigger behaviours from the earlier chapters.

## The complete study

<!-- student-code:09_a_population_kept.gd -->
```gdscript
__MAIN__
```

## Give each value a name

A dictionary stores values under names. The recipe's `cap`, `stem` and `colour` are authored dimensions and material. Each population record names its chosen `kind`, `position`, `yaw` and `size`. Instead of remembering that the third number means rotation, the next function can ask for `record.yaw`.

`records` is still the one-dimensional list from Trace. An index names one member. Each member now holds several related values. The drawn kind is an integer index into `recipes`; it selects one whole recipe. It does not interpolate a new kind between two entries.

`randi_range()` chooses a valid recipe index. `randf() * TAU` chooses a turn around Y in radians. `lerpf(size_low, size_high, rng.randf())` maps a uniform draw into the scale interval, initially 0.7 to 1.3. These sizes use the previous hall's uniform option. A Gaussian lesson does not require every later number to be Gaussian.

The program makes those calls in that order for each record. The current SIZE switch is absent from the sampling loop: a scale value is stored even when it will not be applied. A seed repeats a population only with the same recipe list, call order, parameters and engine behaviour.

Positions return to the four-column grid from Arrays. Remainder chooses the column; integer division chooses the row. Twelve places make three rows. Positions are fixed so that two comparisons can be read at the same addresses. The code bounds the count to zero through twelve, keeping this table's footprint finite. It does not sample the garden's clearings or place bodies at random.

## Construct the body, then transform it

`make_mushroom()` joins the familiar cylinder and sphere meshes. The stem's centre is half its height above the local origin; its bottom therefore stays at zero. The cap sits at stem height and is flattened along Y. These proportions follow the installed bed's standard tan and red recipes, with gills omitted. They are stylised constructions, not biological species.

`rebuild()` reads the saved records and makes bodies. It consumes no randomness. `apply_sizes()` changes only each body's uniform scale. Both parts inherit the scale through their parent, and the stem stays rooted on the table. With scale one, the red recipe still has a shorter stem and smaller cap than the tan recipe. Equal scale is not equal size.

Yaw is saved and applied even though these rotationally symmetric specimens make it hard to see. The record can retain a distinction that the current shape does not reveal. We do not add a decoration merely to teach rotation again.

SIZE keeps the exact body nodes as well as their records. Switching it back restores every sampled scale. REPLAY is a different operation: it resets the generator, makes the records again and creates new nodes. The installed garden also reconstructs on SIZE, keeping scale draws in the same order so the other decisions return. Our smaller table keeps the record directly. These routes support the same comparison through different storage choices.

## The familiar hand control

The point's position is converted from world coordinates into this table's local coordinates before choosing an action. Turn the whole study and its left, middle and right remain attached to the table. The thresholds divide X; this small control does not test distance to the table or snap the point into a socket. Use the labelled edge to locate its zones.

<details>
<summary>Complete unchanged PointBody dependency</summary>

<!-- student-code:point_body.gd -->
```gdscript
__POINT__
```

</details>

## Change one rule and predict the result

1. Change `size_low` to `0.4` and `size_high` to `1.6`. Restart with seed 42. The same members should occupy the same places with the same kinds and turns. Each scale's distance from one doubles. SIZE still sets every parent scale to one. Check the record as well as the silhouette.
2. Change `count` from twelve to six. The first six records of the old population should return, with no new sample inserted before them. Only part of the second row remains. Returning to twelve recovers the full population.
3. Add a third dictionary to `recipes`: cap `0.12`, stem `0.35`, colour `Color(0.9, 0.9, 0.8)`. Restart. The same construction function can now make a tall, narrow member. The sampler can choose index 2; find those entries in the record and their corresponding bodies. Twelve draws need not include every recipe. Changing the number of choices can change which draw is assigned where; a retained seed is not a promise that the old kinds remain.

For an independent check, take two records of the same kind with sizes 0.7 and 1.3. SIZE must make their dimensions equal without moving their origins; restoring it must recover both sizes. Then compare two different kinds at scale one. Explain why they can remain different heights. Rebuild the display twice from the saved records and check that the generator state does not advance.

Changing the population seed explores the current repertoire. Adding the third recipe changes that repertoire. It still cannot produce a hollow cap or a branch: those need another construction instruction. The arrival wardrobe and couture figures in this hall let you inspect that distinction at another scale; building their interfaces is outside this lesson.

Carry the separation onward: **keep the values; decide what relation will turn them into form.** Random Space Geometry compares independently chosen heights with neighbouring heights related by a field. The garden's separate ground and clearing rules have already made that question visible.
'''
    for tag,name in [('MAIN','09_a_population_kept.gd'),('POINT','point_body.gd')]:
        tutorial=tutorial.replace('__'+tag+'__',(STUDY/name).read_text(encoding='utf8').rstrip())
    (ROOT/'commons/maps/Random_Mushrooms/tutorial.md').write_text(tutorial,encoding='utf8')
    final=(HERE/'before/commons/maps/Random_Mushrooms/final.md').read_text(encoding='utf8')
    final=re.sub(r'\n```gdscript\n.*?\n```\n','\n',final,flags=re.S)
    final=final.replace("A copy carries its template's details with it:","A copy carries its template's details with it.")
    final=re.sub(r'For a scattered mushroom, the scale had been chosen here:\s+And the switch decides what to do with that value:', 'A scattered mushroom receives an extra scale between 0.7 and 1.3. SIZE decides whether to use it.',final)
    final=final.replace('At each proposed position, a noise field was consulted:', 'At each proposed position, a noise field was consulted.')
    final=final.replace("The 2 in that line, with the field's own frequency of one half, decides how far apart two candidates are in the field's coordinates, and so how wide a clearing can be: about a metre here. In Random Space Geometry, that number is a slider.", "The scale at which positions are read in the field helps determine how nearby decisions resemble each other. A threshold then decides which candidates remain. Random Space Geometry will let you compare that relation with independently chosen values.")
    final=final.replace('This is the accept–reject method: propose a position, test it, keep it or throw it away.[^accept-reject]', 'The placement procedure proposes a position, tests it and keeps it only if the field passes the threshold. That is a rejection rule; it does not by itself establish a particular target probability distribution.')
    final=re.sub(r'\n\[\^accept-reject\]:[^\n]*','',final)
    final=final.replace('Its members were given equal angular intervals:', 'Its members were given equal angular intervals.')
    final=final.replace('Nothing there can be grown again.', 'This exhibit offers no control for returning to the same bubble population.')
    final=final.replace('The sampled sizes never grow a seventh template between two others.', "On the tutorial table, you keep each body\u2019s record and switch off only its scale. Nothing has asked chance to decide again. One difference has been withheld from view; it remains available to return.\n\nThe sampled sizes never grow a seventh template between two others.")
    final=re.sub(r'\n{3,}','\n\n',final)
    (ROOT/'commons/maps/Random_Mushrooms/final.md').write_text(final.rstrip()+'\n',encoding='utf8')

if __name__=='__main__':main()
