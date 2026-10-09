extends Node3D

# @identity
# essence: GPU computes noise per-fragment in parallel — the room sphere and walls run independent shader noise loops animated by a time uniform, cycling color and density in real-time
# desire: to be inside the noise — to stand inside a sphere where the walls are made of animated GPU hash functions and feel surrounded by the mathematics of structured randomness
# critical_parameter: generator (perlin) — which noise basis the fragment shader evaluates; the room is made of the field, so the basis is the architecture
# triggers: toggling animation_enabled freezes the noise field, revealing its spatial structure without temporal motion; space bar toggles it; escape resets to original parameters
# emerges: the two materials (room sphere vs walls) animate out of phase, creating a sense that the space itself is breathing — an undesigned emergent rhythm from two independent cycles
# needs: animation_enabled toggle via spacebar [has]; no VR slider controls [missing]; color cycling and density animation are coupled to time only [has]
# relationships: demonstrates GPU noise as distinct from CPU noise in noiselayers; pairs with shader_arch_gallery; shows what QueerNoiseShader.gdshader produces at room scale
# truth: GPU noise is not one calculation but millions happening simultaneously — the shader room makes visible that what looks like a continuous field is massively parallel computation

## GENERATOR — which basis fills the field. The same axis, the same four values in the same
## order, as perlin_noise, simplex_noise and noise_terrain carry: the noise sequence is built
## on comparing bases, and spelling the comparison a second way would leave nothing to
## compare. What is different here is the scale of the question. On the bench a basis is a
## tabletop of displaced cubes you look down at; in this room it is the walls, the ceiling and
## the floor, so choosing one decides what the space you are standing inside is MADE of.
##
## The default is perlin and not simplex — the opposite of the bench artifacts — because that
## is what this shader has always computed: hash2 returns a gradient per lattice corner and
## noise2d dots it with the offset, which is Perlin's construction with a sine hash in place
## of a permutation table.
##
##   simplex    the same gradient idea on a triangular lattice, three corners with a radial
##              falloff. No preferred direction survives; the busiest of the four
##   perlin     the shipped field. Smooth swells with the square lattice faintly latent
##   value      a random height per corner rather than a gradient, so cells become plateaus
##              and the grid stops being latent and becomes the picture
##   cellular   Worley. Not a smooth field at all — space partitioned by feature points, and
##              the only one of the four with edges in it
@export_enum("simplex", "perlin", "value", "cellular") var generator: String = "perlin"
const GENERATORS: PackedStringArray = ["simplex", "perlin", "value", "cellular"]

## CAPTURE BENCH ONLY, and deliberately not an axis. Every visible parameter of this room is
## driven off a clock in _process, so a still is taken at whatever moment the shutter happened
## to fall. `frozen` leaves the .tscn's own authored uniforms in place and never advances
## them, which makes four basis frames comparable instead of four different instants. It is a
## String enum rather than a bool because the sweep sets exports from strings before _ready
## and a typed bool silently rejects "true". No placement passes it.
@export_enum("live", "frozen") var animation: String = "live"

# ── THE PANEL (stand:panel) — N5, 12 September 2026 ─────────────────────────
#
# WHICH LAYER OF A SURFACE ARE YOU ATTENDING TO? This room is lined with a sum
# of six spatial scales and, until now, a visitor could not take one away. The
# shader's loop bound is a uniform since this pass, and `show_term` opens the
# accumulation on its own; both default to the shipped picture.
#
#   stand:none   SHIPPED. The immersive interior, six layers, full mix.
#   stand:panel  A reading surface at the entrance: four patches of ONE field at
#                1, 2, 4 and 6 layers, at one seed, one set of coordinates, one
#                contrast, one colour and one time — differing only in how many
#                terms are summed, with the weights each term carries declared
#                on the plate. LAYERS sets the ROOM's walls (scoped to this hall
#                and no other), BASIS changes the generator as its own separate
#                comparison, FREEZE stops every animated term the comparison
#                uses: the shader's clock, the colour cycling and the density.
#
# AND EVERY INSTANCE GETS ITS OWN MATERIALS. The room's walls shared one
# ShaderMaterial resource with every other placement of this scene, so a uniform
# set in one hall was set in all of them — the same class of fault as the group
# broadcast found in Noise_Voxel a room earlier.
const PANEL_LAYERS: Array = [1, 2, 4, 6]
const PANEL_WEIGHTS: Array = [0.5, 0.75, 0.9375, 0.984375]
const PANEL_PATCH: float = 0.42
const PANEL_GAP: float = 0.06
const PANEL_GAIN: float = 2.0     # the same display gain on all four patches, declared on the plate

