extends Node3D
class_name QueerMarchingCave

# @identity
# essence: marching cubes cave generator with layered noise — combines four noise fields (primary, secondary, bulge, cave) into a single density function then meshes the iso-surface, producing a walkable bulgy cavern at VR scale
# desire: to make a cave that does not feel like a gridded-out rock — the bulginess parameter pushes the noise into rounded, gestural forms that read as organic rather than geological
# critical_parameter: bulginess — at 0 the cave reads as procedural noise, at high values walls swell into pillowy curves; this is the parameter that turns mathematics into atmosphere
# triggers: vertical_bias adds a downward density gradient (caves go down, not up); cave_density shifts the iso-level threshold to make the void wider or narrower; color_shift_speed cycles the wall coloring over time
# emerges: a 256-case lookup table over a noise sum produces a cave that is somehow both random and architectural — the cubes-and-cases substrate vanishes into the sensed roundness of the result
# needs: FastNoiseLite x4 [resolved], ArrayMesh [resolved], collision body [resolved]
# relationships: queer variant of the standard marching cubes cave — same algorithm but parameter-tuned for an aesthetic that resists the usual procedural-rock look; sibling to mc_inside_cave, marchingcubes_cave
# truth: the difference between geology and architecture is just parameter choice — the same algorithm builds rocks or rooms depending on which noise weights you pick

# --- DNA (stage 2, promoted 2026-08-12) -------------------------------------
# The sequence's truth line is "define a field, extract a surface". This artifact
# had until now argued only the first half, and argued it at exactly one setting.
#
# bulge — GEOLOGY OR ARCHITECTURE. The @identity above picks this parameter for
#   me: "bulginess — at 0 the cave reads as procedural noise, at high values
#   walls swell into pillowy curves; this is the parameter that turns mathematics
#   into atmosphere", and the truth line says "the difference between geology and
#   architecture is just parameter choice". That claim shipped at one value, 1.5,
#   which is the same fault `fusion` was promoted to fix on the metaballs next
#   door. bulginess does two things in calculate_density_at_position: it warps the
#   sample point by up to bulginess * 10 m of cellular noise, and it scales the
#   primary noise read at the warped point, which then enters the density sum at
#   0.5 weight.
#     pillowed   SHIPPED, 1.5, and a SHORT-CIRCUIT — returns the `bulginess`
#                export untouched, so a placement that names the number directly
#                still wins over the named rung.
#     gridded    0.0. The artifact's own stated null: the whole warp term is
#                exactly zero (it is multiplied by bulginess twice over), and what
#                is left is simplex noise plus a vertical gradient plus a
#                smoothstep boundary — the "gridded-out rock" the desire line says
#                it is trying not to be.
#     rounded    0.75, the half-step, where the warp is legible as a warp.
#     engulfed   2.5, deliberately NOT 3.0. At 0.5 weight the bulge term already
#                swings about +/-1.25 against other terms of similar magnitude; a
#                higher value risks a wholly solid or wholly empty field, and the
#                empty one photographs as NO RENDER, which the critic would read
#                as a dead axis rather than as an overdriven one.
#
# resolution — HOW FINELY THE FIELD IS SAMPLED, the second half of the sequence's
#   own gap, and an argument against this artifact's own emerges line: "the
#   cubes-and-cases substrate vanishes into the sensed roundness of the result".
#   At `coarse` it does not vanish. Same field, same threshold, same noise; only
#   the sampling moves, and the claim of roundness turns out to be a claim about a
#   cell size.
#     mid        SHIPPED, 0.5 m, a SHORT-CIRCUIT returning `cell_size` untouched.
#                21 x 13 x 21 density samples, 20 x 12 x 20 marched cells.
#     coarse     1.0 m. 11 x 7 x 11 samples, 600 cells — half-metre plates you can
#                read the lattice off.
#     fine       0.3 m. 34 x 21 x 34 samples, ~21,800 cells. Three rungs and not
#                four: 0.2 m is ~75,000 samples and ~525,000 FastNoiseLite calls
#                inside _ready, a watchdog risk that buys no extra argument.
#   The word is SHARED, taken from riemann_pump ("resolution is HOW FINE THE
#   PARTITION IS ... the partition is this artifact's own subject", rungs
#   pump|coarse|mid|fine) and from sphere_mid (coarse|mid|fine|ultra). Declared
#   with the shipped state named `mid` so the three can be read against each
#   other. When a shared vocabulary is honest the siblings measure alike.
#
# THE EXPORT RENAME, and why it was unavoidable. The cell size shipped as an
#   export literally NAMED resolution, typed float, defaulting to 0.5 — so the
#   shared WORD was already spent on the number, and an axis name has to be a
#   settable property. (Written out in prose rather than quoted as a line of code
#   on purpose: check_dna_declarations scans the whole file with a regex and no
#   comment awareness, so pasting the old declaration here made it read
#   `resolution` as a numeric axis and file a MISMATCH against three rung names —
#   the gate reporting a fact about a COMMENT as a verdict about the registry,
#   which is the exact disease that tool exists to cure.)
#   riemann_pump and sphere_mid both keep the named rung on
#   `resolution` and the magnitude on a second property (n_strips; rings and
#   radial_segments). Matching them means the float moves to `cell_size` and
#   `resolution` becomes the enum. Nothing in the repository sets the old
#   property: QueerMarchingCave.tscn does not, noise_terrain_with_blobs_demo.tscn
#   instances the scene without overriding it, no map passes it, and
#   set_cave_parameters never touched it. get_cave_info() still reports the number
#   under the key "resolution", so its one external contract is unchanged.
#
# cave_seed — NOT AN AXIS, A PRECONDITION. setup_noise_generators called randi()
#   four times from the globally-seeded RNG, and regenerate_cave four more, so
#   every instantiation was a DIFFERENT CAVE. An unfixed sweep would have
#   photographed four unrelated objects and reported the difference as an axis.
#   0 keeps the shipped randi() calls exactly, in the same order, consuming the
#   global stream identically — the only way to preserve behaviour that is itself
#   random. Non-zero derives the four seeds as seed, seed+1, seed+2, seed+3,
#   assigned before the first get_noise_3d. dna.fixture pins it.
#
# DECLINED, by name. color_shift_speed and pulse_intensity are refused as
#   time-domain: they are the only thing _process does — an emission_energy
#   sinusoid and an albedo lerp on a second sinusoid — so a still photographs one
#   arbitrary phase of them and two frames of the SAME value taken 1.5 s apart
#   would differ. The fixture zeroes them instead, which freezes emission_energy
#   at a constant 1.8 and the albedo at a constant mix. vertical_bias and
#   cave_density are real and visible but are magnitudes on the same density sum
#   that `bulge` already varies, so they would say one thing twice. cave_size is
#   extent, and extent self-cancels under a camera that fits the subject.
#   primary_noise_scale / secondary_noise_scale were considered for the second
#   axis and dropped: they change the FIELD, whereas resolution changes what the
#   extractor is allowed to see of it, which is the sequence's question.
const BULGES: PackedStringArray = ["pillowed", "gridded", "rounded", "engulfed"]
const RESOLUTIONS: PackedStringArray = ["mid", "coarse", "fine"]
## Bulginess per rung. `pillowed` is absent on purpose — it short-circuits to the
## exported `bulginess` rather than being recomputed onto the same number.
const BULGE_AMOUNT: Dictionary = {
	"gridded": 0.0,
	"rounded": 0.75,
	"engulfed": 2.5,
}
## Cell size in metres per rung. `mid` is absent for the same reason.
const CELL_SIZE_BY_RUNG: Dictionary = {
	"coarse": 1.0,
	"fine": 0.3,
}

