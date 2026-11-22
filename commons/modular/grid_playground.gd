extends Node3D
## Shared saved Three.js recipe executed by Godot/Jolt and the Void player rigs.
## Every recipe part remains a named, editable lab-editor part. No mesh-only port.
const Motion=preload("grid_motion.gd")
const Sources=preload("grid_native_sources.gd")
const Finishes=preload("construction_materials.gd")
const GroundProfile=preload("ground_profile.gd")
const WorkshopContract=preload("res://commons/artifacts/scaffold_workstation/contract.gd")
const Fitted=preload("res://commons/artifacts/scaffold_workstation/fitted_geometry.gd")
const Bauhaus=preload("res://commons/artifacts/scaffold_workstation/bauhaus_kit.gd")
const Windmill=preload("windmill.gd")
@export_file("*.json") var recipe_path="res://commons/void/trials/revolving_playground/recipe.json"
@export var embedded_study:=false
@export var field_size:=Vector2(6,4)
@export var study_bounds:=Vector2(14,8)
@export var study_height:=5.8
@export var study_bottom:=-.5
@export var running:=true
@export_range(.1,3.0) var speed:=1.0
var recipe:Dictionary={}
var parts:Dictionary={}
var bodies:Dictionary={}
var offsets:Dictionary={}
var part_defaults:Dictionary={}
var elapsed:=0.0
var stage:=0
var resets:=0
var cooldown:=2.0
var preview:=false
var visual_only_preview:=false # Grid editor study: source owns all physics.
var isolated_parts:=false
var source_factory:Node3D
var batches:Array=[]
var batched_meshes:Array=[]
var previous_poses:Dictionary={}
var push_contacts:=0
var ground_regions:Array[Rect2]=[]
var ground_mesh:MeshInstance3D
var ground_refresh_queued:=false
var palette:="" # "white": slim fitted parts, white with dark edges (config "palette", or the recipe's appearance)
var windmills:Dictionary={} # the windmill sidecar applied (config "windmills"), {} when none

func _ready()->void:
	process_physics_priority=-150 # Before XRTools (-100) and desktop (0).
	if recipe.is_empty():recipe=JSON.parse_string(FileAccess.get_file_as_string(recipe_path))
	var errors:=WorkshopContract.validate(recipe)
	if not errors.is_empty():
		push_error("Invalid workshop playground: "+str(errors));set_physics_process(false);return
	_apply_style()
	source_factory=Sources.new();source_factory.phase=Finishes.phase_for(self,str(recipe.get("appearance",{}).get("phase","monochrome")));add_child(source_factory)
	for p in recipe.parts: parts[p.id]=p
	for p in recipe.parts:
		var moving:bool=p.motion.enabled or p.has("parent")
		var body:Node3D=Node3D.new() if visual_only_preview else (AnimatableBody3D.new() if moving else StaticBody3D.new())
		body.name=p.id;body.set_meta("grid_part",p.id);body.set_meta("electrical",p.get("electrical",false));body.set_meta("grid_owner",get_instance_id());body.set_meta("padded_pusher",(p.source=="paddle" or p.get("pusher",false)) and not p.get("electrical",false))
		body.set_meta("assembly_root",p.get("assembly_root",p.id))
		if moving and body is AnimatableBody3D: body.sync_to_physics=false
		add_child(body)
		if p.source==Windmill.PADDLE:Windmill.populate(body,p,source_factory.phase)
		else:source_factory.populate(body,p)
		if p.get("workshop_palette","")==Fitted.PALETTE_WHITE:Fitted.whiten(body)
		elif p.get("workshop_palette","")==Bauhaus.PALETTE_BAUHAUS:Bauhaus.dress_playground_body(body,p,str(p.get("workshop_color_scheme",source_factory.phase)))
		if visual_only_preview:
			for child in body.get_children():
				if child is CollisionShape3D:child.free()
		body.transform=Motion.pose(p,recipe.grid,0,parts)
		bodies[p.id]=body;offsets[p.id]=Transform3D.IDENTITY;previous_poses[p.id]=body.transform
		var size:=Motion.v(p.size)
		part_defaults[p.id]={"position":array(body.position),"rotation":array(body.rotation_degrees),"bounds":[-size.x/2,0,-size.z/2,size.x,size.y,size.z]}
	_make_field()
	set_notify_transform(true)
	_refresh_ground.call_deferred()
	_batch_static()
	set_meta("void_preview_kind","Native Jolt recipe; editor geometry at clock zero. Moving parts remain editable.")

func array(v:Vector3)->Array: return [v.x,v.y,v.z]

