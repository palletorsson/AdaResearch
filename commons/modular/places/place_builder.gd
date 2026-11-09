extends "principal_builder.gd"
## Opt-in parameterized places; writes a separate recipe, never the approved hall.
const Spec=preload("res://commons/modular/places/place_spec.gd")
const Boards=preload("res://commons/modular/places/board_builder.gd")
const Corridors=preload("res://commons/modular/places/corridor_builder.gd")
const Paths=preload("res://commons/modular/places/path_builder.gd")
const Decks=preload("res://commons/modular/places/deck_builder.gd")
const Banks=preload("res://commons/modular/places/grid_banks.gd")
const ACTIVITY_LIFT:=.03   # a slotted surface sits this much above its place floor: its flat rim must not share the shell's plane (z-fighting)
func compile(raw:Dictionary)->Dictionary:
	seen.clear();tiles.clear();tile_requests.clear();errors.clear()
	var problems:=Spec.validate(raw)
	if not problems.is_empty():return {"errors":problems}
	design={"appearance":{"phase":"colour","workshop_profile":"fitted"},"supports":{"ramp_trestles":true}}
	recipe={"version":1,"study":"parameterized-places","title":"Parameterized place prototype",
		"grid":{"columns":160,"rows":160,"cell":1,"electrical":false,"fieldY":0},
		"appearance":design.appearance,"parts":[],"assemblies":[],
		"authorizedKit":{"unitMetres":2,"fixedDimensions":true},
		"course":{"id":"parameterized-places","height":20,"stages":[]},"place_labels":[],
		"inspection_route":[],"installations":[],"lifts":[],"work_lights":[],"activities":[],
		"place_spec":raw,"places":[],"spawn":[79.5,.71,79.5],"goal":[79.5,.71,79.5]}
	for p in raw.places:build_place(p)
	Corridors.build_all(self,raw)
	Paths.build_all(self,raw)
	Decks.build_all(self,raw)
	Banks.build_all(self,raw)
	Boards.build_all(self,raw)   # rectangular boards, framed and repeated, as pieces of the structure
	tile_requests.sort_custom(func(a,b):return tile_priority(a)>tile_priority(b))
	for request in tile_requests:place_tile(request.id,request.at,request.size)
	if raw.get("palette","") in ["trans","white"]:
		# "white" (2026-11-09): the slim fitted parts in white with dark edges, pools and plates included.
		for part in recipe.parts:part["workshop_palette"]=raw.palette
		if raw.palette=="white":recipe.appearance=recipe.appearance.duplicate();recipe.appearance.palette="white"
	errors.append_array(Contract.validate(recipe))
	if not errors.is_empty():return {"errors":errors}
	return {"recipe":recipe,"errors":[]}

