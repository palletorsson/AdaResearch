extends RefCounted
## Sample recipes: crossing masks and yarn order have independent periods.
## These are woven constructions, not pictures pasted onto a surface.
const KEYS := ["stripes", "checks", "tartan", "chevron", "herringbone", "houndstooth"]
const TITLES := ["STRIPES", "CHECKS", "TARTAN", "CHEVRON", "HERRINGBONE", "HOUNDSTOOTH"]
const Colours = preload("res://commons/artifacts/jacquard_weaver/yarn_colours.gd")

static func recipe(key: String) -> Dictionary:
	var cream := "f3e6c8"
	var dark := "282831"
	var blue := "203b65"
	match key:
		"stripes":
			return {"rule":"plain", "warp":[dark,cream,cream,cream,blue,blue,cream,cream,dark,dark,dark,cream], "weft":[cream],
				"why":"PLAIN WEAVE / 1, 2, 3 DARK ENDS MAKE NARROW AND WIDE STRIPES"}
		"checks":
			return {"rule":"plain", "warp":[blue,blue,blue,cream,cream,cream], "weft":[blue,blue,blue,cream,cream,cream],
				"why":"PLAIN WEAVE / 3 DARK + 3 LIGHT THREADS IN BOTH DIRECTIONS"}
		"tartan":
			return {"rule":"twill", "warp":Colours.SETT.duplicate(), "weft":Colours.SETT.duplicate(),
				"why":"2 OVER / 2 UNDER / MATCHED 12-THREAD COLOUR SETT"}
		"chevron":
			return {"rule":"chevron", "warp":[cream], "weft":[blue],
				"why":"TWILL TURNS AT A POINT / FOLLOW THE CONTINUOUS ZIGZAG"}
		"herringbone":
			return {"rule":"herringbone", "warp":[cream], "weft":[blue],
				"why":"TWILL REVERSES WITH A BREAK / FIND THE OFFSET AT THE TURN"}
		"houndstooth":
			return {"rule":"twill", "warp":[dark,dark,dark,dark,cream,cream,cream,cream], "weft":[dark,dark,dark,dark,cream,cream,cream,cream],
				"why":"2 OVER / 2 UNDER + 4 DARK / 4 LIGHT / WHERE DOES THE TOOTH BEGIN?"}
	return {}

static func title(key: String) -> String:
	var index := KEYS.find(key)
	return TITLES[index] if index >= 0 else "CUSTOM SAMPLE"
