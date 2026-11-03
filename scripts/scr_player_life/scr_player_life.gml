// scr_player_life: spawning players from obj_spawn markers, and keeping them in their band.

/// @desc Replaces each obj_spawn marker with that player's obj_player. Called at Room Start.
function players_spawn() {
    global.players = [noone, noone];
    with (obj_spawn) {
        global.players[player_id] = instance_create_layer(x, y, layer, obj_player, { player_id: player_id });
        instance_destroy();
    }
    for (var i = 0; i < 2; i++) {
        if (!instance_exists(global.players[i])) {
            show_error("Room '" + room_get_name(room) + "' has no obj_spawn with player_id " + string(i) + ".", true);
        }
    }
}

/// @desc Keeps the calling player inside the room horizontally and inside their band's top edge.
/// Falling out of the bottom of the band is a shared fail.
function player_check_bounds() {
    var _top = dim_top(dim);

    if (bbox_top < _top) {
        y += _top - bbox_top;
        yspd = max(yspd, 0);
    }
    if (bbox_left < 0) {
        x -= bbox_left;
        xspd = max(xspd, 0);
    }
    if (bbox_right >= room_width) {
        x -= bbox_right - (room_width - 1);
        xspd = min(xspd, 0);
    }
    if (bbox_top > _top + DIM_H) game_fail(FAIL.FALL, id);
}
