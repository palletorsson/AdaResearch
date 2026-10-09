from pathlib import Path
import hashlib,json
r=Path.cwd();o=r/'doc/book/iterations/2026-09-25-ca-opening-review'
baseline=json.loads((o/'baseline.json').read_text())
owned=['commons/maps/CA_Introduction/final.md','commons/maps/CA_Introduction/summary.md','commons/maps/CA_Introduction/map_data.json','commons/maps/CA_GameOfLife/final.md','commons/maps/CA_GameOfLife/map_data.json','commons/maps/CA_AgentsCircuits/final.md','commons/maps/CA_ElementaryRules/map_data.json','commons/maps/CA_BeyondBinary/map_data.json','commons/data/book/cellularautomata.json','commons/maps/sequences/cellularautomata.json']
for path in owned:assert hashlib.sha256((r/path).read_bytes()).hexdigest()==baseline[path],path
def write(rel,s):(r/rel).write_bytes(s.encode('utf-8'))
def replace(rel,a,b):
 s=(r/rel).read_text(encoding='utf-8-sig');assert s.count(a)==1,(rel,a);write(rel,s.replace(a,b))
intro='commons/maps/CA_Introduction/final.md'
replace(intro,'We have carried noise a long way: across a sheet, into a volume, around the body and under a foot. A little variation can satisfy the first wish for something organic. Its ease is part of its power. It can also make that first answer so familiar that other possible forms remain in its shadow. Keep the pleasure of the blob. Bring an unfinished question with it.','Keep the pleasure of the blob. Bring an unfinished question with it.')
replace(intro,'Begin with Rule 90 and the single seed.[^ca-wolfram]','On the smaller CA RULES panel, between the study buttons and the board, press 90. Keep the single seed.[^ca-wolfram]')
replace(intro,'For Rule 90, compare `100` with `010`. Each contains one occupied cell. The answers differ.','For Rule 90, compare `100` with `010`. Each contains one occupied cell. The first makes the next cell occupied; the second leaves it empty.')
replace(intro,'Choose Rule 30 and keep the single seed.','Press 30 on that rule panel and keep the single seed.')
replace(intro,"so that Rule 90 is 01011010 (“Statistical mechanics",'so that Rule 90 is 01011010. In the order 111, 110, 101, 100, 011, 010, 001, 000, its eight answers are 0, 1, 0, 1, 1, 0, 1, 0 (“Statistical mechanics')
replace(intro,"Langton's ants, cells that move, each turning","Langton's ants, agents that move, each turning")
replace(intro,"The orb rests on the rug's edge, and a showcase waits", "The orb rests on the rug's edge, another is held on a low stand, and a showcase waits")
replace(intro,'Every hall from here changes one or two of them and keeps the rest; that is all a variation is.','These choices will help us follow the variations ahead. Sometimes the rule changes; sometimes we give the same record another body.')
replace(intro,'gives disappearance more than one state: the second choice and the first.','gives disappearance more than one state.')
replace('commons/maps/CA_Introduction/summary.md','All nine original placements remain.','Eight placements remain. The unused substrate runner has been removed from this hall; its source and registry entry remain available. The low synthesis stand retains a supporting orb.')

history='commons/maps/CA_GameOfLife/final.md'
replace(history,'Here `a`, `b` and `c` are the three states. The shifts give their positions different weights: four, two, one. `100` and `001` both contain one occupied cell, but ask different questions of the rule.','Here `a`, `b` and `c` are the three states, read into one index as the board in the first hall did.')
replace(history,'The next hall holds a two-dimensional present.','Beyond the basin the hall continues: columns, the orb again, a lab, a mirrored automaton. The lab arranges a tape, a head and a state register as a model of a machine. Its sign asks what counts as computation. A familiar arrangement gives us somewhere to begin asking; it cannot do the work of a proof.\n\nThe next hall holds a two-dimensional present.')
replace('commons/maps/CA_AgentsCircuits/final.md','Set the rule explorer to Rule 90 and reset its central seed.','Press 90 on the explorer’s CA RULES panel, then RST to return to the central seed.')

# Remove one unused placement, retaining the artifact implementation and registry.
path='commons/maps/CA_Introduction/map_data.json';s=(r/path).read_text();assert s.count('"grid_substrate_runner"')==1;write(path,s.replace('"grid_substrate_runner"','" "'))
path='commons/maps/CA_GameOfLife/map_data.json'
replace(path,'#signage_top:TURING MACHINE LAB#signage_sub:Rule 110 → universal computation#annotation_top:M = (Q, Σ, Γ, δ, q0, F) — Game of Life is Turing complete#annotation_bottom:belt = Γ*, panel = q, server rack = δ, button = HALT', '#signage_top:WHAT COUNTS AS COMPUTATION?#signage_sub:A tape, a head, a set of states#annotation_top:A model of a machine is not a proof of universality#annotation_bottom:What connects the tape, the head and the state?')
titles={m:(r/'commons/maps'/m/'final.md').read_text().splitlines()[0].removeprefix('# ') for m in ['CA_ElementaryRules','CA_GameOfLife','CA_BeyondBinary']}
for m,title in titles.items():
 path=f'commons/maps/{m}/map_data.json';s=(r/path).read_text();d=json.loads(s);old=d['map_info']['title']
 if old!=title:
  a='"title": '+json.dumps(old,ensure_ascii=False);assert s.count(a)==1;write(path,s.replace(a,'"title": '+json.dumps(title,ensure_ascii=False)))
path='commons/data/book/cellularautomata.json';d=json.loads((r/path).read_text())
for p in d['pearls']:
 if p['map'] in titles:p['pearl']=titles[p['map']]
write(path,json.dumps(d,ensure_ascii=False,indent=2)+'\n')
path='commons/maps/sequences/cellularautomata.json';d=json.loads((r/path).read_text());seq=d['sequences']['cellularautomata']
seq['content']=[entry.split(':',1)[0]+': '+titles[entry.split(':',1)[0]] if entry.split(':',1)[0] in titles else entry for entry in seq['content']]
write(path,json.dumps(d,ensure_ascii=False,indent=2)+'\n')
(o/'changed-files.json').write_bytes((json.dumps(owned,indent=2)+'\n').encode())
print('Applied targeted CA opening edits, descriptive hall names and one inactive placement removal.')
