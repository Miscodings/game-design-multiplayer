// scr_hud: the divider between the two worlds, timer, coin counters, level banner and the fail / clear panels.
// Drawn from obj_game's Draw GUI event on the 1280 x 720 GUI.

// (ui_text, ui_text_shadow and ui_text_w live in scr_font.)

function time_format(_frames) {
    var _secs = _frames / game_get_speed(gamespeed_fps);
    var _m = floor(_secs / 60);
    var _s = _secs - _m * 60;
    return string(_m) + ":" + string_replace_all(string_format(_s, 2, 2), " ", "0");
}

function secs_format(_secs) {
    return time_format(_secs * game_get_speed(gamespeed_fps));
}

function hud_panel(_x1, _y1, _x2, _y2, _accent) {
    draw_set_alpha(0.86);
    draw_set_colour(make_colour_rgb(12, 9, 20));
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 22, 22, false);
    draw_set_alpha(1);
    draw_set_colour(_accent);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 22, 22, true);
    draw_roundrect_ext(_x1 + 1, _y1 + 1, _x2 - 1, _y2 - 1, 22, 22, true);
}

/// @desc A small gem icon, the same one the coins use.
function hud_gem(_x, _y, _col, _s = 1) {
    draw_set_colour(_col);
    draw_triangle(_x - 8 * _s, _y, _x, _y - 10 * _s, _x + 8 * _s, _y, false);
    draw_triangle(_x - 8 * _s, _y, _x, _y + 10 * _s, _x + 8 * _s, _y, false);
    draw_set_colour(c_white);
    draw_set_alpha(0.6);
    draw_triangle(_x - 3 * _s, _y - 1, _x, _y - 7 * _s, _x + 2 * _s, _y - 1, false);
    draw_set_alpha(1);
}

/// @desc Headline for the fail panel: who went down and how ("P1 was caught"). Falls back to "A hero" if unknown.
function fail_headline(_reason, _player) {
    var _who = (_player == 0) ? "P1" : ((_player == 1) ? "P2" : "A hero");
    switch (_reason) {
        case FAIL.HAZARD: return _who + " hit a hazard";
        case FAIL.ENEMY:  return _who + " was caught";
        case FAIL.FALL:   return _who + " fell";
        case FAIL.CRUSH:  return _who + " was crushed";
    }
    return _who + " went down";
}

