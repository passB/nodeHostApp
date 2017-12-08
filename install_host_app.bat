@ECHO OFF
SETLOCAL

SET "APP_NAME=passb"
SET "INSTALL_TYPE=source"

SET "TARGET_DIR=%APPDATA%\%APP_NAME%"
SET "HOST_MANIFEST=%APP_NAME%.json"
IF "%INSTALL_TYPE%"=="source" (
    SET "HOST_SCRIPT=index.js"
) else (
    SET "HOST_SCRIPT=index.exe"
)

SET "HOST_BATCH=%APP_NAME%.bat"

SET "HOST_MANIFEST_FULL=%TARGET_DIR%\%HOST_MANIFEST%"
SET "HOST_SCRIPT_FULL=%TARGET_DIR%\%HOST_SCRIPT%"
SET "HOST_BATCH_FULL=%TARGET_DIR%\%HOST_BATCH%"

SET "USE_LOCAL_FILES="
SET "TARGET_REG="

REM check prerequisites: is pass installed & in path?
pass version >NUL 2> NUL || sh -c "pass version" >NUL 2> NUL || (
    ECHO "pass not found in PATH. Please execute this command in a shell where pass is in PATH"
    EXIT /B
)

:loop
IF NOT "%1"=="" (
     IF "%1"=="--help" (
        GOTO :help
    ) ELSE IF "%1"=="firefox" (
        SET "TARGET_REG=HKCU\SOFTWARE\Mozilla\NativeMessagingHosts\%APP_NAME%"
        SHIFT
    ) ELSE IF "%1"=="chrome"  (
        SET "TARGET_REG=HKCU\Software\Google\Chrome\NativeMessagingHosts\%APP_NAME%"
        SHIFT
    ) ELSE IF "%1"=="chromium"  (
        ECHO Chromium registry key location for Native Messaging Hosts is undocumented. Assuming key for Chrome. Please provide feedback if this worked: https://github.com/passB/nodeHostApp/issues/6
        SET "TARGET_REG=HKCU\Software\Google\Chrome\NativeMessagingHosts\%APP_NAME%"
        SHIFT
    ) ELSE IF "%1"=="opera"  (
        ECHO Opera registry key location for Native Messaging Hosts is undocumented. Assuming key for Chrome. Please provide feedback if this worked: https://github.com/passB/nodeHostApp/issues/6
        SET "TARGET_REG=HKCU\Software\Google\Chrome\NativeMessagingHosts\%APP_NAME%"
        SHIFT
    ) ELSE IF "%1"=="vivaldi"  (
        ECHO Vivaldi registry key location for Native Messaging Hosts is undocumented. Assuming key for Chrome. Please provide feedback if this worked: https://github.com/passB/nodeHostApp/issues/6
        SET "TARGET_REG=HKCU\Software\Google\Chrome\NativeMessagingHosts\%APP_NAME%"
        SHIFT
    ) ELSE (
        SHIFT
    )
    GOTO :loop
)

IF "%TARGET_REG%"=="" (
    GOTO :help
)

IF EXIST "%TARGET_DIR%" (
    dir /AD "%TARGET_DIR%" > nul || (
        ECHO "%TARGET_DIR%" is not a directory
        EXIT /B
    )
) ELSE (
    MKDIR "%TARGET_DIR%" 2> nul
)

IF NOT EXIST "%~dp0%HOST_MANIFEST%" (
    ECHO local file "%~dp0%HOST_MANIFEST%" not found
    EXIT /B
)
IF NOT EXIST "%~dp0%HOST_SCRIPT%" (
    ECHO local file "%~dp0%HOST_SCRIPT%" not found
    EXIT /B
)
COPY /Y "%~dp0%HOST_MANIFEST%" "%HOST_MANIFEST_FULL%"
COPY /Y "%~dp0%HOST_SCRIPT%" "%HOST_SCRIPT_FULL%"
IF "%INSTALL_TYPE%"=="source" (
    COPY /Y "%~dp0package.json" "%TARGET_DIR%"
    COPY /Y "%~dp0yarn.lock" "%TARGET_DIR%"
    CMD /C "cd ""%TARGET_DIR%"" & yarn install || npm install" || (
        echo 'Tried "yarn install" and "npm install", but none of them worked. Do you have those tools installed?'
        EXIT /B
    )
)

powershell -Command "(Get-Content '%HOST_MANIFEST_FULL%') -replace 'PLACEHOLDER', '%HOST_BATCH_FULL:\=/%' | Set-Content '%HOST_MANIFEST_FULL%'"

(
    ECHO @ECHO OFF
    ECHO SET "PATH=%PATH%"
    ECHO SET "HOME=%HOME%"
    ECHO SET "GNUPGHOME=%GNUPGHOME%"
    ECHO SET "PASSWORD_STORE_DIR=%PASSWORD_STORE_DIR%"
    ECHO SET "PASSWORD_STORE_GPG_OPTS=%PASSWORD_STORE_GPG_OPTS%"
    ECHO SET "PASSWORD_STORE_ENABLE_EXTENSIONS=%PASSWORD_STORE_ENABLE_EXTENSIONS%"
    IF "%INSTALL_TYPE%"=="source" (
        ECHO node "%HOST_SCRIPT_FULL%"  %%*
    ) ELSE (
        ECHO "%HOST_SCRIPT_FULL%"  %%*
    )
)>"%HOST_BATCH_FULL%"

REG ADD "%TARGET_REG%" /ve /d "%HOST_MANIFEST_FULL%" /f || (
    ECHO Adding key to registry failed - maybe you need Administrator rights for this. Please run
    ECHO REG ADD "%TARGET_REG%" /ve /d "%HOST_MANIFEST_FULL%" /f
    ECHO manually in an administrative shell.
)
EXIT /B

:help
ECHO Usage: %0 [chrome^|chromium^|firefox^|opera^|vivaldi]
ECHO.
ECHO Options:
ECHO   --help     Show this message"
EXIT /B
