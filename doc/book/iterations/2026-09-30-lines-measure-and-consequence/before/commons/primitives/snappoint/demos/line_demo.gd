extends Node3D

# @identity
# essence: snap_connection(pointA, pointB) → line — demonstrate the SnapConnectionManager wiring
# desire: learner sees the snap system itself as a subject — connections have categories and validation logic
# critical_parameter: SnapConnectionManager — the node that tracks which snap points are linked
# triggers: any snap or unsnap event — CategoryLogicDisplay shows/hides to reflect current connection state
# emerges: that snap networks can encode semantic rules — not just any point connects to any other
# needs: [missing VR controls — purely demonstrative, driven by scene-level snap events]
# relationships: depends on SnapConnectionManager; in Point_Lines the first connection blows apart the nearest do_not_cross_barrier in the same hall instance
# truth: a connection is not just spatial proximity — it carries categorical meaning about what fits with what

## MAKE IT POP (2026-09-01, Palle: "larger points, glowing, new display that is
## a bit bigger and higher up").
##
## Two ends and the segment between them is the first thing the room asks you to
## make, and it was rendering as two 18 mm dots and a small panel at knee height.
##
## THE GLOW IS GONE — see point_color. It was three additive shells, and it was
## answering the wrong question; a black ball makes the room's argument better.
##
## The points are enlarged through point_mesh's own set_radius(),
## which rebuilds the sphere properly, rather than by scaling the node — scaling
## a pickable scales its collider and its grab feel with it.
@export var point_radius_m: float = 0.075
## SOLID BLACK, NO RINGS (2026-09-01, Palle: "make the point sphere i like black
## solid fetch noir no outer rings").
##
## The three additive shells are gone. They were built to answer "make it glow",
## and glow was the wrong instrument for this room: a point that emits light is a
## point advertising itself, and Point_One spent its whole text arguing that the
## visible sphere is scaffolding for three invisible floats. A black ball says
## that better than a lit one — it takes light and gives nothing back, which is
## the closest a rendered object gets to admitting it is a stand-in.
##
## Not pure #000: 0.035 with a low roughness keeps a single specular highlight,
## so the sphere still reads as round rather than as a hole in the frame.
@export var point_color: Color = Color(0.035, 0.033, 0.038)
@export var point_roughness: float = 0.18
## How far apart the two ends START, metres.
##
## The scene placed them 0.30 m apart, which was right for 18 mm dots and wrong
## the moment they became 75 mm ones: the capture showed a single blob, and a
## room whose first sentence is "two points" cannot
## afford its two points to read as one. They are draggable, so this is only
## where they begin — but where a thing begins is what most people will see.
@export var point_separation_m: float = 0.52
## ABOVE THE POINTS, NOT BEHIND THEM. The snap points sit at y = 1.5 in the
## scene, and the first attempt put a 0.46 m-tall screen centred at 1.66 — so it
## spanned 1.43 to 1.89 at z = 0 and the two points hung in the middle of their
## own instructions. The photograph showed the text reading THROUGH the spheres.
@export var display_height_m: float = 2.94
## And set back, so a point being dragged never crosses in front of the words.
@export var display_z_m: float = -0.72
## Where the ceiling is. The screen hangs from it on two drops, so it reads as
## suspended above the work rather than floating at nothing — and the gap between
## the points and the screen becomes a real distance you can see the length of,
## instead of two things at similar heights competing for the same glance.
@export var ceiling_m: float = 3.62
## THE RAIL the drops hang from — a horizontal bar above the screen, wider than
## it, in the drops' own plane.
##
## Without it the two drops end in mid-air and the screen reads as hanging from
## nothing in particular. With it there is a thing they hang FROM, and the whole
## assembly becomes a fitting somebody installed rather than a panel that happens
## to be up there. It is also, in a room about lines, one more line — horizontal,
## structural, load-bearing in both senses, and the only one here you are not
## invited to touch.
@export var rail_span_scale: float = 2.84
@export var rail_color: Color = Color(0.86, 0.27, 0.24)
## Wider, because it moved further away. A screen that recedes without growing
## reads as smaller, not as further off.
@export var display_width_m: float = 1.02

const TextScreenScript = preload("res://commons/ui/text_screen.gd")

@onready var manager = $SnapConnectionManager
@onready var logic_display = $CategoryLogicDisplay

var _screen = null
var _solved: bool = false

## First successful connection; moving or reconnecting the ends remains possible.
signal solved()

func _ready() -> void:
	if manager:
		manager.connection_created.connect(_on_connection_created)
		manager.connection_broken.connect(_on_connection_broken)
	_pop()

## Bigger ends, black, and one display worth reading from standing.
func _pop() -> void:
	var ends: Array = []
	for child in get_children():
		if str(child.name).begins_with("SnapPoint"):
			ends.append(child)
	# Set them symmetrically about the demo's own centre, in scene order.
	var count: int = ends.size()
	for i in count:
		var e = ends[i]
		if e is Node3D and count > 1:
			var t: float = float(i) / float(count - 1)   # 0 .. 1
			e.position.x = lerpf(-point_separation_m * 0.5,
					point_separation_m * 0.5, t)

	for child in ends:
		# THE SNAP RANGE HAS TO GROW WITH THE POINTS, or there is no line to see.
		#
		# snap_point.gd connects two points when they come within snap_distance,
		# which ships at 0.15 m. That was fine for 18 mm dots. At 75 mm it is a
		# disaster with no error message: two snapped points are 0.15 m apart and
		# their radii sum to exactly 0.15, so they TOUCH, and the connecting line
		# — which runs centre to centre — is entirely buried inside the two
		# spheres. The connection fires, the line exists, and the room looks like
		# two points that refuse to join.
		#
		# So the threshold is set from the point size rather than left at a
		# constant that silently assumed one. Six radii leaves ~0.3 m of line
		# showing between the two surfaces at the moment they snap.
		if "snap_distance" in child:
			child.snap_distance = point_radius_m * 6.0

		var mesh: MeshInstance3D = _find_mesh(child)
		if mesh == null:
			continue
		# the sphere, rebuilt at a size you can see across a room
		for n in mesh.get_children():
			if n.has_method("set_radius"):
				n.call("set_radius", point_radius_m)
		_blacken(child, mesh)

	# THE DISPLAY. The old CategoryLogicDisplay stays in the scene and stays
	# wired — other demos read its state — but it is no longer the thing you are
	# meant to read, so it steps aside for a TextScreen at standing height.
	if logic_display:
		logic_display.visible = false
	_screen = TextScreenScript.new()
	_screen.mode = 0                                  # TextScreen.Mode.SCREEN
	_screen.width_m = display_width_m
	_screen.title = "A LINE"
	_screen.body = "Two points. Drag either one.
