# square_pyramid.gd - Johnson Solid J1: Square Pyramid
extends Node3D

const PolyhedronFactory = preload("res://commons/primitives/shared/polyhedron_factory.gd")

func _ready():
	var pyramid = PolyhedronFactory.create_square_pyramid(0.6, Color(1.0, 0.7, 0.3))
	add_child(pyramid)
