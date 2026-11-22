extends RefCounted
## The same half-step construction describes the hand model and metre-scale output.
## Six neighbours; one- and two-metre edges; two complementary right triangles or one quad per square.
const AXES := [Vector3i.RIGHT,Vector3i.UP,Vector3i.BACK]
const LIMIT := 3
## Integer addresses are construction modules, not metres. Keep the hand-sized
## model reachable while one full-size module spans two 1m scaffold grid cells.
const WORLD_STEP := 2.0
const HAND_STEP := .2
var records: Array[Dictionary] = []
var domain_min := Vector3(-1, -1, -1)
var domain_max := Vector3(2, 2, 2)
var free_ground_points := false

static func vec(a: Array) -> Vector3:return Vector3(float(a[0]),float(a[1]),float(a[2]))
static func arr(v: Vector3) -> Array:
	var result:Array=[]
	for n in [v.x,v.y,v.z]:result.append(int(n) if is_equal_approx(n,roundf(n)) else float(n))
	return result
static func key(v: Vector3) -> String:return "%.1f,%.1f,%.1f"%[v.x,v.y,v.z]
static func inside(v: Vector3) -> bool:return v.x>=-1 and v.y>=-1 and v.z>=-1 and v.x<=2 and v.y<=2 and v.z<=2
func in_domain(v: Vector3) -> bool:return v.x>=domain_min.x-.001 and v.y>=domain_min.y-.001 and v.z>=domain_min.z-.001 and v.x<=domain_max.x+.001 and v.y<=domain_max.y+.001 and v.z<=domain_max.z+.001

func points() -> Dictionary:
	var result := {key(Vector3.ZERO):Vector3.ZERO}
	for r in records:
		if r.kind=="point":result[key(vec(r.at))]=vec(r.at)
	return result

func edge(a:Vector3,b:Vector3) -> bool:
	for r in records:
		if r.kind in ["rod","rod_short"] and ((vec(r.at)==a and vec(r.end)==b) or (vec(r.at)==b and vec(r.end)==a)):return true
	# Two 1m rods can close the same 2m side as one long rod; a 4 m side is two 2 m sides, and so on down to the metre.
	if a.distance_to(b)>.5+.001:
		var middle:Vector3=(a+b)*.5
		return edge(a,middle) and edge(middle,b)
	return false

func rod_overlaps(a:Vector3,b:Vector3) -> bool:
	var direction:Vector3=(b-a).normalized();var length:float=a.distance_to(b)
	for r in records:
		if r.kind not in ["rod","rod_short"]:continue
		var c:Vector3=vec(r.at)-a;var d:Vector3=vec(r.end)-a
		if c.cross(direction).length()>.001 or d.cross(direction).length()>.001:continue
		if minf(length,maxf(c.dot(direction),d.dot(direction)))-maxf(0,minf(c.dot(direction),d.dot(direction)))>.001:return true
	return false

func has_record(candidate: Dictionary) -> bool:
	for r in records:
		if r==candidate:return true
	return false

static func required_tier(kind:String) -> int:
	return {"point":0,"rod":1,"rod_short":1,"rod_4":1,"rod_8":1,"diag":2,"panel":2,"quad":3,"quad_4":3,"wedge":2,"pyramid":2}.get(kind,99)

## THE LONG RODS (Palle, 2026-10-31: "1, 2, 4, 8 m rods - add a 6-ball to every metre of the rod, so it works as a
## faster way to build for the player and for automatic reconstruction"). A long rod is a MACRO, not a record: laid
## from an existing point along an axis, it adds a point at every metre (every half address) that is not there yet
## and a one-metre rod between each pair that is not already joined. The saved graph stays the atomic grammar -
## points and one-metre rods - so the fitted copy, the walkers and the undo see nothing new.
const MACRO_UNITS := {"rod_4":2.0,"rod_8":4.0}   # address units; one unit is two metres
## THE BIG PLATE (Palle: "this idea can also be applied to surfaces so we reduce the geometry in the final build - if
## we place a 4 m surface we can remove the 6-ball at that middle position"). A 4 m quad is a macro too: laid from
## a point in a plane it lays the frame it needs - a joint at every metre along its four sides and the one-metre
## rods between - then ONE quad record of span 2, and takes away the joint at its centre if one stands there with
## nothing attached. One plate instead of four, and no joint under its middle.
const MACRO_FACES := {"quad_4":2.0}
static func is_macro(kind:String)->bool:return MACRO_UNITS.has(kind) or MACRO_FACES.has(kind)
static func is_macro_face(kind:String)->bool:return MACRO_FACES.has(kind)
## A macro face as the quad record it stands for (span filled in), for poses, shapes and looks.
static func as_face(r:Dictionary)->Dictionary:
	if not is_macro_face(str(r.get("kind",""))):return r
	var q:Dictionary=r.duplicate(true);q.span=MACRO_FACES[r.kind];q.kind="quad";return q

