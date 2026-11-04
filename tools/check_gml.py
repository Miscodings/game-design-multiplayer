"""Crude GML sanity check: bracket balance per file (ignoring strings and comments). python tools/check_gml.py"""
import glob, os, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))


def strip(s):
    out, i, n = [], 0, len(s)
    while i < n:
        c = s[i]
        if c == '"':
            i += 1
            while i < n and s[i] != '"':
                i += 2 if s[i] == "\\" else 1
            i += 1
        elif s.startswith("//", i):
            while i < n and s[i] != "\n":
                i += 1
        elif s.startswith("/*", i):
            i = s.find("*/", i) + 2
        else:
            out.append(c)
            i += 1
    return "".join(out)


bad = 0
for f in glob.glob(os.path.join(ROOT, "scripts", "*", "*.gml")) + glob.glob(os.path.join(ROOT, "objects", "*", "*.gml")):
    s = strip(open(f, encoding="utf8").read())
    stack = []
    pairs = {")": "(", "]": "[", "}": "{"}
    ok = True
    for ch in s:
        if ch in "([{":
            stack.append(ch)
        elif ch in ")]}":
            if not stack or stack.pop() != pairs[ch]:
                ok = False
                break
    if stack or not ok:
        print("UNBALANCED:", os.path.relpath(f, ROOT))
        bad += 1
print("checked, problems:", bad)
sys.exit(1 if bad else 0)
