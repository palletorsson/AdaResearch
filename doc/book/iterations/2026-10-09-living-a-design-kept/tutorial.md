# Living — a design kept

## Learning elements

- Design records and parameter ranges
- Rounding and clamping a requested value
- A generated rule and a generated body
- Independent retained specimens

Competition kept the instructions fixed while their conditions changed. Living lets us change the values from which instructions are made. You bring rewriting, a saved turtle state, the point in your hand, and the distinction between an editable record and its copy.

## Start with the existing sculptor

Press RESET, then HOLD. The editing tree now has a witness beside it. Depth starts at 4.000. Press MORE four times. The value reaches 4.800, but both trees still agree. One more press reaches 5.000: the editing tree adds a generation.

The generator halves Depth, rounds, then clamps the result between two and five. At 4.8 it reads 2.4 and selects two generations. At 5 it reads 2.5 and selects three. A changed input does not always make a changed instruction.

The black point on the front rail edits the selected gene through horizontal hand movement. Its held trigger performs HOLD. GENE selects another gene; PLANT keeps a floor specimen. Release before choosing another gene. The original sliders remain at the side. All act on the same editing design.

## Build a small version in the museum

Put these four files together and attach `living.gd` to an empty, unit-scale Node3D in a clear working bay of the prepared museum. The project already supplies the floor, camera, player and XRTools. Keep your existing `point_body.gd` and `line_skin.gd`; their copies below are unchanged. No prepared mesh or named scene child is needed.

The study makes three display positions: editing at (−2,0.78,−2.5), held at (2,0.78,−2.5), planted at (0,0.035,−8). Leave a clear bay around them and a bypass. In a working copy, the original sculptor can be hidden for comparison at its host; this does not require replacing the museum's primary artifact. The small drawing has no branch colliders and does not change the floor.

We keep three inputs: Depth, Forks and Angle. Arrange stays on the source's opposite-branch recipe; taper stays 0.7; the starting step is 1.2 metres. Leaves, roots, twist and droop stay off. The cylinders retain the line's familiar thickness rather than reconstructing the source's tapered bark. This is the same parameter-to-rule relation with a smaller presentation, not every feature of the sculptor.

### The design becomes instructions

In `design.gd`, `parameters()` converts the record to counts and an angle. `rules_for()` makes F become S followed by the requested forks. S becomes FF on the next rewrite. The opposite-branch recipe alternates + and −; later pairs also roll the turtle's frame. The slash is a roll instruction, not division in the sentence.

The rewrite function is unchanged from the earlier lessons. Its symbol budget is raised explicitly to 32,768 so this bounded three-gene range can be generated before the separate 200-command drawing limit is applied. These are different limits: one bounds sentence construction, the other bounds its display.

<!-- student-code:design.gd -->
```gdscript
extends RefCounted
const SYMBOL_LIMIT := 32768
const DRAW_LIMIT := 200

func parameters(record: Dictionary) -> Dictionary:
	return {"generations": clampi(roundi(float(record.depth) * 0.5), 2, 5),
		"forks": clampi(roundi(float(record.forks)), 2, 5),
		"angle": clampf(float(record.angle), 15, 90)}

func rules_for(forks: int) -> Dictionary:
	var replacement := "S"
	for i in forks:
		var turn := "+" if i % 2 == 0 else "-"
		replacement += "[" + turn + "/".repeat(i / 2) + "F]"
	return {"F": replacement, "S": "FF"}

func rewrite(sentence: String, rules: Dictionary) -> Dictionary:
	var size := 0
	for symbol in sentence:
		size += str(rules.get(symbol, symbol)).length()
		if size > SYMBOL_LIMIT:
			return {"accepted": false, "text": sentence}
	var next := ""
	for symbol in sentence:
		next += str(rules.get(symbol, symbol))
	return {"accepted": true, "text": next}

func build(record: Dictionary) -> Dictionary:
	var params := parameters(record)
	var rules := rules_for(params.forks)
	var sentence := "F"
	for generation in params.generations:
		var result := rewrite(sentence, rules)
		if not result.accepted:
			return {"accepted": false, "error": "Symbol budget refused this generation."}
		sentence = result.text
	var reading := read(sentence, params.angle)
	reading.merge({"accepted": true, "parameters": params, "sentence": sentence,
		"requested": sentence.count("F") + sentence.count("S")})
	return reading

func read(sentence: String, angle: float) -> Dictionary:
	# The bare, opposite-arranged subset of TreeMorphology's turtle.
	# Fixed inputs: step1.2m, taper.68, no droop, twist, leaves or roots.
	var state := {"pos": Vector3.ZERO, "dir": Vector3.UP,
		"right": Vector3.RIGHT, "up": Vector3.BACK, "length": 1.2}
	var stack: Array[Dictionary] = []
	var ends: Array[Vector3] = []
	var commands := 0
	var radians := deg_to_rad(angle)
	for symbol in sentence:
		if commands >= DRAW_LIMIT: break
		match symbol:
			"F", "S":
				var distance: float = state.length * (0.6 if symbol == "S" else 1.0)
				var finish: Vector3 = state.pos + state.dir * distance
				if distance >= 0.001:
					ends.append(state.pos); ends.append(finish)
				state.pos = finish
				if symbol == "F": state.length *= 0.68
				commands += 1
			"+", "-":
				var sign := 1.0 if symbol == "+" else -1.0
				state.dir = (state.dir * cos(radians) + state.right * sin(radians) * sign).normalized()
				state.right = state.dir.cross(state.up).normalized()
			"/":
				state.right = (state.right * cos(radians) + state.up * sin(radians)).normalized()
				state.up = state.right.cross(state.dir).normalized()
			"[": stack.append(state.duplicate(true))
			"]": state = stack.pop_back()
	return {"ends": ends, "drawn_commands": commands}
```

