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
force {CLOCK_50} 0 0ns, 1 5 ns -r 10 ns
run 600 ns