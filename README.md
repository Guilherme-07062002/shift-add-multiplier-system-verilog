# Multiplicador Shift-Add

Este repositório contém a implementação em SystemVerilog de um multiplicador sequencial baseado no algoritmo Shift-Add, juntamente com testbench e scripts para simulação com Icarus Verilog e visualização com GTKWave.

Arquivos principais:
- `rtl/shift_register.sv`
- `rtl/counter.sv`
- `rtl/shift_add_multiplier.sv`
- `rtl/ula_74181.sv`
- `rtl/ula_8_bits.sv`
- `tb/tb_shift_add_multiplier.sv`

## Arquitetura

O design segue estritamente o algoritmo Shift-Add:

1. Registradores de deslocamento (A, B, Q) de 8 bits.
	- `A`: acumulador (byte alto do produto ao final).
	- `B`: multiplicando (mantido, não sofre deslocamentos após a carga inicial).
	- `Q`: multiplicador (byte baixo do produto ao final).
2. Encadeamento serial no deslocamento à direita: `A_ser_out -> Q_ser_in`.
3. Carry da soma entra no MSB de `A` em cada ciclo de shift.
4. Contador de 8 (decrementando) controla precisamente o número de iterações.
5. ULA de 8 bits realiza soma condicional: se `Q[0] == 1` soma `B`, caso contrário soma 0 (mantém `A`).
6. Máquina de estados finitos (FSM) simples e determinística:
	- `LOAD` : carga inicial (A=0, B=multiplicand, Q=multiplier, contador=8)
	- `ADD`  : soma condicional (A <- A + (Q0?B:0))
	- `SHIFT`: deslocamento simultâneo de A e Q para a direita, carry -> A.MSB, A_ser_out -> Q_ser_in, contador--
	- repete `ADD`/`SHIFT` 8 vezes
	- `DONE` : sinaliza término (`end_op=1`)

Resultado final: `result = {A_out, Q_out}` (A é a parte alta, Q a parte baixa do produto de 16 bits).

## Módulos Implementados

- `shift_register.sv`: registrador universal parametrizável com operações hold, shift left, shift right e carga paralela; expõe `ser_out` do bit deslocado e entrada `ser_in` para encadeamento.
- `counter.sv`: contador síncrono parametrizável com reset assíncrono, carga, enable, direção (up/down) e sinal `end_flag` quando chega a zero.
- `ula_74181.sv` / `ula_8_bits.sv`: ULA utilizada para as operações aritméticas (soma necessária pelo algoritmo).
- `shift_add_multiplier.sv`: integração de todos os blocos e FSM.
- `tb_shift_add_multiplier.sv`: testbench com múltiplos vetores (3x5, 10x12, 127x201, 255x255, 0x123, 13x11), geração de VCD e `display` de estados internos.

## Requisitos
- Icarus Verilog (`iverilog`)
- GTKWave (opcional, para abrir arquivos VCD)

## Passo-a-passo (Windows usando Git Bash, WSL ou macOS/Linux)

1) Abrir um terminal no diretório do projeto.

2) Compilar o design e o testbench:

```bash
iverilog -g2012 -o sim/shift_add_multiplier.vvp \
	rtl/ula_74181.sv rtl/ula_8_bits.sv rtl/shift_register.sv rtl/counter.sv rtl/shift_add_multiplier.sv \
	tb/tb_shift_add_multiplier.sv
```

3) Executar a simulação:

```bash
cd tb
vvp ../sim/shift_add_multiplier.vvp
```

Também é possível rodar o script `build.sh` (no Linux ou macOS) para compilar e executar todos os testes automaticamente. O script `build.bat` (no Windows) oferece funcionalidade semelhante.

O testbench imprimirá (por ciclo) estado da FSM, valor do contador e conteúdos de A, B, Q, além de gerar `sim/shift_add_multiplier.vcd`.

1) Visualizar formas-de-onda:

```bash
gtkwave sim/shift_add_multiplier.vcd
```