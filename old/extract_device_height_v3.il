;=============================================================================
; extract_device_height.il v3.7 - 最终修复版
;   从 PLACE_BOUND_TOP 形状读取 PACKAGE_HEIGHT_MAX
;=============================================================================

; ===== CONFIG: Edit these lines =====
CFG_MODE      = "exclude"           ; "exclude" or "select"
CFG_OUTPUT_FILE = nil                ; nil = auto, or "D:/path/output.csv"
CFG_OUTPUT     = list("DEVICE_TYPE" "REFDES" "PACKAGE_HEIGHT_MAX" "PART_NUMBER")

; ===== DEVICE TYPES to exclude (exclude mode) or keep (select mode) =====
CFG_EXCLUDE    = list(
    "732520091_SD_18_732520091_SD_18",
    "SCREW_HOLE_3_5MM_RD8M00_SCREW_H",
    "COUPON_4-5MIL_HD_COUPON_4-5MIL_",
    "LTST-C191KGKT-RJ_LTST-C191KGKT-",
    "TEST_40_TEST_40_TEST_40_V10B_X-",
    "TEST_016_TEST_016_TEST_016_V10B"
)
; ===== END CONFIG =====

;=============================================================================
; build_output_path
;=============================================================================
procedure( build_output_path()
    let((design_path parts)
        design_path = simplifyFilename(axlCurrentDesign())
        unless(design_path design_path = "./unnamed.brd")
        parts = parseString(design_path ".")
        if(length(parts) > 1 then
            strcat(buildString(reverse(cdr(reverse(parts))) ".") "_device_height.csv")
        else
            strcat(design_path "_device_height.csv")
        )
    )
)

;=============================================================================
; get_height_from_shape
;=============================================================================
procedure( get_height_from_shape(shape)
    let((height)
        height = nil
        
        ; 从 prop 列表获取
        when(shape->prop
            height = get(shape->prop "PACKAGE_HEIGHT_MAX")
        )
        
        ; 从 axlDBGetProperties 获取
        when(null(height)
            let((props)
                props = axlDBGetProperties(shape)
                when(props
                    height = get(props "PACKAGE_HEIGHT_MAX")
                )
            )
        )
        
        if(height then height else "N/A")
    )
)

;=============================================================================
; get_comp_property
;=============================================================================
procedure( get_comp_property(comp field_name)
    let((value)
        value = nil
        
        when(comp->prop
            value = get(comp->prop field_name)
        )
        
        when(null(value)
            let((props)
                props = axlDBGetProperties(comp)
                when(props
                    value = get(props field_name)
                )
            )
        )
        
        if(value then value else "N/A")
    )
)

;=============================================================================
; get_device_type
;=============================================================================
procedure( get_device_type(comp)
    let((dev_type)
        dev_type = comp->deviceType
        unless(dev_type
            when(comp->compdef
                dev_type = comp->compdef->name
            )
        )
        unless(dev_type dev_type = "UNKNOWN")
        dev_type
    )
)

;=============================================================================
; wildcard_match
;=============================================================================
procedure( wildcard_match(value pattern)
    prog((vp pp part pos found)
        unless(index(pattern "*") return(equal(value pattern)))
        vp = value
        pp = pattern
        while(strlen(pp) > 0
            pos = index(pp "*")
            if(pos then
                if(pos > 1 then
                    part = substring(pp 1 pos - 1)
                    found = index(vp part)
                    if(found then
                        vp = substring(vp found + strlen(part) strlen(vp))
                    else
                        return(nil)))
                pp = substring(pp pos + 1 strlen(pp))
            else
                if(strlen(pp) <= strlen(vp) then
                    return(equal(substring(vp strlen(vp) - strlen(pp) + 1 strlen(vp)) pp))
                else
                    return(nil))))
        return(t)
    )
)

;=============================================================================
; is_excluded
;=============================================================================
procedure( is_excluded(dev_type)
    let((dev_upper)
        dev_upper = upperCase(dev_type)
        exists(pattern CFG_EXCLUDE
            wildcard_match(dev_upper pattern))
    )
)

