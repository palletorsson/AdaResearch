extends RefCounted
## THE BADGE COINS, READ (Palle, 2026-11-17: "let the badges be ... real coins in the world we can pick up. They will
## change the player and be collected in the badges collation"). The game's one reader of
## commons/data/badges/path.json - DERIVED by tools/badge_coins.ts from the authored commons/data/badges/coins.json;
## never read coins.json here - and the keeper of which coins this player has collected (user://badges/collected.json).
## Static, so the floor's coin layer (commons/void/badge_layer.gd), the coin (badge_coin.gd), the inventory's verbs
## (badge_verbs.gd) and the collation (badges_view.gd) all get the same answers. Preload it by path: a new class_name
## is not in Godot's class cache until the editor scans.
##
## A coin that `gives` a verb (pick, translate, rotate, scale) unlocks it when collected (Palle chose 2026-11-17: the
## verbs act on the things the player PLACES with the inventory wand, LOCKED until their coin is collected). A verb no
## coin of the path gives is not locked - with no path.json at all the inventory behaves as it did before the coins.
## `--all-badges` (a user arg, after `--`) or `grant_all` grants every verb without collecting anything.
## collected.json keeps the ORDER of collecting, newest last (Palle 2026-11-17: the player's t-shirt wears the LAST badge:
## last_collected()); every new collect calls the group "badge_listeners" with badge_collected(id).

const PATH_DEFAULT := "res://commons/data/badges/path.json"
const COLLECTED_DEFAULT := "user://badges/collected.json"
const RASTER := 256                     # px on the long side of a face texture (the stickers' size)
const Trajectory := preload("res://commons/void/trajectory_runtime.gd")

static var path_file := PATH_DEFAULT          # a probe points this at a fixture
static var collected_file := COLLECTED_DEFAULT   # a probe points this at ada_run/badges/, never at the game's user://
static var grant_all := false                 # a probe's (or a dev's) every verb

static var _path: Dictionary = {}
static var _coins: Array = []
static var _by_id: Dictionary = {}
static var _loaded := false
static var _collected: Array = []             # [{id, at}] in the order collected, newest last
static var _collected_loaded := false
static var _textures: Dictionary = {}         # "id|face" -> Texture2D (null when the SVG did not draw)

## Forget everything read (a probe that changed path_file or collected_file, or a file written by another process). NOT named
## reload(): Badges.reload() would be GDScript.reload(), which recompiles this script and resets every static var.
static func reread() -> void:
	_loaded = false;_collected_loaded = false
	_path = {};_coins = [];_by_id = {};_collected = [];_textures = {}
	Trajectory.reread()

static func _read_path() -> void:
	if _loaded:return
	_loaded = true;_path = {};_coins = [];_by_id = {}
	if not FileAccess.file_exists(path_file):return   # no path yet: no coins, nothing locked
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path_file))
	if not parsed is Dictionary or not (parsed as Dictionary).get("coins") is Array:
		push_warning("badges: %s is not a coin path" % path_file);return
	_path = parsed
	# Fixtures opt out of the live outline; the actual game and editor share it.
	var effective: Array = Trajectory.coins(_path.coins) if path_file == PATH_DEFAULT else _path.coins
	for c in effective:
		if c is Dictionary and str(c.get("id", "")) != "":_coins.append(c)
	_coins.sort_custom(func(a, b):return float(a.get("n", 0)) < float(b.get("n", 0)))
	for c in _coins:_by_id[str(c.id)] = c

## The whole path file ({} when there is none).
static func data() -> Dictionary:
	_read_path();return _path

## Every coin of the path, in number order.
static func coins() -> Array:
	_read_path();return _coins

static func count() -> int:
	return coins().size()

static func coin(id: String) -> Dictionary:
	_read_path();return _by_id.get(id, {})

static func families() -> Dictionary:
	var f: Variant = data().get("families", {})
	return f if f is Dictionary else {}