## The records a macro lays, given the model as it is: missing points, missing one-metre rods. Empty = illegal
## (off the domain, or a rod of its own would overlap one already there).
func macro_records(candidate:Dictionary)->Array[Dictionary]:
	if is_macro_face(str(candidate.kind)):return face_records(candidate)
	return line_records(vec(candidate.at),vec(candidate.end),points(),[])

## The points and one-metre rods a line from a to b still needs (every half address), given the model and the
## records already planned in `pending`. Empty = no room.
func line_records(a:Vector3,b:Vector3,nodes:Dictionary,pending:Array)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	var n:int=int(roundf(a.distance_to(b)*2))
	if n<1:return out
	var dir:Vector3=(b-a)/float(n)
	for i in range(1,n+1):
		var s:Vector3=a+dir*i
		if not in_domain(s):return []
		var planned:bool=pending.any(func(r):return r.kind=="point" and vec(r.at)==s)
		if not nodes.has(key(s)) and not planned:out.append({"kind":"point","at":arr(s)})
	for i in n:
		var s:Vector3=a+dir*i;var t:Vector3=a+dir*(i+1)
		var planned:bool=pending.any(func(r):return r.kind=="rod_short" and ((vec(r.at)==s and vec(r.end)==t) or (vec(r.at)==t and vec(r.end)==s)))
		if planned or edge_exact(s,t) or covered(s,t):continue   # already joined, or a longer rod along the same line covers it
		if rod_overlaps(s,t):return []                              # a rod crosses or half-covers the stretch: no room
		out.append({"kind":"rod_short","at":arr(s),"end":arr(t)})
	return out

## The frame and the plate of a macro face, and nothing under its middle. Empty = no room or the face is taken.
func face_records(candidate:Dictionary)->Array[Dictionary]:
	var face:=as_face(candidate);var span:float=float(face.span);var p:Vector3=vec(face.at)
	var u:Vector3=Vector3(AXES[face.plane[0]])*span;var v:Vector3=Vector3(AXES[face.plane[1]])*span
	if not in_domain(p) or not in_domain(p+u+v):return []
	if face_occupied(face.at,face.plane,-1,span):return []
	var out:Array[Dictionary]=[];var nodes:=points()
	for side in [[p,p+u],[p,p+v],[p+u,p+u+v],[p+v,p+u+v]]:
		var laid:Array[Dictionary]=line_records(side[0],side[1],nodes,out)
		if laid.is_empty() and not (edge(side[0],side[1])):return []
		for r in laid:out.append(r)
	out.append({"kind":"quad","at":face.at,"plane":face.plane,"span":span})
	return out

## A point nothing holds on to: no rod ends on it, no face has it for a corner.
func point_free(at:Vector3)->bool:
	for r in records:
		if r.kind in ["rod","rod_short","diag"] and (vec(r.at)==at or vec(r.end)==at):return false
		if r.kind in ["panel","quad"]:
			var s:float=float(r.get("span",1));var u:Vector3=Vector3(AXES[r.plane[0]])*s;var v:Vector3=Vector3(AXES[r.plane[1]])*s;var q:Vector3=vec(r.at)
			if at in [q,q+u,q+v,q+u+v]:return false
	return true

## A rod record along the same line that holds both addresses (the stretch between them is already a rod).
func covered(a:Vector3,b:Vector3)->bool:
	for r in records:
		if r.kind not in ["rod","rod_short"]:continue
		var p:Vector3=vec(r.at);var q:Vector3=vec(r.end);var length:float=p.distance_to(q)
		if length<.001:continue
		var d:Vector3=(q-p)/length;var ca:Vector3=a-p;var cb:Vector3=b-p
		if ca.cross(d).length()>.001 or cb.cross(d).length()>.001:continue
		var ta:float=ca.dot(d);var tb:float=cb.dot(d)
		if ta>=-.001 and ta<=length+.001 and tb>=-.001 and tb<=length+.001:return true
	return false

