## LSystemBranchOp — Drive mesh branching via L-System string rewriting.
## Bridge between the existing LSystem class (utils/lsystem.gd) and mesh grammar.
## Generates an L-system string, then interprets it as a sequence of tube-branch
## and rotation operations applied to selected faces of the mesh.
## Inspired by: fractal trees, coral branching, fungal networks.
## Params:
##   axiom: String = "F"           — L-system starting axiom
##   rules: Dictionary = {}        — L-system production rules {symbol: replacement}
##   lsystem_generations: int = 2  — number of L-system rewrite generations
##   preset: String = ""           — use a preset: "tree", "bush", "plant", "3d_tree"
##   step_length: float = 0.15     — tube length per 'F' command
##   step_taper: float = 0.85      — radius multiplier per generation
##   start_radius: float = 0.03    — starting tube radius
##   angle_degrees: float = 25.0   — rotation angle for +/- commands
##   tube_segments: int = 4        — tube ring resolution
##   tube_rings: int = 3           — segments along each tube
##   max_branches: int = 50        — safety limit on number of tubes
##   branch_tag: String = "lsys_branch"
##   tip_tag: String = "lsys_tip"
extends "res://commons/mesh_grammar/mesh_rule.gd"
class_name LSystemBranchOp

func _execute(mesh, selected: PackedInt32Array) -> void:
	var axiom: String = params.get("axiom", "F")
	var lsys_rules: Dictionary = params.get("rules", {})
	var lsys_gens: int = params.get("lsystem_generations", 2)
	var preset: String = params.get("preset", "")
	var step_length: float = params.get("step_length", 0.15)
	var step_taper: float = params.get("step_taper", 0.85)
	var start_radius: float = params.get("start_radius", 0.03)
	var angle_deg: float = params.get("angle_degrees", 25.0)
	var tube_seg: int = params.get("tube_segments", 4)
	var tube_rings: int = params.get("tube_rings", 3)
	var max_branches: int = params.get("max_branches", 50)
	var branch_tag: String = params.get("branch_tag", "lsys_branch")
	var tip_tag: String = params.get("tip_tag", "lsys_tip")

	# Create L-system
	var lsys: LSystem = LSystem.new(axiom)

	if preset != "":
		# Use a preset L-system
		match preset:
			"tree":
				lsys = LSystem.create_tree()
			"bush":
				lsys = LSystem.create_bush()
			"plant":
				lsys = LSystem.create_plant()
			"3d_tree":
				lsys = LSystem.create_3d_tree()
			"fractal_plant":
				lsys = LSystem.create_fractal_plant()
			_:
				lsys = LSystem.create_tree()
	else:
		# Use custom rules
		for symbol in lsys_rules:
			lsys.add_rule(symbol, lsys_rules[symbol])

	# Generate the L-system string
	lsys.generate_n(lsys_gens)
	var sentence: String = lsys.get_sentence()

	# Interpret the L-system string as mesh operations
	# We grow from each selected face
	var angle_rad: float = deg_to_rad(angle_deg)
	var branch_count: int = 0

	for face_idx in selected:
		if face_idx >= mesh.faces.size():
			continue
		if branch_count >= max_branches:
			break

		var start_normal: Vector3 = mesh.get_face_normal(face_idx)
		var start_pos: Vector3 = mesh.get_face_centroid(face_idx)

		# Turtle state for interpreting L-system
		var turtle_pos: Vector3 = start_pos
		var turtle_dir: Vector3 = start_normal.normalized()
		var turtle_right: Vector3
		if abs(turtle_dir.dot(Vector3.UP)) < 0.99:
			turtle_right = turtle_dir.cross(Vector3.UP).normalized()
		else:
			turtle_right = turtle_dir.cross(Vector3.RIGHT).normalized()
		var turtle_up: Vector3 = turtle_right.cross(turtle_dir).normalized()
		var turtle_radius: float = start_radius
		var turtle_length: float = step_length

		# Stack for branching [and ]
		var stack: Array = []

		for ci in range(sentence.length()):
			if branch_count >= max_branches:
				break

			var ch: String = sentence.substr(ci, 1)
			match ch:
				"F", "S":
					# Move forward and draw a tube segment
					var end_pos: Vector3 = turtle_pos + turtle_dir * turtle_length
					var end_radius: float = turtle_radius * step_taper
					_add_tube_segment(mesh, turtle_pos, end_pos, turtle_dir,
						turtle_radius, end_radius, tube_seg, tube_rings,
						branch_tag, tip_tag)
					turtle_pos = end_pos
					turtle_radius = end_radius
					branch_count += 1

				"f":
					# Move forward without drawing
					turtle_pos += turtle_dir * turtle_length

				"+":
					# Yaw right
					turtle_dir = (turtle_dir * cos(angle_rad) + turtle_right * sin(angle_rad)).normalized()
					turtle_right = turtle_dir.cross(turtle_up).normalized()

				"-":
					# Yaw left
					turtle_dir = (turtle_dir * cos(angle_rad) - turtle_right * sin(angle_rad)).normalized()
					turtle_right = turtle_dir.cross(turtle_up).normalized()

				"&":
					# Pitch down
					turtle_dir = (turtle_dir * cos(angle_rad) + turtle_up * sin(angle_rad)).normalized()
					turtle_up = turtle_right.cross(turtle_dir).normalized()

				"^":
					# Pitch up
					turtle_dir = (turtle_dir * cos(angle_rad) - turtle_up * sin(angle_rad)).normalized()
					turtle_up = turtle_right.cross(turtle_dir).normalized()

				"/", "'":
					# Roll clockwise
					turtle_right = (turtle_right * cos(angle_rad) + turtle_up * sin(angle_rad)).normalized()
					turtle_up = turtle_right.cross(turtle_dir).normalized()

				"\\":
					# Roll counter-clockwise
					turtle_right = (turtle_right * cos(angle_rad) - turtle_up * sin(angle_rad)).normalized()
					turtle_up = turtle_right.cross(turtle_dir).normalized()

				"|":
					# Turn 180 degrees
					turtle_dir = -turtle_dir
					turtle_right = -turtle_right

				"[":
					# Push state
					stack.append({
						"pos": turtle_pos,
						"dir": turtle_dir,
						"right": turtle_right,
						"up": turtle_up,
						"radius": turtle_radius,
						"length": turtle_length
					})

				"]":
					# Pop state
					if stack.size() > 0:
						var state: Dictionary = stack.pop_back()
						turtle_pos = Vector3(state.get("pos", turtle_pos))
						turtle_dir = Vector3(state.get("dir", turtle_dir))
						turtle_right = Vector3(state.get("right", turtle_right))
						turtle_up = Vector3(state.get("up", turtle_up))
						turtle_radius = float(state.get("radius", turtle_radius))
						turtle_length = float(state.get("length", turtle_length))

				"!":
					# Decrease radius
					turtle_radius *= 0.7

				"'":
					pass  # Already handled as roll

	mesh._adjacency_dirty = true


