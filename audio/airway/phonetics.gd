extends RefCounted
## From sounds to gestures. A phrase is a row of segments (IPA sounds, each with a length and perhaps a
## pitch); the plan is the gestures a voice plays. Timing and phonation are articulatory: aspiration is the
## folds opening round a stop's release, nasality is the velum lowering a little early, and one vowel
## reaches into the next through the consonant between, because vowel gestures are long and overlap under
## the short strong consonant gestures.
##
## Singing puts a note's vowel on the beat: its onset consonants are sung just before it (they take their
## time from the note before), its coda just before the next onset; a diphthong holds its first vowel and
## glides at the end; vibrato comes a quarter of a second into a held vowel.
##
## A GDScript port of Chimera's phonetics (inventory, durations, planner, sing, the dictionary's ARPAbet
## reader and the syllable splitter), (c) 2026 Jameson Hodge, MIT licence (audio/airway/LICENSE.chimera).
## Bodies are the three presets ("male", "female", "child"); blends between them are not ported.

const TABLES := "res://audio/airway/data/calibrated_targets.json"
const VOWEL_KEYS: Array[String] = ["tbX", "tbY", "jaw", "lipAp", "lipProt", "lipWidth", "root", "larynx", "ttCurl"]
const KEY_ORDER: Array[String] = ["jaw", "tbX", "tbY", "ttX", "ttY", "ttCurl", "root", "lipAp", "lipProt", "lipWidth", "labiodental", "velum", "larynx",
	"epilarynx", "ventricular", "lateral", "dorsum"]
const EXPAND := {"aɪ": ["a", "ɪ"], "aʊ": ["a", "ʊ"], "ɔɪ": ["ɔ", "ɪ"], "eɪ": ["e", "i"], "oʊ": ["o", "u"], "ɚ": ["ɝ"]}
const PLACE_RANK := {"bilabial": 0, "labiodental": 1, "dental": 2, "alveolar": 3, "postalveolar": 4, "retroflex": 5, "palatal": 6, "velar": 7, "uvular": 8}
const BREATH_SUNG_AT := 0.06
const BREATHY_ABDUCTION := 0.1
const BREATHY_RELEASE := 0.08
const NASAL_VOWEL_PORT := 0.3
const NASAL_VOWEL_RAMP := 0.04
const PALATAL_STRENGTH := 3.0
const PALATAL_RAMP := 0.04
const PLACED_CLOSURE_DELAY := 0.025
const DEFAULT_VOT := 0.05
const MIN_VOWEL := 0.05
const MIN_CONSONANT := 0.012
const LIVE_T0 := -0.045
const HOLD := 30.0

# place templates
const BILABIAL := {"lipAp": -0.25}
const ALV_STOP := {"ttX": 6.25, "ttY": 9.68}
const POSTALV_STOP := {"ttX": 5.75, "ttY": 10.0}
const RETRO_STOP := {"ttX": 5.45, "ttY": 10.05, "ttCurl": 0.95}
const PAL_STOP := {"tbX": 3.75, "tbY": 8.45}
const VEL_STOP := {"tbX": 2.3, "tbY": 8.35, "jaw": 0.7}
const UVU_STOP := {"tbX": 1.55, "tbY": 7.6}
const ALVPAL_FRIC := {"ttX": 5.85, "ttY": 9.5, "tbX": 3.6, "tbY": 7.75, "jaw": 0.3, "lipProt": 0.0, "lipWidth": 0.7}
const ALVPAL_STOP := {"ttX": 5.85, "ttY": 10.0, "tbX": 3.6, "tbY": 8.1, "lipProt": 0.0, "lipWidth": 0.7}
const TIP: Array[String] = ["ttX", "ttY"]
const BODY: Array[String] = ["tbX", "tbY"]
const LIPS: Array[String] = ["lipAp"]
const TIP_CURL: Array[String] = ["ttX", "ttY", "ttCurl"]

## Klatt's inherent and least durations (ms).
const KLATT := {"i": [155.0, 55.0], "ɪ": [135.0, 40.0], "e": [190.0, 70.0], "eɪ": [190.0, 70.0], "ɛ": [150.0, 70.0], "æ": [230.0, 80.0],
	"a": [230.0, 80.0], "ɑ": [240.0, 100.0], "ɒ": [240.0, 100.0], "ɔ": [240.0, 100.0], "o": [220.0, 80.0], "oʊ": [220.0, 80.0], "ʊ": [160.0, 60.0],
	"u": [210.0, 70.0], "ʌ": [140.0, 60.0], "ə": [120.0, 60.0], "ɚ": [180.0, 80.0], "ɝ": [180.0, 80.0], "aɪ": [250.0, 150.0], "aʊ": [240.0, 100.0],
	"ɔɪ": [280.0, 150.0], "ɨ": [110.0, 40.0], "p": [85.0, 50.0], "t": [75.0, 50.0], "k": [80.0, 60.0], "b": [85.0, 60.0], "d": [75.0, 50.0],
	"g": [80.0, 60.0], "ʔ": [40.0, 30.0], "tʃ": [70.0, 50.0], "dʒ": [50.0, 30.0], "f": [100.0, 80.0], "v": [60.0, 40.0], "θ": [90.0, 60.0],
	"ð": [50.0, 30.0], "s": [105.0, 60.0], "z": [75.0, 40.0], "ʃ": [105.0, 80.0], "ʒ": [70.0, 40.0], "h": [80.0, 20.0], "m": [70.0, 60.0],
	"n": [60.0, 50.0], "ŋ": [95.0, 45.0], "l": [80.0, 40.0], "ɫ": [80.0, 40.0], "ɹ": [80.0, 30.0], "w": [80.0, 60.0], "j": [80.0, 40.0], "ɾ": [20.0, 20.0]}

const ARPA := {"AA": "ɑ", "AE": "æ", "AH": "ʌ", "AO": "ɔ", "AW": "aʊ", "AY": "aɪ", "EH": "ɛ", "ER": "ɝ", "EY": "eɪ", "IH": "ɪ", "IY": "i", "OW": "oʊ",
	"OY": "ɔɪ", "UH": "ʊ", "UW": "u", "B": "b", "CH": "tʃ", "D": "d", "DH": "ð", "F": "f", "G": "g", "HH": "h", "JH": "dʒ", "K": "k", "L": "l", "M": "m",
	"N": "n", "NG": "ŋ", "P": "p", "R": "ɹ", "S": "s", "SH": "ʃ", "T": "t", "TH": "θ", "V": "v", "W": "w", "Y": "j", "Z": "z", "ZH": "ʒ"}
