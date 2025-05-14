;=================================================================================================
; create blank array for use when something may be/is wrong.
;
undef("create_empty_array")
function create_empty_array(yS:numeric,yE:numeric,mS:numeric,mE:numeric,opttype:string)
local yS,yE,mS,mE,opttype
begin
  if (ismissing(yS).or.ismissing(yE)) then
     yS = 1
     yE = 50
  end if
  timeT =  yyyymm_time(yS, yE, "integer")
  time = timeT({yS*100+mS:yE*100+mE})
  if (opttype.eq."time_lat_lon") then  
     blankarr = new((/dimsizes(time),90,180/),"float",1.e20)
     blankarr!0 = "time"    ; time coordinate variable assigned below  
     blankarr&time = time
     blankarr!1 = "lat"
     blankarr&lat = fspan(-89,89,90)
     blankarr!2 = "lon"
     blankarr&lon = fspan(0,358,180)
     blankarr&lat@units = "degrees_north"
     blankarr&lon@units = "degrees_east"
  end if
  if (opttype.eq."time_lev_lat") then  
     blankarr = new((/dimsizes(time),41,90/),"float",1.e20)
     blankarr!0 = "time"    ; time coordinate variable assigned below  
     blankarr&time = time
     blankarr!1 = "lev"
     blankarr&lev =fspan(0,5000,41)
     blankarr!2 = "lat"
     blankarr&lat = fspan(-89,89,90)
     blankarr&lat@units = "degrees_north"
     blankarr&lev@units = "m"
     blankarr&lev@positive = "down"
  end if
  if (opttype.eq."lat_lon") then
     blankarr = new((/90,180/),"float",1.e20)
     blankarr!0 = "lat"
     blankarr&lat = fspan(-89,89,90)
     blankarr!1 = "lon"
     blankarr&lon = fspan(0,358,180)
     blankarr&lat@units = "degrees_north"
     blankarr&lon@units = "degrees_east"
  end if
  blankarr@units = ""
  blankarr@is_all_missing = True
  return(blankarr)
  delete([/yS,yE,mS,mE,opttype,blankarr,timeT,time/])
end
;===================================================================================================
; read in atmospheric/land data from selected files
; assign time coordinate variables, check for issues with the array, assign _FillValue (if needed)
; assign dimension names (for ease-of-use), check and modify units
;
; vname settings at top of this script can be modified if a different variable name is
; encountered. For instance, if a TS data file has the TS array named as "sfc_t", one
; could add "sfc_t" to the vname TS coding as follows:
;   if (vn.eq."TS") then
;      vname = (/"TS","ts","sst","sfc_t"/)
;   end if
;
undef("data_read_in")
function data_read_in(zpath:string,vn:string,yearS:integer,yearE:integer)
; path for file(s), variable name, start year, and end year are read in.
local zpath,vn,cpath0,ta,tfiles,c,arr,farr,yearS,yearE,mocheck,fils_precc,fils_precl,opt
begin
  if (vn.eq."TS") then
     vname = (/"TS","ts","sst","t_surf","skt","tos","SST"/)
  end if
  if (vn.eq."PSL") then
     vname = (/"PSL","psl","slp","SLP","prmsl","msl","slp_dyn"/)
  end if
  if (vn.eq."TREFHT") then
     vname = (/"TREFHT","tas","temp","air","temperature_anomaly","temperature","t2m","t_ref","T2","tempanomaly","tas_mean","trefht"/)
  end if
  if (vn.eq."PRECT") then
     vname = (/"PRECC","PRECL","PRECT","pr","PPT","ppt","p","P","precip","PRECIP","tp","prcp","prate","prect"/)
  end if

  if (ismissing(zpath) ) then
;     print("File missing, creating blank array of data. View "+vn+" namelist for details.")
     arr = create_empty_array(yearS,yearE,1,12,"time_lat_lon")
     sydata = yearS     ; assign these variables based on yearS/yearE provided in namelist. Doesn't matter 
     eydata = yearE     ; as data array is totally missing..  
     smdata = 1
     emdata = 12
  else
     cpath0 = stringtochar(zpath)
     ta = stringtochar("*")
     if (any(cpath0.eq.ta(0)).or.any(cpath0.eq.tochar("{"))) then   ; check for "*" and "{" denoting multiple files
        tfiles = systemfunc("ls "+zpath+" 2> /dev/null")   ; /dev/null suppresses all standard error output
        if (vn.eq."PRECT") then   ; special section for precip, as might need to do PRECC+PRECL
           b = addfile(tfiles(0),"r")   ; check for PRECC
           if (isfilevar(b,"PRECC").or.isfilevar(b,"PRECL")) then  ; PRECC/PRECL section
              fils_precc = str_match(tfiles,"PRECC") 
              fils_precl = str_match(tfiles,"PRECL") 
              if (any(ismissing(fils_precc)).or.any(ismissing(fils_precl))) then
                 print("Fatal: Need both PRECC and PRECL file(s), creating blank array")
                 print(fils_precc)
                 print(fils_precl)
                 arr = create_empty_array(yearS,yearE,1,12,"time_lat_lon")
                 sydata = yearS     ; assign these variables based on yearS/yearE provided in namelist. Doesn't matter 
                 eydata = yearE     ; as data array is totally missing..  
                 smdata = 1
                 emdata = 12
                 print(sydata+" "+eydata)
              else
                 c = addfiles(fils_precc,"r")
                 arr = c[:]->PRECC
                 c2  = addfiles(fils_precl,"r")
                 arr = (/ arr+c2[:]->PRECL  /)
                 arr@long_name = "Large-scale (stable) + convective precipitation rate (liq + ice)"
                 delete(c2)
              end if
              delete([/fils_precc,fils_precl/])            
           else    ; pr, ppt, PPT, PRECT multiple/single file read-in here..
              c = addfiles(tfiles,"r")
              do ii=0,dimsizes(vname)-1
                 if (isfilevar(c[0],vname(ii))) then
                    arr = c[:]->$vname(ii)$
                    break
                 end if
              end do
           end if
           delete(b)
        else
           c = addfiles(tfiles,"r")
           do ii=0,dimsizes(vname)-1
              if (isfilevar(c[0],vname(ii))) then
                 arr = c[:]->$vname(ii)$
                 break
              end if
           end do
        end if     
        nfil = dimsizes(tfiles)
        cpathS = stringtochar(tfiles(0))      ; this section will work for PRECC/PRECL, as it will read the first
        cpathE = stringtochar(tfiles(nfil-1)) ; PRECC file and the last PRECL file.  
        ncharS = dimsizes(cpathS)
        ncharE = dimsizes(cpathE)
        if (.not.isvar("sydata")) then
           sydata = stringtointeger(charactertostring(cpathS(ncharS-17:ncharS-14)))
           smdata = stringtointeger(charactertostring(cpathS(ncharS-13:ncharS-12)))
           eydata = stringtointeger(charactertostring(cpathE(ncharE-10:ncharE-7)))
           emdata = stringtointeger(charactertostring(cpathE(ncharE-6:ncharE-5)))  
        end if
        delete([/cpathS,cpathE,ncharS,ncharE,nfil/])
     else
        c = addfile(zpath,"r")
        do i=0,dimsizes(vname)-1
           if (isfilevar(c,vname(i))) then
              arr = c->$vname(i)$
              break
           end if
        end do
        cpath = stringtochar(zpath)     
        nchar = dimsizes(cpath)
        sydata = stringtointeger(charactertostring(cpath(nchar-17:nchar-14)))
        smdata = stringtointeger(charactertostring(cpath(nchar-13:nchar-12)))
        eydata = stringtointeger(charactertostring(cpath(nchar-10:nchar-7)))
        emdata = stringtointeger(charactertostring(cpath(nchar-6:nchar-5))) 
        delete([/cpath,nchar/])
     end if
     delete([/ta,cpath0/])
  end if
  
  if (isvar("arr").eq.False) then
     print("Variable ("+vn+") not found. Examine input file "+zpath+". Creating empty array and continuing")
     arr = create_empty_array(yearS,yearE,1,12,"time_lat_lon")
  end if

  if (isshort(arr)) then
     arrT = short2flt(arr)
     delete(arr)
     arr = arrT
     delete(arrT)
  end if
  
  if (.not.isatt(arr,"_FillValue")) then     ; assign _FillValue if one is not present
     if (isatt(arr,"missing_value")) then
        arr@_FillValue = arr@missing_value
     else
        arr@_FillValue = default_fillvalue(typeof(arr)) 
     end if
  end if
  
  if (isnan_ieee(arr@_FillValue)) then   ; _FillValue = nan of type double, check data for nans, and alter _FillValue
     value = 1.e20
     replace_ieeenan (arr, value, 0)
     arr@_FillValue = value
  end if
  
  dimz = dimsizes(arr)
  if (any(dimz.eq.1)) then
     arrT = rm_single_dims(arr)
     delete(arr)
     arr = arrT
     delete(arrT)
  end if
  if (dimsizes(dimz).le.2) then
     print("Possible unstructured grid detected. In driver.ncl set regrid_check to True to check all CVDP input data for unstructured data.") 
     print("Input file: "+zpath)
     print("Setting array to all missing")
     delete(arr)
     arr = create_empty_array(yearS,yearE,smdata,emdata,"time_lat_lon")
     sydata = yearS     ; assign these variables based on yearS/yearE provided in namelist. Doesn't matter 
     eydata = yearE     ; as data array is totally missing..  
     smdata = 1
     emdata = 12 
  end if
  delete(dimz)
  
  arr!0 = "time"
  arr!1 = "lat"
  arr!2 = "lon"

  if (isatt(arr&lon,"_FillValue")) then    ; for some unknown reason, NCL may write out a file with _FillValue = 0. for coordinates
     delete(arr&lon@_FillValue)            ; _FillValue not needed for coordinates, so erase them. Seen with CESM2-LENS data.
  end if
  if (isatt(arr&lat,"_FillValue")) then
     delete(arr&lat@_FillValue)
  end if
  
  if (any(abs(arr).ge.1.e20)) then   ; check for inf values or values way out of range, reset to _FillValue.
     print("Values greater than 1.e20 or less than -1.e20 detected in "+zpath+", resetting to _FillValue")
     arr = where(abs(arr).ge.1.e20,arr@_FillValue,arr)
  end if
     
  if (yearS.lt.sydata.or.yearE.gt.eydata) then
     print("Requested "+yearS+"-"+yearE+" time span is outside the input file "+zpath+" time span of "+sydata+"-"+eydata+"")
     print("Setting array to all missing")
     delete(arr)
     arr = create_empty_array(yearS,yearE,smdata,emdata,"time_lat_lon")
     sydata = yearS     ; assign these variables based on yearS/yearE provided in namelist. Doesn't matter 
     eydata = yearE     ; as data array is totally missing..  
     smdata = 1
     emdata = 12          
  else
     timeT =  yyyymm_time(sydata, eydata, "integer")
     time = timeT({sydata*100+smdata:eydata*100+emdata})  
     if (iscoord(arr,"time")) then
        delete(arr&time)
     end if
     dimz = dimsizes(arr)
     if (dimz(0).eq.dimsizes(time)) then
        arr&time = time
     else
        print("Possible mismatch detected between time specified in file name and file variables, setting array to missing")
        print("File = "+zpath)
        print("Read from file name: "+min(time)+"-"+max(time))        
        delete(arr)
        arr = create_empty_array(yearS,yearE,smdata,emdata,"time_lat_lon")
        sydata = yearS     ; assign these variables based on yearS/yearE provided in namelist. Doesn't matter 
        eydata = yearE     ; as data array is totally missing..  
        smdata = 1
        emdata = 12 
     end if
     delete(dimz)
     delete([/time,timeT/])
  end if
  delete([/sydata,smdata,eydata,emdata/])
    
  if (arr&lat(0).ge.0) then
     farr = arr({yearS*100+1:yearE*100+12},::-1,:)   ; flip the latitudes
  else
     farr = arr({yearS*100+1:yearE*100+12},:,:)
  end if
  delete(arr)     
  
  mocheck = (/(yearS*100+1)-min(farr&time),(yearE*100+12) - max(farr&time)/)
  if (any(mocheck.ne.0)) then    ; previously: if (mod(dimsizes(farr&time),12).ne.0) then
     if (mocheck(0).ne.0) then
        print("First requested year is incomplete")
     end if
     if (mocheck(1).ne.0) then
        print("Last requested year is incomplete")
     end if
     print("Incomplete data year(s) requested for file "+zpath+", printing out time and creating blank array")
     print("Time requested: "+yearS+"-"+yearE)
     print(farr&time)
     delete(farr)
     farr = create_empty_array(yearS,yearE,1,12,"time_lat_lon")
  end if
  delete(mocheck)

  if (farr&lon(0).lt.0) then
     farr = lonFlip(farr)     ; lon flip
  end if     
  if (min(farr&lon).lt.0.or.max(farr&lon).gt.360) then
     print(farr&lon)
     print("Fatal: Longitudes in "+zpath+" not in expected 0-360E range, creating blank array")
     delete(farr)
     farr = create_empty_array(yearS,yearE,1,12,"time_lat_lon")
  end if
  
  if (vn.eq."TREFHT".or.vn.eq."TS") then      ; units check
     if (farr@units.eq."K".or.farr@units.eq."Kelvin".or.farr@units.eq."deg_k".or.farr@units.eq."deg_K".or.farr@units.eq."degrees K") then 
        if (max(farr).ge.100) then    ; data sets can be anomalies with units of K, so check for range before subtracting
           farr = farr-273.15
        end if
        farr@units = "C"
     end if
     if (farr@units.eq."degrees_C".or.farr@units.eq."degrees C".or.farr@units.eq."degree_C".or.farr@units.eq."degree C".or.farr@units.eq."degC") then
        farr@units = "C"
     end if
  end if
  if (vn.eq."PSL") then
     if (farr@units.eq."Pa".or.farr@units.eq."Pascals".or.farr@units.eq."Pascal") then
        farr = farr/100.
        farr@units = "hPa"
     end if
     if (farr@units.eq."mb") then
        farr@units = "hPa"
     end if
  end if
  if (vn.eq."PRECT") then    ; convert (if necessary) to mm/day
     if (farr@units.eq."m/s".or.farr@units.eq."m s-1") then
        farr = farr*86400000.
     end if
     if (farr@units.eq."kg m-2 s-1".or.farr@units.eq."kg/m2/s".or.farr@units.eq."kg/m^2/s".or.farr@units.eq."kg/(s*m2)".or.farr@units.eq."mm/s") then
        farr = farr*86400.
     end if
     if (farr@units.eq."m".or.farr@units.eq."m/month".or.farr@units.eq."cm".or.farr@units.eq."cm/month".or.farr@units.eq."mm".or.farr@units.eq."mm/month") then    
        yr = toint(farr&time)/100
        mo = toint(farr&time - (yr*100))
        days = days_in_month(yr,mo)
        do gg = 0,dimsizes(farr&time)-1
           farr(gg,:,:) = (/ farr(gg,:,:) / days(gg) /)
        end do
        if (farr@units.eq."cm".or.farr@units.eq."cm/month") then
           farr = farr*10.   ; convert from cm/day to mm/day
        end if        
        if (farr@units.eq."m".or.farr@units.eq."m/month") then
           farr = farr*1000.   ; convert from m/day to mm/day
        end if   
     end if  
     if (farr@units.eq."m/day".or.farr@units.eq."m day-1") then
        farr = farr*1000.
     end if
     farr@units = "mm/day" 
  end if    
  
  date = farr&time         ; switch time to be CF-conforming
  delete(farr&time)
  yyyy = date/100
  mm = date-(yyyy*100)
  days = (days_in_month(yyyy,mm))/2
  hms  = days
  hms = 0   ; hours, minutes, seconds all the same (=0)
  opt = 0
  opt@return_type = "float"
  time = cd_inv_calendar(yyyy,mm,days,hms,hms,hms,"months since "+min(yyyy)+"-01-15 00:00:00",opt)
  time@long_name = "Time"
  time@standard_name = "time"
  time@actual_range = (/min(time),max(time)/)
  time!0 = "time"
  time&time = time
  farr&time = time
  delete([/time,yyyy,mm,days,hms,date/])
  if (isdouble(farr)) then   ; done to prevent differences from observations resulting in a fatal error when obs #1 is double but other datasets are floats
     farrF = tofloat(farr)
     copy_VarMeta(farr,farrF)
     return(farrF)
  else
     return(farr)
  end if
