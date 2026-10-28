#macro WORLD_W 1700
#macro WORLD_H 360
#macro SCREEN_W 1280
#macro FLOOR_Y 320
#macro GRAVITY 0.5
#macro RUN_SPEED 3
#macro JUMP_SPEED 9.7
// horizontal gap (px) the pair can have before balance starts to drain, and the gap where it bottoms out
#macro BALANCE_SAFE 260
#macro BALANCE_FAR 800

// fonts are bitmap assets sized at twice their layout size, so drawing at half scale stays sharp
function ui_text(_x, _y, _str, _big = false) {
	draw_set_font(_big ? fnt_title : fnt_ui);
	draw_text_transformed(_x, _y, _str, 0.5, 0.5, 0);
}

function Rect(_x, _y, _w, _h) constructor {
	x = _x;
	y = _y;
	w = _w;
	h = _h;
}

// world 0 = light (player 1), world 1 = shadow (player 2). x/y is bottom-centre of the body.
function Actor(_world, _spawn_x) constructor {
	world = _world;
	spawn_x = _spawn_x;
	x = _spawn_x;
	y = FLOOR_Y;
	vx = 0;
	vy = 0;
	w = 20;
	h = 24;
	face = 1;
	grounded = false;
	at_exit = false;
	sub = 0;
}

function rects_overlap(_ax, _ay, _aw, _ah, _bx, _by, _bw, _bh) {
	return _ax < _bx + _bw && _ax + _aw > _bx && _ay < _by + _bh && _ay + _ah > _by;
}

function box_hits(_rects, _x, _y, _w, _h) {
	for (var i = 0; i < array_length(_rects); i++) {
		var r = _rects[i];
		if (rects_overlap(_x, _y, _w, _h, r.x, r.y, r.w, r.h)) return true;
	}
	return false;
}

// everything a body in this world can stand on, except the crate (handled separately)
function solids_for(_world) {
	var g = global.game;
	var out = [];
	array_copy(out, 0, g.statics[_world], 0, array_length(g.statics[_world]));
	if (_world == 0) {
		if (g.lever_on) array_push(out, g.bridge);
	} else {
		if (!g.door_open) array_push(out, g.door);
	}
	return out;
}

function crate_hit(_x, _y, _w, _h) {
	var c = global.game.crate;
	return rects_overlap(_x, _y, _w, _h, c.x, c.y, c.w, c.h);
}

// only the light world can move the crate; the shadow world just sees it move
function crate_push(_dir) {
	var c = global.game.crate;
	if (!box_hits(solids_for(0), c.x + _dir, c.y, c.w, c.h)) c.x += _dir;
}

function crate_update() {
	var g = global.game;
	var c = g.crate;
	var solids = solids_for(0);
	c.vy = min(c.vy + GRAVITY, 10);
	repeat (ceil(c.vy)) {
		if (box_hits(solids, c.x, c.y + 1, c.w, c.h)) {
			c.vy = 0;
			break;
		}
		c.y += 1;
	}
	if (c.y > WORLD_H + 120) {
		c.x = g.crate_home_x;
		c.y = FLOOR_Y - c.h;
		c.vy = 0;
	}
}

function actor_move(_a, _dx, _dy) {
	var solids = solids_for(_a.world);
	var bw = _a.w;
	var bh = _a.h;
	var sx = sign(_dx);

	repeat (abs(_dx)) {
		var nx = _a.x + sx;
		var bl = nx - bw / 2;
		var bt = _a.y - bh;
		// beside the crate (not standing on it) means pushing it
		if (_a.world == 0 && _a.y > global.game.crate.y + 4 && crate_hit(bl, bt, bw, bh)) crate_push(sx);
		if (box_hits(solids, bl, bt, bw, bh) || crate_hit(bl, bt, bw, bh)) {
			_a.vx = 0;
			break;
		}
		_a.x = nx;
	}

	var bl2 = _a.x - bw / 2;
	var sy = sign(_dy);
	var rem = abs(_dy);
	while (rem > 0) {
		var step = min(1, rem) * sy;
		if (box_hits(solids, bl2, _a.y + step - bh, bw, bh) || crate_hit(bl2, _a.y + step - bh, bw, bh)) {
			_a.vy = 0;
			break;
		}
		_a.y += step;
		rem -= 1;
	}

	_a.grounded = _a.vy >= 0 && (box_hits(solids, bl2, _a.y + 1 - bh, bw, bh) || crate_hit(bl2, _a.y + 1 - bh, bw, bh));
}

function actor_update(_a, _dir, _jump, _speed) {
	_a.vx = _dir * RUN_SPEED * _speed;
	if (_dir != 0) _a.face = _dir;
	if (_jump && _a.grounded) _a.vy = -JUMP_SPEED;
	_a.vy = min(_a.vy + GRAVITY, 10);
	// actor_move steps whole pixels, so carry the fractional part between frames
	_a.sub = _dir == 0 ? 0 : _a.sub + _a.vx;
	var mx = sign(_a.sub) * floor(abs(_a.sub));
	_a.sub -= mx;
	actor_move(_a, mx, _a.vy);
	_a.x = clamp(_a.x, _a.w / 2, WORLD_W - _a.w / 2);
	if (_a.y > WORLD_H + 100) {
		_a.x = _a.spawn_x;
		_a.y = FLOOR_Y;
		_a.vx = 0;
		_a.vy = 0;
	}
}