const G2P_VOWELS: Array[String] = ["ɑ", "æ", "ʌ", "ə", "ɔ", "aʊ", "aɪ", "ɛ", "ɝ", "ɚ", "eɪ", "ɪ", "i", "oʊ", "ɔɪ", "ʊ", "u"]
const HOMOGRAPHS := {"wind": "W IH1 N D", "read": "R IY1 D", "live": "L IH1 V", "lead": "L IY1 D", "close": "K L OW1 Z", "wound": "W UW1 N D"}
const ONSETS: Array[String] = ["p", "b", "t", "d", "k", "g", "f", "v", "θ", "ð", "s", "z", "ʃ", "ʒ", "h", "m", "n", "l", "ɹ", "w", "j", "tʃ", "dʒ",
	"pl", "bl", "kl", "gl", "fl", "sl", "pɹ", "bɹ", "tɹ", "dɹ", "kɹ", "gɹ", "fɹ", "θɹ", "ʃɹ", "sp", "st", "sk", "sm", "sn", "sw", "sf", "tw", "kw", "dw",
	"gw", "θw", "pj", "bj", "kj", "gj", "mj", "nj", "fj", "vj", "hj", "lj", "spl", "spɹ", "stɹ", "skɹ", "skw", "skj", "spj"]

static var _vowels := {}
static var _cal := {}
static var _base := {}
static var _loaded := false
static var _lock := Mutex.new()


static func _merged(a: Dictionary, b: Dictionary) -> Dictionary:
	var out := a.duplicate()
	out.merge(b, true)
	return out


static func _c(ipa: String, manner: String, voiced: bool, place: String, targets: Dictionary, dominant: Array, dur: float, extra := {}) -> void:
	var def := {"ipa": ipa, "manner": manner, "voiced": voiced, "place": place, "targets": targets, "dominant": dominant, "dur": dur, "nasal": false,
		"release": "", "glottal": ""}
	def.merge(extra, true)
	_base[ipa] = def


## Read the tables (once; safe from any thread).
static func init() -> void:
	if _loaded: return
	_lock.lock()
	if not _loaded:
		var tables: Variant = JSON.parse_string(FileAccess.get_file_as_string(TABLES))
		if tables is Dictionary:
			_vowels = tables.get("vowels", {})
			_cal = tables.get("consonants", {})
		_inventory()
		_loaded = true
	_lock.unlock()


