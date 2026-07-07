@tool
extends Node3D
class_name SnapSocket

# @identity
# essence: a lit cradle that wants its piece back — a glowing ring with a shaped recess, and a matching
#          token that clicks home when a hand brings it close. The lab's example of the SNAP modality:
#          not free-carry (that is the grab cube) but carry-TO-A-PLACE, the satisfying magnetic seat of
#          an object into its socket.
# desire: to be completed. The socket is an absence shaped like a specific thing; it pulls that thing in
#         when offered and holds it, lighting green. It wants the loop closed: object out, object back.
# critical_parameter: snap range + the matching token — close enough and the magnet takes over, the
#         object leaving the hand and seating itself. Too tight and it feels broken; too loose and it
#         grabs the wrong thing. The shaped recess is the affordance: it tells you what belongs here.
# triggers: a held pickable enters the snap range -> the zone takes it, seats it, lights green (has_picked_up);
#           grabbing it back empties the socket, lights amber (has_dropped).
# emerges: the logic of return, of a place for everything. Tools in a rack, the key in the lock, the
#          piece in the puzzle. The socket teaches that the hand can not only take but PUT — and that
#          some absences are shaped to be filled.
# needs: an XRToolsSnapZone [instanced child]; a visible cradle ring [present]; a starting token [present];
#        green/amber state lights [present]
# relationships: the seated twin of grab_cube (which is the thing it wants); part of the put-back family
#                with return_to_snap_zone; complement to the press/drive/poke gadgets in the wall.
# truth: to carry is half the verb; to PLACE is the other half. The snap socket is the lab's lesson that
#        the world has slots, that objects have homes, and that the hand completes a shape by filling it.

@export var ring_color: Color = Color(0.45, 0.55, 0.75, 1.0)
@export var filled_color: Color = Color(0.30, 0.95, 0.45, 1.0)
@export var empty_color: Color = Color(0.95, 0.62, 0.20, 1.0)
@export var snap_range: float = 0.09
## If true, spawn a matching grab token already seated in the socket.
@export var spawn_token: bool = true

var _ring_mat: StandardMaterial3D
var _ring: MeshInstance3D
var _zone: Node3D
var _built: bool = false

signal socket_filled()
signal socket_emptied()


func _ready() -> void:
	if _built:
		return
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		if str(k) == "spawn_token":
			spawn_token = str(config_data[k]).to_lower() in ["true", "1", "yes"]
	if _built:
		for c in get_children():
			c.queue_free()
		_built = false
		_build()


func _build() -> void:
	_built = true

	# Cradle base.
	var base := MeshInstance3D.new()
	base.name = "Base"
	var bm := CylinderMesh.new()
	bm.top_radius = 0.085
	bm.bottom_radius = 0.095
	bm.height = 0.02
	base.mesh = bm
	var base_mat := StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.08, 0.09, 0.11)
	base_mat.metallic = 0.4
	base_mat.roughness = 0.7
	base.material_override = base_mat
	add_child(base)

	# Glowing seat ring — the affordance.
	_ring = MeshInstance3D.new()
	_ring.name = "Ring"
	var rm := TorusMesh.new()
	rm.inner_radius = 0.05
	rm.outer_radius = 0.065
	rm.rings = 32
	rm.ring_segments = 12
	_ring.mesh = rm
	_ring_mat = StandardMaterial3D.new()
	_ring_mat.albedo_color = ring_color
	_ring_mat.emission_enabled = true
	_ring_mat.emission = empty_color
	_ring_mat.emission_energy_multiplier = 1.0
	_ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring.material_override = _ring_mat
	_ring.rotation_degrees = Vector3(90, 0, 0)
	_ring.position = Vector3(0, 0.02, 0)
	add_child(_ring)

	if Engine.is_editor_hint():
		return

	# Instance the real XR-tools snap zone.
	var zone_path := "res://addons/godot-xr-tools/objects/snap_zone.tscn"
	if ResourceLoader.exists(zone_path):
		_zone = load(zone_path).instantiate()
		_zone.name = "SnapZone"
		_zone.position = Vector3(0, 0.05, 0)
		if "snap_zone_range" in _zone:
			_zone.snap_zone_range = snap_range
		if "snap_zone_size" in _zone:
			_zone.snap_zone_size = snap_range
		add_child(_zone)
		if _zone.has_signal("has_picked_up"):
			_zone.has_picked_up.connect(_on_filled)
		if _zone.has_signal("has_dropped"):
			_zone.has_dropped.connect(_on_emptied)

	# A matching token, optionally pre-seated.
	if spawn_token:
		var token_path := "res://commons/interactables/grab_cube.tscn"
		if ResourceLoader.exists(token_path):
			var token = load(token_path).instantiate()
			token.name = "Token"
			if "cube_color" in token:
				token.cube_color = filled_color
			add_child(token)
			token.global_position = global_position + Vector3(0, 0.07, 0)
			# Seat it into the zone next frame (zone needs to be in tree).
			if _zone and _zone.has_method("pick_up_object"):
				_zone.call_deferred("pick_up_object", token)


func _on_filled(_what) -> void:
	if _ring_mat:
		_ring_mat.emission = filled_color
		_ring_mat.emission_energy_multiplier = 1.6
	socket_filled.emit()


func _on_emptied() -> void:
	if _ring_mat:
		_ring_mat.emission = empty_color
		_ring_mat.emission_energy_multiplier = 1.0
	socket_emptied.emit()