## A rod record between exactly these two addresses (either way round).
## A diagonal record between exactly these two addresses (either way round).
func diag_exists(a:Vector3,b:Vector3)->bool:
	for r in records:
		if r.kind=="diag" and ((vec(r.at)==a and vec(r.end)==b) or (vec(r.at)==b and vec(r.end)==a)):return true
	return false

## A half face's own three edges: two sides of its square and the diagonal it is cut along. Halves 0 and 1 are cut
## along at -> at+u+v, halves 2 and 3 along at+u -> at+v.
func triangle_edges(p:Vector3,u:Vector3,v:Vector3,half:int)->bool:
	match half:
		0:return edge(p,p+u) and edge(p+u,p+u+v) and diag_exists(p,p+u+v)
		1:return edge(p,p+v) and edge(p+v,p+u+v) and diag_exists(p,p+u+v)
		2:return edge(p,p+u) and edge(p,p+v) and diag_exists(p+u,p+v)
		3:return edge(p+u,p+u+v) and edge(p+v,p+u+v) and diag_exists(p+u,p+v)
	return false

func edge_exact(a:Vector3,b:Vector3)->bool:
	for r in records:
		if r.kind in ["rod","rod_short"] and ((vec(r.at)==a and vec(r.end)==b) or (vec(r.at)==b and vec(r.end)==a)):return true
	return false

static func is_prefab(kind:String)->bool:return kind in ["wedge","pyramid"]

## A solid's side in addresses: 1 (the 2 m bay solid, centred on `at`) or .5 (the CELL solid, 2026-11-06: it
## stands in the 1 m cell whose low corner is `at`, between the balls - a pyramid fills that cell to the next
## node level, a wedge runs on into the next cell along its facing and rises one level over the two).
static func prefab_span(r:Dictionary)->float:return .5 if float(r.get("span",1))==.5 else 1.0

## The envelope a solid occupies, in addresses.
static func prefab_box(r:Dictionary)->AABB:
	return pose(r)*prefab_envelope(r)

## The same in the solid's own frame (before its turn).
static func prefab_envelope(r:Dictionary)->AABB:
	if prefab_span(r)==1.0:return AABB(Vector3(-.5,0,-.5),Vector3(1,.5,1))
	if str(r.get("kind",""))=="wedge":return AABB(Vector3(-.25,0,-.25),Vector3(.5,.5,1))
	return AABB(Vector3(-.25,0,-.25),Vector3(.5,.5,.5))

func prefab_fits(candidate:Dictionary)->bool:
	if candidate.is_empty() or not in_domain(vec(candidate.at)):return false
	# Completed solids occupy a 2 x 1 x 2 m envelope (a cell pyramid 1 x 1 x 1 m, a cell wedge 1 x 1 x 2 m), in quarter turns.
	var bounds:AABB=prefab_box(candidate)
	if not in_domain(bounds.position) or not in_domain(bounds.end):return false
	for r in records:
		if is_prefab(r.kind):
			var other:AABB=prefab_box(r)
			if bounds.grow(-.001).intersects(other.grow(-.001)):return false
	return true

func face_occupied(at:Array,plane:Array,half:int=-1,span:float=1) -> bool:
	for r in records:
		if r.kind not in ["panel","quad"] or r.plane!=plane:continue
		var u:int=plane[0];var v:int=plane[1];var normal:int=3-u-v
		if r.at[normal]!=at[normal]:continue
		var other:float=float(r.get("span",1))
		var a:=Rect2(float(at[u]),float(at[v]),span,span)
		var b:=Rect2(float(r.at[u]),float(r.at[v]),other,other)
		if not a.intersects(b):continue
		if a!=b or half<0 or r.kind=="quad" or r.half==half or (int(r.half)<2)!=(half<2):return true   # 0/1 split one diagonal, 2/3 the other
	return false

