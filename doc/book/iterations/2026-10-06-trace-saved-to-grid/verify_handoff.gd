extends SceneTree

var checks: Array[Dictionary] = []
var failures: Array[String] = []
var world: Node3D
var archive
var expected: Array[Vector3] = [Vector3(0,1.12,0),Vector3(0.33,1.12,0.2),Vector3(0.78,0.93,0.14),Vector3(0.85,0.60,0.11),Vector3(0.1,0.52,0.27),Vector3(-0.6,0.62,-0.16),Vector3(-0.73,1.17,-0.08),Vector3(-0.27,1.37,0.04),Vector3(-0.1,1.0,0.38)]

func _initialize() -> void: call_deferred("run")
func check(ok: bool,id: String,description: String) -> void:
    checks.append({"id":id,"passed":ok,"description":description})
    if not ok: failures.append(id)
func frames(n: int = 6) -> void:
    for i in n:
        await physics_frame
        await process_frame
func values_match(values, target) -> bool:
    if values.size()!=target.size(): return false
    for i in target.size():
        if not Vector3(values[i]).is_equal_approx(Vector3(target[i])): return false
    return true
func make_lesson(path: String) -> Node3D:
    var node: Node3D = load(path).new()
    node.position = Vector3(-3,0.2,4)
    node.rotation.y = -0.6
    world.add_child(node)
    return node
func producer() -> void:
    if FileAccess.file_exists(archive.PATH): DirAccess.remove_absolute(archive.PATH)
    var lesson:=make_lesson("res://trace.gd")
    var controller:=XRController3D.new()
    world.add_child(controller)
    controller.global_position=lesson.point.global_position
    var pickup: Node3D=load("res://addons/godot-xr-tools/functions/function_pickup.gd").new()
    pickup.hand_offset_mode=4
    pickup.ranged_enable=false
    controller.add_child(pickup)
    await frames()
    pickup._update_closest_object()
    check(pickup.closest_object==lesson.point,"save/target","The actual XRTools overlap targets the authored point.")
    pickup._pick_up_object(lesson.point)
    check(lesson.point.is_picked_up(),"save/grab","The point is moved by the real grab driver.")
    for p in expected.slice(1):
        controller.global_position=lesson.to_global(p)
        await frames()
    check(values_match(lesson.positions,expected),"save/record","The saved drawing comes from the held point's actual ordered movement.")
    pickup.drop_object()
    await frames()
    check(FileAccess.file_exists(archive.PATH),"save/release","Releasing the real point writes the archive.")
    var saved: Node3D=archive.load_drawing()
    check(saved!=null,"save/valid","The release produces a loadable saved sculpture.")
    if saved!=null:
        check(values_match(saved.get_meta("positions"),expected),"save/local_data","Saved positions retain local metres, order and values.")
        check(saved.get_child_count()==expected.size()-1,"save/geometry","The existing segments are saved with the data.")
        var unchanged:=true
        for i in saved.get_child_count():
            var a: MeshInstance3D=saved.get_child(i)
            var b: MeshInstance3D=lesson.trail.get_child(i)
            unchanged=unchanged and a.transform.is_equal_approx(b.transform) and is_equal_approx(a.mesh.height,b.mesh.height) and a.material_override.albedo_color.is_equal_approx(b.material_override.albedo_color)
            if not a.transform.is_equal_approx(b.transform) or not is_equal_approx(a.mesh.height,b.mesh.height) or not a.material_override.albedo_color.is_equal_approx(b.material_override.albedo_color):
                print("SEGMENT ",i," stored/live transform ",a.transform," / ",b.transform," height ",a.mesh.height," / ",b.mesh.height," colour ",a.material_override.albedo_color," / ",b.material_override.albedo_color)
        check(unchanged,"save/same_geometry","Saved sculpture has the source segment shapes, transforms and finish.")
        saved.free()
    var digest:=FileAccess.get_sha256(archive.PATH)
    lesson.positions.append(Vector3(9,9,9))
    check(FileAccess.get_sha256(archive.PATH)==digest,"save/snapshot","Later live-array edits do not mutate the saved snapshot.")
    var one: Array[Vector3]=[Vector3.ZERO]
    check(archive.save_drawing(lesson.trail,one)==ERR_INVALID_DATA and FileAccess.get_sha256(archive.PATH)==digest,"save/minimum","One position cannot replace the last valid drawing.")
    lesson.queue_free()
    controller.queue_free()
    await frames()
