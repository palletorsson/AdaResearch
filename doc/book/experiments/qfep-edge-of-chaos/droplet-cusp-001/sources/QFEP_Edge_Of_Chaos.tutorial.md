# Same start, different steps

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

<!-- student-code:timed_field.gd -->
```gdscript
extends RefCounted
const N := 32
const START_SEED := 0x5EED17
var a := PackedFloat32Array()
var b := PackedFloat32Array()
var ticks := 0
var fault := ""

func _init() -> void:
    reset(START_SEED)

func index(x: int, y: int) -> int:
    return posmod(y,N)*N+posmod(x,N)

func reset(seed_value: int) -> void:
    a.resize(N*N)
    b.resize(N*N)
    a.fill(1.0)
    b.fill(0.0)
    ticks = 0
    fault = ""
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_value
    for spot in 12:
        var x := N/2+rng.randi_range(-N/8,N/8)
        var y := N/2+rng.randi_range(-N/8,N/8)
        for dx in range(-2,3):
            for dy in range(-2,3):
                var i := index(clampi(x+dx,0,N-1),clampi(y+dy,0,N-1))
                a[i] = 0.5
                b[i] = 1.0

func laplacian(values: PackedFloat32Array, x: int, y: int) -> float:
    return (values[index(x-1,y)]+values[index(x+1,y)]
        +values[index(x,y-1)]+values[index(x,y+1)])*0.25-values[index(x,y)]

func step(dt: float, weight: float) -> bool:
    if not fault.is_empty(): return false
    if not is_finite(dt) or dt <= 0.0 or dt > 0.3 or not is_finite(weight) or weight < 0.0 or weight > 1.0:
        fault = "Invalid timestep or parameter"
        return false
    var feed := lerpf(0.01,0.08,weight)
    var kill := lerpf(0.08,0.03,weight)
    var da := lerpf(0.8,1.2,weight)
    var db := lerpf(0.3,0.7,weight)
    var next_a := PackedFloat32Array()
    var next_b := PackedFloat32Array()
    next_a.resize(N*N)
    next_b.resize(N*N)
    for y in N:
        for x in N:
            var i := index(x,y)
            var reaction := a[i]*b[i]*b[i]
            next_a[i] = a[i]+(da*laplacian(a,x,y)-reaction+feed*(1.0-a[i]))*dt
            next_b[i] = b[i]+(db*laplacian(b,x,y)+reaction-(kill+feed)*b[i])*dt
            if not is_finite(next_a[i]) or not is_finite(next_b[i]) or next_a[i] < 0.0 or next_b[i] < 0.0:
                fault = "Invalid concentration; restart the comparison"
                return false
    a = next_a
    b = next_b
    ticks += 1
    return true
```

`reset` uses a numbered random generator to place twelve small patches in the centre region. A starts at one and B at zero; a seeded patch has A = 0.5 and B = 1. Overlapping patches overwrite the same values. RESTART can therefore reproduce an entire beginning. Changing the seed changes that beginning without changing the rule.

`index` wraps coordinates. At x = 0, the left neighbour is x = 31. `laplacian` returns zero for a uniform field and otherwise returns the four neighbours' mean minus the centre. Diffusion uses that difference to exchange concentration. The supplied Gray–Scott reaction consumes A and produces B through A×B×B. Feed replenishes A; feed plus removal reduces B.[^model]

Lambda is a route through four numbers: feed 0.01–0.08, removal 0.08–0.03, diffusion A 0.8–1.2 and diffusion B 0.3–0.7. It is an authored convenience, not an entropy measurement or the location of a universal “edge”. Moving it changes four coefficients together. To isolate just feed would require a different control and comparison.

For each cell, `step` calculates **old value + change rate × dt**. This is a forward Euler update. Every rate reads the unchanged old arrays. Only after all cells have valid results do the new arrays become the present. Updating in place would instead make the scan order part of the operation. Like our earlier CA example, this small class allocates fresh next arrays for clarity; the installed artifact reuses spare buffers.

