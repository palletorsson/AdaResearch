# complexity_pattern.gd
# QFEP Edge of Chaos Visualization - Emergent Complexity
# Self-organizing pattern at λ ≈ 0.4
# Where structure emerges from the dance of order and chaos

extends Node3D

class_name QFEPComplexityPattern

# @identity
# essence: Conway_GoL(B3/S23) on toroidal grid, density ~40% -> edge-of-chaos automaton
# desire: watch complexity self-organize — gliders, oscillators, structures nobody designed
# critical_parameter: initial density (~0.4) — the lambda value that places this automaton at the edge of chaos
# triggers: cells die out below threshold -> auto-reseed; each generation applies B3/S23 rules
# emerges: gliders, blinkers, and long-lived metastable structures from random initial conditions
# needs: VR speed control [missing], touch-to-toggle cells [missing], density slider [missing]
# relationships: unlocks edge_core concept; depends on cellular automata foundations; contrasts preserved_pattern (frozen) and chaos_particles (dissolved)
# truth: at the edge of chaos, simple local rules generate unbounded computational complexity

## STAGE-2 DNA PROMOTION (2026-08-03). The runner refused this token for NO
## TURNABLE KNOBS: grid_size, cell_size, update_interval and two colours are
## dimensions and decoration, and the two decisions that carry the whole
## argument were hard-coded one function down.
##
##   rule     which automaton fills the field
##            life · highlife · seeds · replicator · maze · coral
##   readout  whether a cell's state is read as elevation, as a flat
##            measurement, or as a raised bar
##            relief · plate · column
##
## rule=life, readout=relief is exactly what shipped — B3/S23 written out as
## `neighbors == 2 or neighbors == 3` on line 110, and alive cells lifted to
## scale.y 1.5 — so the existing placements are byte-identical.
##
## WHY `rule` AND NOT A PARAMETER OF THE FIELD. The shipped comment claims
## "Standard Conway rules - known to produce edge-of-chaos behavior", and the
## registry names this artifact's critical parameter as the initial density.
## Density is the wrong knob for a still and the wrong knob for the claim: under
## Life every starting density converges to the same sparse litter of still
## lifes within twenty generations, so five densities photograph as five
## indistinguishable fields — the reaction_diffusion failure exactly. The
## interesting quantity was never the soup, it was the LAW applied to it. λ is a
## property of the rule table, and this axis is the only place in the corpus
## where that is walkable: life sits at the edge, seeds sprays, replicator
## fills with periodic fractal texture, maze and coral freeze into standing
## structure. The artifact stops asserting "edge of chaos" and starts showing
## what the two sides of it look like.
##
## NOT NAMED `generator` although perlin_noise declares that word for the same
## slot (which basis fills the field). A noise generator is sampled once and
## has no history; these are transition rules whose whole content is what they
## do to their own output over time. Different question, different word.
##
## `readout` IS taken character for character from perlin_noise, noisetorus and
## mandelbrot_set — relief · plate · column, same three words, same meaning,
## same default sense (the shipped code lifts its sample), so this artifact can
## be compared with those three and not merely contrasted.
##
## pattern_seed and warmup are NOT axes. They are fixture knobs, both defaulting
## to the shipped behaviour (unseeded soup, no pre-run), and they exist because
## this field is generative: without a seed five variants are five different
## soups and the sweep would measure the RNG, and without a warmup the capture
## photographs the soup before any rule has had time to speak.
##
## Usage in map_data.json:
##   "complexity_pattern#rule:maze"
##   "complexity_pattern#readout:column"

## Grid size
@export var grid_size: int = 16

## Cell size
@export var cell_size: float = 0.04

## Update speed
@export var update_interval: float = 0.2

## Edge color
@export var alive_color: Color = Color(0.2, 0.9, 0.4, 1.0)
@export var dead_color: Color = Color(0.1, 0.15, 0.1, 0.5)

## DNA axis: which automaton fills the field. "life" is B3/S23, the rule the
## shipped code wrote out by hand.
@export_enum("life", "highlife", "seeds", "replicator", "maze", "coral") var rule: String = "life"

