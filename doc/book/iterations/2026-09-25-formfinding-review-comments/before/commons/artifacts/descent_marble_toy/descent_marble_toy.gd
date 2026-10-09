extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name DescentMarbleToy

## @identity
## name: "Settling: gradient descent toward max Q"
## tier: small
## lineage: a marble in a bowl — the oldest optimiser. It does not compute the minimum;
##   it just follows the slope down until the slope is zero, and there it rests.
## essence: A held marble-in-a-bowl, ~0.4m across. Tip it and the marble rolls downhill,
##   overshoots, rolls back, and settles at the bottom. The bowl is an energy landscape;
##   the bottom is the rest state. A soft body finding its shape is doing exactly this in
##   many dimensions at once — rolling downhill until nothing pulls it further.
## truth: "FINDING A SHAPE IS ROLLING DOWNHILL" — settle = follow the slope to the bottom
## applications: optimisation, training, physics relaxation — descent is how systems settle.

@export var bowl_radius: float = 0.18
@export var bowl_depth: float = 0.12
@export var marble_radius: float = 0.03
@export var bowl_segs: int = 32
@export var bowl_col: Color = Color(0.45, 0.50, 0.58)
@export var marble_col: Color = Color(0.98, 0.82, 0.40)
@export var trail_col: Color = Color(0.55, 0.90, 0.95)
@export var label_col: Color = Color(0.92, 0.95, 0.99)

var _t: float = 0.0
var _sway: Node3D = null
var _marble: MeshInstance3D = null
# Marble state in bowl-local polar-ish coordinates (x,z offset from centre).
var _pos: Vector2 = Vector2.ZERO
var _vel: Vector2 = Vector2.ZERO


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("bowl_radius"):
		bowl_radius = clampf(float(config["bowl_radius"]), 0.1, 0.3)
	if config.has("bowl_depth"):
		bowl_depth = clampf(float(config["bowl_depth"]), 0.05, 0.2)
	if config.has("marble_col"):
		marble_col = _parse_color(config["marble_col"], marble_col)
	if config.has("bowl_col"):
		bowl_col = _parse_color(config["bowl_col"], bowl_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_sway = null
	_marble = null
	_build()


func _bowl_height(r: float) -> float:
	# Paraboloid bowl: y rises with the square of distance from centre.
	var u: float = clampf(r / bowl_radius, 0.0, 1.0)
	return u * u * bowl_depth


func _bowl_mesh() -> ArrayMesh:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	var bands: int = 8
	for b in range(bands + 1):
		var rr: float = (float(b) / float(bands)) * bowl_radius
		for s in range(bowl_segs + 1):
			var th: float = (float(s) / float(bowl_segs)) * TAU
			var p := Vector3(rr * cos(th), _bowl_height(rr), rr * sin(th))
			verts.append(p)
			normals.append(Vector3.UP)
	var stride: int = bowl_segs + 1
	for b in range(bands):
		for s in range(bowl_segs):
			var i0: int = b * stride + s
			var i1: int = b * stride + s + 1
			var i2: int = (b + 1) * stride + s + 1
			var i3: int = (b + 1) * stride + s
			indices.append_array([i0, i2, i1, i0, i3, i2])
	var am := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return am


func _build() -> void:
	# Held housing — a base disc so it reads as a desk toy.
	add_child(_box(Vector3(0.0, -bowl_depth - 0.04, 0.0), Vector3(bowl_radius * 2.6, 0.04, bowl_radius * 2.6), _steel_mat(Color(0.28, 0.30, 0.35))))

	var sway := Node3D.new()
	sway.name = "BowlSway"
	add_child(sway)
	_sway = sway

	# The bowl (energy landscape)
	var bowl := MeshInstance3D.new()
	bowl.mesh = _bowl_mesh()
	var bmat := _matte_mat(bowl_col, 0.4, 0.3)
	bmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	bowl.material_override = bmat
	sway.add_child(bowl)

	# A glowing dot at the very bottom — the rest state / minimum.
	sway.add_child(_sphere(Vector3(0.0, 0.002, 0.0), 0.012, _glow_mat(trail_col, 1.6)))

	# The marble — start it up the wall so it visibly rolls down.
	_pos = Vector2(bowl_radius * 0.8, 0.0)
	_vel = Vector2.ZERO
	_marble = _sphere(_marble_world(_pos), marble_radius, _glow_mat(marble_col, 1.4))
	sway.add_child(_marble)

	add_child(_billboard_label("FINDING A SHAPE IS ROLLING DOWNHILL", Vector3(0.0, bowl_depth + 0.12, 0.0), 18, label_col))


func _marble_world(p: Vector2) -> Vector3:
	var r: float = p.length()
	return Vector3(p.x, _bowl_height(r) + marble_radius, p.y)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta

	# Gradient descent in 2D: acceleration points down the local slope toward centre.
	# Slope of u*u*depth is proportional to distance from centre -> linear restoring force.
	var r: float = _pos.length()
	var accel: Vector2 = -_pos * (bowl_depth / maxf(bowl_radius * bowl_radius, 1e-4)) * 9.0
	_vel = (_vel + accel * delta) * 0.985    # damping = energy bleeds away, it settles
	_pos += _vel * delta
	# Keep it inside the rim.
	if _pos.length() > bowl_radius:
		_pos = _pos.normalized() * bowl_radius
		_vel *= 0.6
	# Occasionally tip the bowl to re-release the marble (keeps the toy alive).
	if fmod(_t, 5.0) < delta:
		_vel += Vector2(_rng.randf_range(-0.4, 0.4), _rng.randf_range(-0.4, 0.4))

	if _marble != null:
		_marble.position = _marble_world(_pos)
	if _sway != null:
		_sway.rotation.y = sin(_t * 0.3) * 0.2
