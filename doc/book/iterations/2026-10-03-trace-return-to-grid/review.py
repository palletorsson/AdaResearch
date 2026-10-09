from pathlib import Path
import difflib, hashlib, html, json, re
import markdown

OUT=Path(__file__).resolve().parent
ROOT=OUT.parents[3]
STARTER=ROOT/'doc/book/studies/ada-xr-starter'
grid=(ROOT/'commons/maps/Point_Line_Grid/tutorial.md').read_text(encoding='utf-8')
trace=(ROOT/'commons/maps/Point_Trace/tutorial.md').read_text(encoding='utf-8')
grid_code=(STARTER/'studies/point_grid/grid.gd').read_text(encoding='utf-8')
trace_code=(STARTER/'studies/point_trace/trace.gd').read_text(encoding='utf-8')
for prose,code,count in [(grid,grid_code,4),(trace,trace_code,5)]:
    blocks=re.findall(r'```gdscript\n(.*?)```',prose,re.S)
    assert len(blocks)==count
    assert all(b.strip() in code for b in blocks)
    assert '$' not in code and 'get_node' not in code
native=json.loads((OUT/'verification.json').read_text())
restart=json.loads((OUT/'restart-verification.json').read_text())
capture=json.loads((OUT/'capture-verification.json').read_text())
assert native['passed'] and restart['passed'] and capture['passed']
checks=len(native['checks'])+len(restart['checks'])
for name,prose in [('Point_Line_Grid',grid),('Point_Trace',trace)]:
    (OUT/(name+'.tutorial.md')).write_text(prose,encoding='utf-8')
    before=(OUT/'before'/(name+'.tutorial.md')).read_text(encoding='utf-8')
    (OUT/(name+'.tutorial.diff')).write_text(''.join(difflib.unified_diff(before.splitlines(True),prose.splitlines(True),fromfile='before/'+name+'/tutorial.md',tofile='commons/maps/'+name+'/tutorial.md')),encoding='utf-8')
(OUT/'grid.gd').write_text(grid_code,encoding='utf-8')
(OUT/'trace.gd').write_text(trace_code,encoding='utf-8')
for helper in ['trace_memory.gd','trace_comparison.gd']:
    (OUT/helper).write_text((STARTER/'prepared'/helper).read_text(encoding='utf-8'),encoding='utf-8')
contract={'maps':['Point_Trace','Point_Line_Grid'],'status':'author_review_pilot','correction':'Reuse the actual released trace; do not start a different gesture in Grid.','data_flow':['Desktop mouse or tracked hand moves PointHandle','Trace selects and retains positions in order','Release saves an exact value snapshot','Grid loads that snapshot into source_points','For each source position, append a rounded value to grid_points','Display source and result without modifying either'], 'supplied':['TraceMemory: release callback, local-file transport, validation and status','TraceComparison: common source-based fit and two display offsets'],'learner_owns':['sampling and ordered record','new output list','per-position rounding and spacing'],'new_concepts':['for over values in the existing list','source and transformed result are distinct lists'],'scope':['one latest record on the same device','same Study-local metre frame','no synthetic fallback on missing data'],'physical_headset_tested':False,'printed_code_matches':True,'checks':checks}
(OUT/'lesson-contract.json').write_text(json.dumps(contract,indent=2)+'\n',encoding='utf-8')
reading=markdown.markdown(grid.replace('../../../doc/book/studies/ada-xr-starter/README.md','../2026-10-03-ada-xr-starter/index.html#guide'),extensions=['fenced_code'])
reading=reading.replace('<h2>2. Keep the source and the result separate</h2>','<figure><a href="trace-saved.png"><img src="trace-saved.png" alt="The Trace room confirms Saved for Point Grid after release"></a><figcaption>Release keeps this drawing. This verification gesture was made with synthetic controller poses through the actual pickup and release path.</figcaption></figure><h2>2. Keep the source and the result separate</h2>')
reading=reading.replace('<h2>4. Change the reading, keep the gesture</h2>','<figure><a href="quarter.png"><img src="quarter.png" alt="The saved pink loop beside its white grid version"></a><figcaption>The same saved record in Grid. Pink is unchanged; white is the calculated result.</figcaption></figure><h2>4. Change the reading, keep the gesture</h2>')
reading+='<figure><a href="half.png"><img src="half.png" alt="A coarser grid changes the white result while the original pink trace stays the same" loading="lazy"></a><figcaption>Spacing changed to 0.5 m. Both lists still have '+str(native['saved_points'])+' entries; some output positions coincide. The original view has not moved.</figcaption></figure>'
page=f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Your trace returns — Trace into Grid</title><link rel="stylesheet" href="style.css"></head><body><main><header><p>ADA / TRACE INTO GRID · 3 October 2026</p><nav><a href="#reading">Read the corrected tutorial</a><a href="#code">Grid code</a><a href="#trace">Trace handoff</a><a href="Point_Line_Grid.tutorial.diff">Grid text diff</a></nav></header><article id="reading">{reading}<p><a class="download" href="../2026-10-03-ada-xr-starter/ada-xr-starter.zip" download>Download the corrected starter</a></p><p class="small">Draw in point_trace.tscn → release and see the saved confirmation → run point_grid.tscn. Change grid_size and run Grid again.</p></article><details id="code"><summary>grid.gd · the complete lesson</summary><div><pre><code>{html.escape(grid_code)}</code></pre><p><a href="grid.gd" download>Download grid.gd</a> · <a href="trace_comparison.gd">Supplied comparison display</a></p></div></details><details id="trace"><summary>Trace now hands its record onward</summary><div><p>The sampling lesson stays intact. A supplied TraceMemory node watches release and saves the current list as a value snapshot. Signal handling and file storage are not new requirements for the student's first loop.</p><pre><code>{html.escape(trace_code)}</code></pre><p><a href="Point_Trace.tutorial.md">Updated Trace tutorial</a> · <a href="Point_Trace.tutorial.diff">Trace text diff</a> · <a href="trace_memory.gd">Supplied transport</a></p></div></details><section class="lineage"><h2>The student brings the material.</h2><p>The earlier Grid pilot started another recording. This version returns to the student's own gesture. The code is reused, and so is what the student made with it.</p><p>One source can support different readings. Grid changes a rule and compares the result while preserving the source. Triangle can continue this distinction between positions, connections and the work we ask them to do.</p></section><details id="checked"><summary>{checks} checks passed · including a separate engine restart</summary><div><p>Mouse-motion input and synthetic XR grip both save through the actual release callback. Checks cover exact values, snapshot independence, unchanged source bytes, alternate grid spacings, duplicate positions and missing/invalid records. A second engine process successfully reloads and maps the saved trace.</p><p>Images are actual desktop renders of the synthetic controller record. A physical headset and beginner reading trial remain pending. The saved file stays on the same device; this is not desktop-to-headset cloud sync.</p><p><a href="verification.json">Native checks</a> · <a href="restart-verification.json">Restart checks</a> · <a href="empty.png">Empty state</a> · <a href="lesson-contract.json">Teaching scope</a> · <a href="DECISIONS.md">Decisions</a></p></div></details></main><script>function reveal(){{const el=document.getElementById(location.hash.slice(1));if(el?.tagName==='DETAILS')el.open=true}}addEventListener('hashchange',reveal);reveal();</script></body></html>'''
(OUT/'index.html').write_text(page,encoding='utf-8')
print(json.dumps({'checks':checks,'grid_words':len(grid.split()),'same_record_points':native['saved_points'],'printed_code_matches':True}))