## DNA axis: whether a cell's state is read as elevation, as a flat measurement,
## or as a raised bar. "relief" is the shipped lift of 1.5.
@export_enum("relief", "plate", "column") var readout: String = "relief"

## Fixture knob, not an axis. 0 = the shipped unseeded soup, so every existing
## placement keeps its own fresh randomness. Any other value pins the field.
@export var pattern_seed: int = 0

## Fixture knob, not an axis. Generations run at build time before the first
## frame. 0 = shipped (the player meets the soup and watches it organise).
@export var warmup: int = 0

## birth neighbour counts, survival neighbour counts.
const RULES = {
	"life": [[3], [2, 3]],
	"highlife": [[3, 6], [2, 3]],
	"seeds": [[2], []],
	"replicator": [[1, 3, 5, 7], [1, 3, 5, 7]],
	"maze": [[3], [1, 2, 3, 4, 5]],
	"coral": [[3], [4, 5, 6, 7, 8]],
}

const READOUTS = ["relief", "plate", "column"]

# Internal
var _cells: Array[Array] = []
var _meshes: Array[Array] = []
var _materials: Array[Array] = []
var _timer: float = 0.0
var _generation: int = 0
## Null unless pattern_seed is set, in which case every draw comes from it.
## Null is the shipped path: the global randf(), exactly as before.
var _rng: RandomNumberGenerator = null
## True once _ready has built the grid. Guards the config hook from rebuilding
## a body that does not exist yet.
var _built: bool = false

func _ready() -> void:
	_seed_rng()
	_init_grid()
	_build_visuals()
	_randomize_cells()
	for _i in range(maxi(warmup, 0)):
		_step_simulation()
	_built = true

func _seed_rng() -> void:
	if pattern_seed == 0:
		_rng = null
		return
	_rng = RandomNumberGenerator.new()
	_rng.seed = pattern_seed

## The shipped call when unseeded, so nothing about the default path changes.
func _roll() -> float:
	if _rng != null:
		return _rng.randf()
	return randf()

## Box height for the current readout. relief and column keep the shipped
## 0.5 x cell_size body; plate flattens it into a tile so the grid reads as a
## measured surface rather than a field of blocks.
func _body_height() -> float:
	if readout == "plate":
		return cell_size * 0.12
	return cell_size * 0.5

## How far a living cell is lifted. 1.5 is the shipped relief.
func _alive_lift() -> float:
	if readout == "column":
		return 8.0
	if readout == "plate":
		return 1.0
	return 1.5

func _init_grid() -> void:
	for x in range(grid_size):
		var row: Array[bool] = []
		for z in range(grid_size):
			row.append(false)
		_cells.append(row)

func _build_visuals() -> void:
	var offset = -grid_size * cell_size / 2.0
	
	for x in range(grid_size):
		var mesh_row: Array[MeshInstance3D] = []
		var mat_row: Array[StandardMaterial3D] = []
		
		for z in range(grid_size):
			var mesh = MeshInstance3D.new()
			var box = BoxMesh.new()
			box.size = Vector3(cell_size * 0.9, _body_height(), cell_size * 0.9)
			mesh.mesh = box
			
			mesh.position = Vector3(
				x * cell_size + offset,
				0,
				z * cell_size + offset
			)
			
			var mat = StandardMaterial3D.new()
			mat.albedo_color = dead_color
			mat.emission_enabled = true
			mat.emission = dead_color
			mat.emission_energy_multiplier = 0.2
			mesh.material_override = mat
			
			add_child(mesh)
			mesh_row.append(mesh)
			mat_row.append(mat)
		
		_meshes.append(mesh_row)
		_materials.append(mat_row)

func _randomize_cells() -> void:
	# Initialize with ~40% alive - edge of chaos density
	for x in range(grid_size):
		for z in range(grid_size):
			_cells[x][z] = _roll() < 0.4
	_update_visuals()

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= update_interval:
		_timer = 0.0
		_step_simulation()