// the other player, rendered as drifting particles inside this player's world
function ghost_step(_view, _other) {
	var g = global.game;
	var gs = g.ghosts[_view];
	// low balance: the ghost wanders away from the true position and smears out
	var loose = 1 - g.balance;
	var j = g.gj[_view];
	if (g.t % 10 == 0) {
		j[2] = random_range(-1, 1) * loose * 70;
		j[3] = random_range(-1, 1) * loose * 40;
	}
	j[0] = lerp(j[0], j[2], 0.12);
	j[1] = lerp(j[1], j[3], 0.12);
	repeat (3) {
		var ang = random(360);
		var d = random(9 + loose * 24);
		array_push(gs, {
			x: _other.x + j[0] + lengthdir_x(d, ang) * 0.9,
			y: _other.y - 12 + j[1] + lengthdir_y(d, ang),
			vx: _other.vx * 0.15 + random_range(-0.25, 0.25),
			vy: random_range(-0.5, -0.05),
			life: 0,
			span: irandom_range(25, 50),
			sz: random_range(1, 2.6)
		});
	}
	for (var i = array_length(gs) - 1; i >= 0; i--) {
		var p = gs[i];
		p.x += p.vx;
		p.y += p.vy;
		p.life++;
		if (p.life >= p.span) array_delete(gs, i, 1);
	}
}

function draw_yinyang(_x, _y, _r, _dark, _light, _rot) {
	draw_set_colour(_light);
	draw_circle(_x, _y, _r, false);
	draw_set_colour(_dark);
	draw_primitive_begin(pr_trianglefan);
	draw_vertex(_x, _y);
	for (var a = -90; a <= 90; a += 10) {
		draw_vertex(_x + lengthdir_x(_r, a + _rot), _y + lengthdir_y(_r, a + _rot));
	}
	draw_primitive_end();
	var t1x = _x + lengthdir_x(_r / 2, 90 + _rot);
	var t1y = _y + lengthdir_y(_r / 2, 90 + _rot);
	var t2x = _x + lengthdir_x(_r / 2, -90 + _rot);
	var t2y = _y + lengthdir_y(_r / 2, -90 + _rot);
	draw_set_colour(_dark);
	draw_circle(t1x, t1y, _r / 2, false);
	draw_set_colour(_light);
	draw_circle(t2x, t2y, _r / 2, false);
	draw_circle(t1x, t1y, _r / 6, false);
	draw_set_colour(_dark);
	draw_circle(t2x, t2y, _r / 6, false);
	draw_circle(_x, _y, _r, true);
}

function draw_body(_a, _ink, _bg) {
	draw_set_colour(_ink);
	draw_circle(_a.x, _a.y - 12, 11, false);
	draw_set_colour(_bg);
	draw_circle(_a.x + _a.face * 4, _a.y - 14, 3, false);
}

