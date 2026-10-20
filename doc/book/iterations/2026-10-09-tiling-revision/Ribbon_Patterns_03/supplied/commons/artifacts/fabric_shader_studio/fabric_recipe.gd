extends RefCounted
const SHADER = preload("res://commons/artifacts/fabric_shader_studio/fabric.gdshader")
const PALETTE = [Color("e7dfce"),Color("b32719"),Color("263f80"),Color("c09933")]
static func initial() -> Dictionary:
	return {"version":1,"cells":[[1,0,0,2],[1,0,0,0],[1,1,3,0],[0,0,0,0]],"repeats":4,"offset":0.0,"mask":false,"finish":0,"displace":false,"uv_view":false}
static func valid(r:Dictionary) -> bool:
	if r.get("version")!=1 or not r.get("cells") is Array or r.cells.size()!=4:return false
	for row in r.cells:
		if not row is Array or row.size()!=4:return false
		for v in row:
			if not (v is int or v is float) or v!=int(v) or v<0 or v>3:return false
	return (r.get("repeats")==4 or r.get("repeats")==8) and (r.get("offset")==0 or r.get("offset")==0.125) and (r.get("finish")==0 or r.get("finish")==1) and r.get("mask") is bool and r.get("displace") is bool and r.get("uv_view") is bool
static func material(r:Dictionary) -> ShaderMaterial:
	if not valid(r):return null
	var image=Image.create(4,4,false,Image.FORMAT_RGBA8)
	for y in 4:
		for x in 4:image.set_pixel(x,y,PALETTE[int(r.cells[y][x])])
	var mat=ShaderMaterial.new();mat.shader=SHADER
	mat.set_shader_parameter("motif",ImageTexture.create_from_image(image))
	mat.set_shader_parameter("repeats",float(r.repeats));mat.set_shader_parameter("phase",float(r.offset))
	mat.set_shader_parameter("cut_out",r.mask);mat.set_shader_parameter("metal_finish",r.finish==1)
	mat.set_shader_parameter("amplitude",0.04 if r.displace else 0.0);mat.set_shader_parameter("uv_view",r.uv_view)
	return mat

static func normalize(r:Dictionary) -> Dictionary:
	if not valid(r):return {}
	var result=initial()
	for y in 4:
		for x in 4:result.cells[y][x]=int(r.cells[y][x])
	for key in ["repeats","finish"]:result[key]=int(r[key])
	result.offset=float(r.offset)
	for key in ["mask","displace","uv_view"]:result[key]=r[key]
	return result
