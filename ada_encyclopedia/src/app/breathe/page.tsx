"use client";

import { useEffect, useState, useCallback } from "react";

// ── Types ────────────────────────────────────────────────────────
interface BreathEntry {
  breath_id: string;
  mode: string;
  baseline_avg: number;
  post_avg: number;
  delta: number;
  items_attempted: string[];
  items_succeeded: string[];
  items_failed: string[];
  failure_reasons: Record<string, string>;
  skills_used: string[];
  skill_effectiveness: Record<
    string,
    { calls: number; succeeded: number; failed?: number }
  >;
  discoveries: string[];
  files_changed?: string[];
  duration_minutes: number;
}

interface HeatItem {
  item: string;
  temperature: number;
  reason: string;
  action: string;
}

interface Proposal {
  id: string;
  created: string;
  skill: string;
  status: string;
  evidence: string;
  proposed_change: string;
  expected_improvement: string;
  breath_refs: string[];
}

interface BreatheData {
  breathLog: { breaths: BreathEntry[] } | null;
  trajectory: {
    total_breaths: number;
    global_avg_history: { date: string; avg: number }[];
    skill_effectiveness_cumulative: Record<
      string,
      { total_calls: number; success_rate: number; avg_delta: number }
    >;
    stall_detected: boolean;
    stall_reason: string | null;
  } | null;
  proposals: { proposals: Proposal[] } | null;
  heatMap: { items: HeatItem[]; generated: string } | null;
  focusVector: {
    current_focus: {
      primary: string;
      secondary: string[];
      blocked: string[];
      energy: string;
    };
  } | null;
}

interface ToolResult {
  action: string;
  code: number | null;
  stdout: string;
  stderr: string;
}

// ── Color helpers ────────────────────────────────────────────────
function tempColor(t: number): string {
  if (t >= 90) return "text-red-400";
  if (t >= 70) return "text-orange-400";
  if (t >= 50) return "text-amber-400";
  if (t >= 30) return "text-yellow-300";
  return "text-zinc-400";
}

function tempBg(t: number): string {
  if (t >= 90) return "bg-red-900/30";
  if (t >= 70) return "bg-orange-900/30";
  if (t >= 50) return "bg-amber-900/20";
  return "bg-zinc-800/50";
}

function deltaBadge(d: number): string {
  if (d > 0) return "text-emerald-400";
  if (d < 0) return "text-red-400";
  return "text-zinc-500";
}

const STAGE_COLORS: Record<string, string> = {
  "stage 1": "bg-zinc-700",
  "stage 2": "bg-blue-800",
  "stage 3": "bg-violet-800",
  "stage 4": "bg-amber-800",
  "stage 5": "bg-orange-800",
  "stage 6": "bg-emerald-800",
  "stage 7": "bg-cyan-800",
  documentation: "bg-blue-800",
  artifacts: "bg-violet-800",
  maps: "bg-amber-800",
  validation: "bg-orange-800",
  "vr testing": "bg-emerald-800",
  polish: "bg-cyan-800",
};

function stageColor(stage: string): string {
  const lower = stage.toLowerCase();
  for (const [key, val] of Object.entries(STAGE_COLORS)) {
    if (lower.includes(key)) return val;
  }
  return "bg-zinc-700";
}

