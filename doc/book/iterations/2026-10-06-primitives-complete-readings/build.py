"""Assemble both complete Primitives readings from current canonical manuscripts."""
from pathlib import Path
from urllib.parse import urlsplit, urlunsplit, quote, unquote
from html import escape
import json, hashlib, shutil, re, zipfile
from bs4 import BeautifulSoup

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
FACING=HERE.parent/'2026-10-05-primitives-facing-pages'
BASE='http://localhost:3003/book-review/'
seq=ROOT/'commons/maps/sequences/primitives.json'
halls=json.loads(seq.read_text(encoding='utf-8-sig'))['sequences']['primitives']['maps']
manifest=json.loads((FACING/'manifest.json').read_text(encoding='utf-8'))
assert halls==manifest['halls']
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
put=lambda p,s:p.write_text(s,encoding='utf-8',newline='\n')
HERE.mkdir(parents=True,exist_ok=True)
for row in manifest['sources']:assert sha(ROOT/row['path'])==row['sha256']
pages=manifest['pages']; page_to_hall={v:k for k,v in pages.items()}
labels={}; sections={'tutorial':[],'final':[]}; combined={'tutorial':[],'final':[]}
sources=[]; code_counts={'tutorial':0,'final':0}

def converted_link(url,side):
    u=urlsplit(url)
    if u.scheme or u.netloc or not u.path:return url
    name=Path(u.path).name
    if name in page_to_hall and '/' not in u.path:
        target_side='final' if '--final--' in u.fragment else ('tutorial' if '--tutorial--' in u.fragment else side)
        fragment=u.fragment or page_to_hall[name]
        return target_side+'.html#'+fragment
    target=(FACING/unquote(u.path)).resolve()
    assert target.is_file(),url
    return BASE+quote(target.relative_to(ROOT).as_posix(),safe='/')+('?' + u.query if u.query else '')+('#'+u.fragment if u.fragment else '')

def markdown_copy(content,hall,side):
    # Scope footnotes to their hall. Resolve relative document links without touching code.
    parts=re.split(r'(^```.*?^```[^\n]*$)',content,flags=re.M|re.S)
    def link(m):
        url=m[1];u=urlsplit(url)
        if u.scheme or u.netloc or not u.path or u.path.startswith('/'):return m[0]
        target=(ROOT/'commons/maps'/hall/unquote(u.path)).resolve()
        if not target.is_file():return m[0]
        return ']('+BASE+quote(target.relative_to(ROOT).as_posix(),safe='/')+('#'+u.fragment if u.fragment else '')+')'
    for i in range(0,len(parts),2):
        parts[i]=re.sub(r'\[\^([^\]]+)\]',lambda m:'[^'+hall+'-'+m[1]+']',parts[i])
        parts[i]=re.sub(r'\]\(([^\s)]+)\)',link,parts[i])
    result=''.join(parts)
    assert re.findall(r'^```.*?^```',result,re.M|re.S)==re.findall(r'^```.*?^```',content,re.M|re.S)
    return result

for number,hall in enumerate(halls,1):
    page=BeautifulSoup((FACING/pages[hall]).read_text(encoding='utf-8'),'html.parser')
    labels[hall]=page.select_one('.spread')['data-label']
    for side in ['tutorial','final']:
        source=ROOT/'commons/maps'/hall/(side+'.md')
        content=source.read_text(encoding='utf-8-sig')
        article=page.select_one('.page.'+side+' .prose')
        original_text=article.get_text()
        for tag in article.select('[href], [src]'):
            for attr in ['href','src']:
                if tag.has_attr(attr):tag[attr]=converted_link(tag[attr],side)
        assert article.get_text()==original_text
        count=len(article.select('pre'));code_counts[side]+=count
        reading='Tutorial' if side=='tutorial' else 'Reflection'
        other='final' if side=='tutorial' else 'tutorial'
        section=f'<section id="{hall}" class="hall"><div class="hall-head"><span>{number:02d} / {len(halls)} · {escape(labels[hall])}</span><a href="{other}.html#{hall}">Read the {"reflection" if other=="final" else "tutorial"} here ↗</a></div>{article}<a class="back" href="#contents">Back to contents ↑</a></section>'
        sections[side].append(section)
        combined[side].append(f'\n\n---\n\n<!-- Hall {number:02d}: {hall}; source: commons/maps/{hall}/{side}.md -->\n\n'+markdown_copy(content,hall,side))
        snapshot=HERE/'sources'/hall/(side+'.md');snapshot.parent.mkdir(parents=True,exist_ok=True)
        shutil.copyfile(source,snapshot)
        assert snapshot.read_bytes()==source.read_bytes()
        sources.append({'map':hall,'track':side,'source':source.relative_to(ROOT).as_posix(),'sha256':sha(source),'code_blocks':count})

