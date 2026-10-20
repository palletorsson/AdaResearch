extends "res://tools/probes/camera_glitch_gpu.gd"
const PixelSurface=preload("res://commons/artifacts/camera_glitch_study/pixel_surface.gdshader")
func pixel_shot(mode:int,amount:float,source:Texture2D,held:Texture2D)->Image:
	mat.shader=PixelSurface;mat.set_shader_parameter("mode",mode);mat.set_shader_parameter("amount",amount)
	mat.set_shader_parameter("camera_frame",source);mat.set_shader_parameter("held_frame",held);mat.set_shader_parameter("has_held",true)
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	for i in 3:await process_frame;await RenderingServer.frame_post_draw
	return viewport.get_texture().get_image()
func source_at(base:Image,x:int,y:int)->Color:
	return base.get_pixel(int((posmod(x,64)+.5)*5),30+int((posmod(y,36)+.5)*5))
func same(a:Color,b:Color)->bool:
	return absf(a.r-b.r)<.01 and absf(a.g-b.g)<.01 and absf(a.b-b.b)<.01
func run()->void:
	viewport=SubViewport.new();viewport.size=Vector2i(320,240);viewport.own_world_3d=true;root.add_child(viewport)
	var world:=Node3D.new();viewport.add_child(world);var camera:=Camera3D.new();world.add_child(camera)
	camera.position=Vector3(0,0,5);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=2.4;camera.current=true
	camera.environment=Environment.new();camera.environment.background_mode=Environment.BG_COLOR;camera.environment.background_color=Color.BLACK
	receiver=MeshInstance3D.new();receiver.mesh=Forms.new().build(2,0);world.add_child(receiver);mat=ShaderMaterial.new();receiver.material_override=mat
	var im:=Image.create(64,36,false,Image.FORMAT_RGB8)
	for y in 36:
		for x in 64:im.set_pixel(x,y,Color(x/63.0,y/35.0,float((x*7+y*3)%64)/63))
	var source:=ImageTexture.create_from_image(im);var held:=texture(Color.RED)
	var before:=source.get_image().get_data().hex_encode().sha256_text()
	var base:Image=await pixel_shot(0,0,source,held);var baseline:=base.get_data().hex_encode().sha256_text()
	var outputs:Array[Image]=[]
	for mode in 10:
		var zero:Image=await pixel_shot(mode,0,source,held)
		check("pixel %d: zero amount is pixel-identical to unchanged source"%mode,zero.get_data().hex_encode().sha256_text()==baseline)
		var changed:Image=await pixel_shot(mode,1,source,held);outputs.append(changed)
		check("pixel %d: operation changes the rendered image"%mode,changed.get_data().hex_encode().sha256_text()!=baseline)
	# At screen (102,72), the known source address is (20,8).
	check("chopped band reads offset source pixel",same(outputs[0].get_pixel(102,72),source_at(base,34,8)))
	check("wrong stride reads row8 column60",same(outputs[1].get_pixel(102,72),source_at(base,60,8)))
	check("repeated row reads row6 instead of row8",same(outputs[2].get_pixel(102,72),source_at(base,20,6)))
	check("block permutation reads block41 local pixel",same(outputs[3].get_pixel(102,72),source_at(base,12,32)))
	var split:=Color(source_at(base,23,8).r,source_at(base,20,8).g,source_at(base,17,8).b)
	check("RGB channels use three different pixel addresses",same(outputs[4].get_pixel(102,72),split))
	check("tear moves only its middle band",same(outputs[5].get_pixel(102,112),source_at(base,34,16)) and same(outputs[5].get_pixel(102,72),source_at(base,20,8)))
	check("held block reads the actual saved red texture",same(outputs[6].get_pixel(22,47),Color.RED))
	check("unselected block retains the current source",same(outputs[6].get_pixel(102,72),source_at(base,20,8)))
	var colours:Dictionary={}
	for x in range(2,320,5):colours[outputs[7].get_pixel(x,100).r]=true
	check("posterisation leaves at most four red levels",colours.size()<=4 and colours.size()>1)
	check("missing block becomes black",same(outputs[8].get_pixel(22,47),Color.BLACK))
	check("present block keeps source pixels",same(outputs[8].get_pixel(102,72),source_at(base,20,8)))
	check("serpentine reverses odd row and retains even row",same(outputs[9].get_pixel(102,77),source_at(base,43,9)) and same(outputs[9].get_pixel(102,72),source_at(base,20,8)))
	check("image operations never mutate the source texture",source.get_image().get_data().hex_encode().sha256_text()==before)
	check("flat receiver stays two triangles",receiver.mesh.surface_get_array_len(0)==6)
	var passed:=true
	for c in checks:passed=passed and c.passed
	var file:=FileAccess.open(OS.get_cmdline_user_args()[0],FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"passed":passed,"scope":"Known 64x36 pixel-address fixture rendered by native Godot; not a museum photograph."},"  "));file.close()
	viewport.queue_free();await process_frame;quit(0 if passed else 1)
