@tool
extends Node3D

# @identity
# essence: cell(t+1) = born/survive(neighbors) with four-fold symmetry enforcement
# desire: To weave itself — a living carpet whose patterns breathe and shift like textile memory
# critical_parameter: rule_border_born/survive vs rule_inner_born/survive — two rulesets create the border-interior tension
# triggers: Switching random_seed reshuffles initial conditions; changing border vs inner rules shifts the visual dialect entirely
# emerges: Intricate symmetric textile patterns from the interplay of two CA rulesets and forced mirror symmetry
# needs: VR parameter controls [missing], auto-play toggle [has via auto_step]
# relationships: Contrasts with mirrored_cellular_automata (stochastic symmetry vs deterministic). Feeds into CA_Introduction.
# truth: Symmetry imposed on local rules transforms noise into ornament — the rug designs itself.

@export_category("Rug Settings")
@export var width: int = 256
@export var height: int = 384
@export var border_size: int = 32
@export var iterations: int = 100
@export var auto_step: bool = true
@export var step_interval: float = 0.05
@export var random_seed: bool = false

@export_category("Performance")
@export var performance_mode: bool = false
@export var play_duration: float = 10.0
@export var pause_duration: float = 10.0

@export_category("Rules")
# Format: [Born_list, Survive_list, States]
@export var rule_border_born: Array[int] = [2]
@export var rule_border_survive: Array[int] = [3, 4, 5]
@export var rule_border_states: int = 4

@export var rule_inner_born: Array[int] = [3]
@export var rule_inner_survive: Array[int] = [1, 2, 3, 4, 5]
@export var rule_inner_states: int = 5

@export_category("Colors (Pink Persian)")
@export var color_background: Color = Color("5e1026")
@export var color_border_active: Color = Color("d6336c")
@export var color_inner_active: Color = Color("ffc966")
@export var color_decay: Gradient
@export var rows_per_frame: int = 40

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION (2026-08-05). Four placements. This file had a dozen
# exports already and the runner still refused it as NO TURNABLE KNOBS, correctly:
# apply_grid_config was a literal `pass`, so no map token could reach any of them,
# and every rug in the project is the same rug. The knobs existed; nothing was
# connected to them.
#
# The two things that were NOT exports are the two things the artifact argues, and
# both were welded shut as literal code:
#
#   stencil    WHAT SYMMETRY IS IMPOSED. _enforce_symmetry() hard-coded a
#              four-fold mirror — top-left quadrant written into the other three.
#              The file's own @identity says "Symmetry imposed on local rules
#              transforms noise into ornament", and that claim could not be tested
#              because the symmetry could not be removed or changed.
#   division   WHERE THE TWO DIALECTS MEET. _is_border() hard-coded a rectangular
#              frame. @identity names the two rulesets as the critical_parameter,
#              but the SHAPE of the boundary between them — the thing that makes a
#              carpet a carpet — was not a parameter at all.
#
# `stencil` is mirrored_cellular_automata's word, taken with its answers: quadrant
# and none are the same operations under the same names, and motif is the same
# idea (one small block broadcast outward). OCTANT IS REFUSED. Its eight-fold
# stencil needs the diagonal reflection grid[x][y], which requires a square grid,
# and this rug is 256x384 — a runner, footprint [3,1,4], taller than it is wide by
# design. Taking a word without its answers is the dishonest half of a shared
# vocabulary, so the fourth value is `halfturn`, which IS native to a rectangle:
# 180-degree point symmetry, the same regularity with no mirror line anywhere.
#
# `division` is this artifact's own word, because no sibling asks it. A CA that
# runs one law in a frame and another inside is arguing about ornament, not about
# automata: frame says ornament is BOUNDED, medallion says it RADIATES, bands says
# it ACCUMULATES IN COURSES, and none abolishes the inside/outside distinction to
# see whether the two-ruleset claim was load-bearing at all.
#
# DEFAULTS PRESERVE. stencil=quadrant runs the original loop and the original four
# writes, in the original order, so the RNG stream under seed(12345) is untouched
# and the rug is bit-identical. division=frame is the original boolean expression,
# reached after one integer compare.
# ─────────────────────────────────────────────────────────────────────────────

