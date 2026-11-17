extends Node
## THE OPENING: a brief rooftop anomaly, then the delivery crate lands in black.
## 2026-11-17: the former accidental outside frame is now an authored encounter.
## Wait under the veil for a ready roof, show the black service back for two
## seconds, close the veil and return to the existing crate landing sequence.
##
## Initially the roof appeared from whichever camera happened to be current during scene handover.
## A veil now covers that loading period. Once scene_visible has run, a fixed roof marker
## supplies the intentional outside view. The veil closes before relocation into the crate.
## Its final lift still requires both camera and body inside, steady for a third of a second.
##
## Then, still in black, the crate lands: a rumble that rises, the blow, boards that rattle and settle. The veil
## lifts while the rattle dies away, and what is seen first is the inside of the crate.
##
## ON THE HEADSET the first build of this stayed black for good: the body there is the XR rig's, which has no
## `scripted_input`, and bool(null) is a script error - every frame, before the lift and before the give-up. It had
## only been run on the desktop. So: the walker test reads that property without assuming it is there; a timer
## that does not pass through _process clears the black whatever happens; the XR rig is run by the probe (--xr);
## and each stage prints a line to the log ([opening]), which is what the headset can be asked afterwards.
##
## Only at a start on the roof with an arrival crate. Not after a fall or a retry: this node is made once, by the
## game's _ready, and frees itself. If the visitor is never found inside the crate the veil lifts anyway after
## GIVE_UP seconds, without the sound: nobody is left in the dark. Under a scripted walker (a probe's
## body.scripted_input) the veil lifts at once, unless the run asks for the opening with --opening; --no-opening
## skips it altogether.
const STEADY_FRAMES := 20                 # physics frames the visitor must be measured inside, in a row
const IMPACT_AT := 0.55                   # seconds into the sound at which the crate meets the roof
const HOLD_AFTER_IMPACT := 0.7            # still black, hearing it
const LIFT_SECONDS := 2.4
const GIVE_UP := 10.0
const DRESS_WAIT := 4.0                   # after this the roof's rows are no longer waited for
const FADER := "opening"                # this node's own layer on the XR rig's fade
const SOUND_SECONDS := 3.0
const RATE := 22050
const EXTERIOR_SECONDS := 2.0
const EXTERIOR_CLOSE_SECONDS := .3
const OPERA := "res://commons/void/inner_opera.gd"
const HUD_CONFIG := "res://commons/void/hud_config.gd"

var game: Node3D
var veil: MeshInstance3D
var paint: StandardMaterial3D
var sheet: ColorRect
var stage := "waiting" # waiting -> exterior -> exterior_closing -> waiting -> landed -> lifting
var crate: Node3D
var waited := 0.0
var steady := 0
var since_landed := 0.0
var lifted := 0.0
var sound: AudioStreamPlayer
var forced := false
var told := -1
var exterior_seen := false
var exterior_active := false
var exterior_elapsed := 0.0
var movement_was_enabled := true
var glimpse_hud: Array[Dictionary] = []
var report := {"seen_outside_while_black": false, "inside_when_landed": false, "crate_closed_when_landed": false, "gave_up": false, "scripted": false, "waited_s": 0.0, "sound_played": false}


