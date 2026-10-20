"""Publish the loom journal in the existing local blog, retaining image snapshots."""
from pathlib import Path
import hashlib
import html
import json
import re
import shutil
import urllib.request
import markdown
import yaml

ROOT = Path(__file__).resolve().parents[1]
SLUG = '2026-10-10-weaving-a-program-into-cloth'
OUT = ROOT/'doc/blog'/SLUG
REVIEW = ROOT/'doc/book/iterations/2026-10-10-jacquard-cards-and-layers'
CANONICAL = ROOT.parent/'ada_encyclopedia/src/content/blog'/f'{SLUG}.md'
PUBLIC_IMAGES = ROOT.parent/'ada_encyclopedia/public/book-images/blog'/SLUG
REFERENCE = Path('C:/Users/palle/AppData/Local/Temp/codex-clipboard-231141f6-4bf6-4956-a7c1-cc90d977d7c6.png')

def digest(p): return hashlib.sha256(p.read_bytes()).hexdigest()

def main():
    OUT.joinpath('images').mkdir(parents=True,exist_ok=True)
    PUBLIC_IMAGES.mkdir(parents=True,exist_ok=True)
    receipts = [json.loads((REVIEW/n).read_text()) for n in ['tests.json','museum-tests.json']]
    assert all(r['passed'] and all(c['passed'] for c in r['checks']) for r in receipts)
    assert len(receipts[0]['checks']) >= 58 and len(receipts[1]['checks']) >= 9
    sources = {n+'.png':REVIEW/(n+'.png') for n in ['tartan-museum','tartan-controls','tartan-flat','tartan-detail','tartan-layers']}
    sources['card-chain-reference.png'] = REFERENCE
    images = []
    for name,source in sources.items():
        target = OUT/'images'/name
        shutil.copyfile(source,target)
        shutil.copyfile(source,PUBLIC_IMAGES/name)
        assert digest(source)==digest(target)
        assert digest(source)==digest(PUBLIC_IMAGES/name)
        images.append({'file':name,'source':str(source),'sha256':digest(target),'type':'supplied reference photograph' if source==REFERENCE else 'native Godot capture'})
    post = (OUT/'post.md').read_text(encoding='utf-8')
    front,body = post[4:].split('\n---\n',1)
    meta = yaml.safe_load(front)
    for ref in re.findall(r'(?:\]\(|src=")(/book-review/[^)"#]+)',post):
        assert (ROOT/ref.removeprefix('/book-review/')).exists(),ref
    CANONICAL.write_bytes((OUT/'post.md').read_bytes())
    assert CANONICAL.read_bytes()==(OUT/'post.md').read_bytes()
    rendered = markdown.markdown(body,extensions=['fenced_code','tables'])
    rendered = re.sub(r'<p>(<img [^>]+>)</p>\s*<p><em>(.*?)</em></p>',r'<figure>\1<figcaption>\2</figcaption></figure>',rendered,flags=re.S)
    rendered = rendered.replace(f'/book-images/blog/{SLUG}/','images/')
    # Root-relative reading links work in the app; portable HTML also has a blog link.
    css = '''*{box-sizing:border-box}body{margin:0;background:#f2eee5;color:#282a2c;font:20px/1.75 Georgia,serif}main{max-width:1180px;margin:auto;padding:28px 24px 80px}nav{display:flex;gap:25px;flex-wrap:wrap;border-bottom:1px solid #ccc2b3;padding:8px 0 20px;font:14px/1.5 system-ui}a{color:#315349;text-underline-offset:4px}header{max-width:760px;margin:60px auto 35px}h1{font:clamp(40px,6vw,70px)/1.07 Georgia,serif;letter-spacing:-.03em;margin:14px 0 24px}.date,figcaption,footer{font:14px/1.6 system-ui;color:#64615d}.subtitle{font-size:25px;line-height:1.4;color:#535c55}article>p{max-width:740px;margin:25px auto}figure{margin:42px auto}figure img{display:block;width:100%;height:auto}figcaption{max-width:740px;margin:12px auto}footer{max-width:740px;border-top:1px solid #ccc2b3;margin:45px auto 0;padding-top:18px}@media(max-width:650px){body{font-size:18px}main{padding:20px 16px 50px}header{margin-top:35px}figure{margin:28px auto}}'''
    page = f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{html.escape(meta['title'])} · Endless Museum</title><style>{css}</style></head><body><main><nav><a href="http://localhost:3003/blog/{SLUG}">Read in the blog</a><a href="post.md">Editable Markdown</a><a href="/book-review/doc/book/iterations/2026-10-10-jacquard-cards-and-layers/index.html">Loom report</a></nav><header><div class="date">10 October 2026 · Endless Museum · Tiling</div><h1>{html.escape(meta['title'])}</h1><p class="subtitle">{html.escape(meta['subtitle'])}</p></header><article>{rendered}</article><footer>Ada Research · Five native Godot captures and one supplied reference photograph.</footer></main></body></html>'''
    (OUT/'index.html').write_text(page,encoding='utf-8')
    url=f'http://localhost:3003/blog/{SLUG}'
    with urllib.request.urlopen(url,timeout=30) as response:
        served=response.read().decode('utf-8')
        assert response.status==200 and meta['title'] in served
    for name in sources:
        with urllib.request.urlopen(f'http://localhost:3003/book-images/blog/{SLUG}/{name}',timeout=30) as response:
            assert response.status==200 and response.headers['Content-Type'].startswith('image/')
            assert hashlib.sha256(response.read()).hexdigest()==digest(OUT/'images'/name)
    checks={'url':url,'canonical':str(CANONICAL),'source_mirror_identical':True,'images':images,'image_count':len(images),'latest_runtime_receipt_count':len(receipts[0]['checks']),'latest_museum_receipt_count':len(receipts[1]['checks']),'hanging_chain':'implemented in linked follow-up' if 'Later on 10 October' in body else 'proposal, not implemented','http_status':200,'browser_layout_checked':False}
    (OUT/'publication-checks.json').write_text(json.dumps(checks,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({'url':url,'images':len(images),'source':str(OUT/'post.md')}))

if __name__=='__main__':main()
