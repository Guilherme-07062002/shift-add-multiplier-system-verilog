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

4) Visualizar formas-de-onda (opcional):

```bash
gtkwave sim/shift_add_multiplier.vcd
```

Observações importantes:
- A porta de saída do `counter` foi renomeada de `end_count` para `end_flag` (evita palavras reservadas) para ficar clara e consistente.
- Se estiver usando o Prompt de Comando do Windows (cmd.exe), utilize o script `run_windows.bat` (fornecido) para compilar e executar automaticamente.
- Se o VCD não for gerado, verifique o caminho do `$dumpfile` no testbench: ele aponta para `../sim/shift_add_multiplier.vcd` quando a simulação é executada a partir de `tb/`.

Ajuda / problemas comuns:
- Se `iverilog` não estiver instalado, instale-o via pacote do seu sistema (ex: apt, pacman, choco) ou baixe em: http://iverilog.icarus.com/
- Se `gtkwave` não estiver disponível, instale-o para analisar o VCD.

Alterações recentes:
- Renomeada a saída do `counter` de `end_count` para `end`.

---

Se quiser, posso também gerar um relatório de cobertura de testes ou adicionar asserts no testbench para falhas automáticas.
