# Shape Grammars — a face continues

## Learning elements

- Seed-face indices and descendant tags
- Inset towards a centroid
- Extrusion along a face normal
- Selecting once, then replacing in reverse index order
- A saved recipe, repeated operations and their limits

Living separated a design record from the instructions and body made from it. Here the cube returns. We change its face list directly. The point, coordinates, triangles, arrays and loops are already ours; the new question is which faces receive the next operation.

We now extend the sequence beyond L-systems. The earlier rules replaced symbols; these rules replace selected mesh faces. Keep the distinction between choosing what receives an operation and constructing its replacement. The same questions remain useful with a different representation.

## Read the six existing specimens

Start at 01. The top looks square, but the diagonal separates two triangles. At 02, each triangle has drawn towards its own centre. At 03, those smaller triangles have risen 0.4 metres; walls connect them to the edges they left. These are two tips, not one square lid.

At 04, the same pair of operations has run three times. Only the new tips continue. The mint shoulders stay behind. Specimen 05 uses a smaller inset amount. Specimen 06 changes the initial selection from the top pair to all twelve triangles. The museum keeps all six forms so that you can walk back and compare them. They are fixed constructions, not a growing simulation.

## Reconstruct the operation

Put these three files together. Attach `family.gd` to an empty, unit-scale Node3D in your working copy of the prepared museum. A clear bay between the two collections is available at hall-local (10.5,0,21.5), rotated 180 degrees around Y. Keep the existing camera, floor, player and XRTools. The example creates its mesh, readout and familiar point in code. It displays one recipe at a time; the gallery retains the comparisons nearby. The example's surface and edge overlay have no colliders. Its lowest point sits 0.56 metres above the floor, matching the gallery's display height, without adding another plinth.

### The seed and its descendants

`faces.gd` starts with eight cube positions and twelve index triples, as in Primitives. This is the vertex order used by the museum's cube factory. Seed faces 8 and 9 are the upward pair. An index tells us where a record is now; it is not a permanent identity.

Before reading the construction code, follow only the selection:

1. At the cube, choose the two top faces, indices 8 and 9. Both receive the tag `growing`.
2. After inset, find the two smaller pink triangles. They receive that tag; their mint borders do not.
3. Predict the next operation's selection: the two pink tips. Their old list addresses are no longer the way to find them.

`growing` is an eligibility label shared by several faces, not a unique identity for each face. Read the tag check in `operate()` before the corner calculations. It collects the selected indices once, before any replacement.

Why process them backwards? Imagine a list A, B, C, D, E. B and D occupy indices 1 and 3. Removing B first moves D to index 2; the old index 3 now names E. Removing D first leaves B at index 1. Descending index order protects this pass's selection. Giving the new tip its tag prepares the next pass. These are two different jobs.

### Two ways to place three new corners

Inset averages the three corners to find their centroid. Each corner moves a fraction of the way towards it. Extrusion moves each corner along the face's outward normal. Both replace one triangle with seven: one new tip and two triangles along each of its three edges. Each successful replacement therefore adds six face records.

The extrusion keeps the museum's checks for tiny or very elongated triangles. The small builder accepts zero to three rounds and distinct seed indices. It retains the input recipe independently. It does not implement the factory's other metadata, zone inheritance or arbitrary mesh operations.

