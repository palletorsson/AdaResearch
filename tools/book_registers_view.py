"""Render the paragraph register snapshot as a self-contained review page.

No model calls or source edits occur here. Probabilities remain model observations;
optional browser-local corrections are exported separately from those observations.
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT = ROOT / "doc/research/possible-bodies/book-registers.html"


def render_report(data: dict, output: Path, editorial_examples: dict | None = None) -> None:
    """Write an offline HTML viewer, safely embedding the supplied JSON snapshot."""
    payload = json.dumps(data, ensure_ascii=False, allow_nan=False, separators=(",", ":"))
    # The HTML parser recognizes closing script tags even in application/json.
    payload = (payload.replace("&", "\\u0026").replace("<", "\\u003c")
               .replace(">", "\\u003e").replace("\u2028", "\\u2028")
               .replace("\u2029", "\\u2029"))
    editorial_payload = json.dumps(editorial_examples or {}, ensure_ascii=False, allow_nan=False)
    editorial_payload = (editorial_payload.replace("&", "\\u0026").replace("<", "\\u003c")
                         .replace(">", "\\u003e").replace("\u2028", "\\u2028")
                         .replace("\u2029", "\\u2029"))
    payloads = {"__BOOK_REGISTER_DATA__": payload, "__BOOK_EDITORIAL_DATA__": editorial_payload}
    page = re.sub(r"__BOOK_(?:REGISTER|EDITORIAL)_DATA__", lambda m: payloads[m.group()], _PAGE)
    output = Path(output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(page, encoding="utf-8")


_PAGE = r'''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="color-scheme" content="dark">
<title>Book registers · AdaResearch</title>
<style>
:root{--bg:#171815;--panel:#20211d;--raised:#292a24;--ink:#eee8d9;--muted:#b0b1a1;--dim:#838878;--line:#3a3d32;--accent:#dfb57d;--uncertain:#e5bc7a;--radius:12px;font-family:ui-sans-serif,system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;color:var(--ink);background:var(--bg)}
*{box-sizing:border-box}body{margin:0}button,input,select{font:inherit}button,select,input{color:var(--ink);background:var(--raised);border:1px solid var(--line);border-radius:7px}button{cursor:pointer}button:hover{border-color:var(--accent);background:#34372d}button:disabled{opacity:.45;cursor:default}a{color:var(--accent);text-underline-offset:4px}button:focus-visible,input:focus-visible,select:focus-visible,a:focus-visible,summary:focus-visible{outline:2px solid var(--accent);outline-offset:4px}p{margin:.55rem 0;line-height:1.65}h1,h2,h3{font-weight:500}h1{font-family:Georgia,"Times New Roman",serif;font-size:clamp(2.5rem,5vw,4.5rem);letter-spacing:-.05em;line-height:1.06;margin:.7rem 0 1rem}h2{font-family:Georgia,"Times New Roman",serif;font-size:2rem;margin:.35rem 0 1rem}h3{margin:.4rem 0 .7rem;font-size:1.15rem}.wrap{max-width:1640px;padding:42px 40px 70px;margin:auto}.eyebrow{font-size:.72rem;text-transform:uppercase;letter-spacing:.16em;color:var(--accent)}.masthead{display:flex;justify-content:space-between;gap:24px;align-items:start;border-bottom:1px solid var(--line);padding-bottom:27px}.intro{max-width:790px}.intro p{color:var(--muted);max-width:750px}.stamp{text-align:right;min-width:200px;font-size:.76rem;color:var(--muted);line-height:1.8;padding-top:8px}.stamp a{display:inline-block;margin-bottom:16px}.metrics{display:flex;flex-wrap:wrap;gap:12px 34px;padding:23px 0 29px}.metric{font-size:.78rem;color:var(--muted)}.metric strong{display:block;font-family:Georgia,serif;font-size:1.8rem;font-weight:400;color:var(--ink);line-height:1.3}.section-label{display:flex;justify-content:space-between;gap:20px;align-items:baseline;margin-bottom:12px}.section-label h2{font-family:inherit;font-size:.78rem;text-transform:uppercase;letter-spacing:.13em;margin:0}.small{font-size:.76rem;color:var(--muted);line-height:1.6}.legend{display:grid;grid-template-columns:repeat(auto-fit,minmax(165px,1fr));gap:9px}.legend-card{border:1px solid var(--line);border-top:3px solid var(--tag);border-radius:5px;padding:12px 13px;background:var(--panel)}.legend-name{display:block;color:var(--tag);font-size:.81rem;font-weight:650;margin-bottom:6px}.legend-card p{font-size:.74rem;line-height:1.5;color:var(--muted);margin:0}.pattern-note{margin:14px 0 18px;max-width:1050px}.sequence-overview{display:grid;grid-template-columns:repeat(auto-fit,minmax(195px,1fr));gap:8px;margin:0 0 28px}.sequence-card{text-align:left;padding:11px 12px;background:var(--panel);min-width:0}.sequence-card[aria-pressed="true"]{border-color:var(--accent)}.sequence-label{display:flex;justify-content:space-between;gap:10px;font-size:.76rem;margin-bottom:9px}.sequence-count{white-space:nowrap;color:var(--muted);font-size:.7rem}.ribbon{display:flex;gap:2px;height:11px;overflow:hidden;min-width:0}.ribbon .tile{flex:1 1 0;min-width:1px;border-radius:1px;background:#55584b}.sequence-card .ribbon,.hall-row .ribbon{gap:0}.sequence-card .tile,.hall-row .tile{min-width:0;border-radius:0}.tile.uncertain{outline:1px dotted var(--uncertain);outline-offset:-1px}.tile.pending{background:repeating-linear-gradient(135deg,#515446,#515446 2px,#30332a 2px,#30332a 4px)}.filters{display:grid;grid-template-columns:130px 1fr 1.3fr 1fr 1fr 1.3fr;gap:12px;padding:20px;background:var(--panel);border:1px solid var(--line);border-radius:var(--radius);margin-bottom:24px}.field{display:flex;flex-direction:column;gap:7px;min-width:0}.field label{font-size:.67rem;text-transform:uppercase;letter-spacing:.11em;color:var(--muted)}select,input{width:100%;padding:10px 9px;font-size:.78rem;min-width:0}input::placeholder{color:var(--dim)}.workspace{display:grid;grid-template-columns:285px minmax(0,1fr);gap:34px;align-items:start}.hall-sidebar{position:sticky;top:22px}.hall-list{max-height:calc(100vh - 180px);overflow:auto;scrollbar-width:thin;scrollbar-color:var(--line) transparent;padding-right:5px}.hall-row{width:100%;text-align:left;margin:0 0 7px;padding:12px;background:var(--panel);border-color:transparent}.hall-row[aria-current="true"]{border-color:var(--accent);background:#2d3026}.hall-row-title{display:block;font-size:.79rem;overflow-wrap:anywhere;margin-bottom:5px}.hall-row-meta{display:block;font-size:.66rem;color:var(--muted);margin-bottom:9px}.reader{min-width:0}.reader-head{padding-bottom:22px;border-bottom:1px solid var(--line);margin-bottom:23px}.reader-title{overflow-wrap:anywhere;font-size:clamp(1.65rem,3vw,2.6rem);letter-spacing:-.03em;margin:.6rem 0}.reader-meta{display:flex;justify-content:space-between;gap:20px;align-items:center;flex-wrap:wrap}.reader-nav{display:flex;gap:7px}.reader-nav button,.export{font-size:.73rem;padding:8px 11px}.reader-path{font: .69rem/1.8 ui-monospace,SFMono-Regular,Consolas,monospace;color:var(--dim);overflow-wrap:anywhere;margin-top:12px}.reader-ribbon{height:20px;margin:20px 0 10px;gap:3px;overflow-x:auto}.reader-ribbon button.tile{padding:0;border:0;min-width:4px}.reader-ribbon button.tile:hover{filter:brightness(1.35)}.block{display:grid;grid-template-columns:minmax(0,1fr) 205px;gap:28px;padding:8px 0 28px;margin-bottom:17px;border-bottom:1px solid #303329;scroll-margin-top:22px}.block:last-child{border-bottom:0}.block-top{display:flex;align-items:center;flex-wrap:wrap;gap:9px;margin-bottom:9px;font-size:.65rem;color:var(--dim);font-variant-numeric:tabular-nums}.block-id{font-family:ui-monospace,SFMono-Regular,Consolas,monospace}.badge{border:1px solid var(--line);padding:2px 6px;border-radius:4px;font-size:.62rem;color:var(--muted)}.badge.uncertain{color:var(--uncertain);border-color:#705d3d}.badge.corrected{color:#b9d1ba;border-color:#537358}.prose{font-family:Georgia,"Times New Roman",serif;font-size:1.08rem;line-height:1.8;white-space:pre-wrap;margin:0;color:#e5decd;overflow-wrap:anywhere}.footnote .prose{font-size:.94rem;color:var(--muted)}.block.structural{padding-bottom:17px;margin-bottom:7px;grid-template-columns:1fr;border-bottom:0}.structural h3{font-family:Georgia,serif;font-size:1.45rem;font-weight:400;white-space:pre-wrap;overflow-wrap:anywhere}.structural pre{padding:18px;background:#11130f;border:1px solid var(--line);border-radius:8px;overflow:auto;font-size:.76rem;line-height:1.6;white-space:pre}.scores{padding-top:3px}.score{display:grid;grid-template-columns:1fr 30px;gap:8px;font-size:.68rem;margin-bottom:9px;align-items:center}.score-name{color:var(--tag)}.score-value{text-align:right;color:var(--muted);font-variant-numeric:tabular-nums}.score-track{height:3px;background:#35392d;border-radius:3px;overflow:hidden;margin-top:4px}.score-fill{height:100%;background:var(--tag)}.score.faint{opacity:.5}.score-review{color:#c4d9c2;font-size:.6rem;display:block;margin-top:2px}.review{border-top:1px solid var(--line);padding-top:10px;margin-top:14px}.review summary{font-size:.66rem;color:var(--muted);cursor:pointer}.review form{display:flex;flex-direction:column;gap:8px;padding-top:9px}.review-label{display:flex;align-items:center;justify-content:space-between;gap:8px;font-size:.64rem}.review-label select{width:91px;font-size:.62rem;padding:5px}.review-actions{display:flex;gap:6px;flex-wrap:wrap}.review-actions button{font-size:.63rem;padding:6px 8px}.empty{border:1px dashed var(--line);border-radius:var(--radius);padding:30px;color:var(--muted);line-height:1.7}.review-footer{display:flex;justify-content:space-between;gap:25px;border-top:1px solid var(--line);margin-top:34px;padding-top:20px;align-items:center}.review-footer p{max-width:800px;margin:0}.filter-status{margin:0 0 20px;font-size:.75rem;color:var(--muted)}.status{min-height:1.4em;color:var(--accent);font-size:.72rem;padding-top:8px}.key-examples{display:inline-flex;gap:13px;flex-wrap:wrap;margin-top:7px}.key-examples span{display:inline-flex;gap:5px;align-items:center}.swatch{width:14px;height:10px;display:inline-block;border-radius:1px}.swatch.uncertain{background:#4d4938;outline:1px dotted var(--uncertain)}.swatch.pending{background:repeating-linear-gradient(135deg,#666956,#666956 2px,#30332a 2px,#30332a 4px)}[hidden]{display:none!important}@media(min-width:1400px){.block{grid-template-columns:minmax(0,1fr) 230px;gap:40px}.prose{font-size:1.12rem}}@media(max-width:1100px){.wrap{padding:30px 24px 50px}.filters{grid-template-columns:repeat(3,1fr)}.workspace{grid-template-columns:225px minmax(0,1fr);gap:24px}.block{grid-template-columns:1fr;gap:16px}.scores{display:grid;grid-template-columns:repeat(auto-fit,minmax(110px,1fr));gap:6px 15px}.review{grid-column:1/-1}.review form{max-width:320px}}@media(max-width:720px){.wrap{padding:24px 16px 40px}.masthead{display:block}.stamp{text-align:left;padding:10px 0 0}.stamp a{margin-bottom:3px}.metrics{gap:18px 25px}.metric strong{font-size:1.5rem}.legend{grid-template-columns:repeat(2,1fr)}.sequence-overview{grid-template-columns:repeat(2,1fr)}.filters{grid-template-columns:repeat(2,1fr);padding:15px}.workspace{grid-template-columns:1fr}.hall-sidebar{position:static}.hall-list{display:flex;gap:8px;max-height:none;overflow-x:auto;padding-bottom:7px}.hall-row{min-width:210px;width:210px;flex-shrink:0}.reader-title{font-size:2rem}.review-footer{display:block}.export{margin-top:14px}.section-label{align-items:start}.prose{font-size:1.02rem}}@media(prefers-reduced-motion:no-preference){button{transition:background .15s,border-color .15s}.block:target{animation:flash 1.5s ease-out}@keyframes flash{from{background:#3a392b}to{background:transparent}}}

/* Text-first view. Analysis retains the corpus and probability tools. */
.wrap{max-width:1540px;padding-top:24px}.masthead{padding-bottom:13px;align-items:center}.intro h1{font-size:36px;letter-spacing:-.035em;margin:.4rem 0}.intro p{font-size:.79rem;margin:.3rem 0}.intro #estimate-note{display:none}.stamp{padding-top:0;font-size:.66rem}.stamp a{margin-bottom:3px}.overview{margin:11px 0 14px;padding-bottom:11px;border-bottom:1px solid var(--line)}.overview>summary{font-size:.73rem;line-height:1.6;color:var(--muted);cursor:pointer}.mode-toolbar{display:flex;justify-content:space-between;align-items:center;gap:10px;flex-wrap:wrap;margin:12px 0}.layer-control{display:flex;gap:10px;align-items:center;font-size:.71rem;color:var(--muted)}.layer-control select{width:200px;padding:8px}.mode-switch{display:flex;gap:3px;border:1px solid var(--line);border-radius:8px;padding:3px}.mode-switch button{padding:6px 12px;font-size:.73rem;border-color:transparent;background:transparent}.mode-switch button[aria-pressed="true"]{background:var(--raised);color:var(--accent);border-color:var(--line)}.layer-banner{padding:9px 13px;border-left:3px solid var(--accent);background:#24261f;margin-bottom:12px}.layer-banner strong{font-size:.76rem;font-weight:550}.layer-banner p{margin:3px 0 0;font-size:.69rem;line-height:1.5;color:var(--muted)}.filters{padding:12px 14px;gap:10px;margin-bottom:18px}.filters select,.filters input{padding:8px;font-size:.74rem}.field label{font-size:.61rem}.reader-head{padding-bottom:11px;margin-bottom:12px}.reader-title{font-size:1.9rem;margin:.35rem 0 .5rem}.reader-meta a{font-size:.73rem}.reader-ribbon{height:11px;margin:12px 0 7px}.reader-head>.small{font-size:.65rem}.filter-status{font-size:.65rem;margin-bottom:13px}.block{grid-template-columns:minmax(0,70ch) 180px;gap:26px;padding:0 0 15px;margin:0 0 13px;border-bottom:0}.block-content{min-width:0}.block-top{font-size:.59rem;margin:0 0 0 15px}.block-id{display:none}.prose-frame{position:relative;padding:8px 15px;border-radius:5px;min-width:0}.voice-bar{position:absolute;left:0;top:4px;bottom:4px;width:4px;display:flex;flex-direction:column;gap:2px}.voice-bar span{flex:1;border-radius:2px}.prose{max-width:70ch;font-size:1.03rem;line-height:1.85}.annotation{padding-top:19px}.tag-chips{display:flex;flex-wrap:wrap;gap:5px;margin-bottom:7px}.tag-chip{font-size:.63rem;line-height:1.4;color:var(--tag);border:1px solid color-mix(in srgb,var(--tag) 35%,transparent);background:color-mix(in srgb,var(--tag) 6%,transparent);border-radius:4px;padding:3px 6px}.annotation .badge{display:inline-block;font-size:.57rem;color:var(--accent);border-color:#5f543e;margin-bottom:7px}.annotation-note{font-size:.68rem;line-height:1.6;color:var(--muted);margin:0}.annotation-empty{font-size:.64rem;color:var(--dim)}.model-details>summary{font-size:.65rem;color:var(--muted);cursor:pointer}.model-details .scores{padding-top:12px}.prose code{font-family:ui-monospace,SFMono-Regular,Consolas,monospace;font-size:.79em;background:#303329;border:1px solid #424637;border-radius:4px;padding:1px 5px;white-space:pre-wrap}.prose strong{font-weight:650;color:#f7eedc}.prose a{color:#d9bd8a}.prose sup{font: .64em ui-sans-serif,system-ui,sans-serif;line-height:0;margin-left:2px}.footnote-mark{font-size:.73rem;color:var(--accent);margin-right:7px}.block.structural{padding:5px 0 12px;margin-bottom:8px}.structural h3{font-size:1.42rem;margin:8px 15px 5px}.structural pre{margin:6px 15px;max-width:70ch}.source-markdown{font-size:.6rem;color:var(--dim);margin:3px 15px}.source-markdown summary{cursor:pointer}.source-markdown pre{font-size:.72rem;line-height:1.6;white-space:pre-wrap}.parse-note{font-size:.7rem;color:var(--accent);margin:6px 15px}.footnote .prose{font-size:.87rem}body[data-mode="reading"] .workspace{display:block}body[data-mode="reading"] .hall-sidebar{display:none}body[data-mode="reading"] .reader{max-width:1000px;margin:0 auto}body[data-mode="reading"] .reader-path,body[data-mode="reading"] .structural .block-top,body[data-mode="reading"] .source-markdown{display:none}body[data-mode="analysis"] .block-id{display:inline}body[data-layer="text"] .block{grid-template-columns:minmax(0,70ch)}body[data-layer="text"] .reader{max-width:800px}body[data-layer="text"] .prose-frame{background:none!important}
@media(min-width:1400px){.block{grid-template-columns:minmax(0,70ch) 180px;gap:28px}.prose{font-size:1.06rem}}@media(max-width:1100px){body[data-mode="analysis"] .block{grid-template-columns:1fr}.scores{display:block}.filters{grid-template-columns:repeat(3,1fr)}}@media(max-width:760px){.wrap{padding:18px 14px 40px}.intro h1{font-size:30px}.masthead{align-items:start}.intro p{font-size:.73rem}.stamp{font-size:.64rem}.stamp #snapshot-date,.stamp #snapshot-usage,.stamp #snapshot-model{display:none}.layer-control{font-size:.65rem;gap:6px}.layer-control select{width:176px;font-size:.7rem}.mode-switch button{font-size:.68rem;padding:6px 8px}.filters{grid-template-columns:repeat(2,1fr)}.block,.block.structural{display:flex;flex-direction:column;gap:0}.annotation{order:-1;padding:6px 15px}.tag-chips{margin-bottom:4px}.annotation .badge{margin:0 6px 5px 0}.annotation-note{font-size:.65rem}.prose{font-size:.98rem;line-height:1.8}.block-content{width:100%}.structural pre{max-width:calc(100vw - 60px)}.reader-title{font-size:1.75rem}.reader-nav button{font-size:.66rem;padding:6px 8px}.model-details .scores{max-width:300px}}

</style>
</head>
<body data-mode="reading">
<div class="wrap">
  <header class="masthead">
    <div class="intro"><div class="eyebrow">AdaResearch / Possible bodies / Reading notes</div>
      <h1>The book, in registers.</h1>
      <p>Read the words. Follow the colored margins as their voices meet and change.</p>
      <p class="small" id="estimate-note">Jev’s estimates describe the probability that each register is present. Labels can overlap; they do not add up to 100%. They are neither quality scores nor a prescription for balancing the prose.</p>
    </div>
    <div class="stamp"><div><a href="/research/possible-bodies/primitives-purpose.html">Purpose &amp; sources: Primitives ↗</a></div><a href="/book">Open the book ↗</a><div id="snapshot-date"></div><div id="snapshot-model"></div><div id="snapshot-usage"></div></div>
  </header>
  <details class="overview" id="overview"><summary>Corpus, register key &amp; sequence overview <span id="coverage-summary"></span></summary>
  <section class="metrics" id="metrics" aria-label="Snapshot coverage"></section>
  <section aria-labelledby="legend-title">
    <div class="section-label"><h2 id="legend-title">A vocabulary of registers</h2><span class="small">More than one can be present.</span></div>
    <div class="legend" id="legend"></div>
    <p class="small pattern-note" id="pattern-note">The strips follow prose blocks in reading order. Each tile shows registers at 65% or above; split colors preserve overlap. A dotted edge marks a tagged block with any estimate from 35–65%, or no register at 65% or above. Structural headings and code have no model labels.<br><span class="key-examples"><span><i class="swatch uncertain"></i>uncertain</span><span><i class="swatch pending"></i>pending</span></span></p>
  </section>
  <section aria-labelledby="sequence-title"><div class="section-label"><h2 id="sequence-title">Through the sequences</h2><span class="small">Select a sequence to read its halls.</span></div><div class="sequence-overview" id="sequence-overview"></div></section>
  </details>
  <div class="mode-toolbar"><div class="layer-control"><label for="layer-filter">Annotation layer</label><select id="layer-filter"></select></div><div class="mode-switch" role="group" aria-label="Reading or analysis"><button type="button" id="reading-view" aria-pressed="true">Reading</button><button type="button" id="analysis-view" aria-pressed="false">Analysis</button></div></div>
  <div class="layer-banner" id="layer-banner" role="status"></div>
  <form class="filters" id="filters" role="search" aria-label="Filter book registers">
    <div class="field"><label for="scope-filter">Corpus</label><select id="scope-filter"><option value="all">All sources</option><option value="spine">Spine only</option><option value="other">Outside the spine</option></select></div>
    <div class="field"><label for="sequence-filter">Sequence</label><select id="sequence-filter"></select></div>
    <div class="field"><label for="hall-filter">Hall</label><select id="hall-filter"></select></div>
    <div class="field"><label for="tag-filter" id="tag-filter-label">Register</label><select id="tag-filter"></select></div>
    <div class="field"><label for="view-filter">Review view</label><select id="view-filter"><option value="all">All blocks</option><option value="uncertain">Uncertain estimates</option><option value="tagged">Tagged prose</option><option value="pending">Pending prose</option><option value="corrected">Locally reviewed</option></select></div>
    <div class="field"><label for="text-filter">Find in the text</label><input id="text-filter" type="search" placeholder="Word or phrase…" autocomplete="off"></div>
  </form>
  <div class="workspace">
    <aside class="hall-sidebar" aria-label="Halls in reading order"><div class="section-label"><h2>Reading order</h2><span class="small" id="hall-count"></span></div><nav class="hall-list" id="hall-list" aria-label="Choose a hall"></nav></aside>
    <main class="reader" id="reader"><div id="reader-head"></div><div class="filter-status" id="filter-status" role="status"></div><div id="blocks"></div></main>
  </div>
  <footer class="review-footer" id="review-footer"><div><p class="small">Local review keeps the original estimates visible. Mark a register present or absent, then export the corrections for later use. Reviews are stored only in this browser, tied to the source and block fingerprints. They do not change the book or this snapshot.</p><div class="status" id="local-status" role="status"></div></div><button type="button" class="export" id="export-reviews">Export local review</button></footer>
  <noscript><p>This review needs JavaScript to display the embedded snapshot. It makes no network requests.</p></noscript>
</div>
<script type="application/json" id="book-register-data">__BOOK_REGISTER_DATA__</script>
<script type="application/json" id="book-editorial-data">__BOOK_EDITORIAL_DATA__</script>
<script>
'use strict';
(() => {
const data = JSON.parse(document.getElementById('book-register-data').textContent);
const editorial = JSON.parse(document.getElementById('book-editorial-data').textContent);
const $ = id => document.getElementById(id);
const el = (tag, cls, text) => { const node=document.createElement(tag); if(cls) node.className=cls; if(text!==undefined) node.textContent=String(text); return node; };
const count = n => Number(n || 0).toLocaleString();
const pretty = name => String(name || 'Outside the spine').replace(/_/g, ' ');
const validColor = color => /^#[0-9a-f]{3}([0-9a-f]{3})?$/i.test(String(color)) ? color : '#c5b791';
const taxonomy = (data.taxonomy || []).map(tag => ({...tag, color:validColor(tag.color)}));
const numberOrder = value => Number.isFinite(Number(value)) && value !== null ? Number(value) : Number.MAX_SAFE_INTEGER;
const sources = (data.sources || []).map((s,i) => ({...s, blocks:s.blocks || [], _index:i})).sort((a,b) =>
  Number(Boolean(b.in_spine))-Number(Boolean(a.in_spine)) || numberOrder(a.sequence_order)-numberOrder(b.sequence_order) || numberOrder(a.map_order)-numberOrder(b.map_order) || a._index-b._index);
const isProse = b => b.kind === 'paragraph' || b.kind === 'footnote';
const isTagged = b => isProse(b) && b.status === 'tagged' && b.registers && typeof b.registers === 'object';
const score = (b,id) => typeof b.registers?.[id] === 'number' && Number.isFinite(b.registers[id]) ? Math.max(0,Math.min(1,b.registers[id])) : null;
const selected = b => taxonomy.filter(t => (score(b,t.id) ?? -1) >= .65);
const uncertain = b => Boolean(isTagged(b) && (taxonomy.some(t => {const p=score(b,t.id); return p!==null && p>=.35 && p<=.65;}) || !selected(b).length));
const blockSources=new Map();for(const source of sources)for(const block of source.blocks)blockSources.set(block,source);
const exampleKey=(map,sourceSHA,blockId,blockSHA)=>JSON.stringify([map,sourceSHA,blockId,blockSHA]);
const editorialIndex=new Map();
if(editorial.kind==='assistant-editorial-examples')for(const e of editorial.examples || [])if(e.map&&e.source_sha256&&e.block_id&&e.block_sha256&&Array.isArray(e.labels))editorialIndex.set(exampleKey(e.map,e.source_sha256,e.block_id,e.block_sha256),e);
const exampleFor=b=>{const s=blockSources.get(b);return s&&isProse(b)?editorialIndex.get(exampleKey(s.map,s.sha256,b.id,b.sha256)):null;};
const exampleTotal=sources.reduce((n,s)=>n+s.blocks.filter(b=>exampleFor(b)).length,0);
const routeParams=new URLSearchParams(typeof location!=='undefined'?location.search:'');
let layer=exampleTotal&&!sources.some(s=>s.blocks.some(isTagged))?'editorial':'jev';
if(['jev','text','editorial'].includes(routeParams.get('layer'))&&(routeParams.get('layer')!=='editorial'||exampleTotal))layer=routeParams.get('layer');
let displayMode=routeParams.get('view')==='analysis'?'analysis':'reading';
const hasAnnotation=b=>layer==='editorial'?Boolean(exampleFor(b)):layer==='jev'&&isTagged(b);
const activeTags=b=>layer==='editorial'?taxonomy.filter(t=>(exampleFor(b)?.labels || []).includes(t.id)):layer==='jev'&&isTagged(b)?selected(b):[];
const layerUncertain=b=>layer==='jev'&&uncertain(b);
const reviewKey = (s,b) => JSON.stringify([s.path,s.sha256,b.sha256]);
const storageKey = 'ada.book-registers.reviews.v1';
let reviews = {}, storageAvailable = true;
try {const parsed=JSON.parse(localStorage.getItem(storageKey) || '{}'); if(parsed && typeof parsed==='object' && !Array.isArray(parsed)) reviews=parsed;} catch (_) {storageAvailable=false;}
function review(s,b) {const value=reviews[reviewKey(s,b)]; return value && typeof value==='object' && value.registers && typeof value.registers==='object' ? value : null;}
function activeReviews() {return sources.flatMap(s=>s.blocks.filter(b=>isTagged(b) && review(s,b)).map(b=>({source:s.path,source_sha256:s.sha256,map:s.map,block_id:b.id,block_sha256:b.sha256,registers:Object.fromEntries(taxonomy.filter(t=>typeof review(s,b).registers[t.id]==='boolean').map(t=>[t.id,review(s,b).registers[t.id]])),updated_at:review(s,b).updated_at}))).filter(r=>Object.keys(r.registers).length);}
function updateReviewStatus(message='') {const n=activeReviews().length; $('local-status').textContent=(message ? message+' ' : '')+count(n)+' prose blocks reviewed in this snapshot.'+(!storageAvailable ? ' Browser storage is unavailable; export to keep this session’s review.' : ''); $('export-reviews').disabled=!n;}
function persistReviews() {try {localStorage.setItem(storageKey,JSON.stringify(reviews));storageAvailable=true;}catch(_){storageAvailable=false;} updateReviewStatus();}
function addOption(select,value,label){const opt=el('option','',label);opt.value=String(value);select.append(opt);}
function colors(tags){return 'linear-gradient(to bottom,'+tags.flatMap((t,i)=>[t.color+' '+(100*i/tags.length)+'%',t.color+' '+(100*(i+1)/tags.length)+'%']).join(',')+')';}
function bookURL(s){return '/book?map='+encodeURIComponent(s.map)+'&section=final';}
function textFor(b){return String(b.text ?? b.source_text ?? '');}
const allProse=sources.flatMap(s=>s.blocks.filter(isProse));
const tagged=allProse.filter(isTagged).length, spine=sources.filter(s=>s.in_spine).length;
for(const [n,label] of [[sources.length,'source files'],[spine,'in the spine'],[sources.length-spine,'outside the spine'],[allProse.length,'prose blocks'],[tagged,'Jev tagged'],[allProse.length-tagged,'awaiting Jev'],[allProse.filter(uncertain).length,'uncertain Jev estimates']]){const metric=el('div','metric');metric.append(el('strong','',count(n)),el('span','',label));$('metrics').append(metric);}
$('snapshot-date').textContent='Snapshot · '+String(data.generated_at || 'undated');
$('snapshot-model').textContent=(tagged?'Jev · ':'Planned model · ')+String(data.model || 'not recorded');
if(!tagged)$('estimate-note').textContent='Source-only preview: no model estimates have been collected. The legend describes the registers that will be considered. Future labels can overlap; they will describe presence, not quality or a prescribed balance.';
const usage=data.summary || {};
const parseNote = warning => typeof warning==='string' ? warning : JSON.stringify(warning);
$('snapshot-usage').textContent=count(usage.api_requests)+' requests · '+count(usage.input_tokens)+' in / '+count(usage.output_tokens)+' out'+(typeof usage.estimated_cost_usd==='number'?' · est. $'+usage.estimated_cost_usd.toFixed(4):'');
for(const t of taxonomy){const card=el('div','legend-card');card.style.setProperty('--tag',t.color);card.append(el('span','legend-name',t.label),el('p','',t.definition));$('legend').append(card);}
addOption($('tag-filter'),'','Any register');for(const t of taxonomy) addOption($('tag-filter'),t.id,t.label);
const groups = Array.from(new Set(sources.map(s=>String(s.sequence || '')))).map(key=>({key,sources:sources.filter(s=>String(s.sequence || '')===key)}));
addOption($('sequence-filter'),'__all__','All sequences');
for(const group of groups){addOption($('sequence-filter'),group.key,pretty(group.key));const button=el('button','sequence-card');button.type='button';button.dataset.sequence=group.key;button.setAttribute('aria-pressed','false');const label=el('span','sequence-label');label.append(el('span','',pretty(group.key)),el('span','sequence-count',count(group.sources.length)+' halls'));button.append(label,ribbon(group.sources.flatMap(s=>s.blocks)));button.addEventListener('click',()=>{$('sequence-filter').value=$('sequence-filter').value===group.key?'__all__':group.key;refresh(true);});$('sequence-overview').append(button);}
const preferredMap=routeParams.get('map') || (exampleTotal&&!tagged?editorial.preferred_map || 'Point_Trace':null);
let current = sources.find(s=>s.map===preferredMap)?._index ?? sources.find(s=>s.blocks.some(hasAnnotation))?._index ?? sources[0]?._index ?? null;
let matchingSources=[];
function hasBlockFilter(){return Boolean($('tag-filter').value || $('text-filter').value.trim() || $('view-filter').value!=='all');}
function sourceMatches(s){const scope=$('scope-filter').value,seq=$('sequence-filter').value;return !(scope==='spine'&&!s.in_spine || scope==='other'&&s.in_spine || seq!=='__all__'&&String(s.sequence || '')!==seq) && (!hasBlockFilter() || s.blocks.some(b=>blockMatches(s,b)));}
function chooseSource(index){current=index;$('hall-filter').value=String(index);renderHallList();renderHall();}
function refresh(preferTagged=false){matchingSources=sources.filter(sourceMatches);if(!matchingSources.some(s=>s._index===current))current=(preferTagged?matchingSources.find(s=>s.blocks.some(hasAnnotation)):null)?._index ?? matchingSources[0]?._index ?? null;$('hall-filter').replaceChildren();for(const s of matchingSources)addOption($('hall-filter'),s._index,pretty(s.map));if(current!==null)$('hall-filter').value=String(current);$('hall-filter').disabled=!matchingSources.length;for(const node of $('sequence-overview').children)node.setAttribute('aria-pressed',String(node.dataset.sequence===$('sequence-filter').value));renderHallList();renderHall();}
function renderHallList(){const list=$('hall-list');list.replaceChildren();$('hall-count').textContent=count(matchingSources.length)+' halls';for(const s of matchingSources){const button=el('button','hall-row');button.type='button';button.setAttribute('aria-current',String(s._index===current));button.append(el('span','hall-row-title',pretty(s.map)),el('span','hall-row-meta',pretty(s.sequence)+' · '+(s.in_spine?'spine':'outside spine')+' · '+count(s.blocks.filter(isProse).length)+' prose blocks'),ribbon(s.blocks));button.addEventListener('click',()=>chooseSource(s._index));list.append(button);}if(!matchingSources.length)list.append(el('p','small','No halls match these filters.'));}
function renderScores(s,b){const aside=el('aside','scores');aside.setAttribute('aria-label','Estimated probability of each register');for(const t of taxonomy){const p=score(b,t.id),line=el('div','score'+(p!==null&&p<.35?' faint':''));line.style.setProperty('--tag',t.color);const left=el('div');left.append(el('span','score-name',t.label));const track=el('div','score-track'),fill=el('div','score-fill');fill.style.width=(100*(p ?? 0))+'%';track.append(fill);left.append(track);const verdict=review(s,b)?.registers[t.id];if(typeof verdict==='boolean')left.append(el('span','score-review','Local: '+(verdict?'present':'absent')));line.append(left,el('span','score-value',p===null?'—':Math.round(100*p)+'%'));aside.append(line);}aside.append(reviewEditor(s,b));return aside;}
function reviewEditor(s,b){const details=el('details','review');details.append(el('summary','','Review tags locally'));const form=el('form'),inputs={};for(const t of taxonomy){const label=el('label','review-label',t.label),select=el('select');select.setAttribute('aria-label','Local review: '+t.label);addOption(select,'','No correction');addOption(select,'true','Present');addOption(select,'false','Absent');const verdict=review(s,b)?.registers[t.id];if(typeof verdict==='boolean')select.value=String(verdict);inputs[t.id]=select;label.append(select);form.append(label);}const actions=el('div','review-actions'),save=el('button','','Save locally'),reset=el('button','','Clear this review');save.type='submit';reset.type='button';actions.append(save,reset);form.append(actions,el('span','small','The model’s probabilities stay unchanged.'));function commit(registers){if(layer!=='jev')return;if(Object.keys(registers).length)reviews[reviewKey(s,b)]={registers,updated_at:new Date().toISOString()};else delete reviews[reviewKey(s,b)];persistReviews();refresh();const next=document.getElementById('block-'+s._index+'-'+s.blocks.indexOf(b));if(next){const panel=next.querySelector('.model-details');if(panel)panel.open=true;const editor=next.querySelector('.review');if(editor){editor.open=true;editor.querySelector('summary').focus({preventScroll:true});}}}form.addEventListener('submit',event=>{event.preventDefault();commit(Object.fromEntries(taxonomy.filter(t=>inputs[t.id].value!=='').map(t=>[t.id,inputs[t.id].value==='true'])));});reset.addEventListener('click',()=>commit({}));details.append(form);return details;}
function renderHall(){const head=$('reader-head'),body=$('blocks');head.replaceChildren();body.replaceChildren();const s=matchingSources.find(s=>s._index===current);if(!s){$('filter-status').textContent='';body.append(el('div','empty',sources.length?'No blocks match. Try another sequence, register, review view, or phrase.':'This snapshot contains no source files.'));return;}const header=el('header','reader-head');header.append(el('div','eyebrow',pretty(s.sequence)+(s.in_spine?' / Curriculum spine':' / Outside the spine')),el('h2','reader-title',pretty(s.map)));const meta=el('div','reader-meta'),link=el('a','','Read this hall in the book ↗');link.href=bookURL(s);meta.append(link);const nav=el('div','reader-nav'),pos=matchingSources.indexOf(s);for(const [step,label] of [[-1,'← Previous'],[1,'Next →']]){const button=el('button','',label);button.type='button';button.disabled=!matchingSources[pos+step];button.addEventListener('click',()=>chooseSource(matchingSources[pos+step]._index));nav.append(button);}meta.append(nav);header.append(meta,el('div','reader-path',String(s.path)+' · SHA-256 '+String(s.sha256 || 'not recorded')));const warnings=[...(Array.isArray(s.parse_warnings)?s.parse_warnings:s.parse_warnings?[s.parse_warnings]:[]),...s.blocks.map(b=>b.parse_warning).filter(Boolean)];for(const warning of new Set(warnings.map(parseNote)))header.append(el('p','small','Source parsing note: '+warning));const strip=el('div','ribbon reader-ribbon');strip.setAttribute('aria-label','Paragraphs in reading order');s.blocks.forEach((b,i)=>{if(!isProse(b))return;const tile=el('button','tile'+(layerUncertain(b)?' uncertain':'')+(!hasAnnotation(b)?' pending':''));tile.type='button';tile.style.flexShrink='0';const tags=activeTags(b);if(tags.length)tile.style.background=colors(tags);tile.title='L'+String(b.start_line)+': '+(hasAnnotation(b)?tags.map(t=>t.label).join(' + ') || 'No estimate ≥65%':'No annotation in this layer')+(layerUncertain(b)?' · uncertain':'');tile.setAttribute('aria-label',tile.title);tile.disabled=!blockMatches(s,b);tile.addEventListener('click',()=>{const target=document.getElementById('block-'+s._index+'-'+i);if(target){target.scrollIntoView({block:'start',behavior:'auto'});target.setAttribute('tabindex','-1');target.focus({preventScroll:true});}});strip.append(tile);});header.append(strip);const prose=s.blocks.filter(isProse);header.append(el('div','small',layer==='editorial'?count(prose.filter(b=>exampleFor(b)).length)+' / '+count(prose.length)+' editorial examples · '+count(prose.filter(isTagged).length)+' Jev tagged':layer==='jev'?count(prose.filter(isTagged).length)+' / '+count(prose.length)+' Jev tagged · '+count(prose.filter(uncertain).length)+' uncertain':count(prose.length)+' prose blocks · plain text'));head.append(header);const visible=s.blocks.filter(b=>blockMatches(s,b)),p=visible.filter(isProse).length;$('filter-status').textContent=hasBlockFilter()?'Showing '+count(p)+' matching prose blocks and '+count(visible.length-p)+' structural blocks. Original order is preserved.':'Showing the complete hall in its original order.';s.blocks.forEach((b,i)=>{if(blockMatches(s,b))body.append(renderBlock(s,b,i));});}
$('filters').addEventListener('submit',event=>event.preventDefault());
for(const id of ['scope-filter','sequence-filter','tag-filter','view-filter'])$(id).addEventListener('change',()=>refresh(true));
$('hall-filter').addEventListener('change',()=>chooseSource(Number($('hall-filter').value)));
let searchTimer;$('text-filter').addEventListener('input',()=>{clearTimeout(searchTimer);searchTimer=setTimeout(()=>refresh(true),120);});
$('export-reviews').addEventListener('click',()=>{if(layer!=='jev')return;const payload={version:1,kind:'book-register-local-review',snapshot_generated_at:data.generated_at,exported_at:new Date().toISOString(),corrections:activeReviews()};const blob=new Blob([JSON.stringify(payload,null,2)+'\n'],{type:'application/json'}),url=URL.createObjectURL(blob),a=el('a');a.href=url;a.download='book-register-reviews.json';document.body.append(a);a.click();a.remove();setTimeout(()=>URL.revokeObjectURL(url),1000);updateReviewStatus('Exported.');});

// Editorial display is a separate view of fingerprint-matched examples. It never
// changes model registers, statuses, probabilities, or model review exports.
function ribbon(blocks,cls=''){
  const node=el('div','ribbon '+cls);
  for(const b of blocks.filter(isProse)){
    const tags=activeTags(b),tile=el('span','tile'+(layerUncertain(b)?' uncertain':'')+(layer!=='text'&&!hasAnnotation(b)?' pending':''));
    if(tags.length)tile.style.background=colors(tags);
    tile.title=(b.id || 'Prose block')+': '+(tags.map(t=>t.label).join(' + ') || (layer==='text'?'Text only':layer==='editorial'?'No editorial example':'No Jev estimate'))+(layer==='editorial'&&hasAnnotation(b)?' · editorial example':'');node.append(tile);
  }
  node.setAttribute('aria-hidden','true');return node;
}
function blockMatches(s,b){
  const tag=$('tag-filter').value,query=$('text-filter').value.trim().toLocaleLowerCase(),view=$('view-filter').value;
  if(query&&!textFor(b).toLocaleLowerCase().includes(query))return false;
  if(tag&&!activeTags(b).some(t=>t.id===tag))return false;
  if(view==='uncertain'&&!layerUncertain(b))return false;
  if(view==='tagged'&&!hasAnnotation(b))return false;
  if(view==='pending'&&(!isProse(b)||hasAnnotation(b)))return false;
  if(view==='corrected'&&(layer!=='jev'||!isTagged(b)||!review(s,b)))return false;
  return true;
}
function footnotes(s){const notes=new Map();for(const b of s.blocks){if(b.kind!=='footnote')continue;const m=String(b.source_text ?? b.text ?? '').match(/^\[\^([^\]]+)\]:\s*/);if(m&&!notes.has(m[1]))notes.set(m[1],{number:notes.size+1,id:'note-'+s._index+'-'+encodeURIComponent(m[1])});}return notes;}
function inlineDOM(parent,text,s,depth=0){
  if(depth>6){parent.append(document.createTextNode(text));return;}
  // Deliberately small Markdown subset: safe DOM nodes, no HTML or image parsing.
  const pattern=/`([^`]+)`|\[\^([^\]]+)\]|\[([^\]\n]+)\]\((https?:\/\/[^\s)]+)\)|\*\*([^*]+)\*\*|__([^_]+)__|\*([^*\n]+)\*/g;
  let match,last=0;
  while((match=pattern.exec(text))){
    parent.append(document.createTextNode(text.slice(last,match.index)));
    if(match[1]!==undefined)parent.append(el('code','',match[1]));
    else if(match[2]!==undefined){const note=footnotes(s).get(match[2]);if(note){const sup=el('sup'),a=el('a','',note.number);a.href='#'+note.id;a.title='Footnote '+note.number;a.setAttribute('aria-label',a.title);sup.append(a);parent.append(sup);}else parent.append(document.createTextNode(match[0]));}
    else if(match[3]!==undefined){const a=el('a');a.href=match[4];a.rel='noopener noreferrer';inlineDOM(a,match[3],s,depth+1);parent.append(a);}
    else{const node=el(match[5]!==undefined||match[6]!==undefined?'strong':'em');inlineDOM(node,match[5] ?? match[6] ?? match[7],s,depth+1);parent.append(node);}
    last=pattern.lastIndex;
  }
  parent.append(document.createTextNode(text.slice(last)));
}
function proseDOM(s,b){
  const node=el(b.kind==='code'?'pre':b.kind==='heading'?'h3':'p',isProse(b)?'prose':'');let text=textFor(b);
  if(b.kind==='code'){node.textContent=text;return node;}
  if(b.kind==='footnote'){const m=String(b.source_text ?? b.text ?? '').match(/^\[\^([^\]]+)\]:\s*/);if(m){const note=footnotes(s).get(m[1]);if(note){node.id=note.id;node.append(el('span','footnote-mark',note.number+'.'));if(text.startsWith(m[0]))text=text.slice(m[0].length);}}}
  inlineDOM(node,text,s);return node;
}
function tagTint(color){let hex=color.slice(1);if(hex.length===3)hex=hex.split('').map(c=>c+c).join('');return 'rgba('+[0,2,4].map(i=>parseInt(hex.slice(i,i+2),16)).join(',')+',0.045)';}
function renderBlock(s,b,index){
  const structural=!isProse(b),article=el('article','block'+(structural?' structural':'')+(b.kind==='footnote'?' footnote':''));article.id='block-'+s._index+'-'+index;
  const content=el('div','block-content'),top=el('div','block-top');
  top.append(el('span','block-id',String(b.id || index+1)),el('span','','L'+String(b.start_line ?? '?')+(b.end_line!==b.start_line?'–'+String(b.end_line ?? '?'):'')));
  if(structural)top.append(el('span','',b.kind+' · structural'));
  content.append(top);if(b.parse_warning)content.append(el('p','parse-note','Source parsing note: '+parseNote(b.parse_warning)));
  if(structural)content.append(proseDOM(s,b));
  else{
    const frame=el('div','prose-frame'),tags=activeTags(b);
    if(tags.length){frame.style.background='linear-gradient(to right,'+tagTint(tags[0].color)+',transparent)';const bar=el('div','voice-bar');bar.setAttribute('aria-hidden','true');for(const t of tags){const segment=el('span');segment.style.background=t.color;bar.append(segment);}frame.append(bar);}
    frame.append(proseDOM(s,b));content.append(frame);
    const original=el('details','source-markdown');original.append(el('summary','','Source Markdown'),el('pre','',String(b.source_text ?? b.text ?? '')));content.append(original);
  }
  article.append(content);
  if(!structural&&layer!=='text'){
    const aside=el('aside','annotation'),chips=el('div','tag-chips');aside.setAttribute('aria-label',layer==='editorial'?'Provisional editorial registers':'Jev registers');
    for(const t of activeTags(b)){const chip=el('span','tag-chip',t.label);chip.style.setProperty('--tag',t.color);chips.append(chip);}
    if(layer==='editorial'){
      const example=exampleFor(b);
      if(example){aside.append(el('span','badge','Editorial example'),chips);if(example.note)aside.append(el('p','annotation-note',example.note));}
      else aside.append(el('span','annotation-empty','No editorial example'));
    }else if(isTagged(b)){
      aside.append(chips);if(uncertain(b))aside.append(el('span','badge uncertain','Uncertain estimate'));if(review(s,b))aside.append(el('span','badge corrected','Local Jev review'));
      const details=el('details','model-details');details.open=displayMode==='analysis';details.append(el('summary','','Jev probabilities & review'),renderScores(s,b));aside.append(details);
    }else aside.append(el('span','annotation-empty','No Jev estimate'));
    article.append(aside);
  }
  return article;
}
function renderSequenceLayers(){
  $('sequence-overview').replaceChildren();
  for(const group of groups){const button=el('button','sequence-card');button.type='button';button.dataset.sequence=group.key;button.setAttribute('aria-pressed',String($('sequence-filter').value===group.key));const label=el('span','sequence-label');label.append(el('span','',pretty(group.key)),el('span','sequence-count',count(group.sources.length)+' halls'));button.append(label,ribbon(group.sources.flatMap(s=>s.blocks)));button.addEventListener('click',()=>{$('sequence-filter').value=$('sequence-filter').value===group.key?'__all__':group.key;refresh(true);});$('sequence-overview').append(button);}
}
function updateLayerUI(){
  document.body.dataset.layer=layer;
  $('layer-banner').replaceChildren();
  const title=layer==='editorial'?'Editorial example, not Jev results':layer==='jev'?(tagged?'Jev estimates · probability of register presence':'Jev estimates · no results collected'):'Plain text · annotations hidden';
  const description=layer==='editorial'?'Provisional assistant labels, with no assigned probabilities. '+count(exampleTotal)+' matched examples; '+count(tagged)+' Jev-tagged paragraphs. Unmarked paragraphs have no editorial example.':layer==='jev'?'Margins show overlapping registers at 65% or above. '+(tagged?'Open the estimates beside a paragraph to inspect every register.':'Every model paragraph remains pending.'):'The complete hall in its original order, with inline formatting and source lines.';
  $('layer-banner').append(el('strong','',title),el('p','',description));
  $('tag-filter-label').textContent=layer==='jev'?'Register ≥65%':'Register';$('tag-filter').disabled=layer==='text';$('view-filter').disabled=layer==='text';
  $('view-filter').replaceChildren();addOption($('view-filter'),'all','All blocks');
  if(layer!=='text'){addOption($('view-filter'),'tagged',layer==='editorial'?'With editorial examples':'Jev tagged');addOption($('view-filter'),'pending',layer==='editorial'?'Without editorial examples':'Awaiting Jev');if(layer==='jev'){addOption($('view-filter'),'uncertain','Uncertain estimates');addOption($('view-filter'),'corrected','Locally reviewed');}}
  $('review-footer').hidden=layer!=='jev';
  $('pattern-note').textContent=layer==='editorial'?'Each strip tile is one prose block in source order. Its split colors show the provisional editorial labels also present in that paragraph’s margin. Gray means no editorial example, not absence of any register. Examples do not change model statuses or probabilities. Labels can overlap; no target balance is implied.':layer==='jev'?'Each tile is one prose block in reading order. Split colors show overlapping estimates at 65% or above. A dotted edge marks any estimate from 35–65%, or no register at 65% or above. Gray means no Jev estimate. These are probabilities of presence, not quality scores or a desired balance.':'The strips show prose order without annotation colors.';
  if(layer==='editorial'&&editorial.note)$('pattern-note').append(document.createTextNode(' '+editorial.note));
  renderSequenceLayers();
}
function updateMode(){document.body.dataset.mode=displayMode;$('overview').open=displayMode==='analysis';$('reading-view').setAttribute('aria-pressed',String(displayMode==='reading'));$('analysis-view').setAttribute('aria-pressed',String(displayMode==='analysis'));renderHall();}
if(exampleTotal)addOption($('layer-filter'),'editorial','Editorial examples');addOption($('layer-filter'),'jev','Jev estimates');addOption($('layer-filter'),'text','Plain text');$('layer-filter').value=layer;
$('coverage-summary').textContent=' · '+count(sources.length)+' files · '+count(tagged)+' Jev tagged';
$('layer-filter').addEventListener('change',()=>{layer=$('layer-filter').value;$('tag-filter').value='';updateLayerUI();refresh(true);});
$('reading-view').addEventListener('click',()=>{displayMode='reading';updateMode();});$('analysis-view').addEventListener('click',()=>{displayMode='analysis';updateMode();});
updateLayerUI();updateReviewStatus();refresh(true);updateMode();

})();
</script>
</body>
</html>'''


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--data", type=Path, required=True, help="Register snapshot JSON")
    parser.add_argument("--out", type=Path, default=DEFAULT_OUTPUT, help="Self-contained review HTML")
    parser.add_argument("--editorial-examples", type=Path, help="Separate provisional editorial example JSON")
    args = parser.parse_args()
    with args.data.open(encoding="utf-8-sig") as handle:
        data = json.load(handle)
    if not isinstance(data, dict):
        parser.error("The snapshot JSON must be an object.")
    editorial_examples = None
    if args.editorial_examples:
        with args.editorial_examples.open(encoding="utf-8-sig") as handle:
            editorial_examples = json.load(handle)
        if not isinstance(editorial_examples, dict):
            parser.error("Editorial example JSON must be an object.")
    render_report(data, args.out, editorial_examples)
    print(args.out)


if __name__ == "__main__":
    main()
