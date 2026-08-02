HC_CSV_QUOTE_PATTERN = pcreCompile("\"")

procedure(csv_escape(value)
    let((text needsQuotes)
        if(null(value) then
            text = ""
        else
            if(stringp(value) then
                text = value
            else
                text = sprintf(
                    nil
                    "%L"
                    value
                )
            )
        )

        needsQuotes = strpbrk(
            text
            ",\"\r\n"
        )

        text = pcreReplace(
            HC_CSV_QUOTE_PATTERN
            text
            "\"\""
            0
        )

        if(needsQuotes then
            strcat("\"" text "\"")
        else
            text
        )
    )
)

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
