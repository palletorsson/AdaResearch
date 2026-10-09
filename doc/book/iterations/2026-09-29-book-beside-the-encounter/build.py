from pathlib import Path
import hashlib,html,json,re
import markdown
from bs4 import BeautifulSoup
ROOT=Path(__file__).resolve().parents[4];OUT=Path(__file__).resolve().parent
read=lambda p:p.read_text(encoding='utf-8-sig')
text=read(OUT/'sources/commons/maps/Pattern_Foundry/final.md')
notes=json.loads(read(OUT/'pairings.json'))
parts=re.split(r'<!-- @([^ ]*) -->',text)
intro=parts[0].split('\n\n',1)[1]
sections={parts[i]:parts[i+1].strip() for i in range(1,len(parts),2)}
machine=sections['pattern_machine_a']
first,returns=machine.split('## On a return visit',1)
flat,held=first.split('With CURVE selected on the display,',1)
held,room=held.split('Link the curve again,',1)
held='With CURVE selected on the display,'+held
room='Link the curve again,'+room
lead='The current specimen is assembled one pixel at a time.'
flat,code=flat.split(lead,1);code=lead+code
figure=re.search(r'!\[([^\]]+)\]\(([^)]+)\)\s*\n\n(\*[^\n]+\*)',room)
assert figure
fig_html=f'<figure><img src="{html.escape(figure[2])}" alt="{html.escape(figure[1])}" loading="lazy"><figcaption>{html.escape(figure[3].strip("*"))} <span>Native museum views, 28 September 2026.</span></figcaption></figure>'
room=room.replace(figure[0],'')
ending=sections['']
left=[sections['pattern_architecture'],sections['pattern_tile_4x4'],sections['pattern_tile_mirror'],flat.strip(),held.strip(),room.strip()]
# All chapter paragraphs remain somewhere in this layout: the source-code explanation
# moves beside the flat/curved encounter; the return visit becomes an optional workshop.
expected=[q.strip() for q in text.split('\n\n') if q.strip() and not q.startswith(('#','<!--','![')) and q.strip()!=figure[3]]
combined='\n\n'.join([intro,*left,code,returns,ending])
for para in expected:
    assert para in combined, 'Missing chapter paragraph: '+para[:100]
def md(s):return markdown.markdown(s,extensions=['extra'])
rows=''
for i,(body,note) in enumerate(zip(left,notes),1):
    extra=md(code) if note['id']=='surface' else ''
    rows+=f'<section class="pair" id="{note["id"]}" aria-label="Encounter {i}: {html.escape(note["title"])}"><div class="prose">{md(body)}</div><aside class="companion"><div class="note"><p class="small">{i:02d} / Tutorial</p><h2>{html.escape(note["title"])}</h2>{md(note["text"])}{extra}</div></aside></section>'
