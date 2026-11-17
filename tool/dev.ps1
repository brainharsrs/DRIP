# Abre o DRIP já com dados e contas, usando o Firebase local (emuladores).
#
# Uso, dentro da pasta drip:
#   .\tool\dev.ps1                  -> escolhe o aparelho (como o flutter run)
#   .\tool\dev.ps1 -d chrome        -> qualquer argumento vai para o flutter run
#   .\tool\dev.ps1 -Celular -d <id> -> celular físico na mesma rede Wi-Fi
#   .\tool\dev.ps1 -Real            -> Firebase real, com firebase.local.json
#
# O que ele faz:
#   1. liga os emuladores do Firebase numa janela separada (se ainda não
#      estiverem ligados), recuperando os dados da última vez;
#   2. grava marcas, drops e contas de teste (tool/seed_emulator.dart);
#   3. roda o flutter run apontando para os emuladores.
#
# Para desligar os emuladores, aperte Ctrl+C na janela deles: o que você fez
# no app fica salvo em .emulator-data e volta na próxima vez.

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root

# Argumentos: -Celular é deste script, o resto vai para o flutter run.
$celular = $false
$real = $false
$flutterArgs = @()
foreach ($a in $args) {
  if ("$a" -ieq '-Celular' -or "$a" -ieq '--celular') { $celular = $true }
  elseif ("$a" -ieq '-Real' -or "$a" -ieq '--real') { $real = $true }
  else { $flutterArgs += "$a" }
}

function Find-Tool($name, $fallback) {
  $cmd = Get-Command $name -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  if (Test-Path $fallback) { return $fallback }
  throw "Não encontrei '$name'. Instale ou ajuste o caminho em tool/dev.ps1."
}

$flutter = Find-Tool 'flutter' 'C:\src\flutter\bin\flutter.bat'
$dart = Join-Path (Split-Path $flutter -Parent) 'dart.bat'

# Firebase real: só precisa da configuração local (que não vai para o Git).
if ($real) {
  if (-not (Test-Path 'firebase.local.json')) {
    throw 'Falta o firebase.local.json. Copie o firebase.local.example.json e preencha com as chaves do seu projeto.'
  }
  & $flutter run --dart-define-from-file=firebase.local.json @flutterArgs
  exit $LASTEXITCODE
}

$firebase = Find-Tool 'firebase' "$env:APPDATA\npm\firebase.cmd"

# Os emuladores precisam de Java. Se não houver no PATH, usa o que vem com o
# Android Studio.
if (-not (Get-Command java -ErrorAction SilentlyContinue)) {
  $jbr = 'C:\Program Files\Android\Android Studio\jbr'
  if (-not (Test-Path "$jbr\bin\java.exe")) {
    throw 'Os emuladores do Firebase precisam de Java 21 ou mais novo. Instale o Android Studio ou um JDK.'
  }
  $env:JAVA_HOME = $jbr
  $env:Path = "$jbr\bin;$env:Path"
}

function Test-Port($port) {
  $client = New-Object System.Net.Sockets.TcpClient
  try { return $client.ConnectAsync('127.0.0.1', $port).Wait(400) }
  catch { return $false }
  finally { $client.Dispose() }
}

if ((Test-Port 8080) -and (Test-Port 9099)) {
  Write-Host 'Emuladores do Firebase já estão ligados.'
} else {
  Write-Host 'Ligando os emuladores do Firebase numa nova janela...'
  $emu = "emulators:start --only auth,firestore --project demo-drip --export-on-exit .emulator-data"
  if (Test-Path '.emulator-data') { $emu += ' --import .emulator-data' }
  Start-Process -FilePath 'cmd.exe' -WorkingDirectory $root `
    -ArgumentList '/k', "title Firebase (DRIP) && `"$firebase`" $emu"
}

# Marcas, drops e contas.
& $dart run tool/seed_emulator.dart
if ($LASTEXITCODE -ne 0) { throw 'Não deu para preencher os emuladores.' }

$defines = @('--dart-define=DRIP_EMULATOR=true')
if ($celular) {
  # IP deste computador na rede local, para o celular alcançar os emuladores.
  $ip = Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object { $_.PrefixOrigin -in 'Dhcp', 'Manual' -and $_.InterfaceAlias -notmatch 'vEthernet|Loopback|VirtualBox|VMware' } |
    Select-Object -First 1 -ExpandProperty IPAddress
  if (-not $ip) { throw 'Não achei o IP deste computador na rede Wi-Fi.' }
  Write-Host "Celular vai usar os emuladores em $ip (mesma rede Wi-Fi)."
  $defines += "--dart-define=DRIP_EMULATOR_HOST=$ip"
}

& $flutter run @defines @flutterArgs
