;=============================================================================
; extract_device_height.il v3.1
;   Inline-config Allegro PCB component property extractor.
;   Edit EXCLUDE_DEVICE_TYPES and OUTPUT_FIELDS below, then:
;     skill load "..."
;     extract_device_height
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
; Helper: trim_string
;=============================================================================
procedure( trim_string(str)
    let((rex)
        rexCompile("^[ \t\n\r]+|[ \t\n\r]+$")
        rexReplace(str "" 0)
    )
)

;=============================================================================
; Helper: build_output_path
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
; _get_package_height_from_bound - 专门从package_bound形状读取高度
;=============================================================================
procedure( _get_package_height_from_bound(comp)
    let((height symbols symbol shapes shape layer_name prop_val)
        height = nil
        
        ; 方法1: 从 symbol 获取
        symbols = comp->symbol
        when(symbols
            ; 如果是列表，遍历所有symbol
            if(listp(symbols) then
                foreach(symbol symbols
                    shapes = symbol->shapes
                    when(shapes
                        foreach(shape shapes
                            ; 检查形状的层
                            layer_name = shape->layer
                            when(layer_name
                                layer_name = upperCase(layer_name)
                                ; 检查是否在package_bound层上
                                when(index(layer_name "PACKAGE_BOUND") ||
                                     index(layer_name "PACKAGE_BOUND_TOP") ||
                                     index(layer_name "PACKAGE_BOUND_BOTTOM")
                                    ; 尝试从不同位置获取高度值
                                    ; 1. 从 shape->prop 获取
                                    when(shape->prop
                                        prop_val = get(shape->prop "PACKAGE_HEIGHT_MAX")
                                        when(prop_val height = prop_val)
                                    )
                                    ; 2. 从 axlDBGetProperties 获取
                                    when(null(height)
                                        prop_val = axlDBGetProperties(shape)
                                        when(prop_val
                                            prop_val = get(prop_val "PACKAGE_HEIGHT_MAX")
                                            when(prop_val height = prop_val)
                                        )
                                    )
                                    ; 3. 尝试从 symbol 的属性获取
                                    when(null(height) && symbol->prop
                                        prop_val = get(symbol->prop "PACKAGE_HEIGHT_MAX")
                                        when(prop_val height = prop_val)
                                    )
                                    ; 如果找到了就返回
                                    when(height return(height))
                                )
                            )
                        )
                    )
                )
            else  ; 单个symbol
                shapes = symbols->shapes
                when(shapes
                    foreach(shape shapes
                        layer_name = shape->layer
                        when(layer_name
                            layer_name = upperCase(layer_name)
                            when(index(layer_name "PACKAGE_BOUND") ||
                                 index(layer_name "PACKAGE_BOUND_TOP") ||
                                 index(layer_name "PACKAGE_BOUND_BOTTOM")
                                when(shape->prop
                                    prop_val = get(shape->prop "PACKAGE_HEIGHT_MAX")
                                    when(prop_val height = prop_val)
                                )
                                when(null(height)
                                    prop_val = axlDBGetProperties(shape)
                                    when(prop_val
                                        prop_val = get(prop_val "PACKAGE_HEIGHT_MAX")
                                        when(prop_val height = prop_val)
                                    )
                                )
                                when(height return(height))
                            )
                        )
                    )
                )
            )
        )
        
        ; 方法2: 如果还没找到，尝试从 compdef 的 shapes 中查找
        when(null(height) && comp->compdef
            shapes = comp->compdef->shapes
            when(shapes
                foreach(shape shapes
                    layer_name = shape->layer
                    when(layer_name
                        layer_name = upperCase(layer_name)
                        when(index(layer_name "PACKAGE_BOUND") ||
                             index(layer_name "PACKAGE_BOUND_TOP") ||
                             index(layer_name "PACKAGE_BOUND_BOTTOM")
                            when(shape->prop
                                prop_val = get(shape->prop "PACKAGE_HEIGHT_MAX")
                                when(prop_val height = prop_val)
                            )
                            when(null(height)
                                prop_val = axlDBGetProperties(shape)
                                when(prop_val
                                    prop_val = get(prop_val "PACKAGE_HEIGHT_MAX")
                                    when(prop_val height = prop_val)
                                )
                            )
                            when(height return(height))
                        )
                    )
                )
            )
        )
        
        ; 方法3: 从组件的其他属性中查找
        when(null(height) && comp->prop
            prop_val = get(comp->prop "PACKAGE_HEIGHT_MAX")
            when(prop_val height = prop_val)
        )
        
        when(null(height) && comp->compdef && comp->compdef->prop
            prop_val = get(comp->compdef->prop "PACKAGE_HEIGHT_MAX")
            when(prop_val height = prop_val)
        )
        
        when(null(height) && comp->symbol && comp->symbol->prop
            prop_val = get(comp->symbol->prop "PACKAGE_HEIGHT_MAX")
            when(prop_val height = prop_val)
        )
        
        when(null(height)
            prop_val = axlDBGetProperties(comp)
            when(prop_val
                prop_val = get(prop_val "PACKAGE_HEIGHT_MAX")
                when(prop_val height = prop_val)
            )
        )
        
        ; 返回结果
        if(height then height else "N/A")
    )
)