## OPT-IN LOOKS AND PREFABS (2026-11-09), applied to an in-memory copy after the recipe validated, so the recipe JSON
## stays as authored and a playground without these keys builds exactly as before:
##   palette "white"  every part in the white-with-edges finish; workshop parts take the slim fitted profile
##   windmills        true (the sidecar <recipe>-windmills.json), a sidecar path, or the spec: windmill.gd
func _apply_style()->void:
	palette=str(get_meta("config_palette",recipe.get("appearance",{}).get("palette","")))
	var mills:Variant=get_meta("config_windmills") if has_meta("config_windmills") else null
	var wanted:bool=mills!=null and not (mills is bool and not mills)
	var any_white:=palette==Fitted.PALETTE_WHITE
	var any_bauhaus:=palette==Bauhaus.PALETTE_BAUHAUS
	for p in recipe.parts:
		any_white=any_white or p.get("workshop_palette","")==Fitted.PALETTE_WHITE
		any_bauhaus=any_bauhaus or p.get("workshop_palette","")==Bauhaus.PALETTE_BAUHAUS
	if not any_white and not any_bauhaus and not wanted:return
	recipe=recipe.duplicate(true)
	if wanted:windmills=Windmill.install(recipe,mills,recipe_path)
	var color_scheme:String=str(get_meta("config_color_scheme",recipe.get("appearance",{}).get("color_scheme","")))
	for p in recipe.parts:
		if palette==Fitted.PALETTE_WHITE:p.workshop_palette=Fitted.PALETTE_WHITE
		elif palette==Bauhaus.PALETTE_BAUHAUS:
			p.workshop_palette=Bauhaus.PALETTE_BAUHAUS
			if color_scheme!="":p.workshop_color_scheme=color_scheme
		if p.get("workshop_palette","")==Fitted.PALETTE_WHITE and str(p.source).begins_with("workshop_"):p.workshop_profile="fitted"

func _make_field()->void:
	var field:=Node3D.new();field.name="ElectricalField";add_child(field)
	ground_mesh=MeshInstance3D.new();ground_mesh.name="ClippedGround";field.add_child(ground_mesh)
	_refresh_ground()
	var labelled:Dictionary={}
	for i in recipe.course.stages.size():
		var s:Dictionary=recipe.course.stages[i]
		var key:=str(s.target)
		if labelled.has(key):continue
		labelled[key]=true
		var label:=Label3D.new();label.name="Stage%d"%i;label.text=str(s.title).replace(" / ","\n")
		label.position=Motion.point(s.target,recipe.grid)+Vector3(0,1.2,0)
		label.font_size=30;label.pixel_size=.003;label.modulate=Color("ededed") if source_factory.phase=="monochrome" else Color("f3eadd")
		label.visibility_range_begin=0;label.visibility_range_end=6
		label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;add_child(label)

func _notification(what:int)->void:
	if what==NOTIFICATION_TRANSFORM_CHANGED and ground_mesh!=null and not ground_refresh_queued:
		ground_refresh_queued=true;_refresh_ground.call_deferred()

func tower_building()->Node3D:
	var node:=get_parent()
	while node!=null:
		if "spec" in node and "floors" in node:return node as Node3D
		node=node.get_parent()
	return null

func _refresh_ground()->void:
	ground_refresh_queued=false
	if ground_mesh==null or isolated_parts:return
	var profile:Dictionary=recipe.get("electricalGround",{})
	var holes:Array[Rect2]=[]
	var building:=tower_building()
	if profile.get("excludeTowerShafts",false) and building!=null:
		for shaft in building.spec.shafts:
			var corners:Array[Vector2]=[]
			for x in [-.5,.5]:
				for z in [-.5,.5]:
					var p:=to_local(building.to_global(Vector3(float(shaft.x)+x*float(building.spec.shaft_width),building.to_local(global_position).y,z*float(building.spec.shaft_depth))))
					corners.append(Vector2(p.x,p.z))
			var rect:=Rect2(corners[0],Vector2.ZERO)
			for p in corners:rect=rect.expand(p)
			holes.append(rect.grow(.05))
	else:
		for a in profile.get("holes",[]):holes.append(Rect2(a[0],a[1],a[2],a[3]).grow(.05))
	# A taped assembly station is a safe working area, even at ground level.
	# Derive the cut from its actual editable Support pose, for mesh and physics.
	for zone in get_tree().get_nodes_in_group("workshop_safe_zones"):
		# Whole floors may be hidden during streaming; only an omitted Support
		# group removes its safe footprint. This keeps reloads deterministic.
		if not zone is Node3D or not zone.get_parent().visible or absf(zone.global_position.y-global_position.y)>.1:continue
		var area:Rect2=zone.get_meta("workshop_safe_rect")
		var cut:=Rect2();var first:=true
		for corner in [area.position,Vector2(area.end.x,area.position.y),area.end,Vector2(area.position.x,area.end.y)]:
			var p:Vector3=to_local(zone.to_global(Vector3(corner.x,0,corner.y)))
			cut=Rect2(Vector2(p.x,p.z),Vector2.ZERO) if first else cut.expand(Vector2(p.x,p.z));first=false
		holes.append(cut)
	var width:float=field_size.x if embedded_study else recipe.grid.columns*recipe.grid.cell
	var depth:float=field_size.y if embedded_study else recipe.grid.rows*recipe.grid.cell
	ground_regions.clear()
	if recipe.grid.electrical:ground_regions=GroundProfile.regions(profile,width,depth,holes)
	ground_mesh.visible=not ground_regions.is_empty()
	if ground_regions.is_empty():return
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var unit:=BoxMesh.new();unit.size=Vector3.ONE
	for rect in ground_regions:
		for x in range(int(ceil(rect.position.x+width/2)),int(floor(rect.end.x+width/2))+1):
			surface.append_from(unit,0,Transform3D(Basis.from_scale(Vector3(.025,.018,rect.size.y)),Vector3(x-width/2,.035,rect.get_center().y)))
		for z in range(int(ceil(rect.position.y+depth/2)),int(floor(rect.end.y+depth/2))+1):
			surface.append_from(unit,0,Transform3D(Basis.from_scale(Vector3(rect.size.x,.018,.025)),Vector3(rect.get_center().x,.035,z-depth/2)))
	ground_mesh.mesh=surface.commit();ground_mesh.material_override=Finishes.surface("danger",source_factory.phase)

