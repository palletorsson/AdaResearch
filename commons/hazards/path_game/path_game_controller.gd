extends Node3D
class_name PathGameController

# @identity
# essence: the rulebook of the path-and-block game made into a node — it watches the two ways to win (reach the teleporter, or befriend every builder) and the one way to lose (let the path stay sealed past the clock), and it answers each with a 3D-pixel reaction badge so the outcome is felt, not just scored.
# desire: to close the loop. The watchdog judges the path; the catalyst flips the foe; this controller is where those two truths become a win or a loss, and where the thumb and the heart get their moment.
# critical_parameter: win_on_all_befriended — whether converting every builder counts as a clear. With it on, the game has a pacifist solution (change their minds) standing beside the racer's solution (reach the exit); with it off, only the exit clears.
# triggers: _ready wires watchdog.level_cleared/level_failed and every enemy's personality_changed; a foe reaching "friend" pops a thumb over it and re-checks the all-befriended condition; a clear pops a heart.
# emerges: a thumb blooming over a converted builder is the catalyst's whole thesis in one image — you didn't destroy it, you changed its mind, and the game says yes.
# relationships: referee's reader (path_watchdog), the catalyst arc's listener (HazardCreatureBase.personality_changed), the pixel_icon badges' summoner; the seam where the path-and-block systems become a game.
# truth: a game is two truths and a verdict — can you still cross, and did you have to destroy anything to do it. The thumb is the answer to the second.

## Win/lose controller for the path-and-block game.
##   WIN A: the player reaches the teleporter (watchdog.level_cleared).
##   WIN B: every foe (group "enemy") reaches the "friend" pole.
##   LOSE : the path stays blocked past the grace window
##          (watchdog.level_failed).
## Befriending a foe pops a pixel_thumb over it; a win pops a pixel_heart.

signal game_won(reason: String)
signal game_lost

@export var win_on_all_befriended: bool = true
## Badge floated over a foe the moment it becomes a friend.
@export var befriend_badge: String = "thumb"
## Badge popped on a win.
@export var celebrate_badge: String = "heart"
@export var badge_size: float = 0.3
## Editor/capture self-test: "badge" spawns both badges here on load;
## "clear" simulates reaching the exit; "befriend" flips all foes.
## Leave "" for normal play.
@export var debug_test: String = ""

const THUMB_SCENE := preload("res://commons/primitives/pixel_icon/pixel_thumb.tscn")
const HEART_SCENE := preload("res://commons/primitives/pixel_icon/pixel_heart.tscn")

var _watchdog: Node = null
var _foes: Array = []
var _befriended: Dictionary = {}
var _over: bool = false


func _ready() -> void:
	_read_metadata_overrides()
	call_deferred("_wire")


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()


func _read_metadata_overrides() -> void:
	if has_meta("config_debug_test"):
		debug_test = str(get_meta("config_debug_test")).to_lower()
	if has_meta("config_win_on_all_befriended"):
		var v := str(get_meta("config_win_on_all_befriended")).to_lower()
		win_on_all_befriended = v in ["true", "1", "yes", "on"]


# ── Wiring ────────────────────────────────────────────────────────────

func _wire() -> void:
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		return
	_watchdog = get_tree().get_first_node_in_group("path_watchdog")
	if _watchdog:
		if _watchdog.has_signal("level_cleared") and not _watchdog.level_cleared.is_connected(_on_reached_exit):
			_watchdog.level_cleared.connect(_on_reached_exit)
		if _watchdog.has_signal("level_failed") and not _watchdog.level_failed.is_connected(_on_failed):
			_watchdog.level_failed.connect(_on_failed)

	for n in get_tree().get_nodes_in_group("enemy"):
		if n.has_method("get_personality"):
			_foes.append(n)
			if n.has_signal("personality_changed") and not n.personality_changed.is_connected(_on_foe_personality):
				n.personality_changed.connect(_on_foe_personality.bind(n))
			# A foe that already starts as a friend counts immediately.
			if str(n.get_personality()) == "friend":
				_befriended[n] = true

	_run_debug()


# ── Win / lose ────────────────────────────────────────────────────────

func _on_foe_personality(_from_p: String, to_p: String, foe: Node) -> void:
	if _over:
		return
	if to_p == "friend" and not _befriended.has(foe):
		_befriended[foe] = true
		if foe is Node3D:
			_spawn_badge(befriend_badge, (foe as Node3D).global_position + Vector3(0, 1.4, 0), 3.5)
		_check_befriend_win()


func _check_befriend_win() -> void:
	if not win_on_all_befriended or _foes.is_empty() or _over:
		return
	for f in _foes:
		if not _befriended.has(f):
			return
	_win("all_befriended")


func _on_reached_exit() -> void:
	_win("reached_exit")


func _on_failed() -> void:
	if _over:
		return
	_over = true
	game_lost.emit()


func _win(reason: String) -> void:
	if _over:
		return
	_over = true
	# Celebrate at the player's position if we can find one, else here.
	var pos := global_position + Vector3(0, 1.6, 0)
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty() and players[0] is Node3D:
		pos = (players[0] as Node3D).global_position + Vector3(0, 1.4, 0)
	_spawn_badge(celebrate_badge, pos, 5.0)
	game_won.emit(reason)


# ── Badge ─────────────────────────────────────────────────────────────

func _spawn_badge(kind: String, world_pos: Vector3, lifetime: float) -> Node3D:
	var scene: PackedScene = HEART_SCENE if kind == "heart" else THUMB_SCENE
	var badge: Node3D = scene.instantiate()
	badge.set("target_size", badge_size)
	var root := get_tree().current_scene
	if root == null:
		root = self
	root.add_child(badge)
	badge.global_position = world_pos
	# Gentle rise + auto-free (a momentary reaction, not a permanent prop).
	if lifetime > 0.0:
		var tw := badge.create_tween()
		tw.tween_property(badge, "global_position", world_pos + Vector3(0, 0.4, 0), lifetime)
		tw.parallel().tween_property(badge, "scale", Vector3.ONE * 1.15, lifetime)
		tw.tween_callback(badge.queue_free)
	return badge


# ── Debug self-test (editor / capture only) ───────────────────────────

func _run_debug() -> void:
	match debug_test:
		"badge":
			_spawn_badge("thumb", global_position + Vector3(-0.4, 1.4, 0), 0.0)
			_spawn_badge("heart", global_position + Vector3(0.4, 1.4, 0), 0.0)
		"clear":
			_on_reached_exit()
		"befriend":
			for f in _foes:
				if f.has_method("set_personality"):
					f.set_personality("friend")
				_on_foe_personality("curious", "friend", f)
