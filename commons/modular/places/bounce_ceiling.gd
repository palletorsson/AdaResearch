extends Node
## THE CEILING OF A BOUNCY FLOOR (Palle, 2026-11-02: "the material should be bouncy ... the bouncy version with the
## 4 m ceiling"). A floor's bounce is XR Tools ground physics: its GroundPhysics carries a bounciness above 1, so the
## headset's player body throws back more than it caught and each landing climbs higher (player_body.gd: v + 2 n m b).
## XR Tools has no ceiling, so this node - one per hall that has bouncy floors (place_activity._walk_body) - listens
## to every XR player body's player_bounced and caps the rise at the floor's bounce_ceiling (metres). The desktop
## walker applies the same cap itself (walker._bounce).
##
## It also COMPLETES the XR bounce. XR Tools tests its bounce after the move, against a local velocity its own
## ground-drag step has just rebuilt from the post-slide velocity whenever the stick is idle - so a body that lands
## standing still meets the floor with zero impact and does not bounce (measured 2026-11-02, probe_comfort_vignette C:
## one apex, 1.04 m, then flat). After each body step this node reads the velocity the body carried into the step,
## and when an XR body has landed on a floor with bounciness and XR Tools did not throw it back, applies XR Tools' own
## rule (normal speed m becomes m (2b - 1)) and the ceiling. Only bouncy halls carry this node.

var _connected := {}
var _since := 0.0
var _carried := {}   # body id -> its velocity at the end of its last step

func _ready() -> void:
	process_physics_priority = 100   # after the player bodies' own step
	_connect_bodies()

func _physics_process(delta: float) -> void:
	_since += delta
	if _since > 1.0:_since = 0.0;_connect_bodies()   # a rig made after the hall still gets the ceiling
	for body in get_tree().get_nodes_in_group("player_body"):
		if not (body is XRToolsPlayerBody):continue
		var id: int = body.get_instance_id()
		if _carried.has(id):
			complete(body, _carried[id], delta)
		_carried[id] = body.velocity

func _connect_bodies() -> void:
	for body in get_tree().get_nodes_in_group("player_body"):
		if body.has_signal("player_bounced") and not _connected.has(body.get_instance_id()):
			body.player_bounced.connect(_on_bounced.bind(body));_connected[body.get_instance_id()] = true

func _on_bounced(collider: Object, _magnitude: float, body: CharacterBody3D) -> void:
	cap(body, collider)

## Cap a body's rise to the ceiling the floor it bounced on carries (the speed that reaches that height, sqrt(2 g h)).
static func cap(body: CharacterBody3D, collider: Object) -> void:
	if collider == null or not (collider is Node) or not (collider as Node).has_meta("bounce_ceiling"):return
	var up := Vector3.UP
	var vmax := sqrt(2.0 * float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)) * float((collider as Node).get_meta("bounce_ceiling")))
	var rise := body.velocity.dot(up)
	if rise > vmax:body.velocity -= up * (rise - vmax)

## Throw an XR body back off a bouncy floor it has just landed on, when XR Tools did not. `carried` is the velocity
## the body ended its previous step with; gravity is added as the body adds it before moving. Returns true if it bounced.
static func complete(body: XRToolsPlayerBody, carried: Vector3, delta: float) -> bool:
	if body.get_slide_collision_count() == 0:return false
	var hit := body.get_slide_collision(0)
	var floor_node := hit.get_collider() as Node
	if floor_node == null:return false
	var gp := floor_node.get_node_or_null("GroundPhysics") as XRToolsGroundPhysics
	if gp == null:return false
	var b := XRToolsGroundPhysicsSettings.get_bounciness(gp.physics, body.default_physics)
	var threshold := XRToolsGroundPhysicsSettings.get_bounce_threshold(gp.physics, body.default_physics)
	var n := hit.get_normal()
	var m := -n.dot(carried + body.gravity * delta - body.ground_velocity)
	if b <= 0.0 or m < threshold:return false
	var want := m * (2.0 * b - 1.0)
	var out := (body.velocity - body.ground_velocity).dot(n)
	if out >= want * 0.5:return false   # XR Tools bounced it (the stick was held)
	body.velocity += n * (want - out)
	cap(body, floor_node)
	body.player_bounced.emit(floor_node, m)
	return true
