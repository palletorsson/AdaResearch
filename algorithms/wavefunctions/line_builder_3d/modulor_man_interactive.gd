extends Node3D

## Interactive Le Corbusier's Modulor Man
## Spawns grabbable points at each vertex - drag to reshape the figure
## Based on the Modulor system: 1.83m height, 2.26m with raised arm

@export var point_scene: PackedScene = preload("res://commons/primitives/point/grab_sphere_point.tscn")
@export var line_material: ShaderMaterial = preload("res://commons/resourses/shaders/line_shader.tres")
@export var line_thickness: float = 0.015
@export var tube_sides: int = 8

var points: Array[Node3D] = []
var mesh_instance: MeshInstance3D
var _line_mat: ShaderMaterial = null          # created once — was duplicated EVERY frame
var _last_points := PackedVector3Array()      # the change detector for the rebuild

# Le Corbusier Modulor dimensions (in meters)
const MODULOR_UNITS = {
	"total_height_arm_raised": 2.26,  # Red series: 226cm
	"standing_height": 1.83,           # Red series: 183cm
	"navel_height": 1.13,              # Red series: 113cm
	"solar_plexus": 1.40,              # Red series: 140cm
	"head_height": 0.22,
	"shoulder_width": 0.46,            # Blue series: 46cm
	"arm_span": 1.83,
	"forearm": 0.43,                   # Blue series: 43cm
	"upper_arm": 0.27,                 # Blue series: 27cm
	"hand": 0.18,                      # Blue series: 18cm
	"thigh": 0.70,
	"lower_leg": 0.43,                 # Blue series: 43cm
	"foot": 0.27,                      # Blue series: 27cm
	"torso_width": 0.35,
}

func _ready() -> void:
	mesh_instance = $LineMesh
	_spawn_modulor_points()
	_update_line()

func _process(_delta):
	_update_line()

func _spawn_modulor_points() -> void:
	var parent = $Points
	points.clear()

	# Build the initial point positions from Modulor proportions
	var positions = _get_modulor_positions()

	for i in range(positions.size()):
		var p = point_scene.instantiate()
		p.position = positions[i]
		p.name = "Point_%d" % i
		parent.add_child(p)
		points.append(p)

	print("Modulor Man Interactive: Spawned %d grabbable points" % points.size())

func _get_modulor_positions() -> Array[Vector3]:
	var positions: Array[Vector3] = []

	var base_y = 0.0
	var foot_length = MODULOR_UNITS["foot"]
	var lower_leg = MODULOR_UNITS["lower_leg"]
	var navel = MODULOR_UNITS["navel_height"]
	var solar_plexus = MODULOR_UNITS["solar_plexus"]
	var shoulder_y = MODULOR_UNITS["standing_height"] - MODULOR_UNITS["head_height"]
	var head_top = MODULOR_UNITS["standing_height"]
	var arm_raised = MODULOR_UNITS["total_height_arm_raised"]
	var shoulder_width = MODULOR_UNITS["shoulder_width"] / 2.0
	var hip_width = 0.18
	var forearm = MODULOR_UNITS["forearm"]
	var upper_arm = MODULOR_UNITS["upper_arm"]
	var hand = MODULOR_UNITS["hand"]
	var knee_y = base_y + lower_leg

	# Left foot
	positions.append(Vector3(-hip_width, base_y, 0))
	positions.append(Vector3(-hip_width - foot_length * 0.7, base_y, foot_length * 0.5))
	positions.append(Vector3(-hip_width, base_y, 0))

	# Left leg
	positions.append(Vector3(-hip_width, knee_y, 0))
	positions.append(Vector3(-hip_width, navel, 0))

	# Torso center
	positions.append(Vector3(0, navel, 0))
	positions.append(Vector3(0, solar_plexus, 0))

	# Right shoulder and arm
	positions.append(Vector3(shoulder_width, shoulder_y, 0))
	var right_elbow_y = shoulder_y - upper_arm
	positions.append(Vector3(shoulder_width + 0.15, right_elbow_y, 0))
	var right_hand_y = right_elbow_y - forearm
	positions.append(Vector3(shoulder_width + 0.25, right_hand_y, 0))
	positions.append(Vector3(shoulder_width + 0.3, right_hand_y - hand, 0))

	# Back up right arm
	positions.append(Vector3(shoulder_width + 0.25, right_hand_y, 0))
	positions.append(Vector3(shoulder_width + 0.15, right_elbow_y, 0))
	positions.append(Vector3(shoulder_width, shoulder_y, 0))

	# Left shoulder
	positions.append(Vector3(-shoulder_width, shoulder_y, 0))

	# Left arm raised
	var left_elbow_raised_y = shoulder_y + upper_arm * 0.8
	positions.append(Vector3(-shoulder_width - 0.15, left_elbow_raised_y, 0))
	positions.append(Vector3(-shoulder_width - 0.05, arm_raised, 0))
	positions.append(Vector3(-shoulder_width, arm_raised + hand * 0.5, 0))

	# Back down left arm
	positions.append(Vector3(-shoulder_width - 0.05, arm_raised, 0))
	positions.append(Vector3(-shoulder_width - 0.15, left_elbow_raised_y, 0))
	positions.append(Vector3(-shoulder_width, shoulder_y, 0))

	# Neck
	var neck_top = shoulder_y + 0.08
	positions.append(Vector3(0, neck_top, 0))

	# Head circle
	var head_radius = (head_top - neck_top) * 0.5
	var head_center_y = neck_top + head_radius
	for angle in range(0, 360, 45):
		var rad = deg_to_rad(angle)
		var x = sin(rad) * head_radius
		var y = head_center_y + cos(rad) * head_radius
		positions.append(Vector3(x, y, 0))

	# Back to neck
	positions.append(Vector3(0, neck_top, 0))

	# Down torso to right hip
	positions.append(Vector3(0, solar_plexus, 0))
	positions.append(Vector3(hip_width, navel, 0))

	# Right leg
	positions.append(Vector3(hip_width, knee_y, 0))
	positions.append(Vector3(hip_width, base_y, 0))

	# Right foot
	positions.append(Vector3(hip_width + foot_length * 0.7, base_y, foot_length * 0.5))
	positions.append(Vector3(hip_width, base_y, 0))

	return positions

