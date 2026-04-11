"use client";

import { useEffect, useState, useCallback } from "react";

// ── Types ────────────────────────────────────────────────────────
interface TaxonomyEntry {
  id: string;
  label: string;
  range: [number, number];
  f: string;
  e: string;
  phi: string;
  bio: string;
  math: string;
  color: string;
}

interface CurriculumEntry {
  stage: number;
  algorithm: string;
  form: string;
}

interface SoftStage {
  nature_kingdoms: string[];
  vegetation_density: number;
  terrain_mode: string;
  ambient_preset?: string;
  capacity_level?: number;
}

interface Snapshot {
  auto_name?: string;
  body_type?: number;
  form_process?: number;
  form_taxonomy?: string;
  biome_stage?: string;
  export_time?: string;
  segments?: number;
  symmetry?: number;
  scale?: number;
  skeleton_complexity?: number;
  surface_method?: number;
  modularity?: number;
  recursion_depth?: number;
}

interface MorphologyData {
  taxonomy: TaxonomyEntry[];
  curriculum: CurriculumEntry[];
  softStages: Record<string, SoftStage> | null;
  snapshots: Snapshot[];
}

// ── Color helpers ────────────────────────────────────────────────
const KINGDOM_COLORS: Record<string, string> = {
  tree: "bg-emerald-500",
  creature: "bg-pink-500",
  flower: "bg-rose-400",
  fungus: "bg-violet-500",
};

const KINGDOM_DOT_COLORS: Record<string, string> = {
  tree: "#10b981",
  creature: "#ec4899",
  flower: "#fb7185",
  fungus: "#8b5cf6",
};

const MOCK_SNAPSHOTS: Snapshot[] = [
  {
    auto_name: "Large Leafy Tree", body_type: 0.1, form_process: 0.05,
    form_taxonomy: "Grown", skeleton_complexity: 0.8, surface_method: 0.1,
    modularity: 0.3, recursion_depth: 0.6, segments: 5, symmetry: 3, scale: 1.5,
    biome_stage: "lsystems",
  },
  {
    auto_name: "Swift Curious Creature", body_type: 1.2, form_process: 0.3,
    form_taxonomy: "Extruded", skeleton_complexity: 0.5, surface_method: 0.0,
    modularity: 0.6, recursion_depth: 0.2, segments: 6, symmetry: 2, scale: 0.8,
    biome_stage: "swarmintelligence",
  },
  {
    auto_name: "Shimmering Complex Flower", body_type: 2.0, form_process: 0.25,
    form_taxonomy: "Extruded", skeleton_complexity: 0.2, surface_method: 0.15,
    modularity: 0.4, recursion_depth: 0.1, segments: 3, symmetry: 8, scale: 0.6,
    biome_stage: "noise",
  },
  {
    auto_name: "Colonial Ghostly Fungus", body_type: 3.1, form_process: 0.1,
    form_taxonomy: "Grown", skeleton_complexity: 0.3, surface_method: 0.3,
    modularity: 0.5, recursion_depth: 0.15, segments: 2, symmetry: 6, scale: 0.7,
    biome_stage: "cellularautomata",
  },
  {
    auto_name: "Strange Hybrid", body_type: 1.7, form_process: 0.55,
    form_taxonomy: "Carved", skeleton_complexity: 0.6, surface_method: 0.5,
    modularity: 0.7, recursion_depth: 0.4, segments: 8, symmetry: 4, scale: 1.2,
    biome_stage: "machinelearning",
  },
];

// ── SVG Helpers ─────────────────────────────────────────────────
function polarToCartesian(cx: number, cy: number, r: number, angleDeg: number) {
  const rad = ((angleDeg - 90) * Math.PI) / 180;
  return { x: cx + r * Math.cos(rad), y: cy + r * Math.sin(rad) };
}

