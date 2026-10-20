"""Collect current Shader manuscripts, preserve code, and attach scoped evidence."""
from pathlib import Path
import hashlib,json,re,shutil,zipfile,html,difflib
from html.parser import HTMLParser
from urllib.parse import urlsplit,unquote
import markdown
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-10-shaders-complete-readings'
GHOST=ROOT/'doc/book/iterations/2026-10-10-shaders-ghost-student'
HALLS=[
 ('Shader_01_Shaping','Shaping','2026-10-10-shaping-a-rule-on-the-cube','student.png','Make a mark','Same point, cube and square receivers. Write one distance mask; point height changes radius and trigger changes edge. Predict which addresses lie inside. Carry the rule and its coordinate convention onward.'),
 ('Shader_05_Patterns','Patterns','2026-10-10-patterns-the-same-circle','student.png','Repeat its address','Keep the circle and receivers. Multiply and fold the coordinates; move the point sideways to shift the lookup. Predict the direction of movement and its return after one tile. Repetition changes the reading without multiplying bodies.'),
 ('Shader_11_QueerRubber','Materials','2026-10-10-materials-light-without-height','height.png','Give light another direction','Keep the repeated circle, now sampled into height data and encoded directions. Compare flat, bump and normal-map readings under one lamp. The point gains coat(); its geometry stays. Explain a changed highlight at an unchanged silhouette.'),
 ('Shader_09_FBM','Water','2026-10-10-water-a-surface-that-moves','height.png','Move the rendered surface','Carry the point and rigid cube; replace the two squares with a subdivided plane. Apply a bounded layered field to colour, normals, then vertex height. Compare four corners with a dense mesh. The glass supports the player through its own collider.'),
 ('Shader_12_PinkExtravaganza','Pink','2026-10-10-pink-three-amounts','composed.png','Choose the composition','Return to rigid point and cube. Their shared recipe combines repeated pigment, a view-dependent rim and emission; local X/Y/Z choose the amounts. Isolate each, then keep a composition. Compare its surroundings without claiming that visible glow is a lamp.'),
 ('Shader_10_ReactionDiffusion','State','2026-10-10-state-a-field-kept','student.png','Keep what happened','Use the same point as an XY selector that plants a difference. Read the completed field, update into a separate texture and retain the result. Compare holding, stepping, running and changing ink. Then inspect one model cell and vary feed at an equal update count.'),
]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def text(p):return p.read_text(encoding='utf-8-sig')
def write(p,s):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(s,encoding='utf8')
def md(s):return markdown.markdown(s,extensions=['fenced_code','tables','footnotes'])
def blocks(s):return dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```(?:gdscript|glsl)\n(.*?)\n```',s,re.S))
def namespace(s,prefix):return re.sub(r'\[\^([^\]]+)\]',lambda m:'[^'+prefix+'-'+m[1]+']',s)
CSS='''*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#eeeae1;color:#202e30;font:19px/1.6 Georgia,serif}main{max-width:1160px;margin:auto;padding:32px}.wide{max-width:1800px}nav,.meta,figcaption,table,summary,.tabs{font:14px/1.5 system-ui}nav{display:flex;flex-wrap:wrap;gap:18px;border-bottom:1px solid #c2b9aa;padding:12px 0 24px}a{color:#246660}h1{font-size:clamp(38px,5vw,66px);line-height:1.08}h2{font-size:29px;line-height:1.2}h3{font-size:22px}img{display:block;width:100%;height:auto}figure{margin:24px 0}figcaption{margin-top:8px;color:#526264}.grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:26px}.card,article{background:#fcfaf5;padding:24px;min-width:0}.card h2{margin-top:12px}.pair{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:24px}.pair h1{font-size:35px}.pair article{align-self:start}pre{font:13px/1.5 Consolas,monospace;overflow:auto;background:#183033;color:#f3eee0;padding:18px;tab-size:4}code{font-size:.88em}pre code{font-size:inherit}table{border-collapse:collapse;width:100%}th,td{border-bottom:1px solid #c9c0b2;padding:12px;text-align:left;vertical-align:top}.table-scroll{overflow-x:auto}.note{border-left:4px solid #4b766c;background:#dfe8df;padding:20px}.chapter{padding-top:30px;margin-top:40px;border-top:2px solid #b3ac9d}.chapter[hidden]{display:none}.tabs{display:flex;gap:8px;flex-wrap:wrap;align-items:center;margin:24px 0}button,select{font:15px system-ui;padding:10px 14px;background:#faf8f2;border:1px solid #8a9996;border-radius:3px;color:#183033;cursor:pointer}button:disabled{opacity:.4;cursor:default}.changes{max-height:600px}.toc{font:16px/1.8 system-ui}blockquote{border-left:3px solid #809d8f;padding-left:20px}section{scroll-margin-top:20px}@media(max-width:900px){.pair,.grid{grid-template-columns:1fr}main{padding:18px}.pair article{padding:18px}}@media print{nav,.tabs{display:none}.chapter[hidden]{display:block}body{font-size:11pt;background:white}main{max-width:none;padding:0}.pair{display:block}article{break-before:page}pre{white-space:pre-wrap;overflow:visible;font-size:8pt}.card{break-inside:avoid}h1{font-size:28pt}}'''
NAV='<nav><a href="index.html">Sequence report</a><a href="parallel.html">Facing pages</a><a href="tutorial.html">Complete tutorial</a><a href="final.html">Complete reflection</a><a href="appendices.html">Optional returns</a><a href="changes.html">Changes</a><a href="shaders-review.zip">Review ZIP</a></nav>'
def page(title,body,wide=False):return '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+CSS+'</style><main'+(' class="wide"' if wide else '')+'>'+NAV+body+'</main></html>'
PREFACE='''# Shaders — what a surface answers to

You are already inside Endless Museum. Walk the hall before reconstructing its selected operation. Some artifacts belong to the tutorial, some to the reflective text, some to both, and some remain encounters without either text. You do not have to rebuild the whole collection.

You bring the point and cube, coordinates and transforms, arrays and loops, functions and classes, colour, periodic motion and sampled noise. The shader sequence returns to those abilities in another place: the material attached to a surface. If one of those returns is unfamiliar, revisit its earlier lesson rather than treating this sequence as an introduction to programming.

The tutorial and reflection do different work. Build, predict and change through the tutorial. Read the reflection beside the encounter, including its wider collection. Neither text replaces the other, and every artwork does not need to become an exercise.

You continue a small program through six lessons. Each supplied launcher instantiates your current version beside the museum's exhibits. This is continuity of the code and the object's construction; the launchers do not automatically carry a held instance or save its state between halls. Keep a copy of each working lesson before continuing.

Each chapter prints its complete program once, including carried code. Start with its changed function or shader, then return to the construction when needed. Prepared player, camera, XR tools and any other supplied support are named. The figures are captures from Godot; some show the learner reconstruction beside a larger installed artifact with separate controls.

Required route: **mask → repeated lookup → normals and light → vertex height → composition → retained field**. Garden, saved-record and plural-body returns are collected after that route. They remain available without becoming prerequisites for the next shader lesson.

Run the program, predict a result, change a value, and explain what the comparison establishes. A passing program is evidence that its operation can be reconstructed. It cannot establish what you understood or whether the form you chose matters to you.
'''
REVIEW='''# Reading the six halls together

The order holds. I would keep all six halls. Their continuity is strongest when each changes one part of an already known relation: a rule makes a visible boundary; coordinates repeat it; normals change its response to light; vertices change its outline; chosen contributions make a composition; a saved field lets an intervention have a later consequence.

This is an intermediate continuation of the book. It is not six introductory shader exercises that can honestly be completed in the old 30–40 minute estimate. The museum visit and the construction work have different durations; neither has been measured with learners.

## What makes the progression work

Shaping and Patterns are the closest pair. The same circle, shared material and two square receivers let the learner isolate a changed address. Materials then reuses the circle as data, which gives the move into textures a reason. Water returns to noise and slope, changing where those operations run and what they can move. Pink gives room to choose a result instead of adding another large system. State changes the dependency of the calculation itself: its previous result now matters.

The point remains a recognisable control body, though its job changes explicitly. The cube remains a geometric and physical witness. Continuity does not require retaining every helper forever: Water sets aside the circle images; Pink sets aside the tray; State replaces the composition rule. Keeping these departures visible is more useful than calling every hall the same unchanged example.

## Where the density rises

Materials is the first substantial rise: texture samples, slopes, tangent directions and encoding arrive together. Its flat receiver and three modes justify that load, but the reader should compare them before studying the data generator. Water is another substantial lesson, especially the difference between per-fragment detail and vertex interpolation. Those are earned returns to coordinates and geometry, not optional terminology to remove.

State is the largest code listing. It contains a model rule, two rendering groups, scheduling and packed data. The central capability is retaining and updating the field. The revised reading path first follows a mark through hold/step/run/display, then examines one cell and the feed variation. Scheduler and packing remain explicit supplied support, printed in full. This is still the main density risk for a human trial. If readers lose the field inside the machinery, split the reading into two visits within the same hall; another compulsory map is not yet justified.

Patterns also contained an optional saved-record lesson with its own data types, code and test. In an uninterrupted book it could look like a prerequisite. The collected tutorial now puts optional returns after the six main chapters. Nothing was deleted from the canonical map text. The reflection remains complete: its broader collection is part of the inquiry, not a second programming checklist.

## How the two texts meet

The reflective thread grows from a boundary that looks soft but stays solid, through seams that belong to a reading, to light that suggests relief, water that cannot carry a foot, a composition changed by its setting, and a record that preserves an intervention without preserving its meaning. That is a coherent companion to the technical thread.

The older racks matter because they complicate the new studies: a clock wraps, a material lacks its intended texture, an edge looks matched without matching tiles, a field asks for input it never receives. Keep those examples, but keep their scope local. A defect or default in one artifact must not become a claim about every shader or the whole hall.

Patterns and Materials are the densest reflective chapters because they visit several specimens. Their central questions are clear enough to retain them for review. If the print reading feels slow, shorten the specimen tours before removing the seam or light argument. Do not turn them into extra mandatory tutorial tasks.

## What changed in this pass

- Shaping's clock jump is now described as dependent on when the slider moves, rather than inherently unpredictable. Its note distinguishes stored control values from an earlier image.
- Patterns explicitly says its saved-record return is a separate optional lesson.
- Water's handoff names Pink's actual fixed-geometry composition: dots, rim and emission.
- Pink's retained-state handoff is made more precise.
- State has two reading passes through the same executable program.
- Sequence metadata describes the completed drafts and retained wall; it no longer calls everything a proposal or supplies an unsupported total duration.

No map was moved, no artifact removed and no printed program changed. The remaining evidence gap is a reader carrying the work through all six lessons, including the changes in the point's job. Existing per-hall tests do not substitute for that experience.
'''
REVIEWER='''# For the next reader or ghost student

Read PREFACE.md first. This is one sequence in the existing Endless Museum book, after the learner has met coordinates, bodies, transforms, arrays, colour, motion and noise. It is not a standalone beginner course.

Read tutorial.md for the six required reconstructions; final.md for the complete companion reflections. Optional returns are in appendices.md. Each hall's exact canonical text and code is also under chapters/. Code is real. The remembered point and cube are a continuing construction; no automatic cross-hall runtime persistence is promised.

For each lesson, name what you bring, what changes, what support is supplied, what you can reconstruct and what you can test independently. Predict before running. Report missing initialization, ambiguous edits or a control whose described action differs from its code. Do not quietly repair a gap and then call the tutorial complete.

Do both jobs: build the operation and investigate what it permits. Give one variation with a reason for choosing it. Keep mathematical, software, experiential and interpretive claims distinct. A technical test may falsify a causal claim; it cannot settle an artistic or political interpretation.

Review the handoffs, especially Materials → Water and Pink → State. Does the optional material remain optional? Does the point's changed job stay legible? Does State's supplied GPU support obscure its central operation? Would two visits to that hall help more than a new hall?

Evidence is teacher-authored: prior GPU program/variation checks, deliberate faults and synthetic-XR museum probes. This package verifies the current printed blocks against that evidence; it does not claim a fresh independent student run, physical-headset validation or learning outcomes. Use the existing AdaResearch Godot 4.6 project to execute the examples. The ZIP does not distribute the full museum or XR toolkit.

Report decisions as Keep / Clarify / Change, with the hall, quoted passage or filename, and a reason. Suggest the smallest change that preserves the sequence's central line.
'''
def main():
    global NAV
    OUT.mkdir(exist_ok=True,parents=True)
    ghost=json.loads(text(GHOST/'validation.json')) if (GHOST/'validation.json').exists() else None
    reviewer=REVIEWER;review=REVIEW
    if ghost:
        assert ghost['passed']
        if 'ghost-student/index.html' not in NAV:NAV=NAV.replace('</nav>','<a href="ghost-student/index.html">Ghost student</a></nav>')
        reviewer=reviewer.replace('This package verifies the current printed blocks against that evidence; it does not claim a fresh independent student run, physical-headset validation or learning outcomes.', 'The attached ghost-student/ folder adds a fresh-context AI reconstruction: all six originals and six independently chosen variations, with new GPU probes and a sequential reading report. Earlier author evidence remains separate. The student used an isolated rendered host and synthetic controls; physical-headset validation and human learning outcomes remain untested.')
        review+='\n\n## Subsequent ghost-student pass\n\nA fresh-context AI reader has now reconstructed all six printed programs and six independent variations. See [the separate report](ghost-student/index.html) for predictions, rendered evidence, initial failures and repairs. The original whole-sequence reading assessment above remains the record of the editorial pass; the new reconstruction is additional evidence.\n'
    write(OUT/'PREFACE.md',PREFACE);write(OUT/'REVIEW.md',review);write(OUT/'REVIEWER.md',reviewer)
    write(OUT/'preface.html',page('Shaders / how to read',md(PREFACE)))
    write(OUT/'reviewer.html',page('Shaders / review brief',md(reviewer)))
    chapters=[];appendices=[];evidence=[];diffs=[];cards=[];density=[]
    source_order=json.loads(text(ROOT/'commons/maps/sequences/shaders.json'))['sequences']['shaders']['maps']
    assert source_order==[r[0] for r in HALLS]
    for index,(name,label,review,shot,job,summary) in enumerate(HALLS,1):
        folder=OUT/'chapters'/name;folder.mkdir(parents=True,exist_ok=True)
        old_review=ROOT/'doc/book/iterations'/review;record=json.loads(text(old_review/'tests.json'));manifest=json.loads(text(old_review/'manifest.json'))
        assert record['passed']
        tutorial=text(ROOT/'commons/maps'/name/'tutorial.md');reflection=text(ROOT/'commons/maps'/name/'final.md')
        code=blocks(tutorial);assert set(code)==set(record['files'])
        for fn,s in code.items():
            saved=old_review/'learner/printed'/fn
            assert text(saved)==s+'\n',(name,fn)
            assert sha(saved)==record['files'][fn],(name,fn)
        # Preserve exact canonical files and before/after diffs for reviewers.
        for track,s in [('tutorial',tutorial),('final',reflection)]:
            if ghost:assert ghost['current_text_hashes'][name][track]==sha(ROOT/'commons/maps'/name/(track+'.md')),(name,track,'ghost publication needs refresh')
            shutil.copy2(ROOT/'commons/maps'/name/(track+'.md'),folder/(track+'.md'))
            original=text(OUT/'before'/name/(track+'.md'))
            assert re.findall(r'```[^\n]*\n.*?\n```',original,re.S)==re.findall(r'```[^\n]*\n.*?\n```',s,re.S)
            diff=''.join(difflib.unified_diff(original.splitlines(True),s.splitlines(True),fromfile=name+'/'+track+' before',tofile=name+'/'+track+' now'))
            write(folder/(track+'.diff'),diff)
            if diff:diffs.append('<h2>'+html.escape(label+' / '+track)+'</h2><pre class="changes">'+html.escape(diff)+'</pre>')
        for p in (old_review/'learner').rglob('*'):
            if p.is_file() and p.suffix not in ('.uid','.import'):
                dest=folder/'learner'/p.relative_to(old_review/'learner');dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dest)
        for fn in ['tests.json','manifest.json','continuation.json','BRIEF.md']:
            if (old_review/fn).exists():shutil.copy2(old_review/fn,folder/fn)
        native=json.loads(text(old_review/'museum/report.json'));assert native['passed']
        (folder/'museum').mkdir(exist_ok=True)
        for fn in [shot,'in-the-hall.png','report.json','engine.log','source_manifest.json']:
            if (old_review/'museum'/fn).exists():shutil.copy2(old_review/'museum'/fn,folder/'museum'/fn)
        # Include already-recorded sources; never rewrite a historical manifest to today's prose hash.
        if (old_review/'source').exists():shutil.copytree(old_review/'source',folder/'source',dirs_exist_ok=True)
        optional=''
        if '\n---\n' in tutorial:
            tutorial,optional=tutorial.split('\n---\n',1)
            appendices.append((name,label,optional))
        picture='chapters/'+name+'/museum/'+shot
        # Qualify footnotes in a whole-book document; local image URLs are bundled below.
        tutorial=namespace(tutorial,'t'+str(index));reflection=namespace(reflection,'f'+str(index))
        for s in [tutorial,reflection,optional]:
            for path in re.findall(r'\]\((/book-images/[^)]+)\)',s):
                src=ROOT/'doc/book'/path.removeprefix('/book-images/')
                assert src.exists(),path
                dest=OUT/'images'/src.name;dest.parent.mkdir(exist_ok=True);shutil.copy2(src,dest)
                tutorial=tutorial.replace(path,'images/'+src.name);reflection=reflection.replace(path,'images/'+src.name)
        if optional:tutorial+='\n\n[Optional returns from this hall](appendices.html#'+name+'). Continue to the next main chapter when ready.\n'
        chapters.append({'name':name,'label':label,'tutorial':tutorial,'final':reflection,'summary':summary,'job':job,'picture':picture})
        prose=re.sub(r'```[^\n]*\n.*?\n```','',tutorial,flags=re.S)
        density.append({'hall':label,'main_tutorial_words':len(prose.split()),'printed_code_lines':sum(len(s.splitlines()) for s in code.values()),'files':len(code),'reflective_words_including_notes':len(reflection.split()),'optional_return':bool(optional)})
        evidence.append({'hall':name,'prior_review':review,'current_tutorial_sha256':sha(ROOT/'commons/maps'/name/'tutorial.md'),'current_final_sha256':sha(ROOT/'commons/maps'/name/'final.md'),'prior_tutorial_sha256':manifest['tutorial_sha256'],'printed_code_matches_tested_files':True,'files':record['files'],'prior_code_assertions':manifest['code_checks'],'prior_museum_assertions':manifest['museum_checks'],'deliberate_faults_rejected':manifest['rejected_faults'],'scope':'Existing per-hall evidence verified by unchanged program hashes; no new engine run in this prose pass.'})
        cards.append(f'<article class="card"><p class="meta">{index:02} / {label}</p><a href="{name}.html"><img loading="lazy" src="{picture}" alt="{html.escape(label)} learner study inside Endless Museum"></a><h2>{job}</h2><p>{summary}</p><a href="{name}.html">Read this pair →</a></article>')
    appendix_md='# Optional returns\n\nThese encounters do not supply prerequisites for the required six-hall route. Their original complete text and code remain in each canonical tutorial. Their separate tests are not included in the required-route totals.\n'
    appendix_html=md(appendix_md)
    for i,(name,label,s) in enumerate(appendices):
        s=namespace(s,'a'+str(i))
        # Resolve app-relative references as explicit online links, not broken offline paths.
        s=s.replace('](/book-review/','](http://localhost:3003/book-review/')
        appendix_md+='\n\n# '+label+' — optional returns\n\n'+s
        appendix_html+='<section id="'+name+'" class="chapter"><p class="meta">'+label+' / OPTIONAL</p>'+md(s)+'</section>'
    write(OUT/'appendices.md',appendix_md);write(OUT/'appendices.html',page('Shaders / optional returns',appendix_html))
    toc='<ol class="toc">'+''.join('<li><a href="#'+c['name']+'">'+c['label']+' — '+c['job']+'</a></li>' for c in chapters)+'</ol>'
    for track in ['tutorial','final']:
        intro=PREFACE if track=='tutorial' else '# Shaders — complete reflective sequence\n\nRead alongside the museum and the tutorial. This track includes the wider collection; it is not an additional list of programs to build.\n'
        complete=intro;body=md(intro)+toc
        for i,c in enumerate(chapters,1):
            complete+='\n\n---\n\n'+c[track]
            body+='<section class="chapter" id="'+c['name']+'"><p class="meta">'+str(i)+' / '+c['label']+'</p>'+md(c[track])+'</section>'
        if track=='tutorial':complete+='\n\n# Optional returns\n\nSee appendices.md for the preserved garden, saved-record and plural-body encounters.\n'
        write(OUT/(track+'.md'),complete);write(OUT/(track+'.html'),page('Shaders / complete '+track,body))
    # Plain links also work in the book viewer, where inline scripts may be disabled.
    intro='<p class="meta">Endless Museum / Shaders / Tutorial left · Reflection right</p><h1>What a surface answers to.</h1>'
    hall_links='<div class="tabs">'+''.join('<a href="'+c['name']+'.html">'+str(i)+' / '+c['label']+'</a>' for i,c in enumerate(chapters,1))+'<a href="parallel-all.html">Show all six</a><a href="preface.html">How to read</a></div>'
    pairs=[]
    for i,c in enumerate(chapters):
        pair='<section class="chapter" id="'+c['name']+'"><p class="meta">'+c['label']+' / '+c['job']+'</p><div class="pair"><article><p class="meta">TUTORIAL / BUILD AND INVESTIGATE</p>'+md(c['tutorial'])+'</article><article><p class="meta">REFLECTION / READ THE ENCOUNTER</p>'+md(c['final'])+'</article></div></section>'
        pairs.append(pair)
        previous='<a href="'+chapters[i-1]['name']+'.html">← Previous</a>' if i else '<span>Start of sequence</span>'
        following='<a href="'+chapters[i+1]['name']+'.html">Next →</a>' if i+1<len(chapters) else '<span>End of sequence</span>'
        steps='<div class="tabs">'+previous+'<strong>'+str(i+1)+' / 6 · '+c['label']+'</strong>'+following+'</div>'
        content=page('Shaders / '+c['label']+' facing pages',intro+hall_links+steps+pair+steps,True)
        write(OUT/(c['name']+'.html'),content)
        if i==0:write(OUT/'parallel.html',content)
    write(OUT/'parallel-all.html',page('Shaders / all facing pages',intro+hall_links+''.join(pairs),True))
    sequence_before=text(OUT/'before/shaders.json');sequence_now=text(ROOT/'commons/maps/sequences/shaders.json')
    sequence_diff=''.join(difflib.unified_diff(sequence_before.splitlines(True),sequence_now.splitlines(True),fromfile='shaders.json before',tofile='shaders.json now'))
    write(OUT/'sequence.diff',sequence_diff)
    write(OUT/'changes.html',page('Shaders / reading changes','<h1>Clarified text. Same lesson programs.</h1><p>The earlier texts are preserved under before/. Current canonical copies are under chapters/. Optional material is relocated only in the collected reading, not deleted from the maps.</p>'+''.join(diffs)+'<h2>Sequence descriptions</h2><pre class="changes">'+html.escape(sequence_diff)+'</pre>'))
    count=sum(e['prior_code_assertions'] for e in evidence);museum=sum(e['prior_museum_assertions'] for e in evidence);faults=sum(e['deliberate_faults_rejected'] for e in evidence)
    data={'date':'2026-10-10','maps':source_order,'code_changed':False,'map_data_changed':False,'order_changed':False,'prior_code_assertions':count,'prior_museum_assertions':museum,'prior_deliberate_faults_rejected':faults,'fresh_engine_run':False,'scope':'Whole-sequence editorial pass. Current printed files verified against prior per-hall test hashes. No independent ghost student, headset, human-learning or cross-hall persistence claim. Optional returns excluded from aggregate test totals.','halls':evidence,'density':density}
    if ghost:
        data.update(fresh_engine_run=True,editorial_pass_fresh_engine_run=False,ghost_student=ghost,scope='Editorial pass plus subsequent fresh-context AI reconstruction of all six originals and six independent variations. Earlier author checks remain separate. Launcher support repaired. Synthetic GPU evidence; no physical headset, human-learning or cross-hall persistence claim. Optional returns excluded.')
    write(OUT/'validation.json',json.dumps(data,ensure_ascii=False,indent=2)+'\n')
    write(OUT/'summaries.md','# Six shader lessons\n\n'+'\n\n'.join('## '+c['label']+' — '+c['job']+'\n\n'+c['summary'] for c in chapters))
    rows=''.join(f'<tr><td>{d["hall"]}</td><td>{d["main_tutorial_words"]}</td><td>{d["printed_code_lines"]} / {d["files"]} files</td><td>{d["reflective_words_including_notes"]}</td></tr>' for d in density)
    report='<p class="meta">Endless Museum / Six shader halls / 10 October 2026</p><h1>What a surface answers to.</h1><p>From a mark on the familiar cube to a field that keeps what happened. The route holds; the final hall needs the most breathing room.</p><p><a href="parallel.html">Read side by side →</a> · <a href="tutorial.html">Whole tutorial</a> · <a href="final.html">Whole reflection</a> · <a href="shaders-review.zip">Download complete review ZIP</a></p><div class="note">'+str(count)+' prior code assertions, '+str(museum)+' prior museum assertions and '+str(faults)+' rejected faults are attached. This pass verified that every required printed program is unchanged. It did not rerun Godot or test an independent student.</div><div class="grid">'+''.join(cards)+'</div>'+md(REVIEW)+'<h2>Size of the reading</h2><p>Approximate whitespace word counts, including headings; reflection includes notes. Code lines include carried construction and supplied support, so these are reading sizes, not measures of new difficulty. Optional returns are excluded from main tutorial counts.</p><div class="table-scroll"><table><thead><tr><th>Hall</th><th>Main tutorial words</th><th>Printed code</th><th>Reflection words</th></tr></thead><tbody>'+rows+'</tbody></table></div><p><a href="preface.html">Preface</a> · <a href="reviewer.html">Instructions for reviewer / ghost student</a> · <a href="summaries.md">One paragraph per hall</a> · <a href="validation.json">Evidence manifest</a> · <a href="changes.html">Exact prose changes</a></p>'
    if ghost:
        report=report.replace('This pass verified that every required printed program is unchanged. It did not rerun Godot or test an independent student.','The editorial pass verified unchanged printed programs. The subsequent fresh-context AI pass below adds new execution evidence.')
        report=report.replace('<div class="grid">','<div class="note"><a href="ghost-student/index.html">New: ghost student through all six lessons →</a><br>'+str(ghost['fresh_student_assertions'])+' fresh student assertions; six independently chosen variations. Supplied-launcher fixes and their separate checks are documented.</div><div class="grid">',1)
        shutil.copytree(GHOST,OUT/'ghost-student',dirs_exist_ok=True,ignore=shutil.ignore_patterns('*.uid','*.import','*.zip','__pycache__','*.pyc'))
    write(OUT/'index.html',page('Shaders / complete readings',report))
    write(OUT/'README.md','''# Shader sequence review

Start with index.html or REVIEW.md. Read PREFACE.md, then tutorial.md and final.md; parallel.html gives next/previous facing pages. Optional returns are preserved in appendices.md. summaries.md gives one paragraph per hall. REVIEWER.md supplies the review brief.

chapters/ contains exact current canonical manuscripts, prior exact learner programs/variations/faults, museum images, logs, test receipts and source snapshots. The manuscripts are current; the per-hall manifest.json and tests.json remain historical evidence of their named runs. validation.json verifies current printed code against those hashes and records this prose-only pass. A changed manuscript hash does not imply changed program text.

Run examples within the prepared AdaResearch Godot 4.6 museum project; this bundle does not contain the whole project or XR toolkit. Source snapshots keep their repository paths. Paths inside supplied launchers are in-project paths. Some optional reference links require the localhost review server.

Teacher-authored test evidence. No new engine run, independent ghost student, human-learning test, physical-headset pass or automatic cross-hall save/transfer is claimed.
''')
    shutil.copy2(ROOT/'commons/maps/sequences/shaders.json',OUT/'shaders.json')
    for fn in ['tools/revise_shader_sequence_reading.py','tools/publish_shader_sequence_reading.py']:
        p=OUT/'source'/fn;p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/fn,p)
    with zipfile.ZipFile(OUT/'shaders-review.zip','w',zipfile.ZIP_DEFLATED) as z:
        for p in sorted(OUT.rglob('*')):
            if p.is_file() and p.suffix not in ('.zip','.uid','.import'):z.write(p,p.relative_to(OUT))
    with zipfile.ZipFile(OUT/'shaders-review.zip') as z:assert z.testzip() is None
    # Local links and unique anchors must survive aggregation and offline export.
    class Audit(HTMLParser):
        def __init__(self):super().__init__();self.links=[];self.ids=[]
        def handle_starttag(self,tag,attrs):
            self.links.extend(v for k,v in attrs if k in ('href','src'))
            self.ids.extend(v for k,v in attrs if k=='id')
    for p in OUT.glob('*.html'):
        a=Audit();a.feed(text(p));assert len(a.ids)==len(set(a.ids)),p
        for value in a.links:
            u=urlsplit(value)
            if u.scheme or u.path.startswith('/'):continue
            if u.path:assert (p.parent/unquote(u.path)).exists(),(p,value)
            elif u.fragment:assert unquote(u.fragment) in a.ids,(p,value)
    print(json.dumps({'output':str(OUT),'verified_prior_assertions':count,'museum_assertions':museum,'rejected_faults':faults,'zip_megabytes':round((OUT/'shaders-review.zip').stat().st_size/1048576,2)}))
if __name__=='__main__':main()
