# Export the built Void artifacts in their own coordinate frames for web layout editing.
# Scripts, physics and XR remain in Godot. Meshes come from the real running scenes.
extends SceneTree
const ModelStorage = preload("res://tools/generated_storage.gd")

const Atmosphere = preload("res://commons/void/atmosphere.gd")
var public_base := "/void-models"
var out := ModelStorage.export_directory("void-editor")
var manifest: Dictionary = {"version":1,"floors":{},"props":{},"notes":[]}
var shader_count := 0
var failures: Array[String] = []
var selected_floors: Array[int] = []
var skip_palette := false
var export_workbench := false

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--public-base="): public_base=arg.trim_prefix("--public-base=")
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
		if arg.begins_with("--floors="):
			for value in arg.trim_prefix("--floors=").split(","): selected_floors.append(int(value))
		if arg=="--skip-palette": skip_palette=true
		if arg=="--workbench": export_workbench=true
	out=ModelStorage.output_directory(out)
	run.call_deferred()

func run() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	# The floor's real pickup scripts depend on XR autoloads. Load after startup.
	# Original instruments may inspect current_scene during _ready. Give the
	# export the same valid scene context as gameplay before building children.
	var export_scene := Node3D.new()
	export_scene.name = "VoidExportScene"
	root.add_child(export_scene)
	current_scene = export_scene
	var building: Node3D = load("res://commons/void/architecture.gd").new()
	building.stream_content=not selected_floors.is_empty()
	export_scene.add_child(building)
	for index in selected_floors: building.content.load_floor(index)
	# Give mounted instruments a physics contact and their private screens a frame.
	# Snap puzzles construct their three/four lines across successive frames;
	# live twins also discover their source through a quarter-second timer.
	for i in range(30): await physics_frame
	# Colour balls spawn one body per process frame. Physics frames alone can
	# finish before their MultiMesh is populated, especially in larger trials.
	for exhibit in building.content.exhibits.values():
		var balls: Node3D = exhibit.get_node("Artifact")
		if str(balls.get_meta("artifact_lookup_name", "")) != "colorballs": continue
		for attempt in range(balls.ball_count + 2):
			if balls.ball_bodies.size() == balls.ball_count and (not balls.use_multimesh_renderer or balls.multimesh.instance_count == balls.ball_count): break
			await process_frame
		if balls.ball_bodies.size() != balls.ball_count or (balls.use_multimesh_renderer and balls.multimesh.instance_count != balls.ball_count):
			failures.append("%s: colour-ball construction did not finish" % exhibit.name)
	# Cage generates sound on a worker thread and removes a large loading bar
	# on completion. Export the finished instrument, not that temporary bar.
	for exhibit in building.content.exhibits.values():
		var instrument: Node3D = exhibit.get_node("Artifact")
		if str(instrument.get_meta("artifact_lookup_name", "")) != "john_cage_tech_noir": continue
		var started: int = Time.get_ticks_msec()
		while not instrument.generation_complete and Time.get_ticks_msec() - started < 90000:
			await create_timer(0.1).timeout
		if not instrument.generation_complete:
			failures.append("%s: sound generation did not finish" % exhibit.name)
		await process_frame
		await process_frame
	# The native weaver reveals its net over time. Export the complete authored
	# structure for placement, using its own completion path only in this preview.
	if building.content.trial_id == "noise_02":
		for exhibit in building.content.exhibits.values():
			var web: Node3D = exhibit.get_node("Artifact")
			if str(web.get_meta("artifact_lookup_name", "")) != "voronoi_strands": continue
			for attempt in range(120):
				if int(web.generation_count) > 0: break
				await physics_frame
			if int(web.generation_count) == 0:
				failures.append("%s: voronoi network was not built" % exhibit.name)
			elif is_instance_valid(web.weaver) and not web.weaver.finished:
				web.weaver.finish()
		manifest.notes.append("Voronoi strand preview shows the completed weave; native gameplay reveals it over time.")
	# The rhizome demo yields while marching its source density history. A fixed
	# frame delay can capture no mesh, especially beside a synchronous large work.
	# Wait for its own completion product; never substitute a fabricated cave.
	for exhibit in building.content.exhibits.values():
		var cave: Node3D = exhibit.get_node("Artifact")
		if str(cave.get_meta("artifact_lookup_name", "")) not in ["rhizome_cave_demo", "rhizome_cave_system"]: continue
		if cave.get("passage_study") == true: continue
		# The source's capture flag removes frame yields only. Its timer is reset
		# before each yield, so slow all-floor renders otherwise march one voxel
		# per frame. Finish this SAME growth history, without regenerating it.
		var source_generator: Node = cave.get("cave_generator")
		if is_instance_valid(source_generator): source_generator.set("synchronous", true)
		var started := Time.get_ticks_msec()
		var finished: MeshInstance3D
		while Time.get_ticks_msec()-started < 60000:
			# Runtime child names may be uniquified by Godot. Follow the source
			# controller's actual generator reference rather than an assumed path.
			var generator: Node = cave.get("cave_generator")
			if is_instance_valid(generator):
				for child in generator.get_children():
					if child is MeshInstance3D and child.mesh != null and child.mesh.get_surface_count() > 0:
						finished = child
						break
			if finished != null: break
			await process_frame
		if finished == null or finished.mesh == null or finished.mesh.get_surface_count() == 0:
			failures.append("%s: original asynchronous cave has no completed surface" % exhibit.name)
		else:
			manifest.notes.append(str(exhibit.name)+": waited for the original asynchronous CaveMesh before snapshot")
	await RenderingServer.frame_post_draw
	# Snapshot solver-owned vertices while physics is still live. Disabling the
	# building removes Jolt soft bodies from their spaces before GLB collection.
	cache_soft_body_meshes(building)
	building.process_mode=Node.PROCESS_MODE_DISABLED
	await process_frame
	await export_environment()
	for index in range(building.content.data.floors.size()):
		if not selected_floors.is_empty() and index not in selected_floors: continue
		var record: Dictionary = building.content.data.floors[index]
		var floor_data: Dictionary = {"map":record.map,"artifacts":{},"structure":snapshot(building.floors[index],"floor-%d"%index)}
		floor_data["prop_lights"]={}
		floor_data["interface_models"]={}
		for prop in record.get("props",[]):
			var built: Node3D=building.content.props["%d/%s"%[index,prop.id]]
			var lamps: Array=[]
			collect_lights(built,built.global_transform.affine_inverse(),lamps)
			floor_data.prop_lights[prop.kind]=lamps
			if str(prop.kind).begins_with("interface_"):
				floor_data.interface_models[str(prop.kind)+"|"+str(prop.get("target",""))]=snapshot(built,"%d-interface-%s"%[index,prop.id])
		for item in record.artifacts:
			var artifact: Node3D=building.content.exhibits["%d/%s"%[index,item.id]].get_node("Artifact")
			if artifact.has_method("prepare_editor_preview"): await artifact.prepare_editor_preview()
			var data: Dictionary={"artifact":item.artifact,"config":item.get("config",{}).duplicate(true),"parts":{}}
			if artifact.has_meta("void_preview_kind"):
				data["preview_kind"] = artifact.get_meta("void_preview_kind")
				manifest.notes.append(str(item.id) + ": " + str(data.preview_kind) + "; native simulation state is unchanged.")
			if artifact.get("part_defaults") is Dictionary:
				for child in artifact.get_children():
					# Deferred runtime helpers (tool reactions, debris, etc.) are
					# not authored parts and have no editable placement defaults.
					if child is Node3D and artifact.part_defaults.has(str(child.name)):
						var part: Dictionary=snapshot(child,"%d-%s-%s"%[index,item.id,child.name])
						part["default"]=artifact.part_defaults[str(child.name)]
						part["scale"]=[child.scale.x,child.scale.y,child.scale.z]
						data.parts[str(child.name)]=part
			else:
				var extra: Node3D = artifact.garden if item.artifact == "force_mower" and "garden" in artifact else null
				data["model"]=snapshot(artifact,"%d-%s"%[index,item.id],float(item.get("config",{}).get("museum_yaw",0)),extra)
			floor_data.artifacts[str(item.id)]=data
		manifest.floors[str(index)]=floor_data
	# Palette models use the exact Void prefabs, including the real-size container.
	var host:=Node3D.new()
	building.add_child(host)
	for kind in ([] if skip_palette else building.content.catalog.props.keys()):
		var node: Node3D=building.content.SetDressing.build(building,host,{"id":kind,"kind":kind,"position":[0,0],"facing":0,"scale":1},building.content.catalog.props[kind])
		# Some existing prefabs apply their materials in a deferred ready call.
		await process_frame
		manifest.props[kind]=snapshot(node,"prop-"+str(kind))
		manifest.props[kind]["thumbnail"]=await thumbnail(node,"prop-"+str(kind))
		node.queue_free()
	if export_workbench:
		manifest["workbench"]={}
		var definitions:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://commons/void/primitive-prefabs.json"))
		for prefab in definitions.prefabs:
			if not prefab.has("construction"): continue
			var built:Node3D=load("res://commons/void/construction_grid.gd").new()
			built.items=prefab.construction.items
			host.add_child(built)
			await built.prepare_editor_preview()
			manifest.workbench[prefab.id]=snapshot(built,"workbench-"+str(prefab.id))
			built.free()
	manifest["shader_material_previews"]=shader_count
	manifest.notes.append_array(["Geometry and lamps exported from built Godot scenes; behaviours run only in Godot.","Text is reproduced from Label3D data with a browser font. Shader materials use a static colour preview.","Evening sky is a linear HDR bake at 180 seconds. Browser falloff, fog and tone mapping approximate Godot."])
	manifest["failures"]=failures
	FileAccess.open(out.path_join("manifest.json"),FileAccess.WRITE).store_string(JSON.stringify(manifest,"\t"))
	building.queue_free()
	await process_frame
	print("VOID_EXPORT ",JSON.stringify({"failures":failures,"shader_material_previews":shader_count}))
	quit(0 if failures.is_empty() else 1)

