extends Node3D
class_name WallPlacard

# @identity
# essence: the small museum caption mounted on the wall beside an artwork — a flat, quiet card that names the thing: TITLE in caps, a thin rule, then the metadata line (sequence · date) and one sentence of intent. Not a screen, not a HUD, not an info-panel blinking with stats. A printed placard. The curatorial voice of the lab: the register that says "this is what you are looking at, and here is the one sentence we want you to carry," in the typographic calm of a gallery label.
# desire: it wants to curate, not to inform. Where the chalkboard STATES the science by hand and the gems ENACT the concept, the placard CAPTIONS — it frames the room as an exhibit and the player as a visitor. It wants the dignity of white space and a single rule line; it wants to drop the XP/health/barcode chrome of the old info board and speak in the flat, certain voice of a wall label that has decided what matters.
# critical_parameter: title + meta + body. title is the work's name (caps, large). meta is the small line under the rule (e.g. "PRIMITIVES · 2036"). body is the one sentence of intent — kept short, because a placard that runs long stops being a placard. accent tints the rule + title underline so a sequence can colour its own labels.
# triggers: _ready renders the three text blocks onto a SubViewport, bakes it to a mipmapped ImageTexture (legible at VR distance, like the chalkboard), and maps it onto a thin card mesh with a slim frame; apply_grid_config rebuilds on content change.
# emerges: hung beside a gem it turns the lab into a gallery — the player reads the card, then looks at the work. A row of placards across a sequence reads as an exhibition wall-text walk. It is the curatorial counterpart to the chalkboard: board = the proof, placard = the label.
# needs: a flat card surface [present]; three typographic registers — title / rule+meta / body [present]; a slim frame so it reads as a mounted label not a poster [present]; mipmapped bake so the small body text survives VR distance [present]
# relationships: replaces the AnnotationInfoBoard (the game-HUD info_board) as the lab's wall caption — that board showed XP/health/barcode (scoreboard chrome); this shows curation. Sibling to the chalkboard (both 2D-in-3D baked boards); the museum-label member of the lab fittings family (signage titles the ROOM, the placard captions the WORK).
# truth: a lab that means to be an exhibit needs the voice of the wall label — the small certain card that names the work and says the one true sentence. The point does not need its XP shown; it needs to be captioned. The placard is the lab admitting it is a museum of ideas, and labelling itself accordingly.

## Wall placard — a museum caption card (title · meta · one-line intent).
##
## Built procedurally: a SubViewport draws the three text blocks, baked to a
## mipmapped ImageTexture (legible at VR distance) and mapped onto a thin
## framed card. Origin at card centre; front faces +Z (hang on a wall).

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Content")
@export var title: String = "THE POINT"
## Small line under the rule — sequence · date, gallery-label style.
@export var meta: String = "PRIMITIVES · 2036"
## One sentence of intent. Keep it short — a placard, not an essay.
@export var body: String = "Position without extension. Zero dimensions. The seed of all form."

@export_group("Look")
@export var card_width: float = 0.62
@export var card_height: float = 0.42
## How far the plaque stands off the wall (metres). Thicker = a more solid
## mounted plaque that sits clearly proud of the wall, not a thin sticker.
@export var card_depth: float = 0.06
@export var card_color: Color = Color(0.96, 0.96, 0.94)     # warm museum white
@export var ink_color: Color = Color(0.10, 0.11, 0.13)      # near-black label ink
@export var accent: Color = Color(0.227, 0.482, 1.0)        # rule + underline
@export var frame_color: Color = Color(0.16, 0.17, 0.20)

@export_group("Render")
@export var viewport_width: int = 1024
@export var viewport_height: int = 694

## Degrees added to the lab editor's wall-facing yaw. The placard's visible card
## is on the +Z side but it reads as the "back" to the wall-align convention, so
## it needs a half turn to face the room when stuck to a wall.
@export var wall_facing_offset_deg: float = 180.0

@export_group("Mounting")
## When true the placard is grabbable and SLIDES VERTICALLY along the wall:
## grab it, move your hand up/down, the card follows on its local Y only
## (the wall plane — local X/Z — stays fixed), clamped to [drag_min, drag_max]
## metres from its mounted start. Release leaves it where you let go.
@export var wall_draggable: bool = true
## Lowest the card may slide, relative to its placed Y (metres, negative = down).
@export var drag_min: float = -0.6
## Highest the card may slide, relative to its placed Y (metres).
@export var drag_max: float = 0.6

# ── State ─────────────────────────────────────────────────────────────

var _built: bool = false
var _base_y: float = 0.0          # the card's placed local Y (drag is relative to this)
var _drag_offset: float = 0.0     # current slide, clamped to [drag_min, drag_max]


func _ready() -> void:
	_read_metadata_overrides()
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		for c in get_children():
			c.queue_free()
		_built = false
		_build()


