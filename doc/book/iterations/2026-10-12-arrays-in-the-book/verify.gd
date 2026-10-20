extends SceneTree

var world := Node3D.new()
var checks: Array[Dictionary] = []
var failures: Array[String] = []
var mode := "normal"
var destination := ""
var heard: Array[int] = []

func _initialize() -> void:
    var args := OS.get_cmdline_user_args()
    mode = args[0]
    destination = args[1]
    run.call_deferred()

func check(id: String, result: bool) -> void:
    checks.append({"id": id, "passed": result})
    if not result:
        failures.append(id)
        print("FAIL ", id)

func make(hall: String, variant := "base", properties := {}) -> Node3D:
    var node: Node3D = load("res://" + hall + "/" + variant + "/lesson.gd").new()
    for key in properties:
        node.set(key, properties[key])
    node.set_process(false)
    world.add_child(node)
    node.set_process(false)
    return node

func actor(at: Vector3, group_name := "player_body", layer := 524288) -> CharacterBody3D:
    var body := CharacterBody3D.new()
    body.collision_layer = layer
    body.collision_mask = 1
    if not group_name.is_empty(): body.add_to_group(group_name)
    var shape := CapsuleShape3D.new()
    shape.radius = 0.15
    shape.height = 0.6
    var collision := CollisionShape3D.new()
    collision.shape = shape
    body.add_child(collision)
    world.add_child(body)
    body.global_position = at
    return body

func settle() -> void:
    for i in 5:
        await physics_frame
        await process_frame

func volume() -> void:
    for variant in ["base", "spaced", "choice"]:
        var s := make("Tutorial_3D", variant)
        check("volume/"+variant+"/layers", s.values.size() == 4)
        var count := 0
        var positions := true
        var identities: Array[int] = []
        for y in 4:
            for z in 4:
                for x in 4:
                    var value: int = s.values[y][z][x]
                    var expected := 0 if Vector3i(x,y,z) == Vector3i(1,0,2) else 1
                    check("volume/"+variant+"/value_%d_%d_%d" % [x,y,z], value==expected)
                    if value == 1:
                        count += 1
                        var cube: MeshInstance3D = s.cubes[y][z][x]
                        positions = positions and cube.position.is_equal_approx(Vector3(x*s.spacing, 0.8+y*s.spacing, z*s.spacing))
                        positions = positions and not identities.has(cube.get_instance_id())
                        identities.append(cube.get_instance_id())
        check("volume/"+variant+"/63_cubes_and_distinct_positions", count==63 and positions)
        var selected: Vector3i = s.selected
        check("volume/"+variant+"/marker", s.marker.position.is_equal_approx(s.place(selected.x,selected.y,selected.z)))
        s.collect(-1,0,0); s.collect(0,-1,0); s.collect(0,0,-1)
        s.collect(4,0,0); s.collect(0,4,0); s.collect(0,0,4)
        check("volume/"+variant+"/bounds", s.values[0][0][0] == 1)
        var before: Array = s.plane.duplicate(true)
        s.collect(0,0,1)
        check("volume/"+variant+"/source_plane_retained", s.plane==before)
        check("volume/"+variant+"/neighbours_retained", s.values[1][1][0]==1 and s.values[0][0][0]==1 and s.values[0][1][1]==1)
        s.collect(0,0,1)
        check("volume/"+variant+"/retained_slot", s.values[0][1].size()==4 and s.cubes[0][1][0]==null)
        await process_frame
        s.free()
    var study := make("Tutorial_3D")
    var prop := actor(study.to_global(study.place(1,2,0)), "", 524288)
    await settle()
    check("volume/props_do_not_collect", study.values[2][0][1]==1)
    prop.free()
    var visitor := actor(study.to_global(study.place(1,2,0)))
    await settle()
    check("volume/physical_xyz_binding", study.values[2][0][1]==0 and study.cubes[2][0][1]==null and study.values[1][0][2]==1)
    check("volume/marker_survives", is_instance_valid(study.marker) and study.readout.text.ends_with("0"))
    visitor.free(); study.free()

