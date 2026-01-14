extends Node3D

## Le Corbusier's Modulor Man as a single continuous line
## Based on the Modulor system: 1.83m height, 2.26m with raised arm
## All measurements in meters, following the golden ratio (φ ≈ 1.618)

@export var line_material: ShaderMaterial = preload("res://commons/resourses/shaders/line_shader.tres")
@export var line_thickness: float = 0.015
@export var tube_sides: int = 8

var mesh_instance: MeshInstance3D
var line_points: Array[Vector3] = []

# Le Corbusier Modulor dimensions (in meters)
const MODULOR_UNITS = {
	"total_height_arm_raised": 2.26,  # Red series: 226cm
	"standing_height": 1.83,           # Red series: 183cm
	"navel_height": 1.13,              # Red series: 113cm (golden section of 183)
	"solar_plexus": 1.40,              # Red series: 140cm
	"head_height": 0.22,               # Approximate head (1.83 - 1.61)
	"shoulder_width": 0.46,            # Blue series: 46cm (quarter of 183)
	"arm_span": 1.83,                  # Equal to height
	"forearm": 0.43,                   # Blue series: 43cm
	"upper_arm": 0.27,                 # Blue series: 27cm
	"hand": 0.18,                      # Blue series: 18cm
	"thigh": 0.70,                     # Approximation
	"lower_leg": 0.43,                 # Blue series: 43cm
	"foot": 0.27,                      # Blue series: 27cm
	"torso_width": 0.35,               # Approximate chest width
}

func _ready():
	mesh_instance = $LineMesh
	_build_modulor_path()
	_update_line()

## Build the continuous line path for Modulor Man
## Path: Left foot → left leg → torso → right arm → left arm → head → right leg → right foot
func _build_modulor_path():
	line_points.clear()

	# Center the figure at origin
	var base_y = 0.0

	# Key proportions
	var foot_length = MODULOR_UNITS["foot"]
	var lower_leg = MODULOR_UNITS["lower_leg"]
	var thigh = MODULOR_UNITS["thigh"]
	var navel = MODULOR_UNITS["navel_height"]
	var solar_plexus = MODULOR_UNITS["solar_plexus"]
	var shoulder_y = MODULOR_UNITS["standing_height"] - MODULOR_UNITS["head_height"]
	var head_top = MODULOR_UNITS["standing_height"]
	var arm_raised = MODULOR_UNITS["total_height_arm_raised"]

	var shoulder_width = MODULOR_UNITS["shoulder_width"] / 2.0
	var hip_width = 0.18  # Narrower than shoulders
	var forearm = MODULOR_UNITS["forearm"]
	var upper_arm = MODULOR_UNITS["upper_arm"]
	var hand = MODULOR_UNITS["hand"]

	# Start: Left foot (bottom left)
	line_points.append(Vector3(-hip_width, base_y, 0))
	line_points.append(Vector3(-hip_width - foot_length * 0.7, base_y, foot_length * 0.5))
	line_points.append(Vector3(-hip_width, base_y, 0))

	# Left lower leg (0.43m)
	var knee_y = base_y + lower_leg
	line_points.append(Vector3(-hip_width, knee_y, 0))

	# Left thigh to hip (0.70m)
	line_points.append(Vector3(-hip_width, navel, 0))

	# Hip to navel to solar plexus (torso center)
	line_points.append(Vector3(0, navel, 0))
	line_points.append(Vector3(0, solar_plexus, 0))

	# Torso to right shoulder
	line_points.append(Vector3(shoulder_width, shoulder_y, 0))

	# Right upper arm down (0.27m)
	var right_elbow_y = shoulder_y - upper_arm
	line_points.append(Vector3(shoulder_width + 0.15, right_elbow_y, 0))

	# Right forearm (0.43m)
	var right_hand_y = right_elbow_y - forearm
	line_points.append(Vector3(shoulder_width + 0.25, right_hand_y, 0))

	# Right hand (0.18m)
	line_points.append(Vector3(shoulder_width + 0.3, right_hand_y - hand, 0))

	# Back up right arm to shoulder
	line_points.append(Vector3(shoulder_width + 0.25, right_hand_y, 0))
	line_points.append(Vector3(shoulder_width + 0.15, right_elbow_y, 0))
	line_points.append(Vector3(shoulder_width, shoulder_y, 0))

	# Across shoulders
	line_points.append(Vector3(-shoulder_width, shoulder_y, 0))

	# Left upper arm raised (Le Corbusier's signature pose)
	var left_elbow_raised_y = shoulder_y + upper_arm * 0.8
	line_points.append(Vector3(-shoulder_width - 0.15, left_elbow_raised_y, 0))

	# Left forearm raised to full height (2.26m)
	line_points.append(Vector3(-shoulder_width - 0.05, arm_raised, 0))

	# Left hand raised
	line_points.append(Vector3(-shoulder_width, arm_raised + hand * 0.5, 0))

	# Back down left arm
	line_points.append(Vector3(-shoulder_width - 0.05, arm_raised, 0))
	line_points.append(Vector3(-shoulder_width - 0.15, left_elbow_raised_y, 0))
	line_points.append(Vector3(-shoulder_width, shoulder_y, 0))

	# Neck to head
	var neck_top = shoulder_y + 0.08
	line_points.append(Vector3(0, neck_top, 0))

	# Head circle (simplified as a few points)
	var head_radius = (head_top - neck_top) * 0.5
	var head_center_y = neck_top + head_radius
	for angle in range(0, 360, 45):
		var rad = deg_to_rad(angle)
		var x = sin(rad) * head_radius
		var y = head_center_y + cos(rad) * head_radius
		line_points.append(Vector3(x, y, 0))

	# Back to neck
	line_points.append(Vector3(0, neck_top, 0))

	# Down torso to right hip
	line_points.append(Vector3(0, solar_plexus, 0))
	line_points.append(Vector3(hip_width, navel, 0))

	# Right thigh (0.70m)
	line_points.append(Vector3(hip_width, knee_y, 0))

	# Right lower leg (0.43m)
	line_points.append(Vector3(hip_width, base_y, 0))

	# Right foot (0.27m)
	line_points.append(Vector3(hip_width + foot_length * 0.7, base_y, foot_length * 0.5))
	line_points.append(Vector3(hip_width, base_y, 0))

	print("Modulor Man: Generated %d points for continuous line drawing" % line_points.size())
	_print_segment_lengths()

