# Procedural Generation — complete tutorial

Seven halls in canonical spine order. Current source texts collected on 9 October 2026. See REVIEW.md and evidence.html for the scope of the checks.


---

<!-- hall: PG_Genetic_Evolution -->

# Genetic Evolution — what the score reads

## Learning elements

- A candidate record and its visible body
- An evaluation function with a declared criterion
- Ranking without changing the candidates
- Stable identity and changing rank
- A held copy and an omitted feature

Living kept a design record. Shape Grammars built a family without ranking it. Assemblage separated a record from its interpretation. Here one reader builds a body and another assigns its score. Our new operation is evaluation: what does this particular function notice?

## A practice for the next seven halls

L-systems separated a description from the reader that made it visible. Here we ask what further operations allow: which body is selected, which site can answer, which cells connect, and what a reconstructed surface keeps. In each hall, preserve an input or witness, change a declared decision and compare the consequence. Say what was retained; a geometric specimen, a repeated seed and a saved simulation are different things. The tutorial rebuilds one selected operation inside the existing museum.

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

## Keep, change, compare

Keep the six candidate descriptions. Change the target before changing any genes. Compare which ID leads, then name a feature the score does not read. A held leader is a separate witness; ranking alone does not save your preferred candidate.


---

<!-- hall: PG_Space_Colonization -->

# Space Colonization — who can answer

## Learning elements

- Assign a request to its nearest eligible site
- Sum unit directions, then take a fixed-length step
- Store a branch as a position and a parent index
- Compare growing tips with all existing sites
- Keep a specimen while changing a rule

Genetic Evolution changed a score while keeping the candidates. Here we keep a set of positions and change which sites may answer them. The vectors return from Forces; the parent and child return from recursive trees. We will build a small version of the growth already in this hall.

## Predict one step

At the existing desk, press RESET. Three pink requests wait above the root: (−2, 3, 0), (2, 3, 0) and (0, 5, 0). Each contributes a direction of length one. The sideways components cancel; the upward components add. Predict the first child, then press STEP. It appears at (0, 0.5, 0). The root stays where it was.

Press FIELD once for eight known points. Under TIPS, each growing end is replaced by its successor. Starting with one root, this makes a strand. HOLD a specimen, then press POLICY. The field restarts under NETWORK. Older sites may now receive requests again, so one site can acquire several children across generations. Each site still adds at most one child in a generation.

These attraction points are coordinates. They exert no physics force. NETWORK names a control; each child still has one parent, so this construction does not join branches into loops.

## The complete small study

Keep the prepared Endless Museum and its player, floor, camera and XRTools. Save these three files together. Attach `colony.gd` to an empty, unit-scale Node3D in your working copy. A temporary study fits behind the main display at hall-local (9.5, 0, 17), facing the entrance with yaw 180 degrees. The branch model is displayed at 0.4 scale; its numerical half-metre step appears as 0.2 metres. No new branch collisions or floor are supplied.

Use the familiar point's held trigger, or SPACE, to advance one generation. Moving the point alone changes nothing. F switches between three and eight requests. P changes eligibility and restarts the same field. H keeps the current branch geometry. R restores the three-point opening and TIPS; the held specimen remains. The installed desk's 96-point canopy stays available as a larger comparison.

### Follow one site's decision

Begin with the three-request opening and one root. Read one generation in this order:

1. `eligible()` supplies the sites allowed to answer. Here there is only the root.
2. In `decision()`, each request chooses its nearest eligible site inside the influence radius. All three choose that root. With several sites, they need not choose the same one.
3. The root receives three unit directions. Their sideways components cancel. The remaining sum points upward.
4. `step()` normalizes that sum and multiplies it by 0.5. It records one child at (0, 0.5, 0), with parent index 0, then appends it after this generation's decisions.

The two normalizations have different jobs: equalise each request's contribution, then give the resulting step its direction before assigning a length. Find those two lines in the complete code below. Predict this one child before using a larger field.

### A position remembers its parent

Each entry in `nodes` stores a position and a parent index. The root uses −1 because it has no parent. New entries are appended, so older indices remain valid. Following those indices recovers the branches without storing cyclic object references.

`eligible()` returns every site under NETWORK. Under TIPS it returns only sites that no existing entry names as a parent. The supporting nearest-site search is included in full: each active point chooses one eligible site strictly nearer than eight metres. Equal distances keep the first site in list order. A request within 0.32 metres of that chosen site is marked for removal.

The new operation is inside `decision()`. Subtract the site from the request, normalize that vector, then add it to the site's sum. Normalizing each request gives it a unit contribution; a faraway point gets no extra length. Normalizing the accumulated sum afterwards gives the direction of the next half-metre step.

All assignments read the same generation. `step()` collects children separately and appends them after the decisions, so a newborn site cannot attract another request during its own generation. Reached requests leave `active`; `points` keeps the original field for the dark witnesses.

<!-- student-code:growth.gd -->
```gdscript
extends RefCounted

const STEP := 0.5
const REACH := 8.0
const KILL := 0.32
var nodes: Array = []
var points: Array = []
var active: Array = []
var network := false
var generation := 0
var reason := ""

static func field(wide: bool) -> Array:
	if not wide:
		return [Vector3(-2,3,0), Vector3(2,3,0), Vector3(0,5,0)]
	return [Vector3(-2,1.5,0), Vector3(-2.5,2.5,0.4), Vector3(-3,3.5,0),
		Vector3(1.5,2.5,0), Vector3(2,3.5,-0.5), Vector3(2.5,4.5,0),
		Vector3(0,5.5,1), Vector3(0,6,0)]

func reset(wide: bool) -> void:
	nodes = [{"position":Vector3.ZERO, "parent":-1}]
	points = field(wide)
	active = points.duplicate()
	generation = 0
	reason = ""

func eligible() -> Array:
	var result: Array = []
	for i in nodes.size():
		if network or not nodes.any(func(n): return n.parent == i): result.append(i)
	return result

func decision() -> Dictionary:
	var sites: Array = eligible()
	var sums: Dictionary = {}
	for i in sites: sums[i] = Vector3.ZERO
	var remove: Array = []
	var votes: Array = []
	for p in active:
		var nearest := -1
		var distance := REACH
		for i in sites:
			var d: float = p.distance_to(nodes[i].position)
			if d < distance:
				distance = d
				nearest = i
		if nearest < 0: continue
		if distance <= KILL:
			remove.append(p)
		else:
			var direction: Vector3 = (p - nodes[nearest].position).normalized()
			sums[nearest] += direction
			votes.append({"point":p, "site":nearest, "direction":direction})
	return {"sums":sums, "remove":remove, "votes":votes}

func step() -> bool:
	if generation >= 60 or nodes.size() >= 192:
		reason = "budget"
		return false
	var d: Dictionary = decision()
	for p in d.remove: active.erase(p)
	var additions: Array = []
	for i in d.sums:
		var sum: Vector3 = d.sums[i]
		if sum.length_squared() < 0.00000001: continue
		var next: Vector3 = nodes[i].position + sum.normalized() * STEP
		if network and (nodes.any(func(n): return n.position.distance_squared_to(next) < 0.00000001)
			or additions.any(func(n): return n.position.distance_squared_to(next) < 0.00000001)): continue
		if nodes.size() + additions.size() >= 192: break
		additions.append({"position":next, "parent":i})
	nodes.append_array(additions)
	generation += 1
	reason = "" if not additions.is_empty() else ("targets reached" if active.is_empty() else "no new direction")
	return not additions.is_empty()
```

The two normalizations do different jobs: one controls each contribution, the other fixes the final step length. No contribution, or an exactly cancelling sum, yields no child in this small program. NETWORK also skips a proposed position already occupied or already proposed in this generation.

This is a declared edge in the reconstruction: the installed TIPS code can append a zero-length child when nonzero requests cancel exactly. Here we stop that site instead. The installed NETWORK code already rejects cancellation. We retain the museum code and test this difference explicitly; we do not hide it under an identical tree silhouette.

The limits are 192 sites and 60 generations. Reaching a limit does not mean every request has been reached. The readout distinguishes a budget from exhausted requests or a lack of new direction.

### Give the decisions a body

The following file joins the model to the museum. It draws a sphere at each request and a thin cylinder between each parent and child. Those construction helpers reuse our earlier geometry. They are here so the example runs; they are not another lesson in making a sphere.