func image_tests() -> void:
    var Pattern = load("res://Tutorial_Tiling_Floor/base/pattern_image.gd")
    var p = Pattern.new()
    check("pattern/known_addresses", p.turn_at(1,0)==1 and p.turn_at(2,0)==2 and p.turn_at(3,1)==0)
    var original: Image = p.make()
    p.exception=true
    var changed: Image = p.make()
    var outside := true
    var changes := 0
    for y in original.get_height():
        for x in original.get_width():
            if original.get_pixel(x,y)!=changed.get_pixel(x,y):
                changes += 1
                outside = outside and x>=32 and x<64 and y>=64 and y<96
    check("pattern/local_exception", outside and changes>0)
    p.exception=false
    p.columns=8; p.rows=8
    var large: Image = p.make()
    check("pattern/expanded_keeps_corner", large.get_region(Rect2i(0,0,128,128)).get_data()==original.get_data())
    var ref = load("res://reference_pattern.gd")
    check("pattern/matches_installed_quarter_rule", original.get_data()==ref.image_for(2,0,false,4,4,32).get_data())
    for variant in ["base","exception","expanded","columns"]:
        var s := make("Tutorial_Tiling_Floor",variant)
        check("floor/"+variant+"/image_dimensions", s.image.get_width()==s.columns*32 and s.image.get_height()==s.rows*32)
        var file := Image.new()
        var error := file.load(s.saved_path)
        check("floor/"+variant+"/exact_saved_pixels", error==OK and file.get_data()==s.image.get_data())
        var a: MeshInstance3D=s.get_child(0)
        var b: MeshInstance3D=s.get_child(1)
        check("floor/"+variant+"/separate_images", a.material_override.albedo_texture!=b.material_override.albedo_texture)
        check("floor/"+variant+"/continuous_supplied_floor", a.get_child_count()==0 and b.get_child_count()==0)
        if variant=="columns":
            var q=load("res://Tutorial_Tiling_Floor/columns/pattern_image.gd").new()
            check("floor/columns/exercise", q.turn_at(1,0)==1 and q.turn_at(1,3)==1 and q.turn_at(2,0)==2)
        s.free()
    # Leave the learner's selected exception result on disk for the next process.
    var selected := make("Tutorial_Tiling_Floor","exception")
    var receipt := {"pixels": selected.image.get_data().hex_encode(), "size": [selected.image.get_width(),selected.image.get_height()]}
    FileAccess.open("user://floor-receipt.json",FileAccess.WRITE).store_string(JSON.stringify(receipt))
    selected.free()

func wall_tests() -> void:
    var receipt = JSON.parse_string(FileAccess.get_file_as_string("user://floor-receipt.json"))
    var file_before := FileAccess.get_file_as_bytes("user://ada_array_pattern.png")
    for variant in ["base","turned","choice"]:
        var s := make("Tutorial_Tiling_Walls",variant)
        check("wall/"+variant+"/actual_prior_process_pixels", s.image.get_data().hex_encode()==receipt.pixels)
        check("wall/"+variant+"/solid_matches_backing", s.panel.get_child(0).mesh.size==s.panel.get_child(1).shape.size)
        check("wall/"+variant+"/children_share_transform", s.panel.get_child(0).global_transform.is_equal_approx(s.panel.get_child(1).global_transform))
        check("wall/"+variant+"/no_saved_file_mutation", FileAccess.get_file_as_bytes("user://ada_array_pattern.png")==file_before)
        var at := s.to_global(Vector3(1.0,1.5,2))
        var visitor := actor(at)
        await settle()
        var hit := visitor.test_move(visitor.global_transform,world.global_basis*Vector3(0,0,-4))
        if variant=="base": check("wall/closed_blocks",hit)
        if variant=="turned": check("wall/turned_route_passes",not hit)
        var front: Vector3=s.panel.to_global(Vector3(0,0,2))
        visitor.global_position=front
        await settle()
        check("wall/"+variant+"/new_front_still_solid",visitor.test_move(visitor.global_transform,s.panel.global_basis*Vector3(0,0,-4)))
        visitor.free(); s.free()
    var missing := make("Tutorial_Tiling_Walls","base",{"saved_path":"user://absent-image.png"})
    check("wall/missing_is_visible_not_invented",missing.panel==null and missing.get_child(0) is Label3D)
    missing.free()

func on_note(index: int) -> void:
    heard.append(index)

