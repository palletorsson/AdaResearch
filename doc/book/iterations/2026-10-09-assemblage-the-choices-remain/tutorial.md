# Assemblage — the choices remain

## Learning elements

- A recorded sample, a threshold decision and its mark
- Changing interpretation without drawing again
- An independent witness, including its alphabet
- A fixed-size row queue
- Perceived paths, addresses and physical support

In Curves, one sentence passed through different readers. Living kept a design while editing continued. Shape Grammars selected which faces could receive the next operation. Here the earlier two-mark textile returns: keep its choices and change what they draw.

## Begin with the installed comparison

Press RESET and HOLD at the existing desk. Follow a few diagonals. ALPHABET changes them into horizontal and vertical bars, then large and small blocks. Compare the same cells with the witness. Their decisions have not changed; their marks have.

Return to diagonals and press ODDS. At 0.75, more of the same samples can choose A than at 0.5. ALPHABET changes representation. ODDS changes decisions. SEED changes the samples. None of these operations asks whether your eye can find a path.

## Reconstruct that separation

Keep the prepared Endless Museum, camera, floor, player and XRTools. Put these three files together and attach `assemblage.gd` to a unit-scale Node3D in your working copy. The small study fits beside the installed desk at hall-local (3.2,0,7.5), yaw 180 degrees. Its two sheets and floor drawing are smaller than the installed comparison; both use the same 12×12 address order. They add no surface collision.

The familiar point changes ALPHABET when its held trigger is pressed. The keyboard also provides A: alphabet, O: odds, H: hold, Space: one row, N: next seed and R: reset. Pickup and hand movement alone do not edit the sheet. Other keyboard actions can first be tried through the museum's existing six buttons; the small program does not rebuild that console.

### Keep what the choice came from

`sheet.gd` holds twelve rows of twelve cells. Each cell stores a sample and a tint. The source draws both, in that order. Omitting the tint draw would shift all later samples, even if we did not care about the colour variation.

`choices()` compares each sample with the current threshold using strict `<`. It draws nothing. `glyph()` then maps the Boolean result to a size and angle; it also draws nothing. Changing either interpretation leaves the random generator at the same state.

The record's row zero is the oldest row, displayed at the bottom. STEP removes that row and appends one new row at the top. The eleven surviving rows keep their cell values. Their current row addresses change.

<!-- student-code:sheet.gd -->
```gdscript
extends RefCounted
const N := 12
const START_SEED := 1010
const ALPHABETS := ["diagonals", "orthogonals", "blocks"]
const ODDS := [0.5, 0.75, 1.0, 0.0, 0.25]
var rng := RandomNumberGenerator.new()
var data := {"seed":START_SEED, "odds":0.5, "alphabet":"diagonals", "rows":[]}

func _init() -> void:
	reset()

func new_row() -> Array:
	var row: Array=[]
	for c in N:
		# Keep both draws: the museum also draws a tint after each sample.
		var sample:=rng.randf()
		var tint:=rng.randf()
		row.append({"sample":sample, "tint":tint})
	return row

func new_sheet(seed_value: int) -> void:
	rng.seed=seed_value
	data.seed=seed_value
	data.rows=[]
	# Index zero is the oldest, bottom row.
	for r in N: data.rows.append(new_row())

func reset() -> void:
	data.odds=0.5; data.alphabet="diagonals"
	new_sheet(START_SEED)

func step() -> void:
	data.rows.pop_front()
	data.rows.append(new_row())

func keep() -> Dictionary:
	return data.duplicate(true)

static func choices(record: Dictionary) -> Array:
	var result: Array=[]
	for row in record.rows:
		var bits: Array=[]
		for cell in row: bits.append(cell.sample < record.odds)
		result.append(bits)
	return result

static func glyph(a: bool, alphabet: String) -> Dictionary:
	var width:=1.0/N
	if alphabet=="blocks":
		var amount:=0.9 if a else 0.3
		return {"size":Vector3(width*amount,0.07*amount,0.03), "angle":0.0}
	var angle: float=(PI/4 if a else -PI/4)
	if alphabet=="orthogonals": angle=0.0 if a else PI/2
	return {"size":Vector3(width*0.9,0.07*0.42,0.03), "angle":angle}
```

### Keep the witness's interpretation too

`keep()` copies the nested record, including rows, odds and alphabet. A copy of only the outer dictionary would still share its rows. A copy of only the samples would not say which marks the witness used.

The display begins with a witness. HOLD replaces it. Later changes and RESET affect only the editing record. Repainting both sheets reads their separate records. This is a local snapshot of a visible result: it does not save to disk or capture the random generator state for resuming the held sheet's future rows.

On the wall, row zero appears lowest. On the floor, the same row/column address receives a fixed position, with row zero at the far edge. This follows the installed floor mapping; it is not a rigid rotation of the whole wall image. Each mark turns onto the floor individually. No neighbouring cell is consulted and no route is computed.

