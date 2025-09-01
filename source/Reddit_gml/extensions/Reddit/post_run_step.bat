@echo off
setlocal
set "SCRIPT_DIR=%~dp0"

rem ---- sanity: need Node
where node >nul 2>&1 || (
  echo [ERROR] Node.js is required but not found in PATH.
  exit /b 1
)

rem Pass through your existing variables
node "%SCRIPT_DIR%devvit_tools.mjs"

set "EC=%ERRORLEVEL%"
exit /b 1



set Utils="%~dp0scriptUtils.bat"
set ExtensionPath="%~dp0"

:: ######################################################################################
:: Script Logic

:: Always init the script
call %Utils% scriptInit

:: Version locks
call %Utils% optionGetValue "versionStable" RUNTIME_VERSION_STABLE
call %Utils% optionGetValue "versionBeta" RUNTIME_VERSION_BETA
call %Utils% optionGetValue "versionDev" RUNTIME_VERSION_DEV
call %Utils% optionGetValue "versionLTS" RUNTIME_VERSION_LTS

:: SDK Hash
call %Utils% optionGetValue "processOnRun" PROCESS_ON_RUN
call %Utils% optionGetValue "outputPath" OUTPUT_PATH
call %Utils% optionGetValue "autoCreate" AUTO_CREATE
call %Utils% optionGetValue "autoPlaytest" AUTO_PLAYTEST
call %Utils% optionGetValue "projectCode" PROJECT_CODE
call %Utils% optionGetValue "projectName" PROJECT_NAME
call %Utils% optionGetValue "subredditName" SUBREDDIT_NAME

if "%PROCESS_ON_RUN%" == "False" (
    call %Utils% log "INFO" "Process on run is disabled, skipping process..."
    exit 0
)

if "%PROJECT_NAME%" == "" (
    call %Utils% logError "Extension option 'Project Name' is required and cannot be empty."
    exit 1
)

:: Ensure we are on the output path
pushd "%YYoutputFolder%"

:: Check if we have npm installed
call %Utils% logInformation "Detecting installed 'npm' version..."
call npm --version
if ERRORLEVEL 1 (
    call %Utils% logError "Failed to detect npm, please install npm in your system."
)

:: This will ensure the update of devvit (if it gets out-dated)
call npm install -g devvit
call %Utils% logInformation "Detected devvit tool init processing..."

:: Resolve the output directory
call %Utils% pathResolve "%YYprojectDir%" "%OUTPUT_PATH%" OUTPUT_DIR

:: Make sure we have a devvit project (check for 'main.tsx' to account for deleted projects)
if not exist "%OUTPUT_DIR%/%PROJECT_NAME%/devvit.json" (
    call %Utils% logInformation "No devvit project ('%PROJECT_NAME%') was found, in output folder: '%OUTPUT_DIR%'"
    if "%AUTO_CREATE%" == "True" (
        call %Utils% logInformation "Auto create is enabled, creating project..."
        pushd "%OUTPUT_DIR%"
        git clone "https://github.com/reddit/devvit-template-hello-world.git" "%PROJECT_NAME%"
        pushd "%OUTPUT_DIR%/%PROJECT_NAME%"
        rem four % per percent sign when calling through CALL:
        call %Utils% expandPlaceholder "." "<%%%% name %%%%>" "%PROJECT_NAME%" 0
        popd
        call %Utils% logInformation "Successfully created devvit project."
        popd
    ) else (
        call %Utils% logError "No devvit project was found, enable auto create or create manually (ie.: devvit new "%PROJECT_NAME%" --template web-view-post)."
    )
)

:: Deleting old & unused files
set "CLIENT_FOLDER=%OUTPUT_DIR%\%PROJECT_NAME%\src\client"
if exist "%CLIENT_FOLDER%\main.ts" (
    del /q "%CLIENT_FOLDER%\main.ts"
)

call %Utils% log "INFO" "Deleting previous build..."
del /q "%CLIENT_FOLDER%\public\"
del /q "%CLIENT_FOLDER%\index.html"
call %Utils% log "INFO" "Previous build deleted."

:: Copy files over
call %Utils% log "INFO" "Copying new build..."
xcopy /E /I /Y "html5game\*" "%CLIENT_FOLDER%\public\html5game\" >nul
copy  /Y "favicon.ico" "%CLIENT_FOLDER%\public\favicon.ico" >nul
copy  /Y "index.html" "%CLIENT_FOLDER%\index.html" >nul
call %Utils% log "INFO" "New build copied."

:: Patching index.html file
call %Utils% log "INFO" "Patching 'index.html' file..."
set "TARGET_HTML=%CLIENT_FOLDER%\index.html"

