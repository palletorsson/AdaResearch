import { parsePlacement } from "./vocab";

/** Describes a generated instrument without creating a second runtime copy. */
export type LinkedPartDefinition = {
  owner: string;
  id: string;
  label: string;
  aliases?: string[];
  when: Record<string, string[] | "present" | "absent">;
  anchor?: { token: string; match: string };
  position: [number, number, number];
  source: string;
  placement_key?: string;
  rotation?: number;
};
export type LinkedPart = LinkedPartDefinition & {
  key: string;
  ownerCell: { x: number; z: number };
  anchorCell: { x: number; z: number } | null;
  x: number | null;
  z: number | null;
  yaw?: number;
  independent?: boolean;
  removed?: boolean;
  height?: number;
  scale?: number;
  issue?: string;
};

export function resolveLinkedParts(inter: string[][], definitions: LinkedPartDefinition[], includeRemoved = false): LinkedPart[] {
  const placements = inter.flatMap((row, z) => row.flatMap((raw, x) => {
    const placement = parsePlacement(raw);
    return placement ? [{ x, z, placement, config: Object.fromEntries(placement.tails.map(t => [t.k, t.v])) }] : [];
  }));
  const result: LinkedPart[] = [];
  for (const owner of placements) {
    for (const def of definitions.filter(d => d.owner === owner.placement.token)) {
      if (!Object.entries(def.when).every(([key, rule]) => {
        const value = (owner.config[key] ?? "").trim().toLowerCase();
        return rule === "present" ? !!value : rule === "absent" ? !value : rule.includes(value);
      })) continue;
      const removed = !!def.placement_key && ["true", "1"].includes((owner.config[def.placement_key + "_removed"] ?? "").trim().toLowerCase());
      if (removed && !includeRemoved) continue;
      const anchors = def.anchor ? placements.filter(p => p.placement.token === def.anchor!.token &&
        !!owner.config[def.anchor!.match] && p.config[def.anchor!.match] === owner.config[def.anchor!.match]) : [owner];
      const part = { ...def, removed, key: `${owner.x},${owner.z}/${def.id}`, ownerCell: { x: owner.x, z: owner.z } };
      if (anchors.length !== 1) {
        result.push({ ...part, anchorCell: null, x: null, z: null,
          issue: anchors.length ? "More than one matching linked exhibit" : "Linked exhibit is missing" });
        continue;
      }
      const anchor = anchors[0];
      const angle = anchor.placement.rot * Math.PI / 180;
      const tailScale = Number(anchor.config.scale);
      const scale = Number.isFinite(tailScale) && anchor.config.scale?.trim() ?
        Math.min(5, Math.max(0.01, tailScale)) : (anchor.placement.scale ?? 1);
      const [dx, , dz] = def.position;
      const poseText = def.placement_key ? owner.config[def.placement_key] : undefined;
      const saved = poseText?.split(",").map(Number);
      const valid = !!saved && [3, 5].includes(saved.length) && poseText!.split(",").every(v => v.trim()) && saved.every(Number.isFinite) && (saved.length === 3 || (saved[4] >= 0.01 && saved[4] <= 5));
      result.push({ ...part, independent: valid, height: valid ? (saved[3] ?? 0) : 0, scale: valid ? (saved[4] ?? 1) : 1, yaw: valid ? saved[2] : anchor.placement.rot + (def.rotation ?? 0),
        ...(poseText && !valid ? { issue: "Invalid saved position; showing original placement" } : {}), anchorCell: { x: anchor.x, z: anchor.z },
        x: valid ? saved[0] : anchor.x + 0.5 + scale * (Math.cos(angle) * dx + Math.sin(angle) * dz),
        z: valid ? saved[1] : anchor.z + 0.5 + scale * (-Math.sin(angle) * dx + Math.cos(angle) * dz) });
    }
  }
  return result;
}

/** Keep the untouched head, including null height and exact config spelling. */
export function writePartPose(raw: string, part: LinkedPartDefinition, x: number, z: number, yaw: number, height = 0, scale = 1): string {
  if (!part.placement_key) throw new Error("This part has no independent placement contract");
  if (![x, z, yaw, height, scale].every(Number.isFinite)) throw new Error("Position must contain finite numbers");
  if (scale < 0.01 || scale > 5) throw new Error("Scale must be between 0.01 and 5");
  const pose = (height === 0 && scale === 1 ? [x, z, yaw] : [x, z, yaw, height, scale])
    .map(n => Number(n.toFixed(4))).join(",");
  return writePartConfig(raw, part.placement_key, pose);
}

function writePartConfig(raw: string, key: string, value: string): string {
  return raw.split("#").filter((f, i) => i === 0 || f.split(":", 1)[0].trim() !== key).join("#") + `#${key}:${value}`;
}

export function removeLinkedPart(inter: string[][], part: LinkedPart) {
  if (!part.placement_key) throw new Error("This instrument cannot be removed independently");
  const cell = part.ownerCell;
  const prev = inter[cell.z][cell.x];
  return { ...cell, prev, next: writePartConfig(prev, part.placement_key + "_removed", "true") };
}

/** Markers must obey the current tool, including paint and remove. */
export function partToolAction(tool: string, carrying = false): "select" | "remove" | "cell" {
  return tool === "remove" ? "remove" : tool === "move" && !carrying ? "select" : "cell";
}

/** A part edit is one ordinary owner-cell edit, so save, drafts and undo agree.
 * Pin siblings on the first edit of a legacy layout as well. */
export function moveLinkedPart(inter: string[][], definitions: LinkedPartDefinition[], key: string,
  x: number, z: number, yaw?: number, height?: number, scale?: number) {
  const parts = resolveLinkedParts(inter, definitions, true);
  const part = parts.find(p => p.key === key);
  if (!part || part.x === null || part.z === null) throw new Error("Instrument is unavailable");
  const cell = part.ownerCell;
  const prev = inter[cell.z][cell.x];
  let next = prev;
  for (const sibling of parts.filter(p => p.ownerCell.x === cell.x && p.ownerCell.z === cell.z)) {
    if (sibling.placement_key && sibling.x !== null && sibling.z !== null && !sibling.independent && !sibling.removed)
      next = writePartPose(next, sibling, sibling.x, sibling.z, sibling.yaw ?? 0);
  }
  next = writePartPose(next, part, x, z, yaw ?? part.yaw ?? 0, height ?? part.height ?? 0, scale ?? part.scale ?? 1);
  if (part.removed) next = writePartConfig(next, part.placement_key! + "_removed", "false");
  return { ...cell, prev, next };
}
