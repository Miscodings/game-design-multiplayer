// scissor works in surface pixels, so scale the layout rectangle up to the surface
var k = surface_get_width(application_surface) / SCREEN_W;
for (var w = 0; w < 2; w++) {
	gpu_set_scissor(0, floor(w * WORLD_H * k), ceil(SCREEN_W * k), ceil(WORLD_H * k));
	matrix_set(matrix_world, matrix_build(-floor(cam[w]), w * WORLD_H, 0, 0, 0, 0, 1, 1, 1));
	draw_world(w, floor(cam[w]));
}

gpu_set_scissor(0, 0, surface_get_width(application_surface), surface_get_height(application_surface));
matrix_set(matrix_world, matrix_build_identity());
draw_set_alpha(1);
