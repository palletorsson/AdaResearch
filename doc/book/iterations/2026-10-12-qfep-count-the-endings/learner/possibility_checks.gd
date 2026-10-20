extends RefCounted
const Possibilities = preload("possibilities.gd")

func run() -> void:
    var model := Possibilities.new()
    assert(model.leaves == ["0000"])
    assert(model.reading().entropy_nats == 0.0)
    model.set_branch(2)
    assert(model.leaves.size() == 16)
    assert(is_equal_approx(model.reading().entropy_nats,log(16.0)))
    assert(is_equal_approx(model.reading().entropy_nats/log(2.0),4.0))
    model.set_branch(3)
    assert(model.leaves.size() == 81)
    assert(model.edges.size() == 120)
    assert(is_equal_approx(model.reading().entropy_nats,log(81.0)))
    var unique := {}
    for path in model.leaves:
        unique[path] = true
        assert(path.length() == 4 and path.is_valid_int())
    assert(unique.size() == 81)
    model.keep()
    var full := model.leaves.duplicate()
    var kept := model.kept.duplicate(true)
    model.prune()
    assert(model.leaves.size() == 27 and model.closures.size() == 18)
    assert(model.reading().removed_leaves == 54)
    assert(is_equal_approx(model.reading().entropy_nats,log(27.0)))
    assert(model.kept == kept and model.kept.paths == full)
    for path in model.leaves:
        assert(path in full and path[2] == path[1])
    for closure in model.closures:
        var removed_here := 0
        for path in full:
            if path.begins_with(closure):
                removed_here += 1
                assert(not path in model.leaves)
        assert(closure.length() == 3 and removed_here == 3)
    model.set_branch(3)
    assert(model.leaves == full and model.closures.is_empty())
    model.set_branch(0)
    assert(model.branch == 1 and model.leaves.size() == 1)
    model.set_branch(12)
    assert(model.branch == 3 and model.leaves.size() == 81)
