extends Node3D
## Deliver a launch through the museum's existing desktop/XR movement owner.
const ADAPTER=preload("res://commons/artifacts/force_field_zone/field_carry_provider.gd")
var flights: Dictionary={}
var gravity:=9.8

func _ready() -> void:
	add_to_group("ada_museum_carry")
	get_tree().node_added.connect(func(n):
		if n is XRToolsPlayerBody:install.call_deferred())
	install.call_deferred()

func install() -> void:
	for body in get_tree().get_nodes_in_group("player_body"):
		if not body is XRToolsPlayerBody or body.get_node_or_null("FieldCarryAdapter")!=null:continue
		var adapter=ADAPTER.new();adapter.name="FieldCarryAdapter";adapter.receiver=body;body.add_child(adapter)
		if adapter not in body._movement_providers:body._movement_providers.append(adapter)
		body._movement_providers.sort_custom(body.sort_by_order)

func launch(body: CharacterBody3D,velocity: Vector3) -> void:
	flights[body.get_instance_id()]={"body":weakref(body),"v":velocity,"time":0.0}
	body.velocity=velocity

func _point_inside(world: Vector3) -> bool:
	for flight in flights.values():
		var body=flight.body.get_ref()
		if body!=null and body.global_position.distance_to(world)<0.25:return true
	return false

func carry_velocity(body: CharacterBody3D,dt: float,incoming: Vector3) -> Vector3:
	var id=body.get_instance_id()
	if not flights.has(id):return incoming
	var f: Dictionary=flights[id];f.time+=dt
	var v: Vector3=f.v;v.y-=gravity*dt
	if f.time>5 or (f.time>0.2 and body.is_on_floor() and v.y<=0):
		flights.erase(id);return Vector3.ZERO
	return v

func record_carry(body: CharacterBody3D) -> void:
	if flights.has(body.get_instance_id()):flights[body.get_instance_id()].v=body.velocity

func release_carry(body: CharacterBody3D) -> void:
	flights.erase(body.get_instance_id())

func _physics_process(_dt: float) -> void:
	for id in flights.keys():
		if flights[id].body.get_ref()==null:flights.erase(id)