func _read_metadata_overrides() -> void:
	if has_meta("config_title"):
		title = str(get_meta("config_title"))
	if has_meta("config_meta"):
		meta = str(get_meta("config_meta"))
	if has_meta("config_body"):
		body = str(get_meta("config_body"))
	if has_meta("config_card_color"):
		card_color = _parse_color(str(get_meta("config_card_color")), card_color)
	if has_meta("config_ink_color"):
		ink_color = _parse_color(str(get_meta("config_ink_color")), ink_color)
	if has_meta("config_accent"):
		accent = _parse_color(str(get_meta("config_accent")), accent)


func _parse_color(raw: String, fallback: Color) -> Color:
	var parts := raw.split(",")
	if parts.size() >= 3:
		return Color(float(parts[0]), float(parts[1]), float(parts[2]),
			float(parts[3]) if parts.size() > 3 else 1.0)
	return fallback


# ── Build ─────────────────────────────────────────────────────────────

func _build() -> void:
	_built = true
	var depth := card_depth

	# SubViewport renders the label art once; baked to a mipmapped texture.
	var vp := SubViewport.new()
	vp.name = "PlacardViewport"
	vp.size = Vector2i(viewport_width, viewport_height)
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	vp.disable_3d = true
	add_child(vp)

	var canvas := _PlacardCanvas.new()
	canvas.name = "Canvas"
	canvas.title = title
	canvas.meta = meta
	canvas.body = body
	canvas.card_color = card_color
	canvas.ink_color = ink_color
	canvas.accent = accent
	canvas.size = Vector2(viewport_width, viewport_height)
	canvas.custom_minimum_size = Vector2(viewport_width, viewport_height)
	vp.add_child(canvas)

	# Card surface.
	var card := MeshInstance3D.new()
	card.name = "CardSurface"
	var qm := QuadMesh.new()
	qm.size = Vector2(card_width, card_height)
	card.mesh = qm
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = vp.get_texture()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	card.material_override = mat
	card.position = Vector3(0, 0, depth * 0.5 + 0.001)
	add_child(card)
	_bake_card_texture.call_deferred(vp, mat)

	# Backing slab.
	var backing := MeshInstance3D.new()
	backing.name = "Backing"
	var bm := BoxMesh.new()
	bm.size = Vector3(card_width, card_height, depth)
	backing.mesh = bm
	var back_mat := StandardMaterial3D.new()
	back_mat.albedo_color = card_color * 0.7
	back_mat.roughness = 0.9
	backing.material_override = back_mat
	add_child(backing)

	# Slim frame — four thin bars.
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = frame_color
	fmat.roughness = 0.5
	fmat.metallic = 0.1
	var ft := 0.018
	var hw := card_width * 0.5
	var hh := card_height * 0.5
	_add_box("FrameTop", Vector3(0, hh + ft * 0.5, 0), Vector3(card_width + ft * 2, ft, depth + 0.01), fmat)
	_add_box("FrameBot", Vector3(0, -hh - ft * 0.5, 0), Vector3(card_width + ft * 2, ft, depth + 0.01), fmat)
	_add_box("FrameL", Vector3(-hw - ft * 0.5, 0, 0), Vector3(ft, card_height, depth + 0.01), fmat)
	_add_box("FrameR", Vector3(hw + ft * 0.5, 0, 0), Vector3(ft, card_height, depth + 0.01), fmat)

	# Wall-mount drag: a grabbable grip covering the card that, while held,
	# slides the WHOLE placard vertically along the wall (local Y only).
	if wall_draggable and not Engine.is_editor_hint():
		_base_y = position.y
		_drag_offset = 0.0
		var grip := _PlacardGrip.new()
		grip.name = "SlideGrip"
		grip.placard = self
		grip.card_size = Vector2(card_width, card_height)
		grip.depth = depth
		add_child(grip)


func _add_box(n: String, pos: Vector3, size: Vector3, mat: StandardMaterial3D) -> void:
	var b := MeshInstance3D.new()
	b.name = n
	var bm := BoxMesh.new()
	bm.size = size
	b.mesh = bm
	b.material_override = mat
	b.position = pos
	add_child(b)


# Bake the SubViewport to a mipmapped ImageTexture once it has rendered, so
# the small body text stays legible at VR distance (a ViewportTexture has no
# mipmaps; thin text vanishes at range). Guarded against running detached.
func _bake_card_texture(vp: SubViewport, mat: StandardMaterial3D) -> void:
	if not is_instance_valid(vp) or not is_instance_valid(mat):
		return
	var tree := get_tree()
	if tree == null:
		return
	await tree.process_frame
	if not is_instance_valid(vp) or not is_instance_valid(mat):
		return
	await tree.process_frame
	if not is_instance_valid(vp) or not is_instance_valid(mat):
		return
	var img: Image = vp.get_texture().get_image()
	if img == null or img.is_empty():
		return
	img.generate_mipmaps()
	mat.albedo_texture = ImageTexture.create_from_image(img)
	if is_instance_valid(vp):
		vp.queue_free()


