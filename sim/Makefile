

# Makefile

VERILATOR = verilator
VERILATOR_FLAGS = -Wall -sv --cc
VERILATOR_INCLUDE = -I../src -I../src/AXI
VERILATOR_LIB_DIR = /usr/local/share/verilator/include

TB_DIR = ../tb
TB_SOURCE = $(TB_DIR)/top_level_nn_tb.sv
SRC_DIR = ../src
SRC_FILES = $(wildcard $(SRC_DIR)/*.sv) $(wildcard $(SRC_DIR)/AXI/*.v)

# Название исполняемого файла
SIM_EXE = sim_top_level_nn

all: $(SIM_EXE)

obj_dir/Vtop_level_nn.cpp: $(TB_SOURCE) $(SRC_FILES)
	$(VERILATOR) $(VERILATOR_FLAGS) $(VERILATOR_INCLUDE) $(TB_SOURCE)

obj_dir/Vtop_level_nn__ALL.a: obj_dir/Vtop_level_nn.cpp
	make -C obj_dir -f Vtop_level_nn.mk

$(SIM_EXE): obj_dir/Vtop_level_nn__ALL.a
	g++ -I$(VERILATOR_LIB_DIR) -I obj_dir $(VERILATOR_LIB_DIR)/verilated.cpp $(VERILATOR_LIB_DIR)/verilated_vcd_c.cpp obj_dir/Vtop_level_nn__ALL.a -o $(SIM_EXE) main.cpp

.PHONY: clean
clean:
	rm -rf obj_dir $(SIM_EXE)

