; ============================================================================
; Export all Allegro components to an Excel-compatible CSV file.
; Target: Cadence Allegro PCB Editor 17.2
;
; 17.2 database fields used:
;   axlDBGetDesign()->components
;   component->name        : reference designator
;   component->deviceType  : device type / component name
;   component->package     : package name
;   component->class       : component classification
;   component->symbol      : placed symbol dbid, or nil when unplaced
;   component->compdef     : component definition containing PART_NUMBER
;   symbol->definition     : package symbol definition
;   symdef->children       : package geometry figures
;
; Properties read with axlDBGetProperties:
;   component definition   : PART_NUMBER
;   placebound figure      : PACKAGE_HEIGHT_MAX
;
; Registered Allegro command:
;   rj_export_components
; ============================================================================

rjEC_quotePattern = if(
  isCallable('pcreCompile)
then
  pcreCompile("\"")
else
  nil
)


procedure(rjEC_csvField(value)
  let((text)
    text = rjEC_valueText(value)

    ; CSV represents a quote inside a quoted field as two quotes.
    if(rjEC_quotePattern && isCallable('pcreReplace) then
      text = pcreReplace(rjEC_quotePattern text "\"\"" 0)
    )

    strcat("\"" text "\"")
  )
)


procedure(rjEC_valueText(value)
  if(null(value) then
    ""
  else
    if(stringp(value) then
      value
    else
      sprintf(nil "%L" value)
    )
  )
)


procedure(rjEC_getPropertyValue(dbid propName)
  let((properties pair)
    if(null(dbid) then
      ""
    else
      properties = axlDBGetProperties(dbid)
      pair = assoc(propName properties)

      if(null(pair) then
        ""
      else
        if(null(cadr(pair)) then "" else cadr(pair))
      )
    )
  )
)


procedure(rjEC_stringEndsWith(text suffix)
  let((index)
    if(!(stringp(text) && stringp(suffix)) then
      nil
    else
      index = nindex(text suffix)
      if(index then
        index + strlen(suffix) - 1 == strlen(text)
      else
        nil
      )
    )
  )
)


procedure(rjEC_placeBoundSide(figure)
  let((layerName)
    if(null(figure) || null(figure->layer) then
      nil
    else
      layerName = upperCase(rjEC_valueText(figure->layer))

      cond(
        (rjEC_stringEndsWith(layerName "PLACE_BOUND_TOP") "TOP")
        (rjEC_stringEndsWith(layerName "PLACE_BOUND_BOTTOM") "BOTTOM")
        (t nil)
      )
    )
  )
)


procedure(rjEC_scanPlaceBounds(figures)
  let((topCount bottomCount topValues bottomValues side height)
    topCount = 0
    bottomCount = 0
    topValues = nil
    bottomValues = nil

    foreach(figure figures
      side = rjEC_placeBoundSide(figure)

      when(side
        height = rjEC_getPropertyValue(figure 'PACKAGE_HEIGHT_MAX)

        if(equal(side "TOP") then
          topCount = topCount + 1
          unless(equal(height "")
            unless(member(height topValues)
              topValues = cons(height topValues)
            )
          )
        else
          bottomCount = bottomCount + 1
          unless(equal(height "")
            unless(member(height bottomValues)
              bottomValues = cons(height bottomValues)
            )
          )
        )
      )
    )

    list(topCount reverse(topValues) bottomCount reverse(bottomValues))
  )
)


procedure(rjEC_mergeUnique(values1 values2)
  let((result)
    result = copy(values1)
    foreach(value values2
      unless(member(value result)
        result = append1(result value)
      )
    )
    result
  )
)


procedure(rjEC_joinValues(values)
  let((text valueText)
    text = ""

    foreach(value values
      valueText = rjEC_valueText(value)
      if(equal(text "") then
        text = valueText
      else
        text = strcat(text "; " valueText)
      )
    )

    text
  )
)


procedure(rjEC_findPackageSymdef(design packageName)
  let((found)
    found = nil

    when(design && packageName
      foreach(symdef design->symdefs
        when(
          null(found)
          && equal(symdef->name packageName)
          && equal(upperCase(symdef->type) "PACKAGE")
          found = symdef
        )
      )
    )

    found
  )
)


procedure(rjEC_getPlaceBoundData(comp design)
  let(
    (
      sym
      symdef
      instanceData
      definitionData
      topCount
      bottomCount
      topValues
      bottomValues
    )

    sym = comp->symbol
    if(sym then
      symdef = sym->definition
      instanceData = rjEC_scanPlaceBounds(sym->children)
    else
      symdef = rjEC_findPackageSymdef(design comp->package)
      instanceData = list(0 nil 0 nil)
    )

    if(symdef then
      definitionData = rjEC_scanPlaceBounds(symdef->children)
    else
      definitionData = list(0 nil 0 nil)
    )

    ; Instance and definition can expose the same placebound. Use the larger
    ; count instead of summing, and de-duplicate height values.
    topCount = max(car(instanceData) car(definitionData))
    bottomCount = max(caddr(instanceData) caddr(definitionData))
    topValues = rjEC_mergeUnique(cadr(instanceData) cadr(definitionData))
    bottomValues = rjEC_mergeUnique(cadddr(instanceData) cadddr(definitionData))

    list(
      topCount
      rjEC_joinValues(topValues)
      bottomCount
      rjEC_joinValues(bottomValues)
    )
  )
)


procedure(rjEC_getMountedHeight(sym placeBoundData)
  let((topHeight bottomHeight)
    topHeight = cadr(placeBoundData)
    bottomHeight = cadddr(placeBoundData)

    if(sym then
      if(sym->isMirrored then
        if(!equal(bottomHeight "") then
          list(bottomHeight "PLACE_BOUND_BOTTOM")
        else
          list("" "")
        )
      else
        if(!equal(topHeight "") then
          list(topHeight "PLACE_BOUND_TOP")
        else
          list("" "")
        )
      )
    else
      list("" "")
    )
  )
)


procedure(rjEC_makeRow(comp design)
  let((sym xy partNumber placeBoundData mountedHeight boardSide)
    sym = comp->symbol
    partNumber = rjEC_getPropertyValue(comp->compdef 'PART_NUMBER)
    placeBoundData = rjEC_getPlaceBoundData(comp design)
    mountedHeight = rjEC_getMountedHeight(sym placeBoundData)

    if(sym then
      xy = sym->xy
      boardSide = if(sym->isMirrored then "BOTTOM" else "TOP")
      list(
        comp->name
        comp->deviceType
        partNumber
        car(mountedHeight)
        cadr(mountedHeight)
        comp->package
        comp->class
        "YES"
        boardSide
        sym->name
        car(xy)
        cadr(xy)
        sym->rotation
        if(sym->isMirrored then "YES" else "NO")
        car(placeBoundData)
        cadr(placeBoundData)
        caddr(placeBoundData)
        cadddr(placeBoundData)
      )
    else
      list(
        comp->name
        comp->deviceType
        partNumber
        car(mountedHeight)
        cadr(mountedHeight)
        comp->package
        comp->class
        "NO"
        "UNPLACED"
        ""
        ""
        ""
        ""
        ""
        car(placeBoundData)
        cadr(placeBoundData)
        caddr(placeBoundData)
        cadddr(placeBoundData)
      )
    )
  )
)


procedure(rjEC_writeCsv(fileName rows)
  let((port writeOk firstField)
    port = outfile(fileName)

    if(null(port) then
      nil
    else
      writeOk = nil

      unwindProtect(
        progn(
          fprintf(
            port
            "\"RefDes\",\"DeviceType\",\"PartNumber\",\"PackageHeightMax\",\"PackageHeightSource\",\"Package\",\"Class\",\"Placed\",\"BoardSide\",\"SymbolName\",\"X\",\"Y\",\"Rotation\",\"Mirrored\",\"PlaceBoundTopCount\",\"PlaceBoundTopPackageHeightMax\",\"PlaceBoundBottomCount\",\"PlaceBoundBottomPackageHeightMax\"\n"
          )

          foreach(row rows
            firstField = t

            foreach(field row
              if(firstField then
                firstField = nil
              else
                fprintf(port ",")
              )
              fprintf(port "%s" rjEC_csvField(field))
            )

            fprintf(port "\n")
          )

          writeOk = drain(port)
        )
        close(port)
      )

      writeOk
    )
  )
)


procedure(rjExportComponents()
  let((design components rows fileName writeOk)
    design = axlDBGetDesign()

    if(null(design) then
      axlMsgPut("Component export: no Allegro design is open.")
      nil
    else
      components = design->components

      if(null(components) then
        axlMsgPut("Component export: this design contains no components.")
        nil
      else
        fileName = axlDMFileBrowse(
          nil
          t
          ?defaultName "component_list.csv"
          ?title "Export All Components to CSV"
          ?optFilters "CSV files (*.csv)|*.csv|"
        )

        if(null(fileName) then
          axlMsgPut("Component export cancelled.")
          nil
        else
          rows = nil

          foreach(comp components
            rows = cons(rjEC_makeRow(comp design) rows)
          )

          ; Sort by reference designator, which is the first item in each row.
          rows = sortcar(rows 'alphalessp)
          writeOk = rjEC_writeCsv(fileName rows)

          if(writeOk then
            axlMsgPut(
              "Component export: wrote %d component(s) to %s."
              length(rows)
              fileName
            )
            t
          else
            axlMsgPut("Component export: failed to write %s." fileName)
            nil
          )
        )
      )
    )
  )
)


if(isCallable('axlCmdRegister) then
  if(
    axlCmdRegister(
      "rj_export_components"
      'rjExportComponents
      ?cmdType "general"
    )
  then
    printf("Loaded command: rj_export_components\n")
  else
    printf("Warning: could not register command rj_export_components\n")
  )
else
  printf("This file must be loaded inside Allegro PCB Editor.\n")
)
