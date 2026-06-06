extends SceneTree
## object_scatter mesh-instance batching — a dense artifact layer should bake to
## MultiMeshInstance3D (1 draw call/mesh) when the artifact has a static mesh, and
## fall back to capped real instances otherwise. No GPU needed (we inspect nodes).
##   godot --headless --xr-mode off --path . --script res://commons/testing/test_object_batch.gd

const Scatter = preload("res://commons/biome_layers/object_scatter.gd")
const Palette = preload("res://commons/biome_layers/artifact_palette.gd")

var _fails := 0
func _ok(c: bool, l: String) -> void:
	print(("  PASS  " if c else "  FAIL  ") + l)
	if not c: _fails += 1

func _has_static_mesh(node: Node) -> bool:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		return true
	for c in node.get_children():
		if _has_static_mesh(c):
			return true
	return false

func _count_type(node: Node, t) -> int:
	var n := 0
	for c in node.get_children():
		if is_instance_of(c, t):
			n += 1
	return n

func _initialize() -> void:
	var art := "prefab_sculpture"
	_ok(Palette.has(art), "test artifact '%s' is registered" % art)

	# Does this artifact expose a static mesh after _ready? Decides expected path.
	var probe = Palette.scene_for(art).instantiate()
	get_root().add_child(probe)
	await process_frame
	var has_mesh := _has_static_mesh(probe)
	probe.queue_free()
	print("  INFO  '%s' static mesh present after _ready: %s" % [art, str(has_mesh)])

	# Dense object layer → many placements (random over 12x12 ≈ 100+).
	var scatter := Node3D.new()
	scatter.set_script(Scatter)
	get_root().add_child(scatter)
	var ctx := {
		"paint_layers": [{"element": "object", "mode": "random", "density": 0.8, "artifacts": [art]}],
		"grid_dims": Vector3i(12, 1, 12),
		"cube_size": 1.0,
		"rng_seed": 4242,
		"budget_scale": 1.0,
		"stage_order": 999,
	}
	scatter.apply(ctx)
	await process_frame

	var mmis := _count_type(scatter, MultiMeshInstance3D)
	var insts := 0
	for c in scatter.get_children():
		if (c is Node3D) and not (c is MultiMeshInstance3D):
			insts += 1
	print("  INFO  scatter children: %d MultiMeshInstance3D, %d other Node3D" % [mmis, insts])
	_ok(mmis + insts > 0, "dense layer placed something")

	if has_mesh:
		_ok(mmis > 0, "static-mesh artifact baked to MultiMeshInstance3D (batched)")
		var total_baked := 0
		var coherent := true
		for c in scatter.get_children():
			if c is MultiMeshInstance3D:
				var mm := (c as MultiMeshInstance3D).multimesh
				_ok(mm != null and mm.instance_count > 0, "MultiMesh has instances (%d)" % (mm.instance_count if mm else -1))
				total_baked = maxi(total_baked, mm.instance_count if mm else 0)
				# first transform must be finite (no NaN from bad bake)
				if mm and mm.instance_count > 0:
					var o := mm.get_instance_transform(0).origin
					if not (is_finite(o.x) and is_finite(o.y) and is_finite(o.z)):
						coherent = false
		_ok(coherent, "baked instance transforms are finite")
		_ok(total_baked <= Scatter.BATCH_CAP, "baked count %d within BATCH_CAP %d" % [total_baked, Scatter.BATCH_CAP])
	else:
		_ok(insts > 0 and insts <= Scatter.INSTANCE_CAP, "procedural artifact fell back to capped instances (%d <= %d)" % [insts, Scatter.INSTANCE_CAP])

	print("RESULT: ", "OK" if _fails == 0 else "%d FAIL" % _fails)
	quit(_fails)
