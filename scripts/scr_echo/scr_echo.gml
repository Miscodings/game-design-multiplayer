// scr_echo: presence as influence. Wherever a player stands, glowing particles rise at the same x in the
// other dimension, lighting it up. One obj_echo per player, created at Room Start.

function echoes_spawn() {
    for (var i = 0; i < 2; i++) {
        var _p = global.players[i];
        instance_create_layer(0, 0, _p.layer, obj_echo, { source_player: _p });
    }
}

function echo_update() {
    if (!instance_exists(source_player)) return;

    // same x, same height within the band, in the other dimension
    x = source_player.x;
    y = dim_mirror_y(source_player.y);
    var _cy = y - 8;   // centre of the body

    // the presence itself lights the area where the partner stands
    light_add(x, _cy, ECHO_RADIUS, 1);

    // a small cloud of particles around the partner: a few born every frame, drifting up and carrying a
    // little of the partner's own motion, then fading out
    repeat (3) {
        if (array_length(motes) >= ECHO_MOTES) break;
        var _ang = random(360);
        var _d = random(9);
        array_push(motes, {
            x: x + lengthdir_x(_d, _ang) * 0.9,
            y: _cy + lengthdir_y(_d, _ang),
            vx: source_player.xspd * 0.15 + random_range(-0.25, 0.25),
            vy: random_range(-0.5, -0.05),
            life: 0,
            span: irandom_range(25, 50),
            sz: random_range(1, 2.6)
        });
    }

    // every particle glows too, fading with its life
    for (var i = array_length(motes) - 1; i >= 0; i--) {
        var _m = motes[i];
        _m.x += _m.vx;
        _m.y += _m.vy;
        _m.life++;
        if (_m.life >= _m.span) {
            array_delete(motes, i, 1);
        } else {
            var _f = 1 - _m.life / _m.span;
            light_add(_m.x, _m.y, 8 + 12 * _f, 0.7 * _f);
        }
    }
}

function echo_draw() {
    // particles are the colour of the player they stand for (the same colour as that player's square)
    if (!instance_exists(source_player)) return;
    draw_set_colour(source_player.image_blend);
    for (var i = 0; i < array_length(motes); i++) {
        var _m = motes[i];
        draw_set_alpha(0.35 * (1 - _m.life / _m.span));
        draw_circle(_m.x, _m.y, _m.sz, false);
    }
    draw_set_alpha(1);
    draw_set_colour(c_white);
}