// ── DonutChart ──────────────────────────────────────────────────
function DonutChart({
  data,
  size = 160,
}: {
  data: { label: string; value: number; color: string }[];
  size?: number;
}) {
  const cx = size / 2;
  const cy = size / 2;
  const outerR = size / 2 - 4;
  const innerR = outerR * 0.4;
  const total = data.reduce((s, d) => s + d.value, 0);
  if (total === 0) return null;

  let cumAngle = 0;
  const segments = data
    .filter((d) => d.value > 0)
    .map((d) => {
      const sweep = (d.value / total) * 360;
      const startAngle = cumAngle;
      const endAngle = cumAngle + sweep;
      cumAngle = endAngle;
      const outerStart = polarToCartesian(cx, cy, outerR, startAngle);
      const outerEnd = polarToCartesian(cx, cy, outerR, endAngle);
      const innerEnd = polarToCartesian(cx, cy, innerR, endAngle);
      const innerStart = polarToCartesian(cx, cy, innerR, startAngle);
      const largeFlag = sweep > 180 ? "1" : "0";
      const path = [
        `M ${outerStart.x} ${outerStart.y}`,
        `A ${outerR} ${outerR} 0 ${largeFlag} 1 ${outerEnd.x} ${outerEnd.y}`,
        `L ${innerEnd.x} ${innerEnd.y}`,
        `A ${innerR} ${innerR} 0 ${largeFlag} 0 ${innerStart.x} ${innerStart.y}`,
        "Z",
      ].join(" ");
      return { ...d, path, sweep };
    });

  return (
    <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
      {segments.map((seg, i) => (
        <path key={i} d={seg.path} fill={seg.color} opacity={0.85} stroke="#18181b" strokeWidth={1.5} />
      ))}
      <text x={cx} y={cy - 6} textAnchor="middle" fill="#d4d4d8" fontSize={18} fontWeight="bold">
        {total}
      </text>
      <text x={cx} y={cy + 10} textAnchor="middle" fill="#71717a" fontSize={9}>
        creatures
      </text>
    </svg>
  );
}

// ── GeneHistogram ───────────────────────────────────────────────
function GeneHistogram({
  values,
  bins = 10,
  color = "#22d3ee",
  label = "",
}: {
  values: number[];
  bins?: number;
  color?: string;
  label?: string;
}) {
  const w = 280;
  const h = 80;
  const pad = { top: label ? 16 : 4, bottom: 16, left: 4, right: 4 };
  const chartW = w - pad.left - pad.right;
  const chartH = h - pad.top - pad.bottom;

  // Bin the values (0-1 range)
  const counts = new Array(bins).fill(0);
  for (const v of values) {
    const idx = Math.min(Math.floor(v * bins), bins - 1);
    counts[idx]++;
  }
  const maxCount = Math.max(...counts, 1);
  const barW = chartW / bins;

  return (
    <svg width={w} height={h} viewBox={`0 0 ${w} ${h}`}>
      {label && (
        <text x={pad.left} y={12} fill="#a1a1aa" fontSize={10}>{label}</text>
      )}
      {counts.map((c, i) => {
        const barH = (c / maxCount) * chartH;
        const opacity = 0.4 + (i / bins) * 0.5;
        return (
          <rect
            key={i}
            x={pad.left + i * barW + 1}
            y={pad.top + chartH - barH}
            width={barW - 2}
            height={barH}
            fill={color}
            opacity={opacity}
            rx={1}
          />
        );
      })}
      <text x={pad.left} y={h - 2} fill="#52525b" fontSize={8}>0.0</text>
      <text x={w - pad.right} y={h - 2} fill="#52525b" fontSize={8} textAnchor="end">1.0</text>
    </svg>
  );
}

