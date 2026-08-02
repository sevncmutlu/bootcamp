@echo off
if /I not "%MAKI_ENV%"=="production" (
  echo ERROR: MAKI_ENV must be exactly production.
  exit /b 1
)
if "%MAKI_BACKEND_URL%"=="" goto :missing
if "%MAKI_OIDC_ISSUER%"=="" goto :missing
if "%MAKI_OIDC_CLIENT_ID%"=="" goto :missing
if "%MAKI_OIDC_AUDIENCE%"=="" goto :missing
if "%MAKI_OIDC_REDIRECT_URI%"=="" goto :missing
if "%MAKI_PRIVACY_URL%"=="" goto :missing
if "%MAKI_TERMS_URL%"=="" goto :missing
if "%MAKI_BILLING_PRODUCT_ID%"=="" goto :missing
if /I not "%MAKI_ENABLE_STORE_BILLING%"=="true" (
  echo ERROR: MAKI_ENABLE_STORE_BILLING must be true.
  exit /b 1
)
for %%U in ("%MAKI_BACKEND_URL%" "%MAKI_OIDC_ISSUER%" "%MAKI_PRIVACY_URL%" "%MAKI_TERMS_URL%") do (
  echo %%~U | findstr /b /c:"https://" >nul
  if errorlevel 1 (
    echo ERROR: API, OIDC issuer and legal URLs must use https://
    exit /b 1
  )
)
set "MAKI_DART_DEFINES=--dart-define=MAKI_ENV=production --dart-define=BACKEND_URL=%MAKI_BACKEND_URL% --dart-define=OIDC_ISSUER=%MAKI_OIDC_ISSUER% --dart-define=OIDC_CLIENT_ID=%MAKI_OIDC_CLIENT_ID% --dart-define=OIDC_AUDIENCE=%MAKI_OIDC_AUDIENCE% --dart-define=OIDC_REDIRECT_URI=%MAKI_OIDC_REDIRECT_URI% --dart-define=PRIVACY_URL=%MAKI_PRIVACY_URL% --dart-define=TERMS_URL=%MAKI_TERMS_URL% --dart-define=BILLING_PRODUCT_ID=%MAKI_BILLING_PRODUCT_ID% --dart-define=ENABLE_STORE_BILLING=true"
exit /b 0

:missing
echo ERROR: Production release environment is incomplete.
echo Required: MAKI_BACKEND_URL, MAKI_OIDC_ISSUER, MAKI_OIDC_CLIENT_ID,
echo MAKI_OIDC_AUDIENCE, MAKI_OIDC_REDIRECT_URI, MAKI_PRIVACY_URL,
echo MAKI_TERMS_URL, MAKI_BILLING_PRODUCT_ID, MAKI_ENABLE_STORE_BILLING=true.
exit /b 1
