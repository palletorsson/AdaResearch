extends SceneTree
## Apply saved filter recipes to captured PNGs. Run from the project with --recipe=res://...json.
var folder: String
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	var recipe_path:=""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--recipe="): recipe_path=arg.trim_prefix("--recipe=")
	if recipe_path.is_empty():push_error("Pass --recipe=res://path/to/filters.json");quit(1);return
	var recipe: Variant=JSON.parse_string(FileAccess.get_file_as_string(recipe_path))
	if not recipe is Dictionary or not recipe.get("images") is Array:push_error("Invalid filter recipe");quit(1);return
	folder=recipe_path.get_base_dir()+"/"
	root.size=Vector2i(int(recipe.width),int(recipe.height))
	var rect:=TextureRect.new();rect.size=Vector2(root.size);root.add_child(rect)
	var shader:=ShaderMaterial.new();shader.shader=preload("book_image_filter.gdshader");rect.material=shader
	var outputs: Array=[]
	for item in recipe.images:
		var source:=Image.load_from_file(folder+item.source)
		if source==null or source.is_empty():push_error("Missing capture: "+str(item.source));quit(1);return
		var texture:=ImageTexture.create_from_image(source)
		rect.texture=texture;shader.set_shader_parameter("source_image",texture);shader.set_shader_parameter("source_size",Vector2(source.get_size()))
		for preset in recipe.presets:
			shader.set_shader_parameter("treatment",int(preset.mode));shader.set_shader_parameter("line_width",float(preset.line_width));shader.set_shader_parameter("sensitivity",float(preset.sensitivity))
			shader.set_shader_parameter("edge_softness",float(preset.get("edge_softness",0.18)))
			for frame in 3:await process_frame
			for layer in root.find_children("*","CanvasLayer",true,false):layer.visible=false
			await RenderingServer.frame_post_draw
			var path:=folder+str(item.id)+"-"+str(preset.id)+".png"
			var result:=root.get_texture().get_image().save_png(path)
			if result!=OK:push_error("Image write failed: "+path);quit(1);return
			outputs.append(path.trim_prefix(folder))
	FileAccess.open(folder+"filter-results.json",FileAccess.WRITE).store_string(JSON.stringify({"recipe":recipe_path,"outputs":outputs,"count":outputs.size(),"dimensions":[root.size.x,root.size.y],"method":"Saved contour/hatch/ink or local-contrast page ink; no synthesized geometry or text"},"  "))
	print("BOOK IMAGE FILTERS ",outputs.size()," PNGs written")
	quit(0)
