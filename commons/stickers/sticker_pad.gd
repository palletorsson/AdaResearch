extends Node3D
## THE STICKER PAD: the inventory's worn tool for sticking and peeling (the same WORN contract as the tape roll,
## commons/artifacts/tape_roll/roll.gd: wear / put_away / fire_worn / release_worn / apply_config /
## apply_grid_config, worn_on, worn_active), so the inventory's wand forwards the trigger to it with no change to the
## wand: in VR the right controller's trigger (InventoryPrism -> InventoryWand.press / release), on the desktop the left
## mouse button or F through the camera (sync_worn(camera, MiniHolder) makes the camera `worn_on`).
##
##   aim     along worn_on's -Z, up to `reach` (4 m), past the UI (layer 23) and held things (layer 17); the pad draws
##           its own ghost (the selected sticker, translucent, where it would go; red when refused) and aim line,
##           because the wand draws none for a worn item
##   tap     (< 0.3 s) on a surface: STICK - an `add` op through StickerData; the host is what the hit belongs to: a
##           node with meta sticker_host first (the board, the bench), else a Void work (its mount), else a Void
##           floor (its walls and slab), else refused. A board takes a sticker on its FACE only (n = +Z, at.z = 0):
##           a hit on its back is refused, "THE BACK OF THE BOARD" (stickers.ts settle: a board has no back)
##   hold    (>= 0.3 s) on a sticker: PEEL it - a peel is an event; the sticker stays as residue, with who peeled
##   tap at nothing: the next design of the sheet
##   turn    VR: the right wrist's twist (twice the roll, 15 degree steps, as the prism turns a prefab); desktop: Q / E
##           (Shift: a quarter turn), counted from the CONTRACT's zero - stickers.ts's one meaning of a turn (refUp:
##           the host's +Y laid on the surface, or its -Z on a surface facing up or down by more than 45 degrees) -
##           against the rounded normal the op carries, as three.js's newPose counts it; a design that may not turn
##           freely (the pink triangle snaps, a fixed one never turns) keeps only the quarter turns of that frame. So a
##           first stick reads the same turn in every medium (the pad's own start - world up laid on anything steeper
##           than |n.y| < 0.9, away from the eye on a top - put the pink triangle on a sideways slope 53 degrees from
##           vertical at turn 90, and on the bench box's top at 90 or 0 by where the person stood, where three.js
##           starts it at 0)
##   ghost   where the sticker would go, as the server will store it; on a body the layer knows (the bench's sphere
##           and cylinder, a box, the board) printed on it like the sticker itself, cut at a face's edge
##           (sticker_layer.gd)
##
## config: sheet (a sheet id of designs.json; "" = every design), sticker (the design to start from), size ("design" =
## the design's own size_m, or metres), reach (m). Who sticks is StickerData.by ("vr:" + a short device name).

const StickerData := preload("res://commons/stickers/sticker_data.gd")
const StickerWorld := preload("res://commons/stickers/sticker_world.gd")
const StickerLayer := preload("res://commons/stickers/sticker_layer.gd")
const SURFACES := 0xFFFFFFFF & ~((1 << 17) | (1 << 19))   # InventoryHand.SURFACES: not the hands, not the body
const MASK := SURFACES & ~(1 << 22) & ~(1 << 16)          # nor the UI (layer 23: the prism's faces), nor held things (17)
const HOLD := 0.3                                         # InventoryWand.HOLD: shorter is a tap
const GHOST_LIFT := 0.008
const PREVIEW_AT := 1.2                                   # aiming at nothing, the ghost shows this far ahead
const TWIST_DEAD := 8.0                                   # InventoryPrism.TWIST_DEAD
const TURN_STEP := 15.0
const TINT_OK := Color(1, 1, 1, 0.62)
const TINT_REFUSED := Color(1.0, 0.31, 0.41, 0.6)
const TINT_IDLE := Color(1, 1, 1, 0.4)
const LINE_OK := Color("ee478f")
const LINE_REFUSED := Color("ff5068")
const LABEL_PX := 0.0007                                  # the ghost's words at arm's length (28 px font: 2 cm)
const LABEL_NEAR := 0.9                                   # metres from the eye at which they are LABEL_PX
const LABEL_GROW_MOST := 5.0

