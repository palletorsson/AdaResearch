"""Prepare exact-code P4 notes, then publish native museum evidence."""
from pathlib import Path
import argparse,hashlib,html,json,re,shutil,subprocess
import markdown

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-09-one-record-many-readings'
ART=ROOT/'commons/artifacts/camera_glitch_study'
HALL=ROOT/'commons/maps/Shader_05_Patterns'
RUN=ROOT/'ada_run/encounter_pilot/Shader_05_Patterns/record-reading'
ENGINE='C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'

def prepare():
    core=(ART/'saved_record.gd').read_text(encoding='utf-8').strip()
    example='''extends SceneTree
const Record = preload("res://saved_record.gd")

func _initialize() -> void:
\tvar record = Record.new()
\trecord.fixture()
\tvar original: PackedByteArray = record.bytes()
\tvar checksum: String = record.digest()
\tassert(original.size() == 192)
\tvar unsigned: Dictionary = Record.decode(original, 8, 8)
\tvar signed_values: Dictionary = Record.decode(original, 8, 8, true)
\tassert(unsigned.valid and signed_values.valid)
\tassert(unsigned.values[12] == 128)
\tassert(signed_values.values[12] == -128)
\tassert(is_equal_approx(record.heights(0, true, 1)[4], -1.2))
\tvar exchanged = Record.new()
\texchanged.load_bytes(record.colour_image(true).get_data())
\tassert(exchanged.colour_image(true).get_data() == original)
\tassert(not Record.decode(original, 7, 8).valid)
\tassert(record.digest() == checksum and record.bytes() == original)
\tprint("RECORD EXAMPLE: 8 assertions passed")
\tquit()
'''
    note='''## Optional return: one record, different readings

**Learning elements:** RGB8 records; row-major addresses; channel permutation; a colour-to-height mapping; unsigned and signed integers; layout validation; source identity.

The pattern lesson stays first. Then go to the existing camera instrument and press **READ RECORD**. Its left screen retains an 8 × 8 colour record. EFFECT now selects five readings on the right. The original FORM and PIXELS effects remain available through the bank button, or by leaving READ RECORD.

Press **SAVE 8 × 8** to sample the current camera view. The instrument takes one pixel at the centre of each of 64 regions; it does not average the region or recover depth. Each sample contributes red, green and blue bytes, giving 192 bytes in row-major RGB order. Moving the camera afterwards does not update this record. Saving again deliberately replaces it. This snapshot lasts while the instrument is loaded; it is not written to disk.

Choose **FIXTURE** for known values. Red increases across its columns through 0, 1, 63, 127, 128, 192, 254 and 255. Blue uses those values down the rows; green alternates 0 and 255. This supplied pattern makes boundaries easy to inspect before returning to a captured image.

In **RGB**, read each triplet as colour. In **BGR**, exchange red and blue in the receiver. Apply the exchange twice and the original order returns. The source stays untouched throughout. The small checksum is an identity witness, not a measure of the image's quality or meaning.

In **UNSIGNED HEIGHT**, choose R, G or B with CHANNEL. A byte divided by 255 becomes a height, multiplied by the strength setting and 1.2 metres. In **SIGNED HEIGHT**, the same eight bits use two's-complement interpretation: 0–127 remain, while 128–255 mean −128 through −1. Height now uses the signed value divided by 128. Both scales are declared. The witness follows cell (4, 0): its red byte is 128 in the fixture, so the second reading crosses below zero. This is a chosen mapping from colour data, not measured camera depth.

The fifth reading requests **7 × 8 RGB**. It would require 168 bytes, but the record has 192. This lesson's strict decoder returns an invalid result instead of truncating, wrapping or reading past the buffer. Other contracts are possible; this one must be explicit. RESET VIEW restores RGB, channel R and 80% strength without replacing the saved bytes.

### Reconstruct the data operation

You bring arrays, loops, coordinates, colour components and functions. The museum camera, console, display meshes and XRTools input are supplied. The following is the complete data core used by this installed study. Save it as **saved_record.gd**. Its `capture(image)` method accepts a supplied Godot Image; `fixture()` provides a complete known input when testing without the museum renderer. The code rebuilds the record and its interpretations, not the camera or the console.

```gdscript
CORE
```

The cell address is `y * 8 + x`; multiply by three and add 0, 1 or 2 to select red, green or blue. `bytes()` and the receiver image use copies. That makes it possible to interpret or exchange channels without accidentally rewriting the retained source. The decoder checks dimensions and byte count before looking at values. A sign change belongs to decoding; the height scale belongs to the receiver.

Save **record_check.gd** beside the first file. In a Godot project, run `godot --headless --path <project-folder> --script res://record_check.gd` using your Godot executable. This small check requires no `.tscn`, add-on or hidden scene reference. The spatial encounter remains in Endless Museum.

```gdscript
EXAMPLE
```

**Independent variation:** choose the blue channel at full strength. Predict which direction the fixture's slope runs, then compare it with red. Copy the saved bytes, set byte 12 to 255, and load that copy into another record. Unsigned reading gives 255; signed reading gives −1. Check that the original record and its checksum remain unchanged. This time you changed data deliberately; that is a different operation from switching receivers.

**Carry onward:** a bounded record, its address convention, an explicit interpretation and a way to detect whether it changed. The next uncertainty study can ask what happens when a reading returns to influence an action.
'''.replace('CORE',core).replace('EXAMPLE',example.strip())
    (OUT/'tutorial.md').write_text('# One record, different readings\n\n'+note,encoding='utf-8')
    path=HALL/'tutorial.md';text=path.read_text(encoding='utf-8');marker='<!-- uncertainty:p4-record -->'
    base=text.split(marker)[0].rstrip()
    path.write_text(base+'\n\n'+marker+'\n\n'+note.rstrip()+'\n',encoding='utf-8')
    reflection='''<!-- uncertainty:p4-record -->

At the camera instrument, keep one small image. Its colours rise into a field of columns. Turn to the signed reading and part of that field hangs below its own zero. The saved picture beside it has not changed. Two neighbouring values, 127 and 128, have crossed a boundary in the reading: what counted as a little more now becomes the most negative value it can hold.

There is a pleasure in watching the form open like this, and a temptation to call it a failure. But the instrument has followed the interpretation we gave it. Its discontinuity makes that choice visible. When the next setting asks the same record to fit a smaller layout, the receiver refuses; the picture remains. What has become impossible belongs to this agreement between a record and a reader. It has not made the record disappear.

<!-- uncertainty:p4-record:end -->

'''
    path=HALL/'final.md';text=path.read_text(encoding='utf-8')
    if '<!-- uncertainty:p4-record -->' in text:
        text=re.sub(r'<!-- uncertainty:p4-record -->.*?<!-- uncertainty:p4-record:end -->\s*',reflection,text,flags=re.S)
    else:
        anchor='Press RESET if you have lost the defaults.'
        assert anchor in text;text=text.replace(anchor,reflection+anchor)
    path.write_text(text,encoding='utf-8')
    (OUT/'reflection.md').write_text('# The reading changes\n\n'+reflection,encoding='utf-8')

    temp=ROOT/'ada_run/record_reading_printed';temp.mkdir(parents=True,exist_ok=True)
    (temp/'project.godot').write_text('config_version=5\n[application]\nconfig/name="Record check"\n',encoding='utf-8')
    blocks=re.findall(r'```gdscript\n(.*?)\n```',note,re.S);assert len(blocks)==2
    for name,block in zip(['saved_record.gd','record_check.gd'],blocks):(temp/name).write_text(block+'\n',encoding='utf-8')
    assert blocks[0]==core
    probe=(ROOT/'tools/probes/record_reading_core.gd').read_text()
    (temp/'full_check.gd').write_text(probe.replace('res://commons/artifacts/camera_glitch_study/saved_record.gd','res://saved_record.gd'),encoding='utf-8')
    results={}
    for name,script in [('printed','full_check.gd'),('example','record_check.gd')]:
        report=OUT/'validation'/(name+'.json');log=OUT/'validation'/(name+'.log')
        if report.exists():report.unlink()
        with log.open('w',encoding='utf-8') as stream:
            process=subprocess.Popen([ENGINE,'--headless','--path',str(temp),'--script','res://'+script,'--',str(report)],stdout=stream,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
            try:code=process.wait(timeout=30)
            except subprocess.TimeoutExpired:process.kill();process.wait();raise
        output=log.read_text(encoding='utf-8',errors='replace')
        assert code==0 and 'SCRIPT ERROR' not in output and 'Parse Error' not in output,output
        if name=='printed':
            data=json.loads(report.read_text());assert data['passed'] and len(data['checks'])==37
            results[name]={'passed':True,'checks':37}
        else:
            assert 'RECORD EXAMPLE: 8 assertions passed' in output
            results[name]={'passed':True,'assertions':8}
    (OUT/'validation/printed-results.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
    print(json.dumps(results))

def publish():
    native=json.loads((RUN/'report.json').read_text());assert native['passed'] and not native['failures'] and len(native['checks'])==121
    log=(RUN/'stdout.log').read_text(encoding='utf-8',errors='replace')
    assert not any(x in log for x in ['SCRIPT ERROR','Parse Error','Shader compilation failed'])
    for path in RUN.glob('*.png'):shutil.copy2(path,OUT/'museum'/path.name)
    for name in ['report.json','stdout.log','source_manifest.json']:shutil.copy2(RUN/name,OUT/'museum'/name)
    for name in ['tutorial.md','final.md']:shutil.copy2(HALL/name,OUT/('hall-'+name))
    files=list(ART.glob('*.gd'))+list(ART.glob('*.gdshader'))+[ART/'CameraGlitchStudy.tscn',ART/'README.md',HALL/'map_data.json',HALL/'tutorial.md',HALL/'final.md']
    files += [ROOT/'tools'/name for name in ['test_record_reading.py','publish_record_reading.py','probes/record_reading_before.gd','probes/record_reading_room.gd','probes/record_reading_core.gd','probes/camera_glitch_controls.gd']]
    manifest=[]
    for path in files:
        dest=OUT/'source'/path.relative_to(ROOT);dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,dest)
        manifest.append({'path':path.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
    (OUT/'source-manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
    style='''*{box-sizing:border-box}body{margin:0;background:#f3efe7;color:#1d292e;font:19px/1.7 Georgia,serif}header,main,footer{max-width:1280px;margin:auto;padding:32px}header{padding-top:54px}h1{font-size:clamp(40px,6vw,76px);line-height:1.05;max-width:1050px}h2{margin-top:2.4em;line-height:1.2}p,li{max-width:80ch}a{color:#93385f;text-underline-offset:4px}nav,figcaption,.eyebrow{font:14px/1.5 system-ui}nav{display:flex;gap:22px;flex-wrap:wrap}.eyebrow{letter-spacing:.09em;text-transform:uppercase}img{display:block;width:100%;height:auto}figure{margin:30px 0}figcaption{padding-top:9px;color:#536268}.pair{display:grid;grid-template-columns:1fr 1fr;gap:20px}pre{padding:24px;overflow:auto;background:#17262b;color:#f5f0e8;font:14px/1.6 Consolas}code{font-size:.85em}pre code{font-size:inherit}table{display:block;overflow:auto;border-collapse:collapse;font:15px/1.5 system-ui}td,th{padding:13px;border-bottom:1px solid #c5c8c0;text-align:left}footer{border-top:1px solid #c5c8c0}@media(max-width:760px){header,main,footer{padding:22px}.pair{display:block}}'''
    nav='<nav><a href="index.html">Museum report</a><a href="tutorial.html">Runnable lesson</a><a href="reflection.html">Reflection</a><a href="../../course/uncertainty-plan/index.html">Cross-sequence plan</a></nav>'
    for name,title,source in [('index.html','One record, different readings','REPORT.md'),('tutorial.html','One record, different readings','tutorial.md'),('reflection.html','The reading changes','reflection.md')]:
        body=markdown.markdown((OUT/source).read_text(encoding='utf-8'),extensions=['fenced_code','tables'])
        (OUT/name).write_text(f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{html.escape(title)}</title><style>{style}</style></head><body><header><div class="eyebrow">Endless Museum / Shaders: Patterns / uncertainty P4 / 9 October 2026</div>{nav}</header><main>{body}</main><footer>Native museum captures. Headset comfort, Quest performance and independent learner reconstruction remain untested.</footer></body></html>',encoding='utf-8')
    receipt={'core_checks':37,'printed_core_checks':37,'printed_example_assertions':8,'rejected_faults':2,'museum_checks':121,'earlier_camera_regressions_included':82,'source_manifest':'source-manifest.json','scope':'Installed record study; earlier camera and controls checked in museum. No new depth reconstruction, external file codec, physical headset, Quest cost or independent learner claim.'}
    (OUT/'validation.json').write_text(json.dumps(receipt,indent=2),encoding='utf-8')
    links=0
    for path in OUT.glob('*.html'):
        for ref in re.findall(r'(?:href|src)="([^"]+)"',path.read_text(encoding='utf-8')):
            if ref.startswith(('http:','https:','#')):continue
            assert (path.parent/ref.split('#')[0]).exists(),ref
            links+=1
    receipt['local_links_valid']=links;(OUT/'validation.json').write_text(json.dumps(receipt,indent=2),encoding='utf-8')
    print(json.dumps(receipt,indent=2))

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--prepare',action='store_true');args=parser.parse_args()
    if args.prepare:prepare()
    else:publish()
