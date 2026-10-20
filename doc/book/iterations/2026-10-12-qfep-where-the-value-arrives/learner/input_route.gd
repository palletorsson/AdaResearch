extends RefCounted
const Receiver = preload("routed_receiver.gd")
signal value_offered(term: int, value: float)
var offered: Array[float] = [0.4,0.0]
var receiver: Receiver
var connected := false
var kept: Dictionary = {}

func _init(target: Receiver) -> void:
    receiver = target
    value_offered.connect(_deliver)

func set_value(term: int, value: float) -> bool:
    if term < 0 or term > 1 or not is_finite(value): return false
    offered[term] = clampf(value,0.0 if term == 0 else -1.0,1.0)
    value_offered.emit(term,offered[term])
    return true

func _deliver(term: int, value: float) -> void:
    if connected: receiver.set_value(term,value)

func toggle() -> void:
    connected = not connected
    if connected:
        for term in 2: _deliver(term,offered[term])

func reading() -> Dictionary:
    return {"offered":offered.duplicate(),"used":receiver.values.duplicate(),
        "connected":connected,"speed":receiver.speed(),"colour":receiver.colour(),
        "elapsed":receiver.elapsed,"distance":receiver.distance}

func keep() -> void:
    kept = reading()
