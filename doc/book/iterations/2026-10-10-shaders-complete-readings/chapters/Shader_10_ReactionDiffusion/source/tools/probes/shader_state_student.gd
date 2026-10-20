extends SceneTree
var checks:Array=[]
var source:String
var report:String
var variation:=false
var study:Node3D
var f:Node
var view:SubViewport
func _initialize()->void:call_deferred("run")
func check(ok:bool,title:String)->void:
    checks.append({"passed":ok,"test":title});print("PASS " if ok else "FAIL ",title)
func settle()->void:
    while f.busy or f.pending_steps>0 or f.pending_reset>=0 or not f.brush_queue.is_empty():await process_frame
    await RenderingServer.frame_post_draw
func act(key:String)->void:
    study.buttons[key].get_node("InteractableAreaButton").button_pressed.emit(null)
func read()->Image:
    for i in range(4):await process_frame
    await RenderingServer.frame_post_draw
    return view.get_texture().get_image()
func diff(a:Image,b:Image)->float:
    var total:=0.0
    for y in a.get_height():
        for x in a.get_width():
            var c:=a.get_pixel(x,y);var d:=b.get_pixel(x,y)
            total+=absf(c.r-d.r)+absf(c.g-d.g)+absf(c.b-d.b)
    return total/(3*a.get_width()*a.get_height())
func reference(old:Image)->Image:
    var result:=Image.create(96,96,false,Image.FORMAT_RGB8)
    for y in 96:
        for x in 96:
            var c:Vector2=f.decode(old.get_pixel(x,y));var lap:Vector2=-c
            for d in [Vector2i(-1,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1)]:lap+=.2*f.decode(old.get_pixel(posmod(x+d.x,96),posmod(y+d.y,96)))
            for d in [Vector2i(-1,-1),Vector2i(1,-1),Vector2i(-1,1),Vector2i(1,1)]:lap+=.05*f.decode(old.get_pixel(posmod(x+d.x,96),posmod(y+d.y,96)))
            var r:float=c.x*c.y*c.y
            var next:Vector2=(c+Vector2(lap.x-r+f.feed*(1-c.x),.5*lap.y+r-(f.feed+f.kill)*c.y)).clamp(Vector2.ZERO,Vector2.ONE)
            result.set_pixel(x,y,f.encode(next.x,next.y))
    return result
func error(a:Image,b:Image)->float:
    var maximum:=0.0
    for y in 96:
        for x in 96:maximum=maxf(maximum,f.decode(a.get_pixel(x,y)).distance_to(f.decode(b.get_pixel(x,y))))
    return maximum
