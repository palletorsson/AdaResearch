from pathlib import Path
import hashlib,json,difflib,re
root=Path.cwd();base=root/'doc/book/iterations/2026-09-19-wavefunctions-review/middle'
owned=[
'algorithms/wavefunctions/coupled_oscillator_lattice/coupled_oscillator_lattice.gd',
'algorithms/wavefunctions/mariocontrol/DualBallFMController.gd',
'algorithms/wavefunctions/technoirgameaudio/john_cage_tech_noir.gd']
diff=[]
for path in owned:
    old=(base/'before-source'/path).read_text(encoding='utf8')
    new=(root/path).read_text(encoding='utf8')
    diff.extend(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='before/'+path,tofile='after/'+path))
(base/'source.diff').write_text(''.join(diff),encoding='utf8')
path='commons/artifacts/registry/wavefunctions.json'
d=json.loads((root/path).read_text(encoding='utf8'))
proposals=[]
descriptions={
'coupled_oscillator_lattice':'A 12 by 12 grid of damped oscillators exchanging forces with up to eight neighbours. Optional comparison controls restart the same lattice with coupling on or off, using the existing continuing sine drive or one pulse. Default 2 Hz sine excitation produces a subtle neighbour response; the pulse makes propagation more visible. Fabric variants change representation without changing these forces.',
'DualBallFMController':'Two movable ValueMapper3D balls control a phase-modulation/FM-style instrument. Blue controls carrier frequency, attack and decay; orange controls modulation ratio, index and decay. BASELINE, HOLD, PLAY and COMPARE support listening against a retained reference. Scope variants expose operands, the phase-modulation expression and output. The signal generator is unchanged.',
'bernini_columns':'CPU-generated spiral columns combine a helical centre offset, sinusoidal radius variation and angular phase through height. Their shafts rotate through time while the repeated plan creates intervals and sight lines. Procedural accompaniment is generated separately; this is not a noise-displaced vertex shader or a touch instrument.',
'john_cage_tech_noir':'A prepared vocabulary of synthesized effect clips is scheduled by chance above drone and city-ambience layers. Non-spatial AudioStreamPlayers mix the sounds; luminous forms report activity. It references John Cage without performing a particular score. Chance changes event order inside a finite vocabulary, and repeats remain possible.'}
for id,new in descriptions.items():
    proposals.append({'path':path,'keys':['artifacts',id,'description'],'old':d['artifacts'][id]['description'],'new':new})
proposals.append({'path':path,'keys':['artifacts','DualBallFMController','name'],'old':d['artifacts']['DualBallFMController']['name'],'new':'Dual Ball Phase Modulation / FM-style Synth'})
(base/'registry-proposals.json').write_text(json.dumps(proposals,ensure_ascii=False,indent=2),encoding='utf8')
def function(s,name):
    return re.search(r'^func '+name+r'\(.*?(?=^func |\Z)',s,re.M|re.S).group(0)
old=(base/'before-source/algorithms/wavefunctions/mariocontrol/DualBallFMController.gd').read_text(encoding='utf8')
new=(root/'algorithms/wavefunctions/mariocontrol/DualBallFMController.gd').read_text(encoding='utf8')
checks={'audio_generator_byte_for_byte_unchanged':function(old,'_generate_fm_sound')==function(new,'_generate_fm_sound'),
'measured_original_modes_unchanged':json.loads((base/'measures/measurements.json').read_text())==json.loads((base/'after-measures/measurements.json').read_text()),
'bernini_source_unchanged':(base/'before-source/algorithms/wavefunctions/berninicolumns/BerniniColumns.gd').read_bytes()==(root/'algorithms/wavefunctions/berninicolumns/BerniniColumns.gd').read_bytes()}
(base/'integrity-checks.json').write_text(json.dumps(checks,indent=2),encoding='utf8')
print(checks)
