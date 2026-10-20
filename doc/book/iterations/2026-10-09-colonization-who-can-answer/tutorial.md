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
