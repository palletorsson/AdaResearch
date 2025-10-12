# ===========================================================================
# NOC Example 8.5: Koch Curve
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

## Example 8.5: Koch Curve
## Koch snowflake fractal curve
## Chapter 08: Fractals

const MAT_PINK := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")

@export var max_depth: int = 4

var _sim_root: Node3D
var _status_label: Label3D
var _lines: Array[Dictionary] = []

func _ready() -> void:
	_setup_environment()
	_generate_koch_curve()
	_draw_curve()
	set_process(false)

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	add_child(_sim_root)


	_status_label = Label3D.new()
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.font_size = 24
	_status_label.modulate = Color(1.0, 0.85, 1.0)
	_status_label.position = Vector3(0, 0.75, 0)
	_status_label.text = "Koch Curve | Depth: %d | Segments: %d" % [max_depth, _lines.size()]
	_sim_root.add_child(_status_label)

func _generate_koch_curve() -> void:
	# Start with a horizontal line
	var start := Vector3(-0.4, 0, 0)
	var end := Vector3(0.4, 0, 0)
	_lines = [{"start": start, "end": end}]

	# Recursively subdivide
	for i in max_depth:
		var new_lines: Array[Dictionary] = []
		for line in _lines:
			new_lines.append_array(_koch_subdivide(line.start, line.end))
		_lines = new_lines

	_status_label.text = "Koch Curve | Depth: %d | Segments: %d" % [max_depth, _lines.size()]

func _koch_subdivide(start: Vector3, end: Vector3) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	var vec := end - start
	var len := vec.length()
	var dir := vec.normalized()

	# Divide line into thirds
	var a := start
	var b := start + dir * (len / 3.0)
	var d := start + dir * (2.0 * len / 3.0)
	var e := end

	# Calculate peak point (equilateral triangle)
	var mid_point := (b + d) / 2.0
	var perpendicular := Vector3(-dir.y, dir.x, 0) # Rotate 90 degrees in XY plane
	var height := (len / 3.0) * sqrt(3.0) / 2.0
	var c := mid_point + perpendicular * height

	# Create 4 new line segments
	result.append({"start": a, "end": b})
	result.append({"start": b, "end": c})
	result.append({"start": c, "end": d})
	result.append({"start": d, "end": e})

	return result

func _draw_curve() -> void:
	for line in _lines:
		_create_line_segment(line.start, line.end)

func _create_line_segment(start: Vector3, end: Vector3) -> void:
	var mesh_instance := MeshInstance3D.new()
	var dir := end - start
	var length := dir.length()
	var mid := (start + end) / 2.0

	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.003
	cylinder.bottom_radius = 0.003
	cylinder.height = length

	mesh_instance.mesh = cylinder
	mesh_instance.position = mid

	# Orient cylinder
	if length > 0.001:
		var up := Vector3.UP
		if abs(dir.normalized().dot(up)) > 0.99:
			up = Vector3.RIGHT
		mesh_instance.look_at(end, up)
		mesh_instance.rotate_object_local(Vector3.RIGHT, PI / 2.0)

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.6, 0.95)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.6, 0.95) * 0.6
	mesh_instance.material_override = material

	_sim_root.add_child(mesh_instance)
