extends SceneTree
## probe_composition_twins.gd — does the big one actually move, and by ten?
##
## THE ONLY FAILURE THAT MATTERS HERE is a twin that does not follow, so this
## measures the following and prints the numbers rather than asserting a boolean.
## It proves, in one boot:
##
##   1. the artifact builds standing alone, with no basin and no config — the
##      state the capture bench and the gallery see
##   2. every small body is on layer 3, the one layer BOTH grab paths reach, is
##      frozen, and is in no_gravity_gun (without which the VR gravity gun
##      unfreezes it and sweeps the table)
##   3. a twin's base rests EXACTLY on the pool floor at the declared depth
##   4. moving a small body by d moves its twin by d * offset_scale, in all three
##      axes, and the twin's own size is body * twin_scale
##   5. ROTATION carries — the twin's basis matches the small body's
##   6. the link survives a GRAB, a CARRY, a RELEASE and a RE-GRAB, simulated the
##      way each hand actually does it: the desktop pointer forces
##      freeze/layer/mask and writes global_position with no signal at all
##      (DesktopInteractionPointer._grab_held), and the VR grab driver writes the
##      whole global_transform from _physics_process
##   7. the reach clamp holds a small body inside its bed, so a twin can never be
##      pushed through a rim wall
##   8. apply_grid_config called BEFORE _ready (the museum's order) and AFTER it
##      (the grid's order) both land, and the second does not rebuild for nothing
##
## Run:
##   godot --headless --path . --xr-mode off \
##     --script res://commons/testing/probe_composition_twins.gd

const SCENE := "res://commons/artifacts/composition_twins/composition_twins.tscn"
const OUT := "res://ada_run/composition_twins_probe.txt"
## Two process frames photographs a half-built artifact; procedural bodies keep
## building past _ready, and the corpus's settle for a measurement is 0.35-0.45 s.
const SETTLE := 0.45
const EPS := 0.002

var _fails: Array[String] = []
var _notes: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _host(name_hint: String) -> Node3D:
	var host := Node3D.new()
	host.name = name_hint
	get_root().add_child(host)
	return host


