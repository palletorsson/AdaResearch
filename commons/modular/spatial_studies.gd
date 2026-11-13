extends RefCounted
## Small, deterministic spatial studies. Transformations make the question visible;
## all generated members remain static, individually editable construction pieces.
## Numeric counterpart: ada_encyclopedia/src/lib/spatial-studies.ts.
static func expression(e: Dictionary) -> Dictionary:
	var parts: Array = []
	var count := clampi(int(e.get("count",8)),2,18)
	var size := float(e.get("size",1))
	var kind := str(e.get("kind","domino"))
	if kind=="sphere_fractal":
		return preload("res://commons/modular/sphere_fractal.gd").expression(e)
	elif kind=="fractal_assembly":
		return preload("res://commons/modular/fractal_assemblage.gd").expression(e)
	elif kind=="tree":
		_branch(parts,e,Vector3.ZERO,0,size,0,"Root")
	elif kind=="random":
		var state := [maxi(1,int(e.get("seed",17)))]
		var cols := int(e.get("columns",5));var rows := int(e.get("rows",5))
		var spacing := float(e.get("spacing",1.3))
		for z in rows:
			for x in cols:
				# Consume the same draws even for an omitted cell: other cells stay put.
				var keep := _random(state);var dx := _random(state)*2-1;var dz := _random(state)*2-1
				var yaw := (_random(state)*2-1)*float(e.get("angle",45))
				var height := size*(.6+_random(state)*.8)
				if (x!=0 or z!=0) and keep<float(e.get("missing",.18)):continue
				var scatter := float(e.get("scatter",.4))*spacing*.5
				_piece(parts,e,"Cell%02d_%02d"%[x+1,z+1],Vector3((x-(cols-1)/2.0)*spacing+dx*scatter,height/2,(z-(rows-1)/2.0)*spacing+dz*scatter),Vector3(0,yaw,0),Vector3(size,height,size))
	elif kind=="domino":
		var cursor := 0.0
		var half_before := 0.0
		var half_first := 0.0
		for i in count:
			var s := size*pow(float(e.get("ratio",1.18)),i)
			var dims := Vector3(.22,.9,.6)*s
			var lean := deg_to_rad(float(e.get("lean",0)))
			var half := (absf(cos(lean))*dims.x+absf(sin(lean))*dims.y)/2
			if i==0:half_first=half
			if i>0:cursor+=half_before+float(e.get("gap",.25))*size+half
			var y := (absf(cos(lean))*dims.y+absf(sin(lean))*dims.x)/2
			_piece(parts,e,"Copy%02d"%(i+1),Vector3(cursor,y,0),Vector3(0,0,rad_to_deg(lean)),dims)
			half_before=half
		var center := (-half_first+cursor+half_before)/2
		for p in parts:p.at[0]-=center
	else:
		var cursor := Vector3.ZERO
		var centers: Array[Vector3]=[]
		for i in count:
			var yaw := deg_to_rad(i*float(e.get("turn",0)))
			var pitch := deg_to_rad(i*float(e.get("pitch",0)))
			if kind=="passage" and i>0:
				var mid := Vector3(deg_to_rad((i-.5)*float(e.get("pitch",0))),deg_to_rad((i-.5)*float(e.get("turn",0))),0)
				cursor+=Basis.from_euler(mid)*Vector3(0,0,float(e.get("gap",.7))*size)
			elif kind=="threshold":cursor=Vector3(0,0,(i-(count-1)/2.0)*float(e.get("gap",1.2))*size)
			centers.append(cursor)
			var ratio := pow(float(e.get("ratio",1)),i)
			var w := float(e.get("opening",2.4))*size*ratio
			var h := 2.4*size*ratio
			var thick := .16*size
			var floor_thick := .08*size
			var rot := Vector3(rad_to_deg(pitch),rad_to_deg(yaw),i*float(e.get("twist",0)))
			var basis := Basis.from_euler(rot*PI/180)
			var center := cursor+Vector3(0,h/2+.004*size,0)
			# A threshold is an isolated frame, a passage is a thick overlapping rib.
			var depth := .2*size if kind=="threshold" else float(e.get("gap",.7))*size*1.16
			var prefix := "Frame%02d_"%(i+1)
			for side in [-1,1]:
				_piece(parts,e,prefix+("Left" if side<0 else "Right"),center+basis*Vector3(side*(w+thick)/2,0,0),rot,Vector3(thick,h,depth))
			_piece(parts,e,prefix+"Top",center+basis*Vector3(0,(h+thick)/2,0),rot,Vector3(w+2*thick,thick,depth))
			_piece(parts,e,prefix+"Floor",center+basis*Vector3(0,-(h+floor_thick)/2,0),rot,Vector3(w+2*thick,floor_thick,depth))
		if kind=="passage":
			var midpoint := (centers[0]+centers[-1])/2
			for p in parts:
				p.at[0]-=midpoint.x;p.at[2]-=midpoint.z
	return {"op":"assemblage","parts":parts}

static func _random(state: Array) -> float:
	state[0]=(int(state[0])*48271)%2147483647
	return float(state[0])/2147483647.0

static func _branch(parts: Array,e: Dictionary,base: Vector3,angle: float,s: float,level: int,id: String) -> void:
	var basis := Basis(Vector3.BACK,deg_to_rad(angle))
	var end := base+basis*Vector3(0,2*s,0)
	_piece(parts,e,id,(base+end)/2,Vector3(0,0,angle),Vector3(.16,2,.16)*s)
	if level<int(e.get("depth",3)):
		for side in [-1,1]:
			_branch(parts,e,end,angle+side*float(e.get("angle",32)),s*float(e.get("ratio",.7)),level+1,id+("L" if side<0 else "R"))

static func _piece(parts: Array,e: Dictionary,id: String,pos: Vector3,rot: Vector3,dims: Vector3) -> void:
	parts.append({"id":id,"at":[pos.x,pos.y,pos.z],"rot":[rot.x,rot.y,rot.z],"of":{"p":"prefab","token":str(e.get("source","construction_cube")),"lab_input":true,"fit_box":[dims.x,dims.y,dims.z]}})
