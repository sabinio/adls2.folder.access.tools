Function Get-CachedAdGroupId{
    param($DisplayName)

    if ($null -eq $AdGroupCache){
        $global:AdGroupCache = @{}
    }
    if (-not  $global:AdGroupCache.ContainsKey($DisplayName)){
        
        $global:AdGroupCache.$DisplayName = (Get-AzADGroup -DisplayName $DisplayName).Id
    }
    return @{Id= $global:AdGroupCache.$DisplayName}
}