func _add_tube_segment(mesh, start: Vector3, end: Vector3,
		_direction: Vector3, start_radius: float, end_radius: float,
		segments: int, rings: int, branch_tag: String, tip_tag_str: String) -> void:
	# Build coordinate frame
	var forward: Vector3 = (end - start)
	var length: float = forward.length()
	if length < 0.001:
		return
	forward = forward.normalized()

	var right: Vector3
	if abs(forward.dot(Vector3.UP)) < 0.99:
		right = forward.cross(Vector3.UP).normalized()
	else:
		right = forward.cross(Vector3.RIGHT).normalized()
	var up: Vector3 = right.cross(forward).normalized()

	# Create ring vertices
	var ring_verts: Array[PackedInt32Array] = []
	for ri in range(rings + 1):
		var t: float = float(ri) / float(rings)
		var pos: Vector3 = start.lerp(end, t)
		var radius: float = lerpf(start_radius, end_radius, t)
		var ring: PackedInt32Array = PackedInt32Array()
		for si in range(segments):
			var angle: float = TAU * float(si) / float(segments)
			var offset: Vector3 = (right * cos(angle) + up * sin(angle)) * radius
			ring.append(mesh.add_vertex(pos + offset))
		ring_verts.append(ring)

	# Connect rings with faces
	for ri in range(rings):
		for si in range(segments):
			var si_next: int = (si + 1) % segments
			var tag: String = tip_tag_str if ri == rings - 1 else branch_tag
			mesh.add_face(
				PackedInt32Array([ring_verts[ri][si], ring_verts[ri + 1][si], ring_verts[ri][si_next]]),
				PackedStringArray([tag]))
			mesh.add_face(
				PackedInt32Array([ring_verts[ri][si_next], ring_verts[ri + 1][si], ring_verts[ri + 1][si_next]]),
				PackedStringArray([tag]))
