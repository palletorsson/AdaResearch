extends Node3D
## OUR decoding studies after the supplied LeWitt images, not certified replicas.
## The cyclic table and height fields are proposed rules, not historical scores.
const Structure = preload("res://commons/artifacts/spine_studies/open_structure.gd")
const NAMES := ["cube", "pyramid", "narrow box", "taper", "shear"]
var mode := 0
var alternative := false
var visible_fraction := 1.0
var bars: MultiMeshInstance3D
var records: Array=[]
var total_edges := 0

func _ready() -> void: rebuild()

# These three numbers form a small vocabulary. The y height stays one metre.
func shape(which: int) -> Array[Vector3]:
	match which:
		1:return Structure.corners(1.0,0.0,0.0)
		2:return Structure.corners(0.38,1.0,0.0)
		3:return Structure.corners(1.0,0.52,0.0)
		4:return Structure.corners(1.0,1.0,0.32)
	return Structure.corners()

# The address decides the form. A cyclic shift is our proposed reading of a series.
func form_at(column: int,row: int) -> int:
	if alternative:return column
	return (column+row)%5

# Five possible height rules on one footprint. Our rules, not LeWitt's score.
func height_at(x: int,z: int,version: int) -> int:
	match version:
		0:return x+1
		1:return 5-x
		2:return z+1
		3:return 5-z
	return 5

func occupied(x: int,z: int) -> bool:
	return alternative or x==2 or z==2

func translated_edges(points: Array[Vector3],at: Vector3,unit: float=1.0) -> Array:
	var moved: Array[Vector3]=[]
	for p in points:moved.append(at+p*unit)
	return Structure.segments(moved)

## Mode 4, the console's 122: LeWitt's Incomplete Open Cubes (1974) as a rule run to exhaustion.
## Every subset of the 12 edges that stays connected and three-dimensional, once per rotation of
## the cube (24), enumerated here, not listed: the count is the check. ada_encyclopedia's
## colour-study.ts finds the same list; tools/address_rules_crosscheck.py --lewitt compares them.
const CUBE := [Vector3i(-1,-1,-1),Vector3i(1,-1,-1),Vector3i(1,-1,1),Vector3i(-1,-1,1),Vector3i(-1,1,-1),Vector3i(1,1,-1),Vector3i(1,1,1),Vector3i(-1,1,1)]

static func incomplete_open_cubes() -> Array:
	var perms: Array = []   # the 24 rotations, each as a permutation of the 12 edges
	for ax in [[0,1,2],[0,2,1],[1,0,2],[1,2,0],[2,0,1],[2,1,0]]:
		var even: bool = ax in [[0,1,2],[1,2,0],[2,0,1]]
		for sg in 8:
			var sgn := [(-1 if sg & 1 else 1), (-1 if sg & 2 else 1), (-1 if sg & 4 else 1)]
			if (1 if even else -1) * sgn[0] * sgn[1] * sgn[2] < 0: continue
			var corner_map: Array = []
			for c in CUBE:
				var q := Vector3i(c[ax[0]] * sgn[0], c[ax[1]] * sgn[1], c[ax[2]] * sgn[2])
				corner_map.append(CUBE.find(q))
			var perm: Array = []
			for e in Structure.EDGES:
				var a: int = corner_map[e[0]]
				var b: int = corner_map[e[1]]
				for j in Structure.EDGES.size():
					var f: Array = Structure.EDGES[j]
					if (f[0] == a and f[1] == b) or (f[0] == b and f[1] == a):
						perm.append(j)
			perms.append(perm)
	var seen := {}
	var out: Array = []
	for mask in range(1, 4095):
		var axes := {}
		var used: Array = []
		for i in 12:
			if mask & (1 << i):
				var e: Array = Structure.EDGES[i]
				used.append(e)
				var d: Vector3i = CUBE[e[1]] - CUBE[e[0]]
				axes[0 if d.x != 0 else (1 if d.y != 0 else 2)] = true
		if axes.size() < 3: continue   # flat: a connected set on two axes lies in one face
		var reach := {used[0][0]: true}
		var nodes := {}
		for e in used:
			nodes[e[0]] = true
			nodes[e[1]] = true
		var grew := true
		while grew:
			grew = false
			for e in used:
				if reach.has(e[0]) != reach.has(e[1]):
					reach[e[0]] = true
					reach[e[1]] = true
					grew = true
		if reach.size() != nodes.size(): continue   # not connected
		var canon := 4096
		for perm in perms:
			var m := 0
			for i in 12:
				if mask & (1 << i): m |= 1 << int(perm[i])
			canon = mini(canon, m)
		if not seen.has(canon):
			seen[canon] = true
			out.append(canon)
	return out

