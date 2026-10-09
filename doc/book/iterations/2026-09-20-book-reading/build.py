from pathlib import Path
import json, hashlib, markdown

H=Path(__file__).resolve().parent;R=H.parents[3]
sequences=[];entries=[]
for part in ['opening','middle','ending']:
 d=json.loads((H/f'reading-{part}-manifest.json').read_text(encoding='utf-8'))
 if part=='ending':
  entries+=d['maps']
  sequences += [v['sequence'] for v in d['sequence_sources']]
 else:
  for seq in d['sequences']:
   sequences.append(seq['sequence'])
   entries += [dict(v,sequence=seq['sequence']) for v in seq['maps']]
covered={v['path']:v for v in entries};ordered=[];errors=[]
for seq in sequences:
 p=R/'commons/maps/sequences'/f'{seq}.json'
 maps=json.loads(p.read_text(encoding='utf-8'))['sequences'][seq]['maps']
 for m in maps:
  rel=f'commons/maps/{m}/final.md';p=R/rel;data=p.read_bytes();digest=hashlib.sha256(data).hexdigest()
  if rel not in covered or covered[rel]['sha256']!=digest:errors.append(rel)
  ordered.append(dict(sequence=seq,map=m,path=rel,sha256=digest,words_whitespace=len(data.decode('utf-8').split())))
assert len(sequences)==len(set(sequences))==24
assert len(ordered)==len(covered)==len(entries)
result=dict(method='Three full parallel close readings; lead read their complete reports and cross-checked selected manuscript passages. Final two halls reread after revision.',sequences=len(sequences),manuscripts=len(ordered),words_whitespace=sum(v['words_whitespace'] for v in ordered),complete_and_current=not errors,missing_or_changed=errors,maps=ordered)
(H/'coverage.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
if errors:raise SystemExit(str(errors))
body=markdown.markdown((H/'ASSESSMENT.md').read_text(encoding='utf-8'),extensions=['tables','fenced_code'])
css='''*{box-sizing:border-box}body{margin:0;background:#f4f1e9;color:#202824;font:18px/1.75 Georgia,serif}header,main,footer{max-width:940px;margin:auto;padding:32px 36px}header{padding-bottom:0;font:14px/1.6 system-ui,sans-serif;color:#55635b}h1{font-size:clamp(36px,5vw,58px);font-weight:500;line-height:1.12}h2{font-size:29px;font-weight:500;line-height:1.25;margin-top:44px}a{color:#24594e;text-underline-offset:4px}p{margin:20px 0}table{font:15px/1.6 system-ui,sans-serif;border-collapse:collapse;width:100%}th,td{padding:14px;text-align:left;vertical-align:top;border:1px solid #c6cfc5}th{background:#e2e8de}code{font:14px/1.5 ui-monospace,monospace;overflow-wrap:anywhere}li{margin:8px 0}figure{margin:28px 0}img{width:100%;height:auto}figcaption,footer{font:14px/1.6 system-ui,sans-serif;color:#55635b}.stats{display:flex;gap:22px;flex-wrap:wrap;border-bottom:1px solid #c6cfc5;padding:16px 0}.stats b{font-size:24px;color:#263f34}@media(max-width:600px){header,main,footer{padding-left:20px;padding-right:20px}table{font-size:13px}td,th{padding:8px}}'''
page='<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Ada Research — whole-book reading</title><style>'+css+'</style><header>Ada Research · 20 September 2026<div class="stats"><span><b>24</b> sequences</span><span><b>'+str(result['manuscripts'])+'</b> hall manuscripts</span><span><b>'+format(result['words_whitespace'],',')+'</b> words, including code and notes</span></div><p><a href="../2026-09-19-review-comparison/index.html#postfoundationscrisis">Text and encounter comparisons</a> · <a href="ASSESSMENT.md">Markdown source</a></p></header><main>'+body+'</main><footer>Reading coverage is recorded against file hashes. Runtime checks for the closing halls are linked separately; manuscript coverage does not assert complete VR verification.</footer></html>'
(H/'index.html').write_text(page,encoding='utf-8')
print(json.dumps({k:v for k,v in result.items() if k!='maps'}))
