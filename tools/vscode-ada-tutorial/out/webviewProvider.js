"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.showTutorial = showTutorial;
const vscode = __importStar(require("vscode"));
const fs = __importStar(require("fs"));
const path = __importStar(require("path"));
const http = __importStar(require("http"));
const registryLoader_1 = require("./registryLoader");
const identityParser_1 = require("./identityParser");
let currentPanel;
function checkEncyclopedia(url) {
    return new Promise((resolve) => {
        const req = http.get(url, (res) => {
            resolve(res.statusCode !== undefined && res.statusCode < 500);
        });
        req.on("error", () => resolve(false));
        req.setTimeout(2000, () => {
            req.destroy();
            resolve(false);
        });
    });
}
function buildOfflineHtml(token, repoPath) {
    const lookup = (0, registryLoader_1.buildLookupIndex)(repoPath);
    const artifact = lookup.get(token);
    let identityHtml = "";
    if (artifact) {
        // Try to read the .gd file for @identity
        const scenePath = artifact.scene;
        const gdPath = scenePath.replace("res://", "").replace(".tscn", ".gd");
        const fullPath = path.join(repoPath, gdPath);
        if (fs.existsSync(fullPath)) {
            const source = fs.readFileSync(fullPath, "utf-8");
            const identity = (0, identityParser_1.parseIdentity)(source);
            if (identity) {
                const fields = [
                    { label: "Essence", value: identity.essence },
                    { label: "Desire", value: identity.desire },
                    { label: "Critical Parameter", value: identity.criticalParameter },
                    { label: "Triggers", value: identity.triggers },
                    { label: "Emerges", value: identity.emerges },
                    { label: "Relationships", value: identity.relationships },
                    { label: "Truth", value: identity.truth },
                ].filter((f) => f.value);
                identityHtml = `
          <div class="section">
            <h2>@identity</h2>
            ${identity.truth ? `<blockquote class="truth">${escapeHtml(identity.truth)}</blockquote>` : ""}
            ${fields
                    .map((f) => `<div class="field"><span class="label">${f.label}</span><span class="value">${escapeHtml(f.value)}</span></div>`)
                    .join("")}
          </div>
        `;
            }
        }
    }
    return `<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: var(--vscode-font-family); background: var(--vscode-editor-background); color: var(--vscode-foreground); padding: 20px; }
    h1 { font-size: 1.5em; margin-bottom: 4px; }
    .token { font-family: monospace; color: var(--vscode-textLink-foreground); font-size: 0.85em; }
    .badge { display: inline-block; padding: 2px 8px; border-radius: 4px; font-size: 0.75em; background: var(--vscode-badge-background); color: var(--vscode-badge-foreground); margin-right: 4px; }
    .section { margin-top: 24px; padding: 16px; border: 1px solid var(--vscode-panel-border); border-radius: 8px; }
    .section h2 { font-size: 1.1em; margin: 0 0 12px 0; color: var(--vscode-textLink-foreground); }
    .truth { font-style: italic; border-left: 3px solid #f59e0b; padding: 8px 12px; margin: 0 0 12px 0; color: #fbbf24; background: rgba(245,158,11,0.1); border-radius: 4px; }
    .field { margin-bottom: 8px; }
    .label { font-size: 0.7em; text-transform: uppercase; letter-spacing: 0.05em; color: var(--vscode-descriptionForeground); display: block; }
    .value { font-size: 0.9em; }
    .offline-note { margin-top: 24px; padding: 12px; background: rgba(245,158,11,0.1); border-radius: 8px; font-size: 0.85em; color: #fbbf24; }
    .offline-note code { background: rgba(0,0,0,0.3); padding: 2px 6px; border-radius: 3px; font-size: 0.9em; }
  </style>
</head>
<body>
  <h1>${artifact ? escapeHtml(artifact.name) : escapeHtml(token)}</h1>
  <span class="token">${escapeHtml(token)}</span>
  ${artifact ? `
    <div style="margin-top: 8px;">
      ${artifact.complexity ? `<span class="badge">${escapeHtml(artifact.complexity)}</span>` : ""}
      ${artifact.category ? `<span class="badge">${escapeHtml(artifact.category)}</span>` : ""}
      ${artifact.mapReady ? '<span class="badge">map-ready</span>' : ""}
    </div>
    <p style="margin-top: 12px; color: var(--vscode-descriptionForeground);">${escapeHtml(artifact.description)}</p>
    <div class="section">
      <h2>Scene</h2>
      <code>${escapeHtml(artifact.scene)}</code>
    </div>
  ` : ""}
  ${identityHtml}
  <div class="offline-note">
    <strong>Offline mode</strong> — Start the Ada Encyclopedia for the full tutorial:<br>
    <code>cd ada_encyclopedia && npm run dev</code>
  </div>
</body>
</html>`;
}
function escapeHtml(s) {
    return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
}
async function showTutorial(token, repoPath, context) {
    const config = vscode.workspace.getConfiguration("ada");
    const baseUrl = config.get("encyclopediaUrl", "http://localhost:3003");
    // Reuse or create panel
    if (currentPanel) {
        currentPanel.reveal(vscode.ViewColumn.Beside);
    }
    else {
        currentPanel = vscode.window.createWebviewPanel("adaTutorial", `Tutorial: ${token}`, vscode.ViewColumn.Beside, {
            enableScripts: true,
            retainContextWhenHidden: true,
        });
        currentPanel.onDidDispose(() => {
            currentPanel = undefined;
        });
    }
    currentPanel.title = `Tutorial: ${token}`;
    // Check if encyclopedia is running
    const online = await checkEncyclopedia(baseUrl);
    if (online) {
        const tutorialUrl = `${baseUrl}/artifact-tutorial/${encodeURIComponent(token)}?embed=true`;
        currentPanel.webview.html = `<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body, html { margin: 0; padding: 0; width: 100%; height: 100%; overflow: hidden; }
    iframe { border: none; width: 100%; height: 100%; }
  </style>
</head>
<body>
  <iframe src="${tutorialUrl}"></iframe>
</body>
</html>`;
    }
    else {
        currentPanel.webview.html = buildOfflineHtml(token, repoPath);
    }
}
//# sourceMappingURL=webviewProvider.js.map