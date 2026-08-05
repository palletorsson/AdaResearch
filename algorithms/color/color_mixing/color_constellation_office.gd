extends Node3D

# @identity
# essence: RGB/CMY glass walls at angles — additive color mixing through transparency and emitted light overlap
# desire: to walk between colored glass partitions and see your shadow split into complementary colors on the floor
# critical_parameter: mixture — WHERE the colours are claimed to meet. The shipped office
#   stages the additive/subtractive pair as two groups of panes and then renders both the
#   same way; the axis makes the room commit to one answer.
# triggers: none — static installation; color mixing happens through player movement and viewing angle
# emerges: walking through overlapping RGB walls creates white-ish zones where all three primaries combine — additive mixing proven by architecture
# needs: OmniLight3D per wall [has]; transparency [has]; VR walkthrough [has]; interactive wall rotation [missing]
# relationships: contrasts with albers_wall_gallery (subtractive paint vs additive light); follows dark_side_prism (spectrum split vs color recombination)
# truth: color mixing is not a formula — it is what happens when light from different sources arrives at the same place at the same time

## Color Walls Office - Transparent colored glass walls like office partitions
## Spread out and rotated at various angles to create color mixing effects

@export var wall_size: Vector2 = Vector2(2.0, 2.4)
@export var wall_thickness: float = 0.03
@export var transparency: float = 0.4
@export var emit_strength: float = 0.6
@export var light_energy: float = 3.0
@export var light_range: float = 5.0

@export_category("Layout")
@export var spread: float = 2.5
@export var room_size: Vector3 = Vector3(12.0, 3.0, 10.0)

# ═══════════════════════════════════════════════════════════════════
# STAGE-2 DNA — `mixture`
# ═══════════════════════════════════════════════════════════════════
#
# WHERE THE COLOURS ARE CLAIMED TO MEET. The word and its meanings are taken
# from visual_color_mixing, the standing bench of the same sequence, which asks
# the identical question of nine disks on two tables. This is the ARCHITECTURAL
# member of that family: you do not look at the mixing, you walk into it.
#
# The shipped room already stages the pair — _build_office_walls labels three
# panes "RGB Section - Primary additive colors" and three "CMY Section - Primary
# subtractive colors" — and then builds all eighteen the same way: alpha 0.4
# glass with emission on and a coloured OmniLight3D bolted to the front. So the
# cyan, magenta and yellow panes EMIT. They are lamps that happen to be named
# after inks, and nothing in this room has ever mixed subtractively. The comment
# made the claim and the material quietly refused it.
#
#   bench    the shipped eighteen panes, both sections named and neither
#            performed. Byte for byte the legacy room — this branch touches
#            nothing at all.
#   light    the panes are LAMPS. Alpha stops damping them and the blend SUMS
#            instead of averaging, so the three 60-degree panes in the middle
#            (the block its own comment calls "Overlapping area") finally make
#            the white core the @identity has always promised.
#   retina   the panes are PIGMENT PATCHES. Opaque, unlit, no glow and no
#            coloured spill: nothing passes through anything, so no two colours
#            meet anywhere except in the eye of whoever is walking. Eighteen
#            pure hues, which is the same count as the family's mosaic.
#
# `pigment` IS DELIBERATELY ABSENT and the reason is in the registry's `declines`:
# subtractive mixing needs a white ground to subtract FROM, and a room of
# freestanding partitions has none. The sibling solved this with a white TABLE.
@export_enum("bench", "light", "retina") var mixture: String = "bench"

## Allow-list. An unknown word in a map token keeps the shipped room rather than
## stranding a placement with a half-staged one.
const MIXTURES: PackedStringArray = ["bench", "light", "retina"]

## _ready has built once. Guards the rebuild: a config call that arrives BEFORE
## the first build must not tear down panes that do not exist yet.
var _built: bool = false

func _ready() -> void:
	_build_office_walls()
	_built = true

