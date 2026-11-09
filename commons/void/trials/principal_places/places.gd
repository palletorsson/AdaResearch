extends "res://commons/modular/grid_playground.gd"
## Static proportions trial. The normal recipe adapter retains editable members.
const Insert=preload("activity_insert.gd")
const Activity=preload("res://commons/modular/places/place_activity.gd")
const Boards=preload("res://commons/modular/places/board_builder.gd")
@export var sidecar_path:=""   # a sidecar of activities and boards to merge; "" = activities.json beside the recipe (when the recipe comes from its file)

func _ready()->void:
	# the sidecar (activities.json beside the approved recipe): activities and framed boards compiled into the loaded
	# recipe before the playground builds, so recipe.json stays what it was
	var from_file:bool=recipe.is_empty()
	if from_file:recipe=JSON.parse_string(FileAccess.get_file_as_string(recipe_path))
	var side:String=sidecar_path if sidecar_path!="" else (recipe_path.get_base_dir().path_join("activities.json") if from_file else "")
	if side!="":
		var side_builder=load("res://commons/modular/places/place_builder.gd").new();side_builder.design={"appearance":recipe.get("appearance",{})}
		Boards.merge_sidecar(side_builder,recipe,side)
		if not side_builder.errors.is_empty():push_warning("principal places sidecar: "+str(side_builder.errors))
	super._ready()
	for item in recipe.get("installations",[]):
		var body:=Insert.build(item);add_child(body)
		if palette==Fitted.PALETTE_WHITE:Fitted.whiten(body)   # the pools and plates take the white too
		body.transform=Motion.pose(item,recipe.grid,0,{})
		body.set_meta("grid_part",item.id);body.set_meta("grid_owner",get_instance_id())
		bodies[item.id]=body;parts[item.id]=item;offsets[item.id]=Transform3D.IDENTITY;previous_poses[item.id]=body.transform
		var half_x:float=float(item.size[0])*.5+.22
		var half_z:float=float(item.size[2])*.5+.22
		part_defaults[item.id]={"position":array(body.position),"rotation":array(body.rotation_degrees),"bounds":[-half_x,-.26,-half_z,half_x*2,float(item.get("suspension_height",item.size[1]))+.4,half_z*2]}
	_batch_static()
	# the artifacts chosen for the slots (place.json "activity"): fitted to the pool floor they stand in
	for item in recipe.get("activities",[]):
		var node:Node3D=Activity.build(item)
		if node!=null:add_child(node);Activity.fit(node,item)
	add_to_group("void_floor_extension")
	# No hazard or timed course: this trial is a place to walk, look and return.
	set_physics_process(false)
	# Local work lighting keeps the empty receiving surfaces legible under the slab.
	var lamps:=Node3D.new();lamps.name="PlaceContext";add_child(lamps)
	part_defaults.PlaceContext={"position":[0,0,0],"rotation":[0,0,0],"bounds":[-20,0,-6,40,12,18]}
	for item in recipe.get("work_lights",[]):
		var lamp:=OmniLight3D.new();lamp.position=Motion.v(item.position)
		lamp.light_color=Color("f3eee5");lamp.light_energy=item.energy;lamp.omni_range=item.range;lamp.shadow_enabled=false;lamps.add_child(lamp)
	for item in recipe.get("place_labels",[]):
		var label:=Label3D.new();label.text=item.text
		label.position=Motion.v(item.position);label.font_size=36;label.pixel_size=.005
		label.modulate=Color("e5e5e5");lamps.add_child(label)

func contains_visitor(at:Vector3)->bool:
	if isolated_parts:return false
	var local:=to_local(at)
	return absf(local.x)<float(recipe.grid.columns)*.5 and absf(local.z)<float(recipe.grid.rows)*.5 and local.y>-.5 and local.y<float(recipe.course.height)

func apply_grid_config(config:Dictionary)->void:
	super.apply_grid_config(config)
	var context:=get_node_or_null("PlaceContext")
	if context==null:return
	if config.has("only_parts") and not "PlaceContext" in config.only_parts:
		context.free();part_defaults.erase("PlaceContext");return
	var pose:Dictionary=config.get("parts",{}).get("PlaceContext",{})
	if pose.has("position"):context.position=Motion.v(pose.position)
	if pose.has("rotation"):context.rotation_degrees=Motion.v(pose.rotation)
