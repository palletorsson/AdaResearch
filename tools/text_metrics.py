#!/usr/bin/env python
"""
text_metrics.py — pure-Python scorer for map text files. Zero LLM.

Companion to `pipe_fixer.py` but for text: measure code ratio, caption length,
paragraph length, forbidden words, and per-file-role threshold compliance
across the spine. Fast enough to run on the whole curriculum in seconds.

Designed to be the objective feedback signal for the auto-research text
loop — the analog of `image_content_score()` in pipe_fixer.py. Zero network
calls; reads only from disk.

Usage::

    # single file
    python tools/text_metrics.py --map Array_Patterns --file tutorial.md
    python tools/text_metrics.py --path commons/maps/Array_Patterns/tutorial.md

    # walk the spine
    python tools/text_metrics.py --spine
    python tools/text_metrics.py --spine --file tutorial.md
    python tools/text_metrics.py --spine --format table

    # all core files per map
    python tools/text_metrics.py --map Array_Patterns

    # dump baseline to json
    python tools/text_metrics.py --spine --format json > doc/text_metrics_baseline.json
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

REPO = Path(__file__).resolve().parent.parent
MAPS = REPO / "commons" / "maps"
SPINE_FILE = MAPS / "curriculum_spine.json"
SEQUENCES_DIR = MAPS / "sequences"

try:
    sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
except Exception:
    pass

# ── File-role thresholds ────────────────────────────────────────────────
# Each threshold has: target, hard_fail_below/above. Metrics not listed
# don't gate. Sourced from markdown-file-roles.ts + populate prompts.

THRESHOLDS: dict[str, dict[str, Any]] = {
    "blurb.md": {
        "word_count_min": 40,
        "word_count_max": 220,
        "paragraphs_max": 5,
        # Blurbs often use rapid declarative fragments — 10 short sentences
        # in one paragraph is valid style. Real wall-of-text would be 15+.
        "max_paragraph_sentences": 12,
        "code_ratio_max": 0.05,
    },
    "technical.md": {
        # technical.md now tolerates two shapes: prose-heavy (2000-3500w, 15-30% code)
        # and code-dense (700-1500w, 50-80% code). The threshold below is the
        # UNION floor — short AND low-code fails; short AND high-code passes.
        "word_count_min": 700,
        "word_count_max": 3500,
        "code_ratio_min": 0.15,
        "code_ratio_max": 0.80,
        "max_paragraph_sentences": 8,
    },
    "tutorial.md": {
        "word_count_min": 400,
        "word_count_max": 1500,
        "code_ratio_min": 0.40,  # rule says ≥0.60 but captions push effective ratio down
        "code_blocks_min": 6,
        "code_blocks_max": 20,
        "caption_max_words": 15,
        "max_paragraph_sentences": 3,
    },
    "critical.md": {
        "word_count_min": 500,
        "word_count_max": 3500,
        # Allow slightly higher code density — some critical pieces cite
        # one concrete code example to anchor the theoretical argument.
        "code_ratio_max": 0.25,
        "max_paragraph_sentences": 10,
    },
    "summary.md": {
        # Corpus standard is 180-450 words of dense structured prose with
        # bullet lists for layout/elements/atmosphere. The original populate
        # prompt's 800-1200 target is aspirational but doesn't match the
        # existing good files.
        "word_count_min": 180,
        "word_count_max": 1500,
        "max_paragraph_sentences": 8,
    },
    "intent.md": {
        "word_count_min": 150,
        "word_count_max": 1200,
    },
    "intent_summary.md": {
        "word_count_min": 50,
        "word_count_max": 400,
    },
}

# Forbidden words from Writer Pro's ADA_CONTEXT / scorecard rules.
FORBIDDEN_WORDS = [
    # AI-slop markers
    "delve", "delves", "delving",
    "tapestry",
    "fascinating",
    "comprehensive",
    "realm",
    "navigating",
    "landscape of",
    "intricate",
    "essence of",
    # Transitional filler the tutorial role bans
    "furthermore",
    "moreover",
    "in addition",
    "additionally",
]

CORE_FILES = ["blurb.md", "technical.md", "tutorial.md", "critical.md",
              "summary.md", "intent.md"]


# ── Parsers ──────────────────────────────────────────────────────────────

CODE_FENCE_RE = re.compile(r"```(\w*)\n(.*?)```", re.DOTALL)
SENTENCE_END = re.compile(r"[.!?][\s\n]+")
WORD_RE = re.compile(r"\b\w+\b")


def extract_code_blocks(text: str) -> list[tuple[str, str]]:
    """Return list of (language, body) tuples for each fenced block."""
    return [(m.group(1), m.group(2)) for m in CODE_FENCE_RE.finditer(text)]


def strip_code_blocks(text: str) -> str:
    return CODE_FENCE_RE.sub("", text)


def char_count_no_whitespace(s: str) -> int:
    return sum(1 for c in s if not c.isspace())


def word_count(s: str) -> int:
    return len(WORD_RE.findall(s))


def split_paragraphs(text: str) -> list[str]:
    """Paragraphs are non-empty prose blocks outside code fences."""
    prose = strip_code_blocks(text)
    # Strip markdown headings for paragraph counting but keep them as
    # paragraph separators
    paras = [p.strip() for p in re.split(r"\n\s*\n", prose)]
    return [p for p in paras if p and not p.startswith("#")]


def count_sentences(paragraph: str) -> int:
    # Trim trailing punct before counting
    p = paragraph.strip()
    if not p:
        return 0
    # Simple split — we only need a ballpark for threshold checks.
    # Re-add the last fragment if it lacks terminal punctuation.
    parts = SENTENCE_END.split(p)
    # Filter empties
    parts = [x for x in parts if x.strip()]
    return max(1, len(parts))


def captions_before_code(text: str) -> list[str]:
    """Last non-empty, non-heading, non-code prose line immediately preceding
    each code fence. Returns [] if no caption (code block first, etc.)."""
    captions: list[str] = []
    lines = text.splitlines()
    i = 0
    while i < len(lines):
        if lines[i].lstrip().startswith("```"):
            # Walk back to find the preceding non-empty line
            caption = ""
            j = i - 1
            while j >= 0:
                s = lines[j].strip()
                if not s:
                    j -= 1
                    continue
                if s.startswith("```"):
                    break  # back-to-back code blocks
                if s.startswith("#"):
                    break  # heading, not a caption
                caption = s
                break
            captions.append(caption)
            # Skip to the end of this code block
            i += 1
            while i < len(lines) and not lines[i].lstrip().startswith("```"):
                i += 1
            i += 1  # past the closing fence
            continue
        i += 1
    return captions


# ── Metric core ──────────────────────────────────────────────────────────

def compute_metrics(text: str, role: str) -> dict[str, Any]:
    blocks = extract_code_blocks(text)
    prose = strip_code_blocks(text)
    total_chars = char_count_no_whitespace(text)
    code_chars = sum(char_count_no_whitespace(body) for _, body in blocks)
    code_ratio = (code_chars / total_chars) if total_chars else 0.0

    paragraphs = split_paragraphs(text)
    sentence_counts = [count_sentences(p) for p in paragraphs]
    max_para_sents = max(sentence_counts) if sentence_counts else 0
    avg_para_sents = (sum(sentence_counts) / len(sentence_counts)) if sentence_counts else 0

    captions = captions_before_code(text) if role == "tutorial.md" else []
    caption_lens = [word_count(c) for c in captions if c]
    missing_captions = sum(1 for c in captions if not c)
    long_captions = sum(1 for n in caption_lens if n > 15)

    prose_lower = prose.lower()
    forbidden_hits: dict[str, int] = {}
    for w in FORBIDDEN_WORDS:
        n = len(re.findall(rf"\b{re.escape(w)}\b", prose_lower))
        if n:
            forbidden_hits[w] = n

    heading_line = text.lstrip().splitlines()[0] if text.strip() else ""
    starts_with_heading = heading_line.startswith("#")

    return {
        "word_count": word_count(text),
        "char_count_no_ws": total_chars,
        "code_blocks": len(blocks),
        "code_char_count": code_chars,
        "code_ratio": round(code_ratio, 4),
        "paragraphs": len(paragraphs),
        "max_paragraph_sentences": max_para_sents,
        "avg_paragraph_sentences": round(avg_para_sents, 2),
        "captions_total": len(captions),
        "captions_missing": missing_captions,
        "captions_over_limit": long_captions,
        "caption_max_words": max(caption_lens) if caption_lens else 0,
        "caption_avg_words": round(sum(caption_lens) / len(caption_lens), 2) if caption_lens else 0,
        "forbidden_word_hits": forbidden_hits,
        "forbidden_word_total": sum(forbidden_hits.values()),
        "starts_with_heading": starts_with_heading,
    }


def evaluate_thresholds(metrics: dict[str, Any], role: str) -> dict[str, Any]:
    """Return {failures: [...], passes: [...], status: 'pass'|'fail'|'warn'}."""
    th = THRESHOLDS.get(role, {})
    failures: list[str] = []
    passes: list[str] = []

    def check(name: str, ok: bool, detail: str) -> None:
        (passes if ok else failures).append(f"{name}: {detail}")

    wc = metrics["word_count"]
    if "word_count_min" in th:
        check("word_count_min", wc >= th["word_count_min"],
              f"{wc} (need ≥{th['word_count_min']})")
    if "word_count_max" in th:
        check("word_count_max", wc <= th["word_count_max"],
              f"{wc} (need ≤{th['word_count_max']})")

    cr = metrics["code_ratio"]
    if "code_ratio_min" in th:
        check("code_ratio_min", cr >= th["code_ratio_min"],
              f"{cr:.2f} (need ≥{th['code_ratio_min']:.2f})")
    if "code_ratio_max" in th:
        check("code_ratio_max", cr <= th["code_ratio_max"],
              f"{cr:.2f} (need ≤{th['code_ratio_max']:.2f})")

    if "code_blocks_min" in th:
        check("code_blocks_min", metrics["code_blocks"] >= th["code_blocks_min"],
              f"{metrics['code_blocks']} (need ≥{th['code_blocks_min']})")
    if "code_blocks_max" in th:
        check("code_blocks_max", metrics["code_blocks"] <= th["code_blocks_max"],
              f"{metrics['code_blocks']} (need ≤{th['code_blocks_max']})")

    if "max_paragraph_sentences" in th:
        check("max_paragraph_sentences",
              metrics["max_paragraph_sentences"] <= th["max_paragraph_sentences"],
              f"{metrics['max_paragraph_sentences']} (need ≤{th['max_paragraph_sentences']})")

    if "paragraphs_max" in th:
        check("paragraphs_max", metrics["paragraphs"] <= th["paragraphs_max"],
              f"{metrics['paragraphs']} (need ≤{th['paragraphs_max']})")

    if "caption_max_words" in th and metrics["captions_total"]:
        check("caption_max_words",
              metrics["caption_max_words"] <= th["caption_max_words"],
              f"{metrics['caption_max_words']} (need ≤{th['caption_max_words']})")
        check("captions_missing",
              metrics["captions_missing"] == 0,
              f"{metrics['captions_missing']} missing (need 0)")

    if metrics["forbidden_word_total"]:
        failures.append(
            f"forbidden_words: {metrics['forbidden_word_total']} hit — "
            f"{dict(list(metrics['forbidden_word_hits'].items())[:5])}"
        )
    else:
        passes.append("forbidden_words: 0 hits")

    status = "pass" if not failures else "fail"
    return {"status": status, "failures": failures, "passes": passes}


def score_file(path: Path) -> dict[str, Any]:
    role = path.name
    if not path.exists():
        return {
            "path": str(path.relative_to(REPO)) if str(REPO) in str(path) else str(path),
            "role": role,
            "exists": False,
            "status": "missing",
        }
    text = path.read_text(encoding="utf-8", errors="replace")
    metrics = compute_metrics(text, role)
    evaluation = evaluate_thresholds(metrics, role)
    return {
        "path": str(path.relative_to(REPO)) if str(REPO) in str(path) else str(path),
        "role": role,
        "exists": True,
        "metrics": metrics,
        "evaluation": evaluation,
        "status": evaluation["status"],
    }


# ── Spine walker ─────────────────────────────────────────────────────────

def load_spine_map_names() -> list[str]:
    """Return ordered list of map names appearing in the 19 spine sequences."""
    if not SPINE_FILE.exists():
        return []
    spine = json.loads(SPINE_FILE.read_text(encoding="utf-8"))
    names: list[str] = []
    for seq in spine.get("spine", {}).get("sequences", []):
        seq_id = seq.get("name") or seq.get("id")
        if not seq_id:
            continue
        seq_path = SEQUENCES_DIR / f"{seq_id}.json"
        if not seq_path.exists():
            continue
        try:
            data = json.loads(seq_path.read_text(encoding="utf-8"))
        except Exception:
            continue
        seq_data = data.get("sequences", {}).get(seq_id) if isinstance(data.get("sequences"), dict) else data
        maps = seq_data.get("maps", []) if isinstance(seq_data, dict) else []
        for m in maps:
            name = m.get("map") if isinstance(m, dict) else m
            if name and name not in names:
                names.append(name)
    return names


# ── CLI ──────────────────────────────────────────────────────────────────

def format_table_row(entry: dict[str, Any]) -> str:
    if entry["status"] == "missing":
        return f"  {entry['role']:<16s}  MISSING"
    m = entry["metrics"]
    ev = entry["evaluation"]
    marker = "✓" if ev["status"] == "pass" else "✗"
    bits = [
        f"{m['word_count']}w",
        f"{m['code_ratio']:.2f}cr",
        f"{m['code_blocks']}b",
        f"{m['max_paragraph_sentences']}ps",
    ]
    if m["forbidden_word_total"]:
        bits.append(f"!{m['forbidden_word_total']}fw")
    label = f"{entry['role']:<16s}"
    return f"  {marker} {label}  {' '.join(bits):<32s}  {len(ev['failures'])} fail"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--map", help="Map name to score")
    ap.add_argument("--file", help="File role (e.g. tutorial.md)")
    ap.add_argument("--path", help="Absolute/relative path to a text file")
    ap.add_argument("--spine", action="store_true", help="Walk all spine maps")
    ap.add_argument("--format", choices=["json", "table"], default="table")
    ap.add_argument("--only-failing", action="store_true",
                    help="With --spine: show only entries with failures")
    ap.add_argument("--thresholds", action="store_true",
                    help="Print threshold config and exit")
    args = ap.parse_args()

    if args.thresholds:
        print(json.dumps(THRESHOLDS, indent=2))
        return 0

    # Single-path mode
    if args.path:
        p = Path(args.path)
        if not p.is_absolute():
            p = (REPO / p).resolve()
        result = score_file(p)
        if args.format == "json":
            print(json.dumps(result, indent=2, ensure_ascii=False))
        else:
            print(format_table_row(result))
            if result.get("evaluation", {}).get("failures"):
                for f in result["evaluation"]["failures"]:
                    print(f"      ✗ {f}")
        return 0

    # Map mode
    if args.map and not args.spine:
        map_dir = MAPS / args.map
        if args.file:
            result = score_file(map_dir / args.file)
            if args.format == "json":
                print(json.dumps(result, indent=2, ensure_ascii=False))
                return 0
            print(f"{args.map}")
            print(format_table_row(result))
            if result.get("evaluation", {}).get("failures"):
                for f in result["evaluation"]["failures"]:
                    print(f"      ✗ {f}")
            return 0

        # All core files for one map
        results = [score_file(map_dir / f) for f in CORE_FILES]
        if args.format == "json":
            print(json.dumps({"map": args.map, "files": results},
                             indent=2, ensure_ascii=False))
            return 0
        print(f"\n{args.map}")
        for r in results:
            print(format_table_row(r))
        return 0

    # Spine mode
    if args.spine:
        names = load_spine_map_names()
        if not names:
            print("No spine maps found", file=sys.stderr)
            return 1
        files = [args.file] if args.file else CORE_FILES
        spine_results: list[dict[str, Any]] = []
        summary = {"total": 0, "pass": 0, "fail": 0, "missing": 0}

        for map_name in names:
            map_dir = MAPS / map_name
            if not map_dir.exists():
                continue
            map_entry: dict[str, Any] = {"map": map_name, "files": []}
            for f in files:
                r = score_file(map_dir / f)
                map_entry["files"].append(r)
                summary["total"] += 1
                if r["status"] == "missing":
                    summary["missing"] += 1
                elif r["status"] == "pass":
                    summary["pass"] += 1
                else:
                    summary["fail"] += 1
            spine_results.append(map_entry)

        if args.format == "json":
            print(json.dumps(
                {"summary": summary, "maps": spine_results},
                indent=2, ensure_ascii=False))
            return 0

        # Table
        for entry in spine_results:
            has_fail = any(f["status"] == "fail" for f in entry["files"])
            if args.only_failing and not has_fail:
                continue
            print(f"\n{entry['map']}")
            for r in entry["files"]:
                print(format_table_row(r))
        print(f"\n{'-' * 60}")
        print(f"summary: {summary['pass']}/{summary['total']} pass  "
              f"{summary['fail']} fail  {summary['missing']} missing")
        return 0

    ap.print_help()
    return 1


if __name__ == "__main__":
    sys.exit(main())