func candidates(kind:String,tier:int) -> Array[Dictionary]:
	var result:Array[Dictionary]=[]
	if required_tier(kind)>tier:return result
	var nodes:=points();var seen:Dictionary={}
	for p:Vector3 in nodes.values():
		if kind=="point":
			for axis in AXES:
				for sign_value in [-1,1]:
					for step in [.5,1.0]:
						var q:Vector3=p+Vector3(axis)*sign_value*step
						if in_domain(q) and not nodes.has(key(q)) and not seen.has(key(q)):
							result.append({"kind":"point","at":arr(q)});seen[key(q)]=true
		elif kind in ["rod","rod_short"]:
			for axis in AXES:
				var q:Vector3=p+Vector3(axis)*(.5 if kind=="rod_short" else 1.0)
				if nodes.has(key(q)) and not rod_overlaps(p,q):result.append({"kind":kind,"at":arr(p),"end":arr(q)})
		elif is_macro_face(kind):
			for plane in [[0,1],[0,2],[1,2]]:
				var c:Dictionary={"kind":kind,"at":arr(p),"plane":plane}
				if not macro_records(c).is_empty() and c not in result:result.append(c)
		elif is_macro(kind):
			for axis in AXES:
				for sign_value in [-1,1]:
					var q:Vector3=p+Vector3(axis)*sign_value*float(MACRO_UNITS[kind])
					var c:Dictionary={"kind":kind,"at":arr(p),"end":arr(q)}
					if in_domain(q) and not macro_records(c).is_empty() and c not in result:result.append(c)
		elif kind=="diag":
			# THE DIAGONAL (2026-11-06): across a square's face, either way, a whole or a half step
			for plane in [[0,1],[0,2],[1,2]]:
				for span in [.5,1.0]:
					var u:Vector3=Vector3(AXES[plane[0]])*span;var v:Vector3=Vector3(AXES[plane[1]])*span
					for q:Vector3 in [p+u+v,p+u-v]:
						if nodes.has(key(q)) and in_domain(q) and not diag_exists(p,q) and not seen.has(key(p)+">"+key(q)) and not seen.has(key(q)+">"+key(p)):
							result.append({"kind":"diag","at":arr(p),"end":arr(q)});seen[key(p)+">"+key(q)]=true
		elif kind in ["panel","quad"]:
			for plane in [[0,1],[0,2],[1,2]]:
				for span in [.5,1.0]:
					var u:Vector3=Vector3(AXES[plane[0]])*span;var v:Vector3=Vector3(AXES[plane[1]])*span
					var square:bool=edge(p,p+u) and edge(p,p+v) and edge(p+u,p+u+v) and edge(p+v,p+u+v)
					if kind=="quad" and not square:continue
					for half in ([-1] if kind=="quad" else [0,1,2,3]):
						if kind=="panel" and not (square or triangle_edges(p,u,v,half)):continue
						if face_occupied(arr(p),plane,half,span):continue
						var r:Dictionary={"kind":kind,"at":arr(p),"plane":plane}
						if kind=="panel":r.half=half
						if span!=1.0:r.span=span
						result.append(r)
	return result

func _clone_empty():
	var other=get_script().new()
	other.domain_min=domain_min;other.domain_max=domain_max;other.free_ground_points=free_ground_points
	return other

func _can_add_atomic(clean:Dictionary,tier:int)->bool:
	var kind:String=str(clean.get("kind",""))
	if required_tier(kind)>tier:return false
	var nodes:=points()
	if kind=="point":
		var p:Vector3=vec(clean.at)
		if not in_domain(p) or nodes.has(key(p)):return false
		if free_ground_points and is_equal_approx(p.y,0.0):return true
		for axis in AXES:
			for sign_value in [-1,1]:
				for s in [.5,1.0]:
					if nodes.has(key(p+Vector3(axis)*sign_value*s)):return true
		return false
	if kind in ["rod","rod_short"]:
		var a:Vector3=vec(clean.at);var b:Vector3=vec(clean.end)
		if not nodes.has(key(a)) or not nodes.has(key(b)):return false
		var want:float=.5 if kind=="rod_short" else 1.0
		var diff:Vector3=b-a
		var aligned:=false
		for axis in AXES:
			if diff.is_equal_approx(Vector3(axis)*want) or diff.is_equal_approx(-Vector3(axis)*want):aligned=true;break
		return aligned and not rod_overlaps(a,b)
	if kind=="diag":
		var a:Vector3=vec(clean.at);var b:Vector3=vec(clean.end)
		if not nodes.has(key(a)) or not nodes.has(key(b)) or not in_domain(a) or not in_domain(b) or diag_exists(a,b):return false
		var d:Vector3=(b-a).abs()
		for span in [.5,1.0]:
			var eq_x:=is_equal_approx(d.x,span);var eq_y:=is_equal_approx(d.y,span);var eq_z:=is_equal_approx(d.z,span)
			if (eq_x and eq_y and is_zero_approx(d.z)) or (eq_x and eq_z and is_zero_approx(d.y)) or (eq_y and eq_z and is_zero_approx(d.x)):return true
		return false
	if kind in ["panel","quad"]:
		var p:Vector3=vec(clean.at);var plane:Array=clean.plane;var span:float=float(clean.get("span",1.0))
		if not (plane in [[0,1],[0,2],[1,2]]) or span not in [.5,1.0,2.0]:return false
		var u:Vector3=Vector3(AXES[plane[0]])*span;var v:Vector3=Vector3(AXES[plane[1]])*span
		if not in_domain(p) or not in_domain(p+u+v):return false
		var half:int=-1 if kind=="quad" else int(clean.get("half",-1))
		if face_occupied(clean.at,plane,half,span):return false
		var sq:bool=edge(p,p+u) and edge(p,p+v) and edge(p+u,p+u+v) and edge(p+v,p+u+v)
		return sq if kind=="quad" else (sq or triangle_edges(p,u,v,half))
	return false

