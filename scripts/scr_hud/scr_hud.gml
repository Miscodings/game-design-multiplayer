// scr_hud: divider, timer and fail / clear banners. Drawn from obj_game's Draw GUI event.

// Fonts are bitmap assets baked at twice their layout size (fnt_ui 24 pt, fnt_title 48 pt), so drawing
// at half scale stays sharp on the 1280 x 720 GUI. Alignment is set by the caller.
function ui_text(_x, _y, _str, _big = false) {
    draw_set_font(_big ? fnt_title : fnt_ui);
    draw_text_transformed(_x, _y, _str, 0.5, 0.5, 0);
}

function time_format(_frames) {
    var _secs = _frames / game_get_speed(gamespeed_fps);
    var _m = floor(_secs / 60);
    var _s = _secs - _m * 60;
    return string(_m) + ":" + string_replace_all(string_format(_s, 2, 2), " ", "0");
}

function hud_banner(_title, _line1, _line2 = "") {
    var _gw = display_get_gui_width();
    var _mid = display_get_gui_height() / 2;
    draw_set_alpha(0.75);
    draw_set_colour(c_black);
    draw_rectangle(0, _mid - 64, _gw, _mid + 64, false);
    draw_set_alpha(1);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_colour(c_white);
    ui_text(_gw / 2, _mid - 24, _title, true);
    ui_text(_gw / 2, _mid + 18, _line1);
    if (_line2 != "") ui_text(_gw / 2, _mid + 42, _line2);
}

function hud_draw() {
    var _gw = display_get_gui_width();
    var _mid = display_get_gui_height() / 2;
    var _half = 12;

    // divider between the two views, each edge in its own dimension's colour
    draw_set_colour(c_black);
    draw_rectangle(0, _mid - _half, _gw, _mid + _half, false);
    draw_set_colour(global.theme[0].accent);
    draw_rectangle(0, _mid - _half, _gw, _mid - _half + 1, false);
    draw_set_colour(global.theme[1].accent);
    draw_rectangle(0, _mid + _half - 1, _gw, _mid + _half, false);

    draw_set_valign(fa_middle);
    draw_set_halign(fa_left);
    draw_set_colour(global.theme[0].accent);
    ui_text(8, _mid, "P1");
    draw_set_halign(fa_right);
    draw_set_colour(global.theme[1].accent);
    ui_text(_gw - 8, _mid, "P2");
    draw_set_halign(fa_center);
    draw_set_colour(c_white);
    ui_text(_gw / 2, _mid, time_format(global.level_time));

    if (global.game_state == GAME_STATE.FAILED) {
        // the dead player's view is highlighted red for the whole fail screen: a strong flash that settles
        // to a steady tint (both views if we don't know who it was)
        draw_set_alpha(lerp(0.6, 0.3, min(global.fail_time / FAIL_FLASH, 1)));
        draw_set_colour(c_red);
        if (global.fail_player != 1) draw_rectangle(0, 0, _gw, _mid - _half, false);
        if (global.fail_player != 0) draw_rectangle(0, _mid + _half, _gw, display_get_gui_height(), false);
        draw_set_alpha(1);
        // then, after a short delay, the prompt
        if (global.fail_time >= FAIL_DELAY) hud_banner("FAILED", "Press Enter to retry");
    } else if (global.game_state == GAME_STATE.CLEARED) {
        hud_banner("LEVEL CLEARED", "Time  " + time_format(global.level_time), "Enter: next level     R: restart");
    }

    draw_set_font(-1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_colour(c_white);
    draw_set_alpha(1);
}