For the first site with a nonzero sum, thin pink rods show the requests, gold rods show their contributions, and white shows the proposed step. The preview is calculated from the current state: after STEP it shows the next decision. HOLD makes a deep copy of positions and parent indices. The smaller witness is 0.6 times the live display scale. It preserves geometry, not the full field, policy or a resumable simulation state.

<!-- student-code:colony.gd -->
```gdscript
extends Node3D
const Growth = preload("growth.gd")
const Point = preload("point_body.gd")
const DISPLAY := 0.4
var model = Growth.new()
var point
var live: Node3D
var witness: Node3D
var caption: Label3D
var held: Array = []
var wide := false

func _ready() -> void:
	caption = label("", Vector3(0,2.85,0))
	point = Point.new()
	add_child(point)
	point.action_pressed.connect(func(_p): act("STEP"))
	act("RESET")

func _physics_process(_delta: float) -> void:
	if not point.held():
		point.global_transform = global_transform * Transform3D(Basis.IDENTITY, Vector3(0,1.1,0.8))

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE: act("STEP")
			KEY_F: act("FIELD")
			KEY_P: act("POLICY")
			KEY_H: act("HOLD")
			KEY_R: act("RESET")

func act(action: String) -> void:
	match action:
		"STEP": model.step()
		"FIELD": wide = not wide; model.reset(wide)
		"POLICY": model.network = not model.network; model.reset(wide)
		"RESET": wide = false; model.network = false; model.reset(wide)
		"HOLD":
			held = model.nodes.duplicate(true)
			if is_instance_valid(witness): witness.free()
			witness = display(Vector3(-2,0.4,0), DISPLAY * 0.6)
			draw_record(held, witness, Color("c3b9df"))
	refresh()

func refresh() -> void:
	if is_instance_valid(live): live.free()
	live = display(Vector3(0,0.35,0), DISPLAY)
	draw_record(model.nodes, live, Color("8fd2c6"))
	for p in model.points:
		var is_active: bool = p in model.active
		sphere(p, 0.1 if is_active else 0.055, Color("efb2d1") if is_active else Color("586270"), live)
	var d: Dictionary = model.decision()
	var chosen := -1
	for i in d.sums:
		if d.sums[i].length_squared() > 0.00000001: chosen = i; break
	if chosen >= 0:
		var start: Vector3 = model.nodes[chosen].position
		for vote in d.votes:
			if vote.site == chosen:
				rod(start, vote.point, 0.012, Color("946678"), live)
				rod(start, start + vote.direction, 0.035, Color("f1d57b"), live)
		rod(start, start + d.sums[chosen].normalized() * Growth.STEP, 0.055, Color.WHITE, live)
	caption.text = "%s / %d sites / %d requests / step %d\nSPACE or held trigger: step | F: field | P: policy\nH: hold | R: reset | %s" % ["NETWORK" if model.network else "TIPS", model.nodes.size(), model.active.size(), model.generation, model.reason]

func display(at: Vector3, factor: float) -> Node3D:
	var node := Node3D.new()
	add_child(node)
	node.position = at
	node.scale = Vector3.ONE * factor
	return node

func draw_record(rows: Array, host: Node3D, colour: Color) -> void:
	sphere(Vector3.ZERO, 0.13, colour, host)
	for row in rows:
		if row.parent >= 0: rod(rows[row.parent].position, row.position, 0.045, colour, host)

func mesh(shape: Mesh, at: Vector3, colour: Color, host: Node3D) -> MeshInstance3D:
	var body := MeshInstance3D.new()
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.7
	body.mesh = shape
	body.material_override = material
	body.position = at
	host.add_child(body)
	return body

func sphere(at: Vector3, radius: float, colour: Color, host: Node3D) -> void:
	var shape := SphereMesh.new()
	shape.radius = radius; shape.height = 2 * radius
	shape.radial_segments = 12; shape.rings = 6
	mesh(shape, at, colour, host)

func rod(a: Vector3, b: Vector3, radius: float, colour: Color, host: Node3D) -> void:
	var length := a.distance_to(b)
	if length < 0.0001: return
	var shape := CylinderMesh.new()
	shape.top_radius = radius; shape.bottom_radius = radius; shape.height = length
	shape.radial_segments = 8
	var body := mesh(shape, (a+b)/2, colour, host)
	body.quaternion = Quaternion(Vector3.UP, (b-a)/length)

func label(text: String, at: Vector3) -> Label3D:
	var node := Label3D.new()
	node.text = text; node.position = at; node.font_size = 26
	node.pixel_size = 0.002; node.outline_size = 8
	add_child(node)
	return node
```

### Keep the point we already made

This is the same `point_body.gd` used in Genetic Evolution, unchanged. The new behaviour belongs to its host: a held action asks the model for one step. XRTools remains the Day Zero dependency.

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

## Make a comparison you can explain

Start with three requests and one step. Check that the child is (0, 0.5, 0). Then switch to eight requests, step fifteen times under TIPS and HOLD. Switch to NETWORK and step fifteen times again. Find a parent with more than one child. The points, step length and influence radius stayed the same; the eligible set changed.

Now make one edit in `growth.gd`: remove `.normalized()` from the assignment to `direction` inside `decision()`. Keep the later normalization in `step()`.

Predict before running. In the symmetric three-point opening both versions still go straight up. Switch to the eight-point field to reveal the difference: longer displacement vectors now contribute more. From its root their raw sum is (−1.5, 29.5, 0.9), so the edited first child is approximately (−0.0254, 0.4991, 0.0152). It is still half a metre from the root. Compare this with the original unit-vote result and explain why changing one line changes the direction without changing the step length. The gold rods now represent distance-weighted contributions; do not call them unit directions.

Restore the original line before carrying the model onward. This experiment changed how requests count, not where they were placed. It supplies no evidence that the weighted version is a better tree.

## Return to the room

The existing desk has a third FIELD: an authored 96-point canopy. Compare it under both policies. More points can change the form, but do not guarantee forks or completion. Walk around the large specimen; the museum's ramp supports you independently of the branch drawing.

Carry the separation between the field, the eligible sites and the operation that combines requests. Branching Growth follows: a site will respond to one nearest invitation instead of accumulating several. We can locate that change before we compare the resulting forms.

## Keep, change, compare

Keep the request field. Change which sites can answer, then compare a fork with the held strand. Name what the witness keeps: positions and parent links, not a resumable field and policy.


---

<!-- hall: PG_Branching_Growth -->

# Branching Growth — a record and a place

## Learning elements

- Search for one nearest unreached target
- Retain the chosen target and parent indices
- Separate a record count from a position count
- Change whether a parent may act again

Keep the eight-point field from Space Colonization. There, each request chose a site, and that site combined its assigned directions. Here each active site chooses one nearest target. The relation has changed before a single branch appears.

## Look before pressing STEP

At the existing museum desk, RESET turns variation off. The root is at (0, 0, 0). Its nearest target is entry 0: (−2, 1.5, 0), 2.5 metres away. Normalize that displacement and take a half-metre step. The first child should be (−0.4, 0.3, 0). Press STEP and check the leftward lean.

Press STEP again. The root is still active. It creates another child at (−0.4, 0.3, 0), while the first child advances to (−0.8, 0.6, 0). We now have four records, including the root, but only three distinct positions. A second record need not add a new place.

## Rebuild the operation

Use the prepared Endless Museum. Save the three complete files below together and attach `branches.gd` to an empty Node3D at unit scale in your working copy. The test installation uses the gap before the old rear structure: hall-local (8.5, 0, 21), yaw 180 degrees. The existing player, camera, floor and XRTools remain our host.

The point is the same one we held in the previous hall. Its held trigger, or SPACE, advances once. T advances ten times. H keeps a specimen; R resets growth while retaining it. Moving the point alone does not grow a branch. The drawing remains a 0.4-scale miniature; a numerical half-metre edge appears as 0.2 metres. It supplies no floor or branch collision.

### Keep the choice in the record

The eight coordinates are unchanged. `reached` has one Boolean for each target; the target list itself stays in place, so its indices remain meaningful. A node keeps its position and parent, as before. We add `target`, the index chosen when this node was made, and `active`, whether the node may respond on another step. The root has no parent or chosen target, so both indices are −1.

`nearest()` scans the unreached points. It starts with a maximum distance of eight metres and replaces the choice only when it finds a closer one. A point exactly eight metres away is excluded. Equal distances keep the earlier entry in the list. A result of −1 means no eligible target was found; it is not a target index to draw.

`step()` reads the existing nodes, collects children separately, then appends them. A new child waits until the following generation before it can choose a target. The chosen index is written into the child, alongside its parent index. We can now ask both where a branch began and what it was answering.