Read `parameters()` and `rules_for()` first. Those are the new connection between a design and its grammar. The reader continues the saved-state pattern. F advances and shortens the next step; S advances sixty percent of a step without shortening it. A bracket saves position, direction, orientation and current length. Returning restores them all.

This reader handles only sentences made by `rules_for()`. It is not a parser for arbitrary user text. Its added S and roll operations reproduce the bare, opposite-arranged subset of the museum turtle. They do not require a new general grammar language. The readout separates requested commands, commands read, and visible cylinders: a command can be counted even when its segment is too short to draw.

### Keep the record when the design changes

`living.gd` holds three records: the editable one and two optional copies. HOLD replaces the witness; PLANT replaces the floor specimen. Neither edits the other. RESET restores only the editing design.

`keep()` uses `duplicate(true)` to store a separate dictionary. This study rebuilds a specimen from its retained recipe whenever the display refreshes. The installed sculptor instead copies its built geometry and its larger DNA resource. Both preserve the design at the moment of the action. A reproducible record depends on the builder too: these records are recipes for this version of `design.gd`, not a promise that future algorithms will produce identical bodies.

<!-- student-code:living.gd -->
```gdscript
extends Node3D
const Design = preload("design.gd")
const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
const START := {"depth": 4.0, "forks": 2.0, "angle": 30.0}
const GENES := ["depth", "forks", "angle"]
const RANGES := [Vector2(2, 10), Vector2(1, 8), Vector2(15, 90)]
const PLACES := [Vector3(-2,.78,-2.5), Vector3(2,.78,-2.5), Vector3(0,.035,-8)]
var model = Design.new()
var editing: Dictionary = START.duplicate(true)
var held: Dictionary = {}
var planted: Dictionary = {}
var preview: Dictionary
var selected := 0
var drawing: Node3D
var readout: Label3D
var point: XRToolsPickable
var last_detent := -1

func _ready() -> void:
	readout = label("", Vector3(0,1.9,1.7))
	label("G: GENE   arrows: LESS / MORE\nH / HELD TRIGGER: HOLD   P: PLANT   R: RESET",Vector3(0,.92,2.75))
	point = PointBody.new(); add_child(point)
	point.action_pressed.connect(func(_body): keep("held"))
	refresh(); park()

func _physics_process(_dt: float) -> void:
	if point.held():
		var detent := clampi(roundi((to_local(point.global_position).x / .8 + .5) * 40), 0, 40)
		if last_detent == -1:
			last_detent = detent
			return
		if detent != last_detent:
			last_detent = detent
			set_normalized(detent / 40.0)
	else:
		last_detent = -1
		park()

func normalized() -> float:
	var span: Vector2 = RANGES[selected]
	return inverse_lerp(span.x, span.y, editing[GENES[selected]])

func park() -> void:
	point.global_transform = global_transform * Transform3D(Basis.IDENTITY, Vector3((normalized()-.5)*.8,1.18,2.55))

func set_normalized(value: float) -> void:
	var span: Vector2 = RANGES[selected]
	editing[GENES[selected]] = lerpf(span.x, span.y, clampf(value,0,1))
	refresh()

func keep(slot: String) -> void:
	# Retain the recipe, not a reference to the editable dictionary.
	var snapshot := editing.duplicate(true)
	if slot == "held": held = snapshot
	elif slot == "planted": planted = snapshot
	refresh()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.keycode:
		KEY_G: selected = (selected+1) % GENES.size(); refresh()
		KEY_LEFT: set_normalized(snappedf(normalized()-.025,.025))
		KEY_RIGHT: set_normalized(snappedf(normalized()+.025,.025))
		KEY_H: keep("held")
		KEY_P: keep("planted")
		KEY_R: editing = START.duplicate(true); selected = 0; refresh()

func refresh() -> void:
	preview = model.build(editing)
	if is_instance_valid(drawing): remove_child(drawing); drawing.queue_free()
	drawing = Node3D.new(); add_child(drawing)
	var records := [editing, held, planted]
	for i in 3:
		if records[i].is_empty(): continue
		var result: Dictionary = model.build(records[i])
		if not result.accepted: continue
		for j in range(0,result.ends.size(),2):
			var line = LineSkin.new(); drawing.add_child(line)
			var a: Vector3 = PLACES[i]+result.ends[j]
			var b: Vector3 = PLACES[i]+result.ends[j+1]
			line.show_segment(a,b-a,a.distance_to(b))
		var caption := label("%s / depth %.3f\n%d generations / %d commands" % [["EDITING","HELD","PLANTED"][i],records[i].depth,result.parameters.generations,result.requested],PLACES[i]+Vector3(0,-.15,.6))
		caption.reparent(drawing)
	if not preview.accepted: readout.text = preview.error; return
	readout.text = "%s %.3f / %d generations / %d forks\n%d requested / %d read / %d visible cylinders" % [GENES[selected],editing[GENES[selected]],preview.parameters.generations,preview.parameters.forks,preview.requested,preview.drawn_commands,preview.ends.size()/2]

func label(text: String, at: Vector3) -> Label3D:
	var tag := Label3D.new(); tag.text=text; tag.position=at
	tag.font_size=36; tag.pixel_size=.002; tag.outline_size=8; add_child(tag)
	return tag
```

