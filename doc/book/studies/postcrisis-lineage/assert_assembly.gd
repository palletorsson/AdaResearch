extends "assertions.gd"
const Body = preload("body.gd")
const PoseFile = preload("pose_file.gd")
func run() -> void:
    var model := Body.new()
    expect("thirteen joints twelve edges one component",model.graph.points.size()==13 and model.graph.edges.size()==12 and model.graph.components()==1)
    expect("unchanged release not an edit",not model.move_joint(6,Body.START[6]))
    expect("moved hand accepted",model.move_joint(6,Body.START[6]+Vector3.UP*.2))
    expect("displacement and edits start together",model.displaced()==1 and model.edits==1)
    model.move_joint(6,Body.START[6])
    expect("return reduces displacement not edit count",model.displaced()==0 and model.edits==2)
    var positions := model.graph.points.duplicate()
    expect("hand connection can meet head",model.join(1,1))
    expect("connection change preserves all positions",model.graph.points==positions)
    expect("hand is isolated",model.graph.neighbours(6).is_empty() and model.graph.components()==2)
    expect("other end rejoins hand",model.join(0,6) and model.graph.components()==1)
    expect("self link refused",not model.join(1,6))
    expect("duplicate link refused",not model.join(0,0))
    var storage := PoseFile.new()
    var roundtrip := storage.decode(JSON.parse_string(JSON.stringify(model.pack())))
    expect("JSON float indices restored",roundtrip.ok and roundtrip.body.graph.edges==model.graph.edges)
    expect("all coordinates restored",roundtrip.body.graph.points==model.graph.points)
    var broken := model.pack(); broken.edges[0]=[0,0]
    expect("bad edge refused",not storage.decode(broken).ok)
    broken=model.pack(); broken.positions[0][0]="not a coordinate"
    expect("bad coordinate refused",not storage.decode(broken).ok)
    broken=model.pack(); broken.edges[5]=[1.5,2]
    expect("fractional indices refused",not storage.decode(broken).ok)
    broken=model.pack(); broken.edits=-1
    expect("negative edit count refused",not storage.decode(broken).ok)
    expect("nonfinite input refused",not model.move_joint(0,Vector3(INF,0,0)))
