"use client";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
import { MapVoxelPreview } from "@/components/book/MapVoxelPreview";
import type { MapLayers } from "@/components/map-builder/MapBuilderPage";
import { SECTIONS, type Section } from "@/lib/book-sections";
import { Search, Package, Save, BookOpen, Map as MapIcon, Layers, X, ChevronRight, ChevronDown, Sparkles, Loader2, Pencil, ListTree, Plus } from "lucide-react";

// ── shapes ────────────────────────────────────────────────────────────────
type Artifact = { pos: number | null; lookup: string; name: string; image: string | null; why?: string };
type Chapter = {
  id: string; map: string; title: string; sequence: string; phase: string; seq_truth?: string;
  artifacts: Artifact[]; sections: Record<string, boolean>; hasText: boolean;
};
type Book = { chapterCount: number; withText: number; sections: string[]; chapters: Chapter[] };
type Neighbor = { id: string; sim: number; source?: string; role?: string; register?: string };
type Ladder = { found: boolean; concept?: string; map?: string; truth?: string; tiers?: Record<string, string[]> };


// Every blank Record<Section, T> is DERIVED from SECTIONS. Five of them used to
// be hand-typed object literals sitting beside the list, which is the drift shape
// this repo keeps paying for: adding a section left the initialisers a member
// short, and a missing key reads as an empty section rather than as an error.
const blank = <T,>(v: T) => Object.fromEntries(SECTIONS.map((s) => [s, v])) as Record<Section, T>;
const TIERS = ["small", "medium", "large", "applied"] as const;
type Mode = "all" | "ladder" | "close";

const PHASE_COLOR: Record<string, string> = {
  F_order: "bg-sky-500/15 text-sky-700 dark:text-sky-300", oscillation: "bg-teal-500/15 text-teal-700 dark:text-teal-300",
  E_entropy: "bg-amber-500/15 text-amber-700 dark:text-amber-300", lambda_edge: "bg-fuchsia-500/15 text-fuchsia-700 dark:text-fuchsia-300",
  integration: "bg-emerald-500/15 text-emerald-700 dark:text-emerald-300", relation: "bg-indigo-500/15 text-indigo-700 dark:text-indigo-300",
  synthesis: "bg-rose-500/15 text-rose-700 dark:text-rose-300",
};
const TIER_TONE: Record<string, string> = {
  small: "text-emerald-600 dark:text-emerald-400", medium: "text-sky-600 dark:text-sky-400",
  large: "text-indigo-600 dark:text-indigo-400", applied: "text-rose-600 dark:text-rose-400",
};


function Thumb({ src, alt, className }: { src?: string | null; alt: string; className?: string }) {
  const [err, setErr] = useState(false);
  if (!src || err) return <div className={`flex items-center justify-center bg-zinc-100 dark:bg-zinc-800 ${className || ""}`}><Package className="h-3 w-3 text-zinc-300 dark:text-zinc-600" /></div>;
  // eslint-disable-next-line @next/next/no-img-element
  return <img src={src} alt={alt} loading="lazy" onError={() => setErr(true)} className={`object-cover ${className || ""}`} />;
}

// keep images inside rendered markdown small (scene-catalog stills would otherwise fill the column)
const MD_COMPONENTS = {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any, @next/next/no-img-element
  img: (p: any) => <img src={p.src} alt={p.alt || ""} loading="lazy" className="my-1 inline-block max-h-32 w-auto rounded border border-zinc-200 align-middle dark:border-zinc-700" />,
};

