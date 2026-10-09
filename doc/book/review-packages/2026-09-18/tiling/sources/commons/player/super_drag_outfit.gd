extends Node3D
## A wearable silhouette, mounted under QueerCostume's inferred torso.
## Geometry is cosmetic: it never changes locomotion, collision or progression.
const DreamFinish := preload("res://commons/artifacts/dream_bodies/dream_skin.gd")
const DreamShader := preload("res://commons/artifacts/dream_bodies/dream_shaders.gd")
const LOOKS := ["latex_cathedral", "chrome_orchid", "holo_fan", "pearl_rococo"]
const TITLES := ["Latex Cathedral", "Chrome Orchid", "Holographic Fan", "Pearl Rococo"]
const HEAD_LAYER := 1 << 18
var look_id: String = ""
var skirt_fabric: Dictionary = {}
var _original_skirt_material: Material
var headpiece: Node3D
var sleeves: Array[MeshInstance3D] = []
var gloves: Array[MeshInstance3D] = []

func dress(id: String) -> bool:
	if not LOOKS.has(id):
		return false
	look_id = id
	for child in get_children():
		remove_child(child)
		child.queue_free()
	sleeves.clear()
	gloves.clear()
	var index: int = LOOKS.find(id)
	var colors := [Color("d91e83"), Color("71e9e0"), Color("b666eb"), Color("f4d7dc")]
	var finishes := ["latex", "chrome", "holo", "pearl"]
	var rng := RandomNumberGenerator.new()
	rng.seed = 719
	var fabric: Material = DreamFinish.skin(finishes[index], colors[index], rng)
	if index == 1:
		# This stylized chrome carries a procedural reflected environment, so it
		# remains legible in galleries without a sky/reflection probe.
		fabric = DreamShader.skin("chrome", "bare", colors[index], Color("ee80c9"), 719)
	var trim: Material = DreamFinish.skin("chrome", Color("edd2a0"), rng)
	var dark: Material = DreamFinish.skin("patent", Color("201226"), rng)
	# Neck is y=0, camera is approximately y=0.15. Bodice narrows to waist.
	_cone(self, "Bodice", Vector3(0, -0.31, 0), 0.21, 0.135, 0.43, fabric).scale.z = 0.72
	var neck := _cone(self, "NeckCollar", Vector3(0, -0.015, 0), 0.065, 0.07, 0.19, dark)
	neck.layers = HEAD_LAYER
	_cone(self, "Skirt", Vector3(0, -0.94, 0.035), 0.145, 0.43 if index != 2 else 0.26, 0.85, fabric).scale.z = 0.8
	for side in [-1.0, 1.0]:
		_ball(self, "Shoulder", Vector3(side * 0.24, -0.16, 0), Vector3(0.23, 0.23, 0.25), fabric)
		var sleeve := _cone(self, "Sleeve", Vector3.ZERO, 0.075, 0.055, 1.0, fabric)
		sleeves.append(sleeve)
		gloves.append(_ball(self, "Glove", Vector3.ZERO, Vector3(0.10, 0.14, 0.075), dark))
		_cone(self, "Boot", Vector3(side * 0.13, -1.35, 0), 0.065, 0.08, 0.28, dark)
		_ball(self, "Platform", Vector3(side * 0.13, -1.49, -0.055), Vector3(0.16, 0.09, 0.28), dark)
	# Head and crown exist for reflections/other observers, excluded from own view.
	headpiece = Node3D.new()
	headpiece.name = "HeadAndCrown"
	add_child(headpiece)
	_ball(headpiece, "Mask", Vector3(0, -0.005, 0), Vector3(0.19, 0.24, 0.18), dark)
	for side in [-1.0, 1.0]:
		_ball(headpiece, "EyeJewel", Vector3(side * 0.047, 0.027, -0.086), Vector3(0.044, 0.014, 0.018), trim)
		_ball(headpiece, "Earring", Vector3(side * 0.12, -0.10, 0), Vector3(0.055, 0.13, 0.055), trim)
	match index:
		0:
			for i in range(9):
				var a := float(i) / 8.0 * PI
				var spike := _cone(self, "CathedralCollar", Vector3(cos(a) * 0.30, -0.06, sin(a) * 0.17 + 0.09), 0.0, 0.07, 0.40 + sin(a) * 0.22, dark)
				spike.rotation.z = -cos(a) * 0.45
			for i in range(5):
				_cone(headpiece, "CrownSpire", Vector3((i - 2) * 0.065, 0.20, 0), 0, 0.03, 0.20 + (2 - absi(i - 2)) * 0.08, trim)
		1:
			for side in [-1.0, 1.0]:
				for i in range(5):
					var petal := _ball(self, "OrchidPetal", Vector3(side * (0.28 + i * 0.045), -0.13 + i * 0.055, 0.07), Vector3(0.17, 0.46, 0.07), fabric)
					petal.rotation.z = -side * (0.3 + i * 0.22)
			for i in range(7):
				var petal := _ball(headpiece, "OrchidCrown", Vector3((i - 3) * 0.055, 0.15, 0.03), Vector3(0.09, 0.30, 0.045), fabric)
				petal.rotation.z = -(i - 3) * 0.22
		2:
			for i in range(9):
				var a := (i - 4) * 0.25
				var ray := _cone(self, "FanPleat", Vector3(sin(a) * 0.40, -0.12 + cos(a) * 0.16, 0.24), 0.19, 0.015, 0.88, fabric)
				ray.scale.z = 0.17
				ray.rotation.z = -a
			_cone(headpiece, "Crest", Vector3(0, 0.22, 0.02), 0, 0.12, 0.38, fabric).scale.z = 0.45
		3:
			for tier in range(3):
				for i in range(18):
					var a := float(i) / 18.0 * TAU
					var radius := 0.23 + tier * 0.095
					_ball(self, "PearlHem", Vector3(cos(a) * radius, -0.72 - tier * 0.27, sin(a) * radius * 0.8), Vector3.ONE * 0.07, fabric)
			for side in [-1.0, 1.0]:
				_ball(self, "RococoSleeve", Vector3(side * 0.31, -0.2, 0), Vector3(0.30, 0.29, 0.29), fabric)
			for i in range(9):
				_ball(headpiece, "PearlCrown", Vector3((i - 4) * 0.032, 0.15 + sin(float(i) / 8.0 * PI) * 0.12, 0), Vector3.ONE * 0.065, fabric)
	for mesh in headpiece.find_children("*", "MeshInstance3D", true, false):
		mesh.layers = HEAD_LAYER
	_original_skirt_material = get_node("Skirt").material_override
	apply_skirt_fabric(skirt_fabric)
	return true