func on_electrical_ground(local:Vector3)->bool:
	return local.y>=-.5 and local.y<.3 and GroundProfile.contains(ground_regions,Vector2(local.x,local.z))

func _batch_static()->void:
	for batch in batches:batch.free()
	batches.clear();batched_meshes.clear()
	var groups:Dictionary={}
	for body in bodies.values():
		if body is AnimatableBody3D:continue
		for mesh in body.get_children():
			if not mesh is MeshInstance3D:continue
			var key:=str(mesh.mesh.get_instance_id())+"/"+str(mesh.material_override.get_instance_id() if mesh.material_override!=null else 0)
			if not groups.has(key):groups[key]=[]
			groups[key].append(mesh)
	for group in groups.values():
		var batch:=MultiMeshInstance3D.new();var mm:=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D
		mm.mesh=group[0].mesh;mm.instance_count=group.size();batch.multimesh=mm;batch.material_override=group[0].material_override
		for i in group.size():
			var mesh:MeshInstance3D=group[i]
			mm.set_instance_transform(i,mesh.get_parent().transform*mesh.transform);mesh.hide();batched_meshes.append(mesh)
		add_child(batch);batches.append(batch)

func apply_grid_config(config:Dictionary)->void:
	if config.has("only_parts"):
		# A copied member is a fixed piece, not a second running circuit with
		# invisible neighbouring colliders and an electrical floor of its own.
		isolated_parts=true;running=false;set_physics_process(false)
		for mesh in batched_meshes:
			if is_instance_valid(mesh):mesh.show()
		for id in bodies.keys():
			if id in config.only_parts:continue
			bodies[id].free();bodies.erase(id);part_defaults.erase(id)
			offsets.erase(id);previous_poses.erase(id)
		ground_mesh=null;ground_regions.clear()
		for child in get_children():
			if child.name=="ElectricalField" or child is Label3D:child.free()
	if config.has("speed"): speed=clampf(float(config.speed),.1,3)
	for id in config.get("parts",{}):
		if not bodies.has(id):continue
		var p:Dictionary=config.parts[id]
		var body:Node3D=bodies[id]
		body.position=Motion.v(p.get("position",part_defaults[id].position))
		body.rotation_degrees=Motion.v(p.get("rotation",part_defaults[id].rotation))
		offsets[id]=body.transform*Motion.pose(parts[id],recipe.grid,0,parts).affine_inverse()
	if not preview:_batch_static()

func prepare_editor_preview()->void:
	preview=true;running=false;elapsed=0
	for batch in batches:batch.hide()
	for mesh in batched_meshes:mesh.show()
	apply_time(0)

func apply_time(seconds:float)->void:
	if isolated_parts:return
	for id in bodies:
		var p:Dictionary=parts[id]
		if p.motion.enabled or p.has("parent"):
			previous_poses[id]=bodies[id].transform
			bodies[id].transform=offsets[id]*Motion.pose(p,recipe.grid,seconds,parts)

