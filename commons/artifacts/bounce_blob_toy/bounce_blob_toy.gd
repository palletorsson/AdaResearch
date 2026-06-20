## @identity
## name: Bounce Blob Toy
## concept: Bounce & pile (native soft bodies)
## tier: small
## truth: a ball that bounces instead of breaking — a held squishy sphere dropped into a little cupped
##        saucer. It lands, flattens, and springs back, jiggling itself still. Native SoftBody3D in a
##        StaticBody3D bowl: the impact has somewhere to go, so nothing shatters.
extends Node3D
class_name BounceBlobToy

@export var emissive: bool = false
@export var blob_radius: float = 0.16          # ~0.32m ball
@export var blob_color: Color = Color(0.95, 0.45, 0.4)
@export var bounciness: float = 0.6            # SoftBody pressure → springiness

const GSB = preload("res://commons/soft_body/grab_soft_body.gd")

var _sb: SoftBody3D


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
	var r: float = blob_radius

	# Cupped saucer base: a ring of short StaticBody3D wall segments around a floor disc, so the ball
	# rolls back to centre and squishes rather than escaping. collision_layer = 1 (soft bodies
	# collide with layer 1).
	var bowl_y: float = 0.0
	var bowl_r: float = r * 1.9
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.19, 0.23)
	mat.roughness = 0.6
	mat.metallic = 0.25

	# Floor disc.
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = 1
	floor_body.collision_mask = 1
	floor_body.position = Vector3(0, bowl_y, 0)
	var floor_col := CollisionShape3D.new()
	var floor_shape := CylinderShape3D.new()
	floor_shape.radius = bowl_r
	floor_shape.height = 0.04
	floor_col.shape = floor_shape
	floor_body.add_child(floor_col)
	var floor_mesh := MeshInstance3D.new()
	var fcm := CylinderMesh.new()
	fcm.top_radius = bowl_r
	fcm.bottom_radius = bowl_r
	fcm.height = 0.04
	floor_mesh.mesh = fcm
	floor_mesh.material_override = mat
	floor_body.add_child(floor_mesh)
	add_child(floor_body)

	# Ring wall — tilted box segments forming a shallow cup lip.
	var seg_count: int = 12
	for i in seg_count:
		var ang: float = TAU * float(i) / float(seg_count)
		var wall := StaticBody3D.new()
		wall.collision_layer = 1
		wall.collision_mask = 1
		var wx: float = cos(ang) * bowl_r
		var wz: float = sin(ang) * bowl_r
		wall.position = Vector3(wx, bowl_y + r * 0.55, wz)
		wall.rotation = Vector3(0, -ang, 0.35)   # lean inward to cup the ball
		var wcol := CollisionShape3D.new()
		var wshape := BoxShape3D.new()
		var seg_w: float = (TAU * bowl_r) / float(seg_count) * 0.62
		wshape.size = Vector3(seg_w, r * 1.3, 0.05)
		wcol.shape = wshape
		wall.add_child(wcol)
		var wmesh := MeshInstance3D.new()
		var wbm := BoxMesh.new()
		wbm.size = wshape.size
		wmesh.mesh = wbm
		wmesh.material_override = mat
		wall.add_child(wmesh)
		add_child(wall)

	# The squishy ball — pressure-inflated so it springs back after each landing.
	var cy: float = bowl_y + r * 1.4 + 0.12     # start a little above the cup so it drops + bounces
	var sb := GSB.soft_setup(SoftBody3D.new(), {
		"mass": 1.0, "stiffness": 0.5, "pressure": bounciness, "damping": 0.12,
		"precision": 5, "color": blob_color, "emissive": emissive,
	})
	sb.mesh = GSB.soft_sphere(r, 12, 16)
	sb.position = Vector3(0, cy, 0)
	add_child(sb)
	_sb = sb

	add_child(_label("A BALL THAT BOUNCES\nINSTEAD OF BREAKING", Vector3(0, bowl_r + 0.5, 0)))


func _label(text: String, pos: Vector3) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.font_size = 26
	l.pixel_size = 0.0014
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.modulate = Color(0.9, 0.92, 1.0)
	l.outline_size = 6
	return l
