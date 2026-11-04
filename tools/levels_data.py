"""The eight levels. Band 0 is the overworld (top), band 1 the underworld (bottom).
Rules of thumb used everywhere: floor top = row 10; a jump clears 2 tiles up and about 3 tiles across; gaps in the
floor are one tile deep (walkable) unless noted; hazards sit in pits with a solid bed under them."""
import random
from build_levels import Level, BAND


def base(L, ceiling=True, seed=0):
    """Floor along the whole level in both worlds, and a cave roof with stalactites in the underworld."""
    rnd = random.Random(L.idx * 101 + seed)
    for b in range(2):
        L.ground(b, 0, L.W)
    if ceiling:
        L.ceiling(1, 0, L.W, 2)
        c = 6
        while c < L.W - 6:
            L.hang(1, c, rnd.choice([1, 1, 2]), rnd.choice([2, 2, 3]), r0=2)
            c += rnd.randint(6, 12)


def both(L, fn):
    for b in (0, 1):
        fn(b)


def starts(L, c=3, exit_c=None):
    for b in (0, 1):
        L.spawn(b, c)
        L.exit(b, exit_c if exit_c is not None else L.W - 6)


def level1():
    L = Level(1, 100)
    base(L)
    starts(L)
    # overworld: rolling hills and a dip
    L.ground(0, 24, 32, top=9)
    L.ground(0, 32, 40, top=8)
    L.ground(0, 40, 46, top=9)
    L.gap(0, 58, 61)
    L.ground(0, 70, 78, top=9)
    L.ground(0, 82, 86, top=9)
    # underworld: a different rhythm
    L.ground(1, 20, 26, top=9)
    L.ground(1, 36, 44, top=9)
    L.ground(1, 44, 50, top=8)
    L.gap(1, 56, 59)
    L.ground(1, 66, 72, top=9)
    L.ground(1, 78, 84, top=9)
    # coins
    L.line_coins(0, 8, 20, 9, 3)
    L.coins(0, [(26, 8), (28, 8), (34, 7), (36, 7), (42, 8), (58, 8), (59, 7), (60, 8), (72, 8), (74, 8)])
    L.line_coins(0, 88, 92, 9, 2)
    L.line_coins(1, 8, 17, 9, 3)
    L.coins(1, [(22, 8), (24, 8), (38, 8), (40, 8), (46, 7), (48, 7), (56, 8), (57, 7), (58, 8), (68, 8), (70, 8), (80, 8), (82, 8)])
    L.line_coins(1, 88, 92, 9, 2)
    # instructions
    for b in (0, 1):
        L.tip(b, 6, 5, "move")
        L.tip(b, 20 if b == 0 else 16, 5, "jump")
        L.tip(b, 13 if b == 0 else 10, 6, "coin")
        L.tip(b, 88, 4, "exit")
    L.tip(0, 52, 5, "shared")
    return L


def level2():
    L = Level(2, 112)
    base(L)
    starts(L)
    # --- plate in the overworld opens a gate in the underworld
    L.set(0, 22, 9, "a")
    L.rect(1, 30, 31, 5, 9, "A")
    L.tip(0, 20, 5, "plate")
    L.tip(1, 26, 4, "gate")
    # --- and the other way round
    L.set(1, 54, 9, "b")
    L.rect(0, 62, 63, 5, 9, "B")
    L.tip(1, 52, 4, "plate")
    L.tip(0, 58, 4, "gate")
    # --- both plates together (latched), then both gates open
    L.set(0, 84, 9, "c")
    L.set(1, 84, 9, "c")
    L.rect(0, 92, 93, 5, 9, "C")
    L.rect(1, 92, 93, 5, 9, "C")
    L.plates["c"] = {"latch": 1}
    L.plates["a"] = {}
    L.plates["b"] = {}
    L.gates["C"] = {"needed": 2}
    L.tip(0, 80, 4, "plate")
    L.tip(1, 80, 4, "plate")
    # terrain variety
    L.ground(0, 10, 16, top=9)
    L.ground(0, 36, 44, top=9)
    L.ground(0, 70, 78, top=9)
    L.ground(1, 12, 18, top=9)
    L.ground(1, 40, 48, top=9)
    L.ground(1, 70, 80, top=9)
    L.line_coins(0, 8, 18, 8, 3)
    L.coins(0, [(37, 8), (39, 8), (41, 8), (71, 8), (73, 8), (75, 8), (66, 9), (68, 9)])
    L.line_coins(1, 6, 16, 8, 3)
    L.coins(1, [(33, 9), (35, 9), (41, 8), (43, 8), (45, 8), (72, 8), (74, 8), (76, 8)])
    L.line_coins(0, 100, 104, 9, 2)
    L.line_coins(1, 100, 104, 9, 2)
    for b in (0, 1):
        L.tip(b, 6, 5, "move")
        L.tip(b, 100, 4, "exit")
    return L


