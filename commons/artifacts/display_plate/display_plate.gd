extends Node3D
class_name DisplayPlate
## THE DISPLAY PLATE (Palle, 2026-10-31: "every pattern that can be displayed on a plate structure ... the scaffolded
## playground should be a structure of displays"). One flat plate that fits a slot like the walkable surfaces do -
## its footprint, a flat rim all round as its frame - and carries a CONTENT: a shader with its parameters (the Book
## of Shaders chapters), a wallpaper pattern (a 4 x 4 domain tiled by a symmetry group, the tiling sequence's
## shader), or a plain colour. On the floor it is WALKABLE GLASS: a thin body you stand on, the content under your
## feet. On a wall it stands up, its face into the room; free-standing it brings two posts. A place's activity
## (place_builder) or any recipe can put one anywhere with a config; a gallery is a row of them.

@export var slot_size := Vector2(3, 3)
@export_enum("floor", "wall") var mount := "floor"
@export var rim_width := 0.25
@export var thickness := 0.04
@export_enum("shader", "wallpaper", "colour") var content := "colour"
@export_file("*.gdshader") var shader_path := ""
@export var params: Dictionary = {}       ## shader uniforms, by name
@export var colour := Color("3a4a58")
@export var wallpaper_group := 0          ## 0..16, the 17 groups of wallpaper_tile.gdshader
@export var repeats := 4.0                ## how many domain tiles across the plate
@export var seed_value := 1               ## the painted 4 x 4 domain, when none is given
@export var stand := false                ## a wall plate on its own posts
@export var title := ""
@export var rim_colour := Color("1d2226")

const WALLPAPER := "res://commons/resourses/shaders/wallpaper_tile.gdshader"
var body: StaticBody3D
var face: MeshInstance3D
var _built := false

func _ready() -> void:
	apply_grid_config(_meta_config())
	_build()

func _meta_config() -> Dictionary:
	var cfg := {}
	for m in get_meta_list():
		if str(m).begins_with("config_"):cfg[str(m).trim_prefix("config_")] = get_meta(m)
	return cfg

func apply_grid_config(config: Dictionary) -> void:
	if config.has("slot_size") and config.slot_size is Array and (config.slot_size as Array).size() == 2:slot_size = Vector2(float(config.slot_size[0]), float(config.slot_size[1]))
	if config.has("mount"):mount = "wall" if str(config.mount) == "wall" else "floor"
	if config.has("rim_width"):rim_width = maxf(float(config.rim_width), 0.0)
	if config.has("thickness"):thickness = clampf(float(config.thickness), .01, .3)
	if config.has("content"):content = str(config.content) if str(config.content) in ["shader", "wallpaper", "colour"] else content
	if config.has("shader"):shader_path = str(config.shader)
	if config.has("params") and config.params is Dictionary:params = (config.params as Dictionary).duplicate()
	if config.has("colour"):colour = Color.html(str(config.colour)) if Color.html_is_valid(str(config.colour)) else colour
	if config.has("wallpaper_group"):wallpaper_group = clampi(int(config.wallpaper_group), 0, 16)
	if config.has("repeats"):repeats = maxf(float(config.repeats), 1.0)
	if config.has("seed"):seed_value = int(config.seed)
	if config.has("stand"):stand = bool(config.stand) if config.stand is bool else str(config.stand) in ["true", "1"]
	if config.has("title"):title = str(config.title)
	if _built:_build()

