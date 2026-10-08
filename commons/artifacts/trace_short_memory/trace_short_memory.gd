extends "res://commons/primitives/point/draw_dot.gd"
## The inherited recorder keeps 32 positions. This variant only thickens their
## display: one bead per retained point, one cord segment per adjacent pair.
## No separate position history, replay, time fade or fabricated reference stroke.
var _beads: MultiMeshInstance3D
var _cord: MultiMeshInstance3D

func _setup_trail() -> void:
	super()
	_trail_instance.visible = false
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = trail_color
	material.emission_enabled = true
	material.emission = trail_color
	material.emission_energy_multiplier = 0.8
	var bead := SphereMesh.new()
	bead.radius = 0.006
	bead.height = 0.012
	bead.radial_segments = 8
	bead.rings = 4
	bead.material = material
	_beads = _instances("RetainedPositions", bead, trail_max_points)
	var strand := CylinderMesh.new()
	strand.top_radius = 0.0035
	strand.bottom_radius = 0.0035
	strand.height = 1.0
	strand.radial_segments = 8
	strand.rings = 1
	strand.material = material
	_cord = _instances("JoinedPositions", strand, maxi(0, trail_max_points - 1))

func _instances(label: String, mesh: Mesh, capacity: int) -> MultiMeshInstance3D:
	var node := MultiMeshInstance3D.new()
	node.name = label
	node.multimesh = MultiMesh.new()
	node.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	node.multimesh.mesh = mesh
	node.multimesh.instance_count = capacity
	node.multimesh.visible_instance_count = 0
	node.top_level = true
	add_child(node)
	node.global_transform = Transform3D.IDENTITY
	return node

func _rebuild_trail() -> void:
	# Render directly from the inherited list: the geometry forgets when it does.
	if not is_instance_valid(_beads) or not is_instance_valid(_cord): return
	var count := _trail_points.size()
	_beads.multimesh.visible_instance_count = count
	_cord.multimesh.visible_instance_count = maxi(0, count - 1)
	for i in range(count):
		_beads.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, _trail_points[i]))
		if i == 0: continue
		var span: Vector3 = _trail_points[i] - _trail_points[i - 1]
		var length := span.length()
		var y := span / length if length > 0.000001 else Vector3.UP
		var helper := Vector3.RIGHT if absf(y.dot(Vector3.UP)) > 0.98 else Vector3.UP
		var x := helper.cross(y).normalized()
		var z := x.cross(y).normalized()
		_cord.multimesh.set_instance_transform(i - 1, Transform3D(Basis(x, y * length, z), (_trail_points[i] + _trail_points[i - 1]) * 0.5))

func clear_trail() -> void:
	super()
	_rebuild_trail()
