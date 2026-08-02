procedure(HC_main()
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
                ; Write CSV header from QUERY_PARAM
                foreach(param QUERY_PARAM
                    when(listp(param) && greaterp(length(param) 0)
                        colName = csv_escape(car(param))
                        fprintf(csvPort "%s%s" sep colName)
                        sep = ","
                    )
                )
                fprintf(csvPort "\n")

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