;=============================================================================
; extract_device_height - 主函数
;=============================================================================
procedure( extract_device_height_v3()
    let((design output_file fp shapes count shape layer parent comp 
         refdes dev_type height part_num row)
        
        printf("\n*==========================================*\n")
        printf("|  Device Height Extraction Tool v3.7      |\n")
        printf("*==========================================*\n\n")
        
        printf("* Mode:     %s\n" CFG_MODE)
        printf("* Output:   %L\n" CFG_OUTPUT)
        printf("* Exclude:  %L\n" CFG_EXCLUDE)
        
        ; 检查设计
        design = axlDBGetDesign()
        unless(design
            axlUIConfirm("Error: No PCB design is open!")
            printf("* ERROR: No open PCB design\n")
            return(nil)
        )
        
        ; 设置输出文件
        output_file = if(CFG_OUTPUT_FILE && nequal(CFG_OUTPUT_FILE "") then
            CFG_OUTPUT_FILE
        else
            build_output_path()
        )
        
        printf("* Exporting to %s\n" output_file)
        
        ; 创建文件
        fp = outfile(output_file "w")
        unless(fp
            printf("* ERROR: Cannot create file %s\n" output_file)
            return(nil)
        )
        
        ; 写入UTF-8 BOM
        fprintf(fp "%c%c%c" intToChar(239) intToChar(187) intToChar(191))
        
        ; 写入表头
        fprintf(fp "DEVICE_TYPE,REFDES,PACKAGE_HEIGHT_MAX,PART_NUMBER\n")
        
        ; 获取 PLACE_BOUND_TOP 形状
        printf("* Getting shapes from PACKAGE GEOMETRY/PLACE_BOUND_TOP...\n")
        shapes = axlDBGetShapes("PACKAGE GEOMETRY/PLACE_BOUND_TOP")
        
        unless(shapes
            printf("* WARNING: No shapes found on PACKAGE GEOMETRY/PLACE_BOUND_TOP\n")
            printf("* Trying alternative layer name...\n")
            shapes = axlDBGetShapes("PACKAGE_GEOMETRY/PLACE_BOUND_TOP")
        )
        
        unless(shapes
            printf("* ERROR: No shapes found on PLACE_BOUND_TOP\n")
            close(fp)
            axlUIConfirm("No PLACE_BOUND_TOP shapes found!")
            return(nil)
        )
        
        printf("* Found %d shapes on PLACE_BOUND_TOP\n" length(shapes))
        
        count = 0
        
        ; 遍历所有形状
        foreach(shape shapes
            ; 获取父对象 (symbol)
            parent = shape->parent
            comp = nil
            refdes = nil
            dev_type = nil
            
            ; 从 symbol 获取 component
            when(parent && parent->objType == "symbol"
                comp = parent->component
            )
            
            ; 如果父对象是 component
            when(null(comp) && parent && parent->objType == "component"
                comp = parent
            )
            
            ; 如果找到了组件
            when(comp
                refdes = comp->name
                dev_type = get_device_type(comp)
                
                ; 检查是否被排除
                skip = nil
                when(equal(CFG_MODE "exclude")
                    when(is_excluded(dev_type)
                        skip = t
                    )
                )
                when(equal(CFG_MODE "select")
                    unless(is_excluded(dev_type)
                        skip = t
                    )
                )
                
                unless(skip
                    ; 获取高度值
                    height = get_height_from_shape(shape)
                    
                    ; 获取 PART_NUMBER
                    part_num = get_comp_property(comp "PART_NUMBER")
                    
                    ; 构建数据行
                    row = sprintf(nil "%s,%s,%s,%s" 
                        dev_type refdes height part_num)
                    
                    fprintf(fp "%s\n" row)
                    count = count + 1
                    
                    when(zerop(mod(count, 100))
                        printf("  Processed %d components ...\n" count)
                    )
                )
            )
        )
        
        close(fp)
        
        printf("\n============================================\n")
        printf("  Export Complete!\n")
        printf("  ----------------------------------------\n")
        printf("  File:    %s\n" output_file)
        printf("  Total Components: %d\n" count)
        printf("  Columns: DEVICE_TYPE, REFDES, PACKAGE_HEIGHT_MAX, PART_NUMBER\n")
        printf("============================================\n\n")
        
        axlUIConfirm(sprintf(nil
            "Export Complete!\n\nFile: %s\nComponents: %d\n\nOpen with Excel to view."
            output_file count))
        
        t  ; 返回 t 表示成功
    )
)

;=============================================================================
; Register command
;=============================================================================
axlCmdRegister("extract_device_height_v3" 'extract_device_height_v3 ?cmdType "general")

;=============================================================================
; Load banner
;=============================================================================
printf("\n")
printf("*==========================================*\n")
printf("| Device Height Extraction Tool v3.7       |\n")
printf("*------------------------------------------*\n")
printf("| Command: extract_device_height_v3        |\n")
printf("| Config:  Edit top of this .il file       |\n")
printf("*==========================================*\n\n")
