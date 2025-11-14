onbreak {resume}

# create library
if [file exists work] {
    vdel -all
}
vlib work

# compile source files
vlog -lint rtl/align.sv tb/align_tb.sv

# start and run simulation
vsim -voptargs=+acc work.test

run -all
quit