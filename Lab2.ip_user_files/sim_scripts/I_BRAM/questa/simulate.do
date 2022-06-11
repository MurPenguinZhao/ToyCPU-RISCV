onbreak {quit -f}
onerror {quit -f}

vsim -lib xil_defaultlib I_BRAM_opt

set NumericStdNoWarnings 1
set StdArithNoWarnings 1

do {wave.do}

view wave
view structure
view signals

do {I_BRAM.udo}

run -all

quit -force
