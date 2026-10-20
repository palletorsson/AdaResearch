# A derivation you can check

**Learning elements**

- Formal syntax
- axioms and rules
- proof checking
- bounded enumeration
- predictions and saved experiments

The installed sentence machine already says ILLUSTRATION — NOT PROOF SEARCH. Watch its timed arm, then build a working copy that actually checks a derivation. Bring the finite arrays and explicit conditions from Russell. The same sphere now marks the last candidate inspected; its position is an index, not a truth value. Moving it by hand does not change the calculus: release returns it to that index.

Our entire toy language is 0, S0, SS0, and so on. There is one axiom, 0, and one rule: from w append an S at the front to produce Sw. A proof is an ordered array beginning at 0, advancing by exactly that rule, and ending at the requested target. `verify` checks a supplied array without searching. `search` enumerates rule applications up to a declared budget. Budget 0 still examines the axiom. Budget 2 examines 0, S0 and SS0, so it misses SSS0. Budget 3 finds a proof that the checker accepts.

This deliberately simple system is decidable and does not encode arithmetic proofs or construct a Gödel sentence. The lesson teaches a distinction needed to read the room: a bounded miss cannot establish unprovability. The theorem concerns specified effective theories with sufficient arithmetic; the source linked below develops the argument. Nothing in a timer, a label or this toy enumeration substitutes for it.

MORE increases the budget to at most 8; TARGET switches between SSS0 and SSSSSS0. DAMAGE removes the second line of a copied candidate. It never alters the search result's stored array. RESET restores budget 2 and an undamaged candidate, retaining the selected target. The checker must reject a damaged chain even when its last line is the desired sentence.

## From a stored proof to a statement about proof

Our proof is already data: an array of strings. The checker receives that array and tests each step. It speaks about the proof from outside our tiny language, whose strings cannot themselves express “this is a proof.”

The bridge to Gödel is a stronger formal language. Finite strings and sequences can be encoded by natural numbers; an effective syntactic check on a proposed proof can then be represented by arithmetic relations. Sufficiently expressive arithmetic can state that a number encodes a proof of a formula. A fixed-point construction uses this capacity to produce a sentence about its own provability. Merely numbering our strings would not supply that construction or the theorem's hypotheses. Keep the small checker as preparation for this additional argument.

## Keep your own experiment

The second row asks about the next search budget: will its candidate pass the checker? PREDICT YES/NO stores the chosen inputs and your expectation without running that next search. TRY + KEEP runs it and appends the full record to `user://ada_foundations_trials_v1.json`. The expectation never enters `search` or `verify`. Up to eight steps are available here; RESET begins another run without clearing the journal. Changing the exploratory setup cancels a pending prediction. Ordinary MORE is exploration and does not save a run.

`trial_archive.gd` validates the file format, keeps earlier entries and writes a complete temporary file before replacing the journal. The record names `unary-derivation-v1` and the SHA-256 of the executed model source. The supplied museum launcher remains infrastructure; this new save/load code is printed below. The journal is local to this project's Godot user-data directory. Another device needs a copy of the file. It records this finite experiment, not a proof of incompleteness.


## Continue inside the museum

Use the existing AdaResearch project with Godot 4.6 and its installed XR Tools. Save these files together under `res://doc/book/studies/foundations-lineage/`. Carry `point_body.gd` and `line_skin.gd` unchanged from Euclid / Non-Euclidean Spaces. Their class construction and pickup were already printed there. Carry `bench.gd` unchanged from Russell. It supplies only geometry, labels, the visible sphere and button wiring; the rule below remains new.

Run the supplied `godel.tscn` in that folder with F6. Its `godel_museum.gd` launcher opens **Godel_Incompleteness** with the existing museum player, room and lighting, then adds your working copy beside the original exhibits. The launcher, `commons/interactables/push_button.tscn` and XR setup are declared infrastructure. No autoload, label, camera or other node is assumed inside your new script: the printed bench creates its own nodes and connects the buttons. This is a session study; it does not replace an installed artifact or carry a live node across hall loads.

