extends RefCounted
## Eight horizontal repeats of the twelve-hook lift, one recorded pick per row.
## All yarns share one mesh. Opening the cloth is a GPU transform of this mesh.
const THREADS := 96
const PITCH := .025
const START_Z := -1.30
const BASE_Y := .98
const CRIMP := .0040
const RADIUS := .0116
const HALF_HEIGHT := .0032
const SIDES := 6
const SHADER = preload("res://commons/artifacts/jacquard_weaver/woven_yarn.gdshader")

static func point(records: Array, col: int, row: int, warp: bool, folded := false) -> Vector3:
	var sign_y := 1.0 if int(records[row].bits[col%12])==1 else -1.0
	if not warp: sign_y=-sign_y
	if not folded:
		return Vector3((col-(THREADS-1)*.5)*PITCH,BASE_Y+sign_y*CRIMP,START_Z+row*PITCH)
	var d := (records.size()-1-row)*.010
	var p := Vector3((col-(THREADS-1)*.5)*.014,1.20,.27+d)
	var normal := Vector3.UP
	if d>.53: p=Vector3(p.x,1.20-(d-.53),.80); normal=Vector3.BACK
	return p+normal*sign_y*.0025

static func opened(p: Vector3, amount: float, count: int) -> Vector3:
	var a := clampf(amount,0.0,1.0)
	var step := a*1.8/maxf(count-1,1)
	return Vector3(p.x*lerpf(1.0,1.15,a),BASE_Y+(p.y-BASE_Y)*lerpf(1.0,4.0,a)+(p.z-START_Z)/PITCH*step,p.z)

static func build(records: Array, folded := false) -> Dictionary:
	var mesh := ArrayMesh.new()
	var result := {"mesh":mesh,"warps":[],"weft":PackedVector3Array()}
	if records.is_empty():return result
	var vertices:=PackedVector3Array();var normals:=PackedVector3Array();var colours:=PackedColorArray()
	var uv:=PackedVector2Array();var offsets:=PackedVector2Array();var indices:=PackedInt32Array()
	var radius := .0065 if folded else RADIUS
	var height := .0020 if folded else HALF_HEIGHT
	for col in range(THREADS):
		var path:=PackedVector3Array()
		for row in range(records.size()):path.append(point(records,col,row,true,folded))
		if path.size()==1:path.append(path[0]+Vector3(0,0,PITCH*.75))
		result.warps.append(path)
		_append_yarn(path,Color(str(records[0].warp_colors[col%12])),radius,height,folded,vertices,normals,colours,uv,offsets,indices)
	var run:=PackedVector3Array();var previous:=""
	for row in range(records.size()):
		var hex:=str(records[row].weft_color)
		if not run.is_empty() and hex!=previous:
			_append_yarn(run,Color(previous),radius,height,folded,vertices,normals,colours,uv,offsets,indices);run.clear()
		previous=hex
		var path:=PackedVector3Array();var first:=0 if row%2==0 else THREADS-1
		var start:=point(records,first,row,false,folded);start.x+=-radius if first==0 else radius;path.append(start)
		for i in range(THREADS):path.append(point(records,i if row%2==0 else THREADS-1-i,row,false,folded))
		var end:=path[-1];end.x+=radius if first==0 else -radius;path.append(end)
		run.append_array(path);result.weft.append_array(path)
	if not run.is_empty():_append_yarn(run,Color(previous),radius,height,folded,vertices,normals,colours,uv,offsets,indices)
	var arrays:Array=[];arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_NORMAL]=normals;arrays[Mesh.ARRAY_COLOR]=colours
	arrays[Mesh.ARRAY_TEX_UV]=uv;arrays[Mesh.ARRAY_TEX_UV2]=offsets;arrays[Mesh.ARRAY_INDEX]=indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return result

static func _append_yarn(path: PackedVector3Array, colour: Color, radius: float, height: float, folded: bool, vertices: PackedVector3Array, normals: PackedVector3Array, colours: PackedColorArray, uv: PackedVector2Array, offsets: PackedVector2Array, indices: PackedInt32Array) -> void:
	var base:=vertices.size();var travel:=0.0
	for i in range(path.size()):
		if i>0:travel+=path[i].distance_to(path[i-1])
		var tangent:Vector3=(path[mini(i+1,path.size()-1)]-path[maxi(0,i-1)]).normalized()
		if tangent.length_squared()<.001:tangent=Vector3.RIGHT
		var up:=Vector3.BACK if folded and path[i].z>.79 else Vector3.UP
		var u:=tangent.cross(up).normalized()
		if u.length_squared()<.001:u=Vector3.RIGHT
		var v:=u.cross(tangent).normalized()
		for side in range(SIDES):
			var angle:=TAU*side/SIDES
			var offset:=u*cos(angle)*radius+v*sin(angle)*height
			vertices.append(path[i]+offset);offsets.append(Vector2(offset.x,offset.z))
			normals.append((u*cos(angle)/radius+v*sin(angle)/height).normalized())
			colours.append(colour.srgb_to_linear());uv.append(Vector2(travel, float(side)/SIDES))
	for i in range(path.size()-1):
		for side in range(SIDES):
			var a:=base+i*SIDES+side;var b:=base+i*SIDES+(side+1)%SIDES
			indices.append_array([a,b,a+SIDES,b,b+SIDES,a+SIDES])

static func material() -> ShaderMaterial:
	var mat:=ShaderMaterial.new();mat.shader=SHADER;return mat
