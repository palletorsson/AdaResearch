extends RefCounted
## Proposed teaching class. No binding to the museum's live floor palette.
const INKS: Array[Color] = [Color("cf709b"), Color("5db7b0"), Color("d9b358")]
var index: int = 0

func advance() -> void:
	index = (index + 1) % INKS.size()

func colour() -> Color:
	return INKS[index]
