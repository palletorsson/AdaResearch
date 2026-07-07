extends Node3D
class_name Chalkboard

# @identity
# essence: a framed blackboard with hand-chalked scientific notation on it — the lab's teaching surface, rendered in Turing's hand. A SubViewport runs a ScribbleControl that draws real math (α+β+γ=180°, a²+b²=c², Heron's formula…) as wobbly chalk strokes with no font, then that 2D canvas is mapped onto a 3D board mesh with a dark wooden frame and a chalk tray. Where the TextMesh whiteboard could only print, this one SCRAWLS — every stroke jittered, doubled, alive, as if someone just stepped away from the board mid-derivation.
# desire: it wants to be the moment the concept is worked out by a hand, not stated by a machine. It wants chalk dust and the slight wrongness of a real letter. It wants the player to feel they walked into the room just after Turing finished writing, the proof still on the board, the science legible AND human. It wants explanation to carry a body.
# critical_parameter: lines — the array of formula strings, each auto-fit and stacked. Change lines and the board teaches a different concept (the script is the same; only the chalk changes). board_color + ink_color set blackboard-green/chalk-white by default but can be whiteboard or any surface. The scribble's wobble is deterministic, so the same formula always lands the same way — a fixed hand, not random noise.
# triggers: _ready builds the SubViewport + ScribbleControl, maps its texture onto the board quad, and frames it; apply_grid_config rebuilds (and re-chalks) on DNA change. The board holds still — chalk does not animate.
# emerges: hung in a concept's lab it becomes the chalkboard the gems are derived on — the scientific register beside the felt artifacts (point/line/triangle salons). A row of chalkboards across a sequence reads as a lecture worked out wall by wall. It is the infoboards_3d base turned into Turing's blackboard.
# needs: a 2D scribble canvas [SubViewport + ScribbleControl, present]; a board surface to carry it [quad + ViewportTexture, present]; a frame + chalk tray so it reads as a blackboard [present]; real notation, hand-drawn [the scribble alphabet, present]
# relationships: the scientific-register companion to every concept salon; successor to the TextMesh `triangle_whiteboard` (this scrawls where that printed); built on `scribble_control.gd` (the stroke renderer) and the `infoboards_3d` 2D-in-3D pipeline; template for point/line/every concept board (swap the lines).
# truth: a curriculum needs a surface where the answer is written down — and a queer-humanist curriculum needs it written by a HAND, not typeset by a machine that pretends mathematics fell from the sky. Turing wrote his proofs in chalk, crossing things out, getting the letters slightly wrong. To put real notation on the lab wall in a wobbling hand is to insist that even the flattest fact (180°) was thought by somebody, in a body, at a board.

## Chalkboard — hand-chalked scientific notation on a 3D board.
##
## Built procedurally. A SubViewport hosts a ScribbleControl; its texture
## is mapped onto a framed board quad. Origin at board centre; front
## faces +Z (hang on a wall). NOTE: the chalk lives in a ViewportTexture,
## so it shows in-engine + in captures; a GLB export carries the board
## mesh but not the live texture.

const SCRIBBLE := preload("res://commons/primitives/scribble/scribble_control.gd")

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Board")
@export var board_width: float = 1.6
@export var board_height: float = 1.12
@export var frame_color: Color = Color(0.22, 0.15, 0.10)   # dark wood frame
@export var board_color: Color = Color(0.10, 0.16, 0.13)   # blackboard green
@export var ink_color: Color = Color(0.93, 0.95, 0.90)     # chalk

@export_group("Content")
## "" = formulas only; "triangle" = labelled triangle diagram on the
## left, formulas on the right.
@export var diagram: String = "triangle"
@export var lines: PackedStringArray = PackedStringArray([
	"α + β + γ = 180°",
	"a² + b² = c²",
	"A = ½ a b",
	"A = √(s(s−a)(s−b)(s−c))",
])
@export var glyph_height: float = 130.0
# Higher-res viewport so the chalk text keeps enough pixels to stay legible
# at VR viewing distance (it was washing out to symbols-only across the room).
@export var viewport_width: int = 2048
@export var viewport_height: int = 1434

# ── State ─────────────────────────────────────────────────────────────

var _built: bool = false


func _ready() -> void:
	_read_metadata_overrides()
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		# Detach IMMEDIATELY (remove_child) before queue_free. queue_free
		# defers to end-of-frame, so the OLD board children (BoardSurface,
		# Backing, Frame…) would still be in the tree when _build() re-adds
		# nodes with the SAME names — Godot then auto-renames the NEW ones to
		# @MeshInstance3D@NNNN, and the deferred texture-bake races against
		# the old BoardSurface being freed, leaving the rebuilt board on the
		# no-mipmap live ViewportTexture (the VR "text vanishes" bug). Removing
		# first guarantees a clean rebuild. Same fix as palm_scanner/lab_room.
		for c in get_children():
			remove_child(c)
			c.queue_free()
		_built = false
		_build()


func _read_metadata_overrides() -> void:
	if has_meta("config_board_width"):
		board_width = float(str(get_meta("config_board_width")))
	if has_meta("config_board_height"):
		board_height = float(str(get_meta("config_board_height")))
	if has_meta("config_board_color"):
		board_color = _parse_color(str(get_meta("config_board_color")), board_color)
	if has_meta("config_ink_color"):
		ink_color = _parse_color(str(get_meta("config_ink_color")), ink_color)
	# lines passed as a single string with "|" separators (token-friendly).
	if has_meta("config_lines"):
		var raw := str(get_meta("config_lines"))
		var parts := raw.split("|")
		var arr := PackedStringArray()
		for p in parts:
			if str(p).strip_edges() != "":
				arr.append(str(p))
		if arr.size() > 0:
			lines = arr


