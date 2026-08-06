# @identity
# essence: impulse = m * delta_v -- central body with 5 tethered blocks demonstrating momentum conservation
# desire: blocks crash and bounce on tethers, impulse arrows tracing each collision's physics
# critical_parameter: tether length / block mass -- constrain the collision space; impulse arrows show transfer
# triggers: player proximity triggers block release; physics simulation drives collisions continuously
# emerges: Newton's third law made ambulatory -- every action-reaction pair visible as arrow vectors
# needs: HazardCreatureBase [has]; tethered block physics [has]; impulse visualization [has]; VR interaction [missing]
# relationships: embodies physics simulation sequence; pairs with spring_mass_bouncer (impulse vs elasticity)
# truth: momentum is always conserved -- the impulse arrows prove it whether you believe the math or not.

extends HazardCreatureBase
class_name CollisionCrasher
## Physics simulation sequence — central body with 5 tethered BoxMesh blocks.
## Blocks orbit/bounce around the body with simulated spring-tether physics.
## Elastic collisions between blocks conserve momentum. Impulse arrows
## appear on player collision. During CHASE: tether radius increases.

@export_group("Physics Blocks")
@export var num_blocks: int = 5
@export var block_size: float = 0.08
@export var tether_radius: float = 0.4
@export var tether_k: float = 15.0       # Spring constant for tether
@export var block_damping: float = 0.5
@export var chase_tether_bonus: float = 0.3

@export_group("Combat")
@export var block_damage: float = 10.0

# ─────────────────────────────────────────────────────────────────────
#  STAGE-2 DNA — promoted 2026-08-06 (hand promotion; the runner refused
#  this token for NO TURNABLE KNOBS, which was a fact about the KIND of
#  knob: seven exports, every one of them a count, a length, a spring
#  constant, a damping rate or a damage number, and not one categorical
#  among them.)
#
#  tether — WHETHER THE CONSTRAINT IS DRAWN AT ALL. This artifact is
#           called CollisionCrasher, its class doc says "5 tethered
#           BoxMesh blocks", its @identity names "tether length" as its
#           critical parameter, and there has never been a tether in it.
#           The blocks are held by a spring force computed in
#           _process_visual and nothing in the scene depicts it, so what
#           a player meets is five cubes hovering near a sphere for no
#           visible reason. The law is the whole content of the object
#           and it is the one thing not drawn.
#
#             none    the shipped silence. Builds nothing; _build_tether
#                     returns on the first line.
#             line    one thin rod per block, body to block, in the
#                     block's own colour, following it every frame. The
#                     spring as a link: it shows that each block is held
#                     to the CENTRE and not to its neighbours.
#             cage    three orthogonal great circles at tether_radius.
#                     The boundary as a wireframe, so the blocks inside
#                     it stay visible while the surface they are being
#                     pulled back to becomes a place.
#             shell   the same boundary as one translucent sphere. The
#                     constraint as a volume rather than a hint - the
#                     envelope the spring defends, drawn.
#
#           IT IS AN ORDINAL LADDER: nothing, the individual links, the
#           boundary implied, the boundary made solid.
#
#  block_seed is the FIXTURE, not an axis, for bouncing_ball's ball_seed
#  reason. _build_mesh draws three unseeded randf_range values per block
#  - a y offset, a launch speed and a mass - so five variants would be
#  five different objects and the sweep would measure the draw. seed 0 is
#  the shipped global RNG, call for call, in the same order.
#
#  AND A SECOND FIXTURE KEY WITH A HARDER REASON, patrol_speed = 0.0.
#  This is a CharacterBody3D that walks. At the shipped patrol_speed of
#  1.5 m/s it crosses 1.65 m during the bench's 1.1 s settle while the
#  whole artifact is 0.9 m across, and the camera was placed from a
#  0.35 s pre-pass - so it simply leaves the frame. fractal_hydra, the
#  other promoted HazardCreatureBase, pins the same two keys for the
#  same reason.
#
#  DECLINED, on the record so nobody reopens it. `regime` - bouncing
#  ball's restitution word, and the obvious second axis here, since the
#  block-block impulse (2.0 * v_n) / (m1 + m2) is a hard-coded e = 1.
#  Refused because restitution is a RATE OF ENERGY LOSS and the evidence
#  is one still: five 8 cm cubes photographed at an arbitrary instant of
#  a chaotic five-body bounce, where elastic and inelastic differ only in
#  how far apart they happen to be. bouncing_ball hit exactly this and
#  stepped around it by drawing a PREDICTED envelope, h(n) = h0 e^(2n),
#  as static geometry. There is no closed-form envelope for this system
#  - and the thing that would stand in for one, the boundary the blocks
#  are held inside, is already what `tether` draws. `configuration` -
#  three_body_problem's and nbody_simulation's word for the initial
#  condition - refused too, and measured rather than guessed: nbody
#  qualifies for it because its bodies drift ~0.002 per frame against a
#  0.35 m radius, so t=0 survives the settle. Here a block starts at
#  0.5-1.5 m/s inside a 0.4 m tether and has crossed its own cage many
#  times over before the shutter falls. The initial condition is gone.
# ─────────────────────────────────────────────────────────────────────