func _ready() -> void:
	game = get_parent() as Node3D
	# Model B's inner voice (commons/void/inner_opera.gd) lives for the whole game, not only for a start on the roof:
	# it is added here so that game.gd, which carries another hand's work, is not touched a second time.
	if game != null and ResourceLoader.exists(OPERA) and not game.has_meta("inner_opera_added"):
		game.set_meta("inner_opera_added", true)
		game.add_child.call_deferred((load(OPERA) as GDScript).new())
	# the viewfinder's numbers from a file that can be sent to a running game (commons/void/hud_config.gd), added the same way
	if game != null and ResourceLoader.exists(HUD_CONFIG) and not game.has_meta("hud_config_added"):
		game.set_meta("hud_config_added", true)
		game.add_child.call_deferred((load(HUD_CONFIG) as GDScript).new())
	var args := OS.get_cmdline_user_args()
	forced = args.has("--opening")
	if game == null or args.has("--no-opening") or not _applies():
		queue_free()
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = 1000               # after everything that moves a camera this frame
	veil = MeshInstance3D.new()
	veil.name = "OpeningVeil"
	var quad := QuadMesh.new()
	quad.size = Vector2(2, 2)
	veil.mesh = quad
	veil.position.z = -0.06
	veil.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	veil.extra_cull_margin = 100
	paint = StandardMaterial3D.new()
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	paint.no_depth_test = true
	paint.render_priority = 127
	paint.albedo_color = Color(0, 0, 0, 1)
	veil.material_override = paint
	var layer := CanvasLayer.new()        # the desktop window and the mirror: over the heads-up display too
	layer.name = "OpeningSheet"
	layer.layer = 128
	add_child(layer)
	sheet = ColorRect.new()
	sheet.color = Color.BLACK
	sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheet.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(sheet)
	game.set_meta("opening", self)
	_hang()
	_shade(1.0)
	# whatever happens in _process, nobody is left in the dark
	get_tree().create_timer(GIVE_UP + LIFT_SECONDS + 4.0, true).timeout.connect(_rescue)
	print("[opening] black from the first frame; camera %s" % str(get_viewport().get_camera_3d()))


## A start on the roof, where an arrival crate stands.
func _applies() -> bool:
	if int(game.get("checkpoint")) != 0: return false
	var building: Object = game.get("building")
	if building == null or building.get("content") == null: return false
	var floors: Array = building.get("content").get("data").get("floors")
	if floors.is_empty(): return false
	return (floors[0].get("props", []) as Array).any(func(item): return str(item.get("kind", "")) == "arrival_crate")


## The veil hangs in front of whichever camera is drawing the world now.
func _hang() -> void:
	var active := get_viewport().get_camera_3d()
	if active == null: active = game.get("camera") as Camera3D
	if active == null or veil.get_parent() == active: return
	if veil.get_parent() != null: veil.get_parent().remove_child(veil)
	active.add_child(veil)


func _find_crate() -> Node3D:
	var content: Object = game.get("building").get("content")
	var props: Dictionary = content.get("props")
	for key in props:
		if not str(key).begins_with("0/"): continue
		var mount := props[key] as Node
		if mount == null or not is_instance_valid(mount): continue
		var found := mount.get_node_or_null("Prefab") as Node3D
		if found != null and found.has_method("inside") and found.has_method("break_panel"): return found
	return null


## The staging's own camera has the XR rig's fade in front of it: hold that black too, on a layer of this node's.
func _shade(alpha: float) -> void:
	XRToolsFade.set_fade(FADER, Color(0, 0, 0, alpha))


func _rescue() -> void:
	if veil == null: return
	print("[opening] RESCUED by the timer at stage %s after %.1f s: the black is cleared" % [stage, waited])
	report.gave_up = true
	_done()


## A probe's walker says so itself. The XR rig's body has no such property: null, and not an error.
static func scripted(body: Variant) -> bool:
	return body is Object and is_instance_valid(body) and (body as Object).get("scripted_input") == true


## Has everything that stands on the roof been stood there? What is in the crate with the visitor should not
## arrive after the veil has lifted. Not waited for beyond DRESS_WAIT seconds.
func _dressed() -> bool:
	if waited > DRESS_WAIT: return true
	var content: Object = game.get("building").get("content")
	var exhibits: Dictionary = content.get("exhibits")
	for item in content.get("data").get("floors")[0].get("artifacts", []):
		if not exhibits.has("0/%s" % str(item.get("id", ""))): return false
	return true


