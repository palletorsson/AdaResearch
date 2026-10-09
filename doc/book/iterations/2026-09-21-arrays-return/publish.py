from pathlib import Path
import json,hashlib,html,re,difflib
import markdown
H=Path(__file__).resolve().parent;R=H.parents[3]
NAMES=['Array','Tutorial_3D','Tutorial_Tiling_Floor','Tutorial_Tiling_Walls','Tutorial_Disco']
NOTES=[
'The row now shows its actual construction loop. Zero-based addresses and the double brackets become readable before the grid needs them. A specific exchanged address explains the table orientation.',
'One paragraph opens the nested address from left to right: a layer, a row, an entry. The encounter with your body in a recorded absence remains intact.',
'The remainder links the flight console to returning orientations and, later, rhythm. Image coordinates are distinguished from room coordinates. The exception now asks what would make a chosen meaning available to someone else.',
'The view outside stays. The enclosure sentence is made more concrete, and the wall waits for a body in its sweep in either direction, including during a turn.',
'Track, step and playhead are introduced before use. Stopping one clock while the other continues becomes a discovery. The sound-to-light connection is explained without an unexplained bridge, and the closing points toward the coloured stacks.'
]
read=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def render(s,prefix):
 s=re.sub(r'<!--\s*@[^>]*-->', '', s)
 out=markdown.markdown(s,extensions=['fenced_code','footnotes','tables'])
 out=re.sub(r'id="([^"]+)"',lambda m:'id="'+prefix+m[1]+'"',out)
 return re.sub(r'href="#([^"]+)"',lambda m:'href="#'+prefix+m[1]+'"',out)
# Content/preservation verification only: unchanged game code needs no new runtime suite.
for rel,digest in read(H/'preserved.json').items():
 assert sha(R/rel)==digest,'Concurrent change; inspect before publishing: '+rel
core=read(R/'commons/data/museum_core_encounters.json');expected=read(H/'before/commons/data/museum_core_encounters.json')
roles=read(R/'commons/data/artifact_roles.json');counts=[];parts=[]
protected={
'Array':['An empty slot can still have an address.','The table knows that its occupant has left, without keeping a destination for it.','it does not require them to look alike, stand straight or remain occupied.'],
'Tutorial_3D':['The table still says zero: it records cubes, not everything that could exist there. What would have to change for it to notice you?'],
'Tutorial_Tiling_Floor':['No tile has to remember the whole field. Its local address and the rule are enough to decide its turn.'],
'Tutorial_Tiling_Walls':['From here the panel is almost nothing. A thin sheet, a hinge, the plain reverse of the image. It was enough to stop us.','The first changed what we could read; the second changed where we could go.','Even this little outside has a floor and a rail.'],
'Tutorial_Disco':['A representation can preserve an event while folding together some of the information about where it came from.','Sharing a space with a rhythm is different from being measured by it.']}
for name,note in zip(NAMES,NOTES):
 rel=Path('commons/maps')/name/'final.md';old=(H/'before'/rel).read_text(encoding='utf-8');now=(R/rel).read_text(encoding='utf-8')
 expected['rooms'][name]['text_sha256']=sha(R/rel)
 markers=lambda text:re.findall(r'<!-- @([A-Za-z_0-9]+) -->',text)
 assert markers(old)==markers(now),'Changed encounter order'
 assert all(quote in now for quote in protected[name]),'Protected passage missing'
 order=roles['order'][name];tokens=[]
 for token in order['primary']:tokens.extend(order['primary|'+token[1:]] if token.startswith('@') else [token])
 assert markers(now)==[token for token in tokens if not token.startswith('#')]==core['rooms'][name]['primary_tokens']
 delta=''.join(difflib.unified_diff(old.splitlines(True),now.splitlines(True),fromfile='before/'+rel.as_posix(),tofile='current/'+rel.as_posix()))
 filename=rel.as_posix().replace('/','__')+'.diff';(H/filename).write_text(delta,encoding='utf-8')
 counts.append({'map':name,'before_words':len(old.split()),'after_words':len(now.split())})
 parts.append('<section id="'+name+'"><h2>'+html.escape(name.replace('_',' '))+'</h2><p>'+html.escape(note)+'</p><nav><a href="/compose/sources?map='+name+'&amp;doc=final">Read and comment</a><a href="'+filename+'">Exact diff</a><a href="/long-museum/encounters?map='+name+'">Encounter map</a></nav><details><summary>Read the revised chapter</summary><div class="reading">'+render(now,name+'-read-')+'</div></details><details><summary>Compare original and current</summary><div class="compare"><article><h3>Original</h3>'+render(old,name+'-old-')+'</article><article><h3>Current</h3>'+render(now,name+'-new-')+'</article></div></details></section>')