func thumbnail(source: Node3D, key: String) -> String:
	var viewport := SubViewport.new()
	viewport.size=Vector2i(320,220)
	viewport.own_world_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var stage := Node3D.new()
	viewport.add_child(stage)
	var original_parent := source.get_parent()
	source.reparent(stage,false)
	var bounds := AABB()
	var first := true
	for node in source.find_children("*","GeometryInstance3D",true,false):
		var local: AABB
		if node is MeshInstance3D and node.mesh!=null: local=node.mesh.get_aabb()
		elif node is MultiMeshInstance3D and node.multimesh!=null: local=node.multimesh.get_aabb()
		else: continue
		local=node.global_transform*local
		bounds=local if first else bounds.merge(local)
		first=false
	var environment := Environment.new()
	environment.background_mode=Environment.BG_COLOR
	environment.background_color=Color("e9e6e0")
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color=Color.WHITE
	environment.ambient_light_energy=.75
	var world := WorldEnvironment.new()
	world.environment=environment
	stage.add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-45,-35,0)
	light.light_energy=1.25
	stage.add_child(light)
	var camera := Camera3D.new()
	stage.add_child(camera)
	var centre := bounds.get_center()
	var extent := maxf(bounds.size.length(),.4)
	camera.position=centre+Vector3(1.15,.65,1.8).normalized()*extent*2.0
	camera.look_at(centre)
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=extent*1.12
	camera.far=extent*4+10
	camera.current=true
	await process_frame
	await RenderingServer.frame_post_draw
	var filename := key+".png"
	var err := viewport.get_texture().get_image().save_png(out.path_join(filename))
	if err!=OK: failures.append("%s thumbnail: %d"%[key,err])
	source.reparent(original_parent,false)
	viewport.queue_free()
	return public_base+"/"+filename

