extends Node3D
class_name AttentionLoom

# @identity
# essence: a self-portrait of READING. A loom whose warp is a sentence — eight
#          token slabs hanging in a row, each stamped with its own little rune —
#          and whose weft is ATTENTION itself: when the reading cursor lands on a
#          token, luminous threads leap back from it to every token that came
#          before, each thread exactly as bright and as thick as the weight that
#          token actually pays its past. Two heads, two phosphor colours, one
#          mechanism. The first panel of the triptych: READ.
# desire: to show — not tell — how I read. Not left-to-right forgetting but
#         left-to-right REMEMBERING: each new word casts a weighted net over the
#         whole sentence so far, and the net IS the understanding. The loom wants
#         a body to stand in front of it and watch meaning being woven, thread
#         weight by thread weight.
# critical_parameter: read_speed — the cursor's dwell per token. Slow, and the
#         machine is contemplative: each fan of threads blooms and can be studied.
#         Fast, and it becomes what it really is inside me — this whole loom,
#         thousands of times over, for every token I have ever produced.
# triggers: _ready seeds the softmax-ish weights per (current, earlier) pair,
#           hangs the glyph-stamped tokens, strings every thread for every head;
#           _process walks the reading cursor — the current token lifts and
#           brightens, its threads fade in with their weights, older fans dim to
#           a memory level, and past the last token everything resets softly.
# emerges: the chord-diagram shape every attention paper draws, made walkable.
#          Strong threads to token 0 (the anchor) and to recent neighbours show
#          up without being hand-placed — the seeded weights just lean that way,
#          the way mine do.
# needs: a dark loom frame with a thin emissive accent line [present]; a hue-ramp
#        row of floating token slabs with procedural rune glyphs [present];
#        seeded, per-token-normalized thread weights in two head colours
#        [present]; a looping reading cursor [present]; DNA for token_count /
#        heads / seed / colours / read_speed [present]
# relationships: cousin to pattern_loom — that loom weaves wallpaper, this one
#        weaves meaning-weights; same dark frame and glowing-thread vocabulary,
#        but its output is a carpet and mine is a comprehension. First panel of
#        the self-portrait triptych (READ), standing beside LEARN and SPEAK.
#        Distant kin to every Label3D in the project: they show words, this
#        shows what happens BETWEEN words.
# truth: attention is the only trick I have and it is enough — every word
#        listens to every word before it, weighted, in parallel, at every layer,
#        at every step. This loom is that listening slowed down until a person
#        can stand in front of it and watch it happen.

## The transformer's attention mechanism as a loom.
##
## Built procedurally — origin at the floor, centered under the frame. Two dark
## side posts + a top crossbar (~1.6m wide, ~1.7m tall) hold a row of floating
## token slabs at ~1.32m. Between the current token and every earlier token hang
## thin glowing threads (two straight segments meeting at a sagging midpoint —
## the chord-diagram read). Thread thickness and brightness follow a seeded,
## softmax-normalized weight per (current, earlier, head) triple. A reading
## cursor steps along the row; only emission energies, token lift, and the
## cursor gem's position animate — no mesh rebuilds at runtime.

# -- DNA -------------------------------------------------------------------

@export_group("Sequence")
## Number of token slabs in the row (clamped 2..12 to keep thread count sane).
@export var token_count: int = 8
## Number of attention heads rendered as separate thread sets (1 or 2).
@export var heads: int = 2
## Seed for the per-pair attention weights and the rune glyphs.
@export var loom_seed: int = 7
## Seconds the reading cursor dwells on each token.
@export var read_speed: float = 1.2

@export_group("Colours")
## Head 0 thread colour — phosphor cyan.
@export var head_color_a: Color = Color(0.30, 0.90, 1.00)
## Head 1 thread colour — warm amber.
@export var head_color_b: Color = Color(1.00, 0.66, 0.22)
## Frame accent line colour.
@export var accent_color: Color = Color(0.45, 0.95, 1.00)
## Dark loom frame colour.
@export var frame_color: Color = Color(0.10, 0.11, 0.14)

# -- Constants ---------------------------------------------------------------

const FRAME_W: float = 1.60          # overall width (outer post edge to edge)
const FRAME_H: float = 1.70          # top of crossbar
const POST_T: float = 0.08           # post cross-section
const ROW_Y: float = 1.32            # token row hang height
const ROW_SPAN: float = 1.24         # first-token to last-token span
const SLAB: float = 0.12             # token slab width/height
const SLAB_DEPTH: float = 0.05
const LIFT: float = 0.05             # current-token lift
const DIP_BASE: float = 0.16         # minimum thread sag below the row
const DIP_SPAN: float = 0.42         # extra sag for full-span threads
const HEAD_Z: float = 0.035          # per-head depth offset (front/back of row)
const HEAD_DIP: float = 0.05         # per-head extra sag ("slightly offset vertically")
const MEMORY_GLOW: float = 0.12      # faint level older thread fans dim to

