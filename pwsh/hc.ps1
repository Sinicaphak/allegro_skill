$name = "12mm_up"
$inputFile  = 'D:\git_warehouse\allegro_skill\pwsh\'+$name+'.txt'
$outputFile = 'D:\git_warehouse\allegro_skill\pwsh\csv\'+$name+'.csv'

$text = Get-Content -LiteralPath $inputFile -Raw

$blocks = $text -split '(?m)(?=^Item\s+\d+\s+<\s*SYMBOL\s*>)'

$rows = foreach ($block in $blocks) {
    if ($block -match '(?m)^\s*RefDes:\s*(.*?)\s*$') {
        $refDes = $Matches[1].Trim()

        $deviceType = ''
        if ($block -match '(?m)^\s*Device Type:\s*(.*?)\s*$') {
            $deviceType = $Matches[1].Trim()
        }

        $symbolName = ''
        if ($block -match '(?m)^\s*Symbol name:\s*(.*?)\s*$') {
            $symbolName = $Matches[1].Trim()
        }

        $partNumber = ''
        if ($block -match '(?m)^\s*PART_NUMBER\s*=\s*(.*?)\s*$') {
            $partNumber = $Matches[1].Trim()
        }

        [PSCustomObject][ordered]@{
            'RefDes'      = $refDes
            'Device Type' = $deviceType
            'PART_NUMBER' = $partNumber
            'Symbol name' = $symbolName
        }
    }
}

$rows | Export-Csv `
    -LiteralPath $outputFile `
    -NoTypeInformation `
    -Encoding UTF8

Write-Host "finish: $outputFile"