end
;=================================================================================================
; read in MOC ocean data from given files
;
; assign time coordinate variables, check for issues with the array, assign _FillValue (if needed)
; assign dimension names (for ease-of-use), check and modify units
;
undef("data_read_in_ocean_MOC")
function data_read_in_ocean_MOC(zpath:string,vn:string,yearS:integer,yearE:integer)
; path for MOC file(s), variable name, start year, and end year are read in.
local zpath,vn,cpath0,ta,tfiles,c,arr,farr,yearS,yearE,mocheck,dimC,lev,opt,farrF
begin
  if (vn.eq."MOC") then
     vname = (/"MOC","msftmz","msftmyz","stfmmc","moc"/)
  end if

  if (ismissing(zpath) ) then
;     print("File missing, creating blank array of data. View "+vn+" namelist for details.")
     arr = create_empty_array(yearS,yearE,1,12,"time_lev_lat")
     sydata = yearS     ; assign these variables based on yearS/yearE provided in namelist. Doesn't matter 
     eydata = yearE     ; as data array is totally missing..  
     smdata = 1
     emdata = 12
  else
     cpath0 = stringtochar(zpath)
  
     ta = stringtochar("*")
     if (any(cpath0.eq.ta(0)).or.any(cpath0.eq."{")) then   ; check for "*" and "{" denoting multiple files
        tfiles = systemfunc("ls "+zpath+" 2> /dev/null")   ; /dev/null suppresses all standard error output
        c = addfiles(tfiles,"r")
        do ii=0,dimsizes(vname)-1
           if (isfilevar(c[0],vname(ii))) then
              dimC = filevardimsizes(c[0],"MOC")
              if (vname(ii).eq."MOC") then    ; CCSM/CESM file    
                 if (dimsizes(dimC).eq.5) then
                    if (dimC(2).ge.2) then
                       arr = dim_sum_n_Wrap(c[:]->$vname(ii)$(:,1,:,:,:),1)  ; select Atl+Med+Labrador+GIN sea+Arctic+Hudson Bay transport region and sum over moc_comp
                    else
                       arr = c[:]->$vname(ii)$(:,1,0,:,:)        ; select Atl+Med+Labrador+GIN sea+Arctic+Hudson Bay transport region and the only moc_comp dimension        
                    end if
                 else if (dimsizes(dimC).eq.4) then         ; for high-resolution CESM1/2
                       arr = c[:]->$vname(ii)$(:,:,1,:)        ; select Atl+Med+Labrador+GIN sea+Arctic+Hudson Bay transport region
                    else
                       print("Unknown MOC variable format")
                    end if
                 end if
              else                           ; CMIP file
                 arr = c[:]->$vname(ii)$(:,0,:,:)             ; CMIP file: 0th basin/region = atlantic_ocean (CMIP3) or atlantic_arctic_ocean (CMIP5)         
              end if
              delete(dimC)  
              break
           end if
        end do     
        nfil = dimsizes(tfiles)
        cpathS = stringtochar(tfiles(0))      
        cpathE = stringtochar(tfiles(nfil-1)) 
        ncharS = dimsizes(cpathS)
        ncharE = dimsizes(cpathE)
        sydata = stringtointeger(charactertostring(cpathS(ncharS-17:ncharS-14)))
        smdata = stringtointeger(charactertostring(cpathS(ncharS-13:ncharS-12)))
        eydata = stringtointeger(charactertostring(cpathE(ncharE-10:ncharE-7)))
        emdata = stringtointeger(charactertostring(cpathE(ncharE-6:ncharE-5)))      
        delete([/cpathS,cpathE,ncharS,ncharE,nfil/])
     else
        c = addfile(zpath,"r")
        do i=0,dimsizes(vname)-1
           if (isfilevar(c,vname(i))) then
              dimC = filevardimsizes(c,"MOC")
              if (vname(i).eq."MOC") then    ; CCSM/CESM file                                                                                               
                 if (dimsizes(dimC).eq.5) then                                                                                                              
                    if (dimC(2).ge.2) then                                                                                                                  
                       arr = dim_sum_n_Wrap(c->$vname(i)$(:,1,:,:,:),1)  ; select Atl+Med+Labrador+GIN sea+Arctic+Hudson Bay transport region and sum over moc_comp       
                    else                                                                                                                                    
                       arr = c->$vname(i)$(:,1,0,:,:)        ; select Atl+Med+Labrador+GIN sea+Arctic+Hudson Bay transport region                           
                    end if                                                                                                                                  
                 else if (dimsizes(dimC).eq.4) then          ; for high-resolution CESM1/2                                                                                                        
                       arr = c->$vname(i)$(:,:,1,:)        ; select Atl+Med+Labrador+GIN sea+Arctic+Hudson Bay transport region                                
                    else                                                                                                                                       
                       print("Unknown MOC variable format")                                                                                                     
                    end if                                                                                                                                     
                 end if                                                                                                                                     
              else                           ; CMIP file                                                                                                    
                 arr = c->$vname(i)$(:,0,:,:)             ; CMIP file: 0th basin/region = atlantic_ocean (CMIP3) or atlantic_arctic_ocean (CMIP5)           
              end if   
              delete(dimC)                       
              break
           end if                             
        end do                           
        cpath = stringtochar(zpath)     
        nchar = dimsizes(cpath)
        sydata = stringtointeger(charactertostring(cpath(nchar-17:nchar-14)))
        smdata = stringtointeger(charactertostring(cpath(nchar-13:nchar-12)))
        eydata = stringtointeger(charactertostring(cpath(nchar-10:nchar-7)))
        emdata = stringtointeger(charactertostring(cpath(nchar-6:nchar-5))) 
        delete([/cpath,nchar/])
     end if
     delete([/ta,cpath0/])
  end if

  if (isvar("arr").eq.False) then
     print("Variable ("+vn+") not found. Examine input file "+zpath+". Creating empty array and continuing")
     arr = create_empty_array(yearS,yearE,1,12,"time_lev_lat")
  end if
  if (isshort(arr)) then
     arrT = short2flt(arr)
     delete(arr)
     arr = arrT
     delete(arrT)
  end if
  if (.not.isatt(arr,"_FillValue")) then     ; assign _FillValue if one is not present
     if (isatt(arr,"missing_value")) then
        arr@_FillValue = arr@missing_value
     else
        arr@_FillValue = default_fillvalue(typeof(arr)) 
     end if
  end if
  
  if (isnan_ieee(arr@_FillValue)) then   ; _FillValue = nan of type double, check data for nans, and alter _FillValue
     value = 1.e20
     replace_ieeenan (arr, value, 0)
     arr@_FillValue = value
  end if  
  
  arr!0 = "time"
  arr!1 = "lev"
  arr!2 = "lat"

  if (isatt(arr,"coordinates")) then
     delete(arr@coordinates)
  end if
  
  if (arr&lev@units.eq."centimeters".or.arr&lev@units.eq."cm") then
     lev = arr&lev
     lev@units = "m"
     lev = lev/100.
     lev&lev = lev
     delete(arr&lev)
     arr&lev = lev
     delete(lev)
  end if
  
  if (arr&lev(2).lt.0) then   ; check for negative levels
     lev = arr&lev
     lev = lev*-1.
     if (any(lev.lt.0)) then
        print("Error detected in MOC level sign conversion")
        print(lev)
     end if
     lev@positive = "down"
     lev&lev = lev
     delete(arr&lev)
     arr&lev = lev
     delete(lev)
  end if
  
  if (any(abs(arr).ge.1.e20)) then   ; check for inf values or values way out of range, reset to _FillValue.
     print("Values greater than 1.e20 or less than -1.e20 detected in "+zpath+", resetting to _FillValue")
     arr = where(abs(arr).ge.1.e20,arr@_FillValue,arr)
  end if
     
  if (yearS.lt.sydata.or.yearE.gt.eydata) then
     print("Requested "+yearS+"-"+yearE+" time span is outside the input file "+zpath+" time span of "+sydata+"-"+eydata+"")
     print("Setting array to all missing")
     delete(arr)
     arr = create_empty_array(yearS,yearE,smdata,emdata,"time_lev_lat")
     sydata = yearS     ; assign these variables based on yearS/yearE provided in namelist. Doesn't matter 
     eydata = yearE     ; as data array is totally missing..  
     smdata = 1
     emdata = 12          
  else
     timeT =  yyyymm_time(sydata, eydata, "integer")
     time = timeT({sydata*100+smdata:eydata*100+emdata})  
     if (iscoord(arr,"time")) then
        delete(arr&time)
     end if
     dimz = dimsizes(arr)
     if (dimz(0).eq.dimsizes(time)) then
        arr&time = time
     else
        print("Possible mismatch detected between time specified in file name and file variables, setting array to missing")
        print("File = "+zpath)
        print("Read from file name: "+min(time)+"-"+max(time))        
        delete(arr)
        arr = create_empty_array(yearS,yearE,smdata,emdata,"time_lev_lat")
        sydata = yearS     ; assign these variables based on yearS/yearE provided in namelist. Doesn't matter 
        eydata = yearE     ; as data array is totally missing..  
        smdata = 1
        emdata = 12 
     end if
     delete(dimz)
     delete([/time,timeT/])
  end if
  delete([/sydata,smdata,eydata,emdata/])
    
  if (arr&lat(0).ge.0) then
     farr = arr({yearS*100+1:yearE*100+12},:,::-1)   ; flip the latitudes
  else
     farr = arr({yearS*100+1:yearE*100+12},:,:)
  end if
  delete(arr)     
  
  mocheck = (/(yearS*100+1)-min(farr&time),(yearE*100+12) - max(farr&time)/)
  if (any(mocheck.ne.0)) then    ; previously: if (mod(dimsizes(farr&time),12).ne.0) then
     if (mocheck(0).ne.0) then
        print("First requested year is incomplete")
     end if
     if (mocheck(1).ne.0) then
        print("Last requested year is incomplete")
     end if
     print("Incomplete data year(s) requested for file "+zpath+", printing out time and creating blank array")
     print("Time requested: "+yearS+"-"+yearE)
     print(farr&time)
     delete(farr)
     farr = create_empty_array(yearS,yearE,1,12,"time_lev_lat")
  end if
  delete(mocheck)
  
  ; check units for MOC array. CMIP5 = "kg s-1"  CMIP3 = "m3 s-1" CCSM3 = "Sverdrups" CCSM4 = "Sverdrups"

  if (farr@units.eq."Sverdrups") then
     farr@units = "Sv"
  end if
  if (farr@units.eq."kg s-1".or.farr@units.eq."KG S-1".or.farr@units.eq."kg/s".or.farr@units.eq."KG/S") then     ; 1 Sv = 1.e9 kg/s
     farr = (/ farr/1.e9 /)
     farr@units = "Sv"
  end if
  if (farr@units.eq."m3 s-1".or.farr@units.eq."M3 S-1".or.farr@units.eq."m3/s".or.farr@units.eq."M3/S") then     ; 1 Sv = 1.e6 m3/s
     farr = (/ farr/1.e6 /)
     farr@units = "Sv"
  end if
  
  date = farr&time         ; switch time to be CF-conforming
  delete(farr&time)
  yyyy = date/100
  mm = date-(yyyy*100)
  days = (days_in_month(yyyy,mm))/2
  hms  = days
  hms = 0   ; hours, minutes, seconds all the same (=0)
  opt = 0
  opt@return_type = "float"
  time = cd_inv_calendar(yyyy,mm,days,hms,hms,hms,"months since "+min(yyyy)+"-01-15 00:00:00",opt)
  time@long_name = "Time"
  time@standard_name = "time"
  time!0 = "time"
  time&time = time
  farr&time = time
  delete([/time,yyyy,mm,days,hms,date/])
  
  if (isdouble(farr)) then   ; done to prevent differences from observations resulting in a fatal error when obs #1 is double but other datasets are floats
     farrF = tofloat(farr)
     copy_VarMeta(farr,farrF)
     return(farrF)
  else
     return(farr)
  end if
