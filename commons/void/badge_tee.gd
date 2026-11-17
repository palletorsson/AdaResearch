extends Node3D
## THE BADGE T-SHIRT (Palle, 2026-11-17: "Put the last badge as the t-shirt and player. The first t-shirt just has a
## badge and a text pink."). Ada - Care Unit Model B, the player's body in the Void (commons/void/care_body.gd) - wears
## a short-sleeved, off-white printed tee over her torso. Its chest print is THE LAST BADGE COLLECTED
## (commons/player/badges.gd last_collected(): that coin's face SVG, its name in pink under it). Before any coin is
## collected it is THE FIRST SHIRT: a round pink badge with ADA lettered in it and a short line in pink under it, the
## words and the pink read from commons/data/badges/coins.json "shirt".first. The print changes the moment a coin is
## collected: the tee is in the group "badge_listeners" and badges.gd collect() calls badge_collected(id) on it.
##
## THE CLOTH is fitted when it is worn to whatever shell Ada shows - the knit cover's torso vertices (ada_knit.glb,
## by their dominant bone) or the armor plates - ring by ring: the convex hull of the body's slice plus fit_margin;
## below the widest ring the cloth HANGS (it narrows at most TAPER per metre going down), so it falls over the waist
## like a tee instead of shrink-wrapping it. The fit is for the unit profile and kept per shell; a changed profile
## (shoulders / waist / hips) re-lofts it, each ring widened by its share of the three torso bones.
## Every ring sees that no hull corner falls between two columns outside their chord (a sharp corner was cut 12 mm).
## THE SLEEVES are fitted the same way in the upper-arm links' own frame (ada_android.gd _link: y runs elbow 0 ->
## shoulder 1, x and z are metres) to the arm beneath - the knit's upper-arm vertices or the armor's arm plate and
## bearing - so each is its own mesh, its dome low on the inner side; they copy the links' transforms every frame.
## They cannot be the links' children: in the knit look the armor links are hidden, and visibility is hierarchical.
## The shoulder junction (knit vertices blended between the thorax and the arm) stretches when an arm is raised;
## no rigid sleeve follows that, so there the knit can show between sleeve and body.
## THE PRINT is a second surface of the shell mesh (its front quads), mapped flat from the front onto an opaque
## texture whose ground is the cloth's own colour: no Decal (the Compatibility renderer draws none), no transparency,
## nothing to z-fight. The lettering is paths - the sticker alphabet, ported below from
## ada_encyclopedia/src/lib/sticker-alphabet.ts - because ThorVG draws no <text>.
## THE PRINT sits high on the chest (PRINT_CENTER): the care body stands the torso 12 cm behind the eye, so the
## upright bust is edge-on from the head; the badge's top lies on the upper chest that slopes up to the eye, and the
## player sees it upside down at the far edge of the chest looking down, as one sees one's own shirt.
## Light for the Quest: one shell mesh (2 surfaces, ~2200 vertices), two sleeve meshes (~340 each), one 512 px
## print (3 kept); the knit is read once per process; wearing cold costs ~130 ms on a desktop, once.
## Default layer 1: the first-person camera hides head layer 20 only, so the player sees the shirt looking down.
##
## Worn by one marked line at the end of care_body.gd configure(): load("res://commons/void/badge_tee.gd").wear(self).

const Badges := preload("res://commons/player/badges.gd")
const SELF := "res://commons/void/badge_tee.gd"
const COINS_JSON := "res://commons/data/badges/coins.json"
const FIRST := {"badge": "ADA", "text": "CARE UNIT MODEL B", "colour": "#eb0d85"}   # when coins.json says nothing
const CLOTH := Color("efe9df")                 # plain off-white cotton (the knit beneath is d9d1bf)
const COLUMNS := 32
const HEM_Y := 0.905                           # at the hips, just above ada_android HIP_Y 0.887
const NECK_Y := 1.478                          # the neckline
const RING_STEP := 0.02
const TAPER := 0.20                            # the cloth below the chest narrows at most this much per metre down
const TORSO_TAGS := {"Thorax": 0, "WaistBellows": 1, "PelvicShell": 2, "LegLUpper": 3, "LegRUpper": 3}
## The sleeve, in t along the upper-arm link (0 elbow, 1 shoulder): its hem at mid upper arm, fitted ring by ring to
## the arm beneath (the knit's upper-arm vertices, or the armor's arm plate and shoulder bearing), so the dome over
## the shoulder hugs it - low on the inner side, where the body's shell covers the joint - and hangs loose below.
const SLEEVE_HEM := 0.47
const SLEEVE_STEP := 0.05
const SLEEVE_TAPER := 0.08                     # metres per metre the sleeve narrows going down the arm, at most
const SLEEVE_EASE := 0.010                     # the hem stands this much further off the arm
const HEM_FOLD := 0.011                        # the width of a turned hem, seen from below
const PRINT_CENTER := Vector2(0.0, 1.335)      # android-local x, y of the print's middle: high on the chest, so the
                                               # disc's top lies on the upper chest that slopes up to the eye
const PRINT_SIZE := Vector2(0.20, 0.20)        # metres the 100-unit print covers
const PRINT_PX := 512
const PRINTS_KEPT := 3
const DISC := Vector3(50.0, 34.0, 27.5)        # the badge disc in print units: centre x, y, radius
const CAPTION_TOP := 68.0
const CAPTION_H := 27.0
const CAPTION_W := 90.0
const CAPTION_CAP := 10.5
const CAPTION_MIN := 6.5                       # under this one line wraps into two
const CAPTION_CAP2 := 9.0

static var coins_file := COINS_JSON            # a probe may point this at a fixture
static var fit_margin := 0.009                 # the cloth stands this far off the body (a probe breaks it)
static var _fits := {}                         # shell kind -> rings (unit profile)
static var _sleeve_fits := {}                 # "kind|side" -> sleeve rings
static var _knit_rows := {}                    # the knit cover read once: {p: bind positions in the android's frame,
                                               # bone: each vertex's heaviest bind, names: the binds' bone names}
static var _prints := {}                       # print key -> Texture2D
static var _print_order: Array = []
static var _glyphs := {}

