extends SceneTree
const OUT="res://doc/reports/interfaces-2026-09-21/console-placement/"
var variant:="after"
var world:Node3D
var camera:Camera3D
var demo:Node3D
var checks:Array=[]
var failures:Array=[]
var measurements:Array=[]
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks.append({"passed":ok,"message":label})
	if not ok:failures.append(label)
	print("LIBRARY ","PASS " if ok else "FAIL ",label)
func settle()->void:
	for i in 6:await process_frame;await physics_frame
func run()->void:
	if not OS.get_cmdline_user_args().is_empty():variant=OS.get_cmdline_user_args()[0]
	world=Node3D.new();root.add_child(world)
	var env:=WorldEnvironment.new();env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color(.13,.16,.20)
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color(.9,.93,1);env.environment.ambient_light_energy=.8
	world.add_child(env)
	var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-35,-25,0);world.add_child(light)
	var floor_mesh:=MeshInstance3D.new();floor_mesh.mesh=PlaneMesh.new();floor_mesh.mesh.size=Vector2(12,12);world.add_child(floor_mesh)
	demo=load("res://commons/ui/demo/vr_component_demo.tscn").instantiate();world.add_child(demo)
	camera=Camera3D.new();world.add_child(camera);camera.current=true;root.msaa_3d=Viewport.MSAA_4X
	await settle()
	check(demo.has_method("show_page"),"Library brings each family to one operating station")
	await capture("library",Vector3(1.4,1.9,2.6),Vector3(0,1,0),57)
	if variant=="after":
		await exercise()
		await analysis_leases()
	FileAccess.open(OUT+variant+"/checks.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"headset_tested":false,"measurements":measurements},"\t"))
	quit(0 if variant=="before" or failures.is_empty() else 1)
func capture(name:String,eye:Vector3,target:Vector3,fov:float)->void:
	camera.position=eye;camera.look_at(target);camera.fov=fov
	await settle();await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+variant+"/"+name+".png")
class TestGrabber extends Node3D:
	var picked_up_ranged:=false
	var held:Node3D
	func drop_object()->void:
		held.let_go(self,Vector3.ZERO,Vector3.ZERO);held=null
func exercise()->void:
	var total:=0
	var master:=AudioServer.get_bus_index("Master")
	var existing:=AudioEffectAmplify.new()
	AudioServer.add_bus_effect(master,existing)
	var base_effects:=AudioServer.get_bus_effect_count(master)
	for i in demo.pages.size():
		demo.show_page(i);await settle()
		var title:String=demo.pages[i].title
		check(demo.page_index==i,title+": page loads")
		check(demo.controls.size()==demo.pages[i].items.size(),title+": every listed component appears")
		check(demo.active_page.get_child_count()>=demo.controls.size(),title+": active controls have one live page")
		total+=demo.controls.size()
		var box:=visible_box(demo,demo)
		measurements.append({"page":i,"size":[box.size.x,box.size.y,box.size.z],"centre":[box.get_center().x,box.get_center().y,box.get_center().z]})
		check(box.position.y>=-.001,title+": visible console stands above its floor origin")
		for slot in range(1,demo.controls.size()):
			var left:=visible_box(demo.controls[slot-1],demo.station)
			var right:=visible_box(demo.controls[slot],demo.station)
			check(left.end.x<right.position.x,title+": neighboring specimens do not overlap")
		var visible_labels:=0
		for label in demo.find_children("*","Label3D",true,false):
			if label.is_visible_in_tree():visible_labels+=1
		check(visible_labels==0,title+": visible text is on flat surfaces")
		for control in demo.controls:
			check(control.global_basis.get_scale().is_equal_approx(Vector3.ONE),title+": control keeps metre scale")
			check(control.global_position.y>.8 and control.global_position.y<1.3,title+": control origin stays above floor in working band")
		for name in ["Prev","Next"]:
			var button:Node3D=demo.station.get_node(name)
			check(button.global_position.y>.7 and button.global_position.y<1.25,title+": pager stays in working band")
		if i in [3,5,6,8,10]:await capture("page-"+str(i),Vector3(.35,1.65,1.25),Vector3(0,1.12,0),58)
	# Repeated audio-page visits must release effects; preserve unrelated bus work.
	for repeat in 3:
		demo.show_page(9);await settle()
		demo.show_page(10);await settle()
		demo.show_page(5);await settle()
		check(AudioServer.get_bus_effect_count(master)==base_effects,"Audio page round trip "+str(repeat)+" leaves no extra effects")
	var untouched:=false
	for i in AudioServer.get_bus_effect_count(master):
		if AudioServer.get_bus_effect(master,i)==existing:untouched=true
	check(untouched,"Paging preserves an unrelated audio effect")
	preload("res://commons/audio/systems/spectrum_analyzer_lease.gd").remove_owned_effect(existing)
	check(total==28,"All 28 original specimen placements remain available across pages")
	# Page events travel through the real physical button pointer bridge.
	demo.show_page(5);await settle()
	var button:Node3D=demo.station.get_node("Next")
	var area:Area3D=button.get_node("InteractableAreaButton")
	var ray:=PhysicsRayQueryParameters3D.create(Vector3(0,1.2,.70),area.global_position,1<<20)
	ray.collide_with_areas=true
	var hit:=world.get_world_3d().direct_space_state.intersect_ray(ray)
	check(not hit.is_empty() and hit.collider==area,"Actual operating ray reaches Next button")
	var pointer:=Node3D.new();world.add_child(pointer)
	XRToolsPointerEvent.pressed(pointer,area,area.global_position)
	await settle()
	check(demo.page_index==6,"Physical Next button changes the page")
	XRToolsPointerEvent.released(pointer,area,area.global_position)
	demo.show_page(demo.pages.size()-1);await settle()
	XRToolsPointerEvent.pressed(pointer,area,area.global_position);await settle()
	check(demo.page_index==0,"Physical Next wraps to the first family")
	XRToolsPointerEvent.released(pointer,area,area.global_position)
	var before:int=demo.active_page.get_instance_id()
	demo._rebuild();await settle()
	check(demo.active_page.get_instance_id()!=before,"Reset rebuilds only the current page")
	check(demo.station.find_children("ActivePage","Node3D",false,false).size()==1,"Page changes do not accumulate hidden active controls")
	demo.show_page(5);await settle()
	var snap:Node3D=demo.controls[1];var zero:Node3D=demo.controls[2]
	snap.set_angle_degrees(23);zero.set_angle_degrees(23)
	check(absf(snap.get_angle_degrees()-25)<.01,"Library uses the actual five-degree lever")
	var grip:Node3D=zero.hinge.get_node("HandleOrigin/InteractableHandle")
	var hand:=TestGrabber.new();world.add_child(hand);hand.global_transform=grip.global_transform;hand.held=grip;grip.pick_up(hand)
	check(not demo.show_page(6) and demo.page_index==5,"Paging waits for a held physical control to be released")
	hand.drop_object();hand.queue_free()
	var start:=zero.global_position
	XRToolsPointerEvent.pressed(pointer,zero,start)
	check(not demo.show_page(6),"Paging waits for an active control pointer")
	XRToolsPointerEvent.released(pointer,zero,start)
	check(is_zero_approx(zero.get_angle_degrees()),"Library uses the actual returning lever")
	# The old slider keeps its typed Label3D internally; only its flat proxy is drawn.
	demo.show_page(0);await settle()
	demo.controls[0].set_normalized_value(.75)
	await create_timer(.2).timeout
	var mirrored:=false
	for entry in demo._mirrors:
		if entry.control==demo.controls[0]:mirrored="0.75" in entry.card.label.text
	check(mirrored,"Legacy value changes appear on the flat card")
	demo.show_page(5);await settle()
	demo.controls[1].set_angle_degrees(23)
	await capture("levers",Vector3(.35,1.65,1.25),Vector3(0,1.12,0),58)

