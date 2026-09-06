extends SceneTree

## Is the ceiling gone, is that really NASA's sky, and does the moon MOVE?
## (2026-09-05)
##
## Palle: "Remove the ceiling in endless museum and add the night sky from
## ... sphere_world_demo.tscn also add a moon a the global moving light source."
##
## Three claims, and each one has a way of looking finished while being nothing:
##
##   THE CEILING     is an absence. Absence prints nothing, and a hall with no
##                   ceiling looks exactly like a hall whose ceiling failed to
##                   build for some other reason. So the buckets are COUNTED.
##
##   THE SKY         is a texture in a shader parameter. If the panorama did not
##                   import, the sampler reads black — and a black dome under a
##                   night sky is indistinguishable from a working one in every
##                   screenshot ever taken indoors. So the texture's own
##                   resource_path is read back off the material.
##
##   THE MOON        is the hardest, because a stationary moon and a moving one
##                   photograph identically. "Moving" is checked twice: the aiming
##                   function is called at four times and its geometry measured,
##                   and then the light is left alone for a second and a half and
##                   asked whether it went anywhere by itself.
##
## Run it with night on, then with commons/data/em_layout.json night.enabled 0
## and night.ceiling 1 — every line here must invert.
##
##   godot --path . --xr-mode off --script res://commons/testing/probe_night_museum.gd -- --em-segments=2

const MUSEUM := "res://commons/scenes/endless_museum.tscn"
const LAYOUT := "res://commons/data/em_layout.json"
const REPORT := "res://ada_run/night_museum_probe.txt"
const PANORAMA_FILE := "starmap_2020_no_figures_4k.jpg"

