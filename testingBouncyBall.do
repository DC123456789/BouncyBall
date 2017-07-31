vlib work
vlog -timescale 1ns/1ns BouncyBall.v
vsim BouncyBall
log {/*}
add wave {/*}
add wave {/C0/*}
# Reset everything
force {SW} 2#00000000
force {KEY} 2#0000
force {CLOCK_50} 0 0ns, 1 5 ns -r 10 ns
run 10 ns
force {SW} 2#00000001
force -deposit {C0/current_state} 10#13
force -deposit {D0/ball_x} 10#1
force -deposit {D0/ball_y} 10#113
force -deposit {D0/paddle_x} 10#1
force -deposit {D0/ball_direction} 2#1
force -deposit {C0/current_state} 10#13
force {CLOCK_50} 0 0ns, 1 5 ns -r 10 ns
run 30 ns