<!-- student-code:assemblage.gd -->
```gdscript
extends Node3D
const Sheet = preload("sheet.gd")
const PointBody = preload("point_body.gd")
var model = Sheet.new()
var held: Dictionary={}
var drawing: Node3D
var label: Label3D
var point: XRToolsPickable

func _ready() -> void:
	drawing=Node3D.new(); add_child(drawing)
	label=Label3D.new(); label.position=Vector3(0,2.6,0.05)
	label.font_size=28; label.pixel_size=.0018; label.outline_size=8; add_child(label)
	point=PointBody.new(); point.position=Vector3(0,1.15,1.1); add_child(point)
	point.action_pressed.connect(func(_body): act("ALPHABET"))
	held=model.keep(); refresh()

func act(action: String) -> void:
	match action:
		"ALPHABET":
			var i: int=Sheet.ALPHABETS.find(model.data.alphabet)
			model.data.alphabet=Sheet.ALPHABETS[(i+1)%Sheet.ALPHABETS.size()]
		"ODDS":
			var i: int=Sheet.ODDS.find(model.data.odds)
			model.data.odds=Sheet.ODDS[(i+1)%Sheet.ODDS.size()]
		"HOLD": held=model.keep()
		"STEP": model.step()
		"SEED": model.new_sheet(int(model.data.seed)+1)
		"RESET": model.reset()
	refresh()

func refresh() -> void:
	for child in drawing.get_children(): drawing.remove_child(child); child.queue_free()
	draw_sheet(model.data,Vector3(-.85,1.8,0),false)
	draw_sheet(held,Vector3(.85,1.8,0),false)
	draw_sheet(model.data,Vector3(0,.035,-4),true)
	var count:=0
	for row in Sheet.choices(model.data):
		for a in row: if a: count+=1
	label.text="EDITING / %s / p %.2f / %d of 144 A\nHELD / %s / p %.2f\nA or held trigger: alphabet   O: odds   H: hold\nSpace: row   N: seed   R: reset" % [model.data.alphabet,model.data.odds,count,held.alphabet,held.odds]

func draw_sheet(record: Dictionary, at: Vector3, on_floor: bool) -> void:
	var panel:=Node3D.new(); panel.position=at; drawing.add_child(panel)
	var backing:=MeshInstance3D.new(); var board:=BoxMesh.new()
	board.size=Vector3(2.6,.012,2.6) if on_floor else Vector3(1.55,1.4,.04)
	backing.mesh=board
	backing.position=Vector3(0,-.02,0) if on_floor else Vector3(0,0,-.05)
	var dark:=StandardMaterial3D.new(); dark.albedo_color=Color("152a32")
	backing.material_override=dark; panel.add_child(backing)
	var bits: Array=Sheet.choices(record)
	for r in Sheet.N:
		for c in Sheet.N:
			var a: bool=bits[r][c]
			var shape: Dictionary=Sheet.glyph(a,record.alphabet)
			var mesh:=BoxMesh.new(); mesh.size=shape.size
			var mark:=MeshInstance3D.new(); mark.mesh=mesh
			var hue: float=(.07 if a else .58)+float(record.rows[r][c].tint)*.05
			var finish:=StandardMaterial3D.new(); finish.albedo_color=Color.from_hsv(hue,.6,.95)
			finish.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
			mark.material_override=finish; panel.add_child(mark)
			if on_floor:
				mark.position=Vector3((c-5.5)*.2,0,(r-5.5)*.2)
				mark.basis=Basis(Vector3.RIGHT,-PI/2)*Basis(Vector3.BACK,shape.angle)
				mark.scale=Vector3(2.4,2.4,.5)
			else:
				mark.position=Vector3((c-5.5)/Sheet.N,(r-5.5)*.07,0)*1.4
				mark.rotation.z=shape.angle; mark.scale=Vector3.ONE*1.4

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	var actions: Dictionary={KEY_A:"ALPHABET",KEY_O:"ODDS",KEY_H:"HOLD",KEY_SPACE:"STEP",KEY_N:"SEED",KEY_R:"RESET"}
	if actions.has(event.keycode): act(actions[event.keycode])

func _physics_process(_dt: float) -> void:
	if not point.held():
		point.global_transform=global_transform*Transform3D(Basis.IDENTITY,Vector3(0,1.15,1.1))
```

### Carry the point

Use the same PointBody from the preceding halls. Its action signal selects another alphabet. Release returns the point to the front of this study.

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

## Predict, then change the reader

1. HOLD the diagonal sheet, then cycle all three alphabets. Samples, decisions and A count should stay fixed. Returning to diagonals should recover the same marks and tints.
2. Change odds from 0.5 to 0.75. Only samples in `[0.5,0.75)` change from B to A. A half-threshold does not demand exactly 72 of the 144 cells. A sample exactly equal to the threshold is B.
3. STEP once. The old second row becomes row zero; the oldest row disappears. Twelve new samples and twelve new tints enter. The witness stays. RESET restores the opening editable sheet, but keeps the witness you most recently held.
4. In `glyph()`, change only the blocks line from `0.9 if a else 0.3` to `0.3 if a else 0.9`. Now A draws the small block. Predict unchanged samples, choices, count, colour and addresses, with the large and small sizes exchanged. Run the complete edited program and compare it with the original.

The same seed reproduces the same draw sequence in this Godot version and call order. For the result itself, keep the actual samples. A seed alone is not a promise of identical output across engine versions.

## Leave room for the other works

Walk across the floor marks. The museum supports you whichever way they lean. Turning them into walls would require collision geometry and an explicit definition and test of connectivity. A maze-like picture has not supplied those things.

The loom, credited pattern galleries, dragon bench and formal-limit objects remain separate encounters. This tutorial reconstructs the two-mark comparison; it does not turn a weaving draft into an L-system or a displayed sentence into a proof.

The sequence has moved from rewriting symbols to reading, building, selecting and retaining results. Here we end by separating what the program chose from the connections we saw. Procedural generation will add another decision: a score used to compare what was made.