var _lines: Array[String] = []
var _fails: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var cfg: Dictionary = _night_cfg()
	var want_night: bool = float(cfg.get("enabled", 0.0)) > 0.5
	var want_ceiling: bool = float(cfg.get("ceiling", 1.0)) > 0.5
	_lines.append("[probe] em_layout night: enabled=%s ceiling=%s moon_energy=%s period_s=%s altitude_deg=%s" % [
		str(cfg.get("enabled", "<unset>")), str(cfg.get("ceiling", "<unset>")),
		str(cfg.get("moon_energy", "-")), str(cfg.get("period_s", "-")), str(cfg.get("altitude_deg", "-"))])

	var mus: Node3D = (load(MUSEUM) as PackedScene).instantiate() as Node3D
	root.add_child(mus)

	# the dress is queued behind the shell, so a census taken when the floor
	# appears counts an undressed hall and calls it a removed ceiling
	var waited: int = 0
	while waited < 3600:
		await process_frame
		waited += 1
		if _find_typed(mus, "MultiMeshInstance3D", ["Skirting", "Trim", "Ceiling", "ArrisCeiling"]).size() > 0:
			break
	for _i in range(20):
		await process_frame
	_lines.append("[probe] em_detail dressed after %d frame(s)" % waited)

	# ── 1. THE CEILING ───────────────────────────────────────────────────
	var ceil_nodes: Array = _find_typed(mus, "MultiMeshInstance3D", ["Ceiling", "ArrisCeiling"])
	var trim_nodes: Array = _find_typed(mus, "MultiMeshInstance3D", ["Skirting", "Trim", "ArrisSkirting", "ArrisTrim"])
	var ceil_panels: int = 0
	for n in ceil_nodes:
		var xf: Variant = (n as Node).get_meta("em_xforms", [])
		if xf is Array:
			ceil_panels += (xf as Array).size()
	# The trim count is the CONTROL. Without it, "0 ceilings" is also what a hall
	# that dressed nothing at all looks like — and this probe would then pass on a
	# museum with no interior finish whatsoever.
	if want_ceiling:
		_check(ceil_nodes.size() > 0 and ceil_panels > 0,
			"the ceiling is hung: %d bucket(s), %d panel(s), beside %d trim bucket(s)" % [
				ceil_nodes.size(), ceil_panels, trim_nodes.size()],
			"night.ceiling is 1 but no ceiling was built (%d trim bucket(s) did build, so the dress ran)" % trim_nodes.size())
	else:
		_check(ceil_nodes.is_empty() and trim_nodes.size() > 0,
			"no ceiling anywhere: 0 buckets, while %d trim bucket(s) DID build — the dress ran and left the sky open" % trim_nodes.size(),
			"%d ceiling bucket(s) carrying %d panel(s) still hang" % [ceil_nodes.size(), ceil_panels]
				if not ceil_nodes.is_empty()
				else "nothing dressed at all (0 trim buckets) — this is an undressed hall, not an unroofed one")

	# ── 2. THE SKY ───────────────────────────────────────────────────────
	var env: Environment = _environment(mus)
	if env == null:
		_check(false, "", "no Environment in the museum at all")
	else:
		var sky: Sky = env.sky
		var mat: Material = sky.sky_material if sky != null else null
		var tex_path := ""
		if mat is ShaderMaterial:
			var t: Variant = (mat as ShaderMaterial).get_shader_parameter("panorama")
			if t is Texture2D:
				tex_path = (t as Texture2D).resource_path
		if want_night:
			_check(tex_path.ends_with(PANORAMA_FILE),
				"the dome samples %s — the starfield is really in the material, not a black fallback" % tex_path.get_file(),
				("the sky material carries no panorama at all (%s) — em_environment fell back to the day dome, so the import did not take"
					% ("no ShaderMaterial" if not (mat is ShaderMaterial) else "panorama parameter empty"))
					if tex_path == "" else "the dome samples %s, which is not the starmap" % tex_path)
			# and the ambient was moved with it — the night ambient block is the
			# difference between "night" and "the lights went out"
			_check(env.ambient_light_sky_contribution < 0.99 and env.ambient_light_energy > 0.30,
				"night ambient in force: sky contribution %.2f, energy %.2f, colour %s" % [
					env.ambient_light_sky_contribution, env.ambient_light_energy, str(env.ambient_light_color)],
				"ambient is still the daylit one (contribution %.2f, energy %.2f) — the dome went dark and nothing replaced it" % [
					env.ambient_light_sky_contribution, env.ambient_light_energy])
		else:
			_check(tex_path == "",
				"no panorama on the dome — the day sky is back",
				"night.enabled is 0 and the dome is still sampling %s" % tex_path.get_file())

	# ── 3. THE MOON, AND WHETHER IT MOVES ────────────────────────────────
	var moon: DirectionalLight3D = null
	var sun: DirectionalLight3D = null
	for c in mus.get_children():
		if c is DirectionalLight3D:
			if String(c.name) == "Moon":
				moon = c
			elif String(c.name) == "Sun":
				sun = c
	if not want_night:
		_check(moon == null and sun != null,
			"the Sun is back and there is no Moon",
			"night.enabled is 0 but the world carries %s" % ("a Moon" if moon != null else "no directional light at all"))
		_finish()
		return

	_check(moon != null,
		"the world's directional light is the Moon (colour %s, energy %.2f, shadows %s)" % [
			str(moon.light_color) if moon != null else "-",
			moon.light_energy if moon != null else 0.0,
			"on" if moon != null and moon.shadow_enabled else "OFF"],
		"there is no DirectionalLight3D named Moon — %s" % ("the Sun is still there" if sun != null else "no directional light at all"))
	if moon == null:
		_finish()
		return

	# THE GEOMETRY, called rather than waited for: four points around one circuit.
	# The design claim is a CONSTANT altitude — the moon circles the zenith rather
	# than rising and setting, so the museum is never in the dark and never lit
	# edge-on. That claim is one number, and it is the same number four times.
	var period: float = float(cfg.get("period_s", 480.0))
	var want_alt: float = deg_to_rad(clampf(float(cfg.get("altitude_deg", 38.0)), 5.0, 85.0))
	var alts: Array[float] = []
	var azis: Array[float] = []
	for k in range(4):
		mus.call("_aim_moon", period * float(k) / 4.0)
		var from: Vector3 = moon.global_transform.basis.z.normalized()
		alts.append(asin(clampf(from.y, -1.0, 1.0)))
		azis.append(atan2(from.z, from.x))
	var alt_spread: float = 0.0
	for a in alts:
		alt_spread = maxf(alt_spread, absf(a - want_alt))
	_check(alt_spread < 0.02,
		"the moon holds %.1f° of altitude all the way round (spread %.3f°) — always up, never edge-on" % [
			rad_to_deg(want_alt), rad_to_deg(alt_spread)],
		"the moon's altitude wanders %.1f° off the %.1f° asked for — it rises and sets, and the museum goes dark for half of every circuit" % [
			rad_to_deg(alt_spread), rad_to_deg(want_alt)])
	var quarter: float = absf(rad_to_deg(_wrap_pi(azis[1] - azis[0])))
	_check(absf(quarter - 90.0) < 1.0,
		"a quarter of a period turns the moon %.1f° of azimuth — one circuit is one period" % quarter,
		"a quarter period turned it %.1f°, not 90° — the period is not the period" % quarter)

	# AND THEN LEAVE IT ALONE. Everything above called the aiming function by
	# hand, which proves the arithmetic and NOT that anything ever calls it. A
	# moon that only moves when a probe pokes it is a still moon in the museum.
	# READ IT WHERE THE MUSEUM PUT IT, NOT WHERE THIS PROBE LEFT IT. Twice now the
	# baseline was one the probe had authored: first _aim_moon(0.0) called for a
	# "clean" start (measured 2.108° against 0.886° due), then the four-point loop
	# above leaving the moon at three quarters of a circuit (69.501° against
	# 0.887°). Both times the reading was a fact about the probe, and both times it
	# accused the museum of moving at the wrong rate. One frame hands the pose back
	# to _process before anything is measured.
	await process_frame
	await process_frame
	var before: Vector3 = moon.global_transform.basis.z.normalized()
	var t0: int = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 1500:
		await process_frame
	var elapsed: float = float(Time.get_ticks_msec() - t0) / 1000.0
	var after: Vector3 = moon.global_transform.basis.z.normalized()
	var turned: float = rad_to_deg(before.angle_to(after))
	# AND COMPARE LIKE WITH LIKE. angle_to is the angle between two DIRECTIONS; the
	# period is a turn of AZIMUTH. On a cone of altitude a, an azimuth step d
	# subtends acos(sin^2 a + cos^2 a cos d) — at 38° that is 0.79 of d, which is
	# most of the gap the first version reported as a fault in the museum.
	var dazim: float = TAU * elapsed / maxf(period, 0.001)
	var sa: float = sin(want_alt)
	var cxa: float = cos(want_alt)
	var expect: float = rad_to_deg(acos(clampf(sa * sa + cxa * cxa * cos(dazim), -1.0, 1.0)))
	# ── 4. AND THE DISC IS WHERE THE LIGHT IS ────────────────────────────
	# Everything above is about the LIGHT. The moon you can see is drawn by the sky
	# shader along LIGHT0_DIRECTION, and the first version had that sign the way
	# the day dome states it — which put the disc on the opposite side of the sky.
	# Nothing failed: the museum was lit correctly from the east while the moon was
	# in the west, and it took a 40-degree debug moon and a debug tint to find,
	# because no probe was asking where the bright thing in the sky was.
	#
	# So bake the dome and look. sky_bake_panorama returns what the shader actually
	# drew, and the brightest pixel in it is the moon; its direction must be the
	# direction the light comes from.
	var sky2: Sky = env.sky if env != null else null
	var pano: Image = null
	if sky2 != null:
		pano = RenderingServer.sky_bake_panorama(sky2.get_rid(), 1.0, false, Vector2i(256, 128))
	if pano == null:
		_check(false, "", "the dome could not be baked, so nothing here knows where the moon is drawn")
	else:
		var bw: int = pano.get_width()
		var bh: int = pano.get_height()
		var best: float = -1.0
		var bx: int = 0
		var by: int = 0
		for y in range(bh):
			for x in range(bw):
				var c: Color = pano.get_pixel(x, y)
				var l: float = c.r + c.g + c.b
				if l > best:
					best = l
					bx = x
					by = y
		var phi: float = ((float(bx) + 0.5) / float(bw) - 0.5) * TAU
		var theta: float = (float(by) + 0.5) / float(bh) * PI
		var st: float = sin(theta)
		var drawn := Vector3(sin(phi) * st, cos(theta), -cos(phi) * st).normalized()
		var lit: Vector3 = moon.global_transform.basis.z.normalized()
		var off: float = rad_to_deg(drawn.angle_to(lit))
		_check(off < 15.0,
			"the brightest point of the baked dome is %.1f° from the direction the light comes from — the disc is on the moon's own side" % off,
			"the dome's brightest point is %.1f° away from the light (drawn %s, light from %s) — %s" % [
				off, str(drawn.round()), str(lit.round()),
				"the disc is on the WRONG SIDE of the sky" if off > 120.0 else "the disc and the light have drifted apart"])

	_check(turned > 0.02 and absf(turned - expect) < maxf(expect * 0.35, 0.10),
		"left alone for %.2f s the moon turned %.3f° by itself (%.3f° expected at a %.0f s period)" % [
			elapsed, turned, expect, period],
		"the moon did not move: %.4f° in %.2f s, against %.3f° expected — _process is not driving it" % [
			turned, elapsed, expect]
			if turned <= 0.02 else
			"the moon turned %.3f° in %.2f s but %.3f° was expected — it moves at the wrong rate" % [
				turned, elapsed, expect])

	_finish()


