extends Node3D
## The bullet, as a guest of the room: a ball thrown across its place by its own
## two lines, again and again, with the path it took drawn behind it.
## It is the kit's bullet.gd with three changes:
##   - its two colours are written out, because a guest names nothing outside
##     its folder, not even the look;
##   - the launch is small enough for a place 1.6 m wide: it leaves 0.6 m to
##     the left of the middle and comes down about 0.6 m to the right of it;
##   - it leaves again after `rest` seconds on the floor, and it does not
##     listen to a key.
## It has no collider: a walker walks through it and a marble falls through it.
## It looks for a node named Walker beside it, which the room has, and prints a
## line when one of the ball's steps is inside that body.
## Yours to change: launch, steps_per_second (the dt you chose is 1 / it), rest.

const BODY := Color("c6ff3d")                # the kit's BODY, written out
const LINE := Color("ffffff")                # the kit's LINE
const RADIUS := 0.1                          # the ball's, in metres

@export var launch := Vector3(1.2, 4.9, 0)   # metres per second, as it leaves
@export var start := Vector3(-0.6, 0.1, 0)   # where it leaves from, counted from this node
@export var steps_per_second := 60           # our own clock
@export var rest := 1.0                      # seconds on the floor before it leaves again

var gravity := Vector3(0, -9.8, 0)           # metres per second, every second
var velocity := Vector3.ZERO                 # metres per second, now
var at := Vector3.ZERO                       # where the bullet is, counted from this node
var dt := 0.0                                # seconds in one step
var path: Array = []                         # every place it has been, one for each step
var flying := false
var clock := 0.0                             # seconds that have passed and are not stepped yet
var walker: Node3D                           # who can be hit; nobody, if there is no Walker beside it
var hit := false
var flights := 0                             # how often it has landed
var line: StandardMaterial3D
var dots: StandardMaterial3D

func _ready() -> void:
	var lime := StandardMaterial3D.new()
	lime.albedo_color = BODY
	lime.roughness = 0.8
	$Ball.material_override = lime
	$Path.mesh = ImmediateMesh.new()
	$Path.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	line = StandardMaterial3D.new()
	line.albedo_color = LINE
	line.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dots = line.duplicate()
	dots.use_point_size = true
	dots.point_size = 7.0
	walker = get_node_or_null("../Walker")
	fire()

func fire() -> void:
	dt = 1.0 / steps_per_second
	velocity = launch
	at = start
	path = [at]
	flying = true
	hit = false
	clock = 0.0

func pull() -> Vector3:
	return gravity

func step() -> void:
	velocity += pull() * dt
	at += velocity * dt
	if at.y <= RADIUS:
		at.y = RADIUS
		flying = false
	path.append(at)
	if walker != null and not hit:
		meet(walker)
	if not flying:
		flights += 1
		if flights == 1:    # said once: the room has other guests to hear
			print("the bullet, dt 1/", steps_per_second, " s: ", path.size() - 1, " steps, landed ", snappedf(at.x - start.x, 0.001), " m from the launch")

func meet(body: Node3D) -> void:
	var above := to_global(at) - body.global_position   # from the body's feet to the ball
	if Vector2(above.x, above.z).length() < 0.3 + RADIUS and above.y > 0.0 and above.y < 1.8:
		hit = true
		print("the bullet hit at step ", path.size() - 1, ", ", snappedf(above.y, 0.01), " m above the feet")

func _physics_process(delta: float) -> void:
	clock += delta
	if not flying:
		if clock >= rest:
			fire()
		return
	while flying and clock >= dt:
		step()
		clock -= dt
	$Ball.position = at
	draw_path()

func draw_path() -> void:
	var mesh: ImmediateMesh = $Path.mesh
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, line)
	for point: Vector3 in path:
		mesh.surface_add_vertex(point)
	mesh.surface_end()
	mesh.surface_begin(Mesh.PRIMITIVE_POINTS, dots)
	for point: Vector3 in path:
		mesh.surface_add_vertex(point)
	mesh.surface_end()
