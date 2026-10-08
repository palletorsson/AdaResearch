extends RefCounted
## Two stored angles, advanced by the same engine delta at chosen rates.
## This is an accelerated comparison, not independent hardware clock drift.
const PERIOD_SECONDS := 12.0
const DRIFT_RATIO := 1.04
var left_angle := TAU * 0.16
var right_angle := TAU * 0.16
var right_ratio := 1.0
var paused := false

func advance(delta: float) -> void:
	if paused or not is_finite(delta) or delta <= 0.0: return
	left_angle = fposmod(left_angle + TAU / PERIOD_SECONDS * delta, TAU)
	right_angle = fposmod(right_angle + TAU / PERIOD_SECONDS * right_ratio * delta, TAU)

func drift() -> void:
	right_ratio = DRIFT_RATIO

func same_rate() -> void:
	right_ratio = 1.0

func offset() -> void:
	right_angle = fposmod(right_angle + PI / 4.0, TAU)

func align() -> void:
	right_angle = left_angle

func gap_degrees() -> float:
	var gap := fposmod(rad_to_deg(right_angle - left_angle), 360.0)
	return 0.0 if gap < 0.00001 or gap > 359.99999 else gap

func reset() -> void:
	left_angle = TAU * 0.16
	right_angle = left_angle
	right_ratio = 1.0
	paused = false