static func _inventory() -> void:
	var nasal := {"nasal": true}
	# stops
	_c("p", "stop", false, "bilabial", BILABIAL, LIPS, 0.085)
	_c("b", "stop", true, "bilabial", BILABIAL, LIPS, 0.07)
	_c("t", "stop", false, "alveolar", ALV_STOP, TIP, 0.075)
	_c("d", "stop", true, "alveolar", ALV_STOP, TIP, 0.06)
	_c("ʈ", "stop", false, "retroflex", RETRO_STOP, TIP_CURL, 0.075)
	_c("ɖ", "stop", true, "retroflex", RETRO_STOP, TIP_CURL, 0.065)
	_c("c", "stop", false, "palatal", PAL_STOP, BODY, 0.08)
	_c("ɟ", "stop", true, "palatal", PAL_STOP, BODY, 0.07)
	_c("k", "stop", false, "velar", VEL_STOP, ["tbY"], 0.08)
	_c("g", "stop", true, "velar", VEL_STOP, ["tbY"], 0.07)
	_c("q", "stop", false, "uvular", UVU_STOP, BODY, 0.085)
	_c("ɢ", "stop", true, "uvular", UVU_STOP, BODY, 0.075)
	_c("ʔ", "glottal", false, "glottal", {}, [], 0.06, {"glottal": "stop"})
	# nasals
	_c("m", "nasal", true, "bilabial", BILABIAL, LIPS, 0.075, nasal)
	_c("ɱ", "nasal", true, "labiodental", {"labiodental": 1.0, "lipAp": -0.1}, ["labiodental", "lipAp"], 0.075, nasal)
	_c("n", "nasal", true, "alveolar", ALV_STOP, TIP, 0.07, nasal)
	_c("ɳ", "nasal", true, "retroflex", RETRO_STOP, TIP_CURL, 0.07, nasal)
	_c("ɲ", "nasal", true, "palatal", PAL_STOP, BODY, 0.075, nasal)
	_c("ŋ", "nasal", true, "velar", VEL_STOP, ["tbY"], 0.08, nasal)
	_c("ɴ", "nasal", true, "uvular", UVU_STOP, BODY, 0.08, nasal)
	# fricatives
	_c("ɸ", "fricative", false, "bilabial", {"lipAp": 0.08}, LIPS, 0.11)
	_c("β", "fricative", true, "bilabial", {"lipAp": 0.1}, LIPS, 0.09)
	_c("f", "fricative", false, "labiodental", {"labiodental": 1.0, "lipAp": 0.05}, ["labiodental", "lipAp"], 0.11)
	_c("v", "fricative", true, "labiodental", {"labiodental": 1.0, "lipAp": 0.06}, ["labiodental", "lipAp"], 0.08)
	_c("θ", "fricative", false, "dental", {"ttX": 6.85, "ttY": 8.5}, TIP, 0.11)
	_c("ð", "fricative", true, "dental", {"ttX": 6.85, "ttY": 8.5}, TIP, 0.07)
	_c("s", "fricative", false, "alveolar", {"ttX": 6.3, "ttY": 9.15, "jaw": 0.3}, ["ttX", "ttY", "jaw"], 0.12)
	_c("z", "fricative", true, "alveolar", {"ttX": 6.3, "ttY": 9.15, "jaw": 0.3}, ["ttX", "ttY", "jaw"], 0.09)
	_c("ʃ", "fricative", false, "postalveolar", {"ttX": 5.7, "ttY": 9.5, "jaw": 0.35, "lipProt": 0.75, "lipWidth": 0.2}, ["ttX", "ttY", "jaw", "lipProt", "lipWidth"], 0.12)
	_c("ʒ", "fricative", true, "postalveolar", {"ttX": 5.7, "ttY": 9.5, "jaw": 0.35, "lipProt": 0.75, "lipWidth": 0.2}, ["ttX", "ttY", "jaw", "lipProt", "lipWidth"], 0.09)
	_c("ʂ", "fricative", false, "retroflex", {"ttX": 5.45, "ttY": 9.7, "ttCurl": 0.9}, TIP_CURL, 0.12)
	_c("ʐ", "fricative", true, "retroflex", {"ttX": 5.45, "ttY": 9.7, "ttCurl": 0.9}, TIP_CURL, 0.09)
	_c("ç", "fricative", false, "palatal", {"tbX": 3.75, "tbY": 8.25}, BODY, 0.12)
	_c("ʝ", "fricative", true, "palatal", {"tbX": 3.75, "tbY": 8.25}, BODY, 0.09)
	_c("x", "fricative", false, "velar", {"tbX": 2.3, "tbY": 7.7}, ["tbY"], 0.12)
	_c("ɣ", "fricative", true, "velar", {"tbX": 2.3, "tbY": 7.7}, ["tbY"], 0.09)
	_c("χ", "fricative", false, "uvular", {"tbX": 1.55, "tbY": 7.6}, BODY, 0.12)
	_c("ʁ", "fricative", true, "uvular", {"tbX": 1.55, "tbY": 7.6}, BODY, 0.09)
	_c("ħ", "fricative", false, "pharyngeal", {"root": -0.95, "tbX": 1.3, "tbY": 6.2}, ["root", "tbX", "tbY"], 0.12)
	_c("ʕ", "fricative", true, "pharyngeal", {"root": -0.95, "tbX": 1.3, "tbY": 6.2}, ["root", "tbX", "tbY"], 0.09)
	_c("h", "glottal", false, "glottal", {}, [], 0.09, {"glottal": "open"})
	_c("ɦ", "glottal", true, "glottal", {}, [], 0.08, {"glottal": "breathy"})
	_c("ɬ", "fricative", false, "alveolar", _merged(ALV_STOP, {"lateral": 0.35}), ["ttX", "ttY", "lateral"], 0.12)
	_c("ɮ", "fricative", true, "alveolar", _merged(ALV_STOP, {"lateral": 0.45}), ["ttX", "ttY", "lateral"], 0.09)
	# affricates
	_c("ts", "affricate", false, "alveolar", ALV_STOP, TIP, 0.14, {"release": "s"})
	_c("dz", "affricate", true, "alveolar", ALV_STOP, TIP, 0.12, {"release": "z"})
	_c("tʃ", "affricate", false, "postalveolar", _merged(POSTALV_STOP, {"lipProt": 0.75, "lipWidth": 0.2}), ["ttX", "ttY", "lipProt", "lipWidth"], 0.15, {"release": "ʃ"})
	_c("dʒ", "affricate", true, "postalveolar", _merged(POSTALV_STOP, {"lipProt": 0.75, "lipWidth": 0.2}), ["ttX", "ttY", "lipProt", "lipWidth"], 0.13, {"release": "ʒ"})
	_c("ɕ", "fricative", false, "alveolo-palatal", ALVPAL_FRIC, ["ttX", "ttY", "tbX", "tbY", "jaw", "lipProt", "lipWidth"], 0.12)
	_c("ʑ", "fricative", true, "alveolo-palatal", ALVPAL_FRIC, ["ttX", "ttY", "tbX", "tbY", "jaw", "lipProt", "lipWidth"], 0.09)
	_c("tɕ", "affricate", false, "alveolo-palatal", ALVPAL_STOP, ["ttX", "ttY", "tbX", "tbY", "lipProt", "lipWidth"], 0.14, {"release": "ɕ"})
	_c("dʑ", "affricate", true, "alveolo-palatal", ALVPAL_STOP, ["ttX", "ttY", "tbX", "tbY", "lipProt", "lipWidth"], 0.12, {"release": "ʑ"})
	_c("tʂ", "affricate", false, "retroflex", RETRO_STOP, TIP_CURL, 0.14, {"release": "ʂ"})
	_c("dʐ", "affricate", true, "retroflex", RETRO_STOP, TIP_CURL, 0.12, {"release": "ʐ"})
	_c("pf", "affricate", false, "labiodental", BILABIAL, LIPS, 0.14, {"release": "f"})
	# approximants, laterals, taps, trills
	_c("w", "approximant", true, "labial-velar", {"lipAp": 0.28, "lipProt": 1.0, "lipWidth": 0.05, "tbX": 2.45, "tbY": 7.45}, ["lipAp", "lipProt", "lipWidth", "tbX", "tbY"], 0.06)
	_c("ʋ", "approximant", true, "labiodental", {"labiodental": 0.9, "lipAp": 0.25}, ["labiodental", "lipAp"], 0.06)
	_c("ɹ", "approximant", true, "postalveolar", {"ttX": 5.35, "ttY": 9.35, "ttCurl": 0.85, "lipProt": 0.5, "lipWidth": 0.3, "root": -0.6, "tbX": 2.3, "tbY": 7.1}, ["ttX", "ttY", "ttCurl", "lipProt", "lipWidth", "root"], 0.065)
	_c("ɻ", "approximant", true, "retroflex", {"ttX": 5.4, "ttY": 9.55, "ttCurl": 1.0}, TIP_CURL, 0.065)
	_c("j", "approximant", true, "palatal", {"tbX": 3.8, "tbY": 7.95, "jaw": 0.25}, BODY, 0.055)
	_c("ɥ", "approximant", true, "labial-palatal", {"tbX": 3.8, "tbY": 7.95, "jaw": 0.25, "lipAp": 0.28, "lipProt": 1.0, "lipWidth": 0.05}, ["tbX", "tbY", "jaw", "lipAp", "lipProt", "lipWidth"], 0.055)
	_c("ɰ", "approximant", true, "velar", {"tbX": 2.35, "tbY": 7.45}, BODY, 0.06)
	_c("l", "lateral", true, "alveolar", _merged(ALV_STOP, {"lateral": 1.0}), ["ttX", "ttY", "lateral"], 0.065)
	_c("ɫ", "lateral", true, "alveolar", _merged(ALV_STOP, {"lateral": 1.0, "tbX": 1.9, "tbY": 6.8}), ["ttX", "ttY", "lateral", "tbX", "tbY"], 0.075)
	_c("ɭ", "lateral", true, "retroflex", _merged(RETRO_STOP, {"lateral": 1.0}), ["ttX", "ttY", "ttCurl", "lateral"], 0.065)
	_c("ʎ", "lateral", true, "palatal", _merged(PAL_STOP, {"lateral": 1.0}), ["tbX", "tbY", "lateral"], 0.07)
	_c("ɾ", "tap", true, "alveolar", ALV_STOP, TIP, 0.025)
	_c("ɽ", "tap", true, "retroflex", RETRO_STOP, TIP_CURL, 0.03)
	_c("r", "trill", true, "alveolar", {"ttX": 6.25, "ttY": 9.45}, TIP, 0.11)
	_c("ʀ", "trill", true, "uvular", {"tbX": 1.55, "tbY": 7.85}, BODY, 0.11)
	_c("ʙ", "trill", true, "bilabial", {"lipAp": 0.02}, LIPS, 0.12)


# ---------------------------------------------------------------- sounds

## A consonant's definition with the postures calibrated for a body, or null.
static func phoneme(ipa: String, body: String) -> Variant:
	init()
	if not _base.has(ipa): return null
	var def: Dictionary = (_base[ipa] as Dictionary).duplicate()
	var cal: Dictionary = _cal.get(body, {})
	if cal.has(ipa): def["targets"] = _merged(def.targets, cal[ipa])
	return def


static func expand(ipa: String) -> Array:
	return EXPAND.get(ipa, [])


static func is_vowel(ipa: String, body: String) -> bool:
	init()
	return (_vowels.get(body, {}) as Dictionary).has(ipa) or EXPAND.has(ipa)


## The calibrated posture of a vowel for a body, or null.
static func vowel_artic(ipa: String, body: String) -> Variant:
	init()
	var table: Dictionary = _vowels.get(body, {})
	var artic: Variant = table.get(ipa)
	if artic == null: artic = (_vowels.get("male", {}) as Dictionary).get(ipa)
	if artic == null: return null
	var out := {}
	for key in VOWEL_KEYS:
		if artic.has(key): out[key] = float(artic[key])
	# a rhotic's tip is raised and curled back, not resting behind the teeth
	if float(artic.get("ttCurl", 0.0)) > 0.05:
		if artic.has("ttX"): out["ttX"] = float(artic["ttX"])
		if artic.has("ttY"): out["ttY"] = float(artic["ttY"])
	return out


static func midi_to_hz(m: float) -> float:
	return 440.0 * pow(2.0, (m - 69.0) / 12.0)


static func _round(x: float) -> float:
	var r := floorf(x)
	return r + 1.0 if x - r >= 0.5 else r


