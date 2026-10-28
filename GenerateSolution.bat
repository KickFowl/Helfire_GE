@echo off
rem ------------------------------------------------------------------
rem Generates a Visual Studio solution (build\vs\Helfire_GE.sln) from
rem CMakeLists.txt and opens it. No admin rights or PATH setup needed:
rem it uses the CMake that ships with Visual Studio.
rem
rem Extra arguments are passed to CMake, e.g.
rem   GenerateSolution.bat -G "Visual Studio 17 2022"
rem ------------------------------------------------------------------
setlocal
cd /d "%~dp0"

set "CMAKE_EXE="

rem 1) CMake bundled with the newest Visual Studio install
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if exist "%VSWHERE%" (
  for /f "usebackq delims=" %%i in (`"%VSWHERE%" -latest -products * -find "Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe"`) do set "CMAKE_EXE=%%i"
)

rem 2) Fall back to a CMake on PATH
if not defined CMAKE_EXE (
  where cmake >nul 2>nul && set "CMAKE_EXE=cmake"
)

if not defined CMAKE_EXE (
  echo Could not find CMake. In the Visual Studio Installer, add the
  echo "C++ CMake tools for Windows" component.
  pause
  exit /b 1
)

echo Using CMake: %CMAKE_EXE%
"%CMAKE_EXE%" -S . -B build\vs -A x64 %*
if errorlevel 1 (
  echo.
  echo CMake configure failed. See the messages above.
  pause
  exit /b 1
)

if exist "build\vs\Helfire_GE.sln" (
  start "" "build\vs\Helfire_GE.sln"
) else (
  echo Configure finished but build\vs\Helfire_GE.sln was not created.
  echo Pass the generator explicitly, e.g. -G "Visual Studio 18 2026"
  pause
  exit /b 1
)
