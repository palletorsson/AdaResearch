## @identity
## name: Blob Pet Toy
## concept: Soft pets & membranes (native)
## tier: small
## truth: a soft pet — grab its scruff, it dangles and wobbles. A little round soft creature with two
##        googly eyes that watch you, held near the origin by one lightly pinned patch so it sits and
##        jiggles; a grabbable scruff-nub on top lets you lift it and it dangles, body swinging soft
##        underneath. Native SoftBody3D — the eyes are rigid, only the body deforms.
extends Node3D
class_name BlobPetToy

@export var emissive: bool = false
@export var blob_radius: float = 0.17               # ~0.34 m across
@export var blob_color: Color = Color(0.95, 0.55, 0.7)

const GSB = preload("res://commons/soft_body/grab_soft_body.gd")

var _sb: SoftBody3D
var _pins: Array = []   # [{pos:Vector3, node:Node3D}]


func _ready() -> void:
	_build()
	set_process(false)


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	_pins.clear()
	var r: float = blob_radius

	# The soft pet body — a dense sphere held near the origin (centre ~0.4 m up, in the hand).
	var cy: float = 0.4
	var sb := GSB.soft_setup(SoftBody3D.new(), {
		"mass": 0.5, "stiffness": 0.28, "pressure": 0.0, "damping": 0.3,
		"precision": 5, "color": blob_color, "emissive": emissive,
	})
	sb.mesh = GSB.soft_sphere(r, 12, 16)
	sb.position = Vector3(0, cy, 0)
	add_child(sb)
	_sb = sb

	# Rest-pin one underside patch lightly to the world so the pet sits and wobbles
	# instead of falling away. A single soft anchor keeps it floating, floppy elsewhere.
	_pins.append({"pos": Vector3(0, -r, 0), "node": null})

	# A grabbable scruff-nub on top — lift it and the body dangles and swings beneath.
	var scruff_local := Vector3(0, r, 0)
	var scruff := GSB.add_handle(self, sb.to_global(scruff_local), 0.05, Color(0.95, 0.85, 0.4))
	_pins.append({"pos": scruff_local, "node": scruff})

	# Two googly eyes — rigid MeshInstance3D children of the artifact (they do NOT deform),
	# hovering at the front so the pet watches you. White ball + dark pupil each.
	_add_eye(Vector3(-r * 0.45, cy + r * 0.25, r * 0.92), r)
	_add_eye(Vector3(r * 0.45, cy + r * 0.25, r * 0.92), r)

	add_child(_label("GRAB ITS SCRUFF — IT DANGLES", Vector3(0, 0.7, 0)))
	call_deferred("_apply_pins")


func _add_eye(pos: Vector3, r: float) -> void:
	var white := MeshInstance3D.new()
	var wm := SphereMesh.new()
	wm.radius = r * 0.42
	wm.height = r * 0.84
	wm.rings = 8
	wm.radial_segments = 12
	white.mesh = wm
	white.position = pos
	var wmat := StandardMaterial3D.new()
	wmat.albedo_color = Color(0.98, 0.98, 1.0)
	wmat.roughness = 0.25
	white.material_override = wmat
	add_child(white)

	var pupil := MeshInstance3D.new()
	var pm := SphereMesh.new()
	pm.radius = r * 0.2
	pm.height = r * 0.4
	pm.rings = 6
	pm.radial_segments = 10
	pupil.mesh = pm
	# Push the pupil slightly forward of the eyeball surface, toward the viewer (+Z).
	pupil.position = pos + Vector3(0, 0, r * 0.3)
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.05, 0.05, 0.08)
	pmat.roughness = 0.2
	pupil.material_override = pmat
	add_child(pupil)


func _apply_pins() -> void:
	if not is_instance_valid(_sb):
		return
	for p in _pins:
		GSB.pin_patch(_sb, p["pos"], p["node"], 0.1)


func _label(text: String, pos: Vector3) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.font_size = 24
	l.pixel_size = 0.0014
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.modulate = Color(0.9, 0.92, 1.0)
	l.outline_size = 6
	return l
