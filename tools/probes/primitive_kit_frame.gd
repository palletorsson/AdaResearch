extends "res://commons/void/architecture.gd"
## Use the real slab/column builders in a bounded three-storey test frame.
## No authored content or live main-tower arrangement is loaded by this fixture.
func _ready() -> void:
	spec=JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	spec.levels=[0,-6,-12];spec.floor_styles={"0":"abstract","1":"abstract","2":"abstract"}
	floor_records=[{}, {}, {}]
	concrete=material(Color("c3bdb1"),.9);steel=material(Color("313b43"),.36,.65)
	pink=material(Color("d77894"),.45,.3);timber=material(Color("b78e59"),.85)
	for i in 3:_build_floor(i)
	_build_columns()