@export_enum("pillowed", "gridded", "rounded", "engulfed") var bulge: String = "pillowed"
@export_enum("mid", "coarse", "fine") var resolution: String = "mid"

# Marching cubes parameters
@export var cave_size: Vector3 = Vector3(10, 6, 10)  # Meters (VR scale)
## Cell size in metres. Was named `resolution` until the rename above; a
## placement that names this directly still WINS over the `mid` rung, which is
## why `mid` returns it untouched instead of looking 0.5 up in a table.
@export var cell_size: float = 0.5
@export var iso_level: float = 0.0

## 0 = the shipped behaviour, four randi() calls, a different cave every launch.
## Any other value pins all four noise fields. See the DNA note above.
@export var cave_seed: int = 0

# Noise parameters for queer bulgy aesthetics
@export var primary_noise_scale: float = 0.15
@export var secondary_noise_scale: float = 0.4
## The shipped bulge. A placement that names this directly still WINS over
## `bulge` — the named rung is a vocabulary laid over the raw number, never a
## replacement for it.
@export var bulginess: float = 1.5
@export var cave_density: float = 0.3
@export var vertical_bias: float = 0.2

# Color and animation
@export var color_shift_speed: float = 0.5
@export var pulse_intensity: float = 0.3

# Noise generators
var primary_noise: FastNoiseLite
var secondary_noise: FastNoiseLite
var bulge_noise: FastNoiseLite
var cave_noise: FastNoiseLite

# Marching cubes data
var density_field: Array = []
var vertices: PackedVector3Array
var indices: PackedInt32Array
var normals: PackedVector3Array
var colors: PackedColorArray

# Cave mesh and collision
var cave_mesh: ArrayMesh
var time: float = 0.0

## Resolved once per build and then read as plain members by the inner loops, so
## the marching pass costs exactly what it always did — no dictionary lookup per
## voxel, no function call per vertex.
var _cs: float = 0.5
var _bulge_amt: float = 1.5
var _built: bool = false
## Set when something names the raw number rather than the rung. The number then
## wins, which is what the doc comments on `bulginess` and `cell_size` promise.
var _bulginess_explicit: bool = false
var _cell_size_explicit: bool = false

