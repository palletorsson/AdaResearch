extends RefCounted
## THE WINDMILL PREFAB (Palle, 2026-11-09, for floor 20's revolving playground: "They should not be on their own. They
## should be more prefab-like, consisting of a rod, some extension to a wooden panel, like a home-made windmill ...
## attached to the corner of the playground structure. The one rotating around y should be one meter and have two
## paddles. The ones rotating in x and z should have 3 or 2 paddles and be standing 1 times 2 meters tall, rotating
## from 2 meter in y.")
##
## A windmill is a handful of ordinary recipe parts - the authorized kit's 2 m rods, 1 m short rods and joints, plus
## one paddle board per arm - grown from ONE existing joint of the structure (its `corner`). Every part stays a named,
## editable part of the playground; nothing here is a mesh-only port.
##   axis "x" / "z": a stand 1 m wide and 2 m tall (two 2 m posts, a 1 m top rail) standing on the corner joint and
##        along the dock edge the axle continues; a 1 m axle out of the top joint, `out` (+1/-1) along the axis; the
##        hub at its end, 2 m above the corner; 2 or 3 arms of 1 m, a paddle board at each end in the rotor's plane.
##   axis "y": a 1 m mast on the corner joint; the hub on top, 1 m up; ONE 1 m bar through the hub (two arms of half
##        a metre) with an upright paddle board at each end - a revolving door at hip height.
## The sidecar (`<recipe>-windmills.json`, or a path, or the spec itself, as the placement config "windmills") lists
## the windmills, the assemblies they replace, and the course stages they retitle. The recipe JSON stays untouched.
const Contract=preload("res://commons/artifacts/scaffold_workstation/contract.gd")
const Finishes=preload("construction_materials.gd")
const PADDLE:="windmill_paddle"
const PADDLE_X:=Vector3(.45,.6,.04)   # x/z sails: width (tangential), length (radial), thickness (along the axle)
const PADDLE_Y:=Vector3(.4,.45,.04)   # y doors: height, length (radial), thickness (tangential)
const STAND:=2.0                      # the x/z stand, corner joint to top joint
const MAST:=1.0                       # the y mast
const ARM:=1.0                        # a 1 m short rod

## Load a sidecar or take one inline; apply it to the (already duplicated) recipe. Returns the spec used, {} if none.
static func install(recipe:Dictionary,source:Variant,recipe_path:String)->Dictionary:
	var spec:Dictionary={}
	if source is Dictionary:spec=source
	else:
		var path:String=str(source) if source is String and str(source).ends_with(".json") else recipe_path.get_basename()+"-windmills.json"
		var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
		if not parsed is Dictionary:
			push_warning("windmills: no sidecar at "+path);return {}
		spec=parsed
	var gone:Array=spec.get("replaces",[])
	recipe.parts=recipe.parts.filter(func(p:Dictionary)->bool:return str(p.get("assembly",p.id)) not in gone and str(p.get("parent","")) not in gone)
	for w in spec.get("windmills",[]):recipe.parts.append_array(parts(w,recipe.grid))
	var titles:Dictionary=spec.get("stages",{})
	for stage in recipe.get("course",{}).get("stages",[]):
		if titles.has(str(stage.get("id",""))):stage.merge(titles[stage.id],true)
	return spec

static func motion(turn:=Vector3.ZERO,period:=24.0,phase:=0.0)->Dictionary:
	return {"enabled":turn!=Vector3.ZERO,"frame":"local","order":"TRS","travel":[0,0,0],"turn":[turn.x,turn.y,turn.z],
		"scale":[1,1,1],"pivot":[0,0,0],"period":period,"phase":phase,"wait":0,"curve":"loop"}

static func euler(b:Basis)->Array:
	var e:Vector3=b.get_euler(EULER_ORDER_YXZ)*180.0/PI
	return [snappedf(e.x,.0001),snappedf(e.y,.0001),snappedf(e.z,.0001)]

## A basis whose local +Y is `d` (rods are built along Y and centred on their cell).
static func along(d:Vector3)->Basis:
	d=d.normalized()
	if d.is_equal_approx(Vector3.UP):return Basis.IDENTITY
	if d.is_equal_approx(Vector3.DOWN):return Basis(Vector3.RIGHT,PI)
	return Basis(Quaternion(Vector3.UP,d))

static func member(w:Dictionary,id:String,kind:String,cell:Vector3,b:Basis,assembly:String,parent:="",turn:=Vector3.ZERO)->Dictionary:
	var record:Dictionary={"kind":kind,"at":[0,0,0]}
	if kind=="rod":record.end=[0,1,0]
	if kind=="rod_short":record.end=[0,.5,0]
	var part:Dictionary={"id":id,"name":str(w.id)+" / "+kind,"source":"workshop_"+kind,"size":[.36,.36,.36],"cell":[cell.x,cell.y,cell.z],
		"rotation":euler(b),"mirror":[1,1,1],"motion":motion(turn,float(w.get("period",16)),float(w.get("phase",0))),
		"assembly":assembly,"assembly_root":assembly,"workshop_record":record,"introduced":Contract.INTRO[kind],
		"electrical":false,"pusher":parent!="" or turn!=Vector3.ZERO,"windmill":str(w.id)}
	var size:Vector3=Contract.SIZES[kind];part.size=[size.x,size.y,size.z]
	if parent!="":part.parent=parent
	return part

