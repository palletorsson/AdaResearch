from pathlib import Path
import urllib.request,json
from concurrent.futures import ThreadPoolExecutor
H=Path(__file__).resolve().parent;R=H.parents[3];reading=H.parent/'2026-09-20-book-reading'
paths=[H/'SUMMARY.md',H/'content-checks.json',H.parent/'2026-09-19-review-comparison/index.html',reading/'index.html',reading/'ASSESSMENT.md',reading/'coverage.json']+list(H.glob('*.png'))+[H/m/'final.diff' for m in ['AdvancedLaboratory_Lab_Equipment_Simulation','PostCrisis_Synthesis']]+list(reading.glob('reading-*.md'))
def check(p):
 url='http://localhost:3003/book-review/'+p.relative_to(R).as_posix()
 try:
  with urllib.request.urlopen(url,timeout=20) as response:return dict(path=p.relative_to(R).as_posix(),status=response.status,identical=response.read()==p.read_bytes())
 except Exception as e:return dict(path=p.relative_to(R).as_posix(),identical=False,error=str(e))
with ThreadPoolExecutor(max_workers=4) as pool:results=list(pool.map(check,paths))
(H/'http-checks.json').write_text(json.dumps(results,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'resources':len(results),'all_identical':all(v['identical'] for v in results),'failures':[v for v in results if not v['identical']]}))
raise SystemExit(not all(v['identical'] for v in results))
