class_name DurerBox
extends Node3D
## THE BOX AND THE GRID (Palle, 2026-11-05: "in primitives melancolia add a box around the durer painting sculpture
## with an open front wall so we can see the work but add a grid in front the setup like in durer grid study but
## larger"). Floor 12's sculpture after Melencolia I (the hall's MelencoliaEngraving part) stands in a box of three
## walls up to the ceiling - back and two sides - its front open. In the open front stands Dürer's drawing screen at
## the size of the opening (standing_grid.gd: a string net in a timber frame), and across the shaft, where a visitor
## can stand, Dürer's SIGHT: a post with a small eye-piece at eye height. Put the eye to it and the work is cut into
## cells by the net - the draughtsman's set-up of 1525 (the woodcut of the man drawing a lute and the reclining woman),
## turned round: here the grid is the instrument and the engraving the model.
##   config: width (m, inner, along local x), depth (m, inner, along local z), height (m), wall (m), colour,
##           cell (m, the net), sight_distance (m from the open front to the sight; 0 = none), sight_height (m)
## Local frame: the open front faces +z; the origin is the middle of the box's floor.

const Grid := preload("res://commons/artifacts/primitives_rooms/standing_grid.gd")

@export var width := 7.4
@export var depth := 5.35
@export var height := 5.55
@export var wall := 0.12
@export var colour := Color("34373c")
@export var cell := 0.5
@export var sight_distance := 6.6
@export var sight_height := 1.6

var grid: Node3D
var sight: Node3D

func apply_grid_config(config: Dictionary) -> void:
	for key in ["width", "depth", "height", "wall", "cell", "sight_distance", "sight_height"]:
		if config.has(key) and str(config[key]).is_valid_float():set(key, float(str(config[key])))
	if config.has("colour"):colour = Color(str(config.colour))
	if is_inside_tree() and get_child_count() > 0:_build()

func _ready() -> void:
	var cfg := {}
	for key in ["width", "depth", "height", "wall", "colour", "cell", "sight_distance", "sight_height"]:
		if has_meta("config_" + key):cfg[key] = get_meta("config_" + key)
	apply_grid_config(cfg)
	if get_child_count() == 0:_build()

## The inside of the box, in this node's space.
func inner() -> AABB:
	return AABB(Vector3(-width * .5, 0, -depth * .5), Vector3(width, height, depth))

func _build() -> void:
	for c in get_children():remove_child(c);c.queue_free()
	var paint := StandardMaterial3D.new();paint.albedo_color = colour;paint.roughness = .95
	var body := StaticBody3D.new();body.name = "Walls";add_child(body)
	var w := wall
	_slab(body, "BackWall", Vector3(width + 2.0 * w, height, w), Vector3(0, height * .5, -depth * .5 - w * .5), paint)
	for s in [-1.0, 1.0]:
		_slab(body, "SideWall", Vector3(w, height, depth), Vector3(s * (width + w) * .5, height * .5, 0), paint)
	# the drawing screen fills the open front, its posts on the walls' ends
	grid = Grid.new();grid.name = "Grid"
	grid.length = width;grid.height = minf(height - .9, 4.6);grid.base = .35;grid.cell = cell;grid.frame = .16;grid.feet = false;grid.finish = "timber"
	grid.position = Vector3(0, 0, depth * .5 + w * .5);add_child(grid)
	if sight_distance > 0.0:_build_sight(paint)

## Dürer's sight: a post on a foot, an eye-piece - a small plate with a hole - at eye height, and a word on the floor.
func _build_sight(paint: StandardMaterial3D) -> void:
	sight = Node3D.new();sight.name = "Sight";sight.position = Vector3(0, 0, depth * .5 + sight_distance);add_child(sight)
	var wood := StandardMaterial3D.new();wood.albedo_color = Color("8a6a46");wood.roughness = .8
	var body := StaticBody3D.new();body.name = "SightPost";sight.add_child(body)
	_slab(body, "Foot", Vector3(.4, .05, .4), Vector3(0, .025, 0), paint)
	_slab(body, "Post", Vector3(.06, sight_height - .06, .06), Vector3(0, (sight_height - .06) * .5 + .05, 0), wood)
	var plate := MeshInstance3D.new();plate.name = "EyePiece";var tm := TorusMesh.new();tm.inner_radius = .012;tm.outer_radius = .045
	plate.mesh = tm;plate.material_override = wood;plate.rotation_degrees.x = 90;plate.position = Vector3(0, sight_height, 0);sight.add_child(plate)
	var l := Label3D.new();l.name = "Words";l.text = "PUT YOUR EYE TO THE SIGHT\nTHE GRID CUTS THE WORK INTO CELLS"
	l.font_size = 40;l.pixel_size = .0016;l.modulate = Color("1d1d1f");l.outline_size = 0;l.rotation_degrees.x = -90
	l.position = Vector3(0, .012, .55);sight.add_child(l)

func _slab(body: StaticBody3D, n: String, size: Vector3, at: Vector3, mat: Material) -> void:
	# the mesh beside its body (the box's own node, or the sight's), the shape inside it, both at `at`
	var mi := MeshInstance3D.new();mi.name = n;var bm := BoxMesh.new();bm.size = size;mi.mesh = bm;mi.material_override = mat;mi.position = at
	body.get_parent().add_child(mi)
	var cs := CollisionShape3D.new();cs.name = n + "Shape";var bs := BoxShape3D.new();bs.size = size;cs.shape = bs;cs.position = at;body.add_child(cs)
