extends Node3D
## A persistent, non-solid listening place. Badge ownership is independent.
const HEIGHT := 2.0
const ENTER_RADIUS := .7
const LEAVE_RADIUS := .95
const REARM_SECONDS := .4
const SYMBOL_OPACITY := .22
const CIRCLE_OPACITY := .14
const READY := Color("ef78ac")
const WAITING := Color("8d8992")
const SINGING := Color("fff0db")
static var _speaker: Texture2D
var song_id := ""
var badge_id := ""
var floor_index := -1
var inside := false
var consumed := false
var outside_seconds := 0.0
var enabled := false
var symbol: MeshInstance3D
var ring: MeshInstance3D
var _symbol_material: StandardMaterial3D
var _ring_material: StandardMaterial3D
var _appearance := ""

func setup(coin: Dictionary, index: int) -> void:
	song_id = str(coin.get("song", "")); badge_id = str(coin.id); floor_index = index

func _ready() -> void:
	add_to_group("song_fields")
	set_meta("song_id", song_id); set_meta("badge_id", badge_id)
	_build_indicator()

func _build_indicator() -> void:
	if _speaker == null:
		var image := Image.new()
		image.load_svg_from_string('<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128"><circle cx="64" cy="64" r="58" fill="#11151d" stroke="#ffffff" stroke-width="4"/><path d="M27 51H43L62 35V93L43 77H27Z" fill="#ffffff"/><path d="M76 46Q96 64 76 82M86 34Q118 64 86 94" fill="none" stroke="#ffffff" stroke-width="6" stroke-linecap="round"/></svg>')
		_speaker = ImageTexture.create_from_image(image)
	symbol = MeshInstance3D.new(); symbol.name = "VoiceSymbol"
	var quad := QuadMesh.new(); quad.size = Vector2(.38,.38); symbol.mesh = quad
	symbol.position.y = HEIGHT
	_symbol_material = StandardMaterial3D.new()
	_symbol_material.albedo_texture = _speaker
	_symbol_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_symbol_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_symbol_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_symbol_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	symbol.material_override = _symbol_material; symbol.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(symbol)
	ring = MeshInstance3D.new(); ring.name = "ListeningCircle"
	var torus := TorusMesh.new(); torus.inner_radius = ENTER_RADIUS-.015; torus.outer_radius = ENTER_RADIUS+.015
	torus.rings = 32; torus.ring_segments = 6; ring.mesh = torus; ring.position.y = .025
	_ring_material = StandardMaterial3D.new(); _ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = _ring_material; ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)
	show_state(false, false)
	_settle_on_surface()

func _settle_on_surface() -> void:
	# Badge height can describe a wall-mounted work, not the standing surface.
	# Resolve once after physics registration; preserve raised walkable stands.
	for tick in 3: await get_tree().physics_frame
	if not is_inside_tree(): return
	var floor_y: float = (get_parent() as Node3D).global_position.y
	var start := global_position+Vector3.UP*.15
	var finish := Vector3(start.x,floor_y-.25,start.z)
	if start.y<=finish.y: return
	var query := PhysicsRayQueryParameters3D.create(start,finish,1|2)
	for attempt in 8:
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty(): return
		if hit.collider is StaticBody3D and hit.normal.y>.7:
			global_position.y=hit.position.y
			return
		var exclusions: Array[RID] = query.exclude
		exclusions.append(hit.rid)
		query.exclude=exclusions

## Hysteresis prevents boundary jitter. Staying or turning within the circle
## never repeats a line; leave fully for 0.4 seconds before a new visit.
func update_presence(feet: Vector3, delta: float, allowed: bool) -> void:
	enabled = allowed
	var local := to_local(feet)
	var distance := Vector2(local.x,local.z).length()
	var same_level := local.y >= -.4 and local.y < 2.2 and is_visible_in_tree()
	if not same_level or distance > LEAVE_RADIUS:
		inside = false
		outside_seconds += maxf(delta,0)
		if outside_seconds >= REARM_SECONDS: consumed = false
	elif distance <= ENTER_RADIUS:
		inside = true; outside_seconds = 0.0

func wants_song() -> bool:
	return inside and enabled and not consumed

func mark_started() -> void:
	consumed = true

func show_state(available: bool, playing: bool) -> void:
	var state := "playing" if playing else "ready" if available else "waiting"
	if state == _appearance: return
	_appearance = state
	var ink := SINGING if playing else READY if available else WAITING
	ink.a=SYMBOL_OPACITY
	_symbol_material.albedo_color = ink
	var circle_ink := ink.darkened(.25)
	circle_ink.a=CIRCLE_OPACITY
	_ring_material.albedo_color = circle_ink