## Is the visitor known to be inside the crate, now?
func _inside() -> bool:
	if not bool(game.get("ready_for_play")) or not _dressed(): return false
	if crate == null or not is_instance_valid(crate): crate = _find_crate()
	if crate == null: return false
	var active := get_viewport().get_camera_3d()
	var body := game.get("body") as Node3D
	if active == null or body == null: return false
	return bool(crate.call("inside", active.global_position)) and bool(crate.call("inside", body.global_position + Vector3(0, 0.9, 0)))


func _physics_process(_delta: float) -> void:
	if stage != "waiting": return
	if _inside(): steady += 1
	else:
		steady = 0
		if waited > 0.05 and crate != null: report.seen_outside_while_black = true


func _process(delta: float) -> void:
	if veil == null: return
	_hang()
	if game.returning or game.recovering:
		_done();return
	if exterior_active and is_instance_valid(game.status): game.status.hide()
	if exterior_active:
		for entry in glimpse_hud:
			if is_instance_valid(entry.node): entry.node.hide()
	# _ready adds this before the chosen start floor is applied. Direct starts
	# on other floors must never inherit the roof's veil or relocation.
	if game.ready_for_play and game.checkpoint != 0:
		_done();return
	match stage:
		"waiting":
			waited += delta
			if int(waited) != told:
				told = int(waited)
				var active := get_viewport().get_camera_3d()
				print("[opening] waiting %d s: ready %s, roof dressed %s, crate %s, camera inside %s, steady %d" % [told, str(game.get("ready_for_play")), str(_dressed()), str(crate != null and is_instance_valid(crate)),
					str(crate != null and is_instance_valid(crate) and active != null and bool(crate.call("inside", active.global_position))), steady])
			if not forced and scripted(game.get("body")):
				report.scripted = true
				_done()
				return
			if not exterior_seen and game.ready_for_play and _dressed() and _begin_exterior():
				return
			if steady >= STEADY_FRAMES and (exterior_seen or waited>DRESS_WAIT):
				report.inside_when_landed = true
				report.crate_closed_when_landed = not bool(crate.get("broken"))
				report.waited_s = waited
				stage = "landed"
				print("[opening] inside the crate after %.2f s (closed: %s): it lands" % [waited, str(report.crate_closed_when_landed)])
				if report.crate_closed_when_landed: _land()
				else: since_landed = IMPACT_AT + HOLD_AFTER_IMPACT      # an opened crate has already landed: no sound
			elif waited > GIVE_UP:
				report.gave_up = true
				report.waited_s = waited
				stage = "lifting"
				print("[opening] GAVE UP after %.1f s: the visitor was not found inside the crate; lifting without the sound" % waited)
		"exterior":
			exterior_elapsed+=delta
			if exterior_elapsed>=EXTERIOR_SECONDS:
				stage="exterior_closing";exterior_elapsed=0.0
		"exterior_closing":
			exterior_elapsed+=delta
			var alpha := clampf(exterior_elapsed/EXTERIOR_CLOSE_SECONDS,0,1)
			paint.albedo_color.a=alpha;sheet.color.a=alpha;_shade(alpha)
			if alpha>=1.0:
				_finish_exterior()
				steady=0;stage="waiting"
		"landed":
			since_landed += delta
			if since_landed >= IMPACT_AT + HOLD_AFTER_IMPACT: stage = "lifting"
		"lifting":
			lifted += delta
			var t := clampf(lifted / LIFT_SECONDS, 0.0, 1.0)
			var alpha := 1.0 - t * t * (3.0 - 2.0 * t)
			paint.albedo_color.a = alpha
			sheet.color.a = alpha
			_shade(alpha)
			if t >= 1.0: _done()


func _done() -> void:
	if exterior_active: _finish_exterior()
	_shade(0.0)
	print("[opening] lifted: %s" % str(report))
	game.set_meta("opening_report", report.duplicate())
	game.remove_meta("opening")
	if veil.get_parent() != null: veil.get_parent().remove_child(veil)
	veil.queue_free()
	veil = null
	if sound != null and sound.playing:
		# let the last of the rattle be heard; the player frees itself
		sound.reparent(game)
		sound.finished.connect(sound.queue_free)
	queue_free()