static func _stress(s: Dictionary) -> int:
	return int(s["stress"]) if s.get("stress") != null else -1


static func _flag(s: Dictionary, key: String) -> bool:
	return s.get(key) != null and bool(s[key])


static func _g(t0: float, t1: float, ramp_in: float, ramp_out: float, strength: float, targets: Dictionary, label: String) -> Dictionary:
	return {"t0": t0, "t1": t1, "rampIn": ramp_in, "rampOut": ramp_out, "strength": strength, "targets": targets, "label": label}


static func _gesture_end(g: Dictionary) -> float:
	return float(g.t1) + float(g.rampOut) + (float(g.releaseHold) if g.get("releaseHold") != null else 0.0)


# ---------------------------------------------------------------- durations

static func _info(s: Dictionary, body: String) -> Dictionary:
	if is_vowel(str(s.ipa), body): return {"vowel": true}
	var d: Variant = phoneme(str(s.ipa), body)
	if d == null: return {"vowel": false, "voiced": false}
	return {"vowel": false, "manner": d.manner, "voiced": d.voiced, "dur": d.dur}


## Lengths (s) for one phrase of segments by Klatt's rules; a length a segment brings is kept.
static func klatt_durations(segs: Array, body: String) -> PackedFloat64Array:
	var infos: Array = []
	for s in segs: infos.append(_info(s, body))
	return klatt_durations_with(segs, infos)


static func klatt_durations_with(segs: Array, inf: Array) -> PackedFloat64Array:
	var n := segs.size()
	var word := PackedInt32Array()
	word.resize(n)
	var word_start := PackedInt32Array()
	for i in n:
		if i == 0 or _flag(segs[i - 1], "wordEnd"): word_start.append(i)
		word[i] = word_start.size() - 1
	var vowels_in_word := {}
	var last_vowel := -1
	for i in n:
		if bool(inf[i].get("vowel", false)):
			vowels_in_word[word[i]] = int(vowels_in_word.get(word[i], 0)) + 1
			last_vowel = i
	var out := PackedFloat64Array()
	for i in n:
		var s: Dictionary = segs[i]
		if s.get("dur") != null:
			out.append(float(s.dur))
			continue
		var fallback := float(inf[i]["dur"]) if inf[i].get("dur") != null else 0.08
		var row: Array = KLATT.get(str(s.ipa), [1000.0 * fallback, 600.0 * fallback])
		var inh: float = row[0]
		var least: float = row[1]
		var p := 1.0
		if bool(inf[i].get("vowel", false)):
			var stress := maxi(0, _stress(s))
			var final_syl := i == last_vowel
			var word_final_syl := true
			var k := i + 1
			while k < n and word[k] == word[i]:
				if bool(inf[k].get("vowel", false)): word_final_syl = false
				k += 1
			p *= 1.4 if final_syl else 0.6
			if not word_final_syl: p *= 0.85
			if int(vowels_in_word.get(word[i], 1)) > 1: p *= 0.8
			if stress == 0:
				least *= 0.5
				p *= 0.7
			if i + 1 < n and word[i + 1] == word[i] and not bool(inf[i + 1].get("vowel", false)):
				var nx: Dictionary = inf[i + 1]
				var voiced := nx.get("voiced") != null and bool(nx.voiced)
				var manner := str(nx.get("manner", ""))
				var f := 1.0
				if manner == "fricative": f = 1.6 if voiced else 1.0
				elif manner == "stop" or manner == "affricate": f = 1.2 if voiced else 0.7
				elif manner == "nasal": f = 0.85
				p *= f if final_syl else 0.7 + 0.3 * f
			if i + 1 < n and bool(inf[i + 1].get("vowel", false)): p *= 1.2
			if i > 0 and bool(inf[i - 1].get("vowel", false)): p *= 0.7
			var d := least + (inh - least) * p
			if stress > 0 and i > 0 and str(inf[i - 1].get("manner", "")) == "stop" and not (inf[i - 1].get("voiced") != null and bool(inf[i - 1].voiced)): d += 20.0
			out.append(d / 1000.0)
			continue
		var word_initial := i == word_start[word[i]]
		var manner_i := str(inf[i].get("manner", ""))
		if i > last_vowel and (manner_i == "nasal" or manner_i == "lateral" or manner_i == "approximant"): p *= 1.4
		if not word_initial: p *= 0.85
		var prev_c := i > 0 and not bool(inf[i - 1].get("vowel", false))
		var next_c := i + 1 < n and not bool(inf[i + 1].get("vowel", false))
		if prev_c and next_c: p *= 0.5
		elif prev_c or next_c: p *= 0.7
		out.append((least + (inh - least) * p) / 1000.0)
	return out


# ---------------------------------------------------------------- the planner

static func _all_in(list: Array, among: Array) -> bool:
	for k in list:
		if not among.has(k): return false
	return true


## The oral gestures of one consonant held from `a` (closure) to `b` (release): a strong one on the
## consonant's own articulators, a weak one on the rest. The articulators' delays are allowed for, so
## the closure and the release are heard at a and b.
static func oral_gestures(def: Dictionary, tg: Dictionary, a: float, b: float, speed: float, label: String, out: Array) -> void:
	var dominant: Array = def.dominant
	var dom := {}
	var sec := {}
	for key in KEY_ORDER:
		if not tg.has(key): continue
		if dominant.has(key): dom[key] = float(tg[key])
		else: sec[key] = float(tg[key])
	# the back of the tongue is heavy: it lets go more slowly than the tip and the lips
	var body_only := _all_in(dominant, ["tbX", "tbY", "root"])
	var sp := 1.0 + (speed - 1.0) * 0.35 if body_only else speed
	var manner := str(def.manner)
	var closing := manner == "stop" or manner == "nasal" or manner == "affricate"
	var lips_only := _all_in(dominant, ["lipAp", "labiodental"])
	var lead := 0.0
	var early := 0.008
	if closing:
		lead = 0.034 if body_only else (0.019 if lips_only else 0.02)
		early = 0.024 if body_only else (0.022 if lips_only else 0.031)
	if not dom.is_empty():
		var g := _g(a - early, maxf(a + 0.01, b - lead), 0.03, 0.03 if body_only else 0.018, 40.0, dom, label)
		g["speed"] = sp
		g["releaseHold"] = 0.045
		out.append(g)
	# alveolars bring the tongue's body forward during the closure
	if str(def.place) == "alveolar" and not tg.has("tbX") and (manner == "stop" or manner == "nasal" or manner == "fricative" or manner == "affricate" or manner == "tap"):
		out.append(_g(a, b, 0.05, 0.05, 1.2, {"tbX": 3.2, "tbY": 7.4}, label))
	if not sec.is_empty():
		# a velar's place front to back follows the vowel: its own tbX only weakly
		var has_place := body_only and sec.has("tbX")
		var place := float(sec["tbX"]) if has_place else 0.0
		if has_place: sec.erase("tbX")
		if not sec.is_empty(): out.append(_g(a, b, 0.05, 0.05, 2.2, sec, label))
		if has_place: out.append(_g(a, b, 0.05, 0.05, 0.25, {"tbX": place}, label))


