OUTPUT_PATH = "D:/program615/allegro/work/retimer/csv"
OUTPUT_FILENAME = "aaa"

EXCLUDE_PARAM = list(
    list("DEVICE_TYPE"
        list(
            "732520091_SD_18_732520091_SD_18"
        )
    )
)

QUERY_PARAM = list(
    list("PART_NUMBER"
         'iterate_part_number)

    list("DEVICE_TYPE"
         'iterate_device_type)

    list("REFDES"
         'iterate_refdes)

    list("MOUNT_SIDE"
         'iterate_mount_side)

    list("PACKAGE_HEIGHT_MAX_TOP"
         'iterate_installed_placebound_top)

    list("PACKAGE_HEIGHT_MAX_BOTTOM"
         'iterate_installed_placebound_bottom)
)

; =================================================================================================================================================================================
procedure(do_csv(outPath)
    prog((csvPort)
        unless(isDir(OUTPUT_PATH)
            axlUIConfirm(
                sprintf(
                    nil
                    "Error: Output directory does not exist:\n%s"
                    OUTPUT_PATH
                )
            )
            return(nil)
        )

        csvPort = outfile(outPath)

        unless(csvPort
            axlUIConfirm(
                sprintf(
                    nil
                    "Error: Cannot create output file:\n%s"
                    outPath
                )
            )
            return(nil)
        )

        return(csvPort)
    )
)

procedure(get_all_symbols()
    prog((design allSymbols)
        design = axlDBGetDesign()

        unless(design
            axlUIConfirm("Error: No design is currently open!")
            return(nil)
        )

        allSymbols = design->symbols

        unless(allSymbols
            axlUIConfirm("No placed symbols found in the design.")
            return(nil)
        )

        printf(
            "Scanning %d symbols for PACKAGE_HEIGHT_MAX...\n"
            length(allSymbols)
        )

        return(allSymbols)
    )
)

procedure(iterate_placebound_top(sym)
    let((layerUpper heightValue child children)
        layerUpper = nil
        heightValue = nil
        child = nil
        children = nil

        children = sym->children

        ; 有些 PLACE_BOUND 只存在于 symbol definition 中
        when(sym->definition && sym->definition->children
            children = append(
                children
                sym->definition->children
            )
        )

        ; 查找第一个有效的 PACKAGE_HEIGHT_MAX
        foreach(child children
            when(null(heightValue) && child && child->layer
                layerUpper = upperCase(child->layer)

                when(
                    equal(
                        layerUpper
                        "PACKAGE GEOMETRY/PLACE_BOUND_TOP"
                    )
                    heightValue = get_db_property(
                        child
                        "PACKAGE_HEIGHT_MAX"
                    )
                )
            )
        )

        if(heightValue then
            heightValue
        else
            "N/A"
        )
    )
)

procedure(iterate_placebound_bottom(sym)
    let((layerUpper heightValue child children)
        layerUpper = nil
        heightValue = nil
        child = nil
        children = nil

        children = sym->children

        ; 有些 PLACE_BOUND 只存在于 symbol definition 中
        when(sym->definition && sym->definition->children
            children = append(
                children
                sym->definition->children
            )
        )

        ; 查找第一个有效的 PACKAGE_HEIGHT_MAX
        foreach(child children
            when(null(heightValue) && child && child->layer
                layerUpper = upperCase(child->layer)

                when(
                    equal(
                        layerUpper
                        "PACKAGE GEOMETRY/PLACE_BOUND_BOTTOM"
                    )

                    heightValue = get_db_property(
                        child
                        "PACKAGE_HEIGHT_MAX"
                    )
                )
            )
        )

        if(heightValue then
            heightValue
        else
            "N/A"
        )
    )
)

procedure(iterate_device_type(sym)
    let((comp deviceType)
        comp = sym->component
        deviceType = nil

        when(comp
            deviceType = comp->deviceType
        )

        if(deviceType then
            deviceType
        else
            "N/A"
        )
    )
)

procedure(iterate_refdes(sym)
    let((refdes comp)
        refdes = nil
        comp = sym->component

        ; 优先使用 component->name
        when(comp && comp->name
            refdes = comp->name
        )

        ; ; 找不到时使用 symbol->refdes
        ; unless(refdes
        ;     refdes = sym->refdes
        ; )

        if(refdes then
            refdes
        else
            "N/A"
        )
    )
)

procedure(iterate_part_number(sym)
    let((comp partNumber)
        comp = sym->component
        partNumber = nil

        when(comp && comp->compdef
            partNumber = get_db_property(
                comp->compdef
                "PART_NUMBER"
            )
        )

        ; 兼容少数直接挂在 component 上的情况
        unless(partNumber
            when(comp
                partNumber = get_db_property(
                    comp
                    "PART_NUMBER"
                )
            )
        )

        if(partNumber then
            partNumber
        else
            "N/A"
        )
    )
)

procedure(iterate_mount_side(sym)
    if(sym->isMirrored then
        "0"
    else
        "1"
    )
)

; 只有正面安装时才输出 TOP PLACE_BOUND
procedure(iterate_installed_placebound_top(sym)
    if(sym->isMirrored then
        "N/A"
    else
        iterate_placebound_top(sym)
    )
)

; 只有背面安装时才输出 BOTTOM PLACE_BOUND
procedure(iterate_installed_placebound_bottom(sym)
    if(sym->isMirrored then
        iterate_placebound_bottom(sym)
    else
        "N/A"
    )
)

procedure(get_db_property(dbid propName)
    let((props value)
        value = nil

        when(dbid
            props = axlDBGetProperties(dbid)

            when(props
                value = _getPropValue(
                    propName
                    props
                )
            )
        )

        value
    )
)

procedure(iterate(allSymbols csvPort)
    let((
        (symCount 0)
        (line "")
        (partNumber "")
        (deviceType "")
        (refdes "")
        (mountSide 1)
        (placebound_top "")
        (placebound_bottom "")
        sym
    )
        foreach(sym allSymbols
            symCount = add1(symCount)

            when(zerop(mod(symCount 1000))
                printf(
                    "  Processing %d / %d symbols...\n"
                    symCount
                    length(allSymbols)
                )
            )

            refdes = iterate_refdes(sym)

            deviceType = iterate_device_type(sym)
            partNumber = iterate_part_number(sym)

            placebound_top = ""
            placebound_bottom = ""

            if(sym->isMirrored then
                ; 背面安装
                mountSide = 0
                placebound_bottom =
                    iterate_placebound_bottom(sym)
            else
                ; 正面安装
                mountSide = 1
                placebound_top =
                    iterate_placebound_top(sym)
            )

            line = sprintf(
                nil
                "\"%s\",\"%s\",\"%s\",%d,\"%s\",\"%s\"\n"
                partNumber
                deviceType
                refdes
                mountSide
                placebound_top
                placebound_bottom
            )

            fprintf(csvPort "%s" line)
            
        )
    )
)

;----------------------------------------------------------------------
; Main function
;----------------------------------------------------------------------
procedure(main()
    prog((allSymbols outFile outPath csvPort sep colName param)
        allSymbols = get_all_symbols()

        unless(allSymbols
            return(nil)
        )

        outFile = strcat(OUTPUT_FILENAME ".csv")
        outPath = strcat(OUTPUT_PATH "/" outFile)
        csvPort = do_csv(outPath)

        unless(csvPort
            return(nil)
        )

        sep = ""

        unwindProtect(
            progn(
                ; ---- Write CSV header from QUERY_PARAM -----------
                foreach(param QUERY_PARAM
                    when(listp(param) && greaterp(length(param) 0)
                        colName = car(param)
                        fprintf(csvPort "%s%s" sep colName)
                        sep = ","
                    )
                )
                fprintf(csvPort "\n")

                ; ---- Iterate all symbols -------------------------
                iterate(allSymbols csvPort)
                drain(csvPort)
            )
            close(csvPort)
        )

        printf("\n")
        printf("========================================\n")
        printf("Scan complete.\n")
        printf("  Symbols processed:%d\n" length(allSymbols))
        printf("  Output file: %s\n" outPath)
        printf("========================================\n")

        axlUIConfirm(
            sprintf(
                nil
                "Done!\n\nSymbols scanned: %d\nOutput file:\n%s"
                length(allSymbols)
                outPath
            )
        )

        return(outPath)
    )
)

;======================================================================
; Helper: Get property value from property assoc list (case-insensitive)
;======================================================================
procedure(_getPropValue(propName propList)
    let((result key keyStr targetUpper pair)
        result = nil
        targetUpper = upperCase(propName)

        foreach(pair propList
            key = nil
            keyStr = nil

            when(listp(pair) && cdr(pair)
                key = car(pair)

                when(key
                    cond(
                        (symbolp(key)
                            keyStr = upperCase(symbolToString(key))
                        )
                        (stringp(key)
                            keyStr = upperCase(key)
                        )
                    )

                    when(keyStr && equal(keyStr targetUpper)
                        result = cadr(pair)
                    )
                )
            )
        )

        result
    )
)

axlCmdRegister("selfv1" 'main)
printf("\n")
printf("========================================\n")
printf("Type 'selfv1' in the console to run.\n")
printf("========================================\n")
