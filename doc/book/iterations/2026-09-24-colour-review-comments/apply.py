from pathlib import Path
import json
r=Path.cwd();o=r/'doc/book/iterations/2026-09-24-colour-review-comments';changed=[]
def edit(rel,pairs):
 p=r/rel;s=p.read_text(encoding='utf-8-sig')
 for a,b in pairs:
  assert s.count(a)==1,(rel,a);s=s.replace(a,b)
 p.write_text(s,encoding='utf-8');changed.append(rel)
edit('commons/maps/Color_Context_Placed/final.md',[
("The columns grow taller. White, red, blue and yellow blocks separated by thin dark levels carry the gallery's reference to Mondrian. Four diminishing blocks in warm colours come from its Albers study. Pink and teal enter the Memphis stack; eight pieces gather into the taller Bauhaus study. These are composed adaptations of references. You can inspect their proportions and colour choices even if the names are new to you.","Four taller columns carry their names on their plates. Each plate says what its column borrows; the shapes and colours are there to inspect even when the name is new."),
('here, yellow helps us recognise a relation someone has chosen to make.','here, yellow helps us recognise a relation someone has chosen to make.[^bauhaus]'),
('*The same column seen from two sides, at a camera height of 1.65 metres above its base.','*The same column seen from two sides.'),
("This is the gallery's `ps07_kras_rainbow`, with the whole capped column raised to 6.2 metres.", 'This column began as a table-sized study, 72 centimetres tall; here it is raised to 6.2 metres.'),
('These choices have been saved: which forms, which proportions, which colours, and how the parts meet. The project often calls such a description DNA. Here it lets us keep a composition and make relatives of it. It does not make the column alive. Later, we will open the rules that read a description into a body; for now, the family stands around us.','The saved description of a stack is what this project calls its DNA. Later we will open the rules that turn such a description into a body; here we can walk among its relatives.')])
p=r/'commons/maps/Color_Context_Placed/final.md';s=p.read_text(encoding='utf-8');s+='\n[^bauhaus]: The assignment draws on [Kandinsky’s Bauhaus colour teaching](https://www.bauhaus.de/en/sammlung/highlights/204_unterricht/444): yellow triangle, red square, blue circle. Our five-form stack loosely recalls Alma Siedhoff-Buscher’s building games for the [1923 Haus am Horn](https://www.klassik-stiftung.de/service/presse/pressemitteilung/bauhaus-welt-fuer-kinder/); it does not reproduce their set of pieces.\n';p.write_text(s,encoding='utf-8')
edit('commons/maps/Color_Nails/final.md',[
('What changes when a colour becomes part of the body you act through?','# The choosing hand\n\nWhat changes when a colour becomes part of the body you act through?'),
('In VR, raise the hand moving with your controller and turn its nails toward you.','Raise the hand you are choosing with and turn its nails toward you.'),
('On desktop, the giant and petite hands carry this comparison. In VR, your hands carry the chosen colours beyond the salon.','The colour leaves with you. Your hands carry it into the halls ahead.')])
edit('commons/maps/Color_Rainbow/final.md',[
('The mushrooms are dressed for it.','Two offers wait by the entrance: a crystal in a wire case and a cube to collect. Neither is required to join the celebration.\n\nThe mushrooms are dressed for it.')])
edit('commons/maps/Color_Grid_Pallet/final.md', [('the same cube still supports the walker.','the same cube still supports you.')])
edit('commons/maps/Color_Walls/final.md',[('Sixteen small cubes hold the intervening values.','Sixteen small cubes run from one to the other.')])
edit('commons/maps/Color_Paint/final.md',[('Turn from that accumulating surface to the Albers studies.','Turn from that accumulating surface to the studies after Josef Albers’s *Homage to the Square*.[^albers]')])
p=r/'commons/maps/Color_Paint/final.md';s=p.read_text(encoding='utf-8');s+='\n[^albers]: Albers began [*Homage to the Square*](https://www.moma.org/collection/works/79438) in 1950. His [*Interaction of Color*](https://www.albersfoundation.org/alberses/teaching/interaction-of-color), published in 1963, develops exercises in how surrounding colours affect what we see. Our invitation to attend to a colour and its surround draws on that inquiry; the procedural gallery is our interpretation.\n';p.write_text(s,encoding='utf-8')
rel='commons/artifacts/color_dna_stack/studies.json';p=r/rel;d=json.loads(p.read_text(encoding='utf-8'));d['kras_rainbow']['body']='A table-sized study, 72 centimetres tall, raised to 6.2 metres. Thirty fixed stripes carry six colours around the shaft.';p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8');changed.append(rel)
spawn=[]
for m in ['Color_Flashlight','Color_Nails','Color_Rainbow','Color_Walls']:
 rel=f'commons/maps/{m}/map_data.json';p=r/rel;d=json.loads(p.read_text(encoding='utf-8-sig'));found=[]
 for z,row in enumerate(d['layers']['utilities']):
  for x,v in enumerate(row):
   if v=='sp':row[x]='s';found.append([x,z]);assert d['layers']['structure'][z][x] not in ['','0',0,' ']
 assert len(found)==1,(m,found)
 p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8');changed.append(rel);spawn.append({'map':m,'cell':found[0],'change':'sp (score display) -> s (authored spawn); other cells unchanged'})
(o/'spawn-changes.json').write_text(json.dumps(spawn,indent=2)+'\n',encoding='utf-8');(o/'changed-files.json').write_text(json.dumps(changed,indent=2)+'\n',encoding='utf-8')
print('Six targeted manuscript changes, matching column plate, four authored spawn tokens. Flashlight and Pillar prose retained.')
