// scr_view: window setup, the two per-dimension cameras, and the band backgrounds.
//
// The room is two bands stacked vertically. View 0 shows band 0 in the top half of the
// window, view 1 shows band 1 in the bottom half. Each camera follows its own player
// in x only; its y is locked to its band. The room's views 0 and 1 provide the cameras
// (so they show in the room editor); this script then sets their size and ports from
// the macros in scr_config.

function window_setup() {
    if (!variable_global_exists("window_ready")) {
        global.window_ready = true;
        // windowed but nearly the full screen: 16:9 kept, with room left for the title bar and taskbar
        // (scales up on big displays too, like GameDesignMultiplayer)
        var _fit = min(display_get_width() * 0.97 / WIN_W, (display_get_height() - 120) / WIN_H);
        window_set_size(floor(WIN_W * _fit), floor(WIN_H * _fit));
        window_center();
        surface_resize(application_surface, WIN_W, WIN_H);
        gpu_set_texfilter(false);
        draw_set_circle_precision(32);
    }
    display_set_gui_size(WIN_W, WIN_H);
}

function cameras_init() {
    global.cams  = [noone, noone];
    global.cam_y = [undefined, undefined];
    view_enabled = true;
    for (var i = 0; i < 2; i++) {
        var _cam = view_camera[i];
        if (_cam < 0) {
            show_error("Room '" + room_get_name(room) + "' needs views 0 and 1 enabled. Duplicate an existing level room so its views carry over.", true);
        }
        camera_set_view_size(_cam, VIEW_W, VIEW_H);
        camera_set_view_pos(_cam, 0, dim_view_top(i));
        view_visible[i] = true;
        view_xport[i] = 0;
        view_yport[i] = i * PORT_H;
        view_wport[i] = PORT_W;
        view_hport[i] = PORT_H;
        global.cams[i] = _cam;
    }
}

/// @desc Camera y for one world. A band no taller than the view (the original 12-tile levels) stays locked to the
/// bottom of the band. A taller band scrolls: the view ignores small moves (a dead zone, so ordinary jumps do not bob
/// the picture) and follows once the player leaves it, a few pixels per frame, always in whole pixels.
function camera_y_for(_i, _p) {
    var _lo = dim_top(_i);
    var _hi = _lo + DIM_H - VIEW_H;
    if (_hi - _lo <= TILE) return _hi;

    var _focus = floor(_p.y) - round(VIEW_H * CAM_FOCUS);
    var _cur = global.cam_y[_i];
    if (is_undefined(_cur)) {
        _cur = _focus;      // first frame in a room: start on the player
    } else {
        var _d = _focus - _cur;
        if (abs(_d) > CAM_DEADZONE) _cur += sign(_d) * clamp(ceil((abs(_d) - CAM_DEADZONE) * 0.18), 1, CAM_MAX_STEP);
    }
    _cur = clamp(_cur, _lo, _hi);
    global.cam_y[_i] = _cur;
    return _cur;
}

/// @desc Each camera follows its own player: x is locked to the player (players move in whole pixels, so any
/// smoothing would make them jitter against the world), y goes through camera_y_for().
function cameras_follow() {
    for (var i = 0; i < 2; i++) {
        var _p = global.players[i];
        if (!instance_exists(_p)) continue;
        var _tx = clamp(floor(_p.x) - VIEW_W / 2, 0, max(0, room_width - VIEW_W));
        var _ty = camera_y_for(i, _p);
        // screen shake: a few pixels either way, never outside the band
        var _sx = 0;
        var _sy = 0;
        if (variable_global_exists("shake") && global.shake > 0) {
            _sx = round(random_range(-1, 1) * global.shake);
            _sy = round(random_range(-1, 1) * global.shake);
        }
        var _lo = dim_top(i);
        camera_set_view_pos(global.cams[i], _tx + _sx, clamp(_ty + _sy, _lo, _lo + DIM_H - VIEW_H));
    }
}

/// @desc Fills each dimension's band with its background colour. Called from Draw Begin.
function bands_draw() {
    for (var i = 0; i < 2; i++) {
        draw_set_colour(global.theme[i].bg);
        draw_rectangle(0, dim_top(i), room_width, dim_top(i) + DIM_H, false);
    }
    draw_set_colour(c_white);
}
