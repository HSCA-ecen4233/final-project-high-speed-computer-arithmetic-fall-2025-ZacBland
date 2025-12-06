vsim -c -do ./scripts/test_fadd_0.do
vsim -c -do ./scripts/test_fadd_1.do
vsim -c -do ./scripts/test_fadd_2.do

vsim -c -do ./scripts/test_fmul_0.do
vsim -c -do ./scripts/test_fmul_1.do
vsim -c -do ./scripts/test_fmul_2.do

vsim -c -do ./scripts/test_fma_0.do
vsim -c -do ./scripts/test_fma_1.do
vsim -c -do ./scripts/test_fma_2.do

vsim -c -do ./scripts/test_fma_special_rz.do
vsim -c -do ./scripts/test_fma_special_rne.do
vsim -c -do ./scripts/test_fma_special_rp.do
vsim -c -do ./scripts/test_fma_special_rm.do