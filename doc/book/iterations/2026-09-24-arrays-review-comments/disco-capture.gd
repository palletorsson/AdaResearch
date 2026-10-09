extends "res://tools/probes/disco_super_triangle.gd"
## Capture-only override: hide the desktop overlay, retain native geometry and controls.
var native_frames:Dictionary={}
func snapshot(title:String,eye:Vector3,target:Vector3,fov:float=55.0) -> void:
	for node in root.find_children("*","Node",true,false):
		if node.get_script()!=null and str(node.get_script().resource_path).ends_with("/MushroomHand.gd"):
			node.show_desktop_count=false
			var hud:CanvasLayer=node.get("_hud")
			if hud!=null:hud.visible=false
	await super.snapshot(title,eye,target,fov)
	if DisplayServer.get_name()!="headless":native_frames[title]=root.get_texture().get_image()
func contact_sheet(title:String,names:Array,columns:int) -> void:
	var width:=900;var height:=600;var gap:=12
	var rows:=ceili(float(names.size())/columns)
	var sheet:=Image.create(columns*width+(columns-1)*gap,rows*height+(rows-1)*gap,false,Image.FORMAT_RGB8)
	sheet.fill(Color("f5f0e8"))
	for i in names.size():
		check("native frame available "+str(names[i]),native_frames.has(names[i]))
		if not native_frames.has(names[i]):return
		var frame:Image=native_frames[names[i]].duplicate()
		frame.resize(width,height,Image.INTERPOLATE_LANCZOS);frame.convert(Image.FORMAT_RGB8)
		sheet.blit_rect(frame,Rect2i(0,0,width,height),Vector2i((i%columns)*(width+gap),int(i/columns)*(height+gap)))
	check("native contact sheet saved "+title,sheet.save_png(ProjectSettings.globalize_path(folder+title+".png"))==OK)
func finish() -> void:
	contact_sheet("fixed-addresses-changing-values",["checker-zero","checker-one"],2)
	contact_sheet("triangle-combinations",["triangles-00","triangles-04","triangles-08","triangles-12","triangles-16","triangles-20"],3)
	super.finish()
