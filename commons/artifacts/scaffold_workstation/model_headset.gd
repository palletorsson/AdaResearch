extends "res://commons/artifacts/primitive_encounters/piece.gd"
## A physical invitation: hold the visor at your eyes. Desktop uses held-tool action.
const Kit=preload("res://commons/artifacts/primitive_encounters/geometry.gd")
const Furniture=preload("shop_furniture.gd")
var visit:Node3D
var home:=Transform3D.IDENTITY
var dwell:=0.0
var queued:=false

func _ready()->void:
	super._ready()
	name="ModelHeadset"
	Kit.box(self,"Visor",Vector3.ZERO,Vector3(.225,.095,.09),Color("dce4df"),false)
	Kit.box(self,"FaceSeal",Vector3(0,0,.045),Vector3(.205,.075,.025),Color("263437"),false)
	for x in [-.053,.053]:
		var lens:=Kit.box(self,"Lens",Vector3(x,0,.061),Vector3(.065,.05,.006),Color("9fbcb9"),false)
		lens.material_override.emission_enabled=true;lens.material_override.emission=Color("96b0ad");lens.material_override.emission_energy_multiplier=.3
		Furniture.tube(self,"Strap",Vector3(signf(x)*.115,0,0),Vector3(signf(x)*.115,0,.16),.009,Color("819490"))
	Furniture.tube(self,"BackStrap",Vector3(-.115,0,.16),Vector3(.115,0,.16),.009,Color("819490"))
	var collision:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(.23,.10,.12);collision.shape=shape;add_child(collision)
	home=transform
	picked_up.connect(func(_p):dwell=0;queued=false)
	dropped.connect(func(_p):dock.call_deferred())
	action_pressed.connect(func(_p):
		var game:Node=get_tree().get_first_node_in_group("void_game")
		if game!=null and not game.vr and held():request_entry())

func _physics_process(delta:float)->void:
	if not held() or queued or not is_instance_valid(visit) or visit.active:return
	var game:Node=get_tree().get_first_node_in_group("void_game")
	if game==null or not game.vr:return
	# A deliberate short hold at the eyes, not immediate activation on pickup.
	var near:bool=global_position.distance_to(game.camera.global_position)<.22*XRServer.world_scale
	dwell=dwell+delta if near else 0.0
	if dwell>.30:request_entry()

func request_entry()->void:
	if queued or not is_instance_valid(visit):return
	queued=true;visit.enter.call_deferred()

func dock()->void:
	if held():return
	transform=home;linear_velocity=Vector3.ZERO;angular_velocity=Vector3.ZERO;freeze=true
	PhysicsServer3D.body_set_state(get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,global_transform)
	dwell=0;queued=false
