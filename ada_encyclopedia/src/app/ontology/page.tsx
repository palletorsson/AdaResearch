"use client";

import { useEffect, useState, useMemo, useCallback } from "react";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface OntologyEntry {
  title: string;
  primitive: string;
  sequence: string;
  phase: string;
  lens: string;
  question: string;
  web_editor: string | null;
  tags: string[];
  status?: string;
  godot_infoboard?: string | null;
  content: string;
}

interface PhaseInfo {
  name: string;
  description: string;
}

interface ApiResponse {
  phases: Record<string, PhaseInfo>;
  entries: OntologyEntry[];
}

// ---------------------------------------------------------------------------
// Phase colors — maps phase keys to accent colors
// ---------------------------------------------------------------------------

const PHASE_COLORS: Record<string, { bg: string; border: string; text: string; badge: string }> = {
  F_order:     { bg: "bg-cyan-950/40",    border: "border-cyan-700/50",    text: "text-cyan-400",    badge: "bg-cyan-900/60 text-cyan-300" },
  oscillation: { bg: "bg-amber-950/40",   border: "border-amber-700/50",   text: "text-amber-400",   badge: "bg-amber-900/60 text-amber-300" },
  E_entropy:   { bg: "bg-pink-950/40",    border: "border-pink-700/50",    text: "text-pink-400",    badge: "bg-pink-900/60 text-pink-300" },
  lambda_edge: { bg: "bg-violet-950/40",  border: "border-violet-700/50",  text: "text-violet-400",  badge: "bg-violet-900/60 text-violet-300" },
  meta:        { bg: "bg-emerald-950/40", border: "border-emerald-700/50", text: "text-emerald-400", badge: "bg-emerald-900/60 text-emerald-300" },
};

function phaseColor(phase: string) {
  return PHASE_COLORS[phase] || PHASE_COLORS.meta;
}

// ---------------------------------------------------------------------------
// Simple Markdown to HTML — no external deps
// ---------------------------------------------------------------------------

function renderMarkdown(md: string): string {
  if (!md) return "";

  // Escape HTML entities first
  let html = md
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");

  // Code blocks (``` ... ```)
  html = html.replace(/```(\w*)\n([\s\S]*?)```/g, (_m, _lang, code) => {
    return `<pre class="bg-zinc-900 rounded p-3 my-3 overflow-x-auto text-sm text-zinc-300 border border-zinc-700"><code>${code.trim()}</code></pre>`;
  });

  // Tables: detect lines with | ... | patterns
  html = html.replace(
    /((?:^\|.+\|$\n?)+)/gm,
    (tableBlock) => {
      const rows = tableBlock.trim().split("\n").filter(Boolean);
      if (rows.length < 2) return tableBlock;

      // Check if second row is separator (| --- | --- |)
      const isSeparator = /^\|[\s-:|]+\|$/.test(rows[1]);
      const dataRows = isSeparator ? [rows[0], ...rows.slice(2)] : rows;

      let table = '<table class="w-full my-3 text-sm border-collapse">';
      dataRows.forEach((row, i) => {
        const cells = row
          .split("|")
          .slice(1, -1)
          .map((c) => c.trim());
        const tag = i === 0 && isSeparator ? "th" : "td";
        const cellClass =
          tag === "th"
            ? "border border-zinc-700 px-3 py-1.5 bg-zinc-800 text-zinc-300 font-medium text-left"
            : "border border-zinc-700 px-3 py-1.5 text-zinc-400";
        table += "<tr>";
        cells.forEach((cell) => {
          table += `<${tag} class="${cellClass}">${cell}</${tag}>`;
        });
        table += "</tr>";
      });
      table += "</table>";
      return table;
    }
  );

  // Split into blocks by double newline
  const blocks = html.split(/\n\n+/);
  const processed = blocks.map((block) => {
    const trimmed = block.trim();
    if (!trimmed) return "";

    // Already processed (pre, table)
    if (trimmed.startsWith("<pre") || trimmed.startsWith("<table")) return trimmed;

    // Headers
    if (trimmed.startsWith("######")) return `<h6 class="text-sm font-semibold text-zinc-300 mt-4 mb-1">${inlineFormat(trimmed.slice(6).trim())}</h6>`;
    if (trimmed.startsWith("#####"))  return `<h5 class="text-sm font-semibold text-zinc-300 mt-4 mb-1">${inlineFormat(trimmed.slice(5).trim())}</h5>`;
    if (trimmed.startsWith("####"))   return `<h4 class="text-base font-semibold text-zinc-200 mt-4 mb-1">${inlineFormat(trimmed.slice(4).trim())}</h4>`;
    if (trimmed.startsWith("###"))    return `<h3 class="text-lg font-semibold text-zinc-200 mt-5 mb-2">${inlineFormat(trimmed.slice(3).trim())}</h3>`;
    if (trimmed.startsWith("##"))     return `<h2 class="text-xl font-bold text-zinc-100 mt-6 mb-2">${inlineFormat(trimmed.slice(2).trim())}</h2>`;
    if (trimmed.startsWith("#"))      return `<h1 class="text-2xl font-bold text-zinc-50 mt-6 mb-3">${inlineFormat(trimmed.slice(1).trim())}</h1>`;

    // List block (lines starting with -)
    const lines = trimmed.split("\n");
    if (lines.every((l) => /^\s*-\s/.test(l) || !l.trim())) {
      const items = lines
        .filter((l) => l.trim())
        .map((l) => `<li class="ml-4 text-zinc-400">${inlineFormat(l.replace(/^\s*-\s*/, ""))}</li>`)
        .join("");
      return `<ul class="list-disc pl-4 my-2 space-y-1">${items}</ul>`;
    }

    // Regular paragraph
    return `<p class="text-zinc-400 my-2 leading-relaxed">${inlineFormat(trimmed.replace(/\n/g, " "))}</p>`;
  });

  return processed.join("\n");
}

