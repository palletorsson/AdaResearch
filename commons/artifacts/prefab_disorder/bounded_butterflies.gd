extends Node3D
## A local flock belonging to the prefab tables, never to the room-wide axiom.
const Butterfly = preload("res://algorithms/randomness/proceduralrandomness/movementbased/scenes/randombutterflies/butterfly.tscn")
const HABITAT := AABB(Vector3(-2.2,1.35,-0.70),Vector3(4.4,1.45,1.4))
const MARGIN := 0.19 # Includes wings at every beat and turn, not just the body.
const FLIGHT_SCALE := 0.20
var count := 16
var birds: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
var elapsed := 0.0

func _ready() -> void:
	rng.seed=435 # A separate stream: never consumes the hybrid experiment's draws.
	for i in count:
		var source: Node3D=Butterfly.instantiate()
		var body: Node3D=source.get_node("butterfly")
		source.remove_child(body)
		body.set_script(null) # Keep the artwork, replace the room-wide wandering.
		source.free() # Discard the source camera and fly-center helper.
		body.name="Butterfly%02d" % (i+1)
		body.scale=Vector3.ONE*FLIGHT_SCALE
		body.position=random_point()
		body.get_node("AnimationPlayer").stop()
		add_child(body)
		body.add_to_group("prefab_butterfly")
		var target:=random_point()
		var direction:=safe_direction(target-body.position)
		body.rotation=Vector3(asin(direction.y),atan2(-direction.x,-direction.z),0)
		birds.append({"node":body,"target":target,"velocity":direction*0.35,
			"speed":rng.randf_range(0.28,0.46),"phase":rng.randf_range(0,TAU),
			"flap_hz":rng.randf_range(4.0,5.5),"turn_in":rng.randf_range(2.0,4.0),
			"left":body.get_node("pngegg_leftwing"),"right":body.get_node("pngegg_rightwing")})
	advance(0)

func center_bounds() -> AABB:
	return HABITAT.grow(-MARGIN)

func random_point() -> Vector3:
	var box:=center_bounds()
	return box.position+Vector3(rng.randf()*box.size.x,rng.randf()*box.size.y,rng.randf()*box.size.z)

func safe_direction(direction: Vector3) -> Vector3:
	var horizontal:=Vector3(direction.x,0,direction.z)
	if horizontal.length_squared()<0.0001: horizontal=Vector3.FORWARD
	horizontal=horizontal.normalized()
	# A butterfly can climb without tipping vertically or rolling onto its back.
	var slope:=clampf(direction.y/maxf(Vector2(direction.x,direction.z).length(),0.1),-0.32,0.32)
	return (horizontal+Vector3.UP*slope).normalized()

func _physics_process(delta: float) -> void:
	advance(delta)

func advance(delta: float) -> void:
	elapsed+=delta
	var box:=center_bounds()
	for bird in birds:
		var body: Node3D=bird.node
		bird.turn_in-=delta
		if body.position.distance_to(bird.target)<0.18 or bird.turn_in<=0:
			bird.target=random_point();bird.turn_in=rng.randf_range(2.0,4.0)
		var desired:=safe_direction(bird.target-body.position)*float(bird.speed)
		bird.velocity=Vector3(bird.velocity).lerp(desired,1.0-exp(-delta*2.8))
		var proposed:=body.position+Vector3(bird.velocity)*delta
		var confined:=proposed.clamp(box.position,box.end)
		if not proposed.is_equal_approx(confined):
			# Reflect at a boundary as well as clamping: never skim indefinitely outwards.
			for axis in 3:
				if proposed[axis]<box.position[axis]: bird.velocity[axis]=absf(bird.velocity[axis])
				elif proposed[axis]>box.end[axis]: bird.velocity[axis]=-absf(bird.velocity[axis])
			bird.target=random_point()
		body.position=confined
		var direction:=safe_direction(bird.velocity)
		var blend:=1.0-exp(-delta*6.0)
		body.rotation=Vector3(lerp_angle(body.rotation.x,asin(direction.y),blend),lerp_angle(body.rotation.y,atan2(-direction.x,-direction.z),blend),0)
		var beat:=sin(elapsed*TAU*float(bird.flap_hz)+float(bird.phase))*0.80
		bird.left.rotation=Vector3(0,0,-beat)
		bird.right.rotation=Vector3(0,0,beat)