The bench synchronizes an unheld frozen sphere on physics ticks. All model positions are local to the unit-scale bench unless a world transform is explicitly passed. Its slab and thin-cylinder lines are visual guides, not a new walkable floor. Use the museum's existing locomotion and pointer/grab controls.

## Complete new files

Read the rule first, then its museum display. There is one `_ready` per script; inherited `start` constructs the bench once. Save each block as the filename above it.

### `derivation.gd`

<!-- student-code:derivation.gd -->
```gdscript
extends RefCounted
# Toy syntax only: 0, S0, SS0, ... . Axiom 0; rule w -> Sw.
func well_formed(word: String) -> bool:
    if not word.ends_with("0"): return false
    return word.left(word.length()-1).replace("S", "").is_empty()

func verify(proof: Array, target: String) -> bool:
    if not well_formed(target) or proof.is_empty() or proof[0] != "0": return false
    for i in range(1, proof.size()):
        if not proof[i] is String or proof[i] != "S"+str(proof[i-1]): return false
    return proof[-1] == target

func search(target: String, budget: int) -> Dictionary:
    if not well_formed(target) or budget < 0 or budget > 32:
        return {"status":"INVALID INPUT", "proof":[], "examined":0}
    var proof: Array[String] = ["0"]
    for step in range(budget+1):
        if proof[-1] == target:
            return {"status":"CHECKED DERIVATION", "proof":proof, "examined":step+1}
        if step < budget: proof.append("S"+proof[-1])
    return {"status":"NOT FOUND WITHIN BUDGET", "proof":proof, "examined":budget+1}
```

### `trial_archive.gd`

