# Multiplicador Sequencial Shift-Add (8×8)

Projeto em SystemVerilog de um multiplicador sequencial 8 bits × 8 bits usando o método Shift-Add. Contém datapath (registradores, contador, ULA), FSM e testbench. Tudo roda com Icarus Verilog; ondas no GTKWave.

## Objetivo
Multiplicar dois números de 8 bits em tempo fixo (8 iterações), só com soma condicional e deslocamentos.

## Estrutura
```
rtl/            Módulos RTL (registradores, contador, ULA, multiplicador)
tb/             Testbench
sim/            Saída de simulação (VVP, VCD)
build/          Script de automação (menu)
doc/            (espaço para relatório/diagramas)
```

## Módulos
`shift_register.sv` registrador universal (hold, shift L/R, carga paralela, ser_in/ser_out).

`counter.sv` contador com load+enable (modo decremento aqui). Saturação em zero. Sinais: data_out, end_flag.

`ula_74181.sv` / `ula_8_bits.sv` ULA em dois estágios (só soma usada).

`shift_add_multiplier.sv` integra A, B, Q, contador e ULA com FSM.

`tb_shift_add_multiplier.sv` vetores de teste e geração de VCD.

## FSM
LOAD  carrega operandos e zera A, contador=8.
ADD   soma condicional (Q0?B) em A.
SHIFT desloca (carry,A,Q) para direita; conta -1.
DONE  finaliza e trava saída.

Ciclos: LOAD + 8×(ADD+SHIFT) + DONE → 17 linhas no log.

## Algoritmo
1. A=0; B e Q carregados.
2. Repetir 8 vezes:
    - Se Q[0]=1 soma B em A.
    - Desloca (carry,A,Q) >> 1.
3. Produto = {A,Q}.

## Testbench
Casos: 3×5, 10×12, 127×201, 255×255, 0×123, 13×11. Mostra ciclo, estado, contador, A, B, Q, soma, carry e PASS/FAIL. Gera `sim/shift_add_multiplier.vcd`.

## Execução (menu)
No Bash:
```bash
bash build/build.sh
```
Menu principal traz opções para ULAs, multiplicador e abrir ondas.

Na opção 3 → 1 roda o testbench do multiplicador. VCD em `sim/shift_add_multiplier.vcd`.

## Execução Direta
```bash
iverilog -g2012 -o sim/shift_add_multiplier.vvp \
    rtl/ula_74181.sv rtl/ula_8_bits.sv rtl/shift_register.sv rtl/counter.sv rtl/shift_add_multiplier.sv \
    tb/tb_shift_add_multiplier.sv
vvp sim/shift_add_multiplier.vvp
```
Abrir ondas (se GTKWave instalado):
```bash
gtkwave sim/shift_add_multiplier.vcd &
```