<!-- student-code:growth.gd -->
```gdscript
extends RefCounted
const STEP := 0.5
const REACH := 8.0
const NEAR := 0.32
var nodes: Array = []
var points: Array = []
var reached: Array = []
var generation := 0
var reason := ""

static func field() -> Array:
	return [Vector3(-2,1.5,0), Vector3(-2.5,2.5,0.4), Vector3(-3,3.5,0),
		Vector3(1.5,2.5,0), Vector3(2,3.5,-0.5), Vector3(2.5,4.5,0),
		Vector3(0,5.5,1), Vector3(0,6,0)]

func reset() -> void:
	nodes = [{"position":Vector3.ZERO, "parent":-1, "target":-1, "active":true}]
	points = field()
	reached.resize(points.size()); reached.fill(false)
	generation = 0
	reason = ""

func nearest(at: Vector3) -> int:
	var chosen := -1
	var distance := REACH
	for i in points.size():
		if reached[i]: continue
		var d: float = at.distance_to(points[i])
		if d < distance:
			distance = d
			chosen = i
	return chosen

func step() -> bool:
	if nodes.size() >= 192:
		reason = "record budget"
		return false
	var additions: Array = []
	var consumed: Array = []
	for i in nodes.size():
		var branch: Dictionary = nodes[i]
		if not branch.active: continue
		var target: int = nearest(branch.position)
		if target < 0:
			branch.active = false
			continue
		var offset: Vector3 = points[target] - branch.position
		var next: Vector3 = branch.position + offset.normalized() * STEP
		additions.append({"position":next, "parent":i, "target":target, "active":true})
		if offset.length() < NEAR:
			consumed.append(target)
			branch.active = false
	for child in additions:
		if nodes.size() >= 192: break
		nodes.append(child)
	for i in consumed: reached[i] = true
	generation += 1
	reason = "" if not additions.is_empty() else "no active target in range"
	return not additions.is_empty()

func distinct_count() -> int:
	var positions: Dictionary = {}
	for row in nodes: positions[row.position] = true
	return positions.size()
```

This follows the installed opening with jitter and pulsing off. Notice its order: it proposes a child first, then tests the parent's old distance from the target. If that distance is strictly less than 0.32 metres, it retires the parent and marks the target reached after the pass. It does not snap the child to the target or remove the target before other sites have read it. At an exact match, the normalized displacement is zero and a coincident child can still be recorded. Those are properties of this implementation, not requirements for every growth algorithm.

Most parents remain active after making a child. That is why the same parent and target may produce the same position again. `distinct_count()` uses positions as dictionary keys, matching the desk's exact-coordinate count. It does not merge approximately equal positions or certify visibly separate branches.

The 192-record budget includes duplicates. Once it is reached, another step changes nothing. The learner model omits the installed jitter, pulse and random colour draws to isolate the nearest-target operation; it does not reproduce those optional variations.

### Draw what the record can tell us

These are the same sphere, cylinder and label helpers from Space Colonization. A line from the first active site to its selected target shows one current decision. The white segment previews its next step. The caption also names the parent and target of the last stored child. A preview and a historical record describe different moments.

HOLD deep-copies the node records and draws a smaller witness. It keeps the selected target indices, but this witness is not a saved simulation: it does not carry the current reached flags or a clock. The installed desk keeps a mesh witness instead. Both let us compare an earlier form; their records are different.

<!-- student-code:branches.gd -->
```gdscript
extends Node3D
const Growth = preload("growth.gd")
const Point = preload("point_body.gd")
const DISPLAY := 0.4
var model = Growth.new()
var point
var live: Node3D
var witness: Node3D
var caption: Label3D
var held: Array = []

func _ready() -> void:
	caption = label("", Vector3(0,2.85,0))
	point = Point.new()
	add_child(point)
	point.action_pressed.connect(func(_p): act("STEP"))
	act("RESET")

func _physics_process(_delta: float) -> void:
	if not point.held():
		point.global_transform = global_transform * Transform3D(Basis.IDENTITY, Vector3(0,1.1,0.8))

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE: act("STEP")
			KEY_T: act("TEN")
			KEY_H: act("HOLD")
			KEY_R: act("RESET")

func act(action: String) -> void:
	match action:
		"STEP": model.step()
		"TEN": for i in 10: model.step()
		"RESET": model.reset()
		"HOLD":
			held = model.nodes.duplicate(true)
			if is_instance_valid(witness): witness.free()
			witness = display(Vector3(-2,0.4,0), DISPLAY * 0.6)
			draw_record(held, witness, Color("c3b9df"))
	refresh()

func refresh() -> void:
	if is_instance_valid(live): live.free()
	live = display(Vector3(0,0.35,0), DISPLAY)
	draw_record(model.nodes, live, Color("8fd2c6"))
	for i in model.points.size():
		sphere(model.points[i], 0.055 if model.reached[i] else 0.1,
			Color("586270") if model.reached[i] else Color("efb2d1"), live)
	for row in model.nodes:
		if not row.active: continue
		var target: int = model.nearest(row.position)
		if target < 0: continue
		var direction: Vector3 = (model.points[target] - row.position).normalized()
		rod(row.position, model.points[target], 0.012, Color("946678"), live)
		rod(row.position, row.position + direction * Growth.STEP, 0.055, Color.WHITE, live)
		break
	var last: Dictionary = model.nodes.back()
	caption.text = "%d records / %d positions / step %d\nLast child: parent %d / target %d\nSPACE or held trigger: step | T: ten | H: hold | R: reset\n%s" % [model.nodes.size(), model.distinct_count(), model.generation, last.parent, last.target, model.reason]

func display(at: Vector3, factor: float) -> Node3D:
	var node := Node3D.new()
	add_child(node)
	node.position = at
	node.scale = Vector3.ONE * factor
	return node

func draw_record(rows: Array, host: Node3D, colour: Color) -> void:
	sphere(Vector3.ZERO, 0.13, colour, host)
	for row in rows:
		if row.parent >= 0: rod(rows[row.parent].position, row.position, 0.045, colour, host)

func mesh(shape: Mesh, at: Vector3, colour: Color, host: Node3D) -> MeshInstance3D:
	var body := MeshInstance3D.new()
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.7
	body.mesh = shape
	body.material_override = material
	body.position = at
	host.add_child(body)
	return body

func sphere(at: Vector3, radius: float, colour: Color, host: Node3D) -> void:
	var shape := SphereMesh.new()
	shape.radius = radius; shape.height = 2 * radius
	shape.radial_segments = 12; shape.rings = 6
	mesh(shape, at, colour, host)

func rod(a: Vector3, b: Vector3, radius: float, colour: Color, host: Node3D) -> void:
	var length := a.distance_to(b)
	if length < 0.0001: return
	var shape := CylinderMesh.new()
	shape.top_radius = radius; shape.bottom_radius = radius; shape.height = length
	shape.radial_segments = 8
	var body := mesh(shape, (a+b)/2, colour, host)
	body.quaternion = Quaternion(Vector3.UP, (b-a)/length)

func label(text: String, at: Vector3) -> Label3D:
	var node := Label3D.new()
	node.text = text; node.position = at; node.font_size = 26
	node.pixel_size = 0.002; node.outline_size = 8
	add_child(node)
	return node
```

### The carried point

`point_body.gd` is unchanged from Space Colonization. The host connects its action to STEP. Reuse it without adding a new grab system.

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

## Retire a parent after it grows

Run two steps first. Read four records and three positions; inspect the parent and target indices of the coincident children. HOLD, then RESET.

Now add `branch.active = false` immediately after the `additions.append(...)` line in `growth.gd`, at the same indentation. Keep the existing near-target check. Predict the second step before running again: the root no longer answers twice. There will be three records and three positions, with the new child attached to the previous child.

Request ten steps in both versions. Compare the counts and the retained specimen. From this single root, the edit makes a chain, since each site retires after its first child. It does not establish a general rule that no two sites may occupy the same position. The change is permission to act again, not geometric deduplication.

Explain the relation to the previous hall. Space Colonization changed which sites could receive several requests. Here we changed the lifetime of a site that selects one request. The same word, branching, was insufficient to tell us either rule.

## Return to the installed comparison

The museum's VARIATION button enables jitter and pulsing and resets the field. These can separate paths and vary edge length. They remain supplied behaviour in this lesson; they are not hidden prerequisites for the printed program. RESET turns them off again, while the held mesh stays.

