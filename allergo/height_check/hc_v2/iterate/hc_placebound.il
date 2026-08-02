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

procedure(iterate_mount_side(sym)
    if(sym->isMirrored then
        "0"
    else
        "1"
    )
)

procedure(iterate_installed_placebound_top(sym)
    if(sym->isMirrored then
        ""
    else
        iterate_placebound_top(sym)
    )
)

procedure(iterate_installed_placebound_bottom(sym)
    if(sym->isMirrored then
        iterate_placebound_bottom(sym)
    else
        ""
    )
)
