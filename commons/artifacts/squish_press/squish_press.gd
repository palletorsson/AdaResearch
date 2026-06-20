## @identity
## name: Squish Press
## concept: Poke & dent (native soft bodies)
## tier: applied
## truth: force in, dent out — strain made visible. A motorised plate rides down onto a soft block,
##        collides, and squashes it; a readout shows how far the plate has travelled (force proxy) and
##        how deep the block has dented in response. Native SoftBody3D under an AnimatableBody3D ram.
extends Node3D
class_name SquishPress

@export var emissive: bool = false
@export var block_size: float = 0.42
@export var block_color: Color = Color(0.55, 0.6, 0.9)
@export var press_depth: float = 0.22      # how far the plate dips below its top rest pose
@export var press_period: float = 4.0      # seconds for a full down-up cycle

const GSB = preload("res://commons/soft_body/grab_soft_body.gd")

var _sb: SoftBody3D
var _pins: Array = []
var _plate: AnimatableBody3D
var _readout: Label3D
var _t: float = 0.0
var _plate_top_y: float = 0.0       # plate rest (highest) y
var _block_rest_top: float = 0.0    # authored top surface of the block (world y)
var _rest_verts: PackedVector3Array


func _ready() -> void:
	_build()
	set_process(true)        # APPLIED: animate the ram + update the readout every frame


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()
	set_process(true)


func _build() -> void:
	_pins.clear()
	_t = 0.0
	_rest_verts = PackedVector3Array()

	var s: float = block_size

	# --- Frame: a ~1 m device. Base plate + two posts + a top crossbeam the ram hangs from. ---
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.18, 0.19, 0.22)
	fmat.roughness = 0.6
	fmat.metallic = 0.3

	var base := MeshInstance3D.new()
	var basebm := BoxMesh.new()
	basebm.size = Vector3(0.9, 0.08, 0.7)
	base.mesh = basebm
	base.position = Vector3(0, 0.04, 0)
	base.material_override = fmat
	add_child(base)

	var beam_y: float = 1.05
	for sx in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		var postbm := BoxMesh.new()
		postbm.size = Vector3(0.08, beam_y, 0.08)
		post.mesh = postbm
		post.position = Vector3(sx * 0.41, beam_y * 0.5, -0.0)
		post.material_override = fmat
		add_child(post)
	var beam := MeshInstance3D.new()
	var beambm := BoxMesh.new()
	beambm.size = Vector3(0.98, 0.1, 0.24)
	beam.mesh = beambm
	beam.position = Vector3(0, beam_y, 0)
	beam.material_override = fmat
	add_child(beam)

	# --- The soft block sitting on the base, base-pinned so it stays put under the press. ---
	var block_bottom: float = 0.08
	var cy: float = block_bottom + s * 0.5
	_block_rest_top = cy + s * 0.5
	var sb := GSB.soft_setup(SoftBody3D.new(), {
		"mass": 2.5, "stiffness": 0.3, "pressure": 0.0, "damping": 0.3,
		"precision": 5, "color": block_color, "emissive": emissive,
	})
	sb.mesh = GSB.soft_box(s, 6)
	sb.position = Vector3(0, cy, 0)
	add_child(sb)
	_sb = sb
	# Pin the bottom face to the world: block can't slide, top stays soft to be squashed.
	_pins.append({"pos": Vector3(0, -s * 0.5, 0), "node": null})

	# --- The ram: an AnimatableBody3D plate the soft body collides with (collision_layer=1). ---
	# It rests just above the block and is driven down each frame in _process; physics moves the
	# pinned-bottom soft body out of its way → a real collision dent, not a faked offset.
	_plate = AnimatableBody3D.new()
	_plate.collision_layer = 1
	_plate.collision_mask = 0
	var plate_mesh := MeshInstance3D.new()
	var pbm := BoxMesh.new()
	pbm.size = Vector3(s + 0.12, 0.06, s + 0.12)
	plate_mesh.mesh = pbm
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.8, 0.5, 0.2)
	pmat.roughness = 0.4
	pmat.metallic = 0.4
	if emissive:
		pmat.emission_enabled = true
		pmat.emission = Color(0.8, 0.5, 0.2)
		pmat.emission_energy_multiplier = 0.3
	plate_mesh.material_override = pmat
	_plate.add_child(plate_mesh)
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(s + 0.12, 0.06, s + 0.12)
	col.shape = box
	_plate.add_child(col)
	_plate_top_y = _block_rest_top + 0.05      # rest just above the block's top face
	_plate.position = Vector3(0, _plate_top_y, 0)
	add_child(_plate)

	# --- Readout: dent depth + plate travel (force proxy), updated in _process. ---
	_readout = _label("PRESS READY", Vector3(0, 1.32, 0))
	add_child(_readout)
	add_child(_label("FORCE IN, DENT OUT — STRAIN MADE VISIBLE", Vector3(0, 1.5, 0)))

	call_deferred("_apply_pins")
	call_deferred("_snapshot_rest")


func _apply_pins() -> void:
	if not is_instance_valid(_sb):
		return
	for p in _pins:
		GSB.pin_patch(_sb, p["pos"], p["node"], 0.13)


func _snapshot_rest() -> void:
	# Capture the block's rest vertices once pins are applied, so dent depth is measured against rest.
	if is_instance_valid(_sb):
		_rest_verts = _mesh_verts(_sb)


func _process(delta: float) -> void:
	if not is_instance_valid(_plate):
		return
	_t += delta
	# Smooth down-up ram travel (0 at top, 1 at bottom of stroke).
	var phase: float = 0.5 - 0.5 * cos(_t / max(press_period, 0.01) * TAU)
	var travel: float = phase * press_depth
	_plate.position.y = _plate_top_y - travel

	# Dent depth: how far the block's current lowest-surface point sits below its rest top surface.
	var dent: float = _measure_dent()
	var force_proxy: float = travel        # plate travel stands in for applied force
	if is_instance_valid(_readout):
		_readout.text = "FORCE %.3f m   DENT %.3f m" % [force_proxy, dent]


# Largest downward displacement of any surface vertex vs. its rest pose (in metres).
func _measure_dent() -> float:
	if not is_instance_valid(_sb) or _rest_verts.is_empty():
		return 0.0
	var live := _mesh_verts(_sb)
	if live.size() != _rest_verts.size():
		return 0.0
	var d := 0.0
	for i in range(live.size()):
		var drop: float = _rest_verts[i].y - live[i].y    # positive = pushed down
		if drop > d:
			d = drop
	return d


func _mesh_verts(sb: SoftBody3D) -> PackedVector3Array:
	var out := PackedVector3Array()
	if sb == null or sb.mesh == null:
		return out
	var arrays: Array = sb.mesh.surface_get_arrays(0)
	if arrays.size() > Mesh.ARRAY_VERTEX:
		out = arrays[Mesh.ARRAY_VERTEX]
	return out


func _label(text: String, pos: Vector3) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.font_size = 26
	l.pixel_size = 0.0015
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.modulate = Color(0.9, 0.92, 1.0)
	l.outline_size = 6
	return l
