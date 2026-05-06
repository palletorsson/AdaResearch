import * as vscode from "vscode";
import * as path from "path";
import { findArtifactByFilePath, clearCache } from "./registryLoader";
import { showTutorial } from "./webviewProvider";
import { ArtifactTreeProvider } from "./artifactTreeProvider";

let statusBarItem: vscode.StatusBarItem;

function getRepoPath(): string | null {
  const folders = vscode.workspace.workspaceFolders;
  if (!folders) return null;

  for (const folder of folders) {
    const p = folder.uri.fsPath;
    // Check if this is Ada Research repo
    const registryDir = path.join(p, "commons", "artifacts", "registry");
    try {
      const fs = require("fs");
      if (fs.existsSync(registryDir)) return p;
    } catch {
      continue;
    }
  }
  return null;
}

export function activate(context: vscode.ExtensionContext): void {
  const repoPath = getRepoPath();
  if (!repoPath) {
    // Not an Ada Research workspace — silently skip activation
    return;
  }

  // Status bar item
  statusBarItem = vscode.window.createStatusBarItem(
    vscode.StatusBarAlignment.Right,
    100
  );
  statusBarItem.command = "ada.showArtifactTutorial";
  context.subscriptions.push(statusBarItem);

  // Tree view
  const treeProvider = new ArtifactTreeProvider(repoPath);
  vscode.window.registerTreeDataProvider("adaArtifactTree", treeProvider);

  // Command: show artifact tutorial
  context.subscriptions.push(
    vscode.commands.registerCommand(
      "ada.showArtifactTutorial",
      async (tokenArg?: string) => {
        let token = tokenArg;

        if (!token) {
          // Try to detect from active editor
          const editor = vscode.window.activeTextEditor;
          if (editor && editor.document.fileName.endsWith(".gd")) {
            token = findArtifactByFilePath(editor.document.fileName, repoPath) ?? undefined;
          }

          if (!token) {
            // Show quick pick
            const input = await vscode.window.showInputBox({
              prompt: "Enter artifact lookup name (e.g., turing_pattern_generator)",
              placeHolder: "artifact_token",
            });
            if (!input) return;
            token = input;
          }
        }

        await showTutorial(token, repoPath, context);
      }
    )
  );

  // Command: refresh tree
  context.subscriptions.push(
    vscode.commands.registerCommand("ada.refreshArtifactTree", () => {
      clearCache();
      treeProvider.refresh();
    })
  );

  // Track active editor to update status bar
  context.subscriptions.push(
    vscode.window.onDidChangeActiveTextEditor((editor) => {
      if (editor && editor.document.fileName.endsWith(".gd")) {
        const token = findArtifactByFilePath(
          editor.document.fileName,
          repoPath
        );
        if (token) {
          statusBarItem.text = `$(book) ${token}`;
          statusBarItem.tooltip = "Click to open artifact tutorial";
          statusBarItem.show();
        } else {
          statusBarItem.hide();
        }
      } else {
        statusBarItem.hide();
      }
    })
  );

  // Check current editor on activation
  const activeEditor = vscode.window.activeTextEditor;
  if (activeEditor && activeEditor.document.fileName.endsWith(".gd")) {
    const token = findArtifactByFilePath(
      activeEditor.document.fileName,
      repoPath
    );
    if (token) {
      statusBarItem.text = `$(book) ${token}`;
      statusBarItem.tooltip = "Click to open artifact tutorial";
      statusBarItem.show();
    }
  }
}

export function deactivate(): void {
  // Cleanup handled by disposables
}