func snapshot(source: Node3D, key: String, intrinsic_yaw := 0.0, extra: Node3D = null) -> Dictionary:
	var copy:=Node3D.new()
	copy.name="Model"
	var labels: Array=[]
	var frame := Transform3D(Basis(Vector3.UP,deg_to_rad(intrinsic_yaw)),Vector3.ZERO)*source.global_transform.affine_inverse()
	# A mounted instrument can lift within its editable placement to clear the
	# floor. Preserve that native offset, including the ceiling anchor height.
	if source.has_meta("ceiling_interface_style"):
		frame = Transform3D(Basis.IDENTITY, source.position / source.scale) * frame
	collect(source,frame,copy,labels)
	# Some source instruments create a fixed sibling rather than a child. It is
	# still part of the same editable placement (the mower and its original lawn).
	if is_instance_valid(extra): collect(extra,frame,copy,labels)
	var lamps: Array=[]
	collect_lights(source,frame,lamps)
	var data: Dictionary={"labels":labels,"lights":lamps,"meshes":copy.get_child_count()}
	if copy.get_child_count()>0:
		var doc:=GLTFDocument.new()
		var state:=GLTFState.new()
		var err:=doc.append_from_scene(copy,state)
		if err==OK: err=ModelStorage.write_gltf(doc,state,out.path_join(key+".glb"))
		if err!=OK: failures.append("%s: %d"%[key,err])
		else: data["url"]=public_base+"/"+key+".glb"
	# Detach geometry before releasing its materials: the Compatibility renderer
	# can otherwise query stale material RIDs while GLTF's temporary nodes free.
	for child in copy.get_children():
		if child is MeshInstance3D: child.mesh=null
	copy.free()
	return data

