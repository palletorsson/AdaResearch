"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.parseIdentity = parseIdentity;
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
function parseIdentity(source) {
    if (!source.includes("@identity"))
        return null;
    const fields = {};
    for (const field of FIELDS) {
        const match = source.match(new RegExp(`#\\s*${field}:\\s*(.+)`));
        if (match)
            fields[field] = match[1].trim();
    }
    if (Object.keys(fields).length === 0)
        return null;
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
//# sourceMappingURL=identityParser.js.map