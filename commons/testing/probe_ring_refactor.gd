extends SceneTree
## probe_ring_refactor.gd — the refactored BiomeRingComponent builds the SAME ring as the
## copy of HEAD's file at ada_run/_ring_head.gd (written by the refactor's patch script with
## its class_name stripped). Ground plane, shader parameters, every foliage MultiMesh: names,
## counts, every instance transform and colour, the plant material.
##
## RUN WITHOUT --headless: under the dummy renderer MultiMesh transforms and colours read
## back as identity for every instance, and the comparison would pass on nothing.
##
##   Godot_v4.6-stable_win64.exe --path . --xr-mode off --script res://commons/testing/probe_ring_refactor.gd
##
## Exit 0 when every check holds, 1 otherwise. Delete ada_run/_ring_head.gd afterwards.

const NEW_PATH := "res://commons/grid/BiomeRingComponent.gd"
const OLD_PATH := "res://ada_run/_ring_head.gd"

const CASES := [
	[Vector3i(10, 1, 10), 1.0, "flat", ["flower", "tree", "fungus"], 0.5],
	[Vector3i(6, 1, 8), 1.0, "flat", ["flower"], 0.1],
	[Vector3i(12, 1, 12), 1.0, "hills", ["flower", "tree", "fungus", "creature"], 0.9],
	[Vector3i(9, 1, 5), 0.5, "flat", ["fungus"], 0.3],
]

var _checks := 0
var _fails := 0


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails += 1
		print("  FAIL  ", msg)


func _init() -> void:
	print("[probe_ring_refactor] renderer: `%s`" % RenderingServer.get_video_adapter_name())
	if RenderingServer.get_video_adapter_name() == "":
		print("  FAIL  headless renderer — instance data would read back as identity; run without --headless")
		quit(1)
		return
	if not FileAccess.file_exists(OLD_PATH):
		print("  FAIL  %s missing — run scratchpad/patch_ring.py (it writes HEAD's ring there)" % OLD_PATH)
		quit(1)
		return
	var root := Node3D.new()
	get_root().add_child(root)
	for case in CASES:
		var a: Node3D = load(OLD_PATH).new()
		var b: Node3D = load(NEW_PATH).new()
		root.add_child(a)
		root.add_child(b)
		a.generate(case[0], case[1], case[2], case[3], case[4])
		b.generate(case[0], case[1], case[2], case[3], case[4])
		var tag := "dims %s kingdoms %s density %.1f" % [str(case[0]), str(case[3]), case[4]]
		_compare(a, b, tag)
		root.remove_child(a)
		root.remove_child(b)
		a.free()
		b.free()
	print("[probe_ring_refactor] %d checks, %d failed" % [_checks, _fails])
	quit(0 if _fails == 0 else 1)


