#!/usr/bin/env python3
"""Build the curation-bay collection manifest (doc/curation_bays.json) for the encyclopedia gallery.

Reads every commons/maps/Curation_Bay_<seq>_<i>/map_data.json, pulls the bay's curation_station token,
and emits a manifest grouped by sequence: {sequences:{<seq>:{bay_count, bays:[{name,index,title,
artifacts:[{id,name}]}]}}, total_bays, sequence_count}. Copy the result to the encyclopedia at
public/bay-gallery/manifest.json (the /curation-bays page fetches it).

Run: python tools/build_bay_manifest.py
"""
import glob
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def _display_names():
    disp = {}
    for f in glob.glob(os.path.join(ROOT, "commons", "artifacts", "registry", "*.json")):
        try:
            d = json.load(open(f, encoding="utf-8"))
        except Exception:
            continue
        for k, v in (d.get("artifacts", {}) or {}).items():
            if isinstance(v, dict):
                disp[v.get("lookup_name", k)] = v.get("name", k)
    return disp


def main():
    disp = _display_names()
    by_seq = {}
    for dd in glob.glob(os.path.join(ROOT, "commons", "maps", "Curation_Bay_*", "map_data.json")):
        m = json.load(open(dd, encoding="utf-8"))
        name = m["map_info"]["name"]
        mm = re.match(r"Curation_Bay_(.+)_(\d+)$", name)
        if not mm:
            continue   # skip Curation_Bay_Demo and the like
        seq, idx = mm.group(1), int(mm.group(2))
        token = None
        for row in m["layers"]["interactables"]:
            for c in (row if isinstance(row, list) else row.split(",")):
                if c and "curation_station" in c:
                    token = c
        arts = token.split("#artifacts:")[1].split("#")[0].split(",") if token else []
        by_seq.setdefault(seq, []).append({
            "name": name, "index": idx, "title": m["map_info"].get("title", name),
            "artifacts": [{"id": a, "name": disp.get(a, a)} for a in arts],
        })

    out = {"sequences": {}, "total_bays": 0, "sequence_count": len(by_seq)}
    for seq in sorted(by_seq):
        bays = sorted(by_seq[seq], key=lambda b: b["index"])
        out["sequences"][seq] = {"bay_count": len(bays), "bays": bays}
        out["total_bays"] += len(bays)

    dst = os.path.join(ROOT, "doc", "curation_bays.json")
    json.dump(out, open(dst, "w", encoding="utf-8"), indent=1, ensure_ascii=False)
    print("manifest: %d bays across %d sequences -> doc/curation_bays.json"
          % (out["total_bays"], out["sequence_count"]))
    print("copy to: ada_encyclopedia/public/bay-gallery/manifest.json")


if __name__ == "__main__":
    main()