@export_enum("none", "panel") var stand: String = "none"
@export var layers: int = 6

var _panel_root: Node3D = null
var _patches: Array = []
var _panel_readout: Label3D = null
var _last_touched: String = "nothing yet"
var _last_broadcast: Dictionary = {}

# Animation controls
@export var animation_enabled: bool = true
@export var animation_speed: float = 1.0
@export var time_scale_variation: float = 0.5
@export var color_cycling: bool = true
@export var color_cycle_speed: float = 0.3
@export var cloud_density_animation: bool = true
@export var density_variation: float = 0.5

# Shader material references
var room_material: ShaderMaterial
var wall_material: ShaderMaterial

# Animation state
var base_time: float = 0.0
var color_cycle_time: float = 0.0
var density_cycle_time: float = 0.0

# Original shader parameters (for restoration)
var original_room_params: Dictionary = {}
var original_wall_params: Dictionary = {}

func _ready() -> void:
	"""Initialize the noise room animation system"""
	_setup_materials()
	_store_original_parameters()
	_apply_generator()
	if animation == "frozen":
		animation_enabled = false
	add_to_group("noise_rooms")
	if stand == "panel":
		_strip_enclosure_for_panel()
		_build_sample_panel()
	_setup_ui()


## Writes the basis into both materials. At the default this writes 1 into a uniform whose
## own default is already 1, so the room renders the field it has always rendered — the
## perlin branch in the shader is the shipped noise2d body, unmoved.
func _apply_generator() -> void:
	var index: int = GENERATORS.find(generator)
	if index < 0:
		index = GENERATORS.find("perlin")
	if room_material:
		room_material.set_shader_parameter("noise_basis", index)
	if wall_material:
		wall_material.set_shader_parameter("noise_basis", index)

func _setup_materials() -> void:
	"""Find and setup shader materials"""
	# Find the main room sphere material
	var room_sphere = get_node("RoomContainer/MainRoomBody/RoomShape")
	if room_sphere and room_sphere.material_override:
		room_material = room_sphere.material_override as ShaderMaterial
		# ONE INSTANCE, ONE MATERIAL. The scene's ShaderMaterial is a shared resource:
		# every placement of this room pointed at the same one, so a uniform set in one
		# hall was set in all of them. Duplicating changes no pixel and stops the leak.
		if room_material != null and not room_material.resource_local_to_scene:
			room_material = room_material.duplicate() as ShaderMaterial
			room_material.resource_local_to_scene = true
			room_sphere.material_override = room_material

	# Find the wall material (all walls use the same material)
	var front_wall = get_node("WallsContainer/FrontWall")
	if front_wall and front_wall.material_override:
		wall_material = front_wall.material_override as ShaderMaterial
		if wall_material != null and not wall_material.resource_local_to_scene:
			wall_material = wall_material.duplicate() as ShaderMaterial
			wall_material.resource_local_to_scene = true
			for w in get_node("WallsContainer").get_children():
				if w is GeometryInstance3D and (w as GeometryInstance3D).material_override != null:
					(w as GeometryInstance3D).material_override = wall_material
	
	print("Noise Room: Materials found - Room: ", room_material != null, ", Wall: ", wall_material != null)