func _wrap_pi(a: float) -> float:
	return fposmod(a + PI, TAU) - PI


func _night_cfg() -> Dictionary:
	if not FileAccess.file_exists(LAYOUT):
		return {}
	var v: Variant = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT))
	if v is Dictionary and (v as Dictionary).get("night") is Dictionary:
		return (v as Dictionary)["night"]
	return {}


func _environment(n: Node) -> Environment:
	if n is WorldEnvironment and (n as WorldEnvironment).environment != null:
		return (n as WorldEnvironment).environment
	for c in n.get_children():
		var e: Environment = _environment(c)
		if e != null:
			return e
	return null


func _find_typed(n: Node, cls: String, names: Array) -> Array:
	var out: Array = []
	if n.is_class(cls) and names.has(String(n.name)):
		out.append(n)
	for c in n.get_children():
		out.append_array(_find_typed(c, cls, names))
	return out


func _check(ok: bool, line: String, why: String) -> void:
	_lines.append("[probe] %s  %s" % [line, "OK" if ok else "*** %s ***" % why])
	if not ok:
		_fails.append(why)


func _finish() -> void:
	var ok: bool = _fails.is_empty()
	_lines.append("[probe] %s%s" % ["PASS" if ok else "FAIL",
		"" if ok else " — " + String(";  ").join(PackedStringArray(_fails))])
	var f := FileAccess.open(REPORT, FileAccess.WRITE)
	if f != null:
		f.store_string(String.chr(10).join(PackedStringArray(_lines)) + String.chr(10))
		f.close()
	for l in _lines:
		print(l)
	quit(0 if ok else 1)
