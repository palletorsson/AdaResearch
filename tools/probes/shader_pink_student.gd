extends SceneTree
var checks:Array=[]
var source:String
var report:String
var variation:=false
var study:Node3D
var view:SubViewport
const SIDE:=192
func _initialize()->void:call_deferred("run")
func check(ok:bool,title:String)->void:
    checks.append({"passed":ok,"test":title});print("PASS " if ok else "FAIL ",title)
func read()->Image:
    for i in range(5):await process_frame
    await RenderingServer.frame_post_draw
    return view.get_texture().get_image()
func pixel(im:Image,p:Vector2)->Color:
    return im.get_pixel(clampi(int(p.x*SIDE),0,SIDE-1),clampi(int(p.y*SIDE),0,SIDE-1))
func difference(a:Image,b:Image)->float:
    var total:=0.0
    for y in SIDE:
        for x in SIDE:
            var p:=a.get_pixel(x,y);var q:=b.get_pixel(x,y)
            total+=(absf(p.r-q.r)+absf(p.g-q.g)+absf(p.b-q.b))/3
    return total/(SIDE*SIDE)
func move(local:Vector3)->void:
    study.control.global_position=study.to_global(local)
    PhysicsServer3D.body_set_state(study.control.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,study.control.global_transform)
    study.update_rule()
func weights(v:Vector3)->void:
    move(Vector3(v.x-.35,v.y+.6,v.z+.9))
