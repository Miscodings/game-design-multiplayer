"""Generates rm_level_1 .. rm_level_N from compact layout code. Run:  python tools/build_levels.py
Each level is two 12-row bands (band 0 = overworld on top, band 1 = underworld below), 16 px cells.
Floor tops sit on row 10 by default (the player's feet at y = 160 inside the band).

Cell characters
  #  solid        .  empty        S  spawn (empty cell above the floor)     E  exit (lower-left cell of a 2x2 portal)
  o  coin         l  torch         T  tar                                    W  pool that follows your partner (stand together)
  V  pool drained by a signal      > <  walker going right / left            M N O  linked box pairs (same letter in both bands)
  a-d plates (signal a-d)          A-D gates (open while that signal is on)  1-6  moving platforms
"""
import os, re, sys, uuid
sys.path.insert(0, os.path.dirname(__file__))
from gm_sprite import ROOT, register

TILE = 16
BAND = 12
TEMPLATE = os.path.join(ROOT, "tools", "room_template.yy")


class Level:
    def __init__(self, idx, width):
        self.idx, self.W = idx, width
        self.g = [[["."] * width for _ in range(BAND)] for _ in range(2)]
        self.tips, self.dark = [], []
        self.plates = {}      # letter -> dict(latch=, activator=)
        self.gates = {}       # letter -> dict(needed=, inverted=)
        self.plats = {}       # digit -> dict(signal=, tx=, ty=, speed=)
        self.pools = {}       # char -> dict(signal=, partner=, radius=)
        self.lamp_radius = {}

    # --- drawing helpers
    def set(self, b, c, r, ch):
        if 0 <= c < self.W and 0 <= r < BAND:
            self.g[b][r][c] = ch

    def get(self, b, c, r):
        return self.g[b][r][c]

    def rect(self, b, c0, c1, r0, r1, ch="#"):
        for c in range(c0, c1):
            for r in range(r0, r1 + 1):
                self.set(b, c, r, ch)

    def ground(self, b, c0, c1, top=10):
        self.rect(b, c0, c1, top, BAND - 1)

    def clear(self, b, c0, c1, r0, r1):
        self.rect(b, c0, c1, r0, r1, ".")

    def ceiling(self, b, c0, c1, rows=2):
        self.rect(b, c0, c1, 0, rows - 1)

    def hang(self, b, c, length, width=1, r0=2):
        """A stalactite column hanging from the ceiling."""
        self.rect(b, c, c + width, r0, r0 + length - 1)

    def coins(self, b, pts):
        for c, r in pts:
            self.set(b, c, r, "o")

    def line_coins(self, b, c0, c1, r, step=2):
        for c in range(c0, c1 + 1, step):
            self.set(b, c, r, "o")

    def tip(self, b, c, r, kind):
        self.tips.append((b, c, r, kind))

    def spawn(self, b, c, floor=10):
        self.set(b, c, floor - 1, "S")

    def exit(self, b, c, floor=10):
        self.set(b, c, floor - 1, "E")

    def pit(self, b, c0, c1, ch="T", top=10):
        """A hazard sunk into the floor: the surface row becomes `ch`, the bed below stays solid."""
        for c in range(c0, c1):
            self.set(b, c, top, ch)

    def dark_zone(self, b, c0, c1, feather=48):
        self.dark.append((b, c0, c1, feather))

    def gap(self, b, c0, c1, top=10):
        """A walkable dip (one tile deep)."""
        self.clear(b, c0, c1, top, top)


# ------------------------------------------------------------------ instance output

def _id():
    return "inst_" + uuid.uuid4().hex[:8].upper()


def _prop(obj, name, value):
    return ('            {"$GMOverriddenProperty":"v1","%Name":"","name":"","objectId":{"name":"' + obj + '","path":"objects/' + obj + '/' + obj + '.yy",},'
            '"propertyId":{"name":"' + name + '","path":"objects/' + obj + '/' + obj + '.yy",},"resourceType":"GMOverriddenProperty","resourceVersion":"2.0","value":"' + str(value) + '",},\n')


