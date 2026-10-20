extends SceneTree
## Parent's regression check of supplied support, not an independent learner run.
var checks: Array = []
func _initialize() -> void: call_deferred("run")
func check(label: String, passed: bool) -> void:
    checks.append({"test":label,"passed":passed})
    print("PASS " if passed else "FAIL ",label)
func run() -> void:
    create_timer(115).timeout.connect(func(): quit(98))
    root.size=Vector2i(1400,1000)
    var spec=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
    var output:String=spec.run
    var launcher=load("res://doc/book/studies/shaders-lineage/shaping_museum.gd")
    var museum=load(output+"museum_snapshot.tscn").instantiate()
    var saved:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(output+"control.json"))
    saved.merge({"first_chapter":"color","first_map":"Color","resume_eye":[1,2,3],"resume_hall":"Color","travel":true},true)
    var file:=FileAccess.open(output+"saved-travel.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(saved));file.close()
    var saved_text:=FileAccess.get_file_as_string(output+"saved-travel.json")
    museum.set("EM_CONTROL",output+"saved-travel.json")
    launcher.configure(museum,output+"lesson-control.json")
    museum.set("_hand_path",output+"necklace_hand.json")
    museum.set("_overrides_path",output+"em_overrides.json")
    museum.set("plan_file",output+"plan.json")
    museum.set("_costume_on",false)
    root.add_child(museum);current_scene=museum
    while not bool(museum.get("_museum_core_ready")): await process_frame
    museum.set("_lazy_pending",0);museum.set_process(false);museum.set_physics_process(false)
    museum.call("flush_stamps")
    var hall:Node3D
    for node in museum.get_children():
        if node is Node3D and str(node.get_meta("em_map",""))=="Shader_01_Shaping": hall=node
    check("Saved travel to Colour does not prevent Shaping hall loading",hall!=null)
    if hall!=null:
        var study:Node3D=launcher.mount(hall,launcher.LESSON)
        for i in range(10): await process_frame
        check("Supplied mount creates both learner receivers",study.get("receivers").size()==2)
        check("Initial local height gives radius .30",is_equal_approx(float(study.get("radius")),.30))
        check("Map position accounts for four-metre vestibule",study.position.is_equal_approx(Vector3(14,0,9)))
        var camera:=Camera3D.new();root.add_child(camera)
        camera.global_position=study.to_global(Vector3(0,1.7,3.1))
        camera.look_at(study.to_global(Vector3(0,1.6,.45)));camera.fov=73
        var old= museum.get("_cam")
        if old:
            for timer in old.find_children("*","Timer",true,false):timer.stop()
        museum.get("_player").hide()
        for i in range(8): camera.make_current();await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(output+"shaping-after-launch-fix.png")
    check("Original copied travel remains byte-for-byte unchanged",FileAccess.get_file_as_string(output+"saved-travel.json")==saved_text)
    var passed:bool=checks.all(func(c):return c.passed)
    file=FileAccess.open(output+"report.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"passed":passed,"checks":checks,"scope":"Fresh native museum regression of supplied configure/mount support with stale-travel fixture. Output paths isolated. No physical headset or independent learner claim."},"  "));file.close()
    quit(0 if passed else 1)
