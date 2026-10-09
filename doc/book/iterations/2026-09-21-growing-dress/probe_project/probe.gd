extends SceneTree
const Wardrobe = preload("res://commons/player/costume_wardrobe.gd")
const Costume = preload("res://commons/player/queer_costume.gd")
const Recipe = preload("res://commons/artifacts/fabric_shader_studio/fabric_recipe.gd")
const Journey = preload("res://museum_costume_slice.gd")
var checks: Array = []
var failures: Array = []
var observations: Array = []
var stage: Node3D

class Progress extends Node:
	signal sequence_completed(sequence: String)
	var done: Array[String] = []
	func is_sequence_completed(sequence: String) -> bool:
		return done.has(sequence)

func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks.append({"label":label,"pass":ok})
	if not ok: failures.append(label); push_error(label)
func settle(frames: int = 4) -> void:
	for i in range(frames): await process_frame
func wear(head: Node3D, progress: Node) -> Node:
	var w = Wardrobe.new()
	w.appearance_save_path = ""
	w.mount_path = head.get_parent().get_path()
	w.head_path = head.get_path()
	w.manager_path = progress.get_path()
	stage.add_child(w)
	await settle()
	return w
func camera(parent: Node3D, label: String) -> Camera3D:
	var c := Camera3D.new(); c.name=label; c.position=Vector3(0,1.65,0); parent.add_child(c); return c
func rig(label: String) -> Node3D:
	var o := XROrigin3D.new(); o.name=label; stage.add_child(o)
	var eye := XRCamera3D.new(); eye.name="XRCamera3D";eye.position.y=1.65;o.add_child(eye)
	return o
func snapshot(w: Node, label: String) -> void:
	var skirt: MeshInstance3D = w.costume.drag_outfit.get_node("Skirt")
	observations.append({"label":label,"stage":w.costume.stage,"height":skirt.mesh.height,"bottom_radius":skirt.mesh.bottom_radius,"hem_y":skirt.position.y-skirt.mesh.height*0.5,"material_id":skirt.material_override.get_instance_id()})
	if not OS.get_cmdline_user_args().has("--capture"):return
	await settle(6)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../"+label+".png")