func run()->void:
    create_timer(65).timeout.connect(func():quit(98))
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--lesson="):source=arg.trim_prefix("--lesson=")
        if arg.begins_with("--report="):report=arg.trim_prefix("--report=")
        if arg=="--variation":variation=true
    var script=load(source)
    if script==null or not script.can_instantiate():quit(2);return
    study=script.new();study.position=Vector3(4,2,7);study.rotation=Vector3(.2,.7,0)
    root.add_child(study);study.set_process(false);await create_timer(.12).timeout;study.update_rule()
    var repeats:=Vector2(4,2) if variation else Vector2(3,3)
    check(study.control!=null and study.readout.is_inside_tree() and study.cube!=null,"Printed program creates point, cube and readout")
    check(study.amounts.is_equal_approx(Vector3(1,.6,.3)) and study.mode==1,"Turned and translated study reads its local starting pose")
    var cube_mesh:MeshInstance3D=study.cube.get_child(0)
    check(study.control.surface.material_override==study.material and cube_mesh.material_override==study.material,"Same material belongs to the inherited cube and point")
    check(cube_mesh.mesh.size==Vector3.ONE*.6 and is_equal_approx(study.control.surface.mesh.radius,.14),"Earned cube and point retain their sizes")
    check(study.material.get_shader_parameter("repeats")==repeats,"Printed repeat choice reaches the shader")
    check(study.find_children("*","CollisionShape3D",true,false).size()==3,"Cube, plinth and point each have a collider")
    check(study.find_children("*","Camera3D",true,false).is_empty(),"Printed program relies on declared museum camera")
    var meshes:Array=[];var poses:Array=[];var shapes:Array=[]
    for m in study.find_children("*","MeshInstance3D",true,false):meshes.append(m.mesh);poses.append(m.transform)
    for c in study.find_children("*","CollisionShape3D",true,false):shapes.append(c.shape)
    move(Vector3(-.35,1.2,1.2));check(study.amounts.is_equal_approx(Vector3(0,.6,.3)),"X changes only DOTS")
    move(Vector3(.65,.6,1.2));check(study.amounts.is_equal_approx(Vector3(1,0,.3)),"Y changes only RIM")
    move(Vector3(.65,1.2,.9));check(study.amounts.is_equal_approx(Vector3(1,.6,0)),"Z changes only GLOW")
    weights(Vector3(-2,-2,-2));check(study.amounts.is_equal_approx(Vector3.ZERO),"All amounts clamp at zero")
    weights(Vector3(3,3,3));check(study.amounts.is_equal_approx(Vector3.ONE),"All amounts clamp at one")
    weights(Vector3(.4,.5,.6));study.control.action()
    check(study.mode==0 and study.amounts.is_equal_approx(Vector3(.4,.5,.6)) and study.material.get_shader_parameter("amounts")==Vector3.ZERO,"Trigger BASE removes contributions without erasing chosen amounts")
    study.control.action();check(study.mode==1 and study.material.get_shader_parameter("amounts").is_equal_approx(Vector3(.4,.5,.6)),"Trigger COMPOSED restores current amounts")
    view=SubViewport.new();view.size=Vector2i(SIDE,SIDE);view.own_world_3d=true;view.transparent_bg=true;view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
    var env:=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color.BLACK;env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;env.environment.ambient_light_energy=1;view.add_child(env)
    var q:=MeshInstance3D.new();var quad:=QuadMesh.new();quad.size=Vector2(2,2);q.mesh=quad;q.material_override=study.material;view.add_child(q)
    var cam:=Camera3D.new();cam.projection=Camera3D.PROJECTION_ORTHOGONAL;cam.size=2;cam.position=Vector3(0,0,3);view.add_child(cam);cam.make_current()
    weights(Vector3(1,0,0));var dots:=await read();dots.save_png(report.get_base_dir()+"/dots.png")
    var circles:=true
    for y in int(repeats.y):
        for x in int(repeats.x):
            circles=circles and pixel(dots,(Vector2(x,y)+Vector2(.5,.5))/repeats).r-pixel(dots,(Vector2(x,y)+Vector2(.03,.03))/repeats).r>.2
    check(circles,"GPU: every repeated cell contains its circle and surrounding ground")
    weights(Vector3.ZERO);var base:=await read();base.save_png(report.get_base_dir()+"/base.png")
    check(difference(dots,base)>.025,"GPU: DOTS changes the pigment")
    check(absf(pixel(base,Vector2(.5,.5)/repeats).r-pixel(base,Vector2(.03,.03)/repeats).r)<.02,"GPU: zero DOTS gives uniform ground")
    var sphere:=SphereMesh.new();sphere.radius=.9;sphere.height=1.8;sphere.radial_segments=64;sphere.rings=32;q.mesh=sphere;cam.size=2.2
    weights(Vector3.ZERO);var sphere_base:=await read()
    weights(Vector3(0,1,0));var rim:=await read();rim.save_png(report.get_base_dir()+"/rim.png")
    print("RIM_DELTA ",pixel(rim,Vector2(.88,.5)).g-pixel(sphere_base,Vector2(.88,.5)).g)
    check(pixel(rim,Vector2(.88,.5)).g-pixel(sphere_base,Vector2(.88,.5)).g>.12,"GPU: RIM brightens a grazing part of the sphere")
    check(absf(pixel(rim,Vector2(.5,.5)).g-pixel(sphere_base,Vector2(.5,.5)).g)<.015,"GPU: RIM leaves the facing centre unchanged")
    # Tilt a flat UV receiver to isolate viewing angle from texture/moving geometry.
    q.mesh=quad;weights(Vector3(0,1,0));var frontal:=await read();q.rotation.y=1.1;var oblique:=await read()
    check(pixel(oblique,Vector2(.5,.5)).g-pixel(frontal,Vector2(.5,.5)).g>.12,"GPU: turning a face changes its view-dependent rim")
    q.rotation.y=0;q.mesh=sphere
    env.environment.ambient_light_energy=0
    weights(Vector3.ZERO);var dark:=await read()
    check(pixel(dark,Vector2(.5,.5)).r<.01,"GPU: base pigment is dark without incident illumination")
    weights(Vector3(0,0,1));var glow:=await read();glow.save_png(report.get_base_dir()+"/glow.png")
    # The default ground is deliberately dark; require a measurable signal.
    # The missing-glow negative control must still produce zero here.
    check(pixel(glow,Vector2(.5,.5)).r-pixel(dark,Vector2(.5,.5)).r>.03,"GPU: GLOW remains visible without a lamp")
    weights(Vector3(0,1,0));var dark_rim:=await read()
    check(pixel(dark_rim,Vector2(.88,.5)).g>.15,"GPU: rim contribution is also emission")
    # A second material near an emitting body remains unlit in this non-GI viewport.
    q.scale=Vector3.ONE*.6;q.position.x=-.55;cam.size=3
    var neighbour:=MeshInstance3D.new();var nb:=BoxMesh.new();nb.size=Vector3.ONE*.5;neighbour.mesh=nb;neighbour.position=Vector3(.75,0,0)
    var grey:=StandardMaterial3D.new();grey.albedo_color=Color(.6,.6,.6);neighbour.material_override=grey;view.add_child(neighbour)
    weights(Vector3(1,1,1));var lit_self:=await read()
    check(pixel(lit_self,Vector2(.75,.5)).r<.01,"GPU: emission does not illuminate the adjacent grey body in this setup")
    env.environment.ambient_light_energy=1
    var lit_neighbour:=await read()
    check(pixel(lit_neighbour,Vector2(.75,.5)).r>.2,"GPU: the same neighbour sample is visible when real illumination is supplied")
    neighbour.queue_free();q.scale=Vector3.ONE;q.position.x=0;cam.size=2.2;env.environment.ambient_light_energy=1
    weights(Vector3(1,.6,.3));var composed:=await read();composed.save_png(report.get_base_dir()+"/composed.png")
    await create_timer(.15).timeout;var later:=await read()
    check(difference(composed,later)==0,"Fixed view and held inputs produce no time animation")
    cam.size=3;cam.position=Vector3(.4,.25,3);cam.look_at(Vector3.ZERO)
    weights(Vector3.ZERO);var silhouette_a:=await read();weights(Vector3.ONE);var silhouette_b:=await read()
    var coverage:=0;var fixed:=true
    for y in SIDE:
        for x in SIDE:
            var a:float=silhouette_a.get_pixel(x,y).a
            if a>.5:coverage+=1
            fixed=fixed and is_equal_approx(a,silhouette_b.get_pixel(x,y).a)
    check(fixed and coverage>1000 and coverage<SIDE*SIDE*.9,"GPU: composition changes no silhouette")
    var kept:=true;var i:=0
    for m in study.find_children("*","MeshInstance3D",true,false):kept=kept and m.mesh==meshes[i] and m.transform==poses[i];i+=1
    i=0
    for c in study.find_children("*","CollisionShape3D",true,false):kept=kept and c.shape==shapes[i];i+=1
    check(kept,"Material changes retain receiver meshes and collision resources")
    await physics_frame
    var ray:=PhysicsRayQueryParameters3D.create(study.to_global(Vector3(-.6,.9,1)),study.to_global(Vector3(-.6,.9,-1)),1)
    var hit:=study.get_world_3d().direct_space_state.intersect_ray(ray)
    check(not hit.is_empty() and hit.collider==study.cube,"The cube retains its solid boundary")
    weights(Vector3(1,.6,.3));check(study.readout.text.contains("COMPOSED") and study.readout.text.contains("dots 1.00"),"Readout names the comparison and actual chosen values")
    var passed:bool=checks.all(func(c):return c.passed)
    var f:=FileAccess.open(report,FileAccess.WRITE);f.store_string(JSON.stringify({"passed":passed,"checks":checks,"variation":variation,"scope":"Exact printed files; declared diagnostic viewport for GPU isolation, synthetic controls, real collision. Teacher-authored reconstruction; no independent student, headset or human learning claim."},"\t"));f.close()
    study.queue_free();view.queue_free();await process_frame;quit(0 if passed else 1)