static func paddle(w:Dictionary,id:String,cell:Vector3,b:Basis,size:Vector3,assembly:String,parent:String)->Dictionary:
	return {"id":id,"name":str(w.id)+" / paddle","source":PADDLE,"size":[size.x,size.y,size.z],"cell":[cell.x,cell.y,cell.z],
		"rotation":euler(b),"mirror":[1,1,1],"motion":motion(),"assembly":assembly,"assembly_root":assembly,
		"electrical":false,"pusher":true,"parent":parent,"windmill":str(w.id)}

static func axis_vector(axis:String)->Vector3:
	return {"x":Vector3.RIGHT,"y":Vector3.UP,"z":Vector3.BACK}[axis]

## The parts of one windmill. Root parts are addressed in the recipe's cells (metres / grid.cell across, metres up);
## the rotor's members in metres local to its turning hub.
static func parts(w:Dictionary,grid:Dictionary)->Array:
	var id:String=str(w.id);var axis:String=str(w.get("axis","y"))
	var a:Vector3=axis_vector(axis)
	var corner:=Vector3(w.corner[0],w.corner[1],w.corner[2])
	var cell:float=float(grid.get("cell",1))
	var metres:=func(v:Vector3)->Vector3:return Vector3(v.x/cell,v.y,v.z/cell)   # a metre offset in cell addresses
	var stand:=id+"-stand";var rotor:=id+"-rotor"
	var result:Array=[]
	var spin:float=float(w.get("direction",1))*360.0
	var n:int=int(w.get("paddles",2))
	if axis=="y":
		var mast:float=float(w.get("height",MAST))
		result.append(member(w,stand+"-mast","rod_short",corner+metres.call(Vector3.UP*mast*.5),Basis.IDENTITY,stand))
		var hub:Vector3=corner+metres.call(Vector3.UP*mast)
		result.append(member(w,rotor,"point",hub,Basis.IDENTITY,rotor,"",Vector3.UP*spin))
		var start:float=deg_to_rad(float(w.get("start",0)))
		var bar:=Vector3(cos(start),0,-sin(start))
		result.append(member(w,rotor+"-bar","rod_short",Vector3.ZERO,along(bar),rotor,rotor))
		for k in 2:
			var r:Vector3=bar*(1 if k==0 else -1)
			result.append(member(w,rotor+"-tip-%d"%k,"point",r*ARM*.5,Basis.IDENTITY,rotor,rotor))
			# Upright board: local x up, local y along the arm, local z tangential (its thickness).
			result.append(paddle(w,rotor+"-paddle-%d"%k,r*ARM*.5,Basis(Vector3.UP,r,Vector3.UP.cross(r)),PADDLE_Y,rotor,rotor))
		return result
	# x / z: the stand runs back along the dock edge the axle continues (never across the walkway it faces).
	var out:float=float(w.get("out",1))
	var e:Vector3=-a*out
	var rise:float=float(w.get("height",STAND))
	var top:Vector3=corner+metres.call(Vector3.UP*rise)
	result.append(member(w,stand+"-post-0","rod",corner+metres.call(Vector3.UP*rise*.5),Basis.IDENTITY,stand))
	result.append(member(w,stand+"-foot-1","point",corner+metres.call(e),Basis.IDENTITY,stand))
	result.append(member(w,stand+"-post-1","rod",corner+metres.call(e+Vector3.UP*rise*.5),Basis.IDENTITY,stand))
	result.append(member(w,stand+"-top-0","point",top,Basis.IDENTITY,stand))
	result.append(member(w,stand+"-top-1","point",top+metres.call(e),Basis.IDENTITY,stand))
	result.append(member(w,stand+"-rail","rod_short",top+metres.call(e*.5),along(e),stand))
	result.append(member(w,stand+"-axle","rod_short",top+metres.call(a*out*ARM*.5),along(a),stand))
	var hub:Vector3=top+metres.call(a*out*ARM)
	result.append(member(w,rotor,"point",hub,Basis.IDENTITY,rotor,"",a*spin))
	var start:float=deg_to_rad(float(w.get("start",90)))
	for k in n:
		var angle:float=start+k*TAU/n
		var r:Vector3=Vector3.UP.rotated(a,angle)   # the arm, in the rotor's plane
		var t:Vector3=r.cross(a)
		result.append(member(w,rotor+"-arm-%d"%k,"rod_short",r*ARM*.5,along(r),rotor,rotor))
		result.append(member(w,rotor+"-tip-%d"%k,"point",r*ARM,Basis.IDENTITY,rotor,rotor))
		# Sail board in the rotor's plane: local x tangential, local y along the arm, local z the axle.
		result.append(paddle(w,rotor+"-paddle-%d"%k,r*ARM,Basis(t,r,a),PADDLE_X,rotor,rotor))
	return result

## The board itself: one box, centred on its cell. White with edges when the playground's palette is white, timber
## otherwise - "a wooden panel".
static func populate(body:Node3D,part:Dictionary,phase:String)->void:
	var size:=Vector3(part.size[0],part.size[1],part.size[2])
	var mesh:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=size;mesh.mesh=box;mesh.name="Paddle"
	mesh.material_override=Finishes.surface("timber",phase);body.add_child(mesh)
	if part.get("collision",true):
		var shape:=CollisionShape3D.new();var solid:=BoxShape3D.new();solid.size=size;shape.shape=solid;body.add_child(shape)
	body.set_meta("windmill",part.get("windmill",""))
