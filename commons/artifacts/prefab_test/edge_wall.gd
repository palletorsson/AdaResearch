# EdgeWall.gd - a short white parapet at a slab's edge: it stops a body, and it ends
#
# @identity
# essence: a white wall slab a little over a metre high, standing at the edge of a floor; solid, and never the whole edge
# desire: the learner is kept from one careless step over the edge, and still sees that the edge is there
# critical_parameter: length - how much of the edge it closes
# triggers: none
# emerges: beside the white block, whose slabs stop nobody, this one stops a body: the same slab with a collider
# relationships: the block's slab given a body ([[white_block]]); stands with the blue police barricades ([[do_not_cross_barrier]])
# truth: safer is not safe. The wall is short on purpose.
extends Node3D

## WHERE THIS COMES FROM. Palle, 23 November 2026: "for around the edge of the slab around the 10 cube add police do
## not cross blue and some wall so we are more safe not to fall but not completely."
##
## One box in the block's own white, `length` along x, `height` tall, `thick` deep, with a collider of the same
## size on layer 1. Origin: the floor, under the middle of the wall.

@export var length := 1.6
@export var height := 1.1
@export var thick := 0.18

var body: StaticBody3D


func apply_grid_config(config: Dictionary) -> void:
	for key in ["length", "height", "thick"]:
		if config.has(key): set(key, float(config[key]))
	if is_node_ready():
		for child in get_children(): child.queue_free()
		_build()


func _ready() -> void:
	for key in ["length", "height", "thick"]:
		if has_meta("config_" + key): set(key, float(get_meta("config_" + key)))
	_build()


func _build() -> void:
	var size := Vector3(length, height, thick)
	body = StaticBody3D.new()
	body.name = "Wall"
	body.position = Vector3(0, height * 0.5, 0)
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var paint := StandardMaterial3D.new()
	paint.albedo_color = Color("f4f2ee")
	paint.roughness = 0.92
	paint.emission_enabled = true
	paint.emission = Color("f4f2ee")
	paint.emission_energy_multiplier = 0.35
	mesh.material_override = paint
	body.add_child(mesh)
	var shape := CollisionShape3D.new()
	var solid := BoxShape3D.new()
	solid.size = size
	shape.shape = solid
	body.add_child(shape)