At lambda 0.4, feed is 0.038 and removal is 0.060. In a uniform patch with A = 0.5 and B = 1, diffusion contributes zero. A dt of 0.3 gives A = 0.3557 and B = 1.1206 after one step. B exceeding one is possible here. The model retains it. The palette will saturate separately; clipping the stored B would change the next reaction.

The allowed dt range is a bound chosen for this study, not a proof that every possible concentration remains valid. A negative or non-finite answer stops the run and records a fault. No partially calculated next field is published. Do not repair such a fault by silently clipping values. Restart, then inspect the start, coefficients and timestep.

## Keep the comparison fair

Create `step_comparison.gd`:

<!-- student-code:step_comparison.gd -->
```gdscript
extends RefCounted
const Field = preload("timed_field.gd")
var coarse := Field.new()
var fine := Field.new()
var weight := 0.4
var dt := 0.3
var seed_value := Field.START_SEED
var kept: Dictionary = {}

func set_weight(value: float) -> bool:
    if not is_finite(value): return false
    weight = clampf(value,0.0,1.0)
    return true

func restart() -> void:
    coarse.reset(seed_value)
    fine.reset(seed_value)

func new_seed() -> void:
    seed_value += 1
    restart()

func toggle_step() -> void:
    dt = 0.15 if dt > 0.2 else 0.3
    restart()

func advance() -> bool:
    # A batch is six model-time units, for either timestep pair.
    if not coarse.fault.is_empty() or not fine.fault.is_empty(): return false
    for i in roundi(6.0/dt):
        if not coarse.step(dt,weight): return false
        for half in 2:
            if not fine.step(dt*0.5,weight): return false
    return true

func difference() -> float:
    var squared := 0.0
    for i in Field.N*Field.N:
        squared += pow(coarse.b[i]-fine.b[i],2)
    return sqrt(squared/(Field.N*Field.N))

func reading() -> Dictionary:
    return {"weight":weight,"seed":seed_value,"dt":dt,
        "coarse_ticks":coarse.ticks,"fine_ticks":fine.ticks,
        "coarse_time":coarse.ticks*dt,"fine_time":fine.ticks*dt*0.5,
        "rms":difference(),"fault":coarse.fault+fine.fault}

func keep() -> void:
    kept = reading()
    kept["coarse_b"] = coarse.b.duplicate()
    kept["fine_b"] = fine.b.duplicate()
```

`coarse` and `fine` are separate instances. Both receive the same numbered seed and lambda. One coarse step of dt = 0.3 is paired with two fine steps of dt = 0.15. The fine calculation evaluates the reaction and neighbours again at the intermediate state. Consequently, two half steps need not equal one full step.

The advance loop requests six model-time units. With the first pair that means 20 coarse steps and 40 fine steps. DT / 2 selects 0.15 and 0.075 and restarts the same seed: now six units need 40 and 80 steps. Model time is ticks × dt. It is not visitor time, and these six units are not a promise that the operation takes six seconds.

`difference` calculates the root mean square of corresponding B differences. Subtract each pair, square, average, then take the square root. Zero means that these B arrays agree. A small nonzero number summarizes disagreement in this observable; it does not measure entropy or assign artistic value. A local feature can matter to you without dominating a whole-field average.

KEEP records the settings, both step counts and times, RMS, and copied B arrays. Those arrays need `duplicate`: unlike Phi's scalar record, these fields are mutable collections. Restart and later evolution preserve the kept evidence. This record lasts for the current run, not across closing the project. It keeps the compared B fields, not a resumable A/B checkpoint or a history of lambda edits. Seed, fixed setting and duration can reconstruct a fixed-setting run; if you intervene midway, record when and how the setting changed as well.

Changing lambda does not reset or advance either field. The new coefficients will apply to the next update. That permits an intervention in an existing history. For a comparison between fixed settings, change lambda and then RESTART. For a timestep comparison, DT / 2 already restarts both copies. If a solver faults, stop comparing its images as if their times still agreed; the display shows the individual clocks and a fault until restart.

## Return the arrays to a surface