func run() -> void:
	stage=Node3D.new();root.add_child(stage);current_scene=stage
	var manager=Progress.new();stage.add_child(manager)
	var preview=preload("res://commons/player/super_drag_outfit.gd").new()
	stage.add_child(preview)
	for look in preview.LOOKS:
		preview.dress(look)
		check(is_equal_approx(preview.get_node("Skirt").mesh.height,0.85),"independent preview retains original size: "+look)
	preview.queue_free()
	var head=camera(stage,"Wearer");head.current=false
	var w:Node=await wear(head,manager)
	check(w.costume!=null,"wardrobe creates the actual costume")
	var spine:Array=Wardrobe.spine_sequences()
	check(spine.size()==24 and spine[2]=="array_tutorial" and spine[4]=="tiling","authoritative 24-sequence spine includes Arrays and Tiling in order")
	check(not w.give("unknown_sequence",true) and w.costume.stage==0,"unknown sequence cannot grow the costume")
	check(w.give("primitives",true),"first visited sequence grows once")
	check(not w.give("primitives",true) and w.costume.stage==1,"revisit cannot grant another stage")
	check(w.choose_outfit("pearl_rococo",false),"selected drag outfit is wearable")
	var recipe:Dictionary=Recipe.initial();recipe.cells[0][0]=3
	check(w.set_skirt_fabric(recipe,false),"selected fabric reaches skirt")
	var skirt:MeshInstance3D=w.costume.drag_outfit.get_node("Skirt")
	var skirt_id:int=skirt.get_instance_id();var mesh_id:int=skirt.mesh.get_instance_id();var mat_id:int=skirt.material_override.get_instance_id()
	var early_height:float=skirt.mesh.height;var early_radius:float=skirt.mesh.bottom_radius
	check(is_equal_approx(skirt.position.y+skirt.mesh.height*0.5,-0.515),"growth starts from a fixed waist")
	# Rendering uses the same real costume; a third-person study, not a headset view.
	var env:=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("141522");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color("eaddec");env.environment.ambient_light_energy=0.85;stage.add_child(env)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-35,-25,0);sun.light_energy=1.3;stage.add_child(sun)
	var floor:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(8,8);floor.mesh=plane;var floor_mat:=StandardMaterial3D.new();floor_mat.albedo_color=Color("4e4759");floor.material_override=floor_mat;stage.add_child(floor)
	var viewer=camera(stage,"Observer");viewer.position=Vector3(1.9,1.6,-2.8);viewer.look_at(Vector3(0,0.9,0));viewer.current=true;viewer.fov=40
	await snapshot(w,"dress-one")
	for seq in ["transformation","array_tutorial","color","tiling"]: check(w.give(seq,true),"growth accepts "+seq)
	check(w.costume.stage==5,"five unique sequences give five stages")
	check(w.costume.drag_outfit.growth_stage==5,"the visible selected outfit receives the stage")
	check(skirt.mesh.height>early_height and skirt.mesh.bottom_radius>early_radius,"worn hem lengthens and widens")
	check(skirt.get_instance_id()==skirt_id and skirt.mesh.get_instance_id()==mesh_id and skirt.material_override.get_instance_id()==mat_id,"growth preserves the exact skirt mesh and chosen material")
	check(w.skirt_fabric==recipe and w.costume.drag_outfit.skirt_fabric==recipe,"growth preserves chosen fabric values")
	await snapshot(w,"dress-five")
	var before:float=skirt.mesh.height
	w.give("change",false)
	check(is_equal_approx(skirt.mesh.height,before),"arrival animation starts at the current hem")
	await create_timer(0.65).timeout
	var mid:float=skirt.mesh.height
	check(mid>before and mid<lerpf(0.5,0.9,6.0/24.0),"arrival passes through an intermediate hem")
	await create_timer(0.95).timeout
	check(is_equal_approx(skirt.mesh.height,lerpf(0.5,0.9,6.0/24.0)),"arrival settles at the visited stage")
	await create_timer(0.2).timeout
	check(w.costume.stage==6,"waiting does not add progress")
	for seq in spine:w.give(seq,true)
	check(w.costume.stage==24 and w.worn().size()==24,"all current sequences fit the growth budget")
	check(w.costume.garment_tiers()==24,"base dress has exactly 24 tiers without queued duplicate children")
	check(w.costume.pinned_count()==24,"all 24 sequence keepsakes are present without replacing one another")
	check(skirt.position.y-skirt.mesh.height*0.5>=-1.416,"worn hem remains bounded below the fixed waist")
	check(skirt.mesh.bottom_radius<0.5,"grown silhouette stays within the authored radius bound")
	check(w.costume.find_children("*","CollisionObject3D",true,false).is_empty(),"cosmetic growth adds no collision bodies")
	await snapshot(w,"dress-twenty-four")
	for look in ["latex_cathedral","chrome_orchid","holo_fan","pearl_rococo"]:
		w.choose_outfit(look,false)
		check(w.costume.drag_outfit.growth_stage==24 and w.costume.drag_outfit.skirt_fabric==recipe,"look change retains growth and recipe: "+look)
	w.choose_outfit("",false)
	check(w.costume._garment.visible and w.costume.stage==24,"return to walk dress retains growth")
	# Quiet restore derives stages from completed sequences, without new save state.
	manager.done.assign(["array_tutorial","tiling"])
	var restored_head=camera(stage,"RestoredHead");restored_head.position.x=20
	var restored:Node=await wear(restored_head,manager)
	check(restored.worn()==["array_tutorial","tiling"] and restored.costume.stage==2,"completed Arrays and Tiling restore on a new wardrobe")
	# Exact museum methods run with staged and active rigs, no production autoload.
	manager.done.clear()
	var menu:Node3D=rig("MenuRig");var game:Node3D=rig("GameRig")
	menu.current=true
	var menu_w:Node=await wear(menu.get_node("XRCamera3D"),manager)
	var game_w:Node=await wear(game.get_node("XRCamera3D"),manager)
	var museum=Journey.new();stage.add_child(museum);museum._vr=true
	var room:=Node3D.new();room.set_meta("em_chapter","array_tutorial");museum.add_child(room)
	museum._segments=[{"z0":-1.0,"z1":3.0,"node":room}]
	game.current=true
	museum._costume_walk()
	check(game_w.costume.stage==1 and menu_w.costume.stage==0,"VR hall growth reaches the current rig, not menu rig")
	museum._costume_walk()
	check(game_w.costume.stage==1,"same VR hall cannot double-grow")
	room.set_meta("em_chapter","tiling");museum._costume_walk()
	check(game_w.worn()==["array_tutorial","tiling"],"VR chapter transition carries previous growth")
	menu.current=true;museum._costume_walk()
	check(menu_w.worn()==["tiling"] and game_w.costume.stage==2,"switching active rigs reacquires the correct wardrobe")
	var late_rig:Node3D=rig("LateRig");late_rig.current=true
	museum._costume_walk()
	var late_w:Node=await wear(late_rig.get_node("XRCamera3D"),manager)
	museum._costume_walk()
	check(late_w.worn()==["tiling"],"a wardrobe arriving after its XR rig still receives the current hall")
	museum._costume_on=false;room.set_meta("em_chapter","color");museum._costume_walk()
	check(late_w.costume.stage==1,"costume-off suppresses museum growth")
	# Desktop path continues to use its own visitor and existing wardrobe.
	museum._vr=false;museum._costume_on=true;museum._wardrobe=restored;museum._player=Node3D.new();museum.add_child(museum._player);museum._cam=restored_head;museum._costume_hall="";museum._costume_walk()
	check(restored.worn().has("color"),"desktop hall entry still grows its own wardrobe")
	var report={"checks":checks,"failures":failures,"observations":observations,"scope":"Actual wardrobe/costume/outfit source and literal museum routing methods; stub completion manager and generated poses. No production autoloads, player saves or physical headset.","headset_tested":false}
	var f:=FileAccess.open("res://../probe-results.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close()
	print("GROWING DRESS: %d checks, %d failures" % [checks.size(),failures.size()])
	quit(0 if failures.is_empty() else 1)