func _run() -> void:
	if not ResourceLoader.exists(SCENE):
		_fails.append("no scene at " + SCENE)
		_report()
		return
	var packed: PackedScene = load(SCENE)

	# ── 1. STANDALONE, no config at all ──────────────────────────────────────
	var bare: Node3D = packed.instantiate() as Node3D
	_host("Bare").add_child(bare)
	await create_timer(SETTLE).timeout
	var n_bare: int = int(bare.call("lead_count"))
	var meshes_bare: int = bare.find_children("*", "MeshInstance3D", true, false).size()
	if n_bare < 1 or meshes_bare < 4:
		_fails.append("standalone build is empty: %d leads, %d meshes — a token dropped anywhere renders nothing" % [n_bare, meshes_bare])
	else:
		var t0: Node3D = bare.call("twin_node", 0) as Node3D
		_notes.append("standalone with NO config: %d pairs, %d meshes, first twin at %s scale %.1f" % [
			n_bare, meshes_bare, str(t0.position.round()), t0.scale.x])
		# with no basin the twins must stand clear of the table, not inside it
		if absf(t0.position.z) < 0.5 and absf(t0.position.x) < 0.5:
			_fails.append("no basin, and the first twin is built on top of the table at %s" % str(t0.position))

	# ── 2. the museum's call order: apply_grid_config BEFORE _ready ───────────
	var art: Node3D = packed.instantiate() as Node3D
	art.call("apply_grid_config", {
		"basin_depth": 4.0, "object_count": 3, "twin_scale": 10.0,
		"offset_scale": 10.0, "pool_m": 7.0, "body_m": 0.16,
		"primitives": "cube,sphere,tetra", "tether": "line"})
	_host("Hall").add_child(art)
	await create_timer(SETTLE).timeout

	var rep: Dictionary = art.call("link_report")
	var n: int = int(rep["count"])
	var s: float = float(rep["twin_scale"])
	var os_: float = float(rep["offset_scale"])
	if n != 3:
		_fails.append("config before _ready did not land: %d pairs, wanted 3" % n)
	else:
		_notes.append("museum order (config BEFORE _ready) landed: %d pairs, twin x%.0f, offset x%.0f, pool anchor %s" % [
			n, s, os_, str(rep["pool_anchor"])])

	# ── 3. the small bodies are grabbable by BOTH hands, and safe on a table ──
	var grab_faults: int = _fails.size()
	for i in range(n):
		var lead: Node3D = art.call("lead_node", i) as Node3D
		var rb := lead as RigidBody3D
		if rb == null:
			_fails.append("lead %d is not a RigidBody3D — neither grab path can see it" % i)
			continue
		if rb.collision_layer != 4:
			_fails.append("lead %d on collision_layer %d; layer 3 (=4) is the only layer BOTH the desktop carry (mask 3/18/19) and the VR pickup (mask 3/17/19) reach" % [i, rb.collision_layer])
		if not rb.has_method("pick_up"):
			_fails.append("lead %d has no pick_up() — the desktop pointer's _find_grabbable walks up looking for exactly that" % i)
		if not rb.freeze:
			_fails.append("lead %d is not frozen — it will roll off the table and take its twin into a wall" % i)
		if not rb.is_in_group("no_gravity_gun"):
			_fails.append("lead %d is not in no_gravity_gun — the VR gravity gun UNFREEZES frozen bodies that have pick_up()" % i)
	if _fails.size() == grab_faults:
		_notes.append("all %d small bodies: layer 3, pick_up(), frozen, no_gravity_gun" % n)

	# ── 4. the twin rests ON the pool floor, and is body x twin_scale ─────────
	var lead0: Node3D = art.call("lead_node", 0) as Node3D
	var twin0: Node3D = art.call("twin_node", 0) as Node3D
	var mesh0: MeshInstance3D = twin0.get_node_or_null("Body") as MeshInstance3D
	var small0: MeshInstance3D = lead0.get_node_or_null("Body") as MeshInstance3D
	var floor_y: float = twin0.position.y + mesh0.position.y * twin0.scale.y - mesh0.get_aabb().size.y * 0.5 * twin0.scale.y
	if absf(floor_y - (-4.0)) > 0.01:
		_fails.append("twin 0 base at y %.4f, the pool floor of a depth-4 basin is -4.0000" % floor_y)
	else:
		_notes.append("twin 0 base rests on the pool floor: y = %.4f" % floor_y)
	var small_h: float = small0.get_aabb().size.y
	var big_h: float = mesh0.get_aabb().size.y * twin0.scale.y
	if absf(big_h / maxf(small_h, 0.0001) - s) > 0.02:
		_fails.append("twin 0 is %.3f m against a %.3f m body — ratio %.3f, wanted %.1f" % [big_h, small_h, big_h / small_h, s])
	else:
		_notes.append("twin 0 is %.3f m tall against a %.3f m body: x%.2f" % [big_h, small_h, big_h / small_h])

	# ── 5. THE MEASUREMENT. Move the small one; did the big one move by ten? ──
	await _assert_follow(art, 0, Vector3(0.09, 0.0, -0.07), "a shove across the table")
	await _assert_follow(art, 1, Vector3(0.0, 0.018, 0.0), "a lift straight up")
	await _assert_follow(art, 2, Vector3(-0.05, 0.010, 0.06), "all three axes at once")

	# ── 6. ROTATION carries ──────────────────────────────────────────────────
	var lead1: Node3D = art.call("lead_node", 1) as Node3D
	var twin1: Node3D = art.call("twin_node", 1) as Node3D
	lead1.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(37.0)) * Basis(Vector3.RIGHT, deg_to_rad(12.0)),
		lead1.position)
	await _settle()
	var want_b: Basis = lead1.transform.basis.orthonormalized()
	var got_b: Basis = twin1.transform.basis.orthonormalized()
	var ang: float = want_b.get_rotation_quaternion().angle_to(got_b.get_rotation_quaternion())
	if ang > 0.01:
		_fails.append("rotation did not carry: %.3f rad between the small body and its twin" % ang)
	else:
		_notes.append("rotation carries one for one (37 deg yaw + 12 deg pitch, %.5f rad of error)" % ang)

	# ── 7. a grab, a carry, a release, a re-grab ─────────────────────────────
	await _assert_carry_cycle(art, 0)

	# ── 8. the clamp holds the twin inside the pool ──────────────────────────
	var bed: Vector2 = rep["bed"]
	var lead2: Node3D = art.call("lead_node", 2) as Node3D
	var twin2: Node3D = art.call("twin_node", 2) as Node3D
	lead2.position = Vector3(40.0, 900.0, -40.0)          # a shove no hand could make
	await _settle()
	var inside: bool = absf(lead2.position.x) <= bed.x + EPS and absf(lead2.position.z) <= bed.y + EPS
	var half_pool: float = 7.0 * 0.5
	var twin_edge: float = absf(twin2.position.x) + big_h * 0.5
	if not inside:
		_fails.append("the clamp let a small body out of its bed: %s against a bed of %s" % [str(lead2.position), str(bed)])
	elif twin_edge > half_pool + 0.01:
		_fails.append("clamped, and the twin still reaches %.2f m from centre — past the 3.50 m rim of a 7 m pool" % twin_edge)
	else:
		_notes.append("the clamp holds: a 40 m shove lands at %s, and the twin's far edge stops %.2f m from centre (rim 3.50)" % [
			str(lead2.position.round()), twin_edge])

	# ── 9. the grid's call order: apply_grid_config AFTER _ready ─────────────
	var sig_before: int = art.find_children("*", "MeshInstance3D", true, false).size()
	art.call("apply_grid_config", {"basin_depth": 4.0, "object_count": 3, "twin_scale": 10.0,
		"offset_scale": 10.0, "pool_m": 7.0, "body_m": 0.16,
		"primitives": "cube,sphere,tetra", "tether": "line"})
	await create_timer(0.2).timeout
	if art.find_children("*", "MeshInstance3D", true, false).size() != sig_before:
		_fails.append("the same config rebuilt the artifact — a rebuild mid-grab frees the XRTools grab driver under a hand")
	else:
		_notes.append("the same config does NOT rebuild (%d meshes before and after)" % sig_before)
	art.call("apply_grid_config", {"object_count": 5, "pool_m": 12.0})
	await create_timer(0.3).timeout
	var n5: int = int(art.call("lead_count"))
	if n5 != 5:
		_fails.append("grid order (config AFTER _ready) did not take: %d pairs, wanted 5" % n5)
	else:
		_notes.append("grid order (config AFTER _ready) rebuilt to %d pairs" % n5)

	# ── 10. every shape in the vocabulary, and the other two tether values ───
	# The torus is the one that matters: it is the only shape whose body is not as
	# tall as the cube it is authored inside, so it is the test of the origin-at-
	# the-base decision. If seating were done from the mesh centre it would float
	# 5.5 cm on the table and 55 cm above the pool floor.
	for mode in ["halo", "none"]:
		var alt: Node3D = packed.instantiate() as Node3D
		alt.call("apply_grid_config", {
			"basin_depth": 4.0, "object_count": 6, "pool_m": 14.0,
			"primitives": "cube,sphere,cone,cylinder,wedge,torus",
			"tether": mode, "pool_offset": "0,0,0"})
		_host("Alt_" + mode).add_child(alt)
		await create_timer(SETTLE).timeout
		var an: int = int(alt.call("lead_count"))
		var am: int = alt.find_children("*", "MeshInstance3D", true, false).size()
		var base5: float = _twin_base_y(alt, 5)
		if an != 6 or am < 12:
			_fails.append("tether=%s with all six shapes built %d pairs / %d meshes" % [mode, an, am])
		elif absf(base5 - (-4.0)) > 0.01:
			_fails.append("tether=%s: the torus twin's base is at %.4f, not on the -4.0 pool floor" % [mode, base5])
		else:
			await _assert_follow(alt, 5, Vector3(0.04, 0.008, -0.03), "the torus, tether=" + mode)
			_notes.append("tether=%s: six shapes, %d meshes, torus twin base y = %.4f" % [mode, am, base5])

	_report()


