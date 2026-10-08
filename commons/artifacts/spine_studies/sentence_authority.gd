extends "res://commons/artifacts/spine_studies/study_forms.gd"
## Original Ada sentences. Changing a display cannot establish a proposition.
const SENTENCES := ["YOU MAY REMAIN HERE", "THIS IS THE WHOLE ACCOUNT", "THE MODEL NEEDS YOUR CONSENT"]
var sentence := 0
var seconds_per_word := 0.85
var elapsed := 0.0
var paused := false
var whole_strip := false
var small: Label3D
var strip: Label3D
var wall: Label3D
var footer: Label3D

func _ready() -> void:
	block(Vector3(0,3.25,-4.3),Vector3(14,6.5,0.18),Color("e6e1d9"),true)
	block(Vector3(0,5.45,-3.65),Vector3(13.3,0.78,0.20),Color("15141b"),true)
	for x in [-6.8,6.8]: block(Vector3(x,2.7,-3.65),Vector3(0.065,5.4,0.065),Color("64616a"),true)
	strip = inscription("",Vector3(0,5.45,-3.53),0.009,Color("ff669a"))
	wall = inscription("",Vector3(0,3.1,-4.18),0.016,Color("842e53"))
	block(Vector3(-3.4,1.35,1.2),Vector3(1.85,0.55,0.10),Color("efece5"),true)
	block(Vector3(-3.4,0.55,1.16),Vector3(0.045,1.1,0.06),Color("64616a"),true)
	small = inscription("",Vector3(-3.4,1.42,1.26),0.00145)
	inscription("Ada / original sentence",Vector3(-3.4,1.20,1.26),0.00095)
	footer = inscription("",Vector3(0,0.65,-4.17),0.0034)
	refresh()

func refresh() -> void:
	var words: PackedStringArray = SENTENCES[sentence].split(" ")
	small.text = SENTENCES[sentence]
	wall.text = SENTENCES[sentence].replace(" ","\n") if sentence == 0 else SENTENCES[sentence].replace("THE ","THE\n").replace("YOUR ","YOUR\n")
	strip.text = SENTENCES[sentence] if whole_strip else words[int(elapsed/seconds_per_word)%words.size()]
	footer.text = "ONE SENTENCE / LABEL · STRIP · WALL\n%.2f s per word / %s / original Ada text" % [seconds_per_word,"HELD" if paused else "RUNNING"]

func _process(delta: float) -> void:
	if not paused: elapsed += delta
	refresh()

func control(index: int) -> void:
	match index:
		0: sentence = (sentence+1)%SENTENCES.size(); elapsed = 0.0
		1: seconds_per_word = 1.7 if seconds_per_word < 1.0 else 0.85
		2: paused = not paused
		3: whole_strip = not whole_strip
		_: sentence = 0; seconds_per_word = 0.85; elapsed = 0.0; paused = false; whole_strip = false
	refresh()