G selects a gene; the arrow keys decrease or increase it on the same normalized 0.025 grid as the museum buttons. H holds, P plants, R resets. In VR, move the point along the rail and use its held trigger to keep a witness. Picking it up without moving leaves the value alone, including values between hand detents. Release parks it at the current setting. The small program rebuilds immediately; the museum waits 0.3 seconds after an edit and flushes that pending rebuild before HOLD or PLANT.

### Carry the known point and line

These two files are unchanged from Competition. The action connection and the design record give them their new job.

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

<!-- student-code:line_skin.gd -->
```gdscript
# Supplied renderer, adapted from commons/primitives/line/line.gd.
# This finite cylinder gives the segment a visible thickness. It is not a collider.
# Inputs share the parent station's local frame; that station has unit scale.
extends MeshInstance3D

func _init() -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.012
	cylinder.bottom_radius = 0.012
	cylinder.radial_segments = 16
	cylinder.rings = 0
	mesh = cylinder
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color(0.98, 0.70, 0.82)
	finish.roughness = 0.3
	material_override = finish
	visible = false

func show_segment(start: Vector3, displacement: Vector3, distance: float) -> void:
	# A zero-length segment has no direction. Do not normalize it.
	visible = distance > 0.0001
	if not visible:
		return
	(mesh as CylinderMesh).height = distance
	position = start + displacement * 0.5
	# CylinderMesh runs along local Y. This borrowed basis aligns it to the ends.
	var direction := displacement / distance
	var right := direction.cross(Vector3.UP).normalized()
	if right.length() < 0.001:
		right = Vector3.RIGHT
	var depth := right.cross(direction).normalized()
	basis = Basis(right, direction, depth)
```

## Make a prediction you can check

1. Hold the opening design. Increase Depth through 4.2,4.4,4.6,4.8. Confirm that the sentence and segment endpoints remain equal to the witness. At 5.0, confirm that the generation count and sentence change while the witness remains at 4.0.
2. Select Angle. Change it and predict which record changes: the sentence, the generation count, or the segment endpoints? Angle changes the interpretation; the sentence and its counts stay fixed.
3. Plant, then edit again. RESET must restore the opening editing design without changing either retained recipe. A later PLANT replaces only the planted recipe.
4. In the START dictionary, change only `"angle": 30.0` to `"angle": 45.0`. Run the complete edited program. Predict the same sentence and number of commands, but different endpoints. Hold this version, change its angle again, then rebuild directly from the held record to verify that the retained body returns.

These snapshots live in this running scene. The small program does not save to disk, export catalyst DNA or move its specimens into the next hall. The installed PLANT also exports an independent DNA resource for an older catalyst consumer, which can mutate and rescale it; that is a separate operation.

## Which changes remain unavailable?

At maximum Depth and Forks the source recipe requests 4,964 F/S commands. This study, like the installed preview at its current detail level, reads at most 200. A complete-looking tree may be a partial reading. Three controls also cannot request a branch reconnecting to an earlier branch, a new alphabet, or a body that remakes the floor. Those need another operation or another builder.

Keep the difference between raw values, compiled instructions and a displayed body. Next, Shape Grammars returns to the cube and makes its face operations available to a design record.