## The world y of a twin's lowest point, which is what has to land on the pool
## floor. Read from the mesh's own AABB rather than assumed, because the shapes
## are not all as tall as each other.
func _twin_base_y(art: Node3D, i: int) -> float:
	var twin: Node3D = art.call("twin_node", i) as Node3D
	if twin == null:
		return NAN
	var mi: MeshInstance3D = twin.get_node_or_null("Body") as MeshInstance3D
	if mi == null:
		return NAN
	return twin.position.y + (mi.position.y + mi.get_aabb().position.y) * twin.scale.y


## A PHYSICS body's node transform is not the probe's to read back mid-flight.
## An XRToolsPickable is a RigidBody3D with freeze_mode KINEMATIC, and Godot syncs
## a kinematic frozen body's transform back from the physics server; headless idle
## frames run far faster than the 60 Hz physics tick, so several writes inside one
## physics step are reverted to the step's own transform and a read-modify-write
## lerp only advances once per tick. Measured, not guessed: the first version of
## this probe drove the carry as `pos = pos.lerp(target, 0.4)` for eight idle
## frames and the body finished 67 percent short, which read as a twin that had
## not followed. It had followed perfectly — the LEAD had not moved.
##
## So every stage settles across real physics frames before anything is measured,
## and every measurement is taken against the lead's ACTUAL position.
func _settle() -> void:
	await create_timer(0.12).timeout
	await process_frame
	await process_frame