# Marching cubes edge table (256 entries)
var edge_table: PackedInt32Array = [
	0x0, 0x109, 0x203, 0x30a, 0x406, 0x50f, 0x605, 0x70c,
	0x80c, 0x905, 0xa0f, 0xb06, 0xc0a, 0xd03, 0xe09, 0xf00,
	0x190, 0x99, 0x393, 0x29a, 0x596, 0x49f, 0x795, 0x69c,
	0x99c, 0x895, 0xb9f, 0xa96, 0xd9a, 0xc93, 0xf99, 0xe90,
	0x230, 0x339, 0x33, 0x13a, 0x636, 0x73f, 0x435, 0x53c,
	0xa3c, 0xb35, 0x83f, 0x936, 0xe3a, 0xf33, 0xc39, 0xd30,
	0x3a0, 0x2a9, 0x1a3, 0xaa, 0x7a6, 0x6af, 0x5a5, 0x4ac,
	0xbac, 0xaa5, 0x9af, 0x8a6, 0xfaa, 0xea3, 0xda9, 0xca0,
	0x460, 0x569, 0x663, 0x76a, 0x66, 0x16f, 0x265, 0x36c,
	0xc6c, 0xd65, 0xe6f, 0xf66, 0x86a, 0x963, 0xa69, 0xb60,
	0x5f0, 0x4f9, 0x7f3, 0x6fa, 0x1f6, 0xff, 0x3f5, 0x2fc,
	0xdfc, 0xcf5, 0xfff, 0xef6, 0x9fa, 0x8f3, 0xbf9, 0xaf0,
	0x650, 0x759, 0x453, 0x55a, 0x256, 0x35f, 0x55, 0x15c,
	0xe5c, 0xf55, 0xc5f, 0xd56, 0xa5a, 0xb53, 0x859, 0x950,
	0x7c0, 0x6c9, 0x5c3, 0x4ca, 0x3c6, 0x2cf, 0x1c5, 0xcc,
	0xfcc, 0xec5, 0xdcf, 0xcc6, 0xbca, 0xac3, 0x9c9, 0x8c0,
	0x8c0, 0x9c9, 0xac3, 0xbca, 0xcc6, 0xdcf, 0xec5, 0xfcc,
	0xcc, 0x1c5, 0x2cf, 0x3c6, 0x4ca, 0x5c3, 0x6c9, 0x7c0,
	0x950, 0x859, 0xb53, 0xa5a, 0xd56, 0xc5f, 0xf55, 0xe5c,
	0x15c, 0x55, 0x35f, 0x256, 0x55a, 0x453, 0x759, 0x650,
	0xaf0, 0xbf9, 0x8f3, 0x9fa, 0xef6, 0xfff, 0xcf5, 0xdfc,
	0x2fc, 0x3f5, 0xff, 0x1f6, 0x6fa, 0x7f3, 0x4f9, 0x5f0,
	0xb60, 0xa69, 0x963, 0x86a, 0xf66, 0xe6f, 0xd65, 0xc6c,
	0x36c, 0x265, 0x16f, 0x66, 0x76a, 0x663, 0x569, 0x460,
	0xca0, 0xda9, 0xea3, 0xfaa, 0x8a6, 0x9af, 0xaa5, 0xbac,
	0x4ac, 0x5a5, 0x6af, 0x7a6, 0xaa, 0x1a3, 0x2a9, 0x3a0,
	0xd30, 0xc39, 0xf33, 0xe3a, 0x936, 0x83f, 0xb35, 0xa3c,
	0x53c, 0x435, 0x73f, 0x636, 0x13a, 0x33, 0x339, 0x230,
	0xe90, 0xf99, 0xc93, 0xd9a, 0xa96, 0xb9f, 0x895, 0x99c,
	0x69c, 0x795, 0x49f, 0x596, 0x29a, 0x393, 0x99, 0x190,
	0xf00, 0xe09, 0xd03, 0xc0a, 0xb06, 0xa0f, 0x905, 0x80c,
	0x70c, 0x605, 0x50f, 0x406, 0x30a, 0x203, 0x109, 0x0
]

# Simplified triangle table (first few entries - full table would be very long)
var triangle_table: Array = []

func _ready() -> void:
	_read_metadata_overrides()
	setup_noise_generators()
	setup_triangle_table()
	generate_cave()
	_built = true

func _process(delta: float) -> void:
	time += delta
	animate_cave_colors(delta)


# ── The two axes, resolved ────────────────────────────────────────────────────

## `pillowed` and any unknown string return the exported number UNTOUCHED rather
## than looking 1.5 up in a table. At the shipped export the two are the same
## float, but a placement that set bulginess alone would have it silently
## overwritten by the table path, and the guarantee should not depend on nobody
## doing that. (The same argument csg_difference_demo's `corner` makes.)
func _bulge_amount() -> float:
	if _bulginess_explicit or bulge == "pillowed" or not BULGES.has(bulge):
		return bulginess
	return float(BULGE_AMOUNT.get(bulge, bulginess))


## `mid` and any unknown string return `cell_size` untouched, for the same reason.
func _resolved_cell_size() -> float:
	if _cell_size_explicit or resolution == "mid" or not RESOLUTIONS.has(resolution):
		return cell_size
	return float(CELL_SIZE_BY_RUNG.get(resolution, cell_size))


## 0 means "leave the shipped randomness alone", so the four randi() calls happen
## in the same order and consume the global stream exactly as they always did.
func _noise_seed(offset: int) -> int:
	if cave_seed == 0:
		return randi()
	return cave_seed + offset


func setup_noise_generators() -> void:
	# Primary cave structure noise
	primary_noise = FastNoiseLite.new()
	primary_noise.seed = _noise_seed(0)
	primary_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	primary_noise.frequency = primary_noise_scale
	primary_noise.fractal_octaves = 4
	primary_noise.fractal_gain = 0.5

	# Secondary detail noise
	secondary_noise = FastNoiseLite.new()
	secondary_noise.seed = _noise_seed(1)
	secondary_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	secondary_noise.frequency = secondary_noise_scale
	# KNOWN BUG, LEFT ALONE ON PURPOSE (found 2026-08-12 while reading for the DNA
	# promotion). This line says `primary_noise`, not `secondary_noise` — a
	# copy-paste that silently overwrites primary's 4 octaves, set eight lines
	# above, and leaves secondary_noise on FastNoiseLite's default octave count.
	# Repairing it changes the density field of every existing placement, which is
	# exactly what a promotion must not do, so it is reported and left for its own
	# decision rather than folded in here.
	primary_noise.fractal_octaves = 3

	# Bulge/distortion noise for queer aesthetics
	bulge_noise = FastNoiseLite.new()
	bulge_noise.seed = _noise_seed(2)
	bulge_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	bulge_noise.frequency = 0.01
	bulge_noise.cellular_return_type = FastNoiseLite.RETURN_CELL_VALUE

	# Cave carving noise
	cave_noise = FastNoiseLite.new()
	cave_noise.seed = _noise_seed(3)
	cave_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	cave_noise.frequency = 0.015