var shell: MeshInstance3D
var sleeves: Array[MeshInstance3D] = []
var links: Array[Node3D] = []
var rings: Array = []                          # the fit worn now (unit profile)
var print_kind := ""                           # "first" or "coin"
var print_badge := ""                          # the badge's words (first) or the coin id
var print_text := ""                           # the pink line under the badge
var print_colour := ""
var print_texture: Texture2D
var _android: Node3D
var _knit: Node3D
var _cloth: StandardMaterial3D
var _print_mat: StandardMaterial3D
var _kind := ""
var _profile := Vector3.ZERO


## Put the tee on a care body (or on a bare android): a child "BadgeTee" of its torso, fitted and printed. Once.
static func wear(holder: Node) -> Node3D:
	var torso: Node3D = holder.get("torso") if holder.get("torso") is Node3D else holder as Node3D
	if torso == null:
		return null
	var worn := torso.get_node_or_null("BadgeTee") as Node3D
	if worn != null:
		return worn
	var tee: Node3D = (load(SELF) as GDScript).new()
	tee.name = "BadgeTee"
	torso.add_child(tee)
	tee.dress(torso)
	return tee


func dress(android: Node3D) -> void:
	_android = android
	_knit = android.get_node_or_null("KnitShell") as Node3D
	add_to_group("badge_listeners")
	links = _upper_links(android)
	_cloth = _material()
	_print_mat = _material()
	shell = MeshInstance3D.new()
	shell.name = "TeeShell"
	add_child(shell)
	for i in links.size():
		var sleeve := MeshInstance3D.new()
		sleeve.name = "TeeSleeve" + ("L" if i == 0 else "R")
		sleeve.material_override = _cloth
		add_child(sleeve)
		sleeves.append(sleeve)
	follow()
	refresh()


func _process(_delta: float) -> void:
	follow()


## The sleeves take the upper arms' pose; a changed shell (Knit / Armor) or profile re-fits the cloth.
func follow() -> void:
	if not is_instance_valid(_android):
		return
	for i in sleeves.size():
		if is_instance_valid(links[i]):
			sleeves[i].transform = links[i].transform
	var kind := _shell_kind()
	var profile := _profile_now()
	if kind != _kind or not profile.is_equal_approx(_profile):
		refit(kind, profile)


func refit(kind: String = _shell_kind(), profile: Vector3 = _profile_now()) -> void:
	_kind = kind
	_profile = profile
	if not _fits.has(kind):
		_fits[kind] = _fit(_body_points(kind))
	rings = _fits[kind]
	shell.mesh = _shell_mesh(rings, profile)
	shell.set_surface_override_material(0, _cloth)
	if shell.mesh.get_surface_count() > 1:
		shell.set_surface_override_material(1, _print_mat)
	for i in sleeves.size():
		var key := "%s|%d" % [kind, i]
		if not _sleeve_fits.has(key):
			_sleeve_fits[key] = _fit_sleeve(_arm_points(kind, i), links[i].transform.basis.y.length())
		sleeves[i].mesh = _sleeve_mesh(_sleeve_fits[key])


## Wear the print the badges say: the last coin collected, else the first shirt.
func refresh() -> void:
	var c: Dictionary = Badges.last_collected()
	if c.is_empty():
		_wear_first()
	else:
		_wear_coin(c)


## badges.gd collect() -> call_group("badge_listeners", "badge_collected", id): the shirt changes now.
func badge_collected(id: String) -> void:
	var c: Dictionary = Badges.coin(id)
	if c.is_empty():
		refresh()
	else:
		_wear_coin(c)


## coins.json "shirt".first, with FIRST for whatever it does not say.
static func shirt_first() -> Dictionary:
	var out := FIRST.duplicate()
	if FileAccess.file_exists(coins_file):
		var doc: Variant = JSON.parse_string(FileAccess.get_file_as_string(coins_file))
		if doc is Dictionary and doc.get("shirt") is Dictionary and doc.shirt.get("first") is Dictionary:
			for k in FIRST:
				var v: Variant = doc.shirt.first.get(k)
				if v is String and v != "":
					out[k] = v
	if not Color.html_is_valid(out.colour):
		out.colour = FIRST.colour
	return out


func _wear_first() -> void:
	var first := shirt_first()
	print_kind = "first"
	print_badge = first.badge
	print_text = first.text
	print_colour = first.colour
	_show(print_texture_for("first", first.badge, first.text, first.colour, ""))


func _wear_coin(c: Dictionary) -> void:
	var colour: String = shirt_first().colour
	print_kind = "coin"
	print_badge = str(c.get("id", ""))
	print_text = str(c.get("name", c.get("id", ""))).strip_edges()
	print_colour = colour
	var face := str(c.get("face", ""))
	var fallback := str(c.get("label", "%02d" % int(c.get("n", 0))))
	_show(print_texture_for("coin", print_badge if face != "" else fallback, print_text, colour, face))


func _show(tex: Texture2D) -> void:
	print_texture = tex
	_print_mat.albedo_texture = tex


# -- THE PRINT ---------------------------------------------------------------------------------------------------------