def level3():
    L = Level(3, 112)
    base(L)
    starts(L)
    # overworld
    L.pit(0, 26, 29)
    L.pit(0, 70, 73)
    L.pit(0, 78, 81)
    L.rect(0, 38, 40, 8, 9)
    L.rect(0, 58, 60, 8, 9)
    L.set(0, 44, 9, ">")
    L.set(0, 52, 9, "<")
    L.ground(0, 88, 94, top=9)
    L.coins(0, [(26, 7), (27, 6), (28, 7), (70, 7), (71, 6), (72, 7), (78, 7), (79, 6), (80, 7), (47, 8), (49, 8)])
    L.line_coins(0, 8, 20, 9, 3)
    # underworld
    L.pit(1, 22, 25)
    L.pit(1, 60, 63)
    L.pit(1, 68, 71)
    L.rect(1, 36, 38, 8, 9)
    L.rect(1, 52, 54, 8, 9)
    L.set(1, 42, 9, "<")
    L.set(1, 46, 9, ">")
    L.rect(1, 76, 80, 8, 8)
    L.ground(1, 90, 96, top=9)
    L.coins(1, [(22, 7), (23, 6), (24, 7), (60, 7), (61, 6), (62, 7), (68, 7), (69, 6), (70, 7), (77, 7), (78, 7), (79, 7)])
    L.line_coins(1, 8, 18, 9, 3)
    for b in (0, 1):
        L.tip(b, 6, 5, "move")
        L.tip(b, 18 if b == 0 else 14, 4, "tar")
        L.tip(b, 32 if b == 0 else 30, 4, "stomp")
        L.tip(b, 100, 4, "exit")
    return L


def level4():
    L = Level(4, 104)
    base(L)
    starts(L)
    # --- puzzle A: push the boxes against the wall and climb them
    for b in (0, 1):
        L.rect(b, 40, 42, 7, 9)
        L.set(b, 30, 9, "M")
        L.tip(b, 27, 4, "box")
    L.line_coins(0, 33, 37, 9, 2)
    L.line_coins(1, 33, 37, 9, 2)
    L.coins(0, [(40, 5), (41, 5)])
    L.coins(1, [(40, 5), (41, 5)])
    # --- puzzle B: both boxes onto both plates, then both gates open
    for b in (0, 1):
        L.set(b, 62, 9, "N")
        L.rect(b, 71, 73, 8, 9)
        L.set(b, 70, 9, "a" if b == 0 else "b")
        L.rect(b, 80, 81, 5, 9, "A" if b == 1 else "B")
    # plate "a" (overworld) opens gate "A" (underworld) and "b" opens "B"
    L.plates["a"] = {"activator": 1}
    L.plates["b"] = {"activator": 1}
    L.line_coins(0, 64, 68, 9, 2)
    L.line_coins(1, 64, 68, 9, 2)
    L.coins(0, [(71, 6), (72, 6)])
    L.coins(1, [(71, 6), (72, 6)])
    L.line_coins(0, 86, 94, 9, 2)
    L.line_coins(1, 86, 94, 9, 2)
    for b in (0, 1):
        L.tip(b, 6, 5, "move")
        L.tip(b, 100, 4, "exit")
    L.tip(0, 50, 4, "coin")
    L.tip(1, 50, 4, "coin")
    return L


