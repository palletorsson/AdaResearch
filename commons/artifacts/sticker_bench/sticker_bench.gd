extends Node3D
## THE STICKER BENCH: a table with four primitives on it - a box, a sphere, a cylinder and a slab - the same bench the
## encyclopedia's /stickers 3D view draws in three.js, so a sticker stuck on the sphere there is on this sphere here.
## Each primitive is a StaticBody3D whose frame is its own centre (axes as the bench's; the bench's front faces +Z),
## with meta sticker_host {kind: primitive, id} for the pad and a StickerLayer child that draws its stickers. The table
## has no host: in the Void a sticker on it belongs to the bench as a work. The sphere and the cylinder also carry their
## analytic body (meta sticker_surface {shape, r[, h]}, the same dictionary as their layer's `surface`), so a sticker on
## them is laid on the curve as a grid - drawn hugging the body as three.js's decal does, and picked on it by the pad.
##
## The numbers below are COPIED from ada_encyclopedia/src/lib/stickers.ts BENCH (top, length, depth, thickness; each
## item's id, centre and size). Change one, change both. Origin: the floor, under the middle of the table.

const StickerData := preload("res://commons/stickers/sticker_data.gd")
const StickerLayer := preload("res://commons/stickers/sticker_layer.gd")
# --- stickers.ts BENCH ---
const TOP := 0.8
const LENGTH := 3.2
const DEPTH := 0.8
const THICKNESS := 0.06
const ITEMS := [
	{"id": "box", "at": Vector3(-1.2, 0.8 + 0.25, 0), "size": Vector3(0.5, 0.5, 0.5)},
	{"id": "sphere", "at": Vector3(-0.4, 0.8 + 0.3, 0), "r": 0.3},
	{"id": "cylinder", "at": Vector3(0.4, 0.8 + 0.3, 0), "r": 0.22, "h": 0.6},
	{"id": "slab", "at": Vector3(1.2, 0.8 + 0.25, 0), "size": Vector3(0.7, 0.5, 0.04)},
]
# --- the look (not shared) ---
const TIMBER := Color("c9a978")
const TIMBER_DARK := Color("b98d5f")
const PLASTER := Color("e8e4da")
const INK := Color("2b1d14")

var primitives: Dictionary = {}    # id -> its StaticBody3D

func apply_grid_config(_config: Dictionary) -> void:
	pass   # the bench is the bench: its numbers are the shared ones

func _ready() -> void:
	StickerData.get_or_create(get_tree())
	_build()

func _build() -> void:
	# the table: a top and four legs, one body
	var table := StaticBody3D.new()
	table.name = "Table"
	add_child(table)
	_part(table, "Top", _boxmesh(Vector3(LENGTH, THICKNESS, DEPTH)), _boxshape(Vector3(LENGTH, THICKNESS, DEPTH)), Vector3(0, TOP - THICKNESS / 2.0, 0), TIMBER, 0.7)
	var leg := TOP - THICKNESS
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_part(table, "Leg", _boxmesh(Vector3(0.06, leg, 0.06)), _boxshape(Vector3(0.06, leg, 0.06)), Vector3(sx * (LENGTH / 2.0 - 0.08), leg / 2.0, sz * (DEPTH / 2.0 - 0.08)), TIMBER_DARK, 0.75)
	var label := Label3D.new()
	label.name = "Title"
	label.text = "THE STICKER BENCH   box  /  sphere  /  cylinder  /  slab"
	label.font_size = 32
	label.pixel_size = 0.0009
	label.modulate = INK
	label.outline_size = 0
	label.double_sided = false
	label.position = Vector3(0, TOP - THICKNESS / 2.0, DEPTH / 2.0 + 0.002)
	add_child(label)
	# the four primitives, each its own frame and host
	for item in ITEMS:
		var id := str(item.id)
		var body := StaticBody3D.new()
		body.name = id.capitalize()
		body.position = item.at
		body.set_meta("sticker_host", {"kind": "primitive", "id": id})
		add_child(body)
		var mesh: Mesh
		var shape: Shape3D
		var surface := {}
		match id:
			"sphere":
				var sm := SphereMesh.new()
				sm.radius = float(item.r)
				sm.height = 2.0 * float(item.r)
				sm.radial_segments = 64
				sm.rings = 32
				mesh = sm
				var ss := SphereShape3D.new()
				ss.radius = float(item.r)
				shape = ss
				surface = {"shape": "sphere", "r": float(item.r)}
			"cylinder":
				var cm := CylinderMesh.new()
				cm.top_radius = float(item.r)
				cm.bottom_radius = float(item.r)
				cm.height = float(item.h)
				cm.radial_segments = 64
				mesh = cm
				var cs := CylinderShape3D.new()
				cs.radius = float(item.r)
				cs.height = float(item.h)
				shape = cs
				surface = {"shape": "cylinder", "r": float(item.r), "h": float(item.h)}
			_:
				mesh = _boxmesh(item.size)
				shape = _boxshape(item.size)
		_part(body, "Mesh", mesh, shape, Vector3.ZERO, PLASTER, 0.85)
		if not surface.is_empty():
			body.set_meta("sticker_surface", surface)
		var layer := StickerLayer.new()
		layer.name = "StickerLayer"
		layer.host = {"kind": "primitive", "id": id}
		layer.surface = surface.duplicate()
		body.add_child(layer)
		primitives[id] = body

func _part(body: Node3D, node_name: String, mesh: Mesh, shape: Shape3D, at: Vector3, colour: Color, rough: float) -> void:
	var m := MeshInstance3D.new()
	m.name = node_name
	m.mesh = mesh
	m.position = at
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness = rough
	m.material_override = mat
	body.add_child(m)
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position = at
	body.add_child(cs)

static func _boxmesh(s: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = s
	return b

static func _boxshape(s: Vector3) -> BoxShape3D:
	var b := BoxShape3D.new()
	b.size = s
	return b
