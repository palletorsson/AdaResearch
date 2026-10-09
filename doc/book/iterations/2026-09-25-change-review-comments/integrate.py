from pathlib import Path
import json,hashlib,shutil
r=Path.cwd();o=r/'doc/book/iterations/2026-09-25-change-review-comments';H=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
figdir=r/'doc/book/figures/change';figdir.mkdir(parents=True,exist_ok=True);figs=[]
for name,sub in [('two-readings-near','intro'),('four-held-eight-live','intro'),('flow-field-near','flow')]:
 src=o/sub/(name+'.png');dst=figdir/(name+'-museum.png');shutil.copyfile(src,dst)
 figs.append({'source':src.relative_to(r).as_posix(),'canonical':dst.relative_to(r).as_posix(),'sha256':H(src),'kind':'Unmodified Godot viewport PNG from the loaded museum; standing camera, existing architecture/materials; GL compatibility renderer.','evidence':(o/sub/'source_manifest.json').relative_to(r).as_posix()})
(o/'figure-provenance.json').write_text(json.dumps(figs,indent=2)+'\n',encoding='utf-8')
def figure(m,needle,content):
 p=r/'commons/maps'/m/'final.md';s=p.read_text(encoding='utf-8');assert s.count(needle)==1 and content not in s;s=s.replace(needle,needle+'\n\n'+content);p.write_text(s,encoding='utf-8')
figure('Change_Intro','The derivative asks what the finite ratios approach as the interval tends to zero, where that limit exists. The gold line comes from an analytic calculation for this smooth function. We can compare our samples with it, although none of the four STEP settings reaches the limit itself. Dividing by zero would not bring us closer.','![A shorter interval and the revealed slope plot at the museum workbench](/book-review/doc/book/figures/change/two-readings-near-museum.png)\n\n*The red sample has stayed at the same address. The green one has come closer; their joining line now rises. Above the curve, the second plot gives its slope another place to appear.*')
figure('Change_Intro','Return to MID and increase the count to eight. Keep the held four beside them. A ridge that passed between two samples can now receive a sample of its own. The total changes noticeably. Continue to narrower rectangles. Their differences become harder to see as the tops gather around the line.','![Eight live rectangles beside four held rectangles inside the museum](/book-review/doc/book/figures/change/four-held-eight-live-museum.png)\n\n*Eight live intervals on the left, four held on the right. The earlier reading remains available.*')
figure('Flow_Field','A long stroke can suddenly cross the canvas. The recorder has joined the last position before the wrap to the first one after it. Its line suggests a journey through the middle that the particle did not make. The same drawing operation that helped us follow a bend has drawn across this jump too.','![Arrows and particle trails on the canvas inside the Flow Field hall](/book-review/doc/book/figures/change/flow-field-near-museum.png)\n\n*The arrows keep their places. Long strokes across the canvas join positions on opposite sides of its frame.*')
# Read the shared index immediately before changing only this pass's records.
p=r/'commons/data/museum_core_encounters.json';raw=p.read_bytes();(o/'core-before-update.json').write_bytes(raw);core=json.loads(raw.decode('utf-8-sig'))
for m in ['Change_Intro','Flow_Field']:
 for kind,fn in [('text','final.md'),('map','map_data.json')]:core['rooms'][m][kind+'_sha256']=H(r/'commons/maps'/m/fn)
 core['rooms'][m]['local_review']='doc/book/iterations/2026-09-25-change-review-comments/index.html#'+m
p.write_text(json.dumps(core,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
p=r/'doc/book/figures/README.md';s=p.read_text(encoding='utf-8-sig');s+='\n\n## Change — native museum views, 25 September 2026\n\nThree unmodified Godot viewport captures: a shortened interval and slope plot, eight live rectangles beside four held, and the shared field with arrows and wrap-spanning trails. Standing cameras preserve the actual museum and adjacent works. GL compatibility renders, not tracked-headset screenshots. [Evidence and hashes](../iterations/2026-09-25-change-review-comments/figure-provenance.json).\n';p.write_text(s,encoding='utf-8')
print('Added three native photographs to the canonical chapters and refreshed only their core records.')
