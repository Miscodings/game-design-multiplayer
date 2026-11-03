// tunables
walk_speed = 0.6;
grav       = 0.25;
max_fall   = 6;

// state (dir is set per instance in the room editor: 1 = right, -1 = left)
movement_init();
dim         = dim_of_y(y);
grounded    = false;
if (dir == 0) dir = 1;
image_xscale = dir;
image_blend  = make_colour_rgb(232, 92, 92);
