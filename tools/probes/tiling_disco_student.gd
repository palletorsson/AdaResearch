extends SceneTree
var checks: Array = []
var failures: Array = []
func _initialize()->void:run.call_deferred()
func check(title:String,ok:bool)->void:
    checks.append({"name":title,"passed":ok})
    if not ok:failures.append(title)
    print("[tiling learner] ","PASS " if ok else "FAIL ",title)
func values(s:Node3D)->Array:
    var out:Array=[]
    for address in s.grid.cells:out.append(s.value_at(address))
    return out
func colours(s:Node3D)->Array:
    var out:Array=[]
    for address in s.grid.cells:out.append(s.grid.read(address))
    return out
func geometry(s:Node3D)->Array:
    var out:Array=[]
    for i in 25:out.append(s.grid.instances.get_instance_transform(i))
    return out
func close_colours(a:Array,b:Array)->bool:
    if a.size()!=b.size():return false
    for i in a.size():
        for c in 4:
            if absf(a[i][c]-b[i][c])>.005:return false
    return true
func all_grey(a:Array)->bool:
    for c in a:
        if absf(c.r-.4)>.005 or absf(c.g-.4)>.005 or absf(c.b-.4)>.005:return false
    return true
func run()->void:
    await process_frame
    var source:="";var report:="";var changed:=false
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--lesson="):source=arg.trim_prefix("--lesson=")
        if arg.begins_with("--report="):report=arg.trim_prefix("--report=")
        if arg=="--changed":changed=true
    var script=load(source)
    if script==null or not script.can_instantiate():
        check("printed script loads",false)
        quit(1)
        return
    var s=script.new()
    s.position=Vector3(4,0,7);s.rotation.y=PI/3
    root.add_child(s);s.set_process(false)
    await create_timer(.2).timeout
    check("complete script creates the carried grid and action point",s.grid.cells.size()==25 and s.control.has_method("pick_up") and s.label.is_inside_tree())
    check("control retains its local start after physics",s.control.position.is_equal_approx(Vector3(0,1,1.9)))
    check("old address UI is hidden without deleting the receiver",not s.grid.marker.visible and not s.grid.readout.visible and s.grid.has_method("write"))
    check("known address fixtures yield parity",s.value_at(Vector2i(0,0))==0 and s.value_at(Vector2i(1,0))==1 and s.value_at(Vector2i(1,1))==0)
    var original_values:=values(s);var original_colours:=colours(s);var original_geometry:=geometry(s)
    check("five by five checker has thirteen zeros and twelve ones",original_values.count(0)==13 and original_values.count(1)==12)
    var assigned:Array=[]
    for address in s.grid.cells:assigned.append(s.palettes[1].colours[(address.x+address.y)%2])
    check("rendered colours follow the selected pair",close_colours(original_colours,assigned))
    check("only the edited pair collapses to grey",all_grey(original_colours)==changed)
    check("carried Palette iterator is not consumed by drawing",s.palettes[1].index==0)
    s.step()
    var inverted:=true
    var one:=values(s)
    for i in 25:inverted=inverted and one[i]==1-original_values[i]
    check("one step exchanges every value",s.phase==1 and inverted and s.palette_index==1)
    if changed:check("grey receiver conceals a changing pattern",close_colours(colours(s),original_colours))
    else:check("distinct colours reveal the changed pattern",not close_colours(colours(s),original_colours))
    s.step()
    check("two steps restore appearance without resetting phase",s.phase==2 and values(s)==original_values and close_colours(colours(s),original_colours))
    s.elapsed=.2
    for i in 4:
        s.cycle_palette()
        check("palette selection preserves phase and partial interval "+str(i),s.phase==2 and is_equal_approx(s.elapsed,.2) and values(s)==original_values and not s.playing)
    check("four pair changes return to selected appearance",s.palette_index==1 and close_colours(colours(s),original_colours))
    s._process(1.0)
    check("held clock cannot advance",s.phase==2 and is_equal_approx(s.elapsed,.2))
    s.toggle_running();s._process(.35)
    check("resume consumes held remainder",s.phase==3 and is_equal_approx(s.elapsed,.05))
    s._process(1.20)
    check("long frame consumes two intervals and keeps remainder",s.phase==5 and is_equal_approx(s.elapsed,.25))
    s.cycle_palette()
    check("palette edit while running keeps the clock",s.playing and s.phase==5 and is_equal_approx(s.elapsed,.25))
    s.step()
    check("manual step starts fresh interval",s.phase==6 and is_zero_approx(s.elapsed))
    s.toggle_running()
    var old:int=s.palette_index
    s.control.position.x=-.5;s.control.action()
    check("left action changes only palette in a rotated host",s.palette_index==(old+1)%4 and s.phase==6 and not s.playing)
    s.control.position.x=0;s.control.action()
    check("middle action advances a held phase",s.phase==7 and not s.playing)
    s.control.position.x=.5;s.control.action()
    check("right action toggles running",s.playing and s.phase==7)
    check("all operations retain the twenty-five instance transforms",geometry(s)==original_geometry)
    check("values remain binary at negative phase too",s.value_at(Vector2i(-20,-1)) in [0,1])
    var stored:Color=s.grid.read(Vector2i(0,0))
    check("unaddressed write is refused",not s.grid.write(Vector2i(5,5),Color.RED) and s.grid.read(Vector2i(0,0))==stored)
    var other=load(source).new();root.add_child(other);other.set_process(false)
    check("instances own separate phase and palette objects",other.phase==0 and other.palettes[1]!=s.palettes[1])
    var source_colour:Color=other.palettes[1].colours[0]
    s.palettes[1].colours[0]=Color.RED
    check("editing one instance's pair leaves the other alone",other.palettes[1].colours[0]==source_colour)
    check("lookup does not need the Palette iterator state",other.palettes[1].index==0)
    check("sample grid is display only with no collider",s.grid.find_children("*","CollisionObject3D",true,false).is_empty())
    if changed:
        other.step();other.cycle_palette()
        check("another pair reveals the retained phase",other.phase==1 and not all_grey(colours(other)) and values(other)!=original_values)
    FileAccess.open(report,FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"source":source,"changed":changed,"engine":Engine.get_version_info(),"scope":"Printed files reconstructed in prepared project with native renderer for MultiMesh colours; author-informed test, not physical headset or human learning evidence."},"  "))
    s.free();other.free()
    quit(0 if failures.is_empty() else 1)
