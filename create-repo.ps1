# Quick script to create WeamApp repository
# 1. Go to https://github.com/settings/tokens
# 2. Click "Generate new token (classic)"
# 3. Check: repo (all), workflow
# 4. Copy the token and paste it below

Write-Host "Opening GitHub token creation page..."
Start-Process "https://github.com/settings/tokens/new?scopes=repo,workflow&description=WeamApp-Release"

Read-Host "Press Enter once you've copied your token"
$token = Read-Host "Paste your Personal Access Token"

$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

$body = @{
    "name" = "WeamApp"
    "description" = "وئام — Weam | Smart Family Counselor iOS & Android App"
    "public" = $true
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "https://api.github.com/user/repos" -Method POST -Headers $headers -Body $body

Write-Host "Repository created: $($response.html_url)"
Write-Host "Pushing code in 3 seconds..."
Start-Sleep -Seconds 3

cd "C:\Users\myd-b\Downloads\WeamApp"
git remote remove origin 2>$null
git remote add origin "https://$token@github.com/moayad/WeamApp.git"
git push -u origin main

Write-Host "✅ Code pushed successfully!"
Write-Host "📱 Repository: https://github.com/moayad/WeamApp"