## One print, drawn once and kept (the newest PRINTS_KEPT): the cloth's ground, a badge disc - ADA lettered in a pink
## rim (kind "first"), or the coin's face drawn from its SVG (kind "coin") - and the pink line under it.
static func print_texture_for(kind: String, badge: String, line: String, colour: String, face: String) -> Texture2D:
	var key := "%s|%s|%s|%s|%d" % [kind, badge, line, colour, face.hash()]
	if _prints.has(key):
		return _prints[key]
	var disc := ""
	if face == "":   # the first shirt's badge, or a coin whose face does not draw: its number in a pink rim
		var pale := CLOTH.lerp(Color(colour), 0.13).to_html(false)
		disc = '<circle cx="%s" cy="%s" r="%s" fill="#%s" stroke="%s" stroke-width="4.4"/>' % [DISC.x, DISC.y, DISC.z, pale, colour]
		disc += '<circle cx="%s" cy="%s" r="%s" fill="none" stroke="%s" stroke-width="0.9"/>' % [DISC.x, DISC.y, DISC.z - 4.9, colour]
		var w := _advance(badge)
		if w > 0.0:
			var cap := minf(13.0, (DISC.z - 6.0) * 2.0 * 100.0 / w)
			disc += _word_svg(badge, cap, DISC.x, DISC.y - cap * 0.5, colour)
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 100 100"><rect x="-1" y="-1" width="102" height="102" fill="#%s"/>%s%s</svg>' % [
		PRINT_PX, PRINT_PX, CLOTH.to_html(false), disc, _caption_svg(line, colour)]
	var img := Image.new()
	if img.load_svg_from_string(svg, 1.0) != OK or img.is_empty():
		push_warning("badge_tee: the print did not draw")
		img = Image.create(PRINT_PX, PRINT_PX, false, Image.FORMAT_RGBA8)
		img.fill(CLOTH)
	img.convert(Image.FORMAT_RGBA8)
	if face != "":
		var side := roundi((DISC.z + 2.2) * 2.0 * PRINT_PX / 100.0)
		var long := maxf(_svg_size(face, "width"), _svg_size(face, "height"))
		var coin := Image.new()
		if coin.load_svg_from_string(face, side / (long if long > 0.0 else 256.0)) == OK and not coin.is_empty():
			coin.convert(Image.FORMAT_RGBA8)
			var at := Vector2i(roundi(DISC.x * PRINT_PX / 100.0) - coin.get_width() / 2, roundi(DISC.y * PRINT_PX / 100.0) - coin.get_height() / 2)
			img.blend_rect(coin, Rect2i(Vector2i.ZERO, coin.get_size()), at)
		else:
			push_warning("badge_tee: the coin face did not draw; the print keeps the name only")
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_prints[key] = tex
	_print_order.append(key)
	while _print_order.size() > PRINTS_KEPT:
		_prints.erase(_print_order.pop_front())
	return tex


## The pink line under the badge: one line when it reads at CAPTION_MIN or larger, else two, split where it balances.
static func _caption_svg(text: String, colour: String) -> String:
	var t := text.strip_edges()
	var w := _advance(t)
	if w <= 0.0:
		return ""
	var cap := minf(CAPTION_CAP, CAPTION_W * 100.0 / w)
	if cap >= CAPTION_MIN or not " " in t:
		return _word_svg(t, cap, 50.0, CAPTION_TOP + (CAPTION_H - cap) * 0.5, colour)
	var words := t.split(" ", false)
	var best := [t, ""]
	var widest := INF
	for i in range(1, words.size()):
		var a := " ".join(words.slice(0, i))
		var b := " ".join(words.slice(i))
		var m := maxf(_advance(a), _advance(b))
		if m < widest:
			widest = m
			best = [a, b]
	var cap2 := minf(minf(CAPTION_CAP2, CAPTION_W * 100.0 / widest), CAPTION_H / 2.45)
	var top := CAPTION_TOP + (CAPTION_H - cap2 * 2.45) * 0.5
	return _word_svg(best[0], cap2, 50.0, top, colour) + _word_svg(best[1], cap2, 50.0, top + cap2 * 1.45, colour)


## One line of the sticker alphabet as SVG paths, centred on cx, the caps' top at `top`, `cap` units high.
static func _word_svg(text: String, cap: float, cx: float, top: float, colour: String) -> String:
	var parts := PackedStringArray()
	var x := 0.0
	var first := true
	for ch in text:
		if ch == " ":
			x += 74.0
			first = true
			continue
		var g := _glyph(ch)
		if not first:
			x += 26.0
		parts.append('<path transform="translate(%s 0)" d="%s"/>' % [_n(x), g.d])
		x += float(g.w)
		first = false
	var s := cap / 100.0
	return '<g transform="translate(%s %s) scale(%s)" fill="none" stroke="%s" stroke-width="13" stroke-linecap="round" stroke-linejoin="round">%s</g>' % [
		_n(cx - x * s * 0.5), _n(top), _n(s), colour, "".join(parts)]


## A line's width in alphabet units (cap height 100): each glyph's width, GAP between glyphs, SPACE for a space.
static func _advance(text: String) -> float:
	var x := 0.0
	var first := true
	for ch in text:
		if ch == " ":
			x += 74.0
			first = true
			continue
		if not first:
			x += 26.0
		x += float(_glyph(ch).w)
		first = false
	return x


static func _svg_size(svg: String, attr: String) -> float:
	var at := svg.find(" %s=\"" % attr)
	if at < 0:
		return 0.0
	var from := at + attr.length() + 3
	return float(svg.substr(from, svg.find("\"", from) - from))


static func _n(v: float) -> String:
	return str(int(v)) if is_equal_approx(v, roundf(v)) else str(snappedf(v, 0.001))


# -- THE CLOTH ---------------------------------------------------------------------------------------------------------

func _material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color.WHITE if _cloth != null else CLOTH
	m.roughness = 0.93
	m.metallic_specular = 0.32
	m.rim_enabled = true                         # the soft sheen at a cotton's edge
	m.rim = 0.28
	m.rim_tint = 0.55
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.texture_repeat = false
	return m


func _shell_kind() -> String:
	var look: Variant = _android.get("look")
	if is_instance_valid(_knit) and (not look is Dictionary or str(look.get("shell", "Knit")) == "Knit"):
		return "Knit"
	return "Armor"


func _profile_now() -> Vector3:
	var p: Variant = _android.get("profile")
	if p is Dictionary:
		return Vector3(float(p.get("shoulders", 1.0)), float(p.get("waist", 1.0)), float(p.get("hips", 1.0)))
	return Vector3.ONE


## The upper-arm links ada_android poses (left, right): its _arms[i].upper, else the UpperArmArmor meshes by side.
static func _upper_links(android: Node3D) -> Array[Node3D]:
	var out: Array[Node3D] = []
	var arms: Variant = android.get("_arms")
	if arms is Array and arms.size() == 2:
		for arm in arms:
			if arm is Dictionary and arm.get("upper") is Node3D:
				out.append(arm.upper)
	if out.size() == 2:
		return out
	out.clear()
	for child in android.get_children():
		if child is Node3D and String(child.name).begins_with("UpperArmArmor"):
			out.append(child)
	out.sort_custom(func(a, b): return a.position.x < b.position.x)
	return out.slice(0, 2)


