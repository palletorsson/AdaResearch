extends SceneTree
var checks:Array=[]
var failures:Array=[]
func _initialize()->void:run.call_deferred()
func check(title:String,ok:bool)->void:
    checks.append({"name":title,"passed":ok})
    if not ok:failures.append(title)
    print("[pattern learner] ","PASS " if ok else "FAIL ",title)
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
    for i in 4:
        if absf(a[i]-b[i])>.005:return false
    return true
func rendered(s:Node3D,expected:Array)->bool:
    for z in 5:
        for x in 5:
            if not close_colour(s.grid.read(Vector2i(x,z)),s.palette.colours[expected[z*5+x]]):return false
    return true
func select_operation(s:Node3D,side:int)->void:
    s.control.global_position=s.to_global(Vector3(side*.6,1.15,1.9));s._process(0)
func run()->void:
    await process_frame
    var source:="";var report:="";var changed:=false
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--lesson="):source=arg.trim_prefix("--lesson=")
        if arg.begins_with("--report="):report=arg.trim_prefix("--report=")
        if arg=="--changed":changed=true
    var script=load(source)
    if script==null or not script.can_instantiate():check("printed script loads",false);quit(1);return
    var s=script.new();s.position=Vector3(4,0,7);s.rotation.y=PI/3;root.add_child(s);s.set_process(false)
    await create_timer(.2).timeout
    s._process(0)
    check("complete reconstruction creates twenty-five cubes and pickable point",s.grid.cells.size()==25 and s.control.has_method("pick_up") and s.label.is_inside_tree())
    check("frozen point retains initial position after physics",s.control.position.is_equal_approx(Vector3(0,1.15,1.9)))
    check("initial reader is translation with no selected action",not s.reflected and s.operation().is_empty() and not s.grid.marker.visible)
    var original:Array=s.source.duplicate(true)
    var transforms:=geometry(s)
    var p1:Array=[0,1,0,0,1, 0,0,1,0,0, 0,1,0,0,1, 0,0,1,0,0, 0,1,0,0,1]
    var pm:Array=[0,1,0,0,1, 0,0,1,1,0, 0,1,0,0,1, 0,0,1,1,0, 0,1,0,0,1]
    if changed:
        p1=[0,1,0,0,1, 2,0,2,2,0, 0,1,0,0,1, 2,0,2,2,0, 0,1,0,0,1]
        pm=p1.duplicate()
    check("initial values match independently listed fixture",values(s)==p1)
    check("initial renderer displays fixture colours",rendered(s,p1))
    select_operation(s,-1)
    check("turned host selects read control in its local frame",s.operation()=="READ RULE" and s.label.text.contains("READ RULE"))
    check("hover alone leaves source and reader unchanged",s.source==original and not s.reflected)
    s.control.action();s._process(0)
    check("held action toggles reader and keeps every stored entry",s.reflected and s.source==original)
    check("reflected values match independently listed fixture",values(s)==pm)
    check("reflected renderer displays fixture colours",rendered(s,pm))
    check("second tile reads backwards while first reads forwards",s.source_address(Vector2i(3,1))==Vector2i(2,1) and s.source_address(Vector2i(2,1))==Vector2i(2,1) and s.source_address(Vector2i(0,1))==Vector2i(0,1))
    check("negative tile uses floor division before reflection",s.source_address(Vector2i(-1,-1))==Vector2i(0,1))
    check("reader addresses repeat after six but not three columns",s.source_address(Vector2i(0,1))==s.source_address(Vector2i(6,1)) and s.source_address(Vector2i(0,1))!=s.source_address(Vector2i(3,1)))
    if not changed:check("asymmetric values expose six-cell period",s.value_at(Vector2i(0,1))==s.value_at(Vector2i(6,1)) and s.value_at(Vector2i(0,1))!=s.value_at(Vector2i(3,1)))
    var reflected_colours:=colours(s)
    select_operation(s,1)
    check("turned host selects source control",s.operation()=="FLIP SOURCE" and s.label.text.contains("FLIP SOURCE"))
    s.control.action();s._process(0)
    var flipped:Array=[[0,1,0],[1,0,0]] if not changed else [[0,1,0],[2,0,2]]
    check("source flip reverses each row rather than row order",s.source==flipped)
    check("source flip leaves selected reader unchanged",s.reflected)
    var reversed_values:Array=[0,1,0,0,1, 1,0,0,0,0, 0,1,0,0,1, 1,0,0,0,0, 0,1,0,0,1] if not changed else pm
    check("source flip reaches values and rendered colours",values(s)==reversed_values and rendered(s,reversed_values))
    s.control.action()
    check("second source flip restores all entries and appearance",s.source==original and values(s)==pm and colours(s)==reflected_colours)
    s.control.global_position=s.grid.to_global(Vector3(3*.32,.33,1*.32));s._process(0)
    check("reflected copy identifies its true source address",s.selected_address()==Vector2i(3,1) and s.label.text.contains("source row 1, column 2") and s.grid.marker.visible)
    s.control.action();s._process(0)
    check("painting a reflected copy edits column two only",s.source==([[0,1,0],[0,0,2]] if not changed else [[0,1,0],[2,0,0]]))
    var edited:Array=[0,1,0,0,1, 0,0,2,2,0, 0,1,0,0,1, 0,0,2,2,0, 0,1,0,0,1] if not changed else [0,1,0,0,1, 2,0,0,0,0, 0,1,0,0,1, 2,0,0,0,0, 0,1,0,0,1]
    check("reflected edit reaches exactly four specified copies",values(s)==edited and rendered(s,edited))
    check("all operations retain cube geometry and palette cursor",geometry(s)==transforms and s.palette.index==0)
    if changed:
        check("symmetric source initially hides changed reader",p1==pm)
        var before_break:=colours(s)
        select_operation(s,-1);s.control.action()
        check("breaking symmetry makes the read rule visible",colours(s)!=before_break and s.value_at(Vector2i(3,1))==2)
    var kept:Array=s.source.duplicate(true);var rule:bool=s.reflected
    for p in [Vector3(0,1.15,1.9),Vector3(-.6,.94,1.9),Vector3(.6,1.51,1.9),Vector3(-.6,1.15,2.16),Vector3(1,1.15,1.9),Vector3(0,1.6,.3)]:
        s.control.global_position=s.to_global(p);s._process(0);s.control.action()
        check("unselected position refuses actions "+str(p),s.operation().is_empty() and s.source==kept and s.reflected==rule)
    s.control.global_position=s.grid.to_global(Vector3(0,.66,0));s.control.action()
    check("grid height gate still refuses painting",s.source==kept)
    # Width three has a fixed centre: a wrong alternate-cell rule can look right.
    # A four-column address witness must distinguish tile parity from cell parity.
    s.source=[[0,1,2,0],[2,1,0,2]];s.reflected=true
    var columns:Array=[]
    for x in 12:columns.append(s.source_address(Vector2i(x,0)).x)
    check("four-wide reader alternates whole tiles not individual cells",columns==[0,1,2,3,3,2,1,0,0,1,2,3])
    check("four-wide negative tile reflects from its far edge",s.source_address(Vector2i(-1,0))==Vector2i(0,0))
    s.source=kept;s.reflected=rule;s.paint()
    var other=script.new();root.add_child(other);other.set_process(false)
    check("new instance starts with independent source and reader",other.source==original and not other.reflected)
    s.source[0][0]=2
    check("editing instance does not alter second nested source",other.source==original)
    FileAccess.open(report,FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"source":source,"changed":changed,"engine":Engine.get_version_info(),"scope":"Exact printed reconstruction and independently edited symmetric source in prepared museum project. Native colour assertions; author-informed, no headset or human-learning claim."},"  "))
    s.free();other.free();quit(0 if failures.is_empty() else 1)
