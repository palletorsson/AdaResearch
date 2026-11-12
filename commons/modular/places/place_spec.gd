extends RefCounted
## Metres and explicit access, independent of the fixed dimensions of workshop parts.
const TYPES := {"plate":"activity_plate", "plastic_pool":"plastic_bath", "steel_pool":"steel_bath"}
const Boards=preload("res://commons/modular/places/board_builder.gd")   # the board vocabulary (Palle, 2026-10-31)

const Corridors=preload("res://commons/modular/places/corridor_builder.gd")
const Paths=preload("res://commons/modular/places/path_builder.gd")
const Decks=preload("res://commons/modular/places/deck_builder.gd")
const Banks=preload("res://commons/modular/places/grid_banks.gd")
const Connectors=preload("res://commons/modular/places/grid_connectors.gd")
const Lattices=preload("res://commons/modular/places/lattice_builder.gd")   # ribs over an opening: bars only (2026-11-12)
const Walks=preload("res://commons/modular/places/walk_builder.gd")   # a seeded walk that lays bars, tiles and ramps (2026-11-12)

static func validate(spec:Dictionary)->PackedStringArray:
	var errors:=PackedStringArray()
	if spec.get("palette","") not in ["","trans","white"]:errors.append("Unknown structural palette")
	if spec.get("version",0)!=1:errors.append("Expected place specification version 1")
	if spec.get("units","")!="metres":errors.append("Units must be metres")
	if not spec.get("places",null) is Array:return PackedStringArray(["places must be an array"])
	if spec.places.is_empty() and spec.get("boards",[])==[] and spec.get("corridors",[])==[] and spec.get("paths",[])==[] and spec.get("decks",[])==[] and spec.get("walks",[])==[] and spec.get("lattices",[])==[] and not spec.has("grid_banks"):errors.append("At least one place, board, corridor, path, deck or grid bank is required")
	if spec.has("boards"):errors.append_array(Boards.validate(spec))
	errors.append_array(Corridors.validate(spec))
	errors.append_array(Paths.validate(spec))
	errors.append_array(Decks.validate(spec))
	errors.append_array(Banks.validate(spec))
	errors.append_array(Connectors.validate(spec))
	errors.append_array(Walks.validate(spec))
	errors.append_array(Lattices.validate(spec))
	var ids:Dictionary={}
	for p in spec.places:
		if not p is Dictionary:errors.append("Each place must be an object");continue
		var id:String=str(p.get("id",""))
		if id.is_empty() or not id.is_valid_identifier():errors.append("Place id must be a stable identifier: "+id)
		if ids.has(id):errors.append("Duplicate place id: "+id)
		ids[id]=true
		for key in p.keys():
			if key not in ["id","at","y","size","depth","type","rim","access","colour","activity"]:errors.append(id+": unknown field "+str(key))
		# THE ACTIVITY in the slot (Palle, 2026-10-31): {"artifact": <registry token>, "config": {...}} - a parameterised
		# artifact fitted to this place's floor by place_builder; place_activity.gd makes it at runtime
		if p.has("activity"):
			var act=p.activity
			if not act is Dictionary or str(act.get("artifact","")).is_empty():errors.append(id+": activity needs an artifact token")
			elif act.has("config") and not act.config is Dictionary:errors.append(id+": activity config must be an object")
			if act is Dictionary and act.has("mount") and str(act.mount) not in ["floor","wall"]:errors.append(id+": activity mount must be floor or wall")
			if act is Dictionary and act.has("side") and str(act.side) not in ["south","north","east","west"]:errors.append(id+": activity side must be south, north, east or west")
			if act is Dictionary and act.has("test") and str(act.test) not in ["balls"]:errors.append(id+": activity test must be balls")
		if not p.get("type","") in TYPES:errors.append(id+": type must be plate, plastic_pool or steel_pool")
		for key in ["at","size"]:
			var a=p.get(key,null)
			if not a is Array or a.size()!=2:errors.append(id+": "+key+" needs [x,z]");continue
			for n in a:
				if not number(n) or not is_equal_approx(float(n),roundf(float(n))):errors.append(id+": "+key+" needs whole metres")
				elif key=="size" and (n<4 or n>20 or int(n)%2!=0):errors.append(id+": footprint dimensions must be even metres from 4 to 20")
				elif key=="at" and absf(n)>48:errors.append(id+": prototype anchors must be within 48m of the host origin")
		for key in ["y","depth"]:
			var n=p.get(key,null)
			if not number(n) or not is_equal_approx(float(n),roundf(float(n))) or n<0 or n>(12 if key=="y" else 3):errors.append(id+": "+key+" outside the supported whole-metre range")
		if p.get("rim",1)!=1:errors.append(id+": first kit uses a 1m rim/gutter")
		if p.has("colour") and (not p.colour is String or not Color.html_is_valid(p.colour)):errors.append(id+": colour must be a valid HTML colour")
		var access=p.get("access",null)
		if not access is Dictionary:errors.append(id+": access needs outer and inner choices");continue
		for key in access.keys():
			if key not in ["outer","inner"]:errors.append(id+": unknown access field "+str(key))
		if access.get("outer","") not in ["level","ramp","tc"]:errors.append(id+": outer access must be level, ramp or tc")
		if access.get("inner","") not in ["level","ramp"]:errors.append(id+": inner access must be level or ramp")
		if number(p.get("y")) and ((p.y==0)!=(access.get("outer")=="level")):errors.append(id+": y=0 requires level access; raised places require ramp or tc")
		if number(p.get("depth")):
			if (p.depth==0)!=(p.get("type")=="plate"):errors.append(id+": plates have zero depth; pools have positive depth")
			if (p.depth==0)!=(access.get("inner")=="level"):errors.append(id+": pool interiors require a descent ramp")
			if number(p.get("y")) and p.depth>p.y:errors.append(id+": pool bottom must remain at or above the host ground")
			var size=p.get("size",[])
			if size is Array and size.size()==2 and number(size[1]) and p.depth>0 and 2*p.depth>size[1]-2:errors.append(id+": length leaves insufficient room for the descent ramp")
	if errors.is_empty():
		for i in spec.places.size():
			for j in range(i):
				if envelope(spec.places[i]).intersects(envelope(spec.places[j])):errors.append(str(spec.places[i].id)+": operating space overlaps "+str(spec.places[j].id))
	return errors

static func envelope(p:Dictionary)->AABB:
	var hx:float=p.size[0]/2.0;var hz:float=p.size[1]/2.0
	var left:float=minf(-hx-1,-2*p.y-3) if p.access.outer=="ramp" else -hx-1
	var rear:float=hz+(7 if p.access.outer=="tc" else 3)
	return AABB(Vector3(p.at[0]+left,-.5,p.at[1]-hz-1),Vector3(hx+1-left,p.y+(5 if p.type=="steel_pool" else 3),rear+hz+1))

static func number(v:Variant)->bool:
	return (v is int or v is float) and is_finite(float(v))
