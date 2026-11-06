extends RefCounted
## Arrangement syntax over the existing workshop kit and slotted artifacts.
## at = entrance centre; the corridor travels along local -Z. Metres throughout.
const Frame=preload("res://commons/modular/places/principal_builder.gd")
const SIDES:=["left","right","floor","ceiling"]

static func number(v:Variant)->bool:
	return (v is int or v is float) and is_finite(float(v))
static func whole(v:Variant,lo:int,hi:int)->bool:
	return number(v) and v>=lo and v<=hi and is_equal_approx(float(v),roundf(float(v)))
static func validate(raw:Dictionary)->PackedStringArray:
	var errors:=PackedStringArray();var rows:Variant=raw.get("corridors",[])
	if not rows is Array:return PackedStringArray(["corridors must be an array"])
	var ids:Dictionary={}
	for c in rows:
		if not c is Dictionary:errors.append("Corridor must be an object");continue
		var id:=str(c.get("id",""))
		if not id.is_valid_identifier() or ids.has(id):errors.append("Corridor needs a unique stable id: "+id)
		ids[id]=true
		for key in c:
			if key not in ["id","at","width_bays","length_bays","module","height","surfaces","panel_turn","contents","overrides"]:errors.append(id+": unknown corridor field "+str(key))
		var at:Variant=c.get("at",null)
		if not at is Array or at.size()!=3 or not at.all(func(n):return whole(n,-48,48)):errors.append(id+": at needs three whole metres")
		elif at[1]!=0:errors.append(id+": corridor currently needs ground-level access (at.y = 0)")
		if c.get("module",2)!=2:errors.append(id+": module is the existing 2m workshop bay")
		if not whole(c.get("width_bays",2),1,4):errors.append(id+": width_bays must be 1..4")
		if not whole(c.get("length_bays",4),1,12):errors.append(id+": length_bays must be 1..12")
		if not whole(c.get("height",4),3,6):errors.append(id+": height must be 3..6m")
		if not number(c.get("panel_turn",0)) or absf(float(c.get("panel_turn",0)))>30:errors.append(id+": panel_turn must be -30..30 degrees")
		var surfaces:Variant=c.get("surfaces",["left","right"])
		if not surfaces is Array or surfaces.is_empty():errors.append(id+": surfaces must be a non-empty array")
		else:
			var seen:Dictionary={}
			for side in surfaces:
				if side not in SIDES or seen.has(side):errors.append(id+": invalid or duplicate surface "+str(side))
				seen[side]=true
		var contents:Variant=c.get("contents",{})
		if not contents is Dictionary:errors.append(id+": contents must map surfaces to example arrays")
		else:
			for side in contents:
				if side not in SIDES or not contents[side] is Array or contents[side].is_empty():errors.append(id+": contents need a non-empty array for "+str(side));continue
				for item in contents[side]:
					if not item is Dictionary or str(item.get("artifact","display_plate")).is_empty() or not item.get("config",{}) is Dictionary:errors.append(id+": invalid content item")
		var overrides:Variant=c.get("overrides",{})
		if not overrides is Dictionary:errors.append(id+": overrides must be keyed by stable panel id")
		else:
			for key in overrides:
				var o:Variant=overrides[key]
				if not str(key).is_valid_identifier() or not o is Dictionary:errors.append(id+": invalid panel override");continue
				for field in o:
					if field not in ["omit","config","position","rotation"]:errors.append(id+": unknown override field "+str(field))
				if o.has("omit") and not o.omit is bool:errors.append(id+": omit must be boolean")
				if o.has("config") and not o.config is Dictionary:errors.append(id+": override config must be an object")
				for field in ["position","rotation"]:
					if o.has(field) and (not o[field] is Array or o[field].size()!=3 or not o[field].all(func(n):return number(n))):errors.append(id+": override "+field+" needs three finite numbers")
	return errors

static func build_all(builder:Object,raw:Dictionary)->void:
	for c in raw.get("corridors",[]):build(builder,c)