func follow(head: Node3D, left: Node3D, right: Node3D) -> void:
	if is_instance_valid(headpiece) and is_instance_valid(head):
		headpiece.global_transform = head.global_transform
	for i in range(sleeves.size()):
		var side := -1.0 if i == 0 else 1.0
		var hand: Node3D = left if i == 0 else right
		var start := Vector3(side * 0.24, -0.20, 0)
		var end := to_local(hand.global_position) if is_instance_valid(hand) else Vector3(side * 0.32, -0.67, -0.10)
		var direction := end - start
		sleeves[i].position = (start + end) * 0.5
		sleeves[i].quaternion = Quaternion(Vector3.UP, direction.normalized()) if direction.length() > 0.001 else Quaternion.IDENTITY
		sleeves[i].scale = Vector3(1, maxf(0.001, direction.length()), 1)
		gloves[i].position = end

func _cone(parent: Node3D, label: String, pos: Vector3, top: float, bottom: float, height: float, mat: Material) -> MeshInstance3D:
	var shape := CylinderMesh.new()
	shape.top_radius = top
	shape.bottom_radius = bottom
	shape.height = height
	shape.radial_segments = 24
	return _mesh(parent, label, pos, shape, mat)

func _ball(parent: Node3D, label: String, pos: Vector3, dimensions: Vector3, mat: Material) -> MeshInstance3D:
	var shape := SphereMesh.new()
	shape.radius = 0.5
	shape.height = 1.0
	shape.radial_segments = 20
	shape.rings = 10
	var item := _mesh(parent, label, pos, shape, mat)
	item.scale = dimensions
	return item

func _mesh(parent: Node3D, label: String, pos: Vector3, shape: Mesh, mat: Material) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = label
	item.mesh = shape
	item.material_override = mat
	item.position = pos
	parent.add_child(item)
	return item

## Only the named skirt receives the recipe; all other garment parts keep their finish.
func apply_skirt_fabric(recipe: Dictionary) -> bool:
	if not recipe.is_empty() and not preload("res://commons/artifacts/fabric_shader_studio/fabric_recipe.gd").valid(recipe):return false
	skirt_fabric=recipe.duplicate(true)
	var skirt:MeshInstance3D=get_node_or_null("Skirt")
	if not skirt:return true
	skirt.extra_cull_margin=0.08
	skirt.material_override=_original_skirt_material if recipe.is_empty() else preload("res://commons/artifacts/fabric_shader_studio/fabric_recipe.gd").material(recipe)
	return true
