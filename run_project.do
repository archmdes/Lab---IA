#Rodando a convolução

vsim work.tb_conv_4_filters_relu
run -all
quit -sim

#Rodando o max_pooling

vsim work.testbench_pooling
run -all
quit -sim

#Rodando a serializacao

vsim work.Test_Flat
run -all
quit -sim

#Rodando a camada densa

vsim work.tb_dense_900x1_sigmoid
run -all
quit -sim