// Room Start: every instance in the room exists by now.
players_spawn();
echoes_spawn();
boxes_link();
coins_count();
terrain_build();
deco_build();
cameras_follow();
// the art layers: sky behind everything, the terrain behind the action, particles in front
instance_create_depth(0, 0, 1000, obj_art, { kind: 0 });
instance_create_depth(0, 0, 350, obj_art, { kind: 1 });
instance_create_depth(0, 0, -300, obj_art, { kind: 2 });