signal stuck(sticker: Dictionary)
signal peeled(id: String)
signal refused(reason: String)
signal stepped(design: String)

@export var sheet := "starter"
@export var sticker := ""
@export var size := "design"
@export var reach := 4.0
@export var turn := 0.0

var worn_on: Node3D = null
var worn_active := true
var notice := ""
var data: Node = null
var aim: Dictionary = {}            # what the aim meets now (_aim_state)
var extra_exclude: Array = []       # RIDs a test (or a host) wants the ray to look past
var _pressed := false
var _press_t := 0.0
var _press_aim: Dictionary = {}
var _consumed := false
var _model: Node3D = null
var _ghost: MeshInstance3D = null
var _ghost_quad: QuadMesh = null
var _ghost_arc: ArrayMesh = null     # the ghost laid on a known body (rebuilt when what it shows changes)
var _ghost_arc_sig := ""
var _ghost_laid := false             # whether the ghost is _ghost_arc (laid) or the quad, for _ghost_arc_sig
var _ghost_mat: StandardMaterial3D = null
var _label: Label3D = null
var _line: MeshInstance3D = null
var _line_mat: StandardMaterial3D = null
var _show_model := true

func apply_grid_config(config: Dictionary) -> void:
	sheet = str(config.get("sheet", sheet))
	sticker = str(config.get("sticker", sticker))
	if config.has("size"):
		size = str(config.get("size"))
	reach = clampf(float(config.get("reach", reach)), 0.5, 12.0)
	if is_inside_tree():
		_refresh_model()

func _ready() -> void:
	var cfg := {}
	for key in ["sheet", "sticker", "size", "reach"]:
		if has_meta("config_" + key):
			cfg[key] = get_meta("config_" + key)
	if not cfg.is_empty():
		apply_grid_config(cfg)
	data = StickerData.get_or_create(get_tree())
	_build_model()

## A knob turned while the pad is worn (the inventory's live config).
func apply_config(config: Dictionary) -> void:
	apply_grid_config(config)
	_cancel()

## WEAR: on the controller (or the desktop camera), small, no collision; the aim comes from there. Called again with the
## same controller it only shows itself; with another it moves over.
func wear(ctrl: Node3D, scale_factor := 0.4, show_model := true) -> void:
	_cancel()
	if get_parent() != ctrl:
		if get_parent() != null:
			get_parent().remove_child(self)
		ctrl.add_child(self)
	worn_on = ctrl
	worn_active = true
	visible = true
	_show_model = show_model
	if _model != null:
		_model.visible = show_model
	transform = Transform3D(Basis().scaled(Vector3.ONE * scale_factor), Vector3(0, .045, .09))

## Put away (another item chosen, or the bracelet out of PLACE): hidden and inert; the stickers stay where they are.
func put_away() -> void:
	_cancel()
	worn_active = false
	visible = false
	_hide_aim()

## The trigger pressed while worn: the aim is taken now; a release within HOLD is a tap, a longer press a peel.
func fire_worn() -> void:
	if worn_on == null or not worn_active or _pressed:
		return
	_pressed = true
	_press_t = 0.0
	_consumed = false
	_press_aim = _aim_state()

func release_worn() -> void:
	if not _pressed:
		return
	_pressed = false
	if _consumed:
		return
	_consumed = true
	_tap(_press_aim)

## The grip (if a hook forwards it): peel what the aim points at, now.
func grip_worn() -> bool:
	if worn_on == null or not worn_active:
		return false
	var st := _aim_state()
	if (st.target as Dictionary).is_empty():
		_refuse("NO STICKER UNDER THE AIM TO PEEL")
		return false
	return _peel(str(st.target.id))

