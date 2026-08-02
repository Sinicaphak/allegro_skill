; Helper: Get property value from property assoc list (case-insensitive)
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