## Allow-list. A typo in a map token falls back to the shipped silence.
const TETHERS: Array[String] = ["none", "line", "cage", "shell"]
## Half-thickness of a drawn tether rod, and of a cage ring.
const TETHER_LINE_RADIUS: float = 0.006
const TETHER_RING_RADIUS: float = 0.008

@export_enum("none", "line", "cage", "shell") var tether: String = "none"
## 0 keeps the shipped global RNG, call for call. Non-zero seeds a local one.
@export var block_seed: int = 0

# ── State ──────────────────────────────────────────────────────────────
var _blocks: Array[Dictionary] = []
# {mesh, mat, position, velocity, mass, color}
var _body_mesh: MeshInstance3D = null
var _body_mat: StandardMaterial3D = null
var _impulse_arrows: Array[Dictionary] = []  # {mesh, lifetime}
var _label: Label3D = null
var _total_ke: float = 0.0
var _total_momentum: float = 0.0
var _leg_roots: Array[Node3D] = []
var _walk_phase: float = 0.0
## Drawn tether rods, one per block, only when tether == "line".
var _tether_lines: Array[MeshInstance3D] = []
## Non-null only when block_seed != 0. Null is the shipped global RNG.
var _rng: RandomNumberGenerator = null
var _built: bool = false

var _block_colors: Array[Color] = [
	Color(0.9, 0.2, 0.15),   # Red
	Color(0.95, 0.55, 0.1),  # Orange
	Color(0.95, 0.85, 0.15), # Yellow
	Color(0.95, 0.45, 0.35), # Coral
	Color(0.95, 0.55, 0.5),  # Salmon
]


func _on_ready() -> void:
	max_health = 85.0
	_health = max_health
	chase_speed = 3.0
	patrol_speed = 1.5
	contact_damage = 10.0
	detection_radius = 8.0


func _create_materials() -> void:
	_body_mat = _make_material(Color(0.3, 0.3, 0.35), Color(0.15, 0.15, 0.2))


func _build_collision() -> void:
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.3
	col.shape = shape
	col.position.y = 0.45
	add_child(col)


## The shipped draw when block_seed is 0 — the same global randf_range, in the
## same order. Only a non-zero seed diverts to a local stream.
func _block_randf(lo: float, hi: float) -> float:
	if _rng == null:
		return randf_range(lo, hi)
	return _rng.randf_range(lo, hi)