Look at Organic Space nearby. Its shells and tunnels offer another account of an organic appearance. Keep that encounter alongside the tutorial without mistaking resemblance for a shared construction.

Carry the parent and target records, and the habit of checking what a count actually counts. In Percolation, the next hall, connectivity becomes the question: under a stated rule of contact, what can reach what?

## Keep, change, compare

Keep the eight targets and step length. Change whether a parent may act again. Compare records as well as distinct positions; the held specimen preserves a form and its selected targets, not the whole simulation.


---

<!-- hall: PG_Percolation_Network -->

# Percolation — a rule of contact

## Learning elements

- Represent occupied cells separately from reached cells
- Define six face neighbours with integer offsets
- Read one generation while writing the next
- Test reachability by changing a contact rule

The point returns as our stepping control. The cubes return as cells with integer addresses. Branching Growth kept a parent relation for each new position. Here the positions are already present. We ask which of them a signal can reach.

## Two cubes first

At the existing museum desk, press RESET. A pink source touches a white cube along a face. Predict the result of STEP. Then press CONTACT: the second cube moves to a corner contact. They still touch, but STEP no longer transmits between them.

The program consults six offsets: one cell in either direction along each axis. A diagonal contact is absent from that list. This is the new decision to inspect. The old/next update returns from Cellular Automata; it makes that decision once per generation.

## Keep the lattice; change what has reached it

Save these three complete files together in your prepared Endless Museum working copy. Attach `lattice.gd` to an empty Node3D at unit scale in an open working bay. Our test placement is hall-local (8.5, 0, 18), yaw 180 degrees. The museum supplies the player, camera, floor and XRTools.

The small model has six cells along each axis. The installed comparison has eighteen. Each dictionary key is a Vector3i address; its value is simply true. Membership answers a question: is this cell occupied, a source, or reached? We do not store a false entry. `occupied` stays fixed during propagation. `sources` stays fixed too. `reached` is the changing state.

For the contact test we place a source at (2, 1, 2). The second cell is either (3, 1, 2), one face away, or (3, 2, 3), one corner away. A cell outside the occupied set cannot acquire flow: the update never visits it. The grid does not wrap at its boundaries.

`step()` starts with a copy of the old reached set. It visits occupied cells and asks whether any of their permitted neighbours was already reached. It reads `reached`, writes `next`, and swaps them only after the pass. A newly reached cell cannot transmit again during that same pass. `break` stops the neighbour search after one successful contact; one is enough. The returned number counts additions on this step.

<!-- student-code:reach.gd -->
```gdscript
extends RefCounted
const SIZE := 6
const OFFSETS := [Vector3i(1,0,0), Vector3i(-1,0,0),
	Vector3i(0,1,0), Vector3i(0,-1,0), Vector3i(0,0,1), Vector3i(0,0,-1)]
var occupied: Dictionary = {}
var sources: Dictionary = {}
var reached: Dictionary = {}
var generation := 0

func contact(corner: bool) -> void:
	var a := Vector3i(2,1,2)
	var b := Vector3i(3,2,3) if corner else Vector3i(3,1,2)
	occupied = {a:true, b:true}
	sources = {a:true}
	restart()

func lattice(cutoff: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1337
	occupied = {}; sources = {}
	for x in SIZE:
		for y in SIZE:
			for z in SIZE:
				if rng.randf() < cutoff: occupied[Vector3i(x,y,z)] = true
	for x in SIZE:
		for y in SIZE:
			var cell := Vector3i(x,y,SIZE-1)
			occupied[cell] = true
			sources[cell] = true
	restart()

func restart() -> void:
	reached = sources.duplicate()
	generation = 0

func step() -> int:
	if generation >= 64: return 0
	var next := reached.duplicate()
	for cell: Vector3i in occupied:
		if reached.has(cell): continue
		for offset: Vector3i in OFFSETS:
			if reached.has(cell + offset):
				next[cell] = true
				break
	var added := next.size() - reached.size()
	reached = next
	generation += 1
	return added

func far_count() -> int:
	var count := 0
	for cell: Vector3i in reached:
		if cell.z == 0: count += 1
	return count
```

R restarts propagation by copying the sources, leaving the occupied arrangement intact. The Boolean values and integer keys need only an ordinary dictionary copy. There are no nested records here. Changing the copy to an alias would change the meaning of a generation.

L builds the six-cubed comparison. The local random generator restarts at seed 1337 and visits addresses in x, y, z order. D changes the occupation cutoff between 0.2, 0.4 and 0.6 using those same draws. The whole z = 5 face is then explicitly occupied and supplied as a source, regardless of its draws. This matches the museum desk's boundary policy; the standalone production artifact normally seeds only occupied boundary cells. A boundary condition is part of the experiment.

One step crosses at most one permitted contact. A row of four face-connected cells needs three steps to reach its last cell from the first. Repeating a step cannot carry the signal across an empty gap. The 64-step limit is a working budget, not proof that every possible six-cubed path has been explored.

## Make that decision visible

These are the cubes and materials we already know. Their edge length and address spacing are both 0.3 metres, so neighbouring faces actually meet. White means occupied but unreached, pink means reached, and dark pink identifies a source. The geometry is drawn from the records; moving its host does not change adjacency.

The inherited point advances STEP when its held trigger is pressed. SPACE does the same; T makes ten requests. C alternates the two contacts, L opens the small lattice, D changes density, and R restarts only the current flow. R therefore differs from the museum desk's RESET, which returns to its face-contact opening. The caption counts all reached non-source cells so far, not just the most recent step.

<!-- student-code:lattice.gd -->
```gdscript
extends Node3D
const Reach = preload("reach.gd")
const Point = preload("point_body.gd")
const EDGE := 0.3
var model = Reach.new()
var point
var cells: Node3D
var caption: Label3D
var corner := false
var is_lattice := false
var density := 0

func _ready() -> void:
	caption = Label3D.new()
	caption.position = Vector3(0,2.85,0)
	caption.font_size = 26; caption.pixel_size = 0.002; caption.outline_size = 8
	add_child(caption)
	point = Point.new()
	add_child(point)
	point.action_pressed.connect(func(_p): act("STEP"))
	model.contact(false)
	refresh()

func _physics_process(_delta: float) -> void:
	if not point.held():
		point.global_transform = global_transform * Transform3D(Basis.IDENTITY, Vector3(0,1.1,1.5))

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE: act("STEP")
			KEY_T: act("TEN")
			KEY_C: act("CONTACT")
			KEY_L: act("LATTICE")
			KEY_D: act("DENSITY")
			KEY_R: act("RESTART")

func act(action: String) -> void:
	match action:
		"STEP": model.step()
		"TEN": for i in 10: model.step()
		"CONTACT":
			corner = not corner
			is_lattice = false
			model.contact(corner)
		"LATTICE":
			is_lattice = true
			model.lattice([0.2,0.4,0.6][density])
		"DENSITY":
			density = (density + 1) % 3
			is_lattice = true
			model.lattice([0.2,0.4,0.6][density])
		"RESTART": model.restart()
	refresh()

func refresh() -> void:
	if is_instance_valid(cells): cells.free()
	cells = Node3D.new()
	add_child(cells)
	for cell: Vector3i in model.occupied:
		var body := MeshInstance3D.new()
		var shape := BoxMesh.new()
		shape.size = Vector3.ONE * EDGE
		body.mesh = shape
		body.position = (Vector3(cell) - Vector3(2.5,0,2.5)) * EDGE + Vector3(0,0.55,0)
		var finish := StandardMaterial3D.new()
		finish.roughness = 0.7
		finish.albedo_color = Color("faf6ee")
		if model.reached.has(cell): finish.albedo_color = Color("ec9ebd")
		if model.sources.has(cell): finish.albedo_color = Color("8b345b")
		body.material_override = finish
		cells.add_child(body)
	var mode: String = "Lattice p=%s" % [0.2,0.4,0.6][density] if is_lattice else ("CORNER" if corner else "FACE")
	caption.text = "%s | step %d/64\n%d reached beyond %d source sites\nSPACE or held trigger: step | T: ten | C: contact\nL: lattice | D: density | R: restart" % [mode, model.generation, model.reached.size()-model.sources.size(), model.sources.size()]
	if is_lattice: caption.text += "\n%d reached on opposite z face" % model.far_count()
```

The miniature supplies no cube collision. The installed white cubes do: their collision is removed when they become flowing. That separate physical rule is visible in the hall, but it is not required to calculate reachability. Neither a pink cell nor a connected chain of centres guarantees a supported route for your body.