// ── SVG Sparkline ────────────────────────────────────────────────
function Sparkline({
  data,
  width = 280,
  height = 80,
}: {
  data: { date: string; avg: number }[];
  width?: number;
  height?: number;
}) {
  if (data.length < 2) {
    return (
      <div className="text-zinc-500 text-sm italic">
        Need 2+ breaths for trajectory
      </div>
    );
  }

  const vals = data.map((d) => d.avg);
  const min = Math.min(...vals) * 0.9;
  const max = Math.max(...vals) * 1.1 || 1;
  const pad = 8;
  const w = width - pad * 2;
  const h = height - pad * 2;

  const points = data
    .map((d, i) => {
      const x = pad + (i / (data.length - 1)) * w;
      const y = pad + h - ((d.avg - min) / (max - min)) * h;
      return `${x},${y}`;
    })
    .join(" ");

  const lastVal = vals[vals.length - 1];
  const prevVal = vals[vals.length - 2];
  const trend = lastVal > prevVal ? "+" : lastVal < prevVal ? "" : "";

  return (
    <div>
      <svg
        viewBox={`0 0 ${width} ${height}`}
        className="w-full"
        style={{ maxWidth: width }}
      >
        <polyline
          points={points}
          fill="none"
          stroke="#22d3ee"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
        {data.map((d, i) => {
          const x = pad + (i / (data.length - 1)) * w;
          const y = pad + h - ((d.avg - min) / (max - min)) * h;
          return (
            <circle key={i} cx={x} cy={y} r="3" fill="#22d3ee" opacity={0.8} />
          );
        })}
        {/* min/max labels */}
        <text x={width - pad} y={pad + 4} textAnchor="end" className="fill-zinc-500" fontSize="10">
          {max.toFixed(1)}
        </text>
        <text x={width - pad} y={height - 2} textAnchor="end" className="fill-zinc-500" fontSize="10">
          {min.toFixed(1)}
        </text>
      </svg>
      <div className="text-xs text-zinc-400 mt-1">
        Latest: <span className="text-cyan-400">{lastVal.toFixed(2)}</span>
        {" "}
        <span className={deltaBadge(lastVal - prevVal)}>
          ({trend}{(lastVal - prevVal).toFixed(2)})
        </span>
      </div>
    </div>
  );
}

// ── Bar helper ───────────────────────────────────────────────────
function Bar({
  value,
  max,
  color = "bg-cyan-500",
  label,
}: {
  value: number;
  max: number;
  color?: string;
  label?: string;
}) {
  const pct = max > 0 ? Math.min((value / max) * 100, 100) : 0;
  return (
    <div className="flex items-center gap-2">
      {label && (
        <span className="text-xs text-zinc-400 w-16 shrink-0 truncate">
          {label}
        </span>
      )}
      <div className="flex-1 h-2 bg-zinc-800 rounded-full overflow-hidden">
        <div
          className={`h-full ${color} rounded-full transition-all`}
          style={{ width: `${pct}%` }}
        />
      </div>
      <span className="text-xs text-zinc-500 w-10 text-right">
        {Math.round(pct)}%
      </span>
    </div>
  );
}

