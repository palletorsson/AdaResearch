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