func visible_box(node:Node3D,space:Node3D)->AABB:
	var box:=AABB();var started:=false
	var meshes:Array=node.find_children("*","MeshInstance3D",true,false)
	if node is MeshInstance3D:meshes.append(node)
	for mesh in meshes:
		if not mesh.is_visible_in_tree():continue
		var transformed:AABB=(space.global_transform.affine_inverse()*mesh.global_transform)*mesh.get_aabb()
		box=box.merge(transformed) if started else transformed
		started=true
	return box


func analysis_leases()->void:
	var master:=AudioServer.get_bus_index("Master")
	var before:=AudioServer.get_bus_effect_count(master)
	var a:Control=load("res://commons/audio/interfaces/SimpleWaveformDisplay.gd").new()
	var b:Control=load("res://commons/audio/interfaces/SimpleWaveformDisplay.gd").new()
	root.add_child(a);root.add_child(b);await settle()
	check(a.spectrum_analyzer==b.spectrum_analyzer,"Two waveform views share one owned analyser")
	var active:=AudioServer.get_bus_effect_count(master)
	a.queue_free();await settle()
	check(AudioServer.get_bus_effect_count(master)==active,"Removing one view keeps the remaining view's analyser")
	var bus_name:="LibraryTest_"+str(b.get_instance_id())
	AudioServer.add_bus();AudioServer.set_bus_name(AudioServer.get_bus_count()-1,bus_name)
	b.set_source_bus(bus_name)
	check(AudioServer.get_bus_effect_count(master)==before,"Changing bus releases the old analyser")
	check(AudioServer.get_bus_effect_count(AudioServer.get_bus_index(bus_name))==1,"New bus has exactly one leased analyser")
	b.set_source_bus("MissingLibraryTestBus")
	check(AudioServer.get_bus_effect_count(AudioServer.get_bus_index(bus_name))==0,"Missing-bus fallback releases the previous bus effect")
	check(b.audio_bus_index==master,"Missing source bus falls back to Master")
	b.queue_free();await settle()
	check(AudioServer.get_bus_effect_count(master)==before,"Last waveform view releases its analyser")
	AudioServer.remove_bus(AudioServer.get_bus_index(bus_name))
