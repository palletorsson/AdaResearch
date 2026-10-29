extends XRToolsPickable
class_name PlaygroundRod
## The two-point rod of the playground kit: a steel core in a foam sleeve, one unit long, the LINE of the
## inventory. Its length is in UNITS of the balls' grid: one unit reaches from a grid ball's socket mouth to the
## next ball's, grid minus two hubs (0.83 m on the 1 m grid); `units` 0 keeps `length` as given. Let go with an
## end within a ball's socket_reach of a free socket and that end snaps in, the rod
## turning to point out of the socket, and a fixed joint holds it; let go with both ends near two balls a rod's
## length apart and it bridges them. Picked up again, the joints go and the sockets are freed. It is also a
## stick: swung into anything at more than `hit_speed`, it gives the foam thwop (a sound made in code, a noise
## burst with a falling tone, higher the harder it lands) and says so with `hit`. Origin: the rod's middle,
## axis +X. A body otherwise: it falls, rolls, stacks.

signal hit(what: Node, speed: float)
signal snapped(end: int, ball: Node3D, socket: int)
signal unsnapped

@export_range(0.25, 4.0) var length := 0.83       ## end to end, metres (set from units when units > 0)
@export_range(0, 8) var units := 1                   ## length in grid units, mouth to mouth; 0 = use length
@export_range(0.25, 4.0) var grid := 1.0            ## the balls' grid pitch
@export var hub := 0.085                             ## a ball's radius + boss: how far a mouth is from its centre
@export_range(0.006, 0.03) var core := 0.012       ## the steel core's radius
@export_range(0.01, 0.06) var sleeve := 0.03       ## the foam sleeve's radius
@export_enum("pale", "pink", "cyan", "steel") var colour := "pink"
@export var hit_speed := 1.2                        ## m/s: slower than this is a touch, not a hit
@export var sleeve_ends := 0.08                     ## the sleeve stops this far from each end: bare steel goes in the socket

const FOAM := {"pale": "ededed", "pink": "ea72ab", "cyan": "5fd3e6", "steel": "2a2c30"}
const STEEL := "2a2c30"
const BallLib = preload("res://commons/artifacts/playground_kit/playground_ball.gd")   # by path: the class cache lags

var joints: Array[Dictionary] = []   # {end, ball, socket, joint}
var _built := false
var _player: AudioStreamPlayer3D = null
var _last_hit := 0.0
var _speed_before := 0.0   # the speed going INTO the physics step: body_entered arrives after the solver has spent it

func _init() -> void:
	collision_layer = 1 | 4;collision_mask = 1;freeze = false;gravity_scale = 1.0;mass = 0.3
	release_mode = ReleaseMode.UNFROZEN;angular_damp = 1.0;linear_damp = 0.1
	contact_monitor = true;max_contacts_reported = 4

func apply_grid_config(config: Dictionary) -> void:
	units = clampi(int(config.get("units", units)), 0, 8);grid = clampf(float(config.get("grid", grid)), .25, 4);hub = clampf(float(config.get("hub", hub)), .02, .3)
	length = clampf(float(config.get("length", length)), .25, 4) if units == 0 else clampf(units * grid - 2 * hub, .1, 8)
	core = clampf(float(config.get("core", core)), .006, .03)
	sleeve = clampf(float(config.get("sleeve", sleeve)), .01, .06)
	colour = str(config.get("colour", colour))
	if colour not in FOAM:colour = "pink"
	hit_speed = clampf(float(config.get("hit_speed", hit_speed)), .2, 10)
	if _built:_build()

func _ready() -> void:
	super._ready()
	if units > 0:length = clampf(units * grid - 2 * hub, .1, 8)
	add_to_group("playground_rods")
	dropped.connect(func(_who):call_deferred("settle"))
	picked_up.connect(func(_who):unsnap())
	body_entered.connect(_on_body_entered)
	_player = AudioStreamPlayer3D.new();_player.name = "Thwop";_player.stream = _make_thwop();_player.max_distance = 12;_player.unit_size = 2;add_child(_player)
	_build()