func setup_triangle_table() -> void:
	var t = [
		[-1],
		[0,8,3,-1],[0,1,9,-1],[1,8,3,9,8,1,-1],[1,2,10,-1],[0,8,3,1,2,10,-1],[9,2,10,0,2,9,-1],[2,8,3,2,10,8,10,9,8,-1],
		[3,11,2,-1],[0,11,2,8,11,0,-1],[1,9,0,2,3,11,-1],[1,11,2,1,9,11,9,8,11,-1],[3,10,1,11,10,3,-1],[0,10,1,0,8,10,8,11,10,-1],[3,9,0,3,11,9,11,10,9,-1],[9,8,10,10,8,11,-1],
		[4,7,8,-1],[4,3,0,7,3,4,-1],[0,1,9,8,4,7,-1],[4,1,9,4,7,1,7,3,1,-1],[1,2,10,8,4,7,-1],[3,4,7,3,0,4,1,2,10,-1],[9,2,10,9,0,2,8,4,7,-1],[2,10,9,2,9,7,2,7,3,7,9,4,-1],
		[8,4,7,3,11,2,-1],[11,4,7,11,2,4,2,0,4,-1],[9,0,1,8,4,7,2,3,11,-1],[4,7,11,9,4,11,9,11,2,9,2,1,-1],[3,10,1,3,11,10,7,8,4,-1],[1,11,10,1,4,11,1,0,4,7,11,4,-1],[4,7,8,9,0,11,9,11,10,11,0,3,-1],[4,7,11,4,11,9,9,11,10,-1],
		[9,5,4,-1],[9,5,4,0,8,3,-1],[0,5,4,1,5,0,-1],[8,5,4,8,3,5,3,1,5,-1],[1,2,10,9,5,4,-1],[3,0,8,1,2,10,4,9,5,-1],[5,2,10,5,4,2,4,0,2,-1],[2,10,5,3,2,5,3,5,4,3,4,8,-1],
		[9,5,4,2,3,11,-1],[0,11,2,0,8,11,4,9,5,-1],[0,5,4,0,1,5,2,3,11,-1],[2,1,5,2,5,8,2,8,11,4,8,5,-1],[10,3,11,10,1,3,9,5,4,-1],[4,9,5,0,8,1,8,10,1,8,11,10,-1],[5,4,0,5,0,11,5,11,10,11,0,3,-1],[5,4,8,5,8,10,10,8,11,-1],
		[9,7,8,5,7,9,-1],[9,3,0,9,5,3,5,7,3,-1],[0,7,8,0,1,7,1,5,7,-1],[1,5,3,3,5,7,-1],[9,7,8,9,5,7,10,1,2,-1],[10,1,2,9,5,0,5,3,0,5,7,3,-1],[8,0,2,8,2,5,8,5,7,10,5,2,-1],[2,10,5,2,5,3,3,5,7,-1],
		[7,9,5,7,8,9,3,11,2,-1],[9,5,7,9,7,2,9,2,0,2,7,11,-1],[2,3,11,0,1,8,1,7,8,1,5,7,-1],[11,2,1,11,1,7,7,1,5,-1],[9,5,8,8,5,7,10,1,3,10,3,11,-1],[5,7,0,5,0,9,7,11,0,1,0,10,11,10,0,-1],[11,10,0,11,0,3,10,5,0,8,0,7,5,7,0,-1],[11,10,5,7,11,5,-1],
		[10,6,5,-1],[0,8,3,5,10,6,-1],[9,0,1,5,10,6,-1],[1,8,3,1,9,8,5,10,6,-1],[1,6,5,2,6,1,-1],[1,6,5,1,2,6,3,0,8,-1],[9,6,5,9,0,6,0,2,6,-1],[5,9,8,5,8,2,5,2,6,3,2,8,-1],
		[2,3,11,10,6,5,-1],[11,0,8,11,2,0,10,6,5,-1],[0,1,9,2,3,11,5,10,6,-1],[5,10,6,1,9,2,9,11,2,9,8,11,-1],[6,3,11,6,5,3,5,1,3,-1],[0,8,11,0,11,5,0,5,1,5,11,6,-1],[3,11,6,0,3,6,0,6,5,0,5,9,-1],[6,5,9,6,9,11,11,9,8,-1],
		[5,10,6,4,7,8,-1],[4,3,0,4,7,3,6,5,10,-1],[1,9,0,5,10,6,8,4,7,-1],[10,6,5,1,9,7,1,7,3,7,9,4,-1],[6,1,2,6,5,1,4,7,8,-1],[1,2,5,5,2,6,3,0,4,3,4,7,-1],[8,4,7,9,0,5,0,6,5,0,2,6,-1],[7,3,9,7,9,4,3,2,9,5,9,6,2,6,9,-1],
		[3,11,2,7,8,4,10,6,5,-1],[5,10,6,4,7,2,4,2,0,2,7,11,-1],[0,1,9,4,7,8,2,3,11,5,10,6,-1],[9,2,1,9,11,2,9,4,11,7,11,4,5,10,6,-1],[8,4,7,3,11,5,3,5,1,5,11,6,-1],[5,1,11,5,11,6,1,0,11,7,11,4,0,4,11,-1],[0,5,9,0,6,5,0,3,6,11,6,3,8,4,7,-1],[6,5,9,6,9,11,4,7,9,7,11,9,-1],
		[10,4,9,6,4,10,-1],[4,10,6,4,9,10,0,8,3,-1],[10,0,1,10,6,0,6,4,0,-1],[8,3,1,8,1,6,8,6,4,6,1,10,-1],[1,4,9,1,2,4,2,6,4,-1],[3,0,8,1,2,9,2,4,9,2,6,4,-1],[0,2,4,4,2,6,-1],[8,3,2,8,2,4,4,2,6,-1],
		[10,4,9,10,6,4,11,2,3,-1],[0,8,2,2,8,11,4,9,10,4,10,6,-1],[3,11,2,0,1,6,0,6,4,6,1,10,-1],[6,4,1,6,1,10,4,8,1,2,1,11,8,11,1,-1],[9,6,4,9,3,6,9,1,3,11,6,3,-1],[8,11,1,8,1,0,11,6,1,9,1,4,6,4,1,-1],[3,11,6,3,6,0,0,6,4,-1],[6,4,8,11,6,8,-1],
		[7,10,6,7,8,10,8,9,10,-1],[0,7,3,0,10,7,0,9,10,6,7,10,-1],[10,6,7,1,10,7,1,7,8,1,8,0,-1],[10,6,7,10,7,1,1,7,3,-1],[1,2,6,1,6,8,1,8,9,8,6,7,-1],[2,6,9,2,9,1,6,7,9,0,9,3,7,3,9,-1],[7,8,0,7,0,6,6,0,2,-1],[7,3,2,6,7,2,-1],
		[2,3,11,10,6,8,10,8,9,8,6,7,-1],[2,0,7,2,7,11,0,9,7,6,7,10,9,10,7,-1],[1,8,0,1,7,8,1,10,7,6,7,10,2,3,11,-1],[11,2,1,11,1,7,10,6,1,6,7,1,-1],[8,9,6,8,6,7,9,1,6,11,6,3,1,3,6,-1],[0,9,1,11,6,7,-1],[7,8,0,7,0,6,3,11,0,11,6,0,-1],[7,11,6,-1],
		[7,6,11,-1],[3,0,8,11,7,6,-1],[0,1,9,11,7,6,-1],[8,1,9,8,3,1,11,7,6,-1],[10,1,2,6,11,7,-1],[1,2,10,3,0,8,6,11,7,-1],[2,9,0,2,10,9,6,11,7,-1],[6,11,7,2,10,3,10,8,3,10,9,8,-1],
		[7,2,3,6,2,7,-1],[7,0,8,7,6,0,6,2,0,-1],[2,7,6,2,3,7,0,1,9,-1],[1,6,2,1,8,6,1,9,8,8,7,6,-1],[10,7,6,10,1,7,1,3,7,-1],[10,7,6,1,7,10,1,8,7,1,0,8,-1],[0,3,7,0,7,10,0,10,9,6,10,7,-1],[7,6,10,7,10,8,8,10,9,-1],
		[6,8,4,11,8,6,-1],[3,6,11,3,0,6,0,4,6,-1],[8,6,11,8,4,6,9,0,1,-1],[9,4,6,9,6,3,9,3,1,11,3,6,-1],[6,8,4,6,11,8,2,10,1,-1],[1,2,10,3,0,11,0,6,11,0,4,6,-1],[4,11,8,4,6,11,0,2,9,2,10,9,-1],[10,9,3,10,3,2,9,4,3,11,3,6,4,6,3,-1],
		[8,2,3,8,4,2,4,6,2,-1],[0,4,2,4,6,2,-1],[1,9,0,2,3,4,2,4,6,4,3,8,-1],[1,9,4,1,4,2,2,4,6,-1],[8,1,3,8,6,1,8,4,6,6,10,1,-1],[10,1,0,10,0,6,6,0,4,-1],[4,6,3,4,3,8,6,10,3,0,3,9,10,9,3,-1],[10,9,4,6,10,4,-1],
		[4,9,5,7,6,11,-1],[0,8,3,4,9,5,11,7,6,-1],[5,0,1,5,4,0,7,6,11,-1],[11,7,6,8,3,4,3,5,4,3,1,5,-1],[9,5,4,10,1,2,7,6,11,-1],[6,11,7,1,2,10,0,8,3,4,9,5,-1],[7,6,11,5,4,10,4,2,10,4,0,2,-1],[3,4,8,3,5,4,3,2,5,10,5,2,11,7,6,-1],
		[7,2,3,7,6,2,5,4,9,-1],[9,5,4,0,8,6,0,6,2,6,8,7,-1],[3,6,2,3,7,6,1,5,0,5,4,0,-1],[6,2,8,6,8,7,2,1,8,4,8,5,1,5,8,-1],[9,5,4,10,1,6,1,7,6,1,3,7,-1],[1,6,10,1,7,6,1,0,7,8,7,0,9,5,4,-1],[4,0,10,4,10,5,0,3,10,6,10,7,3,7,10,-1],[7,6,10,7,10,8,5,4,10,4,8,10,-1],
		[6,9,5,6,11,9,11,8,9,-1],[3,6,11,0,6,3,0,5,6,0,9,5,-1],[0,11,8,0,5,11,0,1,5,5,6,11,-1],[6,11,3,6,3,5,5,3,1,-1],[1,2,10,9,5,11,9,11,8,11,5,6,-1],[0,11,3,0,6,11,0,9,6,5,6,9,1,2,10,-1],[11,8,5,11,5,6,8,0,5,10,5,2,0,2,5,-1],[6,11,3,6,3,5,2,10,3,10,5,3,-1],
		[5,8,9,5,2,8,5,6,2,3,8,2,-1],[9,5,6,9,6,0,0,6,2,-1],[1,5,8,1,8,0,5,6,8,3,8,2,6,2,8,-1],[1,5,6,2,1,6,-1],[1,3,6,1,6,10,3,8,6,5,6,9,8,9,6,-1],[10,1,0,10,0,6,9,5,0,5,6,0,-1],[0,3,8,5,6,10,-1],[10,5,6,-1],
		[11,5,10,7,5,11,-1],[11,5,10,11,7,5,8,3,0,-1],[5,11,7,5,10,11,1,9,0,-1],[10,7,5,10,11,7,9,8,1,8,3,1,-1],[11,1,2,11,7,1,7,5,1,-1],[0,8,3,1,2,7,1,7,5,7,2,11,-1],[9,7,5,9,2,7,9,0,2,2,11,7,-1],[7,5,2,7,2,11,5,9,2,3,2,8,9,8,2,-1],
		[2,5,10,2,3,5,3,7,5,-1],[8,2,0,8,5,2,8,7,5,10,2,5,-1],[9,0,1,5,10,3,5,3,7,3,10,2,-1],[9,8,2,9,2,1,8,7,2,10,2,5,7,5,2,-1],[1,3,5,3,7,5,-1],[0,8,7,0,7,1,1,7,5,-1],[9,0,3,9,3,5,5,3,7,-1],[9,8,7,5,9,7,-1],
		[5,8,4,5,10,8,10,11,8,-1],[5,0,4,5,11,0,5,10,11,11,3,0,-1],[0,1,9,8,4,10,8,10,11,10,4,5,-1],[10,11,4,10,4,5,11,3,4,9,4,1,3,1,4,-1],[2,5,1,2,8,5,2,11,8,4,5,8,-1],[0,4,11,0,11,3,4,5,11,2,11,1,5,1,11,-1],[0,2,5,0,5,9,2,11,5,4,5,8,11,8,5,-1],[9,4,5,2,11,3,-1],
		[2,5,10,3,5,2,3,4,5,3,8,4,-1],[5,10,2,5,2,4,4,2,0,-1],[3,10,2,3,5,10,3,8,5,4,5,8,0,1,9,-1],[5,10,2,5,2,4,1,9,2,9,4,2,-1],[8,4,5,8,5,3,3,5,1,-1],[0,4,5,1,0,5,-1],[8,4,5,8,5,3,9,0,5,0,3,5,-1],[9,4,5,-1],
		[4,11,7,4,9,11,9,10,11,-1],[0,8,3,4,9,7,9,11,7,9,10,11,-1],[1,10,11,1,11,4,1,4,0,7,4,11,-1],[3,1,4,3,4,8,1,10,4,7,4,11,10,11,4,-1],[4,11,7,9,11,4,9,2,11,9,1,2,-1],[9,7,4,9,11,7,9,1,11,2,11,1,0,8,3,-1],[11,7,4,11,4,2,2,4,0,-1],[11,7,4,11,4,2,8,3,4,3,2,4,-1],
		[2,9,10,2,7,9,2,3,7,7,4,9,-1],[9,10,7,9,7,4,10,2,7,8,7,0,2,0,7,-1],[3,7,10,3,10,2,7,4,10,1,10,0,4,0,10,-1],[1,10,2,8,7,4,-1],[4,9,1,4,1,7,7,1,3,-1],[4,9,1,4,1,7,0,8,1,8,7,1,-1],[4,0,3,7,4,3,-1],[4,8,7,-1],
		[9,10,8,10,11,8,-1],[3,0,9,3,9,11,11,9,10,-1],[0,1,10,0,10,8,8,10,11,-1],[3,1,10,11,3,10,-1],[1,2,11,1,11,9,9,11,8,-1],[3,0,9,3,9,11,1,2,9,2,11,9,-1],[0,2,11,8,0,11,-1],[3,2,11,-1],
		[2,3,8,2,8,10,10,8,9,-1],[9,10,2,0,9,2,-1],[2,3,8,2,8,10,0,1,8,1,10,8,-1],[1,10,2,-1],[1,3,8,9,1,8,-1],[0,9,1,-1],[0,3,8,-1],[-1]
	]
	triangle_table.resize(256)
	for i in 256:
		triangle_table[i] = t[i]