<!-- student-code:trial_archive.gd -->
```gdscript
extends RefCounted
# One local journal. Prediction is recorded but never supplied to the search/checker.
const DEFAULT_PATH = "user://ada_foundations_trials_v1.json"
const MODEL_ID = "unary-derivation-v1"

func capture(model, target: String, budget: int, damage: bool, prediction: bool) -> Dictionary:
    var found: Dictionary = model.search(target, budget)
    var candidate: Array = found.proof.duplicate()
    if damage and candidate.size() > 1: candidate.remove_at(1)
    var accepted: bool = model.verify(candidate, target)
    return {"model_id":MODEL_ID,
        "model_sha256":FileAccess.get_sha256(model.get_script().resource_path),
        "saved_at":Time.get_datetime_string_from_system(true)+"Z",
        "target":target, "budget":budget, "damage":damage,
        "prediction":prediction, "search_result":found.duplicate(true),
        "candidate":candidate, "accepted":accepted,
        "prediction_matched":prediction == accepted}

func whole(value, low: int, high: int) -> bool:
    return (value is int or value is float) and is_finite(float(value)) and value == int(value) and value >= low and value <= high

func words(value) -> bool:
    if not value is Array or value.size() > 33: return false
    for word in value:
        if not word is String or word.length() > 33: return false
    return true

func valid(entry) -> bool:
    if not entry is Dictionary: return false
    for key in ["model_id", "model_sha256", "saved_at", "target", "budget", "damage",
            "prediction", "search_result", "candidate", "accepted", "prediction_matched"]:
        if not entry.has(key): return false
    if entry.model_id != MODEL_ID: return false
    if not entry.model_sha256 is String or entry.model_sha256.length() != 64 or not entry.model_sha256.is_valid_hex_number(false): return false
    if not entry.saved_at is String or not entry.target is String: return false
    if entry.target.length() > 33 or not entry.target.ends_with("0") or not entry.target.left(-1).replace("S", "").is_empty(): return false
    if not whole(entry.budget, 0, 32) or not words(entry.candidate): return false
    for key in ["damage", "prediction", "accepted", "prediction_matched"]:
        if not entry[key] is bool: return false
    var result = entry.search_result
    if not result is Dictionary or not result.has_all(["status", "proof", "examined"]): return false
    if result.status not in ["CHECKED DERIVATION", "NOT FOUND WITHIN BUDGET"]: return false
    if not words(result.proof) or not whole(result.examined, 1, 33): return false
    return entry.prediction_matched == (entry.prediction == entry.accepted)

func read(path: String = DEFAULT_PATH) -> Dictionary:
    if not FileAccess.file_exists(path): return {"ok":true, "entries":[], "message":"No saved experiment yet. Visit the Godel study."}
    var file = FileAccess.open(path, FileAccess.READ)
    if file == null: return {"ok":false, "entries":[], "message":"Cannot read the journal."}
    var parser := JSON.new()
    var error := parser.parse(file.get_as_text())
    file.close()
    if error != OK: return {"ok":false, "entries":[], "message":"Journal is not valid JSON; kept unchanged."}
    var data = parser.data
    if not data is Dictionary or not data.has_all(["schema", "entries"]) or data.schema != 1 or not data.entries is Array:
        return {"ok":false, "entries":[], "message":"Unknown journal format; kept unchanged."}
    for entry in data.entries:
        if not valid(entry): return {"ok":false, "entries":[], "message":"Invalid experiment record; kept unchanged."}
        # JSON numbers load as floats. Restore the declared integer fields.
        entry.budget = int(entry.budget)
        entry.search_result.examined = int(entry.search_result.examined)
    return {"ok":true, "entries":data.entries.duplicate(true), "message":"Read %d saved experiments." % data.entries.size()}

func append(entry: Dictionary, path: String = DEFAULT_PATH) -> Dictionary:
    if not valid(entry): return {"ok":false, "message":"Experiment record refused."}
    var previous := read(path)
    if not previous.ok: return previous
    var entries: Array = previous.entries
    entries.append(entry.duplicate(true))
    # Replace only after a complete temporary file has been written successfully.
    var temporary := path + ".tmp"
    var file = FileAccess.open(temporary, FileAccess.WRITE)
    if file == null: return {"ok":false, "message":"Cannot open journal for writing."}
    file.store_string(JSON.stringify({"schema":1, "entries":entries}, "  "))
    file.flush()
    var error := file.get_error()
    file.close()
    if error == OK:
        error = DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path))
    if error != OK: return {"ok":false, "message":"Save failed; previous journal kept."}
    return {"ok":true, "message":"Kept experiment %d, including its prediction." % entries.size()}
```

### `godel_study.gd`

