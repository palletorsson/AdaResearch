@tool
extends RichTextLabel

@export var scroll_speed: float = 1.0  # Speed of scrolling

var v_scroll_bar: VScrollBar = null
var http_request: HTTPRequest

const WIKI_URL = "https://raw.githubusercontent.com/wiki/palletorsson/AdaResearch/RandomWalk.md"  # Change to your actual source

# Default text if HTTP request fails
@export_multiline var init_text: String = ""

func _ready():
	visible = true  # Ensure visibility

	# Attach to CanvasLayer for VR rendering
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 1
	add_child(canvas_layer)

	# Get the vertical scrollbar
	v_scroll_bar = get_v_scroll_bar()
	if v_scroll_bar:
		v_scroll_bar.set_deferred("value", 0)

	# Ensure RichTextLabel updates correctly in VR
	await get_tree().process_frame
	queue_redraw()

	# Initialize HTTP request
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", _on_request_completed)

	# Fetch HTTP content
	fetch_wiki_text()

func fetch_wiki_text():
	text = "📡 Sending request..."
	var error = http_request.request(WIKI_URL)

	# Handle case where request fails to start
	if error != OK:
		text = "❌ Request could not be sent. Falling back to local text."
		fallback_to_local_text()

func _on_request_completed(_result, _response_code, _headers, body):
	if _response_code != 200:
		text = "❌ Failed to load data. Response code: " + str(_response_code)
		fallback_to_local_text()
		return

	# Successfully received data
	var wiki_text = body.get_string_from_utf8()
	text = wiki_text
	scroll_to_top()

func fallback_to_local_text():
	""" Sets the text to the initial placeholder if the HTTP request fails """
	text = init_text
	scroll_to_top()

func scroll_to_top():
	if v_scroll_bar:
		v_scroll_bar.set_deferred("value", 0)
