// scr_game_state: the shared fail / clear state machine, the level timer, coins and scoring.
// Everything that can end a round calls game_fail() or game_clear().
// Nothing kills a player directly.

function game_init() {
    global.game_state  = GAME_STATE.PLAYING;
    global.fail_reason = FAIL.NONE;
    // frames since the fail, and which player (0 or 1) caused it (-1 = unknown)
    global.fail_time   = 0;
    global.fail_player = -1;
    // frames, counted only while PLAYING
    global.level_time  = 0;
    // coins collected in each dimension, how many each dimension has, and a flash for the HUD when one is picked up
    global.coins_got   = [0, 0];
    global.coins_total = [0, 0];
    global.coin_flash  = 0;
    // filled in when the level is cleared
    global.result      = undefined;
    // frames since the room started (drives the level-name banner)
    global.intro_time  = 0;
}

function game_is_playing() {
    return global.game_state == GAME_STATE.PLAYING;
}

/// @desc Counts the coins in each dimension. Called at Room Start.
function coins_count() {
    global.coins_total = [0, 0];
    with (obj_coin) global.coins_total[dim]++;
}

/// @desc Shared fail: if either player dies, both do. _who is the player instance that died (so its view
/// can be highlighted); leave it out if unknown.
function game_fail(_reason, _who = noone) {
    if (!game_is_playing()) return;
    global.game_state  = GAME_STATE.FAILED;
    global.fail_reason = _reason;
    global.fail_time   = 0;
    global.fail_player = (_who != noone && instance_exists(_who)) ? _who.player_id : -1;
    shake_add(6);
    // a checkpoint keeps your progress but not your time: the clock carries on from here
    if (cp_active()) global.cp.time = global.level_time;
    // both heroes burst into embers
    for (var i = 0; i < 2; i++) {
        var _p = global.players[i];
        if (instance_exists(_p)) fx_burst(_p.x, _p.y - 11, 26, global.theme[i].accent, 2.4, 40, 2, 0.05, true);
    }
}

function game_clear() {
    if (!game_is_playing()) return;
    global.game_state = GAME_STATE.CLEARED;
    var _meta = level_meta();
    var _secs = global.level_time / game_get_speed(gamespeed_fps);
    var _coins = global.coins_got[0] + global.coins_got[1];
    var _bonus = max(0, round((_meta.par - _secs) * TIME_SCORE));
    var _score = _coins * COIN_SCORE + _bonus;
    var _rec = level_record(_secs, _score);
    global.result = {
        secs: _secs, coins: _coins, coins_total: global.coins_total[0] + global.coins_total[1], bonus: _bonus, score: _score,
        new_best: _rec.new_best, best_score: _rec.best_score, best_time: _rec.best_time, par: _meta.par
    };
    for (var i = 0; i < 2; i++) {
        var _p = global.players[i];
        if (instance_exists(_p)) fx_burst(_p.x, _p.y - 11, 30, global.theme[i].accent, 2.2, 50, 2, -0.01, true);
    }
}

/// @desc True when each player is inside an obj_exit in their own dimension.
function exits_all_occupied() {
    for (var i = 0; i < 2; i++) {
        var _p = global.players[i];
        if (!instance_exists(_p)) return false;
        var _inside = false;
        with (_p) _inside = place_meeting(x, y, obj_exit);
        if (!_inside) return false;
    }
    return true;
}

function level_next() {
    var _next = room_next(room);
    if (_next != -1 && room_exists(_next)) room_goto(_next);
    else room_goto(rm_title);
}

/// @desc Runs once per frame from obj_game (End Step).
function game_update() {
    global.intro_time++;
    if (global.coin_flash > 0) global.coin_flash--;
    if (global.cp_flash > 0) global.cp_flash--;
    switch (global.game_state) {
        case GAME_STATE.PLAYING:
            global.level_time++;
            if (exits_all_occupied()) game_clear();
            break;
        case GAME_STATE.FAILED:
            // the round stays on the fail screen until Enter is pressed (after a short delay,
            // so a button mash at the moment of death can't skip it)
            global.fail_time++;
            if (global.fail_time >= FAIL_DELAY && keyboard_check_pressed(vk_enter)) room_restart();
            break;
        case GAME_STATE.CLEARED:
            if (keyboard_check_pressed(vk_enter)) level_next();
            break;
    }
}