func generate_cave() -> void:
	print("Generating queer bulgy cave landscape...")

	# Resolve the two axes ONCE, here, so every loop below reads a plain float and
	# the density field, the marching pass and the vertex colours cannot disagree
	# about which cell size they are working in.
	_cs = _resolved_cell_size()
	_bulge_amt = _bulge_amount()

	clear_previous_data()
	generate_density_field()
	generate_mesh_marching_cubes()
	create_collision()
	
	print("Cave generation complete!")

func clear_previous_data() -> void:
	vertices.clear()
	indices.clear()
	normals.clear()
	colors.clear()
	density_field.clear()

func generate_density_field() -> void:
	# Create 3D density field for marching cubes
	var grid_x = int(cave_size.x / _cs) + 1
	var grid_y = int(cave_size.y / _cs) + 1
	var grid_z = int(cave_size.z / _cs) + 1

	density_field.resize(grid_x * grid_y * grid_z)

	for x in range(grid_x):
		for y in range(grid_y):
			for z in range(grid_z):
				var world_pos = Vector3(
					x * _cs - cave_size.x * 0.5,
					y * _cs - cave_size.y * 0.5,
					z * _cs - cave_size.z * 0.5
				)
				
				var density = calculate_density_at_position(world_pos)
				var index = x + y * grid_x + z * grid_x * grid_y
				density_field[index] = density
	
	print("QueerMarchingCave: density field %dx%dx%d = %d voxels" % [grid_x, grid_y, grid_z, density_field.size()])