// one world, in world coordinates; the caller sets the scissor and the camera matrix
function draw_world(_w, _cx) {
	var g = global.game;
	var bg = g.bg[_w];
	var ink = g.ink[_w];
	var mid = merge_colour(bg, ink, 0.25);
	var terr = g.terr[_w];
	var acc = g.acc[_w];

	draw_set_colour(bg);
	draw_rectangle(_cx - 2, -2, _cx + SCREEN_W + 2, WORLD_H + 2, false);

	// static terrain, with a lit top edge
	var st = g.statics[_w];
	for (var i = 0; i < array_length(st); i++) {
		var r = st[i];
		draw_set_colour(terr);
		draw_rectangle(r.x, r.y, r.x + r.w - 1, r.y + r.h - 1, false);
		draw_set_colour(merge_colour(terr, ink, 0.55));
		draw_rectangle(r.x, r.y, r.x + r.w - 1, r.y + 2, false);
	}

	// exit
	var ey = _w == 0 ? FLOOR_Y : 200;
	var pulse = 1 + 0.12 * sin(g.t * 0.1);
	var pa = _w == 0 ? g.p1 : g.p2;
	draw_set_colour(acc);
	draw_circle(g.exit_x, ey - 16, 16 * pulse, true);
	draw_circle(g.exit_x, ey - 16, 15 * pulse, true);
	if (pa.at_exit) draw_circle(g.exit_x, ey - 16, 8, false);

	if (_w == 0) {
		// crate: pushable here
		var c = g.crate;
		draw_set_colour(acc);
		draw_rectangle(c.x, c.y, c.x + c.w - 1, c.y + c.h - 1, false);
		draw_set_colour(bg);
		draw_rectangle(c.x + 8, c.y + 8, c.x + c.w - 9, c.y + c.h - 9, true);
		draw_circle(c.x + c.w / 2, c.y + c.h / 2, 4, false);

		// bridge (raised by the shadow lever)
		if (g.lever_on) {
			var b = g.bridge;
			draw_set_colour(acc);
			draw_rectangle(b.x, b.y, b.x + b.w - 1, b.y + b.h - 1, false);
			draw_set_colour(bg);
			for (var px = b.x + 20; px < b.x + b.w; px += 20) draw_line(px, b.y, px, b.y + 12);
		} else {
			draw_set_colour(mid);
			for (var px = 560; px < 720; px += 16) draw_line(px, FLOOR_Y, px + 8, FLOOR_Y);
		}

		// pressure plate (only the light player can press it)
		draw_set_colour(acc);
		var ph = g.plate_down ? 4 : 8;
		draw_rectangle(g.plate.x, FLOOR_Y - ph, g.plate.x + g.plate.w - 1, FLOOR_Y - 1, false);

		// echoes of shadow-only things
		draw_set_alpha(0.35);
		draw_set_colour(ink);
		draw_rectangle(g.door.x, g.door.y, g.door.x + g.door.w - 1, g.door.y + g.door.h - 1, !g.door_open ? false : true);
		draw_rectangle(g.lever_x - 10, FLOOR_Y - 8, g.lever_x + 9, FLOOR_Y - 1, false);
		draw_set_alpha(1);
	} else {
		// shadow of the crate: solid, but only the light world can push it
		var c2 = g.crate;
		draw_set_colour(acc);
		draw_set_alpha(0.18);
		draw_rectangle(c2.x, c2.y, c2.x + c2.w - 1, c2.y + c2.h - 1, false);
		draw_set_alpha(1);
		draw_rectangle(c2.x, c2.y, c2.x + c2.w - 1, c2.y + c2.h - 1, true);
		draw_rectangle(c2.x + 1, c2.y + 1, c2.x + c2.w - 2, c2.y + c2.h - 2, true);
		draw_line(c2.x, c2.y, c2.x + c2.w - 1, c2.y + c2.h - 1);
		draw_line(c2.x + c2.w - 1, c2.y, c2.x, c2.y + c2.h - 1);

		// door: held open by the light plate
		var d = g.door;
		draw_set_colour(acc);
		if (!g.door_open) {
			draw_rectangle(d.x, d.y, d.x + d.w - 1, d.y + d.h - 1, false);
			draw_set_colour(bg);
			draw_circle(d.x + d.w / 2, d.y + d.h / 2, 4, false);
		} else {
			draw_set_alpha(0.4);
			draw_rectangle(d.x, d.y, d.x + d.w - 1, d.y + d.h - 1, true);
			draw_set_alpha(1);
		}

		// lever (only the shadow player can pull it)
		var lx = g.lever_x;
		var ang = 90 - g.lever_ang * 35;
		var kx = lx + lengthdir_x(26, ang);
		var ky = FLOOR_Y - 6 + lengthdir_y(26, ang);
		draw_set_colour(acc);
		draw_rectangle(lx - 12, FLOOR_Y - 8, lx + 11, FLOOR_Y - 1, false);
		draw_line_width(lx, FLOOR_Y - 8, kx, ky, 3);
		draw_circle(kx, ky, 5, false);
		if (abs(g.p2.x - lx) < 40 && !g.won) {
			draw_set_halign(fa_center);
			ui_text(lx, FLOOR_Y - 62, "[DOWN]");
			draw_set_halign(fa_left);
		}

		// echoes of light-only things
		draw_set_alpha(0.35);
		draw_set_colour(ink);
		if (g.lever_on) {
			draw_rectangle(560, FLOOR_Y, 719, FLOOR_Y + 10, false);
		} else {
			for (var px2 = 560; px2 < 720; px2 += 16) draw_line(px2, FLOOR_Y, px2 + 8, FLOOR_Y);
		}
		draw_rectangle(g.plate.x, FLOOR_Y - (g.plate_down ? 4 : 8), g.plate.x + g.plate.w - 1, FLOOR_Y - 1, !g.plate_down);
		draw_set_alpha(1);
	}

	// the other player, as particles
	var gs = g.ghosts[_w];
	draw_set_colour(merge_colour(bg, ink, 0.7));
	for (var i = 0; i < array_length(gs); i++) {
		var p = gs[i];
		draw_set_alpha(0.8 * (1 - p.life / p.span));
		draw_circle(p.x, p.y, p.sz, false);
	}
	draw_set_alpha(1);

	// this world's player
	draw_body(pa, ink, bg);

	// shade the edge that touches the divider so the halves read as separate rooms
	var shade = merge_colour(bg, c_black, 0.5);
	draw_set_colour(shade);
	for (var s = 0; s < 6; s++) {
		draw_set_alpha(0.45 * (1 - s / 6));
		if (_w == 0) draw_rectangle(_cx, WORLD_H - 6 * (s + 1), _cx + SCREEN_W, WORLD_H - 6 * s, false);
		else draw_rectangle(_cx, 6 * s, _cx + SCREEN_W, 6 * (s + 1), false);
	}
	draw_set_alpha(1);
}
