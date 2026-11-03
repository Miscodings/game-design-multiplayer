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

/// @desc Each camera follows its own player in x only (y stays locked to its band).
/// No smoothing on purpose: players move in whole pixels, so locking the camera to the
/// player's position keeps the player perfectly steady on screen. Any lerp here makes
/// the player jitter against the world.
function cameras_follow() {
    for (var i = 0; i < 2; i++) {
        var _p = global.players[i];
        if (!instance_exists(_p)) continue;
        var _tx = clamp(floor(_p.x) - VIEW_W / 2, 0, max(0, room_width - VIEW_W));
        camera_set_view_pos(global.cams[i], _tx, dim_view_top(i));
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