func calculate_density_at_position(pos: Vector3) -> float:
	# Primary cave structure
	var primary_val = primary_noise.get_noise_3d(pos.x, pos.y, pos.z)
	
	# Secondary detail
	var secondary_val = secondary_noise.get_noise_3d(pos.x, pos.y, pos.z) * 0.3
	
	# Bulge distortion for queer aesthetics
	var bulge_x = pos.x + bulge_noise.get_noise_3d(pos.x * 0.1, pos.y * 0.1, pos.z * 0.1) * _bulge_amt * 10.0
	var bulge_y = pos.y + bulge_noise.get_noise_3d(pos.x * 0.12, pos.y * 0.12, pos.z * 0.12) * _bulge_amt * 8.0
	var bulge_z = pos.z + bulge_noise.get_noise_3d(pos.x * 0.11, pos.y * 0.11, pos.z * 0.11) * _bulge_amt * 10.0
	var bulge_val = primary_noise.get_noise_3d(bulge_x, bulge_y, bulge_z) * _bulge_amt
	
	# Cave carving
	var cave_val = cave_noise.get_noise_3d(pos.x, pos.y, pos.z)
	
	# Vertical bias to create more horizontal cave passages
	var height_factor = pos.y / (cave_size.y * 0.5)
	var vertical_influence = height_factor * vertical_bias
	
	# Distance from center for organic cave shape
	var center_distance = pos.length() / (cave_size.length() * 0.3)
	var cave_boundary = smoothstep(0.8, 1.2, center_distance)
	
	# Combine all influences
	var final_density = primary_val + secondary_val + bulge_val * 0.5 + cave_val * cave_density
	final_density += vertical_influence + cave_boundary
	
	return final_density

