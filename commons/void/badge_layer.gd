extends RefCounted
## THE BADGE COINS ON A FLOOR (Palle, 2026-11-17: the coins "connected to the walking path so we know a possible
## order"). floor_content.gd calls build() beside the timeline walk for every floor of the MAIN tower (no trial): this
## floor's coins that the player has not collected are stood under the floor's root - a coin with `replaces` exactly
## where that work stood (its position, height and facing, as floor_content._build_artifact mounts a work), a coin with
## `stop` hovering over the walk's stand for that stop. The work a coin replaces is not stood at all (replaced()).
## It also makes sure the game has ONE collation (commons/player/badges_view.gd) and ONE verbs node
## (commons/player/badge_verbs.gd: the desktop keys and the VR stick for translate and scale).

const Badges := preload("res://commons/player/badges.gd")
const CoinScene := preload("res://commons/void/badge_coin.tscn")
const SongField := preload("res://commons/void/song_field.gd")
const FramedField := preload("res://commons/void/framed_song_field.gd")
const Trail := preload("res://commons/void/opening_opera_trail.gd")
const EncounterFrame := preload("res://commons/void/encounter_note_frame.gd")
const ViewLib := preload("res://commons/player/badges_view.gd")
const VerbsLib := preload("res://commons/player/badge_verbs.gd")
const HOVER := 1.1          # a 'stop' coin's centre over the stand's surface
const REPLACE_LIFT := 0.5   # a 'replaces' coin's disc over the work's mount: where the counting coin's disc stood
static var _view: WeakRef
static var _verbs: WeakRef

## The ids of the works this floor's coins stand in place of: floor_content.gd does not stand them.
static func replaced(index: int, map := "") -> Array:
	return Badges.replaced(index, map)

## Stand uncollected coins and persistent song fields under the floor's content root.
static func build(host: Node3D, index: int) -> Node3D:
	ensure_singletons(host)
	var map := str(host.get_meta("map", ""))
	var placements := Trail.placements(map)
	for id in placements:
		var entry: Dictionary = placements[id]
		if entry.get("kind") == "encounter":
			var frame := EncounterFrame.new()
			frame.set_meta("encounter_id", id)
			frame.caption = entry.title
			frame.aperture = Vector2(entry.width, entry.height) / 2.0
			host.add_child(frame)
			frame.apply_floor_pose(host, entry)
	var standing: Array = Badges.coins_on(index, map)
	if standing.is_empty():return null
	var frames := Trail.frames(map)
	var root := Node3D.new();root.name = "BadgeCoins";host.add_child(root)
	for source in standing:
		var c: Dictionary = source
		if Trail.POLICIES.has(map) and c.has("song") and frames.get(c.song, {}).get("badge", "") != c.id:
			# A reserve badge still collects and recharges in the opening edition.
			c = c.duplicate()
			c.erase("song")
		var coin: Node3D = CoinScene.instantiate()
		coin.name = "Coin_" + str(c.get("label", c.id)).validate_node_name()
		if c.get("at") is Array and c.at.size() == 3:
			coin.setup(c, 0.0)
			coin.position = Vector3(float(c.at[0]), float(c.at[1]), float(c.at[2]))
			coin.rotation_degrees.y = float(c.get("facing", 0.0))
		elif str(c.get("replaces", "")) != "" and c.get("position") is Array:
			var at: Array = c.position
			coin.setup(c, REPLACE_LIFT)
			coin.position = Vector3(float(at[0]), float(c.get("height", 0.0)), float(at[1]))
			coin.rotation_degrees.y = float(c.get("facing", 0.0))
		elif c.get("stand") is Array:
			var stand: Array = c.stand
			coin.setup(c, 0.0)
			coin.position = Vector3(float(stand[0]), float(c.get("y", 0.0)) + HOVER, float(stand[1]))
			coin.rotation_degrees.y = float(c.get("facing", 0.0))
		else:
			push_warning("badges: coin %s has neither a work it replaces nor a stand" % str(c.id))
			coin.free();continue
		coin.set_meta("badge_n", c.get("n", 0))
		# The listening place survives collection and streamed floor rebuilds.
		# Its horizontal position follows the same editable badge placement.
		if not str(c.get("song", "")).is_empty():
			var field: SongField
			if frames.has(c.song) and frames[c.song].badge == c.id:
				var framed := FramedField.new()
				framed.configure_frame(host, frames[c.song].view_frame)
				field = framed
			else:
				field = SongField.new()
			field.name = "Voice_"+str(c.id).validate_node_name()
			field.setup(c,index)
			field.position = Vector3(coin.position.x,maxf(0.0,coin.position.y+coin.lift-HOVER),coin.position.z)
			root.add_child(field)
		if Badges.has(str(c.id)): coin.free()
		else: root.add_child(coin)
	return root

## One collation view and one verbs node for the game (or the scene, in a probe), made the first time any floor builds.
static func ensure_singletons(near: Node) -> void:
	if not near.is_inside_tree():return
	var tree := near.get_tree()
	var parent: Node = tree.get_first_node_in_group("void_game")
	if parent == null:parent = tree.current_scene if tree.current_scene != null else tree.root
	if _view == null or _view.get_ref() == null or not is_instance_valid(_view.get_ref()):
		var view: Node3D = ViewLib.new();view.name = "BadgesView"
		_view = weakref(view);parent.add_child.call_deferred(view)
	if _verbs == null or _verbs.get_ref() == null or not is_instance_valid(_verbs.get_ref()):
		var verbs: Node = VerbsLib.new();verbs.name = "BadgeVerbs"
		_verbs = weakref(verbs);parent.add_child.call_deferred(verbs)