CSS='''*{box-sizing:border-box}html{scroll-behavior:smooth;scroll-padding-top:90px}body{margin:0;background:#f4f1eb;color:#272522;font:19px/1.7 Georgia,serif}a{color:#943a5b;text-underline-offset:3px}nav{position:sticky;top:0;z-index:2;background:#f4f1ebf5;border-bottom:1px solid #d9d1c6;padding:16px 5vw;display:flex;flex-wrap:wrap;gap:12px 28px;font:14px/1.4 system-ui,sans-serif}nav a[aria-current]{font-weight:700;color:#242322}header,main,footer{max-width:950px;margin:auto;padding:42px 28px}h1{font-size:46px;line-height:1.15;font-weight:400}h2{font-size:31px;line-height:1.3}h3{font-size:24px;line-height:1.4}.eyebrow,.meta,.hall-head,.back{font:13px/1.6 system-ui,sans-serif}.eyebrow{letter-spacing:.12em}.meta{color:#665f59}#contents{margin:38px 0;padding:25px;background:#ebe5db}ol{padding-left:25px}.hall{border-top:1px solid #cfc5b8;padding:35px 0 65px;scroll-margin-top:85px}.hall-head{display:flex;justify-content:space-between;gap:20px;text-transform:uppercase;letter-spacing:.04em;margin-bottom:35px;color:#625b54}.prose>h1{font-size:38px}pre{background:#20272c;color:#f0ede6;padding:24px;border-radius:5px;overflow-x:auto;font:14px/1.65 Consolas,monospace;tab-size:4}code{font-family:Consolas,monospace;font-size:.88em}pre code{font-size:inherit}img{max-width:100%;height:auto}table{display:block;max-width:100%;overflow:auto;border-collapse:collapse;font-size:16px}td,th{border:1px solid #cbc3b7;padding:10px;text-align:left}blockquote{border-left:3px solid #bf95a5;margin-left:0;padding-left:25px}.footnote{font-size:15px}.back{display:inline-block;margin-top:35px}.choices{display:grid;grid-template-columns:1fr 1fr;gap:24px}.choice{padding:25px;background:#ebe5db;border:1px solid #d5cbbb}.choice h2{margin-top:0}@media(max-width:650px){header,main,footer{padding:26px 20px}h1{font-size:36px}.prose>h1{font-size:30px}.hall-head{display:block}.choices{grid-template-columns:1fr}pre{padding:16px;font-size:12px}nav{gap:10px 18px;padding:12px 20px}}@media print{nav,.back,.hall-head a,.downloads{display:none}body{background:white;color:black;font-size:11pt}header,main{max-width:none;padding:0}.hall{break-before:page}pre{background:#f1f1f1;color:black;white-space:pre-wrap;overflow:visible;font-size:8pt}a{color:inherit}.footnote{font-size:9pt}h1,h2,h3{break-after:avoid}img{break-inside:avoid}}'''