func _compare(a: Node3D, b: Node3D, tag: String) -> void:
	_check(is_equal_approx(float(a.ring_width), float(b.ring_width)), "%s: ring_width %s vs %s" % [tag, a.ring_width, b.ring_width])
	_check(is_equal_approx(float(a.fade_width), float(b.fade_width)), "%s: fade_width" % tag)
	# ground
	var ga: MeshInstance3D = a.get_node_or_null("BiomeGround")
	var gb: MeshInstance3D = b.get_node_or_null("BiomeGround")
	_check((ga == null) == (gb == null), "%s: ground presence" % tag)
	if ga != null and gb != null:
		_check((ga.mesh as PlaneMesh).size.is_equal_approx((gb.mesh as PlaneMesh).size), "%s: ground size" % tag)
		_check(ga.position.is_equal_approx(gb.position), "%s: ground position" % tag)
		var ma: Material = ga.material_override
		var mb: Material = gb.material_override
		_check(ma.get_class() == mb.get_class(), "%s: ground material class %s vs %s" % [tag, ma.get_class(), mb.get_class()])
		if ma is ShaderMaterial and mb is ShaderMaterial:
			for p in ["grid_size", "grid_center", "ring_width", "fade_width", "density"]:
				var va: Variant = (ma as ShaderMaterial).get_shader_parameter(p)
				var vb: Variant = (mb as ShaderMaterial).get_shader_parameter(p)
				_check(str(va) == str(vb), "%s: shader param %s %s vs %s" % [tag, p, va, vb])
		elif ma is StandardMaterial3D and mb is StandardMaterial3D:
			_check((ma as StandardMaterial3D).albedo_color.is_equal_approx((mb as StandardMaterial3D).albedo_color), "%s: earth albedo" % tag)
			_check(is_equal_approx((ma as StandardMaterial3D).roughness, (mb as StandardMaterial3D).roughness), "%s: earth roughness" % tag)
	# walk body
	var ba: Node = a.get_node_or_null("BiomeGroundBody")
	var bb: Node = b.get_node_or_null("BiomeGroundBody")
	_check((ba == null) == (bb == null), "%s: walk body presence" % tag)
	if ba != null and bb != null:
		var sa: BoxShape3D = (ba.get_child(0) as CollisionShape3D).shape
		var sb: BoxShape3D = (bb.get_child(0) as CollisionShape3D).shape
		_check(sa.size.is_equal_approx(sb.size), "%s: walk body size" % tag)
	# foliage
	var fa: Array = _foliage(a)
	var fb: Array = _foliage(b)
	_check(fa.size() == fb.size(), "%s: foliage MultiMesh count %d vs %d" % [tag, fa.size(), fb.size()])
	for i in range(mini(fa.size(), fb.size())):
		var ia: MultiMeshInstance3D = fa[i]
		var ib: MultiMeshInstance3D = fb[i]
		_check(ia.name == ib.name, "%s: foliage #%d name %s vs %s" % [tag, i, ia.name, ib.name])
		var mma: MultiMesh = ia.multimesh
		var mmb: MultiMesh = ib.multimesh
		_check(mma.instance_count == mmb.instance_count, "%s: %s instance_count %d vs %d" % [tag, ia.name, mma.instance_count, mmb.instance_count])
		_check(mma.mesh.get_class() == mmb.mesh.get_class(), "%s: %s mesh class" % [tag, ia.name])
		_check(_mesh_sig(mma.mesh) == _mesh_sig(mmb.mesh), "%s: %s mesh dims %s vs %s" % [tag, ia.name, _mesh_sig(mma.mesh), _mesh_sig(mmb.mesh)])
		var bad_t := 0
		var bad_c := 0
		var moved := 0
		for k in range(mini(mma.instance_count, mmb.instance_count)):
			var ta: Transform3D = mma.get_instance_transform(k)
			var tb: Transform3D = mmb.get_instance_transform(k)
			if not ta.is_equal_approx(tb):
				bad_t += 1
			if not ta.origin.is_zero_approx():
				moved += 1
			if not mma.get_instance_color(k).is_equal_approx(mmb.get_instance_color(k)):
				bad_c += 1
		_check(bad_t == 0, "%s: %s %d transforms differ" % [tag, ia.name, bad_t])
		_check(bad_c == 0, "%s: %s %d colours differ" % [tag, ia.name, bad_c])
		_check(moved > 0 or mma.instance_count == 0, "%s: %s reads back identity — the renderer kept no instance data" % [tag, ia.name])
		var pa: StandardMaterial3D = ia.material_override
		var pb: StandardMaterial3D = ib.material_override
		_check(pa.vertex_color_use_as_albedo == pb.vertex_color_use_as_albedo and pa.cull_mode == pb.cull_mode
			and pa.emission_enabled == pb.emission_enabled and pa.emission.is_equal_approx(pb.emission)
			and is_equal_approx(pa.emission_energy_multiplier, pb.emission_energy_multiplier),
			"%s: %s plant material" % [tag, ia.name])
	print("  %s: %d foliage sets, ground %s" % [tag, fb.size(), "ok" if gb != null else "none"])


func _foliage(n: Node3D) -> Array:
	var out: Array = []
	for c in n.get_children():
		if c is MultiMeshInstance3D and String(c.name).begins_with("BiomeFoliage_"):
			out.append(c)
	return out


func _mesh_sig(m: Mesh) -> String:
	if m is QuadMesh:
		return "quad %s %s" % [(m as QuadMesh).size, (m as QuadMesh).center_offset]
	if m is SphereMesh:
		return "sphere %s %s %d %d" % [(m as SphereMesh).radius, (m as SphereMesh).height, (m as SphereMesh).radial_segments, (m as SphereMesh).rings]
	if m is CylinderMesh:
		return "cyl %s %s %s %d" % [(m as CylinderMesh).top_radius, (m as CylinderMesh).bottom_radius, (m as CylinderMesh).height, (m as CylinderMesh).radial_segments]
	if m is CapsuleMesh:
		return "capsule %s %s" % [(m as CapsuleMesh).radius, (m as CapsuleMesh).height]
	return m.get_class()
