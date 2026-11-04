var _d = view_current;
if (_d > 1) exit;
switch (kind) {
    case 0: bg_draw(_d); break;
    case 1: terrain_draw(_d); deco_draw(_d); break;
    case 2: fx_draw(_d); break;
}
