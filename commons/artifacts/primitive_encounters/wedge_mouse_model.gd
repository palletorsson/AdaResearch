extends Node3D
## A player-steered wedge maze. Physical walls can be rearranged by hand.
## Theseus is a spatial reference; this mouse has no search or learning algorithm.
const Kit = preload("geometry.gd")
const Piece = preload("piece.gd")
const JoystickScene = preload("res://commons/interactables/joystick_zero.tscn")
const TOP: float = 0.82
const START := Vector3(-1.00, TOP + 0.012, 0)
const GRID_ORIGIN := Vector2(-0.80, -0.45)
const CELL := Vector2(0.36, 0.30)
const COLS := 5
const ROWS := 3
const WALL_HEIGHT: float = 0.24
const WALL_BASE: float = 0.08
const GOAL := Vector2i(4, 1)
const PASSAGES := [
	Vector4i(0,1,0,0), Vector4i(0,0,1,0), Vector4i(1,0,1,1),
	Vector4i(1,1,1,2), Vector4i(1,2,2,2), Vector4i(2,2,3,2),
	Vector4i(3,2,3,1), Vector4i(3,1,2,1),
	# Branching passages let the player explore and backtrack.
	Vector4i(0,1,0,2), Vector4i(1,0,2,0), Vector4i(2,0,3,0),
	Vector4i(3,0,4,0), Vector4i(4,0,4,1), Vector4i(4,1,4,2)
]
var pieces: Array[XRToolsPickable] = []
var homes: Array[Transform3D] = []
var mouse: CharacterBody3D
var cheese: XRToolsPickable
var cheese_home: Transform3D
var joystick: Node3D
var outcome := "ready"
var facing := Vector3.RIGHT
var return_delay: float = 0.0

func _ready() -> void:
	Kit.box(self,"Plinth",Vector3(0,TOP/2,0),Vector3(2.8,TOP,1.0),Color("d2c4b2"))
	build_maze()
	build_cheese()
	build_mouse()
	# Local +Z is the neutral stick axis. Lay its base on the plinth:
	# +Z points up, local +Y goes forwards, and local +X goes right.
	joystick=JoystickScene.instantiate();joystick.name="SteerMouse"
	joystick.basis=Basis(Vector3.BACK,Vector3.RIGHT,Vector3.UP)
	joystick.position=Vector3(-1.24,TOP+0.02,0)
	add_child(joystick)
	reset_mouse()

func cell_position(cell: Vector2i) -> Vector3:
	return Vector3(GRID_ORIGIN.x+(cell.x+0.5)*CELL.x,TOP+0.012,GRID_ORIGIN.y+(cell.y+0.5)*CELL.y)

func passage(a: Vector2i, b: Vector2i) -> bool:
	for edge in PASSAGES:
		var first:=Vector2i(edge.x,edge.y);var second:=Vector2i(edge.z,edge.w)
		if (a==first and b==second) or (a==second and b==first):return true
	return false

func build_maze() -> void:
	# Every wall stands on its broad edge. Passages are actual empty spaces.
	for z in ROWS:
		for x in range(COLS+1):
			if x==0 and z==1:continue # mouse entrance
			if x>0 and x<COLS and passage(Vector2i(x-1,z),Vector2i(x,z)):continue
			add_wall("WallX_%d_%d"%[x,z],Vector2(GRID_ORIGIN.x+x*CELL.x,GRID_ORIGIN.y+(z+0.5)*CELL.y),CELL.y,0)
	for z in range(ROWS+1):
		for x in COLS:
			if z>0 and z<ROWS and passage(Vector2i(x,z-1),Vector2i(x,z)):continue
			add_wall("WallZ_%d_%d"%[x,z],Vector2(GRID_ORIGIN.x+(x+0.5)*CELL.x,GRID_ORIGIN.y+z*CELL.y),CELL.x,PI/2)

func add_wall(title: String, centre: Vector2, length: float, yaw: float) -> void:
	var p:=Piece.new();p.name=title
	var turn:=Basis(Vector3.UP,yaw)
	# Reverse the earlier quarter-turn: the wide edge is now at the bottom.
	p.basis=turn*Basis(Vector3.BACK,-PI/2)*Basis(Vector3.UP,PI/2)
	p.position=Vector3(centre.x,TOP+WALL_HEIGHT/2,centre.y)-turn*Vector3(WALL_BASE/2,0,0)
	var vertices:=Kit.wedge(length,WALL_BASE,WALL_HEIGHT)
	Kit.solid(p,"Wedge",vertices,Kit.wedge_faces(),Color("b4a1c9"),false)
	var shape:=ConvexPolygonShape3D.new();shape.points=vertices;shape.margin=0.001
	var c:=CollisionShape3D.new();c.name="CollisionShape3D";c.shape=shape;p.add_child(c)
	add_child(p);pieces.append(p);homes.append(p.transform)
	p.picked_up.connect(func(_body):joystick.set_angles_degrees(Vector2.ZERO))

