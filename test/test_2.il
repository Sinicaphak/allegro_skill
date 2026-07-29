procedure(ExportHeightToCSV()
  let((shapes s layer parent refdes propValue count csvPath outPort)
    count = 0
    csvPath = "E:/RjDir/UserData/Desktop/height_check/output/height_data.csv"
    
    axlClearSelSet()
    
    axlSetFindFilter(
      ?enabled '("noall" "shapes")
      ?onButtons '("noall" "shapes")
    )
    
    axlAddSelectAll()
    shapes = axlGetSelSet()
    
    outPort = outfile(csvPath)
    unless(outPort
      printf("ERROR: Cannot open file for writing. Check path: %s\n" csvPath)
      return(nil)
    )
    
    fprintf(outPort "RefDes,Layer,PACKAGE_HEIGHT_MAX\n")
    
    foreach(s shapes
      layer = s->layer
      
      when(or(layer == "PACKAGE GEOMETRY/PLACE_BOUND_TOP"
              layer == "PACKAGE GEOMETRY/PLACE_BOUND_BOTTOM"
              )
        
        parent = s->parent
        refdes = nil
        when(parent
          refdes = parent->refdes
          if(null(refdes) then
            refdes = parent->name
          )
        )
        if(null(refdes) then
          refdes = "NO_PARENT"
        )
        
        ; Try multiple ways to get PACKAGE_HEIGHT_MAX property
        propValue = nil
        
        ; Method 1: Direct property access via arrow
        propValue = s->PACKAGE_HEIGHT_MAX
        
        ; Method 2: Through property list
        when(null(propValue)
          when(s->prop
            propValue = s->prop->PACKAGE_HEIGHT_MAX
          )
        )
        
        ; Method 3: Using get() with symbol
        when(null(propValue)
          when(s->prop
            propValue = get(s->prop 'PACKAGE_HEIGHT_MAX)
          )
        )
        
        if(null(propValue) then
          propValue = "N/A"
        )
        
        fprintf(outPort "%s,%s,%s\n" refdes layer propValue)
        count++
      )
    )
    
    close(outPort)
    
    printf("CSV exported: %s\n" csvPath)
    printf("Total records: %d\n\n" count)
    
    axlClearSelSet()
  )
)

ExportHeightToCSV()