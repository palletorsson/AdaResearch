"""Local journal and sequence-memory publication; preserve all thirty manuscripts."""
from pathlib import Path
from urllib.parse import urlsplit,quote
import json,hashlib,shutil,urllib.request
import markdown
from bs4 import BeautifulSoup

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
WEB=ROOT.parent/'ada_encyclopedia'
SLUG=HERE.name
BASE='http://localhost:3003'
read=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def put(p,text):
    p.parent.mkdir(parents=True,exist_ok=True)
    p.write_text(text,encoding='utf-8',newline='\n')
def save(p,data):put(p,json.dumps(data,ensure_ascii=False,indent=2)+'\n')
def backup(p):
    target=HERE/'before'/p.relative_to(ROOT)
    if not target.exists():target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(p,target)
def api(body=None):
    request=urllib.request.Request(BASE+'/api/tutorial-plan',data=None if body is None else json.dumps(body).encode(),headers={'Origin':BASE,'Content-Type':'application/json'})
    with urllib.request.urlopen(request,timeout=90) as r:return json.load(r)

halls=read(ROOT/'commons/maps/sequences/primitives.json')['sequences']['primitives']['maps']
pins={f'commons/maps/{h}/{n}':sha(ROOT/f'commons/maps/{h}/{n}') for h in halls for n in ['tutorial.md','final.md','map_data.json']}
pins['commons/maps/sequences/primitives.json']=sha(ROOT/'commons/maps/sequences/primitives.json')
notes=ROOT/'doc/book/course/execution-plan/PRIMITIVES_TAKEAWAYS.md'

for name in ['doc/book/course/execution-plan/plan.json','doc/book/course/execution-plan/README.md','doc/book/course/execution-plan/REVIEW.md','doc/book/course/storyboards/BRIEF.md','doc/book/course/storyboards/CONTEXT.md']:backup(ROOT/name)
current=api()
sequence=dict(next(s for s in current['plan']['sequences'] if s['id']=='primitives'))
sequence.update(
    aim='Make a running world available for construction: distinguish execution, position, frame, relation, record, representation, connectivity, generating rule and finite limit; compose with what those distinctions permit.',
    carry='Reuse PointBody and CubeBody recipes, independent resources, local/world frames, retained records and face connections. A saved drawing, a class and a live node are different kinds of continuity. Carry placement versus construction into Transformation, using familiar bodies to study change through time.',
    check='Offer an independent arrangement using generated positions, a preserved source and altered copy, a valid indexed face and two sphere resolutions. Ask for predictions, execution and an explanation of the choices. The exercise is assigned; independent learner understanding has not been observed.',
    note='6 October: all fifteen Primitives tutorial/final pairs exist; Trace → Grid and the nine later learner programs have native evidence. Consolidate this chapter rather than restart it. For each comparison ask BRING / CHANGE / KEEP / LEARN / TEST / CARRY. Mark concept roles supplied, introduced, practised, or independently demonstrated with evidence; supplied syntax is not mastery. Takeaways: /book-review/doc/book/iterations/'+SLUG+'/notes.html. Next: inspect Transformation using the familiar sphere/cube. Keep reflection and runnable reconstruction distinct; sequence order remains editable.')
api({'kind':'sequence','revision':current['revision'],'record':sequence})

