# color_tint.gd
# Seq 3: color. Tints prior primitives by deterministic position → HSL.
# No random palettes — hue is a function of (x, z).
#
# Works with MultiMesh instances. Turns on use_colors, sets per-instance
# color from each instance's transform origin. Also ensures the underlying
# material has vertex_color_use_as_albedo so the per-instance color actually
# drives rendering.

extends Node3D


func apply(ctx: Dictionary) -> void:
	var params: Dictionary = ctx.get("params", {})
	var saturation: float = float(params.get("saturation", 0.6))
	var value: float = float(params.get("value", 0.85))

	var accrual: Node = ctx.get("accrual_root", null)
	if not accrual:
		return

	for prior in accrual.get_children():
		if prior == self:
			continue
		_tint_recursive(prior, saturation, value)


func _tint_recursive(node: Node, sat: float, val: float) -> void:
	if node is MultiMeshInstance3D:
		_tint_multimesh(node as MultiMeshInstance3D, sat, val)
	elif node is MeshInstance3D:
		_tint_mesh_instance(node as MeshInstance3D, sat, val)
	for c in node.get_children():
		_tint_recursive(c, sat, val)


func _tint_multimesh(mmi: MultiMeshInstance3D, sat: float, val: float) -> void:
	var mm: MultiMesh = mmi.multimesh
	if mm == null:
		return
	mm.use_colors = true
	_ensure_vertex_color_material(mm.mesh)
	for i in mm.instance_count:
		var p: Vector3 = mm.get_instance_transform(i).origin
		var hue: float = fposmod(atan2(p.z, p.x) / TAU + 0.5, 1.0)
		mm.set_instance_color(i, Color.from_hsv(hue, sat, val))


func _tint_mesh_instance(mi: MeshInstance3D, sat: float, val: float) -> void:
	var p: Vector3 = mi.global_position
	var hue: float = fposmod(atan2(p.z, p.x) / TAU + 0.5, 1.0)
	var col: Color = Color.from_hsv(hue, sat, val)
	var mat: StandardMaterial3D = mi.material_override as StandardMaterial3D
	if not mat:
		mat = StandardMaterial3D.new()
		mi.material_override = mat
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 0.6


## Make sure the mesh's surface material will respect per-instance vertex color.
## Flip vertex_color_use_as_albedo and disable any additive emission so the
## instance color actually reads (additive white emission would wash it out).
func _ensure_vertex_color_material(mesh: Mesh) -> void:
	if mesh == null or mesh.get_surface_count() == 0:
		return
	var mat = mesh.surface_get_material(0)
	if mat is StandardMaterial3D:
		var sm: StandardMaterial3D = mat
		sm.vertex_color_use_as_albedo = true
		# Leave emission alone if it was already off; if it's white/additive,
		# turn it down so it doesn't wash out the instance color.
		if sm.emission_enabled:
			sm.emission = sm.emission.darkened(0.7)
			sm.emission_energy_multiplier = minf(sm.emission_energy_multiplier, 0.4)
