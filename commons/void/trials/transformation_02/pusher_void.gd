extends "res://commons/hazards/transformation_blocks/pusher_block.gd"
## A saved editor yaw turns the original local travel axis with the whole exhibit.

func _ready() -> void:
	super._ready()
	_place_route()

func apply_grid_config(config_data: Dictionary) -> void:
	super.apply_grid_config(config_data)
	if is_instance_valid(_body): _place_route()

func _place_route() -> void:
	_start_pos=global_position
	_end_pos=_start_pos+global_basis.orthonormalized()*push_axis.normalized()*push_distance
	_body.global_position=_start_pos.lerp(_end_pos,_t)
