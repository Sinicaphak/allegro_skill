$inputFile  = 'D:\program615\allegro\work\0728\aaa.txt'
$outputFile = 'D:\program615\allegro\work\0728\components.csv'

$text = Get-Content -LiteralPath $inputFile -Raw

$blocks = $text -split '(?m)(?=^Item\s+\d+\s+<\s*SYMBOL\s*>)'

$rows = foreach ($block in $blocks) {
    if ($block -match '(?m)^\s*RefDes:\s*(.*?)\s*$') {
        $refDes = $Matches[1].Trim()

        $deviceType = ''
        if ($block -match '(?m)^\s*Device Type:\s*(.*?)\s*$') {
            $deviceType = $Matches[1].Trim()
        }

        $partNumber = ''
        if ($block -match '(?m)^\s*PART_NUMBER\s*=\s*(.*?)\s*$') {
            $partNumber = $Matches[1].Trim()
        }

        [PSCustomObject][ordered]@{
            'RefDes'      = $refDes
            'Device Type' = $deviceType
            'PART_NUMBER' = $partNumber
        }
    }
}

$rows | Export-Csv `
    -LiteralPath $outputFile `
    -NoTypeInformation `
    -Encoding UTF8

Write-Host "finish: $outputFile"