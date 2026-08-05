extends MeshInstance3D

@export var texture_size: Vector2i = Vector2i(1440, 1000)  # Resolution of the drawing texture
@export var default_brush_size: int = 12  # Default size of the brush stroke
@export var default_brush_color: Color = Color(0, 0, 0, 1)  # Default brush color
@export var default_snap_grid_size: int = 8  # Default snap grid size
@export var random_dot_colors: Array = [Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW]  # Colors for the random dots

## STAGE-2 DNA — AXIS: WHAT COLOUR "NOTHING" IS.
##
## This script owns the entire visible body of two artifacts. `ball_painting_demo` is a
## 4 x 2.5 m canvas in a dark frame with thirty grabbable pigment balls on a shelf, and
## `drawing_paper` is the same surface as a sheet with a pen. In a STILL both are almost
## entirely one thing: the blank surface. The balls are 3-9 cm across and cover under a
## tenth of one percent of a fitted frame, so an axis on THEM would be measured through
## a keyhole; the surface is about 7-8% of frame and is the only place here where a
## still can carry an argument at all.
##
## And the surface is not neutral. `reset_canvas()` splats Color(1,1,1,1) — a white
## ground — which every drawing app hands you as though white were the absence of a
## decision. It is a decision, and a recent one. The axis is the four historical answers
## to what a painter puts down before the first mark:
##
##   white       gesso. Chalk and glue. The picture begins from nothing and the ground
##               is not a colour — the modern default, the blank slate, the white cube.
##               THE SHIPPED VALUE, Color(1,1,1,1), the exact literal that was here.
##   ochre       imprimatura, the warm mid-tone wash. White is a LIGHT you have to earn:
##               every mark is up or down from a middle, and the highlight is paint.
##   bole        the red-brown clay ground of the Baroque. The picture is pulled out of
##               a warm dark, and the ground stays visible in every shadow it left.
##   verdaccio   the cool green underpainting of tempera flesh. The ground is a
##               CORRECTION — laid in order to be cancelled by what goes over it.
##
## Not a lightness ladder: neutral light, warm mid, warm dark, cool mid. Every pair
## differs in hue as well as value, and each value covers the whole surface.
##
## REACHED WITHOUT A ROOT SCRIPT. Both scenes have a scriptless root, so a map token's
## `apply_grid_config` has nowhere to land — but GridInteractablesComponent stamps
## `config_<key>` metadata on the root BEFORE add_child (line 1195 vs 1220), which is
## before any _ready in the subtree. Walking up for it here reads the token one call
## earlier than apply_grid_config could, so the ground is laid once and never relaid.
@export_enum("white", "ochre", "bole", "verdaccio") var priming: String = "white"

## Allow-list. An unknown word in a map token keeps the shipped white.
const PRIMINGS: PackedStringArray = ["white", "ochre", "bole", "verdaccio"]

## `white` is the literal that was hard-coded in reset_canvas(), unchanged.
const PRIMING_COLOR: Dictionary = {
	"white": Color(1, 1, 1, 1),
	"ochre": Color(0.78, 0.60, 0.33, 1),
	"bole": Color(0.42, 0.20, 0.16, 1),
	"verdaccio": Color(0.45, 0.50, 0.36, 1),
}

# --- WET PAINT EFFECT (GPU) ---
@export var wet_paint: bool = false:
	set(value):
		wet_paint = value
		_update_paint_params()
		
@export var flow_speed: float = 0.0005:
	set(value):
		flow_speed = value
		_update_paint_params()

const WET_PAINT_SCENE = preload("res://commons/context/drawingboard/wet_paint_canvas.tscn")
var viewport: SubViewport
var brush_layer: Node2D
var simulation_rect: ColorRect

# Active pen settings
var active_pen_properties = {
	"brush_size": 10,
	"brush_color": Color(0, 0, 0, 1),
	"snap_size": 8,
	"random_dots_active": false
}

@onready var debug_label: Label3D = $"../Label3D"

func _ready():
	# BEFORE _setup_gpu_painting(), because that ends by calling reset_canvas() and the
	# ground has to be settled by then. Both existing scenes carry no config metadata at
	# all, so this leaves `priming` at "white" and reset_canvas() splats the same white it
	# always did.
	_settle_priming()
	_setup_gpu_painting()

	# Initialize active properties from exports
	active_pen_properties["brush_size"] = default_brush_size
	active_pen_properties["brush_color"] = default_brush_color
	active_pen_properties["snap_size"] = default_snap_grid_size
	
	if debug_label:
		debug_label.text = "GPU Drawing initialized."