### Carry the point

This file is unchanged from Branching Growth. The host gives its existing action another job. Moving it alone does not advance the field; releasing it parks it beside the model.

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

## Permit one more kind of contact

Run the corner test first and predict that it stays white. Add `Vector3i(1,1,1)` and `Vector3i(-1,-1,-1)` to `OFFSETS`. These opposite offsets permit one diagonal orientation in both directions. They do not admit every possible edge or corner contact.

Run the same corner test again. The cube should now be reached in one step, without changing either position. A different corner, such as an offset of (1, 1, −1), should still fail. Explain why both results follow from the list. Then return to the seeded lattice and compare the two rules at the same density and generation. The occupied arrangement must remain identical; only the permitted relations have changed.

Do not expect every edited rule to produce a visibly different result in every field. Test a contact that distinguishes them before using a larger arrangement. An empty far-face count after a few steps may mean the wave has not arrived yet. A stopped wave on this finite field is not a universal critical threshold.

## Return to the large field

Use LATTICE and DENSITY at the museum desk. Its 18-cubed field has a supplied z = 17 source plane, and the opposite plane is z = 0. These are opposing sides, not top and bottom in Godot's y-up world. The seed and cutoff match our construction procedure, but the different grid size changes which random draw belongs to each address. The two fields are not scaled copies.

Our model keeps the reachability decision only. The installed artifact also stores numerical flow, decay, randomized transfer amounts and separate flowing/connected states. The tutorial does not reconstruct those amplitudes or claim to simulate a conserved fluid. Its Boolean wave is checked against which sites the installed update reaches, under supplied fixtures.

Keep the dark sphere and stand as other encounters in the hall. Carry the occupied addresses, reached set and explicit contact rule onward. Caves / Mazes will ask how to construct an interior for a body, after this signal has needed only a relation.

## Keep, change, compare

Keep occupancy and the source plane. Change one permitted neighbour relation. Compare reached addresses at the same generation. Restarting the fixed seed repeats an input; it is not an archive of every earlier state.


---

<!-- hall: PG_Caves_Mazes -->

# Caves and Mazes — a route needs room

## Learning elements

- Reuse recorded positions as carving centres
- Store a solid volume in a one-dimensional array
- Clear a footprint and headroom around each centre
- Separate the route, its cleared volume and its display

Percolation kept the cells and changed which ones a signal could reach. Here we change the cells themselves. Our point still advances the work. The position list returns from Trace: a position tells us where an operation happens, but does not yet say how much space it needs.

## Read the existing cave

At the museum desk, turn on TRACE. Gold dots mark carving centres inside the cave. They include repeated visits. They do not connect separate walkers into one invented journey. CAVE SEED changes the walk while keeping the carving rule.

The installed cave starts walkers on four sides, biases them towards the centre, then makes them wander and climb through prescribed levels. Its construction is partly random and partly directed. We will isolate one operation from it: clear cells around a supplied centre. Learning another random walker would hide that operation among things we already know.

## Keep the route; give it room

Save the three complete files below together in the prepared Endless Museum project. Attach `cave.gd` to an empty Node3D at unit scale in a clear working bay. Our tested placement is hall-local (10.5, 0, 10), yaw 180 degrees. The museum supplies the floor, player, camera and XRTools.

`carver.gd` is the data model. A cell contains 1 for solid or 0 for air. We store a seven-by-four-by-seven volume as 196 bytes in a `PackedByteArray`. This is a compact list of integer values. `index()` gives each three-dimensional address one slot: x changes fastest, then z, then y. Advancing x adds 1; advancing z adds 7; advancing y adds 49. Check the bounds before reading or writing a slot.

`carve()` applies a footprint at a centre. With radius 1, the lateral distance test admits the centre and four face neighbours in the x/z plane. It excludes the four diagonal corners. This is a five-cell cross, not a three-by-three square and not a sphere. The operation repeats that footprint upwards for two layers: dy is 0, then 1. At a boundary, out-of-volume cells are ignored.

<!-- student-code:carver.gd -->
```gdscript
extends RefCounted
const SIZE := Vector3i(7, 4, 7)
const RADIUS := 1
const HEADROOM := 2
var solid := PackedByteArray()
var history: Array[Vector3i] = []

func reset() -> void:
	solid.resize(SIZE.x * SIZE.y * SIZE.z)
	solid.fill(1)
	history.clear()

func inside(p: Vector3i) -> bool:
	return p.x >= 0 and p.x < SIZE.x and p.y >= 0 and p.y < SIZE.y and p.z >= 0 and p.z < SIZE.z

func index(p: Vector3i) -> int:
	return (p.y * SIZE.z + p.z) * SIZE.x + p.x

func carve(center: Vector3i) -> void:
	history.append(center)
	for dy in HEADROOM:
		for dz in range(-RADIUS, RADIUS + 1):
			for dx in range(-RADIUS, RADIUS + 1):
				var p := center + Vector3i(dx, dy, dz)
				if inside(p) and Vector2i(dx, dz).length() <= RADIUS:
					solid[index(p)] = 0

func air_count() -> int:
	return solid.count(0)
```

For one interior centre at ground level, predict ten empty cells: five across two layers. At the front boundary only eight fit inside the volume. A repeated carve leaves the same air cells, but adds another entry to `history`. The final void cannot tell us how many times we cleared it.

## Watch each removal

`cave.gd` supplies nine centres, including one repeated position. The route enters at z = 6, turns, and leaves at z = 0. These are declared test data, not a recording secretly obtained from another scene. You can later supply a saved, suitably mapped trace. Here we keep this short list fixed so that two clearance choices can be compared exactly.

Each press of SPACE, or action on the held point, applies the next centre. `cursor` is the index of that entry; it stops at the list's length. F applies the remaining entries. R refills the volume and clears the operation history. None of these changes the route.

The display uses our existing cube and sphere construction. A remaining solid cell becomes a cube; a recorded centre becomes a gold dot. `location()` converts addresses to the small study's local positions. At 0.28 metres per cell, two layers mean 0.56 metres, so this is a hand model. The production cave has one-metre cells. Its two-layer clearance is nominally two metres before we check turns, boundaries, support and the player's actual body.

<!-- student-code:cave.gd -->
```gdscript
extends Node3D
const Carver = preload("carver.gd")
const PointBody = preload("point_body.gd")
const EDGE := 0.28
const ROUTE := [Vector3i(3,0,6), Vector3i(3,0,5), Vector3i(3,0,4),
	Vector3i(3,0,4), Vector3i(4,0,4), Vector3i(4,0,3),
	Vector3i(4,0,2), Vector3i(4,0,1), Vector3i(4,0,0)]
var model := Carver.new()
var point := PointBody.new()
var drawing := Node3D.new()
var caption := Label3D.new()
var cursor := 0
var cutaway := false

func _ready() -> void:
	add_child(drawing)
	add_child(caption)
	caption.position = Vector3(0, 2.55, 0)
	caption.font_size = 26
	caption.pixel_size = 0.002
	add_child(point)
	park()
	point.action_pressed.connect(func(_p): act("STEP"))
	act("RESET")

func _physics_process(_delta: float) -> void:
	if not point.held(): park()

func park() -> void:
	point.global_transform = global_transform * Transform3D(Basis.IDENTITY, Vector3(0, 1.1, 1.45))

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.keycode:
		KEY_SPACE: act("STEP")
		KEY_F: act("FINISH")
		KEY_C: act("CUT")
		KEY_R: act("RESET")

func act(command: String) -> void:
	match command:
		"STEP": advance()
		"FINISH":
			while cursor < ROUTE.size(): advance()
		"CUT": cutaway = not cutaway
		"RESET":
			model.reset()
			cursor = 0
	redraw()

func advance() -> void:
	if cursor < ROUTE.size():
		model.carve(ROUTE[cursor])
		cursor += 1

func location(p: Vector3i) -> Vector3:
	return Vector3(p - Vector3i(3,0,3)) * EDGE + Vector3(0, 0.75 + EDGE / 2, 0)

func redraw() -> void:
	for child in drawing.get_children():
		drawing.remove_child(child)
		child.queue_free()
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color("eee8dc")
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color("efb751")
	var cube := BoxMesh.new()
	cube.size = Vector3.ONE * EDGE
	for y in Carver.SIZE.y:
		for z in Carver.SIZE.z:
			for x in Carver.SIZE.x:
				var p := Vector3i(x,y,z)
				if model.solid[model.index(p)] == 0: continue
				if cutaway and y >= 2: continue
				var cell := MeshInstance3D.new()
				cell.mesh = cube
				cell.material_override = stone
				cell.position = location(p)
				drawing.add_child(cell)
	var dot := SphereMesh.new()
	dot.radius = 0.025
	dot.height = 0.05
	for p in model.history:
		var mark := MeshInstance3D.new()
		mark.mesh = dot
		mark.material_override = gold
		mark.position = location(p)
		drawing.add_child(mark)
	caption.text = "A ROUTE NEEDS ROOM\n%d / %d centres | %d empty cells | headroom %d\nSPACE / held action: carve | F: finish | C: cutaway | R: reset\n%s" % [cursor, ROUTE.size(), model.air_count(), Carver.HEADROOM,
		"CUTAWAY: upper two layers hidden, data kept" if cutaway else "All remaining solid cells shown"]
```

