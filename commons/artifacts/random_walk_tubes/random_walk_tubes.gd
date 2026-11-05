extends Node3D
class_name RandomWalkTubes

# @identity
# essence: a walk toward a goal made of chance - each step tries a few random moves and keeps the ones that come
#          nearer; the steps are piped to one middle point and a thick tube follows the curve they steer
# desire: see a random walk with a bias become a body: a tube that wanders but arrives, held by spokes to a centre
# critical_parameter: step_min/step_max - the range each random move is drawn from (-1..5: mostly forward, a little back)
# triggers: built procedurally in _ready() from a seeded generator; rebuilt by apply_grid_config
# needs: a floor about `scale` x 113 m long; the origin is the middle of the walk, on the floor
# truth: the walk is biased, not aimed - a move is kept only if it ends nearer the goal than the step began
#
# Palle, 2026-11-05, for the Randomness sequence: "also this one" - a second Rhino Python script. Ported as written:
#   - start: a random point in the square 0..4 x 0..4; goal: a random point in 80..84 x 80..84; both at height 0;
#   - six steps; each step tries five moves of uniform(-1, 5) on every axis from the current point, and keeps a move
#     when it ends nearer the goal than the step's STARTING distance (the script never updates that distance), so a
#     later try can undo an earlier gain as long as it stays better than where the step began;
#   - each step is piped (radius 2.4) to the middle point (40, 44, 0), with a sphere of the same radius at both ends;
#   - a tube of radius 2.2 follows rs.AddCurve's curve - a clamped cubic B-spline whose CONTROL points are the start,
#     the six steps and the goal (it passes through the start and the goal, not through the steps);
#   - the script's `elevate` argument is overwritten inside newVector and never used, and its two 'low' points are
#     made and never joined: neither is ported.
# Rhino's z is up. The walk's diagonal is turned to run along +X; `scale` sets metres per unit (Palle: fit one floor,
# about 15 m start to goal); the whole is lifted so its lowest surface rests on the floor.
# The walk climbs (each try's height change is drawn from -1..5 too): where it would stand taller than fit_height, the
# whole is scaled down to fit under the ceiling.
# Config: #seed:5 #scale:0.133 #steps:6 #tries:5 #step_min:-1 #step_max:5 #fit_height:5.2

@export var seed: int = 5
@export var scale_m: float = .133
@export var steps: int = 6
@export var tries: int = 5
@export var step_min: float = -1.0
@export var step_max: float = 5.0
## The tallest the whole may stand, in metres: a walk that climbs higher is scaled down to fit under a 6 m storey.
## 0 = no limit.
@export var fit_height: float = 5.2

const MID := Vector3(40, 44, 0)
const SPOKE_RADIUS := 2.4
const TUBE_RADIUS := 2.2
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_build()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "steps", "tries"]:
		if config_data.has(key): set(key, int(config_data[key]))
	if config_data.has("scale"): scale_m = float(config_data.scale)
	for key in ["step_min", "step_max", "fit_height"]:
		if config_data.has(key): set(key, float(config_data[key]))
	if is_inside_tree(): _build()

func _build() -> void:
	for child in get_children(): child.queue_free()
	_rng.seed = seed
	var start := Vector3(_rng.randf_range(0, 4), _rng.randf_range(0, 4), 0)
	var goal := Vector3(_rng.randf_range(80, 84), _rng.randf_range(80, 84), 0)
	var control: Array[Vector3] = [start]
	var at := start
	for i in steps:
		at = _step(at, goal)
		control.append(at)
	control.append(goal)
	# Script units to local metres: the start-goal diagonal along +X, the script's z up, centred, resting on the floor.
	var along := Vector2(goal.x - start.x, goal.y - start.y).normalized()
	var centre := (start + goal) * .5
	var lowest := INF
	var curve := _bspline(control, 160)
	for p in curve: lowest = minf(lowest, p.z - TUBE_RADIUS)
	for p in control.slice(1, control.size() - 1): lowest = minf(lowest, p.z - SPOKE_RADIUS)
	lowest = minf(lowest, MID.z - SPOKE_RADIUS)
	var highest := MID.z + SPOKE_RADIUS
	for p in curve: highest = maxf(highest, p.z + TUBE_RADIUS)
	for p in control.slice(1, control.size() - 1): highest = maxf(highest, p.z + SPOKE_RADIUS)
	var s := scale_m if fit_height <= 0.0 else minf(scale_m, fit_height / (highest - lowest))
	set_meta("scale_used", snappedf(s, .0001))
	var local := func(p: Vector3) -> Vector3:
		var d := Vector2(p.x - centre.x, p.y - centre.y)
		return Vector3(d.dot(along), p.z - lowest, d.dot(Vector2(-along.y, along.x))) * s
	var body := StaticBody3D.new();body.name = "Body";add_child(body)
	var white := StandardMaterial3D.new();white.albedo_color = Color("e4e1da");white.roughness = .45;white.metallic = .2
	var pink := StandardMaterial3D.new();pink.albedo_color = Color("ff4f9a");pink.roughness = .5
	# The tube along the curve.
	var path := PackedVector3Array()
	for p in curve: path.append(local.call(p))
	var tube := _sweep(path, TUBE_RADIUS * s, 24)
	var tube_mesh := MeshInstance3D.new();tube_mesh.name = "Tube";tube_mesh.mesh = tube;tube_mesh.material_override = white;add_child(tube_mesh)
	var tube_shape := CollisionShape3D.new();tube_shape.shape = tube.create_trimesh_shape();body.add_child(tube_shape)
	# The spokes from every step to the middle, and their spheres.
	var spokes := SurfaceTool.new();spokes.begin(Mesh.PRIMITIVE_TRIANGLES)
	var balls := SurfaceTool.new();balls.begin(Mesh.PRIMITIVE_TRIANGLES)
	var r := SPOKE_RADIUS * s
	var mid_local: Vector3 = local.call(MID)
	var sphere := SphereMesh.new();sphere.radius = r;sphere.height = 2 * r;sphere.radial_segments = 20;sphere.rings = 10
	_ball(balls, body, sphere, mid_local, r)
	for p in control.slice(1, control.size() - 1):
		var a: Vector3 = local.call(p)
		_cylinder(spokes, body, a, mid_local, r)
		_ball(balls, body, sphere, a, r)
	var spoke_mesh := MeshInstance3D.new();spoke_mesh.name = "Spokes";spoke_mesh.mesh = spokes.commit();spoke_mesh.material_override = white;add_child(spoke_mesh)
	var ball_mesh := MeshInstance3D.new();ball_mesh.name = "Spheres";ball_mesh.mesh = balls.commit();ball_mesh.material_override = pink;add_child(ball_mesh)
	var box := AABB(path[0], Vector3.ZERO)
	for p in path: box = box.expand(p)
	box = box.grow(TUBE_RADIUS * s).merge(AABB(mid_local - Vector3.ONE * r, Vector3.ONE * 2 * r))
	set_meta("footprint_m", [snappedf(box.size.x, .01), snappedf(box.size.z, .01), snappedf(box.size.y, .01)])
	set_meta("steps", control.slice(1, control.size() - 1).map(func(p): return [snappedf(p.x, .01), snappedf(p.y, .01), snappedf(p.z, .01)]))

