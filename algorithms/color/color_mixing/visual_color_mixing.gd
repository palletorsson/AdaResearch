extends Node3D

# @identity
# essence: two 1.2 m tables — a black one carrying nine additive R/G/B disks, a white one
#   carrying nine C/M/Y disks — each disk mirrored at five times the size on a plane three
#   metres behind, so a hand-sized overlap is legible across a room.
# desire: to let a player make white out of red, green and blue with their hands, and black
#   out of cyan, magenta and yellow, and feel that these are two different physics.
# critical_parameter: mixture — WHERE the colours are claimed to meet. The shipped bench
#   stages the additive/subtractive pair; the axis can stage either alone, or neither.
# triggers: _ready reads `mixture` (or a map token via apply_grid_config) and restages the
#   bench; the disks themselves stay grabbable at every value.
# emerges: the classic three-circle Venn is not drawn anywhere — it is what happens when
#   three transparent additive disks are laid on one centre, so the law is demonstrated
#   rather than illustrated.
# relationships: the standing bench of the `color` sequence; the disks are commons GrabDisk;
#   the mirror plane is eighteen MirroredDisplayDisk nodes in the same scene.
# truth: additive and subtractive are not two facts about colour. They are two claims about
#   where the mixing happens — in the light, in the pigment, or in the eye — and a bench
#   that shows only two of the three has already taken a side.

# ═══════════════════════════════════════════════════════════════════
# STAGE-2 DNA — `mixture`
# ═══════════════════════════════════════════════════════════════════
#
# WHERE THE COLOURS ARE CLAIMED TO MEET. The shipped object is a comparison
# bench: two tables, two grounds, two laws, side by side. That pairing is itself
# an argument, and it leaves out the third answer entirely.
#
#   bench    the shipped comparison: black table with nine R/G/B disks at
#            x = -0.8, white table with nine C/M/Y disks at x = +0.8, every disk
#            parked in its hue column, nothing overlapping. Byte for byte the
#            legacy scene — this script does nothing at all at this value.
#   light    the white table and its nine disks are gone. The black table moves
#            to the centre and its nine disks fall into THREE red/green/blue
#            trios laid on a common centre, 55 mm apart, so each trio makes the
#            additive Venn: white core, yellow / cyan / magenta lenses. Three
#            rosettes glowing on black. The mirror plane shrinks to a 1.6x echo
#            so it reads as three rosettes too instead of one blob.
#   pigment  the mirror of that: the black table is gone, the white table takes
#            the centre, its nine disks form three cyan/magenta/yellow trios —
#            and they are switched to the SUBTRACTIVE blend, so the cores go
#            black and the lenses come out red / green / blue. Dark rosettes on
#            white. (The shipped scene sets blend_type = 0 on all nine of those
#            disks, i.e. additive; see the note in _stage_pigment.)
#   retina   neither law. Both tables slide together into one continuous 2.4 m
#            slab, both are repainted neutral 50% grey, and all eighteen disks
#            are laid edge to edge on a 6 x 3 mosaic at 0.21 m pitch — six pure
#            hues per row, R C G M B Y, nothing overlapping anything. No ground
#            to add to, no ground to subtract from, no overlap: the only place
#            the mixing can happen is behind the player's cornea.
#
# The axis is CHROMATIC AND STRUCTURAL AT ONCE — deliberately, because the pixel
# critic is weakest on colour. Every value changes the table count, the table
# positions and the disk layout, so a greyscale reading still sees four different
# objects even before it sees four different palettes.
@export_enum("bench", "light", "pigment", "retina") var mixture: String = "bench"

## Allow-list. An unknown word in a map token keeps the shipped bench rather than
## stranding a placement with half a scene.
const MIXTURES: PackedStringArray = ["bench", "light", "pigment", "retina"]