func add(candidate: Dictionary,tier: int) -> bool:
	var kind:String=str(candidate.get("kind",""))
	if is_prefab(kind):
		var clean:=canonical(candidate)
		if tier<2 or not prefab_fits(clean):return false
		records.append(clean);return true
	if is_macro(kind):
		if candidate not in candidates(kind,tier):return false
		for r in macro_records(candidate):records.append(r)
		if is_macro_face(kind):
			# the joint under the plate's middle goes, when nothing holds on to it: one plate, no ball beneath it
			var face:=as_face(candidate);var s:float=float(face.span)
			var centre:Vector3=vec(face.at)+(Vector3(AXES[face.plane[0]])+Vector3(AXES[face.plane[1]]))*s*.5
			for i in range(records.size()-1,-1,-1):
				if records[i].kind=="point" and vec(records[i].at)==centre and point_free(centre):records.remove_at(i)
		return true
	var clean:=canonical(candidate)
	if clean.is_empty() or not _can_add_atomic(clean,tier):return false
	if kind in ["rod","rod_short"]:
		# Keep canonical ascending order along the axis so saved records match candidates() deterministically.
		var a:Vector3=vec(clean.at);var b:Vector3=vec(clean.end)
		if (b-a).x<0 or (b-a).y<0 or (b-a).z<0:
			var tmp=clean.at;clean.at=clean.end;clean.end=tmp
	records.append(clean);return true

func restore(raw: Array) -> bool:
	var before:=records.duplicate(true);records.clear()
	# Bound the finer one-metre lattice; old integer records retain their exact poses.
	if raw.size()>2048:records=before;return false
	for r in raw:
		if not r is Dictionary or not add(canonical(r),3):
			set_meta("restore_error",{"index":records.size(),"record":r});records=before;return false
	return true

func revision(index:int,replacement:Dictionary={}) -> Dictionary:
	# Reorder dependencies only in the proposed copy. Failed edits never mutate us.
	if index<0 or index>=records.size():return {"ok":false}
	if replacement==records[index]:return {"ok":true,"records":records.duplicate(true)}
	var pending:Array=records.duplicate(true);pending.remove_at(index)
	if not replacement.is_empty():pending.insert(index,replacement.duplicate(true))
	var rebuilt=_clone_empty()
	while not pending.is_empty():
		var progressed:=false
		for i in range(pending.size()-1,-1,-1):
			if rebuilt.add(pending[i],3):pending.remove_at(i);progressed=true
		if not progressed:return {"ok":false}
	return {"ok":true,"records":rebuilt.records.duplicate(true)}

func edit_candidates(index:int,tier:int) -> Array[Dictionary]:
	if index<0 or index>=records.size():return []
	var other=_clone_empty();other.records=records.duplicate(true)
	var kind:String=other.records[index].kind;other.records.remove_at(index)
	return other.candidates(kind,tier)