<!-- student-code:godel_study.gd -->
```gdscript
extends "bench.gd"
const Derivation = preload("derivation.gd")
const TrialArchive = preload("trial_archive.gd")
var model := Derivation.new()
var archive := TrialArchive.new()
var journal_path := TrialArchive.DEFAULT_PATH
var pending: Dictionary = {}
var journal_label: Label3D
var journal_message := "Predict the next budget, then TRY + KEEP."
var target := "SSS0"
var budget := 2
var result: Dictionary = {}
var damaged := false

func _ready() -> void:
    start("GODEL / CHECKING IS NOT SEARCHING", ["MORE", "TARGET", "DAMAGE", "RESET"],
        [more, next_target, damage, reset])
    block(self, Vector3(0, 0.84, 1.15), Vector3(2.5, 0.08, 0.55), Color("d3ccc1"))
    var words := ["PREDICT YES", "PREDICT NO", "TRY + KEEP"]
    var actions := [predict.bind(true), predict.bind(false), run_trial]
    for i in 3:
        var button = PushButton.instantiate()
        button.position = Vector3((i-1)*0.8, 0.92, 1.15)
        add_child(button)
        button.pressed.connect(actions[i])
        buttons.append(button)
        label(self, words[i], button.position+Vector3.UP*0.12, 16)
    journal_label = label(self, "", Vector3(0, 1.69, -0.8), 22)
    refresh()

func cancel_prediction() -> void:
    pending.clear()
    journal_message = "Setup changed. Predict before TRY + KEEP."

func predict(accepted: bool) -> void:
    if point.held(): return
    if budget >= 8:
        journal_message = "RESET first: the next budget would exceed 8."
    else:
        pending = {"target":target, "budget":budget+1, "damage":damaged, "prediction":accepted}
        journal_message = "Next budget %d; checker accepts? %s\nTRY + KEEP will run and retain this prediction." % [budget+1, "YES" if accepted else "NO"]
    refresh()

func run_trial() -> void:
    if point.held(): return
    if pending.is_empty():
        journal_message = "Choose PREDICT YES or NO before running."
    else:
        var entry := archive.capture(model, pending.target, pending.budget, pending.damage, pending.prediction)
        var saved := archive.append(entry, journal_path)
        budget = pending.budget
        journal_message = "%s\nPredicted %s; accepted %s. %s" % [saved.message,
            str(entry.prediction), str(entry.accepted), "MATCH" if entry.prediction_matched else "DID NOT MATCH"]
        pending.clear()
    refresh()

func more() -> void:
    if point.held(): return
    cancel_prediction()
    budget = mini(8, budget+1)
    damaged = false
    refresh()

func next_target() -> void:
    if point.held(): return
    cancel_prediction()
    target = "SSSSSS0" if target=="SSS0" else "SSS0"
    damaged = false
    refresh()

func damage() -> void:
    if point.held(): return
    cancel_prediction()
    damaged = not damaged
    refresh()

func reset() -> void:
    if point.held(): return
    cancel_prediction()
    budget = 2
    damaged = false
    refresh()

func refresh() -> void:
    result = model.search(target, budget)
    var candidate: Array = result.proof.duplicate()
    if damaged and candidate.size()>1: candidate.remove_at(1)
    clear_drawing()
    for i in candidate.size():
        var at := Vector3(-1.12+i*0.28, 1.05+i*0.035, 0)
        block(drawing, at, Vector3(0.23, 0.08, 0.35), Color("94aeba"))
        label(drawing, str(i), at+Vector3(0, 0.12, 0.2), 19)
    point_home = Vector3(-1.12+(candidate.size()-1)*0.28, 1.27+(candidate.size()-1)*0.035, 0)
    readout.text = "Target %s | at most %d rule steps\n%s\nCandidate checks: %s%s" % [
        target, budget, result.status, str(model.verify(candidate, target)),
        " (step removed)" if damaged else ""]
    journal_label.text = journal_message
```

## Predict, build, check

Before running, predict: SSSSSS0 is missed at budget 5 and found at 6. Check the returned array with `verify`. Remove S0 from a valid proof: reaching the target is insufficient when the intermediate inference is invalid. Supply X or 00: syntax validation refuses them, which differs from a bounded miss on a well-formed target.

Write down one claim our test can refute: “not found within two steps means unprovable.” The budget-3 run is its concrete counterexample. Do not replace it with the opposite overclaim that every proof system is this easy. The next hall changes medium: a closed spatial route has a directly checkable height invariant.

Reference: [Olivier Bournez, Incompleteness of arithmetic](https://www.enseignement.polytechnique.fr/informatique/INF412/uploads/Main/chap10english-goodINF412ENGLISH.pdf). Our unary study is an original teaching construction, not that theorem's proof.

For your carried experiment, RESET at target SSS0. Predict whether the checker will accept a candidate at the **next** budget, 3. Press PREDICT YES or PREDICT NO, then TRY + KEEP. The prediction is fixed before that run. Compare it with the accepted result. Keep a mistaken prediction as it was. Repeat with DAMAGE enabled or target SSSSSS0; earlier entries remain.

Leave the study and open Synthesis. Its first personal card must contain your target, budget, damage setting, prediction, candidate and outcome. Returning to RESET never erases the journal. If the journal cannot be read or saved, the display says so; a missing record is not replaced with an invented personal experiment.


The automated reconstruction tests extract the printed files, add only these declared carried dependencies and run native Godot assertions. They use synthetic interaction. They do not establish human learning or headset reach.
