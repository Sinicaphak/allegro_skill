OUTPUT_PATH = "D:/program615/allegro/skill/0729/output"
OUTPUT_FILENAME = "aaa"

EXCLUDE_PARAM = list(
    list("DEVICE_TYPE"
        list(
            "732520091_SD_18_732520091_SD_18"
        )
    )
)

QUERY_PARAM = list(
    list("PART_NUMBER")
    list("DEVICE_TYPE")
    list("REFDES")
    list("PACKAGE_HEIGHT_MAX")
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

procedure(iterate_placebound(sym)
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
                    ||
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

        ; 找不到时使用 symbol->refdes
        unless(refdes
            refdes = sym->refdes
        )

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
        (heightValue "")
        sym
    )
        foreach(sym allSymbols
            symCount = add1(symCount)

            ; Progress indicator
            when(zerop(mod(symCount 1000))
                printf(
                    "  Processing %d / %d symbols...\n"
                    symCount
                    length(allSymbols)
                )
            )

            ; Only process symbols with a refdes
            refdes = iterate_refdes(sym)

            unless(equal(refdes "N/A")
                deviceType = iterate_device_type(sym)
                partNumber = iterate_part_number(sym)
                heightValue = iterate_placebound(sym)

                ; 顺序与 QUERY_PARAM 保持一致：
                ; PART_NUMBER, DEVICE_TYPE, REFDES, PACKAGE_HEIGHT_MAX
                line = sprintf(
                    nil
                    "%s,%s,%s,%s\n"
                    partNumber
                    deviceType
                    refdes
                    heightValue
                )

                fprintf(csvPort "%s" line)
            )
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
