$scriptPath = "C:\Users\diall\Documents\IonicProjects\Claude\RECHERCHER\DIVERS\POWER-SHELL\PAIN-Auto-Processor.ps1"

Write-Host "Verification de la syntaxe du script..." -ForegroundColor Yellow

try {
    $scriptContent = Get-Content $scriptPath -Raw -ErrorAction Stop
    $errors = $null
    $tokens = [System.Management.Automation.PSParser]::Tokenize($scriptContent, [ref]$errors)

    if ($errors.Count -eq 0) {
        Write-Host "SUCCES : Aucune erreur de syntaxe detectee !" -ForegroundColor Green
        Write-Host "Nombre de tokens : $($tokens.Count)" -ForegroundColor Cyan
        exit 0
    } else {
        Write-Host "ERREUR : $($errors.Count) erreur(s) de syntaxe detectee(s) :" -ForegroundColor Red
        foreach ($error in $errors) {
            Write-Host "  Ligne $($error.Token.StartLine) : $($error.Message)" -ForegroundColor Red
        }
        exit 1
    }
} catch {
    Write-Host "ERREUR : Impossible d'analyser le script" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
