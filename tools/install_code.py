"""Installs the visual-overhaul code: new scripts, updated scripts, new / patched objects.
Idempotent: safe to run repeatedly.   python tools/install_code.py
"""
import os, re, sys
sys.path.insert(0, os.path.dirname(__file__))
from gm_sprite import ROOT
from gm_object import write_script, write_object, patch_object, set_sprite, add_props, write_gml

GML = os.path.join(ROOT, "tools", "gml")


def read(p):
    return open(os.path.join(ROOT, p), encoding="utf8").read()


def write(p, s):
    with open(os.path.join(ROOT, p), "w", encoding="utf8", newline="\n") as f:
        f.write(s)


def gml(name):
    return open(os.path.join(GML, name + ".gml"), encoding="utf8").read()


def replace_in(path, old, new, count=1):
    s = read(path)
    if new in s and old not in s:
        return
    assert old in s, f"{path}: pattern not found: {old[:60]}"
    write(path, s.replace(old, new, count))


# ------------------------------------------------------------------ scripts
for name, folder in [("scr_art", "world"), ("scr_fx", "fx"), ("scr_player_art", "player"), ("scr_props", "world"),
                     ("scr_tips", "world"), ("scr_levels", "core"), ("scr_checkpoint", "core")]:
    write_script(name, folder, gml(name))
write("scripts/scr_hud/scr_hud.gml", gml("scr_hud"))
write("scripts/scr_game_state/scr_game_state.gml", gml("scr_game_state"))

# ------------------------------------------------------------------ small edits to existing scripts
replace_in("scripts/scr_config/scr_config.gml", "#macro DEBUG        true", "#macro DEBUG        false")

_dim = read("scripts/scr_dim/scr_dim.gml")
if "Placeholder colours" in _dim:
    write("scripts/scr_dim/scr_dim.gml", _dim[:_dim.index("/// @desc Placeholder colours")] + '''/// @desc Colours per dimension. Dimension 0 is the overworld (gold), dimension 1 the underworld (ember).
/// bg / solid are fallbacks; the real look comes from the art in scr_art. accent drives lights, UI and particles.
function theme_init() {
    global.theme = [
        { bg: make_colour_rgb(120, 170, 190), solid: make_colour_rgb(60, 52, 40),  accent: make_colour_rgb(255, 214, 120) },
        { bg: make_colour_rgb(70, 14, 28),    solid: make_colour_rgb(60, 20, 26),  accent: make_colour_rgb(255, 104, 66)  }
    ];
}
''')

# camera shake
replace_in("scripts/scr_view/scr_view.gml",
           "        camera_set_view_pos(global.cams[i], _tx, dim_view_top(i));",
           """        // screen shake: sideways either way, upward only (the band's top 12 pixels are spare, below it is the next world)
        var _sx = 0;
        var _sy = 0;
        if (variable_global_exists("shake") && global.shake > 0) {
            _sx = round(random_range(-1, 1) * global.shake);
            _sy = -round(random(1) * global.shake);
        }
        camera_set_view_pos(global.cams[i], _tx + _sx, dim_view_top(i) + max(_sy, -12));""")

# player feel: hang time at the top of a jump, heavier fall
replace_in("scripts/scr_player_move/scr_player_move.gml",
           "    yspd = min(yspd + grav, max_fall);",
           """    // lighter at the top of a jump (hang time), heavier on the way down (snappy landings)
    var _g = grav;
    if (abs(yspd) < 0.9 && input.jump_held) _g *= 0.6;
    else if (yspd > 0) _g *= 1.25;
    yspd = min(yspd + _g, max_fall);""")

# echo particles glow
replace_in("scripts/scr_echo/scr_echo.gml",
           "    draw_set_colour(source_player.image_blend);\n    for (var i = 0; i < array_length(motes); i++) {",
           "    draw_set_colour(source_player.image_blend);\n    gpu_set_blendmode(bm_add);\n    for (var i = 0; i < array_length(motes); i++) {")
s = read("scripts/scr_echo/scr_echo.gml")
if "gpu_set_blendmode(bm_normal);\n    draw_set_alpha(1);" not in s:
    s = s.replace("        draw_circle(_m.x, _m.y, _m.sz, false);\n    }\n    draw_set_alpha(1);",
                  "        draw_circle(_m.x, _m.y, _m.sz, false);\n    }\n    gpu_set_blendmode(bm_normal);\n    draw_set_alpha(1);")
    s = s.replace("draw_set_alpha(0.35 * (1 - _m.life / _m.span));", "draw_set_alpha(0.7 * (1 - _m.life / _m.span));")
    write("scripts/scr_echo/scr_echo.gml", s)

