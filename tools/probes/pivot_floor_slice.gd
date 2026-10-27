extends "res://commons/void/architecture.gd"
## Focused rendering/testing fixture: actual saved floor 15, actual production
## floor and content builders. Does not allocate the other 208 storeys.
func _ready() -> void:
	spec=Content.Source.read_layout("");floor_records=Content.Source.read_rooms("").floors
	concrete=material(Color("c3bdb1"),.9);steel=material(Color("313b43"),.36,.65)
	pink=material(Color("d77894"),.45,.3);pipe_material=material(Color("718d98"),.4,.5);timber=material(Color("b78e59"),.85)
	_build_floor(15)
	content=Content.new();content.name="FloorContent";content.lazy=true;add_child(content);content.load_floor(15)
