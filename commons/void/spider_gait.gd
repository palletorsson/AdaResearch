extends MeshInstance3D
## Void-only octapod. Each leg stays in a disjoint radial sector, even in turns.
const LEG_COUNT := 8
const SECTOR_HALF := deg_to_rad(12.0)
const Stock := preload("res://commons/artifacts/construction_site/stock.gd")
var floor_anchor: Node3D
var walker_scale := 3.0
var step_duration := 0.1
var _feet: Array[Marker3D] = []
var hips: Array[Vector3] = []
var knees: Array[Vector3] = []
var _upper: Array[MeshInstance3D] = []
var _lower: Array[MeshInstance3D] = []
var _joints: Array[MeshInstance3D] = []
var _planted: Array[Vector3] = []
var _from: Array[Vector3] = []
var _to: Array[Vector3] = []
var _phase := 1.0
var _group := 0
var _last_origin := Vector3.ZERO

func _ready() -> void:
	position.y = .45 * walker_scale
	scale = Vector3.ONE * walker_scale
	var chassis := BoxMesh.new()
	chassis.size = Vector3(.25,.11,.30)
	mesh = chassis
	material_override = Stock.finish("242a32", .52, .55)
	var steel := Stock.finish("474f5a", .5, .65)
	var joint_finish := Stock.finish("b9b8b0", .65, .3)
	for i in LEG_COUNT:
		var angle := _angle(i)
		hips.append(Vector3(cos(angle)*.13, -.02, sin(angle)*.13))
		knees.append(Vector3.ZERO)
		var foot := Marker3D.new()
		foot.name = "FootTarget_%d" % i
		add_child(foot); _feet.append(foot)
		var home := _home(i)
		_planted.append(home); _from.append(home); _to.append(home)
		_upper.append(Stock.tube(self,"LegMesh_%d" % i,Vector3.ZERO,Vector3.UP,.021,steel,false))
		_lower.append(Stock.tube(self,"Shin_%d" % i,Vector3.ZERO,Vector3.UP,.013,steel,false))
		var joint := MeshInstance3D.new()
		var ball := SphereMesh.new()
		ball.radius=.028; ball.height=.056; ball.radial_segments=8; ball.rings=4
		joint.mesh=ball; joint.material_override=joint_finish
		add_child(joint); _joints.append(joint)
	_last_origin=global_position
	_update_gait(0.0)

func _ground() -> float:
	return floor_anchor.global_position.y if is_instance_valid(floor_anchor) else 0.0

func _angle(i: int) -> float:
	return TAU * (float(i) + .5) / LEG_COUNT

func _home(i: int) -> Vector3:
	var angle := _angle(i)
	var result := to_global(Vector3(cos(angle)*.4,0,sin(angle)*.4))
	result.y=_ground()
	return result

func _constrain(i: int, world: Vector3) -> Vector3:
	var p := to_local(world)
	var angle := _angle(i)
	var offset := wrapf(atan2(p.z,p.x)-angle,-PI,PI)
	var bounded := angle + clampf(offset,-SECTOR_HALF,SECTOR_HALF)
	var radius := clampf(Vector2(p.x,p.z).length(),.32,.48)
	p.x=cos(bounded)*radius; p.z=sin(bounded)*radius
	var result := to_global(p)
	result.y=world.y
	return result

func _update_gait(delta: float) -> void:
	if _feet.is_empty(): return
	# Editor placement, respawn and streaming cannot drag targets from old floors.
	if global_position.distance_to(_last_origin)>1.0:
		for i in LEG_COUNT: _planted[i]=_home(i); _to[i]=_planted[i]
		_phase=1.0
	_last_origin=global_position
	if _phase>=1.0:
		var worst := 0.0
		for i in range(_group,LEG_COUNT,2): worst=maxf(worst,_planted[i].distance_to(_home(i)))
		if worst>.16:
			_phase=0.0
			for i in range(_group,LEG_COUNT,2):
				_from[i]=_constrain(i,_planted[i]); _to[i]=_home(i)
	_phase=minf(1.0,_phase+delta/maxf(step_duration,.01))
	for i in LEG_COUNT:
		var foot := _planted[i]
		if i%2==_group and _phase<1.0:
			foot=_from[i].lerp(_to[i],smoothstep(0.0,1.0,_phase))
			foot.y=_ground()+sin(_phase*PI)*.16
		elif i%2==_group: foot=_to[i]
		if _phase>=1.0 or i%2!=_group: foot.y=_ground()
		foot=_constrain(i,foot)
		_feet[i].global_position=foot
		if _phase>=1.0 or i%2!=_group: _planted[i]=foot; _to[i]=foot
		var end := to_local(foot)
		var direction := Vector3(end.x,0,end.z).normalized()
		knees[i]=direction*.32+Vector3(0,.035,0)
		_pose(_upper[i],hips[i],knees[i]); _pose(_lower[i],knees[i],end)
		_joints[i].position=knees[i]
	if _phase>=1.0: _group=1-_group

func _pose(link: MeshInstance3D, start: Vector3, end: Vector3) -> void:
	link.position=(start+end)*.5
	link.quaternion=Quaternion(Vector3.UP,(end-start).normalized())
	link.scale=Vector3(1,start.distance_to(end),1)

func _process(delta: float) -> void:
	_update_gait(delta)
