# Seed Orb — the `seed` catalyst affordance for proceduralgeneration
#
# The player throws a glowing seed. Where it lands, procedural growth happens around it:
# a small terrain bump rises, a few tile-like structures snap into place via constraint
# propagation, a flower/cluster of L-system-style branches grows. The seed is the *input*
# to a generator; the world is the *output*.
#
# This is the new catalyst affordance flagged by the λ_edge sieve as the 5th color of the edge:
# - CA → evolve (cells emerge)
# - fractals → split (recursion makes infinity)
# - lsystems → grow (grammar makes space)
# - procgen → seed (an author isn't needed)
# - swarm → flock (no leader is needed)
#
# @identity: First map where the catalyst issues an emergent generation event.
# @qfep_term: λ — rules constrained by entropy → seeded world.

extends Node3D
class_name SeedOrb

@export_category("Seed Settings")
@export var seed_color: Color = Color(0.55, 0.95, 0.55, 1.0)  # vivid green
@export var glow_color: Color = Color(0.4, 1.0, 0.6, 1.0)
@export var pedestal_color: Color = Color(0.18, 0.22, 0.18, 1.0)
@export var orb_radius: float = 0.18
@export var pedestal_height: float = 0.9
@export var growth_clusters: int = 5
@export var growth_radius: float = 0.9

var _orb: MeshInstance3D
var _pedestal: MeshInstance3D
var _grown_nodes: Array = []
var _t: float = 0.0


func _ready() -> void:
	_build_pedestal()
	_build_orb()
	_build_grown_cluster()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("seed_color"):
		seed_color = config_data["seed_color"]
	if config_data.has("growth_clusters"):
		growth_clusters = int(config_data["growth_clusters"])
	if config_data.has("growth_radius"):
		growth_radius = float(config_data["growth_radius"])


func _process(delta: float) -> void:
	_t += delta
	if is_instance_valid(_orb):
		_orb.position.y = pedestal_height + 0.4 + sin(_t * 1.8) * 0.05
		_orb.rotation.y = _t * 0.6
	# Pulse the grown cluster's emission to suggest active emergence.
	for child in _grown_nodes:
		if is_instance_valid(child):
			var mat := child.material_override as StandardMaterial3D
			if mat:
				mat.emission_energy_multiplier = 0.5 + 0.3 * sin(_t * 2.0 + child.position.x * 3.0)


func _build_pedestal() -> void:
	_pedestal = MeshInstance3D.new()
	_pedestal.name = "Pedestal"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.2
	cyl.bottom_radius = 0.32
	cyl.height = pedestal_height
	_pedestal.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = pedestal_color
	mat.roughness = 0.9
	_pedestal.material_override = mat
	_pedestal.position.y = pedestal_height * 0.5
	add_child(_pedestal)


func _build_orb() -> void:
	_orb = MeshInstance3D.new()
	_orb.name = "Seed"
	var sphere := SphereMesh.new()
	sphere.radius = orb_radius
	sphere.height = orb_radius * 2.0
	_orb.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = seed_color
	mat.emission_enabled = true
	mat.emission = glow_color
	mat.emission_energy_multiplier = 2.0
	mat.metallic = 0.15
	mat.roughness = 0.2
	_orb.material_override = mat
	_orb.position.y = pedestal_height + 0.4
	add_child(_orb)


func _build_grown_cluster() -> void:
	# Around the pedestal, a small ring of grown nodes — placeholder for what the seed grew.
	# In a real implementation this would be procedurally generated when the player throws.
	for i in growth_clusters:
		var angle: float = TAU * float(i) / float(growth_clusters)
		var base_x: float = cos(angle) * growth_radius
		var base_z: float = sin(angle) * growth_radius
		# Each cluster: a small stack of boxes growing vertically.
		var cluster_height := 3
		for j in cluster_height:
			var box := MeshInstance3D.new()
			var bm := BoxMesh.new()
			var scale := 1.0 - float(j) * 0.25
			bm.size = Vector3(0.18 * scale, 0.18, 0.18 * scale)
			box.mesh = bm
			var mat := StandardMaterial3D.new()
			var tint: float = 1.0 - float(j) * 0.15
			mat.albedo_color = Color(seed_color.r * tint, seed_color.g * tint, seed_color.b * tint, 1.0)
			mat.emission_enabled = true
			mat.emission = glow_color
			mat.emission_energy_multiplier = 0.5
			box.material_override = mat
			box.position = Vector3(base_x, 0.1 + 0.18 * float(j), base_z)
			add_child(box)
			_grown_nodes.append(box)