// ── ProcessRadar ────────────────────────────────────────────────
function ProcessRadar({
  genes,
  size = 140,
}: {
  genes: { label: string; value: number }[];
  size?: number;
}) {
  const cx = size / 2;
  const cy = size / 2;
  const maxR = size / 2 - 20;
  const n = genes.length;
  if (n < 3) return null;

  const angleStep = (2 * Math.PI) / n;
  const getPoint = (index: number, radius: number) => ({
    x: cx + radius * Math.sin(index * angleStep),
    y: cy - radius * Math.cos(index * angleStep),
  });

  // Grid rings
  const rings = [0.25, 0.5, 0.75, 1.0];

  // Value polygon
  const valuePoints = genes
    .map((g, i) => {
      const p = getPoint(i, g.value * maxR);
      return `${p.x},${p.y}`;
    })
    .join(" ");

  return (
    <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
      {/* Grid rings */}
      {rings.map((r) => {
        const pts = Array.from({ length: n }, (_, i) => {
          const p = getPoint(i, r * maxR);
          return `${p.x},${p.y}`;
        }).join(" ");
        return (
          <polygon key={r} points={pts} fill="none" stroke="#3f3f46" strokeWidth={0.5} />
        );
      })}
      {/* Spokes */}
      {genes.map((_, i) => {
        const p = getPoint(i, maxR);
        return <line key={i} x1={cx} y1={cy} x2={p.x} y2={p.y} stroke="#3f3f46" strokeWidth={0.5} />;
      })}
      {/* Value polygon */}
      <polygon points={valuePoints} fill="#22d3ee" fillOpacity={0.2} stroke="#22d3ee" strokeWidth={1.5} />
      {/* Value dots */}
      {genes.map((g, i) => {
        const p = getPoint(i, g.value * maxR);
        return <circle key={i} cx={p.x} cy={p.y} r={2} fill="#22d3ee" />;
      })}
      {/* Labels */}
      {genes.map((g, i) => {
        const p = getPoint(i, maxR + 12);
        return (
          <text
            key={i}
            x={p.x}
            y={p.y}
            textAnchor="middle"
            dominantBaseline="middle"
            fill="#a1a1aa"
            fontSize={size > 100 ? 8 : 6}
          >
            {g.label}
          </text>
        );
      })}
    </svg>
  );
}

// ── Kingdom helpers ─────────────────────────────────────────────
function getKingdomFromBodyType(bodyType?: number): string {
  if (bodyType === undefined) return "creature";
  if (bodyType < 1) return "tree";
  if (bodyType < 2) return "creature";
  if (bodyType < 3) return "flower";
  return "fungus";
}

function Card({
  title,
  children,
  className = "",
}: {
  title: string;
  children: React.ReactNode;
  className?: string;
}) {
  return (
    <div
      className={`rounded-lg border border-zinc-700/50 bg-zinc-800/50 ${className}`}
    >
      <div className="px-4 py-3 border-b border-zinc-700/30">
        <h3 className="text-sm font-medium text-zinc-300 uppercase tracking-wider">
          {title}
        </h3>
      </div>
      <div className="p-4">{children}</div>
    </div>
  );
}