@export_category("Ornament (DNA)")
## mirrored_cellular_automata's word. `quadrant` is the shipped four-fold mirror.
@export_enum("quadrant", "motif", "halfturn", "none") var stencil: String = "quadrant"
## Where the border ruleset lives. `frame` is the shipped rectangular border.
@export_enum("frame", "bands", "medallion", "none") var division: String = "frame"
## Side of the repeating block under stencil:motif. Unused at every other value.
@export var motif_cells: int = 48

const STENCILS: PackedStringArray = ["quadrant", "motif", "halfturn", "none"]
const DIVISIONS: PackedStringArray = ["frame", "bands", "medallion", "none"]

# _is_border runs twice per cell per step — 98304 cells at 256x384 — so the string
# is resolved to an int ONCE and the hot path compares integers. The shipped
# expression stays the first branch and is reached after a single compare.
var _division_mode: int = 0   # 0 frame · 1 bands · 2 medallion · 3 none
var _built: bool = false

# Optimization: Use PackedByteArray for 1D grid and pixel buffer
var grid: PackedByteArray
var next_grid: PackedByteArray
var pixel_buffer: PackedByteArray

var texture: ImageTexture
var image: Image
var timer: float = 0.0
var current_step: int = 0
var current_row: int = 0

var cycle_timer = 0.0
var is_playing = true

@onready var mesh_instance: MeshInstance3D = $RugMesh

func _ready() -> void:
	if not color_decay:
		_setup_default_gradient()

	_initialize_grid()
	_setup_texture()
	# Initial full update
	_update_texture_slice(height)
	_built = true


## Map tokens: "persian_rug#stencil:halfturn", "persian_rug#division:medallion".
##
## The shipped body was a literal `pass`, which is why the runner saw no reachable knob.
## GUARDED the same way force_pad's was fixed: the grid is re-laid only when a value
## actually CHANGED and only after _ready has built the image and texture once, so a call
## naming nothing this rug owns costs four dictionary lookups and nothing else.
func apply_grid_config(config: Dictionary) -> void:
	var regen: bool = false
	if config.has("stencil"):
		var s: String = _pick_axis(str(config["stencil"]), STENCILS, stencil)
		if s != stencil:
			stencil = s
			regen = true
	if config.has("division"):
		var d: String = _pick_axis(str(config["division"]), DIVISIONS, division)
		if d != division:
			division = d
			regen = true
	if config.has("motif_cells"):
		var mc: int = int(config["motif_cells"])
		if mc != motif_cells:
			motif_cells = mc
			regen = true
	if config.has("border_size"):
		var bs: int = int(config["border_size"])
		if bs != border_size:
			border_size = bs
			regen = true
	# Untyped on purpose: a typed bool rejects the string "true" a fixture hands it.
	if config.has("random_seed"):
		var rs: bool = _truthy(config["random_seed"])
		if rs != random_seed:
			random_seed = rs
			regen = true
	if regen and _built:
		_initialize_grid()
		current_step = 0
		current_row = 0
		_update_texture_slice(height)


## An unreadable word keeps the current value rather than silently blanking a rug four
## rooms expect to be woven.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.strip_edges().to_lower()
	if allowed.has(v):
		return v
	if v != "":
		push_warning("persian_rug: unknown value '%s' — keeping '%s'" % [v, fallback])
	return fallback


func _truthy(v) -> bool:
	if typeof(v) == TYPE_BOOL:
		return v
	var s: String = str(v).strip_edges().to_lower()
	return s == "true" or s == "1" or s == "yes"


func _resolve_modes() -> void:
	if division == "bands":
		_division_mode = 1
	elif division == "medallion":
		_division_mode = 2
	elif division == "none":
		_division_mode = 3
	else:
		_division_mode = 0

