extends SceneTree
var checks:Array=[]
var failures:Array=[]
func _initialize()->void:run.call_deferred()
func check(title:String,ok:bool)->void:
    checks.append({"name":title,"passed":ok})
    if not ok:failures.append(title)
    print("[context learner] ","PASS " if ok else "FAIL ",title)
func action(s:Node3D,x:float)->void:
    s.control.global_position=s.to_global(Vector3(x,1.15,2.8));s._process(0);s.control.action();s._process(0)
func select(s:Node3D,x:int,z:int)->void:
    s.control.global_position=s.reference.to_global(Vector3(x*.32,.22,z*.32));s.control.action();s._process(0)
func target_colours(s:Node3D,c:Color)->bool:
    return s.targets[0].material_override.albedo_color==c and s.targets[1].material_override.albedo_color==c and s.bridge.material_override.albedo_color==c
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
    var navy:=Color(0.5,0.5,0.5) if changed else Color("172051")
    var pink:=Color("fc62ad");var mint:=Color("55f3cf")
    var source:Array=[[0,1,0],[0,0,2 if changed else 1]]
    var positions:Array=[];var ids:Array=[]
    for view in s.targets+[s.bridge,s.reference]:positions.append(view.transform);ids.append(view.get_instance_id())
    check("same source six entries and one25-cell reference",s.source==source and s.reference.cells.size()==25)
    check("one carried point and two targets",s.find_children("*","RigidBody3D",true,false).size()==1 and s.targets.size()==2)
    check("initial target and connector colours follow predicted first palette entry",target_colours(s,navy))
    check("targets and connector deliberately share one resource",s.targets[0].material_override==s.targets[1].material_override and s.bridge.material_override==s.targets[0].material_override)
    check("surrounds own separate materials",s.surrounds[0].material_override!=s.surrounds[1].material_override and s.surrounds[0].material_override!=s.target_material)
    check("dark left light right at start",s.surrounds[0].material_override.albedo_color==Color(.1,.1,.1) and s.surrounds[1].material_override.albedo_color==Color(.9,.9,.9))
    check("connector initially hidden",not s.bridge.visible)
    var unshaded:=true
    for view in s.targets+s.surrounds+[s.bridge]:unshaded=unshaded and view.material_override.shading_mode==BaseMaterial3D.SHADING_MODE_UNSHADED
    check("all comparison materials bypass lighting dependent shading",unshaded)
    var fixture:Array=[0,1,0,0,1,0,0,2 if changed else 1,0,0,0,1,0,0,1,0,0,2 if changed else 1,0,0,0,1,0,0,1]
    var matched:=true
    for z in 5:
        for x in 5:
            var actual:Color=s.reference.read(Vector2i(x,z));var expected:Color=[navy,pink,mint][fixture[z*5+x]]
            for c in 4:matched=matched and absf(actual[c]-expected[c])<.005
    check("all25 reference colours match non-square source fixture",matched)
    s.control.global_position=s.reference.to_global(Vector3(.32,.22,0));s._process(0)
    check("hover alone does not select or recolour",s.selected==Vector2i.ZERO and target_colours(s,navy))
    s.control.action();s._process(0)
    check("trigger selects source[0][1] and both targets become pink",s.selected==Vector2i(1,0) and target_colours(s,pink))
    check("readout labels source in row column order",s.label.text.contains("SOURCE [0][1] = 1"))
    action(s,-.6)
    check("SWAP on rotated host exchanges only surrounds",s.swapped and s.surrounds[0].material_override.albedo_color==Color(.9,.9,.9) and s.surrounds[1].material_override.albedo_color==Color(.1,.1,.1) and target_colours(s,pink))
    action(s,0)
    check("EQUAL matches both surrounds to targets",s.equal and s.surrounds[0].material_override.albedo_color==pink and s.surrounds[1].material_override.albedo_color==pink)
    action(s,.6)
    check("CONNECT reveals same coloured bridge",s.connected and s.bridge.visible and target_colours(s,pink))
    action(s,-.6)
    check("SWAP retains equality while EQUAL is on",not s.swapped and s.equal and s.surrounds[0].material_override.albedo_color==pink and s.surrounds[1].material_override.albedo_color==pink)
    select(s,2,1)
    var selected_colour:Color=mint if changed else pink
    check("independent source edit selects expected colour",s.selected==Vector2i(2,1) and target_colours(s,selected_colour))
    check("EQUAL follows a newly selected value",s.surrounds[0].material_override.albedo_color==selected_colour and s.surrounds[1].material_override.albedo_color==selected_colour)
    action(s,0)
    check("leaving EQUAL reveals retained surround order",not s.equal and s.surrounds[0].material_override.albedo_color==Color(.1,.1,.1) and s.surrounds[1].material_override.albedo_color==Color(.9,.9,.9))
    action(s,.6)
    check("second CONNECT hides bridge without losing target colour",not s.bridge.visible and target_colours(s,selected_colour))
    select(s,4,3)
    check("larger reference address wraps to source[1][1]",s.value_at(Vector2i(4,3))==0 and s.label.text.contains("SOURCE [1][1] = 0") and target_colours(s,navy))
    check("selection marker stays on chosen reference cell",s.reference.marker.position.is_equal_approx(Vector3(1.28,.06,.96)))
    s.control.global_position=s.reference.to_global(Vector3(0,-.1,0));s.control.action();s._process(0)
    check("point below reference does not select",s.hovered_cell()==Vector2i(-1,-1) and s.selected==Vector2i(4,3))
    s.control.global_position=s.to_global(Vector3(10,1.15,2.8));s.control.action()
    check("trigger outside controls preserves selection and state",s.selected==Vector2i(4,3) and not s.swapped and not s.equal and not s.connected)
    check("selection and surround changes never paint source",s.source==source)
    var stable:=true;var i:=0
    for view in s.targets+[s.bridge,s.reference]:stable=stable and view.transform==positions[i] and view.get_instance_id()==ids[i];i+=1
    check("existing target and selector bodies retained in place",stable)
    var f:=FileAccess.open(report,FileAccess.WRITE);f.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures},"  "));f.close()
    s.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