func _setup_gpu_painting():
	# Instance the viewport scene
	var canvas = WET_PAINT_SCENE.instantiate()
	canvas.name = "WetPaintCanvas"
	add_child(canvas)
	
	viewport = canvas
	brush_layer = canvas.get_node("BrushLayer")
	var sim_pass = canvas.get_node("SimulationPass")
	simulation_rect = sim_pass.get_node("SimulationRect")
	
	# Resize viewport to match texture size
	viewport.size = texture_size
	
	# Explicitly resize the ColorRect because it's inside a Node2D (BackBufferCopy)
	# and anchors won't work automatically to fill the Viewport
	simulation_rect.size = Vector2(texture_size)
	
	# Get the viewport texture
	var vp_tex = viewport.get_texture()
	
	# Assign to material
	var material = StandardMaterial3D.new()
	material.albedo_texture = vp_tex
	# Ensure material is local and unique
	self.material_override = material
	
	_update_paint_params()
	
	# Initial clear to white
	reset_canvas()

func _update_paint_params():
	if simulation_rect and simulation_rect.material:
		# If wet paint is off, set flow to 0
		var speed = flow_speed if wet_paint else 0.0
		simulation_rect.material.set_shader_parameter("flow_speed", speed)

# Draw random dots around the pen tip
func draw_random_dots(uv_position: Vector2):
	for i in range(4):  # Draw four random dots
		# Generate random offset
		var random_offset = Vector2(randf_range(-0.02, 0.02), randf_range(-0.02, 0.02))
		var dot_position = uv_position + random_offset

		# Pick a random color
		var random_color = random_dot_colors[randi() % random_dot_colors.size()]

		# Draw the dot
		draw_point(dot_position, random_color)

# Function to reset the canvas
func reset_canvas():
	# To reset a feedback loop viewport, we need to clear it.
	# The easiest way for a "Fade/Clear" is to draw a giant rect on the BrushLayer
	#
	# THE GROUND IS LAID HERE, and only here — one splat, the same call, the same
	# geometry. At priming = "white" the colour looked up is Color(1, 1, 1, 1), the
	# literal that used to be written on this line, so the shipped path is unchanged
	# down to the argument. A reset by the player relays the ground rather than
	# whitewashing it, which is what a reset to a primed canvas means.
	if brush_layer:
		brush_layer.add_splat(Vector2(texture_size.x/2, texture_size.y/2), max(texture_size.x, texture_size.y), _priming_color())

	if debug_label:
		debug_label.text = "Drawing reset."

# Snap a UV position to the nearest grid point
func snap_to_grid(uv_position: Vector2, snap_size: int = -1) -> Vector2:
	var s_size = snap_size if snap_size > 0 else active_pen_properties["snap_size"]
	
	var grid_size = Vector2(1.0 / s_size, 1.0 / s_size)
	var snapped_x = round(uv_position.x / grid_size.x) * grid_size.x
	var snapped_y = round(uv_position.y / grid_size.y) * grid_size.y
	return Vector2(snapped_x, snapped_y)

# Draw a single point
# Draw a single point
func draw_point(uv_position: Vector2, color: Color, size: int = -1, snap_size: int = -1):
	var b_size = size if size > 0 else active_pen_properties["brush_size"]
	
	# Snap the UV position to the grid
	uv_position = snap_to_grid(uv_position, snap_size)
	
	# Convert UV to pixel coordinates
	var x = uv_position.x * texture_size.x
	var y = uv_position.y * texture_size.y
	
	# Delegate to BrushLayer
	if brush_layer:
		brush_layer.add_splat(Vector2(x, y), b_size, color)


# Function to draw while tracking the pen tip position
func draw_with_pen(uv_position: Vector2):
	# Draw the main pen stroke
	draw_point(uv_position, active_pen_properties["brush_color"])
	# Draw random dots around the pen tip
	draw_random_dots(uv_position)


# Update the pen properties dynamically
func update_pen(brush_size: int, brush_color: Color, snap_size: int, random_dots_active: bool):
	active_pen_properties["brush_size"] = brush_size
	active_pen_properties["brush_color"] = brush_color
	active_pen_properties["snap_size"] = snap_size
	active_pen_properties["random_dots_active"] = random_dots_active



func draw_line(from_uv: Vector2, to_uv: Vector2, color: Color, size: int = -1, snap_size: int = -1):
	var b_size = size if size > 0 else active_pen_properties["brush_size"]

	# Snap the UV positions to the grid
	from_uv = snap_to_grid(from_uv, snap_size)
	to_uv = snap_to_grid(to_uv, snap_size)

	if from_uv == Vector2(-1, -1):  # No previous point to connect from
		draw_point(to_uv, color, size, snap_size)
		return

	# Interpolate between the points and draw along the line
	var from_pos = from_uv * Vector2(texture_size)
	var to_pos = to_uv * Vector2(texture_size)
	
	var steps = int(from_pos.distance_to(to_pos) / (b_size * 0.5))
	steps = max(1, steps)
	
	for i in range(steps + 1):
		var t = float(i) / float(steps)
		var p = from_pos.lerp(to_pos, t)
		if brush_layer:
			brush_layer.add_splat(p, b_size, color)