func build_cheese() -> void:
	cheese=Piece.new();cheese.name="Cheese";cheese.floats=false;cheese.freeze=false
	cheese.release_mode=XRToolsPickable.ReleaseMode.UNFROZEN
	# One symmetric wedge with a centred ridge.
	var vertices:=PackedVector3Array([
		Vector3(-0.09,0,-0.07),Vector3(0.09,0,-0.07),Vector3(0,0.17,-0.07),
		Vector3(-0.09,0,0.07),Vector3(0.09,0,0.07),Vector3(0,0.17,0.07)])
	Kit.solid(cheese,"CheeseSurface",vertices,[[0,1,2],[3,5,4],[0,3,4,1],[0,2,5,3],[1,4,5,2]],Color("e9bc4e"),false)
	var shape:=ConvexPolygonShape3D.new();shape.points=vertices;shape.margin=0.001
	var c:=CollisionShape3D.new();c.name="CollisionShape3D";c.shape=shape;cheese.add_child(c)
	cheese.position=cell_position(GOAL);cheese.position.y=TOP+0.003
	add_child(cheese);cheese_home=cheese.transform

func build_mouse() -> void:
	mouse=CharacterBody3D.new();mouse.name="BrownWedgeMouse"
	mouse.collision_layer=0;mouse.collision_mask=1
	mouse.floor_max_angle=deg_to_rad(50);mouse.floor_snap_length=0.025;mouse.safe_margin=0.001
	var c:=CollisionShape3D.new();var capsule:=CapsuleShape3D.new();capsule.radius=0.032;capsule.height=0.09
	c.shape=capsule;c.position.y=0.045;mouse.add_child(c)
	var skin:=MeshInstance3D.new();var prism:=PrismMesh.new();prism.size=Vector3(0.16,0.10,0.09);prism.left_to_right=0
	skin.mesh=prism;skin.position.y=0.05;skin.material_override=Kit.material(Color("78503b"));mouse.add_child(skin)
	add_child(mouse)

func reset_mouse() -> void:
	return_delay=0;outcome="ready";facing=Vector3.RIGHT
	mouse.position=START;mouse.rotation=Vector3.ZERO;mouse.velocity=Vector3.ZERO
	joystick.set_angles_degrees(Vector2.ZERO)

func steering() -> Vector3:
	var angles:Vector2=joystick.get_angles_degrees()/45.0
	var input:Vector3=joystick.basis*Vector3(angles.x,-angles.y,0).limit_length(1.0)
	return input if input.length()>0.08 else Vector3.ZERO

func piece_held() -> bool:
	return cheese.held() or pieces.any(func(p):return p.held())

func _physics_process(delta: float) -> void:
	# Recover off-table pieces. Returning the mouse preserves edited walls.
	for i in pieces.size():
		if not pieces[i].held() and (pieces[i].position.y < -0.5 or pieces[i].position.length() > 4.0):pieces[i].transform=homes[i]
	if not cheese.held() and (cheese.position.y<TOP-0.2 or cheese.position.length()>4.0):
		cheese.transform=cheese_home;cheese.linear_velocity=Vector3.ZERO;cheese.angular_velocity=Vector3.ZERO
	if mouse.position.y<TOP-0.15:
		outcome="returning";return_delay+=delta
		if return_delay>=0.7:reset_mouse()
		return
	var direction:=steering() if not piece_held() else Vector3.ZERO
	if direction.length()>0.08:facing=direction.normalized()
	var world_horizontal:=global_basis*(direction*0.24)
	mouse.velocity.x=world_horizontal.x;mouse.velocity.z=world_horizontal.z
	if mouse.is_on_floor():mouse.velocity.y=-0.15
	mouse.velocity.y-=3.0*delta
	mouse.move_and_slide()
	mouse.rotation.y=-atan2(facing.z,facing.x)
	var to_cheese:=cheese.position-mouse.position
	if mouse.is_on_floor() and Vector2(to_cheese.x,to_cheese.z).length()<0.18 and absf(to_cheese.y)<0.15:outcome="arrived"

func get_museum_occupied_cells() -> Array:
	return [Vector2i(-1,0),Vector2i.ZERO,Vector2i(1,0)]