func disco_tests() -> void:
    for variant in ["base","moved","slow","choice"]:
        var s := make("Tutorial_Disco",variant)
        heard.clear(); s.note_played.connect(on_note)
        check("disco/"+variant+"/held_initially",s.step==-1 and not s.playhead.visible and not s.score_running and not s.floor_running)
        var visitor := Node3D.new(); visitor.add_to_group("player_body"); world.add_child(visitor)
        var snapshot: Array=s.score.duplicate()
        for i in s.score.size(): s._on_control(visitor,3)
        var expected: Array[int]=[]
        for i in s.score.size():
            if s.score[i]: expected.append(i)
        check("disco/"+variant+"/step_order",heard==expected and s.step==7)
        s._on_control(visitor,3)
        check("disco/"+variant+"/wrap",s.step==0)
        check("disco/"+variant+"/score_preserved",s.score==snapshot)
        var before: Array=[]
        var materials: Array[int]=[]
        for x in 4:
            for z in 4:
                before.append(s.tiles[x][z].position)
                materials.append(s.tiles[x][z].material_override.get_instance_id())
        s._on_control(visitor,1)
        check("disco/"+variant+"/single_floor_step",s.phase==1 and s.step==0)
        var fixed := true; var n:=0; var distinct:=true
        for x in 4:
            for z in 4:
                fixed=fixed and s.tiles[x][z].position==before[n]
                for j in n: distinct=distinct and materials[j]!=materials[n]
                n+=1
        check("disco/"+variant+"/fixed_addresses_owned_materials",fixed and distinct)
        s.floor_running=true; s.score_running=false
        s.advance(0.625)
        check("disco/"+variant+"/floor_alone",s.phase==0 and s.step==0 and is_equal_approx(s.floor_elapsed,0.125))
        s.floor_running=false; s.score_running=true
        var duration: float=60.0/s.bpm/4.0
        s.advance(duration*1.5)
        check("disco/"+variant+"/score_alone_remainder",s.step==1 and s.phase==0 and is_equal_approx(s.score_elapsed,duration*0.5))
        s.score_running=false; s.advance(2.0)
        check("disco/"+variant+"/pause_retains_fraction",is_equal_approx(s.score_elapsed,duration*0.5))
        s.score_running=true; s.advance(duration*0.75)
        check("disco/"+variant+"/resume",s.step==2 and is_equal_approx(s.score_elapsed,duration*0.25))
        visitor.free(); s.free()
    var stalled:=make("Tutorial_Disco")
    heard.clear(); stalled.note_played.connect(on_note)
    stalled.score_running=true
    stalled.advance(0.65625)
    check("disco/stall_skips_sound_burst",stalled.step==4 and heard==[4] and is_equal_approx(stalled.score_elapsed,0.03125))
    stalled.free()
    for fps in [30,120]:
        var s:=make("Tutorial_Disco")
        s.score_running=true; s.floor_running=true
        for frame in fps*2: s.advance(1.0/fps)
        s.advance(0.01)
        check("disco/fps_"+str(fps),s.step==7 and s.phase==0 and abs(s.score_elapsed-0.01)<0.00001)
        s.free()
    var active:=make("Tutorial_Disco")
    var prop:=actor(active.to_global(Vector3(0,0.4,2.3)),"",524288)
    await settle()
    check("disco/prop_not_control",not active.floor_running)
    prop.free()
    var body:=actor(active.to_global(Vector3(0,0.4,2.3)))
    await settle()
    check("disco/native_control",active.floor_running and not active.score_running)
    body.free(); active.free()
    var Clip=load("res://Tutorial_Disco/base/click_sound.gd")
    var clip: AudioStreamWAV=Clip.make()
    var signed_sum:=0
    for byte in clip.data: signed_sum+=byte if byte<128 else byte-256
    check("sound/short_signed_pcm",clip.data.size()==1323 and clip.mix_rate==22050 and abs(float(signed_sum)/1323)<1 and clip.data[-1]==0)

func fault() -> void:
    if mode=="volume_axis":
        var s:=make("Tutorial_3D")
        check("fault/plane_conversion",s.values[0][2][1]==0 and s.values[0][1][2]==1)
        s.free()
    elif mode=="volume_binding":
        var s:=make("Tutorial_3D")
        var b:=actor(s.to_global(s.place(1,2,0)))
        await settle()
        check("fault/physical_xyz",s.values[2][0][1]==0 and s.values[0][2][1]==0)
        b.free(); s.free()
    elif mode=="pattern_exception":
        var p=load("res://Tutorial_Tiling_Floor/base/pattern_image.gd").new()
        p.exception=true
        check("fault/exception_local",p.turn_at(0,0)==0 and p.turn_at(1,2)==0)
    elif mode=="pattern_rule":
        var p=load("res://Tutorial_Tiling_Floor/base/pattern_image.gd").new()
        check("fault/quarter_turn_range",p.turn_at(2,0)==2 and p.turn_at(3,0)==3)
    elif mode=="wall_collision":
        var s:=make("Tutorial_Tiling_Walls")
        var b:=actor(s.to_global(Vector3(0,1.5,2)))
        await settle()
        check("fault/wall_is_solid",b.test_move(b.global_transform,world.global_basis*Vector3(0,0,-4)))
        b.free(); s.free()
    elif mode=="wall_load":
        var s:=make("Tutorial_Tiling_Walls")
        var receipt=JSON.parse_string(FileAccess.get_file_as_string("user://floor-receipt.json"))
        check("fault/keeps_saved_pixels",s.image.get_data().hex_encode()==receipt.pixels)
        s.free()
    elif mode=="disco_remainder":
        var s:=make("Tutorial_Disco")
        s.score_running=true; s.advance(0.1875)
        check("fault/elapsed_fraction",is_equal_approx(s.score_elapsed,0.0625))
        s.free()
    elif mode=="disco_coupled":
        var s:=make("Tutorial_Disco")
        s.floor_running=true; s.advance(0.5)
        check("fault/clocks_independent",s.step==-1)
        s.free()
    elif mode=="disco_stall":
        var s:=make("Tutorial_Disco")
        s.score_running=true; s.advance(0.65625)
        check("fault/elapsed_visits",s.step==4)
        s.free()

func run() -> void:
    root.add_child(world)
    world.position=Vector3(7,0,-3)
    world.rotation.y=0.31
    if mode=="normal":
        await volume()
        image_tests()
        await disco_tests()
    elif mode=="walls":
        await wall_tests()
    else:
        await fault()
    world.free()
    await process_frame
    FileAccess.open(destination,FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failure_ids":failures},"  "))
    print("ARRAYS ",mode," ",checks.size()," checks; failures ",failures.size())
    quit(0 if failures.is_empty() else 1)
