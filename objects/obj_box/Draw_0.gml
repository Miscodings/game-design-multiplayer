var _col = merge_colour(global.theme[dim].solid, global.theme[dim].accent, 0.65);
draw_sprite_ext(sprite_index, 0, x, y, image_xscale, image_yscale, 0, _col, 1);
box_glow_draw();
// a bright dot in the corner shows the box has found its partner in the other dimension
if (partner != noone) {
    draw_set_colour(global.theme[dim].accent);
    draw_rectangle(bbox_left + 3, bbox_top + 3, bbox_left + 4, bbox_top + 4, false);
    draw_set_colour(c_white);
}
