from pathlib import Path
import hashlib, json, datetime, re

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[5]
manifest = HERE / 'freeze_manifest.json'
if manifest.exists(): raise RuntimeError('Freeze already exists; preserve original')
def digest(path): return hashlib.sha256(path.read_bytes()).hexdigest()
input_files = [HERE.parent/'input'/'tutorial.md', HERE.parent/'input'/'final.md']
deps = [ROOT/p for p in ['commons/interactables/push_button.tscn','commons/interactables/push_button.gd','commons/interactables/interactable_area_button_pointer.gd','addons/godot-xr-tools/objects/pickable.gd','addons/godot-xr-tools/interactables/interactable_area_button.gd','addons/godot-xr-tools/events/pointer_event.gd']]
skills = [Path('C:/Users/palle/.codex/skills')/p/'SKILL.md' for p in ['ada-dispatcher','ada-code-specialist']]
original = input_files[0].read_bytes()
listing_match = {}
for name,code in re.findall(rb'<!-- student-code:([^ >]+) -->\r?\n```gdscript\r?\n(.*?)```',original,re.S):
    listing_match[name.decode()] = (HERE/name.decode()).read_bytes()==code
assert all(listing_match.values()) and len(listing_match)==5
data = {
 'frozen_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),
 'engine_executed_before_freeze':False,
 'input_sha256':{str(p.relative_to(ROOT)):digest(p) for p in input_files},
 'declared_dependencies_read_sha256':{str(p.relative_to(ROOT)):digest(p) for p in deps},
 'skills_read_sha256':{str(p):digest(p) for p in skills},
 'student_file_sha256':{p.name:digest(p) for p in HERE.iterdir() if p.is_file()},
 'five_listings_byte_identical_to_fenced_blocks':listing_match,
 'reading_assistance_trail':[
  'Read the frozen tutorial and final reflection plus Ada dispatcher and code specialist skills.',
  'Read only declared push_button scene and its callback-chain scripts, and XRTools pickable, area button and pointer event dependencies.',
  'Scoped file-name searches only inside addons/godot-xr-tools located permitted dependencies. First rg lacked -uu and returned sparse ignored-file results; repeated with -uu.',
  'Extracted five marked listing bodies mechanically without editing their contents; prepared minimal Node3D attachment scene.',
  'Independent Python spherical cosine law computed predictions before any Godot execution. Replaced a draft default-sum test constant with calculated 213.456909662684 before freeze.',
  'No outside human or agent supplied numerical expectations or implementation corrections. No prior assessment or canonical study implementation inspected.',
  'No web page read; linked mathematical sources remain outside the executed-code evidence and the mathematical explanation is checked through direct numerical construction.'
 ],
 'assistance':'Experienced AI programmer with source extraction and independently written harness; not a novice learning evaluation.'
}
manifest.write_text(json.dumps(data,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
print(json.dumps({'freeze_manifest':str(manifest),'sha256':digest(manifest),'frozen_utc':data['frozen_utc'],'verbatim':listing_match},indent=2))
