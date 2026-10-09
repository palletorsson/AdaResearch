"""Build a portable reading copy of the encyclopedia blog from its canonical Markdown."""
from pathlib import Path
import hashlib
import html
import json
import re
import shutil
import markdown

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]
SLUG = HERE.name
SOURCE = REPO.parent / "ada_encyclopedia" / "src" / "content" / "blog" / f"{SLUG}.md"
CAPTURES = {
    "conveyor-aftermath.png": "2026-10-07-everything-worked/museum/aftermath.png",
    "vectors-in-hand.png": "2026-10-07-vectors-one-room/layout/direction-moved.png",
    "flying-points.png": "2026-10-07-flight-forward-and-confetti/flight/thrust-points.png",
    "swings.png": "2026-10-07-forces-stick-hinges-and-catalyst/museum/Vectors_Act4b_Oscillation/stick-and-swings.png",
    "donut-mortar.png": "2026-10-07-forces-extravaganza/after/Vectors_Act5_ForceAsPlace/donut-cake.png",
    "catapult.png": "2026-10-07-human-catapult-launch/museum/red-trajectory.png",
    "slope-basins.png": "2026-10-07-slopes-walk-up-and-drop/museum/basin-trails.png",
    "flowers.png": "2026-10-07-mower-grass-to-flowers/museum/flowers-in-the-cut.png",
    "club-and-bag.png": "2026-10-07-club-and-punching-bag/museum/hanging-bag.png",
    "gravity-oval.png": "2026-10-07-gravity-oval/museum/whole-oval.png",
    "endless-drive.png": "2026-10-07-endless-drive/museum/endless-bend.png",
}


