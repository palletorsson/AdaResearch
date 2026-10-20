extends SceneTree
var checks:Array=[]
var failures:Array=[]
var viewport:SubViewport
var panel:MeshInstance3D
var samples:Array=[]
func _initialize()->void:run.call_deferred()
func check(title:String,ok:bool)->void:
    checks.append({"name":title,"passed":ok})
    if not ok:failures.append(title)
    print("[shader learner] ","PASS " if ok else "FAIL ",title)
func wait_draw()->void:
    for i in 4:await process_frame
    await RenderingServer.frame_post_draw
func act(s:Node3D,id:String)->void:
    s.act(id);await wait_draw()
func picture(s:Node3D,expected:Array,name:String)->void:
    panel.material_override=s.wall.material_override
    await wait_draw()
    var image:Image=viewport.get_texture().get_image()
    var uv_list:Array=[Vector2(.03,.06),Vector2(.08,.06),Vector2(.15,.20),Vector2(.22,.20),Vector2(.03,.31),Vector2(.08,.31),Vector2(.15,.31),Vector2(.4,.4),Vector2(.57,.7),Vector2(.9,.92)]
    var ok:=true;var record:Array=[]
    for i in uv_list.size():
        var p:Vector2=uv_list[i]
        var actual:Color=image.get_pixel(int(p.x*256),int(p.y*128))
        var wanted:Color=s.Recipe.PALETTE[expected[i]]
        var distance:=maxf(absf(actual.r-wanted.r),maxf(absf(actual.g-wanted.g),absf(actual.b-wanted.b)))
        ok=ok and distance<.035
        record.append({"uv":[p.x,p.y],"value":expected[i],"actual":actual.to_html(false),"expected":wanted.to_html(false),"error":distance})
    samples.append({"case":name,"samples":record})
    check("GPU readback "+name+" ten independently predicted texels",ok)
func run()->void:
    await process_frame
    var path:="";var report:="";var changed:=false
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--lesson="):path=arg.trim_prefix("--lesson=")
        if arg.begins_with("--report="):report=arg.trim_prefix("--report=")
        if arg=="--changed":changed=true
    var scene=load(path)
    if scene==null or not scene.can_instantiate():quit(2);return
    var s=scene.instantiate();s.position=Vector3(20,0,0);root.add_child(s)
    s.save_path=report.get_base_dir()+"/"+report.get_file().get_basename()+"-recipe.json"
    await wait_draw()
    var expected_shader:Shader=load(path.get_base_dir()+"/09_fabric_sample.gdshader")
    var skirt:MeshInstance3D=s.preview.outfit.get_node("Skirt")
    check("supplied studio constructs wall source editor and preview",s.cells.size()==16 and s.buttons.size()==32 and s.wall.mesh is QuadMesh and skirt.mesh is CylinderMesh)
    check("both preview receivers use printed shader",s.wall.material_override.shader==expected_shader and skirt.material_override.shader==expected_shader)
    check("two materials are independently made from one recipe",s.wall.material_override!=skirt.material_override and s.preview.outfit.skirt_fabric==s.recipe)
    check("original four by four source retained",s.recipe.cells==[[1,0,0,2],[1,0,0,0],[1,1,3,0],[0,0,0,0]])
    check("host binds named texture and parameters",s.wall.material_override.get_shader_parameter("motif") is Texture2D and s.wall.material_override.get_shader_parameter("repeats")==4.0 and s.wall.material_override.get_shader_parameter("phase")==0.0)
    var source:PackedByteArray=s.wall.material_override.get_shader_parameter("motif").get_image().get_data()
    var mesh_id:int=s.wall.mesh.get_instance_id();var vertices:PackedVector3Array=s.wall.mesh.get_mesh_arrays()[Mesh.ARRAY_VERTEX]
    var collision:BoxShape3D=s.wall.get_node("WallCollision/CollisionShape3D").shape
    var size:=collision.size
    viewport=SubViewport.new();viewport.size=Vector2i(256,128);viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
    panel=MeshInstance3D.new();var quad:=QuadMesh.new();quad.size=Vector2(2,1);panel.mesh=quad;viewport.add_child(panel)
    var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=1.0;camera.position=Vector3(0,0,3);viewport.add_child(camera);camera.current=true
    await picture(s,[1,0,3,0,0,0,0,0,0,0] if changed else [1,0,0,0,1,1,3,0,0,0],"repeat4 phase0")
    await act(s,"OFFSET")
    check("OFFSET reaches both new materials",s.recipe.offset==.125 and s.wall.material_override.get_shader_parameter("phase")==.125 and skirt.material_override.get_shader_parameter("phase")==.125)
    await picture(s,[1,0,3,1,0,0,0,0,0,0] if changed else [1,0,0,1,1,1,3,0,0,0],"repeat4 phase125")
    await act(s,"OFFSET");await act(s,"REPEAT")
    check("REPEAT changes horizontal count without phase",s.recipe.repeats==8 and s.recipe.offset==0 and s.wall.material_override.get_shader_parameter("repeats")==8.0)
    await picture(s,[1,0,1,0,0,0,0,1,0,0] if changed else [1,0,1,0,1,3,1,0,0,0],"repeat8 phase0")
    check("parameter edits preserve source pixels and mesh",s.wall.material_override.get_shader_parameter("motif").get_image().get_data()==source and s.wall.mesh.get_instance_id()==mesh_id and s.wall.mesh.get_mesh_arrays()[Mesh.ARRAY_VERTEX]==vertices and collision.size==size)
    var mat_id:int=s.wall.material_override.get_instance_id()
    s.paint_index=3;s.paint(1,0);await wait_draw()
    check("paint edits one address through existing host",s.recipe.cells[0][1]==3 and s.preview.outfit.skirt_fabric.cells[0][1]==3)
    check("adapter reapplies printed shader after fresh materials",s.wall.material_override.get_instance_id()!=mat_id and s.wall.material_override.shader==expected_shader and skirt.material_override.shader==expected_shader)
    await act(s,"UNDO");check("UNDO recovers original source",s.recipe.cells==s.Recipe.initial().cells)
    await act(s,"SAVE");var saved:Dictionary=s.saved_recipe()
    check("SAVE roundtrips supported recipe",saved==s.recipe)
    check("saved recipe excludes shader palette look and vertical count",saved.keys().size()==8 and not saved.has("shader") and not saved.has("vertical_repeats") and not saved.has("palette") and not saved.has("look"))
    var received:ShaderMaterial=s.Recipe.material(saved)
    check("saved receiver uses original shader not lesson shader",received.shader==s.Recipe.SHADER and received.shader!=expected_shader)
    check("saved receiver still has original two vertical repeats",received.shader.code.contains("vec2(repeats, 2.0)"))
    await act(s,"OFFSET");check("unsaved edit does not mutate saved file",s.recipe!=saved and s.saved_recipe()==saved)
    await act(s,"LOAD");check("LOAD restores recipe but lesson shader stays attached",s.recipe==saved and s.wall.material_override.shader==expected_shader)
    var malformed:Dictionary=saved.duplicate(true);malformed.repeats=6
    check("unsupported repeat count is rejected by declared host",not s.Recipe.valid(malformed))
    var f:=FileAccess.open(report,FileAccess.WRITE);f.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"gpu_samples":samples},"  "));f.close()
    s.queue_free();viewport.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)

