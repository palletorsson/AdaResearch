extends RefCounted
const VERTICES := [Vector3(-.5,-.5,.5),Vector3(.5,-.5,.5),Vector3(.5,.5,.5),Vector3(-.5,.5,.5),
	Vector3(-.5,-.5,-.5),Vector3(.5,-.5,-.5),Vector3(.5,.5,-.5),Vector3(-.5,.5,-.5)]
const FACES := [[0,1,2],[0,2,3],[5,4,7],[5,7,6],[4,0,3],[4,3,7],
	[1,5,6],[1,6,2],[3,2,6],[3,6,7],[4,5,1],[4,1,0]]

func build(recipe: Dictionary) -> Dictionary:
	if recipe.rounds < 0 or recipe.rounds > 3:
		return {"accepted":false,"error":"Use zero to three rounds."}
	var chosen: Array = recipe.faces
	for id in chosen:
		if not id is int or id < 0 or id >= 12 or chosen.count(id) != 1:
			return {"accepted":false,"error":"Use distinct seed-face indices from zero to eleven."}
	var mesh := {"vertices":PackedVector3Array(VERTICES),"faces":[],"tags":[],
		"accepted":true,"recipe":recipe.duplicate(true)}
	for i in FACES.size():
		mesh.faces.append(PackedInt32Array(FACES[i]))
		mesh.tags.append("growing" if chosen.has(i) else "seed")
	if recipe.get("inset_only",false): operate(mesh,true,recipe.amount)
	for round in int(recipe.rounds):
		operate(mesh,true,recipe.amount)
		operate(mesh,false,recipe.amount)
	return mesh

func operate(mesh: Dictionary, inset: bool, amount: float) -> void:
	# Select once per operation, before removing any faces.
	var selected: Array[int] = []
	for i in mesh.faces.size():
		if mesh.tags[i] == "growing": selected.append(i)
	selected.reverse()
	for id in selected:
		var face: PackedInt32Array = mesh.faces[id]
		var a: Vector3 = mesh.vertices[face[0]]
		var b: Vector3 = mesh.vertices[face[1]]
		var c: Vector3 = mesh.vertices[face[2]]
		var centre := (a+b+c)/3.0
		var normal := (b-a).cross(c-a)
		if not inset:
			var shortest := minf(a.distance_to(b),minf(b.distance_to(c),c.distance_to(a)))
			var longest := maxf(a.distance_to(b),maxf(b.distance_to(c),c.distance_to(a)))
			# Match the museum's area/aspect guards before extrusion.
			if normal.length()*.5 < .001 or shortest/longest < .05: continue
		var tips: Array[int] = []
		for p in [a,b,c]:
			tips.append(mesh.vertices.size())
			var at: Vector3 = p.lerp(centre,clampf(amount,.01,.99)) if inset else p+normal.normalized()*.4
			mesh.vertices.append(at)
		mesh.faces.remove_at(id); mesh.tags.remove_at(id)
		add_face(mesh,tips,"growing")
		for j in 3:
			var k := (j+1)%3
			var role := "growing"
			add_face(mesh,[face[j],face[k],tips[k]],role)
			add_face(mesh,[face[j],tips[k],tips[j]],role)

func add_face(mesh: Dictionary, indices: Array, tag: String) -> void:
	mesh.faces.append(PackedInt32Array(indices)); mesh.tags.append(tag)

func surface(mesh: Dictionary) -> ArrayMesh:
	var builder := SurfaceTool.new(); builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in mesh.faces.size():
		var face: PackedInt32Array = mesh.faces[i]
		var a: Vector3 = mesh.vertices[face[0]]
		var b: Vector3 = mesh.vertices[face[1]]
		var c: Vector3 = mesh.vertices[face[2]]
		var normal := (b-a).cross(c-a)
		if normal.length_squared() < 1e-10: continue
		var colour := Color("ddd9ce")
		if mesh.tags[i] == "growing": colour=Color("ea749a")
		elif mesh.tags[i] == "shoulder": colour=Color("84c9be")
		builder.set_normal(normal.normalized()); builder.set_color(colour)
		for p in [a,b,c]: builder.add_vertex(p)
	return builder.commit()
