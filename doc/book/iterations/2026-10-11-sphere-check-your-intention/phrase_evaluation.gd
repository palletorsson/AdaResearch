extends RefCounted
## Visitor-declared intent is evaluation data; it never enters prediction or training.
const MAX_RECORDS := 120
const INTENTS := ["A", "B", "OTHER"]
const OUTCOMES := ["A", "B", "UNKNOWN", "AMBIGUOUS"]
var records: Array = []
var models: Dictionary = {}
var message := "Choose an intention before recording a fresh take."

static func digest(value: Variant) -> String:
	return JSON.stringify(value,"",true,true).sha256_text()

func record(model: RefCounted, take: Array, intent: String) -> Dictionary:
	if intent not in INTENTS: message="Choose A, B or OTHER before capturing.";return {}
	if not model.trained: message="Train both phrases before checking.";return {}
	if records.size()>=MAX_RECORDS: message="120 checks kept. EXPORT, then CLEAR to continue.";return {}
	var data: Dictionary = model.snapshot()
	var version := digest(data)
	var take_id := digest(take)
	for label in ["A","B"]:
		for example: Array in data[label].examples:
			if digest(example)==take_id: message="That exact take was teaching data. Record a fresh performance.";return {}
	for row: Dictionary in records:
		if row.model_id==version and row.take_id==take_id:
			message="That exact take is already counted for this model.";return {}
	# Only measured movement reaches the classifier. Intent is attached afterwards.
	var result: Dictionary = model.predict(take)
	if result.is_empty(): message="Incomplete or invalid take; nothing counted.";return {}
	var row := {"model_id":version,"take_id":take_id,"intent":intent,"result":result.duplicate(true),"take":take.duplicate(true)}
	models[version]=data.duplicate(true)
	records.append(row)
	message="Meant %s / model said %s. One whole take counted."%[intent,result.label]
	return row.duplicate(true)

func summary(model: RefCounted) -> Dictionary:
	var version := digest(model.snapshot())
	var matrix := [[0,0,0,0],[0,0,0,0],[0,0,0,0]]
	var count := 0
	for row: Dictionary in records:
		if row.model_id!=version: continue
		matrix[INTENTS.find(row.intent)][OUTCOMES.find(row.result.label)]+=1
		count+=1
	return {"matrix":matrix,"total":count,"previous":records.size()-count,"model_id":version}

func snapshot() -> Dictionary:
	return {"schema":"ada-phrase-checks-1","intent_labels":INTENTS,"result_labels":OUTCOMES,"models":models.duplicate(true),"records":records.duplicate(true),"scope":"Visitor-declared intent; repeated personal checks, not an independent accuracy estimate. No automatic training."}

func clear() -> void:
	records.clear();models.clear();message="Check history cleared. Teaching data and saved files remain."

func export_file(path: String) -> Error:
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file==null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify(snapshot(),"  ",true,true))
	return file.get_error()
