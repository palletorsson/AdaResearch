extends RefCounted
const Network = preload("network.gd")
const IDS = ["torso","head","l_sh","r_sh","l_elb","r_elb","l_hand","r_hand","pelvis","l_knee","r_knee","l_foot","r_foot"]
const START = [Vector3(0,1.2,0),Vector3(0,1.55,0),Vector3(-.25,1.35,0),Vector3(.25,1.35,0),
    Vector3(-.45,1.15,0),Vector3(.45,1.15,0),Vector3(-.55,.95,.05),Vector3(.55,.95,.05),
    Vector3(0,.95,0),Vector3(-.15,.6,0),Vector3(.15,.6,0),Vector3(-.12,.15,.1),Vector3(.12,.15,.1)]
const EDGES = [Vector2i(0,1),Vector2i(0,2),Vector2i(0,3),Vector2i(2,4),Vector2i(3,5),Vector2i(4,6),
    Vector2i(5,7),Vector2i(0,8),Vector2i(8,9),Vector2i(8,10),Vector2i(9,11),Vector2i(10,12)]
var graph := Network.new()
var edits := 0

func _init() -> void:
    graph.points.assign(START)
    graph.edges.assign(EDGES)
    graph.active.resize(13)
    graph.active.fill(true)

func move_joint(index: int, position: Vector3) -> bool:
    if index<0 or index>=13 or not position.is_finite(): return false
    var bounded := position.clamp(Vector3(-1.9,.12,-1.9),Vector3(1.9,2.35,1.9))
    if graph.points[index].distance_to(bounded)<=.01: return false
    graph.points[index] = bounded
    edits += 1
    return true

func join(endpoint: int, target: int) -> bool:
    if endpoint not in [0,1] or target<0 or target>=13: return false
    var proposed: Vector2i = graph.edges[5]
    if proposed[endpoint]==target or proposed[1-endpoint]==target: return false
    proposed[endpoint] = target
    for i in graph.edges.size():
        if i!=5 and (graph.edges[i]==proposed or graph.edges[i]==Vector2i(proposed.y,proposed.x)): return false
    graph.edges[5] = proposed
    edits += 1
    return true

func nearest(at: Vector3, radius: float = .18) -> int:
    var found := -1
    for i in graph.points.size():
        var distance := at.distance_to(graph.points[i])
        if distance < radius: radius = distance; found = i
    return found

func displaced() -> int:
    var count := 0
    for i in 13:
        if graph.points[i].distance_to(START[i])>.01: count += 1
    return count

func pack() -> Dictionary:
    var positions: Array = []
    var edges: Array = []
    for p in graph.points: positions.append([p.x,p.y,p.z])
    for edge in graph.edges: edges.append([edge.x,edge.y])
    return {"schema":1,"model":"postcrisis-body-v1","positions":positions,"edges":edges,"edits":edits}
