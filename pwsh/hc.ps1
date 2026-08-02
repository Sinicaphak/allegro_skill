# 定义要处理的文件名数组
$fileNames = @(
    @{ Name = "down_0mm_1"     ;      dxf_height = 0 },                               
    @{ Name = "down_12mm_part1";      dxf_height = 12 },                                   
    @{ Name = "down_12mm_part2";      dxf_height = 12 },                                   
    @{ Name = "down_1mm"       ;      dxf_height = 1 },                               
    @{ Name = "down_2mm_1"     ;      dxf_height = 2 },                               
    @{ Name = "down_2mm_2"     ;      dxf_height = 2 },                               
    @{ Name = "down_7mm_1"     ;      dxf_height = 7 },                               
    @{ Name = "down_7mm_2"     ;      dxf_height = 7 },                               
    @{ Name = "down_7mm_3"     ;      dxf_height = 7 },                               
    @{ Name = "down_7mm_4"     ;      dxf_height = 7 },                               
    @{ Name = "down_mcio1"     ;      dxf_height = 1 },                               
    @{ Name = "down_mcio10"    ;      dxf_height = 1 },                               
    @{ Name = "down_mcio2"     ;      dxf_height = 1 },                               
    @{ Name = "down_mcio3_1"   ;      dxf_height = 1 },                                   
    @{ Name = "down_mcio3_2"   ;      dxf_height = 1 },                                   
    @{ Name = "down_mcio4"     ;      dxf_height = 1 },                               
    @{ Name = "down_mcio6"     ;      dxf_height = 1 },                               
    @{ Name = "down_mcio7"     ;      dxf_height = 1 },                               
    @{ Name = "down_mcio9"     ;      dxf_height = 1 },                               
    @{ Name = "down_mcio_5"    ;      dxf_height = 1 },                               
    @{ Name = "dwn_mcio8"      ;      dxf_height = 1 }
)

# 基础路径
$basePath = "E:\RjDir\UserData\Desktop\height_check\SP7-0727_2100_pcb\dxf\"
# 输出文件路径（所有数据合并到一个CSV）
$outputFile = $basePath + "\csv\" + "combined_results.csv"
# 用于存储所有数据的集合
$allRows = @()

# 遍历每个文件名
foreach ($name in $fileNames) {
    $inputFile = $basePath + $name.Name + '.txt'
    
    # 检查文件是否存在
    if (-not (Test-Path -LiteralPath $inputFile)) {
        Write-Warning "文件不存在，跳过: $inputFile"
        continue
    }
    
    $dxf_height = $name.dxf_height
    # 读取文件内容
    $text = Get-Content -LiteralPath $inputFile -Raw
    
    # 按Item块分割
    $blocks = $text -split '(?m)(?=^Item\s+\d+\s+<\s*SYMBOL\s*>)'

    # 处理每个块
    foreach ($block in $blocks) {
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
            
            # 添加源文件名信息
            $allRows += [PSCustomObject][ordered]@{
                'RefDes'      = $refDes
                'Device Type' = $deviceType
                'PART_NUMBER' = $partNumber
                'Symbol name' = $symbolName
                'dxf_height'  = $dxf_height
            }
        }
    }
}

if ($allRows.Count -gt 0) {
    $allRows | Export-Csv `
        -LiteralPath $outputFile `
        -NoTypeInformation `
        -Encoding UTF8
    Write-Host "输出文件: $outputFile"
} else {
    Write-Warning "没有提取到任何数据"
}