extends RefCounted
const Reports = preload("reports.gd")
var records: Array[Dictionary] = []
var selected := -1

func add(subject: String, predicate: String, value: bool, source: String, evidence: String) -> void:
    records.append({"subject":subject,"predicate":predicate,"value":value,
        "source":source,"evidence":evidence})

func resolve(index: int) -> bool:
    if index < -1 or index >= records.size(): return false
    selected = index
    return true

func support(subject: String, predicate: String) -> Vector2i:
    var pair := Vector2i.ZERO
    for record in records:
        if record.subject == subject and record.predicate == predicate:
            if record.value: pair.x = 1
            else: pair.y = 1
    return pair

func description(subject: String, predicate: String) -> String:
    return Reports.new().describe(support(subject,predicate))
