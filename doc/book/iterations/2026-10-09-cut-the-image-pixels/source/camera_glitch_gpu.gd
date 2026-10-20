extends SceneTree
const Forms=preload("res://commons/artifacts/camera_glitch_study/receivers.gd")
const Surface=preload("res://commons/artifacts/camera_glitch_study/camera_surface.gdshader")
const Channels=preload("res://commons/artifacts/camera_glitch_study/colour_plane.gdshader")
var checks:Array=[]
var viewport:SubViewport
var receiver:MeshInstance3D
var mat:ShaderMaterial
var observations:Dictionary={}
func _initialize()->void:run.call_deferred()
func check(label:String,ok:bool)->void:
	checks.append({"name":label,"passed":ok});print("GPU ","PASS " if ok else "FAIL ",label)
func texture(colour:Color)->ImageTexture:
	var im:=Image.create(64,64,false,Image.FORMAT_RGB8);im.fill(colour);return ImageTexture.create_from_image(im)
func shot(mode:int,amount:float,current:Texture2D,held:Texture2D=null)->Image:
	mat.shader=Surface;mat.set_shader_parameter("mode",mode);mat.set_shader_parameter("amount",amount);mat.set_shader_parameter("camera_frame",current)
	mat.set_shader_parameter("has_held",held!=null);mat.set_shader_parameter("held_frame",held if held!=null else current)
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	for i in 3:await process_frame;await RenderingServer.frame_post_draw
	return viewport.get_texture().get_image()
func lit_pixels(im:Image)->int:
	var result:=0
	for y in im.get_height():
		for x in im.get_width():
			if im.get_pixel(x,y).r>.8:result+=1
	return result
func run()->void:
	viewport=SubViewport.new();viewport.size=Vector2i(320,240);viewport.own_world_3d=true;root.add_child(viewport)
	var world:=Node3D.new();viewport.add_child(world)
	var camera:=Camera3D.new();world.add_child(camera);camera.position=Vector3(0,0,5);camera.current=true;camera.fov=50
	# A camera override keeps the project's NatureRenderer autoload from changing
	# this colour oracle's world environment, fog and exposure.
	camera.environment=Environment.new();camera.environment.background_mode=Environment.BG_COLOR;camera.environment.background_color=Color.BLACK
	receiver=MeshInstance3D.new();receiver.mesh=Forms.new().build(1,0);world.add_child(receiver);mat=ShaderMaterial.new();receiver.material_override=mat
	var white:=texture(Color.WHITE);var red:=texture(Color.RED);var blue:=texture(Color.BLUE)
	var flat:Image=await shot(1,0,white);var relief:Image=await shot(1,1,white)
	check("white source actually moves GPU vertices toward camera",lit_pixels(relief)>lit_pixels(flat)*1.5)
	var black:Image=await shot(1,1,texture(Color.BLACK));check("black source adds no emitted colour",lit_pixels(black)==0)
	var bands:Image=await shot(6,1,blue,red)
	var reds:=0;var blues:=0
	for y in range(75,165):
		var c:=bands.get_pixel(160,y)
		if c.r>.9 and c.b<.1:reds+=1
		if c.b>.9 and c.r<.1:blues+=1
	check("GPU bands read both real held and current textures",reds>30 and blues>30)
	observations.bands={"red":reds,"blue":blues,"centre":str(bands.get_pixel(160,120))}
	var low:Image=await shot(8,0,texture(Color(.3,.3,.3)));var cut:Image=await shot(8,1,texture(Color(.3,.3,.3)))
	check("luminance threshold removes a visible low-valued pixel",low.get_pixel(160,120).r>.05 and cut.get_pixel(160,120).r<.01)
	observations.cut={"low":str(low.get_pixel(160,120)),"cut":str(cut.get_pixel(160,120))}
	var bright:Image=await shot(8,1,white);check("luminance threshold retains white pixels",bright.get_pixel(160,120).r>.9)
	for channel in 3:
		mat.shader=Channels;mat.set_shader_parameter("camera_frame",white);var mask:=Vector3.ZERO;mask[channel]=1;mat.set_shader_parameter("channel",mask)
		viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
		for i in 3:await process_frame;await RenderingServer.frame_post_draw
		var c:=viewport.get_texture().get_image().get_pixel(160,120)
		check("colour plane %d emits only its selected channel"%channel,c[channel]>.9 and c[(channel+1)%3]<.01 and c[(channel+2)%3]<.01)
		observations["channel"+str(channel)]=str(c)
	var passed:=true
	for c in checks:passed=passed and c.passed
	var file:=FileAccess.open(OS.get_cmdline_user_args()[0],FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"passed":passed,"observations":observations,"scope":"Controlled GPU fixtures, separate from museum captures."},"  "));file.close()
	viewport.queue_free();await process_frame;quit(0 if passed else 1)
