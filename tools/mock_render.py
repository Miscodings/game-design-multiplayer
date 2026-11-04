"""Approximate render of what the game draws (terrain autotiles, parallax, props, hero) so the look can be checked
without launching GameMaker.   python tools/mock_render.py <level> <start_col> [out.png]"""
import os, sys, glob
from PIL import Image
sys.path.insert(0, os.path.dirname(__file__))
from gm_sprite import ROOT
import levels_data
from build_levels import BAND

TILE = 16
VIEW_W, VIEW_H = 640, 180


def spr(name, frame=0):
    d = os.path.join(ROOT, "sprites", name)
    pngs = sorted(glob.glob(os.path.join(d, "*.png")))
    if frame >= len(pngs):
        frame = 0
    # frame order follows the .yy; for single-frame sprites any png is fine, for multi-frame sprites read the yy
    import re
    yy = open(os.path.join(d, name + ".yy"), encoding="utf8").read()
    ids = re.findall(r'"%Name":"([0-9a-f\-]{36})","name"', yy)
    return Image.open(os.path.join(d, ids[frame] + ".png")).convert("RGBA")


def render(level_idx, start_col, out):
    L = [l for l in levels_data.all_levels() if l.idx == level_idx][0]
    cam_x = start_col * TILE
    img = Image.new("RGBA", (1280, 740), (0, 0, 0, 255))
    for d in range(2):
        k = "o" if d == 0 else "u"
        view = Image.new("RGBA", (1280, 360), (0, 0, 0, 255))
        # sky + layers (screen px = 2 * units; art at 1:1 screen px)
        sky = spr(f"spr_bg_{k}0").resize((1280, 360), Image.NEAREST)
        view.alpha_composite(sky)
        for l, f in zip(range(1, 5), [0.07, 0.14, 0.24, 0.38]):
            im = spr(f"spr_bg_{k}{l}")
            w = im.width
            x0 = -int((cam_x * f * 2) % w)
            for xx in range(x0 - w, 1280, w):
                view.alpha_composite(im, (xx, 360 - im.height))
        ground = spr(f"spr_ground_{k}")
        grid = L.g[d]

        def solid(c, r):
            if c < 0 or c >= L.W or r < 0 or r >= BAND:
                return True
            return grid[r][c] in "#TWVU"

        def pick(u, dn, l, r, ul, ur):
            if not u and not dn:
                c = 6 if (not l and not r) else (6 if not l else (8 if not r else 7))
                return c, 5
            if not l and not r:
                if not dn:
                    return 6, 4
                if not u:
                    return 6, 3
                return 1, 1
            c = 0 if not l else (2 if not r else 1)
            row = 0 if not u else (2 if not dn else 1)
            return c, row

        c0 = start_col - 1
        for r in range(BAND):
            for c in range(c0, c0 + 42):
                if c < 0 or c >= L.W or grid[r][c] != "#":
                    continue
                t = pick(solid(c, r - 1), solid(c, r + 1), solid(c - 1, r), solid(c + 1, r), solid(c - 1, r - 1), solid(c + 1, r - 1))
                tile = ground.crop((t[0] * 32, t[1] * 32, t[0] * 32 + 32, t[1] * 32 + 32))
                view.alpha_composite(tile, ((c - start_col) * 32, r * 32 - 24))
        # hero standing on the first floor cell found at spawn
        hero = spr("spr_hero_a" if d == 0 else "spr_hero_b", 0)
        for r in range(BAND):
            for c in range(L.W):
                ch = grid[r][c]
                px = (c - start_col) * 32 + 16
                py = (r + 1) * 32 - 24
                if ch == "S" and c >= start_col - 2 and c < start_col + 40:
                    view.alpha_composite(hero, (px - 39, py - 64))
                if ch in "><" and start_col <= c < start_col + 40:
                    view.alpha_composite(spr(f"spr_slime_{k}", 0), (px - 16, py - 32))
                if ch == "o" and start_col <= c < start_col + 40:
                    view.alpha_composite(spr(f"spr_coin_{k}", 0), (px - 12, py - 16 - 8))
                if ch == "E" and start_col <= c < start_col + 40:
                    view.alpha_composite(spr(f"spr_portal_{k}", 3), (px + 16 - 32, py - 64 + 32 + 0))
        img.paste(view.convert("RGB"), (0, d * 380))
    img.save(out)


if __name__ == "__main__":
    lvl = int(sys.argv[1]); col = int(sys.argv[2])
    out = sys.argv[3] if len(sys.argv) > 3 else os.path.join(ROOT, "tools", "preview", f"mock_{lvl}.png")
    render(lvl, col, out)
    print(out)
