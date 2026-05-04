#!/usr/bin/env python3
"""
Generate a self-contained HTML gallery for every PNG in the Godot
user-data folder. Uses relative paths so the HTML works as a static
file (open with a double-click).

Default location:
    C:/Users/palle/AppData/Roaming/Godot/app_userdata/Ada Research Zero One/

Output:
    <that folder>/_gallery.html

Run:
    python tools/build_godot_userdata_gallery.py
    python tools/build_godot_userdata_gallery.py --root <other-path>
"""
from __future__ import annotations
import argparse
import html
import sys
from collections import defaultdict
from pathlib import Path

DEFAULT_ROOT = Path(r"C:/Users/palle/AppData/Roaming/Godot/app_userdata/Ada Research Zero One")


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--root", default=str(DEFAULT_ROOT),
                   help="Folder to scan (default: Godot Ada Research Zero One user_data)")
    p.add_argument("--out", default=None,
                   help="Output HTML path (default: <root>/_gallery.html)")
    p.add_argument("--open", action="store_true",
                   help="Open the gallery in the default browser when done.")
    args = p.parse_args()

    root = Path(args.root).resolve()
    if not root.exists():
        print(f"root not found: {root}")
        return 1

    out = Path(args.out) if args.out else (root / "_gallery.html")

    # Collect all PNGs grouped by their immediate parent folder.
    groups: dict[str, list[Path]] = defaultdict(list)
    total = 0
    for png in root.rglob("*.png"):
        rel = png.relative_to(root)
        parent = str(rel.parent).replace("\\", "/") or "(root)"
        groups[parent].append(rel)
        total += 1

    if total == 0:
        print(f"no PNGs under {root}")
        return 1

    # Sort groups by name; within each group, sort by mtime descending so
    # the newest captures show first.
    sorted_groups = sorted(groups.items(), key=lambda kv: kv[0])
    for k, files in sorted_groups:
        files.sort(key=lambda f: (root / f).stat().st_mtime, reverse=True)

    # Build HTML.
    h = []
    h.append("<!doctype html><html><head><meta charset='utf-8'>")
    h.append(f"<title>Godot captures — {html.escape(root.name)}</title>")
    h.append("<style>")
    h.append("""
      * { box-sizing: border-box; }
      body { margin: 0; padding: 16px 24px; background: #0e0e12; color: #d8d8e0;
             font: 13px/1.4 -apple-system, system-ui, "Segoe UI", sans-serif; }
      h1 { font-size: 20px; margin: 8px 0 4px; }
      .totals { color: #6e6e80; font-size: 11px; margin-bottom: 16px; }
      .toc { display: flex; flex-wrap: wrap; gap: 6px; margin-bottom: 24px; }
      .toc a { font-family: ui-monospace, monospace; font-size: 11px;
               padding: 3px 8px; border-radius: 4px; background: #1c1c24;
               color: #b8b8c8; text-decoration: none; }
      .toc a:hover { background: #2a2a36; color: #fff; }
      h2 { font-size: 14px; margin: 24px 0 6px; padding-top: 12px;
           border-top: 1px solid #1c1c24; font-family: ui-monospace, monospace; }
      h2 .count { color: #6e6e80; font-weight: 400; margin-left: 8px; font-size: 11px; }
      .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
              gap: 8px; }
      .tile { background: #1c1c24; border-radius: 6px; overflow: hidden; cursor: zoom-in;
              border: 1px solid transparent; transition: border-color .15s; }
      .tile:hover { border-color: #4a4a5e; }
      .tile img { width: 100%; height: 140px; object-fit: contain; background: #08080c;
                  display: block; }
      .tile .name { padding: 6px 8px; font-family: ui-monospace, monospace; font-size: 10px;
                    color: #9a9aae; word-break: break-all; }
      /* Lightbox */
      #lightbox { position: fixed; inset: 0; background: rgba(0,0,0,.92); display: none;
                  z-index: 100; cursor: zoom-out; align-items: center; justify-content: center; }
      #lightbox.open { display: flex; }
      #lightbox img { max-width: 95vw; max-height: 92vh; box-shadow: 0 8px 60px rgba(0,0,0,.5); }
      #lightbox .label { position: absolute; bottom: 16px; left: 50%; transform: translateX(-50%);
                          background: rgba(0,0,0,.55); color: #d8d8e0; padding: 6px 14px;
                          border-radius: 4px; font-family: ui-monospace, monospace; font-size: 11px; }
      #lightbox .close { position: absolute; top: 16px; right: 16px; color: rgba(255,255,255,.7);
                          font-family: ui-monospace, monospace; font-size: 12px;
                          padding: 6px 12px; border: 1px solid rgba(255,255,255,.3);
                          border-radius: 4px; }
    """)
    h.append("</style></head><body>")
    h.append(f"<h1>{html.escape(root.name)} — Godot captures</h1>")
    h.append(f"<div class='totals'>{total} PNGs across {len(sorted_groups)} folders · "
             f"<code>{html.escape(str(root))}</code></div>")

    # TOC
    h.append("<div class='toc'>")
    for folder, files in sorted_groups:
        anchor = "g_" + folder.replace("/", "_").replace(" ", "_").replace(".", "_")
        h.append(f"<a href='#{anchor}'>{html.escape(folder)} <span style='opacity:.5'>· {len(files)}</span></a>")
    h.append("</div>")

    # Sections
    for folder, files in sorted_groups:
        anchor = "g_" + folder.replace("/", "_").replace(" ", "_").replace(".", "_")
        h.append(f"<h2 id='{anchor}'>{html.escape(folder)}<span class='count'>{len(files)}</span></h2>")
        h.append("<div class='grid'>")
        for rel in files:
            # Relative URL works because gallery sits at root.
            url = str(rel).replace("\\", "/")
            display_name = rel.name
            h.append(
                f"<div class='tile' onclick=\"openLightbox('{html.escape(url)}','{html.escape(display_name)}')\">"
                f"<img src='{html.escape(url)}' loading='lazy' alt='{html.escape(display_name)}'/>"
                f"<div class='name'>{html.escape(display_name)}</div>"
                f"</div>"
            )
        h.append("</div>")

    # Lightbox + JS
    h.append("""
<div id='lightbox' onclick='closeLightbox()'>
  <img id='lb-img' />
  <div class='label' id='lb-label'></div>
  <div class='close'>esc ✕</div>
</div>
<script>
  function openLightbox(src, name) {
    const lb = document.getElementById('lightbox');
    document.getElementById('lb-img').src = src;
    document.getElementById('lb-label').textContent = name;
    lb.classList.add('open');
  }
  function closeLightbox() {
    document.getElementById('lightbox').classList.remove('open');
  }
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') closeLightbox();
  });
</script>
""")
    h.append("</body></html>")

    out.write_text("\n".join(h), encoding="utf-8")
    print(f"wrote {out}  ({total} PNGs, {len(sorted_groups)} sections)")

    if args.open:
        import webbrowser
        webbrowser.open(out.as_uri())
    return 0


if __name__ == "__main__":
    sys.exit(main())