// ── Card wrapper ─────────────────────────────────────────────────
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
export default function BreatheDashboard() {
  const [data, setData] = useState<BreatheData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [toolRunning, setToolRunning] = useState<string | null>(null);
  const [toolResult, setToolResult] = useState<ToolResult | null>(null);
  const [expandedBreath, setExpandedBreath] = useState<string | null>(null);

  const fetchData = useCallback(async () => {
    try {
      setLoading(true);
      const res = await fetch("/api/breathe");
      if (!res.ok) throw new Error(`API error: ${res.status}`);
      const json = await res.json();
      setData(json);
      setError(null);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to load data");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const runTool = useCallback(
    async (action: string) => {
      setToolRunning(action);
      setToolResult(null);
      try {
        const res = await fetch("/api/breathe", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ action }),
        });
        const json = await res.json();
        setToolResult(json);
        // Refresh data after tool run
        await fetchData();
      } catch (e) {
        setToolResult({
          action,
          code: -1,
          stdout: "",
          stderr: e instanceof Error ? e.message : "Unknown error",
        });
      } finally {
        setToolRunning(null);
      }
    },
    [fetchData]
  );

  // ── Render ───────────────────────────────────────────────────
  if (loading && !data) {
    return (
      <div className="min-h-screen bg-zinc-900 flex items-center justify-center">
        <div className="text-zinc-400 animate-pulse">Loading BREATHE data...</div>
      </div>
    );
  }

  if (error && !data) {
    return (
      <div className="min-h-screen bg-zinc-900 flex items-center justify-center">
        <div className="text-red-400">{error}</div>
      </div>
    );
  }

  const breaths = data?.breathLog?.breaths ?? [];
  const trajectory = data?.trajectory;
  const heatItems = data?.heatMap?.items ?? [];
  const focus = data?.focusVector?.current_focus;
  const proposals = data?.proposals?.proposals ?? [];
  const skillStats = trajectory?.skill_effectiveness_cumulative ?? {};

  return (
    <div className="min-h-screen bg-zinc-900 text-zinc-100">
      {/* ── Header ──────────────────────────────────────────── */}
      <header className="border-b border-zinc-800 px-6 py-4">
        <div className="max-w-7xl mx-auto flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <div>
            <h1 className="text-xl font-semibold tracking-tight">
              BREATHE{" "}
              <span className="text-zinc-500 font-normal">
                Self-Improving Agent
              </span>
            </h1>
            <p className="text-xs text-zinc-500 mt-1">
              {breaths.length} breaths recorded
              {trajectory?.stall_detected && (
                <span className="text-amber-400 ml-2">
                  Stall detected: {trajectory.stall_reason}
                </span>
              )}
            </p>
          </div>

          <div className="flex items-center gap-2">
            {(["score", "heatmap", "garden", "gates"] as const).map((action) => (
              <button
                key={action}
                onClick={() => runTool(action)}
                disabled={toolRunning !== null}
                className={`px-3 py-1.5 rounded text-xs font-medium transition-colors ${
                  toolRunning === action
                    ? "bg-cyan-800 text-cyan-200 animate-pulse"
                    : "bg-zinc-800 text-zinc-300 hover:bg-zinc-700 hover:text-zinc-100"
                } disabled:opacity-50`}
              >
                {toolRunning === action ? "Running..." : action}
              </button>
            ))}
            <button
              onClick={fetchData}
              disabled={loading}
              className="px-3 py-1.5 rounded text-xs font-medium bg-cyan-900/50 text-cyan-300 hover:bg-cyan-800/50 transition-colors disabled:opacity-50"
            >
              {loading ? "..." : "Refresh"}
            </button>
          </div>
        </div>
      </header>

      {/* ── Tool result banner ──────────────────────────────── */}
      {toolResult && (
        <div className="border-b border-zinc-800 px-6 py-3 bg-zinc-800/50">
          <div className="max-w-7xl mx-auto">
            <div className="flex items-start justify-between gap-4">
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 mb-1">
                  <span className="text-xs font-medium text-zinc-300">
                    {toolResult.action}
                  </span>
                  <span
                    className={`text-xs ${
                      toolResult.code === 0
                        ? "text-emerald-400"
                        : "text-red-400"
                    }`}
                  >
                    exit {toolResult.code}
                  </span>
                </div>
                <pre className="text-xs text-zinc-400 whitespace-pre-wrap max-h-32 overflow-y-auto font-mono">
                  {toolResult.stdout || toolResult.stderr || "(no output)"}
                </pre>
              </div>
              <button
                onClick={() => setToolResult(null)}
                className="text-zinc-500 hover:text-zinc-300 text-xs shrink-0"
              >
                dismiss
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ── Dashboard grid ──────────────────────────────────── */}
      <main className="max-w-7xl mx-auto px-6 py-6">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
          {/* ── Left column ───────────────────────────────── */}
          <div className="space-y-4">
            {/* Trajectory */}
            <Card title="Trajectory">
              {trajectory &&
              trajectory.global_avg_history &&
              trajectory.global_avg_history.length > 0 ? (
                <Sparkline data={trajectory.global_avg_history} />
              ) : (
                <div className="text-zinc-500 text-sm">
                  No trajectory data yet. Run a full breath to start tracking.
                </div>
              )}
            </Card>

            {/* Heat Map */}
            <Card title="Heat Map">
              {heatItems.length > 0 ? (
                <div className="space-y-2">
                  {heatItems.map((item, i) => (
                    <div
                      key={i}
                      className={`flex items-center gap-3 px-3 py-2 rounded ${tempBg(
                        item.temperature
                      )}`}
                    >
                      <span
                        className={`text-lg font-bold w-10 text-right ${tempColor(
                          item.temperature
                        )}`}
                      >
                        {item.temperature}
                      </span>
                      <div className="flex-1 min-w-0">
                        <div className="text-sm text-zinc-200 truncate">
                          {item.item}
                        </div>
                        <div className="text-xs text-zinc-500 truncate">
                          {item.reason}
                        </div>
                      </div>
                      <span className="text-xs text-zinc-500 shrink-0">
                        {item.action}
                      </span>
                    </div>
                  ))}
                  <div className="text-xs text-zinc-600 mt-1">
                    Generated:{" "}
                    {data?.heatMap?.generated
                      ? new Date(data.heatMap.generated).toLocaleString()
                      : "unknown"}
                  </div>
                </div>
              ) : (
                <div className="text-zinc-500 text-sm">
                  No heat map data. Click &quot;heatmap&quot; to generate.
                </div>
              )}
            </Card>
          </div>

          {/* ── Center column ─────────────────────────────── */}
          <div className="space-y-4">
            {/* Breath Log */}
            <Card title="Breath Log">
              {breaths.length > 0 ? (
                <div className="space-y-2">
                  {breaths
                    .slice()
                    .reverse()
                    .slice(0, 10)
                    .map((b) => {
                      const expanded = expandedBreath === b.breath_id;
                      return (
                        <div key={b.breath_id}>
                          <button
                            onClick={() =>
                              setExpandedBreath(expanded ? null : b.breath_id)
                            }
                            className="w-full text-left px-3 py-2 rounded bg-zinc-800/60 hover:bg-zinc-700/60 transition-colors"
                          >
                            <div className="flex items-center justify-between">
                              <div className="flex items-center gap-2">
                                <span className="text-xs text-zinc-500">
                                  {b.breath_id}
                                </span>
                                <span className="text-xs px-1.5 py-0.5 rounded bg-zinc-700 text-zinc-400">
                                  {b.mode}
                                </span>
                              </div>
                              <span
                                className={`text-sm font-medium ${deltaBadge(
                                  b.delta
                                )}`}
                              >
                                {b.delta > 0 ? "+" : ""}
                                {b.delta.toFixed(2)}
                              </span>
                            </div>
                            <div className="flex items-center gap-3 mt-1 text-xs text-zinc-500">
                              <span>
                                {b.items_succeeded.length}/
                                {b.items_attempted.length} succeeded
                              </span>
                              <span>{b.duration_minutes}m</span>
                              <span>
                                {b.discoveries.length} discoveries
                              </span>
                            </div>
                          </button>

                          {expanded && (
                            <div className="mt-1 px-3 py-3 rounded bg-zinc-900/80 border border-zinc-700/30 space-y-2 text-xs">
                              {b.items_succeeded.length > 0 && (
                                <div>
                                  <span className="text-emerald-400 font-medium">
                                    Succeeded:{" "}
                                  </span>
                                  <span className="text-zinc-300">
                                    {b.items_succeeded.join(", ")}
                                  </span>
                                </div>
                              )}
                              {b.items_failed.length > 0 && (
                                <div>
                                  <span className="text-red-400 font-medium">
                                    Failed:{" "}
                                  </span>
                                  <span className="text-zinc-300">
                                    {b.items_failed.join(", ")}
                                  </span>
                                  {Object.entries(b.failure_reasons).map(
                                    ([k, v]) => (
                                      <div
                                        key={k}
                                        className="text-zinc-500 ml-4"
                                      >
                                        {k}: {v}
                                      </div>
                                    )
                                  )}
                                </div>
                              )}
                              {b.discoveries.length > 0 && (
                                <div>
                                  <span className="text-cyan-400 font-medium">
                                    Discoveries:{" "}
                                  </span>
                                  <ul className="text-zinc-300 ml-4 list-disc">
                                    {b.discoveries.map((d, i) => (
                                      <li key={i}>{d}</li>
                                    ))}
                                  </ul>
                                </div>
                              )}
                              {b.skills_used.length > 0 && (
                                <div>
                                  <span className="text-zinc-400 font-medium">
                                    Skills:{" "}
                                  </span>
                                  <span className="text-zinc-300">
                                    {b.skills_used.join(", ")}
                                  </span>
                                </div>
                              )}
                            </div>
                          )}
                        </div>
                      );
                    })}
                </div>
              ) : (
                <div className="text-zinc-500 text-sm">
                  No breaths recorded yet. The first{" "}
                  <code className="text-cyan-400">/ada-breather full</code> will
                  appear here.
                </div>
              )}
            </Card>

            {/* Proposals */}
            <Card title="Skill Evolution Proposals">
              {proposals.length > 0 ? (
                <div className="space-y-3">
                  {proposals.map((p) => (
                    <div
                      key={p.id}
                      className="px-3 py-2 rounded bg-zinc-900/60 border border-zinc-700/30"
                    >
                      <div className="flex items-center justify-between mb-1">
                        <span className="text-sm text-violet-400 font-medium">
                          {p.skill}
                        </span>
                        <span
                          className={`text-xs px-1.5 py-0.5 rounded ${
                            p.status === "proposed"
                              ? "bg-amber-900/40 text-amber-300"
                              : p.status === "applied"
                              ? "bg-emerald-900/40 text-emerald-300"
                              : "bg-zinc-700 text-zinc-400"
                          }`}
                        >
                          {p.status}
                        </span>
                      </div>
                      <p className="text-xs text-zinc-400">{p.evidence}</p>
                      <p className="text-xs text-zinc-300 mt-1">
                        {p.proposed_change}
                      </p>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="text-zinc-500 text-sm">
                  No proposals yet. The Evolve phase generates these after 3+ similar failures.
                </div>
              )}
            </Card>
          </div>

          {/* ── Right column ──────────────────────────────── */}
          <div className="space-y-4">
            {/* Focus Vector */}
            <Card title="Focus Vector">
              {focus ? (
                <div className="space-y-3">
                  <div>
                    <div className="text-xs text-zinc-500 uppercase tracking-wider mb-1">
                      Primary
                    </div>
                    <p className="text-sm text-cyan-300">{focus.primary}</p>
                  </div>
                  {focus.secondary && focus.secondary.length > 0 && (
                    <div>
                      <div className="text-xs text-zinc-500 uppercase tracking-wider mb-1">
                        Secondary
                      </div>
                      <ul className="space-y-1">
                        {focus.secondary.map((s, i) => (
                          <li key={i} className="text-xs text-zinc-400">
                            {s}
                          </li>
                        ))}
                      </ul>
                    </div>
                  )}
                  {focus.blocked && focus.blocked.length > 0 && (
                    <div>
                      <div className="text-xs text-red-500 uppercase tracking-wider mb-1">
                        Blocked
                      </div>
                      {focus.blocked.map((b, i) => (
                        <div key={i} className="text-xs text-red-300">
                          {b}
                        </div>
                      ))}
                    </div>
                  )}
                  {focus.energy && (
                    <p className="text-xs text-zinc-600 italic mt-2">
                      {focus.energy}
                    </p>
                  )}
                </div>
              ) : (
                <div className="text-zinc-500 text-sm">
                  No FOCUS_VECTOR.json found.
                </div>
              )}
            </Card>

            {/* Skill Report Card */}
            <Card title="Skill Report Card">
              {Object.keys(skillStats).length > 0 ? (
                <div className="space-y-2">
                  {Object.entries(skillStats)
                    .sort(([, a], [, b]) => b.total_calls - a.total_calls)
                    .map(([name, stats]) => (
                      <div key={name}>
                        <div className="flex items-center justify-between mb-1">
                          <span className="text-xs text-zinc-300 truncate">
                            {name}
                          </span>
                          <span className="text-xs text-zinc-500">
                            {stats.total_calls} calls
                          </span>
                        </div>
                        <Bar
                          value={stats.success_rate * 100}
                          max={100}
                          color={
                            stats.success_rate >= 0.8
                              ? "bg-emerald-500"
                              : stats.success_rate >= 0.5
                              ? "bg-amber-500"
                              : "bg-red-500"
                          }
                          label={`${Math.round(stats.success_rate * 100)}%`}
                        />
                      </div>
                    ))}
                </div>
              ) : (
                <div className="text-zinc-500 text-sm">
                  No skill data yet. Runs accumulate after full breaths.
                </div>
              )}
            </Card>

            {/* Pipeline Status (compact) */}
            <Card title="Pipeline">
              <div className="text-xs text-zinc-500 mb-2">
                Run &quot;score&quot; to see current pipeline stages
              </div>
              {toolResult?.action === "score" && toolResult.code === 0 ? (
                <pre className="text-xs text-zinc-300 font-mono whitespace-pre-wrap max-h-64 overflow-y-auto">
                  {toolResult.stdout}
                </pre>
              ) : (
                <div className="text-zinc-500 text-sm">
                  Click the <span className="text-zinc-300">score</span> button above to run the pipeline scorer.
                </div>
              )}
            </Card>
          </div>
        </div>
      </main>
    </div>
  );
}
