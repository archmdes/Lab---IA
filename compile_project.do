quit -sim

vlib work
vmap work work

vlog -work work convolucao/*.v max_pooling/*.v camada_densa/*.v serializacao/*.v

echo "--- Compilacao Finalizada! ---"
echo "para rodar testbench: vsim work.testbench"
echo "run -all"