func current_design() -> String:
	if data == null:
		return sticker
	var list: Array = data.sheet_designs(sheet)
	if sticker != "" and (list.has(sticker) or not data.design(sticker).is_empty()):
		return sticker
	return str(list[0]) if not list.is_empty() else ""

## The next (d = 1) or previous design of the sheet.
func step(d := 1) -> String:
	var list: Array = data.sheet_designs(sheet) if data != null else []
	if list.is_empty():
		return sticker
	sticker = str(list[posmod(list.find(current_design()) + d, list.size())])
	_refresh_model()
	stepped.emit(sticker)
	return sticker

func _physics_process(delta: float) -> void:
	if worn_on == null or not worn_active or not is_inside_tree() or data == null:
		_hide_aim()
		return
	if worn_on is XRController3D:
		turn = _wrist_yaw(worn_on)
	aim = _aim_state()
	_draw(aim)
	if _pressed:
		_press_t += delta
		if not _consumed and _press_t >= HOLD:
			_consumed = true
			_hold(_press_aim)

func _unhandled_input(event: InputEvent) -> void:
	# the desktop's turn; in VR the wrist turns it
	if worn_on == null or not worn_active or worn_on is XRController3D or not event is InputEventKey:
		return
	var k := event as InputEventKey
	if not k.pressed or k.echo or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if k.keycode == KEY_Q or k.keycode == KEY_E:
		turn = wrapf(turn + (90.0 if k.shift_pressed else TURN_STEP) * (1.0 if k.keycode == KEY_Q else -1.0), -180.0, 180.0)
		get_viewport().set_input_as_handled()

# ==== aiming ====

## What the aim meets: {origin, dir, end, hit, ok, reason, host, frame, surface, pose, at, n, up, size, size_w, design,
## target}. `pose` is the sticker's {at, n, up} in the host's frame exactly as the op will carry it and the truth will
## hold it (StickerData.server_pose: rounded, settled, a non-free design snapped); at / n / up are the same as vectors,
## size is in the host's units; `surface` is the host body's analytic shape when the layer knows it (the bench's
## sphere and cylinder, the box of a board's or a bench primitive's collider: sticker_layer.gd surface_of); `target`
## is the sticker on that host under the aim (the top one), {} when none.
func _aim_state() -> Dictionary:
	var origin := worn_on.global_position
	var dir := -worn_on.global_basis.z.normalized()
	var st := {"origin": origin, "dir": dir, "end": origin + dir * reach, "hit": {}, "ok": false, "reason": "", "target": {}, "design": current_design(), "surface": {}}
	var q := PhysicsRayQueryParameters3D.create(origin, origin + dir * reach, MASK)
	q.exclude = _exclude()
	q.hit_from_inside = false
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		st.reason = "TAP: NEXT STICKER"
		return st
	st.hit = hit
	st.end = hit.position
	var found := StickerWorld.host_at(hit.collider)
	if not bool(found.ok):
		st.reason = str(found.reason)
		return st
	if bool(found.get("void", false)) and get_tree().get_first_node_in_group("sticker_world") == null:
		st.reason = "THE VOID'S STICKERS ARE NOT ON HERE"
		return st
	var frame: Transform3D = found.frame
	var p: Vector3 = hit.position
	var nw: Vector3 = Vector3(hit.normal).normalized()
	var at_l := frame.affine_inverse() * p
	# the surface's normal in the host frame: a normal goes by the basis's transpose (right for a scaled frame too)
	var n_l := (frame.basis.transposed() * nw).normalized()
	var host: Dictionary = found.host
	if str(host.get("kind", "")) == "board" and n_l.z < 0.99:
		# a board has no back to stick on (stickers.ts settle: n = +Z): the Face body's box answers from behind too
		st.reason = "THE BACK OF THE BOARD" if n_l.z < 0.0 else "THE EDGE OF THE BOARD"
		return st
	st.host = host
	st.frame = frame
	var node: Variant = found.get("node")
	st.surface = StickerLayer.surface_of(node, host)
	st.target = _sticker_under(host, at_l, st.surface, n_l)
	var d: Dictionary = data.design(str(st.design))
	if d.is_empty():
		st.reason = "NO STICKER ON THIS SHEET"
		return st
	# the person's turn (the wrist, or Q / E; in quarter turns for a design that may not turn freely) from the
	# contract's zero (stickers.ts refUp: the host's +Y laid on the surface, its -Z on one facing up or down by more
	# than 45 degrees) against the normal the truth will hold - three.js's newPose, so a first stick reads the same
	# turn in every medium; then the pose the server will store (on a board n = +Z and at.z = 0, a non-free design
	# snapped to the quarter turns of the host frame: stickers.ts turnOf / allowedUp)
	var n_kept: Array = StickerData.server_pose(host, at_l, n_l, StickerData.ref_up(n_l), null).n
	var up_l: Array = StickerData.up_at_turn(n_kept, StickerData.allowed_turn(d, turn))
	var pose: Dictionary = StickerData.server_pose(host, at_l, n_l, up_l, d)
	var b := StickerData.basis(StickerData.v3(pose.n), StickerData.v3(pose.up))
	# a host frame may be scaled (a scaled work): sizes are in its units, as paper on it would be
	var along_right: Vector3 = frame.basis * Vector3(b.right)
	var along_up: Vector3 = frame.basis * Vector3(b.up)
	var scale_here: float = (along_right.length() + along_up.length()) / 2.0
	st.size_w = _size_for(d)
	st.size = st.size_w / maxf(scale_here, 1e-6)
	st.pose = pose
	st.at = StickerData.v3(pose.at)
	st.n = b.n
	st.up = b.up
	st.ok = true
	return st

