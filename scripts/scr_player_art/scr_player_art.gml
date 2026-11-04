// scr_player_art: animation, squash and stretch and drawing for the two heroes, plus the feel effects (dust, shake)
// that come with moving. Frames in the hero sprites (80 x 64 px each, standing on the bottom edge):
//   0-4 idle, 5-12 walk, 13-20 run, 21-24 jump, 25-28 fall, 29-38 death.

#macro HERO_IDLE   0
#macro HERO_RUN    13
#macro HERO_JUMP   21
#macro HERO_FALL   25
#macro HERO_DEATH  29

function player_art_init() {
    squash       = 0;       // > 0 squashed (landing), < 0 stretched (taking off)
    was_grounded = false;
    prev_yspd    = 0;
    idle_t       = 0;
    run_t        = 0;
    air_t        = 0;
    step_dust    = 0;
    blink_t      = irandom(200);
}

/// @desc Run once per frame after the movement: landing and take-off effects, animation clocks.
function player_art_update() {
    var _col = global.art[dim].dust;

    // landing: the squash and the puff scale with how hard we hit
    if (grounded && !was_grounded) {
        var _hard = clamp((prev_yspd - 1.5) / 4, 0, 1);
        squash = 0.1 + 0.22 * _hard;
        fx_dust(x, y, 0, 3 + round(5 * _hard), _col);
        if (_hard > 0.7) shake_add(1.2);
        air_t = 0;
    }
    // taking off: stretch tall
    if (!grounded && was_grounded && yspd < 0) {
        squash = -0.18;
        fx_dust(x, y, -face, 3, _col);
    }
    was_grounded = grounded;
    prev_yspd = yspd;

    // squash settles back to normal
    squash = lerp(squash, 0, 0.22);
    if (abs(squash) < 0.01) squash = 0;

    if (grounded) {
        air_t = 0;
        if (abs(xspd) > 0.2) {
            run_t += abs(xspd) * 0.11;
            // a puff on every footfall, and when skidding to turn around
            step_dust--;
            if (step_dust <= 0) {
                step_dust = 9;
                fx_dust(x - face * 3, y, -face * 0.4, 1, _col);
            }
        } else {
            idle_t += 0.1;
            run_t = 0;
        }
    } else {
        air_t++;
    }
}

function player_art_draw() {
    var _a = global.art[dim];
    var _spr = _a.hero;
    if (!sprite_exists(_spr)) { draw_self(); return; }

    var _idx;
    if (global.game_state == GAME_STATE.FAILED) {
        _idx = HERO_DEATH + min(9, floor(global.fail_time / 5));
    } else if (!grounded) {
        if (yspd < -0.3)     _idx = HERO_JUMP + min(3, floor(air_t / 4));
        else if (yspd < 0.6) _idx = HERO_JUMP + 3;
        else                 _idx = HERO_FALL + min(3, floor((air_t - 12) / 5));
        if (_idx < HERO_JUMP) _idx = HERO_JUMP;
    } else if (abs(xspd) > 0.2) {
        _idx = HERO_RUN + (floor(run_t) mod 8);
    } else {
        _idx = HERO_IDLE + (floor(idle_t) mod 5);
    }

    // a soft glow behind the hero in their world's colour
    var _ac = global.theme[dim].accent;
    gpu_set_blendmode(bm_add);
    draw_sprite_ext(spr_light, 0, x, y - 11, 0.28, 0.28, 0, _ac, 0.32 + 0.06 * sin(global.frame * 0.08));
    gpu_set_blendmode(bm_normal);

    var _sx = ART_S * (1 + squash) * face;
    var _sy = ART_S * (1 - squash);
    draw_sprite_ext(_spr, _idx, x, y, _sx, _sy, 0, c_white, 1);
}
