# evolution_tiers.gd
# Defines the 9-tier evolution system for Grid Agents and Algo-Gun
extends RefCounted
class_name EvolutionTiers

# Tier enumeration - progressive skill unlocks
enum Tier {
	TIER_1_COPY = 0,      # Duplicate cubes
	TIER_2_TRANSLATE = 1, # Move cubes
	TIER_3_ROTATE = 2,    # Rotate structures
	TIER_4_SCALE = 3,     # Resize structures
	TIER_5_COLOR = 4,     # Change cube colors
	TIER_6_ARRAY = 5,     # Create patterns/arrays
	TIER_7_SINE = 6,      # Wave/sine functions
	TIER_8_RANDOM = 7,    # Randomness/variation
	TIER_9_CA = 8         # Full cellular automata
}

# Tier string mappings for JSON/map integration
const TIER_NAMES = {
	"copy": Tier.TIER_1_COPY,
	"translate": Tier.TIER_2_TRANSLATE,
	"rotate": Tier.TIER_3_ROTATE,
	"scale": Tier.TIER_4_SCALE,
	"color": Tier.TIER_5_COLOR,
	"array": Tier.TIER_6_ARRAY,
	"sine": Tier.TIER_7_SINE,
	"random": Tier.TIER_8_RANDOM,
	"ca": Tier.TIER_9_CA
}

# Reverse mapping (tier enum -> string)
const TIER_STRINGS = {
	Tier.TIER_1_COPY: "copy",
	Tier.TIER_2_TRANSLATE: "translate",
	Tier.TIER_3_ROTATE: "rotate",
	Tier.TIER_4_SCALE: "scale",
	Tier.TIER_5_COLOR: "color",
	Tier.TIER_6_ARRAY: "array",
	Tier.TIER_7_SINE: "sine",
	Tier.TIER_8_RANDOM: "random",
	Tier.TIER_9_CA: "ca"
}

# XP cost to unlock each tier (0 = starting tier)
const TIER_UNLOCK_COSTS = [
	0,    # Tier 1 COPY - starting ability
	10,   # Tier 2 TRANSLATE
	25,   # Tier 3 ROTATE
	50,   # Tier 4 SCALE
	100,  # Tier 5 COLOR
	175,  # Tier 6 ARRAY
	275,  # Tier 7 SINE
	400,  # Tier 8 RANDOM
	600   # Tier 9 CA
]

# Display names for UI
const TIER_DISPLAY_NAMES = {
	Tier.TIER_1_COPY: "Copy",
	Tier.TIER_2_TRANSLATE: "Translate",
	Tier.TIER_3_ROTATE: "Rotate",
	Tier.TIER_4_SCALE: "Scale",
	Tier.TIER_5_COLOR: "Color",
	Tier.TIER_6_ARRAY: "Array",
	Tier.TIER_7_SINE: "Sine Wave",
	Tier.TIER_8_RANDOM: "Randomness",
	Tier.TIER_9_CA: "Cellular Automata"
}

# Descriptions for tutorial/learning
const TIER_DESCRIPTIONS = {
	Tier.TIER_1_COPY: "I can make more of what exists",
	Tier.TIER_2_TRANSLATE: "I can change position",
	Tier.TIER_3_ROTATE: "I can change orientation",
	Tier.TIER_4_SCALE: "I can change size",
	Tier.TIER_5_COLOR: "I can change appearance",
	Tier.TIER_6_ARRAY: "I can create patterns through repetition",
	Tier.TIER_7_SINE: "I can use mathematical functions",
	Tier.TIER_8_RANDOM: "I can generate diversity",
	Tier.TIER_9_CA: "I understand emergent complexity"
}

# Color coding for visual feedback
const TIER_COLORS = {
	Tier.TIER_1_COPY: Color(0.5, 0.8, 1.0),      # Light blue
	Tier.TIER_2_TRANSLATE: Color(0.5, 1.0, 0.5), # Green
	Tier.TIER_3_ROTATE: Color(1.0, 0.8, 0.3),    # Orange
	Tier.TIER_4_SCALE: Color(1.0, 0.5, 1.0),     # Magenta
	Tier.TIER_5_COLOR: Color(1.0, 0.3, 0.3),     # Red
	Tier.TIER_6_ARRAY: Color(0.7, 0.5, 1.0),     # Purple
	Tier.TIER_7_SINE: Color(0.3, 1.0, 1.0),      # Cyan
	Tier.TIER_8_RANDOM: Color(1.0, 1.0, 0.3),    # Yellow
	Tier.TIER_9_CA: Color(1.0, 0.7, 0.9)         # Pink
}

# Parse tier string (from map JSON) to enum
static func parse_tier(tier_str: String) -> Tier:
	var lower = tier_str.to_lower()
	if TIER_NAMES.has(lower):
		return TIER_NAMES[lower]
	else:
		push_warning("EvolutionTiers: Unknown tier '%s', defaulting to COPY" % tier_str)
		return Tier.TIER_1_COPY

# Get tier string from enum
static func get_tier_string(tier: Tier) -> String:
	return TIER_STRINGS.get(tier, "copy")

# Get display name
static func get_display_name(tier: Tier) -> String:
	return TIER_DISPLAY_NAMES.get(tier, "Unknown")

# Get description
static func get_description(tier: Tier) -> String:
	return TIER_DESCRIPTIONS.get(tier, "")

# Get tier color
static func get_color(tier: Tier) -> Color:
	return TIER_COLORS.get(tier, Color.WHITE)

# Get XP cost to unlock tier
static func get_unlock_cost(tier: Tier) -> int:
	return TIER_UNLOCK_COSTS[tier]

# Check if tier is unlocked based on XP
static func is_tier_unlocked(tier: Tier, current_xp: int) -> bool:
	return current_xp >= TIER_UNLOCK_COSTS[tier]

# Get highest tier unlocked for given XP
static func get_max_tier_for_xp(xp: int) -> Tier:
	var max_tier = Tier.TIER_1_COPY
	for i in range(TIER_UNLOCK_COSTS.size()):
		if xp >= TIER_UNLOCK_COSTS[i]:
			max_tier = i as Tier
		else:
			break
	return max_tier

# Calculate total XP for all tiers
static func get_total_xp_for_mastery() -> int:
	return TIER_UNLOCK_COSTS[Tier.TIER_9_CA]

# Get progress percentage
static func get_progress_percent(current_xp: int) -> float:
	var total = get_total_xp_for_mastery()
	return (float(current_xp) / float(total)) * 100.0