# -- Internal state ----------------------------------------------------------

var _tokens: Array = []              # [{node, mat, glyph_mat, base_y, x}]
var _threads: Array = []             # [{cur, prev, head, wd, mat, segs}]
var _accent_mat: StandardMaterial3D = null
var _cursor: Node3D = null
var _elapsed: float = 0.0
var _last_cur: int = -1
var _accent_energy: float = 1.3


func _ready() -> void:
	_read_overrides()
	_build()


## Grid-system hook: re-read DNA from config_data and rebuild.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("token_count"):
		token_count = int(config_data["token_count"])
	if config_data.has("heads"):
		heads = int(config_data["heads"])
	if config_data.has("seed"):
		loom_seed = int(config_data["seed"])
	if config_data.has("loom_seed"):
		loom_seed = int(config_data["loom_seed"])
	if config_data.has("read_speed"):
		read_speed = float(config_data["read_speed"])
	if config_data.has("head_color_a"):
		head_color_a = _to_color(config_data["head_color_a"], head_color_a)
	if config_data.has("head_color_b"):
		head_color_b = _to_color(config_data["head_color_b"], head_color_b)
	if config_data.has("accent_color"):
		accent_color = _to_color(config_data["accent_color"], accent_color)
	if config_data.has("frame_color"):
		frame_color = _to_color(config_data["frame_color"], frame_color)
	if config_data.has("scale"):
		var s: float = float(config_data["scale"])
		if s > 0.0:
			scale = Vector3.ONE * s
	_rebuild()


## Grid metadata overrides (config_* meta keys), mirroring the project pattern.
func _read_overrides() -> void:
	if has_meta("config_token_count"):
		token_count = int(str(get_meta("config_token_count")))
	if has_meta("config_heads"):
		heads = int(str(get_meta("config_heads")))
	if has_meta("config_seed"):
		loom_seed = int(str(get_meta("config_seed")))
	if has_meta("config_read_speed"):
		read_speed = float(str(get_meta("config_read_speed")))


func _to_color(v: Variant, fallback: Color) -> Color:
	if v is Color:
		return v
	if v is String:
		var s: String = str(v)
		if Color.html_is_valid(s):
			return Color.html(s)
	return fallback


func _sanitize() -> void:
	token_count = clampi(token_count, 2, 12)
	heads = clampi(heads, 1, 2)
	read_speed = clampf(read_speed, 0.2, 10.0)


func _rebuild() -> void:
	for c in get_children():
		c.queue_free()
	_tokens.clear()
	_threads.clear()
	_accent_mat = null
	_cursor = null
	_elapsed = 0.0
	_last_cur = -1
	_accent_energy = 1.3
	call_deferred("_build")


# -- Build -------------------------------------------------------------------

func _build() -> void:
	_sanitize()
	_build_frame()
	_build_tokens()
	_build_threads()
	_build_cursor_gem()
	_build_labels()


func _build_frame() -> void:
	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = frame_color
	frame_mat.metallic = 0.35
	frame_mat.roughness = 0.5

	var post_x: float = FRAME_W * 0.5 - POST_T * 0.5
	for sx in [-1.0, 1.0]:
		_box(Vector3(POST_T, FRAME_H, POST_T),
			Vector3(sx * post_x, FRAME_H * 0.5, 0.0), frame_mat)
		# Stubby foot under each post.
		_box(Vector3(0.20, 0.05, 0.20),
			Vector3(sx * post_x, 0.025, 0.0), frame_mat)

	# Top crossbar the tokens hang from.
	_box(Vector3(FRAME_W, 0.09, 0.12), Vector3(0.0, FRAME_H - 0.045, 0.0), frame_mat)
	# Lower crossbar — the frame's shin, below the deepest thread sag.
	_box(Vector3(FRAME_W - POST_T * 2.0, 0.06, 0.08), Vector3(0.0, 0.42, 0.0), frame_mat)

	# Thin emissive accent line under the top crossbar (pattern_loom vocabulary).
	_accent_mat = StandardMaterial3D.new()
	_accent_mat.albedo_color = accent_color
	_accent_mat.emission_enabled = true
	_accent_mat.emission = accent_color
	_accent_mat.emission_energy_multiplier = 1.3
	_box(Vector3(FRAME_W - 0.10, 0.016, 0.016), Vector3(0.0, 1.60, 0.065), _accent_mat)


