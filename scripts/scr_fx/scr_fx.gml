// scr_fx: particles, screen shake and the ambient life of each world (pollen and fireflies above, embers below).
// Particles are plain structs in global.fx. They live in world space and are drawn by the front art object.

function fx_init() {
    global.fx    = [];
    global.shake = 0;
}

/// @desc One particle. _size in world units (1 unit = 2 screen pixels), _life in frames.
function fx_emit(_x, _y, _vx, _vy, _life, _size, _col, _grav = 0, _add = false) {
    if (array_length(global.fx) > 900) return;
    array_push(global.fx, {
        x: _x, y: _y, vx: _vx, vy: _vy, life: 0, span: _life, size: _size, col: _col, grav: _grav, add: _add,
        dim: dim_of_y(_y)
    });
}

/// @desc A ring-ish burst of particles.
function fx_burst(_x, _y, _n, _col, _speed, _life, _size = 1.5, _grav = 0.04, _add = true) {
    repeat (_n) {
        var _a = random(360);
        var _s = random_range(_speed * 0.35, _speed);
        fx_emit(_x, _y, lengthdir_x(_s, _a), lengthdir_y(_s, _a) - 0.3, irandom_range(_life div 2, _life), random_range(_size * 0.6, _size), _col, _grav, _add);
    }
}

/// @desc A little puff of dust kicked up at the feet (landing, jumping, skidding).
function fx_dust(_x, _y, _dir, _n = 4, _col = c_white) {
    repeat (_n) {
        fx_emit(_x + random_range(-3, 3), _y - 1, _dir * random_range(0.1, 0.6) + random_range(-0.3, 0.3), random_range(-0.5, -0.1),
                irandom_range(12, 22), random_range(1.2, 2.4), _col, 0, false);
    }
}

function shake_add(_amount) {
    global.shake = max(global.shake, _amount);
}

function fx_update() {
    global.frame++;
    for (var i = array_length(global.fx) - 1; i >= 0; i--) {
        var _p = global.fx[i];
        _p.x += _p.vx;
        _p.y += _p.vy;
        _p.vy += _p.grav;
        _p.life++;
        if (_p.life >= _p.span) array_delete(global.fx, i, 1);
    }
    global.shake = max(global.shake - 0.35, 0);
    fx_ambient();
}

/// @desc Pollen and fireflies drift through the overworld; embers rise out of the underworld.
function fx_ambient() {
    if (!variable_global_exists("cams")) return;
    for (var d = 0; d < 2; d++) {
        var _cam = global.cams[d];
        var _vx = camera_get_view_x(_cam);
        var _vy = camera_get_view_y(_cam);
        if (d == 1) {
            if (irandom(5) == 0) {
                fx_emit(_vx + random(VIEW_W), _vy + VIEW_H + 2, random_range(-0.15, 0.25), random_range(-0.7, -0.3), irandom_range(90, 170),
                        random_range(0.8, 1.6), make_colour_rgb(255, irandom_range(80, 170), 40), 0, true);
            }
        } else {
            if (irandom(9) == 0) {
                fx_emit(_vx + random(VIEW_W), _vy + random_range(40, VIEW_H - 20), random_range(-0.25, 0.25), random_range(-0.15, 0.1), irandom_range(120, 220),
                        random_range(0.8, 1.4), make_colour_rgb(255, 240, irandom_range(140, 200)), 0, true);
            }
        }
    }
}

function fx_draw(_dim) {
    var _n = array_length(global.fx);
    for (var i = 0; i < _n; i++) {
        var _p = global.fx[i];
        if (_p.dim != _dim) continue;
        var _t = _p.life / _p.span;
        var _a = 1 - _t * _t;
        var _s = _p.size * (1 - 0.5 * _t);
        if (_p.add) gpu_set_blendmode(bm_add);
        draw_set_alpha(_a);
        draw_set_colour(_p.col);
        draw_rectangle(round(_p.x - _s / 2), round(_p.y - _s / 2), round(_p.x + _s / 2), round(_p.y + _s / 2), false);
        if (_p.add) gpu_set_blendmode(bm_normal);
    }
    draw_set_alpha(1);
    draw_set_colour(c_white);
}
