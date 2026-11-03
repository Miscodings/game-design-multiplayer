var _col = global.theme[dim].accent;
draw_sprite_ext(sprite_index, 0, x, y, image_xscale, image_yscale, 0, _col, 0.35);
draw_set_colour(_col);
draw_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom, true);
draw_set_colour(c_white);