func build_place(p:Dictionary)->void:
	var id:String=p.id
	var x:float=p.at[0];var z:float=p.at[1];var y:float=p.y
	var hx:float=p.size[0]/2.0;var hz:float=p.size[1]/2.0;var depth:float=p.depth
	var steel:bool=p.type=="steel_pool";var plate:bool=p.type=="plate"
	var bottom:float=y-depth;var top:float=y+3 if steel else y
	var item:Dictionary={"id":id+"_surface","name":id+" / "+p.type,"source":Spec.TYPES[p.type],
		"cell":cell(Vector3(x,bottom,z)),"size":[p.size[0],depth,p.size[1]],"rotation":[0,0,0],
		"mirror":[1,1,1],"motion":motion(),"colour":p.get("colour","b9c6d0" if steel else ("6852bc" if plate else "49d6b0")),
		"shell_thickness":.12 if p.type=="plastic_pool" else .06,"corner_radius":.16 if plate else .3,
		"opening":2.2,"suspension_height":depth+3 if steel else depth}
	recipe.installations.append(item)
	# Rectangular one-metre rim; an explicit rear opening receives the descent.
	for ix in range(int(-hx)-1,int(hx)+1):
		for iz in range(int(-hz)-1,int(hz)+1):
			if ix>=-hx and ix<hx and iz>=-hz and iz<hz:continue
			if not plate and ix>=-1 and ix<1 and iz>=hz:continue
			tile(id+"_rim_%d_%d"%[ix,iz],Vector3(x+ix,y,z+iz),1)
	if not plate:
		ramp(id+"_descent",Vector3(x-1,bottom,z+hz-2*depth+1),int(depth),0,false)
		tile(id+"_ramp-landing",Vector3(x-1,y,z+hz+1),2)
		for side in [-3,1]:
			# The outer ramp rises through the western wing's footprint. A full
			# deck here blocks its low end and covers the slope at every height.
			if side==-3 and p.access.outer=="ramp":continue
			tile(id+"_arrival_%d"%side,Vector3(x+side,y,z+hz+1),2)
		# Rounded bath walls retain their own collision. The outside rim has rails.
		for sx in [-1,1]:
			var xx:float=x+sx*(hx+1)
			bar(id+"_side_rail_%d"%sx,Vector3(xx,y+1,z-hz-1),Vector3(xx,y+1,z+hz+1))
			for zz in range(int(-hz)-1,int(hz)+2,2):bar(id+"_rail_post_%d_%d"%[sx,zz],Vector3(xx,y,z+zz),Vector3(xx,y+1,z+zz))
		bar(id+"_front_rail",Vector3(x-hx-1,y+1,z-hz-1),Vector3(x+hx+1,y+1,z-hz-1))
		for sx in [-1,1]:
			bar(id+"_rear_rail_%d"%sx,Vector3(x+sx*3,y+1,z+hz+1),Vector3(x+sx*(hx+1),y+1,z+hz+1))
	# Canonical rods span the frame; dimensions change repetition, never rod scale.
	if y>0:
		for sx in [-1,1]:
			for sz in [-1,1]:
				bar(id+"_column_%d_%d"%[sx,sz],Vector3(x+sx*(hx+1),0,z+sz*(hz+1)),Vector3(x+sx*(hx+1),top,z+sz*(hz+1)))
		var bearing:float=bottom-float(item.shell_thickness)-.075
		for side in [-1,1]:
			bar(id+"_bearing_%d"%side,Vector3(x-hx-1,bearing,z+side*(hz-1)),Vector3(x+hx+1,bearing,z+side*(hz-1)))
			bar(id+"_ledger_%d"%side,Vector3(x+side*(hx+1),bearing,z-hz-1),Vector3(x+side*(hx+1),bearing,z+hz+1))
	if steel:
		for side in [-1,1]:
			bar(id+"_overhead_x_%d"%side,Vector3(x-hx-1,top,z+side*(hz+1)),Vector3(x+hx+1,top,z+side*(hz+1)))
			bar(id+"_overhead_z_%d"%side,Vector3(x+side*(hx+1),top,z-hz-1),Vector3(x+side*(hx+1),top,z+hz+1))
			for other in [-1,1]:
				bar(id+"_seat_x_%d_%d"%[side,other],Vector3(x+side*hx,top,z+other*(hz+1)),Vector3(x+side*(hx+1),top,z+other*(hz+1)))
				bar(id+"_seat_z_%d_%d"%[side,other],Vector3(x+side*hx,top,z+other*hz),Vector3(x+side*hx,top,z+other*(hz+1)))
	var arrival:=Vector3(x,y,z+hz+2)
	var entry:=Vector3(x,0,z+hz+4)
	if p.access.outer=="ramp":
		entry=Vector3(x-2*y-2,0,z+hz+2)
		ramp(id+"_climb",Vector3(x-2*y-1,0,z+hz+1),int(y),1)
		tile(id+"_entry",entry-Vector3(1,0,1),2)
		tile(id+"_ramp-landing_outer",arrival-Vector3(1,0,1),2)
	elif p.access.outer=="tc":
		var lift:Dictionary={"id":id+"_tc","cell":cell(entry),"size":[2,y+1,2],"rotation":[0,0,0],"mirror":[1,1,1],"motion":motion(),"rise":y}
		recipe.lifts.append(lift)
		tile(id+"_tc_approach",entry+Vector3(-1,0,1),2)
		tile(id+"_ramp-landing_outer",arrival-Vector3(1,0,1),2)
	else:entry=Vector3(x,0,z+hz+.5)
	var extent:AABB=Spec.envelope(p)
	recipe.places.append({"id":id,"rim_y":y,"floor_y":bottom,"footprint":p.size,
		"entry":arr(entry),"arrival":arr(arrival),"surface":item.id,"access":p.access,
		"bounds":arr(extent.position)+arr(extent.size)})
	label("%s / y %dm / %d x %dm / depth %dm"%[id,y,p.size[0],p.size[1],depth],Vector3(x,y+1.4,z-hz))
	if p.has("activity"):
		# the artifact in the slot: told the place's floor footprint and depth, it fits itself (TopologySpace.fit_slot)
		var act:Dictionary=p.activity;var cfg:Dictionary=(act.get("config",{}) as Dictionary).duplicate(true)
		var mount:String=str(act.get("mount","floor"));var side:String=str(act.get("side","south"))
		if mount=="wall":
			# the surface stands against one wall of the pool, just inside the shell, its relief into the room
			var along:float=p.size[0] if side in ["south","north"] else p.size[1];var inset:float=float(item.shell_thickness)+.01
			cfg.merge({"mount":"wall","slot_size":[along,maxf(depth,1.0)],"slot_depth":.5,"slot_floor":bottom,"slot_rim":y,"slot_margin":0.0,"rim_width":.5,"edge_band":1.0})
			var at:Vector3={"south":Vector3(x,bottom+ACTIVITY_LIFT,z+hz-inset),"north":Vector3(x,bottom+ACTIVITY_LIFT,z-hz+inset),"east":Vector3(x+hx-inset,bottom+ACTIVITY_LIFT,z),"west":Vector3(x-hx+inset,bottom+ACTIVITY_LIFT,z)}.get(side,Vector3(x,bottom+ACTIVITY_LIFT,z+hz-inset))
			var yaw:float={"south":0.0,"north":180.0,"east":90.0,"west":-90.0}.get(side,0.0)
			recipe.activities.append({"id":id+"_activity_"+side,"place":id,"artifact":str(act.artifact),"config":cfg,"position":arr(at),"rotation":[0,yaw,0],"mount":"wall","side":side})
		else:
			cfg.merge({"slot_size":[p.size[0],p.size[1]],"slot_depth":maxf(depth,.5),"slot_floor":bottom,"slot_rim":y,"slot_margin":0.0,"rim_width":.5,"edge_band":1.0})
			recipe.activities.append({"id":id+"_activity","place":id,"artifact":str(act.artifact),"config":cfg,"position":[x,bottom+ACTIVITY_LIFT,z]})
		if str(act.get("test",""))=="balls" and mount!="wall":
			# THE POCKET TEST over the same slot: a hundred balls read the surface (pocket_test.gd)
			var tcfg:Dictionary={"slot_size":[p.size[0],p.size[1]],"slot_depth":maxf(depth,.5),"rim_width":.5,"surface":id+"_activity","count":int(act.get("balls",100))}
			recipe.activities.append({"id":id+"_balltest","place":id,"artifact":"pocket_test","config":tcfg,"position":[x,bottom+ACTIVITY_LIFT,z]})
	recipe.work_lights.append({"position":[x,top+3,z],"energy":2.0,"range":maxf(p.size[0],p.size[1])+4})