end
;=================================================================================================
; read in ocean 3D data (time, nlat, nlon) from given files
;
; assign time coordinate variables, check for issues with the array, assign _FillValue (if needed)
; assign dimension names (for ease-of-use), check and modify units
;
undef("data_read_in_ocean")
function data_read_in_ocean(zpath:string,vn:string,yearS:integer,yearE:integer)
; path for ice file(s), variable name, start year, and end year are read in.
local zpath,vn,cpath0,ta,tfiles,c,arr,farr,yearS,yearE,mocheck,dimC,lev,geolat,geolon
begin
  if (vn.eq."SSH") then
     vname = (/"SSH","zos","ssh"/)
  end if

  if (ismissing(zpath) ) then
     print("File missing, creating blank array of data. View "+vn+" namelist for details.")
     arr = create_empty_array(yearS,yearE,1,12,"time_lat_lon")
     sydata = yearS     ; assign these variables based on yearS/yearE provided in namelist. Doesn't matter 
     eydata = yearE     ; as data array is totally missing..  
     smdata = 1
     emdata = 12
  else
     cpath0 = stringtochar(zpath)
  
     ta = stringtochar("*")
     tfiles = systemfunc("ls "+zpath+" 2> /dev/null")   ; /dev/null suppresses all standard error output
     c = addfiles(tfiles,"r")
     do ii=0,dimsizes(vname)-1
        if (isfilevar(c[0],vname(ii))) then
           if (vname(ii).eq."SSH".or.vname(ii).eq."ssh") then    ; CCSM/CESM file     
              arr = c[:]->$vname(ii)$
              if (isatt(arr,"coordinates")) then
                 strarr = str_split(arr@coordinates," ")
                 if (any(strarr.eq."TLONG")) then    ; CESM POP longitude 2D coordinate
                    dimZ = dimsizes(c[0]->TLONG)
                    if (dimsizes(dimZ).eq.3) then
                       arr@lon2d = c[0]->TLONG(0,:,:)
                    else
                       arr@lon2d = c[0]->TLONG
                    end if
                    delete(dimZ)
                 end if
                 if (any(strarr.eq."TLAT")) then     ; CESM POP latitude 2D coordinate
                    dimZ = dimsizes(c[0]->TLAT)
                    if (dimsizes(dimZ).eq.3) then
                       arr@lat2d = c[0]->TLAT(0,:,:)
                    else
                       arr@lat2d = c[0]->TLAT
                    end if
                    delete(dimZ)
                 end if
                 if (any(strarr.eq."geolon")) then    ; CESM MOM longitude 2D coordinate
                    dimZ = dimsizes(c[0]->geolon)
                    if (dimsizes(dimZ).eq.3) then
                       geolon = c[0]->geolon(0,:,:)
                    else
                       geolon = c[0]->geolon
                    end if
                    geolon@units = "degrees_east"
                    arr@lon2d = geolon
                    delete([/dimZ,geolon/])
                 end if
                 if (any(strarr.eq."geolat")) then     ; CESM MOM latitude 2D coordinate
                    dimZ = dimsizes(c[0]->geolat)
                    if (dimsizes(dimZ).eq.3) then
                       geolat = c[0]->geolat(0,:,:)
                    else
                       geolat = c[0]->geolat
                    end if
                    geolat@units = "degrees_north"
                    arr@lat2d = geolat
                    delete([/dimZ,geolat/])
                 end if
                 delete(strarr)
              end if
              if (isatt(arr,"cell_measures").and.isfilevar(c[0],"tarea")) then    ; if an attribute named cell_measures exists, and tarea is on file(0)
                 if (arr@cell_measures.eq."area: tarea") then
                    arr@area = totype(c[0]->tarea,typeof(arr))      ; in units of m^2
                 end if
              end if
           else                           ; CMIP file
              arr = c[:]->$vname(ii)$
              if (isatt(arr,"coordinates")) then
                 strarr = str_split(arr@coordinates," ")
                 if (any(strarr.eq."lon")) then      ; IPCC longitude 2D coordinate
                    arr@lon2d = c[0]->lon
                 end if
                 if (any(strarr.eq."lat")) then      ; IPCC latitude 2D coordinate
                    arr@lat2d = c[0]->lat
                 end if
                 if (any(strarr.eq."longitude")) then      ; IPCC longitude 2D coordinate
                    arr@lon2d = c[0]->longitude
                 end if
                 if (any(strarr.eq."latitude")) then      ; IPCC latitude 2D coordinate
                    arr@lat2d = c[0]->latitude
                 end if
                 delete(strarr)
              end if  
           end if   
           break
        end if
     end do     
     nfil = dimsizes(tfiles)
     cpathS = stringtochar(tfiles(0))      
     cpathE = stringtochar(tfiles(nfil-1)) 
     ncharS = dimsizes(cpathS)
     ncharE = dimsizes(cpathE)
     sydata = stringtointeger(charactertostring(cpathS(ncharS-17:ncharS-14)))
     smdata = stringtointeger(charactertostring(cpathS(ncharS-13:ncharS-12)))
     eydata = stringtointeger(charactertostring(cpathE(ncharE-10:ncharE-7)))
     emdata = stringtointeger(charactertostring(cpathE(ncharE-6:ncharE-5)))      
     delete([/cpathS,cpathE,ncharS,ncharE,nfil,ta,cpath0/])
  end if

  if (isvar("arr").eq.False) then
     print("Variable ("+vn+") not found. Examine input file "+zpath+". Creating empty array and continuing")
     arr = create_empty_array(yearS,yearE,1,12,"time_lat_lon")
  end if

  if (isshort(arr)) then
     arrT = short2flt(arr)
     delete(arr)
     arr = arrT
     delete(arrT)
  end if
  if (.not.isatt(arr,"_FillValue")) then     ; assign _FillValue if one is not present
     if (isatt(arr,"missing_value")) then
        arr@_FillValue = arr@missing_value
     else
        arr@_FillValue = default_fillvalue(typeof(arr)) 
     end if
  end if

  dimz = dimsizes(arr)
  if (dimsizes(dimz).le.2) then
     print("Possible curvilinear (or unstructured) grid detected. Please set regrid_check=True and set regrid_to_res and regrid_dir paths in driver.ncl.") 
     print("Input file: "+zpath)
     print("Setting array to all missing")
     delete(arr)
     arr = create_empty_array(yearS,yearE,smdata,emdata,"time_lat_lon")
     sydata = yearS     ; assign these variables based on yearS/yearE provided in namelist. Doesn't matter 
     eydata = yearE     ; as data array is totally missing..  
     smdata = 1
     emdata = 12 
  end if

  if (any(dimz.eq.1)) then   ; remove single dimensions (if necessary)
     tarr = rm_single_dims(arr)
     delete(arr)
     arr = tarr
     delete(tarr)
  end if
  delete(dimz)

  arr!0 = "time"
  arr!1 = "nlat"
  arr!2 = "nlon"

  if (.not.isatt(arr,"lat2d")) then     ; if latitudes are 1D, make sure latitudes run from south to north +
     if (arr&nlat(0).ge.0) then           
        tarr = arr(:,::-1,:)
        delete(arr)
        arr = tarr
        delete(tarr)
     end if
  end if
     
  if (yearS.lt.sydata.or.yearE.gt.eydata) then
     print("Requested "+yearS+"-"+yearE+" time span is outside the input file "+zpath+" time span of "+sydata+"-"+eydata+"")
     print("Setting array to all missing")
     delete(arr)
     arr = create_empty_array(yearS,yearE,smdata,emdata,"time_lat_lon")
     sydata = yearS     ; assign these variables based on yearS/yearE provided in namelist. Doesn't matter 
     eydata = yearE     ; as data array is totally missing..  
     smdata = 1
     emdata = 12          
  else
     timeT =  yyyymm_time(sydata, eydata, "integer")
     time = timeT({sydata*100+smdata:eydata*100+emdata})  
     if (iscoord(arr,"time")) then
        delete(arr&time)
     end if
     dimz = dimsizes(arr)
     if (dimz(0).eq.dimsizes(time)) then
        arr&time = time
     else
        print("Possible mismatch detected between time specified in file name and file variables, setting array to missing")
        print("File = "+zpath)
        print("Read from file name: "+min(time)+"-"+max(time))        
        delete(arr)
        arr = create_empty_array(yearS,yearE,smdata,emdata,"time_lat_lon")
        sydata = yearS     ; assign these variables based on yearS/yearE provided in namelist. Doesn't matter 
        eydata = yearE     ; as data array is totally missing..  
        smdata = 1
        emdata = 12 
     end if
     delete(dimz)
     delete([/time,timeT/])
  end if
  delete([/sydata,smdata,eydata,emdata/])
  farr = arr({yearS*100+1:yearE*100+12},:,:)  
;  printVarSummary(farr)
  delete(arr)     
  
  mocheck = (/(yearS*100+1)-min(farr&time),(yearE*100+12) - max(farr&time)/)
  if (any(mocheck.ne.0)) then    ; previously: if (mod(dimsizes(farr&time),12).ne.0) then
     if (mocheck(0).ne.0) then
        print("First requested year is incomplete")
     end if
     if (mocheck(1).ne.0) then
        print("Last requested year is incomplete")
     end if
     print("Incomplete data year(s) requested for file "+zpath+", printing out time and creating blank array")
     print("Time requested: "+yearS+"-"+yearE)
     print("From file: Times present from "+min(farr&time)+"-"+max(farr&time))
     delete(farr)
     farr = create_empty_array(yearS,yearE,1,12,"time_lat_lon")
  end if
  delete(mocheck)

  if (farr@units.eq."m") then    ; CMIP units
     farr = (/ farr*100. /)
     farr@units = "centimeter"
  end if  
  if (farr@units.eq."centimeter") then   ; done for plot subtitles
     farr@units = "cm"
  end if
  
  date = farr&time         ; switch time to be CF-conforming
  delete(farr&time)
  yyyy = date/100
  mm = date-(yyyy*100)
  days = (days_in_month(yyyy,mm))/2
  hms  = days
  hms = 0   ; hours, minutes, seconds all the same (=0)
  time = cd_inv_calendar(yyyy,mm,days,hms,hms,hms,"months since "+min(yyyy)+"-01-15 00:00:00",0)
  time@long_name = "Time"
  time@standard_name = "time"
  time!0 = "time"
  time&time = time
  farr&time = time
  delete([/time,yyyy,mm,days,hms,date/])

  if (isdouble(farr)) then   ; done to prevent differences from observations resulting in a fatal error when obs #1 is double but other datasets are floats
     farrF = tofloat(farr)
     copy_VarMeta(farr,farrF)
     return(farrF)
  else
     return(farr)
  end if

  return(farr)
end

;=================================================================================================
; read in ice data from given files
;
; assign time coordinate variables, check for issues with the array, assign _FillValue (if needed)
; assign dimension names (for ease-of-use), check and modify units
;
undef("data_read_in_ice")
function data_read_in_ice(zpath:string,vn:string,yearS:integer,yearE:integer)
; path for ice file(s), variable name, start year, and end year are read in.
local zpath,vn,cpath0,ta,tfiles,c,arr,farr,yearS,yearE,mocheck,dimC,lev,opt,farrF
begin
  if (vn.eq."aice_nh") then
     vname = (/"aice_nh","aice","sic","siconc","SIC","CN","ice","icec","SEAICE"/)
  end if
  if (vn.eq."aice_sh") then
     vname = (/"aice_sh","aice","sic","siconc","SIC","CN","ice","icec","SEAICE"/)
  end if

  if (ismissing(zpath) ) then
     arr = create_empty_array(yearS,yearE,1,12,"time_lat_lon")
     sydata = yearS     ; assign these variables based on yearS/yearE provided in namelist. Doesn't matter 
     eydata = yearE     ; as data array is totally missing..  
     smdata = 1
     emdata = 12
  else
     cpath0 = stringtochar(zpath)
  
     ta = stringtochar("*")
     tfiles = systemfunc("ls "+zpath+" 2> /dev/null")   ; /dev/null suppresses all standard error output
     c = addfiles(tfiles,"r")
     do ii=0,dimsizes(vname)-1
        if (isfilevar(c[0],vname(ii))) then
           if (vname(ii).eq."aice_nh".or.vname(ii).eq."aice_sh".or.vname(ii).eq."aice") then    ; CCSM/CESM file     
              arr = c[:]->$vname(ii)$
              if (isatt(arr,"coordinates")) then
                 strarr = str_split(arr@coordinates," ")
                 if (any(strarr.eq."TLON")) then    ; CESM longitude 2D coordinate
                    dimZ = dimsizes(c[0]->TLON)
                    if (dimsizes(dimZ).eq.3) then
                       arr@lon2d = c[0]->TLON(0,:,:)
                    else
                       arr@lon2d = c[0]->TLON
                    end if
                    delete(dimZ)
                 end if
                 if (any(strarr.eq."TLAT")) then     ; CESM latitude 2D coordinate
                    dimZ = dimsizes(c[0]->TLAT)
                    if (dimsizes(dimZ).eq.3) then
                       arr@lat2d = c[0]->TLAT(0,:,:)
                    else
                       arr@lat2d = c[0]->TLAT
                    end if
                    delete(dimZ)
                 end if
                 delete(strarr)
              end if
              if (isatt(arr,"cell_measures").and.isfilevar(c[0],"tarea")) then    ; if an attribute named cell_measures exists, and tarea is on file(0)
                 if (arr@cell_measures.eq."area: tarea") then
                    arr@area = totype(c[0]->tarea,typeof(arr))      ; in units of m^2
                 end if
              end if
           else                           ; CMIP or other non-CESM file
              if (vname(ii).eq."CN") then     ; GFDL file
                 arrT = c[:]->$vname(ii)$
                 arr = dim_sum_n_Wrap(arrT,1)
                 delete(arrT)
                 arr = where(arr.ge.1,1,arr) ; optional
              else
                 arr = c[:]->$vname(ii)$
              end if
              if (isatt(arr,"coordinates")) then    ; 2D latitudes/longitudes are present
                 strarr = str_split(arr@coordinates," ")
                 if (any(strarr.eq."lon")) then      ; IPCC longitude 2D coordinate
                    arr@lon2d = c[0]->lon
                 end if
                 if (any(strarr.eq."lat")) then      ; IPCC latitude 2D coordinate
                    arr@lat2d = c[0]->lat
                 end if
                 if (any(strarr.eq."longitude")) then      ; NSIDC longitude 2D coordinate
                    arr@lon2d = c[0]->longitude
                 end if
                 if (any(strarr.eq."latitude")) then      ; NSIDC latitude 2D coordinate
                    arr@lat2d = c[0]->latitude
                 end if
                 delete(strarr)

                 dir_temp = str_sub_str(tfiles(0),"/sic/","/areacello/")    ; Attempt to find area files
                 dir_temp = str_sub_str(dir_temp,"/siconc/","/areacello/")  ; sic = cmip5, siconc = cmip6
                 dir_temp = str_sub_str(dir_temp,"/OImon/","/fx/")   ; OImon/fx = cmip5
                 dir_temp = str_sub_str(dir_temp,"/SImon/","/Ofx/")  ; SImon/Ofx = cmip6
                 dir_temp_sp = str_split(dir_temp,"/")
                 if (.not.ismissing(str_match_ic_regex(dir_temp_sp,"areacello"))) then   ; must have areacello in file path
                    dir_test = str_match_ic_regex(dir_temp_sp,"^r[0-9]+i[0-9]+p[0-9]+")  ; find the r*i*p* subdirectory
                    if (.not.ismissing(dir_test).and.dimsizes(dir_test).eq.1) then       ; and append r0i0p0 to it (for CMIP5 naming conventions)
                       dir_temp_sp = str_sub_str(dir_temp_sp, dir_test,"{r0i0p0,"+dir_test+"}")
                    end if
                    ufile = systemfunc("ls /"+str_join(dir_temp_sp(:dimsizes(dir_temp_sp)-2),"/")+"/*.nc 2> /dev/null")  ; try to locate areacello file
                    delete([/dir_test/])
                    if (.not.ismissing(ufile)) then
                       d = addfile(ufile,"r")
                       arr@area = totype(d->areacello,typeof(arr))
                       dimQ = dimsizes(arr)
                       if (dimsizes(ndtooned(arr@area)).ne.(dimQ(1)*dimQ(2))) then    ; the dimension sizes of areacello 
                          delete(arr@area)                                  ; do not match sizes of area j,i dimensions 
                       end if
                       delete([/dimQ,ufile/])
                    end if
                 end if
                 delete([/dir_temp,dir_temp_sp/])
              end if  
              if (isfilevar(c[0],"AREA")) then    ; check to see if there is an AREA array present and if so use it
                 areaT = c[0]->AREA
                 if (areaT@units.eq."km^2") then
                    area_unit_km2_to_m2 = True
                    areaT = areaT*1000000.
                    areaT@units = "m^2"
                 end if
                 areaT@_FillValue = 1.e20
                 arr@area = totype(areaT,typeof(arr))
                 if (isatt(areaT,"pole_hole_area")) then    ; format of ystart, yend, value, ystart, yend, value
                    if (isvar("area_unit_km2_to_m2")) then
                       extra_area = tofloat(areaT@pole_hole_area)
                       extra_area(2::3) = extra_area(2::3)*1000000.   ; convert pole hole area from km^2->m^2
                       arr@pole_hole_area = totype(extra_area,typeof(arr))
                       delete(extra_area)
                    else
                       arr@pole_hole_area = totype(areaT@pole_hole_area,typeof(arr))
                    end if
                 end if
                 delete(areaT)
              end if
           end if   
           break
        end if
     end do     
     nfil = dimsizes(tfiles)
     cpathS = stringtochar(tfiles(0))      
     cpathE = stringtochar(tfiles(nfil-1)) 
     ncharS = dimsizes(cpathS)
     ncharE = dimsizes(cpathE)
     sydata = stringtointeger(charactertostring(cpathS(ncharS-17:ncharS-14)))
     smdata = stringtointeger(charactertostring(cpathS(ncharS-13:ncharS-12)))
     eydata = stringtointeger(charactertostring(cpathE(ncharE-10:ncharE-7)))
     emdata = stringtointeger(charactertostring(cpathE(ncharE-6:ncharE-5)))      
     delete([/cpathS,cpathE,ncharS,ncharE,nfil,ta,cpath0/])
  end if

  if (isvar("arr").eq.False) then
     print("Variable ("+vn+") not found. Examine input file "+zpath+". Creating empty array and continuing")
     arr = create_empty_array(yearS,yearE,1,12,"time_lat_lon")
  end if

  if (.not.isatt(arr,"area")) then   ; calculate grid cell areas manually (not implemented)
