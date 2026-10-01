extends Node3D
## The guest of the lesson The look: the pair of bodies in the course's look.
## A box in BODY and a sphere in SECOND, each with a collider, standing on the
## ground at the guest's origin, 1.4 m wide and 0.6 m deep together.
## A guest names nothing outside its folder, so the two colours are written
## out here, with the names the palette gives them. It declares no class_name.

const BODY := Color("c6ff3d")     # acid lime: the made body
const SECOND := Color("22d9ff")   # cyan: a second body

func _ready() -> void:
	var body_paint := StandardMaterial3D.new()
	body_paint.albedo_color = BODY
	body_paint.roughness = 0.8
	$Box.material_override = body_paint

	var second_paint := StandardMaterial3D.new()
	second_paint.albedo_color = SECOND
	second_paint.roughness = 0.8
	$Sphere.material_override = second_paint