Create `edge_study.gd`:

<!-- student-code:edge_study.gd -->
```gdscript
extends "bench.gd"
const Comparison = preload("step_comparison.gd")
const LOW := 1.12
const TRAVEL := 0.48
var model := Comparison.new()
var textures: Array[ImageTexture] = []
var captions: Array[Label3D] = []

func _ready() -> void:
    start("SAME START / SAME MODEL TIME",
        ["+6 TIME", "RESTART", "NEW SEED", "DT / 2", "KEEP"],
        [advance, restart, new_seed, toggle_step, keep])
    for side in 2:
        var x := -0.42+side*1.05
        var image := Image.create(32,32,false,Image.FORMAT_RGB8)
        var texture := ImageTexture.create_from_image(image)
        textures.append(texture)
        var screen := block(self,Vector3(x,1.32,0.05),Vector3(0.9,0.62,0.025),Color.WHITE)
        var face := QuadMesh.new()
        face.size = Vector2(0.9,0.62)
        screen.mesh = face
        screen.material_override.albedo_texture = texture
        screen.material_override.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
        captions.append(label(self,"",Vector3(x,1.68,0.05),17))
    redraw()

func _process(_delta: float) -> void:
    if point == null or not point.held(): return
    model.set_weight((to_local(point.global_position).y-LOW)/TRAVEL)
    update_readout()

func advance() -> void:
    if point.held(): return
    model.advance()
    redraw()

func restart() -> void:
    if point.held(): return
    model.restart()
    redraw()

func new_seed() -> void:
    if point.held(): return
    model.new_seed()
    redraw()

func toggle_step() -> void:
    if point.held(): return
    model.toggle_step()
    redraw()

func keep() -> void:
    if point.held(): return
    model.keep()
    update_readout()

func tint(value: float) -> Color:
    return Color("123039").lerp(Color("efbf80"),clampf(value,0.0,1.0))

func redraw() -> void:
    for side in 2:
        var values: PackedFloat32Array = model.coarse.b if side == 0 else model.fine.b
        var image := Image.create(32,32,false,Image.FORMAT_RGB8)
        for y in 32:
            for x in 32:image.set_pixel(x,y,tint(values[y*32+x]))
        textures[side].update(image)
        captions[side].text = "DT %.3f" % (model.dt if side == 0 else model.dt*0.5)
    update_readout()

func update_readout() -> void:
    point_home = Vector3(-1.17,LOW+model.weight*TRAVEL,0.22)
    var r := model.reading()
    var record := "KEEP: no comparison yet"
    if not model.kept.is_empty():
        record = "KEEP L %.2f / seed %d / t %.0f / RMS %.5f" % [
            model.kept.weight,model.kept.seed-Comparison.Field.START_SEED,
            model.kept.coarse_time,model.kept.rms]
    readout.text = "LAMBDA %.2f / seed %d / 32 x 32\nSteps %d / %d; time %.1f / %.1f\nB difference %.5f / %s\n%s" % [
        r.weight,r.seed-Comparison.Field.START_SEED,r.coarse_ticks,r.fine_ticks,
        r.coarse_time,r.fine_time,r.rms,"READY" if r.fault.is_empty() else "FAULT: "+r.fault,record]
```

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