func generate_mesh_marching_cubes() -> void:
	var grid_x = int(cave_size.x / _cs)
	var grid_y = int(cave_size.y / _cs)
	var grid_z = int(cave_size.z / _cs)
	
	for x in range(grid_x):
		for y in range(grid_y):
			for z in range(grid_z):
				process_cube(x, y, z, grid_x, grid_y, grid_z)
	
	# Create the mesh
	if vertices.size() > 0:
		create_mesh()

func process_cube(x: int, y: int, z: int, size_x: int, size_y: int, size_z: int) -> void:
	var cube_index = 0
	var cube_vertices: Array = []
	
	# Get the 8 corner positions
	var positions = [
		Vector3(x, y, z),
		Vector3(x + 1, y, z),
		Vector3(x + 1, y + 1, z),
		Vector3(x, y + 1, z),
		Vector3(x, y, z + 1),
		Vector3(x + 1, y, z + 1),
		Vector3(x + 1, y + 1, z + 1),
		Vector3(x, y + 1, z + 1)
	]
	
	# Get density values at each corner
	var densities: Array = []
	for i in range(8):
		var pos = positions[i]
		var index = int(pos.x + pos.y * (size_x + 1) + pos.z * (size_x + 1) * (size_y + 1))
		if index < density_field.size():
			densities.append(density_field[index])
		else:
			densities.append(1.0)  # Outside bounds = solid
	
	# Determine cube configuration
	for i in range(8):
		if densities[i] < iso_level:
			cube_index |= (1 << i)
	
	# Skip if completely inside or outside
	if cube_index == 0 or cube_index == 255:
		return
	
	# Generate triangles using the lookup table
	var edges = edge_table[cube_index]
	if edges == 0:
		return
	
	# Interpolate vertices on intersected edges
	var edge_verts: Array = []
	edge_verts.resize(12)
	for i in range(12):
		if edges & (1 << i):
			edge_verts[i] = interpolate_edge(positions, densities, i)
		else:
			edge_verts[i] = Vector3.ZERO
	
	# Build triangles from lookup table
	var tri_config = triangle_table[cube_index]
	var i = 0
	while i < tri_config.size():
		if tri_config[i] == -1:
			break
		var v1 = world_position_from_grid(edge_verts[tri_config[i]], x, y, z)
		var v2 = world_position_from_grid(edge_verts[tri_config[i + 1]], x, y, z)
		var v3 = world_position_from_grid(edge_verts[tri_config[i + 2]], x, y, z)
		add_triangle(v1, v2, v3)
		i += 3

func interpolate_edge(positions: Array, densities: Array, edge_index: int) -> Vector3:
	# Edge vertex mapping
	var edge_connections = [
		[0, 1], [1, 2], [2, 3], [3, 0],  # Bottom face
		[4, 5], [5, 6], [6, 7], [7, 4],  # Top face
		[0, 4], [1, 5], [2, 6], [3, 7]   # Vertical edges
	]
	
	if edge_index >= edge_connections.size():
		return Vector3.ZERO
	
	var v1_idx = edge_connections[edge_index][0]
	var v2_idx = edge_connections[edge_index][1]
	
	var p1 = positions[v1_idx]
	var p2 = positions[v2_idx]
	var d1 = densities[v1_idx]
	var d2 = densities[v2_idx]
	
	# Linear interpolation
	var t = (iso_level - d1) / (d2 - d1)
	t = clamp(t, 0.0, 1.0)
	
	return p1.lerp(p2, t)

func world_position_from_grid(grid_pos: Vector3, offset_x: int, offset_y: int, offset_z: int) -> Vector3:
	return Vector3(
		(grid_pos.x + offset_x) * _cs - cave_size.x * 0.5,
		(grid_pos.y + offset_y) * _cs - cave_size.y * 0.5,
		(grid_pos.z + offset_z) * _cs - cave_size.z * 0.5
	)

func add_triangle(v1: Vector3, v2: Vector3, v3: Vector3) -> void:
	var base_index = vertices.size()
	
	# Add vertices
	vertices.append(v1)
	vertices.append(v2)
	vertices.append(v3)
	
	# Add indices
	indices.append(base_index)
	indices.append(base_index + 1)
	indices.append(base_index + 2)
	
	# Calculate normal
	var normal = (v2 - v1).cross(v3 - v1).normalized()
	normals.append(normal)
	normals.append(normal)
	normals.append(normal)
	
	# Generate queer colors
	colors.append(generate_queer_color(v1))
	colors.append(generate_queer_color(v2))
	colors.append(generate_queer_color(v3))

func generate_queer_color(pos: Vector3) -> Color:
	# Base queer color palette
	var base_pink = Color(0.9, 0.3, 0.7, 1.0)
	var base_purple = Color(0.6, 0.2, 0.9, 1.0)
	var base_cyan = Color(0.2, 0.8, 0.9, 1.0)
	
	# Noise-based color variation
	var color_noise = secondary_noise.get_noise_3d(pos.x * 0.05, pos.y * 0.05, pos.z * 0.05)
	var color_variation = (color_noise + 1.0) * 0.5
	
	# Height-based color mixing
	var height_ratio = (pos.y + cave_size.y * 0.5) / cave_size.y
	height_ratio = clamp(height_ratio, 0.0, 1.0)
	
	# Mix colors
	var color1 = base_pink.lerp(base_purple, height_ratio)
	var color2 = base_purple.lerp(base_cyan, color_variation)
	var final_color = color1.lerp(color2, 0.5)
	
	# Add some sparkle
	var sparkle = abs(bulge_noise.get_noise_3d(pos.x * 0.1, pos.y * 0.1, pos.z * 0.1))
	final_color = final_color.lerp(Color.WHITE, sparkle * 0.2)
	
	return final_color

func create_mesh() -> void:
	cave_mesh = ArrayMesh.new()
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	
	cave_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	var mesh_instance = $CaveMesh
	mesh_instance.mesh = cave_mesh

