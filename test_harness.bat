@echo off
setlocal EnableExtensions

REM =====================================================================
REM  test_harness.bat
REM  Harness de validacion para:
REM    - proyecto_delegado  (Flutter)  -> flutter analyze
REM    - backend_delegado   (FastAPI)  -> py_compile de main.py
REM
REM  Uso:
REM    test_harness.bat
REM
REM  Modos:
REM    test_harness.bat                 -> los lints "info" NO son fatales
REM                                        (solo fallan errores y warnings)
REM    set HARNESS_STRICT=1 ^&^& test_harness.bat
REM                                     -> modo estricto: cualquier aviso
REM                                        (incluidos los "info") falla
REM
REM  Codigos de salida:
REM    0 = todo limpio (sintaxis Python OK y flutter analyze sin problemas)
REM    1 = se detectaron errores de sintaxis y/o de analisis
REM    2 = falta una herramienta o una carpeta del proyecto
REM
REM  El script detecta automaticamente las carpetas, tanto si se ejecuta
REM  desde la raiz que contiene ambos proyectos como si se ejecuta desde
REM  dentro de proyecto_delegado.
REM =====================================================================

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

echo.
echo ======================================================================
echo   HARNESS DE VALIDACION  -  Delegado PH
echo ======================================================================

REM ---------- 1) Localizar carpeta Flutter ----------
set "FLUTTER_DIR="
if exist "%SCRIPT_DIR%\pubspec.yaml" (
    set "FLUTTER_DIR=%SCRIPT_DIR%"
) else if exist "%SCRIPT_DIR%\proyecto_delegado\pubspec.yaml" (
    set "FLUTTER_DIR=%SCRIPT_DIR%\proyecto_delegado"
)

REM ---------- 2) Localizar carpeta Backend ----------
set "BACKEND_DIR="
if exist "%SCRIPT_DIR%\..\backend_delegado\main.py" (
    set "BACKEND_DIR=%SCRIPT_DIR%\..\backend_delegado"
) else if exist "%SCRIPT_DIR%\backend_delegado\main.py" (
    set "BACKEND_DIR=%SCRIPT_DIR%\backend_delegado"
)

if not defined FLUTTER_DIR (
    echo [ERROR] No se encontro el proyecto Flutter ^(pubspec.yaml^).
    echo         Coloca test_harness.bat junto a "proyecto_delegado" o dentro de el.
    endlocal & exit /b 2
)

if not defined BACKEND_DIR (
    echo [ERROR] No se encontro backend_delegado\main.py.
    echo         Coloca test_harness.bat junto a "backend_delegado".
    endlocal & exit /b 2
)

REM Normalizar rutas absolutas
for %%I in ("%FLUTTER_DIR%") do set "FLUTTER_DIR=%%~fI"
for %%I in ("%BACKEND_DIR%") do set "BACKEND_DIR=%%~fI"

echo   Flutter : %FLUTTER_DIR%
echo   Backend : %BACKEND_DIR%
echo.

REM ---------- 3) Verificar Python ----------
set "PY_CMD="
where python >nul 2>&1
if not errorlevel 1 set "PY_CMD=python"
if not defined PY_CMD (
    where py >nul 2>&1
    if not errorlevel 1 set "PY_CMD=py -3"
)
if not defined PY_CMD (
    echo [ERROR] No se encontro Python en el PATH.
    endlocal & exit /b 2
)

REM ---------- 4) Verificar Flutter ----------
set "FLUTTER_CMD="
where flutter >nul 2>&1
if not errorlevel 1 set "FLUTTER_CMD=flutter"
if not defined FLUTTER_CMD (
    echo [ERROR] No se encontro "flutter" en el PATH.
    endlocal & exit /b 2
)

REM =====================================================================
REM  PASO 1/2  -  Sintaxis Python (py_compile)
REM =====================================================================
echo ----------------------------------------------------------------------
echo   [1/2] Backend FastAPI: verificando sintaxis con py_compile...
echo ----------------------------------------------------------------------
pushd "%BACKEND_DIR%"
%PY_CMD% -m py_compile main.py
set "PY_EXIT=%ERRORLEVEL%"
popd

if not "%PY_EXIT%"=="0" (
    echo.
    echo [FALLO] Errores de sintaxis Python en backend_delegado\main.py
    endlocal & exit /b 1
)
echo [OK] Sintaxis de main.py correcta.
echo.

REM =====================================================================
REM  PASO 2/2  -  Analisis estatico Flutter (flutter analyze)
REM =====================================================================
echo ----------------------------------------------------------------------
echo   [2/2] Frontend Flutter: ejecutando "flutter analyze"...
echo ----------------------------------------------------------------------
set "ANALYZE_FLAGS=--no-fatal-infos"
if /I "%HARNESS_STRICT%"=="1" set "ANALYZE_FLAGS="

pushd "%FLUTTER_DIR%"
call %FLUTTER_CMD% analyze %ANALYZE_FLAGS%
set "ANALYZE_EXIT=%ERRORLEVEL%"
popd

if not "%ANALYZE_EXIT%"=="0" (
    echo.
    echo [FALLO] "flutter analyze" reporto problemas ^(exit %ANALYZE_EXIT%^).
    if not "%HARNESS_STRICT%"=="1" echo         Nota: los avisos "info" no son fatales; usa HARNESS_STRICT=1 para exigir cero avisos.
    endlocal & exit /b 1
)
echo [OK] flutter analyze sin errores ni warnings.
echo.

REM =====================================================================
REM  RESULTADO FINAL
REM =====================================================================
echo ======================================================================
echo   [OK] TODO LIMPIO: sintaxis backend + analisis Flutter correctos.
echo ======================================================================
endlocal & exit /b 0
