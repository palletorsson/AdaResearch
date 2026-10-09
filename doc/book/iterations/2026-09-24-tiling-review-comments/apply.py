from pathlib import Path
import json
r=Path.cwd();o=r/'doc/book/iterations/2026-09-24-tiling-review-comments'
def edit(m,old,new):
 p=r/'commons/maps'/m/'final.md';s=p.read_text(encoding='utf-8-sig');assert s.count(old)==1,(m,old[:80]);p.write_text(s.replace(old,new),encoding='utf-8')
titles={'Pattern_Disco':'The same floor, another palette','Pattern_Foundry':'One decision, many surfaces','Tutorial_Pattern':'The mark and its return','Array_Patterns':'An address needs a surface','Symmetry_Seventeen':'What counts as the same?','Ribbon_Patterns_01':'A mark acquires an inside','Ribbon_Patterns_02':'The carrier participates','Ribbon_Patterns_03':'What can you take with you?'}
for m,title in titles.items():
 p=r/'commons/maps'/m/'final.md';s=p.read_text(encoding='utf-8-sig');assert not s.startswith('# ');p.write_text('# '+title+'\n\n'+s,encoding='utf-8')
edit('Pattern_Disco','Before Colour, black and white made a checker, a travelling row, diagonal bands and a snaking passage through the cells.','Before Colour, black and white made a checker, a travelling row, diagonal bands, a snaking passage and the turning combinations of SUPER TRIANGLE.')
edit('Pattern_Disco','two values, four arrangements, four palettes.','two values, five pattern modes, four palettes.')
# Move the actual first-visit studio passage to where the chapter sends the reader.
p=r/'commons/maps/Pattern_Foundry/final.md';s=p.read_text(encoding='utf-8');start=s.index('Take the passage into the runway annex');end=s.index('\n\n<!-- @ -->',start);studio=s[start:end].strip();s=s[:start]+s[end:]
old='For a first visit, link the curve again and continue to the studio in the runway annex, where the third pass begins. When you return to the loom, the following experiments ask what a saved source remembers, and which receivers accept a change in spacing or position.'
assert s.count(old)==1
s=s.replace(old,'For a first visit, link the curve again and continue to the studio in the runway annex, where the third pass begins.\n\n'+studio+'\n\nOn a return visit, the loom has more to show. The following experiments ask what a saved source remembers, and which receivers accept a change in spacing or position.')
s=s.replace('\n\n\n\n<!-- @ -->','\n\n<!-- @ -->');p.write_text(s,encoding='utf-8')
edit('Tutorial_Pattern','Here, take the opening into the side bay.','Here, pass the patterned plates in the main room and take the opening in the east wall into the side bay.')
edit('Ribbon_Patterns_01','Begin with the low array.','The two grids near the entrance begin this study. The bars, shelves and sorting race further along the hall offer other ways to revisit arrays; start here with the low array.')
edit('Ribbon_Patterns_02','Press **SURROUNDS** to give both targets the same grey background. Then return to the unequal backgrounds and press **CONNECT**.','Press **SURROUNDS** to give both targets the same grey background. Seen straight on, the squares lose their edges in the surrounding grey. They are still there; the contrast that picked them out has gone. Return to the unequal backgrounds and press **CONNECT**.')
p=r/'commons/maps/Ribbon_Patterns_02/final.md';s=p.read_text(encoding='utf-8');start=s.index('The archived name of this artifact');end=s.index('\n\n',start);s=s[:start]+s[end+2:];p.write_text(s,encoding='utf-8')
edit('Ribbon_Patterns_03','Change your look at the mirror. The skirt keeps the recipe.','Use **NEXT** or **PREVIOUS** at the mirror to change your look. The new skirt receives the saved recipe. **WALK DRESS** returns to your walking costume; the recipe waits in the wardrobe until you choose a skirted look again.')
edit('Ribbon_Patterns_03','The performers have been moving while we worked. In **Change_Intro**, we will ask a question that a saved appearance cannot answer: how much is changing, and how quickly, here? The fabric can come with us. A clock might do more than ease a new hem into place. What happens when the change itself keeps going?','We have followed one mark as its address, surroundings and carrier changed. In **Change_Intro**, a curve waits for us. Read its height at two places and join them with a line. The line can slope down while the curve beside your first reading rises. How far should we look before saying which way something is changing?')
edit('Symmetry_Seventeen','A fivefold-looking flower can sit inside a repeating cell.','The other machines give these names somewhere else to work. Compare a loom or mill with the framed samples: can you find a repeated turn or reversal before reading its group label? The patterned wall gallery carries selected rules across the architecture. Its changing colours and motifs can make the operation harder to recognise than our small, deliberately awkward mark.\n\nAt the atlas plates, read the makers’ names as well as the patterns. A symmetry group can describe a relation between marks without describing the work, place or history that brought them together. Carry both kinds of attention through the gallery.\n\nA fivefold-looking flower can sit inside a repeating cell.')
# Only this placement opts out of player targeting. Existing turret defaults remain.
p=r/'commons/maps/Ribbon_Patterns_03/map_data.json';s=p.read_text(encoding='utf-8-sig');old='laser_turret#pin:1#plinth:0';assert s.count(old)==1;p.write_text(s.replace(old,'laser_turret#target_player:false#pin:1#plinth:0'),encoding='utf-8')
p=r/'commons/artifacts/turret_targeting/laser_turret.gd';s=p.read_text(encoding='utf-8-sig');needle='func _ready() -> void:';assert s.count(needle)==1
patch='''# Placements can retain ball hunting without making the visitor a target.
# Configuration may arrive before _ready or while a target is already locked.
func apply_grid_config(config: Dictionary) -> void:
	if not config.has("target_player"):
		return
	match str(config["target_player"]).strip_edges().to_lower():
		"true", "1": target_player = true
		"false", "0": target_player = false
		_: return
	if not target_player and is_inside_tree() and is_instance_valid(current_target):
		if current_target == _find_player():
			_lose_target()

'''
p.write_text(s.replace(needle,patch+needle),encoding='utf-8')
print('Eight focused manuscript edits; studio moved intact; one turret placement opts out of player targeting.')