func _exclude() -> Array:
	var out: Array = extra_exclude.duplicate()
	var body := get_tree().get_first_node_in_group("player_body")
	if body is CollisionObject3D:
		out.append((body as CollisionObject3D).get_rid())
	return out

## Up on a surface that is no host (the ghost refused, or aimed at nothing; a sticker's up is the contract's, above): on a
## wall world up laid on it; on a floor or a ceiling (|n.y| > POLE, as refUp splits them) away from the head.
func _up_on_surface(p: Vector3, nw: Vector3) -> Vector3:
	if absf(nw.y) <= StickerData.POLE:
		var u := Vector3.UP - nw * nw.dot(Vector3.UP)
		if u.length() > 1e-4:
			return u.normalized()
	var cam := get_viewport().get_camera_3d()
	var away: Vector3 = p - (cam.global_position if cam != null else worn_on.global_position)
	away -= nw * nw.dot(away)
	if away.length() < 1e-4:
		away = -worn_on.global_basis.z
		away -= nw * nw.dot(away)
	return away.normalized() if away.length() > 1e-4 else Vector3.FORWARD

func _size_for(d: Dictionary) -> float:
	var v := float(size) if size.is_valid_float() else 0.0
	return clampf(v, 0.01, 4.0) if v > 0.0 else float(d.get("size_m", 0.2))

## The top sticker of this host that holds the point: on a body the layer knows, one whose print covers it (its
## projector's box, on a surface facing it: sticker_layer.gd holds, with the hit's normal n_l); elsewhere one whose quad
## holds it, within a thickness (a quad on a body that is not flat).
func _sticker_under(host: Dictionary, at_l: Vector3, surface: Dictionary = {}, n_l := Vector3.ZERO) -> Dictionary:
	var best := {}
	var best_z := -INF
	for s0 in data.stickers_on(StickerData.host_key(host)):
		var s := StickerLayer.drawn_as(s0, host)   # where it is drawn (a board sticker on the face)
		if str(s.get("state", "on")) != "on":
			continue
		var d: Dictionary = data.design(str(s.get("design", "")))
		if d.is_empty():
			continue
		var size_l := float(s.get("size", 0.2))
		var e := StickerData.extent(d, size_l)
		var inside := false
		if not surface.is_empty():
			inside = StickerLayer.holds(s, d, at_l, surface, n_l)
		else:
			var b := StickerData.basis(StickerData.v3(s.get("n")), StickerData.v3(s.get("up")))
			var rel: Vector3 = at_l - StickerData.v3(s.get("at"))
			inside = absf(rel.dot(b.right)) <= e.x / 2.0 and absf(rel.dot(b.up)) <= e.y / 2.0 and absf(rel.dot(b.n)) <= maxf(0.03, 0.35 * size_l)
		if inside and float(s.get("z", 0)) > best_z:
			best = s
			best_z = float(s.get("z", 0))
	return best