## The body the cloth must clear, in the android's frame at the unit profile: [point, tag] (tag 0 thorax, 1 waist,
## 2 pelvis, 3 a thigh's top - for the hem only).
func _body_points(kind: String) -> Array:
	var out: Array = []
	if kind == "Knit":
		var rows := _knit_cover()
		var tags := PackedInt32Array()
		for title in rows.names:
			tags.append(int(TORSO_TAGS.get(title, -1)))
		var points: PackedVector3Array = rows.p
		var bones: PackedInt32Array = rows.bone
		for i in points.size():
			var p := points[i]
			var tag: int = tags[bones[i]] if bones[i] >= 0 else -1
			if tag >= 0 and p.y >= HEM_Y - 0.03 and p.y <= NECK_Y + 0.035 and (tag < 3 or p.y < HEM_Y + 0.03):
				out.append([p, tag])
	else:
		for piece in _android.get_children():
			if not piece is MeshInstance3D or piece.mesh == null:
				continue
			var title := String(piece.name)
			var tag := -1
			var frame: Transform3D = piece.transform
			if title.begins_with("Thorax") or title.begins_with("CoreBezel") or title.begins_with("CoreLight") or title.begins_with("SpineHinge"):
				tag = 0
			elif title.begins_with("WaistBellows") or title.begins_with("AbdominalPlate"):
				tag = 1
			elif title.begins_with("PelvicShell"):
				tag = 2
			elif title.begins_with("HipBearing"):
				tag = 3
			if tag < 0:
				continue
			if tag in [1, 2] or title.begins_with("Thorax"):
				frame = Transform3D(Basis.IDENTITY, piece.position)   # the loft at the unit profile
			for p in _surface_points(piece.mesh, frame, 0.008):
				if p.y >= HEM_Y - 0.03 and p.y <= NECK_Y + 0.035 and (tag < 3 or p.y < HEM_Y + 0.03):
					out.append([p, tag])
	return out


## The arm a sleeve must clear, in its upper-arm link's frame (y = t, x and z metres) at rest: the knit's vertices
## whose heaviest bone is that upper arm (placed by the link's rest frame, which the knit's bone pose gives back:
## rest = pose^-1 x link), or the armor's arm plate and shoulder bearing.
func _arm_points(kind: String, side: int) -> PackedVector3Array:
	var out := PackedVector3Array()
	var link := links[side]
	if kind == "Knit":
		var bone_name := "ArmLUpper" if side == 0 else "ArmRUpper"
		var rows := _knit_cover()
		var bind: int = rows.names.find(bone_name)
		var skeleton := _knit.find_children("*", "Skeleton3D", true, false)
		var bone := (skeleton[0] as Skeleton3D).find_bone(bone_name) if not skeleton.is_empty() else -1
		if bind >= 0 and bone >= 0:
			var to_link := ((skeleton[0] as Skeleton3D).get_bone_pose(bone).affine_inverse() * link.transform).affine_inverse()
			var points: PackedVector3Array = rows.p
			var bones: PackedInt32Array = rows.bone
			for i in points.size():
				if bones[i] == bind:
					out.append(to_link * points[i])
	else:
		var to_link := link.transform.affine_inverse()
		if link is MeshInstance3D and link.mesh != null:
			out.append_array(_surface_points(link.mesh, Transform3D.IDENTITY, 0.02))
		var arms: Variant = _android.get("_arms")
		if arms is Array and side < arms.size() and arms[side].get("bearing") is MeshInstance3D:
			var bearing: MeshInstance3D = arms[side].bearing
			out.append_array(_surface_points(bearing.mesh, to_link * bearing.transform, 0.02))
	return out


## The knit cover, read once per process (every android shares the one ada_knit.glb): its vertices in the android's
## frame at the bind pose, and each one's heaviest bind.
func _knit_cover() -> Dictionary:
	var surface: MeshInstance3D = null
	for found: MeshInstance3D in _knit.find_children("*", "MeshInstance3D", true, false):
		if found.skin != null and found.mesh != null:
			surface = found
			break
	if surface == null:
		return {"p": PackedVector3Array(), "bone": PackedInt32Array(), "names": PackedStringArray()}
	var key := surface.mesh.get_instance_id()
	if _knit_rows.has(key):
		return _knit_rows[key]
	var names := PackedStringArray()
	for b in surface.skin.get_bind_count():
		names.append(String(surface.skin.get_bind_name(b)))
	var to_body := _relative(surface, _android)
	var points := PackedVector3Array()
	var heaviest_bind := PackedInt32Array()
	for s in surface.mesh.get_surface_count():
		var arrays := surface.mesh.surface_get_arrays(s)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var per := bones.size() / maxi(1, verts.size())
		for i in verts.size():
			var best := -1
			var heaviest := -1.0
			for k in per:
				if weights[i * per + k] > heaviest:
					heaviest = weights[i * per + k]
					best = bones[i * per + k]
			points.append(to_body * verts[i])
			heaviest_bind.append(best if best < names.size() else -1)
	_knit_rows[key] = {"p": points, "bone": heaviest_bind, "names": names}
	return _knit_rows[key]


## A mesh's vertices and points along its triangles' edges at most `step` apart (in the mesh's own units), in `frame`.
static func _surface_points(mesh: Mesh, frame: Transform3D, step: float) -> PackedVector3Array:
	var out := PackedVector3Array()
	for s in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(s)
		var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var index: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		for p in v:
			out.append(frame * p)
		var count := index.size() if not index.is_empty() else v.size()
		for t in range(0, count - 2, 3):
			for e in 3:
				var a: Vector3 = v[index[t + e]] if not index.is_empty() else v[t + e]
				var b: Vector3 = v[index[t + (e + 1) % 3]] if not index.is_empty() else v[t + (e + 1) % 3]
				var n := int(a.distance_to(b) / step)
				for k in range(1, n + 1):
					out.append(frame * a.lerp(b, float(k) / (n + 1)))
	return out