func _process(delta: float) -> void:
	# Ensure variables are initialized for @tool hot-reloading
	if cycle_timer == null: cycle_timer = 0.0
	if is_playing == null: is_playing = true
	if rows_per_frame == null: rows_per_frame = 40
	
	# Hot-reload safety: Ensure grid is correct type
	if not grid is PackedByteArray or grid.size() != width * height:
		_initialize_grid()
		_setup_texture()
		current_row = 0

	if performance_mode:
		cycle_timer += delta
		if is_playing:
			if cycle_timer >= play_duration:
				is_playing = false
				cycle_timer = 0.0
		else:
			if cycle_timer >= pause_duration:
				is_playing = true
				cycle_timer = 0.0
				if random_seed:
					_initialize_grid() 
	
	# Update a slice of the texture every frame
	if current_row < height:
		var rows: int = 40
		if rows_per_frame != null:
			rows = int(rows_per_frame)
		if rows <= 0: rows = 40
		_update_texture_slice(rows)
	
	# Only step if we are done updating the view
	if auto_step and is_playing and current_row >= height:
		timer += delta
		if timer >= step_interval:
			timer = 0.0
			step()
			current_row = 0

func _setup_default_gradient() -> void:
	color_decay = Gradient.new()
	color_decay.remove_point(0)
	color_decay.remove_point(0)
	color_decay.add_point(0.0, Color("2a1a4a"))
	color_decay.add_point(0.5, Color("9c1c5a"))
	color_decay.add_point(1.0, Color("f8d7da"))

func _initialize_grid() -> void:
	var size = width * height
	# Force type reset in case of hot-reload artifact
	grid = PackedByteArray()
	next_grid = PackedByteArray()
	grid.resize(size)
	next_grid.resize(size)
	grid.fill(0)
	next_grid.fill(0)
	
	# Cheap, and it makes a stale mode impossible: _is_border is called from the seeding
	# loop below, which _process can reach on hot-reload without going through _ready.
	_resolve_modes()

	if random_seed:
		randomize()
	else:
		seed(12345)

	# The FUNDAMENTAL DOMAIN is whatever the stencil will broadcast from. Only the part
	# that gets copied is drawn, so each value seeds exactly the region it owns.
	match stencil:
		"motif":
			_seed_region(_motif_side(), _motif_side())
		"halfturn":
			# 180° maps a half onto a half, so the domain is the top half at FULL width.
			_seed_region(width, height / 2)
		"none":
			# mirrored_cellular_automata's precedent: with no stencil every cell is drawn
			# on its own account, at the same 0.15 the quadrant draws inside its fragment.
			_seed_region(width, height)
		_:
			# quadrant — the shipped loop, character for character, in the same x-then-y
			# order. The RNG stream under seed(12345) is therefore identical and so is
			# the rug the four placements have always shown.
			for x in range(width / 2):
				for y in range(height / 2):
					if randf() < 0.15:
						var is_border = _is_border(x, y)
						var max_state = rule_border_states if is_border else rule_inner_states
						var idx = y * width + x
						grid[idx] = max_state - 1

	_enforce_symmetry()

## The shipped seeding rule (0.15 density, state = max-1 for whichever ruleset owns the
## cell) applied to an arbitrary rectangle anchored at the top-left.
func _seed_region(region_w: int, region_h: int) -> void:
	var cw: int = clampi(region_w, 1, width)
	var ch: int = clampi(region_h, 1, height)
	for x in range(cw):
		for y in range(ch):
			if randf() < 0.15:
				var is_border: bool = _is_border(x, y)
				var max_state: int = rule_border_states if is_border else rule_inner_states
				grid[y * width + x] = max_state - 1

func _motif_side() -> int:
	return clampi(motif_cells, 2, mini(width, height))

