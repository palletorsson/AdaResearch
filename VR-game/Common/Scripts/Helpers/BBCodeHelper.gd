extends Node
class_name BBCodeHelper

# Converts Markdown text to BBCode for use in Godot's RichTextLabel.
static func markdown_to_bbcode(markdown_text: String) -> String:
	var bbcode_text = markdown_text

	# **Bold** -> [b]text[/b]
	bbcode_text = _replace_pairs(bbcode_text, "**", "[b]", "[/b]")
	bbcode_text = _replace_pairs(bbcode_text, "__", "[b]", "[/b]")

	# *Italic* -> [i]text[/i]
	bbcode_text = _replace_pairs(bbcode_text, "*", "[i]", "[/i]")
	bbcode_text = _replace_pairs(bbcode_text, "_", "[i]", "[/i]")

	# ~~Strikethrough~~ -> [s]text[/s]
	bbcode_text = _replace_pairs(bbcode_text, "~~", "[s]", "[/s]")

	# Headers: # Header -> [center][b]Header[/b][/center]
	for i in range(6, 0, -1):
		var header_md = "#".repeat(i) + " "
		var header_bb = "[center][b]"
		bbcode_text = _replace_line_start(bbcode_text, header_md, header_bb, "[/b][/center]")

	# Links: [text](url) -> [url=url]text[/url]
	var link_regex = RegEx.new()
	link_regex.compile("\\[([^\\]]+)\\]\\(([^)]+)\\)")
	bbcode_text = link_regex.sub(bbcode_text, "[url=\\2]\\1[/url]")

	# Images: ![alt text](url) -> [img]url[/img]
	var img_regex = RegEx.new()
	img_regex.compile("!\\[([^\\]]*)\\]\\(([^)]+)\\)")
	bbcode_text = img_regex.sub(bbcode_text, "[img]\\2[/img]")

	# Code blocks: ```code``` -> [code]code[/code]
	bbcode_text = _replace_pairs(bbcode_text, "```", "[code]", "[/code]")

	# Inline code: `code` -> [code]code[/code]
	bbcode_text = _replace_pairs(bbcode_text, "`", "[code]", "[/code]")

	# Blockquotes: > text -> [quote]text[/quote]
	bbcode_text = _replace_line_start(bbcode_text, "> ", "[quote]", "[/quote]")

	# Lists: - Item -> [list][*]Item[/*][/list]
	bbcode_text = _convert_lists(bbcode_text)

	return bbcode_text


# Replace opening and closing tag pairs correctly
static func _replace_pairs(text: String, markdown: String, open_tag: String, close_tag: String) -> String:
	var count = text.count(markdown)
	for i in range(count / 2):
		text = text.replacen(markdown, open_tag)
		text = text.replacen(markdown, close_tag)
	return text


# Replace line-starting Markdown syntax (for headers, blockquotes)
static func _replace_line_start(text: String, markdown: String, open_tag: String, close_tag: String) -> String:
	var lines = text.split("\n")
	for i in range(lines.size()):
		if lines[i].begins_with(markdown):
			lines[i] = lines[i].replace(markdown, open_tag) + close_tag
	return "\n".join(lines)


# Convert Markdown lists (- item) to BBCode lists
static func _convert_lists(text: String) -> String:
	var lines = text.split("\n")
	var in_list = false
	var result = ""

	for line in lines:
		if line.begins_with("- "):
			if not in_list:
				result += "[list]\n"
				in_list = true
			result += "[*]" + line.substr(2) + "\n"
		else:
			if in_list:
				result += "[/list]\n"
				in_list = false
			result += line + "\n"

	if in_list:
		result += "[/list]\n"

	return result.strip_edges()