assert core==expected,'Core changes beyond five text hashes'
(H/'verification.json').write_text(json.dumps({'scope':'Manuscript/source reading and preservation checks; no new runtime tests or captures','preserved_files':len(read(H/'preserved.json')),'protected_passages':sum(map(len,protected.values())),'encounter_order_preserved':True,'only_five_core_text_hashes_changed':True,'chapter_counts':counts},indent=2)+'\n',encoding='utf-8')
style=(R/'doc/book/iterations/2026-09-21-point-one-return/index.html').read_text(encoding='utf-8').split('<style>')[1].split('</style>')[0]
style+='section{margin:48px 0;border-top:1px solid var(--line);padding-top:24px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:18px}.pair figure{margin:16px 0}.compare{align-items:start}@media(max-width:760px){.pair{grid-template-columns:1fr}}'
nav=''.join('<a href="#'+n+'">'+n.replace('Tutorial_','').replace('_',' ')+'</a>' for n in NAMES)
page='<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Arrays — the same instruction, another address</title><style>'+style+'</style></head><body><main><div class="eyebrow">Ada Research · Arrays reading pass · 21 September 2026</div><h1>The same instruction,<br>another address.</h1><p class="intro">Four cubes, but the last address is three. The same instruction makes the many by changing what it receives.</p><p>Claude\'s review identifies useful gaps in what a beginner has been shown. This pass supplies those handholds while keeping the sequence\'s encounters with absence, enclosure and rhythm. The maps and artifact implementations stay as they were.</p><nav>'+nav+'<a href="SUMMARY.md">Decisions and evidence</a><a href="/book-review/doc/book/review-feedback/2026-09-21/array_tutorial/01-claude-review.txt">Received review</a></nav><blockquote>The table still says zero: it records cubes, not everything that could exist there. What would have to change for it to notice you?</blockquote><p>The opening owns the first explicit loop through these array addresses. Colour can reuse it. The corrected Grid pen encounter stays; the obsolete time-domain suggestion is not applied. The internal name row_3_x stays too: the text and example plainly show four cubes.</p><div class="pair"><figure><a href="../2026-09-20-wall-exception/closed.png"><img src="../2026-09-20-wall-exception/closed.png" alt="Earlier actual museum capture of the printed wall in its closed position"></a><figcaption>The printed sheet, closed.</figcaption></figure><figure><a href="../2026-09-20-wall-exception/reverse.png"><img src="../2026-09-20-wall-exception/reverse.png" alt="Earlier actual museum view from the landing showing the thin wall edge and plain reverse"></a><figcaption>Its edge and plain reverse, seen from the landing.</figcaption></figure></div><p class="note">These actual Godot images come from the 20 September wall encounter. They illustrate two existing states, not new geometry from this pass. Current source inspection confirms the wall pauses while its landing or sweep is occupied; this pass makes the chapter\'s wording match that behaviour.</p>'+''.join(parts)+'<section><div class="eyebrow">Next · Colour, then the later Tiling return</div><h2>A value acquires a colour.</h2><p>The coloured stacks bring primitives, transformations and arrays together. When Tiling returns after Colour, it can build on these six monochrome relations and develop colour, material and architectural control. It need not introduce the whole ladder again.</p><nav><a href="/compose/sources?map=Color_Context_Placed&amp;doc=final">Read the Color opening</a><a href="/book-review/doc/book/iterations/2026-09-21-transformation-return/index.html">Previous Transformation pass</a><a href="/book-review/doc/book/review-feedback/2026-09-21/array_tutorial/DECISIONS.md">Review decisions</a></nav></section><p class="note">This pass changes five manuscripts and their derived text hashes. All five map files, artifact code, roles, sequence order, Grid manuscript and frozen Claude export remain unchanged. No fresh gameplay or headset verification is claimed.</p></main></body></html>'
(H/'index.html').write_text(page,encoding='utf-8')
print('Published Arrays comparison; preservation and encounter-order checks passed.')
print(json.dumps(counts))
