@tool
extends "res://addons/godot-xr-tools/objects/pickable.gd"
class_name GrabCube

# @identity
# essence: a small free cube you can grab out of the air and carry — the simplest hand verb, the one a
#          baby learns first: close your hand on a thing and it comes with you. Glows on highlight, hums
#          when held, drops with weight. The lab's example of the GRAB-CARRY modality (as distinct from
#          grab-to-drive a lever, or snap-into-a-socket).
# desire: to be picked up. To prove the hand can take possession of a loose object and move it through
#         space with full six-degrees-of-freedom freedom — no track, no hinge, no constraint. Just held.
# critical_parameter: mass + the highlight — light enough to toss, heavy enough to feel real. The
#         highlight is what tells the hand "this is grabbable", the affordance made visible before contact.
# triggers: a hand grab closes on it -> picked_up; release -> dropped (it falls or floats per freeze).
# emerges: agency over the loose world. The first thing a player tries in any VR space is to grab
#          something and move it; the grab_cube guarantees that try succeeds, and teaches the verb.
# needs: a RigidBody pickable [extends pickable.gd]; a visible cube + highlight [present]; grab points [present];
#        a held hum [present]
# relationships: the loose twin of snap_socket (which wants this cube returned to it); cousin to the
#                lever/slider (grab-to-DRIVE) — this is grab-to-CARRY, the unconstrained case.
# truth: before you can build, sort, or operate, you must be able to TAKE. The grab cube is the lab's
#        atom of possession — the hand learning it can hold the world and carry a piece of it away.

@export var cube_size: float = 0.07
@export var cube_color: Color = Color(0.95, 0.55, 0.20, 1.0)

var _mesh: MeshInstance3D
var _mat: StandardMaterial3D
var _hum: AudioStreamPlayer3D


func _ready() -> void:
	# pickable.gd has its own _ready — call it so grab handling initialises.
	super()
	if Engine.is_editor_hint():
		_build_visual()
		return
	_build_visual()
	# Wire highlight + held feedback.
	if has_signal("highlight_updated"):
		highlight_updated.connect(_on_highlight)
	if has_signal("grabbed"):
		grabbed.connect(_on_grabbed)
	if has_signal("released"):
		released.connect(_on_released)


func _build_visual() -> void:
	if has_node("CubeMesh"):
		return
	# Collision shape (pickable needs one for grabbing + physics).
	if not _has_collision_shape():
		var cs := CollisionShape3D.new()
		cs.name = "CollisionShape3D"
		var box := BoxShape3D.new()
		box.size = Vector3(cube_size, cube_size, cube_size)
		cs.shape = box
		add_child(cs)

	_mesh = MeshInstance3D.new()
	_mesh.name = "CubeMesh"
	var bm := BoxMesh.new()
	bm.size = Vector3(cube_size, cube_size, cube_size)
	_mesh.mesh = bm
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = cube_color
	_mat.metallic = 0.3
	_mat.roughness = 0.35
	_mat.emission_enabled = true
	_mat.emission = cube_color
	_mat.emission_energy_multiplier = 0.25
	_mesh.material_override = _mat
	add_child(_mesh)

	# Grab points (left + right) so XR hands snap to it cleanly.
	for side in ["Left", "Right"]:
		var gp_path: String = "res://addons/godot-xr-tools/objects/grab_points/grab_point_hand_%s.tscn" % side.to_lower()
		if ResourceLoader.exists(gp_path):
			var gp_scene: PackedScene = load(gp_path)
			var gp: Node = gp_scene.instantiate()
			gp.name = "GrabPoint" + side
			add_child(gp)

	if not Engine.is_editor_hint():
		_hum = AudioStreamPlayer3D.new()
		_hum.name = "HeldHum"
		_hum.volume_db = -20.0
		_hum.max_distance = 5.0
		_hum.stream = _build_hum()
		add_child(_hum)


func _has_collision_shape() -> bool:
	for c in get_children():
		if c is CollisionShape3D:
			return true
	return false


func _on_highlight(_p, enable: bool) -> void:
	if _mat:
		_mat.emission_energy_multiplier = 1.2 if enable else 0.25


func _on_grabbed(_p, _by) -> void:
	if _hum and not _hum.playing:
		_hum.play()


func _on_released(_p, _by) -> void:
	if _hum and _hum.playing:
		_hum.stop()


func _build_hum() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	var n := 4410
	stream.loop_end = n
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var tt := float(i) / stream.mix_rate
		var s := (sin(TAU * 140.0 * tt) * 0.5 + sin(TAU * 210.0 * tt) * 0.3) * 0.18
		var si := int(clamp(s, -1.0, 1.0) * 32767.0)
		data[2 * i] = si & 0xFF
		data[2 * i + 1] = (si >> 8) & 0xFF
	stream.data = data
	return stream
