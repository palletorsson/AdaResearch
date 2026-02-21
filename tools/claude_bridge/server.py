#!/usr/bin/env python3
"""
Claude Bridge Server — lightweight HTTP bridge between Godot and Claude Code.

Godot POSTs messages to http://localhost:9876/message
Claude Code reads them from the inbox file or via GET /messages

Endpoints:
  POST /message          — Godot sends a message (body = JSON {"text": "..."})
  GET  /messages          — Claude reads all unread messages
  GET  /messages/latest   — Claude reads the latest message
  POST /clear             — Clear the inbox
  GET  /status            — Health check
"""

import json
import os
import sys
import time
from http.server import HTTPServer, BaseHTTPRequestHandler
from datetime import datetime

PORT = 9876
INBOX_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "inbox")
os.makedirs(INBOX_DIR, exist_ok=True)


class BridgeHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path == "/message":
            length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(length).decode("utf-8") if length else ""

            try:
                data = json.loads(body) if body else {}
            except json.JSONDecodeError:
                data = {"text": body}

            # Add metadata
            data["timestamp"] = datetime.now().isoformat()
            data["id"] = f"msg_{int(time.time() * 1000)}"

            # Write to inbox
            filename = f"{data['id']}.json"
            filepath = os.path.join(INBOX_DIR, filename)
            with open(filepath, "w") as f:
                json.dump(data, f, indent=2)

            print(f"[BRIDGE] Received: {data.get('text', '(no text)')[:80]}")

            self._respond(200, {"status": "ok", "id": data["id"]})

        elif self.path == "/clear":
            count = 0
            for f in os.listdir(INBOX_DIR):
                if f.endswith(".json"):
                    os.remove(os.path.join(INBOX_DIR, f))
                    count += 1
            print(f"[BRIDGE] Cleared {count} messages")
            self._respond(200, {"status": "cleared", "count": count})

        else:
            self._respond(404, {"error": "not found"})

    def do_GET(self):
        if self.path == "/status":
            self._respond(200, {"status": "running", "port": PORT, "inbox": INBOX_DIR})

        elif self.path == "/messages":
            messages = self._read_all_messages()
            self._respond(200, {"messages": messages, "count": len(messages)})

        elif self.path == "/messages/latest":
            messages = self._read_all_messages()
            if messages:
                self._respond(200, messages[-1])
            else:
                self._respond(200, {"text": "(no messages)"})

        else:
            self._respond(404, {"error": "not found"})

    def _read_all_messages(self):
        messages = []
        for f in sorted(os.listdir(INBOX_DIR)):
            if f.endswith(".json"):
                filepath = os.path.join(INBOX_DIR, f)
                with open(filepath, "r") as fh:
                    messages.append(json.load(fh))
        return messages

    def _respond(self, code, data):
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(json.dumps(data).encode("utf-8"))

    def log_message(self, format, *args):
        # Quieter logging — only show errors
        pass


def main():
    print(f"=== Claude Bridge Server ===")
    print(f"  Listening on http://localhost:{PORT}")
    print(f"  Inbox dir:  {INBOX_DIR}")
    print(f"  Endpoints:")
    print(f"    POST /message         — Godot sends a message")
    print(f"    GET  /messages        — Read all messages")
    print(f"    GET  /messages/latest — Read latest message")
    print(f"    POST /clear           — Clear inbox")
    print(f"    GET  /status          — Health check")
    print(f"")
    print(f"  Godot usage:")
    print(f'    var http = HTTPRequest.new()')
    print(f'    http.request("http://localhost:{PORT}/message",')
    print(f'      ["Content-Type: application/json"], HTTPClient.METHOD_POST,')
    print(f'      JSON.stringify({{"text": "hello from godot"}})')
    print(f"")

    server = HTTPServer(("localhost", PORT), BridgeHandler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n[BRIDGE] Shutting down.")
        server.server_close()


if __name__ == "__main__":
    main()
