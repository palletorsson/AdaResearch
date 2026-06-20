## @identity
## name: Jelly Ball Pit Room
## concept: Bounce & pile (native soft bodies)
## tier: large
## truth: wade in; the pile gives — a room-scale tray sunk into the floor, filled with a heap of soft
##        balls. They settle into each other, squash where they touch, and shift around your legs as you
##        push through. Native self-colliding SoftBody3D pile contained by StaticBody3D walls: a ball pit
##        that actually deforms.
extends Node3D
class_name JellyBallPitRoom

@export var emissive: bool = false
@export var ball_count: int = 7
@export var ball_radius: float = 0.45
@export var tray_size: float = 5.0          # inner span of the pit on the 7x7 floor

const GSB = preload("res://commons/soft_body/grab_soft_body.gd")

var _balls: Array = []

const _COLORS := [
	Color(0.95, 0.4, 0.45), Color(0.45, 0.75, 0.9), Color(0.6, 0.85, 0.45),
	Color(0.95, 0.75, 0.3), Color(0.7, 0.5, 0.9), Color(0.95, 0.55, 0.75),
	Color(0.4, 0.85, 0.75), Color(0.9, 0.6, 0.35),
]


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
	_balls.clear()
	var span: float = tray_size
	var half: float = span * 0.5
	var floor_y: float = -0.05      # large-tier floor sits at y = -0.05
	var wall_h: float = 1.3

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.16, 0.17, 0.21)
	mat.roughness = 0.7
	mat.metallic = 0.2

	# Tray floor — a wide StaticBody3D slab the balls rest on (collision_layer = 1).
	var tray := StaticBody3D.new()
	tray.collision_layer = 1
	tray.collision_mask = 1
	tray.position = Vector3(0, floor_y, 0)
	var tcol := CollisionShape3D.new()
	var tshape := BoxShape3D.new()
	tshape.size = Vector3(span, 0.1, span)
	tcol.shape = tshape
	tray.add_child(tcol)
	var tmesh := MeshInstance3D.new()
	var tbm := BoxMesh.new()
	tbm.size = tshape.size
	tmesh.mesh = tbm
	tmesh.material_override = mat
	tray.add_child(tmesh)
	add_child(tray)

	# Four containing walls so the pile can't roll out — each a StaticBody3D box, layer 1.
	var wall_defs := [
		[Vector3(0, floor_y + wall_h * 0.5, half), Vector3(span + 0.2, wall_h, 0.2)],
		[Vector3(0, floor_y + wall_h * 0.5, -half), Vector3(span + 0.2, wall_h, 0.2)],
		[Vector3(half, floor_y + wall_h * 0.5, 0), Vector3(0.2, wall_h, span + 0.2)],
		[Vector3(-half, floor_y + wall_h * 0.5, 0), Vector3(0.2, wall_h, span + 0.2)],
	]
	for wd in wall_defs:
		var wall := StaticBody3D.new()
		wall.collision_layer = 1
		wall.collision_mask = 1
		wall.position = wd[0]
		var wcol := CollisionShape3D.new()
		var wshape := BoxShape3D.new()
		wshape.size = wd[1]
		wcol.shape = wshape
		wall.add_child(wcol)
		var wmesh := MeshInstance3D.new()
		var wbm := BoxMesh.new()
		wbm.size = wd[1]
		wmesh.mesh = wbm
		wmesh.material_override = mat
		wall.add_child(wmesh)
		add_child(wall)

	# The pile: soft balls dropped at varied positions so they don't perfectly overlap, varied colours,
	# self-colliding (collision_mask includes layer 1, which other soft bodies sit on). They squash
	# where they meet and settle into a heap.
	var r: float = ball_radius
	var inner: float = half - r - 0.15
	var n: int = max(1, ball_count)
	for i in range(n):
		var ang: float = TAU * float(i) / float(n) + 0.3
		var ring: float = inner * (0.15 + 0.6 * float(i % 3) / 2.0)
		var bx: float = cos(ang) * ring
		var bz: float = sin(ang) * ring
		# Stagger heights so they drop and pile rather than spawning interpenetrating.
		var by: float = floor_y + 0.1 + r + float(i) * (r * 0.9)
		var col: Color = _COLORS[i % _COLORS.size()]
		var sb := GSB.soft_setup(SoftBody3D.new(), {
			"mass": 2.5, "stiffness": 0.4, "pressure": 0.5, "damping": 0.18,
			"precision": 4, "color": col, "emissive": emissive,
		})
		sb.mesh = GSB.soft_sphere(r, 10, 14)
		sb.position = Vector3(bx, by, bz)
		add_child(sb)
		_balls.append(sb)

	add_child(_label("WADE IN — THE PILE GIVES", Vector3(0, 3.6, 0)))


func _label(text: String, pos: Vector3) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.font_size = 40
	l.pixel_size = 0.004
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.modulate = Color(0.9, 0.92, 1.0)
	l.outline_size = 8
	return l