def level5():
    L = Level(5, 124)
    base(L)
    starts(L)
    # overworld is dark from col 30 to 64: tar pits and a walker hide in there; the partner's glow shows the way
    L.dark_zone(0, 30, 64, 40)
    L.pit(0, 40, 43)
    L.pit(0, 52, 55)
    L.set(0, 60, 9, "<")
    L.rect(0, 47, 49, 8, 9)
    L.set(0, 27, 9, "l")
    L.set(0, 66, 9, "l")
    L.line_coins(0, 34, 38, 9, 2)
    L.coins(0, [(41, 7), (42, 6), (53, 7), (54, 6), (49, 9), (50, 9)])
    # underworld is dark from col 72 to 106
    L.dark_zone(1, 72, 106, 40)
    L.pit(1, 82, 85)
    L.pit(1, 92, 95)
    L.set(1, 100, 9, "<")
    L.rect(1, 88, 90, 8, 9)
    L.set(1, 69, 9, "l")
    L.set(1, 108, 9, "l")
    L.line_coins(1, 76, 80, 9, 2)
    L.coins(1, [(83, 7), (84, 6), (93, 7), (94, 6), (90, 9), (91, 9)])
    # lit parts: ordinary hills
    L.ground(0, 76, 84, top=9)
    L.ground(0, 96, 104, top=9)
    L.ground(1, 20, 26, top=9)
    L.ground(1, 40, 48, top=9)
    L.line_coins(0, 8, 20, 9, 3)
    L.line_coins(1, 8, 17, 9, 3)
    for b in (0, 1):
        L.tip(b, 6, 5, "move")
        L.tip(b, 118, 4, "exit")
    L.tip(0, 21, 4, "partner")
    L.tip(1, 63, 4, "partner")
    return L


def level6():
    L = Level(6, 116)
    base(L)
    starts(L)
    # overworld water: cross it while your partner walks beside you
    L.pit(0, 28, 38, "W")
    L.tip(0, 22, 4, "water")
    L.coins(0, [(31, 10), (33, 10), (35, 10)])
    # underworld lava
    L.pit(1, 60, 70, "W")
    L.tip(1, 54, 4, "water")
    L.coins(1, [(63, 10), (65, 10), (67, 10)])
    # drained by plates
    L.pit(0, 86, 94, "V")
    L.pools["V"] = {"signal": "a", "partner": 0}
    L.set(1, 82, 9, "a")
    L.plates["a"] = {"latch": 1}
    # a second drained pool (signal b) in the underworld, its plate in the overworld
    L.pit(1, 96, 104, "U")
    L.pools["U"] = {"signal": "b", "partner": 0}
    L.set(0, 97, 9, "b")
    L.plates["b"] = {"latch": 1}
    L.ground(0, 14, 20, top=9)
    L.ground(0, 44, 52, top=9)
    L.ground(1, 14, 20, top=9)
    L.ground(1, 40, 48, top=9)
    L.line_coins(0, 8, 14, 9, 3)
    L.line_coins(1, 8, 14, 9, 3)
    L.coins(0, [(45, 8), (47, 8), (49, 8), (88, 10), (90, 10), (92, 10)])
    L.coins(1, [(41, 8), (43, 8), (45, 8), (98, 10), (100, 10), (102, 10)])
    for b in (0, 1):
        L.tip(b, 6, 5, "move")
        L.tip(b, 110, 4, "exit")
    return L


