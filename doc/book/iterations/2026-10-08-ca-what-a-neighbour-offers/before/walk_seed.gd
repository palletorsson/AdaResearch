extends Node3D
## One body crossing calls the existing matched INJECT action once.
## This is a receiver for presence, not pressure and not a diffusion source.
var study:Node3D
var visitors:Dictionary={}
var pad_material:StandardMaterial3D

func _ready() -> void:
	study=get_parent()
	var pad:MeshInstance3D=study.box("SeedCrossingPlate",Vector3(1.5,0.012,1.0),Vector3(0,0.012,2.15),Color("263744"))
	pad.reparent(self,false);pad_material=pad.material_override
	for side in [-1,1]:
		var a:MeshInstance3D=study.box("SeedCrossingSide_%d"%side,Vector3(0.025,0.014,1.0),Vector3(side*0.75,0.021,2.15),Color("d5ae74"));a.reparent(self,false)
		var b:MeshInstance3D=study.box("SeedCrossingEnd_%d"%side,Vector3(1.5,0.014,0.025),Vector3(0,0.021,2.15+side*0.5),Color("d5ae74"));b.reparent(self,false)
	var words:Label3D=study.label("SeedCrossingWords","STEP IN\nLEAVE A SEED",44)
	words.pixel_size=0.002;words.position=Vector3(0,0.031,2.15);words.rotation_degrees=Vector3(-90,180,0);add_child(words)
	var area:=Area3D.new();area.name="BodyReceiver";area.collision_layer=0;area.collision_mask=0xFFFFFFFF
	var shape:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(1.5,1.8,1.0);shape.shape=box;shape.position=Vector3(0,0.9,2.15);area.add_child(shape)
	area.body_entered.connect(_entered);area.body_exited.connect(_exited);add_child(area)

func accepts(body:Node3D) -> bool:
	return body is XRToolsPlayerBody or (body is CharacterBody3D and (body.is_in_group("em_walker") or body.is_in_group("player_body") or body.is_in_group("player")))

func _entered(body:Node3D) -> void:
	if not accepts(body):return
	var id:int=body.get_instance_id()
	if visitors.has(id):return
	for old_id in visitors.keys():
		if not is_instance_valid(visitors[old_id].get_ref()):visitors.erase(old_id)
	var was_empty:bool=visitors.is_empty()
	visitors[id]=weakref(body)
	if was_empty:study.inject()
	_update_plate()

func _exited(body:Node3D) -> void:
	visitors.erase(body.get_instance_id());_update_plate()

func _update_plate() -> void:
	pad_material.albedo_color=Color("735269") if not visitors.is_empty() else Color("263744")