css="""
:root{color-scheme:light;--paper:#f7f4ee;--ink:#262b2d;--muted:#66716f;--line:#d7d9d0;--green:#245950;--note:#edf0e8}*{box-sizing:border-box}html{scroll-behavior:smooth;scroll-padding-top:90px}body{margin:0;background:var(--paper);color:var(--ink);font:20px/1.75 Georgia,serif}.wrap{max-width:1240px;margin:auto;padding:0 52px}a{color:var(--green);text-underline-offset:4px}button,a,summary{-webkit-tap-highlight-color:transparent}button:focus-visible,a:focus-visible,summary:focus-visible{outline:3px solid #8e555e;outline-offset:5px}.toolbar{position:sticky;top:0;z-index:2;background:rgba(247,244,238,.97);border-bottom:1px solid var(--line);font:13px/1.5 system-ui,sans-serif}.toolbar>.wrap{display:flex;align-items:center;justify-content:space-between;gap:20px;padding-top:14px;padding-bottom:14px}.brand{text-transform:uppercase;letter-spacing:.12em;color:var(--muted)}.modes{display:flex;gap:4px;padding:3px;border:1px solid var(--line);border-radius:5px}.modes button{border:0;border-radius:3px;padding:7px 11px;font:inherit;background:transparent;color:var(--ink);cursor:pointer}.modes button[aria-pressed=true]{background:var(--green);color:white}header{padding-top:64px;padding-bottom:40px}.small{font:11px/1.5 system-ui,sans-serif;text-transform:uppercase;letter-spacing:.12em;color:var(--muted);margin:0 0 15px}h1{font:normal clamp(40px,5.4vw,66px)/1.12 Georgia,serif;letter-spacing:-.025em;margin:15px 0 28px}header .intro{max-width:680px;font-size:23px;line-height:1.62}.columns{display:grid;grid-template-columns:minmax(0,1.75fr) minmax(0,1fr);gap:65px;border-block:1px solid var(--line);padding:12px 0;margin-bottom:32px;font:11px/1.5 system-ui,sans-serif;text-transform:uppercase;letter-spacing:.12em;color:var(--muted)}.pair{display:grid;grid-template-columns:minmax(0,1.75fr) minmax(0,1fr);gap:65px;padding:0 0 34px}.prose{min-width:0}p{margin:0 0 24px}.companion{font:15px/1.7 system-ui,sans-serif;min-width:0}.note{border-top:2px solid #8ca69b;padding:18px 20px 5px;background:var(--note)}.note h2{font:600 19px/1.35 system-ui,sans-serif;letter-spacing:-.01em;margin:0 0 18px}.note p{margin-bottom:18px}.note .small{font-size:10px}.note strong{font-weight:650}.note code{font:12px/1.55 Consolas,monospace}.note pre{background:#e1e7df;padding:14px;margin:20px -6px;white-space:pre-wrap;overflow-wrap:anywhere}.note pre code{font-size:11.5px}figure{margin:16px 0 48px}figure img{display:block;width:100%;height:auto;border:1px solid var(--line)}figcaption{font:13px/1.65 system-ui,sans-serif;max-width:900px;padding-top:14px;color:var(--muted)}figcaption span{display:block;font-size:11px}.finish{max-width:670px;padding:18px 0 34px}.finish .small{color:var(--green)}details{border-top:1px solid var(--line);padding:22px 0}summary{cursor:pointer;font:16px/1.5 system-ui,sans-serif;color:var(--green)}.workshop{max-width:730px;margin:30px auto}.workshop h2{font-size:25px;font-weight:normal}.editorial{font:14px/1.7 system-ui,sans-serif}.editorial>div{max-width:750px;padding:25px 0}.editorial li{margin:10px 0}footer{padding:35px 0 60px;font:12px/1.7 system-ui,sans-serif;color:var(--muted)}.text-only .companion,.text-only .columns{display:none}.text-only .pair{display:block;max-width:690px;margin:auto;padding-bottom:0}.text-only .finish{margin:auto}.text-only header{max-width:690px;margin:auto}.text-only figure{max-width:940px;margin:30px auto 48px}[hidden]{display:none!important}
@media(max-width:950px){.wrap{padding-inline:28px}.pair,.columns{gap:35px;grid-template-columns:minmax(0,1.65fr) minmax(0,1fr)}body{font-size:19px}.note{padding-inline:15px}}
@media(max-width:760px){.toolbar>.wrap{padding:10px 18px;gap:10px}.brand{font-size:10px}.modes button{font-size:11px;padding:6px 8px}.wrap{padding-inline:22px}header{padding-top:34px}header .intro{font-size:21px}.pair{display:block;padding-bottom:24px}.companion{margin:12px 0 30px}.columns{display:none}h1{font-size:43px}.note{padding:16px 18px 4px}}
@media print{.toolbar,.editorial,footer{display:none}.wrap{max-width:none;padding:0}body{font-size:10.5pt;background:white}.pair{gap:24pt;padding-bottom:14pt}.note{font-size:8.5pt;break-inside:avoid}header{padding-top:0}header h1{font-size:32pt}header .intro{font-size:13pt}figure{break-inside:avoid}.workshop{font-size:10pt}details{display:none}a{color:inherit}}
"""
page=f"""<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>A mark in the room | Text and tutorial</title><style>{css}</style></head><body>
<div class="toolbar"><div class="wrap"><span class="brand">Ada Research / Patterns 02</span><div class="modes" role="group" aria-label="Reading layout"><button id="paired" type="button" aria-pressed="true">Text + tutorial</button><button id="solo" type="button" aria-pressed="false">Text only</button></div></div></div>
<main class="wrap"><header><p class="small">The Pattern Foundry / A reading-layout study</p><h1>A mark in the room</h1><div class="intro">{md(intro)}</div></header>
<div class="columns" aria-hidden="true"><span>The encounter</span><span>Try it / Open the operation</span></div>
{rows}{fig_html}
<div class="finish"><p class="small">An exception within the repeat</p>{md(ending)}</div>
<details id="return"><summary>On a return visit / Saving, spacing, offset and connections</summary><div class="workshop">{md(returns)}</div></details>
<details class="editorial" id="editorial"><summary>About this layout and its sources</summary><div><p>This is a proposal for reading the same encounter at two depths. The main text keeps the bodily action, essential explanation and critical question. Short tutorial companions offer a deliberate test or a closer look at the operation beside the passage that needs it.</p><p>The complete existing chapter is present: its code and immediate explanation move beside the flat/curved encounter; its return experiments sit under the disclosure above. The six tutorial companions are edited for this layout from the current tutorial and technical notes. Canonical manuscripts are unchanged.</p><p>The paired view shares one scroll. On a narrow screen, each companion follows its passage. Text only lets you test the continuity of the main reading. In print, the same pairing could occupy a facing page or outer margin.</p><p><a href="sources/commons/maps/Pattern_Foundry/final.md">Captured final.md</a> / <a href="sources/commons/maps/Pattern_Foundry/tutorial.md">Captured tutorial.md</a> / <a href="sources/commons/maps/Pattern_Foundry/technical.md">Captured technical.md</a> / <a href="pairings.json">Editable tutorial pairings</a> / <a href="sources.json">Source fingerprints</a></p><p>Native illustration reused from the existing Foundry review. No museum geometry or production reading route was changed.</p></div></details>
<footer>29 September 2026 / <a href="/compose/sources?map=Pattern_Foundry&amp;doc=final">Current manuscript and comments</a> / <a href="/book-review/doc/book/iterations/2026-09-28-foundry-a-mark-in-the-room/index.html#reading">Previous reading layout</a></footer></main>
<script>const paired=document.getElementById('paired');const solo=document.getElementById('solo');function setReadingMode(textOnly){{document.body.classList.toggle('text-only',textOnly);paired.setAttribute('aria-pressed',String(!textOnly));solo.setAttribute('aria-pressed',String(textOnly));document.querySelectorAll('.companion').forEach(note=>{{note.hidden=textOnly;}});}}paired.addEventListener('click',()=>setReadingMode(false));solo.addEventListener('click',()=>setReadingMode(true));</script></body></html>"""
soup=BeautifulSoup(page,'html.parser')
ids=[t['id'] for t in soup.find_all(id=True)];assert len(ids)==len(set(ids))
assert len(soup.select('.pair'))==6
assert len(soup.select('.companion'))==6
for path,sha in json.loads(read(OUT/'sources.json')).items():
    assert hashlib.sha256((ROOT/path).read_bytes()).hexdigest()==sha, 'Source changed: '+path
(OUT/'index.html').write_text(page,encoding='utf-8')
(OUT/'verification.json').write_text(json.dumps({'all_chapter_paragraphs_retained':True,'canonical_sources_unchanged':True,'encounter_pairs':6,'unique_element_ids':True,'browser_visual_check':'pending'},indent=2)+'\n',encoding='utf-8')
print('Paired reading built. All chapter paragraphs retained; canonical sources unchanged.')
