extends "res://supplied/sheet_tools.gd"
## The Extrude kit's sheet. It needs a window, so run it WITHOUT --headless,
## from this folder:
##   godot --path . --xr-mode off --script res://sheet.gd
## It writes
##   sheet.png    the four values of taper (1.0, 0.6, 0.2, 0.0), each solid alone
##                in the studio, from the side, from straight above and from a
##                corner: twelve tiles
##   process.png  the strip: one still after each of the eight operations
##   sheet.json   every pair of the four from each standpoint, how much of the
##                still each solid covers, six equal steps of taper each against
##                the next, the same solid with smoothed normals against the
##                flat one, and how much each step of the strip changed
## and the single stills, in stills/. Every solid is made by the learner's own
## function, extrude() in extrude.gd; only the unfinished solids of the strip
## (walls alone, one cap, smoothed normals) are made here, by stage(), and
## stage() with everything on is compared with extrude() before it is used.

const Segment := preload("res://supplied/segment.gd")
const Grammar := preload("res://borrowed/grammar_extrude.gd")
const TAPERS := [1.0, 0.6, 0.2, 0.0]
const NAMES := ["taper 1.0: a prism", "0.6: a frustum", "0.2", "0.0: a pyramid"]
const HEIGHT := 0.8
const DISTANCE := 2.5                       # metres from the eye to the middle, side and above
const CORNER := Vector3(1.9, 1.5, 2.1)      # the third standpoint: over a corner
const STRIP_EYE := Vector3(1.3, 1.7, 3.0)
const STRIP_AT := Vector3(0.0, 0.6, 0.0)

var maker: Node3D      # extrude.gd, for its walk and its function

func run() -> void:
	maker = load("res://extrude.gd").new()
	await sheet()
	await equal_steps()
	await smooth_against_flat()
	await process_strip()
	maker.free()

func solid(mesh: ArrayMesh) -> MeshInstance3D:
	var body := MeshInstance3D.new()
	body.mesh = mesh
	body.material_override = Look.paint(Look.BODY)
	return body

## The comparison sheet: every value from three standpoints, every pair measured.
func sheet() -> void:
	var tiles: Array[Image] = []
	report["covers_pct"] = {}
	for view: String in ["side", "above", "corner"]:
		var stills := []
		var pixels := []
		for taper: float in TAPERS:
			var body := solid(maker.extrude(maker.walk, HEIGHT, taper))
			await stand(body)
			if view == "corner":
				look_from(CORNER, Vector3(0.0, 0.4, 0.0))
				shadows(false)
			else:
				look("level" if view == "side" else "above", DISTANCE)
			var taken: Array = await portrait(body, "taper_%.1f_%s" % [taper, view])
			stills.append(taken[0])
			pixels.append(taken[1])
			tiles.append(small(taken[0]))
			report["covers_pct"]["%s, taper %.1f" % [view, taper]] = share(taken[1])
			print("%s, taper %.1f: the solid covers %.2f%% of the still" % [view, taper, share(taken[1])])
		var short := []
		for taper: float in TAPERS:
			short.append("%.1f" % taper)
		report["pairs_" + view] = compare_all(short, stills, pixels)
		print("%s: the closest pair is %s, the farthest %s" % [view, report["pairs_" + view]["closest"], report["pairs_" + view]["farthest"]])
	report["sheet_png"] = await compose(tiles, TAPERS.size(), NAMES, "res://sheet.png")
	report["sheet_rows"] = ["from the side, 2.5 m from the middle", "from straight above, 2.5 m", "from a corner, the eye at (1.9, 1.5, 2.1)"]

## The four values are not equally far apart (0.4, 0.4, 0.2). So the same
## solid in six equal steps of 0.2, from the side: each against the next.
func equal_steps() -> void:
	var stills := []
	var pixels := []
	var tapers := [1.0, 0.8, 0.6, 0.4, 0.2, 0.0]
	for taper: float in tapers:
		var taken: Array = await photograph(solid(maker.extrude(maker.walk, HEIGHT, taper)), "level", "step_%.1f_side" % taper, DISTANCE)
		stills.append(taken[0])
		pixels.append(taken[1])
	report["equal_steps_side"] = {}
	for i in range(1, tapers.size()):
		var pair := compare(stills[i - 1], pixels[i - 1], stills[i], pixels[i])
		report["equal_steps_side"]["%.1f vs %.1f" % [tapers[i - 1], tapers[i]]] = pair
		print("equal steps, side: %.1f vs %.1f differ on %5.2f%% of the still: %5.2f%% outline, %5.2f%% inside" % [tapers[i - 1], tapers[i], pair["differ_pct"], pair["outline_pct"], pair["inside_pct"]])

## The planted bug as pixels: the same triangles with the normals smoothed over
## the corners (SurfaceTool's default) against one normal for each triangle.
func smooth_against_flat() -> void:
	report["smooth_vs_flat"] = {}
	for view: String in ["side", "corner"]:
		var stills := []
		var pixels := []
		for flat: bool in [false, true]:
			var body := solid(stage(maker.walk, HEIGHT, 1.0, true, true, true, flat))
			await stand(body)
			if view == "corner":
				look_from(CORNER, Vector3(0.0, 0.4, 0.0))
				shadows(false)
			else:
				look("level", DISTANCE)
			var taken: Array = await portrait(body, "%s_%s" % ["flat" if flat else "smooth", view])
			stills.append(taken[0])
			pixels.append(taken[1])
		report["smooth_vs_flat"][view] = compare(stills[0], pixels[0], stills[1], pixels[1])
		print("smoothed against flat, %s: they differ on %.2f%% of the still, %.2f%% of it inside the solid" % [view, report["smooth_vs_flat"][view]["differ_pct"], report["smooth_vs_flat"][view]["inside_pct"]])

