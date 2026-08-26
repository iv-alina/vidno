@echo off
chcp 866 >nul
setlocal
cd /d "%~dp0"
title VIDNO - publikaciya

echo.
echo   VIDNO - публикация на GitHub Pages
echo   ----------------------------------
echo.

where git >nul 2>nul
if errorlevel 1 goto :net_git

if not exist ".gitignore" call :sozdat_gitignore

if exist ".git" goto :repo_gotov

echo   Первый запуск: подключаю папку к репозиторию...
git init >nul
git branch -M main >nul 2>nul
git remote add origin https://github.com/iv-alina/vidno.git >nul 2>nul
git fetch origin main
if errorlevel 1 goto :net_repo
git reset --soft origin/main >nul
echo   Готово, папка подключена.
echo.

:repo_gotov
git config user.name >nul 2>nul
if errorlevel 1 git config user.name "iv-alina"
git config user.email >nul 2>nul
if errorlevel 1 git config user.email "iv-alina@users.noreply.github.com"

if exist "sw.js" call :shtamp

git add -A
git rm --cached -r --quiet _to_delete >nul 2>nul
git rm --cached --quiet *.md >nul 2>nul

git diff --cached --quiet
if not errorlevel 1 goto :net_izmeneniy

for /f "tokens=1-2 delims=:.," %%a in ("%time%") do set NOW=%%a-%%b
git commit -m "VIDNO: obnovlenie %date% %NOW%" >nul
if errorlevel 1 goto :net_kommita

echo   Отправляю на GitHub...
git push -u origin main
if errorlevel 1 goto :net_otpravki

echo.
echo   Опубликовано. Через 1-2 минуты обновится:
echo   https://iv-alina.github.io/vidno/
echo.
echo   На телефоне приложение само предложит обновиться.
goto :konec

:net_izmeneniy
echo   Изменений нет - публиковать нечего.
goto :konec

:net_git
echo   [!] Git не найден.
echo       Установи с https://git-scm.com/download/win и запусти снова.
goto :konec

:net_repo
echo.
echo   [!] Не удалось получить репозиторий с GitHub.
echo       Проверь интернет и вход в GitHub, потом запусти снова.
goto :konec

:net_kommita
echo.
echo   [!] Git не смог сохранить изменения.
echo       Скопируй текст выше и покажи Клоду.
goto :konec

:net_otpravki
echo.
echo   [!] Не удалось отправить на GitHub.
echo       Чаще всего это вход: git должен открыть окно авторизации.
echo       Если окно не появилось, выполни один раз в командной строке:
echo       git config --global credential.helper manager
goto :konec

:shtamp
powershell -NoProfile -Command "$p = Join-Path $PWD 'sw.js'; $v = Get-Date -Format 'yyyyMMdd-HHmm'; $s = [IO.File]::ReadAllText($p); $s = $s -replace 'var BUILD = ''[^'']*'';', ('var BUILD = ''' + $v + ''';'); [IO.File]::WriteAllText($p, $s, (New-Object Text.UTF8Encoding($false))); Write-Host ('  versiya ' + $v)"
if errorlevel 1 echo   [!] Штамп версии не поставился - телефон может не заметить обновление.
exit /b

:sozdat_gitignore
> .gitignore echo _to_delete/
>> .gitignore echo *.md
>> .gitignore echo desktop.ini
>> .gitignore echo Thumbs.db
exit /b

:konec
echo.
pause