func _on_scribel_pen_pen_grabbed(pickable: Variant, by: Variant) -> void:

	var pentip_ray_cast = pickable.get_node("Pen/PentipRayCast")  # Adjust the path as needed
	if pentip_ray_cast:
		# Get the current snap_grid_size
		active_pen_properties["snap_size"] = pentip_ray_cast.snap_grid_size
		if debug_label:
			debug_label.text = "Current Resolution: " + str(active_pen_properties["snap_size"])
	else:
		if debug_label:
			debug_label.text = "PentipRayCast node not found!"

# Debug: set to true to see coordinate transformation values
var _debug_uv_transform: bool = false

# Helper to convert world position to UV
func get_uv_from_world_pos(world_pos: Vector3) -> Vector2:
	# Explicitly get the current global transform (forces update)
	var gt = get_global_transform()

	# Transform world position to local space
	var local_pos = gt.affine_inverse() * world_pos

	# Get mesh size (default PlaneMesh is 2x2 in local XZ plane)
	var mesh_size = Vector2(2.0, 2.0)
	if mesh and mesh is PlaneMesh:
		mesh_size = (mesh as PlaneMesh).size

	var half_size = mesh_size / 2.0

	# PlaneMesh lies in local XZ plane with Y as normal
	# Local X ranges from -half_size.x to +half_size.x
	# Local Z ranges from -half_size.y to +half_size.y
	var uv_x = (local_pos.x + half_size.x) / mesh_size.x
	# The canvas rotation causes local.z to be negated relative to world Y
	# Correct for this by using -local_pos.z, then apply UV inversion
	var uv_y = 1.0 - (-local_pos.z + half_size.y) / mesh_size.y

	if _debug_uv_transform:
		var parent_name = get_parent().get_parent().get_parent().name if get_parent() and get_parent().get_parent() and get_parent().get_parent().get_parent() else "unknown"
		print("Canvas [%s]: world=%s, gt.origin=%s, local=%s, uv=(%0.2f, %0.2f)" % [
			parent_name, world_pos, gt.origin, local_pos, uv_x, uv_y
		])

	return Vector2(uv_x, uv_y)

# Draw at a specific world position
func draw_at_world_position(world_pos: Vector3, color: Color = Color.BLACK):
	var uv = get_uv_from_world_pos(world_pos)
	if uv.x >= 0.0 and uv.x <= 1.0 and uv.y >= 0.0 and uv.y <= 1.0:
		draw_point(uv, color)

func _process(_delta):
	# GPU simulation runs automatically in the shader/viewport
	pass


# ── PRIMING ──────────────────────────────────────────────────────────────────────────
# Appended LAST. Nothing here touches the brush, the pen, the wet-paint shader, the
# snapping, the UV transform or the viewport. Only what is on the surface before anyone
# has drawn on it.

## The ground colour for the settled value, and the shipped white for anything unknown.
func _priming_color() -> Color:
	var c: Color = PRIMING_COLOR.get(priming, Color(1, 1, 1, 1))
	return c


## Config from map_data.json tokens:  ball_painting_demo#priming:bole
##
## NOT apply_grid_config, deliberately. Both scenes that run this script have a scriptless
## ROOT — GridInteractablesComponent calls apply_grid_config on the root and would never
## reach a MeshInstance3D three levels down — but it stamps `config_<key>` metadata on that
## same root BEFORE add_child, so the value is already sitting on an ancestor when this
## subtree's _ready runs. Reading it here needs no new script on either .tscn and no
## rebuild: the ground is laid once, correctly, on the first pass.
##
## NEAREST ANCESTOR WINS and the walk stops there, so a token on this artifact is never
## overridden by a stray `config_priming` further up the map's tree. Both existing scenes
## and all placements of both tokens carry no such metadata anywhere, so the loop runs to
## the top, finds nothing, and leaves "white".
func _settle_priming() -> void:
	var node: Node = self
	while node != null:
		if node.has_meta("config_priming"):
			var m: String = str(node.get_meta("config_priming")).strip_edges().to_lower()
			if PRIMINGS.has(m):
				priming = m
			break
		node = node.get_parent()
	var v: String = String(priming).strip_edges().to_lower()
	priming = v if PRIMINGS.has(v) else "white"
