extends Node3D
class_name RoomSketchRender
## Renders a saved room sketch (line segments) as fat glowing tubes in the actual
## game world. Point it at a sketch JSON written by room_line_sketcher.gd; it
## draws the linework where it sits — origin at the room's (0,0,0) corner.
##
## Placeable as an artifact: include apply_grid_config so a map/lab can pass
## a sketch_path / color / radius override.

const SketchMeshLib := preload("res://commons/tools/room_sketcher/sketch_mesh.gd")

@export_file("*.json") var sketch_path: String = "res://commons/tools/room_sketcher/sketches/room_sketch.json"
@export var line_radius: float = 0.02
@export var line_color: Color = Color(0.20, 0.90, 1.0)
@export var glow: float = 2.5

var _built: bool = false

func _ready() -> void:
	_build()

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("sketch_path"):
		sketch_path = str(config_data["sketch_path"])
	if config_data.has("line_radius"):
		line_radius = float(config_data["line_radius"])
	if config_data.has("line_color"):
		line_color = _parse_color(str(config_data["line_color"]), line_color)
	if config_data.has("glow"):
		glow = float(config_data["glow"])
	if _built:
		for c in get_children():
			c.queue_free()
		_built = false
	_build()

func _build() -> void:
	_built = true
	var d := SketchMeshLib.load_json(sketch_path)
	if d.is_empty():
		push_warning("[RoomSketchRender] no sketch found at %s" % sketch_path)
		return
	var segs := SketchMeshLib.segments_from_dict(d)
	if not segs.is_empty():
		var mat := SketchMeshLib.make_line_material(line_color, glow)
		add_child(SketchMeshLib.build_tubes(segs, line_radius, mat))
	var fills := SketchMeshLib.fills_from_dict(d)
	if not fills.is_empty():
		add_child(SketchMeshLib.build_fills(fills))
	var prims := SketchMeshLib.prims_from_dict(d)
	if not prims.is_empty():
		add_child(SketchMeshLib.build_prims(prims))

func _parse_color(s: String, fallback: Color) -> Color:
	var p := s.split(",")
	if p.size() < 3:
		return fallback
	var a := 1.0
	if p.size() >= 4:
		a = float(p[3])
	return Color(float(p[0]), float(p[1]), float(p[2]), a)
