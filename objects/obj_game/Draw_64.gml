var gw = display_get_gui_width();
var gh = display_get_gui_height();
var half = gh / 2;

// divider band: each side takes its own world's colour, with a bright seam between
var band = 10;
draw_set_colour(merge_colour(bg[0], c_black, 0.45));
draw_rectangle(0, half - band, gw, half, false);
draw_set_colour(merge_colour(bg[1], c_black, 0.5));
draw_rectangle(0, half, gw, half + band, false);
draw_set_colour(merge_colour(ink[0], ink[1], 0.5));
draw_rectangle(0, half - 1, gw, half, false);
// balance meter: one bar across the middle of the divider, draining toward both ends from the centre
var full = 274;
var len = full * balance;
var mc = merge_colour(acc[0], acc[1], 0.5);
draw_set_colour(merge_colour(bg[0], bg[1], 0.5));
draw_rectangle(gw / 2 - full, half - 3, gw / 2 + full, half + 2, false);
draw_set_colour(merge_colour(c_gray, mc, balance));
draw_rectangle(gw / 2 - len, half - 3, gw / 2 + len, half + 2, false);

// world tags stay on screen
draw_set_halign(fa_right);
draw_set_colour(ink[0]);
ui_text(gw - 14, 10, "LIGHT  -  P1");
draw_set_colour(ink[1]);
ui_text(gw - 14, half + band + 6, "SHADOW  -  P2");
draw_set_halign(fa_left);

if (won) {
	draw_set_alpha(0.8);
	draw_set_colour(bg[1]);
	draw_rectangle(0, half - 50, gw, half + 50, false);
	draw_set_alpha(1);
	draw_set_colour(acc[1]);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	ui_text(gw / 2, half - 14, "IN BALANCE", true);
	draw_set_colour(ink[1]);
	ui_text(gw / 2, half + 24, "press R to play again");
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
}
