# ===========================================================================
# ClaudeBridge.gd — Send messages from Godot to Claude Code
# Add as an AutoLoad singleton named "ClaudeBridge" in Project Settings
#
# Usage from anywhere:
#   ClaudeBridge.send("hello from godot!")
#   ClaudeBridge.send("artifact selected: bouncing_ball", {"lookup_name": "bouncing_ball"})
# ===========================================================================
extends Node

const BRIDGE_URL := "http://localhost:9876/message"

var _http: HTTPRequest

func _ready():
	_http = HTTPRequest.new()
	_http.name = "ClaudeBridgeHTTP"
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)

## Send a text message to Claude Code
func send(text: String, extra: Dictionary = {}) -> void:
	var payload := {"text": text}
	payload.merge(extra)

	var body := JSON.stringify(payload)
	var headers := ["Content-Type: application/json"]

	var err := _http.request(BRIDGE_URL, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		push_warning("ClaudeBridge: Failed to send (server may not be running): %s" % error_string(err))

## Send artifact info when selected in catalog
func send_artifact_selected(lookup_name: String, artifact_info: Dictionary = {}) -> void:
	send("Artifact selected: %s" % lookup_name, {
		"type": "artifact_selected",
		"lookup_name": lookup_name,
		"info": artifact_info,
	})

## Send an error or warning
func send_error(message: String, context: String = "") -> void:
	send(message, {
		"type": "error",
		"context": context,
	})

## Send a map event
func send_map_event(event_name: String, data: Dictionary = {}) -> void:
	send("Map event: %s" % event_name, {
		"type": "map_event",
		"event": event_name,
		"data": data,
	})

func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if response_code != 200 and response_code != 0:
		push_warning("ClaudeBridge: Response code %d" % response_code)
