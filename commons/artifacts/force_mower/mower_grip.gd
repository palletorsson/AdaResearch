extends "res://commons/artifacts/force_capability_lab/loose_point.gd"
## A tracked hand target. The mower has its own mass and never follows by teleport.
func _ready() -> void:
	super()
	collision_mask=0; gravity_scale=0; freeze=true
	var bar:=CylinderMesh.new(); bar.top_radius=0.045; bar.bottom_radius=0.045; bar.height=0.44
	get_child(0).mesh=bar; get_child(0).rotation.x=PI/2
	var shape:=CapsuleShape3D.new(); shape.radius=0.065; shape.height=0.48
	get_child(1).shape=shape; get_child(1).rotation.x=PI/2
	var mat:=StandardMaterial3D.new(); mat.albedo_color=Color("f18fb8"); mat.roughness=0.35
	get_child(0).material_override=mat
func held() -> bool:
	return is_picked_up() or has_meta("capability_desktop_held")
