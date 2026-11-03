// scr_game_state: the shared fail / clear state machine and the level timer.
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
}

function game_is_playing() {
    return global.game_state == GAME_STATE.PLAYING;
}

/// @desc Shared fail: if either player dies, both do. _who is the player instance that died (so its view
/// can be highlighted); leave it out if unknown.
function game_fail(_reason, _who = noone) {
    if (!game_is_playing()) return;
    global.game_state  = GAME_STATE.FAILED;
    global.fail_reason = _reason;
    global.fail_time   = 0;
    global.fail_player = (_who != noone && instance_exists(_who)) ? _who.player_id : -1;
}

function game_clear() {
    if (!game_is_playing()) return;
    global.game_state = GAME_STATE.CLEARED;
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
    else room_restart();
}

/// @desc Runs once per frame from obj_game (End Step).
function game_update() {
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
