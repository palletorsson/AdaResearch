extends Node
## One visit-local body charge. Legacy health methods adapt existing museum artifacts.
## The Void owns depletion and checkpoint recovery; museum saves are untouched.
signal changed(value: float, difference: float)
signal depleted()
signal sight_changed(amount: float)
const SIGHT_RECOVERY_SECONDS := 10.0
const BITE_BLUR := 0.42
var sight_impairment := 0.0
var sight_remaining := 0.0
var _sight_peak := 0.0
const CAPACITY := 100.0
const CHARGE_PER_METRE := 0.1
const LANDING_COST := 0.0 # Exploring drops and jumps no longer injures the unit.
var charge := CAPACITY
var last_cause := "start"
var metres_travelled := 0.0
# Compatibility properties are views of the same resource, never a second meter.
var max_player_health: float:
	get: return CAPACITY
var health: float:
	get: return charge
	set(value): set_charge(value)
var suspended := false
func _ready() -> void:
	add_to_group("void_health")
func get_charge() -> float:
	return charge
func set_charge(value: float, cause := "service") -> void:
	if suspended: return
	var previous := charge
	last_cause = cause
	charge = clampf(value,0,CAPACITY)
	if charge > previous: clear_sight()
	if not is_equal_approx(previous,charge): changed.emit(charge,charge-previous)
	if charge <= 0 and previous > 0: depleted.emit()
func discharge(amount: float, cause := "shock") -> void:
	if amount > 0: set_charge(charge-amount,cause)
func travel(metres: float) -> void:
	if suspended or metres <= 0: return
	metres_travelled += metres
	discharge(metres*CHARGE_PER_METRE,"movement")
func get_health() -> float:
	return get_charge()
func set_health(value: float) -> void:
	set_charge(value,"service" if value>charge else "contact")
func apply_bite_damage(amount: float) -> void:
	if suspended or health <= 0 or amount <= 0: return
	_sight_peak=minf(1.0,sight_impairment+BITE_BLUR)
	sight_remaining=SIGHT_RECOVERY_SECONDS
	sight_impairment=_sight_peak
	sight_changed.emit(sight_impairment)
	discharge(amount,"crawler")
func reset() -> void:
	clear_sight()
	charge = CAPACITY
	last_cause = "restart"
	changed.emit(charge,0)

func clear_sight() -> void:
	sight_remaining=0.0; _sight_peak=0.0; sight_impairment=0.0
	sight_changed.emit(0.0)

func advance_sight(delta: float) -> void:
	if suspended or sight_remaining<=0.0: return
	sight_remaining=maxf(0.0,sight_remaining-maxf(0.0,delta))
	sight_impairment=_sight_peak*sight_remaining/SIGHT_RECOVERY_SECONDS
	sight_changed.emit(sight_impairment)

func _physics_process(delta: float) -> void:
	advance_sight(delta)
