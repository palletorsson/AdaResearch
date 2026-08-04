extends StaticBody3D

# Queer Cylinder Target
# A dynamic, responsive target practice object celebrating queer aesthetics
# Features concentric rings in Pride colors arranged like a traditional target face
#
# @identity
# essence: Concentric Pride-color rings on a cylindrical target — hit registration with rippling response and point scoring
# desire: To turn the target — usually a violent object — into a celebratory and responsive surface; aim becomes greeting
# critical_parameter: face and flag — the arrangement decides whether it reads as target or banner, the palette decides whose
# triggers: Hits anywhere produce ripple feedback; ring stacking reads as Pride flag at rest, target face under aim
# emerges: The same geometry is two cultural objects depending on intent — flag when still, target when sighted
# needs: hit detection [has], rippling visual response [has], score signal [has], declared genome [has]
# relationships: Anchor object in forces/Combat_Arena map alongside gravity_gun and vector_normalize_demo
# truth: A target does not have an inside and an outside — it has a surface that records intentions arriving from elsewhere.

class_name QueerCylinderTarget

# ═══════════════════════════════════════════════════════════════════════════
# STAGE-2 DNA — `face` and `flag`
# ═══════════════════════════════════════════════════════════════════════════
#
# THE WHOLE ARTIFACT IS AN ARGUMENT ABOUT TWO HARD-CODED LISTS, AND UNTIL NOW
# NEITHER OF THEM COULD BE ASKED A QUESTION.
#
# `emerges` in the identity block above already says it: "the same geometry is
# two cultural objects depending on intent — flag when still, target when
# sighted". That claim was made in a comment about a build that only ever
# produced ONE of the two. Concentric rings, outermost first, z-offset by a
# millimetre each: that is a target face and nothing else. The flag reading was
# something the reader was asked to supply. `face` makes the arrangement a
# declared choice so the claim can be looked at instead of asserted.
#
#   bullseye  the shipped build, ring for ring: concentric disks in the XY plane,
#             radius stepping down by max_radius / n, each pushed 1 mm forward of
#             the last. Archery's target face. The legacy lineage.
#   bands     the same colours, the same order, the same total square — stacked
#             as horizontal stripes. Nobody shoots at this. It is the flag the
#             palette always was, standing where the target stood, and the ONE
#             thing that changed is that the colours no longer converge on a
#             centre. A bullseye has a place worth hitting; a flag does not.
#   spokes    the colours turned radial: n bars from a shared hub, a wheel or a
#             pinwheel. Everything is still equidistant from the middle, so there
#             is no inner and no outer, no bull and no outer ring — no hierarchy
#             of colours, which the bullseye cannot avoid asserting.
#   column    the face laid down and stacked into a ziggurat: horizontal disks
#             narrowing upward, a monument rather than a surface. It stops facing
#             the shooter altogether, which is what the truth line above says a
#             target cannot do.
#
# `flag` is the second hard-coded list, and the source comment on it is the tell:
# "(removed outer yellow/orange/red)". Somebody made an editorial decision about
# which stripes this object wears and left it as a parenthesis. Making it a word
# puts the decision back in the room — including the two values that are NOT
# celebrations: `full`, which restores what the parenthesis removed, and
# `archery`, which is the official FITA target and shows what this object looks
# like with the flag taken off it. That is the counterfactual the artifact needs.
#
# Neither word touches the CollisionShape3D, the particles, the audio, the flash
# or the score: any arrangement is hit exactly the same way, which is the point.
@export_enum("bullseye", "bands", "spokes", "column") var face: String = "bullseye"
@export_enum("progress", "rainbow", "trans", "full", "archery") var flag: String = "progress"

## Allow-lists. An unknown word from a map token falls back to the shipped build
## rather than stranding a placement with an empty container.
const FACES: PackedStringArray = ["bullseye", "bands", "spokes", "column"]
const FLAGS: PackedStringArray = ["progress", "rainbow", "trans", "full", "archery"]

@export_group("Settings")
@export var points_per_hit: int = 10
@export var breathing_speed: float = 2.0
@export var breathing_amount: float = 0.02
@export var target_radius: float = 0.6
@export var target_thickness: float = 0.05
## -1.0 is the shipped behaviour: a random starting phase per instance, so two targets in
## one arena do not breathe in lockstep. Any value >= 0 pins it. Nothing but a capture has
## a reason to pin it, and without the pin the 2% breathing scale is noise in the frame
## rather than a fact about the axis being measured.
@export var breathing_phase: float = -1.0

@onready var container = $RingsContainer
@onready var audio_player = $AudioStreamPlayer3D
@onready var hit_particles = $GPUParticles3D

