extends "res://commons/void/ride_platform.gd"
## The original transport's carry, with a thin construction deck instead of cubes.
const Finish = preload("res://commons/void/abstract_finish.gd")

func _ready() -> void:
	super._ready()
	# Replace only the inherited visual cubes; retain the single moving support.
	for child in static_body.get_children():
		if child is Node3D and child.get_meta("construction_definition", "") == "structure_2": child.free()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2, .16, 2)
	_support_shape.shape = shape
	_support_shape.position.y = .42 # Deck top stays at the original +0.5 m.
	_support_bounds = shape.get_debug_mesh().get_aabb()
	var deck := MeshInstance3D.new()
	deck.name = "SteelDeck"
	var mesh := BoxMesh.new()
	mesh.size = shape.size
	deck.mesh = mesh
	deck.position.y = .42
	deck.material_override = Finish.material(Color("91b6b8"), .08)
	static_body.add_child(deck)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	# Update after the transport moves, so hangers and deck share the same pose.
	if get_parent().has_method("_update_suspension"):
		get_parent()._update_suspension()

func _supports_body(rider: Node3D) -> bool:
	if rider is not CharacterBody3D: return false
	if rider is XRToolsPlayerBody: return _supports_xr_rider(rider)
	var feet: Vector3 = _support_shape.to_local(rider.global_position)
	return rider.velocity.y <= .25 and feet.y >= .02 and feet.y <= .24 and absf(feet.x) <= 1.04 and absf(feet.z) <= 1.04
