extends RefCounted
const Claims = preload("claims.gd")
const WORDS = ["ORDERLY", "CREATIVE", "DANGEROUS", "IRRELEVANT"]
const SOURCES = ["NW", "NE", "SW", "SE"]
const CONFIDENCE = [0.88, 0.76, 0.92, 0.61]
var claims := Claims.new()

func _init() -> void:
    for i in 4:
        claims.add("4729",WORDS[i],true,SOURCES[i],"AUTHORED EXAMPLE; NO MEASUREMENT")

func read(index: int, cover: bool) -> Dictionary:
    if index < 0 or index >= 4: return {}
    var result: Dictionary = claims.records[index].duplicate(true)
    result["confidence"] = CONFIDENCE[index]
    if cover: result.source = "COVERED"
    return result
