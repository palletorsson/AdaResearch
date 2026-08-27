extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name StainedCurtain

## @identity
## lineage: the Through hero — a doorway hung with a bead-curtain of glass strips, the
##   domestic answer to the cathedral window. Each strip carries one tint at one alpha;
##   where strips overlap in your line of sight the tints MULTIPLY, and the floor
##   wears the pooled result as a lying carpet of light.
## essence: alpha is the fraction that continues. A strip at 0.3 keeps its colour's
##   claim on 30% of what passes; two strips compound - transmission is multiplication,
##   which is why the overlaps go rich and dark, never brighter.
## truth: transparency is a toll road, not a window: every pane charges its colour on
##   the way through. Walk the curtain and arrive tinted.
##
## The 2026-08-27 category-heroes pass, color.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")
const TINTS := [
	Color(0.78, 0.16, 0.12), Color(0.92, 0.75, 0.14), Color(0.13, 0.30, 0.62),
	Color(0.20, 0.42, 0.17), Color(0.88, 0.44, 0.66),
]

@export var seed: int = 19
@export var door_w: float = 1.7
@export var door_h: float = 2.3
@export_range(4, 14) var strips: int = 9
## Alpha climbs along the row 0.18 -> 0.55: the curtain itself is a graded lesson in
## how much each strip lets THROUGH.
@export var alpha_min: float = 0.18
@export var alpha_max: float = 0.55

func _ready() -> void:
	_rng.seed = seed
	_build_frame()
	_build_strips()
	_build_pool()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "door_w", "door_h", "strips"]:
		if config_data.has(key):
			set(key, config_data[key])

func _build_frame() -> void:
	var brass := _steel_mat(Color(0.55, 0.48, 0.30))
	for sx in [-1.0, 1.0]:
		var jamb := MeshInstance3D.new()
		var jamb_mesh := BoxMesh.new()
		jamb_mesh.size = Vector3(0.1, door_h + 0.2, 0.1)
		jamb.mesh = jamb_mesh
		jamb.position = Vector3(sx * (door_w * 0.5 + 0.08), (door_h + 0.2) * 0.5, 0.0)
		jamb.material_override = brass
		add_child(jamb)
	var lintel := MeshInstance3D.new()
	var lintel_mesh := BoxMesh.new()
	lintel_mesh.size = Vector3(door_w + 0.36, 0.12, 0.14)
	lintel.mesh = lintel_mesh
	lintel.position = Vector3(0.0, door_h + 0.16, 0.0)
	lintel.material_override = brass
	add_child(lintel)

func _build_strips() -> void:
	# two staggered ranks, so a walker's line of sight always crosses at least two
	# strips somewhere - the compounding is unavoidable, which is the lesson
	for rank in range(2):
		var z := -0.09 + 0.18 * float(rank)
		var n := strips - rank
		for i in range(n):
			var u := (float(i) + (0.5 if rank == 1 else 0.0)) / float(strips - 1)
			var x := (u - 0.5) * (door_w - 0.14)
			var a := alpha_min + (alpha_max - alpha_min) * u
			var strip := MeshInstance3D.new()
			var strip_mesh := BoxMesh.new()
			var drop := door_h - 0.1 - _rng.randf_range(0.0, 0.25)
			strip_mesh.size = Vector3(0.14, drop, 0.02)
			strip.mesh = strip_mesh
			strip.position = Vector3(x, door_h + 0.05 - drop * 0.5, z)
			var gm := StandardMaterial3D.new()
			gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			var col: Color = TINTS[(i + rank * 2) % TINTS.size()]
			gm.albedo_color = Color(col.r, col.g, col.b, a)
			gm.roughness = 0.08
			gm.cull_mode = BaseMaterial3D.CULL_DISABLED
			strip.material_override = gm
			add_child(strip)
			# the hanger ring
			var ring := MeshInstance3D.new()
			var ring_mesh := TorusMesh.new()
			ring_mesh.inner_radius = 0.018
			ring_mesh.outer_radius = 0.03
			ring.mesh = ring_mesh
			ring.position = Vector3(x, door_h + 0.08, z)
			ring.material_override = _steel_mat(Color(0.55, 0.48, 0.30))
			add_child(ring)

func _build_pool() -> void:
	# the lying carpet: pooled tints on the floor where the light lands after paying
	# every toll - painted as overlapping translucent discs, richest in the middle
	for i in range(6):
		var pool := MeshInstance3D.new()
		var pool_mesh := CylinderMesh.new()
		pool_mesh.top_radius = 0.32 - 0.03 * float(i)
		pool_mesh.bottom_radius = 0.32 - 0.03 * float(i)
		pool_mesh.height = 0.006
		pool.mesh = pool_mesh
		var col: Color = TINTS[i % TINTS.size()]
		var pm := StandardMaterial3D.new()
		pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		pm.albedo_color = Color(col.r * 0.7, col.g * 0.7, col.b * 0.7, 0.3)
		pm.emission_enabled = true
		pm.emission = col
		pm.emission_energy_multiplier = 0.25 if emissive else 0.08
		pool.material_override = pm
		pool.position = Vector3(_rng.randf_range(-0.4, 0.4), 0.012 + 0.002 * float(i), 0.55 + _rng.randf_range(0.0, 0.35))
		add_child(pool)

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "CurtainPlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(-(door_w * 0.5 + 0.5), 0.24, 0.7)
	ts.rotation.y = deg_to_rad(35.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("STAINED CURTAIN - alpha",
			"Transparency is a toll road: every strip charges its colour on the fraction\nthat continues. Overlaps multiply - richer and darker, never brighter.\nWalk through and arrive tinted. The floor wears the receipts.")