brief_path=ROOT/'doc/book/course/storyboards/BRIEF.md'
brief=brief_path.read_text(encoding='utf-8')
addition='''**Comparison and carry, 6 October:** use **BRING → CHANGE → KEEP → LEARN → TEST → CARRY** to specify the particular comparison. What is kept can differ between experiments in the same hall. Mark each concept's role as supplied, introduced, practised, or independently demonstrated; the last needs observed learner work, not a passed script or an assigned exercise. Keep source/evidence links behind the short brief. [Primitives takeaways](../execution-plan/PRIMITIVES_TAKEAWAYS.md) record fifteen concrete comparisons and the handoff to Transformation. These are planning guides, not compulsory prose headings.

'''
if '**Comparison and carry, 6 October:**' not in brief:put(brief_path,brief.replace('# Tutorial storyboards\n\n','# Tutorial storyboards\n\n'+addition,1))
readme_path=ROOT/'doc/book/course/execution-plan/README.md';text=readme_path.read_text(encoding='utf-8')
old=next(l for l in text.splitlines() if l.startswith('Started 5 October 2026.'))
new='Started 5 October 2026. An editable execution plan for the existing Endless Museum, connecting the author’s 116-subject inventory to 25 sequences and 207 halls. The original census below records the planning baseline. By 6 October the fifteen Primitives tutorial/reflection pairs are assembled, including the saved Trace → Grid handoff and nine tested continuations through Melencolia. [What carries onward](PRIMITIVES_TAKEAWAYS.md) records the current sequence decisions; the Primitives capacity entry is updated to match. Native evidence and human learning remain separate.'
put(readme_path,text.replace(old,new,1))
review_path=ROOT/'doc/book/course/execution-plan/REVIEW.md';text=review_path.read_text(encoding='utf-8')
addition='**Primitives update, 6 October:** the opening sequence now has fifteen paired texts and source-bound evidence for its learner programs. Its current consolidation and handoff are recorded in [Primitives takeaways](PRIMITIVES_TAKEAWAYS.md). Earlier next-step instructions below are the review baseline; do not use them to reopen completed Trace → Grid or the nine later Primitives lessons.\n\n'
if '**Primitives update, 6 October:**' not in text:
    first,rest=text.split('\n',1);put(review_path,first+'\n\n'+addition+rest.lstrip('\n'))
context_path=ROOT/'doc/book/course/storyboards/CONTEXT.md';text=context_path.read_text(encoding='utf-8')
addition='''
## What the next room keeps — 6 October

The author requested a blog and clearer sequence takeaways after reading both Primitives tracks together. [Sequence notes](../execution-plan/PRIMITIVES_TAKEAWAYS.md) name a bounded change/keep comparison for each of the fifteen halls. The compact editorial contract is BRING → CHANGE → KEEP → LEARN → TEST → CARRY. Concept role and code verification are separate: supplied / introduced / practised describe lesson design; independently demonstrated needs observed learner work. No human mastery is claimed.

The editable Primitives sequence aim/carry/check/note now replaces its stale instruction to finish Trace → Grid before mesh lessons. Next work is a source-led Transformation pass using familiar PointBody/CubeBody constructions. Do not automatically rewrite Primitives or make every future sequence follow its pattern. [Research journal](../../iterations/2026-10-06-what-the-next-room-keeps/index.html). This documentation pass changes neither museum behaviour nor the thirty chapter manuscripts.
'''
if '## What the next room keeps — 6 October' not in text:put(context_path,text.rstrip()+'\n'+addition)