## The script's getNewPoint: `tries` random moves from the current point, each kept if it ends nearer the goal
## than the step began (orgDist is never updated).
func _step(v: Vector3, goal: Vector3) -> Vector3:
	var original := v.distance_to(goal)
	for t in tries:
		var candidate := v + Vector3(_rng.randf_range(step_min, step_max), _rng.randf_range(step_min, step_max), _rng.randf_range(step_min, step_max))
		if original > candidate.distance_to(goal):
			v = candidate
	return v

## rs.AddCurve's default: a clamped cubic B-spline on these control points, sampled at n points (de Boor).
func _bspline(points: Array[Vector3], n: int) -> Array[Vector3]:
	var degree := mini(3, points.size() - 1)
	var count := points.size()
	var knots: Array[float] = []
	for i in degree + 1: knots.append(0.0)
	for i in range(1, count - degree): knots.append(float(i))
	for i in degree + 1: knots.append(float(count - degree))
	var top := float(count - degree)
	var out: Array[Vector3] = []
	for s in n:
		var u := top * s / (n - 1)
		var k := degree
		while k < count - 1 and u >= knots[k + 1]: k += 1
		var d: Array[Vector3] = []
		for j in degree + 1: d.append(points[k - degree + j])
		for level in range(1, degree + 1):
			for j in range(degree, level - 1, -1):
				var i := k - degree + j
				var denom := knots[i + degree - level + 1] - knots[i]
				var alpha := 0.0 if denom == 0.0 else (u - knots[i]) / denom
				d[j] = d[j - 1].lerp(d[j], alpha)
		out.append(d[degree])
	return out

## A tube of radius r along a polyline, with rotation-minimising frames so it does not twist.
func _sweep(path: PackedVector3Array, r: float, sides: int) -> ArrayMesh:
	var st := SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array = []
	var t0 := (path[1] - path[0]).normalized()
	var normal := (Vector3.UP.cross(t0) if absf(t0.dot(Vector3.UP)) < .95 else Vector3.RIGHT.cross(t0)).normalized()
	for i in path.size():
		var t := ((path[mini(i + 1, path.size() - 1)] - path[maxi(i - 1, 0)])).normalized()
		normal = (normal - t * normal.dot(t)).normalized()
		var binormal := t.cross(normal)
		var ring: Array = []
		for k in sides:
			var a := TAU * k / sides
			ring.append([path[i] + (normal * cos(a) + binormal * sin(a)) * r, normal * cos(a) + binormal * sin(a)])
		rings.append(ring)
	for i in path.size() - 1:
		for k in sides:
			var a: Array = rings[i][k];var b: Array = rings[i][(k + 1) % sides]
			var c: Array = rings[i + 1][k];var d: Array = rings[i + 1][(k + 1) % sides]
			for v in [a, c, b, b, c, d]:
				st.set_normal(v[1]);st.add_vertex(v[0])
	return st.commit()

func _cylinder(st: SurfaceTool, body: StaticBody3D, a: Vector3, b: Vector3, r: float) -> void:
	var length := a.distance_to(b)
	if length < 1e-4: return
	var y := (b - a) / length
	var reference := Vector3.RIGHT if absf(y.dot(Vector3.UP)) > .95 else Vector3.UP
	var x := reference.cross(y).normalized()
	var frame := Transform3D(Basis(x, y, x.cross(y)), (a + b) * .5)
	var mesh := CylinderMesh.new();mesh.top_radius = r;mesh.bottom_radius = r;mesh.height = length;mesh.radial_segments = 20;mesh.rings = 1
	mesh.cap_top = false;mesh.cap_bottom = false
	st.append_from(mesh, 0, frame)
	var shape := CollisionShape3D.new();var capsule := CapsuleShape3D.new();capsule.radius = r;capsule.height = length + 2 * r
	shape.shape = capsule;shape.transform = frame;body.add_child(shape)

func _ball(st: SurfaceTool, body: StaticBody3D, mesh: SphereMesh, at: Vector3, r: float) -> void:
	st.append_from(mesh, 0, Transform3D(Basis.IDENTITY, at))
	var shape := CollisionShape3D.new();var s := SphereShape3D.new();s.radius = r;shape.shape = s;shape.position = at;body.add_child(shape)
