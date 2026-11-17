"""Verify the actual APK contains the current chapter score, bindings and playable audio."""
import argparse,hashlib,json,re,zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def digest(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--out',type=Path,required=True);a=p.parse_args()
 build=json.loads((a.out/'build.json').read_text(encoding='utf-8'))
 assert build.get('export_completed') and build.get('zip_integrity_passed') and build.get('runtime_payload_passed'), 'Incomplete game export'
 assert digest(Path(build['apk']))==build['sha256'],'APK changed after export'
 bindings=json.loads((ROOT/'commons/data/opera/tower_bindings.json').read_text(encoding='utf-8'))
 manifest=json.loads((ROOT/'audio/voice_cache/chapters-20261117.json').read_text(encoding='utf-8'))
 report={'apk_sha256':build['sha256'],'exact_json':{},'audio':[],'scripts':[]}
 with zipfile.ZipFile(build['apk']) as z:
  names=set(z.namelist())
  for relative in ['commons/data/opera/tower_bindings.json',bindings['score'].removeprefix('res://'),bindings['accompaniment'].removeprefix('res://')]:
   actual=z.read('assets/'+relative);assert actual==(ROOT/relative).read_bytes(),relative
   report['exact_json'][relative]=hashlib.sha256(actual).hexdigest()
  score=json.loads(z.read('assets/'+bindings['score'].removeprefix('res://')))
  ids={p['object_id'] for p in score['phrases']}
  assert ids=={x['object_id'] for x in manifest['files']},'Active score differs from audio manifest'
  assert all(i in ids for m in bindings['maps'].values() for i in m.values()),'Binding lacks a phrase'
  assert len(ids)==94 and len(bindings['maps'])==22
  cfg=json.loads(z.read('assets/'+bindings['accompaniment'].removeprefix('res://')))
  audio=['audio/voice_cache/'+x['file'] for x in manifest['files']]+[cfg[k].removeprefix('res://') for k in ['bed','pulse']]
  for relative in audio:
   imported='assets/'+relative+'.import'
   assert imported in names,relative
   info=z.read(imported).decode('utf-8');target=re.search(r'^path="res://(.+)"$',info,re.M)
   assert target and 'assets/'+target[1] in names,(relative,target)
   assert len(z.read('assets/'+target[1]))>1000,relative
   report['audio'].append(relative)
  for relative in ['commons/void/inner_opera.gd','commons/void/inner_voice_godot.gd','commons/void/inner_opera_score.gd','audio/generators/PhonemeVoice.gd']:
   remap='assets/'+relative+'.remap';assert remap in names,relative
   target=re.search(r'path="res://(.+)"',z.read(remap).decode('utf-8'))
   assert target and 'assets/'+target[1] in names,relative
   report['scripts'].append(relative)
  # The LJ sample bank remains available for editable/new phrases as well.
  report['lj_samples']=sum(n.startswith('assets/audio/voice_samples/lj_consonants/') and n.endswith('.wav.import') for n in names)
  assert report['lj_samples']>=17
 report.update(passed=True,phrases=len(ids),maps=len(bindings['maps']),bindings=sum(len(m) for m in bindings['maps'].values()))
 (a.out/'opera-payload.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
 print(json.dumps({k:v for k,v in report.items() if k not in ['audio','exact_json','scripts']},indent=2))
if __name__=='__main__': main()
