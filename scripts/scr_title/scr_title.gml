// scr_title: the title screen, drawn entirely on the 1280 x 720 GUI. Each world gets a half of the screen.
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
    ui_text(_gw / 2 + 4, _half - 120 + _bob + 5, "ABOVE", true, 3);
    draw_set_colour(global.theme[0].accent);
    ui_text(_gw / 2, _half - 120 + _bob, "ABOVE", true, 3);
    draw_set_colour(make_colour_rgb(8, 6, 14));
    ui_text(_gw / 2 + 4, _half + 120 - _bob + 5, "BELOW", true, 3);
    draw_set_colour(global.theme[1].accent);
    ui_text(_gw / 2, _half + 120 - _bob, "BELOW", true, 3);

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