static func canonical(raw:Dictionary) -> Dictionary:
	# JSON numbers arrive as floats. Rebuild the integer grammar before matching
	# candidate dictionaries. Half addresses are the added 1m lattice; integers stay integers.
	var kind:String=str(raw.get("kind",""));var result:Dictionary={"kind":kind}
	if kind not in ["point","rod","rod_short","diag","panel","quad","wedge","pyramid"]:return {}
	var fields:Array=["at"]
	if kind in ["rod","rod_short","diag"]:fields.append("end")
	if kind in ["panel","quad"]:fields.append("plane")
	for field:String in fields:
		var value=raw.get(field)
		if not value is Array or value.size()!=(2 if field=="plane" else 3):return {}
		var numbers:Array=[]
		for n in value:
			if not (n is int or n is float) or not is_finite(float(n)) or not is_equal_approx(float(n)*2,roundf(float(n)*2)):return {}
			numbers.append(int(n) if float(n)==float(int(n)) else float(n))
		result[field]=numbers
	if is_prefab(kind):
		var turn=raw.get("turn",[0,0,0])
		if not turn is Array or turn.size()!=3:return {}
		result.turn=[]
		for n in turn:
			if not (n is int or n is float) or not is_finite(float(n)) or float(n)!=roundf(float(n)):return {}
			result.turn.append(posmod(int(n),4))
		if raw.has("span"):
			if not (raw.span is int or raw.span is float) or float(raw.span) not in [.5,1.0]:return {}
			if float(raw.span)==.5:result.span=.5
	if kind=="panel":
		var half=raw.get("half")
		if not (half is int or half is float) or float(half) not in [0.0,1.0,2.0,3.0]:return {}
		result.half=int(half)
	if kind in ["panel","quad"] and raw.has("span"):
		if raw.span not in [.5,1,1.0,2,2.0]:return {}
		if float(raw.span)==.5:result.span=.5
		if float(raw.span)==2.0:result.span=2.0
	return result

static func pose(raw: Dictionary) -> Transform3D:
	var r:Dictionary=as_face(raw)
	var p:=Vector3(vec(r.at))
	if is_prefab(r.kind):
		var axes:=Basis.from_euler(vec(r.get("turn",[0,0,0]))*PI*.5)
		if prefab_span(r)==.5:p+=Vector3(.25,0,.25)   # the cell solid turns about its own cell's centre
		return Transform3D(Basis(axes.x.round(),axes.y.round(),axes.z.round()),p)
	if r.kind in ["rod","rod_short","diag"] or is_macro(r.kind):
		var q:=Vector3(vec(r.end));var centre:Vector3=(p+q)*.5
		if r.get("_seated",false):centre.y-=.0375
		return Transform3D(Basis(Quaternion(Vector3.UP,(q-p).normalized())),centre)
	if r.kind in ["panel","quad"]:
		var u:=Vector3(AXES[r.plane[0]]);var v:=Vector3(AXES[r.plane[1]]);var span:float=float(r.get("span",1))
		var centres:Array[Vector3]=[Vector3(2.0/3,0,1.0/3),Vector3(1.0/3,0,2.0/3),Vector3(1.0/3,0,1.0/3),Vector3(2.0/3,0,2.0/3)]
		var centre:Vector3=Vector3(.5,0,.5) if r.kind=="quad" else centres[int(r.half)]
		# The named face is the contact plane. Thickness extends behind it, so a
		# horizontal face at one metre has its walkable top at exactly one metre.
		var normal:Vector3=v.cross(u)
		return Transform3D(Basis(u,normal,v),p+(u*centre.x+v*centre.z)*span-normal*.018)
	return Transform3D(Basis.IDENTITY,p)

func ground_address()->float:
	return ground_for(records)

static func ground_for(all:Array)->float:
	# Joint centres and solid bases define construction heights; render thickness
	# must not add a floating pedestal to the whole graph.
	var lowest:=0.0
	for r in all:
		if r.kind=="point":lowest=minf(lowest,vec(r.at).y)
		if is_prefab(r.kind):
			var bounds:AABB=prefab_box(r)
			lowest=minf(lowest,bounds.position.y)
	return lowest

static func fit_record(record:Dictionary,all:Array)->Dictionary:
	var r:Dictionary=record.duplicate(true)
	if r.kind not in ["point","rod","rod_short"]:return r
	var points:Array=[vec(r.at)]
	if r.kind!="point":
		points.append(vec(r.end))
		if not is_equal_approx(points[0].y,points[1].y):return r
	var ground:float=ground_for(all)
	var has_solid:bool=all.any(func(part):return is_prefab(part.kind))
	var seated:=true
	for p:Vector3 in points:
		var supported:bool=has_solid and is_equal_approx(p.y,ground)
		for face in all:
			if face.kind not in ["panel","quad"] or face.plane!=[0,2]:continue
			var local:Vector3=p-vec(face.at);var span:float=float(face.get("span",1))
			if absf(local.y)>.001 or local.x<0 or local.z<0 or local.x>span or local.z>span:continue
			if face.kind=="quad" or (face.half==0 and local.z<=local.x) or (face.half==1 and local.z>=local.x) or (face.half==2 and local.x+local.z<=span) or (face.half==3 and local.x+local.z>=span):supported=true
		seated=seated and supported
	if seated:r._seated=true
	return r