The cubes touch face to face. Their bottom layer begins 0.75 metres above the host origin; this floating model has no floor or collision. It is an illustration of the carved data, not a second walkable cave.

C hides the upper two layers for inspection. It does **not** carve them or change the array. Its caption names the cutaway. With the complete solid visible, look through the entrance; with the cutaway, follow the bend from above. A display decision must not quietly become a claim about the interior.

## The point stays the same

Copy `point_body.gd` unchanged from Percolation. Its complete contents are printed here so the example has no hidden construction. The sphere remains our held control: moving it alone does not carve; its action advances one entry. Releasing it returns it beside the model. These behaviours belong to the host script above, not a new point class.

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

## Change one condition

Before editing, finish the nine entries and inspect the entrance with C off. Change **only** `HEADROOM := 2` to `HEADROOM := 3` in `carver.gd`, run again, and finish the same route.

Predict three things: the recorded centres remain identical; every previously empty cell remains empty; one more layer clears above each distinct footprint cell. The roof is still present at y = 3 because this volume has four layers. The first interior centre now clears fifteen cells. The front-boundary centre clears twelve. A repeated visit still adds history without making more air.

Explain why doubling the number of recorded visits would not necessarily double the void. Then return to the full cave. A connected route of centres and an adequately clear, supported passage are different results. This small model makes the footprint visible; a body-clearance test belongs to the actual collision geometry.

## Compare the maze; carry the distinction

The other installed study removes walls in a nine-by-nine grid. MAZE STEP chooses an unvisited neighbour, opens the intervening wall and pushes the previous cell onto a stack. At a dead end it pops a previous cell and tries another branch. FINISH completes it; RESET starts that construction again. This is the next comparison to read in the room, not a second implementation hidden in our three files. Binary space partitioning remains another museum artifact.

The cave stores solid and air at volume addresses. The maze stores walls, visited cells and a return stack. Neither record alone measures whether your body fits. Keep the distinction between a list of centres, the volume produced around them, and the object shown by the renderer. Sculpted Forms will ask what another sampling operation can keep from a group of moving bodies.

Source operations: `algorithms/proceduralgeneration/growth_systems/caverandomwalk/caverandomwalk.gd` (`_idx`, `_carve_ball`, `_carve_cave`) and the installed controls in `commons/artifacts/timing_machines/pg_workshop.gd`. The maze comparison uses `algorithms/proceduralgeneration/procedural_logic/mazegeneration/maze_generator_vr.gd`.

## Keep, change, compare

Keep the nine carving centres, including the repeated entry. Change headroom. Compare the empty cells and the event history separately: the finished void does not record how often a cell was cleared.


---

<!-- hall: PG_Sculpted_Forms -->

# Sculpted Forms — what the centres keep

## Learning elements

- Capture positions in the construction's local frame
- Map centres to occupied voxel addresses
- Emit faces only where occupied cells meet empty space
- Compare a retained sample with its source objects

Caves and Mazes cleared cells around a list of centres. This hall marks cells around centres and builds their outer surface. The point still lets us commit a step. A surface now records a choice about the bodies we showed it.

## Choose a moment in the existing pile

Press DROP at the museum desk. Twelve cubes fall. SAMPLE freezes them and constructs a surface from their centres. ORIGINAL switches between those frozen cubes and their sample. Their rotations remain visible in the originals, but are absent from the sample's inputs.

We will reconstruct that sampling operation with three fixed cubes. They are declared test objects, already posed, so the same comparison can be repeated. They do not fall and are not a replacement for the installed pile. The supplied museum physics remains available beside the lesson.

## From positions to cells

Save these four complete files together in your prepared Endless Museum project. Attach `sculpture.gd` to an empty Node3D at unit scale in a clear bay. Our test placement is hall-local (8.5, 0, 21), yaw 180 degrees. The museum supplies the player, camera, floor and XRTools.

`sample.gd` keeps three records: the captured centres, the grid origin, and the occupied cells. A dictionary entry means that an address is occupied. Two source objects can mark the same address; it remains one occupied cell.

`capture()` converts each body's global position through the construction frame's `to_local()`. The output mesh will live beneath that same frame. Keeping a global position as though it were local would apply the frame's translation, rotation and scale again when rendering it.

The grid begins one body edge below the smallest captured coordinate on each axis. Divide the distance from that origin by cell size, then use `floor()` to obtain an integer address. The minimum centre anchors the grid: moving that minimum can shift addresses for other bodies too. This origin is not a clipping boundary. Like the installed code, the sparse dictionary accepts every marked address.

### Follow one centre to one face

Use one fixed cube at local (0, 1, 0), with spacing 0.5, as a small example of the same pipeline. Read these stages before assembling the full three-cube surface:

| Stage | Value or decision |
|---|---|
| Capture | `to_local()` gives the centre (0, 1, 0) in the construction frame |
| Anchor | Subtract one body edge: the grid origin is (−1, 0, −1) |
| Address | `floor((centre − origin) / 0.5)` gives (2, 2, 2) |
| Occupy | Extent 2 marks addresses 0 through 4 on every axis |
| Expose | At cell (4, 2, 2), neighbour (5, 2, 2) is absent, so its +x face is emitted |
| Assemble | That face lies at local x = 1.25; four corners become two triangles |

The central cell's six neighbours are present, so it contributes no surface face. A single marked neighbourhood contains 125 cells but exposes only its boundary. The three-cube program follows the same stages, with overlapping addresses stored once. These exact local values explain the rule; the later transform discussion explains why captured floating-point values near an address boundary can produce different counts.

<!-- student-code:sample.gd -->
```gdscript
extends RefCounted
const BODY_EDGE := 1.0
const EXTENT_FACTOR := 1.0
const DIRECTIONS := [Vector3i.RIGHT, Vector3i.LEFT, Vector3i.UP,
	Vector3i.DOWN, Vector3i(0,0,1), Vector3i(0,0,-1)]
var centres: Array[Vector3] = []
var cells: Dictionary = {}
var origin := Vector3.ZERO
var cell_size := 0.5

func capture(frame: Node3D, bodies: Array) -> void:
	var positions: Array[Vector3] = []
	for body in bodies: positions.append(frame.to_local(body.global_position))
	sample(positions, cell_size)

func sample(positions: Array, spacing: float) -> void:
	assert(spacing > 0.0)
	cell_size = spacing
	centres = []
	for p in positions: centres.append(p)
	cells.clear()
	origin = Vector3.ZERO
	if centres.is_empty(): return
	origin = centres[0]
	for p in centres: origin = origin.min(p)
	origin -= Vector3.ONE * BODY_EDGE
	var extent := ceili(BODY_EDGE * EXTENT_FACTOR / cell_size)
	for p in centres:
		var address := Vector3i(((p - origin) / cell_size).floor())
		for x in range(-extent, extent + 1):
			for y in range(-extent, extent + 1):
				for z in range(-extent, extent + 1):
					cells[address + Vector3i(x,y,z)] = true

func faces() -> Array:
	var result: Array = []
	for cell: Vector3i in cells:
		for direction: Vector3i in DIRECTIONS:
			if not cells.has(cell + direction):
				result.append([cell, direction])
	return result
```

The marking rule deliberately follows the existing artifact. A one-unit body at cell size 0.5 gives an extent of 2 cells **each way**, including the central cell: five cells across. Its sampled box is therefore 2.5 units wide, not one. This operation expands an axis-aligned neighbourhood around a centre. It does not voxelize the exact rotated cube.

The renderer places cell centres at `origin + address * cell_size`. There is no extra half-cell shift. `floor()` chooses the address; it does not promise that the source centre lands at the middle of that cell. These conventions are part of the approximation.

