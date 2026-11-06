extends RefCounted
## Snapshot of source-grid heights. Zero remains a hole; h=1 is the bank datum.
static func validate(raw:Dictionary)->PackedStringArray:
	var errors:=PackedStringArray()
	if not raw.has("grid_banks"):return errors
	var g:Variant=raw.grid_banks
	if not g is Dictionary:return PackedStringArray(["grid_banks must be an object"])
	var at:Variant=g.get("at");var cells:Variant=g.get("cells")
	if not at is Array or at.size()!=3 or not at.all(func(v):return (v is int or v is float) and is_finite(v) and absf(v)<=48):errors.append("grid_banks needs finite at [x,y,z] within 48m")
	if not cells is Array or cells.is_empty() or cells.size()>80:return PackedStringArray(["grid_banks needs 1..80 rows"])
	var width:int=cells[0].size() if cells[0] is Array else 0
	if width<1 or width>80:errors.append("grid_banks needs 1..80 columns")
	for row in cells:
		if not row is Array or row.size()!=width:errors.append("grid_banks rows must be rectangular");continue
		if not row.all(func(v):return (v is int or v is float) and is_equal_approx(v,roundf(v)) and v>=0 and v<=6):errors.append("grid_banks heights must be integers 0..6")
	return errors

static func build_all(b:Object,raw:Dictionary)->void:
	if not raw.has("grid_banks"):return
	var g:Dictionary=raw.grid_banks;var used:Dictionary={};var cells:Array=g.cells
	var origin:=Vector3(g.at[0],g.at[1],g.at[2])
	var occupied:=0;var holes:=0
	for z in cells.size():
		for x in cells[z].size():
			var h:int=cells[z][x]
			if h==0:holes+=1;continue
			occupied+=1
			if used.has(Vector2i(x,z)):continue
			var span:=1
			if z+1<cells.size() and x+1<cells[z].size() and cells[z][x+1]==h and cells[z+1][x]==h and cells[z+1][x+1]==h and not used.has(Vector2i(x+1,z)) and not used.has(Vector2i(x,z+1)) and not used.has(Vector2i(x+1,z+1)):span=2
			var p:Vector3=origin+Vector3(x-.5,h-1,z-.5)
			b.tile("source_%d_%d"%[x,z],p,span)
			for dx in span:
				for dz in span:used[Vector2i(x+dx,z+dz)]=true
			# Legs stay within occupied cells; no beam bridges a source hole.
			if p.y>0:
				for corner in [Vector3.ZERO,Vector3(span,0,span)]:
					# Match the fitted plate's node seat, keeping whole-metre rods.
					var seat:float=.04 if b.design.appearance.get("workshop_profile","")=="fitted" else 0.0
					var end:Vector3=p+corner-Vector3.UP*seat
					b.bar("source_leg_%d_%d_%s"%[x,z,str(corner)],Vector3(end.x,-seat,end.z),end)
	b.recipe["source_grid"]={"map":g.get("map",""),"crop":g.get("crop",[]),"occupied":occupied,"holes":holes,"at":g.at}
	for ratio in [.2,.8]:
		b.recipe.work_lights.append({"position":[origin.x+cells[0].size()*ratio,origin.y+4,origin.z+cells.size()*.5],"energy":1.2,"range":22})
