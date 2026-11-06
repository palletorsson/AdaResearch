extends "res://commons/void/trials/principal_places/places.gd"
## Opt-in receiver. The approved floor continues using its original receiver.
const Lift=preload("res://commons/artifacts/movable_pivot/route_lift.gd")
var lifts:Array[Node3D]=[]

func _ready()->void:
	super._ready()
	for item in recipe.get("lifts",[]):
		var lift:=Node3D.new();lift.set_script(Lift);lift.name=item.id
		lift.rise=float(item.rise);lift.transform=Motion.pose(item,recipe.grid,0,{})
		add_child(lift);lifts.append(lift)
		lift.set_meta("grid_part",item.id);lift.set_meta("grid_owner",get_instance_id())
		bodies[item.id]=lift;parts[item.id]=item;offsets[item.id]=Transform3D.IDENTITY
		part_defaults[item.id]={"position":array(lift.position),"rotation":array(lift.rotation_degrees),"bounds":[-1,-1,-1,2,item.rise+2,2]}
	# Context bounds follow this recipe rather than the original three-place hall.
	var extent:=AABB()
	var first:=true
	for item in recipe.get("places",[]):
		var b:Array=item.bounds
		var box:=AABB(Vector3(b[0],b[1],b[2]),Vector3(b[3],b[4],b[5]))
		extent=box if first else extent.merge(box);first=false
	part_defaults.PlaceContext.bounds=array(extent.position)+array(extent.size)

func contains_visitor(at:Vector3)->bool:
	if isolated_parts:return false
	for item in recipe.get("places",[]):
		var b:Array=item.bounds
		if AABB(Vector3(b[0],b[1],b[2]),Vector3(b[3],b[4],b[5])).has_point(to_local(at)):return true
	return false

func apply_grid_config(config:Dictionary)->void:
	super.apply_grid_config(config)
	for lift in lifts:
		if is_instance_valid(lift):lift.rebase()

func prepare_editor_preview()->void:
	super.prepare_editor_preview()
	for lift in lifts:
		if is_instance_valid(lift):lift.prepare_editor_preview()