func _step_simulation() -> void:
	# The transition rule. "life" is [[3], [2, 3]] — B3/S23, which is the
	# `neighbors == 2 or neighbors == 3` this function used to write out by hand,
	# so the default path is the shipped one exactly.
	var law: Array = RULES.get(rule, RULES["life"])
	var birth: Array = law[0]
	var survive: Array = law[1]
	var new_cells: Array[Array] = []

	for x in range(grid_size):
		var row: Array[bool] = []
		for z in range(grid_size):
			var neighbors = _count_neighbors(x, z)
			var alive = _cells[x][z]

			if alive:
				row.append(survive.has(neighbors))
			else:
				row.append(birth.has(neighbors))
		new_cells.append(row)
	
	_cells = new_cells
	_generation += 1
	_update_visuals()
	
	# Re-seed if pattern dies out
	var alive_count = 0
	for x in range(grid_size):
		for z in range(grid_size):
			if _cells[x][z]:
				alive_count += 1
	
	if alive_count < grid_size:
		_randomize_cells()

func _count_neighbors(x: int, z: int) -> int:
	var count = 0
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			if dx == 0 and dz == 0:
				continue
			var nx = (x + dx + grid_size) % grid_size
			var nz = (z + dz + grid_size) % grid_size
			if _cells[nx][nz]:
				count += 1
	return count

func _update_visuals() -> void:
	for x in range(grid_size):
		for z in range(grid_size):
			var alive = _cells[x][z]
			var mat = _materials[x][z]
			var mesh = _meshes[x][z]
			
			var lift: float = 1.0
			if alive:
				mat.albedo_color = alive_color
				mat.emission = alive_color
				mat.emission_energy_multiplier = 1.0
				lift = _alive_lift()
			else:
				mat.albedo_color = dead_color
				mat.emission = dead_color
				mat.emission_energy_multiplier = 0.2
			mesh.scale.y = lift
			# A column stands ON the grid instead of growing through it. Only the
			# column readout touches position, so relief and plate keep the
			# shipped transform untouched.
			if readout == "column":
				mesh.position.y = _body_height() * (lift - 1.0) * 0.5

## Reset pattern
func reset() -> void:
	_generation = 0
	_randomize_cells()

## Get current generation
func get_generation() -> int:
	return _generation

## Tear the field down and grow it again under the current axis values. Only
## called from apply_grid_config, and only when a value actually changed.
func _rebuild() -> void:
	for row in _meshes:
		for m in row:
			if is_instance_valid(m):
				m.queue_free()
	_meshes.clear()
	_materials.clear()
	_cells.clear()
	_generation = 0
	_timer = 0.0
	_seed_rng()
	_init_grid()
	_build_visuals()
	_randomize_cells()
	for _i in range(maxi(warmup, 0)):
		_step_simulation()

## Guarded on both counts: the field is rebuilt only when a key's value actually
## CHANGED, and only after _ready has grown it once. A placement that passes
## none of these keys — which today is every placement — gets exactly the
## behaviour it had before the axes existed. Values arrive as strings from a map
## token, so each is parsed and validated before it is allowed through.
func apply_grid_config(config_data: Dictionary) -> void:
	var re_grow: bool = false
	for key in config_data:
		var k: String = str(key)
		if k == "rule":
			var r: String = str(config_data[key]).to_lower()
			if RULES.has(r) and r != rule:
				rule = r
				re_grow = true
			continue
		if k == "readout":
			var d: String = str(config_data[key]).to_lower()
			if READOUTS.has(d) and d != readout:
				readout = d
				re_grow = true
			continue
		if k == "pattern_seed":
			var s: int = int(config_data[key])
			if s != pattern_seed:
				pattern_seed = s
				re_grow = true
			continue
		if k == "warmup":
			var w: int = maxi(int(config_data[key]), 0)
			if w != warmup:
				warmup = w
				re_grow = true
			continue
		if k in self:
			set(k, config_data[key])
	if re_grow and _built:
		_rebuild()