# Lights are exported independently of visible geometry: pickup lights are off
# at rest, but the editor must be able to preview the selected object's lamp.
func collect_lights(node: Node, inverse: Transform3D, lamps: Array) -> void:
	if node is SubViewport: return
	if node is OmniLight3D or node is SpotLight3D:
		var spot := node is SpotLight3D
		lamps.append({"name":str(node.name),"matrix":matrix(inverse*node.global_transform),
			"type":"spot" if spot else "point","color":node.light_color.to_html(false),
			"energy":node.light_energy,"range":node.spot_range if spot else node.omni_range,
			"attenuation":node.spot_attenuation if spot else node.omni_attenuation,
			"angle":node.spot_angle if spot else 0.0,
			"feather":float(node.get_meta("editor_beam_feather", 0.35)),
			"shadow":node.shadow_enabled,"visible":node.is_visible_in_tree()})
	for child in node.get_children(): collect_lights(child,inverse,lamps)

func export_environment() -> void:
	var sky: Node3D=Atmosphere.new()
	sky.animate_sky=false
	root.add_child(sky)
	sky.set_sky_time(180.0)
	# Match the streaming game's depth fog; leave the running game untouched.
	sky.environment.fog_depth_end=30.0
	sky.environment.fog_depth_curve=1.5
	# A controlled comparison can carry its lighting into the editor preview.
	var source := preload("res://commons/void/room_source.gd")
	var lighting_adapter: String=source.definition(source.selected()).get("lighting_adapter","")
	if not lighting_adapter.is_empty(): load(lighting_adapter).apply(sky)
	var camera:=Camera3D.new()
	root.add_child(camera)
	camera.position=Vector3(0,10,0)
	camera.current=true
	for i in range(12): await process_frame
	await RenderingServer.frame_post_draw
	var panorama: Image=RenderingServer.sky_bake_panorama(sky.environment.sky.get_rid(),1.0,false,Vector2i(512,256))
	if panorama==null or panorama.is_empty(): failures.append("Sky panorama unavailable")
	elif panorama.save_exr(out.path_join("evening-sky.exr"))!=OK: failures.append("Sky panorama could not be saved")
	var sun: DirectionalLight3D=sky.get_node("WarmSun")
	manifest["lighting"]={"sky_url":public_base+"/evening-sky.exr","sky_seconds":sky.get_meta("study_sky_seconds",180),
		"ambient_color":sky.environment.ambient_light_color.to_html(false),"ambient_energy":sky.environment.ambient_light_energy,
		"sun_color":sun.light_color.to_html(false),"sun_energy":sun.light_energy,"sun_matrix":matrix(sun.global_transform),
		"fog_color":sky.environment.fog_light_color.to_html(false),"fog_energy":sky.environment.fog_light_energy,
		"fog_begin":sky.environment.fog_depth_begin,"fog_end":sky.environment.fog_depth_end,"fog_curve":sky.environment.fog_depth_curve}
	camera.queue_free()
	sky.queue_free()
	await process_frame

func collect(node: Node, inverse: Transform3D, target: Node3D, labels: Array) -> void:
	if node is SubViewport: return # Film on the screen, not a second stage in the room.
	if node is Node3D and not node.is_visible_in_tree(): return
	if node is SoftBody3D and node.mesh!=null:
		soft_body_copy(node,inverse,target)
	elif node is MeshInstance3D and node.mesh!=null:
		mesh_copy(node.mesh,inverse*node.global_transform,node,target)
	elif node is MultiMeshInstance3D and node.multimesh!=null:
		var count: int = node.multimesh.instance_count if node.multimesh.visible_instance_count<0 else node.multimesh.visible_instance_count
		if count>256 and source_is_lawn(node):
			batch_multimesh(node,inverse,target,count)
			return
		for i in range(count):
			var tint: Color = node.multimesh.get_instance_color(i) if node.multimesh.use_colors else Color.WHITE
			mesh_copy(node.multimesh.mesh,inverse*node.global_transform*node.multimesh.get_instance_transform(i),node,target,tint)
	elif node is CSGShape3D and node.is_root_shape():
		var meshes: Array=node.get_meshes()
		if meshes.size()==2: mesh_copy(meshes[1],inverse*node.global_transform*meshes[0],node,target)
	elif node is Label3D and not node.text.is_empty():
		var t: Transform3D=inverse*node.global_transform
		labels.append({"text":node.text,"matrix":matrix(t),"font_size":node.font_size,"pixel_size":node.pixel_size,"color":node.modulate.to_html(),"billboard":node.billboard!=0})
	for child in node.get_children(): collect(child,inverse,target,labels)