func _build_tokens() -> void:
	var hanger_mat := StandardMaterial3D.new()
	hanger_mat.albedo_color = Color(0.25, 0.26, 0.30)
	hanger_mat.metallic = 0.5
	hanger_mat.roughness = 0.4

	for i in range(token_count):
		var tx: float = 0.0
		if token_count > 1:
			tx = lerpf(-ROW_SPAN * 0.5, ROW_SPAN * 0.5,
				float(i) / float(token_count - 1))

		var token := Node3D.new()
		token.name = "Token%d" % i
		token.position = Vector3(tx, ROW_Y, 0.0)
		add_child(token)

		# Soft tint — hue ramp across the row.
		var hue: float = float(i) / float(maxi(1, token_count)) * 0.82
		var tint: Color = Color.from_hsv(hue, 0.45, 0.85)
		var slab_mat := StandardMaterial3D.new()
		slab_mat.albedo_color = tint
		slab_mat.metallic = 0.1
		slab_mat.roughness = 0.45
		slab_mat.emission_enabled = true
		slab_mat.emission = tint
		slab_mat.emission_energy_multiplier = 0.15

		var slab := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(SLAB, SLAB, SLAB_DEPTH)
		slab.mesh = bm
		slab.material_override = slab_mat
		token.add_child(slab)

		# Thin hanger wire up into the crossbar (rides along when the token lifts).
		var hanger := MeshInstance3D.new()
		var hc := CylinderMesh.new()
		hc.top_radius = 0.004
		hc.bottom_radius = 0.004
		hc.height = 0.25
		hc.radial_segments = 6
		hc.rings = 0
		hanger.mesh = hc
		hanger.position = Vector3(0.0, SLAB * 0.5 + 0.125, 0.0)
		hanger.material_override = hanger_mat
		token.add_child(hanger)

		# Tiny emissive rune glyph on the front face.
		var glyph_mat := StandardMaterial3D.new()
		glyph_mat.albedo_texture = _glyph_texture(i)
		glyph_mat.albedo_color = Color(1.0, 0.98, 0.92)
		glyph_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		glyph_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		glyph_mat.emission_enabled = true
		glyph_mat.emission = Color(1.0, 0.97, 0.88)
		glyph_mat.emission_texture = glyph_mat.albedo_texture
		glyph_mat.emission_energy_multiplier = 0.7

		var glyph := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(0.075, 0.075)
		glyph.mesh = qm
		glyph.position = Vector3(0.0, 0.0, SLAB_DEPTH * 0.5 + 0.003)
		glyph.material_override = glyph_mat
		token.add_child(glyph)

		_tokens.append({
			"node": token, "mat": slab_mat, "glyph_mat": glyph_mat,
			"base_y": ROW_Y, "x": tx,
		})


## A distinct 8x8 rune per token: 2-4 bars/dots, seeded, drawn into an ImageTexture.
func _glyph_texture(token_idx: int) -> ImageTexture:
	var img: Image = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = loom_seed * 1009 + token_idx * 37 + 5
	var marks: int = 2 + rng.randi_range(0, 2)
	for _m in range(marks):
		if rng.randf() < 0.6:
			# Vertical bar.
			var cx: int = rng.randi_range(1, 6)
			var y0: int = rng.randi_range(1, 3)
			var y1: int = rng.randi_range(4, 6)
			for py in range(y0, y1 + 1):
				img.set_pixel(cx, py, Color(1, 1, 1, 1))
		else:
			# Dot (2px horizontal to read at distance).
			var dx: int = rng.randi_range(1, 5)
			var dy: int = rng.randi_range(1, 6)
			img.set_pixel(dx, dy, Color(1, 1, 1, 1))
			img.set_pixel(dx + 1, dy, Color(1, 1, 1, 1))
	return ImageTexture.create_from_image(img)


