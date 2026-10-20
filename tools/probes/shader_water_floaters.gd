extends "res://tools/probes/shader_water_museum.gd"

func wait_physics(seconds: float) -> void:
    for i in range(ceili(seconds * 60)):
        await physics_frame

func place(body: RigidBody3D, at: Vector3, basis: Basis = Basis.IDENTITY) -> void:
    body.freeze = true
    body.global_transform = Transform3D(stage.global_basis * basis, stage.to_global(at))
    body.linear_velocity = Vector3.ZERO
    body.angular_velocity = Vector3.ZERO
    await physics_frame
    body.freeze = false
    await physics_frame

func run() -> void:
    root.size = Vector2i(1800,1200); root.msaa_3d = Viewport.MSAA_4X
    create_timer(130).timeout.connect(func():quit(98))
    var spec:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]));output=spec.run
    museum=load(output+"museum_snapshot.tscn").instantiate();museum.set("_costume_on",false);museum.set("EM_CONTROL",output+"control.json");museum.set("_hand_path",output+"necklace_hand.json");museum.set("_overrides_path",output+"em_overrides.json")
    load("res://doc/book/studies/shaders-lineage/water_museum.gd").configure(museum,output+"float_control.json")
    museum.set("plan_file",output+"plan.json");root.add_child(museum);current_scene=museum
    while not bool(museum.get("_museum_core_ready")):await process_frame
    museum.set("_lazy_pending",0);museum.set_process(false);museum.set_physics_process(false);museum.call("flush_stamps");await create_timer(1).timeout
    var old:Camera3D=museum.get("_cam")
    if old:
        for timer in old.find_children("*","Timer",true,false):timer.stop()
    for child in museum.get_children():
        if child is Node3D and str(child.get_meta("em_map",""))=="Shader_09_FBM":hall=child
    check(hall!=null,"Actual Water museum hall loads")
    if hall==null:quit(1);return
    var basin:Node3D
    for node in hall.find_children("*","Node3D",true,false):
        if node.scene_file_path.ends_with("/basin_water.tscn"):basin=node
    stage=basin.get("_study");origin=basin.global_position-hall.global_basis*Vector3(12.5,0,4.5)
    camera=Camera3D.new();root.add_child(camera);museum.get("_player").hide()
    check(stage.floaters.size()==7,"Six balls and one swim ring exist in the basin")
    var ball=stage.floaters[0];var ring=stage.floaters[-1]
    check(stage.floaters.all(func(b):return b is RigidBody3D and b.has_method("pick_up") and not b.freeze and b.collision_layer==4),"All toys are physical pickable bodies")
    check(ring.samples.size()==8 and ring.find_children("*","CollisionShape3D",true,false).size()==16,"Ring uses distributed buoyancy and an open compound collider")
    check(not stage.playing,"Existing held phase remains the opening state")
    await wait_physics(7)
    var afloat:=true
    for b in stage.floaters:
        var height:float=stage.height_world(b.global_position)
        var gap:float=b.global_position.y-height
        print("FLOAT ",b.name," gap=",gap," speed=",b.linear_velocity.length())
        afloat=afloat and absf(gap)<b.radius*.8 and b.linear_velocity.length()<.35
    check(afloat,"Released toys settle around the sampled water height without sinking")
    check(absf(ring.global_basis.y.dot(Vector3.UP))>.92,"Ring settles approximately horizontal")
    var ray:=PhysicsRayQueryParameters3D.create(ring.global_position+Vector3.UP*.5,ring.global_position-Vector3.UP*.5,4)
    check(hall.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(),"A ray passes through the ring's open centre")
    ray=PhysicsRayQueryParameters3D.create(ring.to_global(Vector3(.64,.5,0)),ring.to_global(Vector3(.64,-.5,0)),4)
    check(not hall.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(),"The same ray hits the ring tube")
    var initial:Vector3=ball.global_position
    ball.apply_central_impulse(stage.global_basis*Vector3(.28,-.14,0))
    await wait_physics(.7)
    check(ball.global_position.distance_to(initial)>.15,"A physical push moves a floating ball")
    await wait_physics(3)
    check(absf(ball.global_position.y-stage.height_world(ball.global_position))<ball.radius,"Ball returns to floating after an impulse")
    # Submerge/tip the ring, then let distributed forces recover it.
    await place(ring,Vector3(2.6,-.8,-7.4),Basis(Vector3.FORWARD,.65))
    await wait_physics(6)
    check(absf(ring.global_position.y-stage.height_world(ring.global_position))<.17 and absf(ring.global_basis.y.dot(Vector3.UP))>.9,"Tipped, submerged ring rises and rights itself")
    # Synthetic XR uses the actual pickup/release driver.
    var xr:=XROrigin3D.new();root.add_child(xr)
    var hand:=XRController3D.new();xr.add_child(hand)
    var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup)
    hand.global_transform=ball.global_transform;ball.pick_up(pickup);await tick()
    hand.global_position=stage.to_global(Vector3(2.1,1,-4.2));await tick()
    check(ball.is_picked_up() and ball.global_position.distance_to(hand.global_position)<.1,"Simulated hand lifts the actual ball")
    stage.act("RESET");await tick()
    check(ball.is_picked_up() and ball.global_position.distance_to(hand.global_position)<.1,"RESET leaves held toys in the hand")
    ball.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await wait_physics(5)
    check(not ball.is_picked_up() and not ball.freeze and absf(ball.global_position.y-stage.height_world(ball.global_position))<.2,"Released ball falls then floats again")
    hand.global_transform=ring.global_transform;ring.pick_up(pickup);await tick()
    hand.global_position=stage.to_global(Vector3(2.8,.8,-7.4));await tick()
    check(ring.is_picked_up() and ring.global_position.distance_to(hand.global_position)<.1,"Swim ring also follows the hand")
    ring.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await wait_physics(4);xr.queue_free()
    check(not ring.freeze and not ring.is_picked_up(),"Ring resumes dynamic physics on release")
    stage.act("COLOUR");await wait_physics(4)
    check(absf(ball.global_position.y-stage.surface.global_position.y)<.12,"Colour mode buoyancy follows the flat visible surface")
    stage.act("NORMAL");check(is_equal_approx(stage.height_world(ball.global_position),stage.surface.global_position.y),"Normal-only mode also retains flat support level")
    stage.act("HEIGHT");stage.act("TIME")
    var old_phase:float=stage.phase;var old_height:float=stage.height_world(ball.global_position)
    await wait_physics(4)
    check(stage.phase>old_phase and absf(stage.height_world(ball.global_position)-old_height)>.002,"TIME changes the buoyancy sample with the rendered field parameters")
    check(absf(ball.global_position.y-stage.height_world(ball.global_position))<.22,"Ball remains afloat while the field moves")
    stage.act("TIME");var held:float=stage.phase;await wait_physics(.25)
    check(is_equal_approx(stage.phase,held),"TIME holds the field without freezing rigid-body simulation")
    await place(ball,Vector3(6.6,1.2,-4.2));await wait_physics(.2)
    check(not stage.contains_water(ball.global_position) and ball.linear_velocity.y<-.5,"Outside the basin there is ordinary gravity, not buoyancy")
    stage.act("RESET");await wait_physics(6)
    check(stage.floaters.all(func(b):return Vector2(stage.to_local(b.global_position).x-b.home.x,stage.to_local(b.global_position).z-b.home.z).length()<.4),"RESET restores toy positions within the pool")
    check(stage.surface.find_children("*","CollisionObject3D",true,false).is_empty(),"Buoyancy adds no water collider")
    route_check()
    await photo("pool",Vector3(4.6,2.1,1.7),Vector3(0,-.05,-7.4),81)
    await photo("ring",Vector3(.45,1.7,-5.7),Vector3(2.05,-.15,-7.2),76)
    await photo("overhead",Vector3(6.7,7.2,-.5),Vector3(0,-.25,-8),83)
    # Existing shader modes still pass their GPU checks after adding props.
    await pixels()
    await defaults_check()
    var passed:bool=checks.all(func(c):return c.passed)
    var file:=FileAccess.open(output+"report.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"passed":passed,"checks":checks,"scope":"Actual museum, Jolt dynamics, synthetic XR pickup/release, shader GPU regression and bridge route. Approximate CPU buoyancy uses the same field recipe; sine-hash CPU/GPU equality is not claimed. No headset, fluid or splash simulation."},"\t"));file.close()
    quit(0 if passed else 1)
