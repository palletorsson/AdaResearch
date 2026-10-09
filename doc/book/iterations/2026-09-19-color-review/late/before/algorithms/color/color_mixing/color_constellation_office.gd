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
var cubicle_office := false
var office_panes: Array[MeshInstance3D] = []
var glass_visible := true
var glass_button: Node3D
var glass_readout: Label

func _ready() -> void:
	cubicle_office = str(get_meta("config_layout", "")) == "cubicles"
	_build_office_walls()
	_built = true

func _build_office_walls() -> void:
	if cubicle_office:
		_build_cubicles()
		return
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

	# ── mixture ──────────────────────────────────────────────────────────────
	# `bench` FALLS THROUGH UNTOUCHED. The eight lines above are the shipped
	# material property for property and in the shipped order, so the default is
	# the legacy room by construction rather than by transcription — nothing here
	# can drift away from it, because nothing here restates it.
	if mixture == "light":
		# LAMPS. Alpha stops damping the pane and the blend SUMS instead of
		# averaging, so where the three 60-degree panes cross — the block whose
		# own comment calls it "Overlapping area" — red, green and blue add
		# toward the white core the @identity has always promised.
		mat.albedo_color = Color(color.r, color.g, color.b, 1.0)
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	elif mixture == "retina":
		# PIGMENT PATCHES. Opaque, unlit, no glow: nothing passes through
		# anything, so no two colours meet anywhere except in the eye of whoever
		# is walking. Eighteen pure hues, the same count as the family's mosaic.
		mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
		mat.albedo_color = Color(color.r, color.g, color.b, 1.0)
		mat.emission_enabled = false
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	wall.material_override = mat
	add_child(wall)

	# Add colored light to the wall.
	#
	# `retina` builds NO OmniLight3D at all. A pigment patch that threw coloured
	# light onto its neighbours would be mixing after all, which is the one thing
	# this reading denies, and leaving the lamp in would have made the axis a
	# statement about alpha rather than about where the colours meet.
	if mixture != "retina":
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
	if str(config.get("layout", "")) == "cubicles" and not cubicle_office:
		cubicle_office = true
		if _built:
			for child in get_children(): remove_child(child); child.queue_free()
			_build_cubicles()
		return
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

func _office_box(parent: Node3D, title: String, pos: Vector3, size: Vector3, color: Color, solid := true) -> MeshInstance3D:
	var node := MeshInstance3D.new(); node.name = title
	var mesh := BoxMesh.new(); mesh.size = size; node.mesh = mesh
	var mat := StandardMaterial3D.new(); mat.albedo_color = color; mat.roughness = 0.55
	node.material_override = mat; parent.add_child(node); node.position = pos
	if solid:
		var body := StaticBody3D.new(); node.add_child(body)
		var shape := BoxShape3D.new(); shape.size = size
		var col := CollisionShape3D.new(); col.shape = shape; body.add_child(col)
	return node

func _office_pane(pos: Vector3, angle: float, width: float, color: Color) -> void:
	var pane := _office_box(self,"GlassPartition",pos+Vector3.UP*1.3,Vector3(width,2.6,0.035),color)
	office_panes.append(pane)
	pane.rotation_degrees.y = angle
	var mat: StandardMaterial3D = pane.material_override
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.26; mat.roughness = 0.09; mat.metallic = 0.12
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var frame := Color("37434c")
	for x in [-width*0.5,width*0.5]:
		_office_box(pane,"Mullion",Vector3(x,0,0),Vector3(0.045,2.65,0.065),frame,false)
	for y in [-1.3,1.3]:
		_office_box(pane,"Rail",Vector3(0,y,0),Vector3(width,0.045,0.065),frame,false)

func _build_cubicles() -> void:
	office_panes.clear()
	var colors := [Color("ec6458"),Color("e8b856"),Color("7eba69"),Color("5cbacb"),Color("657acc"),Color("ad70c1"),Color("d979a8"),Color("72ba9b")]
	for row in range(4):
		for side in [-1,1]:
			var z := -5.4+row*3.6
			var x: float = side*3.2
			var index: int = row*2+(0 if side == -1 else 1)
			var color: Color = colors[index]
			_office_pane(Vector3(x,0,z+1.5),0,3.2,color)
			_office_pane(Vector3(x,0,z-1.5),0,3.2,color)
			_office_pane(Vector3(side*4.8,0,z),90,3.0,color)
			# Two short panes leave a 1.2 m entrance from the central aisle.
			for end in [-1,1]: _office_pane(Vector3(side*1.6,0,z+end*1.05),90,0.9,color)
			_office_box(self,"Carpet",Vector3(x,0.012,z),Vector3(3.15,0.024,2.95),Color("c9c7bf"),false)
			_office_box(self,"DeskTop",Vector3(x,0.74,z+0.8),Vector3(1.7,0.065,0.7),Color("bb9672"))
			for dx in [-0.7,0.7]:
				_office_box(self,"DeskLeg",Vector3(x+dx,0.35,z+0.8),Vector3(0.055,0.7,0.55),Color("3e474b"))
			_office_box(self,"Monitor",Vector3(x,1.04,z+1.0),Vector3(0.58,0.36,0.05),Color("293b46"))
			_office_box(self,"ChairSeat",Vector3(x,0.45,z-0.1),Vector3(0.5,0.09,0.5),Color("565f68"))
			_office_box(self,"ChairBack",Vector3(x,0.7,z-0.35),Vector3(0.5,0.55,0.07),Color("565f68"))
			_office_box(self,"ChairStem",Vector3(x,0.22,z-0.1),Vector3(0.12,0.44,0.12),Color("37434c"))
	set_meta("em_visibility_bounds",AABB(Vector3(-5,0,-8.5),Vector3(10,3,15.5)))
	if str(get_meta("config_compare", "")) == "visibility":
		var controls: Node3D = load("res://commons/ui/control_panel.gd").new()
		controls.name = "VisibilityConsole"
		controls.title = "WHAT CAN PASS?"
		controls.position = Vector3(0,1.1,-8)
		controls.rotation_degrees.y = 180
		add_child(controls)
		glass_button = controls.add_button("GLASS / OPAQUE")
		glass_button.pressed.connect(toggle_office_glass)
		glass_readout = controls.add_readout("GLASS / SAME WALLS")
		_office_box(self,"VisibilityPlinth",Vector3(0,0.45,-8),Vector3(0.85,0.9,0.65),Color("cdc5ba"))

func toggle_office_glass() -> void:
	glass_visible = not glass_visible
	for pane in office_panes:
		var mat: StandardMaterial3D = pane.material_override
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if glass_visible else BaseMaterial3D.TRANSPARENCY_DISABLED
		mat.albedo_color.a = 0.26 if glass_visible else 1.0
	if glass_readout: glass_readout.text = "GLASS / SAME WALLS" if glass_visible else "OPAQUE / SAME WALLS"
