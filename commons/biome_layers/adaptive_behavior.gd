# adaptive_behavior.gd
# Seq 15: machine learning. Creatures gain a "memory ring" — visual indicator
# that the world has learned something. Ring intensity pulses with time, simulating
# weights updating. A halo on prior critters from dna_creatures or swarm_creatures.

extends Node3D

var _rings: Array = []


func apply(ctx: Dictionary) -> void:
	var accrual: Node = ctx.get("accrual_root", null)
	if not accrual:
		return
	# Find dna_creatures and swarm_creatures layers; halo their children.
	for prior in accrual.get_children():
		var n: String = str(prior.name)
		if n.ends_with("dna_creatures") or n.ends_with("swarm_creatures"):
			_halo_children(prior)


func _halo_children(layer: Node) -> void:
	for child in layer.get_children():
		if not child is Node3D:
			continue
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.25
		torus.outer_radius = 0.32
		ring.mesh = torus
		ring.position = Vector3(0, 0.6, 0)
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		var col := Color(0.4, 1.0, 0.8, 0.7)
		mat.albedo_color = col
		mat.emission_enabled = true
		mat.emission = col
		mat.emission_energy_multiplier = 1.5
		ring.material_override = mat
		(child as Node3D).add_child(ring)
		_rings.append({"mi": ring, "phase": randf() * TAU})


func _process(_delta: float) -> void:
	var t: float = Time.get_ticks_msec() / 1000.0
	for r in _rings:
		var mi: MeshInstance3D = r.mi
		if not is_instance_valid(mi):
			continue
		var mat := mi.material_override as StandardMaterial3D
		if mat:
			mat.emission_energy_multiplier = 1.0 + absf(sin(t * 2.0 + r.phase)) * 1.5
