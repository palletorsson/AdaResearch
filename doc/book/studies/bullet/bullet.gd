extends Node3D

const Look := preload("res://supplied/look.gd")
const RADIUS := 0.1                          # the ball's, in metres
const RATES := [4, 10, 30, 60, 240]          # what M steps through

@export var launch := Vector3(4, 6, 0)       # metres per second, as it leaves
@export var start := Vector3(0, 0.1, 0)      # where it leaves from, counted from this node
@export var steps_per_second := 60           # our own clock

var gravity := Vector3(0, -9.8, 0)           # metres per second, every second
var velocity := Vector3.ZERO                 # metres per second, now
var at := Vector3.ZERO                       # where the bullet is, counted from this node
var dt := 0.0                                # seconds in one step
var path: Array = []                         # every place it has been, one for each step
var flying := false
var clock := 0.0                             # seconds that have passed and are not stepped yet
var walker: Node3D                           # who can be hit; nobody, if the scene has no Walker
var hit := false
var line: StandardMaterial3D
var dots: StandardMaterial3D

func _ready() -> void:
	$Ball.material_override = Look.paint(Look.BODY)
	$Path.mesh = ImmediateMesh.new()
	$Path.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	line = Look.paint(Look.LINE)
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
		print("dt 1/", steps_per_second, " s: ", path.size() - 1, " steps, landed ", snappedf(at.x - start.x, 0.001), " m from the launch")

func meet(body: Node3D) -> void:
	var above := to_global(at) - body.global_position   # from the body's feet to the ball
	if Vector2(above.x, above.z).length() < 0.3 + RADIUS and above.y > 0.0 and above.y < 1.8:
		hit = true
		print("hit at step ", path.size() - 1, ", ", snappedf(above.y, 0.01), " m above the feet")

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		fire()
	if Input.is_action_just_pressed("drop"):
		steps_per_second = RATES[(RATES.find(steps_per_second) + 1) % RATES.size()]
		fire()
	if not flying:
		return
	clock += delta
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