static func verbs() -> Dictionary:
	var v: Variant = data().get("verbs", {})
	return v if v is Dictionary else {}

## The coins standing on one floor of the tower, in number order. By the floor's MAP when it is given (a floor inserted
## above shifts every index below it - 2026-11-09), else by its index.
static func coins_on(floor_index: int, map := "") -> Array:
	return coins().filter(func(c):return str(c.get("floor", "")) == map if map != "" else int(c.get("floor_index", -1)) == floor_index)

## The ids of the works a coin stands in place of on this floor: they are not stood (collected coin or not).
static func replaced(floor_index: int, map := "") -> Array:
	var out: Array = []
	for c in coins_on(floor_index, map):
		if str(c.get("replaces", "")) != "":out.append(str(c.replaces))
	return out

# -- WHAT THIS PLAYER HAS ----------------------------------------------------------------------------------------------

static func _read_collected() -> void:
	if _collected_loaded:return
	_collected_loaded = true;_collected = []
	if not FileAccess.file_exists(collected_file):return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(collected_file))
	if not parsed is Dictionary:return
	var rows: Variant = (parsed as Dictionary).get("collected")
	if rows is Array:   # [{id, at}], in the order collected
		for row in rows:
			if row is Dictionary and str(row.get("id", "")) != "" and not has_in(_collected, str(row.id)):_collected.append({"id": str(row.id), "at": int(row.get("at", 0))})
	elif rows is Dictionary:   # an older {id: at}: ordered by the time each was collected
		for id in rows:_collected.append({"id": str(id), "at": int(rows[id])})
		_collected.sort_custom(func(a, b):return int(a.at) < int(b.at))

static func has_in(rows: Array, id: String) -> bool:
	for row in rows:
		if str(row.id) == id:return true
	return false

static func has(id: String) -> bool:
	_read_collected();return has_in(_collected, id)

## The collected ids that are coins of the path, in number order.
static func collected_ids() -> Array:
	_read_collected()
	return coins().filter(func(c):return has_in(_collected, str(c.id))).map(func(c):return str(c.id))

## The collected ids in the order they were collected, newest last.
static func collect_order() -> Array:
	_read_collected()
	return _collected.map(func(row):return str(row.id))

## The coin collected last ({} when none is) - what the player's t-shirt wears.
static func last_collected() -> Dictionary:
	var order := collect_order()
	for i in range(order.size() - 1, -1, -1):
		var c := coin(str(order[i]))
		if not c.is_empty():return c
	return {}

static func collected_count() -> int:
	return collected_ids().size()

## Collect a coin: kept at once (a temp file, then renamed over the old), newest last; a NEW collect calls
## badge_collected(id) on the group "badge_listeners" (the t-shirt, the collation). Returns the coin ({} for an id not
## on the path).
static func collect(id: String) -> Dictionary:
	var c := coin(id)
	if c.is_empty():return {}
	_read_collected()
	if not has_in(_collected, id):
		_collected.append({"id": id, "at": int(Time.get_unix_time_from_system())})
		_save()
		var tree := Engine.get_main_loop() as SceneTree
		if tree != null:tree.call_group("badge_listeners", "badge_collected", id)
	return c

## Forget what was collected (a probe, a fresh start): the file is rewritten empty.
static func forget_all() -> void:
	_read_collected();_collected = [];_save()

static func _save() -> bool:
	var abs_path := ProjectSettings.globalize_path(collected_file)
	DirAccess.make_dir_recursive_absolute(abs_path.get_base_dir())
	var f := FileAccess.open(abs_path + ".tmp", FileAccess.WRITE)
	if f == null:push_warning("badges: could not keep the collected coins at " + abs_path);return false
	f.store_string(JSON.stringify({"version": 1, "collected": _collected}, "  ") + "\n");f.close()
	if FileAccess.file_exists(abs_path):DirAccess.remove_absolute(abs_path)
	return DirAccess.rename_absolute(abs_path + ".tmp", abs_path) == OK

