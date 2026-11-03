var _on = pressed || latched;
var _col = _on ? global.theme[dim].accent : merge_colour(global.theme[dim].accent, c_black, 0.5);
// a pressed plate sinks: half the height, pushed down
draw_sprite_ext(sprite_index, 0, x, y + (pressed ? 2 : 0), image_xscale, image_yscale * (pressed ? 0.5 : 1), 0, _col, 1);
