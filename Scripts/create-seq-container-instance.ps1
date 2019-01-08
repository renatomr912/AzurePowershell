Add-AzureRmAccount

$ResourceGroup = ''
$StorageAccountName = ''
$fileShareName = ''
$location = ''

$storageKey = $(az storage account keys list --resource-group $ResourceGroup --account-name $StorageAccountName --query "[0].value" --output tsv)


az container create --resource-group $ResourceGroup --name seqlogcontainer --image datalust/seq:latest --dns-name-label seqlog --ports 80 5341 --azure-file-volume-account-name $StorageAccountName --azure-file-volume-account-key $storageKey --azure-file-volume-share-name $fileShareName --azure-file-volume-mount-path /data --cpu 1 --memory 2 --location $location --environment-variables ACCEPT_EULA=Y