if not exist "%TARGET_HTML%" (
  call %Utils% logError "index.html not found at '%TARGET_HTML%'."
  exit /b 1
)

set "PS1=%TEMP%\patch_index_%RANDOM%%RANDOM%.ps1"

>"%PS1%"  echo $ErrorActionPreference='Stop'
>>"%PS1%" echo $p = Resolve-Path '%TARGET_HTML%'
>>"%PS1%" echo $html = Get-Content -Raw -Path $p

rem Skip if already patched (has a module script tag anywhere)
>>"%PS1%" echo if ($html -match '(?is)^<script[^^^>]*type\s*=\s*[''^"]module[''^"]') {
>>"%PS1%" echo ^  Write-Host ('Already patched: ' + $p)
>>"%PS1%" echo ^  exit
>>"%PS1%" echo }
rem Find classic loader: src="/?html5game/NAME.js?..."
>>"%PS1%" echo $pattern1 = '(?is)^<script[^^^>]*\bsrc\s*=\s*[''^"]\s*/?html5game/(?^<name^>[^^''"?\s<>/]+)\.js(?:\?[^''"]*)?[''^"][^^^>]*^>\s*^</script^>'
rem Remove inline window.onload = GameMaker_Init
>>"%PS1%" echo $pattern2 = '(?is)\s*^<script[^^^>]*^>\s*window\.onload\s*=\s*GameMaker_Init\s*;?\s*^</script^>'
>>"%PS1%" echo $m = [regex]::Match($html,$pattern1)
>>"%PS1%" echo if (-not $m.Success) { throw 'Could not find html5game/*.js ^<script^> tag in ' + $p }
>>"%PS1%" echo $game = $m.Groups['name'].Value
>>"%PS1%" echo $replacement = @'
>>"%PS1%" echo ^<script type="module"^>
>>"%PS1%" echo   const s = document.createElement('script');
>>"%PS1%" echo   s.src = '/html5game/$1.js';
>>"%PS1%" echo   s.onload = () =^> window.GameMaker_Init?.();
>>"%PS1%" echo   document.head.appendChild(s);
>>"%PS1%" echo ^</script^>
>>"%PS1%" echo '@
>>"%PS1%" echo Copy-Item -Path $p -Destination ($p.Path + '.bak') -Force
>>"%PS1%" echo $out = [regex]::Replace($html,$pattern1,$replacement)
>>"%PS1%" echo $out = [regex]::Replace($out,$pattern2,'')
>>"%PS1%" echo Set-Content -Path $p -Encoding UTF8 -Value $out
>>"%PS1%" echo Write-Host ('Patched ' + $p + ' (game file: ' + $game + '.js). Backup: ' + $p + '.bak')

powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
set "EC=%ERRORLEVEL%"
:: del /q "%PS1%" 2>nul
if not "%EC%"=="0" (
  call %Utils% logError "Failed to patch '%TARGET_HTML%'."
  exit /b 1
)
call %Utils% log "INFO" "index.html patched successfully."

popd

call %Utils% log "INFO" "Checking dependencies..."
pushd "%OUTPUT_DIR%/%PROJECT_NAME%"
start /d "%OUTPUT_DIR%\%PROJECT_NAME%" /wait cmd /c "npm i"
if not "%ERRORLEVEL%"=="0" (
  call %Utils% logError "npm install failed (exit %ERRORLEVEL%)."
  exit /b 1
)
call %Utils% log "INFO" "Dependencies are ready."

:: Upload and init playtest (if enabled)
if "%AUTO_PLAYTEST%" == "True" (

    call %Utils% log "INFO" "auto playtest is enabled, uploading project..."
    start /d "%OUTPUT_DIR%\%PROJECT_NAME%" /wait cmd /k "npm run dev"
    if ERRORLEVEL 1 (
        call %Utils% logError "devvit failed to initialize playtest (unknown error)."
        exit 1
    )
    
    echo "###########################################################################"
    call %Utils% log "INFO" "Project built successfully and devvit project was create..."
    echo "Output Folder: '%OUTPUT_DIR%\%PROJECT_NAME%'"
    echo "Application is ready for playtest, refresh your subreddit page."
    echo "###########################################################################"
    exit 255

) else (
    echo "###########################################################################"
    call %Utils% log "INFO" "Project built successfully and devvit project was create..."
    echo "Output Folder: '%OUTPUT_DIR%\%PROJECT_NAME%'"
    echo "You can playtest it by going to the output folder and using the commands:"
    echo npm run dev
    echo "###########################################################################"
    exit 255
)

popd

exit %ERRORLEVEL%
