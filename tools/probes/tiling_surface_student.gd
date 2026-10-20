extends SceneTree
var checks:Array=[]
var failures:Array=[]
func _initialize()->void:run.call_deferred()
func check(title:String,ok:bool)->void:
    checks.append({"name":title,"passed":ok})
    if not ok:failures.append(title)
    print("[surface learner] ","PASS " if ok else "FAIL ",title)
func rendered(s:Node3D)->bool:
    var expected:Array=[0,1,0,0,1, 0,0,1,0,0, 0,1,0,0,1, 0,0,1,0,0, 0,1,0,0,1]
    for z in 5:
        for x in 5:
            var a:Color=s.grid.read(Vector2i(x,z))
            var b:Color=s.palette.colours[expected[z*5+x]]
            for i in 4:
                if absf(a[i]-b[i])>.005:return false
    return true
func hand(s:Node3D,p:Vector3)->void:
    s.control.global_position=s.to_global(p);s._process(0)
func point_at(s:Node3D,col:float,row:float,width:float,depth:float,on_wall:bool)->void:
    # Independent host-space prediction: deliberately do not use the receiver transform.
    hand(s,Vector3(.9-depth,2.2-row*width,col*width) if on_wall else Vector3(-.64+col*width,.82+depth,row*width))
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
    await create_timer(.2).timeout
    s._process(0)
    check("four-file reconstruction creates grid, readout and inherited pickable point",s.grid.cells.size()==25 and s.label.is_inside_tree() and s.control.has_method("pick_up"))
    check("physics keeps the initial frozen point",s.control.position.is_equal_approx(Vector3(0,1.15,2.5)) and s.control.freeze)
    check("initial colours match explicit twenty-five-cell fixture",rendered(s))
    check("neutral point selects neither cell nor action",s.selected_address()==Vector2i(-1,-1) and s.operation().is_empty())
    var record:Array=s.source.duplicate(true)
    var id:int=s.grid.get_instance_id()
    var resource_id:int=s.grid.instances.get_instance_id()
    var geometry:Array=[]
    for i in 25:geometry.append(s.grid.instances.get_instance_transform(i))
    var widths:Array=[.24,.36] if changed else [.32,.48]
    var spans:Array=[.72,1.08] if changed else [.96,1.44]
    for pose in 2:
        for size in 2:
            var width:float=widths[size]
            var prefix:="wall " if pose==1 else "table "
            prefix+=str(width)+" / "
            check(prefix+"selected state is the predicted face and size",s.wall==(pose==1) and s.width_index==size)
            var first:Vector3=s.to_local(s.grid.to_global(Vector3.ZERO))
            var next_column:Vector3=s.to_local(s.grid.to_global(Vector3(.32,0,0)))
            var next_row:Vector3=s.to_local(s.grid.to_global(Vector3(0,0,.32)))
            check(prefix+"receiver origin stays explicit",first.is_equal_approx(Vector3(.9,2.2,0) if pose==1 else Vector3(-.64,.82,0)))
            check(prefix+"column direction and metre spacing",(next_column-first).is_equal_approx(Vector3(0,0,width) if pose==1 else Vector3(width,0,0)))
            check(prefix+"row direction and metre spacing",(next_row-first).is_equal_approx(Vector3(0,-width,0) if pose==1 else Vector3(0,0,width)))
            check(prefix+"three-column source has predicted physical width",is_equal_approx(first.distance_to(next_column)*3,spans[size]))
            point_at(s,3,1,width,.3,pose==1)
            check(prefix+"world point returns to surface (3,1)",s.selected_address()==Vector2i(3,1))
            check(prefix+"readout names original source and width",s.label.text.contains("source row 1, column 0") and s.label.text.contains("SOURCE WIDTH %.2f m"%spans[size]))
            var marker:Vector3=s.to_local(s.grid.marker.global_position)
            var expected_marker:=Vector3(.9-.06*width/.32,2.2-width,3*width) if pose==1 else Vector3(-.64+3*width,.82+.06*width/.32,width)
            check(prefix+"visible ring follows the chosen cube",s.grid.marker.visible and marker.is_equal_approx(expected_marker))
            s.control.action()
            check(prefix+"inspection does not paint or change receiver",s.source==record and s.wall==(pose==1) and s.width_index==size)
            for depth in [.11,.66,-.2]:
                point_at(s,3,1,width,depth,pose==1)
                check(prefix+"metre distance gate rejects "+str(depth),s.selected_address()==Vector2i(-1,-1) and not s.grid.marker.visible)
            for depth in [.13,.64]:
                point_at(s,3,1,width,depth,pose==1)
                check(prefix+"metre distance gate admits "+str(depth),s.selected_address()==Vector2i(3,1))
            point_at(s,-.51,0,width,.3,pose==1)
            check(prefix+"negative boundary stays outside",s.selected_address()==Vector2i(-1,-1))
            point_at(s,4.51,0,width,.3,pose==1)
            check(prefix+"beyond fifth interval stays outside",s.selected_address()==Vector2i(-1,-1))
            point_at(s,4.49,4.49,width,.3,pose==1)
            check(prefix+"last interval includes its outer half",s.selected_address()==Vector2i(4,4))
            hand(s,Vector3(.6,1.15,2.5))
            check(prefix+"hover names width action without acting",s.operation()=="CELL WIDTH" and s.width_index==size)
            s.control.action()
        hand(s,Vector3(-.6,1.15,2.5))
        check("local FACE action on translated, rotated host",s.operation()=="FACE" and s.wall==(pose==1))
        s.control.action()
    check("complete action cycle returns to original receiver",not s.wall and s.width_index==0)
    check("receiver changes never rewrite source or colours",s.source==record and rendered(s))
    check("same grid and MultiMesh resource survive",s.grid.get_instance_id()==id and s.grid.instances.get_instance_id()==resource_id)
    var same:=true
    for i in 25:same=same and geometry[i]==s.grid.instances.get_instance_transform(i)
    check("all twenty-five local cube transforms survive",same)
    for p in [Vector3(0,1.15,2.5),Vector3(-.6,.94,2.5),Vector3(.6,1.51,2.5),Vector3(-.6,1.15,2.76)]:
        hand(s,p);s.control.action()
        check("invalid action position keeps state "+str(p),s.operation().is_empty() and not s.wall and s.width_index==0)
    s.reflected=true
    check("carried reflected reader maps same surface address to source column two",s.source_address(Vector2i(3,1))==Vector2i(2,1))
    check("carried asymmetric read has six-cell translation period",s.value_at(Vector2i(0,1))==s.value_at(Vector2i(6,1)) and s.value_at(Vector2i(0,1))!=s.value_at(Vector2i(3,1)))
    var other=script.new();root.add_child(other);other.set_process(false)
    s.source[0][0]=2
    check("another reconstruction owns independent nested source and state",other.source==record and not other.wall and not other.reflected)
    FileAccess.open(report,FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"source":path,"changed":changed,"engine":Engine.get_version_info(),"scope":"Exact printed code, transformed host, independent narrower-width variation. Author-informed assertions and simulated actions; no headset or human-learning claim."},"  "))
    s.free();other.free();quit(0 if failures.is_empty() else 1)