# ------------------------------------------------------------------ obj_game
patch_object("obj_game", {
    "create": """// Game controller. Exactly one per level room.
game_init();
cp_init();
input_init();
signals_init();
theme_init();
lights_init();
fx_init();
art_init();
global.players = [noone, noone];
window_setup();
cameras_init();""",
    "room_start": """// Room Start: every instance in the room exists by now.
players_spawn();
echoes_spawn();
boxes_link();
coins_count();
cp_restore();
terrain_build();
deco_build();
cameras_follow();
// the art layers: sky behind everything, the terrain behind the action, particles in front
instance_create_depth(0, 0, 1000, obj_art, { kind: 0 });
instance_create_depth(0, 0, 350, obj_art, { kind: 1 });
instance_create_depth(0, 0, -300, obj_art, { kind: 2 });""",
    "begin_step": """// Begin Step: forget last frame's lights, read both players' input, then global keys.
lights_clear();
deco_lights();
input_poll_all();
if (keyboard_check_pressed(ord("R"))) { cp_reset(); room_restart(); }
if (keyboard_check_pressed(vk_escape)) game_end();

// debug: jump straight to a level with the number keys
if (DEBUG) {
    for (var i = 1; i <= 8; i++) {
        if (keyboard_check_pressed(ord(string(i)))) {
            var _rm = asset_get_index("rm_level_" + string(i));
            if (room_exists(_rm)) room_goto(_rm);
        }
    }
}""",
    "end_step": """// End Step: after every instance has moved.
game_update();
signals_swap();
cameras_follow();
fx_update();""",
    "draw_begin": """// Draw Begin: the sky is drawn by obj_art (kind 0), far behind everything. Nothing to do here.""",
    "draw_end": """// Draw End runs once per view, after everything else is drawn: darkness (with holes where lights are) goes over the
// world, then the vignette. (Post Draw would NOT work here: it runs once per frame, outside the views.)
darkness_draw();
if (view_current <= 1) vignette_draw(view_current);""",
})

# ------------------------------------------------------------------ player
s = read("objects/obj_player/Create_0.gml")
if "player_art_init" not in s:
    write("objects/obj_player/Create_0.gml", s.rstrip("\n") + "\nplayer_art_init();\n")
s = read("objects/obj_player/Step_0.gml")
if "player_art_update" not in s:
    write("objects/obj_player/Step_0.gml", s.rstrip("\n") + "\nplayer_art_update();\n")
patch_object("obj_player", {"draw": "player_art_draw();"})
set_sprite("obj_player", sprite="spr_player")

# ------------------------------------------------------------------ the world's objects
patch_object("obj_solid", {"draw": "// Terrain is drawn as autotiles by obj_art (see scr_art). Plain solids draw nothing themselves."})
patch_object("obj_gate", {"draw": "gate_draw();"})
patch_object("obj_platform", {"draw": "platform_draw();"})
patch_object("obj_box", {"draw": "box_draw();"})
patch_object("obj_plate", {"draw": "plate_draw();"})
patch_object("obj_tar", {"draw": "tar_draw();"})
patch_object("obj_walker", {"draw": "walker_draw();"})
patch_object("obj_exit", {"draw": "exit_draw();", "step": "if (!game_is_playing()) exit;\nexit_update();"})
patch_object("obj_lamp", {"draw": "lamp_draw();", "step": "lamp_update();"})
replace_in("objects/obj_walker/Create_0.gml", "image_blend  = make_colour_rgb(232, 92, 92);\n", "")

# ------------------------------------------------------------------ new objects
write_object("obj_art", "core", None, {
    "create": "// kind is passed in by obj_game's Room Start: 0 = sky and parallax, 1 = terrain and scenery, 2 = particles.",
    "draw": """var _d = view_current;
if (_d > 1) exit;
switch (kind) {
    case 0: bg_draw(_d); break;
    case 1: terrain_draw(_d); deco_draw(_d); break;
    case 2: fx_draw(_d); break;
}""",
})
write_object("obj_coin", "level", None, {
    "create": "dim   = dim_of_y(y);\nphase = irandom(120);",
    "step": "if (!game_is_playing()) exit;\ncoin_update();",
    "draw": "coin_draw();",
})
write_object("obj_checkpoint", "level", None, {
    "create": "// idx (a property) orders the flags in a level. Both worlds have one with the same idx.\nidx = real(idx);\ndim = dim_of_y(y - 1);\nreached = false;",
    "step": "checkpoint_update();",
    "draw": "checkpoint_draw();",
}, props=[("idx", 0)])
write_object("obj_tip", "level", None, {
    "create": "// kind picks what the tip shows (see scr_tips). Drawn in GUI space by tips_draw_gui().\ndim = dim_of_y(y);",
}, props=[("kind", "move")], visible=False)

print("installed")