;     print("Grid cell areas not found.")
  end if

  if (isshort(arr)) then
     arrT = short2flt(arr)
     delete(arr)
     arr = arrT
     delete(arrT)
  end if
  if (.not.isatt(arr,"_FillValue")) then     ; assign _FillValue if one is not present
     if (isatt(arr,"missing_value")) then
        arr@_FillValue = arr@missing_value
     else
        arr@_FillValue = default_fillvalue(typeof(arr)) 
     end if
  end if
  
  if (isnan_ieee(arr@_FillValue)) then   ; _FillValue = nan of type double, check data for nans, and alter _FillValue
     value = 1.e20
     replace_ieeenan (arr, value, 0)
     arr@_FillValue = value
  end if  
  
  arr!0 = "time"
  arr!1 = "j"
  arr!2 = "i"

  if (.not.isatt(arr,"lat2d")) then     ; if latitudes are 1D, make sure latitudes run from south to north +
     if (arr&j(0).ge.0) then            ; calculate area of 1D lat/lon arrays
        tarr = arr(:,::-1,:)
        delete(arr)
        arr = tarr
        delete(tarr)
     end if

     if (min(arr&i).ge.0.and.max(arr&i).le.360) then
        fctr = 111120   ; how many meters per degree of latitude (approximate)
	       pi=4.*atan(1.0)
        rad=(pi/180.)
        lat = tofloat(arr&j)
	       dimlat = dimsizes(lat)
	       latr = new(dimlat,typeof(lat))
	       do gg = 0,dimlat-1
	          if (gg.eq.0) then
		            latr(gg) = abs(-90-(lat(1)+lat(0))/2.)
		         end if
	          if (gg.ge.1.and.gg.lt.dimlat-1) then
	             latr(gg) = abs((lat(gg-1)+lat(gg))/2. - (lat(gg)+lat(gg+1))/2.)
		         end if
		         if (gg.eq.dimlat-1) then
		            latr(gg) = abs(90 - (lat(dimlat-2)+lat(dimlat-1))/2.)
		         end if
	       end do
        lon = tofloat(arr&i)
	       dimlon = dimsizes(lon)
	       lonr = new(dimlon,typeof(lon))
        do gg = 0,dimlon-1
	          if (gg.eq.0) then
		            lonr(gg) = abs( (lon(1)+lon(0))/2. - (((lon(dimlon-1)+(lon(0)+360))/2.)-360) )
		         end if
		         if (gg.ge.1.and.gg.lt.dimlon-1) then
			       	   lonr(gg) = abs((lon(gg)+lon(gg+1))/2. - (lon(gg-1)+lon(gg))/2.)
		         end if
		         if (gg.eq.dimlon-1) then
		            lonr(gg) = abs(((lon(dimlon-1)+(lon(0)+360))/2.) - (lon(gg-1)+lon(gg))/2.)
		         end if		
	       end do
        area = tofloat(arr(0,:,:))
	       area = area@_FillValue
	       area@long_name = "Area of grid box"
	       area@units = "m2"

	       do ff = 0,dimlat-1
	          do gg = 0,dimlon-1
		            area(ff,gg) = (/ (fctr*latr(ff))*(cos(rad*lat(ff))*lonr(gg)*fctr) /)     ; cosine weighting
		         end do
	       end do
;        print("Total area = "+sum(area))
        arr@area = totype(area,"float")
        delete([/lat,lon,latr,lonr,area,fctr,pi,rad,dimlat,dimlon/])		
     end if
  end if

  if (.not.isatt(arr,"is_all_missing")) then    ; erase data in hemisphere not specified via vn
     if (isatt(arr,"lat2d")) then
        tlat2 = conform(arr,arr@lat2d,(/1,2/))
        tlon2 = conform(arr,arr@lon2d,(/1,2/))
        if (vn.eq."aice_nh") then
           arr = where(tlat2.ge.0,arr,arr@_FillValue)
        end if
        if (vn.eq."aice_sh") then
           arr = where(tlat2.lt.0,arr,arr@_FillValue)
        end if
        delete([/tlat2,tlon2/])
     else
        if (vn.eq."aice_nh") then
           arr(:,{:-1.},:) = arr@_FillValue
        end if
        if (vn.eq."aice_sh") then
           arr(:,{0:},:) = arr@_FillValue
        end if
     end if
  end if
     
  if (yearS.lt.sydata.or.yearE.gt.eydata) then
     print("Requested "+yearS+"-"+yearE+" time span is outside the input file "+zpath+" time span of "+sydata+"-"+eydata+"")
     print("Setting array to all missing")
     delete(arr)
     arr = create_empty_array(yearS,yearE,smdata,emdata,"time_lat_lon")
     sydata = yearS     ; assign these variables based on yearS/yearE provided in namelist. Doesn't matter 
     eydata = yearE     ; as data array is totally missing..  
     smdata = 1
     emdata = 12          
  else
     timeT =  yyyymm_time(sydata, eydata, "integer")
     time = timeT({sydata*100+smdata:eydata*100+emdata})  
     if (iscoord(arr,"time")) then
        delete(arr&time)
     end if
     dimz = dimsizes(arr)
     if (dimz(0).eq.dimsizes(time)) then
        arr&time = time
     else
        print("Possible mismatch detected between time specified in file name and file variables, setting array to missing")
        print("File = "+zpath)
        print("Read from file name: "+min(time)+"-"+max(time))        
        delete(arr)
        arr = create_empty_array(yearS,yearE,smdata,emdata,"time_lat_lon")
        sydata = yearS     ; assign these variables based on yearS/yearE provided in namelist. Doesn't matter 
        eydata = yearE     ; as data array is totally missing..  
        smdata = 1
        emdata = 12 
     end if
     delete(dimz)
     delete([/time,timeT/])
  end if
  delete([/sydata,smdata,eydata,emdata/])
  farr = arr({yearS*100+1:yearE*100+12},:,:)  
  delete(arr)     
  
  mocheck = (/(yearS*100+1)-min(farr&time),(yearE*100+12) - max(farr&time)/)
  if (any(mocheck.ne.0)) then    ; previously: if (mod(dimsizes(farr&time),12).ne.0) then
     if (mocheck(0).ne.0) then
        print("First requested year is incomplete")
     end if
     if (mocheck(1).ne.0) then
        print("Last requested year is incomplete")
     end if
     print("Incomplete data year(s) requested for file "+zpath+", printing out time and creating blank array")
     print("Time requested: "+yearS+"-"+yearE)
     print("From file: Times present from "+min(farr&time)+"-"+max(farr&time))
     delete(farr)
     farr = create_empty_array(yearS,yearE,1,12,"time_lat_lon")
  end if
  delete(mocheck)

  if (farr@units.eq."0-1".or.farr@units.eq."1") then    ; GFDL units, NSIDC units
     farr = (/ farr*100. /)
     farr@units = "%"
  end if  
  
  date = farr&time         ; switch time to be CF-conforming
  delete(farr&time)
  yyyy = date/100
  mm = date-(yyyy*100)
  days = (days_in_month(yyyy,mm))/2
  hms  = days
  hms = 0   ; hours, minutes, seconds all the same (=0)
  opt = 0
  opt@return_type = "float"
  time = cd_inv_calendar(yyyy,mm,days,hms,hms,hms,"months since "+min(yyyy)+"-01-15 00:00:00",opt)
  time@long_name = "Time"
  time@standard_name = "time"
  time!0 = "time"
  time&time = time
  farr&time = time
  delete([/time,yyyy,mm,days,hms,date/])
  if (isdouble(farr)) then   ; done to prevent differences from observations resulting in a fatal error when obs #1 is double but other datasets are floats
     farrF = tofloat(farr)
     copy_VarMeta(farr,farrF)
     return(farrF)
  else
     return(farr)
  end if
end
;=================================================================================================
;  alters the formatting of the Y-axis
;
;  not currently used
;
undef("y_axis_check")
function y_axis_check(temparr:numeric,tempres:logical)
local temparr,tempres,minval,maxval
begin
  minval = min(temparr)
  maxval = max(temparr)
  if (minval.gt.-1.and.minval.lt.0.and.maxval.lt.1.and.maxval.gt.0) then
     tempres@tmYLFormat = "0@;*.2f"
  else
     tempres@tmYLFormat = "0@*+^sg"
  end if
  return(tempres)
  delete([/tempres,temparr,minval,maxval/])
end
;==================================================================================================
; In version 6.2.1 the behavior of isfilepresent switched, where only files readable by NCL return
; True. Previously if a file (or directory) simply existed, isfilepresent would return True. A new
; function has been created in v6.2.1, fileexists, that acts like the previous version of isfilepresent
; did. To compensate for this, check the NCL version number, and use isfilepresent/fileexists when 
; appropriate.
;
undef("isfilepresent2")
function isfilepresent2(fdpres:string)
local nclver, num0, num1, ra
begin
  nclver = stringtochar(get_ncl_version())
  
  num0 = toint(tostring(nclver(0)))
  num1 = toint(tostring(nclver(2)))
  num2 = toint(tostring(nclver(4)))
  if (num0.le.5) then
     ra = isfilepresent(fdpres)
  end if
  if (num0.eq.6) then
     if (num1.le.1) then
        ra = isfilepresent(fdpres)
     end if
     if (num1.eq.2) then
        if (num2.eq.0) then
           ra = isfilepresent(fdpres)
        else
           ra = fileexists(fdpres)
        end if
     end if
     if (num1.ge.3) then
        ra = fileexists(fdpres)
     end if
  end if  
  if (num0.ge.7) then
     ra = fileexists(fdpres)
  end if
  return(ra)
  delete([/nclver,num0,num1,ra/])
end
;================================================================================================
; Create direct links for website
;
undef("table_link_setup")
function table_link_setup(ipath:string,iname:string,ltxt:string)
; image name, along with link text
local ipath, iname, ltxt, otxt, quote
begin
  quote = str_get_dq()
  if (isfilepresent2(ipath+iname)) then
     otxt = "<a href="+quote+iname+quote+">"+ltxt+"</a>" 
  else
     otxt = ltxt
  end if
  return(otxt)
  delete([/ipath,iname,ltxt,otxt,quote/])
end

;=================================================================================================
; Create expanding/contracting links for website
;
undef("table_link_setup_le")
function table_link_setup_le(ipath:string,iname:string,ltxt:string)
; image name, along with link text
local ipath, iname, ltxt, otxt, quote
begin
  quote = str_get_dq()
  if (isfilepresent2(ipath+iname)) then
     otxt = "<a href="+quote+iname+quote+" class="+quote+"badge badge-info"+quote+">"+ltxt+"</a>" 
  else
     otxt = ltxt
  end if
  return(otxt)
  delete([/ipath,iname,ltxt,otxt,quote/])
end
;=================================================================================================
undef ("gsn_panel2")
procedure gsn_panel2(wksp:graphic,plotp:graphic,lpl:numeric,panelres:logical)
; checks to make sure at least one image is present in plot before paneling,
; thereby eliminating this possible error message: 
; Error: gsn_panel: all of the plots passed to gsn_panel appear to be invalid

local wksp, plotp, lpl, panelres
begin
  if (.not.all(ismissing(plotp))) then
     gsn_panel(wksp,plotp,lpl,panelres)
  end if  
end
;=================================================================================================
undef ("eofunc_north2")
function eofunc_north2(eval[*]:numeric, N[1]:integer, prinfo[1]:logical)
;
; North, G.R. et al (1982): Sampling Errors in the Estimation of Empirical Orthogonal Functions.
; Mon. Wea. Rev., 110, 699–706.
; doi: http://dx.doi.org/10.1175/1520-0493(1982)110<0699:SEITEO>2.0.CO;2
;
; Usage after 'eofunc'. Here ntim was used,  
;             prinfo = True
;             sig    = eval_north(eof@eval, ntim, prinfo)
;
; Copied directly from v6.3.0 contributed.ncl for use in the package regardless of NCL version.
;
local neval, dlam, low, high, sig, n
begin
  neval   = dimsizes(eval)
  if (neval.eq.1)
      print("eofunc_north: neval=1, no testing can be performed")
      sig = True 
      sig@long_name = "EOF separation is not testable N=1"
      sig@N         =  N
      return(sig)
  end if

  dlam    = eval * sqrt(2.0/N)   ; eq 24
  low     = eval-dlam
  high    = eval+dlam

  sig     = new(dimsizes(eval), logical)
  sig = False  ; default is not significantly separated

; first and last eigenvalues are special cases

  if (eval(0).gt.high(1)) then
      sig(0) = True
  end if
  if (eval(neval-1).lt.low(neval-2)) then
      sig(neval-1) = True
  end if

; loop over other eignvalues

  if (N.gt.2) then
      do n=1,neval-2
         if (eval(n).lt.low(n-1) .and. eval(n).gt.high(n+1)) then
             sig(n) = True
         end if
      end do
  end if

  if (prinfo) then
      print(dlam+"   "+low+"   "+eval+"   "+high+"  "+sig)
  end if

  sig@long_name = "EOF separation"
  sig@N         =  N
  return(sig)
end
;=================================================================================================
; Standardize and set attributes for array. Remove NCL-added and superfluous attributes, 
; set missing_value equal to _FillValue, provide options to set long_name, units, and comment_cvdp 
; attributes. For last three inputs "" means leave as set and "delete" means delete the attribute.
; This function will be used immediately prior to an array being written to a netCDF file.
;
undef("set_varAtts")
function set_varAtts(zarr:numeric,loname:string,uni:string,com_cvdp:string)

local zarr,loname,uni,com_cvdp
begin
  if (isatt(zarr,"actual_range")) then
     delete(zarr@actual_range)
  end if
  if (isatt(zarr,"anomaly_op_ncl")) then
     delete(zarr@anomaly_op_ncl)
  end if
  if (isatt(zarr,"average_op_ncl")) then
     delete(zarr@average_op_ncl)
  end if
  if (isatt(zarr,"cell_measures")) then
     delete(zarr@cell_measures)
  end if
  if (isatt(zarr,"cell_methods")) then
     delete(zarr@cell_methods)
  end if
  if (isatt(zarr,"coi")) then
     delete(zarr@coi)
  end if
  if (isatt(zarr,"lonFlip")) then
     delete(zarr@lonFlip)
  end if
  if (isatt(zarr,"nptxy")) then
     delete(zarr@nptxy)
  end if
  if (isatt(zarr,"rstd")) then
     delete(zarr@rstd)
  end if
  if (isatt(zarr,"runave_op_ncl")) then
     delete(zarr@runave_op_ncl)
  end if
  if (isatt(zarr,"standardize_op_ncl")) then
     delete(zarr@standardize_op_ncl)
  end if
  if (isatt(zarr,"stddev_op_ncl")) then
     delete(zarr@stddev_op_ncl)
  end if
  if (isatt(zarr,"sum_op_ncl")) then
     delete(zarr@sum_op_ncl)
  end if
  if (isatt(zarr,"time")) then
     delete(zarr@time)
  end if
  if (isatt(zarr,"tval")) then
     delete(zarr@tval)
  end if
  if (isatt(zarr,"wgt_areaave_op_ncl")) then
     delete(zarr@wgt_areaave_op_ncl)
  end if
  if (isatt(zarr,"wgt_runave_op_ncl")) then
     delete(zarr@wgt_runave_op_ncl)
  end if
  if (isatt(zarr,"yintercept")) then
     delete(zarr@yintercept)
  end if
  if (isatt(zarr,"_FillValue")) then      ; set missing_value = _FillValue
     if (isatt(zarr,"missing_value")) then
        delete(zarr@missing_value)
     end if
     zarr@missing_value = zarr@_FillValue
  end if
  
  if (loname.eq."delete") then
     delete(zarr@long_name)
  else
     if (loname.ne."") then    ; "" = leave as is
        zarr@long_name = loname
     end if
  end if
  if (uni.eq."delete") then
     delete(zarr@units)
  else
     if (uni.ne."") then    ; "" = leave as is
        zarr@units = uni
     end if
  end if
  if (com_cvdp.eq."delete") then
     delete(zarr@comment_cvdp)
  else
     if (com_cvdp.ne."") then    ; "" = leave as is
        zarr@comment_cvdp = com_cvdp
     end if
  end if
  return(zarr)
end
;=================================================================================================
; Area (approximate) of a global rectilinear grid cells.
; This could be modified for non-global grids by adding
;     the left and right and left dx.
; D. Shea
;
undef("area_global_rectilinear_grid")
function area_global_rectilinear_grid (lat[*]:numeric, lon[*], opt[1]:logical)

local rearth, nlat, mlon, pi, rad, rr, dlon, dx, dy
    , area_lat, area_grid, area_total, area_sphere  
