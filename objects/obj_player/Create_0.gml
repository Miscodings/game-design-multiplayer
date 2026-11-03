// player_id (0 or 1) is passed in by players_spawn(). Player 0 lives in the top dimension, player 1 in the bottom.

// tunables
accel              = 0.25;
decel              = 0.35;
max_speed          = 2;
grav               = 0.25;
max_fall           = 6;
jump_speed         = 4.6;
jump_cut           = 1.8;
coyote_frames      = 6;
jump_buffer_frames = 6;
stomp_bounce       = 3.2;

// state
movement_init();
dim               = player_id;
input             = global.input[player_id];
grounded          = false;
face              = 1;
coyote_timer      = 0;
jump_buffer_timer = 0;
push_timer        = 0;
image_blend       = global.theme[dim].accent;
