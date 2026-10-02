"""MkDocs hook: take the navigation from docs/_nav.json, which build_site.py writes.

The course's order lives in course.json and opening.json, so the left tree is generated
with the pages instead of being typed into mkdocs.yml.
"""
import json
import os


def on_config(config, **kwargs):
    nav_file = os.path.join(config["docs_dir"], "_nav.json")
    if os.path.isfile(nav_file):
        with open(nav_file, encoding="utf-8") as f:
            config["nav"] = json.load(f)
    return config