static func _closes_in_front(front: String, back: String) -> bool:
	return PLACE_RANK.has(front) and PLACE_RANK.has(back) and int(PLACE_RANK[front]) < int(PLACE_RANK[back])


# Whether stop i closes behind the closure of the stop before it, its own articulators already placed
# by the consonant before that one (the t of "sharp tree").
static func _pre_placed(segs: Array, i: int) -> bool:
	if i < 1 or segs[i].def == null or segs[i - 1].def == null: return false
	var def: Dictionary = segs[i].def
	var prev: Dictionary = segs[i - 1].def
	if str(def.manner) != "stop" or str(prev.manner) != "stop" or not _closes_in_front(str(prev.place), str(def.place)) or i < 2: return false
	var before: Dictionary = segs[i - 2]
	var tg: Variant = null
	if before.def != null: tg = before.def.targets
	elif before.vowel != null and float(before.vowel.get("ttCurl", 0.0)) > 0.05: tg = before.vowel
	if tg == null: return false
	for k in def.dominant:
		if not tg.has(k): return false
	return true


static func _pitch_ramp(dur: float) -> float:
	return minf(0.06, maxf(0.008, 0.5 * dur))


static func _palatal_body(def: Dictionary, body: String) -> Variant:
	var j: Variant = phoneme("j", body)
	if j == null: return null
	var out := {}
	for k in ["tbX", "tbY"]:
		if not (def.dominant as Array).has(k) and j.targets.has(k): out[k] = float(j.targets[k])
	if out.is_empty() or str(def.place) == "palatal" or str(def.manner) == "glottal": return null
	return out