func _store_original_parameters() -> void:
	"""Store original shader parameters for restoration"""
	if room_material:
		original_room_params = {
			"time_scale": room_material.get_shader_parameter("time_scale"),
			"cloud_density": room_material.get_shader_parameter("cloud_density"),
			"pink_intensity": room_material.get_shader_parameter("pink_intensity"),
			"base_pink": room_material.get_shader_parameter("base_pink"),
			"deep_pink": room_material.get_shader_parameter("deep_pink")
		}
	
	if wall_material:
		original_wall_params = {
			"time_scale": wall_material.get_shader_parameter("time_scale"),
			"cloud_density": wall_material.get_shader_parameter("cloud_density"),
			"pink_intensity": wall_material.get_shader_parameter("pink_intensity"),
			"base_pink": wall_material.get_shader_parameter("base_pink"),
			"deep_pink": wall_material.get_shader_parameter("deep_pink")
		}

func _setup_ui() -> void:
	"""Create UI controls for animation parameters"""
	# This could be expanded to create runtime UI controls
	# For now, we'll use the exported variables in the editor
	pass

func _process(delta: float) -> void:
	"""Main animation loop"""
	if not animation_enabled:
		return
	
	base_time += delta * animation_speed
	color_cycle_time += delta * color_cycle_speed
	density_cycle_time += delta * 0.4
	
	_update_room_animation()
	_update_wall_animation()

func _update_room_animation() -> void:
	"""Update the main room sphere animation"""
	if not room_material:
		return
	
	# Update time parameter
	room_material.set_shader_parameter("time", base_time)
	
	# Animate time scale with variation
	var time_scale = original_room_params.get("time_scale", 0.2)
	time_scale += sin(base_time * 0.3) * time_scale_variation * 0.1
	room_material.set_shader_parameter("time_scale", time_scale)
	
	# Animate cloud density
	if cloud_density_animation:
		var density = original_room_params.get("cloud_density", 1.0)
		density += sin(density_cycle_time) * density_variation
		room_material.set_shader_parameter("cloud_density", density)
	
	# Animate colors
	if color_cycling:
		_animate_room_colors()

func _update_wall_animation() -> void:
	"""Update the wall animation with different timing"""
	if not wall_material:
		return
	
	# Update time parameter with different speed
	var wall_time = base_time * 0.7
	wall_material.set_shader_parameter("time", wall_time)
	
	# Animate time scale with different variation
	var time_scale = original_wall_params.get("time_scale", 0.427)
	time_scale += cos(base_time * 0.2) * time_scale_variation * 0.15
	wall_material.set_shader_parameter("time_scale", time_scale)
	
	# Animate cloud density with different pattern
	if cloud_density_animation:
		var density = original_wall_params.get("cloud_density", 1.499)
		density += cos(density_cycle_time * 1.3) * density_variation * 0.3
		wall_material.set_shader_parameter("cloud_density", density)
	
	# Animate colors with different cycle
	if color_cycling:
		_animate_wall_colors()

func _animate_room_colors() -> void:
	"""Animate room colors with cycling effects"""
	if not room_material:
		return
	
	var base_pink = original_room_params.get("base_pink", Color(1, 0.6, 0.8, 1))
	var deep_pink = original_room_params.get("deep_pink", Color(0.8, 0.2, 0.6, 1))
	
	# Create color cycling
	var cycle_r = sin(color_cycle_time) * 0.2
	var cycle_g = cos(color_cycle_time * 0.8) * 0.15
	var cycle_b = sin(color_cycle_time * 1.2) * 0.1
	
	var animated_base = Color(
		clamp(base_pink.r + cycle_r, 0.0, 1.0),
		clamp(base_pink.g + cycle_g, 0.0, 1.0),
		clamp(base_pink.b + cycle_b, 0.0, 1.0),
		base_pink.a
	)
	
	var animated_deep = Color(
		clamp(deep_pink.r + cycle_r * 0.5, 0.0, 1.0),
		clamp(deep_pink.g + cycle_g * 0.7, 0.0, 1.0),
		clamp(deep_pink.b + cycle_b * 0.3, 0.0, 1.0),
		deep_pink.a
	)
	
	room_material.set_shader_parameter("base_pink", animated_base)
	room_material.set_shader_parameter("deep_pink", animated_deep)
	
	# Animate pink intensity
	var intensity = original_room_params.get("pink_intensity", 0.8)
	intensity += sin(color_cycle_time * 0.5) * 0.2
	room_material.set_shader_parameter("pink_intensity", clamp(intensity, 0.0, 2.0))

