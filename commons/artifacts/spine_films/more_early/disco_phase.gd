extends "res://commons/artifacts/spine_films/film_stage.gd"
const G=preload("res://commons/artifacts/spine_films/early/geometry.gd")
const SOURCE="res://commons/artifacts/regularity/disco_controls.gd"
var source:Node3D
var cells:Array=[]
var labels:Array[Label3D]=[]
var source_values: Array[int]=[]
var headings: Array[Label3D]=[]
const SIDE:=8

func _build()->void:
	title_text="One phase travels through sixty-four addresses"
	phases=["THE ROW TURNS BACK","ADVANCE ONE PHASE","CROSS THE LAST ADDRESS","THE PALETTE IS ANOTHER CHOICE"]
	notes=["The source's snake index reverses X on every second row.","A strip of eight active cells moves as the integer phase advances.","Modulo 64 returns the moving strip to the first addresses.","The same binary values can select another pair of colours. Height here is only a reading aid."]
	source_paths=[SOURCE];source=load(SOURCE).new();source.pattern=3
	for board in range(2):
		var row:Array[MeshInstance3D]=[]
		var cx:float=-2.1 if board==0 else 2.1
		G.box(display,Vector3(cx,.05,0),Vector3(3.65,.1,3.65),Color("293c4e"))
		for z in SIDE:
			for x in SIDE:
				var tile:=G.box(display,Vector3(cx+(x-3.5)*.43,.17,(z-3.5)*.43),Vector3(.4,.16,.4),G.WHITE);row.append(tile)
		cells.append(row)
		headings.append(G.label(display,"",Vector3(cx,1.00,-2),G.WHITE,.18))
		if board==1:
			for i:int in [0,7,8,15,56,63]:
				var z:int=i/SIDE;var x:int=i%SIDE if z%2==0 else SIDE-1-i%SIDE
				labels.append(G.label(display,str(i),Vector3(cx+(x-3.5)*.43,.42,(z-3.5)*.43),G.GOLD,.13))
	source.phase=0
	for z in SIDE:
		for x in SIDE:source_values.append(source.value_at(x,z,SIDE,SIDE))
	evidence={"width":SIDE,"depth":SIDE,"active_count":source_values.count(1),"period":SIDE*SIDE,"pattern":"snake","method":"disco_controls.value_at; PALETTES","raised_cells":"explanatory only; the live floor changes colour"}
	frame_scene(Vector3(0,.2,0),10.9,.21,.64)

func _draw(time:float)->void:
	var p:=phase_index(time);var u:=phase_progress(time)
	var value:=0
	match p:
		0:value=0
		1:value=int(u*31)
		2:value=56+int(u*16)
		3:value=24
	for board in range(2):
		source.phase=(24 if p==3 else 0) if board==0 else value
		var palette:int=1 if board==1 and p==3 else 0
		for z in SIDE:
			for x in SIDE:
				var v:int=source.value_at(x,z,SIDE,SIDE)
				var node:MeshInstance3D=cells[board][z*SIDE+x]
				node.position.y=.17+float(v)*.14
				node.material_override.albedo_color=source.PALETTES[palette][v]
		headings[board].text=("REFERENCE / phase 24" if p==3 else "REFERENCE / phase 0") if board==0 else "phase %d / modulo 64 = %d" % [value,posmod(value,64)]
	for label in labels:label.visible=p==0 or p==2

func validation()->Dictionary:
	var before:Array[int]=[];var after:Array[int]=[]
	source.phase=0
	for z in SIDE:
		for x in SIDE:before.append(source.value_at(x,z,SIDE,SIDE))
	source.phase=64
	for z in SIDE:
		for x in SIDE:after.append(source.value_at(x,z,SIDE,SIDE))
	return {"passed":before==after and before.count(1)==8,"evidence":evidence}

func _exit_tree()->void:
	if is_instance_valid(source):source.free()