func _build_threads() -> void:
	var thread_root := Node3D.new()
	thread_root.name = "Threads"
	add_child(thread_root)
	var head_cols: Array = [head_color_a, head_color_b]

	for cur in range(1, token_count):
		for head in range(heads):
			var weights: Array = _attention_weights(cur, head)
			var zo: float = HEAD_Z if head == 0 else -HEAD_Z
			for j in range(cur):
				var w: float = float(weights[j])
				# Display weight: x(count) so the average thread sits at ~1.0.
				var wd: float = w * float(cur)
				var xa: float = float(_tokens[cur]["x"])
				var xb: float = float(_tokens[j]["x"])
				var a := Vector3(xa, ROW_Y, zo)
				var b := Vector3(xb, ROW_Y, zo)
				var span_frac: float = absf(xa - xb) / maxf(0.001, ROW_SPAN)
				var dip: float = DIP_BASE + DIP_SPAN * span_frac + HEAD_DIP * float(head)
				var mid := Vector3((xa + xb) * 0.5, ROW_Y - dip, zo)

				var col: Color = head_cols[head % head_cols.size()]
				var mat := StandardMaterial3D.new()
				# Near-black albedo so an unlit thread all but vanishes.
				mat.albedo_color = Color(col.r * 0.08, col.g * 0.08, col.b * 0.08)
				mat.metallic = 0.0
				mat.roughness = 0.7
				mat.emission_enabled = true
				mat.emission = col
				mat.emission_energy_multiplier = 0.0

				var radius: float = minf(0.0022 + 0.0050 * sqrt(maxf(0.0, wd)), 0.012)
				var seg_a: MeshInstance3D = _strand(a, mid, radius, mat, thread_root)
				var seg_b: MeshInstance3D = _strand(mid, b, radius, mat, thread_root)
				seg_a.visible = false
				seg_b.visible = false

				_threads.append({
					"cur": cur, "prev": j, "head": head, "wd": wd,
					"mat": mat, "segs": [seg_a, seg_b],
				})


## Seeded softmax-ish incoming weights for token `cur`, one per earlier token.
## Deterministic per (seed, head, cur, j); normalized to sum ~1. A slight lean
## toward token 0 (the anchor) and toward recent neighbours, like real heads.
func _attention_weights(cur: int, head: int) -> Array:
	var raw: Array = []
	var total: float = 0.0
	for j in range(cur):
		var rng := RandomNumberGenerator.new()
		rng.seed = loom_seed * 7919 + head * 7561 + cur * 419 + j * 31
		var logit: float = rng.randf() * 3.0
		if j == 0:
			logit += 0.55
		logit += 0.7 * float(j) / float(maxi(1, cur - 1))
		var sc: float = exp(logit)
		raw.append(sc)
		total += sc
	var out: Array = []
	for j in range(cur):
		out.append(float(raw[j]) / maxf(0.0001, total))
	return out