func _animate_wall_colors() -> void:
	"""Animate wall colors with different cycling effects"""
	if not wall_material:
		return
	
	var base_pink = original_wall_params.get("base_pink", Color(1, 0.6, 0.8, 1))
	var deep_pink = original_wall_params.get("deep_pink", Color(1, 1, 1, 1))
	
	# Create different color cycling for walls
	var cycle_r = cos(color_cycle_time * 0.6) * 0.15
	var cycle_g = sin(color_cycle_time * 1.1) * 0.2
	var cycle_b = cos(color_cycle_time * 0.9) * 0.25
	
	var animated_base = Color(
		clamp(base_pink.r + cycle_r, 0.0, 1.0),
		clamp(base_pink.g + cycle_g, 0.0, 1.0),
		clamp(base_pink.b + cycle_b, 0.0, 1.0),
		base_pink.a
	)
	
	var animated_deep = Color(
		clamp(deep_pink.r + cycle_r * 0.3, 0.0, 1.0),
		clamp(deep_pink.g + cycle_g * 0.4, 0.0, 1.0),
		clamp(deep_pink.b + cycle_b * 0.2, 0.0, 1.0),
		deep_pink.a
	)
	
	wall_material.set_shader_parameter("base_pink", animated_base)
	wall_material.set_shader_parameter("deep_pink", animated_deep)
	
	# Animate pink intensity with different pattern
	var intensity = original_wall_params.get("pink_intensity", 0.8)
	intensity += cos(color_cycle_time * 0.7) * 0.15
	wall_material.set_shader_parameter("pink_intensity", clamp(intensity, 0.0, 2.0))

func _input(event: InputEvent) -> void:
	"""Handle input for animation controls"""
	if event.is_action_pressed("ui_accept"):  # Space key
		animation_enabled = !animation_enabled
		print("Noise Room Animation: ", "Enabled" if animation_enabled else "Disabled")
	
	elif event.is_action_pressed("ui_cancel"):  # Escape key
		_reset_to_original_parameters()
		print("Noise Room: Reset to original parameters")

func _reset_to_original_parameters() -> void:
	"""Reset shaders to their original parameters"""
	if room_material and not original_room_params.is_empty():
		for param in original_room_params:
			room_material.set_shader_parameter(param, original_room_params[param])
	
	if wall_material and not original_wall_params.is_empty():
		for param in original_wall_params:
			wall_material.set_shader_parameter(param, original_wall_params[param])
	
	base_time = 0.0
	color_cycle_time = 0.0
	density_cycle_time = 0.0

func set_animation_speed(speed: float) -> void:
	"""Set the animation speed"""
	animation_speed = clamp(speed, 0.0, 5.0)

func set_color_cycling(enabled: bool) -> void:
	"""Enable or disable color cycling"""
	color_cycling = enabled

func set_cloud_density_animation(enabled: bool) -> void:
	"""Enable or disable cloud density animation"""
	cloud_density_animation = enabled

func get_animation_info() -> Dictionary:
	"""Get current animation state information"""
	return {
		"animation_enabled": animation_enabled,
		"animation_speed": animation_speed,
		"base_time": base_time,
		"color_cycling": color_cycling,
		"cloud_density_animation": cloud_density_animation,
		"room_material_active": room_material != null,
		"wall_material_active": wall_material != null
	}

## Gated on the key, on the word being one this file knows, and on it differing from the word
## already held — so a map that says nothing about the generator (which is all five existing
## placements) gets no call at all. Nothing is torn down here in any case: the basis is a
## single int uniform, so switching it repaints the field without rebuilding the room.
func apply_grid_config(config: Dictionary) -> void:
	if config.has("stand"):
		var sv: String = str(config["stand"]).strip_edges().to_lower()
		stand = "panel" if sv in ["panel", "samples", "entrance", "compare"] else "none"
	if config.has("layers"):
		set_layers(int(config["layers"]))
	if not config.has("generator"):
		return
	var g: String = str(config["generator"]).strip_edges().to_lower()
	if not GENERATORS.has(g) or g == generator:
		return
	generator = g
	_apply_generator()

