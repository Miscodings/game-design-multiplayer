// scr_light: a per-frame list of light sources, and the darkness that those lights cut holes in.
//
// Anything that glows calls light_add() during its Step. obj_game clears the list in Begin Step.
// In Draw End, once per view, darkness_draw() fills every obj_dark_zone of that view's dimension
// with opaque black on a surface, erases a soft hole at each light, and draws the surface over the
// view. Only lights in the same dimension as the view count. Anything inside a dark zone (hazards
// included) stays hidden until a light reaches it.

function lights_init() {
    global.lights    = [];
    global.dark_surf = [-1, -1];
}

function lights_clear() {
    global.lights = [];
}

function lights_cleanup() {
    for (var i = 0; i < 2; i++) {
        if (surface_exists(global.dark_surf[i])) surface_free(global.dark_surf[i]);
        global.dark_surf[i] = -1;
    }
}

/// @desc Add a light for this frame. _strength (0..1) is how much darkness it removes at its centre.
function light_add(_x, _y, _radius, _strength = 1) {
    array_push(global.lights, { x: _x, y: _y, r: _radius, s: _strength, dim: dim_of_y(_y) });
}

/// @desc A small glow around the calling player so they can always see themselves.
function player_emit_light() {
    light_add(x, y - 8, PLAYER_GLOW, 0.9);
}

/// @desc Called from obj_game's Draw End event, which runs once per view.
function darkness_draw() {
    var _v = view_current;
    if (_v > 1) return;
    var _dim = _v;

    var _has_zone = false;
    with (obj_dark_zone) {
        if (dim == _dim) _has_zone = true;
    }
    if (!_has_zone) return;

    var _cam = global.cams[_v];
    var _vx = camera_get_view_x(_cam);
    var _vy = camera_get_view_y(_cam);

    if (!surface_exists(global.dark_surf[_v])) global.dark_surf[_v] = surface_create(VIEW_W, VIEW_H);
    var _surf = global.dark_surf[_v];

    surface_set_target(_surf);
    draw_clear_alpha(c_black, 0);

    // 1. opaque black over each dark zone in this dimension
    draw_set_colour(c_black);
    draw_set_alpha(1);
    with (obj_dark_zone) {
        if (dim == _dim) dark_zone_fill(bbox_left - _vx, bbox_top - _vy, bbox_right - _vx, bbox_bottom - _vy, feather);
    }

    // 2. erase a soft hole at every light: dst = dst * (1 - light alpha)
    gpu_set_blendmode_ext(bm_zero, bm_inv_src_alpha);
    var _n = array_length(global.lights);
    for (var i = 0; i < _n; i++) {
        var _l = global.lights[i];
        if (_l.dim != _dim) continue;
        var _sc = (_l.r * 2) / sprite_get_width(spr_light);
        draw_sprite_ext(spr_light, 0, _l.x - _vx, _l.y - _vy, _sc, _sc, 0, c_white, _l.s);
    }
    gpu_set_blendmode(bm_normal);
    surface_reset_target();

    // 3. lay the darkness over the view
    draw_surface(_surf, _vx, _vy);
    draw_set_colour(c_white);
}

/// @desc Fill one dark zone with black. The left and right edges fade in over _feather pixels, like walking
/// into a cave mouth, instead of a hard line. Top and bottom stay solid (they sit on the band edges).
function dark_zone_fill(_x1, _y1, _x2, _y2, _feather) {
    var _f = clamp(_feather, 0, (_x2 - _x1) / 2);

    // solid middle
    draw_set_colour(c_black);
    draw_set_alpha(1);
    draw_rectangle(_x1 + _f, _y1, _x2 - _f, _y2, false);
    if (_f <= 0) return;

    // soft entrances: a strip of quads whose alpha follows a smoothstep curve
    var _steps = 10;
    gpu_set_blendmode_ext_sepalpha(bm_src_alpha, bm_inv_src_alpha, bm_one, bm_inv_src_alpha);
    for (var side = 0; side < 2; side++) {
        draw_primitive_begin(pr_trianglestrip);
        for (var i = 0; i <= _steps; i++) {
            var _t = i / _steps;
            var _a = _t * _t * (3 - 2 * _t);
            var _x = (side == 0) ? _x1 + _f * _t : _x2 - _f * _t;
            draw_vertex_colour(_x, _y1, c_black, _a);
            draw_vertex_colour(_x, _y2, c_black, _a);
        }
        draw_primitive_end();
    }
    gpu_set_blendmode(bm_normal);
}