What is between them is the line."
	_screen.position = Vector3(0, display_height_m, display_z_m)
	add_child(_screen)
	_hang_it()


## Two thin drops from the ceiling to the top of the screen.
##
## Without them the display is a rectangle at an arbitrary altitude; with them it
## is a thing somebody mounted, and the eye reads the height as deliberate. It
## also gives the vertical gap a measurable body, which in a room whose whole
## argument is that a distance becomes a length once you can see it is not a
## decorative point.
func _hang_it() -> void:
	var screen_top: float = display_height_m + (display_width_m * 0.62) * 0.5
	var drop: float = maxf(0.05, ceiling_m - screen_top)

	# The rail first, so the drops have something to end at.
	var rail := MeshInstance3D.new()
	rail.name = "Rail"
	var rm := CylinderMesh.new()
	rm.top_radius = 0.028
	rm.bottom_radius = 0.028
	rm.height = display_width_m * rail_span_scale
	rail.mesh = rm
	rail.rotation = Vector3(0, 0, PI * 0.5)          # lay it horizontal
	rail.position = Vector3(0, ceiling_m, display_z_m)
	var railm := StandardMaterial3D.new()
	railm.albedo_color = rail_color
	railm.roughness = 0.42
	railm.emission_enabled = true
	railm.emission = rail_color
	railm.emission_energy_multiplier = 0.5
	rail.material_override = railm
	add_child(rail)

	for side in [-1.0, 1.0]:
		var rod := MeshInstance3D.new()
		rod.name = "Drop"
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.012
		cyl.bottom_radius = 0.012
		cyl.height = drop
		rod.mesh = cyl
		rod.position = Vector3(side * display_width_m * 0.42,
				screen_top + drop * 0.5, display_z_m)
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.28, 0.29, 0.33)
		m.roughness = 0.5
		m.metallic = 0.4
		rod.material_override = m
		add_child(rod)


func _find_mesh(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D:
		return n
	for c in n.get_children():
		var r := _find_mesh(c)
		if r != null:
			return r
	return null


## SOLID BLACK — and the snap point's OWN material is replaced, not overridden.
##
## snap_point.gd owns this mesh: it captures `_original_material` in its _ready
## and swaps a built `_glow_material` in on pickup, restoring the original on
## drop. Setting only material_override from out here would look right until the
## first grab, after which the restore would put the ORIGINAL cyan back and the
## points would silently change colour halfway through the room.
##
## So both are set: the override for now, and `_original_material` so that what
## the snap point restores is also black. The pickup highlight still works — it
## builds its glow FROM whatever _original_material is, so the grab now flares a
## black ball instead of a cyan one, which is the right behaviour and not a
## side effect worth avoiding.
func _blacken(point: Node, mesh: MeshInstance3D) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = point_color
	m.roughness = point_roughness
	m.metallic = 0.0
	m.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	mesh.material_override = m
	if "_original_material" in point:
		point.set("_original_material", m)


func _on_connection_created(point_a, point_b, line) -> void:
	# Hide instruction display when a connection is made
	if logic_display:
		logic_display.visible = false
	if _solved or not is_instance_valid(line):
		return
	# Only this demonstration's two ends can complete its encounter.
	if not ((point_a == $SnapPoint1 and point_b == $SnapPoint2)
			or (point_a == $SnapPoint2 and point_b == $SnapPoint1)):
		return
	_solved = true
	solved.emit()
	# Snap callbacks may arrive during a physics flush. Break the barrier afterward.
	call_deferred("_open_point_lines_barrier")


func _open_point_lines_barrier() -> void:
	# Never search the whole museum: several halls can be loaded at once.
	var hall: Node = get_parent()
	while hall != null:
		var map_id: String = str(hall.get_meta("em_map", hall.get_meta("map_name", "")))
		if not map_id.is_empty():
			if map_id == "Point_Lines":
				var barrier: Node3D = _nearest_barrier(hall)
				if barrier != null:
					barrier.trigger_explosion()
			return
		hall = hall.get_parent()


func _nearest_barrier(hall: Node) -> Node3D:
	var nearest: Node3D = null
	var distance: float = INF
	var pending: Array[Node] = [hall]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if node.is_queued_for_deletion():
			continue
		if node != hall and (node.has_meta("em_map") or node.has_meta("map_name")):
			continue
		if node is DoNotCrossBarrier and not node.is_broken():
			var candidate_distance: float = global_position.distance_squared_to(node.global_position)
			if candidate_distance < distance:
				nearest = node
				distance = candidate_distance
		for child in node.get_children():
			pending.append(child)
	return nearest

func _on_connection_broken(_point_a, _point_b) -> void:
	# Show instruction display again if connection is broken
	if logic_display:
		logic_display.visible = true
