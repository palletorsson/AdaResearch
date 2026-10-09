extends "res://tools/probes/transformation_encounters.gd"
const Journey=preload("res://tools/probes/array_entered_address.gd")
class SuppliedGrabber extends Node3D:
	var picked_up_ranged:=false
var field:Node3D
var atlas:Node3D
var actor:CharacterBody3D
var driver:Journey.KeyJourney
var completed:=false
var paths:Array=[]
func travel(point:Vector3) -> bool:
	driver.target=field.to_global(point);driver.arrived=false;driver.moving=true
	var start:=Time.get_ticks_msec()
	while not driver.arrived and Time.get_ticks_msec()-start<14000:await physics_frame
	driver.moving=false;driver.release()
	paths.append({"target":xyz(point),"reached":xyz(field.to_local(actor.global_position)),"arrived":driver.arrived})
	return driver.arrived
func landing_checks() -> void:
	root.size=Vector2i(1440,960)
	var grid:Node3D=hall.get_node_or_null("SimGrid_Color_Pillar")
	check("authored grid present",grid!=null)
	if grid==null:return
	for frame in 3600:
		if grid.has_meta("stage_grid_ready"):break
		await process_frame
	check("authored grid ready",grid.has_meta("stage_grid_ready"))
	field=find_scene("/pillarcolorcollection.gd");atlas=find_scene("/color_sets_overview.gd")
	check("field and named palette collection placed",field!=null and atlas!=null)
	if field==null or atlas==null:return
	check("spatial field and existing named palette layout active",field.spatial_gradient and atlas.structure=="named")
	var samples:=field.find_children("Pillar_*","Node3D",false,false)
	check("thirty-five pillars",samples.size()==35)
	var records:Array=[];var materials_ok:=true;var labels_ok:=true;var poses:Array=[]
	for pillar:Node3D in samples:
		var c:Color=field.sample_space(pillar.position)
		var mat:ShaderMaterial=pillar.get_node("Column").material_override
		var hsv:Vector3=mat.get_shader_parameter("sample_hsv")
		materials_ok=materials_ok and mat.get_shader_parameter("field_mode")==1 and is_equal_approx(hsv.x,c.h) and is_equal_approx(hsv.y,c.s)
		labels_ok=labels_ok and pillar.get_node("SampleAddress").text.contains("H %.2f / S %.2f" % [c.h,c.s]) and pillar.get_node("SampleAddress").text.contains("UP = VALUE")
		records.append({"sample":str(pillar.name),"local":xyz(pillar.position),"hex":c.to_html(false)})
		poses.append(pillar.global_transform)
	check("every pillar uses its coordinate hue and saturation in a height shader",materials_ok)
	check("each label identifies H/S and the value axis",labels_ok)
	var c0:Color=field.sample_space(Vector3(3.2,0,0));var c1:Color=field.sample_space(Vector3(3.2,0,19.2));var c2:Color=field.sample_space(Vector3(9.6,0,19.2))
	check("walking length holds hue and value while saturation rises",is_equal_approx(c0.h,c1.h) and is_equal_approx(c0.v,c1.v) and is_equal_approx(c0.s,0.25) and is_equal_approx(c1.s,1.0))
	check("crossing width changes hue while saturation and value hold",not is_equal_approx(c1.h,c2.h) and is_equal_approx(c1.s,c2.s) and is_equal_approx(c1.v,c2.v))
	var between:=Vector3(1.6,0,1.6);var cb:Color=field.sample_space(between)
	check("field evaluates a colour where no pillar stands",not samples.any(func(p):return p.position.is_equal_approx(between)) and cb.v>0.94)
	var ceiling:MeshInstance3D=field.get_node("ColourCeiling")
	var floor:MeshInstance3D=field.get_node("DarkFloor")
	check("old bright floor removed",not field.has_node("ContinuousGradient"))
	check("ceiling meets the column tops at value one",is_equal_approx(ceiling.position.y,field.VALUE_TOP) and ceiling.material_override.get_shader_parameter("field_mode")==2)
	check("ceiling spans beyond every outer column",ceiling.mesh.size.is_equal_approx(Vector2(15.2,21.6)))
	var address_ok:=true
	var colour_ok:=true
	var offset:Vector2=ceiling.material_override.get_shader_parameter("plane_offset")
	for pillar:Node3D in samples:
		var p:Vector3=ceiling.to_local(field.to_global(pillar.position+Vector3.UP*field.VALUE_TOP))
		var x:float=clampf((p.x+offset.x)/12.8,0.0,1.0)
		var z:float=clampf((p.z+offset.y)/19.2,0.0,1.0)
		address_ok=address_ok and is_equal_approx(x,pillar.position.x/12.8) and is_equal_approx(z,pillar.position.z/19.2)
		var c:Color=Color.from_hsv(x*0.85,lerpf(0.25,1.0,z),1.0)
		colour_ok=colour_ok and c.is_equal_approx(field.sample_volume(pillar.position+Vector3.UP*field.VALUE_TOP)) and c.is_equal_approx(field.sample_space(pillar.position))
	check("all 35 ceiling addresses align with pillar centres",address_ok)
	check("all 35 ceiling samples match the pillar top colours",colour_ok)
	check("ceiling uses spatial positions rather than stretched UVs","position_in_mesh.xz + plane_offset" in ceiling.material_override.shader.code)
	check("near-black matte floor replaces the reference slice",floor.material_override is StandardMaterial3D and floor.material_override.albedo_color.is_equal_approx(Color("080a0e")) and is_equal_approx(floor.material_override.roughness,1.0))
	check("floor remains above existing collision support",not floor_at(field.to_global(Vector3(1.6,0,1.6))).is_empty() and floor.position.y<0.03)
	var col:MeshInstance3D=samples[0].get_node("Column")
	check("coloured column reaches 4.6m above the base",is_equal_approx((col.global_transform*col.get_aabb()).end.y-field.global_position.y,4.6))
	var endpoints_ok:=true
	for pillar:Node3D in samples:
		var pos:Vector3=pillar.position
		var low:Color=field.sample_volume(Vector3(pos.x,0.46,pos.z))
		var middle:Color=field.sample_volume(Vector3(pos.x,2.53,pos.z))
		var high:Color=field.sample_volume(Vector3(pos.x,4.6,pos.z))
		endpoints_ok=endpoints_ok and low.is_equal_approx(Color.BLACK) and is_equal_approx(middle.v,0.5) and is_equal_approx(high.v,1.0)
	check("all 35 columns run from black through half value to full value",endpoints_ok)
	check("neutral comparison uses zero saturation",field.get_node("NeutralValueReference/Column").material_override.get_shader_parameter("sample_hsv").y==0.0)
	var sampler:RigidBody3D=field.sampler
	check("sampler exists with ordinary production pickup",sampler!=null and sampler.has_method("pick_up") and sampler.has_method("let_go"))
	var grip:=SuppliedGrabber.new();root.add_child(grip);grip.global_transform=sampler.global_transform
	sampler.pick_up(grip)
	check("sampler can be grabbed",sampler.is_picked_up())
	var data:Array=[]
	for value in [0.0,0.5,1.0]:
		grip.global_transform=Transform3D(field.global_basis*Basis(Vector3.UP,PI),field.to_global(Vector3(1.6,0.65+1.2*value,0.6)))
		for frame in 20:await physics_frame
		check("hand movement reaches value "+str(value),is_equal_approx(sampler.sampled_hsv.z,value))
		check("same H/S retained while raising "+str(value),is_equal_approx(sampler.sampled_hsv.x,0.10625) and is_equal_approx(sampler.sampled_hsv.y,0.2734375))
		check("field marker shows full height "+str(value),is_equal_approx(field.sample_marker.position.y,lerpf(0.46,4.6,value)))
		check("card and field marker use same sampled HSV "+str(value),sampler.get_node("MeshInstance3D").material_override.get_shader_parameter("sample_hsv")==field.sample_marker.material_override.get_shader_parameter("sample_hsv"))
		check("both RGB and HSV appear in held readout "+str(value),sampler.get_node("Label").text.contains("HSV") and sampler.get_node("Label").text.contains("RGB") and sampler.get_node("Label").text.contains("FIELD Y"))
		data.append({"hand_y":0.65+1.2*value,"hsv":xyz(sampler.sampled_hsv),"rgb":xyz(Vector3(sampler.sampled_rgb.r,sampler.sampled_rgb.g,sampler.sampled_rgb.b)),"represented_position":xyz(sampler.field_point)})
		await snapshot("sampler-"+str(int(value*100)),field.to_global(Vector3(1.6,0.65+1.2*value,-0.10)),sampler.global_position,49)
	# Known conversion, then clamped limits, through the actual grab mechanism.
	grip.global_position=field.to_global(Vector3(12.8*0.5/0.85,1.25,19.2))
	for frame in 20:await physics_frame
	check("HSV half-value cyan equals RGB 0, .5, .5",sampler.sampled_rgb.is_equal_approx(Color(0,0.5,0.5)))
	grip.global_position=field.to_global(Vector3(-5,0.05,25))
	for frame in 20:await physics_frame
	check("out-of-field sample is clamped and explicitly marked",sampler.field_point.is_equal_approx(Vector3(0,0.46,19.2)) and sampler.get_node("Label").text.contains("EDGE"))
	grip.global_position=field.to_global(Vector3(1.6,1.25,0.6))
	for frame in 20:await physics_frame
	sampler.let_go(grip,Vector3.ZERO,Vector3.ZERO)
	check("released sampler stays available at its chosen position",not sampler.is_picked_up() and sampler.freeze)
	grip.queue_free()
	observations["vertical_samples"]=data
	await snapshot("value-columns",field.to_global(Vector3(0.7,1.65,-4.3)),field.to_global(Vector3(2.2,2.1,2)),68)
	await snapshot("grey-reference",field.to_global(Vector3(-3.0,1.65,-4.5)),field.to_global(Vector3(-0.7,2.45,0)),67)
	await snapshot("under-the-palette",field.to_global(Vector3(1.6,1.65,-0.6)),field.to_global(Vector3(5.0,3.7,8)),84)
	await snapshot("ceiling-and-column",field.to_global(Vector3(0.7,1.65,-4.3)),field.to_global(Vector3(3.2,3.6,4)),72)
	await snapshot("pale-edge",field.to_global(Vector3(1.6,1.65,-2)),field.to_global(Vector3(2.2,2.0,12)),70)
	await snapshot("sample-address",field.to_global(Vector3(3.2,1.65,-1.75)),field.to_global(Vector3(3.2,1.3,-0.4)),50)
	var sets:=atlas.find_children("PaletteSet_*","Node3D",false,false)
	var stickers:=atlas.find_children("Sticker_*","RigidBody3D",true,false)
	check("twelve named sets with pickable swatches",sets.size()==12 and stickers.size()>0 and stickers.all(func(s):return s.has_method("pick_up") and s.has_method("let_go")))
	observations["palette_titles"]=[]
	for s in sets:
		for child in s.get_children():
			if child is Label3D:observations["palette_titles"].append(child.text)
	await snapshot("named-collections",atlas.to_global(Vector3(0,1.65,2.7)),atlas.to_global(Vector3(0,1.6,0)),82)
	var paper:RigidBody3D=stickers[0]
	var original:Transform3D=paper.global_transform;var original_freeze:bool=paper.freeze
	var original_label:String=paper.get_node("Label").text;var original_color:Color=paper.get_node("MeshInstance3D").material_override.albedo_color
	var grabber:=SuppliedGrabber.new();root.add_child(grabber);grabber.global_transform=original
	paper.pick_up(grabber);check("actual palette swatch can be picked up",paper.is_picked_up())
	grabber.global_transform=Transform3D(field.global_basis*Basis(Vector3.UP,PI),field.to_global(Vector3(1.6,1.3,1.6)))
	for frame in 20:await physics_frame
	check("held swatch follows supplied movement into the field",paper.global_position.distance_to(grabber.global_position)<0.02)
	check("carrying preserves colour and name",paper.get_node("Label").text==original_label and paper.get_node("MeshInstance3D").material_override.albedo_color.is_equal_approx(original_color))
	await snapshot("carried-colour",field.to_global(Vector3(1.6,1.65,0.6)),field.to_global(Vector3(1.6,1.3,1.6)),57)
	grabber.global_transform=original
	for frame in 20:await physics_frame
	paper.let_go(grabber,Vector3.ZERO,Vector3.ZERO)
	check("swatch releases after return",not paper.is_picked_up())
	paper.freeze=original_freeze;paper.global_transform=original;paper.linear_velocity=Vector3.ZERO;paper.angular_velocity=Vector3.ZERO
	check("original wall placement restored",paper.global_transform.is_equal_approx(original))
	actor=museum.get("_player");actor.global_position=field.to_global(Vector3(1.6,0.05,-1));actor.velocity=Vector3.ZERO;museum.set("_dollhouse",false)
	driver=Journey.KeyJourney.new();driver.world=museum;driver.actor=actor;driver.view=museum.get("_cam");root.add_child(driver)
	await create_timer(0.2).timeout
	check("ordinary walking follows saturation between columns",await travel(Vector3(1.6,0.05,17.6)))
	await snapshot("within-the-field",actor.global_position+Vector3.UP*1.65,field.to_global(Vector3(6.4,1.8,11.2)),76)
	check("ordinary walking crosses hues between rows",await travel(Vector3(11.2,0.05,17.6)))
	check("ordinary walking returns toward pale edge",await travel(Vector3(11.2,0.05,-1)))
	check("body remains on supporting floor",actor.is_on_floor() and absf(field.to_local(actor.global_position).y)<0.12)
	var unchanged:=true
	for i in samples.size():unchanged=unchanged and samples[i].global_transform.is_equal_approx(poses[i])
	check("walking and holding leave all pillars fixed",unchanged)
	observations["samples"]=records;observations["walks"]=paths;observations["swatches"]=stickers.size()
	observations["carried_swatch"]={"name":original_label,"hex":original_color.to_html(false)}
	observations["ceiling_shader"]=ceiling.material_override.shader.code
	observations["dark_floor_rgb"]=floor.material_override.albedo_color.to_html(false)
	var legacy:Node3D=load("res://algorithms/color/pillarcolorcollection/pillarcolorcollection.tscn").instantiate()
	root.add_child(legacy)
	check("default layout still uses uniform lit pillar materials",not legacy.spatial_gradient and legacy.find_children("Pillar_*","Node3D",false,false).size()==24 and legacy.get_node("Pillar_0_0/Column").material_override is StandardMaterial3D)
	check("default layout has no field sampler",not legacy.has_node("FieldSampler"))
	legacy.queue_free()
	completed=true
func finish() -> void:
	if driver!=null:driver.release();driver.set_physics_process(false)
	check("focused encounter completed",completed)
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Isolated production museum. Ceiling/column coordinate agreement, dark floor, vertical field materials and CPU endpoints, sampler H/S/V/RGB through actual pickup API, native captures, named swatch grabber and ordinary-controller walks. No claim of a tracked hand or calibrated pixel values. No headset, tracked reach, colour calibration, learner or performance claim."},"  "))
	print("PILLAR CEILING ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