## THE INVARIANT, and the whole contract of this artifact in one line: a twin
## stands at the pool anchor plus the small body's offset from the table anchor,
## times offset_scale. Read from the artifact's own report, so the probe is not
## holding a second copy of the numbers.
func _map_error(art: Node3D, i: int) -> float:
	var rep: Dictionary = art.call("link_report")
	var lead: Node3D = art.call("lead_node", i) as Node3D
	var twin: Node3D = art.call("twin_node", i) as Node3D
	if lead == null or twin == null:
		return INF
	var want: Vector3 = Vector3(rep["pool_anchor"]) \
		+ (lead.position - Vector3(rep["table_anchor"])) * float(rep["offset_scale"])
	return (twin.position - want).length()


## Move a small body by d, then read what the twin did — the ratio against the
## lead's measured travel, and the mapping error at rest.
func _assert_follow(art: Node3D, i: int, d: Vector3, why: String) -> void:
	var lead: Node3D = art.call("lead_node", i) as Node3D
	var twin: Node3D = art.call("twin_node", i) as Node3D
	if lead == null or twin == null:
		_fails.append("pair %d is missing" % i)
		return
	var os_: float = float((art.call("link_report") as Dictionary)["offset_scale"])
	var lead_before: Vector3 = lead.position
	var twin_before: Vector3 = twin.position
	lead.position = lead_before + d
	await _settle()
	var moved_lead: Vector3 = lead.position - lead_before
	var moved_twin: Vector3 = twin.position - twin_before
	var err: float = (moved_twin - moved_lead * os_).length()
	var map_err: float = _map_error(art, i)
	if moved_lead.length() < 0.001:
		_fails.append("pair %d (%s): the small body did not move at all, so nothing was tested" % [i, why])
	elif err > EPS * os_ or map_err > EPS * os_:
		_fails.append("pair %d (%s): small moved %s, twin moved %s, wanted %s — delta error %.4f m, mapping error %.4f m" % [
			i, why, str(moved_lead), str(moved_twin), str(moved_lead * os_), err, map_err])
	else:
		_notes.append("pair %d (%s): small %s -> twin %s = x%.2f, delta error %.5f m, mapping error %.5f m" % [
			i, why, str(moved_lead), str(moved_twin),
			moved_twin.length() / maxf(moved_lead.length(), 0.00001), err, map_err])


