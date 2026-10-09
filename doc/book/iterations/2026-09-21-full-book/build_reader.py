"""Assemble this snapshot from its sequence captures; never edit manuscripts."""
from pathlib import Path
import hashlib, html, json, re, zipfile
from urllib.parse import urljoin
import markdown
from markdown.extensions import Extension
from markdown.inlinepatterns import InlineProcessor
from xml.etree import ElementTree

class StrikePattern(InlineProcessor):
    def handleMatch(self, match, data):
        element=ElementTree.Element('del');element.text=match.group(1)
        return element,match.start(0),match.end(0)

class Strike(Extension):
    def extendMarkdown(self, md):
        md.inlinePatterns.register(StrikePattern(r'(?<!~)~~(.+?)~~(?!~)',md),'strike',175)

H=Path(__file__).resolve().parent;R=H.parents[3]
spine=R/'commons/maps/curriculum_spine.json'
sequences=sorted(json.loads(spine.read_text(encoding='utf-8'))['spine']['sequences'],key=lambda s:float(s['order']))
manifests=[];parts=['# Ada Research — full manuscript','', 'Snapshot: 21 September 2026. Current working-copy final.md texts in curriculum spine and sequence order. Includes uncommitted edits.','']
toc=[];bodies=[];total=0
for index,seq in enumerate(sequences,1):
    name=seq['name'];folder=H/'sequences'/name
    manifest=json.loads((folder/f'{name}-book.manifest.json').read_text(encoding='utf-8'))
    capture=folder/f'{name}-book.md';text=capture.read_text(encoding='utf-8')
    assert hashlib.sha256(capture.read_bytes()).hexdigest()==manifest['output_sha256']
    assert hashlib.sha256((R/'commons/maps/sequences'/f'{name}.json').read_bytes()).hexdigest()==manifest['sequence_sha256']
    for source in manifest['maps']:
        assert hashlib.sha256((R/source['path']).read_bytes()).hexdigest()==source['sha256'],source['path']
    label=f'{index:02d} · {name.replace("_"," ")}'
    toc.append(f'<li><a href="#{name}">{html.escape(label)}</a> <small>{len(manifest["maps"])} halls</small></li>')
    parts += [f'# {index:02d}. {name.replace("_"," ")}', '', '\n'.join(text.splitlines()[1:]).strip(), '', '\n---\n']
    # Render each hall separately so its heading and relative source links stay local.
    import sys
    sys.path.insert(0,str(R/'tools'))
    from export_book_captures import clean_text
    articles=[]
    for source in manifest['maps']:
        raw=(R/source['path']).read_text(encoding='utf-8-sig');clean=clean_text(raw,source['map']);total+=len(clean.split())
        body=markdown.markdown(clean,extensions=['fenced_code','footnotes','tables',Strike()])
        base='/book-review/'+str(Path(source['path']).parent).replace('\\','/')+'/'
        def href(match):
            target=html.unescape(match[2])
            if target.startswith(('#','/')) or re.match(r'^[a-zA-Z][a-zA-Z0-9+.-]*:',target):return match[0]
            return match[1]+html.escape(urljoin(base,target),quote=True)+match[3]
        body=re.sub(r'((?:href|src)=")([^"]+)(")',href,body)
        # Namespace renderer-generated footnote backreference IDs too.
        body=re.sub(r'(id="|href="#)(fnref\d*:[^"]+)',lambda m:m[1]+source['map']+'--'+m[2],body)
        articles.append(f'<article id="{source["map"]}"><div class="map-id">{html.escape(source["map"])} · <a href="/compose/sources?map={source["map"]}&amp;doc=final">Read and comment on this hall</a></div>'+body+'</article>')
    bodies.append(f'<section id="{name}"><h2 class="sequence">{html.escape(label)}</h2>'+''.join(articles)+'</section>')
    manifests.append(manifest)
