# cartridge_wave.gd
# A diagonal traveling wave swept across the array. Each cell's value is
# quantized from sin(2π·(x + y) / N + t), so bright and dark bands move
# uniformly across the index space. The array becomes a medium — the
# values flow, the cells stay put.
#
# Curriculum role (array_tutorial): wave is disco with continuous depth.
# Disco said "indexing makes pattern." Wave says "indexing + a phase
# offset over time makes oscillation." Prepares the leap to wavefunctions
# / oscillation later in the spine. F_order, still — every cell evolves
# by the same deterministic rule.

class_name CartridgeWave
extends Grid2DCartridge

## Quantization buckets — how many discrete brightness states.
const STATES = 8

## Spatial wavelength expressed in cells (full sine cycle every WAVELEN
## diagonal cells).
const WAVELEN = 16.0

## Saturation / value for the band palette. We use a single hue and
## sweep value — bands read as brightness, not as color cycle.
const HUE = 0.58       # cyan-ish; reads as "wave"
const SAT = 0.55
const VAL_MIN = 0.18
const VAL_MAX = 1.0

# Internal phase, advanced each step.
var _phase: float = 0.0

# How much phase advances per step. Wavelength / 8 gives one band-shift
# per step, which reads as a clean traveling wave.
const PHASE_PER_STEP = TAU / 8.0


func get_name() -> String:
	return "Wave"


func get_state_count() -> int:
	return STATES


func get_state_color(state: int) -> Color:
	# Map state 0..STATES-1 to a brightness ramp. State is the
	# quantized sine amplitude.
	var t = float(state) / float(STATES - 1)
	var v = lerp(VAL_MIN, VAL_MAX, t)
	return Color.from_hsv(HUE, SAT, v)


func get_state_emission(state: int) -> float:
	# Bright bands glow; dark bands sit. Reads as moving light.
	var t = float(state) / float(STATES - 1)
	return 0.2 + 0.7 * t


func _quantize(amp: float) -> int:
	# amp in [-1, 1] → state 0..STATES-1
	var n = (amp + 1.0) * 0.5  # → [0, 1]
	var s = int(floor(n * float(STATES)))
	return clamp(s, 0, STATES - 1)


func initialize(grid: PackedInt32Array, width: int, height: int) -> void:
	_phase = 0.0
	for y in range(height):
		for x in range(width):
			var amp = sin(TAU * float(x + y) / WAVELEN)
			grid[y * width + x] = _quantize(amp)


func step(grid: PackedInt32Array, width: int, height: int) -> PackedInt32Array:
	# Advance phase, recompute the whole field. The wave travels.
	_phase += PHASE_PER_STEP
	for y in range(height):
		for x in range(width):
			var amp = sin(TAU * float(x + y) / WAVELEN + _phase)
			grid[y * width + x] = _quantize(amp)
	return grid
