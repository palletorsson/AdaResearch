from pathlib import Path
import json,difflib,hashlib,urllib.request
from html.parser import HTMLParser
from urllib.parse import urlparse,unquote
r=Path.cwd();o=r/'doc/book/iterations/2026-09-25-wavefunctions-review-comments'
p=r/'doc/book/iterations/WORKING.md';s=p.read_text(encoding='utf-8-sig');(o/'working-before-update.md').write_text(s,encoding='utf-8');first,rest=s.split('\n',1)
entry='''

**25 September — Wavefunctions review comments: what a return keeps.** [Reading, exact diffs and native museum pairs](2026-09-25-wavefunctions-review-comments/index.html) · [queue](http://localhost:3003/book-tasks/review?seq=wavefunctions). All 13 comments addressed. Twelve chapters read, ten revised, Intro and John Cage retained. Unit circle now opts into continuing point/projection motion after its finite build; other placements keep the held default. Interior photographs exposed its lower semicircle below the floor and an entrance-wall obstruction: raised this placement 1.7 m and moved it one empty cell inward to (1,2). All 400 local step transforms remain unchanged through subsequent motion. Counting follows COARSE, visible button captions replace missing options, RELIEF is a cycle, Bernini's separate repeated phrase returns, paired sine/cosine steps remain supporting, and directions use landmarks. Kept Lucier's substantial room passage; explicit departure and longer return compare feedback with a sum calculated afresh. Two original native museum PNGs enter final.md. 36 native checks across three halls, 102 publication/preservation checks pass; processes exit 0. Synthesis has existing scalar_pointer.gd:32 control_path assignment errors despite successful coefficient/button signal checks; shared adapter left untouched and listed for follow-up. Other UID/renderer warnings retained. No pointer/grab, headset, microphone or full scene-travel acceptance. Sequence order, roles, other placements, companion manuscripts and code excerpts retained. Current capture refreshed, original reviewer fields preserved, live bake/save untouched. Reload Unit Circle for new placement/motion. Next review sequence: Randomness; coordinate with the independent Noise artifact work rather than duplicating it.
'''
p.write_text(first+entry+rest,encoding='utf-8')
changes=json.loads((o/'changed-files.json').read_text())
for rel in ['doc/tasks/book_wavefunctions.json','doc/book/iterations/WORKING.md']:
 if rel not in changes:changes.append(rel)
 p=r/rel;dst=o/'after'/rel;dst.parent.mkdir(parents=True,exist_ok=True);dst.write_bytes(p.read_bytes());a=(o/'working-before-update.md' if rel.endswith('WORKING.md') else o/'before'/rel).read_text(encoding='utf-8-sig');b=p.read_text(encoding='utf-8-sig');dst=o/'diffs'/(rel+'.diff');dst.parent.mkdir(parents=True,exist_ok=True);dst.write_text(''.join(difflib.unified_diff(a.splitlines(True),b.splitlines(True),fromfile='before/'+rel,tofile=rel)),encoding='utf-8')
(o/'changed-files.json').write_text(json.dumps(changes,indent=2)+'\n',encoding='utf-8')
class Links(HTMLParser):
 def __init__(self):super().__init__();self.ids=[];self.links=[]
 def handle_starttag(self,t,attrs):
  d=dict(attrs)
  if 'id' in d:self.ids.append(d['id'])
  if t in ['a','img']:self.links.append(d.get('href',d.get('src','')))
p=Links();p.feed((o/'index.html').read_text());fail=[];resources=[]
for link in p.links:
 u=urlparse(link)
 if u.scheme or u.netloc:continue
 if not u.path:
  if u.fragment and unquote(u.fragment) not in p.ids:fail.append(link)
  continue
 if u.path.startswith('/compose/') or u.path.startswith('/book-tasks/'):continue
 path=r/u.path.removeprefix('/book-review/') if u.path.startswith('/book-review/') else o/unquote(u.path)
 if not path.exists():fail.append(link)
 resources.append(path)
assert not fail,fail
assert len(p.ids)==len(set(p.ids)),'duplicate IDs'
url='http://localhost:3003/book-review/doc/book/iterations/2026-09-25-wavefunctions-review-comments/index.html'
with urllib.request.urlopen(url,timeout=20) as response:assert response.read()==(o/'index.html').read_bytes()
result={'links_checked':len(p.links),'missing':fail,'duplicate_ids':False,'live_page_matches_file':True};(o/'page-verification.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8');print(result)
