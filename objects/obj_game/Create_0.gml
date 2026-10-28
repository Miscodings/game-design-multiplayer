global.game = id;

// windowed, but nearly the full screen (16:9 kept, room left for title bar and taskbar)
var fit = min(display_get_width() * 0.97 / 1280, (display_get_height() - 120) / 720);
var win_w = floor(1280 * fit);
var win_h = floor(720 * fit);
window_set_size(win_w, win_h);
window_center();

// render at the window's real resolution (not 1280x720 stretched up), with antialiasing and smooth circles
display_reset(4, true);
surface_resize(application_surface, win_w, win_h);
display_set_gui_size(1280, 720);
draw_set_circle_precision(64);
gpu_set_texfilter(true);

t = 0;
won = false;

// light world: warm cream and plum. shadow world: deep indigo and aqua. coral / gold mark things you can interact with.
bg = [make_colour_rgb(242, 230, 208), make_colour_rgb(20, 24, 52)];
ink = [make_colour_rgb(62, 48, 84), make_colour_rgb(140, 220, 212)];
terr = [make_colour_rgb(120, 98, 146), make_colour_rgb(46, 62, 112)];
acc = [make_colour_rgb(226, 112, 92), make_colour_rgb(244, 196, 98)];

// terrain per world: 0 = light, 1 = shadow
statics = [
	[new Rect(0, 320, 560, 40), new Rect(720, 320, 980, 40), new Rect(1000, 210, 30, 110)],
	[new Rect(0, 320, 1000, 40), new Rect(1000, 200, 700, 160)]
];

bridge = new Rect(560, 320, 160, 40);
door = new Rect(700, 120, 24, 200);
plate = new Rect(450, 312, 50, 8);
lever_x = 180;
exit_x = 1560;

crate_home_x = 800;
crate = { x: crate_home_x, y: FLOOR_Y - 40, w: 40, h: 40, vy: 0 };

lever_on = false;
lever_ang = -1;
plate_down = false;
door_open = false;

p1 = new Actor(0, 80);
p2 = new Actor(1, 80);

cam = [0, 0];
ghosts = [[], []];

// balance: 1 when the pair stays close, drains as they spread apart horizontally (height does not count)
balance = 1;
gj = [[0, 0, 0, 0], [0, 0, 0, 0]];