func _parse_color(raw: String, fallback: Color) -> Color:
	var parts := raw.split(",")
	if parts.size() >= 3:
		return Color(float(parts[0]), float(parts[1]), float(parts[2]),
			float(parts[3]) if parts.size() > 3 else 1.0)
	return fallback


# ── Build ─────────────────────────────────────────────────────────────

func _build() -> void:
	_built = true
	var depth := 0.05

	# SubViewport that renders the scribble canvas ONCE. The chalk never
	# animates, so we let the viewport draw a single frame, then BAKE it to a
	# static ImageTexture WITH MIPMAPS and discard the live viewport.
	#
	# Why bake: a ViewportTexture has NO mipmaps. On a flat monitor that's
	# fine, but in VR at an oblique angle each thin chalk stroke maps to a
	# sub-pixel and, with no mipmaps, the GPU point-samples — so thin letters
	# fall BETWEEN texels and vanish entirely (only heavy marks like =,(,)
	# survive). That's the "symbols but no text" bug. A baked ImageTexture
	# with generated mipmaps fades thin strokes to faint gray at distance
	# instead of dropping them, so the words stay legible at any range.
	var vp := SubViewport.new()
	vp.name = "ScribbleViewport"
	vp.size = Vector2i(viewport_width, viewport_height)
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	vp.disable_3d = true
	add_child(vp)

	var ctrl: Control = SCRIBBLE.new()
	ctrl.name = "Scribble"
	ctrl.set("lines", lines)
	ctrl.set("diagram", diagram)
	ctrl.set("glyph_height", glyph_height)
	ctrl.set("board_color", board_color)
	ctrl.set("ink_color", ink_color)
	ctrl.set("draw_board", true)
	ctrl.size = Vector2(viewport_width, viewport_height)
	ctrl.custom_minimum_size = Vector2(viewport_width, viewport_height)
	vp.add_child(ctrl)

	# Board quad. The texture is baked in deferred (after the viewport has
	# rendered its one frame); until then the board shows the live viewport
	# texture so it's never blank.
	var board := MeshInstance3D.new()
	board.name = "BoardSurface"
	var qm := QuadMesh.new()
	qm.size = Vector2(board_width, board_height)
	board.mesh = qm
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = vp.get_texture()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	board.material_override = mat
	board.position = Vector3(0, 0, depth * 0.5 + 0.001)
	add_child(board)
	# Bake the viewport → mipmapped ImageTexture once it has drawn.
	_bake_board_texture.call_deferred(vp, mat)

	# Backing slab behind the quad (so it's solid from behind).
	var backing := MeshInstance3D.new()
	backing.name = "Backing"
	var bm := BoxMesh.new()
	bm.size = Vector3(board_width, board_height, depth)
	backing.mesh = bm
	var back_mat := StandardMaterial3D.new()
	back_mat.albedo_color = board_color * 0.6
	back_mat.roughness = 0.9
	backing.material_override = back_mat
	add_child(backing)

	# Frame — four wooden bars + a chalk tray.
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = frame_color
	fmat.roughness = 0.6
	fmat.metallic = 0.05
	var ft := 0.06
	var hw := board_width * 0.5
	var hh := board_height * 0.5
	_add_box("FrameTop", Vector3(0, hh + ft * 0.5, 0), Vector3(board_width + ft * 2, ft, depth + 0.02), fmat)
	_add_box("FrameBot", Vector3(0, -hh - ft * 0.5, 0), Vector3(board_width + ft * 2, ft, depth + 0.02), fmat)
	_add_box("FrameL", Vector3(-hw - ft * 0.5, 0, 0), Vector3(ft, board_height, depth + 0.02), fmat)
	_add_box("FrameR", Vector3(hw + ft * 0.5, 0, 0), Vector3(ft, board_height, depth + 0.02), fmat)
	_add_box("ChalkTray", Vector3(0, -hh - ft - 0.02, depth * 0.5 + 0.05), Vector3(board_width * 0.7, 0.035, 0.10), fmat)


# Wait for the SubViewport to finish its one render, then snapshot it into a
# static ImageTexture WITH mipmaps and point the board material at it. The
# live viewport is freed afterward — the chalk is fixed, so there's no reason
# to keep rendering it, and the mipmapped still is what keeps thin strokes
# legible in VR (a ViewportTexture has no mipmaps; thin glyphs vanish at
# distance/angle). Falls back to leaving the live texture if the grab fails.
func _bake_board_texture(vp: SubViewport, mat: StandardMaterial3D) -> void:
	if not is_instance_valid(vp) or not is_instance_valid(mat):
		return
	# Wait for frames so the Control's _draw() has rendered into the viewport.
	# This runs deferred, by which point an apply_grid_config rebuild may have
	# already detached this chalkboard from the tree — get_tree() is null on a
	# detached node, so DON'T await on it. Wait on the SceneTree we capture up
	# front, and re-check validity after each await (the node/viewport can be
	# freed mid-wait). Bail cleanly if anything went away — the live
	# ViewportTexture stays as a (no-mipmap) fallback.
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
		return  # keep the live ViewportTexture as a fallback
	img.generate_mipmaps()
	var baked := ImageTexture.create_from_image(img)
	mat.albedo_texture = baked
	# Drop the live viewport — its job is done.
	if is_instance_valid(vp):
		vp.queue_free()


func _add_box(n: String, pos: Vector3, size: Vector3, mat: StandardMaterial3D) -> void:
	var b := MeshInstance3D.new()
	b.name = n
	var bm := BoxMesh.new()
	bm.size = size
	b.mesh = bm
	b.material_override = mat
	b.position = pos
	add_child(b)
