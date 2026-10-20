extends "res://doc/book/iterations/2026-09-28-foundry-a-mark-in-the-room/probe.gd"
var student_completed:=false

func landing_checks()->void:
    await super.landing_checks()
    if not completed:return
    if driver:driver.release();driver.set_physics_process(false)
    if actor:
        actor.hide();actor.set_process(false);actor.set_physics_process(false);actor.global_position=Vector3(0,-100,0)
    var wardrobe=museum.get("_wardrobe")
    if wardrobe!=null and is_instance_valid(wardrobe.get("costume")):wardrobe.get("costume").hide()
    camera.set_cull_mask_value(19,false)
    for n in museum.get_children():
        if n is Node3D and n.has_meta("em_map") and n!=hall:n.hide()
    await small_tile_check()
    var spec:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
    var script=load(spec.lesson)
    if script==null or not script.can_instantiate():check("learner script loads",false);return
    var learner=script.new();learner.position=Vector3(14,0,15.5);learner.rotation.y=PI/2
    hall.add_child(learner)
    var foot:Vector3=learner.to_global(Vector3(0,0,2.5))
    var support:=floor_at(foot)
    check("learner approach supported",not support.is_empty() and absf(support.position.y-foot.y)<.05)
    var capsule:=CapsuleShape3D.new();capsule.height=1.7;capsule.radius=.28
    var query:=PhysicsShapeQueryParameters3D.new();query.shape=capsule;query.collision_mask=1|4;query.transform.origin=foot+Vector3.UP*.88
    var overlaps:=hall.get_world_3d().direct_space_state.intersect_shape(query,8)
    check("learner approach has standing clearance",overlaps.is_empty())
    observations["approach_colliders"]=[]
    for hit in overlaps:observations.approach_colliders.append(str(hit.collider.get_path()))
    await create_timer(.3).timeout
    check("point retains authored start after physics",learner.control.position.is_equal_approx(Vector3(0,1.15,1.9)))
    await snapshot("student-source",learner.to_global(Vector3(0,2.2,3.0)),learner.to_global(Vector3(0,1,.7)),54)
    var originals:Array=[];var transforms:Array=[]
    for i in 25:
        originals.append(learner.grid.instances.get_instance_color(i));transforms.append(learner.grid.instances.get_instance_transform(i))
    var origin:=XROrigin3D.new();root.add_child(origin)
    var controller:=XRController3D.new();origin.add_child(controller)
    var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
    controller.global_transform=learner.control.global_transform;learner.control.pick_up(pickup);await tick()
    controller.global_position=learner.grid.to_global(Vector3(4*.32,.33,2*.32))
    for i in 8:await tick()
    check("simulated grip reaches intended tile in turned host",learner.control.is_picked_up() and learner.selected_address()==Vector2i(4,2))
    check("hover identifies source without painting",learner.source[0][1]==1 and learner.grid.marker.visible and learner.label.text.contains("source row 0, column 1"))
    learner.control.action();await tick()
    var changed:=0;var fixed:=true
    for i in 25:
        if learner.grid.instances.get_instance_color(i)!=originals[i]:changed+=1
        fixed=fixed and learner.grid.instances.get_instance_transform(i).is_equal_approx(transforms[i])
    check("held action changes six copies and one source entry",learner.source[0][1]==2 and changed==6)
    check("painting preserves all twenty-five cube transforms",fixed)
    await snapshot("student-one-edit",learner.to_global(Vector3(0,2.2,3.0)),learner.to_global(Vector3(0,1,.7)),54)
    controller.global_position=learner.grid.to_global(Vector3(0,1.0,0))
    for i in 6:await tick()
    var before:Array=learner.source.duplicate(true)
    learner.control.action()
    check("raised hand declines editing",learner.selected_address()==Vector2i(-1,-1) and learner.source==before)
    learner.control.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick()
    check("release freezes inherited point",learner.control.freeze and not learner.control.is_picked_up())
    learner.hide();learner.queue_free();origin.queue_free()
    var transfer_path:String=spec.lesson.replace('/printed/','/third-row/')
    var transfer=load(transfer_path).new();transfer.position=Vector3(14,0,15.5);transfer.rotation.y=PI/2;hall.add_child(transfer)
    await tick()
    check("independent three-row program keeps receiver and extends period",transfer.source.size()==3 and transfer.grid.cells.size()==25 and transfer.value_at(Vector2i(0,2))==2 and transfer.value_at(Vector2i(0,3))==0)
    await snapshot("student-third-row",transfer.to_global(Vector3(0,2.2,3.0)),transfer.to_global(Vector3(0,1,.7)),54)
    observations["student"]={"temporary_host_hall_local":[14,0,15.5],"yaw":90,"printed":spec.lesson,"transfer":transfer_path,"scope":"Temporary study in real museum; pointer source controls, simulated held trigger and separate changed source. No permanent placement or physical headset claim."}
    transfer.queue_free();student_completed=true

func small_tile_check()->void:
    var tile:Node3D=null
    var distance:=INF
    for n in hall.find_children("*","Node3D",true,false):
        if n.get_script()!=null and str(n.get_script().resource_path).ends_with('/pattern_tile_puzzle.gd'):
            var d:float=hall.to_local(n.global_position).distance_to(Vector3(7.5,0,7.5))
            if d<distance:tile=n;distance=d
    check("primary four by four source exists",tile!=null and tile.tile_size==4 and tile.repeat_mode==0)
    if tile==null:return
    var prior:int=tile.get_cell(1,0);var next:int=(prior+1)%tile.palette.size()
    var before:Array=tile.get_pattern_data().duplicate(true)
    tile.set_cell(1,0,next)
    check("installed source update reaches repeated lookup",tile._get_tiled_color(1,0)==next and tile._get_tiled_color(5,0)==next and tile._get_tiled_color(1,4)==next)
    var one:=true
    for z in 4:
        for x in 4:
            if Vector2i(x,z)!=Vector2i(1,0):one=one and tile.get_cell(x,z)==before[z][x]
    check("installed source changes only the selected entry",one)
    var tex:Texture2D=tile._preview_mesh.material_override.albedo_texture
    var pixel:Color=tex.get_image().get_pixel(1,0)
    var expected:Color=tile.palette[next]
    var matches:=true
    for channel in 4:matches=matches and absf(pixel[channel]-expected[channel])<=1.0/255.0+.000001
    observations["small_tile_pixel"]={"format":"RGBA8","received":[pixel.r,pixel.g,pixel.b,pixel.a],"palette":[expected.r,expected.g,expected.b,expected.a],"maximum_channel_error":1.0/255.0}
    check("installed RGBA8 preview refreshes its changed pixel",matches)
    await snapshot("small-source",tile.to_global(Vector3(0,1.8,2.3)),tile.to_global(Vector3(0,.6,0)),65)
    tile.set_cell(1,0,prior)

func finish()->void:
    check("printed learner and transfer completed",student_completed)
    super.finish()