begin
  rearth = 6371.220d0            ; default; meters
  if (opt .and. isatt(opt, "rearth")) then
      rearth = opt@rearth 
  end if

  nlat   = dimsizes(lat)
  mlon   = dimsizes(lon)

  pi     = 4d0*atan(1.0d0)
  rad    = pi/180d0
  rr     = rearth*rad
  dlon   = rr*(lon(2)-lon(1))

  dx     = dlon*cos(lat*rad)   ; lon spacing at each latitude

  if (lat(0).lt.-89.9999d0) then ; force exact 0.0, rounding issue
      dx(0)  = 0.0d0
  end if
  if (lat(nlat-1).gt.89.9999d0) then
      dx(nlat-1)  = 0.0d0
  end if
                               ; lat can have variable spacing
  dy           = new (nlat, "double", "No_FillValue")
  dy(0)        = (lat(1)-lat(0))*rr
  dy(1:nlat-2) = (lat(2:)-lat(1:nlat-2))*rr
  dy(nlat-1)   = (lat(nlat-1)-lat(nlat-2))*rr

  area_lat      = dx*dy        ; [*]
  area_grid     = conform_dims( (/nlat,mlon/), area_lat, 0)
  area_total    = sum( area_grid )

  area_sphere   = 4d0*pi*rearth^2

  area_grid@long_name  = "area of each grid cell"
  area_grid@units      = "km^2"
  area_grid@area_total = area_total      ; scalar
  area_grid@area_lat   = area_lat        ; [*]
  area_grid@rearth     = rearth          ; scalar
  area_grid@area_sphere= area_sphere     ; scalar
  area_grid@area_ratio = area_total/area_sphere    ; scalar

  area_grid!0   = "lat"
  area_grid!1   = "lon"
  area_grid&lat =  lat
  area_grid&lon =  lon

  return(area_grid)
end
;=================================================================================================
; (Deprecated) This function creates and draws a labelbar based on a given 
; contour plot.   Only called from aice_*.mean_stddev.ncl scripts. Other scripts call
; summary_lb_flag, which employs simpler/better coding to determine when to turn on
; the labelbars.
;
undef("create_summary_labelbar")
function create_summary_labelbar(wks,plot)
local colors, levels, labels, nboxes,plot
begin
  getvalues plot@contour
    "cnLevels"     : levels
    "cnFillColors" : colors
  end getvalues
  nboxes = dimsizes(colors)
  labels                   = ""+levels    ; labels for the labelbar

  lbres                    = True
;  lbres@vpXF               = 0.5         ; Position labelbar at         
;  lbres@vpYF               = 0.1         ; bottom center of frame.
  lbres@vpWidthF           = 0.55
  lbres@vpHeightF          = 0.075

  lbres@lbPerimOn          = False            ; Turn off perimeter.
  lbres@lbOrientation      = "Horizontal"     ; Default is vertical.
  lbres@lbFillColors       = colors
  lbres@lbMonoFillPattern  = True             ; Fill them all solid.
  lbres@lbLabelFontHeightF = 0.020            ; Label font height
  lbres@lbLabelAlignment   = "InteriorEdges"
  lbres@lbBoxLineColor = "gray70"

  if (levels(3).eq.20.and.levels(4).eq.80) then   ; for special summary plot, change the box fractions
     lbres@lbBoxSizing = "ExplicitSizing"
     lbres@lbBoxFractions = (/0.,.0833,.166,.25,.417,.583,.75,.834,.917,1./) 
  end if
  lbid = gsn_create_labelbar(wks,nboxes,labels,lbres)

  return(lbid)   ; Return it so we can maximize later if desired.
end
;=================================================================================================
; This function sets colors to use in the subtitles that denote that they are part of the
; same ensemble.
;
undef("set_subtitle_colors")
function set_subtitle_colors(EM_num[1]:integer)
local EM_num,cs_color,cs_colorT,zt,eind
begin
  cs_color = (/"deepskyblue4","darkseagreen4","khaki3","chocolate4","mediumpurple3", "burlywood3",\
              "cadetblue4","sienna3","lemonchiffon3","dodgerblue3","springgreen4","brown3",\
              "blue2","mediumpurple4","lightcyan4","gray35","aquamarine3","mediumorchid2","azure3","lightpink3"/)
  
  if (EM_num.gt.20) then
     zt = (EM_num/20)+1
     cs_colorT = cs_color
     delete(cs_color)
     cs_color = new((/zt*20/),string) 
     eind = 0
     do dd = 0,zt-1
        cs_color(eind:eind+19) = (/  cs_colorT /)
        eind = eind+20
     end do
     delete(cs_colorT)
  end if
  return(cs_color)
end
;=================================================================================================
; This function checks for the presence of two CVDP files, and if present reads in the relevant
; array from the file.
;
undef("read_cvdp_le_data")
function read_cvdp_le_data(filenameT:string,filenameT2:string,vari_name:string)
local filenameT,filenameT2,vari_name,arr_temp,coordatt
begin
  if (isfilepresent2(filenameT)) then   ; check to see if the file created by this script is present, if not read the summary file created earlier in this script
     d = addfile(filenameT,"r")
     if (isfilevar(d,vari_name)) then
        arr_temp = d->$vari_name$
     end if
  end if
  if (.not.isvar("arr_temp")) then
     if (isfilepresent2(filenameT2)) then 
        d = addfile(filenameT2,"r")
        if (isfilevar(d,vari_name)) then
           arr_temp = d->$vari_name$
        end if
     end if
  end if
  if (.not.isvar("arr_temp")) then
     arr_temp = create_empty_array(1900,1950,1,12,"lat_lon")
  end if
  if (isatt(arr_temp,"coordinates")) then   ; copy 2d coordinates to lat2d/lon2d for sea ice data
     if (.not.(str_squeeze(arr_temp@coordinates).eq."")) then ; required for some data where coordinates att incorrectly set to ""
        coordatt = str_split(arr_temp@coordinates," ")
        if (dimsizes(coordatt).eq.2) then
           if (coordatt(0).eq."lat2d_ice_nh".or.coordatt(0).eq."lat2d_ice_sh".or.coordatt(0).eq."lat2d_ocean") then
              if (isfilevar(d,coordatt(0))) then
                 arr_temp@lat2d = d->$coordatt(0)$
              end if
              if (isfilevar(d,coordatt(1))) then
                 arr_temp@lon2d = d->$coordatt(1)$
              end if
           end if
        end if
     end if
  end if
  return(arr_temp)
end
;=================================================================================================
; This function sets the y-axis for power spectra plots.
;
undef("powspec_set_yaxis")
function powspec_set_yaxis (psdata_max[*]:numeric,opt3[1]:logical)

local psdata_max,opt3
begin
  if (isatt(opt3,"tmYLValues")) then
     delete([/opt3@tmYLValues,opt3@tmYLLabels,opt3@tmYLMinorValues/])
  end if
  if (psdata_max.lt.70) then
     opt3@trYMaxF = 75.
     opt3@tmYLValues = (/0,25,50,75/)
     opt3@tmYLLabels = opt3@tmYLValues
     opt3@tmYLMinorValues = ispan(5,70,5)
  end if
  if (psdata_max.ge.70.and.psdata_max.lt.145) then
     opt3@trYMaxF = 150.
     opt3@tmYLValues = (/0,50,100,150/)
     opt3@tmYLLabels = opt3@tmYLValues
     opt3@tmYLMinorValues = ispan(10,140,10)
  end if
  if (psdata_max.ge.145) then
     opt3@trYMaxF = psdata_max+15.
  end if
  return(opt3)
end
;=================================================================================================
; Compute annual and seasonal means 
;
undef("calculate_means")
function calculate_means(kan:numeric)
local kan,fin_kan,arrT,arr_seas,arr_ann,dimz
begin
  dimz = dimsizes(kan)
  fin_kan = kan(:13,:,:)
  fin_kan = fin_kan@_FillValue

  arrT = kan    
  arr_seas = runave_n_Wrap(arrT,3,0,0)
  arr_seas(0,:,:) = (/ dim_avg_n(arrT(:1,:,:),0) /)
  arr_seas(dimsizes(arrT&time)-1,:,:) = (/ dim_avg_n(arrT(dimsizes(arrT&time)-2:,:,:),0) /)
  arr_ann = runave_n_Wrap(arrT,12,0,0)

  fin_kan(0,:,:) = (/ dim_avg_n(arr_seas(0::12,:,:),0) /)
  fin_kan(1,:,:) = (/ dim_avg_n(arr_seas(1::12,:,:),0) /)
  fin_kan(2,:,:) = (/ dim_avg_n(arr_seas(3::12,:,:),0) /)
  fin_kan(3,:,:) = (/ dim_avg_n(arr_seas(6::12,:,:),0) /)
  fin_kan(4,:,:) = (/ dim_avg_n(arr_seas(7::12,:,:),0) /)
  fin_kan(5,:,:) = (/ dim_avg_n(arr_seas(9::12,:,:),0) /)
  fin_kan(6,:,:) = (/ dim_avg_n(arr_ann(5::12,:,:),0) /)
  delete([/arr_seas,arr_ann,arrT,dimz/])
  return(fin_kan)
end
;=================================================================================================
; Compute annual and seasonal standard deviations 
; kan = input array (3D), kopt2 = "True" or "False" on whether to detrend (this option has been deprecated)
undef("calculate_stddev")
function calculate_stddev(kan:numeric)   ;,kopt2:string)
local kan,fin_kan,arrT,arr_seas,arr_ann,dimz  ;,kopt2
begin
  dimz = dimsizes(kan)
  fin_kan = kan(:6,:,:)
  fin_kan = fin_kan@_FillValue

  arrT = kan
  arr_seas = runave_n_Wrap(arrT,3,0,0)
  arr_seas(0,:,:) = (/ dim_avg_n(arrT(:1,:,:),0) /)
  arr_seas(dimsizes(arrT&time)-1,:,:) = (/ dim_avg_n(arrT(dimsizes(arrT&time)-2:,:,:),0) /)
  arr_ann = runave_n_Wrap(arrT,12,0,0)
;  if (kopt2.eq."False") then   ; False = do not detrend
     fin_kan(0,:,:) = (/ dim_stddev_n(arr_seas(0::12,:,:),0) /)
     fin_kan(1,:,:) = (/ dim_stddev_n(arr_seas(1::12,:,:),0) /)
     fin_kan(2,:,:) = (/ dim_stddev_n(arr_seas(3::12,:,:),0) /)
     fin_kan(3,:,:) = (/ dim_stddev_n(arr_seas(6::12,:,:),0) /)
     fin_kan(4,:,:) = (/ dim_stddev_n(arr_seas(7::12,:,:),0) /)
     fin_kan(5,:,:) = (/ dim_stddev_n(arr_seas(9::12,:,:),0) /)
     fin_kan(6,:,:) = (/ dim_stddev_n(arr_ann(5::12,:,:),0) /)
;  else
;     fin_kan(0,:,:) = (/ dim_stddev_n(dtrend_msg_n(ispan(0,dimz(0)/12-1,1),arr_seas(0::12,:,:),False,False,0),0) /)
;     fin_kan(1,:,:) = (/ dim_stddev_n(dtrend_msg_n(ispan(0,dimz(0)/12-1,1),arr_seas(1::12,:,:),False,False,0),0) /)
;     fin_kan(2,:,:) = (/ dim_stddev_n(dtrend_msg_n(ispan(0,dimz(0)/12-1,1),arr_seas(3::12,:,:),False,False,0),0) /)
;     fin_kan(3,:,:) = (/ dim_stddev_n(dtrend_msg_n(ispan(0,dimz(0)/12-1,1),arr_seas(6::12,:,:),False,False,0),0) /)
;     fin_kan(4,:,:) = (/ dim_stddev_n(dtrend_msg_n(ispan(0,dimz(0)/12-1,1),arr_seas(7::12,:,:),False,False,0),0) /)
;     fin_kan(5,:,:) = (/ dim_stddev_n(dtrend_msg_n(ispan(0,dimz(0)/12-1,1),arr_seas(9::12,:,:),False,False,0),0) /)
;     fin_kan(6,:,:) = (/ dim_stddev_n(dtrend_msg_n(ispan(0,dimz(0)/12-1,1),arr_ann(5::12,:,:),False,False,0),0) /)
;  end if
  delete([/arr_seas,arr_ann,arrT,dimz/])
  return(fin_kan)
end

;=================================================================================================
; Compute annual and seasonal trends
;
undef("calculate_trends")
function calculate_trends(kan:numeric)
local kan,fin_kan,kt,kan_seas,kan_ann,tarr,dimz,si
begin
  dimz = dimsizes(kan)
  fin_kan = kan(:6,:,:)
  fin_kan = fin_kan@_FillValue
  fin_kan@units = kan@units+" "+(dimz(0)/12)+"yr~S~-1~N~"

  kan_seas = runave_n_Wrap(kan,3,0,0)
  kan_seas(0,:,:) = (/ dim_avg_n(kan(:1,:,:),0) /)
  kan_seas(dimz(0)-1,:,:) = (/ dim_avg_n(kan(dimz(0)-2:,:,:),0) /)
  kan_ann = runave_n_Wrap(kan,12,0,0)

  si = (/0,1,3,6,7,9/)
  do aa = 0,6
     if (aa.le.5) then
        tarr = kan_seas(si(aa)::12,:,:)    ; select seasonal averages  
     else
        tarr = kan_ann(5::12,:,:)        ; select annual averages
     end if
     kt := dtrend_msg_n(ispan(0,dimsizes(tarr&time)-1,1),tarr,False,True,0)   
     fin_kan(aa,:,:) = (/ onedtond(kt@slope, (/dimz(1),dimz(2)/) ) /)
     delete([/tarr,kt/])        
  end do
  delete([/kan_seas,kan_ann/])
  fin_kan = (/ fin_kan*(dimz(0)/12.) /)   ; scale the seasonal/annual trends by the total number of timesteps
  return(fin_kan)
end
;=================================================================================================
; Compute annual and seasonal (DJF,JFM,MAM,JJA,JAS,SON) area-averages
;
undef("calculate_areaavg")
function calculate_areaavg(kan:numeric,minlat[1]:numeric,maxlat[1]:numeric,minlon[1]:numeric,maxlon[1]:numeric)
local kan,fin_kan,kt,kan_seas,kan_ann,tarr,dimz,pi,rad,cowsgt,si,minlat,maxlat,minlon,maxlon
begin
  if (minlon.lt.0.and.maxlon.gt.180) then
     print("calculate_areaavg error, minlon.lt.0.and.maxlon.gt.180, function not set up to handle this situation, exiting")
     exit
  end if
  if (minlon.lt.0) then
     kan = lonFlip(kan)
  end if

  pi=4.*atan(1.0)
  rad=(pi/180.)
  coswgt=cos(rad*kan&lat)
  coswgt!0 = "lat"
  coswgt&lat= kan&lat

  dimz = dimsizes(kan)
  fin_kan = new((/7,dimz(0)/12/),typeof(kan))
  fin_kan = fin_kan@_FillValue
  copy_VarAtts(kan,fin_kan)

  kan_seas = runave_n_Wrap(kan,3,0,0)
  kan_seas(0,:,:) = (/ dim_avg_n(kan(:1,:,:),0) /)
  kan_seas(dimz(0)-1,:,:) = (/ dim_avg_n(kan(dimz(0)-2:,:,:),0) /)
  kan_ann = runave_n_Wrap(kan,12,0,0)
  si = (/0,1,3,6,7,9/)
  do aa = 0,6
     if (aa.le.5) then
        tarr = kan_seas(si(aa)::12,:,:)    ; select seasonal averages  
     else
        tarr = kan_ann(5::12,:,:)        ; select annual averages
     end if
     fin_kan(aa,:) = (/ wgt_areaave(tarr(:,{minlat:maxlat},{minlon:maxlon}),coswgt({minlat:maxlat}),1.0,0) /)
     delete([/tarr/])        
  end do
  delete([/kan_seas,kan_ann/])
  return(fin_kan)
