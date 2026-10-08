extends "res://commons/artifacts/spine_films/film_stage.gd"
const E=preload("res://commons/artifacts/spine_films/early/geometry.gd")
const Sim=preload("res://commons/pattern_grammar/pattern_sim.gd")
const Groups=preload("res://commons/primitives/arrays/wallpaper_groups.gd")
var tiles:Array[MeshInstance3D]=[]
var source_grid:Array=[]
var changed_grid:Array=[]
var colors:Array[Color]=[]
var color_ids:Array[int]=[]
var changed_ids:Array[int]=[]
var marker:Node3D

func _build()->void:
	title_text="A fragment becomes a pattern"
	phases.assign(["The mill's five-by-five motif", "Mirror and turn", "A sheet from the same rule", "One edited cell returns elsewhere"])
	notes.assign(["Seed 7, density 0.5, the existing Bauhaus palette.","The real wallpaper-group lookup chooses every colour.","Raised cells reveal the output; the mill itself uses a texture.","One source cell changes. Its transformed occurrences light up."])
	source_paths.assign(["res://commons/artifacts/pattern_mill/pattern_mill.gd","res://commons/pattern_grammar/pattern_sim.gd","res://commons/primitives/arrays/wallpaper_groups.gd"])
	for c:Array in Sim.PALETTES.bauhaus:colors.append(Color(c[0],c[1],c[2]))
	source_grid=Sim.generate_motif(5,colors.size(),7,0.5)
	changed_grid=source_grid.duplicate(true)
	changed_grid[1][2]=(int(changed_grid[1][2])+1)%colors.size()
	for y in range(20):
		for x in range(20):
			var ci:int=Groups.get_symmetric_color(x,y,5,source_grid,Groups.Group.P4M)
			var edited:int=Groups.get_symmetric_color(x,y,5,changed_grid,Groups.Group.P4M)
			color_ids.append(ci);changed_ids.append(edited)
			var tile:=E.box(display,Vector3((x-9.5)*0.235,0.18,(y-9.5)*0.235),Vector3(0.222,0.09,0.222),colors[ci])
			tiles.append(tile)
	marker=E.frame(display,Vector3(1.175,0.13,1.175),E.PINK)
	marker.position=Vector3(-1.7625,0.26,-1.7625)
	var changed:=0
	for i in range(color_ids.size()):if color_ids[i]!=changed_ids[i]:changed+=1
	evidence={"group":"p4m","seed":7,"motif_size":5,"output_cells":400,"changed_source_cell":Vector2i(2,1),"changed_output_cells":changed,"source_lookup":true}
	frame_scene(Vector3(0,0.6,0),9.5,0.4,0.65)

func _draw(time:float)->void:
	var p:=phase_index(time);var u:=phase_progress(time)
	var focus:=Vector3(-1.7625,0.35,-1.7625)
	var distance:=3.4
	if p==1:
		focus=focus.lerp(Vector3(-1.175,0.4,-1.175),smoothstep(0,1,u))
		distance=lerpf(3.4,5.5,smoothstep(0,1,u))
	elif p>=2:
		var amount:=smoothstep(0,0.55,u) if p==2 else 1.0
		focus=Vector3(-1.175,0.4,-1.175).lerp(Vector3(0,0.6,0),amount)
		distance=lerpf(5.5,9.5,amount)
	frame_scene(focus,distance,_azimuth,0.65)
	for i in range(tiles.size()):
		var x:=i%20;var y:=i/20
		var in_unit:=x<5 and y<5
		var in_four:=x<10 and y<10
		tiles[i].visible=in_unit if p==0 else (in_four if p==1 else true)
		var lift:=0.0
		if p==1:lift=(1.0-smoothstep(0,1,u))*float((x/5)+(y/5))*0.6
		if p==2:lift=maxf(0,float(y)/20.0-u)*1.8
		var changed:=color_ids[i]!=changed_ids[i]
		if p==3 and changed:lift=sin(u*PI)*0.7
		tiles[i].position.y=0.18+lift
		tiles[i].material_override.albedo_color=colors[int(source_grid[y][x])] if p==0 and in_unit else (colors[changed_ids[i]] if p==3 and u>=0.45 else colors[color_ids[i]])
	marker.visible=p==0 or p==3