func rebuild() -> void:
	for child in get_children():
		remove_child(child);child.queue_free()
	records.clear()
	var lines: Array=[]
	if mode==4:
		var by_edges := {}
		for m in incomplete_open_cubes():
			var k := 0
			for i in 12: k += (m >> i) & 1
			if not by_edges.has(k): by_edges[k] = []
			by_edges[k].append(m)
		var line := 0.0
		var keys: Array = by_edges.keys()
		keys.sort()
		for k in keys:
			var list: Array = by_edges[k]
			list.sort()
			for i in list.size():
				var at := Vector3((i % 16 - 7.5) * .55, .18, (line + floor(i / 16.0)) * .55 - 3.0)
				var p := Structure.corners()
				for j in Structure.EDGES.size():
					if list[i] & (1 << j):
						var e: Array = Structure.EDGES[j]
						lines.append([at + p[e[0]] * .42, at + p[e[1]] * .42])
				records.append({"mask": list[i], "edges": k, "origin": at})
			plaque(Vector3(-4.75, .18, line * .55 - 3.0), "%d" % k)
			line += ceil(list.size() / 16.0) + .3
		plinth(Vector3(0, .08, (line - .3) * .55 * .5 - 3.2), Vector3(9.4, .16, (line - .3) * .55 + .5))
		plaque(Vector3(0, .18, -3.6), "%d INCOMPLETE OPEN CUBES" % records.size())
	elif mode==0 or mode==3:
		var count := 5 if mode==0 else 7
		for i in count:
			var at:=Vector3((i-(count-1)*.5)*1.65,.18,0)
			var p:=shape(i) if mode==0 else Structure.corners(1.0,float(i)/6.0,0.0)
			lines.append_array(translated_edges(p,at))
			records.append({"index":i,"top_fraction":float(i)/6.0 if mode==3 else -1.0,"origin":at})
			plaque(at+Vector3(0,0,-.83),NAMES[i] if mode==0 else "%.2f"%(float(i)/6.0))
		plinth(Vector3(0,.08,0),Vector3(count*1.65+.5,.16,2.15))
	elif mode==1:
		for row in 5:
			for column in 5:
				var kind:=form_at(column,row)
				var at:=Vector3((column-2)*1.65,.18,(row-2)*1.65)
				lines.append_array(translated_edges(shape(kind),at,.9))
				plinth(Vector3(at.x,.08,at.z),Vector3(1.55,.16,1.55))
				records.append({"column":column,"row":row,"form":kind,"origin":at})
	else:
		var sites := [Vector3(-3.5,.06,-1.6),Vector3(0,.06,-1.6),Vector3(3.5,.06,-1.6),Vector3(-1.8,.06,2),Vector3(1.8,.06,2)]
		var unique: Dictionary={}
		for version in 5:
			for z in 5:
				for x in 5:
					if not occupied(x,z):continue
					var height:=height_at(x,z,version)
					records.append({"version":version,"x":x,"z":z,"height":height})
					for y in height:
						var at: Vector3=sites[version]+Vector3(x-2,y,z-2)*.31
						for segment in translated_edges(shape(0),at,.31):
							# Adjacent cells share a physical bar. Merge its two representations.
							var a: String=str(segment[0].snapped(Vector3.ONE*.0001))
							var b: String=str(segment[1].snapped(Vector3.ONE*.0001))
							unique[a+"|"+b if a<b else b+"|"+a]=segment
			plaque(sites[version]+Vector3(0,0,1.17),["x + 1","5 - x","z + 1","5 - z","5 everywhere"][version])
		lines=unique.values()
	bars=Structure.display(lines,.028 if mode==2 or mode==4 else .065)
	add_child(bars)
	total_edges=lines.size()
	set_reveal(visible_fraction)

func set_reveal(value: float) -> void:
	visible_fraction=clampf(value,0,1)
	if is_instance_valid(bars):bars.multimesh.visible_instance_count=roundi(total_edges*visible_fraction)

func plinth(at: Vector3,size: Vector3) -> void:
	var mesh:=MeshInstance3D.new()
	var box:=BoxMesh.new();box.size=size;mesh.mesh=box;mesh.position=at
	var material:=StandardMaterial3D.new();material.albedo_color=Color(.62,.64,.61);material.roughness=.9
	mesh.material_override=material;add_child(mesh)

func plaque(at: Vector3,text: String) -> void:
	var label:=Label3D.new();label.text=text;label.font_size=36;label.pixel_size=.0018
	label.modulate=Color(.18,.22,.21);label.outline_size=0
	label.position=at+Vector3(0,.025,0);label.rotation_degrees.x=-90;add_child(label)