# ── Layout constants, in metres ──────────────────────────────────────
const TABLE_SIZE: float = 1.2          # both tables are 1.2 x 1.2
const DISK_Y: float = 0.1              # shipped disk height above table centre
const VENN_OFFSET: float = 0.055       # trio radius — 0.1 m disks at 0.055 overlap hard
# three trios on one 1.2 m table
const VENN_CENTRES: Array = [
	Vector2(-0.27, -0.24), Vector2(0.27, -0.24), Vector2(0.0, 0.28),
]
const MOSAIC_PITCH: float = 0.21       # 0.2 m disks at 0.21 pitch just touch
const MOSAIC_COLS: int = 6
const MOSAIC_ROWS: int = 3
const RETINA_TABLE_X: float = 0.6      # two 1.2 m tables abutting into one 2.4 m slab
const MIRROR_VENN: float = 0.16        # mirror-plane disk radius for light / pigment
const MIRROR_MOSAIC: float = 0.105     # 1:1 echo for retina
const GREY_GROUND := Color(0.5, 0.5, 0.5)

const ADDITIVE_DISKS: PackedStringArray = [
	"Red1", "Red2", "Red3", "Green1", "Green2", "Green3", "Blue1", "Blue2", "Blue3",
]
const SUBTRACTIVE_DISKS: PackedStringArray = [
	"Cyan1", "Cyan2", "Cyan3", "Magenta1", "Magenta2", "Magenta3",
	"Yellow1", "Yellow2", "Yellow3",
]
## Row-major mosaic order: six hues per row, no two neighbours alike.
const MOSAIC_ORDER: PackedStringArray = [
	"Red1", "Cyan1", "Green1", "Magenta1", "Blue1", "Yellow1",
	"Red2", "Cyan2", "Green2", "Magenta2", "Blue2", "Yellow2",
	"Red3", "Cyan3", "Green3", "Magenta3", "Blue3", "Yellow3",
]


func _ready() -> void:
	_apply_mixture()


func apply_grid_config(config: Dictionary) -> void:
	# Only the declared axis is read; every other key in a map token is ignored,
	# exactly as when this root had no script at all.
	if config.has("mixture"):
		mixture = str(config["mixture"])
		_apply_mixture()


# ═══════════════════════════════════════════════════════════════════
# `mixture` — the whole of this script. `bench` returns before touching anything.
# ═══════════════════════════════════════════════════════════════════

func _apply_mixture() -> void:
	var want: String = String(mixture).strip_edges().to_lower()
	if not MIXTURES.has(want):
		want = "bench"          # unknown word keeps the shipped bench
	mixture = want
	if want == "bench":
		return
	match want:
		"light": _stage_light()
		"pigment": _stage_pigment()
		"retina": _stage_retina()


## Additive alone: the black table centred, its nine disks in three R/G/B Venns.
func _stage_light() -> void:
	_drop_table("SubtractiveTable", SUBTRACTIVE_DISKS)
	var table: Node3D = get_node_or_null("AdditiveTable")
	if table == null:
		return
	table.position.x = 0.0
	_lay_venn(table, ADDITIVE_DISKS)
	_size_mirrors(MIRROR_VENN)


## Subtractive alone: the white table centred, its nine disks in three C/M/Y Venns.
func _stage_pigment() -> void:
	_drop_table("AdditiveTable", ADDITIVE_DISKS)
	var table: Node3D = get_node_or_null("SubtractiveTable")
	if table == null:
		return
	table.position.x = 0.0
	# LATENT BUG IN THE SHIPPED SCENE, NOT FIXED HERE: visual_color_mixing.tscn
	# sets blend_type = 0 (ADDITIVE) on all nine of these disks, so the shipped
	# "subtractive" table blends additively and cyan+magenta+yellow would come out
	# WHITE. The default value is left exactly as it ships; this variant sets the
	# blend it needs to make its own claim, and the default's bug is reported
	# rather than silently corrected.
	for disk_name in SUBTRACTIVE_DISKS:
		var disk: Node = table.get_node_or_null(String(disk_name))
		if disk != null and "blend_type" in disk:
			disk.set("blend_type", 1)   # GrabDisk.BlendType.SUBTRACTIVE
	_lay_venn(table, SUBTRACTIVE_DISKS)
	_size_mirrors(MIRROR_VENN)


