extends RefCounted
## Compile dimensioned places into the EXISTING grid/parts/assemblies recipe.
## Every small assembly must restore in the unmodified hand-workbench grammar.
const Model=preload("res://commons/artifacts/scaffold_workstation/model.gd")
const Contract=preload("res://commons/artifacts/scaffold_workstation/contract.gd")
var recipe:Dictionary
var design:Dictionary
var seen:Dictionary={}
var tiles:Dictionary={}
var tile_requests:Array=[]
var errors:Array=[]

func require(condition:bool,message:String)->void:
	if not condition:errors.append(message)
func write(path:String,data:Dictionary)->void:
	FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(data,"  ")+"\n")
func arr(v:Vector3)->Array:return [snappedf(v.x,.000001),snappedf(v.y,.000001),snappedf(v.z,.000001)]
func motion()->Dictionary:
	return {"enabled":false,"frame":"local","order":"TRS","travel":[0,0,0],"turn":[0,0,0],"scale":[1,1,1],"pivot":[0,0,0],"period":24,"phase":0,"wait":.3,"curve":"pingpong"}
func cell(v:Vector3)->Array:return [v.x+recipe.grid.columns*.5-.5,v.y,v.z+recipe.grid.rows*.5-.5]

func assembly(id:String,at:Vector3,records:Array)->void:
	# Godot rewrites dots in node names. Keep IDs identical across recipe, native
	# bodies and the editor manifest, including names derived from metre values.
	id=id.replace(".","p")
	var model=Model.new()
	if not model.restore(records):errors.append("Illegal assembly "+id+str(model.get_meta("restore_error",{})));return
	var members:Array=[]
	var all:Array=[{"kind":"point","at":[0,0,0]}]+records
	for i in all.size():
		var raw:Dictionary=all[i]
		var fitted:Dictionary=Model.fit_record(raw,records)
		var pose:Transform3D=Model.pose(fitted);pose.origin=pose.origin*Model.WORLD_STEP+at
		# Whole spheres sit low enough for the 20cm-radius player capsule to roll
		# across their crowns within its floor-angle limit. The sphere is not cut.
		if fitted.get("_seated",false) and design.appearance.get("workshop_profile","")=="fitted":pose.origin.y-=.04 if raw.kind=="point" else .01
		var seated_signature:bool=fitted.get("_seated",false)
		if raw.kind=="point" and design.appearance.get("workshop_profile","")=="fitted":seated_signature=false # Whole spheres share one geometry.
		var sig:=str(raw.kind)+str(arr(pose.origin))+str(arr(pose.basis.get_euler()))+str(raw.get("span",1))+str(seated_signature)
		if seen.has(sig):members.append(seen[sig]);continue
		var name:=id+"-%03d-"%i+str(raw.kind);seen[sig]=name;members.append(name)
		var size:Vector3=Contract.SIZES[raw.kind]
		if raw.kind in ["panel","quad"]:size*=Vector3(raw.get("span",1),1,raw.get("span",1))
		recipe.parts.append({"id":name,"name":id+" / "+raw.kind,"source":"workshop_"+raw.kind,"size":arr(size),"cell":cell(pose.origin),"rotation":arr(pose.basis.get_euler()*180/PI),"mirror":[1,1,1],"motion":motion(),"assembly":id,"assembly_root":id,"workshop_record":raw,"workshop_seated":fitted.get("_seated",false),"introduced":Contract.INTRO[raw.kind],"electrical":false})
		recipe.parts[-1].workshop_profile=design.appearance.get("workshop_profile","")
	recipe.assemblies.append({"id":id,"origin":arr(at),"records":records,"members":members,"moving":false})

func square(size:float,plane:Array=[0,2])->Array:
	var u:=Vector3.ZERO;u[plane[0]]=size/2
	var v:=Vector3.ZERO;v[plane[1]]=size/2
	var points=[Vector3.ZERO,u,v,u+v];var records:Array=[]
	for p in points.slice(1):records.append({"kind":"point","at":Model.arr(p)})
	for edge in [[points[0],u],[points[0],v],[u,u+v],[v,u+v]]:
		records.append({"kind":"rod" if size==2 else "rod_short","at":Model.arr(edge[0]),"end":Model.arr(edge[1])})
	var face:Dictionary={"kind":"quad","at":[0,0,0],"plane":plane}
	if size==1:face.span=.5
	records.append(face);return records