def level7():
    L = Level(7, 128)
    base(L)
    starts(L)
    # overworld gap with a platform; the underworld partner stands on a plate to carry it across
    L.clear(0, 40, 49, 10, 11)
    L.set(0, 40, 10, "1")
    L.set(0, 41, 10, "1")
    L.set(0, 42, 10, "1")
    L.plats["1"] = {"signal": "a", "tx": 96, "speed": 1}
    L.set(1, 30, 9, "a")
    L.plates["a"] = {}
    # underworld gap, platform carried by a plate in the overworld
    L.clear(1, 62, 71, 10, 11)
    L.set(1, 62, 10, "2")
    L.set(1, 63, 10, "2")
    L.set(1, 64, 10, "2")
    L.plats["2"] = {"signal": "b", "tx": 96, "speed": 1}
    L.set(0, 56, 9, "b")
    L.plates["b"] = {}
    # a tar-and-walker stretch to finish
    L.pit(0, 84, 87)
    L.pit(0, 94, 97)
    L.set(0, 104, 9, "<")
    L.pit(1, 82, 85)
    L.pit(1, 96, 99)
    L.set(1, 106, 9, "<")
    L.rect(0, 100, 102, 8, 9)
    L.rect(1, 102, 104, 8, 9)
    L.ground(0, 18, 26, top=9)
    L.ground(1, 14, 22, top=9)
    L.line_coins(0, 8, 16, 9, 3)
    L.line_coins(1, 8, 12, 9, 3)
    L.coins(0, [(44, 8), (46, 8), (84, 7), (85, 6), (86, 7), (94, 7), (95, 6), (96, 7), (20, 8), (22, 8), (24, 8)])
    L.coins(1, [(66, 8), (68, 8), (82, 7), (83, 6), (84, 7), (96, 7), (97, 6), (98, 7), (16, 8), (18, 8), (20, 8)])
    for b in (0, 1):
        L.tip(b, 6, 5, "move")
        L.tip(b, 122, 4, "exit")
    L.tip(0, 36, 4, "gate")
    L.tip(1, 26, 4, "plate")
    return L


def level8():
    L = Level(8, 156)
    base(L)
    starts(L)
    # --- A: tar and slimes (cols 14-44)
    L.pit(0, 16, 19)
    L.set(0, 28, 9, ">")
    L.rect(0, 22, 24, 8, 9)
    L.rect(0, 34, 36, 8, 9)
    L.pit(1, 20, 23)
    L.set(1, 30, 9, "<")
    L.rect(1, 26, 28, 8, 9)
    L.rect(1, 38, 40, 8, 9)
    L.coins(0, [(16, 7), (17, 6), (18, 7), (29, 8)])
    L.coins(1, [(20, 7), (21, 6), (22, 7), (31, 8)])
    # --- B: dark cave with a box wall in the underworld (cols 46-80)
    L.dark_zone(1, 46, 82, 40)
    L.set(1, 44, 9, "l")
    L.set(1, 84, 9, "l")
    L.set(1, 54, 9, "M")
    L.rect(1, 64, 66, 7, 9)
    L.pit(1, 72, 75)
    L.set(0, 54, 9, "M")
    L.rect(0, 64, 66, 7, 9)
    L.pit(0, 72, 75)
    L.coins(0, [(58, 9), (60, 9), (73, 7), (74, 6)])
    L.coins(1, [(58, 9), (60, 9), (73, 7), (74, 6)])
    # --- C: cross the water together (cols 88-112)
    L.pit(0, 90, 99, "W")
    L.pit(1, 100, 109, "W")
    L.coins(0, [(93, 10), (95, 10), (97, 10)])
    L.coins(1, [(103, 10), (105, 10), (107, 10)])
    # --- D: plates, gate and a platform (cols 114-148)
    L.set(0, 116, 9, "a")
    L.rect(1, 122, 123, 5, 9, "A")
    L.plates["a"] = {"latch": 1}
    L.clear(0, 128, 137, 10, 11)
    for c in (128, 129, 130):
        L.set(0, c, 10, "1")
    L.plats["1"] = {"signal": "b", "tx": 96, "speed": 1}
    L.set(1, 126, 9, "b")
    L.plates["b"] = {}
    L.coins(0, [(132, 8), (134, 8), (136, 8)])
    L.coins(1, [(128, 8), (130, 8), (132, 8)])
    L.set(0, 142, 9, "o")
    for b in (0, 1):
        L.tip(b, 6, 5, "move")
        L.tip(b, 150, 4, "exit")
    L.tip(0, 12, 4, "tar")
    L.tip(1, 14, 4, "tar")
    return L


def all_levels():
    return [level1(), level2(), level3(), level4(), level5(), level6(), level7(), level8()]