;=============================================================================
; _get_prop_value
;=============================================================================
procedure( _get_prop_value(comp field_name)
    let((fn_upper value)
        fn_upper = upperCase(field_name)
        
        cond(
            (equal(fn_upper "REFDES")     comp->name)
            (equal(fn_upper "DEVICE_TYPE") let((dt) dt = comp->deviceType
                if(dt then dt else "UNKNOWN")))
            ; 专门处理 PACKAGE_HEIGHT_MAX - 必须在 t 分支之前
            (equal(fn_upper "PACKAGE_HEIGHT_MAX")
                _get_package_height_from_bound(comp)
            )
            (t
                value = nil
                ; comp->prop
                when(null(value) && comp->prop
                    value = get(comp->prop field_name))
                ; comp->compdef->prop
                when(null(value) && comp->compdef && comp->compdef->prop
                    value = get(comp->compdef->prop field_name))
                ; comp->symbol->prop
                when(null(value) && comp->symbol && comp->symbol->prop
                    value = get(comp->symbol->prop field_name))
                ; axlDBGetProperties fallbacks
                when(null(value)
                    let((p) p = axlDBGetProperties(comp)  when(p value = get(p field_name))))
                when(null(value) && comp->compdef
                    let((p) p = axlDBGetProperties(comp->compdef)  when(p value = get(p field_name))))
                when(null(value) && comp->symbol
                    let((p) p = axlDBGetProperties(comp->symbol)  when(p value = get(p field_name))))
                if(value then value else "N/A")
            )
        )
    )
)

;=============================================================================
; _wildcard_match
;=============================================================================
procedure( _wildcard_match(value pattern)
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
; _is_excluded
;=============================================================================
procedure( _is_excluded(comp)
    let((dev_type dev_upper excl)
        dev_type = comp->deviceType
        unless(dev_type dev_type = "UNKNOWN")
        dev_upper = upperCase(dev_type)
        ; check against exclude list with wildcard support
        exists(pattern CFG_EXCLUDE
            _wildcard_match(dev_upper pattern))
    )
)

;=============================================================================
; _do_export
;=============================================================================
procedure( _do_export(comps output_fields output_file)
    prog((fp field_value header row count)
        
        printf("\n* Exporting %d components to %s\n" length(comps) output_file)
        
        fp = outfile(output_file "w")
        unless(fp
            printf("* ERROR: Cannot create file %s\n" output_file)
            return(nil))
        
        fprintf(fp "%c%c%c" intToChar(239) intToChar(187) intToChar(191))
        
        header = ""
        foreach(field_name output_fields
            header = strcat(header field_name ","))
        header = substring(header 1 strlen(header) - 1)
        fprintf(fp "%s\n" header)
        
        count = 0
        foreach(comp comps
            count = count + 1
            row = ""
            foreach(field_name output_fields
                field_value = _get_prop_value(comp field_name)
                if(index(field_value ",") then
                    row = strcat(row "\"" field_value "\",")
                else
                    row = strcat(row field_value ",")))
            row = substring(row 1 strlen(row) - 1)
            fprintf(fp "%s\n" row)
            when(zerop(mod(count, 200))
                printf("  Processed %d / %d ...\n" count length(comps))))
        
        close(fp)
        
        printf("\n============================================\n")
        printf("  Export Complete!\n")
        printf("  ----------------------------------------\n")
        printf("  File:    %s\n" output_file)
        printf("  Total:   %d\n" count)
        printf("  Columns: %L\n" output_fields)
        printf("============================================\n\n")
        
        axlUIConfirm(sprintf(nil
            "Export Complete!\n\nFile: %s\nComponents: %d  Columns: %d\n\nOpen with Excel to view."
            output_file count length(output_fields)))
        return(t)
    )
)

;=============================================================================
; extract_device_height
;=============================================================================
procedure( extract_device_height()
    prog((design comps filtered_comps output_file comp)
        
        printf("\n*==========================================*\n")
        printf("|  Device Height Extraction Tool v3.1      |\n")
        printf("*==========================================*\n\n")
        
        printf("* Mode:     %s\n" CFG_MODE)
        printf("* Output:   %L\n" CFG_OUTPUT)
        printf("* Exclude:  %L\n" CFG_EXCLUDE)
        
        design = axlDBGetDesign()
        unless(design
            axlUIConfirm("Error: No PCB design is open!")
            printf("* ERROR: No open PCB design\n")
            return(nil))
        
        comps = design->components
        unless(comps
            axlUIConfirm("Info: No components in design.")
            printf("* INFO: No components\n")
            return(nil))
        
        printf("* Total components in design: %d\n" length(comps))
        
        ; filter
        filtered_comps = nil
        foreach(comp comps
            if(equal(CFG_MODE "select") then
                when(_is_excluded(comp)
                    filtered_comps = cons(comp, filtered_comps))
            else
                unless(_is_excluded(comp)
                    filtered_comps = cons(comp, filtered_comps))))
        filtered_comps = reverse(filtered_comps)
        
        printf("* After filtering (%s): %d components\n"
            CFG_MODE length(filtered_comps))
        
        unless(filtered_comps
            axlUIConfirm("Info: No components after filtering.")
            return(nil))
        
        output_file = if(CFG_OUTPUT_FILE && nequal(CFG_OUTPUT_FILE "") then
            CFG_OUTPUT_FILE
        else
            build_output_path())
        
        _do_export(filtered_comps CFG_OUTPUT output_file)
        return(t)
    )
)

;=============================================================================
; Register command
;=============================================================================
axlCmdRegister("extract_device_height" 'extract_device_height ?cmdType "general")

;=============================================================================
; Load banner
;=============================================================================
printf("\n")
printf("*==========================================*\n")
printf("| Device Height Extraction Tool v3.1       |\n")
printf("*------------------------------------------*\n")
printf("| Command: extract_device_height           |\n")
printf("| Config:  Edit top of this .il file       |\n")
printf("*==========================================*\n\n")