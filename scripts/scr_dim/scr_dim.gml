// scr_dim: helpers for the two stacked dimensions.
// Dimension 0 is the top band (player 0), dimension 1 the bottom band (player 1).
// An instance's dimension is simply which band its y lies in.

function dim_of_y(_y) {
    return floor(_y / DIM_H);
}

/// @desc y coordinate of the top of a dimension's band.
/// @desc World y of the top of a dimension's camera (the view shows the bottom VIEW_H pixels of the band).
function dim_view_top(_dim) {
    return _dim * DIM_H + DIM_H - VIEW_H;
}

function dim_top(_dim) {
    return _dim * DIM_H;
}

/// @desc The same local height, in the other dimension.
function dim_mirror_y(_y) {
    return _y + ((dim_of_y(_y) == 0) ? DIM_H : -DIM_H);
}

function player_get(_id) {
    return global.players[_id];
}

function player_partner(_id) {
    return global.players[1 - _id];
}

/// @desc Placeholder colours per dimension. Swap for real art / tileset themes later.
function theme_init() {
    global.theme = [
        { bg: make_colour_rgb(40, 34, 58), solid: make_colour_rgb(112, 94, 142), accent: make_colour_rgb(246, 202, 122) },
        { bg: make_colour_rgb(16, 40, 48), solid: make_colour_rgb(54, 112, 122),  accent: make_colour_rgb(134, 226, 216) }
    ];
}