# ═════════════════════════════════════════════════════════════════════════════
# THE SAMPLE PANEL — stand:panel. Nothing below runs at stand:none.
# ═════════════════════════════════════════════════════════════════════════════

## How many terms the walls sum. The shader's loop bound; 6 is the shipped room.
func set_layers(n: int) -> void:
	layers = clampi(n, 1, 6)
	if room_material:
		room_material.set_shader_parameter("layers", layers)
	if wall_material:
		wall_material.set_shader_parameter("layers", layers)


## Every animated term the comparison uses, stopped together: the shader's own
## clock, the colour cycling and the density breathing. Astra's card asks for a
## freeze that covers all of them rather than one parameter at zero.
func set_frozen(frozen: bool) -> void:
	animation = "frozen" if frozen else "live"
	animation_enabled = not frozen
	color_cycling = not frozen
	cloud_density_animation = not frozen
	for m in [room_material, wall_material]:
		if m != null:
			m.set_shader_parameter("time_scale", 0.0 if frozen else 0.2)
	for p in _patches:
		var mat: ShaderMaterial = (p as Dictionary)["mat"]
		if mat != null:
			mat.set_shader_parameter("time_scale", 0.0 if frozen else 0.2)
	_last_touched = "FREEZE"
	_update_panel_readout()


## A BOARD IS NOT A ROOM (2026-09-12, N5). `stand:panel` used to place the whole
## scene and hang the board on it, so a 27 m enclosure stood invisibly around the
## entrance — its walls outside the hall's own walls, its ceiling above the hall's
## ceiling — and the museum's reach repair had a body far larger than the thing a
## visitor can see. The materials are already held by _setup_materials, so the
## enclosure can leave the tree: the staged body is the board and nothing else.
## Removed rather than hidden, because an extent is measured from the tree.
func _strip_enclosure_for_panel() -> void:
	for n in ["RoomContainer", "WallsContainer", "LightingContainer", "Camera3D"]:
		var node: Node = get_node_or_null(n)
		if node != null:
			remove_child(node)
			node.queue_free()

func is_frozen() -> bool:
	return animation == "frozen"


