from pathlib import Path
from html import escape as esc
from html.parser import HTMLParser
import json, shutil, struct, zipfile

OUT = Path(__file__).resolve().parent
data = json.loads((OUT / 'scenes.json').read_text(encoding='utf-8'))
(OUT / 'images').mkdir(exist_ok=True)
sizes = {}
for scene in data['scenes']:
    dest = OUT / scene['saved_file']
    source = Path(scene['source_path'])
    if source.exists():
        shutil.copy2(source, dest)
    raw = dest.read_bytes()
    assert raw[:8] == b'\x89PNG\r\n\x1a\n'
    sizes[scene['id']] = struct.unpack('>II', raw[16:24])

cards = ''
for i, s in enumerate(data['scenes'], 1):
    w, h = sizes[s['id']]
    cards += f'''<section class="scene" id="{s['id']}"><figure><a href="{s['saved_file']}"><img src="{s['saved_file']}" width="{w}" height="{h}" alt="{esc(s['title'] + '. ' + s['hook'] + ' ' + s['end'])}"></a><figcaption>Illustrerat förslag · klicka för hela bilden</figcaption></figure><div class="notes"><p class="eyebrow">{i:02} / tre bilder, ungefär tio sekunder</p><h2>{esc(s['title'])}</h2><p class="beat">0–2 s · löftet</p><p>{esc(s['hook'])}</p><p class="beat">2–6 s · vändningen</p><p>{esc(s['mechanism'])}</p><p class="beat">6–10 s · efteråt</p><p>{esc(s['end'])}</p><blockquote>{esc(s['question'])}</blockquote></div></section>'''