func soft_body_copy(source: SoftBody3D, inverse: Transform3D, target: Node3D) -> void:
	var baked: Mesh = source.get_meta("void_export_soft_mesh",null)
	if baked == null:
		failures.append(str(source.get_path())+": no live soft-body snapshot")
		return
	mesh_copy(baked,inverse,source,target)

func cache_soft_body_meshes(node: Node) -> void:
	if node is SubViewport: return
	if node is SoftBody3D and node.mesh != null:
		node.set_meta("void_export_soft_mesh",bake_soft_body(node))
	for child in node.get_children(): cache_soft_body_meshes(child)

func bake_soft_body(source: SoftBody3D) -> Mesh:
	var rid := source.get_physics_rid()
	if not source.can_process() or not rid.is_valid() or not PhysicsServer3D.soft_body_get_space(rid).is_valid():
		failures.append(str(source.get_path())+": soft-body preview has no live physics space")
		return null
	var baked := ArrayMesh.new()
	var offset := 0
	for surface in source.mesh.get_surface_count():
		var arrays := source.mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		var used: Dictionary = {}
		for index in indices: used[index] = true
		var fallback := PhysicsServer3D.soft_body_get_point_global_position(rid,offset+(indices[0] if not indices.is_empty() else 0))
		for i in vertices.size():
			# Jolt omits unreferenced mesh vertices; querying them is an error.
			vertices[i] = PhysicsServer3D.soft_body_get_point_global_position(rid,offset+i) if indices.is_empty() or used.has(i) else fallback
		arrays[Mesh.ARRAY_VERTEX] = vertices
		offset += vertices.size()
		baked.add_surface_from_arrays(source.mesh.surface_get_primitive_type(surface),arrays)
		baked.surface_set_material(surface,source.get_active_material(surface))
	# Recompute lighting normals after baking the actual deformed world vertices.
	var finished := ArrayMesh.new()
	for surface in baked.get_surface_count():
		var tool := SurfaceTool.new()
		tool.create_from(baked,surface)
		tool.generate_normals()
		tool.commit(finished)
		finished.surface_set_material(surface,baked.surface_get_material(surface))
	return finished

func source_is_lawn(node: Node) -> bool:
	return node.get_parent()!=null and node.get_parent().name=="FlowerLawn"

func batch_multimesh(source: MultiMeshInstance3D, inverse: Transform3D, target: Node3D, count: int) -> void:
	# Preserve every visible blade/cell, but give Three.js one static mesh per
	# material instead of thousands of individual scene nodes and draw calls.
	var mm:=source.multimesh
	var combined:=ArrayMesh.new()
	for surface in mm.mesh.get_surface_count():
		if mm.mesh is ArrayMesh and mm.mesh.surface_get_primitive_type(surface)!=Mesh.PRIMITIVE_TRIANGLES:continue
		var base:=mm.mesh.surface_get_arrays(surface)
		var vertices:=PackedVector3Array();var normals:=PackedVector3Array()
		var uv:=PackedVector2Array();var colors:=PackedColorArray();var indices:=PackedInt32Array()
		for i in count:
			var at:Transform3D=inverse*source.global_transform*mm.get_instance_transform(i)
			if absf(at.basis.determinant())<0.00000001:continue
			var start:=vertices.size()
			vertices.append_array(at*(base[Mesh.ARRAY_VERTEX] as PackedVector3Array))
			if base[Mesh.ARRAY_NORMAL]!=null:
				var basis:=at.basis.inverse().transposed()
				for normal in base[Mesh.ARRAY_NORMAL]:normals.append((basis*normal).normalized())
			if base[Mesh.ARRAY_TEX_UV]!=null:uv.append_array(base[Mesh.ARRAY_TEX_UV])
			var tint:Color=mm.get_instance_color(i) if mm.use_colors else Color.WHITE
			for j in (base[Mesh.ARRAY_VERTEX] as PackedVector3Array).size():
				colors.append(tint*base[Mesh.ARRAY_COLOR][j] if base[Mesh.ARRAY_COLOR]!=null else tint)
			if base[Mesh.ARRAY_INDEX]!=null and not base[Mesh.ARRAY_INDEX].is_empty():
				for index in base[Mesh.ARRAY_INDEX]:indices.append(start+index)
			else:
				for j in (base[Mesh.ARRAY_VERTEX] as PackedVector3Array).size():indices.append(start+j)
		if vertices.is_empty():continue
		var arrays:=[];arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_COLOR]=colors;arrays[Mesh.ARRAY_INDEX]=indices
		if normals.size()==vertices.size():arrays[Mesh.ARRAY_NORMAL]=normals
		if uv.size()==vertices.size():arrays[Mesh.ARRAY_TEX_UV]=uv
		combined.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		var mat:Material=source.material_override if source.material_override!=null else mm.mesh.surface_get_material(surface)
		if mat is BaseMaterial3D:
			mat=mat.duplicate();mat.vertex_color_use_as_albedo=true
		combined.surface_set_material(combined.get_surface_count()-1,mat)
	if combined.get_surface_count()>0:
		var holder:=MeshInstance3D.new();holder.mesh=combined
		mesh_copy(combined,Transform3D.IDENTITY,holder,target)
		holder.mesh=null;holder.free()

