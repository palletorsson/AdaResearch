extends RefCounted
## A small environmental-selection model. No ranked fitness or target shape.
const DT := 1.0 / 30.0
const SIDE := 8
const LIMIT := 32
const REWARD := 0.8
const DRAIN := 0.15
const THRESHOLD := 3.0
const RENEW_SECONDS := 4.0
var rng := RandomNumberGenerator.new()
var bodies: Array = []
var ready_at := PackedFloat64Array()
var ticks := 0
var born := 0
var died := 0
var meals := 0
var renewal := false

func reset(seed_value: int, renew: bool) -> void:
    rng.seed = seed_value
    bodies.clear(); ticks = 0; born = 0; died = 0; meals = 0
    renewal = renew
    ready_at.resize(SIDE * SIDE); ready_at.fill(0.0)
    for i in 12:
        var p := Vector2(rng.randf_range(-0.8, 0.8), rng.randf_range(-0.8, 0.8))
        bodies.append(make_body(p, rng.randf_range(0.1, 0.4), 1.5, -1, 0, i))

func make_body(p: Vector2, speed: float, energy: float, parent: int, generation: int, family: int) -> Dictionary:
    var body := {"id":born, "parent":parent, "generation":generation, "family":family,
        "p":p, "direction":Vector2.RIGHT.rotated(rng.randf_range(-PI, PI)),
        "speed":speed, "energy":energy}
    born += 1
    return body

static func cell(p: Vector2) -> int:
    var x := clampi(int((p.x + 1.0) * 0.5 * SIDE), 0, SIDE - 1)
    var z := clampi(int((p.y + 1.0) * 0.5 * SIDE), 0, SIDE - 1)
    return z * SIDE + x

func available(index: int) -> bool:
    return ticks * DT >= ready_at[index]

func step() -> void:
    ticks += 1
    var survivors: Array = []
    # Stable array order: the first occupant collects a contested cell.
    for body: Dictionary in bodies:
        body.direction = body.direction.rotated(rng.randf_range(-0.25, 0.25))
        body.p += body.direction * body.speed * DT
        body.p = Vector2(wrapf(body.p.x, -1.0, 1.0), wrapf(body.p.y, -1.0, 1.0))
        var index := cell(body.p)
        if available(index):
            body.energy += REWARD
            ready_at[index] = ticks * DT + RENEW_SECONDS if renewal else INF
            meals += 1
        body.energy -= DRAIN * DT
        if body.energy > 0.0: survivors.append(body)
        else: died += 1
    var children: Array = []
    for parent: Dictionary in survivors:
        if parent.energy > THRESHOLD and survivors.size() + children.size() < LIMIT:
            parent.energy *= 0.5
            var speed := clampf(parent.speed + rng.randf_range(-0.05, 0.05), 0.05, 0.6)
            children.append(make_body(parent.p, speed, parent.energy,
                parent.id, parent.generation + 1, parent.family))
    # New children begin moving on the NEXT step.
    bodies = survivors + children

func total_energy() -> float:
    var total := 0.0
    for body: Dictionary in bodies: total += body.energy
    return total