## A grab, a carry, a release and a re-grab, done the way the two hands actually
## do them — because neither of them tells anybody. The desktop pointer forces
## freeze/layer/mask to 0 and writes global_position with no signal; the VR grab
## driver is a RemoteTransform3D writing the whole global_transform.
func _assert_carry_cycle(art: Node3D, i: int) -> void:
	var rb: RigidBody3D = art.call("lead_node", i) as RigidBody3D
	var twin: Node3D = art.call("twin_node", i) as Node3D
	var os_: float = float((art.call("link_report") as Dictionary)["offset_scale"])
	var start: Vector3 = twin.position

	# GRAB, desktop style: state saved, freeze forced, layer and mask zeroed, and
	# nothing at all emitted. This is the exact body of _grab_held.
	var keep_freeze: bool = rb.freeze
	var keep_layer: int = rb.collision_layer
	var keep_mask: int = rb.collision_mask
	rb.freeze = true
	rb.collision_layer = 0
	rb.collision_mask = 0
	# CARRY: the pointer's 0.4 lerp toward a held target, one step per PHYSICS
	# frame and the step computed in the probe rather than read back off the body
	# (see _settle for why reading it back is a measurement of the physics server,
	# not of the hand).
	var pos: Vector3 = rb.position
	var target: Vector3 = pos + Vector3(0.06, 0.012, 0.03)
	for _f in range(10):
		pos = pos.lerp(target, 0.4)
		rb.position = pos
		await physics_frame
		await process_frame
	await _settle()
	var carried: Vector3 = twin.position
	var carry_map: float = _map_error(art, i)
	if (carried - start).length() < 0.05:
		_fails.append("carried and the twin did not move (%.4f m). Nothing in either grab path emits a signal, so this is the poll failing." % (carried - start).length())
	elif carry_map > EPS * os_:
		_fails.append("mid-carry the twin is %.4f m off its mapping" % carry_map)

	# RELEASE: state restored, again silently. The twin must still satisfy the
	# mapping — a release that moved it would mean the artifact had been keying
	# off freeze or off the collision layer, both of which LIE while held.
	rb.freeze = keep_freeze
	rb.collision_layer = keep_layer
	rb.collision_mask = keep_mask
	await _settle()
	var rel_map: float = _map_error(art, i)
	if rel_map > EPS * os_:
		_fails.append("after release the twin is %.4f m off its mapping" % rel_map)

	# RE-GRAB, VR style: the grab driver is a RemoteTransform3D and writes the
	# whole global_transform, rotation included.
	var mid: Vector3 = twin.position
	var lead_mid: Vector3 = rb.position
	var d2 := Vector3(-0.03, 0.006, -0.02)
	rb.global_transform = Transform3D(
		Basis(Vector3.UP, deg_to_rad(20.0)), rb.global_transform.origin + d2)
	await _settle()
	var again: Vector3 = twin.position - mid
	var lead_again: Vector3 = rb.position - lead_mid
	var err: float = (again - lead_again * os_).length()
	var end_map: float = _map_error(art, i)
	if lead_again.length() < 0.001:
		_fails.append("re-grab: the small body did not move, so nothing was tested")
	elif err > EPS * os_ or end_map > EPS * os_:
		_fails.append("re-grab: small moved %s, twin moved %s, wanted %s — mapping error %.4f m" % [
			str(lead_again), str(again), str(lead_again * os_), end_map])
	else:
		_notes.append("grab -> carry -> release -> re-grab all followed: carry %.3f m of twin travel, release mapping error %.5f m, re-grab %s = x%.2f" % [
			(carried - start).length(), rel_map, str(again),
			again.length() / maxf(lead_again.length(), 0.00001)])


func _report() -> void:
	var out := "COMPOSITION TWINS PROBE\n"
	for n in _notes:
		out += "  ok   %s\n" % n
	for f in _fails:
		out += "  FAIL %s\n" % f
	out += "%d fail(s), %d check(s)\n" % [_fails.size(), _notes.size() + _fails.size()]
	var fh := FileAccess.open(OUT, FileAccess.WRITE)
	if fh != null:
		fh.store_string(out)
		fh.close()
	print(out)
	quit(1 if not _fails.is_empty() else 0)
