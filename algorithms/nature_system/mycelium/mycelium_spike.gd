# mycelium_spike.gd — mycelium thread, milestone 1: the filament render spike.
#
# doc/plans/mycelium_substrate.md. Proves the pipeline the substrate will use:
# an L-system string → a 3D turtle walk → each hypha step swept as a TAPERING
# MorphoSweep tube (radius shrinks with branch depth so strands thin toward
# their tips). Standalone (not wired into the dispatcher yet) — a capture
# surface to validate that MorphoSweep + a turtle read as a branching filament
# web. Space-colonization (the organic target) is milestone 2; batching is
# milestone 3.
extends Node3D
class_name MyceliumSpike

const MorphoSweepClass = preload("res://algorithms/nature_system/morphology/morpho_sweep.gd")

@export var iterations: int = 4
@export var angle_deg: float = 24.0
@export var step_len: float = 0.13
@export var base_radius: float = 0.028
@export var color_hypha: Color = Color(0.62, 0.85, 0.78)  # pale bioluminescent fungal


func _ready() -> void:
	var s: String = _expand("F", iterations)
	var segments: Array = _walk(s)  # [{a, b, depth}]
	var max_depth: int = 0
	for seg in segments:
		max_depth = maxi(max_depth, int(seg["depth"]))
	for seg in segments:
		_render_hypha(seg["a"], seg["b"], int(seg["depth"]))
	# glowing spore tips at the leaves (short/deep segments' far ends)
	for seg in segments:
		if int(seg["depth"]) >= max_depth - 1:
			_spore(seg["b"], _radius_at(int(seg["depth"])) * 1.6)


func _expand(axiom: String, iters: int) -> String:
	var out: String = axiom
	for _i in range(iters):
		var nxt: String = ""
		for ch in out:
			# a sparse 3D branching rule — forward growth with side + pitched shoots
			nxt += "FF[+F][-F][&F]" if ch == "F" else ch
			if nxt.length() > 40000:
				break
		out = nxt
	return out


func _walk(s: String) -> Array:
	var pos: Vector3 = Vector3.ZERO
	var dir: Vector3 = Vector3(0.0, 0.28, 1.0).normalized()  # outward + slight rise
	var depth: int = 0
	var stack: Array = []
	var out: Array = []
	var a: float = deg_to_rad(angle_deg)
	for ch in s:
		match ch:
			"F":
				var ln: float = step_len * pow(0.82, float(depth))
				var nxt: Vector3 = pos + dir * ln
				out.append({"a": pos, "b": nxt, "depth": depth})
				pos = nxt
			"+":
				dir = dir.rotated(Vector3.UP, a).normalized()
			"-":
				dir = dir.rotated(Vector3.UP, -a).normalized()
			"&":
				var right: Vector3 = dir.cross(Vector3.UP)
				if right.length_squared() > 0.0001:
					dir = dir.rotated(right.normalized(), a).normalized()
			"^":
				var right2: Vector3 = dir.cross(Vector3.UP)
				if right2.length_squared() > 0.0001:
					dir = dir.rotated(right2.normalized(), -a).normalized()
			"[":
				stack.push_back([pos, dir, depth])
				depth += 1
			"]":
				if not stack.is_empty():
					var st = stack.pop_back()
					pos = st[0]
					dir = st[1]
					depth = st[2]
	return out


func _radius_at(depth: int) -> float:
	return base_radius * pow(0.64, float(depth))


func _render_hypha(a: Vector3, b: Vector3, depth: int) -> void:
	var r0: float = _radius_at(depth)
	var r1: float = _radius_at(depth + 1) * 0.9  # taper toward the far (younger) end
	var mesh: Mesh = MorphoSweepClass.sweep(
		MorphoSweepClass.profile_circle(6),
		MorphoSweepClass.path_line(a, b),
		MorphoSweepClass.radius_taper(r0, r1),
		0.0, 5, false)
	if mesh == null:
		return
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color_hypha
	mat.roughness = 0.6
	mat.emission_enabled = true
	mat.emission = color_hypha
	mat.emission_energy_multiplier = 0.35
	mi.material_override = mat
	add_child(mi)


func _spore(p: Vector3, r: float) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 6
	sm.rings = 4
	mi.mesh = sm
	var mat := StandardMaterial3D.new()
	var glow := Color(0.8, 0.95, 1.0)
	mat.albedo_color = glow
	mat.emission_enabled = true
	mat.emission = glow
	mat.emission_energy_multiplier = 2.0
	mi.material_override = mat
	mi.position = p
	add_child(mi)
