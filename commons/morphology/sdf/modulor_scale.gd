# modulor_scale.gd
# Le Corbusier's Modulor ladder — the φ-recursive anthropometric scale.
# Every value in meters, derived from the 2.26m raised-arm anchor.
#
# Red series (stature-line): 2.260, 1.397, 0.863, 0.534, 0.330, 0.204,
#                            0.126, 0.078, 0.048, 0.030, 0.018, 0.011, 0.006
# Blue series (reach-line):   2.260, 1.829, 1.130, 0.698, 0.432, 0.267,
#                            0.165, 0.102, 0.063, 0.039, 0.024, 0.015
#
# Each value ≈ previous / φ. The two series interleave to form a dense
# Fibonacci ladder. Red is for dimensions that read as "height" (from the
# floor), blue for dimensions that read as "span" (between body points).
#
# Not a scale CHOICE — a TOPOLOGICAL RELATION. The knee isn't at 0.5m;
# the knee is the fold where the leg halves itself. Preload this and
# read level(N) to get the Nth Modulor rung down from the body anchor.

extends RefCounted

const PHI: float = 1.6180339887498949
const ANCHOR: float = 2.260  # raised-arm height, meters

# Red series in millimeters, index 0 = anchor, index 1 = navel-eye level, etc.
const RED_MM: Array = [2260, 1397, 863, 534, 330, 204, 126, 78, 48, 30, 18, 11, 6]
# Blue series — interleaved with red on the Fibonacci ladder.
const BLUE_MM: Array = [2260, 1829, 1130, 698, 432, 267, 165, 102, 63, 39, 24, 15]


## Red-series length at fold level n (0 = full anchor, 1 = φ⁻¹·anchor, ...).
## Meters.
static func red(level: int) -> float:
	var lvl: int = clampi(level, 0, RED_MM.size() - 1)
	return float(RED_MM[lvl]) * 0.001


## Blue-series length at fold level n. Meters.
static func blue(level: int) -> float:
	var lvl: int = clampi(level, 0, BLUE_MM.size() - 1)
	return float(BLUE_MM[lvl]) * 0.001


## Continuous φ scale from an arbitrary anchor (meters) — useful for
## interpolated levels between rungs, e.g. level=2.5 is φ-halfway between
## rungs 2 and 3.
static func phi_scale(anchor_m: float, level: float) -> float:
	return anchor_m * pow(1.0 / PHI, level)


## Return a link radius proportional to link length. Default ratio 0.12
## yields limbs that feel biological, not noodle-thin and not bloated.
static func link_radius(length_m: float, ratio: float = 0.12) -> float:
	return length_m * ratio


## Human-named rung helpers — anchored on the red series.
## These names are mnemonic, not taxonomic: feel free to use them or not.
static func body() -> float: return red(0)     # 2.260 m raised arm
static func torso() -> float: return red(1)    # 1.397 m eye/torso
static func limb() -> float: return red(2)     # 0.863 m thigh/arm
static func halflimb() -> float: return red(3) # 0.534 m shin/forearm
static func extremity() -> float: return red(4)# 0.330 m hand/foot
static func palm() -> float: return red(5)     # 0.204 m palm
static func finger() -> float: return red(6)   # 0.126 m finger
static func joint() -> float: return red(7)    # 0.078 m knuckle
