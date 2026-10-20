extends RefCounted
## A bounded, colour-blind random walk, in the original jar's coordinates.
## Symmetric proposals outside the cylinder are rejected, not clamped to its wall.
## No common destination, sorting operation or target entropy is imposed.
const STEP_SECONDS:=0.48
const STEP_METRES:=0.11
var initial: Array=[]
var previous: Array=[]
var following: Array=[]
var current: Array=[]
var radius:=0.0
var half_height:=0.0
var step_scale:=Vector3.ZERO
var stream_seed:=435
var tick:=0
var remainder:=0.0
var rng:=RandomNumberGenerator.new()

func configure(points: Array,usable_radius: float,usable_half_height: float,scale_to_record: Vector3,stream: int) -> void:
	initial=points.duplicate();radius=usable_radius;half_height=usable_half_height
	step_scale=scale_to_record*STEP_METRES
	# All four paths derive from the hall's baseline seed, with distinct streams.
	stream_seed=435+104729*stream
	reset()

func reset() -> void:
	rng.seed=stream_seed;tick=0;remainder=0.0
	previous=initial.duplicate();current=initial.duplicate();propose()

func propose() -> void:
	following.clear()
	for p: Vector3 in previous:
		var q:=p+Vector3(rng.randf_range(-1,1),rng.randf_range(-1,1),rng.randf_range(-1,1))*step_scale
		following.append(q if absf(q.y)<=half_height and Vector2(q.x,q.z).length()<=radius else p)

func advance(seconds: float) -> void:
	if not is_finite(seconds) or seconds<=0:return
	remainder+=seconds
	while remainder+0.000000001>=STEP_SECONDS:
		remainder=maxf(0,remainder-STEP_SECONDS);tick+=1
		previous=following.duplicate();propose()
	current.clear()
	for i in previous.size():current.append(previous[i].lerp(following[i],remainder/STEP_SECONDS))
