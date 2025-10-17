# res://morphogenesis/MorphoBody.gd
extends Node3D

@export var grid_n: int = 32
@export var steps_per_frame: int = 3
@export var feed: float = 0.037
@export var kill: float = 0.065
@export var diff_a: float = 1.0
@export var diff_b: float = 0.5
@export var dt: float = 1.0

@export var bud_threshold: float = 0.28
@export var max_buds: int = 4
@export var torso_radius: Vector3 = Vector3(0.5, 0.8, 0.4)
@export var limb_max_len: float = 0.9
@export var limb_radius: float = 0.06
@export var growth_speed: float = 0.35

var A: PackedFloat32Array
var B: PackedFloat32Array

var buds: Array = []  # each: {"pos": Vector3, "dir": Vector3, "len": float, "mesh": MeshInstance3D}
var inited := false

func _cell(x:int,y:int,z:int) -> int:
	return x + grid_n * (y + grid_n * z)

func _ready():
	_alloc_fields()
	_seed_fields()
	_make_torso_visual()
	inited = true

func _process(delta: float):
	if not inited: return
	for i in range(steps_per_frame):
		_step_rd()
	if buds.is_empty():
		_spawn_buds_from_field()
	else:
		_grow_limbs(delta)

# --- field setup ---
func _alloc_fields():
	var n3 = grid_n * grid_n * grid_n
	A = PackedFloat32Array()
	B = PackedFloat32Array()
	A.resize(n3); B.resize(n3)
	for i in range(n3):
		A[i] = 1.0
		B[i] = 0.0

func _seed_fields():
	var c = (grid_n - 1) * 0.5
	for z in range(grid_n):
		for y in range(grid_n):
			for x in range(grid_n):
				var p = Vector3((x-c)/c, (y-c)/c, (z-c)/c) # -1..1
				if _inside_ellipsoid(p, Vector3.ONE):
					var equator = absf(p.y) < 0.25
					var noise = randf() < 0.03
					if equator and noise:
						var id = _cell(x,y,z)
						B[id] = 1.0
						A[id] = 0.0

func _inside_ellipsoid(p: Vector3, r: Vector3) -> bool:
	return (p.x*p.x)/(r.x*r.x) + (p.y*p.y)/(r.y*r.y) + (p.z*p.z)/(r.z*r.z) <= 1.0

# --- RD simulation (Gray–Scott, 6-neighbour Laplacian) ---
func _lap(buf: PackedFloat32Array, x:int,y:int,z:int) -> float:
	var idx0 = _cell(x,y,z)
	var v = -6.0 * buf[idx0]
	if x > 0:            v += buf[_cell(x-1,y,z)]
	if x < grid_n-1:     v += buf[_cell(x+1,y,z)]
	if y > 0:            v += buf[_cell(x,y-1,z)]
	if y < grid_n-1:     v += buf[_cell(x,y+1,z)]
	if z > 0:            v += buf[_cell(x,y,z-1)]
	if z < grid_n-1:     v += buf[_cell(x,y,z+1)]
	return v

func _step_rd():
	var A2 := A.duplicate()
	var B2 := B.duplicate()
	for z in range(1, grid_n-1):
		for y in range(1, grid_n-1):
			for x in range(1, grid_n-1):
				var i = _cell(x,y,z)
				var a = A[i]
				var b = B[i]
				var ra = diff_a * _lap(A, x,y,z) - a*b*b + feed*(1.0 - a)
				var rb = diff_b * _lap(B, x,y,z) + a*b*b - (kill + feed)*b
				A2[i] = clamp(a + ra * dt, 0.0, 1.0)
				B2[i] = clamp(b + rb * dt, 0.0, 1.0)
	A = A2; B = B2

# --- Bud detection + limb growth ---
func _spawn_buds_from_field():
	var c = (grid_n - 1) * 0.5
	var candidates: Array = []
	for z in range(1, grid_n-1):
		for y in range(1, grid_n-1):
			for x in range(1, grid_n-1):
				var i = _cell(x,y,z)
				var b = B[i]
				if b > bud_threshold:
					var p = Vector3((x-c)/c, (y-c)/c, (z-c)/c) # -1..1
					var d = _ellipsoid_sdf(p, Vector3.ONE)
					if absf(d) < 0.08:
						candidates.append({"p": p, "b": b})
	if candidates.is_empty():
		return
	candidates.sort_custom(func(a,b): return a["b"] > b["b"])
	var picked: Array = []
	for cand in candidates:
		if picked.size() >= max_buds: break
		var ok := true
		for other in picked:
			if (cand["p"] as Vector3).distance_to(other as Vector3) < 0.35:
				ok = false; break
		if ok:
			picked.append(cand["p"])
	for p in picked:
		var dir = (p as Vector3).normalized()
		var limb = _make_capsule(limb_radius, 0.01)
		add_child(limb)
		limb.position = _ellipsoid_scale(p)
		limb.look_at_from_position(limb.position, limb.position + dir, Vector3.UP)
		buds.append({ "pos": p, "dir": dir, "len": 0.01, "mesh": limb })

func _grow_limbs(delta: float):
	for bud in buds:
		bud["len"] = min((bud["len"] as float) + growth_speed * delta, limb_max_len)
		var m: MeshInstance3D = bud["mesh"]
		_update_capsule(m, limb_radius, bud["len"])

func _ellipsoid_scale(p: Vector3) -> Vector3:
	return Vector3(p.x * torso_radius.x, p.y * torso_radius.y, p.z * torso_radius.z)

# Signed-distance (approx) to unit ellipsoid shell
func _ellipsoid_sdf(p: Vector3, r: Vector3) -> float:
	var k0: Vector3 = p.abs() / r
	var k1: float = sqrt(k0.dot(k0)) # sqrt is global
	return k1 - 1.0

# --- Visuals ---
func _make_torso_visual():
	var mesh := MeshInstance3D.new()
	var m := SphereMesh.new()
	m.radius = 0.5
	m.radial_segments = 24
	m.rings = 24
	mesh.mesh = m
	mesh.scale = torso_radius * 2.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.6, 0.85, 1.0)
	mat.roughness = 0.6
	mesh.material_override = mat
	add_child(mesh)

func _make_capsule(r: float, h: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = r
	cap.height = maxf(h, 0.01)
	mi.mesh = cap
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.3, 0.7, 1.0)
	mat.metallic = 0.1
	mat.roughness = 0.4
	mi.material_override = mat
	return mi

func _update_capsule(mi: MeshInstance3D, r: float, h: float):
	var cap := mi.mesh as CapsuleMesh
	cap.radius = r
	cap.height = maxf(h, 0.01)
	mi.mesh = cap
