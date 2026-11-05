class_name StandingGrid
extends Node3D
## A GRID STANDING IN A LARGE FRAME (Palle, 2026-11-05: "in point trace add a 4 meter high and 8 meter long grid
## standing in a large frame"; and in Melencolia "a grid in front ... like in durer grid study but larger"). Dürer's
## drawing screen (dgrid, commons/primitives/frame/durer_grid.gd: a wire net in a light frame, a metre across) at the
## size of a wall: a net of thin strings, `cell` apart, held in a heavy frame - two posts, a head beam and a sill -
## standing on two feet. The strings are only seen, never touched (a hand passes through, as through a veil); the
## frame is solid. The net's lower edge is `base` over the floor.
##   config: length (m, the net along x), height (m, the net), cell (m), base (m), frame (m, the beams' section),
##           finish timber | black | white, feet (true/false), strings (a colour)
## The origin is the middle of the sill on the floor; the net is the plane z = 0.

@export var length := 8.0
@export var height := 4.0
@export var cell := 0.5
@export var base := 0.3
@export var frame := 0.16
@export_enum("timber", "black", "white") var finish := "timber"
@export var feet := true
@export var strings := Color("1b1b1d")

const FINISH := {"timber": Color("8a6a46"), "black": Color("1e1f22"), "white": Color("e9e6df")}
const STRING_W := 0.012

func apply_grid_config(config: Dictionary) -> void:
	for key in ["length", "height", "cell", "base", "frame"]:
		if config.has(key) and str(config[key]).is_valid_float():set(key, float(str(config[key])))
	if config.has("finish") and str(config.finish) in FINISH:finish = str(config.finish)
	if config.has("feet"):feet = str(config.feet).to_lower() not in ["false", "0", "no"]
	if config.has("strings"):strings = Color(str(config.strings))
	length = clampf(length, 1.0, 20.0);height = clampf(height, .5, 5.0);cell = clampf(cell, .05, 2.0)
	if is_inside_tree() and get_child_count() > 0:_build()

func _ready() -> void:
	var cfg := {}
	for key in ["length", "height", "cell", "base", "frame", "finish", "feet", "strings"]:
		if has_meta("config_" + key):cfg[key] = get_meta("config_" + key)
	apply_grid_config(cfg)
	if get_child_count() == 0:_build()

## Where the net is, in this node's space: its corners (the probe and durer_box read them).
func net_rect() -> Rect2:
	return Rect2(-length * .5, base, length, height)

func _build() -> void:
	for c in get_children():remove_child(c);c.queue_free()
	var wood := StandardMaterial3D.new();wood.albedo_color = FINISH[finish];wood.roughness = .8
	var body := StaticBody3D.new();body.name = "Frame";add_child(body)
	var f := frame
	var top := base + height
	var span := length + 2.0 * f
	_beam(body, "Sill", Vector3(span, f, f), Vector3(0, base - f * .5, 0), wood)
	_beam(body, "Head", Vector3(span, f, f), Vector3(0, top + f * .5, 0), wood)
	for s in [-1.0, 1.0]:
		_beam(body, "Post", Vector3(f, top + f, f), Vector3(s * (length + f) * .5, (top + f) * .5, 0), wood)
		if feet:
			var reach := clampf(height * .32, .6, 1.4)
			_beam(body, "Foot", Vector3(f * 1.1, f * .7, reach * 2.0), Vector3(s * (length + f) * .5, f * .35, 0), wood)
	# the net: one MultiMesh of thin boxes, each scaled to its string
	var mm := MultiMesh.new();mm.transform_format = MultiMesh.TRANSFORM_3D
	var unit := BoxMesh.new();unit.size = Vector3.ONE;mm.mesh = unit
	var cols := maxi(1, int(round(length / cell)))
	var rows := maxi(1, int(round(height / cell)))
	var xs: Array = []
	for i in range(1, cols):xs.append(-length * .5 + length * i / cols)
	var ys: Array = []
	for j in range(1, rows):ys.append(base + height * j / rows)
	mm.instance_count = xs.size() + ys.size()
	var k := 0
	for x in xs:
		mm.set_instance_transform(k, Transform3D(Basis.from_scale(Vector3(STRING_W, height, STRING_W)), Vector3(x, base + height * .5, 0)));k += 1
	for y in ys:
		mm.set_instance_transform(k, Transform3D(Basis.from_scale(Vector3(length, STRING_W, STRING_W)), Vector3(0, y, 0)));k += 1
	var net := MultiMeshInstance3D.new();net.name = "Net";net.multimesh = mm
	var sm := StandardMaterial3D.new();sm.albedo_color = strings;sm.roughness = .9;net.material_override = sm
	net.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(net)
	# the capture's AABB counts MeshInstance3D only: an invisible anchor the net's size
	var anchor := MeshInstance3D.new();anchor.name = "NetBounds";var am := BoxMesh.new();am.size = Vector3(length, height, .02);anchor.mesh = am
	anchor.position = Vector3(0, base + height * .5, 0);anchor.layers = 0;add_child(anchor)

func _beam(body: StaticBody3D, n: String, size: Vector3, at: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new();mi.name = n;var bm := BoxMesh.new();bm.size = size;mi.mesh = bm;mi.material_override = mat;mi.position = at;add_child(mi)
	var cs := CollisionShape3D.new();cs.name = n + "Shape";var bs := BoxShape3D.new();bs.size = size;cs.shape = bs;cs.position = at;body.add_child(cs)
