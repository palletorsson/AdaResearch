#!/usr/bin/env python3
"""Download YouTube metadata and transcript into local JSON/Markdown files.

Example:
    python tools/fetch_youtube_transcript.py ^
        --url https://www.youtube.com/watch?v=2ghhiPLg-jg ^
        --output-dir ada_encyclopedia/public/konstfack-ai-specialist/data
"""

from __future__ import annotations

import argparse
import json
import re
import unicodedata
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from urllib.parse import parse_qs, urlparse

import requests
from bs4 import BeautifulSoup, Tag
from yt_dlp import YoutubeDL
from youtube_transcript_api import YouTubeTranscriptApi


def extract_video_id(value: str) -> str:
    """Accept a raw ID or common YouTube URL formats."""
    if re.fullmatch(r"[\w-]{11}", value):
        return value

    parsed = urlparse(value)
    if parsed.netloc in {"youtu.be", "www.youtu.be"}:
        candidate = parsed.path.strip("/")
        if re.fullmatch(r"[\w-]{11}", candidate):
            return candidate

    if "youtube.com" in parsed.netloc or "youtube-nocookie.com" in parsed.netloc:
        query_id = parse_qs(parsed.query).get("v", [""])[0]
        if re.fullmatch(r"[\w-]{11}", query_id):
            return query_id

        path_parts = [part for part in parsed.path.split("/") if part]
        if len(path_parts) >= 2 and path_parts[0] in {"embed", "shorts", "live"}:
            candidate = path_parts[1]
            if re.fullmatch(r"[\w-]{11}", candidate):
                return candidate

    raise ValueError(f"Could not determine video id from: {value}")


def format_timestamp(seconds: float) -> str:
    total_seconds = max(int(seconds), 0)
    minutes, secs = divmod(total_seconds, 60)
    hours, minutes = divmod(minutes, 60)
    if hours:
        return f"{hours:02d}:{minutes:02d}:{secs:02d}"
    return f"{minutes:02d}:{secs:02d}"


def clean_text(text: str) -> str:
    collapsed = re.sub(r"\s+", " ", text).strip()
    normalized = unicodedata.normalize("NFKC", collapsed)
    replacements = {
        "â€™": "'",
        "â€œ": '"',
        "â€\x9d": '"',
        "â€”": "-",
        "â€“": "-",
        "â€¢": "-",
        "’": "'",
        "“": '"',
        "”": '"',
        "—": "-",
        "–": "-",
        "•": "-",
    }
    for source, target in replacements.items():
        normalized = normalized.replace(source, target)
    normalized = re.sub(r"^[^\w\"(]+", "", normalized)
    normalized = normalized.replace("[ ", "[").replace(" ]", "]")
    return normalized


def fetch_metadata(url: str) -> dict[str, Any]:
    with YoutubeDL({"quiet": True, "no_warnings": True}) as ydl:
        info = ydl.extract_info(url, download=False)

    return {
        "id": info.get("id"),
        "title": info.get("title"),
        "channel": info.get("channel"),
        "uploader": info.get("uploader"),
        "upload_date": info.get("upload_date"),
        "duration_seconds": info.get("duration"),
        "description": clean_text(info.get("description") or ""),
        "webpage_url": info.get("webpage_url") or url,
    }


def fetch_transcript(video_id: str) -> list[dict[str, Any]]:
    transcript = YouTubeTranscriptApi().fetch(video_id)
    return [
        {
            "start": round(item.start, 3),
            "duration": round(item.duration, 3),
            "timestamp": format_timestamp(item.start),
            "text": clean_text(item.text),
        }
        for item in transcript
    ]


def slugify(text: str) -> str:
    lowered = text.lower().replace("'", "")
    return re.sub(r"[^a-z0-9]+", "-", lowered).strip("-")


def extract_timestamp_from_node(node: Tag) -> str | None:
    for anchor in node.find_all("a"):
        stamp = anchor.get_text(" ", strip=True).strip("[] ")
        if re.fullmatch(r"\d{2}:\d{2}", stamp) or re.fullmatch(r"\d{1,2}:\d{2}", stamp):
            return stamp
    return None