CSS='''*{box-sizing:border-box}body{margin:0;background:#f4f0e8;color:#292722;font:20px/1.78 Georgia,serif}header,footer{padding:20px 5vw;font:13px/1.6 system-ui,sans-serif;border-bottom:1px solid #d6cbbb}header{display:flex;justify-content:space-between;flex-wrap:wrap;gap:15px}nav{display:flex;gap:20px;flex-wrap:wrap}main{max-width:850px;margin:60px auto;padding:0 28px}h1{font-size:clamp(42px,7vw,72px);line-height:1.06;letter-spacing:-.03em;font-weight:400}h2{font-size:31px;line-height:1.25;margin-top:48px}a{color:#923d62;text-underline-offset:4px}p{margin:25px 0}main>p:first-of-type{font:14px/1.6 system-ui;color:#655d55}blockquote{border-left:3px solid #ba8b9e;margin:35px 0;padding:4px 25px;background:#ebe2d8}code{font:.86em Consolas,monospace}table{display:block;overflow-x:auto;width:100%;border-collapse:collapse;font:14px/1.65 system-ui,sans-serif}td,th{border-bottom:1px solid #d6cbbb;padding:12px;text-align:left;min-width:140px;vertical-align:top}td:first-child,th:first-child{min-width:110px}li{margin:13px 0}footer{border-top:1px solid #d6cbbb;border-bottom:0;color:#655d55}hr{border:0;border-top:1px solid #d6cbbb;margin-top:48px}@media(max-width:650px){body{font-size:18px}main{padding:0 20px;margin-top:32px}header{padding:15px 20px}}@media print{header,footer{display:none}body{background:white;font-size:11pt}main{max-width:none;margin:0;padding:0}h1{font-size:32pt}table{display:table;font-size:9pt}td,th{min-width:0}h2{break-after:avoid}}'''
def links_in(markup,source):
    soup=BeautifulSoup(markup,'html.parser')
    for a in soup.select('a[href]'):
        u=urlsplit(a['href'])
        if u.scheme or u.netloc or not u.path or u.path.startswith('/'):continue
        target=(source.parent/u.path).resolve();assert target.is_file(),a['href']
        a['href']='/book-review/'+quote(target.relative_to(ROOT).as_posix(),safe='/')+('#'+u.fragment if u.fragment else '')
    return str(soup)
def page(title,body):
    return '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+title+'</title><style>'+CSS+'</style><header><span>ADA / RESEARCH JOURNAL</span><nav><a href="index.html">The article</a><a href="notes.html">Sequence takeaways</a><a href="http://localhost:3003/tutorial-plan?view=sequences&seq=primitives">Edit sequence capacity</a></nav></header><main>'+body+'</main><footer>6 October 2026 · Local research journal · Editorial reasoning, verified behaviour and learner understanding remain distinct.</footer></html>'
# notes.html is referenced by the article; create it before resolving its links.
put(HERE/'notes.html','')
put(HERE/'index.html','')
article=(HERE/'BLOG.md').read_text(encoding='utf-8')
body=links_in(markdown.markdown(article,extensions=['extra','toc']),HERE/'BLOG.md')
put(HERE/'index.html',page('What the next room keeps',body))
put(HERE/'notes.html',page('Primitives — what carries onward',links_in(markdown.markdown(notes.read_text(encoding='utf-8'),extensions=['extra','toc']),notes)))
post_body='\n'.join(article.splitlines()[4:]).lstrip()
# Preserve Markdown in the journal; resolve links into the existing review routes.
import re
def resolve(m):
    href=m[1];u=urlsplit(href)
    if u.scheme or u.netloc or href.startswith('/'):return m[0]
    dest=(HERE/u.path).resolve();assert dest.is_file()
    return '](/book-review/'+dest.relative_to(ROOT).as_posix()+('#'+u.fragment if u.fragment else '')+')'
post_body=re.sub(r'\]\(([^)]+)\)',resolve,post_body)
front='''---
title: "What the next room keeps"
subtitle: "Learning to change an object, preserve a record, and carry a capacity into another room"
date: "2026-10-06"
author: "Ada Research"
tags: ["pedagogy", "tutorials", "artistic-research", "primitives", "ghost-student"]
sequence: "primitives"
---

'''
post=WEB/'src/content/blog'/f'{SLUG}.md'
assert post.parent.is_dir();put(post,front+post_body)
assert all(sha(ROOT/p)==h for p,h in pins.items())
save(HERE/'checks.json',{'source_pins':pins,'thirty_manuscripts_unchanged':True,'maps_and_sequence_order_unchanged':True,'native_rerun':False,'local_blog_route':'/blog/'+SLUG,'local_post':str(post),'sequence_notes':notes.relative_to(ROOT).as_posix(),'remote_deployment':False,'sequence_capacity':sequence})
print('Local journal written; sequence takeaways, capacity and working memory updated. Thirty manuscripts and runtime preserved.')
