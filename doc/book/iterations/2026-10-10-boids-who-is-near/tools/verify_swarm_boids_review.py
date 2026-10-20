from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urlsplit,unquote
import urllib.request,json,re,zipfile,subprocess
R=Path(__file__).resolve().parents[1];O=R/'doc/book/iterations/2026-10-10-boids-who-is-near'
class Page(HTMLParser):
 def __init__(self):super().__init__();self.links=[];self.blocks=[];self.pre=False
 def handle_starttag(self,tag,attrs):
  attrs=dict(attrs)
  if tag in ['a','img']:self.links.append(attrs.get('href',attrs.get('src','')))
  if tag=='pre':self.pre=True;self.blocks.append('')
 def handle_endtag(self,tag):
  if tag=='pre':self.pre=False
 def handle_data(self,s):
  if self.pre:self.blocks[-1]+=s
checked=set()
for p in O.glob('*.html'):
 page=Page();page.feed(p.read_text(encoding='utf8'))
 for ref in page.links:
  parsed=urlsplit(ref)
  if parsed.scheme or ref.startswith('#'):continue
  target=(p.parent/unquote(parsed.path)).resolve();assert target.is_file(),(p.name,ref)
  checked.add(str(target.relative_to(O)))
 if p.name in ['tutorial.html','parallel.html']:
  sources=re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',(O/'tutorial.md').read_text(encoding='utf8'),re.S)
  assert len(page.blocks)==len(sources)==3
  assert all(a.strip().expandtabs(4)==b.strip().expandtabs(4) for a,(_,b) in zip(page.blocks,sources))
with zipfile.ZipFile(O/'boids-review.zip') as z:assert z.testzip() is None
base='http://localhost:3003/book-review/doc/book/iterations/2026-10-10-boids-who-is-near/'
http={}
for name in ['index.html','parallel.html','assets/three-requests.png','boids-review.zip']:
 with urllib.request.urlopen(base+name,timeout=15) as response:http[name]=response.status
 assert http[name]==200
paths=['commons/artifacts/flocking_controls/flocking_controls.gd','commons/maps/SwarmIntelligence_Boids_Algorithm','commons/data/museum/em_plan.json','doc/book/course/execution-plan/plan.json']
diff=subprocess.run(['git','diff','--check','--',*paths],cwd=R,capture_output=True,text=True,encoding='utf8')
assert diff.returncode==0, '\n'.join(line[:200] for line in diff.stdout.splitlines() if not line.startswith('+'))
plan=json.loads((R/'doc/book/course/execution-plan/plan.json').read_text(encoding='utf8'))
old=json.loads((O/'before/execution-plan.json').read_text(encoding='utf8'))
for a,b in zip(plan['lessons'],old['lessons']):
 if a['id']!='SwarmIntelligence_Boids_Algorithm':assert a==b
 else:assert a['decision']==b['decision'] and a['baseline']==b['baseline']
report={'local_references':len(checked),'rendered_code_matches_with_markdown_tab_expansion':True,'zip_crc_passed':True,'http':http,'scoped_whitespace_passed':True,'other_lesson_rows_unchanged':True,'review_decision_preserved':True}
(O/'review-checks.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
print(json.dumps(report))