func _build() -> void:
	for c in get_children():
		if c is MeshInstance3D or c is CollisionShape3D:remove_child(c);c.queue_free()
	var foam := StandardMaterial3D.new();foam.albedo_color = Color(FOAM[colour]);foam.roughness = .88
	var steel := StandardMaterial3D.new();steel.albedo_color = Color(STEEL);steel.metallic = .6;steel.roughness = .35
	var along := Basis(Vector3.FORWARD, PI / 2)   # a cylinder stands on Y; the rod lies on X
	var c := MeshInstance3D.new();var cm := CylinderMesh.new();cm.top_radius = core;cm.bottom_radius = core;cm.height = length;cm.radial_segments = 12;c.mesh = cm;c.material_override = steel;c.basis = along;c.name = "Core";add_child(c)
	var s := MeshInstance3D.new();var smm := CylinderMesh.new();smm.top_radius = sleeve;smm.bottom_radius = sleeve;smm.height = maxf(.05, length - 2 * sleeve_ends);smm.radial_segments = 20;s.mesh = smm;s.material_override = foam;s.basis = along;s.name = "Sleeve";add_child(s)
	var shape := CollisionShape3D.new();var cap := CapsuleShape3D.new();cap.radius = sleeve;cap.height = length;shape.shape = cap;shape.basis = along;add_child(shape)
	_built = true

## An end in the world: 0 at -X, 1 at +X.
func end_global(end: int) -> Vector3:
	return global_transform * Vector3((length / 2.0) * (1.0 if end == 1 else -1.0), 0, 0)

## Where the rod came to rest: each end looks for a free socket within reach; a found one takes that end.
## Returns how many ends snapped.
func settle() -> int:
	if not is_inside_tree() or is_picked_up():return 0
	var balls := get_tree().get_nodes_in_group("playground_balls")
	var found: Array = []   # [end, ball, socket]
	for end in 2:
		var p := end_global(end);var best: Node3D = null;var best_i := -1;var best_d := INF
		for b in balls:
			if not b.has_method("nearest_free_socket"):continue
			var i: int = b.nearest_free_socket(p)
			if i < 0:continue
			var d: float = p.distance_to(b.socket_global(i))
			if d < best_d:best_d = d;best = b;best_i = i
		if best != null and not (found.size() == 1 and found[0][1] == best and found[0][2] == best_i):found.append([end, best, best_i])
	if found.is_empty():return 0
	# place the rod: one end in its socket pointing out of it; two ends between their two sockets
	var t := global_transform
	if found.size() == 2:
		var a: Vector3 = found[0][1].socket_global(found[0][2]);var b: Vector3 = found[1][1].socket_global(found[1][2])
		var axis := (b - a).normalized() * (1.0 if found[0][0] == 0 else -1.0)   # +X runs from end 0 to end 1
		t = Transform3D(_basis_x(axis), (a + b) / 2.0)
	else:
		var end: int = found[0][0];var ball: Node3D = found[0][1];var i: int = found[0][2]
		var out: Vector3 = ball.socket_dir(i);var mouth: Vector3 = ball.socket_global(i)
		var axis := out if end == 0 else -out   # the far end points away from the ball
		t = Transform3D(_basis_x(axis), mouth + out * (length / 2.0))
	freeze = false;linear_velocity = Vector3.ZERO;angular_velocity = Vector3.ZERO;global_transform = t
	if found.size() == 1:   # laid along its socket, the far end may now sit in another ball's mouth: take it too
		var other: int = 1 - int(found[0][0]);var p := end_global(other)
		for b in balls:
			if b == found[0][1] or not b.has_method("nearest_free_socket"):continue
			var i: int = b.nearest_free_socket(p)
			if i >= 0 and p.distance_to(b.socket_global(i)) < .03:found.append([other, b, i]);break
	for f in found:_join(f[0], f[1], f[2])
	BallLib.reevaluate(get_tree())
	return found.size()

