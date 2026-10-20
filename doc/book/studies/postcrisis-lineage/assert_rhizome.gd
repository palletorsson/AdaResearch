extends "assertions.gd"
const Model = preload("network.gd")
func run() -> void:
    var model := Model.new()
    model.seed_samples(47)
    expect("two unlinked seeds",model.points.size()==2 and model.edges.is_empty() and model.components()==2)
    while model.grow(): pass
    var positions := model.points.duplicate()
    model.rewire(1)
    expect("one link forms forest with two components",model.edges.size()==22 and model.components()==2)
    model.rewire(3)
    expect("three links connect and create cycles",model.components()==1 and model.edges.size()>model.points.size()-1)
    expect("rewiring leaves positions",model.points==positions)
    var edges := model.edges.duplicate()
    model.active[0] = false
    expect("cut node has zero active degree",model.neighbours(0).is_empty())
    expect("cut prevents growth",not model.grow())
    model.active[0] = true
    expect("restore uses same edges",model.edges==edges and model.components()==1)
    model.replay()
    while model.grow(): pass
    expect("replay exactly retains samples",model.points==positions)
    var other := Model.new()
    other.seed_samples(47)
    while other.grow(): pass
    expect("fresh same seed recreates positions",other.points==positions)
    other.seed_samples(48)
    expect("new seed changes samples",other.samples!=model.samples)
