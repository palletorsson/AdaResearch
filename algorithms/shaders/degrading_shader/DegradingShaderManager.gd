extends Node3D

@export var mesh_instance: MeshInstance3D
@export var log_label_path: NodePath
@export var imprint_radius: float = 36.0
@export var imprint_strength: float = 0.18
@export var auto_increment_rate: float = 0.02

var degradation_image: Image
var degradation_texture: ImageTexture

var left_hand: Node3D
var right_hand: Node3D
var _log_label: Label3D
var _last_log: String = ""

func _ready() -> void:
	if log_label_path != NodePath():
		_log_label = get_node_or_null(log_label_path) as Label3D

	if not mesh_instance:
		_write_log("MeshInstance not assigned")
		return

	var material := mesh_instance.material_override
	if material == null and mesh_instance.mesh:
		material = mesh_instance.mesh.surface_get_material(0)
	if not (material and material is ShaderMaterial):
		_write_log("Target material is not a ShaderMaterial")
		return

	degradation_image = Image.create(512, 512, false, Image.FORMAT_L8)
	degradation_image.fill(Color(0, 0, 0))
	degradation_texture = ImageTexture.create_from_image(degradation_image)

	material.set_shader_parameter("degradation_map", degradation_texture)
	material.set_shader_parameter("degradation_amount", 0.0)

	left_hand = get_node_or_null("/root/Main/LeftHand")
	right_hand = get_node_or_null("/root/Main/RightHand")
	_write_log("Degrading shader initialised")

func _process(delta: float) -> void:
	if not mesh_instance:
		return
	var material := mesh_instance.material_override as ShaderMaterial
	if not material:
		return

	var current_amount: float = material.get_shader_parameter("degradation_amount")
	current_amount = clamp(current_amount + delta * auto_increment_rate, 0.0, 1.0)
	material.set_shader_parameter("degradation_amount", current_amount)

	if left_hand:
		_apply_imprint(left_hand.global_transform.origin)
	if right_hand:
		_apply_imprint(right_hand.global_transform.origin)

func _apply_imprint(world_position: Vector3) -> void:
	var local_pos: Vector3 = mesh_instance.to_local(world_position)
	var uv := _local_to_uv(local_pos)
	if uv.x < 0.0 or uv.x > 1.0 or uv.y < 0.0 or uv.y > 1.0:
		return

	var px: int = int(uv.x * float(degradation_image.get_width()))
	var py: int = int(uv.y * float(degradation_image.get_height()))

	var radius: int = clamp(int(imprint_radius), 1, 128)
	degradation_image.lock()
	for y in range(-radius, radius + 1):
		var ty: int = py + y
		if ty < 0 or ty >= degradation_image.get_height():
			continue
		for x in range(-radius, radius + 1):
			var tx: int = px + x
			if tx < 0 or tx >= degradation_image.get_width():
				continue
			var dist := sqrt(float(x * x + y * y)) / float(radius)
			if dist > 1.0:
				continue
			var falloff := pow(1.0 - dist, 2.0)
			var current_value: float = degradation_image.get_pixel(tx, ty).r
			var new_value: float = clamp(current_value + imprint_strength * falloff, 0.0, 1.0)
			degradation_image.set_pixel(tx, ty, Color(new_value, new_value, new_value))
	degradation_image.unlock()
	degradation_texture.update(degradation_image)
	_write_log("Imprint applied at %s" % str(world_position))

func _local_to_uv(local_pos: Vector3) -> Vector2:
	var aabb: AABB = mesh_instance.get_transformed_aabb()
	if aabb.size.x == 0 or aabb.size.y == 0:
		return Vector2(-1, -1)
	var min_corner := mesh_instance.to_local(aabb.position)
	var size := mesh_instance.to_local(aabb.position + aabb.size) - min_corner
	var u := (local_pos.x - min_corner.x) / size.x
	var v := (local_pos.y - min_corner.y) / size.y
	return Vector2(u, v)

func _write_log(message: String) -> void:
	_last_log = message
	if _log_label:
		_log_label.text = message
