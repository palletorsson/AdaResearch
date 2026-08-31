# WireframeThreshold.gd — stand in it and the museum shows how it is built
#
# @identity
# essence: a wireframe ring on the floor; stand inside and every surface in the room drops to its triangles, step out and it dresses again
# desire: learner stops treating the museum as a place and sees it as a mesh — walls, works and their own hands all made of the same triangles
# critical_parameter: undressing — which way the room comes apart (wireframe / overdraw / unshaded / normals); under it radius sets how much of the floor is the threshold, and blink_seconds whether it holds or flashes
# triggers: a body entering the Area3D; released on exit, on the last occupant leaving, and unconditionally when the node leaves the tree
# emerges: the recognition that the solidity of a room is a rendering decision, not a property of the room
# relationships: the room-scale answer to [[wireframe_confession]], which undresses one torus and leaves the world dressed around it
# truth: nothing here was ever solid — the surface is a decision made once per frame, and it can be unmade
extends Node3D
class_name WireframeThreshold

## HOW THIS WORKS, and the one thing that was checked before it was written.
##
## 2026-08-31, Palle: "a new artifact that when we step into it, it can blink the
## museum to wireframe. And when we step it goes back to normal."
##
## The whole idea rests on `Viewport.debug_draw`, and the docs leave a question
## open that decides whether it is buildable at all: wireframe index buffers are
## documented as generated when a mesh LOADS, which would mean an artifact cannot
## switch this on for a museum whose meshes are already in memory, and the flag
## would have to be set at boot instead — a global change, in a different file,
## for every run of the game.
##
## commons/testing/probe_wireframe.gd rendered it rather than guessing.
## On Godot 4.6, forward_plus, `debug_draw = DEBUG_DRAW_WIREFRAME` alone draws
## the triangles, with no `RenderingServer.set_debug_generate_wireframes()` call
## and no boot-time anything. So this artifact is self-contained: nothing outside
## this folder changes, and a map that does not place it is untouched.

## Which way the room comes apart. All four are the same gesture — the renderer
## asked to stop pretending — and each stops pretending about something else:
## wireframe shows the triangles, overdraw shows how many times a pixel was
## painted, unshaded strips the lighting, normals show which way each surface
## faces. They are held here as one export rather than four artifacts because
## the argument is the same and only the confession differs.
@export_enum("wireframe", "overdraw", "unshaded", "normals") var undressing: String = "wireframe"

## The same list as the @export_enum above. The enum is what the editor and
## tools/check_dna_declarations.py read; this is what an incoming map token is
## checked against.
const UNDRESSINGS: Array[String] = ["wireframe", "overdraw", "unshaded", "normals"]

const DRAW_MODE: Dictionary = {
	"wireframe": Viewport.DEBUG_DRAW_WIREFRAME,
	"overdraw": Viewport.DEBUG_DRAW_OVERDRAW,
	"unshaded": Viewport.DEBUG_DRAW_UNSHADED,
	"normals": Viewport.DEBUG_DRAW_NORMAL_BUFFER,
}

## Radius of the standing area, in metres. The ring is drawn at this radius, so
## what you see is exactly what you have to be inside.
@export var radius: float = 0.85
@export var height: float = 2.2

## 0.0 holds the undressing for as long as someone is standing in it — which is
## what was asked for. Above 0.0 it BLINKS instead: the room comes apart for that
## many seconds and dresses again while you are still standing there, so the
## threshold has to be stepped out of and back into to be used again.
@export var blink_seconds: float = 0.0

@export var ring_color: Color = Color(0.55, 0.85, 1.0)
@export var plate_color: Color = Color(0.09, 0.10, 0.13)

# WHO COUNTS AS SOMEONE STANDING HERE.
#
# The obvious mask is force_pad's PLAYER_MASK — layer 20, "Player Body", the VR
# rig. That alone would make this artifact invisible to the endless museum's own
# visitor: endless_museum.gd:3120 puts the walker in group `em_walker` and
# deliberately NOT in `player_body`, with a comment saying why (player_body is
# read by force_field_zone, drag_corridor and artifact_runner, and the walker was
# not meant to be shoved by every field in the corpus). It also never sets a
# collision_layer, so it is on the default layer 1 with the static world.
#
# So the mask has to take layer 1 as well, which means the floor and the walls
# arrive here too — every StaticBody3D in the room. That is what _is_occupant is
# for, and why it tests what a body IS rather than only which group it joined.
const PLAYER_MASK: int = 524288                     # layer 20, "Player Body"
const WORLD_MASK: int = 1                           # layer 1 — where the museum walker is
const OCCUPANT_GROUPS: Array[String] = ["player_body", "em_walker", "player", "vr_player"]

# ONE STUCK STATE IS THE FAILURE THAT MATTERS. If this artifact ever restores the
# wrong value the whole game is left undressed, which is unrecoverable without a
# restart, so the saved value and the occupancy count are STATIC: two overlapping
# thresholds, or a second one entered before the first is left, hand back the
# value the museum actually had rather than the one the second instance happened
# to observe.
static var _held: int = 0
static var _restore_to: int = Viewport.DEBUG_DRAW_DISABLED

var _area: Area3D
var _ring: MeshInstance3D
var _inside: Dictionary = {}          # body instance id -> true
var _blink_left: float = 0.0
var _holding: bool = false


func _ready() -> void:
	_build_plate()
	_build_ring()
	_build_area()
	set_process(false)