end
;=================================================================================================
; p-value calculation: count the number of ensemble members that have a value less than obs, divide by ensemble size*100.
;
undef("calculate_pval")
function calculate_pval(obs:numeric,model:numeric)
local obs,model,p_val,mm,nn,temp,ttt,temp,dimZ,tind,temp2,dimY2
begin
  if (dimsizes(dimsizes(model)).ne.3.or.dimsizes(dimsizes(obs)).ne.2) then
     p_val = -999.
  else
     p_val = model(0,:,:)
     p_val = p_val@_FillValue                ; p-value plots
     dimZ = dimsizes(model)
     do mm = 0,dimZ(1)-1     ; count the number of ensemble members that have a value less than obs, divide by ensemble size*100.
        do nn = 0,dimZ(2)-1
           temp := new(dimZ(0)+1,typeof(model))
           temp(0) = (/ obs(mm,nn) /)
           temp(1:) = (/ model(:,mm,nn) /)
           tind  := ind(.not.ismissing(temp))
           if (ismissing(tind(0))) then
              continue
           end if
           temp2 := temp(tind)
           dimY2 := dimsizes(temp2)-1  
           qsort(temp2)
           if (dimY2.ge.2.and.temp2(0).eq.temp2(dimY2-1)) then   ; all values are the same
              continue   
           end if
           ttt := ind(temp2.eq.obs(mm,nn))
           if (dimY2.gt.1) then
              p_val(mm,nn) = (/ ((ttt(0)*1.)/dimY2)*100. /)   
           end if
           delete([/ttt,temp,tind,temp2,dimY2/])
        end do
     end do
     p_val = where(p_val.eq.0,-1,p_val)   ; for plotting, values less than the lowest model value need to be less than 0.
  end if
  return(p_val)
end
;=================================================================================================
; Determine whether to turn the summary panel label bars on by examining the paths array
; paths = Paths to data files, m = which ensemble mean is being analyzed, 
; n = number of ensembles, EMn = array containing ensemble mean assignment integers
;
undef("summary_lb_flag")
function summary_lb_flag(paths:string,EMn:integer,m:integer,n:integer)
local paths,m,n,EMn,cntr_ensT,dataq,dcntr,lbFlag
begin
  if (m.eq.n) then
     lbFlag = True
  else
     lbFlag = False
     dataq := new(n-m+1,string)
     dcntr = 0
     do pp = m,n
        cntr_ensT := ind(EMn.eq.pp)
        if (dimsizes(cntr_ensT).eq.1.and.ismissing(cntr_ensT(0))) then
           dataq(dcntr) = False
        else
           if (all(ismissing(paths(cntr_ensT)))) then
              dataq(dcntr) = False
           else
              dataq(dcntr) = True
           end if
        end if
        dcntr = dcntr+1
     end do
     if (all(dataq(1:).eq.False)) then
        lbFlag = True
     end if
  end if
  return(lbFlag)
end
;==============================================================================================================
; Check that input years match each other and set a flag to 0 (if years match) or to 1 (if years do not match)
;
undef("check_years_match")
function check_years_match(startyear0:integer,startyear1:integer,endyear0:integer,endyear0:integer)
local startyear0,endyear0,startyear1,endyear1,yrFlag
begin  
  if (any(ismissing((/startyear0,startyear1,endyear0,endyear1/)))) then
     yrFlag = 1
  else
     if (startyear0.eq.startyear1) then     ; check that the start and end years match for ts, tas, and psl
        if (endyear0.eq.endyear1) then
           yrFlag = 0
        else
           yrFlag = 1
        end if
     else
        yrFlag = 1
     end if
  end if 
  return(yrFlag)
end
;==============================================================================================================
; Create power spectra and add all necessary metadata
;
undef("create_power_spectra")
function create_power_spectra(PC1,IOPT,JAVE,PCT,VAL1,VAL2,ISTD)
local PC1,IOPT,JAVE,PCT,VAL1,VAL2,SDOF,SPLT1,ISTD
begin
   SDOF = specx_anal(PC1,IOPT,JAVE,PCT)   ; pc1 is standardized
   SPLT1 = specx_ci(SDOF,VAL1,VAL2)
   SPLT1!0 = "ncurves"
   SPLT1&ncurves = ispan(0,3,1)
   SPLT1&ncurves@long_name = "power spectra curves"
   SPLT1&ncurves@units = "1"
   SPLT1!1 = "frequency"
   SPLT1&frequency = SDOF@frq
   SPLT1&frequency@units = "1"
   if (ISTD) then
      SPLT1@units_info = "df refers to frequency interval; data are standardized so there are no physical units"
   else
      SPLT1@units_info = "df refers to frequency interval"
   end if
   SPLT1@units = "1/df"
   SPLT1@info = "(0,:)=spectrum,(1,:)=Markov red noise spectrum, (2,:)="+VAL1+"% confidence bound for Markhov, (3,:)="+VAL2+"% confidence bound for Markhov"
   return(SPLT1)
end
;=================================================================================================
; Compute annual and seasonal EOFS (for atmospheric modes)
;
undef("calculate_eofs")
function calculate_eofs(karr:numeric,minlat[1]:numeric,maxlat[1]:numeric,minlon[1]:numeric,maxlon[1]:numeric,numeof:integer)
local karr,fineof,dimz,karr_seas,karr_ann,minlat,maxlat,minlon,maxlon,numeof,attstring,evecv,pcts,pcts_s,tarr,signif,signif_str
begin
  dimz = dimsizes(karr)
  fineof = new((/numeof,7,dimz(1),dimz(2)/),typeof(karr))
  fineof!0 = "neof"
  fineof&neof = ispan(1,numeof,1)
  fineof!1 = "seas"
  fineof&seas = ispan(0,6,1)
  fineof!2 = "lat"
  fineof&lat = karr&lat
  fineof!3 = "lon"
  fineof&lon = karr&lon
  copy_VarAtts(karr,fineof)

  if (minlon.lt.0.or.maxlon.lt.0) then
     if (min(karr&lon).ge.0) then
        print("Warning! Input array longitudes span "+min(karr&lon)+"-"+max(karr&lon)+". Longitudes specified for EOF ("+minlon+"/"+maxlon+") are out of range.")
        print("Exiting from calculate_eofs function.")
        exit
     end if
  end if 

  karr_seas = runave_n_Wrap(karr,3,0,0)
  karr_seas(0,:,:) = (/ dim_avg_n(karr(:1,:,:),0) /)
  karr_seas(dimz(0)-1,:,:) = (/ dim_avg_n(karr(dimz(0)-2:,:,:),0) /)
  karr_ann = runave_n_Wrap(karr,12,0,0)

  si = (/0,1,3,6,7,9/)
  do aa = 0,6
     if (aa.le.5) then
        tarr = karr_seas(si(aa)::12,:,:)    ; select seasonal averages  
     else
        tarr = karr_ann(5::12,:,:)        ; select annual averages
     end if
     tarr_CW = SqrtCosWeight(tarr)
     evecv = eofunc_n(tarr_CW(:,{minlat:maxlat},{minlon:maxlon}),numeof,75,0)
     pcts = eofunc_ts_n(tarr_CW(:,{minlat:maxlat},{minlon:maxlon}),evecv,False,0)
     fineof@$(/"pcvar_seas"+(aa+1)/)$ = str_join(tostring(evecv@pcvar),",")
     if (numeof.ge.2) then
        signif := eofunc_north2(evecv@pcvar,dimz(0)/12,False)   ; dimz(0) based on monthly data, but tarr = seasonal array
        signif_str := new(numeof,string)
        signif_str = where(signif.eq.True,"True","False")
        fineof@$(/"pcvar_signif_seas"+(aa+1)/)$ = str_join(signif_str,",")
     end if
     do bb = 0,numeof-1
        pcts_s = dim_standardize(pcts(bb,:),0)
        fineof(bb,aa,:,:) = (/ regCoef_n(pcts_s,tarr,0,0) /)
        attstring = "pc"+(bb+1)+"_seas"+(aa+1)
        fineof@$attstring$ = pcts_s
     end do
     delete([/tarr,pcts_s,tarr_CW,evecv,pcts/])        
  end do
  return(fineof)
end
;=================================================================================================
; Compute monthly EOFS (for atmospheric modes)
;
undef("calculate_eofs_mon")
function calculate_eofs_mon(karr:numeric,minlat[1]:numeric,maxlat[1]:numeric,minlon[1]:numeric,maxlon[1]:numeric,numeof:integer)
local karr,fineof,dimz,karr_seas,karr_ann,minlat,maxlat,minlon,maxlon,numeof,attstring,evecv,pcts,pcts_s,tarr,signif,signif_str
begin
  dimz = dimsizes(karr)
  fineof = new((/numeof,dimz(1),dimz(2)/),typeof(karr))
  fineof!0 = "neof"
  fineof&neof = ispan(1,numeof,1)
  fineof!1 = "lat"
  fineof&lat = karr&lat
  fineof!2 = "lon"
  fineof&lon = karr&lon
  copy_VarAtts(karr,fineof)

  if (minlon.lt.0.or.maxlon.lt.0) then
     if (min(karr&lon).ge.0) then
        print("Warning! Input array longitudes span "+min(karr&lon)+"-"+max(karr&lon)+". Longitudes specified for EOF ("+minlon+"/"+maxlon+") are out of range.")
        print("Exiting from calculate_eofs function.")
        exit
     end if
  end if

  tarr = karr
  tarr_CW = SqrtCosWeight(tarr)

  evecv = eofunc_n(tarr_CW(:,{minlat:maxlat},{minlon:maxlon}),numeof,75,0)
  pcts = eofunc_ts_n(tarr_CW(:,{minlat:maxlat},{minlon:maxlon}),evecv,False,0)

  fineof@pcvar = str_join(tostring(evecv@pcvar),",")
   
  if (numeof.ge.2) then
     signif := eofunc_north2(evecv@pcvar,dimz(0),False)   ; dimz(0) based on monthly data
     signif_str := new(numeof,string)
     signif_str = where(signif.eq.True,"True","False")
     fineof@$(/"pcvar_signif"/)$ = str_join(signif_str,",")
  end if

  do bb = 0,numeof-1
     pcts_s = dim_standardize(pcts(bb,:),0)
     fineof(bb,:,:) = (/ regCoef_n(pcts_s,tarr,0,0) /)
     attstring = "pc"+(bb+1)
     fineof@$attstring$ = pcts_s
  end do
  delete([/tarr,pcts_s,tarr_CW,evecv,pcts/])
  return(fineof)
end
;;================================================================================================================
undef("add_labelbar_mt")
procedure add_labelbar_mt(wks,plot,colors,labels)
local vph, vpw, nboxes, lbres, lbid, amres, annoid
begin
  getvalues plot                      ; Get plot size for use in
    "vpHeightF" : vph                 ; creating labelbar.
    "vpWidthF"  : vpw
  end getvalues

  nboxes = dimsizes(colors)

  lbres                    = True          ; labelbar only resources
  lbres@lbAutoManage       = False          ; Necessary to control sizes
  lbres@vpWidthF           = 0.15 * vpw    ; labelbar width
  if (vph.eq..175) then    ; minimum height
     lbres@vpHeightF          = 0.155  
     lbres@lbLabelFontHeightF = 0.008 
  end if
  if (vph.gt..175.and.vph.lt..8601) then
     lbres@vpHeightF          = 0.85 * vph
     lbres@lbLabelFontHeightF = 0.008+(((vph-.17)/.7101)*.0075)
  end if
  if (vph.ge..8601) then
     lbres@vpHeightF          = 0.7 * vph
     lbres@lbLabelFontHeightF = 0.0105-(((vph-.8601)*10)*2)     
  end if
  lbres@lbFillColors       = colors        ; labelbar colors
  lbres@lbMonoFillPattern  = True          ; Solid fill pattern
    
  lbres@lbLabelAlignment   = "InteriorEdges"  ; center of box
  lbres@lbOrientation      = "Vertical"
  lbres@lbPerimOn          = False
  lbres@lbFillOpacityF = 0.5

  lbid = gsn_create_labelbar(wks,nboxes,labels,lbres)                                                          
  amres                  = True
  amres@amJust           = "CenterLeft"
  amres@amParallelPosF   =  0.52
  amres@amOrthogonalPosF =  0.0
  plot@annoid = gsn_add_annotation(plot,lbid,amres)
end
;=================================================================================================
; Given a 1D array, this function calculates the 10, 25, median, 75 and 90% values 
; of the sorted array.  
undef("boxplot_stat")
function boxplot_stat(bparrT[*]:numeric)
local bparrT,bparr,bpcalcarr,x10,x25,x75,x90,dimBP
begin
  if (.not.isatt(bparrT,"_FillValue")) then
     bparrT@_FillValue = default_fillvalue(typeof(bparrT))
  end if
  bpcalcarr = new(5,typeof(bparrT))
  bpcalcarr@_FillValue = -999
  if (.not.all(ismissing(bparrT))) then
     bparr = bparrT(ind(.not.ismissing(bparrT)))
     qsort(bparr)
     dimBP = dimsizes(bparr)    
     x10  = round(.10*dimBP,3)-1     ; -1 to account for NCL indexing starting
     x25  = round(.25*dimBP,3)-1    
     x75  = round(.75*dimBP,3)-1 
     x90  = round(.90*dimBP,3)-1 
     if (dimBP.ge.5) then   ; only compute if dimBP.ge.5 (also=x10.ge.0)
        bpcalcarr(0) = bparr(x10)   ;min(bparr)
        bpcalcarr(1) = bparr(x25)
        bpcalcarr(2) = dim_median(bparr)
        bpcalcarr(3) = bparr(x75)
        bpcalcarr(4) = bparr(x90)    ;max(bparr) 
     end if
  end if
  return(bpcalcarr)
end
;=================================================================================================
; Calculate the area of each grid box given lat and lon
;
undef("calculate_gridbox_area")
function calculate_gridbox_area(lat,lon)
local lat,fcnt,rad,dimlat,latr,lon,dimlon,lonr,area
begin
  if (min(lon).ge.0.and.max(lon).le.360) then
     fctr = 111120   ; how many meters per degree of latitude (approximate)
     rad=((4.*atan(1.0))/180.)
	    dimlat = dimsizes(lat)
	    latr = new(dimlat,typeof(lat))
	    do gg = 0,dimlat-1
	       if (gg.eq.0) then
           if (lat(0).le.-85) then  ; is the first point near the South Pole? 
		            latr(gg) = abs(-90-(lat(1)+lat(0))/2.)  ; If so, assume that is the southernmost latitude of grid
           else
              latr(gg) = abs((lat(0)+lat(1))/2. - (lat(1)+lat(2))/2.) ; if not, assume it is the same size as the nearest grid box
           end if
		      end if
	       if (gg.ge.1.and.gg.lt.dimlat-1) then
	          latr(gg) = abs((lat(gg-1)+lat(gg))/2. - (lat(gg)+lat(gg+1))/2.)
		      end if
		      if (gg.eq.dimlat-1) then
           if (lat(dimlat-1).ge.85) then  ; is the first point near the North Pole? 
		            latr(gg) = abs(90 - (lat(dimlat-2)+lat(dimlat-1))/2.)   ; if so, assume that it is the northernmost latitude of grid
           else
              latr(gg) = abs((lat(gg-2)+lat(gg-1))/2. - (lat(gg-1)+lat(gg))/2.)  ; if not, assume it is the same size as the nearest grid box
           end if
		      end if
	    end do
	    dimlon = dimsizes(lon)
	    lonr = new(dimlon,typeof(lon))
     do gg = 0,dimlon-1
	       if (gg.eq.0) then
           if (lon(0).le.5) then    ; is the first point near the Prime Meridian?
		            lonr(gg) = abs( (lon(1)+lon(0))/2. - (((lon(dimlon-1)+(lon(0)+360))/2.)-360) )  ; if so, assume this is the western most grid cell
           else
   			        lonr(gg) = abs((lon(gg+1)+lon(gg+2))/2. - (lon(gg)+lon(gg+1))/2.)    ; otherwise this longitude size is the same as the 2nd longitude
           end if
		      end if
		      if (gg.ge.1.and.gg.lt.dimlon-1) then
			        lonr(gg) = abs((lon(gg)+lon(gg+1))/2. - (lon(gg-1)+lon(gg))/2.)
		      end if
		      if (gg.eq.dimlon-1) then
           if (lon(dimlon-1).ge.355) then   ; is the last point near the Prime Meridian
   		         lonr(gg) = abs(((lon(dimlon-1)+(lon(0)+360))/2.) - (lon(gg-1)+lon(gg))/2.)   ; if so, assume this is the eastern most grid cell
           else
              lonr(gg) = abs((lon(gg-1)+lon(gg))/2. - (lon(gg-2)+lon(gg-1))/2.)  ; otherwise set the longitude size is the same as the 2nd-to-last longitude
           end if
		      end if		
	    end do  
     area = new((/dimsizes(lat),dimsizes(lon)/),double)
     area!0 = "lat"
     area&lat = lat
     area!1 = "lon"
     area&lon = lon
	    area@long_name = "Area of grid box"
	    area@units = "m2"
     do ff = 0,dimlat-1
	       do gg = 0,dimlon-1
		         area(ff,gg) = (/ (fctr*latr(ff))*(cos(rad*lat(ff))*lonr(gg)*fctr) /)     ; cosine weighting
		      end do
	    end do
  else
     area = True
     area@is_all_missing = True
  end if
  return(area)
