extends Node
## Opt-in look study. Changes scene-owned lighting and architecture finishes only.
## No layout writes, geometry, collision, teaching colours or source materials change.
const NAMES := ["baseline", "light", "finish"]
var game: Node3D
var selected := "baseline"
var env_before: Dictionary = {}
var sun_before: Dictionary = {}
var bindings: Array[Dictionary] = []
var bound_ids: Dictionary = {}
var finishes: Dictionary = {}
var fill: DirectionalLight3D
var grain: Texture2D
var normal: Texture2D

func configure(owner_game: Node3D, initial := "finish") -> void:
	game = owner_game
	for key in ["ambient_light_source","ambient_light_sky_contribution","ambient_light_color","ambient_light_energy","tonemap_mode","tonemap_exposure","fog_depth_begin","fog_depth_end","fog_depth_curve","fog_density"]:
		env_before[key] = game.atmosphere.environment.get(key)
	var sun: DirectionalLight3D = game.atmosphere.get_node("WarmSun")
	for key in ["rotation_degrees","light_color","light_energy","directional_shadow_max_distance"]:
		sun_before[key] = sun.get(key)
	fill = DirectionalLight3D.new()
	fill.name = "VisualStudyBounceApproximation"
	fill.rotation_degrees = Vector3(-32,145,0)
	fill.light_color = Color("d9e1f0")
	fill.light_energy = 0.22
	fill.shadow_enabled = false
	fill.light_cull_mask = sun.light_cull_mask
	fill.visible = false
	game.add_child(fill)
	_make_textures()
	for key in ["concrete","steel","pink","pipe_material","timber"]:
		var source: StandardMaterial3D = game.building.get(key)
		var finish: StandardMaterial3D = source.duplicate()
		finish.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		finish.uv1_triplanar = true
		finish.uv1_triplanar_sharpness = 4.0
		finish.uv1_scale = Vector3.ONE * (0.9 if key == "concrete" else 2.0)
		finish.albedo_texture = grain
		finish.normal_enabled = true
		finish.normal_texture = normal
		finish.normal_scale = 0.24 if key == "concrete" else 0.09
		finish.roughness = {"concrete":0.86,"steel":0.39,"pink":0.42,"pipe_material":0.45,"timber":0.78}[key]
		finishes[source] = finish
	_collect(game.building)
	game.building.content.floor_changed.connect(func(index):
		if game.building.content.roots.has(index): _collect(game.building.content.roots[index])
		fill.light_cull_mask = game.atmosphere.get_node("WarmSun").light_cull_mask
		_apply_bindings())
	set_profile(initial)

func _make_textures() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = 270126
	noise.frequency = 0.07
	noise.fractal_octaves = 3
	var height := noise.get_seamless_image(128,128)
	var colour := Image.create(128,128,false,Image.FORMAT_RGB8)
	for y in 128:
		for x in 128:
			var v := 0.94 + height.get_pixel(x,y).r * 0.06
			colour.set_pixel(x,y,Color(v,v,v))
	colour.generate_mipmaps()
	grain = ImageTexture.create_from_image(colour)
	height.bump_map_to_normal_map(0.55)
	height.generate_mipmaps()
	normal = ImageTexture.create_from_image(height)

func _collect(node: Node) -> void:
	if node is GeometryInstance3D and "material_override" in node:
		var source: Material = node.material_override
		if finishes.has(source) and not bound_ids.has(node.get_instance_id()):
			bound_ids[node.get_instance_id()] = true
			bindings.append({"node":node,"source":source})
	for child in node.get_children(): _collect(child)

func _apply_bindings() -> void:
	for binding in bindings:
		if is_instance_valid(binding.node):
			binding.node.material_override = finishes[binding.source] if selected == "finish" else binding.source

func set_profile(value: String) -> void:
	assert(value in NAMES,"Unknown Void visual profile")
	selected = value
	var env: Environment = game.atmosphere.environment
	var sun: DirectionalLight3D = game.atmosphere.get_node("WarmSun")
	for key in env_before: env.set(key,env_before[key])
	for key in sun_before: sun.set(key,sun_before[key])
	fill.visible = value != "baseline"
	if value != "baseline":
		# An art-directed indirect-light approximation shared by Mobile and Forward+.
		# It is not SDFGI and it creates no extra shadow map.
		sun.rotation_degrees = Vector3(-24,-40,0)
		sun.light_color = Color("ffe6dc")
		sun.light_energy = 0.72
		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		env.ambient_light_sky_contribution = 0.65
		env.ambient_light_energy = 0.34
		env.tonemap_mode = Environment.TONE_MAPPER_AGX
		env.tonemap_exposure = 1.05
		env.fog_depth_begin = 16.0
		env.fog_depth_end = 60.0
		env.fog_depth_curve = 1.35
		env.fog_density = 0.65
	_apply_bindings()
	set_meta("look_profile",selected)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F8:
		set_profile(NAMES[(NAMES.find(selected)+1)%NAMES.size()])
		game._notice("VISUAL STUDY / "+selected.to_upper()+"\nF8: current / light / finish")
		get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	# Duplicates are scene-local; no imported materials are mutated.
	_apply_bindings_to_baseline()
	if is_instance_valid(fill): fill.queue_free()

func _apply_bindings_to_baseline() -> void:
	for binding in bindings:
		if is_instance_valid(binding.node): binding.node.material_override = binding.source
