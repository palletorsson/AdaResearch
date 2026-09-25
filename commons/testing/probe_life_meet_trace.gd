extends SceneTree
## Readback for two claims the CA_BeyondBinary chapter makes after the Nature of Code
## reading (2026-09-25): MEET empties within six generations and only lamp A ever
## lights (task book_cellularautomata.002); TRACE counts the wake - born + died == changed
## after a step, and a replay shows no births.
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_life_meet_trace.gd

const OUT := "C:/Users/palle/AppData/Local/Temp/claude/C--Users-palle-Documents-GitHub-AdaResearch-46/8987ca3e-a19b-46d1-b00a-85888e1b0458/scratchpad/life_meet_trace.txt"
var _lines: PackedStringArray = []

func _init() -> void:
	await process_frame
	var packed: PackedScene = load("res://commons/artifacts/game_of_life_petri/game_of_life_petri.tscn")
	var inst: Node3D = packed.instantiate()
	inst.apply_grid_config({"study": "addresses"})  # the museum configures before _ready
	root.add_child(inst)
	await create_timer(0.5).timeout
	var study: Node = inst.get_node_or_null("AddressStudy")
	if study == null:
		_say("[probe] FAIL: no AddressStudy mounted")
		_finish()
		return
	# --- MEET: populations per generation, lamps ---
	study.choose_meeting()
	var pops: Array = []
	var lit_ever := {"A": false, "B": false, "C": false}
	var empty_at := -1
	for g in range(0, 25):
		var rb: Dictionary = study.readback()
		pops.append(int(rb["population"]))
		var letters := ["A", "B", "C"]
		for i in range(rb["receivers"].size()):
			if bool(rb["receivers"][i]["occupied"]):
				lit_ever[letters[i]] = true
		if int(rb["population"]) == 0:
			empty_at = int(rb["generation"])
			break
		study.step_once()
	study.choose_meeting()
	var a_at_replay: bool = bool(study.readback()["receivers"][0]["occupied"])
	var meet_ok: bool = empty_at >= 0 and empty_at <= 6 and bool(lit_ever["A"]) and not bool(lit_ever["B"]) and not bool(lit_ever["C"]) and a_at_replay
	_say("[probe] MEET populations gen 0..: %s | empty at gen %d | lamps ever occupied A=%s B=%s C=%s | A occupied at replay=%s | %s" % [
		str(pops), empty_at, lit_ever["A"], lit_ever["B"], lit_ever["C"], a_at_replay, "PASS" if meet_ok else "FAIL"])
	# --- TRACE on the glider ---
	study.choose_glider()
	study.toggle_trace()
	var rb0: Dictionary = study.readback()
	var replay_clean: bool = int(rb0["born"]) == 0 and int(rb0["died"]) == 0 and bool(rb0["trace"])
	study.step_once()
	var rb1: Dictionary = study.readback()
	var b: int = int(rb1["born"]); var d: int = int(rb1["died"]); var c: int = int(rb1["changed"])
	# read the floor and dish colours back from the model's own bookkeeping: count the marked cells
	var trace_ok: bool = replay_clean and c > 0 and b + d == c and int(rb1["population"]) == 5
	_say("[probe] TRACE glider: replay born/died %d/%d trace=%s | after one step born %d died %d changed %d pop %d | %s" % [
		int(rb0["born"]), int(rb0["died"]), bool(rb0["trace"]), b, d, c, int(rb1["population"]), "PASS" if trace_ok else "FAIL"])
	study.toggle_trace()
	_say("[probe] trace off again: %s | readout line: %s" % [not bool(study.readback()["trace"]), study.reading.text.replace("\n", " | ")])
	_finish()

func _say(msg: String) -> void:
	print(msg)
	_lines.append(msg)

func _finish() -> void:
	_say("[probe] done")
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	if f:
		f.store_string("\n".join(_lines))
		f.close()
	quit()