func tile(id:String,at:Vector3,size:float=2)->void:
	tile_requests.append({"id":id,"at":at,"size":size})

func place_tile(id:String,at:Vector3,size:float)->void:
	# Account for occupied one-metre cells, even where 1m rims meet 2m catwalks.
	# Comparing tile origins alone allowed differently sized panels to overlap.
	var cells:Array=[];var occupied:=0
	for x in int(size):
		for z in int(size):
			var cell_at:=at+Vector3(x,0,z);cells.append(cell_at)
			if tiles.has(str(arr(cell_at))):occupied+=1
	if occupied==cells.size():return
	if occupied>0:
		for i in cells.size():place_tile(id+"-fill-%d"%i,cells[i],1)
		return
	for cell_at:Vector3 in cells:tiles[str(arr(cell_at))]=id
	assembly(id,at,square(size))

func floor_rect(id:String,x:float,z:float,w:int,d:int,y:float,step:int=2)->void:
	if w%step!=0 or d%step!=0:errors.append("Incomplete tile in "+id);return
	for ix in range(0,w,step):
		for iz in range(0,d,step):tile(id+"-%d-%d"%[ix,iz],Vector3(x+ix,y,z+iz),step)

func bar(id:String,a:Vector3,b:Vector3)->void:
	var delta:=b-a;var axis:=0 if absf(delta.x)>.01 else (1 if absf(delta.y)>.01 else 2)
	var low:=a.min(b);var length:=delta.length();var amount:=int(round(length))
	if absf(length-amount)>.001:errors.append("Non-integral bar "+id);return
	var cursor:=0
	while cursor<amount:
		var step:=mini(2,amount-cursor);var end:=Vector3.ZERO;end[axis]=float(step)/2
		var pos:=low;pos[axis]+=cursor
		assembly(id+"-%d"%cursor,pos,[{"kind":"point","at":Model.arr(end)},{"kind":"rod" if step==2 else "rod_short","at":[0,0,0],"end":Model.arr(end)}]);cursor+=step

func ramp(id:String,low:Vector3,rise:int,turn:int,base_face:bool=true)->void:
	var direction:=Vector3.RIGHT if turn==1 else Vector3.BACK
	for i in rise:
		var origin:=low+direction*2*i+Vector3.UP*i
		var records:=square(2)
		# A fitted ramp is the walking plate itself; no hidden duplicate base panel.
		if not base_face or design.appearance.get("workshop_profile","")=="fitted":records=records.filter(func(r):return r.kind!="quad")
		records.append({"kind":"wedge","at":[.5,0,.5],"turn":[0,turn,0]})
		assembly(id+"-%d"%i,origin,records)
	if rise>1 and design.get("supports",{}).get("ramp_trestles",true):
		var across:=Vector3.BACK*2 if turn==1 else Vector3.RIGHT*2
		for step in range(2,rise+1,2):
			var seat:=low+direction*2*step+Vector3.UP*(step-.04)
			for side in 2:
				var top:=seat+across*side
				bar(id+"-trestle-%d-leg-%d"%[step,side],Vector3(top.x,-.04,top.z),top)
			bar(id+"-trestle-%d-tie"%step,seat-Vector3.UP,seat+across-Vector3.UP)

func bath_cradle(id:String,p:Dictionary,floor_y:float)->void:
	if not design.get("supports",{}).get("bath_cradles",true):return
	var half:float=p.size/2;var cx:float=p.centre[0];var cz:float=p.centre[1]
	# Rod crowns contact the shell underside. Side ledgers connect to the existing
	# outer columns; the hanging bath retains its four cables and open volume below.
	var y:float=floor_y-float(p.insert.shell_thickness)-.075
	for side in [-1,1]:
		var x:float=cx+side*(half+1)
		bar(id+"-cradle-ledger-"+str(side),Vector3(x,y,cz-half-1),Vector3(x,y,cz+half+1))
		var z:float=cz+side*(half-1)
		bar(id+"-cradle-bearer-"+str(side),Vector3(cx-half-1,y,z),Vector3(cx+half+1,y,z))

