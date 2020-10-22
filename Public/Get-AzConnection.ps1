function Get-AzConnection{
  [CmdLetBinding()]
    param ([string]$subscriptionName)
if ($null -eq (Get-AzContext)){

    Select-AzSubscription -SubScriptionName $subscriptionName  | out-null
    $context = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile.DefaultContext
    
    $graphToken = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id.ToString(), $null, [Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never, $null, "https://graph.microsoft.com").AccessToken
    $aadToken = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id.ToString(), $null, [Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never, $null, "https://graph.windows.net").AccessToken
    
    if ($null -ne $aadToken){
      Connect-AzAccount -AadAccessToken $aadToken -AccountId $context.Account.Id -TenantId $context.tenant.id
    }
    else{
    Write-Host "No Azure Context... logging in. Check for login window behind this one, especially if you are using VSCode!"
    Connect-AzAccount

    }
  }
Write-Host "Ensuring connected to correct subscription"
if ((Get-AzContext).Subscription.Name -ne $subscriptionName){
  Set-AzContext -SubscriptionName $subscriptionName #-Tenant $tenant
}
}