func _update_line() -> void:
	if points.size() < 2:
		return

	# Rebuild ONLY when a point moved (2026-08-20). This ran the full
	# SurfaceTool sweep — ~1,800 vertices, generate_normals, and a freshly
	# DUPLICATED ShaderMaterial — every frame, dragged or parked, and the
	# museum stands the figure where nobody can drag it at all. The figure
	# still reshapes live under a grab; parked, a frame costs one position
	# compare. The material is created once and reused.
	var cur := PackedVector3Array()
	cur.resize(points.size())
	for pi in range(points.size()):
		cur[pi] = to_local(points[pi].global_position)
	if cur == _last_points and mesh_instance != null and mesh_instance.mesh != null:
		return
	_last_points = cur

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	if _line_mat == null:
		_line_mat = _create_line_material()
	var mat := _line_mat
	st.set_material(mat)

	for i in range(points.size() - 1):
		var p1 = cur[i]
		var p2 = cur[i + 1]
		var segment_dir = (p2 - p1).normalized()

		var up = Vector3.UP
		if abs(segment_dir.dot(up)) > 0.9:
			up = Vector3.RIGHT
		var right = segment_dir.cross(up).normalized()
		var forward = right.cross(segment_dir).normalized()

		var uv_x1 = float(i) / float(points.size() - 1)
		var uv_x2 = float(i + 1) / float(points.size() - 1)

		for side in range(tube_sides):
			var angle1 = (float(side) / tube_sides) * TAU
			var angle2 = (float(side + 1) / tube_sides) * TAU

			var offset1 = (right * cos(angle1) + forward * sin(angle1)) * line_thickness
			var offset2 = (right * cos(angle2) + forward * sin(angle2)) * line_thickness

			st.set_uv(Vector2(uv_x1, float(side) / tube_sides))
			st.add_vertex(p1 + offset1)
			st.set_uv(Vector2(uv_x2, float(side) / tube_sides))
			st.add_vertex(p2 + offset1)
			st.set_uv(Vector2(uv_x2, float(side + 1) / tube_sides))
			st.add_vertex(p2 + offset2)

			st.set_uv(Vector2(uv_x1, float(side) / tube_sides))
			st.add_vertex(p1 + offset1)
			st.set_uv(Vector2(uv_x2, float(side + 1) / tube_sides))
			st.add_vertex(p2 + offset2)
			st.set_uv(Vector2(uv_x1, float(side + 1) / tube_sides))
			st.add_vertex(p1 + offset2)

	st.generate_normals()
	var mesh := st.commit()
	mesh_instance.mesh = mesh
	mesh_instance.material_override = mat

func _create_line_material() -> ShaderMaterial:
	var mat := line_material.duplicate() as ShaderMaterial
	mat.set_shader_parameter("time_offset", 0.0)
	mat.set_shader_parameter("flow_speed", 0.5)
	mat.set_shader_parameter("glow_intensity", 1.8)
	mat.set_shader_parameter("thickness_variation", 0.0)
	mat.set_shader_parameter("pulse_frequency", 0.0)
	return mat

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
