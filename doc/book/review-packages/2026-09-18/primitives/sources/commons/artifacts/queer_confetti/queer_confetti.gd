extends Node3D
class_name QueerConfetti

## WHAT COMES OUT WHEN SOMETHING IS BROKEN.
##
## 2026-09-01, Palle: "if we do so with the laser or with a hammer create super
## nice queer confetti that disappears soon."
##
## THE PALETTE IS PLURAL ON PURPOSE. The obvious move is a rainbow, and a rainbow
## is one flag — a single agreed image standing in for the whole thing. What
## comes out here is eight saturated hues that do not resolve into any one
## banner, in pieces of four different shapes, at four different sizes, spinning
## at rates that never sync. It reads as celebration and refuses to read as a
## logo, which is the distinction this project spends most of its time on.
##
## AND IT GOES. "Disappears soon" is not a performance concession — a room whose
## destruction leaves permanent debris is a room keeping score. The burst is at
## its brightest for a moment, thins, and frees itself, and afterwards there is
## the broken thing and no evidence of how you felt about it.
##
## USE IT FROM ANYWHERE:
##
##     QueerConfetti.burst(some_node, global_pos)                # a hit
##     QueerConfetti.burst(some_node, global_pos, 90, 1.6)       # a breaking
##
## It parents itself to the node you pass, positions in GLOBAL space, and
## queue_frees when done. Nothing has to remember it exists.

## One MultiMesh per shape, because a confetto is a scrap of a specific thing —
## a square, a strip, a triangle, a disc — and one shape repeated reads as
## machine output rather than as something torn.
const SHAPES := 4

## Eight hues that make no single flag.
const HUES: Array[Color] = [
	Color(0.98, 0.24, 0.53),   # magenta
	Color(0.20, 0.82, 0.95),   # cyan
	Color(0.99, 0.80, 0.16),   # yellow
	Color(0.62, 0.35, 0.94),   # violet
	Color(0.25, 0.88, 0.52),   # green
	Color(0.99, 0.48, 0.16),   # orange
	Color(0.96, 0.96, 0.98),   # white
	Color(0.36, 0.51, 0.98),   # blue
]

@export var count: int = 54
@export var lifetime: float = 1.9
@export var spread: float = 2.6          ## initial speed, m/s
@export var gravity: float = 3.4
@export var piece_m: float = 0.032

var _mm: Array[MultiMeshInstance3D] = []
var _vel: Array = []                     ## PackedVector3Array per shape
var _spin: Array = []
var _base: Array = []                    ## starting transforms
var _age := 0.0
var _rng := RandomNumberGenerator.new()
## The seed is a parameter so a probe gets the same burst twice. Unseeded randf
## is how five variants of a generative artifact became five different objects
## in this corpus's own DNA sweeps.
@export var seed_value: int = 0


## The one call anyone else needs.
static func burst(parent: Node, at: Vector3, n: int = 54, scale_up: float = 1.0) -> Node3D:
	if parent == null or not parent.is_inside_tree():
		return null
	# Loaded by PATH, not by the class name. `QueerConfetti.new()` inside the
	# class that declares it fails to compile in a fresh headless boot, because
	# the global class cache has not been reimported — the same trap that has
	# already cost this session two rounds.
	var c = load("res://commons/artifacts/queer_confetti/queer_confetti.gd").new()
	c.count = int(max(4, n))
	c.spread *= scale_up
	c.piece_m *= scale_up
	parent.add_child(c)
	c.global_position = at
	return c


func _ready() -> void:
	_rng.seed = seed_value if seed_value != 0 else hash(str(global_position))
	_build()
	set_process(true)


func _build() -> void:
	var per: int = int(ceil(float(count) / float(SHAPES)))
	for s in SHAPES:
		var mmi := MultiMeshInstance3D.new()
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = _shape(s)
		mm.instance_count = per
		mmi.multimesh = mm
		var mat := StandardMaterial3D.new()
		mat.vertex_color_use_as_albedo = true
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED   # scraps have two sides
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mmi.material_override = mat
		add_child(mmi)

		var v := PackedVector3Array()
		var w := PackedVector3Array()
		var b: Array = []
		for i in per:
			var dir := Vector3(_rng.randfn(0.0, 1.0), _rng.randfn(0.6, 0.8),
					_rng.randfn(0.0, 1.0)).normalized()
			v.append(dir * spread * _rng.randf_range(0.5, 1.35))
			w.append(Vector3(_rng.randf_range(-9, 9), _rng.randf_range(-9, 9),
					_rng.randf_range(-9, 9)))
			var t := Transform3D(Basis(), Vector3.ZERO)
			b.append(t)
			mm.set_instance_transform(i, t)
			mm.set_instance_color(i, HUES[_rng.randi_range(0, HUES.size() - 1)])
		_mm.append(mmi)
		_vel.append(v)
		_spin.append(w)
		_base.append(b)


func _shape(i: int) -> Mesh:
	var m := QuadMesh.new()
	match i:
		0: m.size = Vector2(piece_m, piece_m)                    # square
		1: m.size = Vector2(piece_m * 0.34, piece_m * 1.9)       # strip
		2: m.size = Vector2(piece_m * 1.5, piece_m * 0.5)        # ribbon
		_: m.size = Vector2(piece_m * 0.75, piece_m * 0.75)      # small square
	return m


func _process(delta: float) -> void:
	_age += delta
	var t: float = clampf(_age / maxf(lifetime, 0.01), 0.0, 1.0)
	if t >= 1.0:
		queue_free()
		return
	# Fade the whole burst out over its last third, so it thins rather than
	# blinking off — the difference between something ending and being switched off.
	var fade: float = 1.0 if t < 0.66 else 1.0 - (t - 0.66) / 0.34

	for s in _mm.size():
		var mmi: MultiMeshInstance3D = _mm[s]
		var mm := mmi.multimesh
		var v: PackedVector3Array = _vel[s]
		var w: PackedVector3Array = _spin[s]
		var b: Array = _base[s]
		for i in mm.instance_count:
			var vel: Vector3 = v[i]
			vel.y -= gravity * delta
			vel *= 0.985                     # air
			v[i] = vel
			var tr: Transform3D = b[i]
			tr.origin += vel * delta
			tr.basis = tr.basis.rotated(Vector3.RIGHT, w[i].x * delta) \
					.rotated(Vector3.UP, w[i].y * delta) \
					.rotated(Vector3.FORWARD, w[i].z * delta)
			b[i] = tr
			mm.set_instance_transform(i, tr)
			var col: Color = mm.get_instance_color(i)
			col.a = fade
			mm.set_instance_color(i, col)
		_vel[s] = v
		_base[s] = b
