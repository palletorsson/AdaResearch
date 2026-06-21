extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name SlimeToy

## @identity
## name: Slime Toy
## tier: small
## truth: stick where you land — a frozen walk becomes a branch
##
## Diffusion-Limited Aggregation, held in the hand (~0.35m). One seed sits at the
## centre. Walkers are released from a rim and random-walk until they touch the
## frozen cluster, then they stick forever. The order of arrival paints the
## dendrite: early sticks deep inside, late sticks out at the frosty tips.

@export var particle_count: int = 250
@export var grid_radius: int = 24
@export var core_color: Color = Color(0.55, 0.85, 1.0)
@export var tip_color: Color = Color(0.95, 0.55, 1.0)

const CELL: float = 0.0065

var _field_mi: MultiMeshInstance3D
var _stuck: Array[Vector2i] = []
var _occupied: Dictionary = {}


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	# housing — a clear holding cradle so it reads as a held object
	add_child(_sphere(Vector3.ZERO, 0.18, _glass_mat(Color(0.6, 0.9, 1.0), 0.08)))
	add_child(_billboard_label("DLA", Vector3(0.0, 0.24, 0.0), 28, Color(0.8, 0.95, 1.0)))

	# the aggregation thing
	_grow_cluster()
	_field_mi = _make_field()
	add_child(_field_mi)


func _grow_cluster() -> void:
	_stuck.clear()
	_occupied.clear()
	# seed at origin
	_stick(Vector2i.ZERO)
	var kill_radius: int = grid_radius + 4
	var spawn_radius: float = float(grid_radius)
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	while _stuck.size() < particle_count:
		# release a walker from the rim
		var ang: float = _rng.randf() * TAU
		var w := Vector2i(int(round(cos(ang) * spawn_radius)), int(round(sin(ang) * spawn_radius)))
		var landed: bool = false
		for _step in range(4000):
			# adjacency check — stick if touching the cluster
			var touching: bool = false
			for d: Vector2i in dirs:
				if _occupied.has(w + d):
					touching = true
					break
			if touching:
				_stick(w)
				landed = true
				# grow the spawn ring as the cluster reaches out
				var r: float = sqrt(float(w.x * w.x + w.y * w.y))
				spawn_radius = maxf(spawn_radius, r + 5.0)
				break
			# random step
			var nd: Vector2i = dirs[_rng.randi() % 4]
			w += nd
			# wandered too far — recycle from the rim
			if absi(w.x) > kill_radius or absi(w.y) > kill_radius:
				var a2: float = _rng.randf() * TAU
				w = Vector2i(int(round(cos(a2) * spawn_radius)), int(round(sin(a2) * spawn_radius)))
		if not landed:
			break


func _stick(p: Vector2i) -> void:
	_occupied[p] = true
	_stuck.append(p)


func _field(n: int) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = BoxMesh.new()
	mm.instance_count = n
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 0.16 if emissive else 0.0
	mi.material_override = mat
	return mi


func _make_field() -> MultiMeshInstance3D:
	var n: int = _stuck.size()
	var mi := _field(n)
	var mm: MultiMesh = mi.multimesh
	var box := mm.mesh as BoxMesh
	box.size = Vector3(CELL, CELL, CELL) * 1.4
	var denom: float = maxf(float(n - 1), 1.0)
	for i in range(n):
		var cell: Vector2i = _stuck[i]
		var pos := Vector3(float(cell.x) * CELL, 0.0, float(cell.y) * CELL)
		var t: float = float(i) / denom
		mm.set_instance_transform(i, Transform3D(Basis(), pos))
		mm.set_instance_color(i, core_color.lerp(tip_color, t))
	return mi


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# small held objects sway gently
	rotate_y(delta * 0.4)