func rim(id:String,cx:float,cz:float,size:int,y:float,width:int)->void:
	var half:=float(size)/2
	# One-metre opening slices reserve the two-metre descent ramp on the rear rim.
	for x in range(-size/2-width,size/2+width):
		for z in range(-size/2-width,size/2+width):
			if x>=-half and x<half and z>=-half and z<half:continue
			if x>=-1 and x<1 and z>=half:continue
			tile(id+"-%d-%d"%[x,z],Vector3(cx+x,y,cz+z),1)
	# Outside guards. Rear access remains open at the centre.
	var e:=half+width
	for x in [-e,e]:
		bar(id+"-side-top"+str(x),Vector3(cx+x,y+1,cz-e),Vector3(cx+x,y+1,cz+e))
		for z in range(int(-e),int(e)+1,2):bar(id+"-post"+str(x)+str(z),Vector3(cx+x,y,cz+z),Vector3(cx+x,y+1,cz+z))
	for z in [-e,e]:
		for x in range(int(-e),int(e)):
			if z==e and x>=-3 and x<3:continue # widened arrival connects to both rim paths
			bar(id+"-end"+str(x)+str(z),Vector3(cx+x,y+1,cz+z),Vector3(cx+x+1,y+1,cz+z))
	# The inner wall belongs to the mounted bath, not to the scaffold grammar.

func installation(id:String,p:Dictionary,y:float,depth:float)->void:
	var item:Dictionary=p.insert.duplicate(true)
	item.merge({"id":id,"name":id.replace("-"," "),"cell":cell(Vector3(p.centre[0],y,p.centre[1])),"size":[p.size,depth,p.size],"rotation":[0,0,0],"mirror":[1,1,1],"motion":motion(),"suspension_height":depth+3 if p.insert.source=="steel_bath" else depth},true)
	recipe.installations.append(item)

func label(text:String,at:Vector3)->void:recipe.place_labels.append({"text":text,"position":arr(at)})

