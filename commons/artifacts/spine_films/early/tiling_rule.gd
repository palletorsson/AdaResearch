extends "res://commons/artifacts/spine_films/film_stage.gd"
const E=preload("res://commons/artifacts/spine_films/early/geometry.gd")
const Pattern=preload("res://commons/artifacts/regularity/tiling_pattern.gd")
var tiles:Array[Node3D]=[]
var skins:Array[MeshInstance3D]=[]
var before:Array[Texture2D]=[]
var after:Array[Texture2D]=[]
var field:MeshInstance3D
var chart:Array[MeshInstance3D]=[]

func sheet(parent:Node,at:Vector3,size:Vector2,texture:Texture2D)->MeshInstance3D:
	var plane:=PlaneMesh.new();plane.size=size
	var n:=E.mesh(parent,plane,E.WHITE);n.position=at
	n.material_override=E.material(E.WHITE,true)
	n.material_override.albedo_texture=texture
	n.material_override.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
	return n

func _build()->void:
	title_text="One instruction reaches a whole floor"
	phases.assign(["Sixteen copies", "Change the rule at each address", "The same rule, sixteen by sixteen", "How far can you read it?"])
	notes.assign(["The source is one black-and-white triangle tile.","turn = source + ((x + y) % 4)","The larger field calls the same image_for function.","The eye chart keeps the pattern and changes only its apparent size."])
	source_paths.assign(["res://commons/artifacts/regularity/tiling_pattern.gd","res://commons/artifacts/regularity/tiling_rule_study.gd"])
	var a:Image=Pattern.image_for(0,0,false,4,4,32)
	var b:Image=Pattern.image_for(2,0,false,4,4,32)
	for y in range(4):
		for x in range(4):
			var holder:=Node3D.new();display.add_child(holder)
			holder.position=Vector3((x-1.5)*0.72,0.65,(y-1.5)*0.72)
			E.box(holder,Vector3.ZERO,Vector3(0.67,0.06,0.67),E.INK)
			before.append(ImageTexture.create_from_image(a.get_region(Rect2i(x*32,y*32,32,32))))
			after.append(ImageTexture.create_from_image(b.get_region(Rect2i(x*32,y*32,32,32))))
			skins.append(sheet(holder,Vector3(0,0.032,0),Vector2(0.67,0.67),before[-1]))
			tiles.append(holder)
	field=sheet(display,Vector3(0,0.08,0),Vector2(5.5,5.5),ImageTexture.create_from_image(Pattern.image_for(2,0,false,16,16,24)))
	for i in range(4):
		var edge:=0.95-pow(float(i)/4.0,0.7)*0.65
		var n:=sheet(display,Vector3(2.15,2.5-float(i)*0.55,-1.5),Vector2.ONE*edge,ImageTexture.create_from_image(b))
		n.rotation_degrees.x=90;chart.append(n)
	evidence={"local_size":Vector2i(4,4),"field_size":Vector2i(16,16),"rule_before":0,"rule_after":2,"source_function":"image_for","identical_chart_texture":true,"physical_tiles_are_explanation":true}
	frame_scene(Vector3(0,0.7,0),9.2,0.5,0.65)

func _draw(time:float)->void:
	var p:=phase_index(time);var u:=phase_progress(time)
	for i in range(16):
		var local_u:=clampf(u*16-float(i),0,1)
		tiles[i].visible=p<3
		tiles[i].position.y=0.65+(sin(local_u*PI)*0.65 if p==1 else 0.0)
		skins[i].material_override.albedo_texture=after[i] if p>=2 or (p==1 and local_u>=0.5) else before[i]
		if p==2:tiles[i].scale=Vector3.ONE*lerpf(1,0.46,smoothstep(0,1,u))
		else:tiles[i].scale=Vector3.ONE
	field.visible=p>=2
	for n in chart:n.visible=p==3
	evidence["updated_tiles"]=clampi(int(u*16),0,16) if p==1 else (16 if p>=2 else 0)
