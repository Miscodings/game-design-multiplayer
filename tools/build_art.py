"""Builds every game sprite from art_source/ (GandalfHardcore packs): the overworld set as-is (lightly graded),
the underworld set recoloured to ember / crimson / black. Writes GameMaker sprite resources.
Run:  python tools/build_art.py
"""
import os, sys
import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from gm_sprite import write_sprite, ROOT

SRC = os.path.join(ROOT, "art_source")
PLAT = os.path.join(SRC, "GandalfHardcore FREE Platformer Assets")
CHAR = os.path.join(SRC, "GandalfHardcore Character Asset Pack")
PREVIEW = os.path.join(ROOT, "tools", "preview")
os.makedirs(PREVIEW, exist_ok=True)


def load(p):
    return Image.open(p).convert("RGBA")


# ---------------------------------------------------------------- colour grading

def gradient_map(im, stops, keep_alpha=True, lum_gamma=1.0):
    """Recolour by luminance through a ramp: stops = [(lum 0..1, (r,g,b)), ...]."""
    a = np.array(im).astype(np.float32)
    lum = (0.299 * a[..., 0] + 0.587 * a[..., 1] + 0.114 * a[..., 2]) / 255.0
    lum = np.clip(lum, 0, 1) ** lum_gamma
    xs = [s[0] for s in stops]
    out = np.zeros(a.shape, dtype=np.float32)
    for c in range(3):
        out[..., c] = np.interp(lum, xs, [s[1][c] for s in stops])
    out[..., 3] = a[..., 3]
    return Image.fromarray(out.astype(np.uint8), "RGBA")


HELL_GROUND = [(0.0, (8, 3, 10)), (0.10, (26, 9, 18)), (0.22, (52, 16, 24)), (0.45, (150, 34, 30)),
               (0.65, (232, 84, 34)), (1.0, (255, 214, 120))]
HELL_SKY = [(0.0, (14, 4, 16)), (0.5, (70, 14, 34)), (0.8, (160, 40, 40)), (1.0, (250, 120, 60))]
HELL_FAR = [(0.0, (10, 3, 12)), (0.5, (44, 10, 26)), (1.0, (110, 26, 38))]
HELL_MID = [(0.0, (6, 2, 8)), (0.5, (30, 8, 20)), (1.0, (80, 18, 30))]
HELL_FIRE = [(0.0, (30, 0, 40)), (0.4, (150, 20, 120)), (0.7, (255, 80, 160)), (1.0, (255, 220, 240))]
HELL_PORTAL_BRIGHT = [(0.0, (10, 2, 14)), (0.3, (120, 20, 40)), (1.0, (255, 150, 70))]


def hue_shift(im, deg_shift, sat=1.0, val=1.0):
    hsv = np.array(im.convert("RGB").convert("HSV")).astype(np.float32)
    hsv[..., 0] = (hsv[..., 0] + deg_shift / 360.0 * 255.0) % 255.0
    hsv[..., 1] = np.clip(hsv[..., 1] * sat, 0, 255)
    hsv[..., 2] = np.clip(hsv[..., 2] * val, 0, 255)
    rgb = Image.fromarray(hsv.astype(np.uint8), "HSV").convert("RGB")
    out = rgb.convert("RGBA")
    out.putalpha(im.getchannel("A"))
    return out


def tint(im, mul):
    a = np.array(im).astype(np.float32)
    for c in range(3):
        a[..., c] = np.clip(a[..., c] * mul[c], 0, 255)
    return Image.fromarray(a.astype(np.uint8), "RGBA")


def crop_alpha(im):
    bb = im.getchannel("A").getbbox()
    return im.crop(bb) if bb else im


# ---------------------------------------------------------------- terrain
def terrain():
    # Floor Tiles1: three seasons, 6 tile rows each. Block 0 is green grass, block 1 autumn.
    sheet = load(os.path.join(PLAT, "Floor Tiles1.png"))
    green = sheet.crop((0, 0, 288, 192))
    autumn = sheet.crop((0, 192, 288, 384))
    write_sprite("spr_ground_o", [green], 0, 0)
    write_sprite("spr_ground_u", [gradient_map(autumn, HELL_GROUND, lum_gamma=0.9)], 0, 0)
    green.save(os.path.join(PREVIEW, "ground_o.png"))
    gradient_map(autumn, HELL_GROUND, lum_gamma=0.9).save(os.path.join(PREVIEW, "ground_u.png"))

    # wooden moving platform strips (Other Tiles1 row 6: 5 plank pieces, 32 px wide, ~12 px tall)
    other = load(os.path.join(PLAT, "Other Tiles1.png"))
    planks = [other.crop((i * 32, 6 * 32, i * 32 + 32, 6 * 32 + 6)) for i in range(5)]   # one board, 6 px tall
    return planks


