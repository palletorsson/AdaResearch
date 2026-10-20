extends SceneTree
var checks: Array = []
var failures: Array = []
func _initialize()->void:run.call_deferred()
func check(title:String,ok:bool)->void:
    checks.append({"name":title,"passed":ok})
    if not ok:failures.append(title)
    print("[foundry learner] ","PASS " if ok else "FAIL ",title)
func values(s:Node3D)->Array:
    var out:Array=[]
    for z in 5:
        for x in 5:out.append(s.value_at(Vector2i(x,z)))
    return out
func colours(s:Node3D)->Array:
    var out:Array=[]
    for z in 5:
        for x in 5:out.append(s.grid.read(Vector2i(x,z)))
    return out
func geometry(s:Node3D)->Array:
    var out:Array=[]
    for i in 25:out.append(s.grid.instances.get_instance_transform(i))
    return out
func close_colour(a:Color,b:Color)->bool:
    return absf(a.r-b.r)<.005 and absf(a.g-b.g)<.005 and absf(a.b-b.b)<.005 and absf(a.a-b.a)<.005
func put_point(s:Node3D,address:Vector2i,height:float=.33)->void:
    s.control.global_position=s.grid.to_global(Vector3(address.x*.32,height,address.y*.32))
func run()->void:
    await process_frame
    var source:="";var report:="";var changed:=false
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--lesson="):source=arg.trim_prefix("--lesson=")
        if arg.begins_with("--report="):report=arg.trim_prefix("--report=")
        if arg=="--changed":changed=true
    var script=load(source)
    if script==null or not script.can_instantiate():
        check("printed script loads",false);quit(1);return
    var s=script.new();s.position=Vector3(4,0,7);s.rotation.y=PI/3
    root.add_child(s);s.set_process(false)
    await create_timer(.2).timeout
    s._process(0)
    check("complete reconstruction supplies grid point and label",s.grid.cells.size()==25 and s.control.has_method("pick_up") and s.label.is_inside_tree())
    check("point keeps local position after physics",s.control.position.is_equal_approx(Vector3(0,1.15,1.9)))
    check("source has declared rectangular dimensions",s.source.size()==(3 if changed else 2) and s.source[0].size()==3)
    check("initial control is outside and marker is hidden",s.selected_address()==Vector2i(-1,-1) and not s.grid.marker.visible)
    check("old readout is hidden and source values are shown",not s.grid.readout.visible and s.label.text.contains(str(s.source)))
    var expected:Array=[0,1,0,0,1, 0,0,1,0,0, 0,1,0,0,1, 0,0,1,0,0, 0,1,0,0,1]
    if changed:expected=[0,1,0,0,1, 0,0,1,0,0, 2,0,0,2,0, 0,1,0,0,1, 0,0,1,0,0]
    check("all twenty-five values match independently listed motif",values(s)==expected)
    var rendered:=true
    for z in 5:
        for x in 5:rendered=rendered and close_colour(s.grid.read(Vector2i(x,z)),s.palette.colours[expected[z*5+x]])
    check("native receiver displays those palette indices",rendered)
    check("negative address wraps to last source cell",s.source_address(Vector2i(-1,-1))==Vector2i(2,2 if changed else 1))
    check("columns repeat after three",s.source_address(Vector2i(4,0))==Vector2i(1,0))
    check("row period is read from source height",s.source_address(Vector2i(1,3 if changed else 2))==Vector2i(1,0))
    var original:Array=s.source.duplicate(true);var original_values:=values(s);var original_colours:=colours(s);var transforms:=geometry(s)
    var target:=Vector2i(4,3 if changed else 2)
    put_point(s,target);s._process(0)
    check("turned host selects the intended preview cell",s.selected_address()==target)
    check("ring and label identify source row zero column one",s.grid.marker.visible and s.label.text.contains("source row 0, column 1") and s.grid.marker.position.is_equal_approx(Vector3(target.x*.32,.06,target.y*.32)))
    check("movement without trigger never edits",s.source==original and colours(s)==original_colours)
    s.control.action();s._process(0)
    check("trigger edits the shared source once",s.source[0][1]==2)
    var only_one:=true
    for z in s.source.size():
        for x in 3:
            if Vector2i(x,z)!=Vector2i(1,0):only_one=only_one and s.source[z][x]==original[z][x]
    check("all other source entries remain unchanged",only_one)
    var edits:Array=[Vector2i(1,0),Vector2i(4,0),Vector2i(1,2),Vector2i(4,2),Vector2i(1,4),Vector2i(4,4)]
    if changed:edits=[Vector2i(1,0),Vector2i(4,0),Vector2i(1,3),Vector2i(4,3)]
    var affected:=true;var untouched:=true;var difference:=0
    var after:=colours(s)
    for z in 5:
        for x in 5:
            var i:=z*5+x
            if not close_colour(after[i],original_colours[i]):difference+=1
            if Vector2i(x,z) in edits:affected=affected and close_colour(after[i],s.palette.colours[2])
            else:untouched=untouched and close_colour(after[i],original_colours[i])
    check("one edit reaches every listed copy",affected and difference==edits.size())
    check("remaining preview colours stay unchanged",untouched)
    put_point(s,Vector2i(1,0));s.control.action()
    check("another copy edits the same source entry",s.source[0][1]==0 and s.value_at(target)==0)
    s.control.action()
    check("three trigger actions restore values and appearance",s.source==original and values(s)==original_values)
    for pos in [Vector3(-.17,.33,0),Vector3(1.45,.33,0),Vector3(0,.33,-.17),Vector3(0,.33,1.45),Vector3(0,.119,0),Vector3(0,.651,0)]:
        s.control.global_position=s.grid.to_global(pos);s._process(0);s.control.action()
        check("outside position refuses editing "+str(pos),s.selected_address()==Vector2i(-1,-1) and not s.grid.marker.visible and s.source==original)
    check("edits do not alter geometry or Palette iterator",geometry(s)==transforms and s.palette.index==0)
    # Explicit repaint: changing source data alone cannot automatically change a MultiMesh.
    var old:Color=s.grid.read(Vector2i(0,0));s.source[0][0]=2
    check("data assignment alone leaves old display",close_colour(s.grid.read(Vector2i(0,0)),old))
    s.paint()
    check("explicit repaint displays the changed data",close_colour(s.grid.read(Vector2i(0,0)),s.palette.colours[2]))
    var other=script.new();root.add_child(other);other.set_process(false)
    check("second construction starts from its own rows",other.source==original)
    s.source[1][0]=2
    check("nested rows are not shared across instances",other.source[1][0]==0)
    check("receiver has no walking collider",s.grid.find_children("*","CollisionObject3D",true,false).is_empty())
    if changed:
        check("added third row creates the predicted mint cells",other.value_at(Vector2i(0,2))==2 and other.value_at(Vector2i(3,2))==2 and other.value_at(Vector2i(0,3))==0)
    FileAccess.open(report,FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"source":source,"changed":changed,"engine":Engine.get_version_info(),"scope":"Exact fenced files in prepared project; native rendered colours and independent row edit. Author-informed, no physical headset or human-learning claim."},"  "))
    s.free();other.free();quit(0 if failures.is_empty() else 1)
