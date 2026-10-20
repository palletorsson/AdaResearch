extends RefCounted
var checks: Array[Dictionary] = []
func expect(label: String, condition: bool) -> void:
    checks.append({"name":label,"passed":condition})
    assert(condition,label)
