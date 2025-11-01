#!/bin/bash

ghdl -a ./Packages/tipos_elevadores.vhd
ghdl -a ./Controlador/display_andar/display_andar.vhd
ghdl -a ./Controlador/keyboard/keyboard.vhd
ghdl -a ./Controlador/porta/porta.vhd
ghdl -a ./Controlador/somador_andar/somador_andar.vhd
ghdl -a ./Controlador/controlador/controlador.vhd
ghdl -a ./Supervisor/supervisor_unico.vhd
ghdl -a ./Supervisor/supervisor_global.vhd
ghdl -a ./top_level.vhd
ghdl -a ./tb_top_level.vhd
ghdl -e tb_Top_Level
ghdl -r tb_Top_Level --wave=simulacao.ghw --stop-time=300us
