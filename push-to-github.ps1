# 🚀 One-Click GitHub Push for WeamApp
# Just run this script and follow the prompts

Write-Host "
╔════════════════════════════════════════╗
║  وئام Weam - Push to GitHub           ║
╚════════════════════════════════════════╝
" -ForegroundColor Cyan

# Step 1: Get token
Write-Host "Step 1: Go to GitHub and create a token" -ForegroundColor Green
Write-Host "URL: https://github.com/settings/tokens/new?scopes=repo,workflow" -ForegroundColor Yellow
Write-Host ""

$token = Read-Host "📝 Paste your Personal Access Token (starts with ghp_)"

if ($token -eq "" -or !$token.StartsWith("ghp_")) {
    Write-Host "❌ Invalid token format!" -ForegroundColor Red
    exit 1
}

# Step 2: Create repo via GitHub API
Write-Host "`nStep 2: Creating repository on GitHub..." -ForegroundColor Green

$headers = @{
    "Authorization" = "Bearer $token"
    "Accept" = "application/vnd.github+json"
}

$body = @{
    name = "WeamApp"
    description = "وئام — Weam | Smart Family Counselor iOS & Android App"
    public = $true
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "https://api.github.com/user/repos" `
        -Method POST `
        -Headers $headers `
        -Body $body `
        -ErrorAction Stop

    Write-Host "✅ Repository created: $($response.html_url)" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Repository might already exist (that's okay!)" -ForegroundColor Yellow
}

# Step 3: Configure git and push
Write-Host "`nStep 3: Pushing code to GitHub..." -ForegroundColor Green

cd "C:\Users\myd-b\Downloads\WeamApp"

git config --global user.credential.helper store
git remote remove origin 2>$null
git remote add origin "https://moayad:$token@github.com/moayad/WeamApp.git"

try {
    $output = git push -u origin main 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Code pushed successfully!" -ForegroundColor Green
        Write-Host "`n📱 Your repository: https://github.com/moayad/WeamApp" -ForegroundColor Cyan
        Write-Host "⏳ Next: I'll set up Codemagic, App Store, and Google Play`n" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Push output:" -ForegroundColor Yellow
        Write-Host $output
    }
} catch {
    Write-Host "❌ Error during push: $_" -ForegroundColor Red
}

Write-Host "`n✨ Done! Let me know when this completes.`n" -ForegroundColor Green