## A row of segments into gestures. Each segment: {ipa, dur?, stress?, f0?, wordEnd?, aspirated?, vot?,
## nasalized?, palatalized?, breathy?}. Options: {body, t0, rate?, f0?, intonation? ("statement",
## "question", "flat"), accent?, openEnd?, sung?}. Returns {gestures, segments, end}.
static func plan_utterance(input: Array, o: Dictionary) -> Dictionary:
	init()
	var rate := float(o["rate"]) if o.get("rate") != null else 1.0
	var body := str(o.get("body", "male"))
	var o_t0 := float(o.get("t0", 0.0))
	var durs := klatt_durations(input, body)
	var segs: Array = []
	for si in input.size():
		var s: Dictionary = input[si]
		var ipa := str(s.ipa)
		var f0_of := float(s["f0"]) if s.get("f0") != null else 0.0
		if is_nan(f0_of): f0_of = 0.0
		var parts := expand(ipa)
		if not parts.is_empty():
			var base := durs[si]
			for i in parts.size():
				var dur := base * (0.55 if i == 0 else 0.45) if parts.size() > 1 else base
				segs.append({"ipa": str(parts[i]), "dur": dur, "stress": _stress(s), "f0": f0_of, "def": null, "vowel": null, "glide": i > 0, "aspirated": null,
					"vot": null, "nasalized": _flag(s, "nasalized"), "palatalized": false, "breathy": _flag(s, "breathy")})
		else:
			segs.append({"ipa": ipa, "dur": durs[si], "stress": _stress(s), "f0": f0_of, "def": null, "vowel": null, "glide": false, "aspirated": s.get("aspirated"),
				"vot": s.get("vot"), "nasalized": _flag(s, "nasalized"), "palatalized": _flag(s, "palatalized"), "breathy": _flag(s, "breathy")})
	for s in segs:
		var v: Variant = vowel_artic(str(s.ipa), body)
		if v != null: s["vowel"] = v
		else: s["def"] = phoneme(str(s.ipa), body)
	var gestures: Array = []
	var planned: Array = []
	var t := o_t0 + 0.06
	var t0s := PackedFloat64Array()
	var t1s := PackedFloat64Array()
	for s in segs:
		var d := float(s.dur) / rate
		t0s.append(t)
		t1s.append(t + d)
		t += d
	var end := t
	var count := segs.size()
	# ---- vowels: they overlap their neighbours, so the tongue travels from vowel to vowel
	var v_idx := PackedInt32Array()
	for i in count:
		if segs[i].vowel != null: v_idx.append(i)
	for n in v_idx.size():
		var i := v_idx[n]
		var prev := t1s[v_idx[n - 1]] if n > 0 else t0s[i] - 0.08
		var next := t0s[v_idx[n + 1]] if n < v_idx.size() - 1 else t1s[i] + 0.08
		var r_in := maxf(0.03, 0.75 * (t0s[i] - prev)) + 0.01
		var r_out := maxf(0.03, 0.4 * (next - t1s[i])) + 0.01
		gestures.append(_g(t0s[i], t1s[i], r_in, r_out, 1.0, (segs[i].vowel as Dictionary).duplicate(), str(segs[i].ipa)))
	# ---- consonants
	for i in count:
		var s: Dictionary = segs[i]
		var t0 := t0s[i]
		var t1 := t1s[i]
		var dur := t1 - t0
		var row := {"ipa": str(s.ipa), "t0": t0, "t1": t1, "kind": "vowel" if s.vowel != null else (str(s.def.manner) if s.def != null else "?")}
		if s.vowel != null: row["stress"] = maxi(0, int(s.stress))
		planned.append(row)
		if s.vowel != null and not bool(s.glide):
			# what a vowel's marks hold for the whole vowel, through a diphthong's glide
			var last := i
			var j := i + 1
			while j < count and bool(segs[j].glide):
				last = j
				j += 1
			var until := t1s[last]
			if bool(s.nasalized): gestures.append(_g(t0, until, NASAL_VOWEL_RAMP, NASAL_VOWEL_RAMP, 4.0, {"velum": NASAL_VOWEL_PORT}, "velum"))
			if bool(s.breathy): gestures.append(_g(t0, until, 0.03, 0.03, 5.0, {"abduction": BREATHY_ABDUCTION}, "breathy"))
		if s.def == null: continue
		var def: Dictionary = s.def
		var manner := str(def.manner)
		var label := str(def.ipa)
		var next_vowel := i < count - 1 and segs[i + 1].vowel != null
		if manner == "stop" and _pre_placed(segs, i):
			oral_gestures(def, def.targets, t0 + minf(PLACED_CLOSURE_DELAY, maxf(0.0, dur - 0.03)), t1, 1.55, label, gestures)
		elif manner == "stop" or manner == "nasal":
			oral_gestures(def, def.targets, t0, t1, 1.55, label, gestures)
		elif manner == "tap":
			oral_gestures(def, def.targets, t0, t1, 2.8, label, gestures)
		elif manner == "trill":
			# a driven trill: near-closure and release in turn at about 26 Hz
			var beats := maxf(2.0, _round(dur * 26.0))
			var k := 0.0
			while k < beats:
				var a := t0 + (k / beats) * dur
				oral_gestures(def, def.targets, a, a + 0.35 / 26.0, 3.2, label, gestures)
				k += 1.0
		elif manner == "affricate":
			var split := t0 + dur * 0.55
			oral_gestures(def, def.targets, t0, split, 2.0, label, gestures)
			var rel: Variant = phoneme(str(def.release), body) if str(def.release) != "" else null
			if rel != null: oral_gestures(def, rel.targets, split + 0.008, t1, 1.4, label, gestures)
		elif manner == "fricative" or manner == "approximant" or manner == "lateral":
			oral_gestures(def, def.targets, t0, t1, 1.3, label, gestures)
		# nasality: the velum lowers a little early and seals again by the end of the nasal
		if bool(def.nasal): gestures.append(_g(t0 - 0.02, t1 - 0.02, 0.05, 0.03, 4.0, {"velum": 0.45}, "velum"))
		# phonation
		var voiced_again := t1
		var glottal := str(def.glottal)
		if glottal == "open":
			gestures.append(_g(t0 - 0.01, t1, 0.03, 0.035, 5.0, {"abduction": 0.33}, "h"))
		elif glottal == "breathy":
			gestures.append(_g(t0, t1, 0.03, 0.03, 5.0, {"abduction": 0.1}, "ɦ"))
		elif glottal == "stop":
			gestures.append(_g(t0, t1, 0.012, 0.015, 8.0, {"closure": 1.0}, "ʔ"))
		elif not bool(def.voiced):
			if manner == "stop" or manner == "affricate":
				# English's rule unless the segment says: aspirated before a vowel and not after s
				var aspirated := bool(s.aspirated) if s.aspirated != null else next_vowel and not (i > 0 and str(segs[i - 1].ipa) == "s")
				var past := 0.012 * 0.4
				if aspirated:
					past = DEFAULT_VOT / rate * 0.4 if s.vot == null else maxf(0.0, 0.4 * DEFAULT_VOT + float(s.vot) - DEFAULT_VOT) / rate
				var g := _g(t0 + 0.25 * dur, t1 + past, 0.035, 0.045 if aspirated else 0.02, 6.0, {"abduction": 0.36 if aspirated else 0.22}, "aspiration")
				voiced_again = _gesture_end(g)
				gestures.append(g)
			else:
				gestures.append(_g(t0 - 0.015, t1 + 0.005, 0.03, 0.03, 6.0, {"abduction": 0.3}, "voiceless"))
		elif manner == "fricative":
			gestures.append(_g(t0, t1, 0.03, 0.03, 3.0, {"abduction": 0.035}, "voiced frication"))
		if bool(s.breathy) and bool(def.voiced) and (manner == "stop" or manner == "affricate"):
			var until := minf(t1 + BREATHY_RELEASE, t1s[i + 1] if i + 1 < count else INF)
			gestures.append(_g(t1 - 0.02, until, 0.03, 0.03, 5.0, {"abduction": BREATHY_ABDUCTION}, "breathy"))
		if bool(s.palatalized):
			var tg: Variant = _palatal_body(def, body)
			if tg != null: gestures.append(_g(t0, voiced_again, PALATAL_RAMP, PALATAL_RAMP, PALATAL_STRENGTH, tg, "palatalized"))
	var open_end := _flag(o, "openEnd")
	var sung := _flag(o, "sung")
	# ---- breath: on through the phrase; a sung phrase's pressure is full as its first segment starts
	gestures.append(_g(o_t0 + (BREATH_SUNG_AT if sung else 0.04), end, 0.04, 0.07 if open_end else 0.05, 1.0, {"breath": 1.0}, "breath"))
	# ---- the end of the breath: the folds part as it stops, so a last consonant is let go into silence
	if not open_end:
		var sonorant := false
		if count > 0:
			var last: Dictionary = segs[count - 1]
			sonorant = last.vowel != null or (last.def != null and ["nasal", "approximant", "lateral", "tap", "trill"].has(str(last.def.manner)))
		var at := end + (0.045 if sonorant else 0.015)
		gestures.append(_g(at, end + 0.1, 0.03, 0.06, 6.0, {"abduction": 0.22}, "exhale"))
	# ---- pitch on the vowels
	var f0 := float(o["f0"]) if o.get("f0") != null else 110.0
	var accent := float(o["accent"]) if o.get("accent") != null else 0.14
	var total := maxf(0.2, end - o_t0)
	var intonation := str(o["intonation"]) if o.get("intonation") != null else ""
	var nuclear := -1
	for i in v_idx:
		if int(segs[i].stress) == 1 and not bool(segs[i].glide): nuclear = i
	for n in v_idx.size():
		var i := v_idx[n]
		var s: Dictionary = segs[i]
		var t0 := t0s[i]
		var t1 := t1s[i]
		# the pitch holds through the consonants up to the next vowel
		var hold := maxf(t1, t0s[v_idx[n + 1]] - 0.03) if n < v_idx.size() - 1 else t1
		var has_f0 := float(s.f0) != 0.0
		var target := float(s.f0)
		if not has_f0:
			var prog := (t0 - o_t0) / total
			var decl := 1.0 - 0.1 * prog
			var is_nuclear := i == nuclear
			var acc := 1.0
			if int(s.stress) == 1: acc = 1.0 + (accent * 1.8 if is_nuclear else accent)
			elif int(s.stress) == 2: acc = 1.0 + accent * 0.5
			target = f0 * decl * acc
			var is_last := n == v_idx.size() - 1
			if is_last and intonation == "question": target = f0 * 1.35
			if is_last and (intonation == "" or intonation == "statement"):
				if is_nuclear and t1 - t0 > 0.08:
					# the accent's peak early in the vowel, then the fall within it
					gestures.append(_g(t0, t0 + 0.35 * (t1 - t0), 0.05, 0.05, 1.0, {"f0": target}, "pitch"))
					gestures.append(_g(t0 + 0.55 * (t1 - t0), t1, 0.06, 0.06, 1.0, {"f0": f0 * 0.82}, "pitch"))
					continue
				target = f0 * 0.82
		var r := _pitch_ramp(t1 - t0) if has_f0 and sung else 0.06
		gestures.append(_g(t0, t1 if has_f0 else hold, r, r, 6.0 if has_f0 else 1.0, {"f0": target}, "pitch"))
	# sung: a consonant given its note's pitch holds it, so the pitch has arrived when the vowel starts
	if sung:
		for i in count:
			var s: Dictionary = segs[i]
			if s.vowel == null and float(s.f0) != 0.0:
				var r := _pitch_ramp(t1s[i] - t0s[i])
				gestures.append(_g(t0s[i], t1s[i], r, r, 6.0, {"f0": float(s.f0)}, "pitch"))
	if rate > 1.0:
		for g in gestures:
			if g.targets.has("f0") or g.targets.has("breath"): continue
			g["rampIn"] = float(g.rampIn) / rate
			g["rampOut"] = float(g.rampOut) / rate
			if g.get("releaseHold") != null: g["releaseHold"] = float(g.releaseHold) / rate
	return {"gestures": gestures, "segments": planned, "end": end}


## Phrases one after another from o.t0, each with its own breath and intonation.
static func plan_phrases(phrases: Array, o: Dictionary) -> Dictionary:
	var all := {"gestures": [], "segments": [], "end": float(o.get("t0", 0.0))}
	var t := float(o.get("t0", 0.0))
	for p in phrases:
		var options := o.duplicate()
		options["t0"] = t
		options["intonation"] = str(p["intonation"]) if p.get("intonation") != null else "statement"
		var plan := plan_utterance(p.segments, options)
		(all.gestures as Array).append_array(plan.gestures)
		(all.segments as Array).append_array(plan.segments)
		t = float(plan.end) + (float(p["pause"]) if p.get("pause") != null else 0.25)
		all["end"] = plan.end
	return all


