extends RefCounted
## Native, deterministic ports of the State and Function browser studies.
## These values belong to the teaching model, never to the visitor or hall.
const SIDES: Array[int] = [4, 6, 8, 12, 16]
const RADIUS := 0.70 # Declared 3D display radius; the browser used 49 pixels.

static func initial_state() -> Dictionary:
	return {"frames":0, "elapsed":0.0, "near":false, "visited":false}

static func state_action(state: Dictionary, key: String) -> void:
	match key:
		"frame":
			state.frames += 1
			state.elapsed += 0.5
		"proximity":
			state.near = not state.near
			if state.near: state.visited = true
		"reset":
			state.merge(initial_state(), true)

static func initial_function() -> Dictionary:
	return {"height":2.0, "sides":8}

static func function_action(state: Dictionary, key: String) -> void:
	match key:
		"sides": state.sides = SIDES[(SIDES.find(int(state.sides))+1)%SIDES.size()]
		"lower": state.height = maxf(1.0, snappedf(float(state.height)-0.1,0.1))
		"raise": state.height = minf(3.0, snappedf(float(state.height)+0.1,0.1))
		"reset": state.merge(initial_function(),true)

static func positions(height: float, sides: int) -> PackedVector3Array:
	var points := PackedVector3Array()
	for y in [0.0, height]:
		for i in sides:
			var angle := float(i)/sides*TAU
			points.append(Vector3(RADIUS*cos(angle),y,RADIUS*sin(angle)))
	return points

static func indices(sides: int) -> PackedInt32Array:
	var result := PackedInt32Array()
	for i in sides:
		var next := (i+1)%sides
		result.append_array(PackedInt32Array([i,next,i+sides,next,next+sides,i+sides]))
	# The browser shows the side quads and top polygon. Keep its open bottom.
	# Top triangulation uses an existing rim point: exactly 2*n positions remain.
	for i in range(1,sides-1): result.append_array(PackedInt32Array([sides,sides+i,sides+i+1]))
	return result

static func mesh(sides: int) -> ArrayMesh:
	var points := positions(1.0,sides)
	var faces := indices(sides)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for t in range(0,faces.size(),3):
		var a := points[faces[t]]
		var b := points[faces[t+1]]
		var c := points[faces[t+2]]
		var normal := (c-a).cross(b-a).normalized()
		surface.set_normal(normal)
		for point in [a,b,c]: surface.add_vertex(point)
	# Renderer duplicates corners for flat normals; generated position data is 2*n.
	return surface.commit()

static func edge_pairs(sides: int) -> PackedVector3Array:
	var points := positions(1.0,sides)
	var pairs := PackedVector3Array()
	for i in sides:
		var next := (i+1)%sides
		for edge in [[i,next],[i+sides,next+sides],[i,i+sides]]:
			pairs.append(points[edge[0]])
			pairs.append(points[edge[1]])
	return pairs