export default function BookPage() {
  const [book, setBook] = useState<Book | null>(null);
  const [imgByLookup, setImgByLookup] = useState<Record<string, string>>({});
  const [nameByLookup, setNameByLookup] = useState<Record<string, string>>({});
  const [allArtifacts, setAllArtifacts] = useState<Artifact[]>([]);

  const [currentId, setCurrentId] = useState<string>("");
  const [sections, setSections] = useState<Record<Section, string>>(blank(""));
  const [dirty, setDirty] = useState<Record<Section, boolean>>(blank(false));
  const [editing, setEditing] = useState<Record<Section, boolean>>(blank(false));
  const [textLoading, setTextLoading] = useState(false);
  const [saving, setSaving] = useState<Section | "">("");
  const [artifactsMd, setArtifactsMd] = useState("");   // generated read-only map summary

  const [mapData, setMapData] = useState<{ layers: MapLayers; [k: string]: unknown } | null>(null);
  const [mapLoading, setMapLoading] = useState(false);
  const [mapDirty, setMapDirty] = useState(false);
  const [mapSaving, setMapSaving] = useState(false);
  const [placeMode, setPlaceMode] = useState(false);
  const layers = mapData?.layers ?? null;

  const [selected, setSelected] = useState<string>("");       // clicked artifact lookup
  const [neighbors, setNeighbors] = useState<Neighbor[] | null>(null);
  const [neighborsLoading, setNeighborsLoading] = useState(false);
  const [ladder, setLadder] = useState<Ladder | null>(null);
  const [ladderLoading, setLadderLoading] = useState(false);
  const [mode, setMode] = useState<Mode>("all");
  const [filter, setFilter] = useState("");
  const [openSeq, setOpenSeq] = useState<Record<string, boolean>>({});
  const [status, setStatus] = useState("");
  const [jumpSection, setJumpSection] = useState("");   // arrived from /wall-map?section=

  const origRef = useRef<Record<Section, string>>(blank(""));

  // Scroll to the section the link asked for, once its text has actually loaded —
  // and clear the flag afterwards so the ring fades and a second arrival re-fires.
  useEffect(() => {
    if (!jumpSection || textLoading) return;
    const el = document.getElementById("sec-" + jumpSection);
    if (!el) return;
    el.scrollIntoView({ behavior: "smooth", block: "start" });
    const t = setTimeout(() => setJumpSection(""), 2200);
    return () => clearTimeout(t);
  }, [jumpSection, textLoading, sections]);

  // ── load book + artifacts palette ──
  useEffect(() => {
    (async () => {
      try {
        const b = (await fetch("/book.json").then((r) => r.json())) as Book;
        setBook(b);
        if (b.chapters?.length) {
          // THE RECEIVER. /wall-map's "this work in the text" panel links here as
          // /book?map=Point_Lines&section=critical — the passage the concordance
          // found, opened where it lives. Without this the link lands on whichever
          // chapter happens to be first and reads as broken. Mirrors the receiver
          // /lines has carried for a while.
          let want: Chapter | undefined;
          let sec = "";
          try {
            const q = new URLSearchParams(window.location.search);
            const m = (q.get("map") || "").trim();
            sec = (q.get("section") || "").trim();
            if (m) want = b.chapters.find((c) => c.map === m);
          } catch { /* no window or no query — fall through to the default */ }
          const first = want || b.chapters.find((c) => c.hasText) || b.chapters[0];
          setCurrentId(first.id);
          setOpenSeq({ [first.sequence]: true });
          if (want && (SECTIONS as readonly string[]).includes(sec)) setJumpSection(sec);
        }
      } catch { setStatus("Could not load book.json — run: python tools/build_book.py"); }
      try {
        const o = await fetch("/order_of_things.json").then((r) => r.json());
        const all: Artifact[] = [...(o.spine || []), ...(o.branch || []), ...(o.dna || []), ...(o.rest || [])];
        const img: Record<string, string> = {}, nm: Record<string, string> = {};
        for (const x of all) { if (x.image && !img[x.lookup]) img[x.lookup] = x.image; if (x.name && !nm[x.lookup]) nm[x.lookup] = x.name; }
        setImgByLookup(img); setNameByLookup(nm);
        const seen = new Set<string>(); const uniq: Artifact[] = [];
        for (const x of all) { if (!seen.has(x.lookup)) { seen.add(x.lookup); uniq.push(x); } }
        setAllArtifacts(uniq);
      } catch { /* palette optional */ }
    })();
  }, []);

  const chapter = useMemo(() => book?.chapters.find((c) => c.id === currentId) || null, [book, currentId]);

  // ── load section text + map layers when the chapter changes ──
  useEffect(() => {
    if (!chapter) return;
    setEditing(blank(false));
    if (chapter.map) {
      setTextLoading(true);
      fetch(`/api/book-text?map=${encodeURIComponent(chapter.map)}`).then((r) => r.json()).then((j) => {
        const s = j.sections || {};
        // Built from SECTIONS so a new section arrives here automatically. The
        // hand-typed version of this line is what made adding one a five-site edit.
        const next = Object.fromEntries(SECTIONS.map((k) => [k, s[k] || ""])) as Record<Section, string>;
        setSections(next); origRef.current = { ...next };
        setDirty(blank(false));
        setArtifactsMd(j.artifacts || "");
      }).catch(() => { /* */ }).finally(() => setTextLoading(false));
    } else {
      const empty = blank("");
      setSections(empty); origRef.current = { ...empty };
      setDirty(blank(false));
      setArtifactsMd("");
    }
    if (chapter.map) {
      setMapLoading(true); setMapData(null); setMapDirty(false); setPlaceMode(false);
      // full map_data (not the derived map-layers view) so we can edit + save it back
      fetch(`/api/voxel-editor?action=load&map=${encodeURIComponent(chapter.map)}`).then((r) => r.json()).then((j) => {
        const d = j.data ?? j.mapData ?? j;
        if (d?.layers) setMapData(d as { layers: MapLayers });
      }).catch(() => { /* */ }).finally(() => setMapLoading(false));
    } else { setMapData(null); }
  }, [chapter]);

  // ── on artifact select: fetch ontology-close neighbors AND the concept ladder ──
  useEffect(() => {
    if (!selected) { setNeighbors(null); setLadder(null); return; }
    setMode((m) => (m === "all" ? "ladder" : m));   // surface the versions by default
    let on = true;
    setNeighborsLoading(true);
    fetch("/api/fold-neighbors", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ ids: [selected], topn: 40 }) })
      .then((r) => r.json()).then((j) => { if (on) setNeighbors((j.neighbors || []) as Neighbor[]); })
      .catch(() => { if (on) setNeighbors([]); }).finally(() => { if (on) setNeighborsLoading(false); });
    setLadderLoading(true); setLadder(null);
    fetch(`/api/concept-ladder?id=${encodeURIComponent(selected)}`).then((r) => r.json())
      .then((j) => { if (on) setLadder(j as Ladder); })
      .catch(() => { if (on) setLadder({ found: false }); }).finally(() => { if (on) setLadderLoading(false); });
    return () => { on = false; };
  }, [selected]);

  const pickArtifact = useCallback((lookup: string) => { if (lookup) setSelected(lookup); }, []);

  // ── 3D map editing — mutate the loaded map_data.layers immutably, mark dirty ──
  const mutateMap = useCallback((fn: (L: MapLayers) => void) => {
    setMapData((prev) => {
      if (!prev) return prev;
      const L: MapLayers = {
        structure: (prev.layers.structure || []).map((r) => [...r]),
        utilities: (prev.layers.utilities || []).map((r) => [...r]),
        interactables: (prev.layers.interactables || []).map((r) => [...r]),
      };
      fn(L);
      return { ...prev, layers: L };
    });
    setMapDirty(true);
  }, []);
  const inGrid = (g: string[][], r: number, c: number) => r >= 0 && c >= 0 && r < g.length && c < (g[r]?.length || 0);
  const addCube = useCallback((r: number, c: number) => mutateMap((L) => { if (!inGrid(L.structure, r, c)) return; const h = parseInt(String(L.structure[r][c] || "0"), 10) || 0; L.structure[r][c] = String(Math.min(h + 1, 5)); }), [mutateMap]);
  const removeCube = useCallback((r: number, c: number) => mutateMap((L) => { if (!inGrid(L.structure, r, c)) return; const h = parseInt(String(L.structure[r][c] || "0"), 10) || 0; L.structure[r][c] = String(Math.max(h - 1, 0)); }), [mutateMap]);
  const moveArtifact = useCallback((fr: number, fc: number, tr: number, tc: number) => mutateMap((L) => {
    if (!inGrid(L.interactables, fr, fc) || !inGrid(L.interactables, tr, tc)) return;
    const tok = L.interactables[fr][fc]; if (!tok || !tok.trim() || tok.trim().startsWith("#")) return;
    L.interactables[fr][fc] = " "; L.interactables[tr][tc] = tok;
  }), [mutateMap]);
  const placeArtifactAt = useCallback((r: number, c: number) => mutateMap((L) => {
    if (!selected || !inGrid(L.interactables, r, c)) return;
    L.interactables[r][c] = `${selected}:0:1`;
    if (inGrid(L.structure, r, c) && (parseInt(String(L.structure[r][c] || "0"), 10) || 0) < 1) L.structure[r][c] = "1";
  }), [mutateMap, selected]);
  const removeArtifact = useCallback((r: number, c: number) => mutateMap((L) => { if (inGrid(L.interactables, r, c)) L.interactables[r][c] = " "; }), [mutateMap]);

  const saveMap = useCallback(async () => {
    if (!mapData || !chapter?.map) return;
    setMapSaving(true);
    try {
      const r = await fetch("/api/voxel-editor", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ mapName: chapter.map, data: mapData }) });
      const j = await r.json().catch(() => ({}));
      if (r.ok && (j.ok ?? true)) { setMapDirty(false); setStatus(`Saved map ${chapter.map}`); }
      else setStatus(`Map save failed: ${j.error || r.status}`);
    } catch (e) { setStatus("Map save failed: " + e); }
    finally { setMapSaving(false); }
  }, [mapData, chapter]);

  // ── harmony meter: spatial layout ↔ ontology (semantic) tension ──
  // positions of each placed artifact (first occurrence), recomputed every edit
  const mapArtifactPos = useMemo(() => {
    const inter = mapData?.layers?.interactables || [];
    const pos: Record<string, { row: number; col: number }> = {};
    for (let r = 0; r < inter.length; r++) for (let c = 0; c < (inter[r]?.length || 0); c++) {
      const cell = String(inter[r][c] ?? "").trim();
      if (!cell || cell.startsWith("#")) continue;
      const lk = cell.split("#")[0].split(":")[0];
      if (lk && !(lk in pos)) pos[lk] = { row: r, col: c };
    }
    return pos;
  }, [mapData]);
  const mapArtifactKey = useMemo(() => Object.keys(mapArtifactPos).sort().join(","), [mapArtifactPos]);
  const [pairs, setPairs] = useState<{ a: string; b: string; sim: number }[]>([]);
  const [pairsLoading, setPairsLoading] = useState(false);
  // fetch semantic pairwise sims only when the SET of placed artifacts changes (not on a move)
  useEffect(() => {
    const ids = mapArtifactKey ? mapArtifactKey.split(",") : [];
    if (ids.length < 3) { setPairs([]); return; }
    let on = true; setPairsLoading(true);
    fetch("/api/artifact-pairs", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ ids }) })
      .then((r) => r.json()).then((j) => { if (on) setPairs((j.pairs || []) as { a: string; b: string; sim: number }[]); })
      .catch(() => { if (on) setPairs([]); }).finally(() => { if (on) setPairsLoading(false); });
    return () => { on = false; };
  }, [mapArtifactKey]);
  // Score one assignment of artifacts→cells. Pulled out of the memo so the null below can
  // call it on a permutation without duplicating the arithmetic.
  const scoreLayout = useCallback((ps: { a: string; b: string; sim: number }[], pos: Record<string, { row: number; col: number }>) => {
    const usable = ps.map((p) => {
      const pa = pos[p.a], pb = pos[p.b];
      if (!pa || !pb) return null;
      return { ...p, d: Math.hypot(pa.row - pb.row, pa.col - pb.col) };
    }).filter(Boolean) as { a: string; b: string; sim: number; d: number }[];
    if (usable.length < 2) return null;
    const sims = usable.map((u) => u.sim), ds = usable.map((u) => u.d);
    const minS = Math.min(...sims), maxS = Math.max(...sims), minD = Math.min(...ds), maxD = Math.max(...ds);
    const nSim = (s: number) => (maxS > minS ? (s - minS) / (maxS - minS) : 0.5);
    const nClose = (d: number) => (maxD > minD ? 1 - (d - minD) / (maxD - minD) : 0.5);
    const scored = usable.map((u) => { const sc = nSim(u.sim), cl = nClose(u.d); return { ...u, sc, cl, tension: Math.abs(sc - cl) }; });
    const meanT = scored.reduce((a, b) => a + b.tension, 0) / scored.length;
    return { score: Math.round((1 - meanT) * 100), count: scored.length, scored };
  }, []);

  // ── the null: what does this meter read when nobody has arranged anything? ──
  //
  // The raw score is mostly NOT about the arrangement. Measured over eight maps with 33–52
  // placed artifacts (tools/harmony_null.py), authored layouts mean 67.9 and random
  // permutations of the same artifacts among the same cells mean 65.9 — two points on a
  // hundred-point scale, with three of the eight authored layouts sitting inside the middle
  // 80% of their own shuffle distribution. Worse, the COLOUR was pre-decided: on
  // Gallery_WaveFunctions, Gallery_MachineLearning and Gallery_ProceduralGeneration a full
  // 100% of random arrangements scored green, and on TemplateMap_Descent13 none could.
  //
  // Because both scales are min–max normalised inside the current map, the raw number reports
  // the artifact set and the position set — neither of which an author edits. The percentile
  // against a permutation of that same set is the part they do control, so that is what is
  // shown. Seeded, so the reading does not flicker between renders.
  const NULL_RUNS = 150;
  const harmony = useMemo(() => {
    const real = scoreLayout(pairs, mapArtifactPos);
    if (!real) return null;
    const ids = Object.keys(mapArtifactPos);
    const cells = ids.map((k) => mapArtifactPos[k]);
    let seed = 20260815;
    const rnd = () => { seed = (seed * 1664525 + 1013904223) >>> 0; return seed / 4294967296; };
    const dist: number[] = [];
    for (let i = 0; i < NULL_RUNS; i++) {
      const perm = cells.slice();
      for (let j = perm.length - 1; j > 0; j--) { const k = Math.floor(rnd() * (j + 1)); [perm[j], perm[k]] = [perm[k], perm[j]]; }
      const shuffled: Record<string, { row: number; col: number }> = {};
      ids.forEach((id, n) => { shuffled[id] = perm[n]; });
      const s = scoreLayout(pairs, shuffled);
      if (s) dist.push(s.score);
    }
    dist.sort((a, b) => a - b);
    const below = dist.filter((s) => s < real.score).length;
    const pct = dist.length ? Math.round((100 * below) / dist.length) : null;
    return {
      score: real.score, count: real.count, pct,
      nullLo: dist.length ? dist[0] : null, nullHi: dist.length ? dist[dist.length - 1] : null,
      nullMean: dist.length ? Math.round(dist.reduce((a, b) => a + b, 0) / dist.length) : null,
      tensions: [...real.scored].sort((a, b) => b.tension - a.tension).slice(0, 6),
    };
  }, [pairs, mapArtifactPos, scoreLayout]);
  // Bands on the PERCENTILE, not the raw score. 50 is chance by construction; below 60 the
  // arrangement is not distinguishable from one nobody made.
  const harmonyColor = (p: number) => (p >= 90 ? "#10b981" : p >= 60 ? "#f59e0b" : "#71717a");

  const saveSection = useCallback(async (s: Section) => {
    if (!chapter?.map) return;
    setSaving(s);
    try {
      const r = await fetch("/api/book-text", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ map: chapter.map, section: s, content: sections[s] }) });
      const j = await r.json();
      if (j.ok) {
        origRef.current[s] = sections[s];
        setDirty((d) => ({ ...d, [s]: false }));
        setEditing((e) => ({ ...e, [s]: false }));
        setStatus(`Saved ${s}.md (${j.bytes} chars)`);
      } else setStatus(`Save failed: ${j.error || "unknown"}`);
    } catch (e) { setStatus("Save failed: " + e); }
    finally { setSaving(""); }
  }, [chapter, sections]);

  const cancelEdit = useCallback((s: Section) => {
    setSections((p) => ({ ...p, [s]: origRef.current[s] ?? "" }));
    setDirty((d) => ({ ...d, [s]: false }));
    setEditing((e) => ({ ...e, [s]: false }));
  }, []);

  // ── derived ──
  const toc = useMemo(() => {
    const groups: { sequence: string; phase: string; chapters: Chapter[] }[] = [];
    for (const c of book?.chapters || []) {
      const g = groups[groups.length - 1];
      if (g && g.sequence === c.sequence) g.chapters.push(c);
      else groups.push({ sequence: c.sequence, phase: c.phase, chapters: [c] });
    }
    return groups;
  }, [book]);

  const q = filter.trim().toLowerCase();
  const matchLk = useCallback((lk: string) => !q || `${nameByLookup[lk] || lk} ${lk}`.toLowerCase().includes(q), [q, nameByLookup]);

  const filteredArtifacts = useMemo(() => {
    if (!q) return allArtifacts.slice(0, 400);
    return allArtifacts.filter((a) => `${a.name} ${a.lookup}`.toLowerCase().includes(q)).slice(0, 400);
  }, [allArtifacts, q]);

  const dirtyCount = Object.values(dirty).filter(Boolean).length;

  // a name + icon row, reused in the TOC and the filter column
  const ArtRow = ({ lookup, name, img, sub, active, big, onClick }: { lookup: string; name?: string; img?: string | null; sub?: string; active?: boolean; big?: boolean; onClick: () => void }) => (
    <button onClick={onClick} title={lookup} className={`flex w-full items-center gap-2 rounded-md px-1.5 py-1 text-left ${active ? "bg-cyan-500/10" : "hover:bg-zinc-100 dark:hover:bg-zinc-800"}`}>
      <div className={`${big ? "h-20 w-20" : "h-7 w-7"} shrink-0 overflow-hidden rounded border border-zinc-200 dark:border-zinc-700`}><Thumb src={img ?? imgByLookup[lookup]} alt={lookup} className="h-full w-full" /></div>
      <span className="min-w-0 flex-1">
        <span className={`block truncate ${big ? "text-xs" : "text-[11px]"} text-zinc-700 dark:text-zinc-200`}>{name || nameByLookup[lookup] || lookup}</span>
        {sub && <span className="block truncate text-[9px] text-zinc-400">{sub}</span>}
      </span>
    </button>
  );

  const tabBtn = (m: Mode, label: string) => (
    <button key={m} onClick={() => setMode(m)} disabled={m !== "all" && !selected}
      className={`rounded px-2 py-0.5 text-[10px] font-medium ${mode === m ? "bg-cyan-500/15 text-cyan-700 dark:text-cyan-300" : "text-zinc-500 hover:bg-zinc-100 disabled:opacity-30 dark:hover:bg-zinc-800"}`}>{label}</button>
  );

  return (
    <div className="fixed inset-x-0 bottom-0 top-14 z-30 flex flex-col bg-zinc-50 text-zinc-800 dark:bg-zinc-950 dark:text-zinc-200">
      {/* header */}
      <div className="flex shrink-0 items-center gap-3 border-b border-zinc-200 bg-white/90 px-4 py-2 backdrop-blur dark:border-zinc-800 dark:bg-zinc-950/90">
        <BookOpen className="h-4 w-4 text-zinc-500" />
        <h1 className="text-sm font-bold text-zinc-900 dark:text-zinc-50">The Book</h1>
        <span className="text-[11px] text-zinc-400">the table of contents is the artifact order in the game</span>
        {book && <span className="text-[11px] text-zinc-400">· {book.chapterCount} chapters · {book.withText} with prose</span>}
        {status && <span className="ml-auto rounded bg-zinc-100 px-2 py-0.5 text-[11px] text-zinc-500 dark:bg-zinc-800">{status}</span>}
      </div>

      <div className="flex min-h-0 flex-1 overflow-x-auto">
        {/* ── 1. TABLE OF CONTENTS ── */}
        <aside className="flex w-80 shrink-0 flex-col border-r border-zinc-200 dark:border-zinc-800">
          <div className="shrink-0 border-b border-zinc-200 px-3 py-1.5 text-[10px] font-semibold uppercase tracking-wide text-zinc-400 dark:border-zinc-800">Table of Contents</div>
          <div className="min-h-0 flex-1 overflow-y-auto">
            {!book && <div className="p-3 text-xs text-zinc-400">Loading book…</div>}
            {toc.map((g) => {
              const open = openSeq[g.sequence] ?? false;
              return (
                <div key={g.sequence} className="border-b border-zinc-100 dark:border-zinc-900">
                  <button onClick={() => setOpenSeq((o) => ({ ...o, [g.sequence]: !open }))} className="flex w-full items-center gap-1 px-2 py-1.5 text-left hover:bg-zinc-50 dark:hover:bg-zinc-900">
                    {open ? <ChevronDown className="h-3 w-3 shrink-0 text-zinc-400" /> : <ChevronRight className="h-3 w-3 shrink-0 text-zinc-400" />}
                    <span className="flex-1 truncate text-[11px] font-semibold text-zinc-700 dark:text-zinc-200">{g.sequence || "—"}</span>
                    <span className={`shrink-0 rounded px-1 text-[8px] ${PHASE_COLOR[g.phase] || "bg-zinc-200 text-zinc-500 dark:bg-zinc-800"}`}>{g.chapters.length}</span>
                  </button>
                  {open && g.chapters.map((c) => (
                    <div key={c.id}>
                      <button onClick={() => setCurrentId(c.id)} className={`flex w-full items-center gap-1.5 py-1 pl-6 pr-2 text-left text-[11px] ${c.id === currentId ? "bg-cyan-500/10 font-medium text-cyan-700 dark:text-cyan-300" : "text-zinc-600 hover:bg-zinc-50 dark:text-zinc-300 dark:hover:bg-zinc-900"}`}>
                        <MapIcon className="h-3 w-3 shrink-0 opacity-50" />
                        <span className="flex-1 truncate">{c.title}</span>
                        {!c.hasText && <span className="shrink-0 text-[8px] text-zinc-400">∅</span>}
                        <span className="shrink-0 text-[9px] tabular-nums text-zinc-400">{c.artifacts.length}</span>
                      </button>
                      {/* artifacts as a name + icon list */}
                      {c.id === currentId && c.artifacts.length > 0 && (
                        <div className="pb-1 pl-7 pr-1">
                          {c.artifacts.map((a) => (
                            <ArtRow key={a.lookup + a.pos} lookup={a.lookup} name={a.name} img={a.image} active={selected === a.lookup} onClick={() => pickArtifact(a.lookup)} />
                          ))}
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              );
            })}
          </div>
        </aside>

        {/* ── 2. TEXT (read-only, edit per section) ── */}
        <section className="flex w-[794px] shrink-0 flex-col border-r border-zinc-200 dark:border-zinc-800">
          <div className="flex shrink-0 items-center gap-2 border-b border-zinc-200 px-3 py-1.5 dark:border-zinc-800">
            <span className="text-[10px] font-semibold uppercase tracking-wide text-zinc-400">Text</span>
            {chapter && <span className="truncate text-xs font-semibold text-zinc-800 dark:text-zinc-100">{chapter.title}</span>}
            {chapter?.sequence && <span className={`shrink-0 rounded px-1.5 py-0.5 text-[9px] ${PHASE_COLOR[chapter.phase] || "bg-zinc-200 text-zinc-500 dark:bg-zinc-800"}`}>{chapter.sequence}</span>}
            {textLoading && <Loader2 className="h-3.5 w-3.5 animate-spin text-zinc-400" />}
            {dirtyCount > 0 && <span className="ml-auto text-[10px] text-amber-500">{dirtyCount} unsaved</span>}
          </div>
          <div className="min-h-0 flex-1 space-y-5 overflow-y-auto p-4">
            {!chapter && <div className="text-sm text-zinc-400">Pick a chapter from the table of contents.</div>}
            {chapter && !chapter.map && <div className="text-sm text-zinc-400">{chapter.title} — the foundation atoms. (No per-map prose; see the artifacts below.)</div>}
            {/* generated, read-only map summary — the map read through its artifacts */}
            {chapter?.map && artifactsMd && (
              <details open className="rounded-md border border-zinc-200 bg-white/60 dark:border-zinc-800 dark:bg-zinc-900/40">
                <summary className="cursor-pointer px-3 py-1.5 text-[11px] font-semibold uppercase tracking-wide text-zinc-500">Artifacts — map summary <span className="font-normal normal-case text-zinc-400">(generated)</span></summary>
                <div className="prose prose-sm max-w-none px-3 pb-3 text-zinc-700 dark:prose-invert dark:text-zinc-300">
                  <ReactMarkdown remarkPlugins={[remarkGfm]} components={MD_COMPONENTS}>{artifactsMd}</ReactMarkdown>
                </div>
              </details>
            )}
            {chapter?.map && SECTIONS.map((s) => {
              const isEditing = editing[s];
              const text = sections[s];
              return (
                <div key={s} id={"sec-" + s} className={jumpSection === s ? "rounded-md ring-2 ring-cyan-400/70 ring-offset-2 ring-offset-white transition-shadow dark:ring-offset-zinc-950" : undefined}>
                  <div className="mb-1 flex items-center gap-2">
                    <label className="text-[11px] font-semibold uppercase tracking-wide text-zinc-500">{s}</label>
                    {dirty[s] && <span className="h-1.5 w-1.5 rounded-full bg-amber-400" title="unsaved" />}
                    {isEditing ? (
                      <span className="ml-auto flex items-center gap-1">
                        <button onClick={() => saveSection(s)} disabled={saving === s} className="inline-flex items-center gap-1 rounded border border-cyan-400 px-1.5 py-0.5 text-[10px] text-cyan-700 hover:bg-cyan-50 disabled:opacity-40 dark:text-cyan-300 dark:hover:bg-cyan-950/40">
                          {saving === s ? <Loader2 className="h-3 w-3 animate-spin" /> : <Save className="h-3 w-3" />} save
                        </button>
                        <button onClick={() => cancelEdit(s)} className="rounded border border-zinc-300 px-1.5 py-0.5 text-[10px] text-zinc-500 hover:bg-zinc-100 dark:border-zinc-700 dark:hover:bg-zinc-800">cancel</button>
                      </span>
                    ) : (
                      <button onClick={() => setEditing((e) => ({ ...e, [s]: true }))} className="ml-auto inline-flex items-center gap-1 rounded border border-zinc-300 px-1.5 py-0.5 text-[10px] text-zinc-500 hover:bg-zinc-100 dark:border-zinc-700 dark:hover:bg-zinc-800">
                        <Pencil className="h-3 w-3" /> edit
                      </button>
                    )}
                  </div>
                  {isEditing ? (
                    <textarea
                      value={text}
                      onChange={(e) => { setSections((p) => ({ ...p, [s]: e.target.value })); setDirty((d) => ({ ...d, [s]: true })); }}
                      placeholder={`${s}.md — empty`}
                      spellCheck={false}
                      className="h-56 w-full resize-y rounded-md border border-cyan-300 bg-white p-2 font-mono text-[11px] leading-relaxed text-zinc-800 outline-none focus:border-cyan-500 dark:border-cyan-800 dark:bg-zinc-900 dark:text-zinc-100"
                    />
                  ) : text.trim() ? (
                    <div className="prose prose-sm max-w-none rounded-md border border-zinc-100 bg-zinc-50/60 p-3 text-zinc-700 dark:prose-invert dark:border-zinc-800 dark:bg-zinc-900/40 dark:text-zinc-300">
                      <ReactMarkdown remarkPlugins={[remarkGfm]} components={MD_COMPONENTS}>{text}</ReactMarkdown>
                    </div>
                  ) : (
                    <div className="rounded-md border border-dashed border-zinc-200 p-3 text-xs italic text-zinc-400 dark:border-zinc-800">empty — click <b>edit</b> to write {s}.md</div>
                  )}
                </div>
              );
            })}
            {chapter && chapter.artifacts.length > 0 && (
              <div className="border-t border-zinc-200 pt-3 dark:border-zinc-800">
                <div className="mb-2 text-[10px] font-semibold uppercase tracking-wide text-zinc-400">Illustrated by</div>
                <div className="grid grid-cols-4 gap-2 sm:grid-cols-5">
                  {chapter.artifacts.map((a) => (
                    <button key={a.lookup + a.pos} onClick={() => pickArtifact(a.lookup)} title={`${a.name}${a.why ? " — " + a.why : ""}`} className={`overflow-hidden rounded-md border text-left ${selected === a.lookup ? "border-cyan-400 ring-2 ring-cyan-400/40" : "border-zinc-200 dark:border-zinc-700"}`}>
                      <Thumb src={a.image || imgByLookup[a.lookup]} alt={a.lookup} className="aspect-square w-full" />
                    </button>
                  ))}
                </div>
              </div>
            )}
          </div>
        </section>

        {/* ── 3. MAP ── */}
        <section className="flex min-w-[24rem] flex-1 flex-col border-r border-zinc-200 dark:border-zinc-800">
          <div className="flex shrink-0 items-center gap-2 border-b border-zinc-200 px-3 py-1.5 dark:border-zinc-800">
            <Layers className="h-3.5 w-3.5 text-zinc-400" />
            <span className="text-[10px] font-semibold uppercase tracking-wide text-zinc-400">Map</span>
            {chapter?.map && <span className="truncate text-xs text-zinc-500">{chapter.map}</span>}
            {mapLoading && <Loader2 className="h-3.5 w-3.5 animate-spin text-zinc-400" />}
            {layers && selected && (
              <button onClick={() => setPlaceMode((v) => !v)} title={`Click a cell to drop ${nameByLookup[selected] || selected}`} className={`ml-auto inline-flex items-center gap-1 rounded border px-1.5 py-0.5 text-[10px] ${placeMode ? "border-cyan-400 bg-cyan-500/10 text-cyan-700 dark:text-cyan-300" : "border-zinc-300 text-zinc-500 hover:bg-zinc-100 dark:border-zinc-700 dark:hover:bg-zinc-800"}`}>
                <Plus className="h-3 w-3" />{placeMode ? "placing…" : "place"}
              </button>
            )}
            {layers && mapDirty && (
              <button onClick={saveMap} disabled={mapSaving} className={`${selected ? "" : "ml-auto"} inline-flex items-center gap-1 rounded border border-amber-400 px-1.5 py-0.5 text-[10px] text-amber-700 hover:bg-amber-50 disabled:opacity-40 dark:text-amber-300 dark:hover:bg-amber-950/40`}>
                {mapSaving ? <Loader2 className="h-3 w-3 animate-spin" /> : <Save className="h-3 w-3" />} save map
              </button>
            )}
          </div>
          <div className="relative min-h-0 flex-1 bg-[#0f1018]">
            {!chapter?.map && <div className="p-4 text-sm text-zinc-400">No map for this chapter.</div>}
            {chapter?.map && !layers && !mapLoading && <div className="p-4 text-sm text-zinc-400">Map not available.</div>}
            {layers && (
              <MapVoxelPreview
                layers={layers} imgByLookup={imgByLookup} mapKey={chapter?.map} editable
                placeArtifact={placeMode ? selected : null}
                onPickArtifact={pickArtifact}
                onAddCube={addCube} onRemoveCube={removeCube}
                onMoveArtifact={moveArtifact} onPlaceArtifact={placeArtifactAt} onRemoveArtifact={removeArtifact}
              />
            )}
            {layers && (
              <p className="pointer-events-none absolute bottom-2 left-2 rounded bg-black/40 px-1.5 py-0.5 text-[10px] text-zinc-300">
                orbit: drag · zoom: scroll · <span className="text-cyan-300">ctrl+click</span> raise · <span className="text-cyan-300">ctrl+right</span> lower · <span className="text-cyan-300">shift+drag</span> move · <span className="text-cyan-300">shift+right</span> remove · click an artifact to select{placeMode ? " · click a cell to place" : ""}
              </p>
            )}
          </div>
          {/* harmony meter — space ↔ ontology tension, the work to gradually harmonise */}
          {layers && harmony && (
            <div className="shrink-0 border-t border-zinc-200 bg-white px-3 py-2 dark:border-zinc-800 dark:bg-zinc-950">
              <div className="flex items-center gap-2">
                <span className="text-[10px] font-semibold uppercase tracking-wide text-zinc-400">Harmony</span>
                {harmony.pct !== null ? (
                  <span className="text-sm font-bold tabular-nums" style={{ color: harmonyColor(harmony.pct) }}>{harmony.pct}<span className="text-[10px] font-normal">th pct</span></span>
                ) : (
                  <span className="text-sm font-bold tabular-nums text-zinc-400">—</span>
                )}
                <span className="text-[10px] text-zinc-400">
                  vs {NULL_RUNS} shuffles of these {Object.keys(mapArtifactPos).length} artifacts · raw {harmony.score}
                  {harmony.nullLo !== null ? ` (chance ${harmony.nullLo}–${harmony.nullHi})` : ""}
                  {pairsLoading ? " · …" : ""}
                </span>
                <span className="ml-auto text-[9px] text-zinc-400">
                  {harmony.pct !== null && harmony.pct < 60 ? "not yet distinguishable from chance" : "better than chance — keep going"}
                </span>
              </div>
              {/* The bar is the percentile. The old bar was the raw score, which moved by about
                  two points across every possible arrangement and so read as full whatever you did. */}
              <div className="mt-1 h-1 w-full overflow-hidden rounded-full bg-zinc-200 dark:bg-zinc-800">
                <div className="h-full rounded-full transition-all" style={{ width: `${harmony.pct ?? 0}%`, background: harmonyColor(harmony.pct ?? 0) }} />
              </div>
              <div className="mt-1.5 max-h-24 space-y-0.5 overflow-y-auto">
                {harmony.tensions.map((t) => (
                  <button key={t.a + t.b} onClick={() => pickArtifact(t.a)} title="select to act on this pair" className="flex w-full items-center gap-1.5 rounded px-1 py-0.5 text-left text-[10px] hover:bg-zinc-100 dark:hover:bg-zinc-800">
                    <span className={`w-16 shrink-0 truncate rounded px-1 text-center text-[8px] font-medium uppercase ${t.sc > t.cl ? "bg-fuchsia-500/15 text-fuchsia-700 dark:text-fuchsia-300" : "bg-amber-500/15 text-amber-700 dark:text-amber-300"}`}>{t.sc > t.cl ? "kin · far" : "near · unrel"}</span>
                    <span className="min-w-0 flex-1 truncate text-zinc-600 dark:text-zinc-300">{nameByLookup[t.a] || t.a} ↔ {nameByLookup[t.b] || t.b}</span>
                    <span className="shrink-0 tabular-nums text-zinc-400">{Math.round(t.sim * 100)}%</span>
                  </button>
                ))}
              </div>
            </div>
          )}
        </section>

        {/* ── 4. ARTIFACT FILTER LIST ── */}
        <aside className="flex w-72 shrink-0 flex-col">
          <div className="shrink-0 space-y-1.5 border-b border-zinc-200 px-3 py-1.5 dark:border-zinc-800">
            {/* search box — always */}
            <div className="flex items-center gap-1.5 rounded-md border border-zinc-300 bg-white px-2 py-1 dark:border-zinc-700 dark:bg-zinc-900">
              <Search className="h-3 w-3 shrink-0 text-zinc-400" />
              <input value={filter} onChange={(e) => setFilter(e.target.value)} placeholder="filter artifacts…" className="w-full bg-transparent text-xs outline-none placeholder:text-zinc-400" />
              {filter && <button onClick={() => setFilter("")} className="text-zinc-400 hover:text-zinc-600"><X className="h-3 w-3" /></button>}
            </div>
            {/* mode tabs */}
            <div className="flex items-center gap-1">
              {tabBtn("all", "All")}
              {tabBtn("ladder", "Versions")}
              {tabBtn("close", "Close")}
              {selected && (
                <span className="ml-auto flex min-w-0 items-center gap-1">
                  <span className="truncate text-[10px] text-cyan-600 dark:text-cyan-300" title={selected}>{nameByLookup[selected] || selected}</span>
                  <button onClick={() => { setSelected(""); setMode("all"); }} title="clear selection" className="text-zinc-400 hover:text-zinc-700 dark:hover:text-zinc-200"><X className="h-3 w-3" /></button>
                </span>
              )}
            </div>
          </div>
          <div className="min-h-0 flex-1 overflow-y-auto p-2">
            {/* ALL */}
            {mode === "all" && (
              <ul className="space-y-0.5">
                {filteredArtifacts.map((a) => (
                  <li key={a.lookup}><ArtRow big lookup={a.lookup} name={a.name} img={a.image} active={selected === a.lookup} onClick={() => pickArtifact(a.lookup)} /></li>
                ))}
                {filteredArtifacts.length === 0 && <div className="p-3 text-xs text-zinc-400">No matches.</div>}
              </ul>
            )}
            {/* VERSIONS — small / medium / large / applied from the concept ladder */}
            {mode === "ladder" && (
              ladderLoading ? <div className="flex items-center gap-2 p-3 text-xs text-zinc-400"><Loader2 className="h-3.5 w-3.5 animate-spin" />finding versions…</div>
              : ladder?.found ? (
                <div className="space-y-2">
                  <div className="px-1 pb-1 text-[10px] text-zinc-400"><ListTree className="mr-1 inline h-3 w-3" />{ladder.map} · <span className="text-zinc-600 dark:text-zinc-300">{ladder.concept}</span></div>
                  {TIERS.map((t) => {
                    const items = (ladder.tiers?.[t] || []).filter(matchLk);
                    if (!items.length) return null;
                    return (
                      <div key={t}>
                        <div className={`px-1 text-[9px] font-bold uppercase tracking-wide ${TIER_TONE[t]}`}>{t}</div>
                        {items.map((lk) => <ArtRow key={lk} big lookup={lk} sub={t} active={selected === lk} onClick={() => pickArtifact(lk)} />)}
                      </div>
                    );
                  })}
                </div>
              ) : <div className="p-3 text-xs text-zinc-400">{selected ? "Not in a concept ladder — try Close." : "Select an artifact to see its small/medium/large/applied versions."}</div>
            )}
            {/* CLOSE — ontology neighbors */}
            {mode === "close" && (
              neighborsLoading ? <div className="flex items-center gap-2 p-3 text-xs text-zinc-400"><Loader2 className="h-3.5 w-3.5 animate-spin" />finding kin…</div>
              : (neighbors && neighbors.length) ? (
                <ul className="space-y-0.5">
                  {neighbors.filter((n) => matchLk(n.id)).map((n) => (
                    <li key={n.id}><ArtRow lookup={n.id} sub={`${n.source || ""}${n.role ? " · " + n.role : ""} · ${(n.sim * 100).toFixed(0)}%`} active={selected === n.id} onClick={() => pickArtifact(n.id)} /></li>
                  ))}
                </ul>
              ) : <div className="p-3 text-xs text-zinc-400">{selected ? "No neighbors found." : "Select an artifact to see its kin."}</div>
            )}
          </div>
        </aside>
      </div>
    </div>
  );
}