# ==== doing ====

func _tap(st: Dictionary) -> void:
	if (st.hit as Dictionary).is_empty():
		step(1)
		return
	if not bool(st.ok):
		_refuse(str(st.reason))
		return
	var s: Dictionary = data.stick(str(st.design), st.host, st.pose.at, st.pose.n, st.pose.up, float(st.size))
	if s.is_empty():
		_refuse("NOT STUCK: " + str(data.last_error))
		return
	notice = ""
	_pulse(0.08, 0.35)
	stuck.emit(s)

func _hold(st: Dictionary) -> void:
	if (st.get("target", {}) as Dictionary).is_empty():
		_refuse("HOLD PEELS A STICKER: NONE UNDER THE AIM")
		return
	_peel(str(st.target.id))

func _peel(id: String) -> bool:
	if not data.peel(id):
		_refuse("NOT PEELED: " + str(data.last_error))
		return false
	notice = ""
	_pulse(0.12, 0.5)
	peeled.emit(id)
	return true

func _refuse(reason: String) -> void:
	notice = reason
	if _label != null:
		_label.text = reason
	_pulse(0.15, 0.6)
	refused.emit(reason)

func _pulse(amplitude: float, seconds: float) -> void:
	if worn_on != null and worn_on.has_method("trigger_haptic_pulse"):
		worn_on.trigger_haptic_pulse("haptic", 0.0, amplitude, seconds, 0.0)

func _cancel() -> void:
	_pressed = false
	_consumed = false
	_press_aim = {}

## The wrist's twist about the aim, as a turn (InventoryPrism._wrist_yaw): twice the roll, 15 degree steps, a dead zone.
func _wrist_yaw(c: Node3D) -> float:
	var f: Vector3 = -c.global_basis.z.normalized()
	if absf(f.dot(Vector3.UP)) > .95:
		return turn
	var ref: Vector3 = (Vector3.UP - f * f.dot(Vector3.UP)).normalized()
	var u: Vector3 = c.global_basis.y.normalized()
	var roll: float = rad_to_deg(atan2(f.dot(ref.cross(u)), ref.dot(u)))
	if absf(roll) < TWIST_DEAD:
		return 0.0
	return snappedf(-clampf(roll, -90.0, 90.0) * 2.0, TURN_STEP)

# ==== drawing: the ghost, its words, the aim line ====

