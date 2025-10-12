# DiamondTower.gd
extends Node3D

@export var unit_count := 12
@export var unit_size := 2.5
@export var unit_height := 2.0
@export var rotation_offset := 15.0 # degrees per step twist

func _ready() -> void:

	# stack alternating "diamonds" using octahedron scene
	for i in range(unit_count):
		var diamond_scene = preload("res://commons/primitives/octahedron/octahedron.tscn")
		var diamond := diamond_scene.instantiate()
		diamond.position = Vector3(0, unit_height * i + unit_height, 0)
		diamond.rotation.y = deg_to_rad(rotation_offset * i)
		diamond.scale = Vector3(unit_size, unit_height, unit_size)
		add_child(diamond)
