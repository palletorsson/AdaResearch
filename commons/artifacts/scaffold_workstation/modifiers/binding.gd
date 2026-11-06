extends Node3D
## Opt-in adapter for a frozen workbench revision. No new mesh/collider per tick.
## A whole rigid assembly moves; cellular state changes only its actual quad materials.
const Model=preload("../model.gd")
var work:Node3D
var experiment:RefCounted
var links:Array=[]
var running:=false
var base_records:Array=[]

func configure(station:Node3D,document:RefCounted)->bool:
	if not station._interactive:return false
	# This experiment modifies fixed frames. Loose wedges/pyramids keep their
	# gravity and need a different adapter; never silently freeze them into a wall.
	if document.members.any(func(m):return Model.is_prefab(m.record.kind)):return false
	work=station;experiment=document
	if not work.model.restore(experiment.records()):return false
	work.redraw()
	if not work.build_copy():return false
	base_records=work.model.records.duplicate(true)
	var structure:Node3D=work.output.get_node("Structure")
	var records:Array=work.geometry_records()
	var bodies:Array=structure.get_children()
	for i in bodies.size():
		var old:PhysicsBody3D=bodies[i];var body:=AnimatableBody3D.new()
		body.name=old.name;body.collision_layer=old.collision_layer;body.collision_mask=old.collision_mask;body.sync_to_physics=false
		body.set_meta("workshop_kind",records[i].kind)
		var home:Transform3D=old.transform
		for child in old.get_children():old.remove_child(child);body.add_child(child)
		structure.remove_child(old);old.free();structure.add_child(body);body.transform=home
		var id:String=experiment.id_for(records[i]);body.set_meta("modifier_member",id)
		var hand:Node3D=work.drawing.get_child(0) if id=="origin" else null
		if hand==null:
			for piece in work.drawing.get_children():
				if piece.has_meta("record_index") and experiment.id_for(work.model.records[piece.get_meta("record_index")])==id:hand=piece;break
		if hand==null:return false
		var materials:Array=[]
		if records[i].kind=="quad":
			for host in [body,hand]:
				var mesh:MeshInstance3D=host.get_child(0)
				mesh.material_override=mesh.material_override.duplicate()
				materials.append(mesh.material_override)
		links.append({"id":id,"body":body,"home":home,"hand":hand,"hand_home":hand.transform,"record":records[i],"materials":materials})
	process_physics_priority=-150;apply_state();return true

func scaled_pose(unit:float)->Transform3D:
	var pose:Transform3D=experiment.assembly_pose();pose.origin*=unit/Model.WORLD_STEP;return pose

func apply_state()->bool:
	if not is_instance_valid(work) or is_instance_valid(work.held) or work.model.records!=base_records:return false
	var offset:Vector3=work.fitted_offset
	var world_pose:Transform3D=Transform3D(Basis.IDENTITY,offset)*scaled_pose(work.output_unit())*Transform3D(Basis.IDENTITY,-offset)
	var hand_pose:Transform3D=scaled_pose(Model.HAND_STEP)
	for link in links:
		if not is_instance_valid(link.body) or not is_instance_valid(link.hand):return false
		link.body.transform=world_pose*link.home
		link.hand.transform=hand_pose*link.hand_home
		var index:int=experiment.cell_index(link.record)
		if index<0:continue
		var active:bool=experiment.settings.cells and experiment.cells[index]==1
		for material:StandardMaterial3D in link.materials:
			var color:=Color("e4eeeb") if active else Color("465052")
			color.a=material.albedo_color.a # Keep the hand model's holographic opacity.
			material.albedo_color=color
			material.emission_enabled=active;material.emission=Color("e4eeeb");material.emission_energy_multiplier=1.2 if active else 0.0
	return true

func _physics_process(delta:float)->void:
	if not running:return
	experiment.advance(delta)
	if not apply_state():running=false

func named_bodies()->Dictionary:
	var result:Dictionary={}
	for link in links:result[link.id]=link.body
	return result