def main():
    raw = SOURCE.read_text(encoding="utf-8-sig")
    front, body = raw.split("---", 2)[1:]
    metadata = {}
    for line in front.strip().splitlines():
        key, value = line.split(":", 1)
        metadata[key] = json.loads(value.strip())
    (HERE / "images").mkdir(exist_ok=True)
    manifest = []
    for name, source in CAPTURES.items():
        original = REPO / "doc" / "book" / "iterations" / source
        destination = HERE / "images" / name
        shutil.copy2(original, destination)
        manifest.append({
            "image": f"images/{name}",
            "source": original.relative_to(REPO).as_posix(),
            "sha256": hashlib.sha256(destination.read_bytes()).hexdigest(),
            "source_identical": destination.read_bytes() == original.read_bytes(),
            "kind": "native Godot museum capture; inspected before inclusion",
        })
    (HERE / "post.md").write_text(raw, encoding="utf-8")
    rendered = markdown.markdown(body, extensions=["extra"])
    for name, source in CAPTURES.items():
        rendered = rendered.replace(f"/book-review/doc/book/iterations/{source}", f"images/{name}")
    # Existing evidence reports remain readable even when the review server is offline.
    def local_report(match):
        relative, marker, fragment = match[1].partition("#")
        return 'href="' + (REPO / relative).as_uri() + (marker + fragment if marker else "") + '"'
    rendered = re.sub(r'href="/book-review/([^\"]+)"', local_report, rendered)
    rendered = re.sub(r'<p>(<img [^>]+>)</p>\s*<p><em>(.*?)</em></p>',
                      r'<figure>\1<figcaption>\2</figcaption></figure>', rendered, flags=re.S)
    rendered = rendered.replace('<img ', '<img loading="lazy" decoding="async" ')
    title = html.escape(metadata["title"])
    subtitle = html.escape(metadata["subtitle"])
    page = f'''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title} — Endless Museum</title>
<style>
:root{{color-scheme:light;--paper:#f6f3ed;--ink:#242329;--muted:#65616b;--accent:#813d65}}
*{{box-sizing:border-box}}body{{margin:0;background:var(--paper);color:var(--ink);font:20px/1.72 Georgia,'Times New Roman',serif}}
nav{{max-width:1120px;margin:0 auto;padding:28px 32px;display:flex;justify-content:space-between;gap:20px;font:12px/1.5 system-ui,sans-serif;letter-spacing:.13em;text-transform:uppercase;border-bottom:1px solid #d6cfd0}}
a{{color:var(--accent);text-decoration-thickness:1px;text-underline-offset:3px}}nav a{{text-decoration:none}}
header{{max-width:890px;margin:78px auto 45px;padding:0 30px}}.eyebrow{{font:12px/1.5 system-ui,sans-serif;letter-spacing:.16em;text-transform:uppercase;color:var(--accent)}}
h1{{font-size:clamp(42px,6.1vw,76px);line-height:1.03;font-weight:500;letter-spacing:-.035em;margin:22px 0 28px}}
.subtitle{{font-size:24px;line-height:1.45;color:var(--muted);max-width:700px}}.meta{{font:13px/1.7 system-ui,sans-serif;color:var(--muted);margin-top:28px}}
article{{max-width:1120px;margin:auto;padding:0 30px 76px}}article>p,article>hr{{max-width:720px;margin:0 auto 25px}}article>p:first-child{{font-size:25px;line-height:1.6}}
figure{{margin:48px 0 50px}}figure img{{display:block;width:100%;height:auto;border:1px solid #d7d1d1;background:#242632}}figcaption{{max-width:760px;margin:13px auto 0;color:var(--muted);font:14px/1.65 system-ui,sans-serif}}
strong{{font-weight:700}}hr{{border:0;border-top:1px solid #d6cfd0;margin-top:56px!important}}footer{{border-top:1px solid #d6cfd0;padding:30px;text-align:center;font:13px/1.7 system-ui,sans-serif;color:var(--muted)}}
@media(max-width:600px){{body{{font-size:18px}}nav{{padding:22px}}header{{margin-top:44px;padding:0 22px}}article{{padding:0 22px 40px}}.subtitle{{font-size:21px}}figure{{margin:32px -10px}}figcaption{{padding:0 10px}}}}
@media print{{nav,footer{{display:none}}header{{margin-top:15px}}body{{background:white;font-size:11pt}}h1{{font-size:32pt}}figure{{break-inside:avoid;margin:25px 0}}a{{color:inherit}}}}
</style></head><body>
<nav><span>Endless Museum · Research journal</span><a href="post.md">Markdown source ↗</a></nav>
<header><div class="eyebrow">Forces · 6–7 October 2026</div><h1>{title}</h1><div class="subtitle">{subtitle}</div><div class="meta">Ada Research · Published 8 October 2026 · 11 museum captures</div></header>
<article id="reading">{rendered}</article>
<footer>Always another room · <a href="image-sources.json">Capture provenance</a> · <a href="publication-checks.json">Publication checks</a></footer>
</body></html>'''
    (HERE / "index.html").write_text(page, encoding="utf-8")
    (HERE / "image-sources.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    local_links = re.findall(r'\]\((/book-review/[^)]+)\)', raw)
    missing = [link for link in local_links if not (REPO / link.removeprefix("/book-review/").split("#")[0]).is_file()]
    unsupported = [link for link in local_links if not link.startswith("/book-review/doc/book/iterations/")]
    checks = {
        "canonical_source": str(SOURCE),
        "portable_copy_matches_source": (HERE / "post.md").read_text(encoding="utf-8") == raw,
        "image_count": len(manifest), "figure_count": page.count("<figure>"),
        "all_images_are_unmodified_copies": all(x["source_identical"] for x in manifest),
        "book_review_links_checked": len(local_links), "missing_local_targets": missing,
        "links_outside_existing_review_route": unsupported,
        "browser_preview": "Blocked by browser security policy: file URLs are not permitted. No workaround attempted. Source images were visually inspected; HTML structure and local paths checked.",
        "body_word_count": len(re.findall(r"\b[\w’'-]+\b", re.sub(r"!?\[[^]]*\]\([^)]*\)", "", body))),
        "runtime_scope": "No museum code changed and no engine tests rerun for this blog. It reports saved scoped verification.",
        "server": "Local review server was offline during publication. Portable HTML uses local images and file links.",
    }
    (HERE / "publication-checks.json").write_text(json.dumps(checks, indent=2), encoding="utf-8")
    assert not missing, missing
    assert not unsupported, unsupported
    assert checks["figure_count"] == checks["image_count"] == 11
    print(json.dumps(checks, indent=2))


if __name__ == "__main__":
    main()