## The fit: one ring per height from the hem to the neckline, COLUMNS radii about (0, cz) each.
static func _fit(points: Array) -> Array:
	var ys: Array = []
	var y := HEM_Y
	while y < 1.4455:
		ys.append([y, y - RING_STEP, y + RING_STEP])
		y += RING_STEP
	ys.append([1.458, 1.445, 1.469])
	ys.append([1.469, 1.458, NECK_Y])
	ys.append([NECK_Y, NECK_Y - 0.004, NECK_Y + 0.03])
	var buckets := {}
	for row in points:
		var cm := floori((row[0] as Vector3).y * 100.0)
		if not buckets.has(cm):
			buckets[cm] = []
		buckets[cm].append(row)
	var out: Array = []
	for band in ys:
		var slice := PackedVector2Array()
		var share := Vector3.ZERO
		var rows: Array = []
		for cm in range(floori(band[1] * 100.0), floori(band[2] * 100.0) + 1):
			rows.append_array(buckets.get(cm, []))
		for row in rows:
			var p: Vector3 = row[0]
			if p.y < band[1] or p.y > band[2] or (row[1] == 3 and band[0] > HEM_Y + 0.025):
				continue
			slice.append(Vector2(p.x, p.z))
			share[mini(row[1], 2)] += 1.0
		var ring := {"y": band[0], "cz": 0.0, "r": PackedFloat32Array(), "need": PackedFloat32Array(), "share": Vector3(0, 0, 1)}
		if slice.size() < 6:
			if out.is_empty():
				continue
			ring.cz = out.back().cz
			ring.need = out.back().need.duplicate()
			ring.share = out.back().share
		else:
			var hull := Geometry2D.convex_hull(slice)
			var lo := INF
			var hi := -INF
			for q in hull:
				lo = minf(lo, q.y)
				hi = maxf(hi, q.y)
			ring.cz = (lo + hi) * 0.5
			ring.share = share / maxf(1.0, share.x + share.y + share.z)
			ring.need = _hull_radii(hull, Vector2(0.0, ring.cz))
			# one shirt for both sides: a column takes the wider of itself and its mirror
			for j in COLUMNS:
				var m := (COLUMNS / 2 - j + COLUMNS) % COLUMNS
				var wide := maxf(ring.need[j], ring.need[m])
				ring.need[j] = wide
				ring.need[m] = wide
		ring.r = ring.need.duplicate()
		out.append(ring)
	# the cloth hangs from the widest ring: going down it narrows at most TAPER per metre
	for k in range(out.size() - 2, -1, -1):
		var drop: float = TAPER * (out[k + 1].y - out[k].y)
		for j in COLUMNS:
			out[k].r[j] = maxf(out[k].r[j], out[k + 1].r[j] - drop)
	# smooth it as cloth (not the neckline's last three rings), then never inside the body
	for _pass in 2:
		var smooth: Array = []
		for k in out.size():
			var r: PackedFloat32Array = out[k].r.duplicate()
			for j in COLUMNS:
				var around: float = (out[k].r[(j + COLUMNS - 1) % COLUMNS] + 2.0 * out[k].r[j] + out[k].r[(j + 1) % COLUMNS]) * 0.25
				if k > 0 and k < out.size() - 4:
					around = (around * 2.0 + out[k - 1].r[j] + out[k + 1].r[j]) * 0.25
				r[j] = maxf(around, out[k].need[j])
			smooth.append(r)
		for k in out.size():
			out[k].r = smooth[k]
	return out


## A ring's COLUMNS radii about `centre` that enclose the convex hull with fit_margin to spare: each column reaches
## the hull's edge along its own direction, and no hull corner lies outside the chord of the two columns either side
## of it (a sharp corner between two columns - the knit's shoulder front - would otherwise be cut by more than the
## margin: measured 12 mm). A chord's middle sits at cos(half a column) of its ends' radius.
static func _hull_radii(hull: PackedVector2Array, centre: Vector2) -> PackedFloat32Array:
	var radii := PackedFloat32Array()
	for j in COLUMNS:
		var a := TAU * j / COLUMNS
		radii.append(_hull_reach(hull, centre, Vector2(cos(a), sin(a))) + fit_margin)
	var sector := TAU / COLUMNS
	for q in hull:
		var d := q - centre
		var j0 := int(floor(fposmod(d.angle(), TAU) / sector)) % COLUMNS
		var j1 := (j0 + 1) % COLUMNS
		var want := (d.length() + fit_margin) / cos(sector * 0.5)
		radii[j0] = maxf(radii[j0], want)
		radii[j1] = maxf(radii[j1], want)
	return radii


## How far a ray from `from` along `dir` reaches the convex hull's edge.
static func _hull_reach(hull: PackedVector2Array, from: Vector2, dir: Vector2) -> float:
	var best := 0.0
	for i in hull.size():
		var a := hull[i] - from
		var b := hull[(i + 1) % hull.size()] - from
		var e := b - a
		var den := dir.cross(e)
		if absf(den) < 1e-9:
			continue
		var t := a.cross(e) / den
		var s := a.cross(dir) / den
		if t > 0.0 and s >= -1e-6 and s <= 1.0 + 1e-6:
			best = maxf(best, t)
	return best


static func _ring_points(ring: Dictionary, profile: Vector3, inset := 0.0, lift := 0.0) -> PackedVector3Array:
	var sx: float = ring.share.dot(profile) if ring.share.x + ring.share.y + ring.share.z > 0.0 else 1.0
	var pts := PackedVector3Array()
	for j in COLUMNS:
		var a := TAU * j / COLUMNS
		var r: float = ring.r[j] - inset
		pts.append(Vector3(cos(a) * r * sx, ring.y + lift, ring.cz + sin(a) * r))
	return pts