## Is this end free (in no socket)?
func end_free(end: int) -> bool:
	for jd in joints:
		if jd.end == end:return false
	return true

## A ball let go with a mouth on this end takes it: the ball's side of the snap (the rod is already in place).
func attach_end(end: int, ball: Node3D, socket: int) -> void:
	if not end_free(end):return
	_join(end, ball, socket)

## The fixed joint at a mouth, the socket claimed, remembered.
func _join(end: int, ball: Node3D, i: int) -> void:
	var j := Generic6DOFJoint3D.new();j.name = "Snap%d" % end
	get_parent().add_child(j);j.global_transform = Transform3D(Basis(), ball.socket_global(i))
	j.node_a = ball.get_path();j.node_b = get_path()
	for ax in ["x", "y", "z"]:   # every axis locked: a fixed joint
		j.set("linear_limit_%s/upper_distance" % ax, 0.0);j.set("linear_limit_%s/lower_distance" % ax, 0.0)
		j.set("angular_limit_%s/upper_angle" % ax, 0.0);j.set("angular_limit_%s/lower_angle" % ax, 0.0)
	ball.claim(i, self)
	joints.append({"end": end, "ball": ball, "socket": i, "joint": j})
	snapped.emit(end, ball, i)

func unsnap() -> void:
	if joints.is_empty():return
	for jd in joints:
		if is_instance_valid(jd.ball):jd.ball.release(self)
		if is_instance_valid(jd.joint):jd.joint.queue_free()
	joints.clear();unsnapped.emit()
	if is_inside_tree():BallLib.reevaluate(get_tree())

## One ball leaving the world: this rod lets go of it and keeps its other end.
func release_ball(ball: Node) -> void:
	var keep: Array[Dictionary] = []
	for jd in joints:
		if jd.ball == ball:
			if is_instance_valid(jd.joint):jd.joint.queue_free()
		else:keep.append(jd)
	joints = keep

static func _basis_x(axis: Vector3) -> Basis:
	var up := Vector3.UP if absf(axis.dot(Vector3.UP)) < .9 else Vector3.BACK
	var z := axis.cross(up).normalized();var y := z.cross(axis).normalized()
	return Basis(axis, y, z)

func _physics_process(_delta: float) -> void:
	_speed_before = linear_velocity.length()

## The stick: a body met faster than hit_speed is a hit, with the foam thwop (higher and louder the harder).
func _on_body_entered(body: Node) -> void:
	var speed := maxf(linear_velocity.length(), _speed_before)
	if speed < hit_speed:return
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_hit < .08:return
	_last_hit = now
	if _player:_player.pitch_scale = clampf(.8 + speed * .12, .8, 1.8);_player.volume_db = clampf(-14 + speed * 3, -14, 4);_player.play()
	hit.emit(body, speed)

## The thwop, made in code: 140 ms of noise under a falling low-pass, with a soft thump under it.
static func _make_thwop() -> AudioStreamWAV:
	var rate := 22050;var n := int(rate * .14);var data := PackedByteArray();data.resize(n * 2)
	var rng := RandomNumberGenerator.new();rng.seed = 7;var lp := 0.0;var phase := 0.0
	for i in n:
		var t := float(i) / rate;var env := exp(-t * 28.0)
		var cutoff := lerpf(.6, .05, minf(1.0, t / .09))   # the brightness falls as the foam gives
		lp += (rng.randf_range(-1, 1) - lp) * cutoff
		phase += TAU * lerpf(160.0, 70.0, minf(1.0, t / .1)) / rate
		var v := (lp * .7 + sin(phase) * .5 * exp(-t * 18.0)) * env
		var s := int(clampf(v, -1, 1) * 32000);data.encode_s16(i * 2, s)
	var wav := AudioStreamWAV.new();wav.format = AudioStreamWAV.FORMAT_16_BITS;wav.mix_rate = rate;wav.stereo = false;wav.data = data
	return wav

func prepare_editor_preview() -> void:
	freeze = true