`faces()` asks six questions per occupied cell: is the neighbouring address occupied? If so, the shared face is internal and omitted. If not, emit a face. This is the six-neighbour relation from Percolation doing another job. One isolated voxel has six exposed faces. Two face-adjacent voxels have ten, because their two shared sides disappear from the surface.

## Turn each exposed face into two triangles

Our face and mesh work returns from Primitives. `faces.gd` is the complete assembly helper. For each face, it chooses two axes lying on that face, builds four corners and submits triangles 0–1–2 and 0–2–3. Its vertex positions and winding match the six cases in the installed cube-mound assembler. Here we keep explicit flat face normals. The installed assembler regenerates normals, so its shading can differ. This helper builds only the boundary geometry; it does not add collision.

<!-- student-code:faces.gd -->
```gdscript
extends RefCounted

static func build(faces: Array, origin: Vector3, spacing: float) -> ArrayMesh:
	if faces.is_empty(): return ArrayMesh.new()
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face in faces:
		var normal := Vector3(face[1])
		var u: Vector3
		var v: Vector3
		if normal.x != 0:
			u = Vector3(0,0,normal.x)
			v = Vector3.UP
		elif normal.y != 0:
			u = Vector3.RIGHT
			v = Vector3(0,0,normal.y)
		else:
			u = Vector3.UP
			v = Vector3(normal.z,0,0)
		var centre := origin + Vector3(face[0]) * spacing + normal * spacing / 2
		var half := spacing / 2
		var corners := [centre + (-u-v)*half, centre + (u-v)*half,
			centre + (u+v)*half, centre + (-u+v)*half]
		surface.set_normal(normal)
		for i in [0,1,2,0,2,3]: surface.add_vertex(corners[i])
	return surface.commit()
```

## Compare what was captured

`sculpture.gd` constructs the three original cubes, their shared display frame, the sampled mesh, a caption and our point. The display frame scales everything to 0.3. A one-unit cube appears 0.3 metres wide; the initial single-cube sample would appear 0.75 metres wide. Calculations still use the frame's local units.

The program captures an opening sample, then shows the originals. Action on the held point captures again and reveals the surface. Moving the point alone does not change the sample. V switches the view; M moves only the third cube half a local unit along x; R restores the opening arrangement. SPACE is the study's keyboard sampling shortcut. Use the held point in the museum when other artifacts also listen for SPACE.

<!-- student-code:sculpture.gd -->
```gdscript
extends Node3D
const Sample = preload("sample.gd")
const Faces = preload("faces.gd")
const PointBody = preload("point_body.gd")
const START := [Vector3(-1.5,1,0), Vector3(0,1,0), Vector3(1.5,1,0)]
var model := Sample.new()
var frame := Node3D.new()
var bodies: Array = []
var skin := MeshInstance3D.new()
var point := PointBody.new()
var caption := Label3D.new()
var show_sample := false
var moved := false

func _ready() -> void:
	add_child(frame)
	frame.position = Vector3(0,0.8,0)
	frame.scale = Vector3.ONE * 0.3
	for i in START.size():
		var body := MeshInstance3D.new()
		var cube := BoxMesh.new()
		cube.size = Vector3.ONE * Sample.BODY_EDGE
		body.mesh = cube
		body.position = START[i]
		body.rotation = Vector3(0.15*i, 0.3*i, 0.2*i)
		frame.add_child(body)
		bodies.append(body)
	frame.add_child(skin)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("b58b64")
	skin.material_override = material
	add_child(caption)
	caption.position = Vector3(0,2.45,0)
	caption.font_size = 26
	caption.pixel_size = 0.002
	add_child(point)
	point.action_pressed.connect(func(_p): act("SAMPLE"))
	act("SAMPLE")
	act("VIEW")

func _physics_process(_delta: float) -> void:
	if not point.held():
		point.global_transform = global_transform * Transform3D(Basis.IDENTITY, Vector3(0,1.1,1.5))

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.keycode:
		KEY_SPACE: act("SAMPLE")
		KEY_V: act("VIEW")
		KEY_M: act("MOVE")
		KEY_R: act("RESET")

func act(command: String) -> void:
	match command:
		"SAMPLE":
			model.capture(frame, bodies)
			skin.mesh = Faces.build(model.faces(), model.origin, model.cell_size)
			show_sample = true
		"VIEW": show_sample = not show_sample
		"MOVE":
			moved = not moved
			bodies[2].position = START[2] + Vector3.RIGHT * (0.5 if moved else 0.0)
		"RESET":
			moved = false
			for i in bodies.size(): bodies[i].position = START[i]
			act("SAMPLE")
			show_sample = false
	skin.visible = show_sample
	for body in bodies: body.visible = not show_sample
	caption.text = "WHAT DO THE CENTRES KEEP?\n%d cells | %d exposed faces | spacing %.1f\nSPACE / held action: sample | V: view | M: move one cube | R: reset\n%s" % [model.cells.size(), model.faces().size(), model.cell_size,
		"SAMPLE: last captured centres" if show_sample else "ORIGINALS: current three cubes"]
```

M changes a source object without updating the sample. Switch views before sampling again: one view shows the current objects, the other shows the last captured centres. A retained sample is allowed to disagree with a changed source. The next SAMPLE replaces it deliberately.

The third cube moves from x = 1.5 to x = 2.0. The minimum centre stays at x = -1.5, so the grid origin stays fixed. At spacing 0.5, predict that the third cube's marked neighbourhood shifts one address along x. Some old cells remain because the other cubes also occupy them.

## Keep the familiar point

Copy this file unchanged from Caves and Mazes. It is printed in full so the construction can be reconstructed without an undeclared scene node. The host reuses physics parking on release and connects the point's action to SAMPLE.

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

## Change the approximation

Change only `EXTENT_FACTOR := 1.0` to `EXTENT_FACTOR := 0.5` in `sample.gd`. Restart with the same three cubes.

For one cube, predict an extent of 1 at spacing 0.5: three cells across, or 1.5 local units. The sample is smaller, but still not an exact rotated cube. For the exact local values in START, the original rule marks 275 cells with 270 exposed faces; the edited rule marks 81 cells with 126 exposed faces. The captured centres and grid origin stay identical. Every edited occupied address belongs to the larger baseline sample.

Each exposed face becomes two triangles, with six submitted vertices altogether. For that exact fixture there are 540 triangles in the baseline and 252 in the edit. Shared internal faces contribute none.

A captured coordinate has travelled through floating-point transforms. Near a cell boundary, a tiny round-trip difference can change `floor()` and therefore the count. In the translated and rotated test host, the actual capture gives 250 cells and 250 faces; its edit gives 72 and 114. Those numbers describe those captured inputs, not a different sampling rule. Preserve the actual centres when comparing the two extents. The exact START fixture and the live capture are both tested.

Now rotate one original cube without moving its centre and sample again. Predict no change to the occupied addresses. If you wanted the rotation to matter, which information would the sampling function need to receive? A smaller neighbourhood alone cannot supply that missing information.

## Return to the room

The installed VOXEL control resamples the frozen centres at another cell size. ORIGINAL changes visibility but leaves the generated collider active. The learner miniature has no collision at all. Neither view switch restores the earlier fall. DROP starts a new physical run and removes the old sampled collider.

The dome's CUT control shows a different construction: a blank, the subtractive cores, the cast and a section. The layered membrane is another comparison. These remain part of the museum without becoming two extra implementations in this lesson.

Carry the separate records onward: source objects, captured local centres, occupied addresses and a surface assembled from their boundary. Mirrored Patterns will ask what remains the same when we reuse an input while changing the operation applied to it.

## Keep, change, compare

Keep the captured local centres. Change the marked extent and compare occupied cells and exposed faces. Name the information that neither sample contains, including the cubes' rotations.

Source: `algorithms/proceduralgeneration/hybrid_complex/cubemound/cube_mound.gd`, particularly `generate_mesh_from_cubes`, `create_mesh_from_voxels` and `add_voxel_face`. Museum controls: `commons/artifacts/timing_machines/pg_workshop.gd`.


---

<!-- hall: PG_Mirrored_Patterns -->

# Mirrored Patterns — a copy kept

## Learning elements

- Hold an independent copy of a nested array
- Reflect addresses into a separate result
- Inspect the centre row and column of an odd-sized grid
- Change a copying rule while preserving its input

