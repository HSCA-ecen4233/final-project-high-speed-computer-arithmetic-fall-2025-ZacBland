onbreak {resume}

# create library
if [file exists work] {
    vdel -all
}
vlib work

# compile source files
vlog -lint rtl/* tb/fma_tb.sv

# start and run simulation
vsim -voptargs=+acc work.stimulus

run -all
quit