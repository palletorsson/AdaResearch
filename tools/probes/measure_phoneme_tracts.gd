extends SceneTree
## Measure the female Airway model at the calibrated vowel postures.
## godot --headless --path . --script res://tools/probes/measure_phoneme_tracts.gd -- <output.json>

const Airway := preload("res://audio/airway/human_airway.gd")
const Phonetics := preload("res://audio/airway/phonetics.gd")
const Tract := preload("res://audio/airway/human_tract.gd")
const BODY := "female"
const RATE := 88200.0
const SAMPLES := 3072


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		push_error("Pass the output JSON path after --.")
		quit(1)
		return
	var calibrated: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Phonetics.TABLES))
	var responses := {}
	for ipa in calibrated.vowels[BODY]:
		var posture := PackedFloat64Array(Tract.NEUTRAL)
		var target: Dictionary = Phonetics.vowel_artic(ipa, BODY)
		for name in target:
			posture[Tract.NAMES.find(name)] = target[name]
		var airway := Airway.new(RATE, BODY)
		airway.apply(posture, 0.0)
		airway.net.snap_to_targets()
		airway.settle()
		airway.net.use_ext_flow = true
		airway.net.ext_flow[airway.net.first_node(airway.pharynx)] = 0.01
		var response := PackedFloat64Array()
		response.resize(SAMPLES)
		for sample in SAMPLES:
			response[sample] = airway.net.step()
			if not is_finite(response[sample]):
				push_error("Non-finite airway output for " + ipa)
				quit(1)
				return
		responses[ipa] = Array(response)
	var file := FileAccess.open(args[0], FileAccess.WRITE)
	if file == null:
		push_error("Cannot write " + args[0])
		quit(1)
		return
	file.store_string(JSON.stringify({"body": BODY, "rate": RATE, "responses": responses}))
	print("[phoneme_tracts] measured %d postures" % responses.size())
	quit()
