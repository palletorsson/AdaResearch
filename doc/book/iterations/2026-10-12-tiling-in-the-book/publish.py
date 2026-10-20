"""Publish current Tiling manuscripts, their differences and bounded evidence."""
from prepare import HERE, ROOT, HALLS, put, sha
import ast, difflib, html, json, re, shutil, zipfile
from urllib.parse import urlsplit, unquote
import markdown

tree=ast.parse((HERE.parent/'2026-10-12-arrays-in-the-book/publish.py').read_text(encoding='utf-8'))
CSS=next(ast.literal_eval(n.value) for n in tree.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='CSS' for t in n.targets))
CSS+='\n.cards{display:grid;grid-template-columns:minmax(0,1.2fr) minmax(0,1fr);gap:2rem;align-items:start}.cards figure{margin-top:1.5rem}.contents{display:flex;flex-wrap:wrap;gap:.5rem 1.3rem}.carried{border-top:1px solid var(--line);padding-top:1rem}.carried summary{font-weight:600}@media(max-width:900px){.cards{display:block}}@media print{details.carried{display:block}}'

def render(text,h,fold=False):
    marker='## Complete carried files'
    if fold and marker in text:
        first,last=text.split(marker,1)
        return render(first,h)+f'<details class="carried"><summary>Complete carried files — reused from earlier lessons</summary>{render(marker+last,h)}</details>'
    out=markdown.markdown(text.replace('/book-images/','/book-review/doc/book/'),extensions=['fenced_code','tables','footnotes'])
    def link(m):
        attr,url=m.groups(); u=urlsplit(html.unescape(url))
        if u.scheme or u.netloc or url.startswith(('/', '#')):return m.group(0)
        target=(ROOT/'commons/maps'/h/unquote(u.path)).resolve()
        if target.is_file() and target.is_relative_to(ROOT):
            return attr+'="/book-review/'+target.relative_to(ROOT).as_posix()+('#'+u.fragment if u.fragment else '')+'"'
        return m.group(0)
    out=re.sub(r'(href|src)="([^"]+)"',link,out)
    # Each chapter's footnotes remain local when complete readings share one page.
    out=re.sub(r'id="(fn[^\"]*)"',lambda m:'id="'+h+'-'+m[1]+'"',out)
    out=re.sub(r'href="#(fn[^\"]*)"',lambda m:'href="#'+h+'-'+m[1]+'"',out)
    return out

def page(title,body,depth=0):
    prefix='../'*depth
    return f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{html.escape(title)} · Endless Museum</title><style>{CSS}</style></head><body><header><b>ENDLESS MUSEUM / TILING</b><a href="{prefix}index.html">Sequence</a><a href="{prefix}all.html">Tutorials</a><a href="{prefix}final.html">Reflections</a><a href="{prefix}tiling-review.zip">Review ZIP</a></header><main>{body}</main><script>let folds=[];addEventListener("beforeprint",()=>{{folds=[...document.querySelectorAll("details.carried")].map(x=>[x,x.open]);folds.forEach(([x])=>x.open=true)}});addEventListener("afterprint",()=>folds.forEach(([x,open])=>x.open=open));</script></body></html>'