func _build_mesh() -> void:
	_mesh_root.position.y = 0.45

	_rng = null
	if block_seed != 0:
		_rng = RandomNumberGenerator.new()
		_rng.seed = block_seed

	# Central body
	var body := SphereMesh.new()
	body.radius = 0.12
	body.height = 0.24
	_body_mesh = _add_mesh(body, _body_mat)
	_body_mesh.name = "CentralBody"

	# Create physics blocks
	for i in range(num_blocks):
		var color: Color = _block_colors[i % _block_colors.size()]
		var mat := _make_material(color, color * 0.5)

		var box := BoxMesh.new()
		box.size = Vector3(block_size, block_size, block_size)
		var mi := MeshInstance3D.new()
		mi.mesh = box
		mi.set_surface_override_material(0, mat)
		mi.name = "Block_%d" % i
		_mesh_root.add_child(mi)

		# Initial position: distribute around the center
		var angle: float = (float(i) / float(num_blocks)) * TAU
		var start_pos := Vector3(
			cos(angle) * tether_radius * 0.5,
			_block_randf(-0.1, 0.1),
			sin(angle) * tether_radius * 0.5
		)

		# Initial velocity: tangential
		var tangent := Vector3(-sin(angle), 0, cos(angle))
		var start_vel: Vector3 = tangent * _block_randf(0.5, 1.5)

		_blocks.append({
			"mesh": mi,
			"mat": mat,
			"position": start_pos,
			"velocity": start_vel,
			"mass": 1.0 + _block_randf(-0.2, 0.2),
			"color": color,
		})

	# 2 legs
	for i in range(2):
		var root := Node3D.new()
		root.name = "Leg_%d" % i
		root.position = Vector3((i - 0.5) * 0.12, -0.35, 0)
		_mesh_root.add_child(root)
		_leg_roots.append(root)

		var cyl := CylinderMesh.new()
		cyl.height = 0.2
		cyl.top_radius = 0.025
		cyl.bottom_radius = 0.018
		var leg_mat := _make_material(Color(0.25, 0.25, 0.3), Color.BLACK)
		var mi := MeshInstance3D.new()
		mi.mesh = cyl
		mi.set_surface_override_material(0, leg_mat)
		mi.position = Vector3(0, -0.1, 0)
		root.add_child(mi)

	# Label
	_label = Label3D.new()
	_label.text = ""
	_label.font_size = 36
	_label.pixel_size = 0.003
	_label.position = Vector3(0, 0.5, 0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.modulate = Color(1, 1, 1, 0.85)
	_mesh_root.add_child(_label)

	# APPENDED LAST so the legacy build above is untouched at the default value.
	_build_tether()
	_built = true


## Draw the constraint the spring already enforces. `none` — the shipped
## value — builds nothing and returns on the first line.
func _build_tether() -> void:
	_tether_lines.clear()
	if tether == "none":
		return

	if tether == "line":
		# One rod per block, body to block, in the block's own colour. Unit
		# height: _update_tether_lines scales it along its own Y each frame.
		for i in range(_blocks.size()):
			var color: Color = _blocks[i]["color"]
			var cyl := CylinderMesh.new()
			cyl.height = 1.0
			cyl.top_radius = TETHER_LINE_RADIUS
			cyl.bottom_radius = TETHER_LINE_RADIUS
			cyl.radial_segments = 6
			cyl.rings = 1
			var mi := MeshInstance3D.new()
			mi.mesh = cyl
			mi.set_surface_override_material(0, _make_material(color, color * 0.6))
			mi.name = "Tether_%d" % i
			_mesh_root.add_child(mi)
			_tether_lines.append(mi)
		return

	if tether == "shell":
		var sph := SphereMesh.new()
		sph.radius = tether_radius
		sph.height = tether_radius * 2.0
		sph.radial_segments = 24
		sph.rings = 12
		var smi := MeshInstance3D.new()
		smi.mesh = sph
		smi.set_surface_override_material(0,
			_make_material(Color(0.55, 0.75, 1.0), Color(0.2, 0.35, 0.6), 0.22))
		smi.name = "TetherShell"
		_mesh_root.add_child(smi)
		return

	# cage — the same boundary as three orthogonal great circles, so the
	# blocks inside it stay visible.
	for i in range(3):
		var tor := TorusMesh.new()
		tor.inner_radius = maxf(tether_radius - TETHER_RING_RADIUS, 0.001)
		tor.outer_radius = tether_radius + TETHER_RING_RADIUS
		tor.rings = 32
		tor.ring_segments = 6
		var tmi := MeshInstance3D.new()
		tmi.mesh = tor
		tmi.set_surface_override_material(0,
			_make_material(Color(0.55, 0.75, 1.0), Color(0.25, 0.45, 0.8)))
		tmi.name = "TetherRing_%d" % i
		if i == 1:
			tmi.rotation.x = PI * 0.5
		elif i == 2:
			tmi.rotation.z = PI * 0.5
		_mesh_root.add_child(tmi)


## Follow the blocks. Only reached when tether == "line".
func _update_tether_lines() -> void:
	var n: int = mini(_tether_lines.size(), _blocks.size())
	for i in range(n):
		var mi: MeshInstance3D = _tether_lines[i]
		if not is_instance_valid(mi):
			continue
		var pos: Vector3 = _blocks[i]["position"]
		var d: float = pos.length()
		if d < 0.002:
			mi.visible = false
			continue
		mi.visible = true
		# Build the basis by hand rather than with look_at: `pos` is in
		# _mesh_root's LOCAL space and the creature yaws while it walks, so a
		# global-space look_at would swing the rods off their blocks.
		var yv: Vector3 = pos / d
		var hint: Vector3 = Vector3.UP
		if absf(yv.dot(hint)) > 0.99:
			hint = Vector3.RIGHT
		var xv: Vector3 = yv.cross(hint).normalized()
		var zv: Vector3 = xv.cross(yv).normalized()
		# The Y column carries the length, so the unit cylinder spans body
		# to block in one assignment and no scale decomposition happens.
		mi.transform = Transform3D(Basis(xv, yv * d, zv), pos * 0.5)


func _process_visual(delta: float) -> void:
	var current_tether: float = tether_radius
	if _state == BaseState.CHASE:
		current_tether += chase_tether_bonus

	_total_ke = 0.0
	var total_p := Vector3.ZERO

	# ── Tether spring forces ──────────────────────────────────────
	for b in _blocks:
		var pos: Vector3 = b["position"]
		var dist: float = pos.length()

		# Spring force toward center if outside tether
		if dist > current_tether:
			var displacement: float = dist - current_tether
			var force: Vector3 = -pos.normalized() * tether_k * displacement
			var acc: Vector3 = force / b["mass"]
			b["velocity"] += acc * delta

		# Gentle centering spring (always)
		b["velocity"] -= pos * 0.5 * delta

		# Damping
		b["velocity"] *= (1.0 - block_damping * delta)

	# ── Elastic collisions between blocks ─────────────────────────
	for i in range(_blocks.size()):
		for j in range(i + 1, _blocks.size()):
			var diff: Vector3 = _blocks[j]["position"] - _blocks[i]["position"]
			var dist: float = diff.length()
			var min_dist: float = block_size * 1.2

			if dist < min_dist and dist > 0.001:
				var normal: Vector3 = diff.normalized()
				var rel_vel: Vector3 = _blocks[i]["velocity"] - _blocks[j]["velocity"]
				var vel_along_normal: float = rel_vel.dot(normal)

				# Only resolve if blocks are approaching
				if vel_along_normal > 0:
					var m1: float = _blocks[i]["mass"]
					var m2: float = _blocks[j]["mass"]
					var impulse: float = (2.0 * vel_along_normal) / (m1 + m2)

					_blocks[i]["velocity"] -= normal * impulse * m2
					_blocks[j]["velocity"] += normal * impulse * m1

				# Separate overlapping blocks
				var overlap: float = min_dist - dist
				_blocks[i]["position"] -= normal * overlap * 0.5
				_blocks[j]["position"] += normal * overlap * 0.5

	# ── Integrate positions ───────────────────────────────────────
	for b in _blocks:
		b["position"] += b["velocity"] * delta
		b["mesh"].position = b["position"]

		var speed: float = b["velocity"].length()
		_total_ke += 0.5 * b["mass"] * speed * speed
		total_p += b["velocity"] * b["mass"]

	_total_momentum = total_p.length()

	# ── Tether rods follow their blocks ───────────────────────────
	if tether == "line":
		_update_tether_lines()

	# ── Walk animation ────────────────────────────────────────────
	if _state == BaseState.PATROL or _state == BaseState.CHASE:
		_walk_phase += delta * 5.0
		for i in range(_leg_roots.size()):
			_leg_roots[i].rotation.x = sin(_walk_phase + float(i) * PI) * 0.3

	# ── Update impulse arrows ────────────────────────────────────
	var remove_arrows: Array[int] = []
	for i in range(_impulse_arrows.size()):
		_impulse_arrows[i]["lifetime"] -= delta
		if _impulse_arrows[i]["lifetime"] <= 0.0:
			if is_instance_valid(_impulse_arrows[i]["mesh"]):
				_impulse_arrows[i]["mesh"].queue_free()
			remove_arrows.append(i)
		else:
			# Fade out
			var t: float = _impulse_arrows[i]["lifetime"]
			if is_instance_valid(_impulse_arrows[i]["mesh"]):
				var mat: StandardMaterial3D = _impulse_arrows[i]["mesh"].get_surface_override_material(0)
				if mat:
					mat.albedo_color.a = t

	for idx in range(remove_arrows.size() - 1, -1, -1):
		_impulse_arrows.remove_at(remove_arrows[idx])

	# ── Check block proximity to player for impulse visualization ─
	if is_instance_valid(_player_node):
		for b in _blocks:
			var block_world: Vector3 = b["mesh"].global_position
			var to_player: float = block_world.distance_to(_player_node.global_position)
			if to_player < 0.3:
				_spawn_impulse_arrow(b["position"], b["velocity"])

	# ── Label ─────────────────────────────────────────────────────
	if _label:
		_label.text = "KE: %.2f, p: %.2f" % [_total_ke, _total_momentum]


func _spawn_impulse_arrow(pos: Vector3, vel: Vector3) -> void:
	if vel.length() < 0.1:
		return

	var cyl := CylinderMesh.new()
	cyl.height = 0.2
	cyl.top_radius = 0.003
	cyl.bottom_radius = 0.015
	var arrow_mat := _make_material(Color(1, 1, 1), Color(0.8, 0.8, 0.8), 0.8)
	var mi := MeshInstance3D.new()
	mi.mesh = cyl
	mi.set_surface_override_material(0, arrow_mat)
	mi.position = pos
	_mesh_root.add_child(mi)

	# Orient arrow along velocity
	var dir: Vector3 = vel.normalized()
	if dir.length() > 0.01:
		var up := Vector3.UP
		if abs(dir.dot(up)) > 0.95:
			up = Vector3.RIGHT
		mi.look_at_from_position(pos, pos + dir, up)
		mi.rotate_object_local(Vector3.RIGHT, PI / 2.0)

	_impulse_arrows.append({
		"mesh": mi,
		"lifetime": 1.0,
	})


func _on_damaged(_amount: float) -> void:
	# Blocks scatter outward on damage
	for b in _blocks:
		var outward: Vector3 = b["position"].normalized()
		if outward.length() < 0.01:
			outward = Vector3(randf() - 0.5, 0, randf() - 0.5).normalized()
		b["velocity"] += outward * 4.0
	_set_state(BaseState.STUNNED)


func _on_state_changed(new_state: BaseState) -> void:
	if new_state == BaseState.CHASE:
		# Give blocks extra energy when entering chase
		for b in _blocks:
			b["velocity"] *= 1.5


## Tear down the visual body and build it again. Only ever reached from
## apply_grid_config when a declared value ACTUALLY changed after the first
## build — an unguarded rebuild here would re-run the whole construction on
## every placement that passes any config key at all, including the ones that
## only name `health` or `speed`.
func _rebuild() -> void:
	for child in _mesh_root.get_children():
		child.queue_free()
	_blocks.clear()
	_impulse_arrows.clear()
	_leg_roots.clear()
	_tether_lines.clear()
	_body_mesh = null
	_label = null
	_build_mesh()


## Config from a map token. The base class's keys (health, speed, chase_speed,
## damage, detection_radius) are forwarded first and untouched; the two added
## here are guarded twice — a value is taken only when it validates AND
## differs, and _rebuild() fires only after _build_mesh has run once.
func apply_grid_config(config: Dictionary) -> void:
	super.apply_grid_config(config)
	if config.is_empty():
		return

	var changed: bool = false

	if config.has("tether"):
		var t: String = str(config["tether"]).to_lower()
		if TETHERS.has(t) and t != tether:
			tether = t
			changed = true

	if config.has("block_seed"):
		var s: int = int(config["block_seed"])
		if s != block_seed:
			block_seed = s
			changed = true

	if not changed:
		return
	# Before the first build there is nothing to tear down — _build_mesh() will
	# pick the new values up when the base class calls it.
	if not _built:
		return
	_rebuild()
