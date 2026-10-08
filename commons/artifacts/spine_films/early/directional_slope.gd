extends "res://commons/artifacts/spine_films/film_stage.gd"
const E=preload("res://commons/artifacts/spine_films/early/geometry.gd")
var source:Node3D
var patches:Array[MeshInstance3D]=[]
var slices:Array[Node3D]=[]
var rods:Array[MeshInstance3D]=[]
var marker:MeshInstance3D
var grid_lines:Array[MeshInstance3D]=[]
var station:=Vector2(-0.55,-0.545)
var sample:Vector3
var dx:=0.0
var dz:=0.0

func _build()->void:
	title_text="One position, two slopes"
	phases.assign(["A function lifts the mesh", "Hold one coordinate still", "Ask along the other axis", "Two signs, one gradient"])
	notes.assign(["Mesh heights come from the existing terrain function.","The pink slice varies x while z stays fixed.","The blue slice varies z while x stays fixed.","At this source station one partial rises and the other falls."])
	source_paths.assign(["res://algorithms/change/partial_derivative_terrain.gd"])
	source=load(source_paths[0]).new()
	for z in range(16):
		for x in range(16):
			var v:=PackedVector3Array()
			var a:=Vector2(-1+float(x)/8,-1+float(z)/8)
			for corner in [a,a+Vector2(0.125,0),a+Vector2(0.125,0.125),a,a+Vector2(0.125,0.125),a+Vector2(0,0.125)]:
				v.append(point(corner.x,corner.y))
			patches.append(E.face(display,v,Color("678d86")))
	for axis in range(2):
		for row in range(9):
			var fixed:=float(row)/4.0-1.0
			for segment in range(16):
				var t0:=float(segment)/8.0-1.0
				var t1:=t0+0.125
				var a:=point(t0,fixed) if axis==0 else point(fixed,t0)
				var b:=point(t1,fixed) if axis==0 else point(fixed,t1)
				grid_lines.append(E.line(display,a+Vector3.UP*0.008,b+Vector3.UP*0.008,Color("91ada1"),0.006))
	for axis in range(2):
		var holder:=Node3D.new();display.add_child(holder);slices.append(holder)
		for i in range(40):
			var t0:float=-1+float(i)/20;var t1:float=t0+0.05
			var a:=point(t0,station.y) if axis==0 else point(station.x,t0)
			var b:=point(t1,station.y) if axis==0 else point(station.x,t1)
			E.line(holder,a+Vector3.UP*0.02,b+Vector3.UP*0.02,E.PINK if axis==0 else E.BLUE,0.018)
	sample=point(station.x,station.y)
	marker=E.sphere(display,sample+Vector3.UP*0.06,0.065,E.GOLD)
	dx=float(source.call("_df_dx",station.x,station.y));dz=float(source.call("_df_dy",station.x,station.y))
	rods.append(E.line(display,sample,sample+Vector3(1,dx,0)*0.8,E.PINK,0.025))
	rods.append(E.line(display,sample,sample+Vector3(0,dz,1)*0.8,E.BLUE,0.025))
	rods.append(E.line(display,sample+Vector3.UP*0.2,sample+Vector3(dx,0,dz)*2+Vector3.UP*0.2,E.GOLD,0.035))
	evidence={"station":station,"partial_x":dx,"partial_z":dz,"opposite_signs":dx*dz<0,"terrain_source_function":"_f","partial_source_functions":["_df_dx","_df_dy"],"render_samples":17*17}
	frame_scene(Vector3(0,0.9,0),8.3,0.5,0.55)

func point(x:float,z:float)->Vector3:
	return Vector3(x*2.2,0.8+float(source.call("_f",x,z))*2.2,z*2.2)

func _draw(time:float)->void:
	var p:=phase_index(time);var u:=phase_progress(time)
	for i in range(patches.size()):patches[i].visible=p>0 or float(i)<u*patches.size()
	for line in grid_lines:line.visible=p>0 or u>0.7
	slices[0].visible=p>=1;slices[1].visible=p>=2
	rods[0].visible=p>=1;rods[1].visible=p>=2;rods[2].visible=p>=3
	marker.visible=p>=1

func _exit_tree()->void:
	if is_instance_valid(source):source.free()