# ---------------------------------------------------------------- singing

# sung consonants: a length the segment brings is its own, else the sound's spoken length times k
static func _consonants(segs: Array, body: String, k: float, hz: float) -> Array:
	var out: Array = []
	for c in segs:
		var d: Variant = phoneme(str(c.ipa), body)
		var seg := {"ipa": str(c.ipa), "dur": float(c["dur"]) if c.get("dur") != null else (float(d.dur) if d != null else 0.07) * k}
		for key in ["aspirated", "vot", "palatalized", "breathy"]:
			if c.get(key) != null: seg[key] = c[key]
		if hz > 0.0: seg["f0"] = hz
		out.append(seg)
	return out


static func _nucleus_part(ipa: String, dur: float, hz: float, nucleus: Dictionary) -> Dictionary:
	var seg := {"ipa": ipa, "dur": dur, "f0": hz, "stress": 1}
	for key in ["nasalized", "breathy"]:
		if nucleus.get(key) != null: seg[key] = nucleus[key]
	return seg


static func _total(segs: Array) -> float:
	var sum := 0.0
	for c in segs: sum += float(c["dur"]) if c.get("dur") != null else 0.0
	return sum


# Fit the consonants between a vowel and the next into `span`: when they leave the vowel less than
# MIN_VOWEL they shrink in proportion, so the next vowel still lands on its beat.
static func _fit(a: Array, b: Array, span: float) -> void:
	var cons := _total(a) + _total(b)
	var room := span - MIN_VOWEL
	if cons <= room or cons <= 0.0: return
	var scale := maxf(0.0, room) / cons
	for c in a: c["dur"] = maxf(MIN_CONSONANT, (float(c["dur"]) if c.get("dur") != null else 0.0) * scale)
	for c in b: c["dur"] = maxf(MIN_CONSONANT, (float(c["dur"]) if c.get("dur") != null else 0.0) * scale)


static func _vibrato(t0: float, t1: float, depth: float) -> Dictionary:
	return _g(t0 + 0.22, t1, 0.3, 0.06, 4.0, {"vibrato": depth}, "vibrato")


static func _melisma(syl: Dictionary) -> bool:
	return _flag(syl, "melisma")


static func _last_of_chain(notes: Array, k: int) -> Dictionary:
	var b := k
	while b > 0 and _melisma(notes[b].syl): b -= 1
	return notes[b].syl


## A whole melody: one utterance a phrase, so each phrase has its own breath. Notes: [{midi, beats,
## syl: {text, onset, nucleus, coda, melisma?, wordEnd, phraseEnd}}]. Options: {body, bpm, t0, vibrato}.
static func plan_song(notes: Array, o: Dictionary) -> Dictionary:
	init()
	var body := str(o.get("body", "male"))
	var beat := 60.0 / float(o.bpm)
	var depth := float(o.get("vibrato", 0.0))
	var gestures: Array = []
	var segments: Array = []
	var times := PackedFloat64Array()
	var t := float(o.t0)
	for n in notes:
		times.append(t)
		t += float(n.beats) * beat
	var end := t
	var count := notes.size()
	var i := 0
	while i < count:
		var j := i
		while j < count - 1 and not _flag(notes[j].syl, "phraseEnd"): j += 1
		var segs: Array = []
		var spans: Array = []
		var onsets: Array = []
		var codas: Array = []
		for k in range(i, j + 1):
			var hz := midi_to_hz(float(notes[k].midi))
			onsets.append([] if _melisma(notes[k].syl) else _consonants(notes[k].syl.onset, body, 0.8, hz))
			codas.append([] if k < j and _melisma(notes[k + 1].syl) else _consonants(_last_of_chain(notes, k).coda, body, 0.8, hz))
		# the phrase's last vowel leaves a short breath
		var reserve := 0.05 if j == count - 1 else 0.12
		var last_end := times[j] + float(notes[j].beats) * beat - minf(reserve, 0.3 * float(notes[j].beats) * beat)
		for k in range(i, j + 1):
			if k < j: _fit(codas[k - i], onsets[k + 1 - i], times[k + 1] - times[k])
			else: _fit(codas[k - i], [], last_end - times[k])
		var first_onset := _total(onsets[0])
		for k in range(i, j + 1):
			var n: Dictionary = notes[k]
			var hz := midi_to_hz(float(n.midi))
			var next_melisma := k < j and _melisma(notes[k + 1].syl)
			var coda: Array = codas[k - i]
			var note_end := times[k + 1] - _total(onsets[k + 1 - i]) if k < j else last_end
			var vdur := maxf(0.02, note_end - times[k] - _total(coda))
			segs.append_array(onsets[k - i])
			var nucleus: Dictionary = n.syl.nucleus
			var parts := expand(str(nucleus.ipa))
			if parts.size() == 2 and not next_melisma:
				segs.append(_nucleus_part(str(parts[0]), vdur * 0.8, hz, nucleus))
				segs.append(_nucleus_part(str(parts[1]), vdur * 0.2, hz, nucleus))
			else:
				segs.append(_nucleus_part(str(parts[0]) if parts.size() == 2 else str(nucleus.ipa), vdur, hz, nucleus))
			segs.append_array(coda)
			spans.append([times[k], times[k] + vdur])
		if not segs.is_empty():
			# the planner lays segments out from t0 + 0.06: start so that the first vowel lands on its beat
			var plan := plan_utterance(segs, {"body": body, "t0": times[i] - first_onset - 0.06, "f0": midi_to_hz(float(notes[i].midi)), "intonation": "flat", "sung": true})
			gestures.append_array(plan.gestures)
			segments.append_array(plan.segments)
			for span in spans:
				if float(span[1]) - float(span[0]) > 0.3: gestures.append(_vibrato(float(span[0]), float(span[1]), depth))
			end = maxf(end, float(plan.end))
		i = j + 1
	return {"gestures": gestures, "segments": segments, "end": end}


# what follows a held vowel: the diphthong's glide at the note's pitch, and the coda
static func _tail(syl: Dictionary, body: String, hz: float) -> Array:
	var out: Array = []
	var parts := expand(str(syl.nucleus.ipa))
	if parts.size() == 2: out.append(_nucleus_part(str(parts[1]), 0.07, hz, syl.nucleus))
	out.append_array(_consonants(syl.coda, body, 0.7, 0.0))
	return out


