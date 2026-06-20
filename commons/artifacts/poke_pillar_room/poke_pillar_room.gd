## @identity
## name: Poke Pillar Room
## concept: Poke & dent (native soft bodies)
## tier: large
## truth: push through, they give and return — a room of tall soft pillars. Each is a native
##        SoftBody3D pinned at the floor AND the ceiling so it stands taut; the unpinned middle bends
##        out of your way as you walk through, then springs back to vertical. Walk a forest of give.
extends Node3D
class_name PokePillarRoom

@export var emissive: bool = false
@export var pillar_height: float = 2.6
@export var pillar_thick: float = 0.34
@export var rows: int = 2
@export var cols: int = 3
@export var pillar_color: Color = Color(0.4, 0.7, 0.55)

const GSB = preload("res://commons/soft_body/grab_soft_body.gd")

var _bodies: Array = []   # [{sb:SoftBody3D, h:float}]


func _ready() -> void:
	_build()
	set_process(false)


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	_bodies.clear()

	# Room floor (LARGE tier: 7x7 floor at y=-0.05, overhead label at y~3.6).
	var floor := MeshInstance3D.new()
	var fbm := BoxMesh.new()
	fbm.size = Vector3(7.0, 0.1, 7.0)
	floor.mesh = fbm
	floor.position = Vector3(0, -0.05, 0)
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.12, 0.13, 0.16)
	fmat.roughness = 0.9
	floor.material_override = fmat
	add_child(floor)

	# Faint ceiling slab the pillars pin up into (also gives a visible top anchor).
	var ceil := MeshInstance3D.new()
	var cbm := BoxMesh.new()
	cbm.size = Vector3(7.0, 0.1, 7.0)
	ceil.mesh = cbm
	ceil.position = Vector3(0, pillar_height + 0.05, 0)
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = Color(0.1, 0.11, 0.14)
	cmat.roughness = 0.9
	ceil.material_override = cmat
	add_child(ceil)

	# A grid of tall soft pillars to push through.
	var t: float = pillar_thick
	var hh: float = pillar_height
	var spacing_x: float = 1.9
	var spacing_z: float = 1.9
	for ix in range(cols):
		for iz in range(rows):
			var px: float = (float(ix) - float(cols - 1) * 0.5) * spacing_x
			var pz: float = (float(iz) - float(rows - 1) * 0.5) * spacing_z
			_make_pillar(Vector3(px, 0.0, pz), t, hh)

	add_child(_label("PUSH THROUGH — THEY GIVE AND RETURN", Vector3(0, 3.6, 0)))
	call_deferred("_apply_pins")


func _make_pillar(base_xz: Vector3, thick: float, height: float) -> void:
	# A tall, thin soft box. Subdivide along height so the column can bend through several segments.
	var sb := GSB.soft_setup(SoftBody3D.new(), {
		"mass": 3.0, "stiffness": 0.5, "pressure": 0.0, "damping": 0.4,
		"precision": 5, "color": pillar_color, "emissive": emissive,
	})
	var bm := BoxMesh.new()
	bm.size = Vector3(thick, height, thick)
	bm.subdivide_width = 2
	bm.subdivide_height = 8       # vertical resolution = smooth bend
	bm.subdivide_depth = 2
	sb.mesh = bm
	# Centre the column so its bottom sits on the floor and its top meets the ceiling.
	sb.position = base_xz + Vector3(0, height * 0.5, 0)
	add_child(sb)
	_bodies.append({"sb": sb, "h": height})


func _apply_pins() -> void:
	# Pin ONLY the bottom cap (to floor/world) and the top cap (to ceiling/world). The whole middle
	# stays free, so each pillar stands vertical but bends when pushed and springs back.
	for b in _bodies:
		var sb: SoftBody3D = b["sb"]
		if not is_instance_valid(sb):
			continue
		var half: float = float(b["h"]) * 0.5
		GSB.pin_patch(sb, Vector3(0, -half, 0), null, 0.18)   # foot pinned to world
		GSB.pin_patch(sb, Vector3(0,  half, 0), null, 0.18)   # head pinned to world


func _label(text: String, pos: Vector3) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.font_size = 34
	l.pixel_size = 0.0024
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.modulate = Color(0.85, 1.0, 0.92)
	l.outline_size = 8
	return l
