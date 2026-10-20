extends RefCounted
## A snapshot of committed loom crossings, shared by table, fitting and wardrobe.
const Program = preload("res://commons/artifacts/jacquard_weaver/weave_program.gd")
const Samples = preload("res://commons/artifacts/jacquard_weaver/weave_samples.gd")
const SAVE_PATH := "user://ada_tailor_cloth.json"

static func valid(data: Dictionary) -> bool:
	if data.get("version") != 1 or not data.get("picks") is Array: return false
	if data.picks.size() < 2 or data.picks.size() > 128: return false
	for pick in data.picks:
		if not pick is Dictionary or not pick.get("bits") is Array or pick.bits.size() != 12: return false
		for bit in pick.bits:
			if not (bit is int or bit is float) or (bit != 0 and bit != 1): return false
		if not pick.get("warp_colors") is Array or pick.warp_colors.is_empty() or pick.warp_colors.size() > 96: return false
		for color in pick.warp_colors:
			if not color is String or not Color.html_is_valid(color): return false
		if not pick.get("weft_color") is String or not Color.html_is_valid(pick.weft_color): return false
	return true

static func sample(key: String) -> Dictionary:
	var recipe: Dictionary = Samples.recipe(key)
	if recipe.is_empty(): return {}
	var picks: Array = []
	for row in range(96):
		picks.append({"bits":Program.preset(recipe.rule,row%8),"warp_colors":recipe.warp.duplicate(),"weft_color":recipe.weft[row%recipe.weft.size()]})
	return {"version":1,"name":Samples.title(key),"picks":picks}

static func save_record(data: Dictionary, path: String = SAVE_PATH) -> bool:
	if not valid(data): return false
	var file := FileAccess.open(path,FileAccess.WRITE)
	if not file: return false
	file.store_string(JSON.stringify(data)); file.close()
	return true

static func load_record(path: String = SAVE_PATH) -> Dictionary:
	var file := FileAccess.open(path,FileAccess.READ)
	if not file or file.get_length() > 1048576: return {}
	var data: Variant = JSON.parse_string(file.get_as_text())
	if not data is Dictionary or not valid(data):return {}
	# JSON numbers arrive as floats; restore the loom's discrete record types.
	data.version=1
	for pick in data.picks:
		for i in range(12):pick.bits[i]=int(pick.bits[i])
		for key in ["id","slot"]:
			if pick.has(key):pick[key]=int(pick[key])
	return data

static func image(data: Dictionary) -> Image:
	# This is the surface of the recorded weave, not a cloth simulation.
	var result := Image.create(576,data.picks.size()*6,false,Image.FORMAT_RGB8)
	for row in range(data.picks.size()):
		var pick: Dictionary = data.picks[row]
		for col in range(96):
			var warp := Color(str(pick.warp_colors[col%pick.warp_colors.size()]))
			var weft := Color(str(pick.weft_color))
			var warp_on_top := int(pick.bits[col%12]) == 1
			for py in range(6):
				for px in range(6):
					var top := warp if warp_on_top else weft
					var edge := px if warp_on_top else py
					result.set_pixel(col*6+px,row*6+py,top.darkened(.25 if edge==0 or edge==5 else .0))
	result.generate_mipmaps()
	return result

static func material(data: Dictionary) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(image(data))
	m.roughness = .92; m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return m