## Print the length of each segment (educational/proportional reference)
func _print_segment_lengths():
	print("\n=== MODULOR MAN - Segment Lengths (Le Corbusier Proportions) ===")

	var segments = [
		{"name": "Left Foot", "start": 0, "end": 2},
		{"name": "Left Lower Leg (0.43m)", "start": 2, "end": 3},
		{"name": "Left Thigh (0.70m)", "start": 3, "end": 4},
		{"name": "Hip to Navel", "start": 4, "end": 5},
		{"name": "Navel to Solar Plexus", "start": 5, "end": 6},
		{"name": "Torso to Right Shoulder", "start": 6, "end": 7},
		{"name": "Right Upper Arm (0.27m)", "start": 7, "end": 8},
		{"name": "Right Forearm (0.43m)", "start": 8, "end": 9},
		{"name": "Right Hand (0.18m)", "start": 9, "end": 10},
	]

	for seg in segments:
		if seg["end"] < line_points.size():
			var length = line_points[seg["start"]].distance_to(line_points[seg["end"]])
			print("  %s: %.3f m" % [seg["name"], length])

	print("\nKey Modulor Heights:")
	print("  Navel: %.2f m (Red 113)" % MODULOR_UNITS["navel_height"])
	print("  Solar Plexus: %.2f m (Red 140)" % MODULOR_UNITS["solar_plexus"])
	print("  Standing: %.2f m (Red 183)" % MODULOR_UNITS["standing_height"])
	print("  Arm Raised: %.2f m (Red 226)" % MODULOR_UNITS["total_height_arm_raised"])
	print("===============================================================\n")

func _update_line():
	if line_points.size() < 2:
		return

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var mat := _create_line_material()
	st.set_material(mat)

	# Build tube connecting all line points
	for i in range(line_points.size() - 1):
		var p1 = line_points[i]
		var p2 = line_points[i + 1]
		var segment_dir = (p2 - p1).normalized()

		# Perpendicular vectors for tube cross-section
		var up = Vector3.UP
		if abs(segment_dir.dot(up)) > 0.9:
			up = Vector3.RIGHT
		var right = segment_dir.cross(up).normalized()
		var forward = right.cross(segment_dir).normalized()

		var uv_x1 = float(i) / float(line_points.size() - 1)
		var uv_x2 = float(i + 1) / float(line_points.size() - 1)

		# Create tube segment
		for side in range(tube_sides):
			var angle1 = (float(side) / tube_sides) * TAU
			var angle2 = (float(side + 1) / tube_sides) * TAU

			var offset1 = (right * cos(angle1) + forward * sin(angle1)) * line_thickness
			var offset2 = (right * cos(angle2) + forward * sin(angle2)) * line_thickness

			# Triangle 1
			st.set_uv(Vector2(uv_x1, float(side) / tube_sides))
			st.add_vertex(p1 + offset1)
			st.set_uv(Vector2(uv_x2, float(side) / tube_sides))
			st.add_vertex(p2 + offset1)
			st.set_uv(Vector2(uv_x2, float(side + 1) / tube_sides))
			st.add_vertex(p2 + offset2)

			# Triangle 2
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
