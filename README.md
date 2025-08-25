# Multiplicador Sequencial Shift-Add

Este repositório documenta a implementação de um multiplicador sequencial binário de 8 bits, baseado no algoritmo Shift-Add. O projeto inclui os módulos RTL, a máquina de estados (FSM) para controle e um testbench para validação funcional. A simulação é feita com Icarus Verilog e a análise de formas de onda com GTKWave.

## Visão Geral da Arquitetura

O algoritmo Shift-Add transforma a multiplicação em uma sequência de somas condicionais e deslocamentos. Os principais componentes e o fluxo de dados são:

- Registradores: três registradores de deslocamento de 8 bits para operandos e resultado parcial:
    - Acumulador (A): parte alta do produto final.
    - Multiplicando (B): valor a ser somado quando necessário.
    - Multiplicador (Q): parte baixa do produto final e fonte do bit de controle (Q[0]).

- Lógica de controle:
    - ULA de 8 bits para a soma condicional.
    - Contador que gerencia 8 iterações (uma por bit).
    - FSM que coordena LOAD → (ADD + SHIFT) × 8 → DONE.

No loop de iterações: se Q[0] == 1 então A <- A + B; em seguida realiza-se um deslocamento à direita de A e Q, com o carry da soma entrando no MSB de A e o bit LSB de A passando para o MSB de Q.

## Módulos do Projeto

- `rtl/shift_register.sv` — registrador parametrizável com carga paralela, hold, shift left/right e sinais `ser_in`/`ser_out`.
- `rtl/counter.sv` — contador síncrono parametrizável com `load`, `en`, `up_down`, `data_in`, `data_out` e `end_flag` quando chega a zero.
- `rtl/ula_74181.sv` e `rtl/ula_8_bits.sv` — ULA reutilizada de tarefa anterior.
- `rtl/shift_add_multiplier.sv` — módulo top que integra ULA, registradores, contador e FSM.
- `tb/tb_shift_add_multiplier.sv` — testbench com vetores de teste e geração de VCD.

## Fluxo de Simulação

Use o Icarus Verilog para compilar e simular. Exemplos de comandos:

```bash
iverilog -g2012 -o sim/shift_add_multiplier.vvp \
        rtl/ula_74181.sv rtl/ula_8_bits.sv rtl/shift_register.sv rtl/counter.sv rtl/shift_add_multiplier.sv \
        tb/tb_shift_add_multiplier.sv

vvp sim/shift_add_multiplier.vvp
```

O testbench imprime estados da FSM e valores dos registradores por ciclo. O arquivo `sim/shift_add_multiplier.vcd` será gerado para análise de formas de onda no GTKWave.