func _physics_process(delta:float)->void:
	if preview or isolated_parts:return
	if running: elapsed+=delta*speed;apply_time(elapsed)
	cooldown=maxf(0,cooldown-delta)
	var game:=get_tree().get_first_node_in_group("void_game")
	if game==null or not game.ready_for_play:return
	var player:CharacterBody3D=game.body
	var local:=to_local(player.global_position)
	# Embedded bays affect only their own field, never the rest of the tower.
	if embedded_study and (local.y < study_bottom or local.y > study_height or absf(local.x)>study_bounds.x/2 or absf(local.z)>study_bounds.y/2):return
	push_player(player,delta)
	var touched:=""
	for i in player.get_slide_collision_count():
		var collider:Node=player.get_slide_collision(i).get_collider()
		if collider!=null and collider.get_meta("grid_owner",0)==get_instance_id() and collider.get_meta("electrical",false):touched="Electrical fin"
	if on_electrical_ground(local) and touching_exposed_ground(player):touched="Electrical floor"
	if not embedded_study and (local.y < -1 or absf(local.x)>float(recipe.grid.columns)/2+1 or absf(local.z)>float(recipe.grid.rows)/2+1):touched="Outside the scaffold"
	if cooldown<=0 and not touched.is_empty(): recover(game,touched);return
	if stage<recipe.course.stages.size() and player.is_on_floor():
		var s:Dictionary=recipe.course.stages[stage]
		for i in player.get_slide_collision_count():
			var collider:Node=player.get_slide_collision(i).get_collider()
			if collider!=null and collider.get_meta("grid_owner",0)==get_instance_id() and collider.get_meta("grid_part","") in s.landing:
				stage+=1
				game._notice("CROSSING COMPLETE / try another timing" if stage==recipe.course.stages.size() else recipe.course.stages[stage].title+"\n"+recipe.course.stages[stage].hint)
				break

func recover(game:Node,reason:String)->void:
	if get_meta("probe_reset",false):print("WORKSHOP_RECOVERY ",reason," ",to_local(game.body.global_position)," ",game.body.get_slide_collision_count()," ",standing_on_workshop(game.body))
	resets+=1;cooldown=1.5
	var s:Dictionary=recipe.course.stages[mini(stage,recipe.course.stages.size()-1)]
	var at:=Motion.point(s.spawn,recipe.grid)
	# Browser capsule is centre-origin; Void player rigs use feet-origin.
	at.y-=.65
	game.place_player(to_global(at))
	game._notice(reason+" / back to the last landing\n"+str(s.hint))

func standing_on_workshop(player:CharacterBody3D)->bool:
	# A low workshop lift insulates its rider from the concrete below. Only
	# actual upward contact counts; standing beside it still meets the hazard.
	for i in player.get_slide_collision_count():
		var hit:=player.get_slide_collision(i)
		var collider:Node=hit.get_collider()
		if hit.get_normal().y>.7 and collider!=null and collider.has_meta("workshop_record") and not collider.get_meta("electrical",false):return true
	return false

func touching_exposed_ground(player:CharacterBody3D)->bool:
	# Contact lists can be from before a teleport or platform update. Sample
	# under the actual feet, so the low quad and the air above it stay safe.
	if not player.is_on_floor():return false
	var ray:=PhysicsRayQueryParameters3D.create(player.global_position+Vector3.UP*.06,player.global_position-Vector3.UP*.10,1)
	ray.exclude=[player.get_rid()]
	var hit:=player.get_world_3d().direct_space_state.intersect_ray(ray)
	return not hit.is_empty() and hit.normal.y>.7 and not hit.collider.has_meta("workshop_record")

func push_player(player:CharacterBody3D,delta:float)->void:
	# Character bodies resolve thin moving triangles along their shortest normal.
	# Transfer the contacted padded surface's tangential velocity as well, so a
	# turning fin pushes sideways rather than merely ejecting the capsule a few cm.
	var capsule:=CapsuleShape3D.new();capsule.radius=.26;capsule.height=1.82
	var q:=PhysicsShapeQueryParameters3D.new();q.shape=capsule;q.collision_mask=1
	q.transform=Transform3D(Basis.IDENTITY,player.global_position+Vector3.UP*.85)
	q.exclude=[player.get_rid()]
	for hit in get_world_3d().direct_space_state.intersect_shape(q,16):
		var body:Node=hit.collider
		if body.get_meta("grid_owner",0)!=get_instance_id() or not body.get_meta("padded_pusher",false):continue
		var id:String=body.get_meta("grid_part")
		var old:Transform3D=global_transform*previous_poses[id]
		var now:Transform3D=body.global_transform
		var point:=player.global_position+Vector3.UP*.85
		var surface:Vector3=(now*(old.affine_inverse()*point)-point)/maxf(delta,.001)
		surface.y=0;surface=surface.limit_length(4)
		if surface.length()<.02:continue
		var direction:=surface.normalized()
		player.velocity+=direction*maxf(0,surface.length()-player.velocity.dot(direction))
		push_contacts+=1
