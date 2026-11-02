extends Node3D
## THE COMFORT VIGNETTE (Palle, 2026-11-02: "in vr to stop motion sickness when jumping ... dynamic vignette ...
## on jump it should be instant ... could be made a general feature"). A dark ring at the edge of sight that
## closes while the GAME moves the player's body, never while the head moves. Three channels; the strongest wins:
##   air  - airborne and rising or falling: a jump, a bounce, a drop down a shaft. Closes INSTANTLY, harder the
##          faster; holds through the one-frame touchdowns between bounces, then opens over `release` seconds.
##   walk - stick locomotion and rides: eases in over `walk_ease` seconds in proportion to speed, gentle at most.
##          `walk_delay` (default 0) keeps it back until the walk has lasted that long (Palle's 2 s, one number away).
##   turn - smooth turning closes it at once; snap turns (the rig's default) and teleports never do.
## It lives on XRCamera3D in museum_rig.tscn, so the museum and the Void both carry it; on the desktop the rig is
## disabled. The ring is drawn in clip space with XR Tools' vignette shader (its inner circle follows each eye's
## centre). Probe: commons/testing/probe_comfort_vignette.tscn.

const SHADER := preload("res://addons/godot-xr-tools/effects/vignette.gdshader")
const STEPS := 32

@export_range(0.0, 1.5) var strength := 1.0       ## 0 turns it off; 1.5 is strong
@export var inner_radius := 0.4                    ## the opening at full closure (1 = wide open)
@export var softness := 0.3                        ## width of the edge's fade
@export var color := Color(0, 0, 0, 1)
@export_group("Air")
@export var air_speed := 1.5      ## m/s up or down, airborne, before it counts (a drop of about 11 cm)
@export var air_min := 0.55       ## closure at that speed
@export var air_max := 0.85       ## closure at air_full
@export var air_full := 9.0       ## m/s; a bounce to 4 m leaves the floor at 8.9
@export var hold := 0.2           ## s it stays closed after touching down
@export var release := 0.5        ## s to open fully from closed
@export_group("Walk")
@export var walk_max := 0.3       ## closure at walk_full
@export var walk_full := 3.0      ## m/s, the Void's walking speed
@export var walk_ease := 0.4      ## s, time constant in and out
@export var walk_delay := 0.0     ## s of continuous walking before the walk channel starts
@export_group("Turn")
@export var turn_max := 0.7       ## closure at turn_full
@export var turn_full := 2.0      ## rad/s, XR Tools' smooth turn speed
@export var snap_angle := 0.12    ## rad in one frame; more is a snap turn or a teleport, ignored

var body: CharacterBody3D = null  ## the XRToolsPlayerBody; found on ready, a probe may set it
var origin: Node3D = null
var closure := 0.0                ## 0 open .. 1 closed to inner_radius, after strength
var air := 0.0                    ## this frame's channel values, before strength
var walk := 0.0
var turn := 0.0
var _held := 0.0
var _event := 0.0
var _airborne := false
var _walked := 0.0
var _last_yaw := 0.0
var _yaw_ready := false
var _mesh: MeshInstance3D
var _material: ShaderMaterial

func _ready() -> void:
	_material = ShaderMaterial.new();_material.shader = SHADER;_material.render_priority = 99
	_material.set_shader_parameter("color", color);_material.set_shader_parameter("fade", softness)
	_mesh = MeshInstance3D.new();_mesh.name = "Ring";_mesh.mesh = _ring()
	_mesh.position = Vector3(0, 0, -1);_mesh.layers = 2;_mesh.visible = false
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;_mesh.ignore_occlusion_culling = true
	_mesh.set_surface_override_material(0, _material)
	add_child(_mesh)
	if body == null:
		body = XRToolsPlayerBody.find_instance(self)
	if origin == null:
		origin = XRHelpers.get_xr_origin(self)

func _process(delta: float) -> void:
	if delta <= 0.0:
		return
	if body == null or not is_instance_valid(body) or strength <= 0.0:
		_show(0.0)
		return
	var up: Vector3 = body.up_player if "up_player" in body else Vector3.UP
	var v := body.velocity
	var vertical := absf(v.dot(up))
	var horizontal := (v - up * v.dot(up)).length()
	var grounded: bool = bool(body.on_ground) if "on_ground" in body else body.is_on_floor()
	# air: counts once airborne past air_speed, and then until the landing - the apex is slow too
	if grounded:
		_airborne = false
	elif vertical >= air_speed:
		_airborne = true
	air = 0.0
	if _airborne:
		air = lerpf(air_min, air_max, clampf((vertical - air_speed) / maxf(air_full - air_speed, .001), 0.0, 1.0))
	# turn: the origin's yaw rate; a big step in one frame is a snap or a teleport
	turn = 0.0
	if origin != null and is_instance_valid(origin):
		var z := origin.global_basis.z
		var yaw := atan2(z.x, z.z)
		if _yaw_ready:
			var step := absf(wrapf(yaw - _last_yaw, -PI, PI))
			if step < snap_angle:
				turn = turn_max * clampf(step / delta / turn_full, 0.0, 1.0)
		_last_yaw = yaw;_yaw_ready = true
	# air and turn close at once, hold after the last moment they asked, then open over `release`
	var target := maxf(air, turn)
	if target > 0.0:
		_held = hold
	if target >= _event:
		_event = target
	elif _held > 0.0:
		_held -= delta
	else:
		_event = maxf(target, _event - delta / maxf(release, .001))
	# walk: eased, optionally delayed
	_walked = _walked + delta if horizontal > 0.3 and grounded else 0.0
	var walk_target := 0.0
	if _walked >= walk_delay:
		walk_target = walk_max * clampf(horizontal / walk_full, 0.0, 1.0)
	walk += (walk_target - walk) * (1.0 - exp(-delta / maxf(walk_ease, .001)))
	if walk_target == 0.0 and walk < .01:walk = 0.0   # end the tail, so the ring is not drawn for a faint 1 %
	_show(clampf(maxf(_event, walk) * strength, 0.0, 1.0))

func _show(c: float) -> void:
	closure = c
	_mesh.visible = c > 0.001
	if _mesh.visible:
		_material.set_shader_parameter("radius", radius() * sqrt(2.0))

## The radius the ring opens to now (1 = no vignette); for probes and overlays.
func radius() -> float:
	return 1.0 - closure * (1.0 - inner_radius)

## XR Tools' ring: an inner circle (moved by the shader) and an outer one at 2, in clip space.
func _ring() -> ArrayMesh:
	var vertices := PackedVector3Array();var indices := PackedInt32Array()
	vertices.resize(2 * STEPS);indices.resize(6 * STEPS)
	for i in STEPS:
		var v := Vector3.RIGHT.rotated(Vector3.FORWARD, TAU * i / STEPS)
		vertices[i] = v;vertices[STEPS + i] = v * 2.0
		var o := i * 6;var j := (i + 1) % STEPS
		indices[o] = STEPS + i;indices[o + 1] = STEPS + j;indices[o + 2] = j
		indices[o + 3] = STEPS + i;indices[o + 4] = j;indices[o + 5] = i
	var arrays := [];arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices;arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.custom_aabb = AABB(Vector3(-1, -1, -1), Vector3(2, 2, 2))
	return mesh
