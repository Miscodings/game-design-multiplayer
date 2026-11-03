// an open gate is parked offscreen, so always draw at home_y
draw_sprite_ext(sprite_index, 0, home_x, home_y, image_xscale, image_yscale, 0, global.theme[dim].accent, is_open ? 0.2 : 1);