// ── Main Page ────────────────────────────────────────────────────
export default function MorphologyDashboard() {
  const [data, setData] = useState<MorphologyData | null>(null);
  const [loading, setLoading] = useState(true);
  const [selectedStage, setSelectedStage] = useState<string | null>(null);

  const fetchData = useCallback(async () => {
    try {
      setLoading(true);
      const res = await fetch("/api/morphology");
      if (!res.ok) throw new Error(`API error: ${res.status}`);
      const json = await res.json();
      setData(json);
    } catch {
      // silent
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  if (loading && !data) {
    return (
      <div className="min-h-screen bg-zinc-900 flex items-center justify-center">
        <div className="text-zinc-400 animate-pulse">
          Loading morphology data...
        </div>
      </div>
    );
  }

  const taxonomy = data?.taxonomy ?? [];
  const curriculum = data?.curriculum ?? [];
  const stages = data?.softStages ?? {};
  const rawSnapshots = data?.snapshots ?? [];
  const usingMockData = rawSnapshots.length === 0;
  const snapshots = usingMockData ? MOCK_SNAPSHOTS : rawSnapshots;
  const stageNames = Object.keys(stages).sort();

  const selectedStageData = selectedStage ? stages[selectedStage] : null;

  // Kingdom counts for population chart
  const kingdomCounts: Record<string, number> = {};
  for (const s of snapshots) {
    const k = getKingdomFromBodyType(s.body_type);
    kingdomCounts[k] = (kingdomCounts[k] || 0) + 1;
  }
  const donutData = Object.entries(kingdomCounts).map(([label, value]) => ({
    label,
    value,
    color: KINGDOM_DOT_COLORS[label] || "#666",
  }));
  const mostCommonKingdom = donutData.sort((a, b) => b.value - a.value)[0]?.label || "none";

  return (
    <div className="min-h-screen bg-zinc-900 text-zinc-100">
      {/* Header */}
      <header className="border-b border-zinc-800 px-6 py-4">
        <div className="max-w-7xl mx-auto">
          <h1 className="text-xl font-semibold tracking-tight">
            Morphology{" "}
            <span className="text-zinc-500 font-normal">
              Form as Process
            </span>
          </h1>
          <p className="text-xs text-zinc-500 mt-1">
            {taxonomy.length} processes | {stageNames.length} biome stages |{" "}
            {snapshots.length} creature snapshots{usingMockData ? " (sample)" : ""}
          </p>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-6 py-6">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
          {/* ── Left: Form Taxonomy ────────────────────────── */}
          <div className="space-y-4">
            <Card title="Form Process Taxonomy">
              <div className="space-y-3">
                {taxonomy.map((t) => (
                  <div
                    key={t.id}
                    className="rounded-lg border border-zinc-700/30 bg-zinc-900/60 p-3"
                  >
                    <div className="flex items-center gap-2 mb-2">
                      <div
                        className="w-3 h-3 rounded-full shrink-0"
                        style={{ backgroundColor: t.color }}
                      />
                      <span className="text-sm font-medium text-zinc-200">
                        {t.label}
                      </span>
                      {t.range[0] >= 0 && (
                        <span className="text-xs text-zinc-600 ml-auto">
                          {t.range[0].toFixed(1)}–{t.range[1].toFixed(1)}
                        </span>
                      )}
                    </div>
                    <div className="grid grid-cols-3 gap-1 text-xs mb-2">
                      <div className="text-center">
                        <div className="text-cyan-400 font-medium">F</div>
                        <div className="text-zinc-500">{t.f}</div>
                      </div>
                      <div className="text-center">
                        <div className="text-amber-400 font-medium">E</div>
                        <div className="text-zinc-500">{t.e}</div>
                      </div>
                      <div className="text-center">
                        <div className="text-violet-400 font-medium">
                          &phi;
                        </div>
                        <div className="text-zinc-500">{t.phi}</div>
                      </div>
                    </div>
                    <div className="text-xs text-zinc-500">
                      <span className="text-zinc-400">{t.bio}</span>
                    </div>
                    <div className="text-xs text-zinc-600 mt-0.5">
                      {t.math}
                    </div>
                  </div>
                ))}
              </div>
            </Card>

            {/* Curriculum */}
            <Card title="Curriculum Progression">
              <div className="space-y-1">
                {curriculum.map((c) => (
                  <div
                    key={c.stage}
                    className="flex items-center gap-3 text-xs py-1"
                  >
                    <span className="text-cyan-400 font-bold w-4 text-right">
                      {c.stage}
                    </span>
                    <span className="text-zinc-400 w-28 truncate">
                      {c.algorithm}
                    </span>
                    <span className="text-zinc-300 flex-1 truncate">
                      {c.form}
                    </span>
                  </div>
                ))}
              </div>
            </Card>
          </div>

          {/* ── Center: Biome Progression ──────────────────── */}
          <div className="space-y-4">
            <Card title="Biome Progression">
              <div className="space-y-1">
                {stageNames.map((name, i) => {
                  const stage = stages[name];
                  if (!stage) return null;
                  const isSelected = selectedStage === name;
                  const kingdoms = stage.nature_kingdoms || [];
                  const density = stage.vegetation_density || 0;

                  return (
                    <button
                      key={name}
                      onClick={() =>
                        setSelectedStage(isSelected ? null : name)
                      }
                      className={`w-full text-left px-3 py-2 rounded transition-colors ${
                        isSelected
                          ? "bg-cyan-900/30 border border-cyan-700/50"
                          : "hover:bg-zinc-800/60"
                      }`}
                    >
                      <div className="flex items-center gap-2">
                        <span className="text-xs text-zinc-600 w-4 text-right">
                          {i + 1}
                        </span>
                        <span className="text-sm text-zinc-300 flex-1 truncate">
                          {name}
                        </span>
                        {/* Kingdom dots */}
                        <div className="flex gap-0.5">
                          {kingdoms.map((k: string) => (
                            <div
                              key={k}
                              className="w-2 h-2 rounded-full"
                              style={{
                                backgroundColor:
                                  KINGDOM_DOT_COLORS[k] || "#666",
                              }}
                              title={k}
                            />
                          ))}
                        </div>
                        {/* Density bar */}
                        <div className="w-12 h-1.5 bg-zinc-800 rounded-full overflow-hidden">
                          <div
                            className="h-full bg-emerald-500/60 rounded-full"
                            style={{ width: `${density * 100}%` }}
                          />
                        </div>
                      </div>
                    </button>
                  );
                })}
              </div>
            </Card>

            {/* Selected stage detail */}
            {selectedStageData && (
              <Card title={selectedStage || "Stage"}>
                <div className="space-y-3 text-sm">
                  <div>
                    <div className="text-xs text-zinc-500 uppercase mb-1">
                      Kingdoms
                    </div>
                    <div className="flex gap-2">
                      {(selectedStageData.nature_kingdoms || []).map(
                        (k: string) => (
                          <span
                            key={k}
                            className={`px-2 py-0.5 rounded text-xs text-white ${
                              KINGDOM_COLORS[k] || "bg-zinc-600"
                            }`}
                          >
                            {k}
                          </span>
                        )
                      )}
                      {(selectedStageData.nature_kingdoms || []).length ===
                        0 && (
                        <span className="text-zinc-600 text-xs italic">
                          No organisms yet
                        </span>
                      )}
                    </div>
                  </div>
                  <div className="grid grid-cols-2 gap-2 text-xs">
                    <div>
                      <span className="text-zinc-500">Density: </span>
                      <span className="text-emerald-400">
                        {Math.round(
                          (selectedStageData.vegetation_density || 0) * 100
                        )}
                        %
                      </span>
                    </div>
                    <div>
                      <span className="text-zinc-500">Terrain: </span>
                      <span className="text-zinc-300">
                        {selectedStageData.terrain_mode || "flat"}
                      </span>
                    </div>
                  </div>
                </div>
              </Card>
            )}

            {/* Population */}
            <Card title="Population">
              {snapshots.length > 0 ? (
                <div className="flex flex-col items-center gap-3">
                  {usingMockData && (
                    <span className="text-xs text-zinc-600 italic">(sample data)</span>
                  )}
                  <DonutChart data={donutData} size={160} />
                  <div className="flex flex-wrap justify-center gap-3 text-xs">
                    {donutData.map((d) => (
                      <div key={d.label} className="flex items-center gap-1.5">
                        <div className="w-2.5 h-2.5 rounded-full" style={{ backgroundColor: d.color }} />
                        <span className="text-zinc-400">{d.label}</span>
                        <span className="text-zinc-500">{d.value}</span>
                      </div>
                    ))}
                  </div>
                  <div className="text-xs text-zinc-500 text-center">
                    {snapshots.length} creatures | most common: <span className="text-zinc-300">{mostCommonKingdom}</span>
                  </div>
                </div>
              ) : (
                <div className="text-zinc-500 text-sm">
                  Export creatures from Godot to see population data
                </div>
              )}
            </Card>
          </div>

          {/* ── Right: Gene Space + Snapshots ──────────────── */}
          <div className="space-y-4">
            {/* Process genes */}
            <Card title="Process Genes">
              <div className="space-y-3">
                {[
                  {
                    id: "form_process",
                    label: "Form Process",
                    desc: "grown → extruded → carved → folded → crystallized",
                  },
                  {
                    id: "skeleton_complexity",
                    label: "Skeleton",
                    desc: "none → spine → branching → recursive",
                  },
                  {
                    id: "surface_method",
                    label: "Surface",
                    desc: "sweep → revolution → SDF → primitive → particle",
                  },
                  {
                    id: "modularity",
                    label: "Modularity",
                    desc: "monolithic → segmented → modular",
                  },
                  {
                    id: "recursion_depth",
                    label: "Recursion",
                    desc: "flat → shallow → deep",
                  },
                ].map((gene) => (
                  <div key={gene.id}>
                    <div className="flex items-center justify-between mb-1">
                      <span className="text-xs text-zinc-300 font-medium">
                        {gene.label}
                      </span>
                      <span className="text-xs text-zinc-600">0.0 – 1.0</span>
                    </div>
                    <div className="h-2 bg-zinc-800 rounded-full overflow-hidden">
                      <div
                        className="h-full rounded-full"
                        style={{
                          width: "50%",
                          background:
                            "linear-gradient(90deg, #22d3ee, #a78bfa, #f59e0b, #ec4899, #06b6d4)",
                        }}
                      />
                    </div>
                    <div className="text-xs text-zinc-600 mt-0.5">
                      {gene.desc}
                    </div>
                  </div>
                ))}
              </div>
              <p className="text-xs text-zinc-600 mt-3 italic">
                Edit these genes in the Godot Creature Editor (Pipeline mode)
              </p>
            </Card>

            {/* Gene distribution histograms */}
            {snapshots.length > 0 && (
              <Card title={`Gene Distribution${usingMockData ? " (sample)" : ""}`}>
                <div className="space-y-2">
                  <GeneHistogram
                    values={snapshots.map((s) => s.form_process ?? 0)}
                    color="#22d3ee"
                    label="Form Process"
                  />
                  <GeneHistogram
                    values={snapshots.map((s) => s.skeleton_complexity ?? 0)}
                    color="#a78bfa"
                    label="Skeleton Complexity"
                  />
                  <GeneHistogram
                    values={snapshots.map((s) => s.modularity ?? 0)}
                    color="#f59e0b"
                    label="Modularity"
                  />
                </div>
              </Card>
            )}

            {/* Creature snapshots */}
            <Card title={`Creature Snapshots${usingMockData ? " (sample data)" : ""}`}>
              <div className="space-y-3">
                {snapshots
                  .slice()
                  .reverse()
                  .slice(0, 8)
                  .map((s, i) => {
                    const kingdom = getKingdomFromBodyType(s.body_type);
                    const radarGenes = [
                      { label: "Form", value: s.form_process ?? 0 },
                      { label: "Skel", value: s.skeleton_complexity ?? 0 },
                      { label: "Surf", value: s.surface_method ?? 0 },
                      { label: "Mod", value: s.modularity ?? 0 },
                      { label: "Rec", value: s.recursion_depth ?? 0 },
                    ];
                    return (
                      <div
                        key={i}
                        className="rounded-lg bg-zinc-900/60 border border-zinc-700/30 p-3"
                      >
                        <div className="flex items-start gap-3">
                          {/* Mini radar */}
                          <div className="shrink-0">
                            <ProcessRadar genes={radarGenes} size={80} />
                          </div>
                          <div className="flex-1 min-w-0">
                            {/* Name + kingdom badge */}
                            <div className="flex items-center gap-2 mb-1">
                              <span className="text-sm font-medium text-zinc-200 truncate">
                                {s.auto_name || "Unknown"}
                              </span>
                              <span className="flex items-center gap-1 shrink-0">
                                <div
                                  className="w-2 h-2 rounded-full"
                                  style={{ backgroundColor: KINGDOM_DOT_COLORS[kingdom] || "#666" }}
                                />
                                <span className="text-xs text-zinc-500">{kingdom}</span>
                              </span>
                            </div>
                            {/* Form taxonomy label */}
                            <div className="text-xs text-zinc-400 mb-1.5">
                              {s.form_taxonomy || "Unclassified"}
                            </div>
                            {/* Stats */}
                            <div className="flex gap-3 text-xs text-zinc-500">
                              <span>seg <span className="text-zinc-300">{s.segments ?? 0}</span></span>
                              <span>sym <span className="text-zinc-300">{s.symmetry ?? 0}</span></span>
                              <span>scale <span className="text-zinc-300">{(s.scale ?? 1).toFixed(1)}</span></span>
                            </div>
                          </div>
                        </div>
                      </div>
                    );
                  })}
              </div>
            </Card>

            {/* QFEP connection */}
            <Card title="QFEP Connection">
              <div className="space-y-2 text-xs text-zinc-400">
                <div>
                  <span className="text-cyan-400 font-medium">F</span> ={" "}
                  Crystallized forms (rigid lattice, max stability)
                </div>
                <div>
                  <span className="text-amber-400 font-medium">
                    -&lambda;E(S)
                  </span>{" "}
                  = Dissolved forms (reaction-diffusion, max entropy)
                </div>
                <div>
                  <span className="text-violet-400 font-medium">
                    &phi;&Delta;E
                  </span>{" "}
                  = Fold system (spring velocity, tension, misfold rate)
                </div>
                <div className="text-zinc-600 mt-2 italic">
                  The mesh IS the Markov blanket — the boundary between internal
                  (DNA) and external (world)
                </div>
              </div>
            </Card>
          </div>
        </div>
      </main>
    </div>
  );
}