## division — which region runs the BORDER ruleset (and so is drawn in the border colour).
## Branch 0 is the shipped expression untouched; the integer compare in front of it is the
## whole cost of the axis on the default path.
func _is_border(x, y) -> bool:
	if _division_mode == 0:
		return x < border_size or x >= width - border_size or y < border_size or y >= height - border_size
	if _division_mode == 1:
		return _in_bands(y)
	if _division_mode == 2:
		return _in_medallion(x, y)
	return false

## division:bands — the two dialects woven in courses across the cloth instead of ringed
## around it. A kilim's claim: ornament accumulates in stripes and there is no inside.
func _in_bands(y) -> bool:
	var b: int = maxi(border_size, 1)
	return (int(y) / b) % 2 == 0

## division:medallion — the border dialect pulled off the edge and into a central ellipse.
## The classic Persian centrepiece, and the exact inverse of the frame's argument: the
## frame says ornament is bounded, the medallion says it radiates from a middle.
func _in_medallion(x, y) -> bool:
	var cx: float = float(width) * 0.5
	var cy: float = float(height) * 0.5
	var dx: float = (float(x) - cx) / maxf(cx * 0.55, 1.0)
	var dy: float = (float(y) - cy) / maxf(cy * 0.55, 1.0)
	return dx * dx + dy * dy <= 1.0

## stencil — the symmetry imposed on the local rules, re-applied after every step so the
## ornament holds as the automaton evolves. Called once per step, not once per cell, so a
## string match here costs nothing measurable.
func _enforce_symmetry() -> void:
	match stencil:
		"motif":
			_tile_motif()
		"halfturn":
			_enforce_halfturn()
		"none":
			pass
		_:
			_enforce_quadrant()

## stencil:quadrant — the shipped four-fold mirror, byte for byte.
func _enforce_quadrant() -> void:
	# Mirror Top-Left to Top-Right, Bottom-Left, Bottom-Right
	for y in range(height / 2):
		var row_offset = y * width
		var mirror_row_offset = (height - 1 - y) * width

		for x in range(width / 2):
			var val = grid[row_offset + x]

			# Top-Right
			grid[row_offset + (width - 1 - x)] = val
			# Bottom-Left
			grid[mirror_row_offset + x] = val
			# Bottom-Right
			grid[mirror_row_offset + (width - 1 - x)] = val

## stencil:halfturn — 180° point symmetry. The bottom half is the top half TURNED rather
## than reflected, so the rug closes on itself with no mirror line anywhere in it. The
## same regularity as quadrant arguing the opposite thing about how ornament repeats.
func _enforce_halfturn() -> void:
	for y in range(height / 2):
		var row_offset: int = y * width
		var mirror_row_offset: int = (height - 1 - y) * width
		for x in range(width):
			grid[mirror_row_offset + (width - 1 - x)] = grid[row_offset + x]

## stencil:motif — one small block broadcast across the whole cloth, reflected at every
## repeat so neighbouring copies meet at a mirror and the seams do not show. The all-over
## repeating field of a woven rug, where quadrant gives one carpet-sized medallion.
## Reads only from the motif block itself, which this pass never writes into.
func _tile_motif() -> void:
	var m: int = _motif_side()
	var span: int = maxi(m * 2 - 2, 1)
	for y in range(height):
		var src_row: int = _fold(y, m, span) * width
		var dst_row: int = y * width
		for x in range(width):
			if y < m and x < m:
				continue
			grid[dst_row + x] = grid[src_row + _fold(x, m, span)]

## Boustrophedon index: 0..m-1 then back down again — how a weaver actually repeats a
## motif, so the repeat is a reflection rather than a visible tile edge.
func _fold(i: int, m: int, span: int) -> int:
	var k: int = i % span
	if k < m:
		return k
	return span - k

