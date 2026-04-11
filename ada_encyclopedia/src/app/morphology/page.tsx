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
  const snapshots = data?.snapshots ?? [];
  const stageNames = Object.keys(stages).sort();

  const selectedStageData = selectedStage ? stages[selectedStage] : null;

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
            {snapshots.length} creature snapshots
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

            {/* Creature snapshots */}
            <Card title="Creature Snapshots">
              {snapshots.length > 0 ? (
                <div className="space-y-2">
                  {snapshots
                    .slice()
                    .reverse()
                    .slice(0, 8)
                    .map((s, i) => (
                      <div
                        key={i}
                        className="px-3 py-2 rounded bg-zinc-900/60 border border-zinc-700/30"
                      >
                        <div className="flex items-center justify-between mb-1">
                          <span className="text-sm text-zinc-200">
                            {s.auto_name || "Unknown"}
                          </span>
                          <span className="text-xs text-zinc-600">
                            {s.form_taxonomy || "—"}
                          </span>
                        </div>
                        <div className="text-xs text-zinc-500">
                          {s.biome_stage && (
                            <span>Stage: {s.biome_stage} | </span>
                          )}
                          seg={s.segments?.toFixed(0)} sym=
                          {s.symmetry?.toFixed(0)} scale=
                          {s.scale?.toFixed(1)}
                        </div>
                      </div>
                    ))}
                </div>
              ) : (
                <div className="text-zinc-500 text-sm">
                  No snapshots yet. Use the &quot;Export DNA&quot; button in the
                  Godot Creature Editor to save creatures here.
                </div>
              )}
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
