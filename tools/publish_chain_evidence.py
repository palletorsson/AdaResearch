"""Move Chains review evidence out of Godot's import tree, preserving bytes."""
import hashlib, json, shutil
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'commons/void/trials/chains_studies/evidence'
DEST=ROOT.parent/'ada_encyclopedia/public/void-trial-evidence/chains_studies'
OUT=ROOT/'ada_run/quest-content-2026-10-26'

def digest(path): return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    # Fixed, named directories; no recursive deletion, no runtime junction scan.
    assert SOURCE.resolve().is_relative_to(ROOT.resolve())
    assert DEST.resolve().is_relative_to((ROOT.parent/'ada_encyclopedia/public').resolve())
    DEST.mkdir(parents=True,exist_ok=True)
    records=[]
    for source in sorted(SOURCE.iterdir()):
        if not source.is_file() or source.name in {'.gdignore','README.md'}:continue
        prefix=source.read_bytes()[:12]
        name=source.with_suffix('.jpg').name if source.suffix.lower()=='.png' and prefix.startswith(b'\xff\xd8\xff') else source.name
        target=DEST/name
        sha=digest(source)
        if target.exists():assert digest(target)==sha, f'Conflicting existing evidence: {target}'
        else:shutil.copy2(source,target)
        assert digest(target)==sha
        records.append({'from':source.relative_to(ROOT).as_posix(), 'to':str(target),
                        'url':'/void-trial-evidence/chains_studies/'+name,'sha256':sha})
        source.unlink()  # Delete only the individually verified source copy.
    (SOURCE/'README.md').write_text('# Chains review evidence\n\nEvidence is served by Ada Encyclopedia at:\n\nhttp://localhost:3003/void-trial-evidence/chains_studies/index.html\n\nThis folder is ignored by Godot. Gameplay has no dependency on its captures.\n',encoding='utf-8')
    existing=DEST/'move-receipt.json'
    if records:existing.write_text(json.dumps({'files':records},indent=2)+'\n',encoding='utf-8')
    images=sorted(p for p in DEST.iterdir() if p.suffix in {'.png','.jpg','.jpeg'})
    html='<!doctype html><meta charset="utf-8"><title>Chains studies — review evidence</title><style>body{max-width:1100px;margin:40px auto;background:#f3f0e7;font:17px system-ui}img{width:100%;height:auto}section{margin:40px 0}</style><h1>Chains studies / review evidence</h1><p>Authoring captures, kept outside the Quest game. Original image bytes retained; JPEG captures have the correct .jpg extension.</p>'
    for p in images:html+='<section><h2>'+p.stem+'</h2><img src="'+p.name+'" alt="'+p.stem+'"></section>'
    (DEST/'index.html').write_text(html,encoding='utf-8')
    OUT.mkdir(parents=True,exist_ok=True)
    receipt={'moved_files':len(records),'images':len(images),'destination':str(DEST),'checks':'SHA-256 matched before removing each source copy; .gdignore remains in Godot source.'}
    (OUT/'evidence-move.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(receipt))

if __name__=='__main__':main()
