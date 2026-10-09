# A rule kept

**Learning elements**

- Describe a construction with a seed, replacement rule and stopping condition.
- Pass named settings to a function; rebuild from the seed.
- Copy a recipe without linking its later edits to the original.
- Compare two results using the same scale.

## In the museum

The interval and block tree return in this last Fractals hall. Between their desks, a small black point controls a comparison table. Move it left, centre or right: each surviving interval keeps one quarter, one third or two fifths at **each end**. The middle is omitted. Both descendants are replaced again at the next cut.

The table starts with three cuts. Predict what changes before moving the point. Each choice still makes eight pieces, but their lengths and the gaps differ. KEEP, or the held trigger, holds your current recipe in the rose row. The dark row remains live. Change the fraction and compare. RESTORE returns the live row to what you kept. RESET returns only LIVE to thirds and three cuts. NEXT adds a cut, up to five; release the point before using NEXT, RESTORE or RESET.

This is a return to Cantor's replacement operation. The new work is to make its decisions explicit and keep one version while changing another. The table keeps one comparison during the current run. It does not save a file or send a drawing into another hall.

## Continue with the point and interval list

Use the prepared Endless Museum workspace. Save the two files below together and attach `recipe.gd` to an empty, unit-scale Node3D on its floor. The front is local +Z. Camera, light, player and installed XRTools are already supplied. PointBody is the unchanged small point from the preceding lessons; its complete file is included so the example has no missing dependency or named scene child.

The example makes its own point, two rows and labels. Move the point to choose a fraction; press its held trigger or Enter to keep. Run again to return to the initial recipe. The installed museum table uses this exact script with furniture and four nearby buttons; that adapter calls `advance()`, `keep_current()`, `restore()` and `reset_live()`. It ignores global Enter. You do not reconstruct the room or the block tree.

## Name what another call needs

The `recipe` dictionary groups three settings under names. `seed` is the familiar `Vector2(start, length)`, here `(0, 6)`. `fraction` says how much of each parent survives at each end. `steps` is the number of replacements. A dictionary packages these decisions; it does not prove they are valid. `build()` bounds the depth, and the replacement function requires a fraction strictly between zero and one half.

`replace_intervals()` makes a separate `next` array. For each parent it places one descendant at the original start and another at `start + length - size`. It never appends to the array it is reading. `build()` starts from the seed every time, replacing the current list once per step. Editing a setting therefore reconstructs the requested version rather than applying another cut to yesterday's result.

At three cuts, eight pieces survive. For quarters their combined length is 0.75 metres; for thirds it is about 1.778 metres; for two fifths it is 3.072 metres. The count alone cannot distinguish these constructions.

## Keep a recipe, reconstruct its result

`kept_recipe = recipe` would give two names to the same dictionary. A later edit through one name would reach the same object. `duplicate(true)` creates a separate copy. The fields used here are numbers and a Vector2; the deep-copy option also copies nested arrays or dictionaries if we add them later. It is not a universal copy of every possible resource.

KEEP copies the settings. `rebuild()` then constructs both lists independently. RESTORE also copies: after restoring, a new LIVE edit must leave KEPT alone. The rendered bars are disposable views; they are removed and drawn again without removing the point or changing the saved recipe.

Both rows use the same scale: one model metre represents 0.34 metres on this table. Neither row is stretched to fill the width. The readouts state the **model lengths**. A length written as six metres does not make this miniature six metres wide.

## Complete code

`recipe.gd` contains the replacement, copy, input and drawing. Its hand control offers the three declared fractions; the display is centred on the six-metre seed. Treat that framing as an explicit choice when developing another work.