## The plate, built flat (face up) in the node's XZ and stood up for a wall.
func _build() -> void:
	for c in get_children():c.free()
	var holder := Node3D.new();holder.name = "Plate";add_child(holder)
	var inner := Vector2(slot_size.x - 2.0 * rim_width, slot_size.y - 2.0 * rim_width).max(Vector2(.2, .2))
	# the slab: a dark box the whole footprint, the thickness; the body you stand on
	body = StaticBody3D.new();body.name = "Glass";body.collision_layer = 1;body.collision_mask = 0;holder.add_child(body)
	var shape := CollisionShape3D.new();var box := BoxShape3D.new();box.size = Vector3(slot_size.x, thickness, slot_size.y);shape.shape = box;shape.position.y = thickness / 2.0;body.add_child(shape)
	var slab := MeshInstance3D.new();slab.name = "Slab";var sm := BoxMesh.new();sm.size = Vector3(slot_size.x, thickness, slot_size.y);slab.mesh = sm;slab.position.y = thickness / 2.0
	var rim_mat := StandardMaterial3D.new();rim_mat.albedo_color = rim_colour;rim_mat.roughness = .6;slab.material_override = rim_mat;body.add_child(slab)
	# the face: the content, a hair above the slab inside the rim
	face = MeshInstance3D.new();face.name = "Face";var qm := QuadMesh.new();qm.size = inner;face.mesh = qm
	face.rotation.x = -PI / 2.0;face.position.y = thickness + .002;face.material_override = _material();body.add_child(face)
	if title != "":
		var label := Label3D.new();label.text = title;label.font_size = 26;label.pixel_size = .004;label.modulate = Color("dfe7e3")
		label.rotation.x = -PI / 2.0;label.position = Vector3(0, thickness + .003, slot_size.y / 2.0 - rim_width / 2.0);body.add_child(label)
		if mount == "wall":label.rotation = Vector3(-PI / 2.0, 0, PI);label.position.z = -slot_size.y / 2.0 + rim_width / 2.0   # stood up, the top rim is the far edge: turned to read from the room
	if mount == "wall":
		# stood up from its base line: local z becomes up, the face looks along -Z into the room
		holder.transform = Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3(0, slot_size.y / 2.0, 0))
		if stand:
			for sx in [-1, 1]:
				var post := MeshInstance3D.new();var cm := CylinderMesh.new();cm.top_radius = .03;cm.bottom_radius = .03;cm.height = slot_size.y + .1;post.mesh = cm
				post.material_override = rim_mat;post.position = Vector3(sx * (slot_size.x / 2.0 - .1), (slot_size.y + .1) / 2.0, thickness + .03);add_child(post)
				var foot := MeshInstance3D.new();var fm := BoxMesh.new();fm.size = Vector3(.3, .04, .6);foot.mesh = fm;foot.material_override = rim_mat;foot.position = Vector3(sx * (slot_size.x / 2.0 - .1), .02, .15);add_child(foot)
	_built = true

## The content as a material: the named shader with its uniforms, the wallpaper shader over a painted domain, or a colour.
func _material() -> Material:
	if content == "shader" and shader_path != "" and ResourceLoader.exists(shader_path):
		var m := ShaderMaterial.new();m.shader = load(shader_path)
		for k in params:m.set_shader_parameter(str(k), params[k])
		return m
	if content == "wallpaper" and ResourceLoader.exists(WALLPAPER):
		var m := ShaderMaterial.new();m.shader = load(WALLPAPER)
		m.set_shader_parameter("domain_texture", _domain());m.set_shader_parameter("tile_scale", repeats)
		m.set_shader_parameter("wallpaper_group", wallpaper_group);m.set_shader_parameter("grout_width", .02)
		m.set_shader_parameter("grout_color", Vector3(.1, .1, .1));m.set_shader_parameter("grout_softness", .005);m.set_shader_parameter("roughness", .8)
		for k in params:m.set_shader_parameter(str(k), params[k])
		return m
	var s := StandardMaterial3D.new();s.albedo_color = colour;s.roughness = .4;return s

## A painted 4 x 4 domain from the seed: four bright colours and a dark, as a pattern studio would leave it.
func _domain() -> ImageTexture:
	var rng := RandomNumberGenerator.new();rng.seed = seed_value
	var img := Image.create(4, 4, false, Image.FORMAT_RGB8)
	var palette := [Color.from_hsv(rng.randf(), .8, .95), Color.from_hsv(rng.randf(), .8, .9), Color.from_hsv(rng.randf(), .7, 1.0), Color("f3eee5"), Color("23272b")]
	for y in 4:
		for x in 4:img.set_pixel(x, y, palette[rng.randi_range(0, palette.size() - 1)])
	return ImageTexture.create_from_image(img)

## Where the content faces: +Y for a floor plate, -Z for a wall plate (in the node's space).
func facing() -> Vector3:
	return Vector3.FORWARD if mount == "wall" else Vector3.UP
