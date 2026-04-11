extends Node3D

# @identity
# essence: grid(width, height) of BoxMesh bricks colored sequentially from a named palette — running bond pattern
# desire: to see a color palette become architecture, each brick a swatch in a wall you can walk alongside
# critical_parameter: palette — selects from 20 named palettes (starry_night to industrial_brutalism), redefining the wall's emotional register
# triggers: apply_grid_config can change dimensions, brick size, mortar, and palette at runtime — wall regenerates entirely
# emerges: the running bond offset (half-brick shift on odd rows) creates diagonal color rivers through the palette sequence
# needs: palette selection [has via config]; VR interaction [missing]; mortar color control [missing]
# relationships: depends on color_palettes.tres; contrasts with pillarcolorcollection (vertical vs horizontal color display)
# truth: a brick wall is a color sequence made solid — the mortar is the silence between notes

@export var wall_width: int = 10
@export var wall_height: int = 5
@export var brick_size: Vector3 = Vector3(0.2, 0.1, 0.1)
@export var mortar_thickness: float = 0.01
@export_enum("starry_night", "rothko_chapel", "mondrian_grid", "memphis_design", "bauhaus_palette", "stonewall_freedom", "pride_rainbow", "harlem_renaissance", "pinkness_spectrum", "dance_energy", "joy_celebration", "pain_depth", "love_warmth", "frida_kahlo", "hokusai_wave", "desert_sunset", "neon_cyberpunk", "autumn_melancholy", "tropical_paradise", "industrial_brutalism") var palette: String = "starry_night"

@export var color_palette_resource: Resource
@export var palette_resource_path: String = "res://algorithms/color/color_palettes.tres"

func _ready() -> void:
	if color_palette_resource == null:
		var loaded := load(palette_resource_path)
		if loaded is Resource:
			color_palette_resource = loaded
	generate_wall()

func generate_wall() -> void:
	for child in get_children():
		child.queue_free()

	var colors: Array = []
	if color_palette_resource and "palettes" in color_palette_resource:
		var palettes_dict = color_palette_resource.palettes
		if typeof(palettes_dict) == TYPE_DICTIONARY and palette in palettes_dict:
			var entry = palettes_dict[palette]
			if typeof(entry) == TYPE_DICTIONARY and "colors" in entry:
				colors = entry["colors"]
	if colors.is_empty():
		# Fallback palette: pleasant HSV ramp
		for i in range(wall_width * wall_height):
			var t = float(i) / max(1, wall_width * wall_height - 1)
			colors.append(Color.from_hsv(0.8 * t, 0.65, 0.9))
	var color_index = 0

	for y in range(wall_height):
		for x in range(wall_width):
			var brick = MeshInstance3D.new()
			brick.mesh = BoxMesh.new()
			brick.mesh.size = brick_size
			var material = StandardMaterial3D.new()
			material.albedo_color = colors[color_index]
			material.emission_enabled = true
			material.emission = colors[color_index]
			brick.material_override = material

			var x_pos = x * (brick_size.x + mortar_thickness)
			if y % 2 == 1:
				x_pos += (brick_size.x + mortar_thickness) / 2.0
			var y_pos = y * (brick_size.y + mortar_thickness)
			brick.transform.origin = Vector3(x_pos, y_pos, 0)

			add_child(brick)

			color_index = (color_index + 1) % colors.size()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	if config.is_empty():
		return
	if config.has("wall_width"):
		wall_width = int(config["wall_width"])
	if config.has("wall_height"):
		wall_height = int(config["wall_height"])
	if config.has("brick_width"):
		brick_size.x = float(config["brick_width"])
	if config.has("brick_height"):
		brick_size.y = float(config["brick_height"])
	if config.has("brick_depth"):
		brick_size.z = float(config["brick_depth"])
	if config.has("mortar_thickness"):
		mortar_thickness = float(config["mortar_thickness"])
	if config.has("palette"):
		palette = str(config["palette"])
	generate_wall()
