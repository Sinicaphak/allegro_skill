procedure(iterate(allSymbols csvPort)
    let((
        (sep "")
        (value "")
        param
        callback
        sym
    )
        foreach(sym allSymbols
            sep = ""

            ; 严格按照 QUERY_PARAM 的声明顺序执行
            foreach(param QUERY_PARAM
                callback = cadr(param)
                value = funcall(
                    callback
                    sym
                )

                value = csv_escape(value)

                fprintf(
                    csvPort
                    "%s%s"
                    sep
                    value
                )

                sep = ","
            )

            fprintf(csvPort "\n")
        )
    )
)
