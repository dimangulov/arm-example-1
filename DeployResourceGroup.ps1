param(
 [string]
 $subscriptionId = "d1d09bac-c318-43d4-9b3f-5182191c44a6",
 [string]
 $paramFileName = "parameters.dev.json",
 [string]
 $resourceGroupName = "Mobile-Apps",
 [string]
 $outConfigFileName = "\src\KPMG.Petstagram.Web\appsettings.azure.json",
 [string]
 $configTemplateFileName = "\src\KPMG.Petstagram.Web\appsettings.azure.template.json"
 )

function Login
{
    $needLogin = $true
    Try 
    {
        $content = Get-AzureRmContext
        if ($content) 
        {
            $needLogin = ([string]::IsNullOrEmpty($content.Account))
        } 
    } 
    Catch 
    {
        if ($_ -like "*Login-AzureRmAccount to login*") 
        {
            $needLogin = $true
        } 
        else 
        {
            throw
        }
    }

    if ($needLogin)
    {
        Login-AzureRmAccount
    }
}

Login;

$context = Get-AzureRmContext

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$utilsDir  = Join-Path -Path $scriptDir -ChildPath ExportedTemplate-petstagram

$parametersFilePath = ($utilsDir + "\" + $paramFileName)

Write-Host ("parametersFilePath: " + $parametersFilePath)

$templateFilePath = ($utilsDir + "\template.json")

$jsondata = Get-Content -Raw -Path $parametersFilePath | ConvertFrom-Json

Write-Host $jsondata

$vaultName = $jsondata.parameters.vaults_petstagram_key_vault_name.value

Write-Host $vaultName
Write-Host $subscriptionId
Write-Host $resourceGroupName
Write-Host $templateFilePath
Write-Host $parametersFilePath

& ($utilsDir + "\deploy.ps1") `
	-subscriptionId $subscriptionId `
	-resourceGroupName $resourceGroupName `
	-deploymentName "initial" `
	-templateFilePath $templateFilePath `
	-parametersFilePath $parametersFilePath;

Set-AzureRmKeyVaultAccessPolicy –VaultName $vaultName -EmailAddress $context.Account.Id –PermissionsToSecrets get,list,set,delete,backup,restore,recover,purge

& ($scriptDir + "\BuildConfigurationFile.ps1") -paramFileName $paramFileName -outFileName $outConfigFileName -configTemplateFileName $configTemplateFileName