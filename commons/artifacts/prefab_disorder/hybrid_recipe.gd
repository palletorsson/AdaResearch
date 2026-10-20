extends RefCounted
## Authored grafts: chance separates the inventory; these rules join it again.
## Every visible mesh is used once. Bundles preserve recognisable local details.
const VERSION="four-grafts/1"
const TITLES=["SCREEN WALKER", "PETAL SCOPE", "BOX OBSERVATORY", "VIEWING PERCH"]
var parts: Array[Dictionary]
var assigned: Dictionary={}

func build(source_parts: Array[Dictionary], inventory: Array[Dictionary], side: float) -> Array[Dictionary]:
	parts=source_parts;assigned.clear()
	# Stool feet carry the monitor face; a cardboard flap becomes its visor.
	var h:=place(0,2,["Hub","Leg_*","Foot_*"],Vector3.ZERO)
	h+=place(0,1,["FrontCasing","Bezel*","Screen","PowerLED","Button_*"],Vector3(0,h,0))
	place(0,0,["FrontFlap"],Vector3(0,h,-0.02))
	# A screen stand and stool stem support optics inside three cardboard petals.
	h=place(1,1,["StandBase","PivotNeck"],Vector3.ZERO)
	h+=place(1,2,["Post"],Vector3(0,h,0))
	place(1,3,["TurretDisc","Objective_*"],Vector3(0,h,0))
	place(1,0,["BackFlap","LeftFlap","RightFlap"],Vector3(0,h-0.025,0))
	# The box receives a specimen stage and binocular eyes on a CRT plinth.
	h=place(2,1,["TubeHousingFar"],Vector3.ZERO,Basis(Vector3.RIGHT,PI/2))
	var box_h:=place(2,0,["BottomPanel","FrontWall","BackWall","LeftWall","RightWall"],Vector3(0,h,0))
	place(2,3,["Illuminator"],Vector3(0,h+0.018,0))
	place(2,3,["Stage","Clamp_*"],Vector3(0,h+box_h-0.025,0))
	place(2,3,["Eyepiece_*"],Vector3(0,h+box_h,0))
	# A microscope foot, CRT casing and stool seat form a perch with a cantilever.
	h=place(3,3,["Base","AccentStrip"],Vector3.ZERO)
	h+=place(3,1,["TubeHousingNear"],Vector3(0,h,0),Basis(Vector3.RIGHT,PI/2))
	h+=place(3,2,["Seat","AccentStrip"],Vector3(0,h,0))
	place(3,3,["Column"],Vector3(0,h,0),Basis(Vector3.FORWARD,PI/2))
	assert(assigned.size()==parts.size(),"Hybrid recipe must account for every source mesh")
	# Fit each completed hybrid uniformly to its pad; retain each source material.
	for group in 4:
		var bounds: AABB
		var first:=true
		for index in assigned:
			var entry: Dictionary=assigned[index]
			if entry.group!=group: continue
			var b: AABB=entry.pose*parts[index].bounds
			bounds=b if first else bounds.merge(b);first=false
		var scale_factor:=0.55/maxf(bounds.size.x,maxf(bounds.size.y,bounds.size.z))
		var origin: Vector3=inventory[group].grid+Vector3(side,0,0)
		var offset:=Vector3(-bounds.get_center().x,-bounds.position.y,-bounds.get_center().z)*scale_factor
		var fit:=Transform3D(Basis.from_scale(Vector3.ONE*scale_factor),origin+offset)
		for index in assigned:
			if assigned[index].group==group: assigned[index].pose=fit*assigned[index].pose
	var result: Array[Dictionary]=[]
	for i in parts.size(): result.append({"item":parts[i].item,"key":parts[i].key,"group":assigned[i].group,"pose":pack(assigned[i].pose)})
	return result

func place(group: int, item: int, names: Array, at: Vector3, turn:=Basis.IDENTITY) -> float:
	var selected: Array[int]=[]
	var bounds: AABB
	for i in parts.size():
		if parts[i].item!=item: continue
		for pattern in names:
			if not String(parts[i].label).match(pattern): continue
			assert(not assigned.has(i),"A hybrid mesh cannot be used twice")
			var b: AABB=Transform3D(turn,Vector3.ZERO)*parts[i].home*parts[i].bounds
			bounds=b if selected.is_empty() else bounds.merge(b)
			selected.append(i);break
	assert(not selected.is_empty(),"Missing authored mesh bundle")
	var offset:=at-Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)
	for i in selected: assigned[i]={"group":group,"pose":Transform3D(turn,offset)*parts[i].home}
	return bounds.size.y

static func pack(t: Transform3D) -> Array:
	return [t.basis.x.x,t.basis.x.y,t.basis.x.z,t.basis.y.x,t.basis.y.y,t.basis.y.z,t.basis.z.x,t.basis.z.y,t.basis.z.z,t.origin.x,t.origin.y,t.origin.z]

static func unpack(a: Array) -> Transform3D:
	return Transform3D(Basis(Vector3(a[0],a[1],a[2]),Vector3(a[3],a[4],a[5]),Vector3(a[6],a[7],a[8])),Vector3(a[9],a[10],a[11]))