func _exit_tree() -> void:
	_restore_glimpse_hud()
	if exterior_active and is_instance_valid(game) and is_instance_valid(game.body):
		game.body.enabled=movement_was_enabled and not game.returning and not game.recovering
	XRToolsFade.set_fade(FADER, Color(0, 0, 0, 0))


func _begin_exterior() -> bool:
	if not game.get_meta("opening_scene_visible",false): return false
	var mount: Node3D=game.building.content.exhibits.get("0/roof-anomaly")
	if mount==null or get_viewport().get_camera_3d()!=game.camera: return false
	var view: Marker3D=mount.get_node_or_null("Artifact/ArrivalView")
	if view==null: return false
	exterior_seen=true;exterior_active=true;exterior_elapsed=0.0
	movement_was_enabled=game.body.enabled
	game.place_player(view.global_position,view.global_rotation.y)
	game.body.enabled=false
	for hud in [game.charge_display,game.desktop_help]:
		if is_instance_valid(hud):
			glimpse_hud.append({"node":hud,"visible":hud.visible})
			hud.hide()
	if is_instance_valid(game.status): game.status.hide()
	stage="exterior"
	paint.albedo_color.a=0.0;sheet.color.a=0.0;_shade(0.0)
	report["exterior_shown"]=true
	report["exterior_seconds"]=EXTERIOR_SECONDS
	print("[opening] rooftop transition/anomaly view")
	return true


func _finish_exterior() -> void:
	exterior_active=false
	_restore_glimpse_hud()
	if not game.returning and not game.recovering: game.place_player_at_spawn(0)
	game.body.enabled=movement_was_enabled and not game.returning and not game.recovering
	if is_instance_valid(game.status): game.status.visible=game.notice_time>0.0


func _restore_glimpse_hud() -> void:
	for entry in glimpse_hud:
		if is_instance_valid(entry.node): entry.node.visible=entry.visible
	glimpse_hud.clear()


## How black it is: 1 black, 0 lifted. For a test.
func blackness() -> float:
	return paint.albedo_color.a if veil != null else 0.0


## ---- the sound of the crate landing, made here: no file ----

func _land() -> void:
	sound = AudioStreamPlayer.new()
	sound.name = "CrateLands"
	sound.stream = landing()
	sound.volume_db = -5.0
	sound.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(sound)
	sound.play()
	report.sound_played = true


## A rumble that rises for IMPACT_AT seconds, the blow, then boards that rattle and settle.
static func landing() -> AudioStreamWAV:
	var count := int(SOUND_SECONDS * RATE)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2611
	var low := 0.0
	var lower := 0.0
	for i in count:
		var t := float(i) / RATE
		var white := rng.randf_range(-1.0, 1.0)
		low = lerpf(low, white, 0.09)
		lower = lerpf(lower, white, 0.012)
		var value := 0.0
		if t < IMPACT_AT:
			var rise := t / IMPACT_AT
			value = lower * 2.6 * rise * rise + sin(TAU * 34.0 * t) * 0.10 * rise
		else:
			var u := t - IMPACT_AT
			var blow := sin(TAU * (58.0 - 60.0 * minf(u, 0.25)) * u) * exp(-u * 6.5) * 0.9
			var crack := low * exp(-u * 24.0) * 1.3
			var rattle := low * exp(-u * 2.4) * 0.5 * (0.55 + 0.45 * sin(TAU * 8.5 * u + sin(u * 23.0)))
			var roll := lower * 2.2 * exp(-u * 1.5)
			var settle := sin(TAU * (290.0 + 70.0 * sin(TAU * 2.6 * u)) * u) * exp(-pow((u - 1.05) / 0.11, 2.0)) * 0.05
			value = blow + crack + rattle + roll + settle
		value *= minf(1.0, (SOUND_SECONDS - t) / 0.35)          # no click at the end
		bytes.encode_s16(i * 2, int(clampf(value, -1.0, 1.0) * 32000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = bytes
	return stream