# -- THE VERBS ---------------------------------------------------------------------------------------------------------

static func all_granted() -> bool:
	return grant_all or "--all-badges" in OS.get_cmdline_user_args()

## The coin that gives a verb ({} when none does).
static func giver(verb: String) -> Dictionary:
	for c in coins():
		if str(c.get("gives", "")) == verb:return c
	return {}

## May the player use this verb now? A collected coin gives it; all are granted; or no coin of the path gives it.
static func can(verb: String) -> bool:
	if all_granted():return true
	var givers: Array = coins().filter(func(c):return str(c.get("gives", "")) == verb)
	if givers.is_empty():return true
	for c in givers:
		if has(str(c.id)):return true
	return false

## How the verb is done here, in the words of path.json's verbs (desktop or VR).
static func how(verb: String, vr := false) -> String:
	var v: Dictionary = verbs().get(verb, {})
	return str(v.get("vr" if vr else "desktop", ""))

## The game's notice when a coin is collected: "COIN 02 / TRANSLATE\nmove a thing you placed a little - G pushes, ...".
static func collected_notice(c: Dictionary, vr := false) -> String:
	var head := "COIN %s / %s" % [str(c.get("label", "%02d" % int(c.get("n", 0)))), str(c.get("name", c.get("id", ""))).to_upper()]
	var verb := str(c.get("gives", ""))
	if verb == "" or not verbs().has(verb):return head + "\n" + str(c.get("text", "")).to_lower()
	var does := str(verbs()[verb].get("does", "")).get_slice(":", 0).strip_edges()
	return head + "\n" + does + " - " + how(verb, vr)

## The notice for a verb still locked: whose coin it is and where it stands.
static func locked_notice(verb: String) -> String:
	var c := giver(verb)
	var title := str(verbs().get(verb, {}).get("title", verb)).to_upper()
	if c.is_empty():return title + " IS LOCKED"
	return "%s IS LOCKED\nits coin, %s, is on %s" % [title, str(c.get("label", "")), str(c.get("floor", "")).replace("_", " ")]

# -- THE FACES ---------------------------------------------------------------------------------------------------------

## A coin's face ("face") or back ("back") drawn once from its SVG as the stickers are (commons/stickers/sticker_data.gd
## texture(): ThorVG at RASTER px on the long side, edges bled, mipmapped) and cached by coin id. Null when it has none.
static func texture(id: String, side := "face") -> Texture2D:
	var key := id + "|" + side
	if _textures.has(key):return _textures[key]
	var svg := str(coin(id).get(side, ""))
	var tex: Texture2D = null
	if svg != "":
		var long := maxf(_svg_size(svg, "width"), _svg_size(svg, "height"))
		var img := Image.new()
		if img.load_svg_from_string(svg, float(RASTER) / (long if long > 0.0 else float(RASTER))) == OK and not img.is_empty():
			img.fix_alpha_edges();img.generate_mipmaps()
			tex = ImageTexture.create_from_image(img)
	_textures[key] = tex
	return tex

static func _svg_size(svg: String, attr: String) -> float:
	var at := svg.find(" %s=\"" % attr)
	if at < 0:return 0.0
	var from := at + attr.length() + 3
	return float(svg.substr(from, svg.find("\"", from) - from))

## A family's tint: path.json's own ("tint" / "color") when it names one, else the coin's metal for the family.
static func tint(family: String) -> Color:
	var f: Dictionary = families().get(family, {})
	for k in ["tint", "color", "colour"]:
		if f.has(k) and Color.html_is_valid(str(f[k])):return Color(str(f[k]))
	return {"basic": Color("c9a24a"), "complex": Color("c4703f"), "paradox": Color("b05fa8"), "edge": Color("4f9aa6")}.get(family, Color("b8b8b0"))