## The shell: surface 0 the cloth (body, turned hem, collar), surface 1 the print (the front quads of the body).
func _shell_mesh(fit: Array, profile: Vector3) -> ArrayMesh:
	var body: Array = []
	for ring in fit:
		body.append(_ring_points(ring, profile))
	var bottom: Dictionary = fit.front()
	var top: Dictionary = fit.back()
	var hem: Array = [_ring_points(bottom, profile, HEM_FOLD), body.front()]
	var collar: Array = [body.back(), _ring_points(top, profile, 0.003, 0.006), _ring_points(top, profile, 0.010, 0.006)]
	var collar_in: Array = [collar[2], _ring_points(top, profile, 0.010, -0.014)]
	var cloth := _new_surface()
	var printed := _new_surface()
	var body_at := _add_band(cloth, body, true)
	var print_at := _add_band(printed, body, true)
	_add_band(cloth, hem)
	_add_band(cloth, collar)
	_add_band(cloth, collar_in)
	# the body's quads go to the print or the cloth by where they stand
	var cell := PRINT_SIZE.x * 0.5 + 0.03
	for i in body.size() - 1:
		for j in COLUMNS:
			var j1 := (j + 1) % COLUMNS
			var mid: Vector3 = (body[i][j] + body[i][j1] + body[i + 1][j] + body[i + 1][j1]) * 0.25
			var front: bool = mid.z < fit[i].cz and absf(mid.x - PRINT_CENTER.x) < cell and absf(mid.y - PRINT_CENTER.y) < PRINT_SIZE.y * 0.5 + RING_STEP * 1.5
			var target := printed if front else cloth
			var base := print_at if front else body_at
			var a := base + i * COLUMNS + j
			var b := base + i * COLUMNS + j1
			for index in [a, b, b + COLUMNS, a, b + COLUMNS, a + COLUMNS]:
				target.i.append(index)
	var mesh := ArrayMesh.new()
	for surface in [cloth, printed]:
		if surface.i.is_empty():
			continue
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = surface.v
		arrays[Mesh.ARRAY_NORMAL] = surface.n
		arrays[Mesh.ARRAY_TEX_UV] = surface.uv
		arrays[Mesh.ARRAY_INDEX] = surface.i
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func _new_surface() -> Dictionary:
	return {"v": PackedVector3Array(), "n": PackedVector3Array(), "uv": PackedVector2Array(), "i": PackedInt32Array()}


## Add a band of rings (each COLUMNS points, in the order whose ring step x column step points out of the cloth):
## its vertices with their averaged quad normals and the print's flat front UVs. Unless `vertices_only`, its quads
## too. Returns the index of its first vertex.
static func _add_band(surface: Dictionary, grid: Array, vertices_only := false) -> int:
	var start: int = surface.v.size()
	var normals: Array = []
	for ring in grid:
		var n := PackedVector3Array()
		n.resize(COLUMNS)
		normals.append(n)
	for i in grid.size() - 1:
		for j in COLUMNS:
			var j1 := (j + 1) % COLUMNS
			var face: Vector3 = (grid[i + 1][j] - grid[i][j1]).cross(grid[i + 1][j1] - grid[i][j])
			for at in [[i, j], [i, j1], [i + 1, j], [i + 1, j1]]:
				normals[at[0]][at[1]] += face
	for i in grid.size():
		for j in COLUMNS:
			var p: Vector3 = grid[i][j]
			surface.v.append(p)
			var n: Vector3 = normals[i][j]
			surface.n.append(n.normalized() if n.length_squared() > 1e-14 else Vector3.UP)
			surface.uv.append(Vector2(0.5 - (p.x - PRINT_CENTER.x) / PRINT_SIZE.x, 0.5 - (p.y - PRINT_CENTER.y) / PRINT_SIZE.y))
	if not vertices_only:
		for i in grid.size() - 1:
			for j in COLUMNS:
				var a := start + i * COLUMNS + j
				var b := start + i * COLUMNS + (j + 1) % COLUMNS
				for index in [a, b, b + COLUMNS, a, b + COLUMNS, a + COLUMNS]:
					surface.i.append(index)
	return start


## A sleeve's rings, fitted to its arm in the link frame: every SLEEVE_STEP of t from the hem up while the arm has
## points there, each the convex hull of the arm's slice (one step either way) plus fit_margin, about the slice's own
## middle. It hangs from its widest ring (narrowing at most SLEEVE_TAPER per metre of arm going down) and its hem is
## eased; a dome closes it over the last ring. No arm found: a plain loose sleeve.
static func _fit_sleeve(points: PackedVector3Array, length: float) -> Array:
	var buckets := {}
	for p in points:
		var cm := floori(p.y * 100.0)
		if not buckets.has(cm):
			buckets[cm] = PackedVector3Array()
		buckets[cm].append(p)
	var out: Array = []
	var t := SLEEVE_HEM
	while t < 1.6:
		var slice := PackedVector2Array()
		for cm in range(floori((t - SLEEVE_STEP) * 100.0), floori((t + SLEEVE_STEP) * 100.0) + 1):
			for p: Vector3 in buckets.get(cm, PackedVector3Array()):
				if absf(p.y - t) <= SLEEVE_STEP:
					slice.append(Vector2(p.x, p.z))
		if slice.size() < 6:
			break
		var hull := Geometry2D.convex_hull(slice)
		var lo := Vector2(INF, INF)
		var hi := Vector2(-INF, -INF)
		for q in hull:
			lo = lo.min(q)
			hi = hi.max(q)
		var mid := (lo + hi) * 0.5
		var need := _hull_radii(hull, mid)
		out.append({"t": t, "mid": mid, "need": need, "r": need.duplicate()})
		t += SLEEVE_STEP
	if out.is_empty():
		for row in [[SLEEVE_HEM, 0.075], [0.75, 0.078], [1.0, 0.08], [1.12, 0.07]]:
			var r := PackedFloat32Array()
			r.resize(COLUMNS)
			r.fill(row[1])
			out.append({"t": row[0], "mid": Vector2.ZERO, "need": r, "r": r.duplicate()})
	for k in range(out.size() - 2, -1, -1):
		var drop: float = SLEEVE_TAPER * (out[k + 1].t - out[k].t) * length
		for j in COLUMNS:
			out[k].r[j] = maxf(out[k].r[j], out[k + 1].r[j] - drop)
	for k in out.size():
		var r: PackedFloat32Array = out[k].r.duplicate()
		for j in COLUMNS:
			var around: float = (out[k].r[(j + COLUMNS - 1) % COLUMNS] + 2.0 * out[k].r[j] + out[k].r[(j + 1) % COLUMNS]) * 0.25
			r[j] = maxf(around, out[k].need[j])
		out[k].r = r
	for j in COLUMNS:
		out[0].r[j] += SLEEVE_EASE
		if out.size() > 1:
			out[1].r[j] += SLEEVE_EASE * 0.5
	return out


