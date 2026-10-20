"""Publish current fourteen-hall readings and the scoped route-change evidence."""
from pathlib import Path
import hashlib
import html
import json
import re
import shutil
import sys
from html.parser import HTMLParser
from urllib.parse import unquote, urlsplit
import markdown
from em_refresh_sequence import sequence_maps
from publish_randomness_revision import STYLE, publish_plan

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'doc/book/iterations/2026-10-09-randomness-without-the-ladder'


def read(rel):
    return json.loads((ROOT/rel).read_text(encoding='utf-8-sig'))


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


def main():
    spec = read('commons/maps/sequences/randomness.json')['sequences']['randomness']
    maps = spec['maps']
    route, spine = sequence_maps('randomness')
    plan = read('commons/data/museum/em_plan.json')
    authored = read('commons/data/map_authored.json')
    strip = read('commons/data/long_museum.json')
    restored = json.loads((OUT/'deferred-ladder.json').read_text(encoding='utf-8'))
    assert len(maps) == 14 and len(route) == 15
    assert route == authored['randomness'] == [r['map'] for r in plan['plans'] if r.get('sequence') == 'randomness']
    assert route == [r['name'] for r in strip['segments'] if r.get('sequence') == 'randomness' and r['kind'] == 'hall']
    assert spine[spine.index('randomness')+1] == 'noise'
    assert route[-1] == 'Random_Game' and restored['map'] not in route
    assert all(sha(ROOT/p) == digest for p,digest in restored['source_hashes'].items())
    before = json.loads((OUT/'before/commons/data/museum/em_plan.json').read_text(encoding='utf-8-sig'))
    assert [r for r in before['plans'] if r.get('sequence') != 'randomness'] == [r for r in plan['plans'] if r.get('sequence') != 'randomness']
    for r in before['plans']:
        if r.get('sequence') != 'randomness' or r.get('map') == restored['map']:
            continue
        current = next(c for c in plan['plans'] if c.get('map') == r['map'])
        ignored = ('pearl_index','pearls_total')
        assert {k:v for k,v in r.items() if k not in ignored} == {k:v for k,v in current.items() if k not in ignored}
    log = (OUT/'route-engine.log').read_text(encoding='utf-8')
    native = json.loads(next(line.split('RANDOMNESS_ROUTE ',1)[1] for line in log.splitlines() if line.startswith('RANDOMNESS_ROUTE ')))
    assert native['passed'] and native['route'] == route
    assert 'SCRIPT ERROR' not in log and 'Parse Error' not in log

    nav = '<a href="index.html">Sequence assessment</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="../2026-10-09-randomness-revision/index.html">Hall reports</a>'
    def shell(title, body):
        return f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{html.escape(title)}</title><style>{STYLE}section.lesson{{border-top:2px solid #b9aaa4;margin-top:4em;padding-top:2em}}.contents{{columns:2;column-gap:30px}}.contents li{{break-inside:avoid}}@media(max-width:650px){{.contents{{columns:1}}}}@media print{{section.lesson{{break-before:page}}details{{display:block}}}}</style><main><nav>{nav}</nav>{body}</main></html>'
    def portable(text):
        def copy_image(match):
            url = match.group(1)
            source = ROOT.parent/'ada_encyclopedia/public'/url.lstrip('/')
            assert source.exists(), source
            dest = OUT/'images'/source.name
            dest.parent.mkdir(exist_ok=True)
            shutil.copy2(source,dest)
            return ']('+dest.relative_to(OUT).as_posix()+')'
        return re.sub(r'\]\((/book-images/[^)]+)\)',copy_image,text)

    inventory=[]
    for track in ['tutorial','final']:
        title = 'Randomness — '+('complete tutorial' if track == 'tutorial' else 'complete reflective sequence')
        intro = f'# {title}\n\nCurrent canonical texts, 2026-10-09. Fourteen teaching halls in spine order. Biome Cage remains an unnumbered museum interlude after Mushrooms; the closing Biome Ladder is deferred. Random Game leads directly to Noise Types.\n\n'
        contents = '<ol class="contents">'+''.join(f'<li><a href="#{m}">{html.escape(m.replace("_"," "))}</a></li>' for m in maps)+'</ol>'
        full = intro
        body = markdown.markdown(intro,extensions=['extra'])+f'<p><a href="{track}.md">Complete Markdown</a></p>'+contents
        for i,m in enumerate(maps,1):
            source = ROOT/'commons/maps'/m/(track+'.md')
            text = portable(source.read_text(encoding='utf-8-sig'))
            rendered = markdown.markdown(text,extensions=['extra'])
            # Footnote anchors remain local to their individual chapter.
            rendered = re.sub(r'(id="|href="#)(fn[^" ]+)',lambda v:v[1]+m+'-'+v[2],rendered)
            if track == 'tutorial':
                printed = re.findall(r'```gdscript\s*\n(.*?)```',text,re.S)
                shown = [html.unescape(c) for c in re.findall(r'<pre><code class="language-gdscript">(.*?)</code></pre>',rendered,re.S)]
                assert len(printed) == len(shown) and all(a.rstrip().expandtabs(4) == b.rstrip() for a,b in zip(printed,shown)),m
                prose = re.sub(r'```.*?```','',text,flags=re.S)
                inventory.append({'map':m,'tutorial_prose_words_approx':len(prose.split()),'gdscript_lines':sum(len(c.splitlines()) for c in printed),'tutorial_sha256':sha(source),'final_sha256':sha(ROOT/'commons/maps'/m/'final.md'),'final_words_approx':len((ROOT/'commons/maps'/m/'final.md').read_text(encoding='utf-8-sig').split())})
            body += f'<section class="lesson" id="{m}"><p>{i:02d} / 14 · {html.escape(m.replace("_"," "))}</p>{rendered}</section>'
            full += f'\n\n---\n\n## {i:02d} · {m}\n\n'+text
        (OUT/(track+'.html')).write_text(shell(title,body),encoding='utf-8')
        (OUT/(track+'.md')).write_text(full,encoding='utf-8')
    report = (OUT/'REPORT.md').read_text(encoding='utf-8')
    (OUT/'index.html').write_text(shell('Randomness — sequence reading',markdown.markdown(report,extensions=['extra'])),encoding='utf-8')
    # Compare current last-hall listings with its tested extraction, not an
    # old sequence hash (the route is intentionally different now).
    text = (ROOT/'commons/maps/Random_Game/tutorial.md').read_text(encoding='utf-8')
    blocks = dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',text,re.S))
    tested = ROOT/'doc/book/iterations/2026-10-09-randomness-revision/Random_Game/extracted/printed'
    assert all((tested/name).read_text(encoding='utf-8') == code+'\n' for name,code in blocks.items())
    warnings = [line for line in log.splitlines() if line.startswith(('ERROR:','WARNING:'))]
    verification = {'teaching_halls':14,'museum_spaces':15,'museum_route':route,'next_sequence':'noise','next_map':'Random_Noise_Types','native_plan_loader':native,'native_log_messages':warnings,'remaining_room_geometry_unchanged':True,'unrelated_plan_rows_unchanged':True,'deferred_sources_unchanged':True,'game_printed_code_matches_tested_extraction':True,'rendered_code_parity':True,'fresh_headset_traversal':False,'fresh_full_lesson_test_run':False,'reading_inventory':inventory,'scope':'Route and handoff edit plus editorial assessment. Native plan loading, not whole-route collision or learner acceptance. Earlier hall tests remain their own dated evidence.'}
    (OUT/'verification.json').write_text(json.dumps(verification,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
    publish_plan()
    class Links(HTMLParser):
        def __init__(self):super().__init__();self.refs=[];self.ids=[]
        def handle_starttag(self,tag,attrs):
            a=dict(attrs)
            if 'id' in a:self.ids.append(a['id'])
            for k in ['href','src']:
                if k in a:self.refs.append(a[k])
    checked=0
    for p in OUT.glob('*.html'):
        parsed=Links();parsed.feed(p.read_text(encoding='utf-8'))
        assert len(parsed.ids)==len(set(parsed.ids)),p
        for ref in parsed.refs:
            u=urlsplit(ref)
            if u.scheme:continue
            if not u.path:
                assert not u.fragment or unquote(u.fragment) in parsed.ids,(p,ref)
            else:
                assert (p.parent/unquote(u.path)).resolve().exists(),(p,ref)
            checked+=1
    print(json.dumps({'report':str(OUT/'index.html'),'local_links_checked':checked,'native_route_passed':True,'rendered_code_parity':True,'lessons':len(maps)}))


if __name__ == '__main__':
    main()
