extends SceneTree
var checks:Array=[]
var failures:Array=[]
func _initialize()->void:run.call_deferred()
func check(title:String,ok:bool)->void:
    checks.append({"name":title,"passed":ok})
    if not ok:failures.append(title)
    print("[temple learner] ","PASS " if ok else "FAIL ",title)
func colours(s:Node3D,i:int)->Array:
    var a:Array=[]
    for y in 5:
        for x in 5:a.append(s.receivers[i].read(Vector2i(x,y)))
    return a
func matches(s:Node3D,i:int,values:Array)->bool:
    var a:=colours(s,i)
    for k in 25:
        var expected:Color=s.palette.colours[values[k]]
        for channel in 4:
            if absf(a[k][channel]-expected[channel])>.005:return false
    return true
func action(s:Node3D,x:float)->void:
    s.control.global_position=s.to_global(Vector3(x,1.15,2.5));s._process(0);s.control.action();s._process(0)
func hover(s:Node3D,i:int,a:Vector2i)->void:
    s.control.global_position=s.receivers[i].to_global(Vector3(a.x*.32,.3,a.y*.32));s._process(0)
func run()->void:
    await process_frame
    var path:="";var report:="";var changed:=false
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--lesson="):path=arg.trim_prefix("--lesson=")
        if arg.begins_with("--report="):report=arg.trim_prefix("--report=")
        if arg=="--changed":changed=true
    var script=load(path)
    if script==null or not script.can_instantiate():quit(2);return
    var s=script.new();s.position=Vector3(4,0,7);s.rotation.y=PI/3;root.add_child(s);s.set_process(false)
    await create_timer(.15).timeout
    var original:Array=s.source.duplicate(true)
    var old:int=2 if changed else 1;var width:int=4 if changed else 3
    var address:=Vector2i(width,0);var cell:=Vector2i(width-1,1)
    var initial:Array=[0,1,0,1,0,0,0,1,0,1,0,1,0,1,0,0,0,1,0,1,0,1,0,1,0]
    if changed:initial=[0,1,2,0,2,2,0,1,2,0,0,1,2,0,2,2,0,1,2,0,0,1,2,0,2]
    check("two carried grids and one point",s.receivers.size()==2 and s.find_children("*","MultiMeshInstance3D",true,false).size()==2 and s.find_children("*","RigidBody3D",true,false).size()==1)
    check("template copied into two initial recipes",s.recipes[0].source==original and s.recipes[1].source==original and s.recipes[0].rule==2 and s.recipes[1].rule==2)
    check("both initial renders match explicit PG fixture",matches(s,0,initial) and matches(s,1,initial))
    check("PG lookup matches independent prediction",s.source_address(0,address)==cell and s.value_at(0,address)==old)
    check("negative address still composes reflection and glide",s.source_address(0,Vector2i(-1,-1))==Vector2i(0,0))
    check("whole horizontal period survives receiver choice",s.source_address(1,address+Vector2i(width*2,0))==cell)
    var poses:Array=[s.receivers[0].transform,s.receivers[1].transform]
    var ids:Array=[s.receivers[0].instances.get_instance_id(),s.receivers[1].instances.get_instance_id()]
    hover(s,1,address);var before:Array=s.recipes.duplicate(true);s.control.action()
    check("unselected wall cannot be painted",s.selected_address()==Vector2i(-1,-1) and s.recipes==before)
    hover(s,0,address)
    check("rotated host recovers table address without edit",s.selected_address()==address and s.recipes==before and s.label.text.contains("TABLE"))
    s.control.action();s._process(0)
    check("paint reaches glided row of selected source",s.recipes[0].source[cell.y][cell.x]==(old+1)%3)
    check("other recipe and initial template stay unchanged",s.recipes[1].source==original and s.source==original)
    var painted:Array=initial.duplicate()
    for k in ([4,8,14,18,24] if changed else [3,7,13,17,23]):painted[k]=(old+1)%3
    check("all selected occurrences repaint; other image stays",matches(s,0,painted) and matches(s,1,initial))
    action(s,.6)
    check("ALL copies selected values and repaints destination",s.recipes[0]==s.recipes[1] and matches(s,0,painted) and matches(s,1,painted))
    before=s.recipes.duplicate(true);var images:Array=[colours(s,0),colours(s,1)]
    action(s,-.6)
    check("TARGET changes only selection on rotated root",s.target==1 and s.recipes==before and colours(s,0)==images[0] and colours(s,1)==images[1])
    hover(s,1,address)
    check("wall inverse frame identifies same address",s.selected_address()==address and s.label.text.contains("WALL") and s.receivers[1].marker.visible and not s.receivers[0].marker.visible)
    s.control.action();s._process(0)
    check("post-copy wall paint remains independent",s.recipes[1].source[cell.y][cell.x]==(old+2)%3 and s.recipes[0].source[cell.y][cell.x]==(old+1)%3 and matches(s,0,painted))
    var wallpaint:Array=painted.duplicate()
    for k in ([4,8,14,18,24] if changed else [3,7,13,17,23]):wallpaint[k]=(old+2)%3
    check("post-copy paint updates every wall occurrence",matches(s,1,wallpaint))
    before=s.recipes.duplicate(true);action(s,0)
    check("RULE changes only selected rule, preserves both source records",s.recipes[1].rule==0 and s.recipes[0].rule==2 and s.recipes[0].source==before[0].source and s.recipes[1].source==before[1].source)
    check("P1 changes lookup and image without touching table",s.source_address(1,address)==Vector2i.ZERO and colours(s,1)!=images[1] and matches(s,0,painted))
    check("P1 visible destination reads expected colour",absf(s.receivers[1].read(address).r - s.palette.colours[0].r) < .005 and absf(s.receivers[1].read(address).g - s.palette.colours[0].g) < .005 and absf(s.receivers[1].read(address).b - s.palette.colours[0].b) < .005)
    action(s,.6)
    check("ALL works from wall back to table",s.recipes[0]==s.recipes[1] and colours(s,0)==colours(s,1) and s.recipes[0].rule==0)
    action(s,-.6);hover(s,0,Vector2i.ZERO);s.control.action()
    check("reverse copy also preserves subsequent independence",s.target==0 and s.recipes[0].source[0][0]==1 and s.recipes[1].source[0][0]==0)
    check("edits never rebuild or move receivers",s.receivers[0].transform==poses[0] and s.receivers[1].transform==poses[1] and s.receivers[0].instances.get_instance_id()==ids[0] and s.receivers[1].instances.get_instance_id()==ids[1])
    s.control.global_position=s.receivers[0].to_global(Vector3(0,-.1,0));s._process(0)
    check("behind receiver gives no selection",s.selected_address()==Vector2i(-1,-1))
    var fresh=script.new();root.add_child(fresh);fresh.set_process(false)
    check("second learner starts with independent original recipes",fresh.recipes[0].source==original and fresh.recipes[1].source==original and fresh.recipes[0].rule==2)
    check("point retains frozen release mode",s.control.freeze and s.control.release_mode==1)
    var f:=FileAccess.open(report,FileAccess.WRITE);f.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures},"  "));f.close()
    s.queue_free();fresh.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
