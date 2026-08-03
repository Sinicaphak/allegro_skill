; 普通字段查询

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
