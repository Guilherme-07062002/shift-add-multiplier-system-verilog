@echo off
REM Script de construção para Windows para compilar e executar os testbenches

REM Obtém o caminho absoluto do diretório do projeto
pushd %~dp0\..
set PROJECT_DIR=%CD%
popd

REM Define diretórios usando caminhos absolutos
set RTL_DIR=%PROJECT_DIR%\rtl
set TB_DIR=%PROJECT_DIR%\tb
set SIM_DIR=%PROJECT_DIR%\sim

REM Cria diretório de saída se não existir
if not exist "%SIM_DIR%" mkdir "%SIM_DIR%"

REM Função para compilar e executar um testbench
:compile_and_run
    echo === Compilando %~1 ===
    iverilog -g2012 -o "%SIM_DIR%\%~1.vvp" %~2 %~3 %~4
    if %ERRORLEVEL% EQU 0 (
        echo === Executando %~1 ===
        REM Executa a partir de tb/ para que $dumpfile("../sim/...\") gere em sim/
        pushd "%TB_DIR%"
        vvp "..\sim\%~1.vvp"
        popd
    ) else (
        echo Erro na compilação de %~1 ^(código: %ERRORLEVEL%^)
    )
    echo.
    goto :eof

:main_menu
cls
echo ===== MENU DE TESTES ULA =====
echo 1. ULA de 4 bits (74181)
echo 2. ULA de 8 bits
echo 3. Visualizar ondas ^(GTKWave^)
echo 4. Sair
echo =============================
set /p main_option=Escolha uma opcao: 

if "%main_option%"=="1" goto menu_ula_4bits
if "%main_option%"=="2" goto menu_ula_8bits
if "%main_option%"=="3" goto menu_gtkwave
if "%main_option%"=="4" goto exit
echo Opcao invalida! Pressione qualquer tecla para continuar...
pause > nul
goto main_menu

:menu_ula_4bits
cls
echo ===== TESTES PARA ULA DE 4 BITS (74181) =====
echo 1. Executar Testbench Completo
echo 2. Voltar
echo =========================================
set /p sub_option=Escolha uma opcao: 

if "%sub_option%"=="1" (
    call :compile_and_run "ula_74181" "%RTL_DIR%\ula_74181.sv" "%TB_DIR%\tb_ula_74181.sv"
    pause
    goto menu_ula_4bits
)
if "%sub_option%"=="2" goto main_menu
echo Opcao invalida! Pressione qualquer tecla para continuar...
pause > nul
goto menu_ula_4bits

:menu_ula_8bits
cls
echo ===== TESTES PARA ULA DE 8 BITS =====
echo 1. Executar Testbench Completo
echo 2. Voltar
echo =================================
set /p sub_option=Escolha uma opcao: 

if "%sub_option%"=="1" (
    call :compile_and_run "ula_8_bits" "%RTL_DIR%\ula_74181.sv" "%RTL_DIR%\ula_8_bits.sv" "%TB_DIR%\tb_ula_8_bits.sv"
    pause
    goto menu_ula_8bits
)
if "%sub_option%"=="2" goto main_menu
echo Opcao invalida! Pressione qualquer tecla para continuar...
pause > nul
goto menu_ula_8bits

:exit
echo Saindo do programa...
exit /b 0

REM Inicia o programa no menu principal
goto main_menu

:menu_gtkwave
cls
echo ===== VISUALIZAR ONDAS ^(GTKWave^) =====
echo 1. 74181 ^(ula_74181.vcd^)
echo 2. ULA 8 bits ^(ula_8_bits.vcd^)
echo 3. Voltar
echo ======================================
set /p gw_option=Escolha uma opcao: 

if "%gw_option%"=="1" call :open_vcd "ula_74181.vcd" & pause & goto menu_gtkwave
if "%gw_option%"=="2" call :open_vcd "ula_8_bits.vcd" & pause & goto menu_gtkwave
if "%gw_option%"=="3" goto main_menu
echo Opcao invalida! Pressione qualquer tecla para continuar...
pause > nul
goto menu_gtkwave

:open_vcd
set VCD_FILE=%SIM_DIR%\%~1
if exist "%VCD_FILE%" (
    where gtkwave >nul 2>&1
    if %ERRORLEVEL% NEQ 0 (
        echo GTKWave nao encontrado no PATH. Instale o GTKWave ou adicione-o ao PATH.
        echo Baixe em: http://gtkwave.sourceforge.net/
        goto :eof
    )
    echo Abrindo %VCD_FILE% no GTKWave...
    start "GTKWave" gtkwave "%VCD_FILE%"
    goto :eof
) else (
    echo Arquivo nao encontrado: %VCD_FILE%
    echo Gerando automaticamente o VCD correspondente...
    REM Mapear o arquivo solicitado para o teste correto
    if /I "%~1"=="ula_74181.vcd" (
        call :compile_and_run "ula_74181" "%RTL_DIR%\ula_74181.sv" "%TB_DIR%\tb_ula_74181.sv"
    ) else if /I "%~1"=="ula_8_bits.vcd" (
        call :compile_and_run "ula_8_bits" "%RTL_DIR%\ula_74181.sv" "%RTL_DIR%\ula_8_bits.sv" "%TB_DIR%\tb_ula_8_bits.sv"
    ) else (
        echo Nao foi possivel identificar o teste para %~1
        goto :eof
    )
    if exist "%VCD_FILE%" (
        echo Abrindo %VCD_FILE% no GTKWave...
        start "GTKWave" gtkwave "%VCD_FILE%"
    ) else (
        echo Falha ao gerar o VCD: %VCD_FILE%
    )
    goto :eof
)
