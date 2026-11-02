extends Node
## THE CEILING OF A BOUNCY FLOOR (Palle, 2026-11-02: "the material should be bouncy ... the bouncy version with the
## 4 m ceiling"). A floor's bounce is XR Tools ground physics: its GroundPhysics carries a bounciness above 1, so the
## headset's player body throws back more than it caught and each landing climbs higher (player_body.gd: v + 2 n m b).
## XR Tools has no ceiling, so this node - one per hall that has bouncy floors (place_activity._walk_body) - listens
## to every XR player body's player_bounced and caps the rise at the floor's bounce_ceiling (metres). The desktop
## walker applies the same cap itself (walker._bounce).

var _connected := {}
var _since := 0.0

func _ready() -> void:
	_connect_bodies()

func _physics_process(delta: float) -> void:
	_since += delta
	if _since > 1.0:_since = 0.0;_connect_bodies()   # a rig made after the hall still gets the ceiling

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
