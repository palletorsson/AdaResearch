## @identity
## name: Tentacle Grab Bench
## concept: Soft pets & membranes (native)
## tier: medium
## truth: no bone — grab the tip and the whole arm follows. A tall soft tentacle rises from a bench,
##        rooted at its base (pinned to the world) and free everywhere above; a grabbable nub at the
##        very tip lets you take hold and wave it, the whole limb trailing and curling after your hand,
##        then settling. Native SoftBody3D, finely subdivided up its length so it bends like a real arm.
extends Node3D
class_name TentacleGrabBench

@export var emissive: bool = false
@export var tentacle_height: float = 1.1
@export var tentacle_thickness: float = 0.16
@export var tentacle_color: Color = Color(0.55, 0.8, 0.55)

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
	var th: float = tentacle_thickness
	var hgt: float = tentacle_height

	# Bench base and pillar — the tentacle is rooted in the bench top at y = 0.85.
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.16, 0.17, 0.2)
	bmat.roughness = 0.7
	var base := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.0, 0.2, 0.8)
	base.mesh = bm
	base.position = Vector3(0, 0.75, 0)
	base.material_override = bmat
	add_child(base)
	var pillar := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.25, 0.65, 0.25)
	pillar.mesh = pm
	pillar.position = Vector3(0, 0.42, 0)
	pillar.material_override = bmat
	add_child(pillar)

	# The soft tentacle: a tall box, tapered toward the tip and densely subdivided up its
	# length so it bends and trails. Local origin at its centre; height runs along local Y.
	var top_thick: float = th * 0.45
	var rod := BoxMesh.new()
	rod.size = Vector3(th, hgt, th)
	rod.subdivide_height = 14                       # length axis — needs density to curl
	rod.subdivide_width = 2
	rod.subdivide_depth = 2
	var sb := GSB.soft_setup(SoftBody3D.new(), {
		"mass": 1.4, "stiffness": 0.18, "pressure": 0.0, "damping": 0.22,
		"precision": 5, "color": tentacle_color, "emissive": emissive,
	})
	sb.mesh = rod
	# Bench top y = 0.85; lift the rod so its base sits just on the bench (centre = top + h/2).
	var base_y: float = 0.85
	var cy: float = base_y + hgt * 0.5
	sb.position = Vector3(0, cy, 0)
	add_child(sb)
	_sb = sb

	# Root the BASE of the tentacle to the world (local -Y face) so it stands up.
	var base_local := Vector3(0, -hgt * 0.5, 0)
	_pins.append({"pos": base_local, "node": null})

	# A grabbable nub at the very TIP (local +Y) — grab it and wave; the whole arm follows.
	var tip_local := Vector3(0, hgt * 0.5, 0)
	var tip := GSB.add_handle(self, sb.to_global(tip_local), 0.06, Color(0.95, 0.6, 0.35))
	_pins.append({"pos": tip_local, "node": tip})

	# A couple of rigid suction-bump decorations near the base (do NOT deform) for character.
	_add_bump(Vector3(top_thick + 0.02, base_y + hgt * 0.3, 0), th)
	_add_bump(Vector3(-(top_thick + 0.02), base_y + hgt * 0.55, 0.0), th)

	add_child(_label("GRAB THE TIP — THE WHOLE ARM FOLLOWS", Vector3(0, 1.6, 0)))
	call_deferred("_apply_pins")


func _add_bump(pos: Vector3, th: float) -> void:
	var b := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = th * 0.3
	sm.height = th * 0.6
	sm.rings = 6
	sm.radial_segments = 10
	b.mesh = sm
	b.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.5, 0.55)
	mat.roughness = 0.5
	b.material_override = mat
	add_child(b)


func _apply_pins() -> void:
	if not is_instance_valid(_sb):
		return
	# Wider grip at the base so the whole root patch anchors; tip grip just catches the cap.
	for p in _pins:
		var grip: float = max(0.12, tentacle_thickness)
		if p["node"] == null:
			grip = max(0.16, tentacle_thickness * 1.2)
		GSB.pin_patch(_sb, p["pos"], p["node"], grip)


func _label(text: String, pos: Vector3) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.font_size = 28
	l.pixel_size = 0.0016
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.modulate = Color(0.9, 0.92, 1.0)
	l.outline_size = 6
	return l
