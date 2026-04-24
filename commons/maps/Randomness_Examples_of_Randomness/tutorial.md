# Examples of Randomness

A gallery of chance. Build four rooms, each showing randomness in a different register.

Declare the gallery registry.

```gdscript
class_name GalleryRegistry
extends Resource

@export var rooms: Dictionary = {
    "pollock": "action painting",
    "pipes": "combinatorial play",
    "butterfly": "biological flight",
    "extremes": "tail distributions",
}
```

Four rooms, four names, four subtitles. The registry is the floor plan.

Place the rooms.

```gdscript
func place_rooms() -> void:
    var angle := 0.0
    for key in registry.rooms:
        var room := preload("res://commons/artifacts/randomness/gallery_room.tscn").instantiate()
        room.name = key
        room.position = Vector3(cos(angle) * 5.0, 0, sin(angle) * 5.0)
        add_child(room)
        angle += TAU / registry.rooms.size()
```

Rooms circle a central rotunda. The learner walks the survey.

Drip Pollock.

```gdscript
func pollock_drip(canvas: Node3D) -> void:
    for i in 80:
        var pos := Vector3(randf_range(-1.5, 1.5), 1.0, randf_range(-1.5, 1.5))
        var dir := Vector3(0, -1, 0) + Vector3(randf() - 0.5, 0, randf() - 0.5) * 0.2
        var drop := preload("res://commons/artifacts/randomness/paint_drop.tscn").instantiate()
        drop.position = pos
        drop.linear_velocity = dir * 5.0
        canvas.add_child(drop)
```

Drops fall from above the canvas, slightly randomised. Each drop leaves a splat where it lands. Action painting as spawn loop.

Generate pipe dreams.

```gdscript
func generate_pipes(grid_size: Vector2i) -> void:
    for x in grid_size.x:
        for y in grid_size.y:
            var piece_kind: int = randi() % 4
            spawn_pipe_piece(Vector2i(x, y), piece_kind)
```

Four piece kinds (straight, bent, tee, cross). Random per cell. The assembly becomes a plumbing puzzle with no designer.

Fly a butterfly.

```gdscript
func fly_butterfly(butterfly: Node3D, dt: float) -> void:
    var noise := FastNoiseLite.new()
    var t := Time.get_ticks_msec() / 1000.0
    butterfly.position += Vector3(
        noise.get_noise_2d(t, 0) * 1.5,
        noise.get_noise_2d(t, 100) * 0.5,
        noise.get_noise_2d(t, 200) * 1.5
    ) * dt
```

Noise drives the butterfly's heading. Each dimension samples noise with a different offset. The path becomes characteristic rather than chaotic.

Visualise extreme tails.

```gdscript
func extreme_sample() -> float:
    return randfn(0.0, 1.0) + randfn(0.0, 4.0) * 0.1
```

A Gaussian mixed with a wider Gaussian produces heavy tails. The values sometimes spike far from zero. The spike drawer shows the far edge.

Plot samples against time.

```gdscript
func plot_sample(value: float) -> void:
    sample_chart.push(value)
```

The chart scrolls. Most values cluster near zero.

Occasional outliers punctuate. Tail distributions become readable.

You have surveyed randomness across domains. The next map, Random Pheromone, turns random agents into collective order.
<<</MAP>>>

Add a label to each room.

```gdscript
func label_room(room: Node3D, key: String) -> void:
    var label := Label3D.new()
    label.text = "%s
%s" % [key, registry.rooms[key]]
    label.position = Vector3(0, 2.5, 0)
    room.add_child(label)
```

Each doorway announces the register within. The learner can skip or linger based on the label.