<!-- student-code:recipe.gd -->
```gdscript
extends Node3D
const PointBody = preload("point_body.gd")
const FRACTIONS := [0.25, 1.0 / 3.0, 0.4]
const LIMIT := 5
const DISPLAY_SCALE := 0.34
var recipe := {"seed": Vector2(0, 6), "fraction": 1.0 / 3.0, "steps": 3}
var kept_recipe: Dictionary = {}
var live: Array[Vector2] = []
var kept: Array[Vector2] = []
var point: XRToolsPickable
var drawing: Node3D
var live_caption: Label3D
var kept_caption: Label3D

func _ready() -> void:
	drawing = Node3D.new()
	add_child(drawing)
	point = PointBody.new()
	add_child(point)
	point.action_pressed.connect(keep_current)
	live_caption = label("", Vector3(0, 1.40, 0))
	kept_caption = label("", Vector3(0, 1.79, 0))
	label("CHANGE ONE RULE / KEEP A COMPARISON", Vector3(0, 2.02, 0))
	for i in 3:
		label(["1/4", "1/3", "2/5"][i], Vector3((i - 1) * 0.35, 1.0, 0.55))
	kept_recipe = recipe.duplicate(true)
	rebuild()
	park()

func replace_intervals(intervals: Array[Vector2], fraction: float) -> Array[Vector2]:
	assert(fraction > 0.0 and fraction < 0.5)
	var next: Array[Vector2] = []
	for interval in intervals:
		var size := interval.y * fraction
		next.append(Vector2(interval.x, size))
		next.append(Vector2(interval.x + interval.y - size, size))
	return next

func build(settings: Dictionary) -> Array[Vector2]:
	assert(settings.steps >= 0 and settings.steps <= LIMIT)
	var intervals: Array[Vector2] = [settings.seed]
	for generation in range(settings.steps):
		intervals = replace_intervals(intervals, settings.fraction)
	return intervals

func rebuild() -> void:
	live = build(recipe)
	kept = build(kept_recipe)
	redraw()

func choose(index: int) -> void:
	var fraction: float = FRACTIONS[clampi(index, 0, 2)]
	if is_equal_approx(recipe.fraction, fraction):
		return
	recipe.fraction = fraction
	rebuild()

func keep_current(_body = null) -> void:
	kept_recipe = recipe.duplicate(true)
	rebuild()

func restore() -> void:
	if point.held():
		return
	recipe = kept_recipe.duplicate(true)
	rebuild()

func advance() -> void:
	if point.held():
		return
	recipe.steps = mini(recipe.steps + 1, LIMIT)
	rebuild()

func reset_live() -> void:
	if point.held():
		return
	recipe = {"seed": Vector2(0, 6), "fraction": 1.0 / 3.0, "steps": 3}
	rebuild()

func _physics_process(_dt: float) -> void:
	if point.held():
		var local := to_local(point.global_position)
		choose(clampi(roundi(local.x / 0.35) + 1, 0, 2))
	else:
		park()

func park() -> void:
	var index: int = FRACTIONS.find(recipe.fraction)
	var home := Vector3((index - 1) * 0.35, 1.15, 0.55)
	point.global_transform = global_transform * Transform3D(Basis.IDENTITY, home)

func _process(_dt: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		keep_current()

func total(intervals: Array[Vector2]) -> float:
	var length := 0.0
	for interval in intervals:
		length += interval.y
	return length

func redraw() -> void:
	for child in drawing.get_children():
		drawing.remove_child(child)
		child.queue_free()
	draw_row(live, 1.27, Color("28252c"))
	draw_row(kept, 1.66, Color("e99db8"))
	live_caption.text = describe("LIVE", recipe, live)
	kept_caption.text = describe("KEPT", kept_recipe, kept)

func describe(title: String, settings: Dictionary, intervals: Array[Vector2]) -> String:
	return "%s / %d cuts / %.1f%% at each end / %d pieces / %.3f m" % [title, settings.steps, settings.fraction * 100, intervals.size(), total(intervals)]

func draw_row(intervals: Array[Vector2], y: float, colour: Color) -> void:
	for interval in intervals:
		var surface := MeshInstance3D.new()
		var shape := BoxMesh.new()
		shape.size = Vector3(interval.y * DISPLAY_SCALE, 0.045, 0.06)
		surface.mesh = shape
		surface.position = Vector3((interval.x + interval.y * 0.5 - 3) * DISPLAY_SCALE, y, 0)
		var finish := StandardMaterial3D.new()
		finish.albedo_color = colour
		surface.material_override = finish
		drawing.add_child(surface)

func label(text: String, at: Vector3) -> Label3D:
	var tag := Label3D.new()
	tag.text = text
	tag.position = at
	tag.font_size = 36
	tag.pixel_size = 0.0016
	tag.outline_size = 7
	add_child(tag)
	return tag
```

`point_body.gd` is carried unchanged. It supplies the sphere and collision shape, XRTools pickup and the museum's desktop-held query.

<!-- student-code:point_body.gd -->
```gdscript
extends XRToolsPickable
## Point Lines' frozen point construction, made smaller for the hand model.
var tint := Color("25212a")
var desktop_pointer: WeakRef

func _init() -> void:
	freeze = true
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	release_mode = XRToolsPickable.ReleaseMode.FROZEN
	ranged_grab_method = XRToolsPickable.RangedMethod.NONE
	collision_layer = 4
	collision_mask = 0
	var surface := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.085
	sphere.height = 0.17
	sphere.radial_segments = 24
	sphere.rings = 12
	surface.mesh = sphere
	add_child(surface)
	var boundary := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.085
	boundary.shape = shape
	add_child(boundary)

func _ready() -> void:
	super._ready()
	var finish := StandardMaterial3D.new()
	finish.albedo_color = tint
	finish.roughness = 0.24
	get_child(0).material_override = finish

func held() -> bool:
	return is_picked_up() or (desktop_pointer != null and desktop_pointer.get_ref() != null)

func on_desktop_grab(pointer: Node) -> void:
	desktop_pointer = weakref(pointer)

func on_desktop_drop(_pointer: Node) -> void:
	desktop_pointer = null
```

## Make another version

First KEEP the initial thirds recipe. Move the point to quarters. LIVE should retain eight pieces totalling 0.75 metres; KEPT should still show the thirds. RESTORE should recover the initial result. Explain why another edit after RESTORE must not change KEPT.

For an independent code change, change only the initial `recipe` declaration to four steps. Leave the six-metre seed, fraction and drawing untouched. Before running, predict sixteen pieces and a combined length of `6 * (2 / 3)^4`, about 1.185 metres. The supplied automated check executes that edited script as well as the printed version. It checks the calculation; your explanation is still part of the exercise.

## What goes into the next room

At the large interval desk, HISTORY and GHOST change what can be inspected without changing which intervals survive. At the tree, FORM, STRATA, REACH and ENDS give different readings of the same branches. At this table, changing the retained fraction changes the generated intervals themselves. State which kind of change you made.

Carry the **thirds rule** into the next grammar laboratory. Its Cantor preset rewrites `F` as `FfF` and `f` as `fff`: uppercase draws a step, lowercase advances without drawing. After the same number of rewrites, that reading gives the same relative intervals. The lab fits its drawing to its display; compare normalized positions, not its apparent size. Quarters and two fifths are different recipes and do not follow from those same two rewrite rules.

We will build the general rewriting process there. Here, finish by naming the seed, operation, stop and display choices clearly enough that another reader could reconstruct your version.
