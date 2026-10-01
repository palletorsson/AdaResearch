extends Node3D

const Wall := preload("res://wall.gd")

@export var spaces := "rgb, hsv, linear, oklab"   # one wall for each name, from the floor up

var walls: Array[Node3D] = []
var lamp := SpotLight3D.new()
var ray := RayCast3D.new()
var lights: Array[Color] = [Color.WHITE]   # the colours the lamp can have
var light := 0                             # which of them it has now

func _ready() -> void:
	for word in spaces.split(","):
		var wall := Wall.new()
		wall.space = word.strip_edges()
		wall.position = Vector3(0, walls.size() * wall.size.y, -1)
		add_child(wall)
		walls.append(wall)
		print(wall.space, ": the middle is ", wall.mix(0.5).to_html(false))
	lights.append(walls[0].first)
	lights.append(walls[0].second)
	lamp.spot_angle = 25.0
	lamp.light_energy = 3.0
	lamp.light_color = lights[light]
	add_child(lamp)
	ray.target_position = Vector3(0, 0, -6)
	lamp.add_child(ray)

func _process(_delta: float) -> void:
	lamp.position = $Walker.position + Vector3(0, 0.7, 0)
	if Input.is_action_just_pressed("pause"):
		light = (light + 1) % lights.size()
		lamp.light_color = lights[light]
		print("the lamp is ", lamp.light_color.to_html(false))
	if Input.is_action_just_pressed("drop"):
		paint()

func paint() -> void:
	if not ray.is_colliding():
		print("the ray met nothing")
		return
	var step: MeshInstance3D = ray.get_collider().get_parent()
	var skin: StandardMaterial3D = step.material_override
	var before := skin.albedo_color
	skin.albedo_color = before.lerp(lamp.light_color, 0.5)
	print("painted ", before.to_html(false), " to ", skin.albedo_color.to_html(false))
