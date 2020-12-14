Function Get-AuthToken
{
[CmdletBinding()]
Param
(
[Parameter(Mandatory=$true)][String]$verb,
[Parameter(Mandatory=$true)][String]$resourceLink,
[Parameter(Mandatory=$true)][String]$resourceType,
[Parameter(Mandatory=$true)][String]$dateTime,
[Parameter(Mandatory=$true)][String]$key,
[Parameter(Mandatory=$true)][String]$keyType,
[Parameter(Mandatory=$true)][String]$tokenVersion
)
 
    $hmacSha256 = New-Object System.Security.Cryptography.HMACSHA256
    $hmacSha256.Key = [System.Convert]::FromBase64String($key)
    
    $payLoad = "$($verb.ToLowerInvariant())`n$($resourceType.ToLowerInvariant())`n$resourceLink`n$($dateTime.ToLowerInvariant())`n`n"
    $hashPayLoad = $hmacSha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($payLoad))
    $signature = [System.Convert]::ToBase64String($hashPayLoad);
 
[System.Web.HttpUtility]::UrlEncode("type=$keyType&ver=$tokenVersion&sig=$signature")
}

Function Update-Document
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $MasterKey,
        [Parameter(Mandatory=$true)]
        [string]
        $EndPoint,
        [Parameter(Mandatory=$true)]
        [string]
        $DatabaseId,
        [Parameter(Mandatory=$true)]
        [string]
        $CollectionId,
        [Parameter(Mandatory=$true)]
        [string]
        $DocumentId,
        [Parameter()]
        $Document
    )
    $Verb = "POST"
    $ResourceType = "docs";
    $ResourceLink = "dbs/$DatabaseId/colls/$CollectionId"
    $dateTime = [DateTime]::UtcNow.ToString("r")
    $authHeader = Get-AuthToken -verb $Verb -resourceLink $ResourceLink -resourceType $ResourceType -key $MasterKey -keyType "master" -tokenVersion "1.0" -dateTime $dateTime
    $header = @{
        authorization=$authHeader;
        "x-ms-version"="2018-12-31";
        "x-ms-date"=$dateTime;
        "x-ms-documentdb-partitionkey"='["' + $DocumentId + '"]';
        "x-ms-documentdb-is-upsert"="True"
    }
    $contentType= "application/json"
    $queryUri = "$EndPoint/dbs/data/colls/$CollectionId/docs"
    try {
        Invoke-RestMethod -Method $Verb -ContentType $contentType -Uri $queryUri -Headers $header -Body $Document       
    }
    catch {
        Write-Host $_.Exception
    }
    return $result.statuscode
}

Function Get-Document
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $MasterKey,
        [Parameter(Mandatory=$true)]
        [string]
        $EndPoint,
        [Parameter(Mandatory=$true)]
        [string]
        $DatabaseId,
        [Parameter(Mandatory=$true)]
        [string]
        $CollectionId,
        [Parameter()]
        [string]
        $DocumentId
    )
    $Verb = "GET"
    $ResourceType = "docs";
    $ResourceLink = "dbs/$DatabaseId/colls/$CollectionId/docs/$DocumentId"
    $dateTime = [DateTime]::UtcNow.ToString("r")
    $authHeader = Get-AuthToken -verb $Verb -resourceLink $ResourceLink -resourceType $ResourceType -key $MasterKey -keyType "master" -tokenVersion "1.0" -dateTime $dateTime
    $header = @{
        authorization=$authHeader;
        "x-ms-version"="2017-02-22";
        "x-ms-date"=$dateTime;
        "x-ms-documentdb-isquery"="True";
        "x-ms-query-enable-crosspartition"="True";
        "x-ms-documentdb-partitionkey"='["' + $DocumentId + '"]';
    }
    $contentType= "application/query+json"
    $queryUri = "$EndPoint$ResourceLink"
    $retVal = Invoke-RestMethod -Method $Verb -ContentType $contentType -Uri $queryUri -Headers $header
    Write-Host $retVal
    return $retVal
}
