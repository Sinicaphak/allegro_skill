OUTPUT_PATH = "D:/program615/allegro/skill/0729/output"
OUTPUT_FILENAME = "aaa.csv"

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
(procedure do_csv()
; ---- Create output CSV file ---------------------------------
    outFile = (strcat OUTPUT_FILENAME ".csv")
    outPath = (strcat OUTPUT_PATH "/" outFile)

    csvPort = (outfile outPath)
    (unless csvPort
      (axlUIConfirm (sprintf nil
        "Error: Cannot create output file:\n%s" outPath))
      (return nil)
    )
    csvPort
)

(procedure get_all_symbols()
    (let (
        (design nil)
        (allSymbols nil)
    
        design = (axlDBGetDesign)
        (unless design
            (axlUIConfirm "Error: No design is currently open!")
            (return nil)
        )
        allSymbols = design->symbols
        (unless allSymbols
            (axlUIConfirm "No placed symbols found in the design.")
            (return nil)
        )

        (printf "Scanning %d symbols for PACKAGE_HEIGHT_MAX...\n"
                (length allSymbols))
        allSymbols
        )
    )
)

(procedure iterate_placebound(child)
    (let (
        (layer nil)
        (layerUpper nil)
        (props nil)
        (heightVal nil)
    )

    layer = child->layer
    (
        when (layer)
            layerUpper = (upperCase layer)
            ; Check for the two target subclasses
            (
                when (or 
                    (equal layerUpper "PACKAGE GEOMETRY/PLACE_BOUND_TOP")
                    (equal layerUpper "PACKAGE GEOMETRY/PLACE_BOUND_BOTTOM")
                )
                    ; Get properties and look for PACKAGE_HEIGHT_MAX
                    props = (axlDBGetProperties child)
                    (
                        when (props)
                            heightVal = (_getPropValue "PACKAGE_HEIGHT_MAX" props)
                                (
                                    when (heightVal)
                                        (return heightVal)
                                )
                    )
            )
    ))
    ; All conditions failed
    "N/A"
)

(procedure iterate_device_type(child)
    (let (
        (layer nil)
        (layerUpper nil)
        (props nil)
        (heightVal nil)
    )

    layer = child->layer
    (
        when (layer)
            layerUpper = (upperCase layer)
            ; Check for the two target subclasses
            (
                when (or 
                    (equal layerUpper "PACKAGE GEOMETRY/PLACE_BOUND_TOP")
                    (equal layerUpper "PACKAGE GEOMETRY/PLACE_BOUND_BOTTOM")
                )
                    ; Get properties and look for PACKAGE_HEIGHT_MAX
                    props = (axlDBGetProperties child)
                    (
                        when (props)
                            heightVal = (_getPropValue "PACKAGE_HEIGHT_MAX" props)
                                (
                                    when (heightVal)
                                        (return heightVal)
                                )
                    )
            )
    ))
    ; All conditions failed
    "N/A"
)

(procedure iterate_refdes(child)
    (let (
        (layer nil)
        (layerUpper nil)
        (props nil)
        (heightVal nil)
    )

    layer = child->layer
    (
        when (layer)
            layerUpper = (upperCase layer)
            ; Check for the two target subclasses
            (
                when (or 
                    (equal layerUpper "PACKAGE GEOMETRY/PLACE_BOUND_TOP")
                    (equal layerUpper "PACKAGE GEOMETRY/PLACE_BOUND_BOTTOM")
                )
                    ; Get properties and look for PACKAGE_HEIGHT_MAX
                    props = (axlDBGetProperties child)
                    (
                        when (props)
                            heightVal = (_getPropValue "PACKAGE_HEIGHT_MAX" props)
                                (
                                    when (heightVal)
                                        (return heightVal)
                                )
                    )
            )
    ))
    ; All conditions failed
    "N/A"
)