## Neither law: one continuous neutral slab, eighteen pure dots edge to edge.
func _stage_retina() -> void:
	var additive: Node3D = get_node_or_null("AdditiveTable")
	var subtractive: Node3D = get_node_or_null("SubtractiveTable")
	if additive == null or subtractive == null:
		return
	additive.position.x = -RETINA_TABLE_X
	subtractive.position.x = RETINA_TABLE_X
	_paint_ground(additive)
	_paint_ground(subtractive)

	var span_x: float = float(MOSAIC_COLS - 1) * MOSAIC_PITCH * 0.5
	var span_z: float = float(MOSAIC_ROWS - 1) * MOSAIC_PITCH * 0.5
	for i in range(MOSAIC_ORDER.size()):
		var disk_name: String = String(MOSAIC_ORDER[i])
		var owner_table: Node3D = additive if ADDITIVE_DISKS.has(disk_name) else subtractive
		var disk: Node3D = owner_table.get_node_or_null(disk_name)
		if disk == null:
			continue
		var col: int = i % MOSAIC_COLS
		var row: int = i / MOSAIC_COLS
		# World-space cell, expressed in the owning table's local frame.
		var world_x: float = float(col) * MOSAIC_PITCH - span_x
		var world_z: float = float(row) * MOSAIC_PITCH - span_z
		disk.position = Vector3(world_x - owner_table.position.x, DISK_Y, world_z)
	_size_mirrors(MIRROR_MOSAIC)


## Three trios of three disks, each trio laid on one centre so the disks overlap.
func _lay_venn(table: Node3D, disk_names: PackedStringArray) -> void:
	for i in range(disk_names.size()):
		var disk: Node3D = table.get_node_or_null(String(disk_names[i]))
		if disk == null:
			continue
		var trio: int = i % VENN_CENTRES.size()
		var slot: int = i / VENN_CENTRES.size()
		var centre: Vector2 = VENN_CENTRES[trio]
		var angle: float = float(slot) * TAU / 3.0 - PI * 0.5
		# A 2 mm stagger per slot so three coplanar transparent disks layer in a
		# stable order instead of fighting for the same plane.
		disk.position = Vector3(
			centre.x + cos(angle) * VENN_OFFSET,
			DISK_Y + float(slot) * 0.002,
			centre.y + sin(angle) * VENN_OFFSET)


## Free a table with its disks, and the mirror-plane nodes that tracked them.
func _drop_table(table_name: String, disk_names: PackedStringArray) -> void:
	for disk_name in disk_names:
		var display: Node = get_node_or_null("%sDisplay" % String(disk_name))
		if display != null:
			display.queue_free()
	var table: Node = get_node_or_null(table_name)
	if table != null:
		table.queue_free()


## Repaint a CSG table with a fresh neutral material. A NEW material, never a
## mutation of the scene's SubResource, so nothing leaks to another instance.
func _paint_ground(table: Node3D) -> void:
	if not ("material" in table):
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = GREY_GROUND
	mat.roughness = 0.9
	table.set("material", mat)


## Rebuild every surviving mirror-plane disk at a new radius. display_radius is
## only read when the node builds its mesh in _ready, which has already run by the
## time the root gets here, so the mesh is replaced rather than the export set.
func _size_mirrors(radius: float) -> void:
	for child in get_children():
		if child is MeshInstance3D or not (child is Node3D):
			continue
		if not ("display_radius" in child):
			continue
		child.set("display_radius", radius)
		for sub in child.get_children():
			if sub is MeshInstance3D:
				var cyl := CylinderMesh.new()
				cyl.top_radius = radius
				cyl.bottom_radius = radius
				cyl.height = float(child.get("display_height"))
				(sub as MeshInstance3D).mesh = cyl
