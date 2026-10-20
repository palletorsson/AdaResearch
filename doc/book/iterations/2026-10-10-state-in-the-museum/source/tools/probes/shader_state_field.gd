extends SceneTree
const Field=preload("res://commons/artifacts/shader_state_chamber/field.gd")
var failures:=0
func _initialize()->void:call_deferred("run")
func check(ok:bool,text:String)->void:
	print("PASS " if ok else "FAIL ",text)
	if not ok:failures+=1
func wait_field(f)->void:
	while f.busy or f.pending_steps>0 or f.pending_reset>=0 or not f.brush_queue.is_empty():await process_frame
	await RenderingServer.frame_post_draw
func run()->void:
	var f:=Field.new();root.add_child(f)
	await process_frame
	f.reset(false);await wait_field(f)
	f.step(8);await wait_field(f)
	var uniform:=f.state_texture.get_image()
	print("UNIFORM ",uniform.get_pixel(40,40)," ",Field.decode(uniform.get_pixel(40,40)))
	check(Field.decode(uniform.get_pixel(40,40)).is_equal_approx(Vector2(1,0)),"uniform fixed point survives eight GPU steps")
	f.reset(true);await wait_field(f)
	var before:=f.state_texture.get_image()
	f.step();await wait_field(f)
	var after:=f.state_texture.get_image();var error:=0.0
	for y in range(Field.SIZE):
		for x in range(Field.SIZE):
			var c:Vector2=Field.decode(before.get_pixel(x,y));var lap:Vector2=-c
			for d in [Vector2i(-1,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1)]:lap+=.2*Field.decode(before.get_pixel(posmod(x+d.x,Field.SIZE),posmod(y+d.y,Field.SIZE)))
			for d in [Vector2i(-1,-1),Vector2i(1,-1),Vector2i(-1,1),Vector2i(1,1)]:lap+=.05*Field.decode(before.get_pixel(posmod(x+d.x,Field.SIZE),posmod(y+d.y,Field.SIZE)))
			var r:float=c.x*c.y*c.y
			var expected:Vector2=(c+Vector2(lap.x-r+f.feed*(1-c.x),.5*lap.y+r-(f.feed+f.kill)*c.y)).clamp(Vector2.ZERO,Vector2.ONE)
			error=maxf(error,Field.decode(after.get_pixel(x,y)).distance_to(expected))
	print("MAX CPU/GPU ERROR ",error)
	check(error<.001,"one GPU step matches independent CPU equation at every cell")
	f.step(5999);await wait_field(f)
	var grown:=f.state_texture.get_image();grown.save_png("res://ada_run/shader_state_data.png")
	var cells:=0
	var visual:=Image.create(Field.SIZE,Field.SIZE,false,Image.FORMAT_RGB8)
	for y in range(Field.SIZE):
		for x in range(Field.SIZE):
			var b:=Field.decode(grown.get_pixel(x,y)).y
			if b>.1:cells+=1
			visual.set_pixel(x,y,Color("ddd5c3").lerp(Color("143436"),smoothstep(.05,.30,b)))
	visual.resize(768,768,Image.INTERPOLATE_NEAREST);visual.save_png("res://ada_run/shader_state_visual.png")
	print("GROWN CELLS ",cells," / ",Field.SIZE*Field.SIZE)
	check(cells>500,"seed grows beyond its initial discs")
	f.queue_free();await process_frame;quit(0 if failures==0 else 1)
