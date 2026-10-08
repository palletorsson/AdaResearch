extends SceneTree

## THE GALLERY OF THE RHIZOME — six surfaces, shot from inside the same body.
##
## Every frame is taken standing in a CHAMBER at the player's own eye height,
## looking down a passage toward a chamber the walk probe has proved is actually
## reachable. A hollow body photographed from outside is a photograph of a lump;
## the whole subject is being on the inside of it.
##
## THE BODY IS BUILT ONCE. Six rebuilds would be six different rhizomes at 23 s
## each, and then the sheet would be comparing bodies rather than surfaces. So it
## is marched once and the shader's mode uniform is swapped on every chunk — same
## geometry, same seed, same lamp, one variable.
##
##   godot --path . --xr-mode off --script res://commons/testing/look_rhizome_inside.gd

const SCENE := "res://commons/artifacts/radial_inside/rhizome_inside.tscn"
const PLAYER := "res://commons/scenes/desktop_player.tscn"
const OUT := "user://rhizome_inside"
const SURFACES: Array[String] = ["wetflesh", "nacre", "chitin", "film", "lymph", "bone"]

var _eye: float = 1.60


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.012, 0.012, 0.018)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.22, 0.20, 0.27)
	e.ambient_light_energy = 0.65
	e.tonemap_mode = Environment.TONE_MAPPER_AGX
	e.tonemap_exposure = 1.15
	e.tonemap_white = 6.0
	e.glow_enabled = true
	e.glow_bloom = 0.0
	e.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	e.glow_hdr_threshold = 1.0
	e.set_glow_level(2, 0.6)
	e.set_glow_level(3, 1.0)
	e.set_glow_level(4, 1.0)
	env.environment = e
	root.add_child(env)

	# A CAVITY HAS NO SUN. One lamp travelling with the eye so the wall reads at
	# all; the sutures supply the rest, which is the point of drawing them.
	var lamp := OmniLight3D.new()
	lamp.omni_range = 18.0
	lamp.light_energy = 2.0
	lamp.light_color = Color(1.0, 0.93, 0.90)
	root.add_child(lamp)

	var cam := Camera3D.new()
	cam.fov = 80.0
	cam.near = 0.04
	root.add_child(cam)
	cam.current = true

	var t0: int = Time.get_ticks_msec()
	var n: Node3D = (load(SCENE) as PackedScene).instantiate() as Node3D
	n.set("seed", 3)
	n.set("surface", "wetflesh")
	root.add_child(n)
	await process_frame
	print("[look] built in %d ms" % (Time.get_ticks_msec() - t0))

	var chunks: Array = _chunk_mats(n)
	print("[look] %d chunk material(s)" % chunks.size())
	if chunks.is_empty():
		print("[look] nothing to shoot")
		quit(1)
		return

	var pts: Array = n.call("cavity_points")
	var edges: Array = n.call("graph_edges")
	if pts.size() < 3 or edges.is_empty():
		print("[look] the body exposes %d chamber(s) and %d edge(s)" % [pts.size(), edges.size()])
		quit(1)
		return

	# THREE STANDPOINTS, each in a chamber and each aimed down a real passage —
	# the edges the probe walked, not lines drawn between centres.
	var shots: Array = []
	for e_v in edges:
		var ed: Array = e_v
		shots.append([int(ed[0]), int(ed[1])])
		if shots.size() >= 3:
			break

	var made: int = 0
	for si in range(SURFACES.size()):
		for m_v in chunks:
			(m_v as ShaderMaterial).set_shader_parameter("mode", si)
		await process_frame
		for sh_v in shots:
			var sh: Array = sh_v
			var here: Vector3 = pts[int(sh[0])]
			var there: Vector3 = pts[int(sh[1])]
			# stand on the chamber floor, not at its centre: the cavity centre is
			# head height and a shot from there reads as a drone, not a visitor
			var eye: Vector3 = here + Vector3(0.0, -0.95 + _eye * 0.35, 0.0)
			cam.global_position = eye
			cam.look_at(there + Vector3(0.0, -0.95 + _eye * 0.35, 0.0), Vector3.UP)
			lamp.global_position = eye + Vector3(0.0, 0.35, 0.0)
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			var img: Image = get_root().get_texture().get_image()
			img.save_png("%s/%s__chamber-%d.png" % [OUT, SURFACES[si], int(sh[0])])
			made += 1
	print("[look] %d frame(s): %d surface(s) x %d standpoint(s)" % [made, SURFACES.size(), shots.size()])
	quit(0)


func _chunk_mats(n: Node) -> Array:
	var out: Array = []
	for m in _meshes(n):
		if m.material_override is ShaderMaterial:
			out.append(m.material_override)
	return out


func _meshes(n: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_meshes(c))
	return out