func _draw(st: Dictionary) -> void:
	_ensure_aim()
	var design := str(st.design)
	var d: Dictionary = data.design(design)
	var tex: Texture2D = data.texture(design) if not d.is_empty() else null
	if _ghost_mat.albedo_texture != tex:
		_ghost_mat.albedo_texture = tex
	var hit: Dictionary = st.hit
	var title := str(d.get("title", design)).to_upper()
	var pose := Transform3D.IDENTITY
	var ghost_mesh: Mesh = _ghost_quad
	var ghost_at := Transform3D.IDENTITY
	if bool(st.ok):
		var e := StickerData.extent(d, float(st.size))
		var b := StickerData.basis(st.n, st.up)
		var frame: Transform3D = st.frame
		var lift: float = GHOST_LIFT / maxf(float(st.size_w) / maxf(float(st.size), 1e-6), 1e-6)
		pose = frame * Transform3D(Basis(b.right * e.x, b.up * e.y, b.n), Vector3(st.at) + b.n * lift)
		ghost_at = pose
		var rec := {"at": st.pose.at, "n": st.pose.n, "up": st.pose.up, "size": float(st.size)}
		# on a body the layer knows (the sphere, the cylinder, a box, the board) the ghost is printed on it as the
		# sticker will be - laid on a curve, cut at a face's edge (8 x 8 cells are enough at the ghost's 8 mm) - in the
		# host frame; elsewhere it is the quad
		var sig := "%s|%s|%s|%s" % [design, JSON.stringify(rec), lift, JSON.stringify(st.surface)]
		if sig != _ghost_arc_sig:
			_ghost_arc_sig = sig
			_ghost_laid = StickerLayer.laid(rec, d, st.surface)
			_ghost_arc.clear_surfaces()
			if _ghost_laid:
				var g := StickerLayer.curved_mesh(rec, d, lift, st.surface, StickerLayer.CELLS_LEAST)
				if not (g.idx as PackedInt32Array).is_empty():
					var arrays: Array = []
					arrays.resize(Mesh.ARRAY_MAX)
					arrays[Mesh.ARRAY_VERTEX] = g.verts
					arrays[Mesh.ARRAY_NORMAL] = g.norms
					arrays[Mesh.ARRAY_TEX_UV] = g.uvs
					arrays[Mesh.ARRAY_INDEX] = g.idx
					_ghost_arc.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		if _ghost_laid:
			ghost_mesh = _ghost_arc
			ghost_at = frame
		_ghost_mat.albedo_color = TINT_OK
		_label.text = title + ("\nTAP: STICK  /  HOLD: PEEL" if not (st.target as Dictionary).is_empty() else "\nTAP: STICK")
		_label.modulate = Color("1d1d1f")
		_line_mat.albedo_color = Color(LINE_OK, .55)
	else:
		var size_w := _size_for(d) if not d.is_empty() else 0.2
		var e := StickerData.extent(d, size_w) if not d.is_empty() else Vector2(size_w, size_w)
		var nw: Vector3
		var at_w: Vector3
		if hit.is_empty():   # nothing: the sticker that would come next, ahead, facing the eye
			nw = -Vector3(st.dir)
			at_w = Vector3(st.origin) + Vector3(st.dir) * minf(reach, PREVIEW_AT)
			_ghost_mat.albedo_color = TINT_IDLE
			_label.modulate = Color("f4f0e6")
			_line_mat.albedo_color = Color(LINE_OK, .3)
		else:
			nw = Vector3(hit.normal).normalized()
			at_w = Vector3(hit.position) + nw * GHOST_LIFT
			_ghost_mat.albedo_color = TINT_REFUSED
			_label.modulate = LINE_REFUSED
			_line_mat.albedo_color = Color(LINE_REFUSED, .65)
		var b := StickerData.basis(nw, _up_on_surface(at_w, nw))
		pose = Transform3D(Basis(b.right * e.x, b.up * e.y, b.n), at_w)
		ghost_at = pose
		_label.text = title + "\n" + str(st.reason)
	if _ghost.mesh != ghost_mesh:
		_ghost.mesh = ghost_mesh
	_ghost.global_transform = ghost_at
	_ghost.show()
	# the words under the ghost keep a readable size: 2 cm letters at arm's length, growing with the distance from the
	# eye (at 4 m they were a grey smear in the refused.png of the first probe)
	var eye := get_viewport().get_camera_3d()
	var far := eye.global_position.distance_to(pose.origin) if eye != null else LABEL_NEAR
	var grow := clampf(far / LABEL_NEAR, 1.0, LABEL_GROW_MOST)
	_label.pixel_size = LABEL_PX * grow
	var up_w: Vector3 = pose.basis.y
	# the whole transform, not only the position: the label went top_level while the pad was worn at 0.4 and kept that
	# scale, so its words were 0.4 of their size (5 px at 1.9 m in the probe's void.png, for 14)
	_label.global_transform = Transform3D(Basis.IDENTITY, pose.origin - up_w.normalized() * (up_w.length() / 2.0 + 0.035 * grow))
	_label.show()
	var from: Vector3 = st.origin
	var to: Vector3 = st.end
	if worn_on is Camera3D:   # from the eye a line is a dot: start it a little ahead
		from += Vector3(st.dir) * minf(.25, from.distance_to(to) * .5)
	var im := _line.mesh as ImmediateMesh
	im.clear_surfaces()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	im.surface_add_vertex(from)
	im.surface_add_vertex(to)
	im.surface_end()
	_line.global_transform = Transform3D.IDENTITY
	_line.show()

