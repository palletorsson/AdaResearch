# Genetic Evolution — what the score reads

## Learning elements

- A candidate record and its visible body
- An evaluation function with a declared criterion
- Ranking without changing the candidates
- Stable identity and changing rank
- A held copy and an omitted feature

Living kept a design record. Shape Grammars built a family without ranking it. Assemblage separated a record from its interpretation. Here one reader builds a body and another assigns its score. Our new operation is evaluation: what does this particular function notice?

## Begin with the existing six

At the museum desk, press RESET. Choose a box you want to keep before reading its score. HOLD keeps the numerical leader, which may be different from your choice. TARGET changes 8 to 16. The six descriptions remain; their ranking changes. The generation is still zero.

At target 8, the scale-1 box leads. At target 16, the scale-1.25 box leads, with estimate 15.625 and score about 72.73. RING adds a visible loop without changing the score. The builder knows this part; the estimator omits it. RULE exposes that difference.

## Reconstruct the comparison

Keep the prepared Endless Museum, floor, camera, player and XRTools. Put these three files together; attach `selection.gd` to a unit-scale Node3D in your working copy. The small study fits in the gap after the large candidates at hall-local (9.5,0,16.8), yaw 180 degrees. It is a temporary learner installation. Its figures are miniatures at 0.38 scale; the data and estimates retain the original candidate units. They add no collision or support surface.

The familiar point's held trigger changes TARGET. Moving it alone edits nothing. Keyboard T changes target, G toggles the leader's ring, H holds the leader and R restores the opening candidates. The installed desk remains available for the same comparison and for STEP; this compact program does not reproduce offspring.

### Describe, evaluate, order

`evaluator.gd` starts with six independent records. An ID names a candidate within this comparison. Its genes describe shapes in local coordinates. Position, rotation and scale are the same fields we have used before.

`estimate()` deliberately reproduces the installed estimator, including its factor eight for boxes and absent torus. It sums contributions; it does not measure the union of overlapping solids. The extra sphere and cylinder branches show what else the source counts. Only boxes and rings enter our bounded reconstruction.

`score()` compares the estimate with a target. Absolute difference treats one above and one below alike. Dividing 100 by one plus that difference gives 100 for a match and 50 at distance one. The function returns a number; it neither constructs geometry nor edits a candidate.

`rank()` makes a new list of references and sorts that list. A shallow copy is enough here: sorting changes the list order, and the function does not mutate the records. For equal scores we choose the lower ID first; the installed kernel does not declare that tie-break. A saved witness needs a deep copy instead, because later edits can change its nested genes.

<!-- student-code:evaluator.gd -->
```gdscript
extends RefCounted
const TARGETS := [8.0, 16.0, 32.0]

static func opening() -> Array:
	var candidates: Array=[]
	for i in 6:
		var size: float=[0.7,1.0,1.25,1.5,1.75,2.0][i]
		candidates.append({"id":i,"genes":[{"type":"box",
			"position":Vector3(0,size/2,0),"rotation":Vector3.ZERO,"scale":Vector3.ONE*size}]})
	return candidates

static func estimate(candidate: Dictionary) -> float:
	var total:=0.0
	for gene in candidate.genes:
		var s: Vector3=gene.scale
		match gene.type:
			"sphere": total+=(4.0/3.0)*PI*s.x*s.y*s.z
			"box": total+=s.x*s.y*s.z*8.0
			"cylinder": total+=PI*s.x*s.z*s.y*2.0
	# This reproduces the museum's proxy, including its omitted torus.
	return total

static func score(candidate: Dictionary, target: float) -> float:
	return 100.0/(1.0+abs(estimate(candidate)-target))

static func rank(candidates: Array, target: float) -> Array:
	# Sort references in a NEW list. Do not reorder or edit the input list.
	var ordered: Array=candidates.duplicate()
	ordered.sort_custom(func(a,b):
		var sa: float=score(a,target);var sb: float=score(b,target)
		return a.id<b.id if sa==sb else sa>sb)
	return ordered

static func toggle_ring(candidate: Dictionary) -> void:
	for i in candidate.genes.size():
		if candidate.genes[i].type=="torus":
			candidate.genes.remove_at(i)
			return
	candidate.genes.append({"type":"torus","position":Vector3(0,1.8,0),
		"rotation":Vector3.ZERO,"scale":Vector3.ONE*1.4})
```