## Four patches of one field, differing only in how many terms are summed.
func _build_sample_panel() -> void:
	var HangarKit := load("res://commons/artifacts/_hangar/hangar_kit.gd")
	var shader: Shader = wall_material.shader if wall_material != null else null
	if shader == null and room_material != null:
		shader = room_material.shader
	_panel_root = Node3D.new()
	_panel_root.name = "SamplePanel"
	add_child(_panel_root)
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.10, 0.105, 0.12)
	dark.roughness = 0.85
	var frame := StandardMaterial3D.new()
	frame.albedo_color = Color(0.52, 0.50, 0.48)
	frame.roughness = 0.8

	var width: float = PANEL_LAYERS.size() * PANEL_PATCH + (PANEL_LAYERS.size() - 1) * PANEL_GAP
	var board: MeshInstance3D = HangarKit.box(Vector3(0, 1.30, 0.0), Vector3(width + 0.16, PANEL_PATCH + 0.44, 0.06), frame)
	board.name = "Board"
	_panel_root.add_child(board)
	var head: MeshInstance3D = HangarKit.stencil("ONE FIELD · ONE SEED · ONE CLOCK · MORE TERMS", Vector2(width, 0.044), Color(0.12, 0.13, 0.15))
	if head:
		head.position = Vector3(0, 1.30 + PANEL_PATCH * 0.5 + 0.13, 0.035)
		_panel_root.add_child(head)

	_patches.clear()
	for i in range(PANEL_LAYERS.size()):
		var n: int = int(PANEL_LAYERS[i])
		var x: float = (float(i) - (PANEL_LAYERS.size() - 1) * 0.5) * (PANEL_PATCH + PANEL_GAP)
		var quad := MeshInstance3D.new()
		quad.name = "Patch_%d" % n
		var qm := QuadMesh.new()
		qm.size = Vector2(PANEL_PATCH, PANEL_PATCH)
		quad.mesh = qm
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.resource_local_to_scene = true
		# every patch the same, except the count
		mat.set_shader_parameter("layers", n)
		mat.set_shader_parameter("show_term", 1)
		mat.set_shader_parameter("term_gain", PANEL_GAIN)
		mat.set_shader_parameter("time", 0.0)
		mat.set_shader_parameter("time_scale", 0.0 if is_frozen() else 0.2)
		mat.set_shader_parameter("cloud_scale", 2.0)
		mat.set_shader_parameter("cloud_density", 1.0)
		mat.set_shader_parameter("pink_intensity", 0.8)
		mat.set_shader_parameter("noise_basis", maxi(0, GENERATORS.find(generator)))
		quad.material_override = mat
		quad.position = Vector3(x, 1.30, 0.035)
		_panel_root.add_child(quad)
		var cap: MeshInstance3D = HangarKit.stencil("%d" % n, Vector2(0.10, 0.05), Color(0.12, 0.13, 0.15))
		if cap:
			cap.name = "Cap_%d" % n
			cap.position = Vector3(x, 1.30 - PANEL_PATCH * 0.5 - 0.07, 0.035)
			_panel_root.add_child(cap)
		_patches.append({"layers": n, "mat": mat, "quad": quad})

	var case_root := Node3D.new()
	case_root.name = "Readout"
	case_root.set_meta("em_local_instrument", true)
	case_root.position = Vector3(0.0, 0.86, 0.10)
	case_root.rotation_degrees = Vector3(-24, 0, 0)
	_panel_root.add_child(case_root)
	case_root.add_child(HangarKit.box(Vector3.ZERO, Vector3(width + 0.16, 0.26, 0.014), dark))
	_panel_readout = Label3D.new()
	_panel_readout.name = "Text"
	_panel_readout.pixel_size = 0.00088
	_panel_readout.font_size = 17
	_panel_readout.line_spacing = 0.5
	_panel_readout.modulate = Color(0.88, 0.94, 1.0)
	_panel_readout.outline_size = 3
	_panel_readout.outline_modulate = Color(0, 0, 0, 1)
	_panel_readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_panel_readout.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_panel_readout.position = Vector3(-(width + 0.10) * 0.5, 0.118, 0.010)
	case_root.add_child(_panel_readout)

	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	if RackTpl != null:
		var panel: Node3D = RackTpl.create_panel("", [
			[{"type": "button", "label": "LAYERS"}, {"type": "button", "label": "BASIS"}],
			[{"type": "button", "label": "FREEZE"}],
		], true)
		panel.name = "Panel"
		panel.set_meta("em_local_instrument", true)
		panel.position = Vector3((width + 0.16) * 0.5 + 0.22, 1.02, 0.12)
		panel.rotation_degrees = Vector3(-24, 0, 0)
		panel.scale = Vector3(1.35, 1.35, 1.35)
		_panel_root.add_child(panel)
		var actions := {"Btn_0": func(): next_layers(), "Btn_1": func(): next_basis(), "Btn_2": func(): set_frozen(not is_frozen())}
		for btn_name in actions.keys():
			var btn: Node = panel.find_child(btn_name, true, false)
			if btn == null:
				continue
			var area: Node = btn.get_node_or_null("InteractableAreaButton")
			if area != null and area.has_signal("button_pressed"):
				var action: Callable = actions[btn_name]
				area.button_pressed.connect(func(_b): action.call())

	set_layers(layers)
	_update_panel_readout()


## The room's walls take the next count — in THIS hall. A material set on a
## shared resource, or a call to every room in the tree, would reach the others.
func next_layers() -> void:
	if stand != "panel":
		return
	var order: Array = [1, 2, 4, 6]
	var i: int = order.find(layers)
	set_layers(int(order[(i + 1) % order.size()]) if i >= 0 else 6)
	_last_touched = "LAYERS"
	_broadcast_layers()
	_update_panel_readout()