func consumer(mode: String) -> void:
    var digest:=FileAccess.get_sha256(archive.PATH)
    var path: String="res://grid.gd" if mode=="consume" else "res://"+mode+".gd"
    var lesson:=make_lesson(path)
    await frames()
    check(lesson.sculpture!=null,"load/existing","A fresh Godot process loads the previous process's saved sculpture.")
    if lesson.sculpture==null:
        lesson.queue_free()
        return
    check(values_match(lesson.positions,expected),"load/record","Grid receives the original hand-movement values and order.")
    check(lesson.find_children("*","RigidBody3D",true,false).is_empty(),"load/no_new_point","Grid contains no new point or input body.")
    check(lesson.sculpture.get_child_count()==expected.size()-1,"load/segments","Grid instantiates the saved geometry rather than another gesture.")
    var transforms: Array[Transform3D]=[]
    var lengths: Array[float]=[]
    for segment in lesson.sculpture.get_children():
        transforms.append(segment.transform)
        lengths.append(segment.mesh.height)
    for pitch in [0.25,0.5,0.25]:
        var prefix: String="pitch/"+str(checks.size())
        lesson.grid_step=pitch
        lesson._place_on_grid()
        await frames()
        check(values_match(lesson.positions,expected),prefix+"/source","Grid's source array never changes.")
        var original_ok:=true
        var independent:=true
        var geometry_ok:=true
        for i in lengths.size():
            var original: MeshInstance3D=lesson.sculpture.get_child(i)
            var copy: MeshInstance3D=lesson.grid_copy.get_child(i)
            original_ok=original_ok and original.transform.is_equal_approx(transforms[i]) and is_equal_approx(original.mesh.height,lengths[i]) and original.material_override.albedo_color.is_equal_approx(Color(0.98,0.70,0.82))
            independent=independent and copy.mesh!=original.mesh and copy.material_override!=original.material_override
            var a:=expected[i].snapped(Vector3.ONE*pitch)
            var b:=expected[i+1].snapped(Vector3.ONE*pitch)
            if mode=="flat_y": a.y=0;b.y=0
            geometry_ok=geometry_ok and copy.visible==(not a.is_equal_approx(b))
            if copy.visible:
                var half: float=copy.mesh.height*0.5
                geometry_ok=geometry_ok and copy.to_global(Vector3(0,-half,0)).distance_to(lesson.to_global(a))<0.001
                geometry_ok=geometry_ok and copy.to_global(Vector3(0,half,0)).distance_to(lesson.to_global(b))<0.001
        check(original_ok,prefix+"/sculpture","The original sculpture retains every transform, length and pink finish.")
        check(independent,prefix+"/ownership","The altered copy owns independent geometry and material resources.")
        check(geometry_ok,prefix+"/geometry","Copied segments reach the independently expected grid positions.")
        check(FileAccess.get_sha256(archive.PATH)==digest,prefix+"/file","Grid never rewrites the saved file.")
    if mode=="consume":
        var event:=InputEventAction.new()
        event.action="ui_accept"; event.pressed=true
        Input.parse_input_event(event)
        await frames()
        event.pressed=false; Input.parse_input_event(event)
        check(lesson.grid_step==0.5,"input/pitch","Desktop comparison switches spacing without a new drawing.")
    lesson.queue_free()
    await frames()
    var reloaded: Node3D=archive.load_drawing()
    check(reloaded!=null and values_match(reloaded.get_meta("positions"),expected),"load/again","The saved record remains available after Grid closes.")
    if reloaded!=null:reloaded.free()
func empty() -> void:
    if FileAccess.file_exists(archive.PATH): DirAccess.remove_absolute(archive.PATH)
    var lesson:=make_lesson("res://grid.gd")
    await frames()
    check(lesson.sculpture==null and lesson.grid_copy==null,"empty/no_invention","No saved drawing produces no fabricated sculpture.")
    check(lesson.readout.text.contains("Trace"),"empty/direction","The student is told to draw and save in Trace.")
    lesson.queue_free()
    await frames()
func run() -> void:
    world=Node3D.new();root.add_child(world)
    archive=load("res://trace_archive.gd")
    var args:=OS.get_cmdline_user_args()
    if args[1]=="produce": await producer()
    elif args[1]=="empty": await empty()
    else: await consumer(args[1])
    FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failure_ids":failures},"  "))
    print("SAVED TRACE ",args[1],": ",checks.size()," checks; ",failures)
    quit(0 if failures.is_empty() else 1)
