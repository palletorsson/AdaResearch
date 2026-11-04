class_name ParallelBeams
extends Node3D
## PARALLEL BEAMS (Palle, 2026-11-03): "in point line add three black beams from floor to ceiling that are parallel and
## rotate 15 degrees" - the upgrade his workbench notes asked of parallel_lines ("black all the way to the ceiling").
## The small parallel_lines (commons/primitives/line/parallel_lines.tscn) stands three line modules leaning 15 degrees
## in the plane they are spaced in, like hatching: / / /. These are the same three lines at the scale of the room -
## square black beams from the floor into the ceiling, one direction, one lean, equal gaps - so the visitor walks
## between them: a line inside large parallel lines.
##
## The origin is the floor at the middle of the group: the beams lean toward +x, are spaced along x, and their
## mid-heights stand centred on the origin, so each foot sits half the lean's run (height x tan(lean) / 2) to the -x
## side of its top. Each beam runs a few centimetres into the floor and the ceiling, so no seam shows at either end.
## Solid: each beam carries its own box collider.

@export var count := 3
@export var lean_deg := 15.0
@export var height_m := 5.64        # a Void storey's clear height: 6 m less the 0.36 m slab
@export var spacing_m := 1.8        # foot to foot along x: an upright visitor clears the 15-degree lean between two
@export var section_m := 0.24       # square section
@export var color := Color("0b0b0c")
@export var collide := true

const EMBED := 0.06   # into the floor and into the ceiling

var beams: Array[Node3D] = []

func apply_grid_config(config: Dictionary) -> void:
	var before := [count, lean_deg, height_m, spacing_m, section_m, color, collide]
	if config.has("count") and str(config.count).is_valid_int(): count = clampi(int(str(config.count)), 1, 12)
	if config.has("lean_deg") and str(config.lean_deg).is_valid_float(): lean_deg = clampf(float(str(config.lean_deg)), -60.0, 60.0)
	if config.has("height_m") and str(config.height_m).is_valid_float(): height_m = clampf(float(str(config.height_m)), 0.5, 40.0)
	if config.has("spacing_m") and str(config.spacing_m).is_valid_float(): spacing_m = clampf(float(str(config.spacing_m)), 0.1, 10.0)
	if config.has("section_m") and str(config.section_m).is_valid_float(): section_m = clampf(float(str(config.section_m)), 0.02, 2.0)
	if config.has("color") and Color.html_is_valid(str(config.color)): color = Color.html(str(config.color))
	if config.has("collide"): collide = str(config.collide) not in ["0", "false", "off", "no"]
	if is_inside_tree() and not beams.is_empty() and before != [count, lean_deg, height_m, spacing_m, section_m, color, collide]:
		_build()

func _ready() -> void:
	var config := {}
	for key in ["count", "lean_deg", "height_m", "spacing_m", "section_m", "color", "collide"]:
		if has_meta("config_" + key): config[key] = get_meta("config_" + key)
	apply_grid_config(config)
	_build()

func _build() -> void:
	for b in beams: b.queue_free()
	beams.clear()
	var lean := deg_to_rad(lean_deg)
	var length := (height_m + 2.0 * EMBED) / cos(lean)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.55
	for i in count:
		var beam: Node3D = StaticBody3D.new() if collide else Node3D.new()
		beam.name = "Beam%d" % i
		# the mid-height of every beam on the floor's centre line, the group centred on the origin
		beam.position = Vector3((i - (count - 1) * 0.5) * spacing_m, height_m * 0.5, 0.0)
		beam.rotation.z = -lean   # +y tipped toward +x
		var mesh := MeshInstance3D.new(); mesh.name = "Mesh"
		var box := BoxMesh.new(); box.size = Vector3(section_m, length, section_m)
		mesh.mesh = box; mesh.material_override = mat
		beam.add_child(mesh)
		if collide:
			var shape := CollisionShape3D.new(); shape.name = "Shape"
			var bs := BoxShape3D.new(); bs.size = box.size; shape.shape = bs
			beam.add_child(shape)
		add_child(beam, true)
		beams.append(beam)

## The beams' direction (all the same), each foot and top on the floor and the ceiling, in this node's space.
func get_state() -> Dictionary:
	var lean := deg_to_rad(lean_deg)
	var dir := Vector3(sin(lean), cos(lean), 0.0)
	var run := height_m * tan(lean)
	var feet: Array = []; var tops: Array = []
	for i in count:
		var x := (i - (count - 1) * 0.5) * spacing_m
		feet.append(Vector3(x - run * 0.5, 0.0, 0.0)); tops.append(Vector3(x + run * 0.5, height_m, 0.0))
	return {"count": count, "lean_deg": lean_deg, "height_m": height_m, "spacing_m": spacing_m, "section_m": section_m,
		"gap_m": spacing_m * cos(lean) - section_m, "direction": dir, "feet": feet, "tops": tops, "collide": collide}