end
;================================================================================================================
; This function will calculate the area that is within a specified range of a given array. 
;
undef("calculate_area_in_range")
function calculate_area_in_range(qarr,val1,val2)
local calc_area,qarr,wgts,max_area,val_area,val1,val2,rval
begin
  calc_area = calculate_gridbox_area(qarr&lat,qarr&lon)
  if (.not.isatt(calc_area,"is_all_missing"))
     calc_area = where(ismissing(qarr),calc_area@_FillValue,calc_area)
     wgts = calc_area
     wgts = 1.
     max_area = wgt_areasum2(calc_area,wgts,0)
     calc_area = where(qarr.ge.val1.and.qarr.le.val2,calc_area,calc_area@_FillValue)
     val_area = wgt_areasum2(calc_area,wgts,0)
     rval = sprintf("%4.0f",(val_area/max_area)*100.)
     if (ismissing(val_area)) then
        rval = "--"
     end if
  else
     rval = "--"
  end if
  return(rval)
end
;================================================================================================================
; This function will calculate the % of timesteps a single timeseries is within 2 curves
;
undef("calculate_percent_in_range")
function calculate_percent_in_range(rarr[*]:numeric,rarr2:numeric)
local rarr,rarr2,qarrT,qarr2T,qarr,qarr2,zo,time_t
begin
  qarrT = rarr
  qarr2T = rarr2
  time_t = tofloat(qarrT&time)   ; fix put in to address inconsistent time values of type double, which can lead
  delete(qarrT&time)             ; to incorrect coordinate subscripting later in this function
  qarrT&time = time_t
  time_t := tofloat(qarr2T&time)
  delete(qarr2T&time)
  qarr2T&time = time_t
  if (min(qarrT&time).gt.max(qarr2T&time).or.max(qarrT&time).lt.min(qarr2T&time)) then
     return(0.0)
  else
     qarr = qarrT({max((/min(qarrT&time),min(qarr2T&time)/)):min((/max(qarrT&time),max(qarr2T&time)/))})
     qarr2 = qarr2T(:,{min(qarr&time):max(qarr&time)})
     zo = new(dimsizes(qarr),integer)
     if (dimsizes(qarr).ne.dimsizes(qarr2(0,:))) then
        return(0.0)
     else
        zo = where(qarr.ge.qarr2(0,:).and.qarr.le.qarr2(1,:),1,0)
        return(decimalPlaces(((num(zo.eq.1)*1.)/dimsizes(qarr))*100.,0,True))
     end if
  end if
end
;================================================================================================================
; This function sets the panel title y-axis NDC coordinate by looking at how many panels and the panel size.
; NCL does not top justify the panels in the frame, and moves them around randomly. This function 
; tries to account for this.
;
undef("set_panel_title_YF")
function set_panel_title_YF(NUMEM:integer,EMRES:logical)
local NUMEM,EMRES,mtvalarr,mtval
begin
  mtval = .97
  if (EMRES@vpHeightF.eq.0.25.and.EMRES@vpWidthF.eq.0.7) then  ; only calculated number out to 35 ensembles using test.yaxis_title.ncl
     mtvalarr = new(36,float)    ; these settings were tested with tmXB/YLFontHeights = 0.0125/0.018, and *StringFontHeightF of 0.015/0.024
     mtvalarr = mtval
     mtvalarr((/1,16,17,25/)) = .75
     mtvalarr((/4,9/)) = .78
     mtvalarr((/12,17,20,26,30/)) = .82
     mtvalarr((/5,10,27,31,35/)) = .85
     mtvalarr((/11,13,15,18,21,24,28,32/)) = .9
     mtvalarr((/19,22,29/)) = .93
     if (NUMEM.le.35) then
        mtval = mtvalarr(NUMEM)
     end if 
  end if
  if (EMRES@vpHeightF.eq.0.35.and.EMRES@vpWidthF.eq.0.65) then  ; only calculated number out to 35 ensembles using test.yaxis_title.ncl
     mtvalarr = new(36,float)    ; these settings were tested with tmXB/YLFontHeights = 0.0125/0.018, and *StringFontHeightF of 0.015/0.024
     mtvalarr = mtval
     mtvalarr((/4,9,16,25/)) = .83
     mtvalarr((/7,17,20,26,30/)) = .93
     if (NUMEM.le.35) then
        mtval = mtvalarr(NUMEM)
     end if 
  end if
  if (EMRES@vpHeightF.eq.0.6.and.EMRES@vpWidthF.eq.0.6) then  ; only calculated number out to 35 ensembles using test.yaxis_title.ncl
     mtvalarr = new(36,float)    ; these settings were tested with tmXB/YLFontHeights = 0.0125/0.018, and *StringFontHeightF of 0.015/0.024
     mtvalarr = mtval
     mtvalarr(1) = .93
     if (NUMEM.le.35) then
        mtval = mtvalarr(NUMEM)
     end if 
  end if
  return(mtval)
end
;=================================================================================================================
; Create small xy plot to graphically represent spread of % variance explained for EOF summary plots.
; opt resource list options = obsval (observed value) gsLineColor_obs (color obsval this color) and 
; gsLineColor (color ensemble bars this color) 
;
undef("add_xy_plot")
function add_xy_plot(wks,varr,opt)
local varr,opt,xyplot,stats,polyres,polyres2,polyres3,v10,v50,v90,dum_p,dum_p2,val,obsval
begin
  obsval = 0.
  if (isatt(opt,"obsval")) then
     if (.not.ismissing(obsval)) then
        obsval = tofloat(opt@obsval)
     end if
  end if
  xyplot = create "plot" logLinPlotClass wks
    "vpHeightF": 0.035
    "vpWidthF": 0.1
    "trYMinF" : -1
    "trYMaxF" : 1
    "trXMinF" : min((/min(varr),obsval/))  
    "trXMaxF" : max((/max(varr),obsval/))
    "pmTickMarkDisplayMode" : "Never"
    "tmYLOn"   : "False"
    "tmXBOn"  : False
    "tmXBBorderOn" : False
    "tmYLBorderOn" : False
    "pmTitleDisplayMode": "Never"                   
  end create
  polyres = True                          ;Set up defaults
  polyres@gsLineThicknessF  = 3.5                          ; thickness of lines
  polyres@gsLineDashPattern = 0
  if (isatt(opt,"gsLineColor"))
     polyres@gsLineColor = opt@gsLineColor
  end if

  polyres2 = polyres   ; for ensemble mean bars
  polyres2@gsLineThicknessF  = 7.5 
  polyres3 = polyres2   ; for 10/90% bars
  polyres3@gsLineThicknessF  = 5.5 

  stats = boxplot_stat(varr)
  v10 = stats(0)  ; 10% value
  v50 = avg(varr) ; avg value
  v90 = stats(4)  ; 90% value

  dum_p = new(dimsizes(varr),graphic)
  dum_p2 = new(4,graphic)

  do gg = 0,dimsizes(varr)-1
     val = varr(gg)
     if (.not.ismissing(val)) then
        dum_p(gg) = gsn_add_polyline(wks,xyplot,(/val,val/),(/-.25,.25/),polyres)
     end if
  end do
  if (.not.ismissing(v10)) then
     dum_p2(0) = gsn_add_polyline(wks,xyplot,(/v10,v10/),(/-.65,.65/),polyres3)   ; draw 10% index
  end if
  if (.not.ismissing(v50)) then
     dum_p2(1) = gsn_add_polyline(wks,xyplot,(/v50,v50/),(/-.85,.85/),polyres2)   ; draw avg index
  end if
  if (.not.ismissing(v90)) then
     dum_p2(2) = gsn_add_polyline(wks,xyplot,(/v90,v90/),(/-.65,.65/),polyres3)   ; draw 90% index
  end if
  if (isatt(opt,"obsval")) then   ; obs value included, plot it
     polyres4 = polyres
     polyres4@gsLineThicknessF  = 5
     polyres4@gsLineColor = "gray20"
     if (isatt(opt,"gsLineColor_obs")) then
        polyres4@gsLineColor = opt@gsLineColor_obs
     end if
     dum_p2(3) = gsn_add_polyline(wks,xyplot,(/tofloat(opt@obsval),tofloat(opt@obsval)/),(/-.99,.99/),polyres4)   ; draw 90% index
  end if

  xyplot@$unique_string("dum")$ = dum_p
  xyplot@$unique_string("dum")$ = dum_p2
  return(xyplot)
end
;=================================================================================================================
; Set summary % where obs lies in sensemble spread resources
;
undef("retrieve_summary_res")
function retrieve_summary_res()
local gres,cmap,cmap2
begin
  gres = True
  gres@cnLevels = (/0,5,10,20,80,90,95,100/)  
  gres@cnFillMode = "RasterFill"
  gres@lbBoxSizing = "ExplicitSizing"
  gres@lbBoxFractions = (/0.,.0833,.166,.25,.417,.583,.75,.834,.917,1./) 
  cmap = read_colormap_file("BlueGreen14")
  cmap2 = cmap((/0,2,4,6,0,7,9,11,13/),:)
  cmap2(4,:2) = (/1,1,1/)
  cmap2(6,0:2:2) = .75
  cmap2(7,0:2:2) = .55
  gres@cnFillPalette = cmap2
  gres@cnMissingValFillColor = "gray90"
  gres@lbTitleString = "%" 
  gres@gsnLeftString = ""
  gres@gsnCenterString = "Rank of Reference Data within Ensemble"
  gres@gsnRightString = ""
  return(gres)
end
;=================================================================================================================
; Set text used in gsnRightString for ENSO Spatial Composites
;
undef("set_subtitle_enso_numevents")
function set_subtitle_enso_numevents(farr:numeric,etxt:string)
local farr,etxt,ftxt
begin
  ftxt = ""
  if (isatt(farr,"number_of_elnino_events")) then
     if (isatt(farr,"number_of_lanina_events")) then
        ftxt = farr@number_of_elnino_events+" EN/"+farr@number_of_lanina_events+" LN "+etxt
     else
        ftxt = farr@number_of_elnino_events+" EN "+etxt
     end if
  else
     if (isatt(farr,"number_of_lanina_events")) then
        ftxt = farr@number_of_lanina_events+" LN "+etxt
     end if
  end if
  return(ftxt)
end
;=================================================================================================================
; Calculate pattern correlation between two input arrays, pass back formatted string to be
; used in spatial plot gsnRightString subtitles
;
undef("pattern_correlation")
function pattern_correlation(dset1:numeric,dset2:numeric)
local dset1,dset2,clat,pc,rpc
begin
  clat := cos(0.01745329*dset1&lat)
  clat!0 = "lat"
  clat&lat = dset1&lat
  pc = pattern_cor(dset1,dset2,clat,0)
  if (ismissing(pc)) then
     rpc = ""
  else
     rpc = sprintf("%4.2f",pc)
  end if
  return(rpc)
end
;=================================================================================================================
; Identify the first index that is not missing (if any) and pass that index back. Used for summary timeseries panels.
;
undef("id_firstvalid_ind")
function id_firstvalid_ind(sumplot:graphic)
local sumplot,i_ind,ii
begin
  i_ind := new(1,integer)
  if (ismissing(sumplot(0))) then
     do ii = 1,dimsizes(sumplot)-1
        if (.not.ismissing(sumplot(ii))) then
           i_ind = ii
           break
        end if
     end do
  else
     i_ind = 0
  end if
  return(i_ind)
end
;=================================================================================================================
; Define new array with requisite coordinate variables to hold 25/75 and 10/90% range arrays
;
undef("define_arr_range_array")
function define_arr_range_array(nem[*]:numeric,idarr[1]:integer)
local nem,idarr,dimnames,pdarr
begin
  dimnames = getvardimnames(nem)
  pdarr = new((/2,dimsizes(nem)/),typeof(nem))
  copy_VarAtts(nem,pdarr)
  pdarr!1 = dimnames(0)
  pdarr&$dimnames(0)$ = nem&$dimnames(0)$
  if (idarr.eq.1) then
      pdarr!0 = "ncurves2"
      pdarr&ncurves2 = (/25,75/)
      pdarr&ncurves2@long_name = "25/75% curves"
      pdarr&ncurves2@units = "1"
  end if
  if (idarr.eq.2) then
      pdarr!0 = "ncurves3"
      pdarr&ncurves3 = (/10,90/)
      pdarr&ncurves3@long_name = "10/90% curves"
      pdarr&ncurves3@units = "1"
  end if
  return(pdarr)
