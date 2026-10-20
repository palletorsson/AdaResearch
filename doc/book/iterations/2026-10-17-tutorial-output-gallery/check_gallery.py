"""Check gallery assets, links, fragments and pinned source/image identity."""
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urljoin, urlsplit, unquote
from urllib.request import urlopen
from concurrent.futures import ThreadPoolExecutor
import hashlib,json

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
BASE='http://localhost:3003/book-review/'+HERE.relative_to(ROOT).as_posix()+'/'
class Page(HTMLParser):
    def __init__(self,text):
        super().__init__();self.links=[];self.ids=set();self.scripts=0;self.feed(text)
    def handle_starttag(self,tag,attrs):
        d=dict(attrs)
        if 'id' in d:self.ids.add(d['id'])
        if tag=='script':self.scripts+=1
        for key in ['href','src']:
            if d.get(key):self.links.append(d[key])
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
    receipt=json.loads((HERE/'verification.json').read_text())
    for name,digest in receipt['source_files'].items():assert sha(HERE/name)==digest,name
    for name,digest in receipt['preserved'].items():assert sha(ROOT/name)==digest,name
    for frame in receipt['frames']:assert sha(HERE/frame['file'])==frame['sha256'],frame['file']
    assert sha(HERE/'generated/ada_student_trace.scn')==receipt['trace']['sha256']
    urls=set();fragments=0
    for path in HERE.glob('*.html'):
        page=Page(path.read_text(encoding='utf-8')); assert page.scripts==0,path
        for ref in page.links:
            url=urljoin(BASE+path.name,ref);parts=urlsplit(url)
            if parts.netloc!='localhost:3003':continue
            target=ROOT/unquote(parts.path.removeprefix('/book-review/'))
            assert target.is_file(),(path.name,ref)
            if parts.fragment:
                assert parts.fragment in Page(target.read_text(encoding='utf-8')).ids,(path.name,ref)
                fragments+=1
            urls.add(url.split('#')[0])
    def fetch(url):
        try:
            with urlopen(url,timeout=30) as response:
                body=response.read()
                assert response.status==200 and body,url
                return {'url':url,'status':response.status,'bytes':len(body)}
        except Exception as exc:
            raise RuntimeError(url+' '+str(exc)) from exc
    with ThreadPoolExecutor(max_workers=6) as pool:results=list(pool.map(fetch,sorted(urls)))
    report={'passed':True,'pages':len(list(HERE.glob('*.html'))),'http_files':len(results),'fragment_links':fragments,'source_files':len(receipt['source_files']),'image_hashes':len(receipt['frames']),'preserved_files':len(receipt['preserved']),'saved_trace_hash_matches':True,'results':results}
    (HERE/'reading-check.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    print('PASS',report['pages'],'pages;',len(results),'HTTP files;',fragments,'fragment links;',len(receipt['frames']),'image hashes.')
if __name__=='__main__':main()