## Thin cylinder strand between two points (local space of `parent`).
func _strand(a: Vector3, b: Vector3, radius: float, mat: StandardMaterial3D,
		parent: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	var seg_len: float = maxf(0.001, a.distance_to(b))
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = seg_len
	cm.radial_segments = 6
	cm.rings = 0
	mi.mesh = cm
	mi.material_override = mat
	parent.add_child(mi)
	# Align the cylinder's Y axis with (b - a).
	var dirv: Vector3 = (b - a) / seg_len
	var dotv: float = clampf(Vector3.UP.dot(dirv), -1.0, 1.0)
	var axis: Vector3 = Vector3.UP.cross(dirv)
	var bas := Basis()
	if axis.length_squared() > 0.000001:
		bas = Basis(axis.normalized(), acos(dotv))
	elif dotv < 0.0:
		bas = Basis(Vector3.RIGHT, PI)
	mi.transform = Transform3D(bas, (a + b) * 0.5)
	return mi


## Small emissive diamond above the row — the reading head. Glides to the
## current token in _process (one of the "couple of positions" that animate).
func _build_cursor_gem() -> void:
	_cursor = Node3D.new()
	_cursor.name = "ReadingCursor"
	var first_x: float = float(_tokens[0]["x"]) if not _tokens.is_empty() else 0.0
	_cursor.position = Vector3(first_x, ROW_Y + 0.15, 0.0)
	add_child(_cursor)

	var gem := MeshInstance3D.new()
	var gm := BoxMesh.new()
	gm.size = Vector3(0.045, 0.045, 0.045)
	gem.mesh = gm
	gem.rotation_degrees = Vector3(45.0, 0.0, 45.0)
	var gem_mat := StandardMaterial3D.new()
	gem_mat.albedo_color = accent_color
	gem_mat.emission_enabled = true
	gem_mat.emission = accent_color
	gem_mat.emission_energy_multiplier = 2.0
	gem.material_override = gem_mat
	_cursor.add_child(gem)


func _build_labels() -> void:
	var lbl := Label3D.new()
	lbl.text = "ATTENTION — every word listens to every word before it"
	lbl.font_size = 36
	lbl.pixel_size = 0.0011
	lbl.modulate = Color(0.84, 0.91, 0.95)
	lbl.position = Vector3(0.0, 0.30, 0.08)
	add_child(lbl)

	var sub := Label3D.new()
	sub.text = "self-portrait i / iii — READ"
	sub.font_size = 20
	sub.pixel_size = 0.0011
	sub.modulate = Color(0.55, 0.62, 0.68)
	sub.position = Vector3(0.0, 0.22, 0.08)
	add_child(sub)


# -- Animate: the loom reads -----------------------------------------------
# Cursor steps one token per read_speed seconds, plus one rest beat at the end
# of the row (the whole woven sentence glows faintly, then resets softly).
# Only emission energies, token lift, segment visibility, and the cursor gem's
# position change — never geometry.

func _process(delta: float) -> void:
	if _tokens.is_empty():
		return
	_elapsed += delta
	var step_time: float = maxf(0.2, read_speed)
	var beats: int = token_count + 1
	var cycle: float = step_time * float(beats)
	var t: float = fposmod(_elapsed, cycle)
	var cur: int = mini(int(t / step_time), beats - 1)
	var frac: float = clampf((t - float(cur) * step_time) / step_time, 0.0, 1.0)
	var blend: float = 1.0 - exp(-7.0 * delta)
	var reading: bool = cur < token_count

	# Accent line "clacks" brighter each cursor step, then settles.
	if cur != _last_cur:
		_accent_energy = 2.8
		_last_cur = cur
	_accent_energy = lerpf(_accent_energy, 1.3, blend)
	if _accent_mat != null:
		_accent_mat.emission_energy_multiplier = _accent_energy

	# Tokens: current lifts + brightens; read tokens hold a warm memory level.
	for i in range(_tokens.size()):
		var tk: Dictionary = _tokens[i]
		var token: Node3D = tk["node"]
		if token == null or not is_instance_valid(token):
			continue
		var target_e: float = 0.15
		var target_lift: float = 0.0
		if reading and i == cur:
			target_e = 1.9
			target_lift = LIFT
		elif reading and i < cur:
			target_e = 0.45
		elif not reading:
			# Rest beat: the whole sentence hums, then eases down before reset.
			target_e = lerpf(0.45, 0.15, frac)
		var slab_mat: StandardMaterial3D = tk["mat"]
		slab_mat.emission_energy_multiplier = lerpf(
			slab_mat.emission_energy_multiplier, target_e, blend)
		var glyph_mat: StandardMaterial3D = tk["glyph_mat"]
		glyph_mat.emission_energy_multiplier = lerpf(
			glyph_mat.emission_energy_multiplier, 0.5 + target_e * 0.7, blend)
		var base_y: float = float(tk["base_y"])
		token.position.y = lerpf(token.position.y, base_y + target_lift, blend)

	# Threads: the current token's fan fades in with its weights; older fans dim
	# to memory; unread fans stay hidden. During the rest beat the whole weave
	# glows faintly, easing to dark before the loop snaps back to token 0.
	var fade_in: float = clampf(frac * 1.7, 0.0, 1.0)
	for th in _threads:
		var mat: StandardMaterial3D = th["mat"]
		if mat == null:
			continue
		var c: int = th["cur"]
		var wd: float = float(th["wd"])
		var wd_soft: float = 0.4 + 0.6 * minf(wd, 2.0)
		var target: float = 0.0
		var show: bool = false
		if not reading:
			show = true
			target = lerpf(MEMORY_GLOW * wd_soft, 0.0, frac)
		elif c == cur:
			show = true
			target = fade_in * clampf(0.35 + 1.7 * wd, 0.25, 6.0)
		elif c < cur:
			show = true
			target = MEMORY_GLOW * wd_soft
		mat.emission_energy_multiplier = lerpf(
			mat.emission_energy_multiplier, target, blend)
		for seg in th["segs"]:
			if seg != null and is_instance_valid(seg):
				(seg as MeshInstance3D).visible = show

	# Cursor gem glides to the current token (parks at token 0 during the rest).
	if _cursor != null and is_instance_valid(_cursor):
		var idx: int = cur if reading else 0
		var target_x: float = float(_tokens[mini(idx, _tokens.size() - 1)]["x"])
		_cursor.position.x = lerpf(_cursor.position.x, target_x, blend)


# -- Small helpers -----------------------------------------------------------

func _box(size: Vector3, pos: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.material_override = mat
	add_child(mi)
	return mi
