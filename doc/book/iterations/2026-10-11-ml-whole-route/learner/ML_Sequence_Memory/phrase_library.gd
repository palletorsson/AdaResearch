extends RefCounted
## Two visitor-taught timed prototypes. Labels name examples, not dance quality.
const Learner := preload("movement_learner.gd")
const SCHEMA := "ada-two-hand-phrase-library-1"
const MARGIN := 0.20
var models: Dictionary = {"A": Learner.new(), "B": Learner.new()}
var tests: Array = []
var message := "Teach three whole takes of A and three of B."
var trained: bool:
	get: return models.A.trained and models.B.trained

func add_example(label: String, take: Array) -> bool:
	if not models.has(label): return false
	var kept: bool = models[label].add_example(take)
	message = label + " / " + models[label].message
	if kept: tests.clear()
	return kept

func undo(label: String) -> bool:
	if not models.has(label): return false
	var changed: bool = models[label].undo()
	message = label + " / " + models[label].message
	if changed: tests.clear()
	return changed

func fit() -> bool:
	tests.clear()
	var a: bool = models.A.fit()
	var b: bool = models.B.fit()
	if not a: message = "A / " + models.A.message
	elif not b: message = "B / " + models.B.message
	else: message = "A + B fitted. TEST a NEW whole performance."
	return a and b

func predict(take: Array) -> Dictionary:
	if not trained: return {}
	var a: Dictionary = models.A.predict(take)
	var b: Dictionary = models.B.predict(take)
	if a.is_empty() or b.is_empty(): return {}
	# Worst hand, relative to that prototype's limit. These are distances, not probabilities.
	var sa: float = maxf(a.rms[0]/models.A.limits[0], a.rms[1]/models.A.limits[1])
	var sb: float = maxf(b.rms[0]/models.B.limits[0], b.rms[1]/models.B.limits[1])
	var label := "UNKNOWN"
	if a.accepted and b.accepted:
		label = "AMBIGUOUS" if absf(sa-sb)<MARGIN else ("A" if sa<sb else "B")
	elif a.accepted: label = "A"
	elif b.accepted: label = "B"
	return {"label": label, "accepted": label in ["A", "B"], "scores": [sa,sb], "margin": absf(sa-sb), "candidates": {"A":a,"B":b}}

func test_example(take: Array) -> Dictionary:
	var result := predict(take)
	if result.is_empty(): return {}
	tests.append(result.duplicate(true))
	if tests.size()>60: tests.pop_front()
	return result

func snapshot() -> Dictionary:
	return {"schema":SCHEMA,"margin":MARGIN,"A":models.A.snapshot(),"B":models.B.snapshot()}

func restore(data: Variant) -> bool:
	if not data is Dictionary or data.get("schema")!=SCHEMA or data.get("margin")!=MARGIN: return false
	var a := Learner.new()
	var b := Learner.new()
	if not a.restore(data.get("A")) or not b.restore(data.get("B")): return false
	models={"A":a,"B":b};tests.clear();message="A + B loaded locally. Fresh tests begin here."
	return true

func save_file(path: String) -> Error:
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file==null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify(snapshot(),"  ",true,true))
	return file.get_error()

func load_file(path: String) -> bool:
	return restore(JSON.parse_string(FileAccess.get_file_as_string(path))) if FileAccess.file_exists(path) else false