func _build_office_walls() -> void:
	# RGB Section - Primary additive colors
	_add_glass_wall(Vector3(-4, 0, -2), 15, Color.RED)
	_add_glass_wall(Vector3(-2.5, 0, -3), -20, Color.GREEN)
	_add_glass_wall(Vector3(-3.5, 0, -0.5), 45, Color.BLUE)
	
	# CMY Section - Primary subtractive colors  
	_add_glass_wall(Vector3(3, 0, -2), -25, Color.CYAN)
	_add_glass_wall(Vector3(4.5, 0, -3.5), 10, Color.MAGENTA)
	_add_glass_wall(Vector3(2, 0, -0.5), -40, Color.YELLOW)
	
	# Mixed colors section - center area
	_add_glass_wall(Vector3(-1, 0, 1), 30, Color.ORANGE)
	_add_glass_wall(Vector3(1, 0, 0.5), -35, Color.PURPLE)
	_add_glass_wall(Vector3(0, 0, 2.5), 0, Color.LIME)
	
	# Overlapping area - creates color mixing when viewed through multiple
	_add_glass_wall(Vector3(-0.8, 0, -1.5), 60, Color.RED, Vector2(1.5, 2.0))
	_add_glass_wall(Vector3(0, 0, -1.2), 60, Color.GREEN, Vector2(1.5, 2.0))
	_add_glass_wall(Vector3(0.8, 0, -0.9), 60, Color.BLUE, Vector2(1.5, 2.0))
	
	# Back wall partitions - warm colors
	_add_glass_wall(Vector3(-4, 0, 3), -10, Color(1.0, 0.3, 0.1), Vector2(2.5, 2.8))
	_add_glass_wall(Vector3(-1.5, 0, 3.5), 20, Color(1.0, 0.6, 0.0), Vector2(2.5, 2.8))
	
	# Back wall partitions - cool colors
	_add_glass_wall(Vector3(2, 0, 3), 5, Color(0.1, 0.5, 1.0), Vector2(2.5, 2.8))
	_add_glass_wall(Vector3(4.5, 0, 3.5), -15, Color(0.4, 0.1, 0.9), Vector2(2.5, 2.8))
	
	# Corner accents
	_add_glass_wall(Vector3(-5, 0, 0), 90, Color.WHITE, Vector2(1.0, 2.4))
	_add_glass_wall(Vector3(5, 0, 0), 90, Color(0.2, 0.2, 0.2), Vector2(1.0, 2.4))

func _add_glass_wall(pos: Vector3, angle_deg: float, color: Color, size: Vector2 = Vector2.ZERO) -> MeshInstance3D:
	var actual_size = size if size != Vector2.ZERO else wall_size
	
	var wall = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(actual_size.x, actual_size.y, wall_thickness)
	wall.mesh = mesh
	wall.position = Vector3(pos.x, actual_size.y * 0.5, pos.z)
	wall.rotation_degrees.y = angle_deg
	
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(color.r, color.g, color.b, transparency)
	mat.roughness = 0.05
	mat.metallic = 0.1
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED  # See from both sides
	
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = emit_strength
	
	wall.material_override = mat
	add_child(wall)
	
	# Add colored light to the wall
	var light = OmniLight3D.new()
	light.light_color = color
	light.light_energy = light_energy
	light.omni_range = light_range
	light.position = Vector3(0, 0, wall_thickness * 2)  # Slightly in front of wall
	wall.add_child(light)
	
	return wall

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## Guarded twice: the word must be in this artifact's own allow-list AND differ
## from what is in play, and the rebuild only runs once _ready has built, because
## the grid calls this deferred.
func apply_grid_config(config: Dictionary) -> void:
	if not config.has("mixture"):
		return
	var want: String = str(config["mixture"]).strip_edges().to_lower()
	if not MIXTURES.has(want) or want == mixture:
		return
	mixture = want
	if not _built:
		return          # _ready has not built yet; it will read the new value
	for child in get_children():
		if child is MeshInstance3D:
			remove_child(child)
			child.queue_free()
	_build_office_walls()