## One sleeve in its link's frame (y = t, x and z metres): the tube, a dome over its top, a turned hem at its end.
static func _sleeve_mesh(fit: Array) -> ArrayMesh:
	var tube: Array = []
	for ring in fit:
		tube.append(_sleeve_ring(ring))
	var last: Dictionary = fit.back()
	var close: Dictionary = last.duplicate()
	close.t = last.t + 0.045
	close.r = PackedFloat32Array()
	for j in COLUMNS:
		close.r.append(last.r[j] * 0.62)
	tube.append(_sleeve_ring(close))
	var pole := PackedVector3Array()
	for j in COLUMNS:
		pole.append(Vector3(last.mid.x, last.t + 0.075, last.mid.y))
	var surface := _new_surface()
	_add_band(surface, tube)
	_add_band(surface, [tube.back(), pole])
	_add_band(surface, [_sleeve_ring(fit.front(), HEM_FOLD), tube.front()])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = surface.v
	arrays[Mesh.ARRAY_NORMAL] = surface.n
	arrays[Mesh.ARRAY_INDEX] = surface.i
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func _sleeve_ring(ring: Dictionary, inset := 0.0) -> PackedVector3Array:
	var pts := PackedVector3Array()
	for j in COLUMNS:
		var a := TAU * j / COLUMNS
		var r: float = ring.r[j] - inset
		pts.append(Vector3(ring.mid.x + cos(a) * r, ring.t, ring.mid.y + sin(a) * r))
	return pts


