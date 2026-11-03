// scr_movement: collision and pixel-accurate movement shared by every mover.

/// @desc The single collision query. Tilemap collision gets added here later,
/// so every mover (players, enemies, boxes) picks it up without changes.
function solid_at(_x, _y) {
    return place_meeting(_x, _y, obj_solid);
}

function movement_init() {
    xspd = 0;
    yspd = 0;
    x_remain = 0;
    y_remain = 0;
}

/// @desc Move the calling instance by xspd / yspd, one pixel at a time, stopping on solids.
/// Fractional speeds are carried between frames in x_remain / y_remain.
function move_collide() {
    var _xt = xspd + x_remain;
    var _yt = yspd + y_remain;
    var _xr = (_xt >= 0) ? floor(_xt) : ceil(_xt);
    var _yr = (_yt >= 0) ? floor(_yt) : ceil(_yt);
    x_remain = _xt - _xr;
    y_remain = _yt - _yr;

    var _sx = sign(_xr);
    repeat (abs(_xr)) {
        if (solid_at(x + _sx, y)) {
            xspd = 0;
            x_remain = 0;
            break;
        }
        x += _sx;
    }

    var _sy = sign(_yr);
    repeat (abs(_yr)) {
        if (solid_at(x, y + _sy)) {
            yspd = 0;
            y_remain = 0;
            break;
        }
        y += _sy;
    }
}

/// @desc Move the calling solid (platform, box) one pixel along one axis, carrying the players standing
/// on top of it and pushing any it moves into. A player with nowhere to go is crushed (shared fail).
function solid_move_pixel(_sx, _sy) {
    var _self = id;

    // who is standing on top before this solid moves
    var _riding = [false, false];
    for (var i = 0; i < 2; i++) {
        var _p = global.players[i];
        if (!instance_exists(_p)) continue;
        with (_p) _riding[i] = !place_meeting(x, y, _self) && place_meeting(x, y + 1, _self);
    }

    x += _sx;
    y += _sy;

    for (var j = 0; j < 2; j++) {
        var _q = global.players[j];
        if (!instance_exists(_q)) continue;
        with (_q) {
            if (_riding[j] || place_meeting(x, y, _self)) {
                if (!solid_at(x + _sx, y + _sy)) {
                    x += _sx;
                    y += _sy;
                } else if (place_meeting(x, y, _self)) {
                    game_fail(FAIL.CRUSH, id);
                }
            }
        }
    }
}
