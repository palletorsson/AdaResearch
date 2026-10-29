extends XRToolsPickable
class_name PlaygroundBall
## The six-point attachment ball of the playground kit: a foam-sleeved steel hub with a socket on each of its
## six faces (+X -X +Y -Y +Z -Z), the POINT of the inventory. A rod (playground_rod.gd) let go with an end near
## a free socket snaps into it and is joined; two balls a rod's length apart take one rod between them, and the
## pair is one rigid thing to lift. Origin: the ball's centre. Let go, it SNAPS TO THE GRID (Palle: 'the ball must
## be placed in a 1 m snap grid'): its centre to the nearest grid point, x and z at multiples of `grid`, y at
## a multiple of `grid` plus the hub's half-height so the lowest row stands on the floor, sockets squared to
## the grid - and freezes there, a node of the scaffold. A rod only holds where a grid ball holds it; picked
## up again the ball is a body until it is let go on the next point. Built in code, as the corpus does (construction-materials.json: black steel, pale foam
## before Colour, pink after).

signal socket_claimed(index: int, rod: Node3D)
signal socket_freed(index: int)
signal placed(at: Vector3)   # snapped to the grid

@export_range(0.03, 0.2) var radius := 0.06        ## the foam ball
@export_range(0.01, 0.08) var boss := 0.025        ## how far a socket's boss stands out of the ball
@export_enum("pale", "pink", "cyan", "steel") var colour := "pink"
@export var socket_reach := 0.12                   ## a rod end this close to a free socket snaps in
@export_range(0.25, 4.0) var grid := 1.0            ## the snap grid's pitch, metres
@export var snap := true                            ## let go: to the nearest grid point, frozen

const DIRS: Array[Vector3] = [Vector3.RIGHT, Vector3.LEFT, Vector3.UP, Vector3.DOWN, Vector3.BACK, Vector3.FORWARD]
const FOAM := {"pale": "ededed", "pink": "ea72ab", "cyan": "5fd3e6", "steel": "2a2c30"}
const STEEL := "2a2c30"

var sockets: Array = [null, null, null, null, null, null]   # the rod in each socket, or null
var _built := false

func _init() -> void:
	collision_layer = 1 | 4;collision_mask = 1;freeze = false;gravity_scale = 1.0;mass = 0.4
	release_mode = ReleaseMode.UNFROZEN;angular_damp = 2.0;linear_damp = 0.2

func apply_grid_config(config: Dictionary) -> void:
	radius = clampf(float(config.get("radius", radius)), .03, .2)
	boss = clampf(float(config.get("boss", boss)), .01, .08)
	colour = str(config.get("colour", colour))
	if colour not in FOAM:colour = "pink"
	socket_reach = clampf(float(config.get("socket_reach", socket_reach)), .02, .5)
	grid = clampf(float(config.get("grid", grid)), .25, 4)
	snap = bool(config.get("snap", snap))
	if _built:_build()

func _ready() -> void:
	super._ready()
	add_to_group("playground_balls")
	dropped.connect(func(_who):call_deferred("settle"))
	picked_up.connect(func(_who):freeze = false)
	_build()

## The hub's half-height: the ball plus a socket boss, what stands on the floor.
func hub() -> float:
	return radius + boss

## The grid point nearest a position: x and z on the grid, y on it plus the hub, so row 0 rests on the floor.
func grid_point(p: Vector3) -> Vector3:
	return Vector3(roundf(p.x / grid) * grid, roundf((p.y - hub()) / grid) * grid + hub(), roundf(p.z / grid) * grid)

## Let go: onto the nearest grid point, squared, frozen. Returns where, or the ball's own place when snap is off.
func settle() -> Vector3:
	if not is_inside_tree() or is_picked_up():return global_position
	if not snap:return global_position
	var at := grid_point(global_position)
	freeze_mode = RigidBody3D.FREEZE_MODE_STATIC;freeze = true
	linear_velocity = Vector3.ZERO;angular_velocity = Vector3.ZERO;global_transform = Transform3D(Basis(), at)
	placed.emit(at);return at

func _build() -> void:
	for c in get_children():
		if c is MeshInstance3D or c is CollisionShape3D:remove_child(c);c.queue_free()
	var foam := StandardMaterial3D.new();foam.albedo_color = Color(FOAM[colour]);foam.roughness = .88
	var steel := StandardMaterial3D.new();steel.albedo_color = Color(STEEL);steel.metallic = .6;steel.roughness = .35
	var ball := MeshInstance3D.new();var sm := SphereMesh.new();sm.radius = radius;sm.height = radius * 2;sm.radial_segments = 32;sm.rings = 16;ball.mesh = sm;ball.material_override = foam;ball.name = "Foam";add_child(ball)
	for i in DIRS.size():
		var d: Vector3 = DIRS[i]
		var b := MeshInstance3D.new();var cm := CylinderMesh.new();cm.top_radius = .016;cm.bottom_radius = .02;cm.height = boss + .01;cm.radial_segments = 12;b.mesh = cm;b.material_override = steel
		b.name = "Socket%d" % i;b.position = d * (radius + boss / 2.0);b.basis = Basis(Quaternion(Vector3.UP, d)) if d != Vector3.UP and d != Vector3.DOWN else (Basis() if d == Vector3.UP else Basis(Vector3.RIGHT, PI))
		add_child(b)
	var shape := CollisionShape3D.new();var ss := SphereShape3D.new();ss.radius = radius + boss;shape.shape = ss;add_child(shape)
	_built = true

## A socket's mouth in the world (where a rod's end sits), and the way a rod in it points away from the ball.
func socket_global(i: int) -> Vector3:
	return global_transform * (DIRS[i] * (radius + boss))

func socket_dir(i: int) -> Vector3:
	return (global_transform.basis * DIRS[i]).normalized()

func socket_free(i: int) -> bool:
	return sockets[i] == null or not is_instance_valid(sockets[i])

## The nearest free socket to a point within reach, or -1.
func nearest_free_socket(p: Vector3) -> int:
	var best := -1;var best_d := socket_reach
	for i in DIRS.size():
		if not socket_free(i):continue
		var d := p.distance_to(socket_global(i))
		if d < best_d:best_d = d;best = i
	return best

func claim(i: int, rod: Node3D) -> void:
	sockets[i] = rod;socket_claimed.emit(i, rod)

func release(rod: Node3D) -> void:
	for i in sockets.size():
		if sockets[i] == rod:sockets[i] = null;socket_freed.emit(i)

func prepare_editor_preview() -> void:
	freeze = true
