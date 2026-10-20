extends SceneTree
var checks:Array=[]
var failures:Array=[]
func _initialize()->void:run.call_deferred()
func check(title:String,ok:bool)->void:
    checks.append({"name":title,"passed":ok})
    if not ok:failures.append(title)
    print("[layer learner] ","PASS " if ok else "FAIL ",title)
func action(s:Node3D,x:float)->void:
    s.control.global_position=s.to_global(Vector3(x,1.15,2.5));s._process(0);s.control.action();s._process(0)
func hover(s:Node3D,y:int,x:int,z:int)->void:
    s.control.global_position=s.layers[y].to_global(Vector3(x*.32,.22,z*.32));s._process(0)
func rendered(s:Node3D,y:int,flat:Array)->bool:
    for z in 5:
        for x in 5:
            var a:Color=s.layers[y].read(Vector2i(x,z));var b:Color=s.palette.colours[flat[z*5+x]]
            for c in 4:
                if absf(a[c]-b[c])>.005:return false
    return true
func stored(s:Node3D,y:int,flat:Array)->bool:
    if s.values[y].size()!=5:return false
    for z in 5:
        if s.values[y][z].size()!=5:return false
        for x in 5:
            if s.values[y][z][x]!=flat[z*5+x]:return false
    return true
func visible_count(s:Node3D)->int:
    var n:=0
    for grid in s.layers:
        if grid.visible:n+=grid.cells.size()
    return n
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
    var count:int=3 if changed else 4
    var r:Array=[0,1,0,0,1,0,0,1,0,0,0,1,0,0,1,0,0,1,0,0,0,1,0,0,1]
    var a:Array=[1,0,0,1,0,0,1,0,0,1,1,0,0,1,0,0,1,0,0,1,1,0,0,1,0]
    var b:Array=[0,0,1,0,0,1,0,0,1,0,0,0,1,0,0,1,0,0,1,0,0,0,1,0,0]
    var expected:Array=[r,b,a] if changed else [r,a,b,r]
    var positions:Array=[];var ids:Array=[]
    for grid in s.layers:positions.append(grid.transform);ids.append(grid.instances.get_instance_id())
    check("one point, one reference and requested carried grids",s.layers.size()==count and s.find_children("*","MultiMeshInstance3D",true,false).size()==count+1 and s.find_children("*","RigidBody3D",true,false).size()==1)
    check("six source values remain independent of display dimensions",s.source==[[0,1,0],[0,0,1]] and s.reference.cells.size()==25)
    check("volume begins with all requested layers stored and shown",s.values.size()==count and visible_count(s)==25*count)
    for y in count:
        check("repeat layer "+str(y)+" matches stored and rendered fixture",stored(s,y,r) and rendered(s,y,r))
    var records:Array=s.values.duplicate(true)
    hover(s,0,4,3);s.control.action()
    check("hovering and triggering away from actions do not paint",s.selected_address()==Vector2i(4,3) and s.values==records)
    action(s,-.6)
    check("LAYER changes only selected index on rotated host",s.layer==1 and s.values==records and visible_count(s)==count*25)
    hover(s,1,4,3)
    check("volume/source readout declares unequal index order",s.label.text.contains("VOLUME [1][3][4] <- SOURCE [1][1] = 0"))
    action(s,.6)
    check("SHIFT changes rule without changing selected layer",s.shifted and s.layer==1)
    for y in count:
        check("shifted layer "+str(y)+" matches stored and rendered fixture",stored(s,y,expected[y]) and rendered(s,y,expected[y]))
    hover(s,1,4,3)
    var wanted:=Vector2i(0,1) if changed else Vector2i(2,1)
    check("height participates in wrapped source address",s.source_address(4,1,3)==wanted and s.values[1][3][4]==(0 if changed else 1))
    check("source marker follows lookup, volume marker keeps address",s.reference.marker.position.is_equal_approx(Vector3(wanted.x*.32,.06,wanted.y*.32)) and s.layers[1].marker.position.is_equal_approx(Vector3(1.28,.06,.96)))
    check("source and reference colours survive the new reading",s.source==[[0,1,0],[0,0,1]] and absf(s.reference.read(Vector2i(1,0)).r-s.palette.colours[1].r)<.005)
    check("negative coordinates wrap to valid source indices",s.source_address(-1,0,-1)==Vector2i(2,1) and s.source_address(0,-1,0)==Vector2i(1 if changed else 2,0))
    check("three height steps restore the source address",s.source_address(0,0,1)==s.source_address(0,3,1))
    check("independent direction prediction at volume [1][1][0]",s.values[1][1][0]==(1 if changed else 0))
    records=s.values.duplicate(true);action(s,0)
    check("SLICE hides bodies while preserving every stored value",s.slice_only and visible_count(s)==25 and s.values==records and s.values.size()==count)
    check("slice selects layer one without deleting render instances",s.layers[1].visible and not s.layers[0].visible and s.find_children("*","MultiMeshInstance3D",true,false).size()==count+1)
    check("counter excludes the separate reference grid",s.label.text.contains("25 VISIBLE / %d STORED"%(count*25)))
    action(s,-.6)
    check("next slice exposes existing next layer",s.layer==2 and s.layers[2].visible and not s.layers[1].visible and s.values==records)
    action(s,0)
    check("ALL restores all nodes with original stored values",not s.slice_only and visible_count(s)==count*25 and s.values==records)
    for i in count:action(s,-.6)
    check("layer index wraps after declared count",s.layer==2)
    var intact:=true
    for y in count:intact=intact and s.layers[y].transform==positions[y] and s.layers[y].instances.get_instance_id()==ids[y]
    check("rule and view edits never move or recreate layers",intact)
    s.values[0][0][0]=2
    check("rows and sheets own distinct lists",s.values[0][2][0]==0 and s.values[1][0][0]==expected[1][0] and s.source[0][0]==0)
    s.fill_values()
    check("refill restores derived record from retained source",stored(s,0,r))
    s.control.global_position=s.layers[2].to_global(Vector3(0,-.1,0));s._process(0)
    check("point below selected layer cannot select it",s.selected_address()==Vector2i(-1,-1))
    var f:=FileAccess.open(report,FileAccess.WRITE);f.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures},"  "));f.close()
    s.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
