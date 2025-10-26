# triangular_cupola.gd - Johnson Solid J3: Triangular Cupola
extends Node3D

const PolyhedronFactory = preload("res://commons/primitives/shared/polyhedron_factory.gd")

func _ready():
	var cupola = PolyhedronFactory.create_triangular_cupola(0.6, Color(0.7, 0.9, 1.0))
	add_child(cupola)