func step() -> void:
	# Pre-calculate constants to avoid lookups in loop
	var w = width
	var h = height
	
	# We can't easily optimize the border check out of the loop without splitting loops,
	# but 1D array access is fast enough.
	
	for y in range(h):
		var y_offset = y * w
		var ym1_offset = ((y - 1 + h) % h) * w
		var yp1_offset = ((y + 1) % h) * w
		
		for x in range(w):
			var idx = y_offset + x
			var is_border = _is_border(x, y)
			
			# Select rules
			var born: Array[int]
			var survive: Array[int]
			var states: int
			
			if is_border:
				born = rule_border_born
				survive = rule_border_survive
				states = rule_border_states
			else:
				born = rule_inner_born
				survive = rule_inner_survive
				states = rule_inner_states
			
			var current = grid[idx]
			
			if current == states - 1: # Active
				# Count neighbors inline
				var xm1 = (x - 1 + w) % w
				var xp1 = (x + 1) % w
				var active_state = states - 1
				var count = 0
				
				if grid[ym1_offset + xm1] == active_state: count += 1
				if grid[ym1_offset + x] == active_state: count += 1
				if grid[ym1_offset + xp1] == active_state: count += 1
				if grid[y_offset + xm1] == active_state: count += 1
				if grid[y_offset + xp1] == active_state: count += 1
				if grid[yp1_offset + xm1] == active_state: count += 1
				if grid[yp1_offset + x] == active_state: count += 1
				if grid[yp1_offset + xp1] == active_state: count += 1
				
				if count in survive:
					next_grid[idx] = active_state
				else:
					next_grid[idx] = current - 1
					
			elif current > 0: # Decaying
				next_grid[idx] = current - 1
				
			else: # Dead
				# Count neighbors inline
				var xm1 = (x - 1 + w) % w
				var xp1 = (x + 1) % w
				var active_state = states - 1
				var count = 0
				
				if grid[ym1_offset + xm1] == active_state: count += 1
				if grid[ym1_offset + x] == active_state: count += 1
				if grid[ym1_offset + xp1] == active_state: count += 1
				if grid[y_offset + xm1] == active_state: count += 1
				if grid[y_offset + xp1] == active_state: count += 1
				if grid[yp1_offset + xm1] == active_state: count += 1
				if grid[yp1_offset + x] == active_state: count += 1
				if grid[yp1_offset + xp1] == active_state: count += 1
				
				if count in born:
					next_grid[idx] = active_state
				else:
					next_grid[idx] = 0
	
	# Swap buffers
	var temp = grid
	grid = next_grid
	next_grid = temp
	
	_enforce_symmetry()
	current_step += 1

func _setup_texture() -> void:
	image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	texture = ImageTexture.create_from_image(image)
	
	# Initialize pixel buffer
	pixel_buffer = PackedByteArray()
	pixel_buffer.resize(width * height * 4)
	pixel_buffer.fill(0)
	
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = texture
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	if mesh_instance:
		mesh_instance.material_override = mat

func _update_texture_slice(rows: int) -> void:
	var end_row = min(current_row + rows, height)
	var w = width
	
	for y in range(current_row, end_row):
		var row_offset = y * w
		var pixel_idx = row_offset * 4
		
		for x in range(w):
			var state = grid[row_offset + x]
			var is_border = _is_border(x, y)
			var max_states = rule_border_states if is_border else rule_inner_states
			var col = color_background
			
			if state == max_states - 1:
				col = color_border_active if is_border else color_inner_active
			elif state > 0:
				var t = float(state) / float(max_states - 1)
				col = color_decay.sample(t)
			
			# Direct byte access is much faster than set_pixel
			pixel_buffer[pixel_idx] = int(col.r * 255)
			pixel_buffer[pixel_idx + 1] = int(col.g * 255)
			pixel_buffer[pixel_idx + 2] = int(col.b * 255)
			pixel_buffer[pixel_idx + 3] = 255
			pixel_idx += 4
	
	# Update the image from the buffer
	# We update the whole image data because set_data is fast
	image.set_data(width, height, false, Image.FORMAT_RGBA8, pixel_buffer)
	texture.update(image)
	
	current_row = end_row