ideas = ''.join(f'''<article><h3>{esc(s['title'])}</h3><p class="hook">{esc(s['hook'])}</p><p>{esc(s['turn'])}</p><p><strong>Att undersöka:</strong> {esc(s['principle'])}</p><p class="after">{esc(s['after'])}</p></article>''' for s in data['more'])
nav = ''.join(f'<a href="#{s["id"]}">{esc(s["title"])}</a>' for s in data['scenes'])
html = '''<!doctype html><html lang="sv"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Jag skulle bara… — Endless Museum</title><style>
:root{--paper:#f4f0e7;--ink:#252525;--muted:#67635e;--red:#953d39;--rule:#d3cbbb}*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:17px/1.65 system-ui,sans-serif}header,main,footer{max-width:1260px;margin:auto;padding:32px}header{padding-top:70px}h1,h2,h3{font-family:Georgia,serif;line-height:1.12}h1{font-size:clamp(50px,8vw,106px);letter-spacing:-.055em;margin:15px 0 28px}h2{font-size:39px;margin:12px 0 25px}h3{font-size:26px}.eyebrow,.beat{font-size:11px;letter-spacing:.12em;text-transform:uppercase;color:var(--red);font-weight:750}.lead{font:26px/1.5 Georgia,serif;max-width:850px}.small,figcaption{font-size:13px;color:var(--muted)}a{color:var(--red);text-underline-offset:4px}nav{display:flex;flex-wrap:wrap;gap:24px;border-block:1px solid var(--rule);padding:18px 0;margin-top:35px;font-size:14px}.scene{display:grid;grid-template-columns:minmax(0,1.4fr) minmax(260px,1fr);gap:48px;padding:35px 0 65px;border-bottom:1px solid var(--rule)}figure{margin:0}img{display:block;width:100%;height:auto}figcaption{padding-top:10px}.notes{position:sticky;top:35px;align-self:start}.notes p{margin:10px 0 18px}.beat{margin-top:28px!important}blockquote{margin:35px 0;font:27px/1.4 Georgia,serif;border-left:2px solid var(--red);padding-left:20px}.reading{max-width:790px;margin:65px auto}.ideas{display:grid;grid-template-columns:repeat(2,1fr);gap:22px}.ideas article{border:1px solid var(--rule);padding:23px}.ideas h3{margin-top:0}.hook{font-family:Georgia,serif;font-size:22px}.after{color:var(--red)}footer{font-size:13px;border-top:1px solid var(--rule);margin-top:55px}.download{display:inline-block;padding:10px 17px;border:1px solid var(--red);text-decoration:none;margin-top:12px}@media(max-width:760px){header,main,footer{padding:24px}.scene{grid-template-columns:1fr;gap:20px}.notes{position:static;order:-1}.ideas{grid-template-columns:1fr}h2{font-size:32px}}@media print{nav,.download{display:none}.scene{display:block;break-before:page}.notes{position:static}img{height:230mm;width:auto;max-width:100%;margin:auto}.ideas{display:block}}
</style></head><body><header><p class="eyebrow">Endless Museum / Forces / Felslutet / 7 oktober 2026</p><h1>Jag skulle bara…</h1><p class="lead">Ett litet löfte om kontroll. Ett motstånd. En följd som fortsätter. Tre nya bildsekvenser och sex korta uppslag med fail-klippets rytm.</p><p class="small">Originalillustrationer för möjliga scener i museet. Detta är bildmanus, inte filmer eller inspelningar av fungerande spelmekanik. Bildtexterna är på engelska för boken; arbetsanteckningarna är på svenska.</p><a class="download" href="forces-fail-shorts.zip">Hämta bilder och redigerbara uppslag</a><nav>''' + nav + '''<a href="#more">Sex fler uppslag</a><a href="#reading">Vad vi tar med oss</a></nav></header><main>''' + cards + '''<article class="reading" id="reading"><p class="eyebrow">Ur arbetet med Felslutet</p><h2>Stanna en sekund efter missen.</h2><p>Du sträcker fram handen. Bollen kommer inte. Piedestalen kommer. I den förskjutningen blir en dold förutsättning synlig: vi hade behandlat basen som orörlig. Händelsen går att skratta åt och sedan undersöka.</p><p>Det här är riktningen jag tar från din text: förväntningen får en annan form. Den högtidliga demonstrationen tappar sin auktoritet. Studenten behöver inte omedelbart återställa ordningen. Hen kan upptäcka vad situationen nu erbjuder.</p><p>Vi behöver skilja mellan en regel som utförs men får en oväntad följd, ett faktiskt programfel och en annan användning av det som uppstått. Här handlar bilderna framför allt om det första och det tredje. Ett hinder som blir en trappa öppnar en fråga om vem som bestämmer vad ett föremål är till för.</p><p>I ett kort klipp ska avsikten synas direkt. Låt kontakten, tyngden eller linan bära vändningen. Behåll sedan den tomma handen, efterklangen eller den försiktiga första foten på trappan. Den sekunden kan bära både skrattet och osäkerheten. Alla missar behöver inte mynna ut i en förbättring; ibland finns bara en följd att ta hand om.</p><p class="small">Scenernas utfall måste prövas i motorn innan de kan beskrivas som emergenta spelhändelser. Klockscenen förutsätter en förspänd fjäder: den höga studsen får energi från mekanismen. Trappscenen kräver tillräckligt stabila kontakter; ett illustrerat resultat bevisar inte att blocken kommer att lägga sig så.</p></article><section id="more"><p class="eyebrow">Ytterligare uppslag / ännu inte illustrerade</p><h2>Sex till att pröva</h2><div class="ideas">''' + ideas + '''</div></section></main><footer>AI-genererade bilder · <a href="scenes.json">Texter, fullständiga bildinstruktioner och ursprung</a> · <a href="../2026-10-07-forces-the-unintended/index.html">De tre tidigare situationerna</a>. Museets kod och bokmanus har inte ändrats i denna bildstudie.</footer></body></html>'''
(OUT / 'index.html').write_text(html, encoding='utf-8')

class Page(HTMLParser):
    def __init__(self):
        super().__init__(); self.links=[]; self.ids=set()
    def handle_starttag(self, tag, attrs):
        a=dict(attrs)
        if 'id' in a: self.ids.add(a['id'])
        for k in ('src','href'):
            if k in a: self.links.append(a[k])
p=Page(); p.feed(html)
for link in p.links:
    if link.startswith('#'): assert link[1:] in p.ids
    elif not link.endswith('.zip'): assert (OUT/link).is_file(), link
with zipfile.ZipFile(OUT/'forces-fail-shorts.zip','w',zipfile.ZIP_DEFLATED) as z:
    for f in OUT.rglob('*'):
        if f.is_file() and f.suffix != '.zip' and '__pycache__' not in f.parts:
            z.write(f, f.relative_to(OUT))
with zipfile.ZipFile(OUT/'forces-fail-shorts.zip') as z: assert z.testzip() is None
print(json.dumps({'images': sizes, 'links_checked':len(p.links), 'zip':'CRC passed', 'page':str(OUT/'index.html')}))
