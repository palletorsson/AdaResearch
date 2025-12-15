
import json
import sys
import os

def compact_serialize(obj, indent_level=0, indent_str='\t'):
    """
    Serializes a JSON object with mixed indentation:
    - Lists containing only primitives (strings, numbers, booleans, null) are serialized on a single line.
    - Other lists and dictionaries are indented normally.
    """
    if isinstance(obj, list):
        # Check if list contains only primitives (no dicts or lists)
        is_simple = True
        if not obj: # Empty list
            return "[]"
            
        for item in obj:
            if isinstance(item, (dict, list)):
                is_simple = False
                break
        
        if is_simple:
            # Return compact representation
            # We use json.dumps for the inner items to handle string escaping correctly
            return "[" + ", ".join(json.dumps(x) for x in obj) + "]"
        else:
            # Multiline list
            items = []
            next_indent = indent_str * (indent_level + 1)
            for item in obj:
                items.append(next_indent + compact_serialize(item, indent_level + 1, indent_str))
            
            if not items:
                return "[]"
            return "[\n" + ",\n".join(items) + "\n" + (indent_str * indent_level) + "]"
            
    elif isinstance(obj, dict):
        if not obj:
            return "{}"
            
        items = []
        next_indent = indent_str * (indent_level + 1)
        for k, v in obj.items():
            # Key is always a string
            items.append(next_indent + json.dumps(k) + ": " + compact_serialize(v, indent_level + 1, indent_str))
            
        return "{\n" + ",\n".join(items) + "\n" + (indent_str * indent_level) + "}"
        
    else:
        # Primitive
        return json.dumps(obj)

def format_file(file_path):
    print(f"Formatting {file_path}...")
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        formatted_json = compact_serialize(data, indent_str='\t')
        
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(formatted_json)
        
        print(f"Successfully formatted {file_path}")
        return True
    except Exception as e:
        print(f"Error formatting {file_path}: {e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python compact_json_arrays.py <file_path>")
        sys.exit(1)
        
    target_file = sys.argv[1]
    format_file(target_file)