def fetch_bagrounds_summary(title: str) -> dict[str, Any]:
    slug = slugify(title)
    source_url = f"https://bagrounds.org/videos/{slug}"
    response = requests.get(source_url, headers={"User-Agent": "Mozilla/5.0"}, timeout=30)
    response.raise_for_status()
    html = response.content.decode("utf-8", errors="replace")
    soup = BeautifulSoup(html, "html.parser")
    article = soup.find("article")
    if article is None:
        raise RuntimeError("Could not find summary article in bagrounds fallback page")

    def find_heading(label: str) -> Tag:
        heading = article.find(lambda tag: tag.name == "h2" and label in tag.get_text(" ", strip=True))
        if heading is None:
            raise RuntimeError(f"Could not find '{label}' section in bagrounds fallback page")
        return heading

    summary_heading = find_heading("AI Summary")
    summary_list = summary_heading.find_next("ul")
    summary_bullets = []
    if summary_list is not None:
        for li in summary_list.find_all("li", recursive=False):
            summary_bullets.append(
                {
                    "text": clean_text(li.get_text(" ", strip=True)),
                    "timestamp": extract_timestamp_from_node(li),
                }
            )

    evaluation_heading = find_heading("Evaluation")
    evaluation_list = evaluation_heading.find_next("ul")
    evaluation_notes = []
    if evaluation_list is not None:
        for li in evaluation_list.find_all("li", recursive=False):
            evaluation_notes.append(clean_text(li.get_text(" ", strip=True)))

    faq_heading = find_heading("Frequently Asked Questions")
    faqs = []
    node = faq_heading.next_sibling
    while node is not None:
        if isinstance(node, Tag) and node.name == "h2":
            break
        if isinstance(node, Tag) and node.name == "h3":
            question = node.get_text(" ", strip=True)
            answer_tag = node.find_next_sibling("p")
            if answer_tag is not None:
                faqs.append(
                    {
                        "question": clean_text(question),
                        "answer": clean_text(answer_tag.get_text(" ", strip=True)),
                        "timestamp": extract_timestamp_from_node(answer_tag),
                    }
                )
        node = node.next_sibling

    return {
        "source_url": source_url,
        "summary_bullets": summary_bullets,
        "evaluation_notes": evaluation_notes,
        "faq": faqs,
    }


def write_markdown(
    path: Path,
    metadata: dict[str, Any],
    transcript: list[dict[str, Any]],
    fallback_summary: dict[str, Any] | None,
) -> None:
    lines = [
        f"# {metadata['title']}",
        "",
        f"- Source: {metadata['webpage_url']}",
        f"- Channel: {metadata.get('channel') or metadata.get('uploader') or 'Unknown'}",
        f"- Upload date: {metadata.get('upload_date') or 'Unknown'}",
        f"- Duration (seconds): {metadata.get('duration_seconds') or 'Unknown'}",
        "",
    ]

    if transcript:
        lines.extend(["## Transcript", ""])
        for item in transcript:
            lines.append(f"[{item['timestamp']}] {item['text']}")
    elif fallback_summary:
        lines.extend(
            [
                "## Fallback Source Notes",
                "",
                "YouTube transcript endpoints were unavailable from this environment, so this file stores a structured summary fetched from bagrounds.org for the same video.",
                "",
                f"- Fallback source: {fallback_summary['source_url']}",
                "",
                "### AI Summary",
                "",
            ]
        )
        for item in fallback_summary.get("summary_bullets", []):
            stamp = f" ({item['timestamp']})" if item.get("timestamp") else ""
            lines.append(f"- {item['text']}{stamp}")

        if fallback_summary.get("evaluation_notes"):
            lines.extend(["", "### Evaluation", ""])
            for item in fallback_summary["evaluation_notes"]:
                lines.append(f"- {item}")

        if fallback_summary.get("faq"):
            lines.extend(["", "### FAQ", ""])
            for item in fallback_summary["faq"]:
                stamp = f" ({item['timestamp']})" if item.get("timestamp") else ""
                lines.append(f"- {item['question']}")
                lines.append(f"  {item['answer']}{stamp}")

    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--url", required=True, help="YouTube video URL or raw video id")
    parser.add_argument(
        "--output-dir",
        required=True,
        help="Directory where metadata.json, transcript.json, and transcript.md will be written",
    )
    args = parser.parse_args()

    video_id = extract_video_id(args.url)
    canonical_url = f"https://www.youtube.com/watch?v={video_id}"
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    metadata = fetch_metadata(canonical_url)
    transcript: list[dict[str, Any]] = []
    transcript_error: str | None = None
    fallback_summary: dict[str, Any] | None = None
    download_method = "youtube_transcript_api"

    try:
        transcript = fetch_transcript(video_id)
    except Exception as exc:  # noqa: BLE001 - want resilient asset generation
        transcript_error = str(exc)
        fallback_summary = fetch_bagrounds_summary(metadata["title"])
        download_method = "bagrounds_summary_fallback"

    payload = {
        "fetched_at_utc": datetime.now(timezone.utc).isoformat(),
        "download_method": download_method,
        "transcript_error": transcript_error,
        "video": metadata,
        "segments": transcript,
        "fallback_summary": fallback_summary,
    }

    (output_dir / "video_metadata.json").write_text(
        json.dumps(metadata, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    (output_dir / "transcript.json").write_text(
        json.dumps(payload, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    write_markdown(output_dir / "transcript.md", metadata, transcript, fallback_summary)

    print(f"Wrote transcript assets to {output_dir}")
    print(f"Title: {metadata['title']}")
    print(f"Method: {download_method}")
    print(f"Segments: {len(transcript)}")


if __name__ == "__main__":
    main()