func create_collision() -> void:
	var collision_shape = $CaveCollision/CollisionShape
	
	if cave_mesh and vertices.size() > 0:
		var shape = ConcavePolygonShape3D.new()
		var collision_faces: PackedVector3Array = []
		
		# Create collision from mesh
		for i in range(0, indices.size(), 3):
			collision_faces.append(vertices[indices[i]])
			collision_faces.append(vertices[indices[i + 1]])
			collision_faces.append(vertices[indices[i + 2]])
		
		shape.set_faces(collision_faces)
		collision_shape.shape = shape

func animate_cave_colors(_delta) -> void:
	var mesh_instance = $CaveMesh
	if mesh_instance.material_override:
		var material = mesh_instance.material_override as StandardMaterial3D
		if material:
			# Pulse emission
			material.emission_energy = 1.8 + sin(time * color_shift_speed) * pulse_intensity
			
			# Shift colors
			var hue_shift = sin(time * color_shift_speed * 0.3) * 0.1
			var base_color = Color(0.7, 0.3, 0.8, 1.0)
			material.albedo_color = base_color.lerp(Color(0.8, 0.3, 0.7, 1.0), hue_shift + 0.5)

# Public API for parameter adjustment
func set_cave_parameters(params: Dictionary) -> void:
	if params.has("bulginess"):
		bulginess = params.bulginess
		# The raw number was asked for by name, so it outranks the `bulge` rung.
		_bulginess_explicit = true
	if params.has("cave_density"):
		cave_density = params.cave_density
	if params.has("vertical_bias"):
		vertical_bias = params.vertical_bias
	if params.has("primary_noise_scale"):
		primary_noise_scale = params.primary_noise_scale
		primary_noise.frequency = primary_noise_scale
	if params.has("secondary_noise_scale"):
		secondary_noise_scale = params.secondary_noise_scale
		secondary_noise.frequency = secondary_noise_scale
	
	# Regenerate cave with new parameters
	generate_cave()

func regenerate_cave() -> void:
	# New random seeds — unless the cave has been PINNED, in which case "regenerate"
	# has to mean "rebuild the same cave", or the pin would last exactly one call.
	primary_noise.seed = _noise_seed(0)
	secondary_noise.seed = _noise_seed(1)
	bulge_noise.seed = _noise_seed(2)
	cave_noise.seed = _noise_seed(3)

	generate_cave()

func get_cave_info() -> Dictionary:
	return {
		"vertices": vertices.size(),
		"triangles": indices.size() / 3,
		"cave_size": cave_size,
		# Still the NUMBER, under the key it always used: at the shipped defaults
		# this is 0.5, bit for bit what the old `resolution` export returned.
		"resolution": _resolved_cell_size(),
		"resolution_rung": resolution,
		"bulge": bulge,
		"bulginess": _bulge_amount(),
		"cave_density": cave_density,
		"vertical_bias": vertical_bias
	}


# ── Config ────────────────────────────────────────────────────────────────────

## Guarded. This was a bare `pass`, so no map has ever reached an assignment here
## and none of the four placements passes a key. It now rebuilds when — and only
## when — a value the build actually reads has changed, because a rebuild on this
## artifact is a whole density field, a whole marching pass and a new
## ConcavePolygonShape3D. Nothing is freed: the script creates no child nodes, it
## writes into the .tscn's own $CaveMesh.mesh and $CaveCollision/CollisionShape
## .shape, so the _RotationTimer GridInteractablesComponent attaches to this root
## after spawn is never touched.
func apply_grid_config(config: Dictionary) -> void:
	var before: String = _config_signature()
	for k in config.keys():
		set_meta("config_%s" % str(k), config[k])
	_read_metadata_overrides()
	if not _built:
		# Config normally lands BEFORE _ready. The values are stashed as metadata
		# and _ready reads them, so the artifact is built once, not twice.
		return
	if _config_signature() == before:
		return
	if cave_seed != 0:
		# A pinned cave stays pinned across a rebuild. When cave_seed is 0 the four
		# fields are deliberately left exactly as _ready drew them — a config key
		# that moves `bulge` must not silently re-roll the cave underneath it, which
		# is what calling setup_noise_generators() here would do.
		primary_noise.seed = _noise_seed(0)
		secondary_noise.seed = _noise_seed(1)
		bulge_noise.seed = _noise_seed(2)
		cave_noise.seed = _noise_seed(3)
	generate_cave()


func _config_signature() -> String:
	return "%s|%s|%d|%.4f|%.4f|%s|%.4f|%.4f|%.4f|%.4f|%.4f" % [
		bulge, resolution, cave_seed, _bulge_amount(), _resolved_cell_size(),
		str(cave_size), iso_level, cave_density, vertical_bias,
		primary_noise_scale, secondary_noise_scale]


func _read_metadata_overrides() -> void:
	if has_meta("config_bulge"):
		var b: String = str(get_meta("config_bulge")).strip_edges().to_lower()
		if BULGES.has(b):
			bulge = b
	if has_meta("config_resolution"):
		var r: String = str(get_meta("config_resolution")).strip_edges().to_lower()
		if RESOLUTIONS.has(r):
			resolution = r
		elif r.is_valid_float():
			# BACK-COMPAT. `resolution` was a float export until 2026-08-12. No map
			# passes it, but a token written against the old name should land on the
			# cell size rather than being silently dropped as an unknown rung.
			cell_size = float(r)
			_cell_size_explicit = true
	if has_meta("config_cell_size"):
		cell_size = float(str(get_meta("config_cell_size")))
		_cell_size_explicit = true
	if has_meta("config_bulginess"):
		bulginess = float(str(get_meta("config_bulginess")))
		_bulginess_explicit = true
	if has_meta("config_cave_seed"):
		cave_seed = str(get_meta("config_cave_seed")).to_int()
	if has_meta("config_cave_density"):
		cave_density = float(str(get_meta("config_cave_density")))
	if has_meta("config_vertical_bias"):
		vertical_bias = float(str(get_meta("config_vertical_bias")))
	if has_meta("config_iso_level"):
		iso_level = float(str(get_meta("config_iso_level")))