func run()->void:
    create_timer(95).timeout.connect(func():quit(98))
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--lesson="):source=arg.trim_prefix("--lesson=")
        if arg.begins_with("--report="):report=arg.trim_prefix("--report=")
        if arg=="--variation":variation=true
    study=load(source).new();study.position=Vector3(4,2,7);study.rotation.y=.7;root.add_child(study)
    f=study.field;await settle()
    check(study.control.is_inside_tree() and study.cube.is_inside_tree() and study.readout.is_inside_tree(),"Printed source constructs point, cube and readout")
    check(is_equal_approx(f.feed,.065 if variation else .055),"Declared feed reaches solver")
    check(study.control.surface.material_override==study.material and study.cube.get_child(0).material_override==study.material,"Point and cube share one display material")
    check(f.views.size()==16 and f.views.all(func(v):return v.size==Vector2i(96,96)),"GPU runner creates its declared two groups")
    check(not f.running and f.iterations==0,"Starts held at step zero")
    var initial:Image=f.state_texture.get_image()
    check(f.decode(initial.get_pixel(1,1)).is_equal_approx(Vector2(1,0)) and f.decode(initial.get_pixel(30,33)).y>.99,"Initial field contains background and seeded discs")
    await create_timer(.08).timeout
    check(f.state_texture.get_image().get_data()==initial.get_data(),"Waiting alone does not update state")
    act("STEP");await settle();var first:Image=f.state_texture.get_image()
    check(f.iterations==1,"STEP button requests exactly one iteration")
    var expected:=reference(initial)
    var first_error:=error(first,expected);print("FIRST_ERROR ",first_error)
    check(first_error<.001,"First GPU update matches independent equation at every cell")
    check(absf(f.decode(first.get_pixel(30,33)).x-(.0325 if variation else .0275))<.001,"Seed interior matches the tutorial prediction")
    act("STEP");await settle();var second:Image=f.state_texture.get_image()
    check(error(second,reference(first))<.001,"Second GPU update uses completed first state")
    check(second.get_data()!=first.get_data(),"Feedback progresses beyond its first output")
    act("RESET");await settle();check(f.iterations==0 and f.state_texture.get_image().get_data()==initial.get_data(),"RESET reproduces initial state exactly")
    f.step(16);await settle();var batch:Image=f.state_texture.get_image()
    act("RESET");await settle()
    for i in 16:f.step();await settle()
    check(f.state_texture.get_image().get_data()==batch.get_data(),"Batched and single-step updates agree after buffer reuse")
    act("CLEAR");await settle();f.step(8);await settle()
    check(f.decode(f.state_texture.get_image().get_pixel(30,33)).is_equal_approx(Vector2(1,0)),"Uniform background stays fixed through eight steps")
    study.control.action();await settle()
    check(f.decode(f.state_texture.get_image().get_pixel(79,62)).y==0,"Unheld trigger cannot plant")
    var xr:=XROrigin3D.new();root.add_child(xr);var hand:=XRController3D.new();xr.add_child(hand)
    var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup)
    hand.global_transform=study.control.global_transform;study.control.pick_up(pickup)
    for i in 5:await process_frame
    hand.global_position=study.to_global(Vector3(-.3,1.8,1.2))
    for i in 5:await process_frame
    check(f.decode(f.state_texture.get_image().get_pixel(33,33)).y==0,"Moving the held point alone adds no mark")
    study.control.action();await settle();var marked:Image=f.state_texture.get_image()
    check(f.decode(marked.get_pixel(33,33)).y>.99 and f.decode(marked.get_pixel(62,62)).y<.001,"Held trigger plants at the local XY address in the rotated study")
    check(f.iterations==8,"Planting while held changes data without advancing model time")
    hand.global_position=study.to_global(Vector3(3,1.8,1.2))
    for i in 5:await process_frame
    study.control.action();await settle()
    check(f.state_texture.get_image().get_data()==marked.get_data(),"Out-of-range XY address is rejected")
    study.control.let_go(pickup,Vector3.ZERO,Vector3.ZERO)
    await create_timer(.08).timeout
    check(study.control.freeze and f.state_texture.get_image().get_data()==marked.get_data(),"Release freezes point and leaves held record intact")
    # Independent viewport exposes the actual display shader, without museum lighting noise.
    view=SubViewport.new();view.size=Vector2i(192,192);view.own_world_3d=true;view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
    var env:=WorldEnvironment.new();env.environment=Environment.new();env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;env.environment.ambient_light_energy=1;view.add_child(env)
    var q:=MeshInstance3D.new();var quad:=QuadMesh.new();quad.size=Vector2(2,2);q.mesh=quad;q.material_override=study.material;view.add_child(q)
    var cam:=Camera3D.new();cam.position.z=3;cam.projection=Camera3D.PROJECTION_ORTHOGONAL;cam.size=2;view.add_child(cam);cam.make_current()
    var painted:=await read();painted.save_png(report.get_base_dir()+"/marked.png")
    check(painted.get_pixel(66,66).r<painted.get_pixel(120,120).r-.2,"GPU display places ink at the planted address")
    act("INK");var recoloured:=await read()
    check(diff(painted,recoloured)>.001,"INK visibly changes display")
    check(f.state_texture.get_image().get_data()==marked.get_data(),"INK leaves all saved data bytes unchanged")
    act("CLEAR");await settle();var clear:=await read()
    check(diff(clear,recoloured)>.002,"CLEAR visibly removes the saved mark")
    act("RESET");await settle();act("RUN/HOLD");await create_timer(.08).timeout;act("RUN/HOLD");await settle()
    check(f.iterations>0 and not f.running,"RUN evolves and HOLD finishes its batch")
    var held:PackedByteArray=f.state_texture.get_image().get_data();await create_timer(.08).timeout
    check(f.state_texture.get_image().get_data()==held,"Held completed output remains fixed")
    act("RESET");await settle();f.step(6000);await settle()
    var grown:Image=f.state_texture.get_image();var cells:=0
    for y in 96:
        for x in 96:
            if f.decode(grown.get_pixel(x,y)).y>.1:cells+=1
    print("GROWN_CELLS ",cells)
    check(cells>500,"Six thousand model updates extend the initial differences")
    var visible:=await read();visible.save_png(report.get_base_dir()+"/grown.png")
    check(study.material.get_shader_parameter("state_texture")==f.state_texture,"Display binds the finished state, not the seed")
    check(study.cube.get_child(0).mesh.size==Vector3.ONE*.6 and is_equal_approx(study.control.surface.mesh.radius,.14),"Updating field retains earned body geometry")
    await physics_frame
    var ray:=PhysicsRayQueryParameters3D.create(study.to_global(Vector3(-.6,.9,1)),study.to_global(Vector3(-.6,.9,-1)),1)
    var hit:=study.get_world_3d().direct_space_state.intersect_ray(ray)
    check(not hit.is_empty() and hit.collider==study.cube,"Cube remains solid after field evolution")
    var passed:bool=checks.all(func(c):return c.passed)
    var out:=FileAccess.open(report,FileAccess.WRITE);out.store_string(JSON.stringify({"passed":passed,"checks":checks,"first_error":first_error,"grown_cells":cells,"scope":"Exact printed reconstruction; actual GPU and synthetic XR. Teacher authored, not independent student or headset evidence."},"\t"));out.close()
    quit(0 if passed else 1)

