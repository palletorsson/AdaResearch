extends Area3D
class_name ArmadilloFireBolt

@export var speed: float = 14.0
@export var damage: float = 12.0
@export var lifetime: float = 4.0
@export var radius: float = 0.12

var _direction: Vector3 = Vector3.FORWARD
var _age: float = 0.0
var _impacted: bool = false

func _ready() -> void:
	monitoring = true
	monitorable = true
	collision_layer = 16
	collision_mask = 1 | 2 | 4 | 8 | 1048576

	if not has_node("CollisionShape3D"):
		var collision: CollisionShape3D = CollisionShape3D.new()
		collision.name = "CollisionShape3D"
		var sphere: SphereShape3D = SphereShape3D.new()
		sphere.radius = radius
		collision.shape = sphere
		add_child(collision)

	if not has_node("MeshInstance3D"):
		var mesh_instance: MeshInstance3D = MeshInstance3D.new()
		mesh_instance.name = "MeshInstance3D"
		var sphere_mesh: SphereMesh = SphereMesh.new()
		sphere_mesh.radius = radius
		sphere_mesh.height = radius * 2.0
		mesh_instance.mesh = sphere_mesh

		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color(1.0, 0.44, 0.08, 1.0)
		material.emission_enabled = true
		material.emission = Color(1.0, 0.25, 0.03, 1.0)
		material.emission_energy = 2.0
		mesh_instance.material_override = material
		add_child(mesh_instance)

	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	if _impacted:
		return

	_age += delta
	if _age >= lifetime:
		queue_free()
		return

	global_position += _direction * speed * delta

func launch(origin: Vector3, direction: Vector3, speed_value: float = -1.0, damage_value: float = -1.0) -> void:
	global_position = origin
	if speed_value > 0.0:
		speed = speed_value
	if damage_value > 0.0:
		damage = damage_value

	var dir: Vector3 = direction
	if dir.length_squared() <= 0.0001:
		dir = Vector3.FORWARD
	_direction = dir.normalized()

	var up: Vector3 = Vector3.UP
	if abs(_direction.dot(up)) > 0.98:
		up = Vector3.FORWARD
	look_at(global_position + _direction, up)

func _on_body_entered(body: Node) -> void:
	_impact(body)

func _on_area_entered(area: Area3D) -> void:
	_impact(area)

func _impact(target: Object) -> void:
	if _impacted:
		return
	_impacted = true
	_try_apply_damage(target)
	queue_free()

func _try_apply_damage(target: Object) -> void:
	if target == null:
		return

	if target.has_method("take_damage"):
		target.take_damage(damage)
		return

	if target.has_method("apply_damage"):
		target.apply_damage(damage)
		return

	if target.has_method("apply_health_damage"):
		target.apply_health_damage(damage)
		return

	if target.has_method("damage_player"):
		target.damage_player(damage)
		return

	if target is Node:
		var node: Node = target as Node
		var lower_name: String = node.name.to_lower()
		if node.is_in_group("player") or lower_name.contains("player") or lower_name.contains("xrorigin"):
			if Engine.has_singleton("GameManager"):
				var game_manager: Object = Engine.get_singleton("GameManager")
				if game_manager and game_manager.has_method("add_points"):
					game_manager.add_points(-int(round(damage)))
