extends Node3D
## A grabbable upgrade cassette in a mains-connected bracket, shared by mouse/XR.
const FX := preload("laser_fx.gd")
const Supply := preload("hardware_supply.gd")
var module: XRToolsPickable
var world: Node3D
var readout: Label3D

func _ready() -> void:
	world = get_tree().get_first_node_in_group("void_game") as Node3D
	var cream := FX.finish(Color("e5e0cf"))
	var dark := FX.finish(Color("30332f"))
	FX.box(self,Vector3(0,1.25,-0.12),Vector3(0.64,0.72,0.14),cream,"SupplyBracket")
	FX.box(self,Vector3(0,0.96,0.04),Vector3(0.54,0.08,0.42),dark,"Cradle")
	FX.box(self,Vector3(0,1.78,-0.03),Vector3(1.0,0.46,0.08),cream,"InstructionPlate")
	module = XRToolsPickable.new(); module.name = "LaserCassette"
	module.freeze = true; module.collision_layer = 4; module.collision_mask = 1
	module.position = Vector3(0,1.25,0.12)
	var collider := CollisionShape3D.new(); collider.name = "CollisionShape3D"
	var shape := BoxShape3D.new(); shape.size = Vector3(0.32,0.25,0.32)
	collider.shape = shape; module.add_child(collider)
	FX.box(module,Vector3.ZERO,Vector3(0.3,0.23,0.28),dark,"Cassette")
	for x in [-0.09,0,0.09]:
		FX.box(module,Vector3(x,0,0.15),Vector3(0.035,0.15,0.025),FX.finish(Color("9cf8ff"),true),"Pulse")
	add_child(module)
	module.picked_up.connect(_taken)
	readout = Label3D.new(); readout.name = "Instructions"
	readout.text = "CATALYST / LASER BURST\nGRAB CASSETTE\nHands together + trigger\nDesktop: hold C + click"
	readout.font_size = 32; readout.pixel_size = 0.0019; readout.outline_size = 0
	readout.modulate = Color("30332f")
	readout.position = Vector3(0,1.78,0.03); add_child(readout)
	Supply.connect_unit(self,Vector3(0,2.02,-0.15))
	if is_instance_valid(world):
		world.laser_acquired.connect(_refresh)
		_refresh()

func _taken(_pickable: Node3D) -> void:
	if is_instance_valid(world):
		world.acquire_laser()
		_refresh.call_deferred()

func _refresh() -> void:
	if not is_instance_valid(world) or not world.laser_unlocked: return
	readout.text = "LASER BURST / INSTALLED\nHands together + trigger\nDesktop: hold C + click"
	if is_instance_valid(module):
		# Defer freeing until XRTools has completed its pick-up signal dispatch.
		_retire_module.call_deferred()

func _retire_module() -> void:
	if not is_instance_valid(module) or module.is_queued_for_deletion(): return
	var retired := module
	module = null
	if retired.is_picked_up():
		var grabber := retired.get_picked_up_by()
		if grabber.has_method("drop_object"): grabber.drop_object()
		else: retired.let_go(grabber,Vector3.ZERO,Vector3.ZERO)
	retired.hide(); retired.freeze=true; retired.collision_layer=0; retired.collision_mask=0
	retired.enabled=false
	# XRTools releases collision-hand exceptions after 0.5 s; retain the RID until then.
	get_tree().create_timer(0.65).timeout.connect(func():
		if is_instance_valid(retired): retired.queue_free())