(procedure iterate_part_number(child)
    (let (
        (layer nil)
        (layerUpper nil)
        (props nil)
        (heightVal nil)
    )

    layer = child->layer
    (
        when (layer)
            layerUpper = (upperCase layer)
            ; Check for the two target subclasses
            (
                when (or 
                    (equal layerUpper "PACKAGE GEOMETRY/PLACE_BOUND_TOP")
                    (equal layerUpper "PACKAGE GEOMETRY/PLACE_BOUND_BOTTOM")
                )
                    ; Get properties and look for PACKAGE_HEIGHT_MAX
                    props = (axlDBGetProperties child)
                    (
                        when (props)
                            heightVal = (_getPropValue "PACKAGE_HEIGHT_MAX" props)
                                (
                                    when (heightVal)
                                        (return heightVal)
                                )
                    )
            )
    ))
    ; All conditions failed
    "N/A"
)


(procedure iterate(allSymbols)
    (let(
        (symCount 0)
        (line "")
    )
        (foreach sym allSymbols
        symCount = (add1 symCount)

        ; Progress indicator
        (when (zerop (mod symCount 1000))
            (printf "  Processing %d / %d symbols...\n"
                    symCount (length allSymbols))
        )

        ; Only process symbols with a refdes
        refdes = sym->refdes
        (when refdes
            ; Only process symbols with children (figures)
            children = sym->children
            (when children
                ; Iterate children to find PLACE_BOUND shapes
                (foreach child children
                    line += (iterate_part_number(child)) += ","
                    line += (iterate_device_type(child)) += ","
                    line += (iterate_refdes(child)) += ","
                    line += (iterate_placebound(child)) += ","
                )
                line += "\n"
                ; line 输出到csv
            )
        )
        )
    )
)

;----------------------------------------------------------------------
; Main function
;----------------------------------------------------------------------
(procedure main()
    (let (
            (allSymbols nil)
            (sym nil)
            (refdes nil)
            (children nil)
            (child nil)
            (layer nil)
            (layerUpper nil)
            (props nil)
            (heightVal nil)
            (drawName nil)
            (drawDir nil)
            (outFile nil)
            (outPath nil)
            (csvPort nil)
       )

    allSymbols = (get_all_symbols)
    csvPort = (do_csv(allSymbols))

    ; ----  Write CSV header from QUERY_PARAM ----------------------
    (let (
            (sep "") 
            (colName nil)
        )
        (foreach param QUERY_PARAM
                (when (and (listp param) (greaterp (length param) 0))
                    colName = (car param)
                    (fprintf csvPort "%s%s" sep colName)
                    sep = ","
                )
        )
        (fprintf csvPort "\n")
    )

    ; ---- Step 5: Iterate all symbols ------------------------------------
    symbols = (iterate)
    

    ; ---- Step 6: Close and report ---------------------------------------
    (close csvPort)

    (printf "\n")
    (printf "========================================\n")
    (printf "Scan complete.\n")
    (printf "  Symbols processed:            %d\n" (length allSymbols))
    (printf "  Output file: %s\n" outPath)
    (printf "========================================\n")

    (axlUIConfirm (sprintf nil
      "Done!\n\nSymbols scanned: %d\nOutput file:\n%s"
      (length allSymbols) outPath))

    outPath
  )
)


;======================================================================
; Helper: Get property value from property assoc list (case-insensitive)
;======================================================================
(procedure _getPropValue(propName propList)
  (let ((result nil) (key nil) (keyStr nil) (targetUpper nil))
    targetUpper = (upperCase propName)
    (foreach pair propList
      (when (and (listp pair) (cdr pair))
        key = (car pair)
        (when key
          (cond
            ((symbolp key) keyStr = (upperCase (symbolToString key)))
            ((stringp key) keyStr = (upperCase key)))
          (when (and keyStr (equal keyStr targetUpper))
            result = (cadr pair)))))
    result))

(axlCmdRegister "selfv1" 'main)
(printf "\n")
(printf "========================================\n")
(printf "Type 'selfv1' in the console to run.\n")
(printf "========================================\n")
