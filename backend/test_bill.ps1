$headers = @{
    "Content-Type" = "application/json"
}

$body = @{
    cartItems = @(
        @{
            menuItem = @{
                id = "m5"
                name = "Jalebi"
                category = "Desserts"
                price = 0.1
                description = "Sweet crispy jalebi"
                icon = "🍥"
            }
            quantityInGrams = 500
        }
    )
    discount = 0
    paymentMethod = "cash"
    notes = "Test bill from script"
} | ConvertTo-Json -Depth 4

Write-Host "Creating bill..."
try {
    $response = Invoke-RestMethod -Uri "http://localhost:5000/api/v1/billing/create" -Method Post -Headers $headers -Body $body
    Write-Host "Response:"
    $response | ConvertTo-Json -Depth 5
    
    $billId = $response.data.id
    Write-Host "Created Bill ID: $billId"
    
    Write-Host "`nFetching bill details..."
    $bill = Invoke-RestMethod -Uri "http://localhost:5000/api/v1/billing/$billId" -Method Get
    Write-Host "Bill Details:"
    $bill | ConvertTo-Json -Depth 5

    Write-Host "`nFetching Top Items..."
    $topItems = Invoke-RestMethod -Uri "http://localhost:5000/api/v1/billing/summary/top-items" -Method Get
    $topItems | ConvertTo-Json -Depth 5

} catch {
    Write-Host "Error: $($_.Exception.Message)"
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        Write-Host "Response Body: $($reader.ReadToEnd())"
    }
}