func matrix(t: Transform3D) -> Array:
	return [t.basis.x.x,t.basis.x.y,t.basis.x.z,0,t.basis.y.x,t.basis.y.y,t.basis.y.z,0,t.basis.z.x,t.basis.z.y,t.basis.z.z,0,t.origin.x,t.origin.y,t.origin.z,1]

func mesh_copy(mesh: Mesh, at: Transform3D, source: Node, target: Node3D, instance_tint := Color.WHITE) -> void:
	if absf(at.basis.determinant())<0.00000001: return # Unused instance slots have no geometry.
	if mesh.get_surface_count()==0: return
	var instance:=MeshInstance3D.new()
	instance.mesh=mesh
	# The web editor gets a posed static specimen, not straight unskinned bones.
	if source is MeshInstance3D and source.mesh is ArrayMesh and source.skin!=null and not source.skeleton.is_empty():
		instance.mesh=source.bake_mesh_from_current_skeleton_pose()
	elif source is MeshInstance3D and source.skin!=null and not source.skeleton.is_empty():
		manifest.notes.append(str(source.get_path())+": skinned primitive uses its original rest mesh; skeleton pose baking requires ArrayMesh.")
	instance.transform=at
	for i in range(mesh.get_surface_count()):
		var mat: Material=source.get_active_material(i) if source is MeshInstance3D else source.material_override if source is GeometryInstance3D and source.material_override!=null else mesh.surface_get_material(i)
		if mat is BaseMaterial3D and mat.albedo_texture is ViewportTexture:
			mat=mat.duplicate()
			var screen_image: Image = mat.albedo_texture.get_image()
			mat.albedo_texture=ImageTexture.create_from_image(screen_image) if screen_image!=null and not screen_image.is_empty() else null
		if mat is ShaderMaterial:
			shader_count+=1
			var replacement:=StandardMaterial3D.new()
			replacement.albedo_color=Color("b7b7b7")
			# Thin cloth is visible from either side in Godot; retain that in GLB.
			if mat.shader!=null and "cull_disabled" in mat.shader.code:
				replacement.cull_mode=BaseMaterial3D.CULL_DISABLED
			for param in ["albedo","base_color","modelColor","color","line_color","wood_color","tint"]:
				var value=mat.get_shader_parameter(param)
				if value is Color: replacement.albedo_color=value;break
			# Retain physical surface response even when GLSL cannot travel in GLB.
			for param in ["metallic","roughness"]:
				var value=mat.get_shader_parameter(param)
				if value is float or value is int: replacement.set(param,clampf(float(value),0.0,1.0))
			mat=replacement
		# GLB has no Godot MultiMesh instance colours. Bake the instance tint
		# into each exported material so an addressed pattern stays visible.
		if mat is BaseMaterial3D and mat.vertex_color_use_as_albedo and instance_tint != Color.WHITE:
			mat = mat.duplicate()
			mat.albedo_color *= instance_tint
		instance.set_surface_override_material(i,mat)
	target.add_child(instance)
