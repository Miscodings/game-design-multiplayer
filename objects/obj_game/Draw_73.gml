// Draw End runs once per view, after everything else is drawn: darkness (with holes where lights are) goes over the
// world, then the vignette. (Post Draw would NOT work here: it runs once per frame, outside the views.)
darkness_draw();
if (view_current <= 1) vignette_draw(view_current);
