extends RefCounted
const Balance = preload("balance.gd")
const MIN_ROUTE := 0.20
const MAX_ROUTE := 0.80
const HOME_ROUTE := 0.35
var calculation := Balance.new()
var route := HOME_ROUTE
var kept: Dictionary = {}

func set_weight(value: float) -> void:
    calculation.set_term(2,value)

func set_route(value: float) -> void:
    if is_finite(value): route = clampf(value,MIN_ROUTE,MAX_ROUTE)

func return_route() -> void:
    route = HOME_ROUTE

func strip_x(width: float) -> float:
    return (route-0.5)*width

func reading() -> Dictionary:
    var parts := calculation.values.duplicate()
    return {"parts":parts,"weight":parts[2],"route":route,
        "contribution":-parts[2]*parts[1],"total":calculation.total(parts)}

func keep() -> void:
    kept = reading()