def main():
    evidence=json.loads((HERE/'sequence-verification.json').read_text());assert evidence['passed']
    for p,d in evidence['inputs'].items():assert sha(ROOT/p)==d,p
    lineage=json.loads((HERE/'lineage.json').read_text())
    report='''# Tiling — one source, many readings

12 October 2026. Current drafts refined and gathered into a complete nine-hall reading.

Colour made a distinction between a value, its receiver and the appearance it produces. Tiling keeps the familiar point, palette and addressed cubes, then asks how one source reaches many places. The sequence already had complete tutorials. This pass preserves the later loom and garment revisions rather than replacing them with older snapshots.

The route is: palette and phase → editable source → reflected reading → physical frame → glide → independent recipes → optional volume → perceptual comparison → fabric sampling and wearing.

## What changed

- Disco now names the current Colour classes and explains their reuse. A new lesson initializes its stated values; it does not silently import a saved palette or a running point.
- Eight printed copies of the inherited grid now match Colour's current helper exactly. Only their old control-hint string changed; all nine lesson entry programs and the shader are unchanged.
- Ribbon 03 separates a guided two-to-three repeat edit from a student-chosen prediction. The optional loom and garment passages remain.
- The plan records all nine completed tutorials. Its obsolete “Ribbon tutorials missing” note is removed, Temple is restored to the collected summary export, and the optional volume is no longer a prerequisite for the perceptual comparison.
- Symmetry's existing optical-cloth image link had lost its target. The exact image is restored from the 10 October archive; the reflective text and image pixels are unchanged.
- Current final.md texts, map layouts and runtime scripts are retained. The sequence definition receives only a completion-status correction.

## How the two texts work together

The tutorial identifies what to hold fixed, what to change and how to check the consequence. The reflection asks what that choice makes available: the reach of a mark, a room's apparent authority, the difference between assigned equality and experienced colour, and an appearance that can be worn. Neither track needs every artifact to become a coding exercise.

The teaching rhythm matters. Disco returns; Foundry builds; the reflected reader changes one operation; the tunnel gives addresses a physical frame; the glide is a short extension; Temple composes. The volume is a branch, the colour comparison a pause, and the final shader brings a known calculation onto another receiver.

## What remains open

The five-column learner receiver cannot show the complete six-column reflected or glided return. The text declares this, and the larger museum fields offer a comparison. A wider learner display would be the most useful later spatial improvement; it has not been implemented in this text pass.

Reused code, copied records and saved artifacts are different handoffs. Most entry scripts initialize their own source. The optional loom explicitly saves cloth for the cutting table. The studio supplies its own four-by-four source and saves a separate recipe; saving that recipe does not save the student's shader.

The next sequence is Change, where two positions on a curve invite a comparison of values. Its existing invitation remains at the end; no Change lesson was revised here.

## Verification

Fresh learner files were extracted from all 36 printed file occurrences. Eighteen native Godot runs passed 647 assertions, including six shader readback cases with ten predicted texels each. A separate existing cross-hall probe passed 12 assertions with a six-row source explicitly copied from glide into independent receivers. All three Colour helpers match in each of the first eight lessons; Symmetry's inherited receiver matches Array Patterns.

These are teacher-authored regression checks, not a blind student trial or a physical headset session. The nine report images are earlier captures inside the museum, dated 9 October. No new installation is implied. The runs also emitted the existing unrecognized-UID message and Jolt/environment warnings; full diagnostics are retained in sequence-verification.json. No script parse failures or failed lesson assertions occurred.
'''
    put(HERE/'REPORT.md',report)
    body='''<h1>Tiling: one source, many readings</h1><p class="deck">Keep Colour’s point, palette and grid. Make a source, change how it returns, give it a place, and finally carry a pattern onto a body.</p><p class="route">Palette → source → reflection → surface frame → glide → copied recipes → optional volume → comparison → garment</p><p>12 October 2026 · Nine current tutorials · 36 printed file occurrences · 647 native assertions + 12 transfer assertions passed.</p><div class="links"><a href="Pattern_Disco/parallel.html">Start paired reading →</a><a href="ALL_TUTORIALS.md">Whole tutorial file</a><a href="ALL_FINAL.md">Whole reflective file</a><a href="SUMMARIES.md">Nine short summaries</a><a href="sequence-verification.json">Fresh test evidence</a></div><p>The complete drafts already existed. This pass tightens their return from Colour and retains the newer loom and garment work. Tutorial on the left, reflection on the right; familiar helper files can be expanded when needed.</p><div class="contents">'''
    body+=''.join(f'<a href="#{x["id"]}">{i+1:02d} {html.escape(x["title"])}</a>' for i,x in enumerate(lineage))+'</div>'
    summary='# Tiling — nine lesson summaries\n\n12 October 2026. Current tutorials; editable teaching decisions.\n\n'
    readings={'tutorial':[],'final':[]};manifest={'date':'2026-10-12','halls':[]}
    for i,item in enumerate(lineage):
        h=item['id'];t=(HERE/h/'tutorial.md').read_text(encoding='utf-8');f=(HERE/h/'final.md').read_text(encoding='utf-8')
        assert sha(HERE/h/'tutorial.md')==sha(ROOT/'commons/maps'/h/'tutorial.md')
        assert sha(HERE/h/'final.md')==sha(ROOT/'commons/maps'/h/'final.md')
        original=ROOT/item['image']['path'];assert original.is_file(),original
        target=HERE/'images'/f'{h}.png';target.parent.mkdir(exist_ok=True);shutil.copyfile(original,target)
        caption='9 October 2026 · Earlier capture inside the museum; this pass changes the reading, not the room.'
        photo=lambda prefix:f'<figure><img loading="lazy" src="{prefix}images/{h}.png" alt="{html.escape(item["image"]["label"])}"><figcaption>{caption}</figcaption></figure>'
        old=(HERE/'before/commons/maps'/h/'tutorial.md').read_text(encoding='utf-8-sig')
        diff=''.join(difflib.unified_diff(old.splitlines(True),t.splitlines(True),fromfile='Before/'+h,tofile='Current/'+h));put(HERE/h/'tutorial.diff',diff)
        previous=f'<a href="../{HALLS[i-1]}/parallel.html">← Previous hall</a>' if i else '<a href="../../2026-10-12-colour-in-the-book/Color_Walls/parallel.html">← Colour: Walls</a>'
        nxt=f'<a href="../{HALLS[i+1]}/parallel.html">Next hall →</a>' if i<len(HALLS)-1 else '<a href="../index.html#next">What travels onward →</a>'
        nav=f'<nav class="nav">{previous}<span>{i+1} / 9</span>{nxt}</nav>'
        spread=f'<p class="label">{h}</p><p>{html.escape(item["summary"])}</p><details><summary>View inside the museum</summary>{photo("../")}</details>{nav}<div class="spread"><section><p class="label">Left page / tutorial</p>{render(t,h,True)}</section><section><p class="label">Right page / reflection</p>{render(f,h)}</section></div><details><summary>Before / after tutorial text</summary><pre class="changes">{html.escape(diff)}</pre></details>{nav}'
        put(HERE/h/'parallel.html',page(item['title'],spread,1))
        entry=json.loads((HERE/'evidence/manifest.json').read_text())['rows'][i]['main']
        body+=f'<article id="{h}"><p class="label">{i+1:02d} / {h} / {item["mode"]}</p><div class="cards"><div><h2>{html.escape(item["title"])}</h2><p>{html.escape(item["summary"])}</p><p><b>This pass:</b> {html.escape(item["change_note"])}</p><p class="muted">Reflection: {html.escape(item["reflection"])}</p><div class="links"><a href="{h}/parallel.html">Paired reading</a><a href="{h}/tutorial.diff">Before / after</a><a href="{h}/{entry}">Learner code</a><a href="http://localhost:3003/tutorial-plan?view=summaries&amp;map={h}">Editable plan</a></div></div>{photo("")}</div></article>'
        summary+=f'## {h} — {item["title"]}\n\n{item["summary"]}\n\n**Short AI:** {item["short"]}\n\n**Carry:** {item["carry"]}\n\n**Next:** {item["next"]}\n\n'
        readings['tutorial'].append((h,t));readings['final'].append((h,f))
        manifest['halls'].append({'id':h,'tutorial_sha256':sha(HERE/h/'tutorial.md'),'final_sha256':sha(HERE/h/'final.md'),'image':item['image']})
    body+='<article id="next"><h2>What travels onward</h2><p>A source, a reading operation and a receiving surface are now separate choices. The same PointBody, Palette and GridSurface code returns from Colour. A reused class does not automatically carry a running edit. The optional loom-to-cutting-table record is a real saved handoff; the shader studio keeps its own separate recipe.</p><p>Next, Change compares values at two positions. Tiling’s complete reading is ready to review before that next pass.</p></article><article><h2>The next useful improvement</h2><p>Show two complete reflected periods in the small learner receiver. Its five columns currently cut the six-column return short. The larger installed comparison already helps; a wider learner display would make the relation easier to see.</p></article><details><summary>Full report, changes and verification limits</summary>'+render(report,'Pattern_Disco')+'</details>'
    put(HERE/'index.html',page('Tiling in the book',body));put(HERE/'SUMMARIES.md',summary)
    put(HERE/'manifest.json',json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
    for kind,title,name in [('tutorial','Tiling — complete tutorials','all.html'),('final','Tiling — current reflections','final.html')]:
        md='# '+title+'\n\n12 October 2026.\n';content=f'<div class="reading"><h1>{title}</h1>'
        for h,text in readings[kind]:
            md+='\n---\n\n<!-- hall:'+h+' -->\n\n'+text+'\n'
            content+=f'<article id="{h}"><p class="label">{h}</p>{render(text,h,kind=="tutorial")}</article>'
        put(HERE/('ALL_TUTORIALS.md' if kind=='tutorial' else 'ALL_FINAL.md'),md);put(HERE/name,page(title,content+'</div>'))
    put(HERE/'README.md','# Tiling review packet\n\nRead ALL_TUTORIALS.md alongside ALL_FINAL.md; SUMMARIES.md gives one paragraph per hall. Complete learner files are grouped by hall. Use them inside the existing Endless Museum project with its prepared XR support, not as a standalone replacement project. The final studio scene declares its dependency on the existing museum artifact.\n\nREPORT.md explains this pass. sequence-verification.json and evidence/ contain fresh native results. Images are earlier museum captures; a lesson study is not automatically installed in the live hall. Supporting reading and image links in Markdown refer back to the repository/book-review server. Reproduction tools in this folder expect the original repository layout.\n')
    with zipfile.ZipFile(HERE/'tiling-review.zip','w',zipfile.ZIP_DEFLATED) as archive:
        for p in HERE.rglob('*'):
            rel=p.relative_to(HERE)
            if not p.is_file() or any(x in rel.parts for x in ['before','__pycache__']):continue
            if p.suffix in ['.md','.gd','.gdshader','.tscn','.py','.json','.diff','.png','.log']:archive.write(p,rel)
    print('Published nine paired pages, whole readings, per-hall changes, museum images and review packet.')

if __name__=='__main__':main()