def instance(obj, x, y, sx=1.0, sy=1.0, props=()):
    n = _id()
    pr = "".join(_prop(obj, k, v) for k, v in props)
    plist = ("\n" + pr + "          ") if pr else ""
    text = ('        {"$GMRInstance":"v4","%Name":"' + n + '","colour":4294967295,"frozen":false,"hasCreationCode":false,"ignore":false,"imageIndex":0,'
            '"imageSpeed":1.0,"inheritCode":false,"inheritedItemId":null,"inheritItemSettings":false,"isDnd":false,"name":"' + n + '",'
            '"objectId":{"name":"' + obj + '","path":"objects/' + obj + '/' + obj + '.yy",},"properties":[' + plist + '],"resourceType":"GMRInstance",'
            '"resourceVersion":"2.0","rotation":0.0,"scaleX":' + str(float(sx)) + ',"scaleY":' + str(float(sy)) + ',"x":' + str(float(x)) + ',"y":' + str(float(y)) + ',},\n')
    return n, text


def merge_rects(mask):
    H, W = len(mask), len(mask[0])
    used = [[False] * W for _ in range(H)]
    out = []
    for r in range(H):
        for c in range(W):
            if mask[r][c] and not used[r][c]:
                w = 1
                while c + w < W and mask[r][c + w] and not used[r][c + w]:
                    w += 1
                h = 1
                while r + h < H and all(mask[r + h][c + k] and not used[r + h][c + k] for k in range(w)):
                    h += 1
                for rr in range(r, r + h):
                    for cc in range(c, c + w):
                        used[rr][cc] = True
                out.append((c, r, w, h))
    return out


def build_room(L):
    layers = {"actors": [], "logic": [], "hazards": [], "solids": []}
    order = []

    def add(layer, obj, x, y, sx=1, sy=1, props=()):
        n, t = instance(obj, x, y, sx, sy, props)
        layers[layer].append(t)
        order.append(n)

    add("logic", "obj_game", 0, 0)
    for b in range(2):
        g = L.g[b]
        y0 = b * BAND
        # solids
        mask = [[ch == "#" for ch in row] for row in g]
        for c, r, w, h in merge_rects(mask):
            add("solids", "obj_solid", c * TILE, (y0 + r) * TILE, w, h)
        # horizontal runs: tar, pools, platforms
        for r in range(BAND):
            c = 0
            while c < L.W:
                ch = g[r][c]
                if ch in "TWVU123456":
                    e = c
                    while e < L.W and g[r][e] == ch:
                        e += 1
                    w = e - c
                    x, y = c * TILE, (y0 + r) * TILE
                    if ch == "T":
                        add("hazards", "obj_tar", x, y, w, 1)
                    elif ch in "WVU":
                        d = L.pools.get(ch, {"partner": 1 if ch == "W" else 0, "signal": "", "radius": 24})
                        add("hazards", "obj_pool", x, y, w, 1, [("signal_id", d.get("signal", "")), ("use_partner_x", d.get("partner", 1)), ("safe_radius", d.get("radius", 24))])
                    else:
                        d = L.plats[ch]
                        add("logic", "obj_platform", x, y, w, 1, [("signal_id", d["signal"]), ("travel_x", d.get("tx", 0)), ("travel_y", d.get("ty", 0)),
                                                                   ("move_speed", d.get("speed", 1)), ("signal_needed", d.get("needed", 1))])
                    c = e
                else:
                    c += 1
        # gates: vertical runs per column
        for c in range(L.W):
            r = 0
            while r < BAND:
                ch = g[r][c]
                if ch in "ABCD":
                    e = r
                    while e < BAND and g[e][c] == ch:
                        e += 1
                    d = L.gates.get(ch, {})
                    add("logic", "obj_gate", c * TILE, (y0 + r) * TILE, 1, e - r,
                        [("signal_id", ch.lower()), ("signal_needed", d.get("needed", 1)), ("inverted", d.get("inverted", 0))])
                    r = e
                else:
                    r += 1
        # single-cell things
        for r in range(BAND):
            for c in range(L.W):
                ch = g[r][c]
                x, y = c * TILE, (y0 + r) * TILE
                if ch == "S":
                    add("actors", "obj_spawn", x + 8, y + 16, 1, 1, [("player_id", b)])
                elif ch == "E":
                    add("logic", "obj_exit", x, y - 16, 2, 2)
                elif ch == "o":
                    add("logic", "obj_coin", x + 8, y + 8)
                elif ch == "l":
                    rad = L.lamp_radius.get((b, c), 56)
                    add("logic", "obj_lamp", x + 8, y + 8, 1, 1, [("light_radius", rad)])
                elif ch in "><":
                    add("hazards", "obj_walker", x + 8, y + 16, 1, 1, [("dir", 1 if ch == ">" else -1)])
                elif ch in "MNO":
                    add("logic", "obj_box", x, y, 1, 1, [("link_id", ch.lower())])
                elif ch in "abcd":
                    d = L.plates.get(ch, {})
                    add("logic", "obj_plate", x, y + 12, 1, 1, [("signal_id", ch), ("latch", d.get("latch", 0)), ("activator", d.get("activator", 0))])
    for b, c0, c1, f in L.dark:
        add("logic", "obj_dark_zone", c0 * TILE, b * BAND * TILE, c1 - c0, BAND, [("feather", f)])
    for b, c, r, kind in L.tips:
        add("logic", "obj_tip", c * TILE + 8, (b * BAND + r) * TILE + 8, 1, 1, [("kind", kind)])

    def layer_json(name, depth):
        body = "".join(layers[name])
        return ('    {"$GMRInstanceLayer":"","%Name":"' + name + '","depth":' + str(depth) + ',"effectEnabled":true,"effectType":null,"gridX":16,"gridY":16,'
                '"hierarchyFrozen":false,"inheritLayerDepth":false,"inheritLayerSettings":false,"inheritSubLayers":true,"inheritVisibility":true,"instances":[\n'
                + body + '      ],"layers":[],"name":"' + name + '","properties":[],"resourceType":"GMRInstanceLayer","resourceVersion":"2.0","userdefinedDepth":false,"visible":true,},\n')

    layer_text = layer_json("actors", 0) + layer_json("logic", 100) + layer_json("hazards", 200) + layer_json("solids", 300)
    name = f"rm_level_{L.idx}"
    t = open(TEMPLATE, encoding="utf8").read()
    t = t.replace("rm_level_1", name)
    order_text = "".join('    {"name":"%s","path":"rooms/%s/%s.yy",},\n' % (n, name, name) for n in order)
    t = re.sub(r'("instanceCreationOrder":\[\n).*?(  \],\n  "isDnd")', lambda m: m.group(1) + order_text + m.group(2), t, flags=re.S)
    t = re.sub(r'("layers":\[\n).*?(  \],\n  "name":"%s")' % name, lambda m: m.group(1) + layer_text + m.group(2), t, flags=re.S)
    t = re.sub(r'"Width":\d+', '"Width":%d' % (L.W * TILE), t)
    t = re.sub(r'"Height":\d+', '"Height":%d' % (BAND * 2 * TILE), t)
    d = os.path.join(ROOT, "rooms", name)
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, name + ".yy"), "w", encoding="utf8", newline="\n") as f:
        f.write(t)
    register("rooms", name, room_order=True)


