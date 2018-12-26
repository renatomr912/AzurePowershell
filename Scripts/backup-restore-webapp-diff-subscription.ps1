#Based on this site: https://docs.microsoft.com/en-us/azure/app-service/scripts/powershell-backup-restore-diff-sub

function Validate-ResourceGroup {
    param([string]$resourceGroupName)
    if($resourceGroupName -eq '') {
        return $false
    }
    try
    {
        $resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName
        Write-Host $resourceGroup.ResourceId
        if($resourceGroup -eq $null) {
            return $false
        }
        return $true   
    }
    catch
    {
        return $false
    }
}

function Validate-WebApp {
    param([string]$webAppName, [string]$resourceGroupName)
    if($webAppName -eq '') {
        return $false
    }
    
    $webApp = Get-AzureRmWebApp -Name $webAppName -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue -ErrorVariable processError

    if($processError) {
        return $false
    }
    
    return $true
    
}

echo "This script will transfer one webapp to another subscription, using its backup"

echo "Log into the origin subscription" 

Add-AzureRmAccount


$originResourceGroupName = Read-Host 'Type the origin resource group name'
$isValid = Validate-ResourceGroup -resourceGroupName $originResourceGroupName
while($isvalid -eq $false)
{
    $originResourceGroupName = Read-Host "Origin resource group name is invalid. Type the origin resource group name"
    $isValid = Validate-ResourceGroup -resourceGroupName $originResourceGroupName
}

$originWebAppName = Read-Host 'Type the origin web app name'
$isValid = Validate-WebApp -webAppName $originWebAppName -resourceGroupName $originResourceGroupName

while($isValid -eq $false)
{
    $originWebAppName = Read-Host "Origin web app name is invalid. Type the origin web app name"
    $isValid = Validate-WebApp -webAppName $originWebAppName -resourceGroupName $originResourceGroupName
}

try
{
    # List statuses of all backups that are complete or currently executing.
    $backupList = Get-AzureRmWebAppBackupList -ResourceGroupName $originResourceGroupName -Name $originWebAppName

    if($backupList -eq $null -or $backupList.Length -eq 0){
        Write-Error 'There is no backup enabled in origin web app. This script will terminate now.' -ErrorAction Stop
    }

    # save the latest backupId to restore
    $backup = $backupList[$backupList.Length - 1]
    echo 'Backup encontrado:' + $backup.BackupName

    echo "Log into the destination subscription" 

    Add-AzureRmAccount

    
    $destResourceGroupName = Read-Host 'Type the destination resource group name'
    $isValid = Validate-ResourceGroup -resourceGroupName $destResourceGroupName
    while($isvalid -eq $false)
    {
        $destResourceGroupName = Read-Host "Destination resource group name is invalid. Type the destination resource group name"
        $isValid = Validate-ResourceGroup -resourceGroupName $destResourceGroupName
    }

    $destWebAppName = Read-Host 'Type the destination web app name'
    $isValid = Validate-WebApp -webAppName $destWebAppName -resourceGroupName $destResourceGroupName

    while($isValid -eq $false)
    {
        $destWebAppName = Read-Host "Destination web app name is invalid. Type the destination web app name"
        $isValid = Validate-WebApp -webAppName $destWebAppName -resourceGroupName $destResourceGroupName
    }

    # Restore the app by overwriting it with the backup data
    Restore-AzureRmWebAppBackup -ResourceGroupName $destResourceGroupName -Name $destWebAppName -StorageAccountUrl $backup.StorageAccountUrl -BlobName $backup.BlobName -Overwrite -IgnoreConflictingHostNames

    echo "Done!"
}
catch
{
    echo "Error... please try again"
}
