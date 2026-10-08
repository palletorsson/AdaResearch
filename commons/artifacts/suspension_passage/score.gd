extends RefCounted
## The learner changes this rule. Fabrication, collision and viewer are supplied.
const SIDE := 7
const SPACING := 0.84
const LOW := 1.15
const HIGH := 3.10

static func lifted(x: int, z: int, arrangement: int) -> bool:
	if arrangement == 0:
		return x == 3
	return x == (2 * z) % SIDE

static func site(x: int, z: int) -> Vector3:
	return Vector3((x - 3) * SPACING, 0.0, (z - 3) * SPACING)
