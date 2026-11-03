/// @desc Move _start toward _end by at most _amount.
function approach(_start, _end, _amount) {
    if (_start > _end) return max(_start - _amount, _end);
    return min(_start + _amount, _end);
}