### Keep the bodies while their places change

`selection.gd` builds each candidate once and keeps its node in a dictionary keyed by ID. TARGET calls `arrange()`: the existing nodes move to rank positions and their captions change. It does not rebuild their meshes. The pink finish identifies the current leader; it contributes nothing to the score.

RING changes one genome, so only that body's geometry is rebuilt. HOLD deep-copies the leader and builds a separate witness. RESET restores the six candidates and target 8 but leaves that witness alone. IDs stay attached to our fixed candidates; a rank is a temporary position in an ordered list. The installed reproduction routine assigns new IDs each generation, so those IDs are not a record of ancestry.

Every new mesh, label, event and data operation is below. The museum supplies the surrounding world. The display scale is applied to each visual parent, outside the genome; changing it would change the miniature, not its score.

<!-- student-code:selection.gd -->
```gdscript
extends Node3D
const Evaluator=preload("evaluator.gd")
const PointBody=preload("point_body.gd")
const DISPLAY_SCALE:=0.38
var candidates: Array=[]
var bodies: Dictionary={}
var captions: Dictionary={}
var target_index:=0
var held: Dictionary={}
var witness: Node3D
var point
var title: Label3D

func _ready() -> void:
	title=label(Vector3(0,2.2,.4),"")
	point=PointBody.new();add_child(point)
	point.action_pressed.connect(func(_p):act("TARGET"))
	reset()
	act("HOLD")

func reset() -> void:
	for body in bodies.values():remove_child(body);body.queue_free()
	for caption in captions.values():remove_child(caption);caption.queue_free()
	bodies.clear();captions.clear();candidates=Evaluator.opening();target_index=0
	for candidate in candidates:
		bodies[candidate.id]=build(candidate)
		captions[candidate.id]=label(Vector3.ZERO,"")
	arrange()

func act(command: String) -> void:
	var ordered: Array=Evaluator.rank(candidates,Evaluator.TARGETS[target_index])
	match command:
		"TARGET":target_index=(target_index+1)%Evaluator.TARGETS.size()
		"RING":
			var candidate: Dictionary=ordered[0]
			Evaluator.toggle_ring(candidate)
			var old: Node3D=bodies[candidate.id];remove_child(old);old.queue_free()
			bodies[candidate.id]=build(candidate)
		"HOLD":
			held=ordered[0].duplicate(true)
			if is_instance_valid(witness):remove_child(witness);witness.queue_free()
			witness=build(held);witness.position=Vector3(-2.15,.6,.65)
		"RESET":reset()
	arrange()

func arrange() -> void:
	var target: float=Evaluator.TARGETS[target_index]
	var ordered: Array=Evaluator.rank(candidates,target)
	for rank_index in ordered.size():
		var candidate: Dictionary=ordered[rank_index]
		var at:=Vector3((rank_index%3-1)*1.15,.6,-floori(rank_index/3.0)*1.8)
		var body: Node3D=bodies[candidate.id];body.position=at
		for mesh in body.get_children():
			mesh.material_override.albedo_color=Color("dcaccb") if rank_index==0 else Color("82c4c8")
		var caption: Label3D=captions[candidate.id];caption.position=at+Vector3(0,-.15,.55)
		caption.text="ID %d / rank %d\nestimate %.3f / score %.2f" % [candidate.id,rank_index+1,Evaluator.estimate(candidate),Evaluator.score(candidate,target)]
	title.text="TARGET %.0f / same six candidates\nT or held trigger: target   G: ring   H: hold   R: reset\nMiniatures at 0.38 scale / held ID %s" % [target,str(held.get("id","none"))]

func build(candidate: Dictionary) -> Node3D:
	var body:=Node3D.new();add_child(body);body.scale=Vector3.ONE*DISPLAY_SCALE
	for gene in candidate.genes:
		var mesh: Mesh
		# Only these two primitive types enter this exercise.
		assert(gene.type in ["box","torus"])
		if gene.type=="box":
			var box:=BoxMesh.new();box.size=Vector3.ONE;mesh=box
		else:
			var ring:=TorusMesh.new();ring.inner_radius=.3;ring.outer_radius=.7;mesh=ring
		var surface:=MeshInstance3D.new();surface.mesh=mesh;body.add_child(surface)
		surface.position=gene.position;surface.rotation=gene.rotation;surface.scale=gene.scale
		var finish:=StandardMaterial3D.new();finish.albedo_color=Color("b7b2c7")
		finish.metallic=.3;finish.roughness=.7;surface.material_override=finish
	return body

func label(at: Vector3, text: String) -> Label3D:
	var result:=Label3D.new();result.position=at;result.text=text
	result.font_size=28;result.pixel_size=.002;result.outline_size=8
	add_child(result);return result

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:return
	var actions: Dictionary={KEY_T:"TARGET",KEY_G:"RING",KEY_H:"HOLD",KEY_R:"RESET"}
	if actions.has(event.keycode):act(actions[event.keycode])

func _physics_process(_dt: float) -> void:
	if not point.held():
		point.global_transform=global_transform*Transform3D(Basis.IDENTITY,Vector3(0,1.15,1.1))
```