end 
;=================================================================================================================
; Add global history attributes to output NetCDF file pointer (given the model, start/end years and the CVDP version #).
;
undef("set_global_ncfile_attributes")
procedure set_global_ncfile_attributes(fpointer[1]:file,modname[1]:string,syr[1]:integer,eyr[1]:integer,vn[1]:string)
local fpointer,modname,syr,eyr,vn
begin
  fpointer@source = "NCAR Climate Analysis Section's Climate Variability Diagnostics Package v"+vn
  fpointer@notes = "Data from "+modname+" Ensemble Mean from "+syr+"-"+eyr
  fpointer@climatology = syr+"-"+eyr+" climatology removed prior to all calculations (other than means)"
  fpointer@Conventions = "CF-1.6"
end
;=================================================================================================================
; For all images in outdir, trim white space, conver to .png (if necessary) and add watermark
; odir = Output directory, otype = output file type (.ps, .png, .eps), max_nt = max number of tasks allowed at once,
; zp0 = path of CVDP scripts, pngsize = size (in ImageMagick units) of png converted from ps
;
undef("image_finalize")
procedure image_finalize(odir[1]:string,otype[1]:string,max_nt[1]:integer,zp0[1]:string,pngsize[1]:integer,im_command[1]:string)
local odir,otype,max_nt,zp0,pngsize,ofiles,ofilesS,ofilesT,gg,filesize,ofiles_png,numPlotsCompleted,numJobsActive,pid,command,im_command
begin
  ofiles = systemfunc("ls "+odir+"*."+otype)
  if (otype.ne."png") then
     ofilesS = systemfunc("ls "+outdir+"*."+output_type)
     ofilesT = systemfunc("ls -l "+outdir+"*."+output_type)
     do gg = 0,dimsizes(ofilesT)-1    ; check for empty .ps files, remove
        filesize =  tofloat(str_get_field(ofilesT(gg),5," "))
        if (filesize.lt.10000) then
           print("Removing: "+ofilesT(gg))
           system("rm "+ofilesS(gg))
        end if
     end do
     ofiles_png = str_sub_str(ofiles,"."+otype,".png")
     oreso = "-density "+pngsize+" -trim +repage -bordercolor white -background white -border 8"
  else
     ofiles_png = ofiles
     oreso = "-trim +repage -bordercolor white -background white -border 15x30"
  end if

  do ff = 0,1  ; first time through trim and add border, second time through add watermark
     numPlotsCompleted = 0
     numJobsActive = 0
     do gg = 0,dimsizes(ofiles)-1
        do while (numJobsActive.ge.(max_num_tasks*2))
           pid = subprocess_wait(0, True) ; check if any tasks have completed; block until something completes...
           if (pid.gt.0) then
              numPlotsCompleted = numPlotsCompleted + 1
              numJobsActive = numJobsActive - 1
              break
           end if
        end do
        if (ff.eq.0) then
           if (otype.eq."png") then
              command = im_command+" "+ofiles(gg)+" "+oreso+" -flatten "+ofiles_png(gg)
           else
              command = "ps2epsi "+ofiles(gg)+" "+str_sub_str(ofiles(gg),"."+otype,".eps")+"; "+im_command+" "+str_sub_str(ofiles(gg),"."+otype,".eps")+" "+oreso+" -bordercolor white -background white -flatten "+ofiles_png(gg)
           end if
        else
           if (im_command.eq."convert") then
              command = "composite -dissolve 50% -gravity northeast "+zp0+"copyright.gif "+ofiles_png(gg)+" "+ofiles_png(gg)
           else
              command = "magick composite -dissolve 50% -gravity northeast "+zp0+"copyright.gif "+ofiles_png(gg)+" "+ofiles_png(gg)
           end if
        end if
        pid = subprocess(command)
        numJobsActive = numJobsActive + 1
     end do
     sleep(10)   ; wait 10 seconds for last batch of conversions to complete
  end do
;---------------------------------------
; Add watermark to metrics graphics
  
  ofiles := systemfunc("ls "+odir+"*.gif 2> /dev/null")
  numPlotsCompleted = 0
  numJobsActive = 0
  if (.not.ismissing(ofiles(0))) then
     do gg = 0,dimsizes(ofiles)-1
        do while (numJobsActive.ge.(max_num_tasks*2))
           pid = subprocess_wait(0, True) ; check if any tasks have completed; block until something completes...
           if (pid.gt.0) then
              numPlotsCompleted = numPlotsCompleted + 1
              numJobsActive = numJobsActive - 1
              break
           end if
        end do
        if (im_command.eq."convert") then
           command = "composite -dissolve 100% -gravity northeast "+zp0+"copyright2.gif "+ofiles(gg)+" "+ofiles(gg)
        else
           command = "magick composite -dissolve 100% -gravity northeast "+zp0+"copyright2.gif "+ofiles(gg)+" "+ofiles(gg)
        end if
        pid = subprocess(command)
        numJobsActive = numJobsActive + 1
     end do
     sleep(10)   ; wait 10 seconds for last batch of conversions to complete
  end if
;---------------------------------------
; Cleanup .eps files and ESMF regridding logs
;
  if (otype.eq."ps") then
     system("rm "+odir+"*.eps")
  end if
  if (isfilepresent2("PET0.RegridWeightGen.Log")) then
     system("rm PET0.RegridWeightGen.Log")
  end if
end
;=================================================================================================================
; This function is used to check whether there are 2D (columnar) data present. If so, regrid it and write the
; new data to a file.
;
undef("data_check_2D")
function data_check_2D(zpath:string,vn:string)
local zpath,vn,cpath0,tfiles,c,arr,farr,yearS,yearE,mocheck,fils_precc,fils_precl,vname_save,vname
begin
  if (vn.eq."TS") then
     vname = (/"TS","ts","sst","t_surf","skt","tos"/)
  end if
  if (vn.eq."PSL") then
     vname = (/"PSL","psl","slp","SLP","prmsl","msl","slp_dyn"/)
  end if
  if (vn.eq."TREFHT") then
     vname = (/"TREFHT","tas","temp","air","temperature_anomaly","temperature","t2m","t_ref","T2","tempanomaly","tas_mean","trefht"/)
  end if
  if (vn.eq."PRECT") then
     vname = (/"PRECC","PRECL","PRECT","pr","PPT","ppt","p","P","precip","PRECIP","tp","prcp","prate","prect"/)
  end if
  if (vn.eq."AICE_NH") then
     vname = (/"aice_nh","aice","sic","siconc","SIC","CN","ice","icec"/)
  end if
  if (vn.eq."AICE_SH") then
     vname = (/"aice_sh","aice","sic","siconc","SIC","CN","ice","icec"/)
  end if
  if (vn.eq."SSH") then
     vname = (/"SSH","zos","ssh"/)
  end if
  latn = (/"lat","LAT","latitude","LATITUDE"/)
  lonn = (/"lon","LON","longitude","LONGITUDE"/)
  vname_save = ""

  if (ismissing(zpath) ) then
     arr = create_empty_array(1950,2000,1,12,"time_lat_lon")
     arr@is_2D = "False"     
  else
     cpath0 = stringtochar(zpath)
     if (any(cpath0.eq.tochar("*")).or.any(cpath0.eq.tochar("{"))) then   ; check for "*" and "{" denoting multiple files
        tfiles = systemfunc("ls "+zpath+" 2> /dev/null")   ; /dev/null suppresses all standard error output
        if (vn.eq."PRECT") then   ; special section for precip, as might need to do PRECC+PRECL
           b = addfile(tfiles(0),"r")   ; check for PRECC
           if (isfilevar(b,"PRECC").or.isfilevar(b,"PRECL")) then  ; PRECC/PRECL section
              fils_precc = str_match(tfiles,"PRECC") 
              fils_precl = str_match(tfiles,"PRECL") 
              vname_save = "PRECT"
              if (any(ismissing(fils_precc)).or.any(ismissing(fils_precl))) then
                 print("Fatal: Need both PRECC and PRECL file(s), creating blank array")
                 print(fils_precc)
                 print(fils_precl)
                 arr = create_empty_array(1950,2000,1,12,"time_lat_lon")
                 break
              end if
              c = addfiles(fils_precc,"r")
              arr = c[:]->PRECC
              delete([/fils_precc,fils_precl/])            
           else    ; pr, ppt, PPT, PRECT multiple/single file read-in here..
              c = addfiles(tfiles,"r")
              do ii=0,dimsizes(vname)-1
                 if (isfilevar(c[0],vname(ii))) then
                    arr = c[:]->$vname(ii)$
                    vname_save = vname(ii)
                    break
                 end if
              end do
           end if
           delete(b)
        else
           c = addfiles(tfiles,"r")
           do ii=0,dimsizes(vname)-1
              if (isfilevar(c[0],vname(ii))) then
                 arr = c[:]->$vname(ii)$
                 vname_save = vname(ii)
                 break
              end if
           end do
        end if     
     else
        c = addfiles(zpath,"r")
        do i=0,dimsizes(vname)-1
           if (isfilevar(c[0],vname(i))) then
              arr = c[0]->$vname(i)$
              vname_save = vname(i)
              arr@pointer = "set"
              break
           end if
        end do
     end if

     if (dimsizes(dimsizes(arr)).eq.2) then
        arr@is_2D = "True"  
        do mm = 0,dimsizes(latn)-1
           if (isfilevar(c[0],latn(mm))) then
              arr@lat    := c[0]->$latn(mm)$
              break
           end if
        end do
        do mm = 0,dimsizes(lonn)-1
           if (isfilevar(c[0],lonn(mm))) then
              arr@lon    := c[0]->$lonn(mm)$
              break
           end if
        end do
     else
        arr@is_2D = "False"
     end if     
  end if
  arr@original_variable_name = vname_save
  return(arr)
end
;=================================================================================================================
; This function is used to set variable names, plot names, titles and output graphic names, depending on
; whether the ensemble mean is removed or not. The input to this is the RM_ENSEMBLE_MEAN environmental 
; variable. True = ensemble mean removed (labeled as prime), False = ensemble mean not removed.
;
; Deprecated after coding change to eliminate altering the output variable name / plot titles 
;
undef("label_check")
function label_check(zflag:string)
local zflag,eetxt
begin
  eetxt = ""
  if (zflag.eq."True") then  ; Ensemble means were removed, add prime text.
     eetxt@text1 = "prime "
     eetxt@text2 = "_"
     eetxt@text3 = "."
     eetxt@text4 = "Internal "
  else
     eetxt@text1 = ""
     eetxt@text2 = ""
     eetxt@text3 = ""
     eetxt@text4 = ""
  end if
  return(eetxt)
end
;====================================================================================================================
; This function identifies the ensemble mean file needed. The input iarr array is only used if the ensemble mean
; file is not present. The ensemble mean is returned. List of inputs:
; iarr = data array, mname = directory path and model name, EMnum = what ensemble this data belongs to, vble = variable, 
; syeara = list of start years from the calling script, eyeara = list of end years from the calling script, 
; EMnuma = list of ensemble numbers from the calling script. 
;
undef("ensemble_mean_read_in")
function ensemble_mean_read_in(iarr:numeric,mname[1]:string,EMnum[1]:integer,vble[1]:string,syeara[*]:integer,eyeara[*]:integer,EMnuma[*]:integer)
local iarr,mname,EMnum,vble,syeara,eyeara,EMnuma,iden,emdata,varilA,varilB,variflip,idfout
begin
  varilA = (/"PSL","TREFHT","TS","PRECT","aice_nh","aice_sh","ssh","moc","aice_nh_sie","aice_sh_sie"/)  ; necessary as ensemble mean files use lowercase variables in names
  varilB = (/"psl","trefht","ts","prect","aice_nh","aice_sh","ssh","moc","aice_nh","aice_sh"/)

  variflip = varilB(ind(varilA.eq.vble))
  iden := ind(EMnum.eq.EMnuma)
  idfout = mname+".cvdp_data."+variflip+".ensemble_mean."+sprinti("%0.4i",syeara(iden(0)))+"01-"+sprinti("%0.4i",eyeara(iden(0)))+"12.nc"

  if (.not.isfilepresent(idfout)) then
     print(idfout+" file not present, skipping")
     idfout@_FillValue = "missing"
     idfout = idfout@_FillValue
  end if
  if (vble.eq."PSL".or.vble.eq."TREFHT".or.vble.eq."TS".or.vble.eq."PRECT") then
     emdata = data_read_in(idfout,vble,syeara(iden(0)),eyeara(iden(0)))
  else
     if (vble.eq."aice_nh_sie".or.vble.eq."aice_sh_sie") then
        emdata = read_cvdp_le_data(idfout,"missing",vble)
     else
        emdata = read_cvdp_le_data(idfout,"missing",variflip)
     end if
  end if
  if (isatt(emdata,"is_all_missing")) then
     iarr = iarr@_FillValue ; set array to be returned to the same size of iarr array, allowing for subtraction within main scripts (even though this array is all missing)
     iarr@is_all_missing = True
     emdata := iarr
  end if
  return(emdata)
end
;====================================================================================================================
; This function identifies the ensemble mean file needed. The input iarr array is only used if the ensemble mean
; file is not present. The ensemble mean is returned. List of inputs:
; sarr = data array, sopt = name of detrending option (valid entries = None, LinearTrend, 30yrRunningMean, rmGMST_EM, rmEM), 
; sopt_em = is only used when sopt="rmGMST_EM" (this is the ensemble mean TAS array to regress out) or "rmEM".
;
; Note that if sopt is not set to LinearTrend, QuadraticTrend, 30yrRunningMean rmGMST_EM or rmEM, the sarr array is returned unaltered.
undef("remove_trend")
function remove_trend(sarr:numeric,sopt[1]:string,sopt_em:numeric)
local sarr,sopt,sopt_em,swgts,scoswgt,sEM_aa,sEM_rc,sarr_save
begin
  omlist = (/"None", "LinearTrend", "QuadraticTrend", "30yrRunningMean", "rmGMST_EM", "rmEM"/)
  if (.not.any(sopt.eq.omlist)) then
     print("sopt entry of "+sopt+" to remove_trend is not valid, exiting")
     exit
  end if
  if (sopt.eq."None") then
     sarr@detrend_option = "none applied"
  end if
  if (sopt.eq."LinearTrend") then   ; linearly detrend the sarr array by month
     do ss = 0,11
        sarr(ss::12,:,:) = dtrend_msg_n(ispan(0,(dimsizes(sarr&time)/12)-1,1),sarr(ss::12,:,:),False,False,0)
     end do
     sarr@detrend_option = "monthly linear trend removed"
  end if
  if (sopt.eq."QuadraticTrend") then   ; quadratically detrend the sarr array by month
     do ss = 0,11
        sarr(ss::12,:,:) = (/ dtrend_quadratic_msg_n(sarr(ss::12,:,:),False,False,0) /)
     end do
     sarr@detrend_option = "monthly quadratic trend removed"

     if (any(isnan_ieee(sarr))) then    ; for whatever reason, dtrend_quadratic_msg_n occasionally outputs nan's.
        replace_ieeenan (sarr, sarr@_FillValue, 0)
     end if
  end if
  if (sopt.eq."30yrRunningMean") then   ; 
     swgts = new(30,"double")
     swgts = (/0.007968192496166648,0.01846646831109216,0.02878470788332294,0.03879919256962656,0.04840267283059424,\
	              0.05749315621761927, 0.0659742298821802, 0.07375597473770572,0.08075589522941848,0.08689978720108463,\
               0.09212252223778641, 0.09636873717464459,0.09959342058679507,0.1017623897484056, 0.1028526528935592,\
               0.1028526528935592,  0.1017623897484056, 0.09959342058679507,0.09636873717464459,0.09212252223778641,\
               0.08689978720108463, 0.08075589522941848,0.07375597473770572,0.0659742298821802, 0.05749315621761927,\
               0.04840267283059424, 0.03879919256962656,0.02878470788332294,0.01846646831109216,0.007968192496166648/)
     sarr_save = sarr
     do ss = 0,11
        sarr_save(ss::12,:,:) = (/ wgt_runave_n(sarr(ss::12,:,:),swgts,1,0) /)
     end do
     sarr = (/ sarr - sarr_save /)
     sarr@detrend_option = "30yr weighted running mean removed"
  end if
  if (sopt.eq."rmGMST_EM".or.sopt.eq."rmEM") then
     if (dimsizes(dimsizes(sopt_em)).eq.1) then   
        print("Incorrect 3rd entry to remove_trend for rmGMST_EM or rmEM option, exiting")
        exit
     end if
  end if
  if (sopt.eq."rmGMST_EM") then   ; remove ensemble mean global TAS
     if (isatt(sopt_em,"is_all_missing")) then
        sarr = sarr@_FillValue
        sarr@is_all_missing = True
     else
        scoswgt=cos(((4.*atan(1.0))/180.)*sopt_em&lat)
        scoswgt!0 = "lat"
        scoswgt&lat = sopt_em&lat

        sEM_aa := wgt_areaave(sopt_em(:,{-90:90},:),scoswgt({-90:90}),1.0,0)   
        sEM_rc := regCoef_n(sEM_aa,sarr,0,0)
        sarr_save := sarr
        sarr_save = sarr_save@_FillValue
        do ss = 0,dimsizes(sarr&time)-1
           sarr_save(ss,:,:) = (/ (sEM_rc*sEM_aa(ss)) /)
        end do  
        sarr = (/ sarr - sarr_save /)
        sarr@detrend_option = "ensemble mean global mean tas regressed out"
     end if
  end if
  if (sopt.eq."rmEM") then   ; remove ensemble mean
     if (isatt(sopt_em,"is_all_missing")) then
        sarr = sarr@_FillValue
        sarr@is_all_missing = True
     else
        sarr = (/ sarr - sopt_em /)
        sarr@detrend_option = "ensemble mean removed"
     end if
  end if
  return(sarr)
end

;====================================================================================================================
; This function identifies the version of Image Magick that is loaded locally and returns the correct command.
; While one can call "convert" using version 7, an error message noting the deprecation of convert is returned. 
; To avoid the error message, one needs to call magick instead of convert in version 7.
;
undef("identify_im_version")
function identify_im_version()
local im_command, rt
begin
  im_command = "magick"   ; try to use newer magick command first
  rt = systemfunc("magick -version 2> /dev/null")
  if (ismissing(rt(0))) then   ; but if magick is not there, use convert
     im_command = "convert"
  end if
  return(im_command)
end