# Colors based on the Progress Pride Flag (removed outer yellow/orange/red).
# These eight, in this order, are what every existing placement shows.
const HEX_PROGRESS: PackedStringArray = [
	"#008026", # Nature (Green) - Outer
	"#004DFF", # Harmony (Blue)
	"#750787", # Spirit (Purple)
	"#FFFFFF", # Magic/Nonbinary (White)
	"#F5A9B8", # Trans Pink
	"#5BCEFA", # Trans Blue
	"#613915", # POC Inclusion (Brown)
	"#000000", # HIV/AIDS Awareness (Black) - Inner (bullseye)
]
## The 1979 six-stripe flag — the one the shipped palette is a revision of.
const HEX_RAINBOW: PackedStringArray = [
	"#E40303", "#FF8C00", "#FFED00", "#008026", "#004DFF", "#750787",
]
## Five stripes, and the only palette here that is symmetric: it has no outer.
const HEX_TRANS: PackedStringArray = [
	"#5BCEFA", "#F5A9B8", "#FFFFFF", "#F5A9B8", "#5BCEFA",
]
## What the source comment says was removed, put back: eleven stripes.
const HEX_FULL: PackedStringArray = [
	"#E40303", "#FF8C00", "#FFED00", "#008026", "#004DFF", "#750787",
	"#FFFFFF", "#F5A9B8", "#5BCEFA", "#613915", "#000000",
]
## The regulation FITA face: white, black, blue, red, gold. The object with no
## flag on it at all — the thing the rest of this artifact is arguing with.
const HEX_ARCHERY: PackedStringArray = [
	"#FFFFFF", "#FFFFFF", "#1A1A1A", "#1A1A1A",
	"#3B7DD8", "#3B7DD8", "#D62828", "#FFD400",
]

var palette: Array[Color] = []

var rings: Array[MeshInstance3D] = []
var time_accum: float = 0.0

func _ready() -> void:
	_read_grid_config_meta()
	_generate_rings()
	if breathing_phase < 0.0:
		time_accum = randf() * 100.0
	else:
		time_accum = breathing_phase

func _process(delta: float) -> void:
	time_accum += delta

	# Gentle breathing animation
	for i in range(rings.size()):
		var ring = rings[i]
		var breathe = 1.0 + sin(time_accum * breathing_speed + (i * 0.2)) * breathing_amount
		ring.scale = Vector3(breathe, 1.0, breathe)


## Grid config arrives twice and by two routes: GridInteractablesComponent sets
## config_<key> metadata on the instantiated root and then calls apply_grid_config(),
## and the capture harness calls apply_grid_config() before the scene enters the tree.
## Reading the metadata on the way in means the rings are built once, correctly.
func _read_grid_config_meta() -> void:
	var node: Node = self
	while node != null:
		if node.has_meta("config_face"):
			face = str(node.get_meta("config_face"))
		if node.has_meta("config_flag"):
			flag = str(node.get_meta("config_flag"))
		node = node.get_parent()


## Config from map_data.json tokens: #face:bands  ·  #flag:archery
##
## GUARDED ON CHANGE, deliberately. All three maps that place this
## (ForcesArena, Forces_Drone_Game, VFM_08_Arena) use a bare token with at most a
## rotation, so neither key is present and this returns before touching anything;
## and the grid reaches this twice per placement, so an unguarded rebuild would tear
## down and re-raise the whole face on both of those, for nothing.
func apply_grid_config(config: Dictionary) -> void:
	var was_face: String = face
	var was_flag: String = flag

	if config.has("face"):
		face = str(config["face"])
	if config.has("flag"):
		flag = str(config["flag"])

	if face == was_face and flag == was_flag:
		return
	# Before _ready() there are no rings yet and _ready() will build them itself.
	if rings.is_empty():
		return

	_rebuild_rings()


func _rebuild_rings() -> void:
	for ring in rings:
		if is_instance_valid(ring):
			if ring.get_parent() != null:
				ring.get_parent().remove_child(ring)
			ring.queue_free()
	rings.clear()
	_generate_rings()


## Fall back to the shipped word rather than to nothing.
func _settle(word: String, allowed: PackedStringArray, fallback: String) -> String:
	var want: String = String(word).strip_edges().to_lower()
	if allowed.has(want):
		return want
	return fallback


## `which` rather than `name`: a parameter called name shadows Node.name.
func _palette_for(which: String) -> Array[Color]:
	var hexes: PackedStringArray = HEX_PROGRESS
	match which:
		"rainbow":
			hexes = HEX_RAINBOW
		"trans":
			hexes = HEX_TRANS
		"full":
			hexes = HEX_FULL
		"archery":
			hexes = HEX_ARCHERY
		_:
			hexes = HEX_PROGRESS
	var out: Array[Color] = []
	for h in hexes:
		out.append(Color(h))
	return out


func _generate_rings() -> void:
	if not container:
		container = Node3D.new()
		container.name = "RingsContainer"
		add_child(container)

	face = _settle(face, FACES, "bullseye")
	flag = _settle(flag, FLAGS, "progress")
	palette = _palette_for(flag)

	# Create concentric rings like a traditional target (bullseye)
	# Rings are horizontal flat disks stacked with slight z-offset
	# Outer rings are larger, inner rings are smaller

	var num_rings: int = palette.size()
	var ring_thickness: float = 0.1  # Height of each cylinder (thin disks)
	var max_radius: float = target_radius

	match face:
		"bands":
			_face_bands(num_rings, ring_thickness, max_radius)
		"spokes":
			_face_spokes(num_rings, ring_thickness, max_radius)
		"column":
			_face_column(num_rings, ring_thickness, max_radius)
		_:
			_face_bullseye(num_rings, ring_thickness, max_radius)


