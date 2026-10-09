extends "res://tools/probes/transformation_encounters.gd"

const BASE := "res://doc/book/iterations/2026-10-06-trace-saved-to-grid/"
const BACKUP := "res://ada_run/encounter_pilot/learner_trace_backup.scn"
const FLAG := "res://ada_run/encounter_pilot/learner_trace_backup.txt"

func landing_checks() -> void:
    museum.flush_stamps()
    await create_timer(0.8).timeout
    var archive=load(BASE+"trace_archive.gd")
    var producer: bool=map_id=="Point_Trace"
    if producer:
        var existed: bool=FileAccess.file_exists(archive.PATH)
        FileAccess.open(FLAG,FileAccess.WRITE).store_string("restore" if existed else "remove")
        if existed:FileAccess.open(BACKUP,FileAccess.WRITE).store_buffer(FileAccess.get_file_as_bytes(archive.PATH))
    var study: Node3D=load(BASE+("trace/trace.gd" if producer else "grid/grid.gd")).new()
    study.name="PointStudy"
    study.position=Vector3(8.5,0,8.5)
    hall.add_child(study)
    await create_timer(0.3).timeout
    check("study belongs to requested museum hall",study.get_parent()==hall)
    check("workplace has actual museum floor",not floor_at(study.global_position).is_empty())
    var player: Node3D=museum.get("_player")
    if player!=null:player.visible=false
    if producer:
        var controller:=XRController3D.new()
        root.add_child(controller)
        controller.global_position=study.point.global_position
        var pickup: Node3D=load("res://addons/godot-xr-tools/functions/function_pickup.gd").new()
        pickup.hand_offset_mode=4;pickup.ranged_enable=false
        controller.add_child(pickup)
        await create_timer(0.25).timeout
        pickup._update_closest_object();pickup._pick_up_object(study.point)
        check("real grab driver holds the Trace point",study.point.is_picked_up())
        for p in [Vector3(0.33,1.12,0.2),Vector3(0.78,0.93,0.14),Vector3(0.85,0.60,0.11),Vector3(0.1,0.52,0.27),Vector3(-0.6,0.62,-0.16),Vector3(-0.73,1.17,-0.08),Vector3(-0.27,1.37,0.04),Vector3(-0.1,1.0,0.38)]:
            controller.global_position=study.to_global(p)
            await create_timer(0.15).timeout
        pickup.drop_object()
        await create_timer(0.25).timeout
        var saved: Node3D=archive.load_drawing()
        check("release saves nine positions and eight existing segments",saved!=null and saved.get_meta("positions").size()==9 and saved.get_child_count()==8)
        if saved!=null:saved.free()
        observations["record_count"]=study.positions.size()
        observations["archive_sha256"]=FileAccess.get_sha256(archive.PATH)
        await snapshot("museum-trace-saved",study.to_global(Vector3(-0.3,1.65,-2.4)),study.to_global(Vector3(0,1.22,0)),68)
        await snapshot("museum-trace-side",study.to_global(Vector3(-2.4,1.65,-0.3)),study.to_global(Vector3(0,1.22,0)),68)
    else:
        check("Grid receives the saved sculpture",study.sculpture!=null)
        if study.sculpture==null:return
        check("Grid has the nine saved positions and eight original segments",study.positions.size()==9 and study.sculpture.get_child_count()==8)
        check("Grid does not build a new point",study.find_children("*","RigidBody3D",true,false).is_empty())
        var hash_before:=FileAccess.get_sha256(archive.PATH)
        observations["archive_sha256"]=hash_before
        await snapshot("museum-grid-sculpture",study.to_global(Vector3(-0.4,1.65,3.0)),study.to_global(Vector3(0,1.22,0)),65)
        study.grid_step=0.5;study._place_on_grid()
        await snapshot("museum-grid-coarse",study.to_global(Vector3(-0.4,1.65,3.0)),study.to_global(Vector3(0,1.22,0)),65)
        check("Grid leaves saved drawing file untouched",FileAccess.get_sha256(archive.PATH)==hash_before)
        if FileAccess.get_file_as_string(FLAG)=="restore":FileAccess.open(archive.PATH,FileAccess.WRITE).store_buffer(FileAccess.get_file_as_bytes(BACKUP))
        else:DirAccess.remove_absolute(archive.PATH)

func finish() -> void:
    FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"room":map_id,"checks":checks,"failures":failures,"observations":observations,"scope":"Actual museum halls and exact learner programs, separate process runs. Synthetic controller draws and releases in Trace; Grid loads the saved sculpture. Temporary study placement, not a permanent museum map edit or physical headset test."},"  "))
    quit(0 if failures.is_empty() else 1)