function inlineFormat(text: string): string {
  // Inline code
  let result = text.replace(/`([^`]+)`/g, '<code class="bg-zinc-800 text-pink-400 px-1.5 py-0.5 rounded text-sm font-mono">$1</code>');
  // Bold + italic
  result = result.replace(/\*\*\*(.+?)\*\*\*/g, "<strong><em>$1</em></strong>");
  // Bold
  result = result.replace(/\*\*(.+?)\*\*/g, '<strong class="text-zinc-200">$1</strong>');
  // Italic
  result = result.replace(/\*(.+?)\*/g, "<em>$1</em>");
  return result;
}

// ---------------------------------------------------------------------------
// Summary table from PRIMITIVE_ONTOLOGY.md
// ---------------------------------------------------------------------------

function SummaryTable({ entries }: { entries: OntologyEntry[] }) {
  return (
    <div className="overflow-x-auto mb-10">
      <table className="w-full text-sm border-collapse">
        <thead>
          <tr>
            <th className="border border-zinc-700 px-4 py-2 bg-zinc-800 text-zinc-300 font-medium text-left">Primitive</th>
            <th className="border border-zinc-700 px-4 py-2 bg-zinc-800 text-zinc-300 font-medium text-left">Lens</th>
            <th className="border border-zinc-700 px-4 py-2 bg-zinc-800 text-zinc-300 font-medium text-left">Core Question</th>
            <th className="border border-zinc-700 px-4 py-2 bg-zinc-800 text-zinc-300 font-medium text-left">Phase</th>
          </tr>
        </thead>
        <tbody>
          {entries.map((e) => (
            <tr key={e.primitive} className="hover:bg-zinc-800/50 transition-colors">
              <td className="border border-zinc-700 px-4 py-2 text-zinc-200 font-medium">{e.title.split(" — ")[0]}</td>
              <td className="border border-zinc-700 px-4 py-2 text-zinc-400">{e.lens}</td>
              <td className="border border-zinc-700 px-4 py-2 text-zinc-400 italic">{e.question}</td>
              <td className="border border-zinc-700 px-4 py-2">
                <span className={`px-2 py-0.5 rounded text-xs ${phaseColor(e.phase).badge}`}>{e.phase}</span>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Primitive card
// ---------------------------------------------------------------------------

function PrimitiveCard({
  entry,
  expanded,
  onToggle,
}: {
  entry: OntologyEntry;
  expanded: boolean;
  onToggle: () => void;
}) {
  const colors = phaseColor(entry.phase);

  return (
    <div
      className={`rounded-lg border ${colors.border} ${colors.bg} transition-all duration-200`}
    >
      {/* Header — always visible */}
      <button
        onClick={onToggle}
        className="w-full text-left p-5 focus:outline-none focus:ring-2 focus:ring-cyan-500/50 rounded-lg"
      >
        <div className="flex items-start justify-between gap-3">
          <div className="flex-1 min-w-0">
            <h3 className="text-lg font-semibold text-zinc-100 mb-1">
              {entry.title}
            </h3>
            <p className="text-sm text-zinc-500 mb-2">
              <span className="font-medium text-zinc-400">Lens:</span> {entry.lens}
            </p>
            <p className="text-zinc-400 italic text-sm">{entry.question}</p>
          </div>
          <div className="flex flex-col items-end gap-2 shrink-0">
            <span className={`px-2 py-0.5 rounded text-xs ${colors.badge}`}>
              {entry.sequence}
            </span>
            {entry.status === "draft" && (
              <span className="px-2 py-0.5 rounded text-xs bg-zinc-700 text-zinc-400">
                draft
              </span>
            )}
            <svg
              className={`w-5 h-5 text-zinc-500 transition-transform ${expanded ? "rotate-180" : ""}`}
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              strokeWidth={2}
            >
              <path strokeLinecap="round" strokeLinejoin="round" d="M19 9l-7 7-7-7" />
            </svg>
          </div>
        </div>
        {/* Tags */}
        <div className="flex flex-wrap gap-1.5 mt-3">
          {entry.tags.map((tag) => (
            <span
              key={tag}
              className="px-2 py-0.5 rounded-full text-xs bg-zinc-800 text-zinc-500 border border-zinc-700"
            >
              {tag}
            </span>
          ))}
        </div>
      </button>

      {/* Expanded content */}
      {expanded && (
        <div className="px-5 pb-5 border-t border-zinc-700/50">
          {entry.web_editor && (
            <a
              href={entry.web_editor}
              className="inline-flex items-center gap-1.5 mt-4 mb-3 px-3 py-1.5 rounded bg-cyan-900/40 text-cyan-400 text-sm font-medium hover:bg-cyan-900/60 transition-colors border border-cyan-800/50"
            >
              <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
              </svg>
              Open Web Editor
            </a>
          )}
          <div
            className="prose-ontology mt-3"
            dangerouslySetInnerHTML={{ __html: renderMarkdown(entry.content) }}
          />
        </div>
      )}
    </div>
  );
}

// ---------------------------------------------------------------------------
// Sidebar
// ---------------------------------------------------------------------------

function Sidebar({
  phases,
  allSequences,
  activePhase,
  activeSequence,
  search,
  onPhaseChange,
  onSequenceChange,
  onSearchChange,
}: {
  phases: Record<string, PhaseInfo>;
  allSequences: string[];
  activePhase: string | null;
  activeSequence: string | null;
  search: string;
  onPhaseChange: (p: string | null) => void;
  onSequenceChange: (s: string | null) => void;
  onSearchChange: (s: string) => void;
}) {
  return (
    <aside className="w-full lg:w-64 shrink-0 space-y-6">
      {/* Search */}
      <div>
        <label className="block text-xs font-medium text-zinc-500 uppercase tracking-wider mb-2">
          Search
        </label>
        <input
          type="text"
          value={search}
          onChange={(e) => onSearchChange(e.target.value)}
          placeholder="Search primitives..."
          className="w-full px-3 py-2 rounded bg-zinc-800 border border-zinc-700 text-zinc-200 text-sm placeholder-zinc-500 focus:outline-none focus:ring-2 focus:ring-cyan-500/50 focus:border-cyan-600"
        />
      </div>

      {/* Phase filters */}
      <div>
        <label className="block text-xs font-medium text-zinc-500 uppercase tracking-wider mb-2">
          QFEP Phase
        </label>
        <div className="space-y-1">
          <button
            onClick={() => onPhaseChange(null)}
            className={`w-full text-left px-3 py-1.5 rounded text-sm transition-colors ${
              !activePhase
                ? "bg-zinc-700 text-zinc-100"
                : "text-zinc-400 hover:bg-zinc-800 hover:text-zinc-200"
            }`}
          >
            All phases
          </button>
          {Object.entries(phases).map(([key, info]) => {
            const colors = phaseColor(key);
            return (
              <button
                key={key}
                onClick={() => onPhaseChange(activePhase === key ? null : key)}
                className={`w-full text-left px-3 py-1.5 rounded text-sm transition-colors ${
                  activePhase === key
                    ? `${colors.bg} ${colors.text} ${colors.border} border`
                    : "text-zinc-400 hover:bg-zinc-800 hover:text-zinc-200"
                }`}
              >
                {info.name}
              </button>
            );
          })}
        </div>
      </div>

      {/* Sequence filters */}
      <div>
        <label className="block text-xs font-medium text-zinc-500 uppercase tracking-wider mb-2">
          Sequence
        </label>
        <div className="space-y-1">
          <button
            onClick={() => onSequenceChange(null)}
            className={`w-full text-left px-3 py-1.5 rounded text-sm transition-colors ${
              !activeSequence
                ? "bg-zinc-700 text-zinc-100"
                : "text-zinc-400 hover:bg-zinc-800 hover:text-zinc-200"
            }`}
          >
            All sequences
          </button>
          {allSequences.map((seq) => (
            <button
              key={seq}
              onClick={() => onSequenceChange(activeSequence === seq ? null : seq)}
              className={`w-full text-left px-3 py-1.5 rounded text-sm transition-colors ${
                activeSequence === seq
                  ? "bg-zinc-700 text-zinc-100"
                  : "text-zinc-400 hover:bg-zinc-800 hover:text-zinc-200"
              }`}
            >
              {seq}
            </button>
          ))}
        </div>
      </div>
    </aside>
  );
}

// ---------------------------------------------------------------------------
// Main page
// ---------------------------------------------------------------------------

export default function OntologyPage() {
  const [data, setData] = useState<ApiResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [expandedPrimitive, setExpandedPrimitive] = useState<string | null>(null);
  const [activePhase, setActivePhase] = useState<string | null>(null);
  const [activeSequence, setActiveSequence] = useState<string | null>(null);
  const [search, setSearch] = useState("");

  useEffect(() => {
    fetch("/api/ontology")
      .then((r) => {
        if (!r.ok) throw new Error(`HTTP ${r.status}`);
        return r.json();
      })
      .then((d: ApiResponse) => {
        setData(d);
        setLoading(false);
      })
      .catch((e) => {
        setError(e.message);
        setLoading(false);
      });
  }, []);

  const allSequences = useMemo(() => {
    if (!data) return [];
    return [...new Set(data.entries.map((e) => e.sequence))].sort();
  }, [data]);

  const filtered = useMemo(() => {
    if (!data) return [];
    let entries = data.entries;
    if (activePhase) entries = entries.filter((e) => e.phase === activePhase);
    if (activeSequence) entries = entries.filter((e) => e.sequence === activeSequence);
    if (search) {
      const q = search.toLowerCase();
      entries = entries.filter(
        (e) =>
          e.title.toLowerCase().includes(q) ||
          e.lens.toLowerCase().includes(q) ||
          e.question.toLowerCase().includes(q) ||
          e.tags.some((t) => t.toLowerCase().includes(q)) ||
          e.content.toLowerCase().includes(q)
      );
    }
    return entries;
  }, [data, activePhase, activeSequence, search]);

  // Group filtered entries by phase
  const groupedByPhase = useMemo(() => {
    if (!data) return [];
    const phaseOrder = Object.keys(data.phases);
    const groups: { phase: string; info: PhaseInfo; entries: OntologyEntry[] }[] = [];
    for (const phase of phaseOrder) {
      const entries = filtered.filter((e) => e.phase === phase);
      if (entries.length > 0) {
        groups.push({ phase, info: data.phases[phase], entries });
      }
    }
    return groups;
  }, [data, filtered]);

  const toggleExpand = useCallback(
    (primitive: string) => {
      setExpandedPrimitive((prev) => (prev === primitive ? null : primitive));
    },
    []
  );

  if (loading) {
    return (
      <div className="min-h-screen bg-zinc-900 flex items-center justify-center">
        <div className="text-zinc-500 text-lg">Loading ontology...</div>
      </div>
    );
  }

  if (error || !data) {
    return (
      <div className="min-h-screen bg-zinc-900 flex items-center justify-center">
        <div className="text-red-400 text-lg">
          Failed to load ontology: {error || "unknown error"}
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-zinc-900 text-zinc-100">
      {/* Header */}
      <header className="border-b border-zinc-800 px-6 py-8">
        <div className="max-w-7xl mx-auto">
          <h1 className="text-3xl font-bold mb-2">Primitive Ontology</h1>
          <p className="text-zinc-400 text-lg max-w-3xl">
            Every primitive is a lens on the world. Not &ldquo;how does it work&rdquo;
            but &ldquo;what does it reveal about the nature of things?&rdquo;
          </p>
          <p className="text-zinc-600 text-sm mt-2">
            {data.entries.length} primitives across{" "}
            {Object.keys(data.phases).length} QFEP phases
          </p>
        </div>
      </header>

      <div className="max-w-7xl mx-auto px-6 py-8">
        {/* Summary table */}
        <SummaryTable entries={data.entries} />

        {/* Main layout: sidebar + content */}
        <div className="flex flex-col lg:flex-row gap-8">
          <Sidebar
            phases={data.phases}
            allSequences={allSequences}
            activePhase={activePhase}
            activeSequence={activeSequence}
            search={search}
            onPhaseChange={setActivePhase}
            onSequenceChange={setActiveSequence}
            onSearchChange={setSearch}
          />

          {/* Content */}
          <main className="flex-1 min-w-0 space-y-10">
            {groupedByPhase.length === 0 && (
              <div className="text-center py-16 text-zinc-500">
                No primitives match your filters.
              </div>
            )}

            {groupedByPhase.map(({ phase, info, entries }) => (
              <section key={phase}>
                <div className="mb-4">
                  <h2 className={`text-xl font-bold ${phaseColor(phase).text}`}>
                    {info.name}
                  </h2>
                  <p className="text-zinc-500 text-sm">{info.description}</p>
                </div>
                <div className="space-y-3">
                  {entries.map((entry) => (
                    <PrimitiveCard
                      key={entry.primitive}
                      entry={entry}
                      expanded={expandedPrimitive === entry.primitive}
                      onToggle={() => toggleExpand(entry.primitive)}
                    />
                  ))}
                </div>
              </section>
            ))}
          </main>
        </div>
      </div>
    </div>
  );
}