# Slide the placard vertically along the wall by `delta_y` metres (called by
# the grip while held). Clamped to [drag_min, drag_max] relative to the placed
# Y; only local Y changes, so the card stays flush on the wall plane.
func slide_by(delta_y: float) -> void:
	_drag_offset = clampf(_drag_offset + delta_y, drag_min, drag_max)
	position.y = _base_y + _drag_offset


# ── 2D canvas: the museum label typography ────────────────────────────
class _PlacardCanvas extends Control:
	var title: String = ""
	var meta: String = ""
	var body: String = ""
	var card_color: Color = Color.WHITE
	var ink_color: Color = Color.BLACK
	var accent: Color = Color.BLUE

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		# Card background.
		draw_rect(Rect2(Vector2.ZERO, size), card_color)
		var font := ThemeDB.fallback_font
		var margin: float = w * 0.07

		# TITLE — large caps, top-left.
		var title_px: int = int(h * 0.13)
		var title_y: float = margin + title_px
		draw_string(font, Vector2(margin, title_y), title.to_upper(),
			HORIZONTAL_ALIGNMENT_LEFT, w - margin * 2, title_px, ink_color)

		# Rule line under the title, tinted by the accent.
		var rule_y: float = title_y + title_px * 0.45
		draw_rect(Rect2(margin, rule_y, w - margin * 2, maxf(2.0, h * 0.006)), accent)

		# META — small, under the rule.
		var meta_px: int = int(h * 0.058)
		var meta_y: float = rule_y + meta_px * 1.6
		draw_string(font, Vector2(margin, meta_y), meta,
			HORIZONTAL_ALIGNMENT_LEFT, w - margin * 2, meta_px,
			ink_color.lerp(card_color, 0.35))

		# BODY — one sentence, wrapped, lower block.
		var body_px: int = int(h * 0.072)
		var body_y: float = meta_y + body_px * 1.9
		draw_multiline_string(font, Vector2(margin, body_y), body,
			HORIZONTAL_ALIGNMENT_LEFT, w - margin * 2, body_px, -1, ink_color)


# ── Wall-drag grip ────────────────────────────────────────────────────
# A handle-driven grab covering the card. Grab it and move your hand up/down;
# the grip reads the grab handle's offset projected onto the placard's local
# Y and slides the WHOLE placard along the wall (slide_by clamps + keeps the
# wall plane fixed). Same proven pattern as commons/interactables/slider_axis
# and every lever/slider in the lab — the handle tracks the hand freely while
# the driven node stays constrained to one axis.
class _PlacardGrip extends XRToolsInteractableHandleDriven:
	var placard: Node = null          # the WallPlacard to slide
	var card_size: Vector2 = Vector2(0.6, 0.4)
	var depth: float = 0.025
	var _accum: float = 0.0           # how far the placard has slid this grab

	func _ready() -> void:
		super()
		# Collision area covering the whole card so the hand can grab anywhere
		# on it (this node IS the interactable; XRToolsInteractable wants a
		# CollisionShape on itself).
		var cs := CollisionShape3D.new()
		cs.name = "CollisionShape3D"
		var box := BoxShape3D.new()
		box.size = Vector3(card_size.x, card_size.y, depth + 0.06)
		cs.shape = box
		add_child(cs)
		# An invisible handle the hand actually grabs; it moves with the hand,
		# and we read its displacement each frame.
		var handle := _make_handle()
		add_child(handle)

	func _make_handle() -> Node3D:
		var h := XRToolsInteractableHandle.new()
		h.name = "GripHandle"
		var hcs := CollisionShape3D.new()
		var hbox := BoxShape3D.new()
		hbox.size = Vector3(card_size.x * 0.9, card_size.y * 0.9, depth + 0.05)
		hcs.shape = hbox
		h.add_child(hcs)
		return h

	func _process(_delta: float) -> void:
		if grabbed_handles.is_empty() or placard == null:
			return
		# Read each held handle's displacement from its origin, projected onto
		# our local Y (the wall's vertical), drive the placard by that delta,
		# THEN re-centre the handle to IDENTITY. The re-centre is the key: it
		# consumes the displacement we just applied AND cancels any X/Z drift,
		# so the card never leaves the wall plane — only Y is honoured, and the
		# motion is incremental rather than compounding. (slider_axis gets this
		# for free because moving the slider carries the handle's origin; our
		# grip drives the PARENT placard, so we re-centre the handle by hand.)
		var offset_y := 0.0
		for item in grabbed_handles:
			var handle := item as XRToolsInteractableHandle
			if handle:
				var diff: Vector3 = handle.global_transform.origin - handle.handle_origin.global_transform.origin
				offset_y += diff.dot(global_transform.basis.y)
				handle.transform = Transform3D.IDENTITY   # re-centre: kill X/Z drift, consume Y
		offset_y /= float(grabbed_handles.size())
		if not is_zero_approx(offset_y) and placard.has_method("slide_by"):
			placard.slide_by(offset_y)
