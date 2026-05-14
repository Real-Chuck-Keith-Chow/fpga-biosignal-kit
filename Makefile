SIM=tb_pipeline

sim:
	verilator --binary \
	fpga/src/top_module.sv \
	fpga/src/adc_interface.sv \
	fpga/src/filter.sv \
	fpga/src/uart_tx.sv \
	fpga/tb/$(SIM).sv

run:
	./obj_dir/V$(SIM)

etl:
	cd python-etl && python3 etl.py

api:
	cd api && python3 server.py

clean:
	rm -rf obj_dir *.vcd *.log
