extends RefCounted
## The same indexed panels unfold on the table and curve around the fitting.
## A deliberately simplified ten-panel suit; not a production sewing draft.
const NAMES := ["FRONT L", "FRONT R", "BACK L", "BACK R", "SLEEVE L", "SLEEVE R", "LEG L FRONT", "LEG L BACK", "LEG R FRONT", "LEG R BACK"]
const U := 16
const V := 12

static func dimensions(i: int) -> Vector2:
	return Vector2(.39,.65) if i<4 else (Vector2(.42,.53) if i<6 else Vector2(.34,.78))

static func flat_point(i: int, u: float, v: float) -> Vector3:
	var size := dimensions(i)
	var taper := lerpf(.86,1.0,v) if i<4 else lerpf(1.0,.74,v)
	# A shallow neckline on the front quarters makes the cut legible.
	var neck := .09*(1.0-v)*maxf(0.0,1.0-u*3.0) if i<2 else 0.0
	return Vector3((u-.5)*size.x*taper,0,(v-.5)*size.y+neck)

static func curved_point(i: int, u: float, v: float) -> Vector3:
	if i<4:
		var start: float = [-PI*.5,0.0,-PI,PI*.5][i]
		var angle: float = float(start)+u*PI*.5
		var radius := lerpf(.09,.255,smoothstep(0.0,.16,v))-.025*sin(v*PI)
		var y := -.025-v*.705
		if i<2: y-=.09*(1.0-v)*maxf(0.0,1.0-u*3.0)
		return Vector3(sin(angle)*radius,y,-cos(angle)*radius*.70)
	if i<6:
		var side := -1.0 if i==4 else 1.0
		var radius := lerpf(.10,.065,v)
		return Vector3(side*(.28+v*.06)+sin(u*TAU)*radius,-.16-v*.53,-cos(u*TAU)*radius)
	var side := -1.0 if i<8 else 1.0
	var angle := u*PI+(0.0 if i%2==0 else PI)
	var radius := lerpf(.13,.085,v)
	return Vector3(side*.135+sin(angle)*radius,-.64-v*.78,-cos(angle)*radius*.92)

static func uv_at(i: int, u: float, v: float) -> Vector2:
	# Non-overlapping regions of the cloth. Retained through folding and wearing.
	var p := table_position(i)+flat_point(i,u,v)
	return Vector2((p.x+2.41)/2.6,(p.z+.975)/1.95)

static func mesh(i: int, fold: float = 1.0) -> ArrayMesh:
	var positions := PackedVector3Array(); var uvs := PackedVector2Array()
	for y in range(V+1):
		for x in range(U+1):
			var u := float(x)/U; var v := float(y)/V
			positions.append(flat_point(i,u,v).lerp(curved_point(i,u,v),fold))
			uvs.append(uv_at(i,u,v))
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for y in range(V):
		for x in range(U):
			var a := y*(U+1)+x; var b := a+U+1
			for k in [a,b,a+1,a+1,b,b+1]:
				st.set_uv(uvs[k]); st.add_vertex(positions[k])
	st.generate_normals(); st.index()
	return st.commit()

static func table_position(i: int) -> Vector3:
	return Vector3(-2.15+(i%5)*.52,1.025,-.55+(i/5)*1.0)