static func build(builder:Object,c:Dictionary)->void:
	var id:String=c.id;var width:float=float(c.get("width_bays",2))*2
	var count:int=int(c.get("length_bays",4));var length:float=count*2.0;var height:float=c.get("height",4)
	var at:=Vector3(c.at[0],c.at[1],c.at[2]);var half:=width*.5
	# The flat route is the kit itself. Side columns and crossheads never cross the walking volume.
	builder.floor_rect(id+"_deck",at.x-half,at.z-length,int(width),int(length),at.y+.02)
	for i in count+1:
		var z:float=at.z-i*2
		for sx in [-1,1]:builder.bar(id+"_post_%d_%d"%[i,sx],Vector3(at.x+sx*half,at.y,z),Vector3(at.x+sx*half,at.y+height,z))
		builder.bar(id+"_crosshead_%d"%i,Vector3(at.x-half,at.y+height,z),Vector3(at.x+half,at.y+height,z))
	for sx in [-1,1]:
		builder.bar(id+"_ledger_%d"%sx,Vector3(at.x+sx*half,at.y+height,at.z),Vector3(at.x+sx*half,at.y+height,at.z-length))
	var surfaces:Array=c.get("surfaces",["left","right"]);var overrides:Dictionary=c.get("overrides",{})
	for i in count:
		var z:float=at.z-i*2-1
		for side in surfaces:
			var key:String=id+"_"+str(side)+"_%02d"%i
			var o:Dictionary=overrides.get(key,{})
			if o.get("omit",false):continue
			var list:Array=c.get("contents",{}).get(side,[{"config":{"content":"wallpaper","wallpaper_group":i%17,"title":key}}])
			var content:Dictionary=list[i%list.size()]
			var cfg:Dictionary=content.get("config",{}).duplicate(true)
			var wall:bool=side in ["left","right"];var size:Array=[1.8,1.8] if wall else [width-.4,1.6]
			cfg.merge({"mount":"wall" if wall else "floor","stand":false,"slot_size":size},true)
			if not cfg.has("title"):cfg.title=key
			var pos:=Vector3(at.x,at.y+.08,z);var rotation:=Vector3.ZERO
			if wall:
				var sx:float=-1 if side=="left" else 1
				pos=Vector3(at.x+sx*half,at.y+1.1,z)
				rotation.y=sx*(90-float(c.get("panel_turn",0)))
				# Hang the complete frame from the upper ledger; no centre pole.
				builder.bar(key+"_hanger",Vector3(pos.x,at.y+3,z),Vector3(pos.x,at.y+height,z))
			elif side=="ceiling":
				pos.y=at.y+height-.12;rotation.x=180
				builder.bar(key+"_mount",Vector3(at.x-half,at.y+height,z),Vector3(at.x+half,at.y+height,z))
			var item:Dictionary={"id":key,"artifact":content.get("artifact","display_plate"),"position":builder.arr(pos),"rotation":builder.arr(rotation),"config":cfg,"corridor":id,"surface":side,"bay":i}
			if item.artifact!="display_plate":item.fit=[size[0],size[1],"wall" if wall else "floor"]
			if side=="floor":item.walk=size;item.label=str(cfg.title)
			if side=="floor" and content.has("jump"):item.jump=content.jump
			if o.has("config"):item.config.merge(o.config,true)
			for field in ["position","rotation"]:
				if o.has(field):item[field]=o[field].duplicate()
			if wall:framed_panel(builder,key,item)
			builder.recipe.activities.append(item)
	builder.recipe.get_or_add("corridors",[]).append({"id":id,"width":width,"length":length,"height":height,"panels":count*surfaces.size(),"entrance":builder.arr(at),"exit":builder.arr(at+Vector3(0,0,-length))})

static func framed_panel(builder:Object,key:String,item:Dictionary)->void:
	# The already-established square display frame, rigidly turned as a whole.
	# Its canonical two-metre members are never stretched or re-authored.
	var frame=Frame.new();frame.design=builder.design
	frame.recipe={"grid":builder.recipe.grid,"parts":[],"assemblies":[]}
	var records:Array=frame.square(2,[0,1]).filter(func(r):return r.kind!="quad")
	frame.assembly(key+"_frame",Vector3(-1,0,0),records)
	var rotation:Array=item.rotation
	var basis:=Basis.from_euler(Vector3(rotation[0],rotation[1],rotation[2])*PI/180.0)
	var p:Array=item.position
	var origin:=Vector3(p[0],p[1],p[2])-basis*Vector3(0,.1,0)
	for part in frame.recipe.parts:
		var cell:Array=part.cell
		var local:=Vector3(cell[0]-builder.recipe.grid.columns*.5+.5,cell[1],cell[2]-builder.recipe.grid.rows*.5+.5)
		part.cell=builder.cell(origin+basis*local)
		var angles:Array=part.rotation
		part.rotation=builder.arr((basis*Basis.from_euler(Vector3(angles[0],angles[1],angles[2])*PI/180.0)).get_euler()*180/PI)
		builder.recipe.parts.append(part)
	for assembly in frame.recipe.assemblies:
		assembly.origin=builder.arr(origin+basis*Vector3(-1,0,0));assembly.rotation=rotation.duplicate()
		builder.recipe.assemblies.append(assembly)
	builder.errors.append_array(frame.errors)