## THE SHIPPED ARRANGEMENT, line for line — the loop that was inline here before,
## with the same radius_step, the same palette order and the same 1 mm z-offset.
func _face_bullseye(num_rings: int, ring_thickness: float, max_radius: float) -> void:
	var radius_step: float = max_radius / num_rings

	for i in range(num_rings):
		# Outer rings first (palette[0] is outermost)
		var ring_radius: float = max_radius - (i * radius_step)
		var color: Color = palette[i]
		# Small z-offset so inner rings appear on top
		var z_offset: float = i * 0.001

		_create_ring(ring_radius, ring_thickness, color, z_offset)


## The flag, standing where the target stood. Same colours, same order, same square.
func _face_bands(num_rings: int, ring_thickness: float, max_radius: float) -> void:
	var band_h: float = (max_radius * 2.0) / float(num_rings)
	for i in range(num_rings):
		var mesh_inst := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(max_radius * 2.0, band_h, ring_thickness)
		mesh_inst.mesh = bm
		mesh_inst.material_override = _create_material(palette[i])
		mesh_inst.position = Vector3(0.0, max_radius - (float(i) + 0.5) * band_h, 0.0)
		container.add_child(mesh_inst)
		rings.append(mesh_inst)


## Radial bars from a shared hub — every colour the same distance from the centre,
## so no ring is the bull and none is the outer.
func _face_spokes(num_rings: int, ring_thickness: float, max_radius: float) -> void:
	var width: float = (TAU * max_radius) / float(num_rings) * 0.55
	for i in range(num_rings):
		var angle: float = TAU * float(i) / float(num_rings)
		var mesh_inst := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(max_radius, width, ring_thickness)
		mesh_inst.mesh = bm
		mesh_inst.material_override = _create_material(palette[i])
		mesh_inst.position = Vector3(cos(angle), sin(angle), 0.0) * (max_radius * 0.5)
		mesh_inst.rotation = Vector3(0.0, 0.0, angle)
		container.add_child(mesh_inst)
		rings.append(mesh_inst)


## The face laid flat and stacked: horizontal disks narrowing upward. A monument,
## which by definition has no side you are supposed to stand in front of.
func _face_column(num_rings: int, ring_thickness: float, max_radius: float) -> void:
	var radius_step: float = max_radius / num_rings
	var total: float = float(num_rings) * ring_thickness
	for i in range(num_rings):
		var mesh_inst := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		var disk_radius: float = max_radius - (i * radius_step)
		cyl.top_radius = disk_radius
		cyl.bottom_radius = disk_radius
		cyl.height = ring_thickness
		cyl.radial_segments = 32
		mesh_inst.mesh = cyl
		mesh_inst.material_override = _create_material(palette[i])
		# No X rotation: the disk stays horizontal and the stack rises.
		mesh_inst.position = Vector3(0.0, -total * 0.5 + (float(i) + 0.5) * ring_thickness, 0.0)
		container.add_child(mesh_inst)
		rings.append(mesh_inst)


func _create_ring(radius: float, thickness: float, color: Color, z_offset: float) -> void:
	var mesh_inst = MeshInstance3D.new()

	var cyl = CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = thickness
	cyl.radial_segments = 32

	mesh_inst.mesh = cyl
	mesh_inst.material_override = _create_material(color)
	# Rotate 90 degrees on X axis so the disk is horizontal (facing forward)
	mesh_inst.rotation_degrees.x = 90.0
	mesh_inst.position.z = z_offset

	container.add_child(mesh_inst)
	rings.append(mesh_inst)

func _create_material(color: Color) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.5
	mat.roughness = 0.2
	mat.metallic = 0.1
	return mat

func damage(_amount: float) -> void:
	_on_hit()

func hit() -> void:
	_on_hit()

func _on_hit() -> void:
	# Feedback
	_flash()
	if audio_player and audio_player.stream:
		# Random pitch to make it musical
		audio_player.pitch_scale = randf_range(0.8, 1.2)
		audio_player.play()

	if hit_particles:
		hit_particles.emitting = true

	# Score
	GameManager.add_points(points_per_hit)

func _flash() -> void:
	# Flash all materials white
	var tween = create_tween()
	for ring in rings:
		var initial_mat = ring.material_override as StandardMaterial3D
		var initial_emission = initial_mat.emission

		# Flash emission bright
		tween.parallel().tween_property(initial_mat, "emission", Color.WHITE * 3.0, 0.05)
		tween.parallel().tween_property(initial_mat, "emission", initial_emission, 0.2).set_delay(0.05)
