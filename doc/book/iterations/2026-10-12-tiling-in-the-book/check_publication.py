"""Check navigation, images, source parity and protected current reflections."""
from prepare import HERE, ROOT, HALLS, put, sha
from html.parser import HTMLParser
from urllib.parse import urlsplit,unquote
import json,re

class Links(HTMLParser):
    def __init__(self):super().__init__();self.links=[];self.ids=[]
    def handle_starttag(self,tag,attrs):
        d=dict(attrs)
        if 'id' in d:self.ids.append(d['id'])
        if tag in ['a','img']:
            url=d.get('href') if tag=='a' else d.get('src')
            if url:self.links.append(url)

def main():
    errors=[];pages=[HERE/'index.html',HERE/'all.html',HERE/'final.html']+[HERE/h/'parallel.html' for h in HALLS]
    for p in pages:
        parser=Links();parser.feed(p.read_text(encoding='utf-8'))
        if len(parser.ids)!=len(set(parser.ids)):errors.append((str(p),'duplicate anchors'))
        for url in parser.links:
            u=urlsplit(url)
            if u.scheme or u.netloc:continue
            path=unquote(u.path)
            if path.startswith('/book-review/'):target=ROOT/path[len('/book-review/'):]
            elif path.startswith('/'):continue # App route, not a file.
            else:target=(p.parent/path).resolve() if path else p
            if not target.is_file():errors.append((p.name,url,'missing file'));continue
            if u.fragment and target.suffix=='.html':
                other=Links();other.feed(target.read_text(encoding='utf-8'))
                if unquote(u.fragment) not in other.ids:errors.append((p.name,url,'missing anchor'))
    for h in HALLS:
        for n in ['tutorial.md','final.md']:
            if sha(HERE/h/n)!=sha(ROOT/'commons/maps'/h/n):errors.append((h,n,'canonical drift'))
    for p,d in json.loads((HERE/'preserved.json').read_text()).items():
        if sha(ROOT/p)!=d:errors.append((p,'protected source drift'))
    plan=json.loads((ROOT/'doc/book/course/execution-plan/plan.json').read_text(encoding='utf-8'))
    for h in HALLS:
        entry=next(x for x in plan['lessons'] if x['id']==h)
        assert entry['baseline']['tutorial']==sha(ROOT/'commons/maps'/h/'tutorial.md')
    result={'passed':not errors,'html_pages':len(pages),'errors':errors,'canonical_parity':not errors,'protected_sources_unchanged':not errors,'scope':'Static file/anchor/source checks. Native GPU images inspected separately; no browser render or headset claim.'}
    put(HERE/'publication-checks.json',json.dumps(result,indent=2)+'\n')
    print(json.dumps(result,indent=2));assert not errors

if __name__=='__main__':main()
