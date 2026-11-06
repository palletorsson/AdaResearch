extends RefCounted
## Shared surface roles and sequence progression. No collision or geometry changes.
const FILE:="res://commons/modular/construction-materials.json"
static var schema:Dictionary={}
static var cached:Dictionary={}
static var grey_textures:Dictionary={}
static var map_phases:Dictionary={}

## Neutralise only the permanent frame; authored exhibits keep their own materials.
static func neutral_frame(node:Node)->void:
	for child in node.find_children("*","",true,false):
		if child is Label3D:
			var c:Color=child.modulate;var g:=c.get_luminance();child.modulate=Color(g,g,g,c.a)
		if not child is MeshInstance3D or not child.material_override is StandardMaterial3D:continue
		var original:StandardMaterial3D=child.material_override
		var key:="frame/"+str(original.get_instance_id())
		if not cached.has(key):
			var mat:StandardMaterial3D=original.duplicate()
			var c:=original.albedo_color;var grey:=c.get_luminance();mat.albedo_color=Color(grey,grey,grey,c.a)
			c=original.emission;grey=c.get_luminance();mat.emission=Color(grey,grey,grey,c.a)
			if original.albedo_texture!=null:mat.albedo_texture=grey_texture(original.albedo_texture)
			cached[key]=mat
		child.material_override=cached[key]

static func data()->Dictionary:
	if schema.is_empty():schema=JSON.parse_string(FileAccess.get_file_as_string(FILE))
	return schema

static func phase_for(node:Node,fallback:="monochrome")->String:
	if map_phases.is_empty():
		var spine:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://commons/void/spine.json"))
		var coloured:=false
		for group in spine.sequences:
			if group.id=="color":coloured=true
			for index in group.floors:map_phases[spine.floors[int(index)].map]="colour" if coloured else "monochrome"
	var parent:=node
	while parent!=null:
		if parent.has_meta("map") and map_phases.has(str(parent.get_meta("map"))):return map_phases[str(parent.get_meta("map"))]
		parent=parent.get_parent()
	return fallback if fallback in ["monochrome","colour"] else "monochrome"

static func kit_role(colour:String,metallic:float)->String:
	if metallic>.5:return "steel"
	var c:=Color(colour)
	if c.r>c.b*1.2 and c.g>c.b*1.15:return "timber"
	if c.b>c.r and c.g>c.r:return "rail"
	if c.r>c.g*1.15:return "foam"
	return "collar"

static func part_role(part:Dictionary)->String:
	if part.get("electrical",false):return "danger"
	var source:String=part.source
	if source=="green-field":return "field"
	if source=="paddle":return "foam"
	if source in ["platform","plank"]:return "timber"
	var name:String=str(part.get("name","")).to_lower()
	if "bearing" in name or "axle" in name or "rotor" in name or "beam" in name or "spindle" in name:return "steel"
	if part.has("tint"):
		var c:=Color(str(part.tint))
		if maxf(c.r,maxf(c.g,c.b))<.3:return "steel"
	return "moving"

static func grey_texture(texture:Texture2D)->Texture2D:
	var key:=texture.get_instance_id()
	if grey_textures.has(key):return grey_textures[key]
	var image:=texture.get_image()
	if image.is_compressed():image.decompress()
	image.convert(Image.FORMAT_RGBA8)
	var bytes:=image.get_data()
	for i in range(0,bytes.size(),4):
		var grey:=int(bytes[i]*.2126+bytes[i+1]*.7152+bytes[i+2]*.0722)
		bytes[i]=grey;bytes[i+1]=grey;bytes[i+2]=grey
	var result:=ImageTexture.create_from_image(Image.create_from_data(image.get_width(),image.get_height(),image.has_mipmaps(),Image.FORMAT_RGBA8,bytes))
	grey_textures[key]=result;return result

static func surface(role:String,phase:String,original:Material=null)->StandardMaterial3D:
	var key:=role+"/"+phase+"/"+str(original.get_instance_id() if original!=null else 0)
	if cached.has(key):return cached[key]
	var spec:Dictionary=data().roles[role]
	var mat:=StandardMaterial3D.new()
	mat.albedo_color=Color(spec.get(phase,spec.monochrome))
	mat.roughness=spec.roughness;mat.metallic=spec.metallic
	if role=="timber" and original is StandardMaterial3D and original.albedo_texture!=null:
		mat.albedo_texture=grey_texture(original.albedo_texture) if phase=="monochrome" else original.albedo_texture
	if spec.shader in ["bands","grid"]:
		var settings:Dictionary=data().shaders[spec.shader]
		var image:=Image.create(32,32,false,Image.FORMAT_RGBA8)
		for y in 32:
			for x in 32:
				var mark:bool=(x+y)%int(settings.period)<int(settings.width) if spec.shader=="bands" else x%int(settings.period)<int(settings.width) or y%int(settings.period)<int(settings.width)
				image.set_pixel(x,y,Color("202020") if mark else Color.WHITE)
		mat.albedo_texture=ImageTexture.create_from_image(image)
		mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
	if float(spec.opacity)<1:
		mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mat.albedo_color.a=spec.opacity;mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	mat.resource_name="Construction / "+phase+" / "+role
	cached[key]=mat;return mat
