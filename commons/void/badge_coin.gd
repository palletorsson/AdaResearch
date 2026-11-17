extends Node3D
## A BADGE COIN in the tower (Palle, 2026-11-17: "bake them real coins in the world we can pick up. They will change
## the player"). Self-contained - not the counting coin (coin_pickup.gd) and not a pick_up_cube: a metal disc 0.2 m
## across, upright, its face SVG (path.json "face", drawn like a research sticker) on its front (+Z) and its back SVG
## on its back, its rim in its family's metal. It moves as its verb does: still; rise (up and down); turn (about its
## upright axis); swell (bigger and smaller) - linear, as Trans_Pre moves before the wave functions are taught.
## The player's body walking into it collects it (pick_up_cube.gd's rule for what a player is): it is kept
## (commons/player/badges.gd), a short chime, it flies to the player and is gone, the game's notice says what it
## gives, and the collation shows for 4 s (group badge_views). A collected coin is never stood again (badge_layer.gd).

const Badges := preload("res://commons/player/badges.gd")
const RADIUS := 0.1          # 0.2 m across
const THICK := 0.016
const FACE := 0.172          # the face picture's side: inside the rim
const REACH := 0.32          # the pickup sphere's radius, round the coin's rest, over its motion
const RISE := 0.12           # rise: metres up and down
const SWELL := 0.25          # swell: 0.75x .. 1.25x
const PERIOD := 1.5          # seconds from one end of a rise or a swell to the other
const TURN := 1.2            # rad / s

var coin_id := ""
var coin: Dictionary = {}
var motion := "still"
var lift := 0.5              # the disc's centre over this node (a 'replaces' coin: where the counting coin's disc stood)
var collected := false
var visual: Node3D
var area: Area3D
var _t := 0.0
static var _chime: AudioStreamWAV
static var last_notice := ""  # what the last collect said (a probe reads it when there is no game)

## Before it enters the tree: which coin it is.
func setup(c: Dictionary, p_lift := 0.5) -> void:
	coin = c;coin_id = str(c.get("id", ""));motion = str(c.get("motion", "still"));lift = p_lift

func _ready() -> void:
	if coin.is_empty() and coin_id != "":coin = Badges.coin(coin_id)
	add_to_group("badge_coins")
	set_meta("badge_coin", coin_id)
	visual = Node3D.new();visual.name = "Coin";visual.position.y = lift;add_child(visual)
	var rim := MeshInstance3D.new();rim.name = "Rim"
	var disc := CylinderMesh.new();disc.top_radius = RADIUS;disc.bottom_radius = RADIUS;disc.height = THICK;disc.radial_segments = 48
	rim.mesh = disc;rim.rotation.x = PI / 2.0   # its axis along Z: the faces look +Z and -Z
	var metal := StandardMaterial3D.new();metal.albedo_color = Badges.tint(str(coin.get("family", "")));metal.metallic = 0.85;metal.roughness = 0.32
	rim.material_override = metal;visual.add_child(rim)
	for side in ["face", "back"]:
		var q := MeshInstance3D.new();q.name = "Face" if side == "face" else "Back"
		var quad := QuadMesh.new();quad.size = Vector2(FACE, FACE);q.mesh = quad
		q.position.z = (THICK * .5 + .0008) * (1.0 if side == "face" else -1.0)
		if side == "back":q.rotation.y = PI
		var tex := Badges.texture(coin_id, side)
		var m := StandardMaterial3D.new()
		if tex != null:
			m.albedo_texture = tex;m.emission_enabled = true;m.emission_texture = tex;m.emission_energy_multiplier = .25
		else:
			m.albedo_color = metal.albedo_color.lightened(.35)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR;m.alpha_scissor_threshold = .5
		m.metallic = .25;m.roughness = .5
		q.material_override = m;q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		visual.add_child(q)
	area = Area3D.new();area.name = "Pickup"
	area.collision_layer = 0;area.collision_mask = 1 | (1 << 19)   # as the pickup cube: world bodies (the desktop walker's) and the player body
	area.monitorable = false
	var shape := CollisionShape3D.new();var sphere := SphereShape3D.new();sphere.radius = REACH;shape.shape = sphere
	area.add_child(shape);area.position.y = lift;add_child(area)
	area.body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if collected or visual == null:return
	_t += delta
	match motion:
		"rise":visual.position.y = lift + lerpf(-RISE, RISE, pingpong(_t / PERIOD + .5, 1.0))
		"turn":visual.rotation.y = fmod(visual.rotation.y + TURN * delta, TAU)
		"swell":visual.scale = Vector3.ONE * lerpf(1.0 - SWELL, 1.0 + SWELL, pingpong(_t / PERIOD + .5, 1.0))

## pick_up_cube.gd's rule: layer 1 also carries ordinary world bodies, so overlap alone must not collect.
func _is_player(body: Node3D) -> bool:
	return body.is_in_group("player") or body.is_in_group("vr_player") or body.name.contains("Player") or body.is_in_group("player_body") or body.is_in_group("em_walker")

func _on_body_entered(body: Node3D) -> void:
	if _is_player(body):collect()

func collect() -> void:
	if collected or coin_id == "":return
	collected = true
	area.set_deferred("monitoring", false)
	var c := Badges.collect(coin_id)
	_play_chime()
	var game: Node = get_tree().get_first_node_in_group("void_game")
	var vr := bool(game.get("vr")) if game != null else (XRServer.primary_interface != null and XRServer.primary_interface.is_initialized())
	last_notice = Badges.collected_notice(c if not c.is_empty() else coin, vr)
	if game != null and game.has_method("_notice"):game._notice(last_notice)
	else:print("[badges] ", last_notice.replace("\n", " / "))
	get_tree().call_group("badge_views", "show_for", 4.0)
	_fly()

## To the player and gone: the disc flies to a little below the eyes, shrinking, then the coin is freed.
func _fly() -> void:
	var cam := get_viewport().get_camera_3d()
	var to: Vector3 = (cam.global_transform * Vector3(0, -.22, -.3)) if cam != null else visual.global_position + Vector3.UP * .5
	visual.top_level = true   # the floor may move or sleep under it; the flight is in the world
	var tw := create_tween().set_parallel(true)
	tw.tween_property(visual, "global_position", to, .38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(visual, "scale", Vector3.ONE * .25, .38)
	tw.chain().tween_callback(queue_free)

func _play_chime() -> void:
	if _chime == null:_chime = _make_chime()
	var p := AudioStreamPlayer.new();p.stream = _chime;p.volume_db = -8.0
	get_tree().root.add_child(p);p.play()
	p.finished.connect(p.queue_free)

## Two short rising bells (a fifth apart), 0.42 s, made once.
static func _make_chime() -> AudioStreamWAV:
	const RATE := 22050
	var n := int(RATE * .42)
	var data := PackedByteArray();data.resize(n * 2)
	for i in n:
		var t := float(i) / RATE
		var s := 0.0
		for note in [[1046.5, 0.0], [1568.0, .11]]:
			var at: float = t - float(note[1])
			if at >= 0.0:s += sin(TAU * float(note[0]) * at) * exp(-at * 9.0) * .32
		var v := clampi(int(s * 32767.0), -32768, 32767)
		data.encode_s16(i * 2, v)
	var w := AudioStreamWAV.new();w.format = AudioStreamWAV.FORMAT_16_BITS;w.mix_rate = RATE;w.stereo = false;w.data = data
	return w
