extends RefCounted
## Raw signals; no geometry bounds or display gain in this model.
## Pink approximation: Julius O. Smith, Spectral Audio Signal Processing,
## Example: Synthesis of 1/F Noise. Uniform innovations replace Gaussian ones;
## this changes the distribution, not the linear filter transfer function.
const WARMUP := 4096
const PINK_GAIN := 11.6 # Fixed display gain; not a per-run normalization.
const STEP_GAIN := 0.10
var rng := RandomNumberGenerator.new()
var x_history := [0.0,0.0,0.0]
var y_history := [0.0,0.0,0.0]
var sum := 0.0
var count := 0
func reset(seed_value:int) -> void:
	rng.seed=seed_value;x_history=[0.0,0.0,0.0];y_history=[0.0,0.0,0.0];sum=0.0;count=0
	# Only the filter receives this preparation history. The visible walk starts at zero.
	for i in range(WARMUP): _pink(rng.randf_range(-1.0,1.0))
func _pink(x:float) -> float:
	var y:float=0.049922035*x-0.095993537*x_history[0]+0.050612699*x_history[1]-0.004408786*x_history[2]+2.494956002*y_history[0]-2.017265875*y_history[1]+0.522189400*y_history[2]
	x_history=[x,x_history[0],x_history[1]];y_history=[y,y_history[0],y_history[1]]
	return y
func next_sample() -> Array:
	var white:=rng.randf_range(-1.0,1.0)
	sum+=STEP_GAIN*white;count+=1
	return [white,sum,_pink(white)]
static func display_values(raw:Array) -> Array:
	return [raw[0],raw[1],raw[2]*PINK_GAIN]
