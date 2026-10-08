# Runs the four project checks: Rojo build, tests, linter, formatter.
$ErrorActionPreference = "Stop"
$env:PATH = "$HOME\.rokit\bin;$env:PATH"

$checks = @(
	@{ Name = "Rojo build"; Cmd = { rojo build -o build.rbxl } },
	@{ Name = "Tests (Lune)"; Cmd = { lune run tests/run } },
	@{ Name = "Linter (Selene)"; Cmd = { selene src tests } },
	@{ Name = "Formatter (StyLua)"; Cmd = { stylua --check src tests } }
)

$failed = 0
foreach ($check in $checks) {
	Write-Host "== $($check.Name)"
	& $check.Cmd
	if ($LASTEXITCODE -ne 0) {
		Write-Host "FAILED: $($check.Name)" -ForegroundColor Red
		$failed++
	} else {
		Write-Host "OK: $($check.Name)" -ForegroundColor Green
	}
}

if ($failed -gt 0) { exit 1 }
Write-Host "`nAll checks passed." -ForegroundColor Green
