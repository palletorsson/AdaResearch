extends "res://commons/artifacts/force_capability_lab/force_point.gd"
## Same XR/desktop hand ownership as the point; this handle is not a thruster.
func _ready() -> void:
	super();remove_from_group("ada_thrust_points")
	sphere.radius=0.09;sphere.height=0.18;get_child(1).shape.radius=0.09
	get_child(0).material_override.albedo_color=Color("ed96bb")
	collision_mask=0;gravity_scale=0;jet.visible=false

func _process(_dt: float) -> void:
	jet.visible=false