## Contract: runs AFTER _ready(), deferred from GridInteractablesComponent. A
## config that names nothing here must touch nothing.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("undressing"):
		var want: String = str(config_data["undressing"]).to_lower().strip_edges()
		if UNDRESSINGS.has(want) and want != undressing:
			undressing = want
			if _holding:                     # already standing in it — swap live
				_apply(DRAW_MODE[undressing])
	if config_data.has("blink_seconds"):
		blink_seconds = float(config_data["blink_seconds"])
	if config_data.has("radius"):
		radius = maxf(0.2, float(config_data["radius"]))
		_rebuild_shape()


# ------------------------------------------------------------------ the body

func _build_plate() -> void:
	var mi := MeshInstance3D.new()
	mi.name = "Plate"
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = 0.02
	mi.mesh = cyl
	mi.position = Vector3(0.0, 0.01, 0.0)
	var m := StandardMaterial3D.new()
	m.albedo_color = plate_color
	m.roughness = 0.9
	mi.material_override = m
	add_child(mi)


## The threshold is DRAWN as a wireframe when nothing else is. It is the one
## object in the room already in the state it puts everything else into, so it
## says what it does without a label — and when it fires, it is the only thing
## that does not change.
func _build_ring() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES)
	var segs: int = 48
	var top: float = height
	for i in range(segs):
		var a0: float = TAU * float(i) / float(segs)
		var a1: float = TAU * float(i + 1) / float(segs)
		var p0 := Vector3(cos(a0) * radius, 0.02, sin(a0) * radius)
		var p1 := Vector3(cos(a1) * radius, 0.02, sin(a1) * radius)
		st.add_vertex(p0)
		st.add_vertex(p1)
		# the same circle again at standing height, so the threshold is a volume
		st.add_vertex(p0 + Vector3(0.0, top, 0.0))
		st.add_vertex(p1 + Vector3(0.0, top, 0.0))
		# four uprights, not forty-eight — a cage, not a cylinder
		if i % 12 == 0:
			st.add_vertex(p0)
			st.add_vertex(p0 + Vector3(0.0, top, 0.0))

	_ring = MeshInstance3D.new()
	_ring.name = "Ring"
	_ring.mesh = st.commit()
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = ring_color
	m.emission_enabled = true
	m.emission = ring_color
	# calibrated against ACES at tonemap_exposure 0.16, which is what both
	# vr_staging.tscn and grid.tscn use — see folding_past for the same sum
	m.emission_energy_multiplier = 5.0
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ring.material_override = m
	add_child(_ring)


func _build_area() -> void:
	_area = Area3D.new()
	_area.name = "Threshold"
	_area.collision_layer = 0
	_area.collision_mask = PLAYER_MASK | WORLD_MASK
	var col := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = radius
	cyl.height = height
	col.shape = cyl
	col.position = Vector3(0.0, height * 0.5, 0.0)
	_area.add_child(col)
	_area.body_entered.connect(_on_entered)
	_area.body_exited.connect(_on_exited)
	add_child(_area)


func _rebuild_shape() -> void:
	if not _area:
		return
	for c in _area.get_children():
		if c is CollisionShape3D:
			var sh: Shape3D = (c as CollisionShape3D).shape
			if sh is CylinderShape3D:
				(sh as CylinderShape3D).radius = radius
	if _ring:
		_ring.queue_free()
	_build_ring()


# ------------------------------------------------------------ who is standing

## A body on the world layer is usually the floor. Accept only things that move
## under their own power or say who they are.
func _is_occupant(body: Node3D) -> bool:
	for g in OCCUPANT_GROUPS:
		if body.is_in_group(g):
			return true
	return body is CharacterBody3D


func _on_entered(body: Node3D) -> void:
	if not _is_occupant(body):
		return
	_inside[body.get_instance_id()] = true
	if _inside.size() != 1:
		return                                # someone was already standing here
	_blink_left = blink_seconds
	set_process(blink_seconds > 0.0)
	_take()


func _on_exited(body: Node3D) -> void:
	var key: int = body.get_instance_id()
	if not _inside.has(key):
		return
	_inside.erase(key)
	if _inside.is_empty():
		set_process(false)
		_release()


func _process(delta: float) -> void:
	if not _holding:
		set_process(false)
		return
	_blink_left -= delta
	if _blink_left <= 0.0:
		set_process(false)
		_release()                            # dressed again, still standing in it


# ------------------------------------------------------------- the undressing

func _take() -> void:
	if _holding:
		return
	_holding = true
	if _held == 0:
		_restore_to = get_viewport().debug_draw
	_held += 1
	_apply(DRAW_MODE.get(undressing, Viewport.DEBUG_DRAW_WIREFRAME))


func _release() -> void:
	if not _holding:
		return
	_holding = false
	_held = maxi(0, _held - 1)
	if _held == 0:
		_apply(_restore_to)


func _apply(mode: int) -> void:
	var vp: Viewport = get_viewport()
	if vp:
		vp.debug_draw = mode


## A BELT, AND THE BRACES ARE ALREADY ON. The failure this guards against is the
## only unrecoverable one here: the node freed while somebody is standing in it,
## nothing left to hand the viewport back, the whole game undressed with no way
## out but a restart.
##
## It is NOT, however, what saves the free() path — measured, not assumed.
## probe_wireframe_threshold case 5 passes with this function gutted to `pass`,
## because Godot 4.6 does emit body_exited when the Area3D is freed, so
## _on_exited has already released by the time this runs. What is left for this
## to cover is the paths where that signal does not come: a subtree removed
## without being freed, or a whole tree torn down. Cheap insurance on an
## expensive failure, kept for the cases the probe cannot reach — and written
## down as insurance rather than as the guard, because a comment claiming it is
## load-bearing would stop the next person testing whether it still is.
func _exit_tree() -> void:
	_inside.clear()
	_release()