<!-- student-code:faces.gd -->
```gdscript
extends RefCounted
const VERTICES := [Vector3(-.5,-.5,.5),Vector3(.5,-.5,.5),Vector3(.5,.5,.5),Vector3(-.5,.5,.5),
	Vector3(-.5,-.5,-.5),Vector3(.5,-.5,-.5),Vector3(.5,.5,-.5),Vector3(-.5,.5,-.5)]
const FACES := [[0,1,2],[0,2,3],[5,4,7],[5,7,6],[4,0,3],[4,3,7],
	[1,5,6],[1,6,2],[3,2,6],[3,6,7],[4,5,1],[4,1,0]]

func build(recipe: Dictionary) -> Dictionary:
	if recipe.rounds < 0 or recipe.rounds > 3:
		return {"accepted":false,"error":"Use zero to three rounds."}
	var chosen: Array = recipe.faces
	for id in chosen:
		if not id is int or id < 0 or id >= 12 or chosen.count(id) != 1:
			return {"accepted":false,"error":"Use distinct seed-face indices from zero to eleven."}
	var mesh := {"vertices":PackedVector3Array(VERTICES),"faces":[],"tags":[],
		"accepted":true,"recipe":recipe.duplicate(true)}
	for i in FACES.size():
		mesh.faces.append(PackedInt32Array(FACES[i]))
		mesh.tags.append("growing" if chosen.has(i) else "seed")
	if recipe.get("inset_only",false): operate(mesh,true,recipe.amount)
	for round in int(recipe.rounds):
		operate(mesh,true,recipe.amount)
		operate(mesh,false,recipe.amount)
	return mesh

func operate(mesh: Dictionary, inset: bool, amount: float) -> void:
	# Select once per operation, before removing any faces.
	var selected: Array[int] = []
	for i in mesh.faces.size():
		if mesh.tags[i] == "growing": selected.append(i)
	selected.reverse()
	for id in selected:
		var face: PackedInt32Array = mesh.faces[id]
		var a: Vector3 = mesh.vertices[face[0]]
		var b: Vector3 = mesh.vertices[face[1]]
		var c: Vector3 = mesh.vertices[face[2]]
		var centre := (a+b+c)/3.0
		var normal := (b-a).cross(c-a)
		if not inset:
			var shortest := minf(a.distance_to(b),minf(b.distance_to(c),c.distance_to(a)))
			var longest := maxf(a.distance_to(b),maxf(b.distance_to(c),c.distance_to(a)))
			# Match the museum's area/aspect guards before extrusion.
			if normal.length()*.5 < .001 or shortest/longest < .05: continue
		var tips: Array[int] = []
		for p in [a,b,c]:
			tips.append(mesh.vertices.size())
			var at: Vector3 = p.lerp(centre,clampf(amount,.01,.99)) if inset else p+normal.normalized()*.4
			mesh.vertices.append(at)
		mesh.faces.remove_at(id); mesh.tags.remove_at(id)
		add_face(mesh,tips,"growing")
		for j in 3:
			var k := (j+1)%3
			var role := "shoulder" if inset else "wall"
			add_face(mesh,[face[j],face[k],tips[k]],role)
			add_face(mesh,[face[j],tips[k],tips[j]],role)

func add_face(mesh: Dictionary, indices: Array, tag: String) -> void:
	mesh.faces.append(PackedInt32Array(indices)); mesh.tags.append(tag)

func surface(mesh: Dictionary) -> ArrayMesh:
	var builder := SurfaceTool.new(); builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in mesh.faces.size():
		var face: PackedInt32Array = mesh.faces[i]
		var a: Vector3 = mesh.vertices[face[0]]
		var b: Vector3 = mesh.vertices[face[1]]
		var c: Vector3 = mesh.vertices[face[2]]
		var normal := (b-a).cross(c-a)
		if normal.length_squared() < 1e-10: continue
		var colour := Color("ddd9ce")
		if mesh.tags[i] == "growing": colour=Color("ea749a")
		elif mesh.tags[i] == "shoulder": colour=Color("84c9be")
		builder.set_normal(normal.normalized()); builder.set_color(colour)
		for p in [a,b,c]: builder.add_vertex(p)
	return builder.commit()
```

The surface builder reads each index triple as three positions. The cross product supplies the same normal used by extrusion. Pink marks `growing`, mint marks `shoulder`, and pale faces include the original body and extrusion walls. The material below shows both sides, like the installed family; two-sided rendering is not a test of watertightness. The thin dark overlay makes the triangle edges visible without changing the faces.

### A recipe you can return to

`family.gd` names the same six comparisons as the gallery. Every selection rebuilds from the cube, so changing the displayed recipe does not accidentally operate on the last result. The inset-only recipe isolates the first operation. The next adds extrusion; the fourth repeats the pair three times. A held trigger or Space advances to the next recipe. R returns to the first. Moving the point does not move vertices or change a recipe; release parks it again.

