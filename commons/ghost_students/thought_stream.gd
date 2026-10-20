extends Node3D
## Authored rehearsal cues, not a claim to a student's inner experience.
const HEAD_LAYER=preload("hologram.gd").HEAD_LAYER
var actor: Node3D
var cards: Array[Label3D]=[]
var entries: Array=[]

func setup(student: Node3D) -> void:
	actor=student
	for colour in [Color("a4ece7"),Color("e6d0ff"),Color("ffdc96")]:
		var card:=Label3D.new();card.font_size=26;card.pixel_size=0.002;card.outline_size=8
		card.modulate=colour;card.billboard=BaseMaterial3D.BILLBOARD_ENABLED;card.layers=HEAD_LAYER
		# These are annotations; a nearby wall must not erase half of a quotation.
		card.no_depth_test=true
		add_child(card);cards.append(card)

func show_entries(values: Array) -> void:
	entries=values.duplicate(true)
	for entry in entries:
		if entry.has("path"):
			entry.sha256=FileAccess.get_sha256(entry.path)
			entry.found=FileAccess.get_file_as_string(entry.path).contains(entry.text)
	for i in cards.size():
		cards[i].visible=i<entries.size()
		if i<entries.size(): cards[i].text=entries[i].role.to_upper()+"\n"+(wrap_words(entries[i].text) if entries[i].get("found",true) else "Source changed — review this cue.")

func _process(_delta: float) -> void:
	if not is_instance_valid(actor): return
	global_position=actor.head.global_position+Vector3.UP*0.38
	# Three small lines above the head; the observer can read them without covering
	# the apparatus. The eye camera excludes this annotation layer.
	for i in cards.size(): cards[i].position=Vector3(0,(2-i)*0.36,0)
	visible=actor.visible

func wrap_words(value: String) -> String:
	var result:="";var line:=""
	for word in value.replace("**","").split(" "):
		if line.length()+word.length()>48:
			result+=line+"\n";line=""
		line+=("" if line.is_empty() else " ")+word
	return result+line
