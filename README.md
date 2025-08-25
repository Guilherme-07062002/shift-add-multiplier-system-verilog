# Multiplicador Shift-Add

Este repositório contém a implementação em SystemVerilog de um multiplicador sequencial baseado no algoritmo Shift-Add, juntamente com testbench e scripts para simulação com Icarus Verilog e visualização com GTKWave.

Arquivos principais:
- `rtl/shift_register.sv`
- `rtl/counter.sv`
- `rtl/shift_add_multiplier.sv`
- `rtl/ula_74181.sv`
- `rtl/ula_8_bits.sv`
- `tb/tb_shift_add_multiplier.sv`

Requisitos:
- Icarus Verilog (`iverilog`)
- GTKWave (opcional, para abrir arquivos VCD)

Passo-a-passo (Windows usando Git Bash, WSL ou macOS/Linux):

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

O testbench imprimirá informações no terminal e gerará o arquivo VCD: `sim/shift_add_multiplier.vcd`.

1) Visualizar formas-de-onda:

```bash
gtkwave sim/shift_add_multiplier.vcd
```

