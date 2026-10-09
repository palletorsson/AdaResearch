from pathlib import Path
import html, json, re
import markdown

OUT=Path(__file__).resolve().parent
ROOT=OUT.parents[3]
changes=json.loads((OUT/'changes.json').read_text(encoding='utf-8'))
order=['Point_One','Primitives_Melencolia','Trans_Rotation','Tutorial_Disco','Color_Nails']
labels={'Point_One':'Point One','Primitives_Melencolia':'Melencolia','Trans_Rotation':'Rotation','Tutorial_Disco':'Disco','Color_Nails':'Nails'}
notes={
 'Point_One':'Three pauses mark the origin, the coordinate comparison and arrival. Repeated explanations become shorter. The opening, borrowed time, giants and fog, rabbit, source history and all code stay.',
 'Primitives_Melencolia':'The counter remains the return to the opening. Its last sentence stays with the number still growing. The final section moves directly into the unfinished work of the image.',
 'Trans_Rotation':'Five sections separate carrying, the angled floor, the order of turns, the swept space and the enclosing forms. Every encounter and code example remains. A few repeated conclusions give way to looking and moving.',
 'Tutorial_Disco':'One note gains company sooner. Preview, playhead, silence and tempo remain intelligible, while repeated setup moves out of the way. The two clocks and the sixteen-to-twelve mapping stay. A full comparison recipe is available in the technical companion.',
 'Color_Nails':'The closing question begins with the fingers that kept their length. The material limit and the desire to alter more remain without a general statement about identity.'
}
def render(source,prefix):
 source=re.sub(r'<!--\s*@([^>]*?)\s*-->',lambda m:('<a id="'+prefix+'-encounter-'+html.escape(m[1].strip(),quote=True)+'"></a>') if m[1].strip() else '',source)
 source=re.sub(r'~~([^~\n]+)~~',r'<del>\1</del>',source)
 result=markdown.markdown(source,extensions=['extra','sane_lists'])
 return result.replace('id="fn','id="'+prefix+'-fn').replace('href="#fn','href="#'+prefix+'-fn')
old_page=(OUT.parent/'2026-09-23-primitives-pacing/index.html').read_text(encoding='utf-8')
css=re.search(r'<style>(.*?)</style>',old_page,re.S)[1]
css+='\n.comparison-note{font:14px/1.55 system-ui,sans-serif;color:#66574c;max-width:850px;margin:28px 0 0}.pair:empty{display:none}.reading{scroll-margin-top:25px}.reading h2{margin-top:2.6em}.empty{color:#827363;font-style:italic}main>header{max-width:850px} .reading pre{tab-size:4}'
parts=[]
for name in order:
 current=(ROOT/'commons/maps'/name/'final.md').read_text(encoding='utf-8')
 assert current==(OUT/(name+'.after.md')).read_text(encoding='utf-8'), 'Manuscript changed; refresh deliberately: '+name
 pairs=[]
 for i,e in enumerate(changes[name]):
  before=render(e['before'],f'{name}-before-{i}');after=render(e['after'],f'{name}-after-{i}')
  if not re.sub('<[^>]+>','',before).strip():before='<p class="empty">No section title at this point.</p>'
  if not after.strip():after='<p class="empty">The following paragraph now begins here.</p>'
  pairs.append('<p class="comparison-note">'+html.escape(e['reason'])+'</p><div class="pair"><div><h4>Before</h4>'+before+'</div><div><h4>Now</h4>'+after+'</div></div>')
 before=(OUT/(name+'.before.md')).read_text(encoding='utf-8')
 count=f'{len(before.split()):,} → {len(current.split()):,} words, including code and notes.'
 extra='<p><a href="/book?map=Tutorial_Disco&amp;section=technical">Optional Disco comparison recipe</a></p>' if name=='Tutorial_Disco' else ''
 parts.append(f'<section id="{name}"><header class="chapter"><span class="eyebrow">{labels[name]}</span><h2>{labels[name]}</h2><p>{notes[name]}</p><a href="/compose/sources?map={name}&amp;doc=final">Read and comment on final.md</a></header><details><summary>Compare the exact changes</summary>{"".join(pairs)}<p class="comparison-note">{count}</p><p><a href="{name}.diff">Manuscript diff</a> · <a href="{name}.before.md">Full original</a></p>{extra}</details><article class="reading" id="reading-{name}">{render(current,name)}</article></section>')
nav=''.join(f'<a href="#reading-{name}">{labels[name]}</a>' for name in order)
page='<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Room to read — Ada Research</title><style>'+css+'</style></head><body><main><header><div class="eyebrow">Ada Research · Opening sequences · 24 September 2026</div><h1>Room to read.</h1><p class="intro">A small pass through five chapters. The encounters keep their particular questions. Longer halls gain pauses; the disco gets to making a rhythm sooner. A few conclusions leave us with the object still doing something.</p></header><p class="status">Applied to the five canonical <strong>final.md</strong> files. All existing code blocks, illustrations, footnotes and encounter anchors are retained. Expand a comparison to see every change beside its original.</p><nav>'+nav+'<a href="SUMMARY.md">Scope and checks</a></nav><div id="reading"></div>'
page+=''.join(parts)
page+='<footer><p>The other twenty-five opening chapters are unchanged. These are reading revisions: no artifacts, maps, movement, controls or sequence membership changed. Existing illustrations are native museum captures from the earlier passes; this page adds no new runtime or headset evidence.</p><p>Next: <a href="/compose/sources?map=Pattern_Disco&amp;doc=final">Pattern_Disco — the familiar floor returns in colour</a>.</p></footer></main></body></html>'
(OUT/'index.html').write_text(page,encoding='utf-8')
print('Built five current readings and exact passage comparisons.')
