%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_nn, assert_not_zero
from starkware.starknet.common.syscalls import get_caller_address

#
# Storage Variables
#

# Current counter value.
@storage_var
func _counter() -> (count : felt):
end

#
# External Functions
#

# Increment internal counter by 1, returning the previous and new counter values.
@external
func incrementCounter{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (prev_count : felt, new_count : felt):
    
    let (prev_count) = _counter.read()
    let new_count = prev_count + 1
    _counter.write(new_count)

    return (prev_count=prev_count, new_count=new_count)
end

#
# View Functions
#

# Return the counter value.
@view
func counter{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (count : felt):
    let (count) = _counter.read()
    return (count=count)
end