# ---------------------------------------------------------------- backgrounds
def backgrounds():
    base = os.path.join(PLAT, "GandalfHardcore Background layers", "Normal BG")
    names = [f"GandalfHardcore Background layers_layer {i}.png" for i in (5, 4, 3, 2, 1)]  # far -> near
    ramps = [HELL_SKY, HELL_FAR, HELL_MID, HELL_MID, HELL_MID]
    for i, n in enumerate(names):
        im = load(os.path.join(base, n))
        o = im
        if i == 0:
            # dusk-gold overworld sky: keep the gradient but warm it up a touch
            o = tint(im, (1.0, 0.97, 0.9))
        write_sprite(f"spr_bg_o{i}", [o], 0, 0)
        u = gradient_map(im, ramps[i], lum_gamma=1.0)
        write_sprite(f"spr_bg_u{i}", [u], 0, 0)
        o.save(os.path.join(PREVIEW, f"bg_o{i}.png"))
        u.save(os.path.join(PREVIEW, f"bg_u{i}.png"))


# ---------------------------------------------------------------- characters
def compose(layer_paths, tintmul=None):
    base = Image.new("RGBA", (800, 448), (0, 0, 0, 0))
    for p, t in layer_paths:
        im = load(p)
        if t:
            im = tint(im, t)
        base.alpha_composite(im)
    return base


def frames_from(sheet):
    rows = [(0, 5), (1, 8), (2, 8), (3, 4), (4, 4), (6, 10)]   # idle, walk, run, jump, fall, death
    out = []
    for r, n in rows:
        for c in range(n):
            f = sheet.crop((c * 80, r * 64, c * 80 + 80, r * 64 + 64))
            if r == 2:   # the run row of the pack faces left; every other row faces right
                f = f.transpose(Image.FLIP_LEFT_RIGHT)
            out.append(f)
    return out


def characters():
    mp = lambda *a: os.path.join(CHAR, *a)
    # P1: overworld hero, warm cream tunic, brown hair
    a = compose([
        (mp("Character skin colors", "Male Skin1.png"), None),
        (mp("Male Clothing", "Pants.png"), (0.75, 0.62, 0.5)),
        (mp("Male Clothing", "Shirt v2.png"), (1.0, 0.95, 0.8)),
        (mp("Male Clothing", "Boots.png"), None),
        (mp("Male Hair", "Male Hair1.png"), (1.0, 0.85, 0.6)),
    ])
    # P2: underworld twin, same sprites recoloured to ember red / black with pale skin
    b_layers = [
        (mp("Character skin colors", "Male Skin5.png"), None),
        (mp("Male Clothing", "Pants.png"), None),
        (mp("Male Clothing", "Shirt v2.png"), None),
        (mp("Male Clothing", "Boots.png"), None),
        (mp("Male Hair", "Male Hair1.png"), None),
    ]
    b = compose(b_layers)
    b = gradient_map(b, [(0.0, (8, 2, 12)), (0.18, (60, 10, 22)), (0.45, (190, 40, 36)), (0.75, (255, 120, 64)),
                         (1.0, (255, 232, 190))], lum_gamma=0.6)
    fa, fb = frames_from(a), frames_from(b)
    write_sprite("spr_hero_a", fa, 39, 64)
    write_sprite("spr_hero_b", fb, 39, 64)
    # preview strip
    strip = Image.new("RGBA", (80 * 8, 64 * 2), (60, 60, 80, 255))
    for i in range(8):
        strip.alpha_composite(fa[5 + i], (i * 80, 0))
        strip.alpha_composite(fb[5 + i], (i * 80, 64))
    strip.save(os.path.join(PREVIEW, "heroes.png"))


