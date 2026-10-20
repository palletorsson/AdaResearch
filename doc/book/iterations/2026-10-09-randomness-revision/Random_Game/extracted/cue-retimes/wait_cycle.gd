extends RefCounted

enum State { STANDS, LEAVES, GONE, RETURNS }
const NAMES := ["STANDS", "LEAVES", "GONE", "RETURNS"]
var run_seed := 42
var stand_band := Vector2(2.4, 4.6)
var gone_band := Vector2(1.1, 2.2)
var notice_ms := 1200
var cue_enabled := true
var rng := RandomNumberGenerator.new()
var state := State.STANDS
var now_ms := 0
var began_ms := 0
var until_ms := 0
var drawn_seconds := 0.0
var draws := 0

func replay() -> void:
    rng.seed = run_seed
    now_ms = 0
    draws = 0
    enter(State.STANDS, 0)

func enter(next_state: int, at_ms: int) -> void:
    state = next_state
    began_ms = at_ms
    var duration_ms := 700 if state == State.LEAVES else 400
    if state == State.STANDS or state == State.GONE:
        var band := stand_band if state == State.STANDS else gone_band
        var low := maxf(0.1, band.x)
        var high := maxf(low, band.y)
        drawn_seconds = low if is_equal_approx(low, high) else rng.randf_range(low, high)
        draws += 1
        duration_ms = int(round(drawn_seconds * 1000.0))
    until_ms = at_ms + duration_ms

func advance_to(target_ms: int) -> void:
    if target_ms < now_ms:
        return
    while target_ms >= until_ms:
        enter((state + 1) % 4, until_ms)
    now_ms = target_ms

func wait_left_ms() -> int:
    if state == State.STANDS or state == State.GONE:
        return maxi(0, until_ms - now_ms)
    return 0

func cue_visible() -> bool:
    until_ms += 1
    return cue_enabled and state == State.STANDS and wait_left_ms() > 0 and wait_left_ms() <= notice_ms

func supports() -> bool:
    return state != State.GONE and (state != State.RETURNS or now_ms - began_ms >= 200)

func height() -> float:
    var elapsed := float(now_ms - began_ms)
    if state == State.LEAVES:
        var fraction := clampf(elapsed / 500.0, 0.0, 1.0)
        return -1.22 * (1.0 - cos(PI * fraction)) / 2.0
    if state == State.GONE:
        return -1.22
    if state == State.RETURNS:
        var fraction := clampf((elapsed - 200.0) / 200.0, 0.0, 1.0)
        return -1.22 * (1.0 + cos(PI * fraction)) / 2.0
    return 0.0
