extends Node

# Test script for the new clipboard system
# Run this to verify the code#key syntax works

func _ready():
	print("Testing Clipboard System...")
	
	# Test the CodeSnippetLibrary
	var snippet_library = preload("res://commons/context/clipboard/code_snippet_library.gd").new()
	
	# Test cases
	var test_cases = [
		"Simple text with code#point snippet",
		"Multiple snippets: code#line and code#triangle",
		"Legacy syntax still works: code:point",
		"Mixed syntax: code#material and code:mesh",
		"No snippets in this text",
		"Invalid snippet: code#nonexistent"
	]
	
	print("\n=== Testing Snippet Expansion ===")
	for i in range(test_cases.size()):
		var test_text = test_cases[i]
		print("\nTest ", i + 1, ": ", test_text)
		print("BBCode Result:")
		var bbcode_result = snippet_library.expand_text(test_text, true)
		print(bbcode_result)
		print("Plain Result:")
		var plain_result = snippet_library.expand_text(test_text, false)
		print(plain_result)
		print("---")
	
	# Test snippet retrieval
	print("\n=== Testing Snippet Retrieval ===")
	var available_snippets = snippet_library.get_all_snippet_ids()
	print("Available snippets: ", available_snippets)
	
	for snippet_id in ["point", "line", "triangle", "nonexistent"]:
		var snippet = snippet_library.get_snippet(snippet_id)
		if snippet.size() > 0:
			print("Snippet '", snippet_id, "': ", snippet.get("title", "No title"))
		else:
			print("Snippet '", snippet_id, "': Not found")
	
	print("\n=== Clipboard System Test Complete ===")