func next_basis() -> void:
	if stand != "panel":
		return
	var i: int = GENERATORS.find(generator)
	generator = GENERATORS[(i + 1) % GENERATORS.size()]
	_apply_generator()
	for p in _patches:
		var mat: ShaderMaterial = (p as Dictionary)["mat"]
		if mat != null:
			mat.set_shader_parameter("noise_basis", maxi(0, GENERATORS.find(generator)))
	_last_touched = "BASIS (a different generator — not a different number of layers)"
	_broadcast_layers()
	_update_panel_readout()


## Tell the other rooms of THIS hall, and no others. The nearest ancestor that
## owns a hall is the boundary; with none, only this body changes.
func _broadcast_layers() -> void:
	if not is_inside_tree():
		return
	var hall: Node = _hall_ancestor()
	var reached: Array = []
	for r in get_tree().get_nodes_in_group("noise_rooms"):
		if r == self:
			continue
		if hall != null and not hall.is_ancestor_of(r):
			continue
		if r.has_method("set_layers"):
			r.call("set_layers", layers)
			reached.append(str((r as Node).name))
	_last_broadcast = {"hall": str(hall.name) if hall != null else "(none)", "reached": reached,
		"rooms_in_tree": get_tree().get_nodes_in_group("noise_rooms").size()}


func _hall_ancestor() -> Node:
	var n: Node = get_parent()
	while n != null:
		if n.has_meta("em_map") or str(n.name).begins_with("Seg"):
			return n
		n = n.get_parent()
	return null


func _update_panel_readout() -> void:
	if _panel_readout == null or not is_instance_valid(_panel_readout):
		return
	var lines: PackedStringArray = PackedStringArray()
	lines.append("the same field in all four: one seed, one coordinate frame, one contrast, one clock%s" % ("  FROZEN" if is_frozen() else ""))
	lines.append("layers   1        2        4        6      · each term half the amplitude, twice the frequency")
	lines.append("weight   %.3f    %.3f    %.4f   %.4f  · which is the whole of why the left patch is darker" % [
		float(PANEL_WEIGHTS[0]), float(PANEL_WEIGHTS[1]), float(PANEL_WEIGHTS[2]), float(PANEL_WEIGHTS[3])])
	lines.append("shown at a display gain of %.1f, the same on all four · the walls are at %d · basis %s" % [PANEL_GAIN, layers, generator])
	lines.append("last touched: %s" % _last_touched)
	_panel_readout.text = "\n".join(lines)


## The panel as the room can read it.
func panel_state() -> Dictionary:
	var patches: Array = []
	for p in _patches:
		var mat: ShaderMaterial = (p as Dictionary)["mat"]
		patches.append({
			"layers": int((p as Dictionary)["layers"]),
			"show_term": int(mat.get_shader_parameter("show_term")) if mat != null else -1,
			"time_scale": float(mat.get_shader_parameter("time_scale")) if mat != null else -1.0,
			"cloud_scale": float(mat.get_shader_parameter("cloud_scale")) if mat != null else -1.0,
			"cloud_density": float(mat.get_shader_parameter("cloud_density")) if mat != null else -1.0,
			"noise_basis": int(mat.get_shader_parameter("noise_basis")) if mat != null else -1,
			"shader": str(mat.shader.resource_path).get_file() if mat != null and mat.shader != null else "-",
			"local": mat.resource_local_to_scene if mat != null else false,
		})
	return {
		"stand": stand, "layers": layers, "generator": generator, "frozen": is_frozen(),
		"weights": PANEL_WEIGHTS, "patches": patches, "last_touched": _last_touched,
		"broadcast": _last_broadcast,
		"room_material_local": room_material.resource_local_to_scene if room_material != null else false,
		"wall_material_local": wall_material.resource_local_to_scene if wall_material != null else false,
		"room_layers": int(room_material.get_shader_parameter("layers")) if room_material != null else -1,
		"wall_layers": int(wall_material.get_shader_parameter("layers")) if wall_material != null else -1,
		"wall_time_scale": float(wall_material.get_shader_parameter("time_scale")) if wall_material != null else -1.0,
		"animation": animation, "animation_enabled": animation_enabled,
		"color_cycling": color_cycling, "cloud_density_animation": cloud_density_animation,
	}
