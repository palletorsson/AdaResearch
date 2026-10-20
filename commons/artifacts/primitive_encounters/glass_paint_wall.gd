extends "res://commons/artifacts/whiteboard/whiteboard.gd"
const Geometry = preload("res://commons/artifacts/primitive_encounters/geometry.gd")
func _init() -> void:
	board_width = 3.0; board_height = 1.1
	glass_surface = true; pens_enabled = true; pen_shelf = true; simple_pens = true
func _ready() -> void:
	super()
	for x in [-1.55, 1.55]:
		Geometry.box(self,"Upright",Vector3(x,0.15,0),Vector3(.05,1.8,.07),Color("737d7c"))
		Geometry.box(self,"Foot",Vector3(x,-.73,0),Vector3(.30,.04,.65),Color("737d7c"))
	var body := StaticBody3D.new(); body.name="GlassContact";body.collision_layer=1
	var collision := CollisionShape3D.new();var shape := BoxShape3D.new()
	shape.size=Vector3(board_width,board_height,.024);collision.shape=shape
	body.position=Vector3(0,board_height/2,.012);body.add_child(collision);add_child(body)
	Geometry.label(self,"PEN + GLASS\nTouch to mark. Lift to leave a gap.",Vector3(0,-.28,.07),27)
