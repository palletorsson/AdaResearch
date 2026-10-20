extends Node3D
## A shallow pit in a raised construction. One editable part owns the visible
## danger surface and its volume; copying or turning it keeps them together.
@export var width := 5.0
@export var depth := 3.0
@export var abstract_finish := false
const CONTACT_HEIGHT := 0.28
var contact: Area3D

func _ready() -> void:
	add_to_group("void_lethal_pit")
	_surface("HotSurface", Vector3(0, 0.04, 0), Vector3(width,.04,depth), Color("281d2b") if abstract_finish else Color("65101d"), 0.0 if abstract_finish else 1.2)
	for i in range(0 if abstract_finish else 10):
		_surface("HeatMark%d" % i, Vector3(-width/2 + width * (i+.5)/10, 0.066, 0), Vector3(0.035, 0.008, depth-.1), Color("ff5935"), 2.0)
	for z in ([] if abstract_finish else [-depth/2+.02, depth/2-.02]):
		_surface("WarningEdge", Vector3(0, 0.072, z), Vector3(width, 0.02, 0.04), Color("ffa13d"), 1.6)
	for x in ([] if abstract_finish else [-1.5, 1.5]):
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(x, 0.3, 0)
		lamp.light_color = Color("ff5935")
		lamp.light_energy = 1.4
		lamp.omni_range = 3.5
		lamp.shadow_enabled = false
		add_child(lamp)
	contact = Area3D.new()
	contact.name = "FatalContact"
	contact.collision_layer = 0
	contact.collision_mask = 0xFFFFFFFF
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	# Broad-phase includes a falling capsule. Feet decide contact so leaning
	# over a bank or standing on the ferry can never count as touching the pit.
	box.size = Vector3(width, 2.0, depth)
	shape.shape = box
	shape.position.y = 0.3
	contact.add_child(shape)
	add_child(contact)
	process_physics_priority = 50

func _physics_process(_delta: float) -> void:
	var health := get_tree().get_first_node_in_group("void_health")
	if health == null or health.suspended or health.get_health() <= 0: return
	for body in contact.get_overlapping_bodies():
		if body is not CharacterBody3D: continue
		if not (body.is_in_group("player") or body.is_in_group("player_body") or body.is_in_group("vr_player") or body.is_in_group("em_walker")): continue
		var feet := to_local(body.global_position)
		if absf(feet.x) < width/2-.01 and absf(feet.z) < depth/2-.01 and feet.y <= CONTACT_HEIGHT and feet.y >= -0.5:
			health.set_health(0.0)
			return

func _surface(title: String, at: Vector3, size: Vector3, color: Color, glow: float) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = title
	mesh.position = at
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.55
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = glow
	mesh.material_override = material
	add_child(mesh)