full='\n'.join(parts)
(H/'ada-research-full-book.md').write_text(full,encoding='utf-8')
brief='''# Read this first — Ada Research manuscript review

This is a frozen text snapshot from 21 September 2026: all 24 spine sequences, 196 hall manuscripts, in the current declared order. It includes local uncommitted edits and the latest Rhizome, Assembly and Synthesis chapters. The source hashes and sequence files are recorded in manifest.json. The manuscript itself has not been rewritten for export: only invisible artifact-routing comments are removed and footnote identifiers are scoped per hall. Code and footnote contents remain.

For a continuous read, use ada-research-full-book.md supplied separately. The sequence-texts.zip contains the same manuscript divided into 24 sequence files, plus this brief and the manifest. Choose either the continuous file or the split set; do not count both as different drafts. No original/revision comparisons or earlier review verdicts are mixed into this text.

## The book we want

Ada Research teaches how code makes a world while asking what bodies that world permits, what its representations let us know, and what they leave out. Its reader can be a beginner, an artist, or a curious maker. The voice should be poetic, critical and intelligible, grounded in specific artifacts, actions and source operations. Code can be part of the poetry and can give the reader a way to change an encounter. Strangeness, pleasure and the desire to make another world matter alongside limits.

The tutorial and critical inquiry can lead each other. Do not impose a repeated paragraph formula. Read the Point One, line, trace and grid passages as early reference points, then judge whether later chapters sustain or develop that investigative relation. The recent Rhizome, Assembly and Synthesis passages attempt to recover it after a drift towards technical reporting. These are intentions to test against the prose, not favourable verdicts to inherit.

## Please review

1. Read the full supplied text before making a whole-book judgement. State exactly which sequences you actually read and any omissions; if you cannot read everything in one pass, work through the ordered sequence files and defer the overall judgement.
2. Describe the book's strongest argument and the pedagogical path it actually delivers. Where do earlier capabilities return with a new consequence, and where is a step missing?
3. Quote brief, specific passages worth protecting. Identify where the voice becomes an audit, instructions without discovery, repeated generic criticism, or poetry that obscures the operation. Do not mistake all code or precise explanation for a voice failure.
4. Distinguish useful recurrence from repetition. A returning concept can do new work when scale, body, context, timing or question changes. Do not automatically cut the rabbit, desire, humour or other literary returns.
5. When the prose asks for an encounter it does not establish clearly, name that gap. Separate a proposed prose change from an artifact/spatial question. The museum's temporarily reduced primary-artifact selection is not a rule that every hall may contain only one important work. A strong passage may call for restoring or developing an artifact.
6. Prioritise a few substantial improvements, with sequence, exact map ID and passage. Some chapters are much more mature than others: do not demand equal rewriting everywhere. Offer a short illustrative revision where helpful, preserving the authorial voice.

This package is for an editorial reading. It contains no complete implementation or runtime evidence. Distinguish what the manuscript conveys from what an exhibit demonstrably does. Do not claim to have tested reach, movement, interaction or VR comfort. Source/space checks can follow the reading where a specific uncertainty warrants them.

Return an overall assessment, the most effective passages, the weakest transitions, a short prioritised map-specific revision list, and questions for the author where artistic intent is unclear. Please do not rewrite the whole book.
'''
(H/'START_HERE.md').write_text(brief,encoding='utf-8')
manifest={'captured_at':manifests[0]['captured_at'],'sequence_count':len(manifests),'hall_count':sum(len(m['maps']) for m in manifests),'words_whitespace_in_manuscripts':total,'spine_sha256':hashlib.sha256(spine.read_bytes()).hexdigest(),'full_book_sha256':hashlib.sha256((H/'ada-research-full-book.md').read_bytes()).hexdigest(),'sequences':manifests}
(H/'manifest.json').write_text(json.dumps(manifest,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
css='''*{box-sizing:border-box}html{scroll-behavior:smooth;scroll-padding-top:30px}body{margin:0;background:#f5f2eb;color:#242b29;font:19px/1.8 Georgia,serif}header,main,footer{max-width:900px;margin:auto;padding:30px 38px}header{padding-top:65px}h1{font-size:38px;font-weight:500;line-height:1.2}header h1{font-size:clamp(36px,6vw,64px)}h2,h3{line-height:1.3;font-weight:500}a{color:#24634f;text-underline-offset:3px}.meta,.map-id,nav,footer,summary{font:14px/1.65 system-ui,sans-serif}.map-id{color:#64706b;border-top:1px solid #c7cec6;padding-top:25px;overflow-wrap:anywhere}.sequence{font:22px/1.4 system-ui,sans-serif;background:#dee6dc;padding:20px;margin:60px 0 35px}article{margin:0 0 70px}pre{overflow:auto;background:#e8ece5;padding:20px;font:14px/1.65 ui-monospace,monospace}code{font-size:.85em}blockquote{margin:24px 0;padding-left:24px;border-left:3px solid #9eaf9c}img{max-width:100%;height:auto}nav{display:flex;gap:18px;flex-wrap:wrap;margin:25px 0}ol.toc{columns:2;padding-left:24px}ol.toc li{break-inside:avoid;margin:6px 0}small{color:#64706b}table{border-collapse:collapse;font-size:16px}td,th{border:1px solid #ccd3cb;padding:8px}.footnote{font-size:15px}.top{position:fixed;right:18px;bottom:15px;background:#fff;padding:5px 12px;border:1px solid #ccd3cb;font:13px system-ui}@media(max-width:650px){header,main,footer{padding:24px}ol.toc{columns:1}}@media print{nav,.top,details,.map-id a{display:none}.sequence{break-before:page}body{font-size:12pt;background:white}}'''
page='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Ada Research — full manuscript, 21 September 2026</title><style>'''+css+'''</style><header id="top"><div class="meta">Ada Research · manuscript snapshot · 21 September 2026</div><h1>Ada Research</h1><p>All 24 sequences and 196 hall manuscripts, in spine order. This is a reading copy of the current working text, including the latest ending.</p><div class="meta">'''+format(total,',')+''' words, including code and notes · snapshot, not a live editor</div><nav><a href="ada-research-full-book.md" download>Full manuscript Markdown</a><a href="sequences/index.md">Individual sequence texts</a><a href="START_HERE.md">Review brief for Claude</a><a href="manifest.json">Source versions</a></nav><details><summary>Review context and instructions</summary>'''+markdown.markdown(brief)+'''</details><ol class="toc">'''+''.join(toc)+'''</ol></header><main>'''+''.join(bodies)+'''</main><footer>The source final.md files remain unchanged. For the latest future edits use the hall reading and comments link. Localhost links work on this computer; attach the Markdown or ZIP when reviewing online.</footer><a class="top" href="#top">Contents ↑</a></html>'''
(H/'index.html').write_text(page,encoding='utf-8')
with zipfile.ZipFile(H/'sequence-texts.zip','w',zipfile.ZIP_DEFLATED) as z:
    for f in ['START_HERE.md','manifest.json']:z.write(H/f,f)
    for seq in sequences:
        f=H/'sequences'/seq['name']/(seq['name']+'-book.md');z.write(f,f.relative_to(H).as_posix())
assert 'The body that returned' in full
print(f'Built current full reader: {len(sequences)} sequences, {manifest["hall_count"]} halls, {total:,} words; all source hashes verified.')
