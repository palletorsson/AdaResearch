extends RefCounted
## Fixed-kit platforms and open lattice passages. Metres; ramps have 1m rise / 2m run.
const SIDES:=["north","south","east","west"]
static func whole(v:Variant,lo:int,hi:int)->bool:
	return (v is int or v is float) and is_finite(float(v)) and v>=lo and v<=hi and is_equal_approx(float(v),roundf(v))
static func validate(raw:Dictionary)->PackedStringArray:
	var errors:=PackedStringArray();var decks:Variant=raw.get("decks",[]);var ids:Dictionary={}
	if not decks is Array:return PackedStringArray(["decks must be an array"])
	for d in decks:
		if not d is Dictionary:errors.append("Deck must be an object");continue
		var id:=str(d.get("id",""))
		if not id.is_valid_identifier() or ids.has(id):errors.append("Deck needs a unique stable id: "+id)
		ids[id]=true
		for k in d:
			if k not in ["id","at","size","enclosure","openings","opening_width","ramp"]:errors.append(id+": unknown deck field "+str(k))
		var at:Variant=d.get("at");var size:Variant=d.get("size")
		if not at is Array or at.size()!=3 or not whole(at[0],-48,48) or not whole(at[1],0,6) or not whole(at[2],-48,48):errors.append(id+": at needs whole [x,y,z] metres, y=0..6")
		if not size is Array or size.size()!=2 or not size.all(func(n):return whole(n,2,12) and int(n)%2==0):errors.append(id+": size needs even [width,length] metres from 2..12")
		if d.get("enclosure","rails") not in ["open","rails","tunnel"]:errors.append(id+": enclosure must be open, rails or tunnel")
		var openings:Variant=d.get("openings",[])
		if not openings is Array or not openings.all(func(s):return s in SIDES):errors.append(id+": openings must name sides")
		else:
			var seen:Dictionary={}
			for side in openings:
				if seen.has(side):errors.append(id+": duplicate opening")
				seen[side]=true
		if not whole(d.get("opening_width",2),2,12):errors.append(id+": opening_width must be whole metres from 2 to 12")
		if d.has("ramp"):
			if d.ramp not in SIDES:errors.append(id+": ramp must name one side")
			elif not openings is Array or d.ramp not in openings:errors.append(id+": ramp side must have an opening")
			if at is Array and at.size()==3 and at[1]==0:errors.append(id+": ground-level decks do not need a ramp")
	return errors

static func build_all(builder:Object,raw:Dictionary)->void:
	for d in raw.get("decks",[]):build(builder,d)

static func build(b:Object,d:Dictionary)->void:
	var id:String=d.id;var x:float=d.at[0];var y:float=d.at[1];var z:float=d.at[2]
	var w:int=d.size[0];var length:int=d.size[1];var hx:float=w*.5;var hz:float=length*.5
	b.floor_rect(id+"_deck",x-hx,z-hz,w,length,y)
	if y>0:
		for sx in [-1,1]:
			for sz in [-1,1]:
				var seat:float=.04 if b.design.appearance.get("workshop_profile","")=="fitted" else 0.0
				b.bar(id+"_leg_%d_%d"%[sx,sz],Vector3(x+sx*hx,-seat,z+sz*hz),Vector3(x+sx*hx,y-seat,z+sz*hz))
	var opening_half:float=float(d.get("opening_width",2))*.5
	var enclosure:String=d.get("enclosure","rails");var top:float=3 if enclosure=="tunnel" else 1
	if enclosure!="open":
		for side in SIDES:
			var along_x:bool=side in ["north","south"];var span:int=w if along_x else length
			var mid:=Vector3(x,y,z)
			if along_x:mid.z+=hz*(1 if side=="south" else -1)
			else:mid.x+=hx*(1 if side=="east" else -1)
			var axis:=Vector3.RIGHT if along_x else Vector3.BACK
			for i in range(-span/2,span/2+1):
				if side in d.get("openings",[]) and abs(i)<opening_half:continue
				var p:Vector3=mid+axis*i
				b.bar(id+"_"+side+"_post_%d"%i,p,p+Vector3.UP*top)
			for i in range(-span/2,span/2):
				for level in range(1,int(top)+1):
					if side in d.get("openings",[]) and i>=-opening_half and i<opening_half and level<3:continue
					b.bar(id+"_"+side+"_rail_%d_%d"%[i,level],mid+axis*i+Vector3.UP*level,mid+axis*(i+1)+Vector3.UP*level)
		if enclosure=="tunnel":
			# A lattice roof admits views of other routes; no opaque ceiling slab.
			for dz in range(-length/2,length/2+1):b.bar(id+"_roof_%d"%dz,Vector3(x-hx,y+3,z+dz),Vector3(x+hx,y+3,z+dz))
	var entry:Variant=null
	if d.has("ramp"):
		var side:String=d.ramp;var turn:int={"west":1,"east":3,"north":0,"south":2}[side]
		# Centre a whole plate on the approach. Its priority over the deck's
		# regular tiling keeps a round joint out of the ramp's centre at the crest.
		var landing:=Vector3(x-1,y,z-1)
		match side:
			"west":landing.x=x-hx
			"east":landing.x=x+hx-2
			"north":landing.z=z-hz
			"south":landing.z=z+hz-2
		b.tile(id+"_ramp-landing",landing,2)
		for i in int(y):
			var at:=Vector3(x-1,i,z-1)
			match side:
				"west":at.x=x-hx-2*y+2*i
				"east":at.x=x+hx+2*y-2-2*i
				"north":at.z=z-hz-2*y+2*i
				"south":at.z=z+hz+2*y-2-2*i
			var records:Array=b.square(2).filter(func(r):return r.kind!="quad")
			records.append({"kind":"wedge","at":[.5,0,.5],"turn":[0,turn,0]})
			b.assembly(id+"_ramp_%d"%i,at,records)
		entry={"west":[x-hx-2*y,0,z],"east":[x+hx+2*y,0,z],"north":[x,0,z-hz-2*y],"south":[x,0,z+hz+2*y]}[side]
	b.recipe.get_or_add("decks",[]).append({"id":id,"at":d.at,"size":d.size,"enclosure":enclosure,"entry":entry})