func _ensure_aim() -> void:
	if _ghost != null:
		return
	_ghost = MeshInstance3D.new()
	_ghost.name = "Ghost"
	_ghost_quad = QuadMesh.new()
	_ghost_quad.size = Vector2.ONE
	_ghost_arc = ArrayMesh.new()
	_ghost.mesh = _ghost_quad
	_ghost_mat = StandardMaterial3D.new()
	_ghost_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ghost_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ghost_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_ghost_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_ghost.material_override = _ghost_mat
	_ghost.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ghost)
	_ghost.top_level = true
	_label = Label3D.new()
	_label.name = "GhostWords"
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 28
	_label.pixel_size = LABEL_PX
	_label.outline_size = 6
	_label.outline_modulate = Color(1, 1, 1, 0.7)
	_label.no_depth_test = true
	_label.fixed_size = false
	add_child(_label)
	_label.top_level = true
	_line = MeshInstance3D.new()
	_line.name = "AimLine"
	_line.mesh = ImmediateMesh.new()
	_line_mat = StandardMaterial3D.new()
	_line_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_line_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_line.material_override = _line_mat
	_line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_line)
	_line.top_level = true

func _hide_aim() -> void:
	if _ghost != null:
		_ghost.hide()
		_label.hide()
		_line.hide()

# ==== the pad itself: a sheet of stickers (shown as the inventory's miniature) ====

func _build_model() -> void:
	_model = Node3D.new()
	_model.name = "Sheet"
	add_child(_model)
	var back := MeshInstance3D.new()
	back.name = "Backing"
	var bm := BoxMesh.new()
	bm.size = Vector3(0.12, 0.09, 0.003)
	back.mesh = bm
	back.position.z = -0.0015
	var pm := StandardMaterial3D.new()
	pm.albedo_color = Color("f4f0e6")
	pm.roughness = 0.9
	back.material_override = pm
	_model.add_child(back)
	for i in 3:
		var peel := MeshInstance3D.new()
		peel.name = "Sticker%d" % i
		peel.mesh = QuadMesh.new()
		peel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_model.add_child(peel)
	_model.visible = _show_model
	_refresh_model()

## The sheet shows the design the pad sticks next, large, and the two after it.
func _refresh_model() -> void:
	if _model == null or data == null:
		return
	var list: Array = data.sheet_designs(sheet)
	var first := current_design()
	var i0 := list.find(first)
	var places := [[Vector2(-0.025, 0.0), 0.065], [Vector2(0.034, 0.02), 0.034], [Vector2(0.034, -0.021), 0.034]]
	for i in 3:
		var node := _model.get_node_or_null("Sticker%d" % i) as MeshInstance3D
		if node == null:
			continue
		var id: String = first if i == 0 else (str(list[posmod(i0 + i, list.size())]) if not list.is_empty() and i0 >= 0 else "")
		var d: Dictionary = data.design(id) if id != "" else {}
		node.visible = not d.is_empty()
		if d.is_empty():
			continue
		var e := StickerData.extent(d, float(places[i][1]))
		(node.mesh as QuadMesh).size = e
		node.position = Vector3(places[i][0].x, places[i][0].y, 0.0006)
		node.material_override = data.material(id)