## The solid as it stood after each step of the lesson. `flat` is the one line
## surface.set_smooth_group(-1). With every part on, flat, it is extrude().
func stage(outline: Array[Vector3], rise: float, top: float, walls: bool, top_cap: bool, bottom_cap: bool, flat: bool) -> ArrayMesh:
	var centre: Vector3 = maker.centre_of(outline)
	var upper: Array[Vector3] = []
	for corner in outline:
		upper.append(centre + (corner - centre) * top + Vector3.UP * rise)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	if flat:
		surface.set_smooth_group(-1)
	if walls:
		for i in range(outline.size()):
			for corner: Vector3 in [outline[i - 1], outline[i], upper[i], outline[i - 1], upper[i], upper[i - 1]]:
				surface.add_vertex(corner)
	if top_cap:
		for i in range(1, outline.size() - 1):
			for corner: Vector3 in [upper[0], upper[i], upper[i + 1]]:
				surface.add_vertex(corner)
	if bottom_cap:
		for i in range(1, outline.size() - 1):
			for corner: Vector3 in [outline[0], outline[i + 1], outline[i]]:
				surface.add_vertex(corner)
	surface.generate_normals()
	return surface.commit()

func same_mesh(a: ArrayMesh, b: ArrayMesh) -> bool:
	var first := a.surface_get_arrays(0)
	var second := b.surface_get_arrays(0)
	return first[Mesh.ARRAY_VERTEX] == second[Mesh.ARRAY_VERTEX] and first[Mesh.ARRAY_NORMAL] == second[Mesh.ARRAY_NORMAL]

## The process strip: one still after each operation, from one standpoint.
func process_strip() -> void:
	var names := ["1 the walked outline", "2 a wall for every edge", "3 the top: the fan", "4 the bottom: the fan reversed",
		"5 one normal for each triangle", "6 taper 0.6", "7 a collider: the marble stays", "8 extruded again: six spires"]
	var walk: Array[Vector3] = maker.walk
	report["stage_equals_extrude"] = same_mesh(stage(walk, HEIGHT, 0.6, true, true, true, true), maker.extrude(walk, HEIGHT, 0.6))
	print("stage() with every part on is extrude(): ", report["stage_equals_extrude"])
	var tiles: Array[Image] = []
	var group := Node3D.new()
	await stand(group, false)          # not held: the marble has to fall
	look_from(STRIP_EYE, STRIP_AT)
	for i in range(walk.size()):
		var segment := Segment.new()
		group.add_child(segment)
		segment.show_between(walk[i - 1], walk[i])
	tiles.append(small(await shot("strip_1")))
	var body := solid(null)
	group.add_child(body)
	var meshes := [
		stage(walk, HEIGHT, 1.0, true, false, false, false),
		stage(walk, HEIGHT, 1.0, true, true, false, false),
		stage(walk, HEIGHT, 1.0, true, true, true, false),
		maker.extrude(walk, HEIGHT, 1.0),
		maker.extrude(walk, HEIGHT, 0.6),
	]
	var counts := []
	for i in meshes.size():
		body.mesh = meshes[i]
		tiles.append(small(await shot("strip_%d" % (i + 2))))
		counts.append((meshes[i].surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3)
	# 7: a collider made from the mesh, and the marble dropped over the middle.
	var wall := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	shape.shape = body.mesh.create_trimesh_shape()
	wall.add_child(shape)
	body.add_child(wall)
	var marble: RigidBody3D = load("res://supplied/marble.tscn").instantiate()
	marble.position = Vector3(1.6, 0.1, 0.8)
	group.add_child(marble)
	var over: Vector3 = maker.centre_of(walk) + Vector3.UP * (HEIGHT + 1.0)
	marble.drop(over)
	for i in 240:
		await physics_frame
	tiles.append(small(await shot("strip_7")))
	var on_frustum := marble.global_position
	# 8: the same solid handed to the project's extrude; the collider is made again.
	body.mesh = Grammar.extrude_up(body.mesh, 0.5, 0.3)
	shape.shape = body.mesh.create_trimesh_shape()
	marble.drop(over)
	for i in 240:
		await physics_frame
	tiles.append(small(await shot("strip_8")))
	counts.append(counts[-1])
	counts.append((body.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3)
	report["strip"] = await strip(tiles, names)
	report["strip"]["triangles"] = [0] + counts
	report["strip"]["marble_on_the_frustum_m"] = snappedf(on_frustum.y, 0.001)
	report["strip"]["marble_on_the_spires_m"] = snappedf(marble.global_position.y, 0.001)
	print("strip: triangles ", report["strip"]["triangles"], "; the marble on the frustum at %.3f m, among the spires at %.3f m" % [on_frustum.y, marble.global_position.y])
