export interface ParsedIdentity {
  essence: string;
  desire: string;
  criticalParameter: string;
  triggers: string;
  emerges: string;
  needs: string;
  relationships: string;
  truth: string;
}

const FIELDS = [
  "essence",
  "desire",
  "critical_parameter",
  "triggers",
  "emerges",
  "needs",
  "relationships",
  "truth",
];

export function parseIdentity(source: string): ParsedIdentity | null {
  if (!source.includes("@identity")) return null;

  const fields: Record<string, string> = {};
  for (const field of FIELDS) {
    const match = source.match(new RegExp(`#\\s*${field}:\\s*(.+)`));
    if (match) fields[field] = match[1].trim();
  }

  if (Object.keys(fields).length === 0) return null;

  return {
    essence: fields.essence || "",
    desire: fields.desire || "",
    criticalParameter: fields.critical_parameter || "",
    triggers: fields.triggers || "",
    emerges: fields.emerges || "",
    needs: fields.needs || "",
    relationships: fields.relationships || "",
    truth: fields.truth || "",
  };
}