# ------------------------------------------------------------------ preview (so the layouts can be checked by eye)

COL = {"#": (90, 70, 50), "T": (40, 10, 60), "W": (60, 120, 230), "V": (60, 120, 230), "U": (230, 90, 40), "o": (255, 215, 60), "S": (60, 255, 60), "E": (255, 255, 255),
       "l": (255, 150, 30), ">": (230, 60, 60), "<": (230, 60, 60), "M": (170, 110, 40), "N": (170, 110, 40), "O": (170, 110, 40)}


def preview(L, path):
    from PIL import Image, ImageDraw
    s = 8
    im = Image.new("RGB", (L.W * s, BAND * 2 * s + 6), (30, 30, 40))
    dr = ImageDraw.Draw(im)
    for b in range(2):
        oy = b * (BAND * s + 6)
        dr.rectangle([0, oy, L.W * s, oy + BAND * s], fill=(120, 170, 200) if b == 0 else (70, 20, 30))
        for r in range(BAND):
            for c in range(L.W):
                ch = L.g[b][r][c]
                if ch == ".":
                    continue
                col = COL.get(ch)
                if col is None:
                    col = (200, 200, 200) if ch.islower() else ((230, 120, 200) if ch.isupper() else (255, 160, 220))
                dr.rectangle([c * s, oy + r * s, c * s + s - 1, oy + r * s + s - 1], fill=col)
        for bb, c0, c1, f in L.dark:
            if bb == b:
                dr.rectangle([c0 * s, oy, c1 * s, oy + BAND * s], outline=(255, 0, 255))
    im.save(path)


def main():
    import levels_data
    out = os.path.join(ROOT, "tools", "preview")
    os.makedirs(out, exist_ok=True)
    only = [int(a) for a in sys.argv[1:]]
    for L in levels_data.all_levels():
        if only and L.idx not in only:
            continue
        build_room(L)
        preview(L, os.path.join(out, f"level_{L.idx}.png"))
        print("built", L.idx, L.W)


if __name__ == "__main__":
    main()
