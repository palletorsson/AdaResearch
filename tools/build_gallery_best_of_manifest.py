from __future__ import annotations

import json
import shutil
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
WEB_PUBLIC = ROOT.parent / "ada_encyclopedia" / "public"
OUT_DIR = ROOT / "commons" / "generated" / "gallery_best_of"
OUT_IMAGES = OUT_DIR / "images"
OUT_CONFIGS = OUT_DIR / "configs"
OUT_MANIFEST = OUT_DIR / "manifest.json"

VERDICT_RANK = {
    "winner": 5,
    "strong": 4,
    "working": 3,
    "interesting": 2,
    "weak": 2,
    "broken": 0,
}


def titleize(name: str) -> str:
    return name.replace("-", " ").replace("_", " ").title()


def score_entry(entry_id: str, data: dict) -> tuple:
    stars = int(data.get("stars", 0) or 0)
    verdict = str(data.get("verdict", "")).strip().lower()
    verdict_rank = VERDICT_RANK.get(verdict, 1)
    # Stable deterministic tiebreaker.
    return (stars, verdict_rank, entry_id)


def find_image_for_entry(gallery_dir: Path, entry_id: str) -> Path | None:
    exact = gallery_dir / f"{entry_id}.png"
    if exact.exists():
        return exact

    entry_tokens = set(entry_id.split("_"))
    best_match: tuple[int, str, Path] | None = None
    for candidate in gallery_dir.glob("*.png"):
        stem_tokens = set(candidate.stem.split("_"))
        overlap = len(entry_tokens & stem_tokens)
        if overlap <= 0:
            continue
        rank = (overlap, candidate.stem)
        if best_match is None or rank > (best_match[0], best_match[1]):
            best_match = (overlap, candidate.stem, candidate)
    return best_match[2] if best_match else None


def live_kind_for_gallery(gallery_name: str) -> str:
    return {
        "morphology-gallery": "morphology",
        "lsystem-gallery": "lsystem",
        "rd-gallery": "rd",
        "primitive-stack-gallery": "primitive_stack",
    }.get(gallery_name, "")


def build_manifest() -> dict:
    OUT_IMAGES.mkdir(parents=True, exist_ok=True)
    OUT_CONFIGS.mkdir(parents=True, exist_ok=True)
    items: list[dict] = []

    for gallery_dir in sorted(p for p in WEB_PUBLIC.iterdir() if p.is_dir() and p.name.endswith("-gallery")):
        evals_path = gallery_dir / "evals.json"
        if not evals_path.exists():
            continue

        data = json.loads(evals_path.read_text(encoding="utf-8-sig"))
        evals = data.get("evals", {})
        if not isinstance(evals, dict) or not evals:
            continue

        candidates: list[tuple] = []
        for entry_id, entry_data in evals.items():
            if not isinstance(entry_data, dict):
                continue
            image_path = find_image_for_entry(gallery_dir, entry_id)
            if image_path is None:
                continue
            candidates.append((score_entry(entry_id, entry_data), entry_id, entry_data, image_path))

        if not candidates:
            continue

        candidates.sort(reverse=True)
        _, entry_id, entry_data, image_path = candidates[0]

        copied_name = f"{gallery_dir.name}__{image_path.name}"
        copied_path = OUT_IMAGES / copied_name
        shutil.copy2(image_path, copied_path)

        config_res_path = ""
        public_config = gallery_dir / f"{entry_id}.json"
        if public_config.exists():
            copied_cfg_name = f"{gallery_dir.name}__{entry_id}.json"
            copied_cfg_path = OUT_CONFIGS / copied_cfg_name
            shutil.copy2(public_config, copied_cfg_path)
            config_res_path = f"res://commons/generated/gallery_best_of/configs/{copied_cfg_name}"

        items.append(
            {
                "gallery": gallery_dir.name,
                "gallery_title": titleize(gallery_dir.name.removesuffix("-gallery")),
                "entry_id": entry_id,
                "title": titleize(entry_id),
                "stars": int(entry_data.get("stars", 0) or 0),
                "verdict": str(entry_data.get("verdict", "")).strip(),
                "notes": str(entry_data.get("notes", "")).strip(),
                "source_route": f"http://localhost:3003/{gallery_dir.name}/{image_path.name}",
                "image_path": f"res://commons/generated/gallery_best_of/images/{copied_name}",
                "config_path": config_res_path,
                "live_kind": live_kind_for_gallery(gallery_dir.name),
            }
        )

    return {
        "generated_on": "2026-04-23",
        "source_public_dir": str(WEB_PUBLIC),
        "items": items,
    }


def main() -> None:
    manifest = build_manifest()
    OUT_MANIFEST.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(f"Wrote {OUT_MANIFEST}")
    print(f"Items: {len(manifest['items'])}")


if __name__ == "__main__":
    main()