## A node's transform in an ancestor's frame, by its parents' local transforms (in the tree or not).
static func _relative(node: Node3D, ancestor: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var at: Node = node
	while at != null and at != ancestor:
		if at is Node3D:
			t = (at as Node3D).transform * t
		at = at.get_parent()
	return t


## Forget the kept fits (a probe that changed fit_margin); with knit_too, the knit cover's reading as well.
static func forget_fits(knit_too := false) -> void:
	_fits.clear()
	_sleeve_fits.clear()
	if knit_too:
		_knit_rows.clear()


# -- THE STICKER ALPHABET ----------------------------------------------------------------------------------------------
# Ported from ada_encyclopedia/src/lib/sticker-alphabet.ts GLYPHS (2026-11-17): cap height 100, y down, the baseline
# at 100, each glyph's centre-lines from x 0 to x w, drawn with a round cap and join. Upper case only; ÆØÅ ÄÖÜÉ; an
# unknown character draws as '?'.

static func _glyph(ch: String) -> Dictionary:
	if _glyphs.is_empty():
		_glyphs = _alphabet()
	var lower := {"æ": "Æ", "ø": "Ø", "å": "Å", "ä": "Ä", "ö": "Ö", "ü": "Ü", "é": "É", "λ": "Λ", "φ": "Φ", "ϕ": "Φ"}
	var up: String = lower.get(ch, ch.to_upper())
	return _glyphs.get(up, _glyphs["?"])


static func _o(cx: float, rx: float, ry: float = 50.0, cy: float = 50.0) -> String:
	return "M%s,%s A%s,%s 0 1 1 %s,%s A%s,%s 0 1 1 %s,%s" % [_n(cx), _n(cy - ry), _n(rx), _n(ry), _n(cx), _n(cy + ry), _n(rx), _n(ry), _n(cx), _n(cy - ry)]


static func _dot(x: float, y: float) -> String:
	return "M%s,%s L%s,%s" % [_n(x), _n(y - 0.5), _n(x), _n(y + 0.5)]


static func _alphabet() -> Dictionary:
	var g := {}
	var add := func(ch: String, d: String, w: float) -> void: g[ch] = {"d": d, "w": w}
	add.call("A", "M0,100 L32,0 L64,100 M12,64 L52,64", 64)
	add.call("B", "M0,100 L0,0 L32,0 A23,23 0 0 1 32,46 L0,46 M32,46 A27,27 0 0 1 32,100 L0,100", 59)
	add.call("C", "M58,16 A32,50 0 1 0 58,84", 60)
	add.call("D", "M0,0 L0,100 L22,100 A40,50 0 0 0 22,0 Z", 62)
	add.call("E", "M58,0 L0,0 L0,100 L58,100 M0,50 L44,50", 58)
	add.call("F", "M58,0 L0,0 L0,100 M0,50 L44,50", 58)
	add.call("G", "M58,16 A32,50 0 1 0 64,52 L64,52 L38,52", 64)
	add.call("H", "M0,0 L0,100 M60,0 L60,100 M0,50 L60,50", 60)
	add.call("I", "M0,0 L0,100", 0)
	add.call("J", "M44,0 L44,70 A22,30 0 0 1 0,70", 44)
	add.call("K", "M0,0 L0,100 M58,0 L0,60 M20,40 L60,100", 60)
	add.call("L", "M0,0 L0,100 L54,100", 54)
	add.call("M", "M0,100 L0,0 L36,62 L72,0 L72,100", 72)
	add.call("N", "M0,100 L0,0 L60,100 L60,0", 60)
	add.call("O", _o(32, 32), 64)
	add.call("P", "M0,100 L0,0 L32,0 A25,26 0 0 1 32,52 L0,52", 57)
	add.call("Q", _o(32, 32) + " M40,72 L68,106", 66)
	add.call("R", "M0,100 L0,0 L32,0 A25,26 0 0 1 32,52 L0,52 M26,52 L60,100", 60)
	add.call("S", "M57,15 C50,4 40,0 30,0 C13,0 3,10 3,25 C3,58 60,42 60,75 C60,91 47,100 30,100 C17,100 6,94 0,84", 60)
	add.call("T", "M0,0 L64,0 M32,0 L32,100", 64)
	add.call("U", "M0,0 L0,66 A30,34 0 0 0 60,66 L60,0", 60)
	add.call("V", "M0,0 L32,100 L64,0", 64)
	add.call("W", "M0,0 L21,100 L42,30 L63,100 L84,0", 84)
	add.call("X", "M0,0 L60,100 M60,0 L0,100", 60)
	add.call("Y", "M0,0 L32,52 L64,0 M32,52 L32,100", 64)
	add.call("Z", "M0,0 L60,0 L0,100 L60,100", 60)
	add.call("0", _o(28, 28), 56)
	add.call("1", "M4,20 L26,0 L26,100", 26)
	add.call("2", "M3,24 C5,9 17,0 30,0 C46,0 58,10 58,26 C58,46 38,60 0,100 L60,100", 60)
	add.call("3", "M2,12 C10,4 19,0 29,0 C45,0 55,10 55,24 C55,39 43,48 26,48 C46,48 58,58 58,74 C58,90 46,100 28,100 C16,100 6,96 0,88", 58)
	add.call("4", "M44,100 L44,0 L0,70 L62,70", 62)
	add.call("5", "M56,0 L8,0 L3,45 C11,39 20,36 30,36 C48,36 60,48 60,68 C60,88 46,100 28,100 C16,100 6,96 0,88", 60)
	add.call("6", "M52,7 C45,2 39,0 32,0 C12,0 2,22 2,55 C2,85 14,100 32,100 C50,100 60,88 60,70 C60,52 48,42 32,42 C16,42 5,51 2,62", 60)
	add.call("7", "M0,0 L60,0 L22,100", 60)
	add.call("8", "M30,46 C15,46 6,36 6,23 C6,9 16,0 30,0 C44,0 54,9 54,23 C54,36 45,46 30,46 C12,46 2,58 2,73 C2,90 14,100 30,100 C46,100 58,90 58,73 C58,58 48,46 30,46 Z", 60)
	add.call("9", "M8,93 C15,98 21,100 28,100 C48,100 58,78 58,45 C58,15 46,0 28,0 C10,0 0,12 0,30 C0,48 12,58 28,58 C44,58 55,48 58,38", 58)
	add.call(".", _dot(0, 99), 0)
	add.call(",", "M2,94 L-4,110", 2)
	add.call("!", "M0,0 L0,70 " + _dot(0, 99), 0)
	add.call("?", "M2,20 C5,7 15,0 28,0 C44,0 54,10 54,24 C54,42 30,45 30,68 " + _dot(30, 99), 54)
	add.call("-", "M0,60 L36,60", 36)
	add.call("–", "M0,60 L52,60", 52)
	add.call("'", "M0,0 L0,24", 0)
	add.call("’", "M2,0 L-2,24", 2)
	add.call("\"", "M0,0 L0,24 M14,0 L14,24", 14)
	add.call(":", _dot(0, 42) + " " + _dot(0, 99), 0)
	add.call(";", _dot(2, 42) + " M2,94 L-4,110", 2)
	add.call("/", "M40,0 L0,100", 40)
	add.call("&", "M62,100 L14,34 C8,26 6,20 6,16 C6,6 14,0 24,0 C34,0 42,6 42,16 C42,30 26,38 14,46 C4,52 0,62 0,72 C0,88 12,100 28,100 C42,100 54,92 62,74", 64)
	add.call("+", "M0,62 L48,62 M24,38 L24,86", 48)
	add.call("=", "M0,50 L44,50 M0,74 L44,74", 44)
	add.call("(", "M20,-6 C5,18 0,40 0,52 C0,64 5,86 20,110", 20)
	add.call(")", "M0,-6 C15,18 20,40 20,52 C20,64 15,86 0,110", 20)
	add.call("#", "M22,4 L14,96 M48,4 L40,96 M2,34 L60,34 M0,66 L58,66", 60)
	add.call("%", _o(12, 12, 14, 14) + " " + _o(48, 12, 14, 86) + " M60,0 L0,100", 60)
	add.call("*", "M24,22 L24,62 M7,32 L41,52 M7,52 L41,32", 48)
	add.call("×", "M4,40 L44,80 M44,40 L4,80", 48)
	add.call("→", "M0,60 L70,60 M46,38 L70,60 L46,82", 70)
	add.call("←", "M70,60 L0,60 M24,38 L0,60 L24,82", 70)
	add.call("♥", "M30,96 C10,76 0,62 0,44 C0,30 9,22 18,22 C24,22 28,25 30,30 C32,25 36,22 42,22 C51,22 60,30 60,44 C60,62 50,76 30,96 Z", 60)
	add.call("−", "M0,60 L44,60", 44)
	add.call("·", _dot(0, 58), 0)
	add.call("…", _dot(0, 99) + " " + _dot(22, 99) + " " + _dot(44, 99), 44)
	add.call("Λ", "M6,0 L18,0 L60,100 M31,30 L0,100", 60)
	add.call("Φ", _o(30, 28, 28, 56) + " M30,8 L30,112", 60)
	add.call("@", "M66,50 A33,50 0 1 0 50,94 M48,34 A15,20 0 1 0 48,74 A15,20 0 1 0 48,34 M64,34 L64,66 C64,78 76,78 78,62", 78)
	add.call("<", "M48,30 L0,62 L48,94", 48)
	add.call(">", "M0,30 L48,62 L0,94", 48)
	add.call("«", "M30,34 L0,62 L30,90 M60,34 L30,62 L60,90", 60)
	add.call("»", "M0,34 L30,62 L0,90 M30,34 L60,62 L30,90", 60)
	add.call("[", "M20,-6 L0,-6 L0,110 L20,110", 20)
	add.call("]", "M0,-6 L20,-6 L20,110 L0,110", 20)
	add.call("_", "M0,112 L56,112", 56)
	add.call("|", "M0,-6 L0,110", 0)
	add.call("°", _o(10, 10, 10, 12), 20)
	add.call("Æ", "M0,100 L38,0 L84,0 M16,62 L44,62 M44,0 L44,100 L84,100 M44,50 L76,50", 84)
	add.call("Ø", _o(32, 32) + " M66,-4 L-2,104", 64)
	add.call("Å", "M0,100 L32,0 L64,100 M12,64 L52,64 " + _o(32, 9, 9, -22), 64)
	add.call("Ä", "M0,100 L32,0 L64,100 M12,64 L52,64 " + _dot(20, -18) + " " + _dot(44, -18), 64)
	add.call("Ö", _o(32, 32) + " " + _dot(20, -18) + " " + _dot(44, -18), 64)
	add.call("Ü", "M0,0 L0,66 A30,34 0 0 0 60,66 L60,0 " + _dot(18, -18) + " " + _dot(42, -18), 60)
	add.call("É", "M58,0 L0,0 L0,100 L58,100 M0,50 L44,50 M24,-8 L40,-24", 58)
	return g