### Carry the point

This is the unchanged point from the preceding halls. Its body, collision and pickup behaviour are already familiar. Here the connected action means TARGET. The host parks it after release; no new grab system is hidden in the example.

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

## Predict, then change one line

1. Start at target 8. ID 1 leads: its scale is 1, estimate 8, score 100. Press T. ID 2 now leads at target 16. Check that all six gene records and mesh instances are unchanged.
2. Hold that leader. Add its ring. The visible part count changes, but its estimate and score do not. Change target and reset: the held record stays independent.
3. In `estimate()`, change only the box contribution from `s.x*s.y*s.z*8.0` to `s.x*s.y*s.z`. Run the complete edited program from its opening. Which candidate should lead now?

The answer is ID 5, scale 2: its product is 8, matching target 8 for a score of 100. The original scale-1 box now estimates 1 and scores 12.5. No candidate needed new geometry for that reversal. Try target 16 too: all six corrected box estimates are below 16, so the largest still leads.

For these isolated unit boxes, the new term is their volume before display miniaturisation. It does not repair every estimate: spheres and cylinders still use their original coefficients, rings remain omitted, and overlapping contributions would still be added. Name the exact correction you made.

## Return to the installed generation

Leave the learner code and use the large desk. RESET, RING, then STEP. The source copies two elites and fills four places from parent tournaments, possible crossover and mutation. A tournament picks the best of three random draws with replacement. At the same target, elitism preserves a best score; it does not guarantee improvement. An elite can carry an uncounted ring onward. Survival does not show that every surviving feature earned points.

This reproduction kernel is supplied museum material in this lesson, not an unexplained call in your program. Its random offspring need not replay after RESET; 50 generations is its limit. Your reconstructed operation is the evaluator and comparison which reproduction uses. Building a different selection or mutation mechanism would be another lesson.

Walk to the retained raised deck. Its collision supports you; the generated candidates do not. A good score says nothing about whether you can stand on a body unless the representation and evaluator include that test. The separate science screen is not a live genome readout.

Carry the distinction between a generated description, its visible body and a chosen criterion. In Space Colonization, targets become spatial points: we will inspect which growing site responds and how its requested directions combine.