<!-- student-code:family.gd -->
```gdscript
extends Node3D
const Faces = preload("faces.gd")
const PointBody = preload("point_body.gd")
const RECIPES := [
	{"title":"01 CUBE","faces":[8,9],"rounds":0,"amount":.28},
	{"title":"02 INSET","faces":[8,9],"rounds":0,"amount":.28,"inset_only":true},
	{"title":"03 EXTRUDE","faces":[8,9],"rounds":1,"amount":.28},
	{"title":"04 REPEAT","faces":[8,9],"rounds":3,"amount":.28},
	{"title":"05 WIDER","faces":[8,9],"rounds":3,"amount":.08},
	{"title":"06 ALL","faces":[0,1,2,3,4,5,6,7,8,9,10,11],"rounds":3,"amount":.28}
]
var model = Faces.new()
var index := 0
var record: Dictionary
var body: MeshInstance3D
var wire: MeshInstance3D
var label: Label3D
var point: XRToolsPickable

func _ready() -> void:
	body=MeshInstance3D.new(); add_child(body)
	var finish:=StandardMaterial3D.new(); finish.vertex_color_use_as_albedo=true
	finish.cull_mode=BaseMaterial3D.CULL_DISABLED; finish.roughness=.56
	body.material_override=finish
	wire=MeshInstance3D.new(); body.add_child(wire)
	var ink:=StandardMaterial3D.new(); ink.albedo_color=Color("252d40")
	ink.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED; wire.material_override=ink
	wire.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	label=Label3D.new(); label.position=Vector3(0,1.7,2.8)
	label.font_size=32; label.pixel_size=.0015; label.outline_size=8; add_child(label)
	point=PointBody.new(); point.position=Vector3(0,1.15,2.2); add_child(point)
	point.action_pressed.connect(func(_body): advance())
	show_recipe(0)

func show_recipe(which: int) -> void:
	index=clampi(which,0,RECIPES.size()-1)
	record=model.build(RECIPES[index])
	if not record.accepted: label.text=record.error; return
	body.mesh=model.surface(record)
	var low: float=record.vertices[0].y
	for p in record.vertices: low=minf(low,p.y)
	# Keep metre scale; place the lowest point at the same height as the gallery.
	body.position.y=.56-low
	var lines:=ImmediateMesh.new(); lines.surface_begin(Mesh.PRIMITIVE_LINES)
	for face in record.faces:
		for j in 3:
			lines.surface_add_vertex(record.vertices[face[j]])
			lines.surface_add_vertex(record.vertices[face[(j+1)%3]])
	lines.surface_end(); wire.mesh=lines
	label.text="%s / %d faces / %d growing\nSpace or held trigger: next   R: first" % [RECIPES[index].title,record.faces.size(),record.tags.count("growing")]

func advance() -> void:
	show_recipe((index+1)%RECIPES.size())

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode==KEY_SPACE: advance()
	elif event.keycode==KEY_R: show_recipe(0)

func _physics_process(_dt: float) -> void:
	if not point.held():
		point.global_transform=global_transform*Transform3D(Basis.IDENTITY,Vector3(0,1.15,2.2))
```

### Keep the same point

Use the point from Living unchanged. It supplies pickup, release and the held action signal. That interaction does not need another sphere construction or a new grab system.

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

## Predict, then inspect

1. The cube has 12 faces. Insetting two selected triangles replaces each with seven: predict 24 faces. Adding one extrusion on the two new tips gives 36. Confirm these counts at the readout.
2. Three inset/extrude rounds on those two tips give 84 faces. There are still only two `growing` records. Why do the shoulders not begin growing too?
3. Compare recipes 04 and 05. Both take three steps of 0.4 metres. Their top height is the same, but their tip widths differ. With inset 28%, each tip's linear dimensions shrink by 0.72 per round. Its area shrinks by the square of that factor.
4. Change only recipe 04's `"faces":[8,9]` to `"faces":[8]`. Predict one projection, one continuing tip and 48 total faces after three rounds. Run the complete edited program. The other top triangle stays at the seed height. Return to recipe 01, then 04: the edited recipe should reconstruct the same result.

The selected index list belongs to the seed. The `growing` tag carries selection through replacement. This is the useful lineage: a face gives way to a new face without making every surface eligible for the next step.

## What needs another operation?

At the extreme inset value 0.99, the tip can become too small for the extrusion guard. A requested round need not produce another 0.4-metre rise. Counts describe what ran, not only what was requested. Our tested three-round gallery recipes stay above that guard.

Further on, the petal study and the large canopy add a different builder. More inset/extrude rounds alone do not create those curved strips, a hole through the cube or a bridge joining its tips. Keep those companion works available to reflection without adding their full construction to this lesson.

The current rule acts on faces. Next, Assemblage returns to a field of separate marks and asks what connections we perceive between results the rule made independently.