Sculpted Forms kept captured centres separate from their surface. Here we keep a field separate from the image copied out of it. The point returns as the action that commits an operation. The cells, arrays and loops are familiar; the new decision is which addresses may speak for others.

## Start with the existing field

At the museum desk, HOLD keeps the current cellular array. STENCIL returns to that held array and applies quadrant reflection, eight-way reflection, rotation or none. STEP first evolves the displayed field, then applies the selected copying rule. These are two operations in a chosen order.

Our reconstruction isolates quadrant reflection. It uses a declared five-by-five input, so you can account for every destination before trying the larger display. The original automaton, network and pattern tunnel remain available in the hall. We do not need another Life implementation to understand this copying step.

## Keep a witness

Save the following three files together in the prepared Endless Museum project. Attach `panels.gd` to an empty Node3D at unit scale in an open bay; our test placement is hall-local (8.5, 0, 6.5), yaw 180 degrees. The museum already supplies the player, camera and XRTools.

`reflection.gd` owns a held field and a result. Both contain rows, which are themselves arrays. `duplicate(true)` copies those rows too. A shallow copy would leave the rows shared: writing the result could silently alter the input we meant to preserve.

The function requires a non-empty square field. `n / 2` uses integer division. For five cells, the loop limit is two: rows 0–1 and columns 0–1 supply the values. The reflected partner of x is `n - 1 - x`, because valid addresses run from zero to n minus one. Thus 0 pairs with 4, 1 with 3, and 2 with itself.

<!-- student-code:reflection.gd -->
```gdscript
extends RefCounted
const INCLUDE_AXES := false
var held: Array = []
var result: Array = []

func hold(field: Array) -> void:
	assert(not field.is_empty())
	for row in field: assert(row.size() == field.size())
	held = field.duplicate(true)
	original()

func original() -> void:
	result = held.duplicate(true)

func reflect() -> void:
	original()
	var n := held.size()
	var limit := n / 2
	if INCLUDE_AXES: limit += n % 2
	for y in range(limit):
		for x in range(limit):
			var value: int = held[y][x]
			result[y][n - 1 - x] = value
			result[n - 1 - y][x] = value
			result[n - 1 - y][n - 1 - x] = value
```

Each REFLECT begins again from the held input. A cell in the upper-left quarter writes to its three partners; its own value is already in the copy. The held field never receives those writes. Applying the same operation twice gives the same result.

There is a deliberate limit here. With `INCLUDE_AXES` false, the centre row and column are not written. They retain their held values, which need not be symmetric. This reproduces the installed quadrant loop. A symmetric set of four corners is not proof that every cell in the image obeys the same reflection.

## Put input and result beside each other

`panels.gd` builds two grids from the cubes we already know. The display is fixed to five by five; the reflection model itself accepts any non-empty square array. Each cell is 0.16 metres apart. Dark cells contain 0; light cells contain 1. The pink cross marks the centre row and column in both panels, with dark and light pink carrying the same two values.

Hold the point and use its action to reflect. Moving the point alone does nothing to the array. SPACE does the same on desktop; V restores the held input to the result. The left panel is the witness throughout.

<!-- student-code:panels.gd -->
```gdscript
extends Node3D
const Reflection = preload("reflection.gd")
const PointBody = preload("point_body.gd")
const FIELD := [[1,0,1,0,0], [0,1,0,1,0], [0,1,1,0,1],
	[1,0,1,0,0], [0,1,0,0,1]]
const EDGE := 0.16
var model := Reflection.new()
var cells: Array = [[], []]
var point := PointBody.new()
var caption := Label3D.new()
var finishes: Array = []

func _ready() -> void:
	model.hold(FIELD)
	for tint in [Color("25212a"), Color("f4f0e8"), Color("653647"), Color("f3a7c0")]:
		var material := StandardMaterial3D.new()
		material.albedo_color = tint
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		finishes.append(material)
	for side in 2:
		for y in FIELD.size():
			for x in FIELD.size():
				var cell := MeshInstance3D.new()
				var cube := BoxMesh.new()
				cube.size = Vector3(EDGE*0.9, EDGE*0.9, 0.04)
				cell.mesh = cube
				cell.position = Vector3((side*2-1)*0.55 + (x-2)*EDGE, 1.55 + (2-y)*EDGE, 0)
				add_child(cell)
				cells[side].append(cell)
	add_child(caption)
	caption.position = Vector3(0,2.2,0)
	caption.font_size = 26
	caption.pixel_size = 0.0018
	add_child(point)
	point.action_pressed.connect(func(_p): act("REFLECT"))
	refresh()

func _physics_process(_delta: float) -> void:
	if not point.held():
		point.global_transform = global_transform * Transform3D(Basis.IDENTITY, Vector3(0,1.1,1.2))

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.keycode:
		KEY_SPACE: act("REFLECT")
		KEY_V: act("ORIGINAL")
		KEY_M: act("MARK")
		KEY_H: act("HOLD")
		KEY_R: act("RESET")

func act(command: String) -> void:
	match command:
		"REFLECT": model.reflect()
		"ORIGINAL": model.original()
		"MARK": model.result[2][4] = 1 - model.result[2][4]
		"HOLD": model.hold(model.result)
		"RESET": model.hold(FIELD)
	refresh()

func refresh() -> void:
	var fields := [model.held, model.result]
	var differences := 0
	for y in 5:
		for x in 5:
			if model.held[y][x] != model.result[y][x]: differences += 1
			for side in 2:
				var axis := 2 if x == 2 or y == 2 else 0
				cells[side][y*5+x].material_override = finishes[axis + fields[side][y][x]]
	caption.text = "HELD INPUT                         RESULT\nPink cross: centre row and column | %d changed cells\nAction / SPACE: reflect | V: original | M: mark right tip\nH: hold result | R: reset | include axes: %s" % [differences, Reflection.INCLUDE_AXES]
```

M flips the right tip of the result's centre row: address (4, 2), written as `result[2][4]`. It does not edit the held input. Press REFLECT and the mark disappears because the operation starts from that input again. This is not an accumulating drawing tool.

Try M, then H instead. HOLD takes the changed result as a new independent input. Now REFLECT retains that centre-row mark in the baseline rule, since this loop does not overwrite the axes. R restores the declared opening field. These actions make the difference between viewing, editing and committing a record visible.

The inherited point is unchanged from Sculpted Forms. It supplies pickup and action; its host keeps the release position in the museum's local frame.

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

## Give the axes a rule

Change only `INCLUDE_AXES := false` to `INCLUDE_AXES := true` in `reflection.gd`. Restart the whole example with the same field.

For five cells, the loop limit becomes three. The top half of the centre column now supplies its lower half; the left half of the centre row supplies its right half. The central cell maps to itself. This is an intentional extension of the installed quadrant operation, not a correction silently made to the museum artifact.

Predict the right-hand centre row: 0, 1, 1, 1, 0. Predict the centre column from top to bottom: 1, 0, 1, 0, 1. Four cells change between the baseline reflection and this edit. Both results still contain thirteen 1s. A count alone cannot tell you whether the axes are symmetric; inspect the addresses and their partners.

The left panel must stay identical. Compare every right-hand address with its horizontal and vertical partner. Then make a different five-by-five input and predict the result before running it. For an even-sized square there is no centre row or column: the two model versions should agree. Our automated checks include those arrays; the five-by-five display would need its layout loops resized before showing them.

## Return to the other constructions

The museum's held field contains 31 by 31 cells. Its quadrant loop reads 15 by 15 positions and leaves the middle cross alone. Eight-way and rotational copying use different loops; this lesson does not claim that they are the same operation with a different name. The rotational implementation passes through floating-point trigonometry and integer addresses.

The network beside the image asks another question. NETWORK changes how six seed positions are connected; SURFACE adds or hides their tunnel skin. Its collision is disabled in both views. The graph counts describe connections, not a guarantee that a body can walk through the specimen. Repeating an image value creates no new passage by itself.

We leave this sequence with operations we can compose: select, guide, branch, connect, carve, sample and copy. Keep their inputs and results explicit. An image can look complete while an address, an opening or a body's support still needs its own rule.

## Keep, change, compare

Keep the held array. Change whether reflection includes its centre axes. Compare corresponding addresses before comparing totals. Decide explicitly whether to commit the result as the next held input.

Source: `algorithms/proceduralgeneration/growth_systems/mirroredcellularautomata/mirrored_cellular_automata.gd`, `apply_quad_symmetry()`. Held-field control: `commons/artifacts/timing_machines/pg_workshop.gd`, `_stencil()`.