# ---------------------------------------------------------------- props, torches, portals
def props(planks):
    dec = load(os.path.join(PLAT, "Decor.png"))

    def cut(x, y, w, h):
        return crop_alpha(dec.crop((x, y, x + w, y + h)))

    items_o = {
        "bush_big": cut(0, 416, 64, 32), "bush_small": cut(64, 416, 32, 32), "fern": cut(96, 416, 32, 32),
        "rock_big": cut(0, 256, 96, 64), "rock_mid": cut(96, 224, 64, 32), "rock_small": cut(0, 224, 32, 32),
        "grass_a": cut(0, 128, 32, 32), "grass_b": cut(32, 128, 32, 32), "grass_c": cut(64, 128, 32, 32),
        "barrel": cut(64, 0, 32, 32), "crate": cut(32, 0, 32, 32), "stump": cut(192, 0, 32, 32),
        "statue": cut(384, 256, 32, 64), "scarecrow": cut(288, 192, 32, 64),
        "tomb_a": cut(192, 96, 32, 32), "tomb_b": cut(224, 96, 32, 32), "tomb_c": cut(256, 96, 32, 32),
        "cross": cut(288, 96, 32, 32), "pumpkin": cut(352, 96, 32, 32),
    }
    for k, im in items_o.items():
        write_sprite(f"spr_deco_o_{k}", [im], im.width // 2, im.height)
        write_sprite(f"spr_deco_u_{k}", [gradient_map(im, HELL_GROUND, lum_gamma=0.8)], im.width // 2, im.height)
        items_o[k].save(os.path.join(PREVIEW, f"deco_{k}.png"))

    # the linked crate: one square 32 x 32 sprite per dimension
    crate = items_o["crate"]
    box_o = crate.resize((32, 32), Image.NEAREST)
    write_sprite("spr_crate_o", [box_o], 16, 32)
    box_u = gradient_map(box_o, [(0.0, (6, 2, 10)), (0.3, (60, 14, 28)), (0.6, (180, 40, 34)), (1.0, (255, 170, 80))])
    write_sprite("spr_crate_u", [box_u], 16, 32)

    # platform planks (one 32px piece; the game tiles it)
    p = planks[2]
    write_sprite("spr_plank_o", [p], 0, 0)
    write_sprite("spr_plank_u", [gradient_map(p, HELL_GROUND)], 0, 0)

    # torches (lit frames: row 1 = 6 frames of 32 x 32)
    tor = load(os.path.join(PLAT, "Torch.png"))
    fr = [tor.crop((i * 32, 32, i * 32 + 32, 64)) for i in range(6)]
    write_sprite("spr_torch_o", fr, 16, 32)
    write_sprite("spr_torch_u", [gradient_map(f, HELL_FIRE, lum_gamma=0.9) for f in fr], 16, 32)

    # exit portals (10 frames, 64 x 64)
    port = load(os.path.join(PLAT, "Animated Sprites", "GandalfHardcore Portal sheet.png"))
    pf = [port.crop((i * 64, 0, i * 64 + 64, 64)) for i in range(10)]
    # overworld: the same dark shape glowing sky-blue / gold; underworld: ember
    po = [gradient_map(f, [(0.0, (16, 24, 70)), (0.2, (40, 80, 190)), (0.5, (120, 200, 255)), (1.0, (255, 250, 210))],
                       lum_gamma=0.6) for f in pf]
    # the original is mostly near-black with sparks: lift it so it reads as a glowing gate
    write_sprite("spr_portal_o", po, 32, 64)
    pu = [gradient_map(f, HELL_PORTAL_BRIGHT, lum_gamma=0.55) for f in pf]
    write_sprite("spr_portal_u", pu, 32, 64)
    po[3].save(os.path.join(PREVIEW, "portal_o.png"))
    pu[3].save(os.path.join(PREVIEW, "portal_u.png"))

    # sky bits: clouds (overworld) and sun
    for i in range(1, 7):
        c = load(os.path.join(PLAT, f"cloud{i}.png"))
        write_sprite(f"spr_cloud{i}", [c], c.width // 2, c.height // 2)
    sun = load(os.path.join(PLAT, "sun.png"))
    write_sprite("spr_sun", [sun], 16, 16)


# ---------------------------------------------------------------- generated creatures and coins
def _outline(mask):
    """Pixels of `mask` that touch the outside (4-neighbourhood)."""
    m = mask
    up = np.pad(m, ((1, 0), (0, 0)))[:-1, :]
    dn = np.pad(m, ((0, 1), (0, 0)))[1:, :]
    lf = np.pad(m, ((0, 0), (1, 0)))[:, :-1]
    rt = np.pad(m, ((0, 0), (0, 1)))[:, 1:]
    return m & ~(up & dn & lf & rt)


def slime_frames(pal):
    out = []
    hs = [18, 17, 15, 17]
    ws = [26, 28, 31, 28]
    yy, xx = np.mgrid[0:32, 0:32]
    for h, w in zip(hs, ws):
        a, b, base = w / 2.0, float(h), 30.0
        body = (((xx - 15.5) / a) ** 2 + ((yy - base) / b) ** 2 <= 1.0) & (yy <= base)
        edge = _outline(body)
        img = np.zeros((32, 32, 4), dtype=np.uint8)
        top = base - b
        for y in range(32):
            for x in range(32):
                if not body[y, x]:
                    continue
                t = (y - top) / b
                col = pal["light"] if t < 0.22 else (pal["body"] if t < 0.62 else pal["dark"])
                if edge[y, x]:
                    col = pal["line"]
                img[y, x] = (*col, 255)
        # glossy highlight
        hx, hy = int(15.5 - a * 0.45), int(top + b * 0.25)
        for dx, dy in [(0, 0), (1, 0), (2, 0), (0, 1)]:
            if body[hy + dy, hx + dx]:
                img[hy + dy, hx + dx] = (*pal["shine"], 255)
        # eyes
        ey = int(base - b * 0.55)
        for ex in (int(15.5 - a * 0.32), int(15.5 + a * 0.32) - 2):
            for dx in range(3):
                for dy in range(4):
                    img[ey + dy, ex + dx] = (*pal["eye"], 255)
            img[ey + 1:ey + 4, ex + 1] = (*pal["pupil"], 255)
        out.append(Image.fromarray(img, "RGBA"))
    return out


def coin_frames(pal):
    out = []
    yy, xx = np.mgrid[0:24, 0:24]
    for i in range(8):
        import math
        c = abs(math.cos(i * math.pi / 8 * 1.0 + 0.0))
        c = abs(math.cos(i * math.pi / 8))
        a = max(2.2, 10.0 * c)
        disk = (((xx - 11.5) / a) ** 2 + ((yy - 11.5) / 10.0) ** 2 <= 1.0)
        edge = _outline(disk)
        inner = (((xx - 11.5) / max(1.0, a - 2.2)) ** 2 + ((yy - 11.5) / 7.8) ** 2 <= 1.0)
        img = np.zeros((24, 24, 4), dtype=np.uint8)
        img[disk] = (*pal["rim"], 255)
        img[inner & disk] = (*pal["face"], 255)
        img[edge] = (*pal["line"], 255)
        if c > 0.55:
            # an embossed diamond on the face
            for d in range(-4, 5):
                w = 4 - abs(d)
                for e in range(-w, w + 1):
                    img[int(11.5 + d), int(11.5 + e)] = (*pal["rim"], 255)
            img[8:10, 8:12] = (*pal["shine"], 255) if False else img[8:10, 8:12]
        # sparkle on the upper left of the lit face
        sx = int(11.5 - a * 0.45)
        if disk[6, max(sx, 0)]:
            img[5:8, max(sx, 0):max(sx, 0) + 2] = (*pal["shine"], 255)
        out.append(Image.fromarray(img, "RGBA"))
    return out


def creatures():
    over = dict(line=(46, 24, 64), dark=(116, 62, 156), body=(176, 100, 206), light=(216, 156, 238), shine=(255, 240, 255),
                eye=(250, 250, 250), pupil=(30, 14, 44))
    under = dict(line=(34, 4, 10), dark=(140, 30, 24), body=(226, 70, 30), light=(255, 150, 60), shine=(255, 236, 170),
                 eye=(255, 236, 120), pupil=(60, 0, 0))
    write_sprite("spr_slime_o", slime_frames(over), 16, 32)
    write_sprite("spr_slime_u", slime_frames(under), 16, 32)
    gold = dict(line=(104, 58, 8), rim=(224, 160, 30), face=(255, 214, 72), shine=(255, 248, 190))
    ember = dict(line=(56, 4, 14), rim=(190, 36, 40), face=(255, 112, 60), shine=(255, 226, 170))
    write_sprite("spr_coin_o", coin_frames(gold), 12, 12)
    write_sprite("spr_coin_u", coin_frames(ember), 12, 12)
    sl = slime_frames(over)
    co = coin_frames(gold)
    sheet = Image.new("RGBA", (32 * 4 + 24 * 8, 32), (70, 70, 90, 255))
    for k, f in enumerate(sl):
        sheet.alpha_composite(f, (k * 32, 0))
    for k, f in enumerate(co):
        sheet.alpha_composite(f, (128 + k * 24, 4))
    for k, f in enumerate(slime_frames(under)):
        sheet.alpha_composite(f, (k * 32, 0)) if False else None
    sheet.save(os.path.join(PREVIEW, "creatures.png"))
    under_s = Image.new("RGBA", (32 * 4 + 24 * 8, 32), (70, 70, 90, 255))
    for k, f in enumerate(slime_frames(under)):
        under_s.alpha_composite(f, (k * 32, 0))
    for k, f in enumerate(coin_frames(ember)):
        under_s.alpha_composite(f, (128 + k * 24, 4))
    under_s.save(os.path.join(PREVIEW, "creatures_u.png"))

    # the player's collision box: 10 x 22 units, feet on the bottom edge
    mask = Image.new("RGBA", (10, 22), (0, 0, 0, 0))
    write_sprite("spr_player", [mask], 5, 22)


def main():
    planks = terrain()
    backgrounds()
    characters()
    props(planks)
    creatures()
    print("art built")


if __name__ == "__main__":
    main()