func compile(input:Dictionary)->Dictionary:
	seen.clear();tiles.clear();tile_requests.clear();errors.clear()
	design=input
	var h:int=int(design.storey_height);var rear:float=design.access.rear_z
	require(h==design.storey_height and h>=3 and h<=5 and design.access.width==2,"First preset supports whole-metre 3–5m storeys and 2m catwalks")
	for key in ["ground","court","basin"]:
		require(int(design[key].size)==design[key].size and int(design[key].size)%2==0 and design[key].size>=4,"Footprints use complete 2m panels")
		var insert:Dictionary=design[key].get("insert",{})
		require(insert.get("source","")=={"ground":"activity_plate","court":"plastic_bath","basin":"steel_bath"}[key],"Missing mounted insert for "+key)
		require(float(insert.get("shell_thickness",0))>0 and float(insert.get("shell_thickness",0))<=.25,"Insert shell thickness must be positive and at most 25cm")
		require(float(insert.get("corner_radius",0))>0 and float(insert.get("corner_radius",0))<float(design[key].size)/2-.5,"Insert corner radius must fit its footprint")
	require(design.ground.gutter==1 and design.court.rim_width==1 and design.basin.rim_width==1,"First preset uses 1m rims")
	require(design.court.depth==1 and design.basin.depth==1,"First preset uses the existing 1m-rise ramp")
	require(design.tower.clear_height>h*2+3,"Canopy clearance")
	if not errors.is_empty():return {"errors":errors}
	recipe={"version":1,"study":"principal-places","title":"Principal places / connected spatial trial","grid":{"columns":design.tower.width,"rows":design.tower.depth,"cell":1,"electrical":false,"fieldY":0},"appearance":design.appearance,"parts":[],"assemblies":[],"authorizedKit":{"unitMetres":2,"fixedDimensions":true},"course":{"id":"principal-places","height":h*2+4,"storeyHeight":h,"stages":[]},"place_labels":[],"inspection_route":[]}
	var g:Dictionary=design.ground;var c:Dictionary=design.court;var b:Dictionary=design.basin
	recipe.installations=[]
	var gx:float=g.centre[0];var gz:float=g.centre[1];var cx:float=c.centre[0];var cz:float=c.centre[1];var bx:float=b.centre[0];var bz:float=b.centre[1]
	installation("disco-plate",g,0,0)
	# Gutter remains a safe clear band around the 8m active array.
	for x in range(-g.size/2-1,g.size/2+1):
		for z in range(-g.size/2-1,g.size/2+1):
			if x>=-g.size/2 and x<g.size/2 and z>=-g.size/2 and z<g.size/2:continue
			tile("gutter-%d-%d"%[x,z],Vector3(gx+x,0,gz+z),1)
	var frame:float=g.size/2+2
	for x in [-frame,frame]:
		for z in [-frame,frame]:bar("array-frame-post"+str(x)+str(z),Vector3(gx+x,0,gz+z),Vector3(gx+x,h,gz+z))
		bar("array-frame-z"+str(x),Vector3(gx+x,h,gz-frame),Vector3(gx+x,h,gz+frame))
	for z in [-frame,frame]:bar("array-frame-x"+str(z),Vector3(gx-frame,h,gz+z),Vector3(gx+frame,h,gz+z))
	for item in [["court",c,h],["basin",b,h*2]]:
		var id:String=item[0];var p:Dictionary=item[1];var y:float=item[2];var x:float=p.centre[0];var z:float=p.centre[1];var half:float=p.size/2
		installation("biome-plastic-bath" if id=="court" else "hanging-steel-bath",p,y-p.depth,p.depth)
		bath_cradle(id,p,y-p.depth)
		rim(id+"-rim",x,z,p.size,y,p.rim_width)
		ramp(id+"-descent",Vector3(x-1,y-1,z+half-1),1,0,false)
		# A full-width landing keeps a joint out of the ramp's walking centreline.
		tile(id+"-ramp-landing",Vector3(x-1,y,z+half+1),2)
		for side in [-3,1]:tile(id+"-arrival-wing"+str(side),Vector3(x+side,y,z+half+1),2)
		floor_rect(id+"-approach",x-1,z+half+3,2,maxi(0,int(rear+1-z-half-3)),y,1)
		var top:float=y if id=="court" else y+3
		for px in [x-half-1,x+half+1]:
			for pz in [z-half-1,z+half+1]:
				bar(id+"-column"+str(px)+str(pz),Vector3(px,0,pz),Vector3(px,top,pz))
		# Basin hangs within a taller frame; the court is supported from below.
		if id=="basin":
			for px in [x-half-1,x+half+1]:bar(id+"-overhead"+str(px),Vector3(px,top,z-half-1),Vector3(px,top,z+half+1))
			for pz in [z-half-1,z+half+1]:bar(id+"-overhead"+str(pz),Vector3(x-half-1,top,pz),Vector3(x+half+1,top,pz))
			for px in [x-half,x+half]:
				for pz in [z-half,z+half]:
					# Steel cables and eyes are part of the bath; frame seats stay here.
					var outer_x:float=px+signf(px-x);var outer_z:float=pz+signf(pz-z)
					bar(id+"-hanger-seat-x"+str(px)+str(pz),Vector3(outer_x,top,outer_z),Vector3(px,top,outer_z))
					bar(id+"-hanger-seat-z"+str(px)+str(pz),Vector3(px,top,outer_z),Vector3(px,top,pz))
		label((("m1 / PLASTIC BIOME BATH" if id=="court" else "m2 / HANGING STEEL BATH")+" / %d x %dm"%[p.size,p.size]),Vector3(x,y+1.4,z-half))
	var r1:float=design.access.first_ramp_x;var r2:float=design.access.second_ramp_x
	floor_rect("ground-approach",r1-2,gz+g.size/2+1,2,int(rear+1-gz-g.size/2-1),0,1)
	ramp("climb-m1",Vector3(r1,0,rear-1),h,1)
	require(r2>=r1+h*2+2,"The first ramp needs its landing")
	floor_rect("catwalk-m1",r1+h*2,rear-1,int(r2-r1-h*2),2,h,2)
	floor_rect("cross-spur",cx-1,rear+1,2,3,h,1)
	ramp("climb-m2",Vector3(r2,h,rear-1),h,1)
	var end:float=maxf(bx+4,r2+h*2+2)
	floor_rect("catwalk-m2",r2+h*2,rear-1,int(end-r2-h*2),2,h*2,2)
	# Sparse raised rails leave the court/basin approach and cross junction open.
	for row in [[r1+h*2,r2,h],[r2+h*2,end,h*2]]:
		for x in range(int(row[0]),int(row[1])):
			for z in [rear-1,rear+1]:
				if (x>=cx-1 and x<cx+1) or (x>=bx-1 and x<bx+1):continue
				bar("cat-rail"+str(x)+str(z),Vector3(x,row[2]+1,z),Vector3(x+1,row[2]+1,z))
				if x%2==0:bar("cat-post"+str(x)+str(z),Vector3(x,row[2],z),Vector3(x,row[2]+1,z))
	# Small/large upright panels and a single podium retain normal member IDs.
	assembly("panel-small",Vector3(gx-3,1,gz-5),square(1,[0,1]))
	assembly("panel-large",Vector3(gx,1,gz-5),square(2,[0,1]))
	tile("podium",Vector3(gx+2,1,gz+6),2)
	for x in [gx+2,gx+4]:
		for z in [gz+6,gz+8]:bar("podium-leg"+str(x)+str(z),Vector3(x,0,z),Vector3(x,1,z))
	label("m0 / DISCO PLATE / %d x %dm"%[g.size,g.size],Vector3(gx,1.4,gz-5))
	var route:Array=[Vector3(gx,0,gz),Vector3(r1-1,0,gz+3),Vector3(r1-1,0,rear),Vector3(r1+h*2+1,h,rear),Vector3(cx,h,rear),Vector3(cx,h,cz+c.size/2+1.5),Vector3(cx,h-1,cz+c.size/2-1.5),Vector3(cx,h-1,cz),Vector3(cx,h-1,cz+c.size/2-1.5),Vector3(cx,h,cz+c.size/2+1.5),Vector3(cx,h,rear),Vector3(cx,h,rear+3),Vector3(cx,h,rear),Vector3(r2-1,h,rear),Vector3(r2+h*2+1,h*2,rear),Vector3(bx,h*2,rear),Vector3(bx,h*2,bz+b.size/2+1.5),Vector3(bx,h*2-1,bz+b.size/2-1.5),Vector3(bx,h*2-1,bz),Vector3(bx,h*2-1,bz+b.size/2-1.5),Vector3(bx,h*2,bz+b.size/2+1.5),Vector3(bx,h*2,rear)]
	for p in route:recipe.inspection_route.append(arr(p))
	# Enter each rim through its widened arrival, circle it, then return to the ramp.
	for item in [[c,h,6],[b,h*2,17]]:
		var p:Dictionary=item[0];var y:float=item[1];var e:float=p.size/2+.5;var x:float=p.centre[0];var z:float=p.centre[1]
		var loop:Array=[Vector3(x-2,y,z+e+1),Vector3(x-2,y,z+e),Vector3(x-e,y,z+e),Vector3(x-e,y,z-e),Vector3(x+e,y,z-e),Vector3(x+e,y,z+e),Vector3(x+2,y,z+e),Vector3(x+2,y,z+e+1),Vector3(x,y,z+e+1)]
		# Locate the descent's first low point; insert the loop before descending.
		var entrance:Array=arr(Vector3(x,y-1,z+p.size/2-1.5))
		var index:int=recipe.inspection_route.find(entrance)
		for point in loop:recipe.inspection_route.insert(index,arr(point));index+=1
	recipe.spawn=cell(Vector3(gx,.71,gz));recipe.goal=cell(Vector3(bx,h*2+.65,rear))
	recipe.work_lights=[]
	for row in [[g,0],[c,1],[b,2]]:recipe.work_lights.append({"position":[row[0].centre[0],h*row[1]+3,row[0].centre[1]],"energy":2.0,"range":14})
	# Full-width ramp arrivals must win over overlapping one-metre approach cells:
	# otherwise a split tile puts a joint directly in the ramp's walking centreline.
	tile_requests.sort_custom(func(a,b):return tile_priority(a)>tile_priority(b))
	for request in tile_requests:place_tile(request.id,request.at,request.size)
	errors.append_array(Contract.validate(recipe))
	if not errors.is_empty():return {"errors":errors}
	var layout:Dictionary={"status":"Separate connected proportions trial","width":design.tower.width,"depth":design.tower.depth,"storey_height":design.tower.clear_height,"slab_thickness":.36,"levels":[0,-design.tower.clear_height,-design.tower.clear_height*2],"shafts":[],"shaft_width":5,"shaft_depth":6,"column_x":[-design.tower.width/2+1,design.tower.width/2-1],"column_z":[-design.tower.depth/2+1,design.tower.depth/2-1],"column_width":.9,"service_x":[-22,22],"service_z":-12,"floor_roles":["Canopy","Principal places","Catch floor"],"descent":{"mode":"shaft_ledges"},"cliff_landings":{"enabled":false},"floor_styles":{"0":"abstract","1":"abstract","2":"abstract"}}
	layout.spawn_points={"1":[gx,.14,gz]}
	return {"recipe":recipe,"layout":layout,"errors":[]}

func tile_priority(item:Dictionary)->float:
	return float(item.size)*10+(3 if str(item.id).ends_with("ramp-landing") else (2 if str(item.id).begins_with("catwalk-") else 0))
