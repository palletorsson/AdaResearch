# animated_primitives.gd
# Seq 2: transformation. The floating lattice begins to MOVE.
# Rotation/scale/translation are deterministic per-index — still slave to
# the rhythm (no randf).
#
# After floating_primitives moved to MultiMesh rendering, this layer animates
# by writing MultiMesh instance transforms per-frame rather than touching
# individual Node3D transforms. One MultiMesh per primitive-type, many
# instances each, all animated in a single _process call.

extends Node3D

var _targets: Array = []  # each: {mmi, bases: Array[Dict{pos, axis, speed, phase, base_rot}]}


func apply(ctx: Dictionary) -> void:
	var params: Dictionary = ctx.get("params", {})
	var rot_min: float = float(params.get("rotate_speed_range", [0.1, 0.8])[0])
	var rot_max: float = float(params.get("rotate_speed_range", [0.1, 0.8])[1])
	var scale_pulse: float = float(params.get("scale_pulse", 0.15))
	var drift_speed: float = float(params.get("drift_speed", 0.3))

	var accrual: Node = ctx.get("accrual_root", null)
	if not accrual:
		return
	var prior: Node = null
	for c in accrual.get_children():
		if str(c.name).ends_with("floating_primitives"):
			prior = c
			break
	if not prior:
		return

	# Each MultiMeshInstance3D under floating_primitives holds many instances.
	# Record per-instance base transform + per-instance animation params.
	var global_idx: int = 0
	for child in prior.get_children():
		if not (child is MultiMeshInstance3D):
			continue
		var mmi: MultiMeshInstance3D = child
		var mm: MultiMesh = mmi.multimesh
		if mm == null:
			continue
		var bases: Array = []
		for i in mm.instance_count:
			var tr: Transform3D = mm.get_instance_transform(i)
			var axis_i: int = global_idx % 3
			var axis: Vector3 = [Vector3.RIGHT, Vector3.UP, Vector3.FORWARD][axis_i]
			var t_norm: float = float(global_idx % 7) / 7.0
			var speed: float = lerp(rot_min, rot_max, t_norm)
			bases.append({
				"base_pos": tr.origin,
				"base_rot": tr.basis,
				"axis": axis,
				"speed": speed,
				"phase": float(global_idx) * 0.37,
				"pulse": scale_pulse,
				"drift": drift_speed,
			})
			global_idx += 1
		_targets.append({"mmi": mmi, "bases": bases})


func _process(_delta: float) -> void:
	var t: float = Time.get_ticks_msec() / 1000.0
	for target in _targets:
		var mmi: MultiMeshInstance3D = target.mmi
		if not is_instance_valid(mmi):
			continue
		var mm: MultiMesh = mmi.multimesh
		if mm == null:
			continue
		var bases: Array = target.bases
		for i in bases.size():
			var b: Dictionary = bases[i]
			var rot := (b.base_rot as Basis).rotated(b.axis, b.speed * t)
			var pulse: float = 1.0 + sin(t * 1.5 + b.phase) * b.pulse
			rot = rot.scaled(Vector3(pulse, pulse, pulse))
			var pos: Vector3 = b.base_pos + Vector3(0, sin(t * b.drift + b.phase) * 0.15, 0)
			mm.set_instance_transform(i, Transform3D(rot, pos))
