Function Get-CachedAdGroupName{
    param($ObjectId)

    if ($null -eq $AdGroupCache){
        $global:AdGroupCache = @{}
    }
    if (-not  $global:AdGroupCache.ContainsKey($ObjectId)){
        
        $global:AdGroupCache.$ObjectId = (Get-AzADGroup -ObjectId $ObjectId).DisplayName
    }
    return  @{DisplayName=$global:AdGroupCache.$ObjectId}
}
