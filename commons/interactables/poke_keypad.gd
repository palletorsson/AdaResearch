@tool
extends Node3D
class_name PokeKeypad

# @identity
# essence: a 3x3 grid of small keys you press with a single fingertip — the POKE modality, distinct from
#          the big palm-push button: here the hand extends one finger and taps, like a calculator or a
#          door code. Each key lights and clicks on poke; an entered sequence can unlock.
# desire: to be tapped precisely. Where the push_button takes a whole hand and the lever takes a grip,
#         the keypad wants the pointed index finger — the most precise hand verb, one key at a time.
# critical_parameter: the per-key area mask (393216 = hands + poke bodies) and key spacing — keys must be
#         far enough apart that a fingertip hits one at a time, close enough to read as a pad. The
#         depress depth is the tactile affordance: the key visibly sinks when poked.
# triggers: a poke body / hand enters a key's Area3D -> that key depresses, lights, emits key_pressed(i);
#           leaving releases it. A matching code sequence emits code_entered.
# emerges: precise discrete input — digits, codes, selections. The keypad teaches the pointed finger as
#          a distinct instrument from the open palm; the lab's example of fine poke targeting.
# needs: a grid of small area buttons [present]; per-key depress + light [present]; a poke-detecting mask
#        [present]; an optional unlock code [present]
# relationships: the precise sibling of push_button (palm-press) and hand_scanner (palm-hover); shares the
#                Area3D-detects-hand pattern with both; the discrete-input member of the gadget wall.
# truth: the hand has a fine setting. The keypad is the lab insisting that not every press is a slap —
#        that one finger, aimed, is its own kind of touch, and that codes are entered key by key.

signal key_pressed(index: int)
signal code_entered()

@export var cols: int = 3
@export var rows: int = 3
@export var key_size: float = 0.045
@export var key_gap: float = 0.018
@export var key_color: Color = Color(0.55, 0.6, 0.7, 1.0)
@export var lit_color: Color = Color(0.3, 0.9, 1.0, 1.0)
@export_flags_3d_physics var poke_mask: int = 393216
## Optional unlock code as comma key indices, e.g. "0,4,8". Empty = none.
@export var unlock_code: String = ""

var _keys: Array = []          # [{area, mesh, mat, base_y, index}]
var _entered: Array = []
var _code: Array = []
var _built: bool = false


func _ready() -> void:
	if _built:
		return
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		if str(k) == "unlock_code":
			unlock_code = str(config_data[k])
	if _built:
		for c in get_children():
			c.queue_free()
		_built = false
		_keys.clear()
		_build()


func _build() -> void:
	_built = true
	_code.clear()
	for tok in unlock_code.split(","):
		if str(tok).strip_edges().is_valid_int():
			_code.append(int(str(tok).strip_edges()))

	# Backing panel.
	var panel := MeshInstance3D.new()
	panel.name = "Panel"
	var pw: float = cols * key_size + (cols + 1) * key_gap
	var ph: float = rows * key_size + (rows + 1) * key_gap
	var pm := BoxMesh.new()
	pm.size = Vector3(pw, ph, 0.02)
	panel.mesh = pm
	var panel_mat := StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.07, 0.08, 0.10)
	panel_mat.metallic = 0.3
	panel_mat.roughness = 0.75
	panel.material_override = panel_mat
	add_child(panel)

	var x0: float = -pw * 0.5 + key_gap + key_size * 0.5
	var y0: float = ph * 0.5 - key_gap - key_size * 0.5
	var idx := 0
	for r in range(rows):
		for c in range(cols):
			var kx: float = x0 + c * (key_size + key_gap)
			var ky: float = y0 - r * (key_size + key_gap)
			_make_key(idx, Vector3(kx, ky, 0.012))
			idx += 1

	if not Engine.is_editor_hint():
		set_process(false)


func _make_key(index: int, pos: Vector3) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = "Key%d" % index
	var bm := BoxMesh.new()
	bm.size = Vector3(key_size, key_size, 0.012)
	mesh.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = key_color
	mat.metallic = 0.5
	mat.roughness = 0.4
	mat.emission_enabled = true
	mat.emission = key_color
	mat.emission_energy_multiplier = 0.15
	mesh.material_override = mat
	mesh.position = pos
	add_child(mesh)

	# A small digit label.
	var lbl := Label3D.new()
	lbl.text = str(index + 1)
	lbl.font_size = 36
	lbl.pixel_size = 0.0008
	lbl.modulate = Color(0.9, 0.93, 1.0)
	lbl.position = pos + Vector3(0, 0, 0.012)
	add_child(lbl)

	var area := Area3D.new()
	area.name = "KeyArea%d" % index
	area.collision_layer = 0
	area.collision_mask = poke_mask
	area.monitoring = true
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(key_size, key_size, 0.04)
	cs.shape = shape
	area.add_child(cs)
	area.position = pos + Vector3(0, 0, 0.015)
	add_child(area)

	var entry := {"area": area, "mesh": mesh, "mat": mat, "base_z": pos.z, "index": index, "down": false}
	_keys.append(entry)
	area.body_entered.connect(_on_key_enter.bind(entry))
	area.body_exited.connect(_on_key_exit.bind(entry))
	area.area_entered.connect(_on_key_enter.bind(entry))
	area.area_exited.connect(_on_key_exit.bind(entry))


func _on_key_enter(_n: Node, entry: Dictionary) -> void:
	if entry["down"]:
		return
	entry["down"] = true
	entry["mesh"].position.z = entry["base_z"] - 0.006
	entry["mat"].emission = lit_color
	entry["mat"].emission_energy_multiplier = 1.6
	key_pressed.emit(entry["index"])
	_register_entry(entry["index"])


func _on_key_exit(_n: Node, entry: Dictionary) -> void:
	if not entry["down"]:
		return
	entry["down"] = false
	entry["mesh"].position.z = entry["base_z"]
	entry["mat"].emission = key_color
	entry["mat"].emission_energy_multiplier = 0.15


func _register_entry(index: int) -> void:
	if _code.is_empty():
		return
	_entered.append(index)
	if _entered.size() > _code.size():
		_entered.pop_front()
	if _entered == _code:
		code_entered.emit()
		_flash_all()
		_entered.clear()


func _flash_all() -> void:
	for entry in _keys:
		entry["mat"].emission = Color(0.3, 0.95, 0.45)
		entry["mat"].emission_energy_multiplier = 2.0
	var t := get_tree().create_timer(0.6)
	t.timeout.connect(func():
		for entry in _keys:
			entry["mat"].emission = key_color
			entry["mat"].emission_energy_multiplier = 0.15)