## A key pressed: the syllable's onset, then its vowel held open-ended. Every gesture gets `tag`, the
## pitch and vibrato `tag + 1`. Options: {body, vibrato, tag, legatoFrom? {syl, midi}}.
static func plan_note_on(syl: Dictionary, midi: float, o: Dictionary) -> Array:
	var body := str(o.get("body", "male"))
	var hz := midi_to_hz(midi)
	var tag := float(o.get("tag", 0.0))
	var segs: Array = []
	if o.get("legatoFrom") != null: segs.append_array(_tail(o.legatoFrom.syl, body, midi_to_hz(float(o.legatoFrom.midi))))
	segs.append_array(_consonants(syl.onset, body, 0.7, 0.0))
	var parts := expand(str(syl.nucleus.ipa))
	segs.append(_nucleus_part(str(parts[0]) if parts.size() == 2 else str(syl.nucleus.ipa), HOLD, hz, syl.nucleus))
	var plan := plan_utterance(segs, {"body": body, "t0": LIVE_T0, "f0": hz, "intonation": "flat", "openEnd": true})
	var vowel: Dictionary = plan.segments[plan.segments.size() - 1]
	var out: Array = []
	for g in plan.gestures:
		g["tag"] = tag + 1.0 if g.targets.has("f0") else tag
		out.append(g)
	var vib := _vibrato(float(vowel.t0), float(vowel.t1), float(o.get("vibrato", 0.0)))
	vib["tag"] = tag + 1.0
	out.append(vib)
	return out


## A held vowel moves to a new pitch (release tag + 1 first).
static func plan_melisma(midi: float, vibrato: float, tag: float) -> Array:
	var pitch := _g(0.0, HOLD, 0.05, 0.06, 6.0, {"f0": midi_to_hz(midi)}, "pitch")
	pitch["tag"] = tag + 1.0
	var vib := _vibrato(0.0, HOLD, vibrato)
	vib["tag"] = tag + 1.0
	return [pitch, vib]


## A key released: the diphthong's glide and the coda (release the note's tags first).
static func plan_note_off(syl: Dictionary, midi: float, body: String) -> Array:
	var hz := midi_to_hz(midi)
	var segs := _tail(syl, body, hz)
	if segs.is_empty(): return []
	return plan_utterance(segs, {"body": body, "t0": LIVE_T0, "f0": hz, "intonation": "flat"}).gestures


# ---------------------------------------------------------------- words

## A dictionary entry in ARPAbet ("F IY1 L") into segments with stress.
static func arpabet_to_segments(phones: String) -> Array:
	var out: Array = []
	for ph in phones.split(" ", false):
		var base := ph
		var stress := 0
		var last := ph.substr(ph.length() - 1)
		if last == "0" or last == "1" or last == "2":
			base = ph.substr(0, ph.length() - 1)
			stress = int(last)
		if not ARPA.has(base): continue
		var ipa := str(ARPA[base])
		if base == "AH" and stress == 0: ipa = "ə"
		if base == "ER" and stress == 0: ipa = "ɚ"
		out.append({"ipa": ipa, "stress": stress if G2P_VOWELS.has(ipa) else 0})
	return out


## One word's segments from a pronouncing dictionary {word: "ARPAbet"} (sung: nothing is reduced).
## Empty when the word is not in it.
static func word_segments(word: String, pronouncing: Dictionary) -> Array:
	var clean := word.to_lower().replace("’", "'").lstrip("'").rstrip("'")
	var entry := str(HOMOGRAPHS.get(clean, pronouncing.get(clean, "")))
	if entry != "": return arpabet_to_segments(entry)
	if clean.contains("-"):
		var out: Array = []
		for part in clean.split("-"): out.append_array(word_segments(part, pronouncing))
		return out
	return []


## One word's segments into syllables {onset, nucleus, coda}: of the consonants between two vowels, the
## longest run that can start an English syllable starts the second.
static func syllabify(segs: Array) -> Array:
	init()
	var vi := PackedInt32Array()
	for i in segs.size():
		if is_vowel(str(segs[i].ipa), "male"): vi.append(i)
	var out: Array = []
	var start := 0
	for n in vi.size():
		var v := vi[n]
		var until := segs.size()
		if n + 1 < vi.size():
			var next := vi[n + 1]
			var k := 0
			for length in range(next - v - 1, 0, -1):
				var cluster := ""
				for q in range(next - length, next): cluster += str(segs[q].ipa)
				if ONSETS.has(cluster):
					k = length
					break
			until = next - k
		out.append({"onset": segs.slice(start, v), "nucleus": segs[v], "coda": segs.slice(v + 1, until)})
		start = until
	return out


## The gestures for one phrase of a score (commons scores: voice_plan.syllables with unit "word:n", vowel,
## midi, gain, and voice_plan.frames at `rate`), as the kit's engine sings it: every vowel on its frame,
## consonants round it, a breath shaped over the phrase. Times count from `lead` seconds before the
## phrase's frame 0. Returns {gestures, lead, seconds, f0} or {error}.
static func plan_score_phrase(voice_plan: Dictionary, pronouncing: Dictionary, body: String, vibrato: float, rate := 44100.0) -> Dictionary:
	init()
	var syllables: Array = voice_plan.get("syllables", [])
	if syllables.is_empty(): return {"error": "no syllables"}
	var frames := float(voice_plan.frames)
	var lead := 0.25
	var by_word := {}
	var sung: Array = []
	var notes: Array = []
	for i in syllables.size():
		var syllable: Dictionary = syllables[i]
		var unit := str(syllable.get("unit", "")).split(":")
		if unit.size() != 2 or not unit[1].is_valid_int(): return {"error": "a syllable needs a word:n label"}
		var word := unit[0].to_lower().replace("’", "'")
		if not by_word.has(word):
			var segs := word_segments(word, pronouncing)
			if segs.is_empty(): return {"error": "no pronunciation for '%s'" % word}
			by_word[word] = syllabify(segs)
		var parts: Array = by_word[word]
		var index := int(unit[1])
		if index >= parts.size(): return {"error": "no syllable %d in '%s'" % [index, word]}
		var vowel := float(syllable.vowel)
		var finish := float(syllables[i + 1].vowel) if i + 1 < syllables.size() else frames
		var is_last := i + 1 == syllables.size()
		var part: Dictionary = parts[index]
		notes.append({"vowel": vowel, "end": finish, "gain": clampf(float(syllable.gain), 0.4, 1.2)})
		sung.append({"midi": float(syllable.midi), "beats": (finish - vowel + (rate / 20.0 if is_last else 0.0)) / rate,
			"syl": {"text": word, "onset": part.onset, "nucleus": part.nucleus, "coda": part.coda, "wordEnd": index + 1 == parts.size(), "phraseEnd": is_last}})
	var plan := plan_song(sung, {"body": body, "bpm": 60.0, "t0": lead + float(notes[0].vowel) / rate, "vibrato": vibrato})
	for seg in plan.segments:
		if float(seg.t0) < 0.0: return {"error": "the first consonants need more than the lead"}
	# a breath shaped over the phrase: strong words are given support, small words relax
	var gestures: Array = plan.gestures
	for i in notes.size():
		var progress := float(i) / float(maxi(notes.size(), 2) - 1)
		var pressure := (0.60 + 0.40 * float(notes[i].gain)) * (0.94 + 0.06 * sin(PI * progress))
		gestures.append(_g(lead + float(notes[i].vowel) / rate, lead + float(notes[i].end) / rate - 0.025, 0.055, 0.025, 8.0, {"breath": pressure}, "expression"))
	return {"gestures": gestures, "segments": plan.segments, "lead": lead, "seconds": lead + frames / rate + 0.5, "f0": midi_to_hz(float(syllables[0].midi))}