<!-- student-code:step_checks.gd -->
```gdscript
extends RefCounted
const Field = preload("timed_field.gd")
const Comparison = preload("step_comparison.gd")

func run() -> void:
    var field := Field.new()
    assert(field.index(-1,0)==31 and field.index(0,-1)==32*31)
    var seeded := field.b.duplicate()
    field.reset(Field.START_SEED)
    assert(field.b==seeded)
    field.reset(Field.START_SEED+1)
    assert(field.b!=seeded)
    field.a.fill(1.0)
    field.b.fill(0.0)
    assert(field.laplacian(field.a,0,0)==0.0)
    assert(field.step(0.3,0.4))
    assert(field.a[0]==1.0 and field.b[0]==0.0)
    field.a.fill(0.5)
    field.b.fill(1.0)
    var old_a := field.a
    assert(field.step(0.3,0.4))
    assert(absf(field.a[0]-0.3557)<0.000001)
    assert(absf(field.b[0]-1.1206)<0.000001)
    assert(old_a[0]==0.5)
    field.a.fill(0.0)
    field.b.fill(0.0)
    field.a[0]=1.0
    assert(field.step(0.3,0.4))
    assert(absf(field.a[31]-0.0834)<0.000001)
    var before := field.a.duplicate()
    var count := field.ticks
    assert(not field.step(0.0,0.4))
    assert(field.a==before and field.ticks==count)
    assert(not field.step(0.3,0.4))
    field.reset(Field.START_SEED)
    assert(field.fault.is_empty() and field.ticks==0)
    assert(not field.step(0.4,0.4))
    field.reset(Field.START_SEED)
    assert(not field.step(0.3,NAN))
    var pair := Comparison.new()
    assert(pair.coarse.b==pair.fine.b and pair.difference()==0.0)
    assert(pair.advance())
    assert(pair.coarse.ticks==20 and pair.fine.ticks==40)
    assert(is_equal_approx(pair.reading().coarse_time,6.0) and is_equal_approx(pair.reading().fine_time,6.0))
    assert(pair.difference()>0.0)
    pair.keep()
    var record: Dictionary = pair.kept.duplicate(true)
    pair.set_weight(0.7)
    assert(pair.coarse.ticks==20 and pair.kept==record)
    pair.toggle_step()
    assert(pair.dt==0.15 and pair.coarse.ticks==0 and pair.coarse.b==seeded)
    assert(pair.advance())
    assert(pair.coarse.ticks==40 and pair.fine.ticks==80 and is_equal_approx(pair.reading().fine_time,6.0))
    pair.new_seed()
    assert(pair.coarse.b!=seeded and pair.coarse.b==pair.fine.b)
    assert(pair.kept==record)
    pair.fine.fault="Injected test fault"
    assert(not pair.advance() and pair.coarse.ticks==0)
    pair.restart()
    assert(pair.fine.fault.is_empty())
    assert(not pair.set_weight(INF))
    pair.set_weight(-2.0)
    assert(pair.weight==0.0)
    pair.set_weight(2.0)
    assert(pair.weight==1.0)
```

Run `python tools/test_qfep_edge.py` from the project root. The supplied harness extracts these four new files and the three unchanged carried files from their printed sources. It runs the assertions and synthetic point/button interactions, including the independent time-18 task. It also compares a 32 × 32 instance of the installed solver with this reconstruction from the same seed and coefficients. That is a matched numerical check, not a comparison between differently sized screenshots.

A separate rendered run loads the existing museum, exercises its real console signals and mounts the extracted learner code. Tests check time accounting, restart, seed changes, state retention, palette separation and the local hand mapping. They do not establish headset comfort, independent learner understanding, physical chemistry or universal criticality.

## Carry onward

Retain enough of an experiment to repeat it: seed, model definition, parameters, timestep and duration. The next hall, Sandbox, asks whether a parameter reaches its intended receiver at all. Similar labels on two objects do not make a connection between them.

**Short instruction:** Carry PointBody + Bench + LineSkin. Adapt CA field to periodic mean-minus-centre exchange, explicit Euler dt, unclipped Float32 concentrations; match current installed solver, not old clipped trajectory. Same seed/coefficients; one coarse step, two half steps; +6 model time at either pair. Sphere edits coupled lambda only. Restart for fixed-setting comparison; DT restarts; KEEP copies fields/settings/times. Assert cell arithmetic, synchronous update, wrap, no hidden clipping, equal clocks, restart, measured refinement, held-point mapping and installed-solver agreement. No universal optimum. Next: explicit sender/receiver connections.

[^model]: John E. Pearson, [“Complex Patterns in a Simple System”](https://arxiv.org/abs/patt-sol/9304003), *Science* 261 (1993), 189–192. This lesson supplies its own discrete grid, seeded start and parameter route; it is not a reproduction of Pearson's experiments.