def document(title,body,side=''):
    nav='<nav aria-label="Readings"><a href="index.html">Primitives</a>'+''.join(f'<a href="{s}.html"'+(' aria-current="page"' if side==s else '')+'>'+label+'</a>' for s,label in [('tutorial','Whole tutorial'),('final','Whole reflection')])+f'<a href="{BASE}{FACING.relative_to(ROOT).as_posix()}/index.html">Facing pages</a></nav>'
    nav=nav.replace('</nav>','<a href="../2026-10-06-what-the-next-room-keeps/notes.html">What carries onward</a></nav>')
    return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+escape(title)+'</title><style>'+CSS+'</style></head><body>'+nav+body+'</body></html>'

checks={}
for side in ['tutorial','final']:
    title='Primitives — '+('the complete tutorial' if side=='tutorial' else 'the complete reflective sequence')
    toc='<div id="contents"><h2>Contents</h2><ol>'+''.join(f'<li><a href="#{h}">{escape(labels[h])}</a></li>' for h in halls)+'</ol></div>'
    intro='All 15 tutorial.md texts, including their full code listings.' if side=='tutorial' else 'All 15 final.md texts, including their notes and references.'
    header=f'<header><p class="eyebrow">ENDLESS MUSEUM · 6 OCTOBER 2026</p><h1>{escape(title)}</h1><p>{intro} Read continuously in the current museum order, from Point Zero to Melencolia.</p><p class="downloads"><a href="primitives-{side}.md" download>Download the complete Markdown</a> · <a href="primitives-source-texts.zip" download>Download both tracks by hall</a></p>{toc}</header>'
    body=header+'<main>'+''.join(sections[side])+'</main><footer class="meta">Compiled from current canonical manuscripts. The source texts are unchanged. Footnote identifiers and local links are adapted for this continuous reading.</footer>'
    rendered=document(title,body,side)
    soup=BeautifulSoup(rendered,'html.parser');ids=[n['id'] for n in soup.select('[id]')]
    assert len(ids)==len(set(ids))
    assert len(soup.select('section.hall'))==len(halls)
    for a in soup.select('a[href^="#"]'):assert a['href'][1:] in ids,a['href']
    assert len(soup.select('pre'))==code_counts[side]
    put(HERE/(side+'.html'),rendered)
    put(HERE/('primitives-'+side+'.md'),'# '+title+'\n\nComplete current sequence · 6 October 2026\n'+''.join(combined[side]))
    checks[side]={'halls':len(halls),'code_blocks':code_counts[side],'complete_visible_text':True,'unique_ids':True,'local_anchors_valid':True}

index='<header><p class="eyebrow">ENDLESS MUSEUM · PRIMITIVES</p><h1>Two complete readings.</h1><p>All 15 halls, in the current spine order. Tutorial and reflection each have their own continuous page, contents and Markdown download.</p><div class="choices"><div class="choice"><h2>Make</h2><p>The complete tutorial, with all code listings.</p><a href="tutorial.html">Read the whole tutorial →</a></div><div class="choice"><h2>Reflect</h2><p>The complete final.md sequence, with notes.</p><a href="final.html">Read the whole reflection →</a></div></div></header><main><h2>The route</h2><ol>'+''.join(f'<li>{escape(labels[h])} · <a href="tutorial.html#{h}">Tutorial</a> · <a href="final.html#{h}">Reflection</a></li>' for h in halls)+'</ol><p><a href="primitives-source-texts.zip" download>Download all 30 source texts</a></p></main>'
put(HERE/'index.html',document('Primitives — complete readings',index))
with zipfile.ZipFile(HERE/'primitives-source-texts.zip','w',zipfile.ZIP_DEFLATED) as z:
    for row in sources:z.write(ROOT/row['source'],row['map']+'/'+row['track']+'.md')
assert all(sha(ROOT/r['source'])==r['sha256'] for r in sources)
put(HERE/'manifest.json',json.dumps({'compiled':'2026-10-06','sequence_sha256':sha(seq),'halls':halls,'sources':sources,'checks':checks,'canonical_sources_unchanged':True},ensure_ascii=False,indent=2)+'\n')
print(json.dumps(checks))
