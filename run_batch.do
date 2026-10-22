if {[file exists rtl_work] == 0} {
    vlib rtl_work
}
vmap work rtl_work
vlog -work work rtl/*.v
vsim -c work.tb_CPU
run -all
quit -f
