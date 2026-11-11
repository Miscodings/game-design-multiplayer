// scr_levels: level names, par times, scoring and the save file (best time and best score per level).
//
// Score = 100 per coin + 10 per second under par. Both players' coins count.

#macro COIN_SCORE    100
#macro TIME_SCORE    10

function level_index() {
    var _n = room_get_name(room);
    var _p = string_pos("rm_level_", _n);
    if (_p == 0) return 0;
    return real(string_delete(_n, 1, 9));
}

function level_count() {
    var _n = 0;
    while (room_exists(asset_get_index("rm_level_" + string(_n + 1)))) _n++;
    return _n;
}

/// @desc Name, par time in seconds and a one-line hint for the current level.
function level_meta(_i = level_index()) {
    // a level can carry its own name, par and hint (properties on its obj_game); older levels use the table below
    if (_i == level_index() && instance_exists(obj_game) && obj_game.level_name != "") {
        return { name: obj_game.level_name, par: obj_game.level_par, hint: obj_game.level_hint };
    }
    switch (_i) {
        case 1: return { name: "First Steps",     par: 45,  hint: "Walk to your portals. Your partner's glow shows where they are." };
        case 2: return { name: "Hold the Line",   par: 60,  hint: "A plate in one world opens a gate in the other." };
        case 3: return { name: "Sticky Situation", par: 70, hint: "Tar kills. Slimes can be stomped." };
        case 4: return { name: "Heavy Lifting",   par: 75,  hint: "One box in each world. Push them together." };
        case 5: return { name: "Into the Dark",   par: 80,  hint: "Your partner is your lantern." };
        case 6: return { name: "Tide Turner",     par: 85,  hint: "Where one of you stands, the other is safe." };
        case 7: return { name: "Crossed Paths",   par: 100, hint: "Plates, platforms and a long way down." };
        case 8: return { name: "The Gauntlet",    par: 130, hint: "Everything you have learned." };
    }
    return { name: "Level " + string(_i), par: 90, hint: "" };
}

/// @desc Dev aid: F3 toggles outlines of every collision box (cyan = plain solid, magenta = platform, yellow = gate / box,
/// red = tar / pool, green = players). What you see drawn but cannot stand on will have no outline under it.
function hitbox_enabled() {
    return variable_global_exists("show_hitboxes") && global.show_hitboxes;
}

function hitbox_draw(_dim) {
    if (!hitbox_enabled()) return;
    draw_set_alpha(1);
    with (obj_solid) {
        if (object_index == obj_platform) draw_set_colour(c_fuchsia);
        else if (object_index == obj_solid) draw_set_colour(c_aqua);
        else draw_set_colour(c_yellow);
        draw_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom, true);
    }
    draw_set_colour(c_red);
    with (obj_tar)  draw_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom, true);
    with (obj_pool) draw_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom, true);
    draw_set_colour(c_lime);
    with (obj_player) draw_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom, true);
    draw_set_colour(c_white);
}

/// @desc Dev aid: jump straight to a level with the number keys. 1-9 = levels 1-9, 0 = level 10, hold Shift to add 10.
/// Works in any level and on the title screen. Switch it off with LEVEL_JUMP_KEYS in scr_config before shipping.
function debug_level_jump() {
    if (keyboard_check_pressed(vk_f3)) global.show_hitboxes = !hitbox_enabled();
    if (!LEVEL_JUMP_KEYS) return false;
    for (var d = 0; d <= 9; d++) {
        if (keyboard_check_pressed(ord(string(d))) || keyboard_check_pressed(vk_numpad0 + d)) {
            var _n = ((d == 0) ? 10 : d) + (keyboard_check(vk_shift) ? 10 : 0);
            var _rm = asset_get_index("rm_level_" + string(_n));
            if (room_exists(_rm)) {
                cp_reset();
                room_goto(_rm);
                return true;
            }
        }
    }
    return false;
}

/// @desc A small reminder of the jump keys in the bottom-left corner of the screen (GUI layer).
function debug_level_hint() {
    if (!LEVEL_JUMP_KEYS) return;
    var _ha = draw_get_halign();
    var _va = draw_get_valign();
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    var _i = level_index();
    var _txt = "DEBUG  keys 1-9 = level 1-9, F3 = hitboxes   (now " + ((_i > 0) ? string(_i) : "title") + " of " + string(level_count()) + ")";
    draw_set_alpha(0.75);
    draw_set_colour(make_colour_rgb(200, 220, 255));
    ui_text_shadow(8, display_get_gui_height() - 14, _txt);
    draw_set_alpha(1);
    draw_set_colour(c_white);
    draw_set_halign(_ha);
    draw_set_valign(_va);
}

function save_open() { ini_open("save.ini"); }

/// @desc Records a finished level: score, time and coins. Returns true if the score is a new best.
function level_record(_time_s, _score) {
    var _sec = "level" + string(level_index());
    ini_open("save.ini");
    var _best_t = ini_read_real(_sec, "time", 99999);
    var _best_s = ini_read_real(_sec, "score", -1);
    var _new = _score > _best_s;
    if (_new) ini_write_real(_sec, "score", _score);
    if (_time_s < _best_t) ini_write_real(_sec, "time", _time_s);
    ini_close();
    return { new_best: _new, best_score: max(_best_s, _score), best_time: min(_best_t, _time_s) };
}

function level_best_text() {
    var _sec = "level" + string(level_index());
    ini_open("save.ini");
    var _s = ini_read_real(_sec, "score", -1);
    ini_close();
    return _s;
}
