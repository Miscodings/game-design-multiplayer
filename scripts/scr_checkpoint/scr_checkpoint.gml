// scr_checkpoint: flags that both players have to pass. When both have, the level remembers it, and after a fail
// "Enter" starts the round again from there: heroes on the flags, coins already collected stay collected, and the
// clock keeps running (a checkpoint saves progress, it does not save time). "R" always restarts the whole level.
//
// Each flag is an obj_checkpoint in both worlds with the same idx (the x axis is shared). Flags have to be lit by
// BOTH players, in their own world, before the checkpoint counts.

function cp_reset() {
    global.cp = { room: room, idx: -1, x: [0, 0], y: [0, 0], coins: [], got: [0, 0], time: 0 };
    global.coins_taken = [];
}

/// @desc Called from obj_game's Create. A checkpoint belongs to one room; entering any other room clears it.
function cp_init() {
    if (!variable_global_exists("cp") || global.cp.room != room) cp_reset();
    global.coins_taken = [];
    global.cp_flash = 0;
}

function cp_active() {
    return variable_global_exists("cp") && global.cp.room == room && global.cp.idx >= 0;
}

/// @desc Room Start: if a checkpoint is active, put both heroes on their flags and restore what was collected.
function cp_restore() {
    if (!cp_active()) return;
    var _c = global.cp;
    for (var i = 0; i < 2; i++) {
        var _p = global.players[i];
        if (!instance_exists(_p)) continue;
        _p.x = _c.x[i];
        _p.y = _c.y[i];
        _p.face = 1;
    }
    // flags up to this one are already lit
    with (obj_checkpoint) if (idx <= _c.idx) reached = true;
    // coins already taken stay taken
    for (var k = 0; k < array_length(_c.coins); k++) {
        var _pt = _c.coins[k];
        with (obj_coin) if (x == _pt[0] && y == _pt[1]) instance_destroy();
    }
    global.coins_taken = array_create(0);
    array_copy(global.coins_taken, 0, _c.coins, 0, array_length(_c.coins));
    global.coins_got = [_c.got[0], _c.got[1]];
    global.level_time = _c.time;
    global.intro_time = 999;
}

/// @desc A flag was reached by its own player: if the other world's flag with the same idx is lit too, save it.
function cp_check(_flag) {
    var _both = false;
    with (obj_checkpoint) if (idx == _flag.idx && dim != _flag.dim && reached) _both = true;
    if (!_both || _flag.idx <= global.cp.idx) return;
    global.cp.idx  = _flag.idx;
    global.cp.coins = array_create(0);
    array_copy(global.cp.coins, 0, global.coins_taken, 0, array_length(global.coins_taken));
    global.cp.got  = [global.coins_got[0], global.coins_got[1]];
    global.cp.time = global.level_time;
    with (obj_checkpoint) {
        if (idx == _flag.idx) {
            global.cp.x[dim] = x;
            global.cp.y[dim] = y;
            fx_burst(x, y - 12, 18, global.theme[dim].accent, 1.6, 36, 1.8, 0.04, true);
        }
    }
    global.cp_flash = 120;
}

function checkpoint_update() {
    if (!game_is_playing()) return;
    var _p = global.players[dim];
    if (!instance_exists(_p)) return;
    if (!reached && _p.x >= x) {
        reached = true;
        fx_burst(x, y - 14, 10, global.theme[dim].accent, 1.2, 28, 1.6, 0.04, true);
        cp_check(id);
    }
    var _lit = reached && (idx <= global.cp.idx);
    if (_lit) light_add(x, y - 14, 40, 0.8);
    else if (reached) light_add(x, y - 14, 24, 0.5);
}

function checkpoint_draw() {
    var _lit = reached && (idx <= global.cp.idx);
    var _acc = global.theme[dim].accent;
    var _wave = sin(global.frame * 0.12);
    // pole
    draw_set_colour(make_colour_rgb(40, 32, 44));
    draw_rectangle(x - 1, y - 26, x, y, false);
    draw_set_colour(make_colour_rgb(150, 140, 160));
    draw_rectangle(x - 1, y - 26, x - 1, y, false);
    // cap
    draw_set_colour(_lit ? c_white : make_colour_rgb(150, 140, 160));
    draw_rectangle(x - 2, y - 28, x + 0, y - 27, false);
    // cloth: grey until both heroes have passed, then the world's colour, waving
    var _col = _lit ? _acc : (reached ? merge_colour(_acc, make_colour_rgb(90, 84, 100), 0.6) : make_colour_rgb(90, 84, 100));
    draw_set_colour(_col);
    for (var i = 0; i < 9; i++) {
        var _h = 9 - i * 0.8;
        var _w = _lit ? round(_wave * (i * 0.12)) : 0;
        draw_rectangle(x + 1 + i, y - 26 + _w, x + 1 + i, y - 26 + _h + _w, false);
    }
    if (_lit) {
        gpu_set_blendmode(bm_add);
        draw_sprite_ext(spr_light, 0, x, y - 16, 0.2, 0.2, 0, _acc, 0.3 + 0.08 * _wave);
        gpu_set_blendmode(bm_normal);
    }
    draw_set_colour(c_white);
}
