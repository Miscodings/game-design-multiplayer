"""Adds the title room (rm_title) and its object, and makes it the first room. Idempotent."""
import os, re, sys
sys.path.insert(0, os.path.dirname(__file__))
from gm_sprite import ROOT, YYP, register
from gm_object import write_object
from build_levels import instance

GAME_TITLE_1 = "ABOVE"
GAME_TITLE_2 = "BELOW"

write_object("obj_title", "core", None, {
    "create": """// Title screen: the two worlds, split, with the two heroes waiting.
theme_init();
art_init();
window_setup();
t = 0;
""",
    "step": """t++;
if (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space)) room_goto(rm_level_1);
if (keyboard_check_pressed(vk_escape)) game_end();
// jump straight to a level while testing: hold Shift and press 1-8
if (keyboard_check(vk_shift)) {
    for (var i = 1; i <= 8; i++) {
        if (keyboard_check_pressed(ord(string(i)))) {
            var _rm = asset_get_index("rm_level_" + string(i));
            if (room_exists(_rm)) room_goto(_rm);
        }
    }
}""",
    "draw_gui": "title_draw();",
})

SCRIPT = '''// scr_title: the title screen, drawn entirely on the 1280 x 720 GUI. Each world gets a half of the screen.
// The art is 32 px, drawn here at 1x GUI scale (so 2x the in-game size), in step with the game's look.

function title_draw() {
    var _gw = display_get_gui_width();
    var _gh = display_get_gui_height();
    var _half = _gh / 2;
    for (var d = 0; d < 2; d++) {
        var _a = global.art[d];
        var _y0 = d * _half;
        // sky
        draw_sprite_ext(_a.bg[0], 0, 0, _y0, _gw / sprite_get_width(_a.bg[0]), _half / sprite_get_height(_a.bg[0]), 0, c_white, 1);
        // parallax layers, drifting
        var _f = [0, 0.15, 0.3, 0.5, 0.8];
        for (var l = 1; l < 5; l++) {
            var _spr = _a.bg[l];
            var _w = sprite_get_width(_spr);
            var _x0 = -((t * _f[l] * 0.6) mod _w);
            for (var xx = _x0; xx < _gw; xx += _w) {
                draw_sprite_ext(_spr, 0, xx, _y0 + _half - sprite_get_height(_spr) + 10, 1, 1, 0, c_white, 1);
            }
        }
        // ground strip
        var _tile = ART_TILE * 2;
        var _gy = _y0 + _half - _tile * 1.5;
        for (var xx = 0; xx < _gw; xx += _tile) {
            draw_sprite_part_ext(_a.ground, 0, 1 * ART_TILE, 0, ART_TILE, ART_TILE, xx, _gy, 2, 2, c_white, 1);
            draw_sprite_part_ext(_a.ground, 0, 1 * ART_TILE, 1 * ART_TILE, ART_TILE, ART_TILE, xx, _gy + _tile, 2, 2, c_white, 1);
        }
        // the hero, idle, on the ground
        var _hx = (d == 0) ? _gw * 0.34 : _gw * 0.66;
        gpu_set_blendmode(bm_add);
        draw_sprite_ext(spr_light, 0, _hx, _gy - 40, 1.2, 1.2, 0, global.theme[d].accent, 0.35);
        gpu_set_blendmode(bm_normal);
        draw_sprite_ext(_a.hero, floor(t * 0.1) mod 5, _hx, _gy + 2, (d == 0) ? 2 : -2, 2, 0, c_white, 1);
        // the dividing glow
    }
    // divider
    draw_set_colour(make_colour_rgb(10, 8, 16));
    draw_rectangle(0, _half - 10, _gw, _half + 10, false);
    draw_set_colour(global.theme[0].accent);
    draw_rectangle(0, _half - 10, _gw, _half - 9, false);
    draw_set_colour(global.theme[1].accent);
    draw_rectangle(0, _half + 9, _gw, _half + 10, false);

    // title
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    var _bob = sin(t * 0.04) * 4;
    draw_set_colour(make_colour_rgb(8, 6, 14));
    ui_text(_gw / 2 + 4, _half - 120 + _bob + 5, "%(t1)s", true, 3);
    draw_set_colour(global.theme[0].accent);
    ui_text(_gw / 2, _half - 120 + _bob, "%(t1)s", true, 3);
    draw_set_colour(make_colour_rgb(8, 6, 14));
    ui_text(_gw / 2 + 4, _half + 120 - _bob + 5, "%(t2)s", true, 3);
    draw_set_colour(global.theme[1].accent);
    ui_text(_gw / 2, _half + 120 - _bob, "%(t2)s", true, 3);

    // controls and prompt
    draw_set_colour(c_white);
    draw_set_alpha(0.55 + 0.45 * sin(t * 0.08));
    ui_text_shadow(_gw / 2, _half - 34, "Press Enter to start");
    draw_set_alpha(1);
    draw_set_colour(global.theme[0].accent);
    draw_set_halign(fa_left);
    ui_text(24, 24, "P1:  A / D to move,  W or Space to jump");
    draw_set_colour(global.theme[1].accent);
    draw_set_halign(fa_right);
    ui_text(_gw - 24, _gh - 24, "P2:  Left / Right to move,  Up to jump");
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_colour(c_white);
}
''' % {"t1": GAME_TITLE_1, "t2": GAME_TITLE_2}

from gm_object import write_script
write_script("scr_title", "core", SCRIPT)

# --- the room
t = open(os.path.join(ROOT, "tools", "room_template.yy"), encoding="utf8").read()
name = "rm_title"
t = t.replace("rm_level_1", name)
n, inst = instance("obj_title", 0, 0)
order_text = '    {"name":"%s","path":"rooms/%s/%s.yy",},\n' % (n, name, name)
t = re.sub(r'("instanceCreationOrder":\[\n).*?(  \],\n  "isDnd")', lambda m: m.group(1) + order_text + m.group(2), t, flags=re.S)
layer = ('    {"$GMRInstanceLayer":"","%Name":"logic","depth":100,"effectEnabled":true,"effectType":null,"gridX":16,"gridY":16,'
         '"hierarchyFrozen":false,"inheritLayerDepth":false,"inheritLayerSettings":false,"inheritSubLayers":true,"inheritVisibility":true,"instances":[\n'
         + inst + '      ],"layers":[],"name":"logic","properties":[],"resourceType":"GMRInstanceLayer","resourceVersion":"2.0","userdefinedDepth":false,"visible":true,},\n')
t = re.sub(r'("layers":\[\n).*?(  \],\n  "name":"%s")' % name, lambda m: m.group(1) + layer + m.group(2), t, flags=re.S)
t = re.sub(r'"Width":\d+', '"Width":1280', t)
t = re.sub(r'"Height":\d+', '"Height":720', t)
t = t.replace('"enableViews":true', '"enableViews":false')
d = os.path.join(ROOT, "rooms", name)
os.makedirs(d, exist_ok=True)
with open(os.path.join(d, name + ".yy"), "w", encoding="utf8", newline="\n") as f:
    f.write(t)

# register, and make it the first room in the order
register("rooms", name)
s = open(YYP, encoding="utf8").read()
node = '    {"roomId":{"name":"rm_title","path":"rooms/rm_title/rm_title.yy",},},\n'
if node not in s:
    marker = '  "RoomOrderNodes":[\n'
    s = s.replace(marker, marker + node, 1)
open(YYP, "w", encoding="utf8", newline="\n").write(s)
print("title installed")