function hud_draw() {
    var _gw = display_get_gui_width();
    var _gh = display_get_gui_height();
    var _mid = _gh / 2;
    var _half = 14;
    var _a0 = global.theme[0].accent;
    var _a1 = global.theme[1].accent;

    tips_draw_gui();

    // ---- divider: a dark carved strip with a lit edge facing each world
    draw_set_colour(make_colour_rgb(10, 8, 16));
    draw_rectangle(0, _mid - _half, _gw, _mid + _half, false);
    draw_set_colour(_a0);
    draw_rectangle(0, _mid - _half, _gw, _mid - _half + 1, false);
    draw_set_alpha(0.3);
    draw_rectangle(0, _mid - _half + 2, _gw, _mid - _half + 3, false);
    draw_set_colour(_a1);
    draw_rectangle(0, _mid + _half - 3, _gw, _mid + _half - 2, false);
    draw_set_alpha(1);
    draw_rectangle(0, _mid + _half - 1, _gw, _mid + _half, false);

    draw_set_valign(fa_middle);
    draw_set_halign(fa_left);
    draw_set_colour(_a0);
    ui_text(14, _mid, "P1  OVERWORLD");
    draw_set_halign(fa_right);
    draw_set_colour(_a1);
    ui_text(_gw - 14, _mid, "P2  UNDERWORLD");
    draw_set_halign(fa_center);
    draw_set_colour(c_white);
    ui_text(_gw / 2, _mid, time_format(global.level_time));

    // ---- coin counters in the corner of each world
    for (var d = 0; d < 2; d++) {
        var _y = (d == 0) ? 22 : _mid + _half + 22;
        var _c = global.theme[d].accent;
        var _pop = (global.coin_flash > 0) ? 1 + 0.02 * global.coin_flash : 1;
        hud_gem(26, _y, _c, _pop);
        draw_set_halign(fa_left);
        draw_set_valign(fa_middle);
        draw_set_colour(c_white);
        ui_text_shadow(42, _y, string(global.coins_got[d]) + " / " + string(global.coins_total[d]));
    }

    // ---- level banner, fading in at the start of the room
    if (global.intro_time < 190 && global.game_state == GAME_STATE.PLAYING) {
        var _t = global.intro_time;
        var _al = (_t < 20) ? _t / 20 : ((_t > 150) ? (190 - _t) / 40 : 1);
        var _m = level_meta();
        draw_set_alpha(_al);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_colour(make_colour_rgb(255, 236, 190));
        ui_text_shadow(_gw / 2, 58, "Level " + string(level_index()) + ": " + _m.name, true);
        draw_set_colour(make_colour_rgb(220, 210, 230));
        ui_text_shadow(_gw / 2, 92, _m.hint);
        draw_set_alpha(1);
    }

    // checkpoint toast, over the divider's top edge of the overworld, fading out
    if (global.cp_flash > 0 && global.game_state == GAME_STATE.PLAYING) {
        var _fa = min(1, global.cp_flash / 30);
        draw_set_alpha(_fa);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_colour(make_colour_rgb(255, 236, 190));
        ui_text_shadow(_gw / 2, 58, "Checkpoint saved");
        draw_set_alpha(1);
    }

    if (global.game_state == GAME_STATE.FAILED) {
        // the dead player's view is highlighted red for the whole fail screen: a strong flash that settles
        // to a steady tint (both views if we don't know who it was)
        draw_set_alpha(lerp(0.6, 0.3, min(global.fail_time / FAIL_FLASH, 1)));
        draw_set_colour(c_red);
        if (global.fail_player != 1) draw_rectangle(0, 0, _gw, _mid - _half, false);
        if (global.fail_player != 0) draw_rectangle(0, _mid + _half, _gw, _gh, false);
        draw_set_alpha(1);
        // then, after a short delay, the prompt
        if (global.fail_time >= FAIL_DELAY) {
            hud_panel(_gw / 2 - 260, _mid - 78, _gw / 2 + 260, _mid + 78, make_colour_rgb(255, 90, 70));
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            draw_set_colour(make_colour_rgb(255, 120, 100));
            ui_text_shadow(_gw / 2, _mid - 38, fail_headline(global.fail_reason, global.fail_player), true);
            draw_set_colour(make_colour_rgb(230, 220, 235));
            ui_text(_gw / 2, _mid + 2, "One falls, you both fall");
            draw_set_colour(c_white);
            ui_text(_gw / 2, _mid + 40, cp_active() ? "Enter: Retry from checkpoint     R: Restart level" : "Press Enter to try again");
        }
    } else if (global.game_state == GAME_STATE.CLEARED && global.result != undefined) {
        var _r = global.result;
        hud_panel(_gw / 2 - 300, _mid - 150, _gw / 2 + 300, _mid + 150, make_colour_rgb(255, 214, 120));
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_colour(make_colour_rgb(255, 230, 150));
        ui_text_shadow(_gw / 2, _mid - 112, "LEVEL CLEARED", true);
        draw_set_colour(c_white);
        var _x1 = _gw / 2 - 210;
        var _x2 = _gw / 2 + 210;
        var _row = function(_xa, _xb, _yy, _label, _value) {
            draw_set_halign(fa_left);
            ui_text(_xa, _yy, _label);
            draw_set_halign(fa_right);
            ui_text(_xb, _yy, _value);
        };
        _row(_x1, _x2, _mid - 62, "Time", secs_format(_r.secs) + "   (Par " + secs_format(_r.par) + ")");
        _row(_x1, _x2, _mid - 32, "Coins", string(_r.coins) + " / " + string(_r.coins_total) + "   +" + string(_r.coins * COIN_SCORE));
        _row(_x1, _x2, _mid - 2, "Time bonus", "+" + string(_r.bonus));
        draw_set_colour(make_colour_rgb(255, 230, 150));
        _row(_x1, _x2, _mid + 34, "Score", string(_r.score) + (_r.new_best ? "   New best!" : "   Best " + string(_r.best_score)));
        draw_set_colour(make_colour_rgb(220, 210, 230));
        draw_set_halign(fa_center);
        ui_text(_gw / 2, _mid + 112, "Enter: Next level     R: Restart level");
    }

        draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_colour(c_white);
    draw_set_alpha(1);
}
