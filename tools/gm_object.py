"""Helpers to create / patch GameMaker objects and scripts from Python."""
import os, re
from gm_sprite import ROOT, register

# event key -> (eventType, eventNum, gml file name)
EVENTS = {
    "create":     (0, 0, "Create_0.gml"),
    "destroy":    (1, 0, "Destroy_0.gml"),
    "step":       (3, 0, "Step_0.gml"),
    "begin_step": (3, 1, "Step_1.gml"),
    "end_step":   (3, 2, "Step_2.gml"),
    "room_start": (7, 4, "Other_4.gml"),
    "draw":       (8, 0, "Draw_0.gml"),
    "draw_begin": (8, 72, "Draw_72.gml"),
    "draw_end":   (8, 73, "Draw_73.gml"),
    "draw_gui":   (8, 64, "Draw_64.gml"),
    "cleanup":    (12, 0, "CleanUp_0.gml"),
}


def _event_json(t, n):
    return ('    {"$GMEvent":"v1","%Name":"","collisionObjectId":null,"eventNum":' + str(n) + ',"eventType":' + str(t) + ',"isDnD":false,'
            '"name":"","resourceType":"GMEvent","resourceVersion":"2.0",},\n')


def _prop_json(name, value):
    is_str = isinstance(value, str)
    return ('    {"$GMObjectProperty":"v2","%Name":"' + name + '","filters":[],"listItems":[],"multiselect":false,'
            '"name":"' + name + '","rangeEnabled":false,"rangeMax":10.0,"rangeMin":0.0,"resourceType":"GMObjectProperty",'
            '"resourceVersion":"2.0","value":"' + str(value) + '","varType":' + ("2" if is_str else "1") + ',},\n')


def write_gml(obj, key, code):
    t, n, fn = EVENTS[key]
    d = os.path.join(ROOT, "objects", obj)
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, fn), "w", encoding="utf8", newline="\n") as f:
        f.write(code.strip("\n") + "\n")


def write_object(name, folder, sprite, events, props=(), parent=None, visible=True, mask_sprite=None):
    d = os.path.join(ROOT, "objects", name)
    os.makedirs(d, exist_ok=True)
    ev = ""
    for key, code in events.items():
        t, n, fn = EVENTS[key]
        ev += _event_json(t, n)
        write_gml(name, key, code)
    pr = "".join(_prop_json(k, v) for k, v in props)
    spr = ('{\n    "name":"%s",\n    "path":"sprites/%s/%s.yy",\n  }' % (sprite, sprite, sprite)) if sprite else "null"
    msk = ('{\n    "name":"%s",\n    "path":"sprites/%s/%s.yy",\n  }' % (mask_sprite, mask_sprite, mask_sprite)) if mask_sprite else "null"
    par = ('{\n    "name":"%s",\n    "path":"objects/%s/%s.yy",\n  }' % (parent, parent, parent)) if parent else "null"
    yy = f'''{{
  "$GMObject":"",
  "%Name":"{name}",
  "eventList":[
{ev}  ],
  "managed":true,
  "name":"{name}",
  "overriddenProperties":[],
  "parent":{{
    "name":"{folder}",
    "path":"folders/objects/{folder}.yy",
  }},
  "parentObjectId":{par},
  "persistent":false,
  "physicsAngularDamping":0.1,
  "physicsDensity":0.5,
  "physicsFriction":0.2,
  "physicsGroup":1,
  "physicsKinematic":false,
  "physicsLinearDamping":0.1,
  "physicsObject":false,
  "physicsRestitution":0.1,
  "physicsSensor":false,
  "physicsShape":1,
  "physicsShapePoints":[],
  "physicsStartAwake":true,
  "properties":[
{pr}  ],
  "resourceType":"GMObject",
  "resourceVersion":"2.0",
  "solid":false,
  "spriteId":{spr},
  "spriteMaskId":{msk},
  "visible":{"true" if visible else "false"},
}}'''
    with open(os.path.join(d, name + ".yy"), "w", encoding="utf8", newline="\n") as f:
        f.write(yy)
    register("objects", name)


def patch_object(name, events):
    """Add missing events to an existing object's .yy and (over)write the GML for every event given."""
    p = os.path.join(ROOT, "objects", name, name + ".yy")
    s = open(p, encoding="utf8").read()
    for key, code in events.items():
        t, n, fn = EVENTS[key]
        write_gml(name, key, code)
        if '"eventNum":%d,"eventType":%d,' % (n, t) not in s:
            marker = '  ],\n  "managed"'
            assert marker in s, name
            s = s.replace(marker, _event_json(t, n) + marker, 1)
    open(p, "w", encoding="utf8", newline="\n").write(s)


def set_sprite(name, sprite=None, mask=None):
    p = os.path.join(ROOT, "objects", name, name + ".yy")
    s = open(p, encoding="utf8").read()
    if sprite is not None:
        new = ('"spriteId":{\n    "name":"%s",\n    "path":"sprites/%s/%s.yy",\n  },' % (sprite, sprite, sprite)) if sprite else '"spriteId":null,'
        s = re.sub(r'"spriteId":(\{[^}]*\}|null),', lambda m: new, s, count=1)
    if mask is not None:
        new = ('"spriteMaskId":{\n    "name":"%s",\n    "path":"sprites/%s/%s.yy",\n  },' % (mask, mask, mask)) if mask else '"spriteMaskId":null,'
        s = re.sub(r'"spriteMaskId":(\{[^}]*\}|null),', lambda m: new, s, count=1)
    open(p, "w", encoding="utf8", newline="\n").write(s)


def add_props(name, props):
    """Append object properties that are missing (list of (name, value))."""
    p = os.path.join(ROOT, "objects", name, name + ".yy")
    s = open(p, encoding="utf8").read()
    for k, v in props:
        if '"name":"%s","rangeEnabled"' % k in s:
            continue
        marker = '  ],\n  "resourceType":"GMObject"'
        if '  "properties":[],\n' in s:
            s = s.replace('  "properties":[],\n', '  "properties":[\n' + _prop_json(k, v) + '  ],\n', 1)
        else:
            s = s.replace(marker, _prop_json(k, v) + marker, 1)
    open(p, "w", encoding="utf8", newline="\n").write(s)


def write_script(name, folder, code):
    d = os.path.join(ROOT, "scripts", name)
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, name + ".gml"), "w", encoding="utf8", newline="\n") as f:
        f.write(code.strip("\n") + "\n")
    yy = f'''{{
  "$GMScript":"v1",
  "%Name":"{name}",
  "isCompatibility":false,
  "isDnD":false,
  "name":"{name}",
  "parent":{{
    "name":"{folder}",
    "path":"folders/scripts/{folder}.yy",
  }},
  "resourceType":"GMScript",
  "resourceVersion":"2.0",
}}'''
    with open(os.path.join(d, name + ".yy"), "w", encoding="utf8", newline="\n") as f:
        f.write(yy)
    register("scripts", name)
