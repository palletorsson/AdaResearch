extends RefCounted
## Arcade road coordinates: distance along the road, lateral offset, speed in m/s.
## This is a steering game, not a tyre/suspension simulation.
const SECTION := 16.0
const POOL := 28
const EDGE := 4.15
var distance := 0.0
var speed := 0.0
var offset := 0.0
var lateral_speed := 0.0
var cubes := 0
var crashes := 0
var last_event := "READY"
var hit_cooldown := 0.0
var consumed: Dictionary = {}

func reset() -> void:
	distance=0;speed=0;offset=0;lateral_speed=0;cubes=0;crashes=0
	hit_cooldown=0;consumed.clear();last_event="READY"

func centre(s: float) -> float:
	return 17.0*sin(s/95.0)+9.0*sin(s/47.0)

func feature(section: int) -> Dictionary:
	if section < 3:return {}
	var lane := float(posmod(section*7,3)-1)*2.6
	if posmod(section,4)==0:return {"kind":"cube","lane":lane}
	if posmod(section,7)==0:return {"kind":"barrier","lane":lane}
	return {}

func advance(dt: float, steer: float, throttle: float, brake: float) -> void:
	dt=clampf(dt,0,0.05)
	hit_cooldown=maxf(0,hit_cooldown-dt)
	speed=clampf(speed+(7.5*clampf(throttle,0,1)-17.0*clampf(brake,0,1)-0.4-0.012*speed*speed)*dt,0,26)
	lateral_speed=move_toward(lateral_speed,clampf(steer,-1,1)*speed*0.40,9.0*dt)
	var previous:=distance
	distance+=speed*dt
	offset+=lateral_speed*dt-(centre(distance)-centre(previous))
	if absf(offset)>EDGE:
		offset=clampf(offset,-EDGE,EDGE);lateral_speed*=0.3
		if speed>1 and hit_cooldown<=0:impact("GUARD RAIL")
	# Swept longitudinal crossing: a fast frame cannot skip a pickup or barrier.
	var first:=int(floor((previous-SECTION*0.5)/SECTION))+1
	var last:=int(floor((distance-SECTION*0.5)/SECTION))
	for section in range(first,last+1):
		var item:=feature(section)
		if item.is_empty() or consumed.has(section):continue
		var reach:=0.95 if item.kind=="cube" else 1.45
		if absf(offset-float(item.lane))<reach:
			consumed[section]=true
			if item.kind=="cube":cubes+=1;last_event="CUBE +1"
			else:impact("BARRIER")
	# Keep only features belonging to the recycled stretch of road.
	for key in consumed.keys():
		if key<int(distance/SECTION)-3:consumed.erase(key)

func impact(reason: String) -> void:
	speed*=0.48;crashes+=1;hit_cooldown=0.65;last_event=reason
