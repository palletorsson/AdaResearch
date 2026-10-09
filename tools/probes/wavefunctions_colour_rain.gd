extends "res://tools/probes/wavefunctions_surface_crossing.gd"

var rain_contacts: Array = []

func landing_checks() -> void:
    await super.landing_checks()
    var rain := find_scene("/colorballs.gd")
    var landscape := find_scene("/algorithms/wavefunctions/sine_space/SineSpace.gd")
    check("Colour's existing ball artifact is installed",rain!=null)
    if rain==null or landscape==null:return
    var floor_node: Node3D = landscape.walk_floor
    check("sine floor widened to fourteen metres",is_equal_approx(landscape.walk_width,14.0))
    check("rain has a bounded pool of 48 real physics balls",rain.ball_bodies.size()==48 and rain.ball_bodies.all(func(b):return b is RigidBody3D))
    check("rain spheres are large enough to read across floor",is_equal_approx(rain.multimesh.mesh.radius,0.22))
    check("rendered count equals physics count",rain.multimesh.instance_count==rain.ball_bodies.size())
    check("rain has saturated colour palette",rain.get_current_palette_name()=="Dance Floor Energy")
    check("no competing camera or room light",rain.get_children().all(func(c):return not c is Camera3D and not c is Light3D))
    var default_balls = load("res://algorithms/color/colorballs/colorballs.gd").new()
    check("other colorballs retain small radius and no rain",not default_balls._sine_rain and is_equal_approx(default_balls._ball_radius,0.1))
    default_balls.free()
    var ids: Array = rain.ball_bodies.map(func(b):return b.get_instance_id())
    var initial_recycles: int = rain._rain_next
    await create_timer(1.25).timeout
    check("rain continues after entry",rain._rain_next>=initial_recycles+3)
    check("continued rain reuses the same bodies",ids==rain.ball_bodies.map(func(b):return b.get_instance_id()))
    # Stop only the recycler while measuring a particular free fall. Physics
    # and rendering continue, including collision with the actual wave floor.
    rain.set_physics_process(false)
    var body: RigidBody3D = rain.ball_bodies[0]
    body.contact_monitor=true
    body.max_contacts_reported=8
    body.body_entered.connect(func(other):rain_contacts.append(other))
    body.global_position=floor_node.to_global(Vector3(0.6,3.6,0.35))
    body.linear_velocity=Vector3.ZERO;body.angular_velocity=Vector3.ZERO;body.sleeping=false
    var drop_start := body.global_position
    var lowest := drop_start.y
    var rebound := false
    for frame in range(150):
        await physics_frame
        lowest=minf(lowest,body.global_position.y)
        if not rain_contacts.is_empty() and body.linear_velocity.y>0.3:rebound=true
    check("a dropped ball touches the actual sine collider",rain_contacts.any(func(c):return is_instance_valid(c) and floor_node.is_ancestor_of(c)))
    check("gravity makes ball descend before contact",lowest<drop_start.y-2.0)
    check("ball bounces after contact",rebound)
    check("relief redirects a vertical drop sideways",Vector2(body.global_position.x-drop_start.x,body.global_position.z-drop_start.z).length()>0.15)
    observations.ball_drop={"start":xyz(drop_start),"end":xyz(body.global_position),"lowest_y":lowest,"contacts":rain_contacts.filter(func(c):return is_instance_valid(c)).map(func(c):return str(c.get_path())),"bounce":rebound}
    rain._recycle_rain_ball(0)
    var local_drop: Vector3 = rain.to_local(body.global_position)
    check("recycled drop uses artifact local coordinates",local_drop.y>=3.6 and local_drop.y<=4.1 and absf(local_drop.x)<=6 and absf(local_drop.z)<=7.5)
    rain._sync_multimesh_transforms()
    check("multimesh follows the recycled physics body",(rain.multimesh_instance.global_transform*rain.multimesh.get_instance_transform(0)).origin.distance_to(body.global_position)<0.0001)
    rain.set_physics_process(true)
    body.global_position=rain.to_global(Vector3(0,-3,0))
    await tick();await tick()
    check("escaped body returns above this hall",rain.to_local(body.global_position).y>3.0)
    var origin := hall.global_position+Vector3(0,0,4)
    await snapshot("rain-eye",origin+Vector3(5,1.8,20),origin+Vector3(10,0.8,29),80)
    await snapshot("rain-above",origin+Vector3(6,9,17),origin+Vector3(10,0.2,27),76)
    observations.scope="Native museum/Jolt: widened wave crossing, walls, real falling and rebounding colour balls, persistent bounded pool. No headset comfort or independent student claim."
