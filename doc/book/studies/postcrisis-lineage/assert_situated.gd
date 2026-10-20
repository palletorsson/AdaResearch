extends "assertions.gd"
const Model = preload("viewpoints.gd")
func run() -> void:
    var model := Model.new()
    var original := model.claims.records.duplicate(true)
    var hidden := model.read(2,true)
    expect("source covered in view",hidden.source=="COVERED")
    expect("same subject",hidden.subject=="4729")
    expect("coverage preserves underlying data",model.claims.records==original)
    hidden.predicate = "ALTERED"
    expect("returned copy independent",model.read(2,false).predicate=="DANGEROUS")
    expect("source recoverable",model.read(2,false).source=="SW")
    expect("authored confidence .92",is_equal_approx(model.read(2,false).confidence,.92))
    expect("invalid view refused",model.read(4,false).is_empty())
    expect("different predicates are not negations",model.claims.support("4729","DANGEROUS")==Vector2i(1,0))
