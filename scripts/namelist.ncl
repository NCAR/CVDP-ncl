; use the user specified namelist / namelist_obs files to locate
; the files to be used, and write those file paths to namelist_byvar/namelist_*
; for use by other CVDP scripts.
;
; Note: ".nc" is removed from the paths given in namelist. 
;
load "$CVDP_SCRIPTS/functions.ncl"

begin
  print("Starting: namelist.ncl")
  o = getenv("OBS")
  case_sens = getenv("MACHINE")
  runstyle = tointeger(getenv("RUNSTYLE"))
  
  if (o.eq."True") then
     obsflag = True
  else
     obsflag = False
  end if
  
  if (.not.isfilepresent2("namelist_byvar/")) then
     system("mkdir namelist_byvar")
  end if
  
  nsim = numAsciiRow("namelist")
  na = asciiread("namelist",(/nsim/),"string")
  
  blankrow = ind(na.eq."")
  if (.not.any(ismissing(blankrow))) then
     goodrows = ind(na.ne."")
     na2 = na(goodrows)
     delete(na)
     na = na2
     delete(na2)
     nsim = dimsizes(na)
  end if     

;  print(na)

  system("   export NSIM="+nsim)
  
  nentry = numAsciiCol("namelist")
  names = new(nsim,"string")
  paths = new(nsim,"string")
  syear = new(nsim,"integer",-999)
  eyear = new(nsim,"integer",-999)
  names_EM = new(nsim,"string")
  names_EM = names_EM@_FillValue
  EM_num = new(nsim,integer)

;  So if na does not have 5 str_get_field entries:
;     - 1 - Verify runstyle eq 1, if not exit out and print descriptive error message
;     - 2 - Set names_EM = "-1-Individual Member"    ; check str_split call below to make sure this is OK
;  If na does have 5 str_get_field entries
;     - 1 - Verify runstyle = 2,3, if not exit out and print descriptive error message
    
  delim = "|"
  r1cntr = -1
  do gg = 0,nsim-1
     names(gg) = str_strip(str_get_field(na(gg),1,delim))
     paths(gg) = str_strip(str_get_field(na(gg),2,delim))
     syear(gg) = stringtointeger(str_strip(str_get_field(na(gg),3,delim)))
     eyear(gg) = stringtointeger(str_strip(str_get_field(na(gg),4,delim)))
     
     if (str_get_field(na(gg),5,delim).eq."") then
        if (runstyle.eq.1) then
           names_EM(gg) = r1cntr+"-Individual Simulation"
           EM_num(gg) = r1cntr
           r1cntr = r1cntr-1
        else
           print("Warning! CVDP set to run in Ensemble Mode (runstyle=2), but ensemble numbers are not assigned to each run in namelist. See documentation. Not creating variable namelists.")
           exit
        end if
     else
        if (runstyle.eq.1) then
           print("Warning! CVDP set to run in Individual Member Mode (runstyle=1), but ensemble numbers have been assigned to each run in namelist. See documentation, and remove the ensemble number and name assignments. Not creating variable namelists.")
           exit
        else
           names_EM(gg) = str_strip(str_get_field(na(gg),5,delim))
           temp = str_split(names_EM(gg),"-")
           EM_num(gg) = toint(temp(0))
           delete(temp)
        end if
     end if
  end do
  delete([/na,delim/])

  if (runstyle.ge.2) then
     testr := ind(EM_num.eq.1)
     if (dimsizes(testr).eq.1) then
        if (ismissing(testr)) then
           print("Ensemble number assignment must start with the number 1 (and be sequential). Please reset the ensemble number assignments in namelist, and start with the number 1 (ex. | 1-CESM1 Control). Exiting.")
           exit
        end if
     end if
  end if

  do gg = min(EM_num),max(EM_num)    ; check that every member of an ensemble span the same number of years, and if not, reset the years to a common span (if possible)
     wind := ind(EM_num.eq.gg)
     if (dimsizes(wind).eq.1) then
        if (ismissing(wind)) then
           print("Ensemble number assignment must be sequential, starting with the number 1. Number "+gg+" has not been set. Please alter the ensemble number assignments to be sequential in namelist. Exiting.")
           exit
        end if
     end if
     yspan := eyear(wind) - syear(wind)
     if (min(yspan).ne.max(yspan)) then
        print("namelist.ncl: Each member of an ensemble must span the same number of years. Resetting "+names_EM(wind(0))+" ensemble to common year span of "+min(yspan)+" years.") 
        eyear(wind) = syear(wind)+min(yspan)
     end if
;     if (.not.all(syear(wind(0)).eq.syear(wind))) then
;        print("namelist.ncl: Each member of an ensemble must start on the same year. Resetting "+names_EM(wind(0))+" ensemble to common start year.") 
;        syear(wind) = max(syear(wind))
;     end if
;     if (.not.all(eyear(wind(0)).eq.eyear(wind))) then
;        print("namelist.ncl: Each member of an ensemble must start on the same year. Resetting "+names_EM(wind(0))+" ensemble to common end year.") 
;        eyear(wind) = min(eyear(wind))
;     end if
  end do

  do gg = 0,nsim-1         ; if path ends in .nc remove it. (It will get appended to the end of the path automatically when searching below.)
     paths(gg) = str_sub_str(paths(gg),".nc","")
  end do
;----- Read in namelist_obs, and check number of supplied Observational datasets ------

  maxnumobs = 0    ; set maximum number of obs datasets per variable. 

  if (obsflag) then
     nobs    = numAsciiRow("namelist_obs")
     nentryB = numAsciiCol("namelist_obs")

     if (nobs.lt.1) then
        print("At least one observational dataset is required for the following variables: ts, tas, pr and psl.")
        print("Observational datasets are available on the CVDP website, and should be set in namelist_obs.")
        exit       
     end if

     vnamesB  = new(nobs,"string")
     namesB  = new(nobs,"string")
     pathsB  = new(nobs,"string")
     syearBT  = new(nobs,"string")
     eyearBT  = new(nobs,"string")
     syearB  = new(nobs,"integer")
     eyearB  = new(nobs,"integer")
  
     na = asciiread("namelist_obs",(/nobs/),"string")
     delim = "|"
     do gg = 0,nobs-1
        vnamesB(gg) = str_strip(str_get_field(na(gg),1,delim))
        namesB(gg)  = str_strip(str_get_field(na(gg),2,delim))
        pathsB(gg)  = str_strip(str_get_field(na(gg),3,delim))
        syearBT(gg) = str_strip(str_get_field(na(gg),4,delim))
        eyearBT(gg) = str_strip(str_get_field(na(gg),5,delim))

        testF := systemfunc("ls "+pathsB(gg))
        if (ismissing(testF(0))) then   ; check to see if the specified observational file is present, if not, set to missing
           pathsB(gg) = pathsB@_FillValue
        end if
        if (syearBT(gg).eq."") then
           syearBT(gg) = "-999"
           eyearBT(gg) = "-999"
        end if   
       
     end do
     
     maxnumobs = max((/dimsizes(ind(vnamesB.eq."TS")),dimsizes(ind(vnamesB.eq."PSL")),dimsizes(ind(vnamesB.eq."TREFHT")), \
                       dimsizes(ind(vnamesB.eq."PRECT")),dimsizes(ind(vnamesB.eq."MOC")), \
                      dimsizes(ind(vnamesB.eq."aice_nh")),dimsizes(ind(vnamesB.eq."aice_sh"))/))
     syearB = stringtointeger(syearBT)
     eyearB = stringtointeger(eyearBT)
     
     do gg = 0,nobs-1      ; check to see if any names are duplicated. If they are, add a "_2", "_3" to the name
        dupn = ind(namesB.eq.namesB(gg))            ; this is needed so that each output .nc file has a different name
        if (dimsizes(dupn).ge.2) then
           do hh = 1,dimsizes(dupn)-1
              namesB(dupn(hh)) = namesB(dupn(hh))+"_"+hh
           end do
        end if
        delete(dupn)
     end do
     delete([/eyearBT,syearBT/])
     delete([/na,delim,nentryB,nobs/])
  end if
;  print(vnamesB+" "+namesB+" "+pathsB+" "+syearB+" "+eyearB)

;----- TS section---------------
  namelist_ts = new(nsim+maxnumobs,string)
  if (obsflag) then
     ts_i = ind(vnamesB.eq."TS")
     if (.not.ismissing(ts_i(0))) then
        incr = dimsizes(ts_i)
        do gg = 0,incr-1
           namelist_ts(gg) = namesB(ts_i(gg))+" | "+pathsB(ts_i(gg))+" | "+syearB(ts_i(gg))+" | "+eyearB(ts_i(gg))+" | 0-Observations" 
        end do
        if (incr.lt.maxnumobs) then     ; fill in the missing obs rows with the first obs file, altering the name slightly for .nc write-outs
           if (.not.ismissing(namelist_ts(0))) then
              nmiss = ind(ismissing(namelist_ts(:maxnumobs-1)))
              do hh = nmiss(0),nmiss(dimsizes(nmiss)-1)
                 namelist_ts(hh) = namesB(ts_i(0))+"_"+hh+" | "+pathsB(ts_i(0))+" | "+syearB(ts_i(0))+" | "+eyearB(ts_i(0))+" | 0-Observations"
              end do
              delete(nmiss)
           end if
        end if
        delete(incr)
     else
        print("Observational dataset is required for TS. Please specify TS dataset in namelist_obs. Observational datasets available on CVDP website.")
        exit
     end if
     delete(ts_i)
  end if  
  
  if (case_sens.eq."True") then
     tstring1 = "TS,ts,t_surf,sst,tos"        ; list in order of likelihood/preference: CESM name, CMIP name, other
  else
     tstring1 = "TS,t_surf,sst,tos"
  end if
  sstr := str_split(tstring1,",")

  do gg = 0,nsim-1
     do hh = 0,dimsizes(sstr)-1
        namelist_ts(gg+maxnumobs) =  names(gg)+" | missing | "+syear(gg)+" | "+eyear(gg)+" | "+names_EM(gg)  ; set to missing as default
        fsst := systemfunc("bash -c 'ls "+paths(gg)+"*."+sstr(hh)+".*.nc 2> /dev/null'")   ; /dev/null suppresses all standard error output
        if (.not.ismissing(fsst(0))) then
           if (dimsizes(fsst).eq.1) then
              fsst@path = fsst
           else
              fsst@path = paths(gg)+"*."+sstr(hh)+".*.nc"
           end if
           namelist_ts(gg+maxnumobs) =  names(gg)+" | "+fsst@path+" | "+syear(gg)+" | "+eyear(gg)+" | "+names_EM(gg)
           break
        else  ; try different method to find files
           tpath := str_sub_str(paths(gg),"/*/","/"+sstr(hh)+"/") 
           tpath = str_sub_str(tpath,"/*_","/"+sstr(hh)+"_")
           fsst2 := systemfunc("bash -c 'ls "+tpath+"*.nc 2> /dev/null'")
           if (.not.ismissing(fsst2(0))) then
              textval = True
              do jj = 0,dimsizes(fsst2)-1
                 u = addfile(fsst2(jj),"r")
                 if (str_match_bool(fsst2(jj),sstr(hh)).and.isfilevar(u,sstr(hh))) then   ; make sure all files identified have sstr(hh) in their file name and as a variable in the file
                 else
                    textval = False
                 end if
                 delete(u)
              end do
              if (textval) then
                 namelist_ts(gg+maxnumobs) =  names(gg)+" | "+tpath+"*.nc | "+syear(gg)+" | "+eyear(gg)+" | "+names_EM(gg)
                 break
              end if
           end if
        end if
        tpath := str_sub_str(paths(gg),"/*/","/"+sstr(hh)+"/")    ; try a 3rd method, looking for files starting with "$variable_"
        tpath = str_sub_str(tpath,"/*_","/"+sstr(hh)+"_")
        fsst3 := systemfunc("bash -c 'ls "+tpath+sstr(hh)+"_*.nc 2> /dev/null'")
        if (.not.ismissing(fsst3(0))) then
           namelist_ts(gg+maxnumobs) =  names(gg)+" | "+tpath+sstr(hh)+"_*.nc | "+syear(gg)+" | "+eyear(gg)+" | "+names_EM(gg)
           break
        end if
        fsst4 := systemfunc("bash -c 'ls "+tpath+sstr(hh)+".*.nc 2> /dev/null'")     ; try a 4th method, looking for files starting with "$variable."
        if (.not.ismissing(fsst4(0))) then
           namelist_ts(gg+maxnumobs) =  names(gg)+" | "+tpath+sstr(hh)+".*.nc | "+syear(gg)+" | "+eyear(gg)+" | "+names_EM(gg)
           break
        end if
     end do
  end do  
  asciiwrite("namelist_byvar/namelist_ts",namelist_ts)
;------- PSL section----------------------------  
  namelist_psl = new(nsim+maxnumobs,string)
  if (obsflag) then
     psl_i = ind(vnamesB.eq."PSL")
     if (.not.ismissing(psl_i(0))) then
        incr = dimsizes(psl_i)
        do gg = 0,incr-1
           namelist_psl(gg) = namesB(psl_i(gg))+" | "+pathsB(psl_i(gg))+" | "+syearB(psl_i(gg))+" | "+eyearB(psl_i(gg))+" | 0-Observations"
        end do
        if (incr.lt.maxnumobs) then     ; fill in the missing obs rows with the first obs file, altering the name slightly for .nc write-outs
           if (.not.ismissing(namelist_psl(0))) then
              nmiss = ind(ismissing(namelist_psl(:maxnumobs-1)))
              do hh = nmiss(0),nmiss(dimsizes(nmiss)-1)
                 namelist_psl(hh) = namesB(psl_i(0))+"_"+hh+" | "+pathsB(psl_i(0))+" | "+syearB(psl_i(0))+" | "+eyearB(psl_i(0))+" | 0-Observations"
              end do
              delete(nmiss)
           end if
        end if
        delete(incr)
     else
        print("Observational dataset is required for PSL. Please specify PSL dataset in namelist_obs. Observational datasets available on CVDP website.")
        exit
     end if
     delete(psl_i)
  end if  
  
  if (case_sens.eq."True") then
     tstring1 = "PSL,psl,SLP,slp"       ; list in order of likelihood/preference: CESM name, CMIP name, other
  else
     tstring1 = "PSL,slp"
  end if
  sstr := str_split(tstring1,",")

  do gg = 0,nsim-1
     do hh = 0,dimsizes(sstr)-1
        namelist_psl(gg+maxnumobs) =  names(gg)+" | missing | "+syear(gg)+" | "+eyear(gg)+" | "+names_EM(gg)     ; set to missing as default
        fsst := systemfunc("bash -c 'ls "+paths(gg)+"*."+sstr(hh)+".*.nc 2> /dev/null'")   ; /dev/null suppresses all standard error output
        if (.not.ismissing(fsst(0))) then
           if (dimsizes(fsst).eq.1) then
              fsst@path = fsst
           else
              fsst@path = paths(gg)+"*."+sstr(hh)+".*.nc"
           end if
           namelist_psl(gg+maxnumobs) =  names(gg)+" | "+fsst@path+" | "+syear(gg)+" | "+eyear(gg)+" | "+names_EM(gg)
           break
        else  ; try different method to find files
           tpath := str_sub_str(paths(gg),"/*/","/"+sstr(hh)+"/") 
           tpath = str_sub_str(tpath,"/*_","/"+sstr(hh)+"_")
           fsst2 := systemfunc("bash -c 'ls "+tpath+"*.nc 2> /dev/null'")
           if (.not.ismissing(fsst2(0))) then
              textval = True
              do jj = 0,dimsizes(fsst2)-1
                 u = addfile(fsst2(jj),"r")
                 if (str_match_bool(fsst2(jj),sstr(hh)).and.isfilevar(u,sstr(hh))) then   ; make sure all files identified have sstr(hh) in their file name and as a variable in the file
                 else
                    textval = False
                 end if
                 delete(u)
              end do
              if (textval) then
                 namelist_psl(gg+maxnumobs) =  names(gg)+" | "+tpath+"*.nc | "+syear(gg)+" | "+eyear(gg)+" | "+names_EM(gg)
                 break
              end if
           end if
        end if
        tpath := str_sub_str(paths(gg),"/*/","/"+sstr(hh)+"/")    ; try a 3rd method, looking for files starting with "$variable_"
        tpath = str_sub_str(tpath,"/*_","/"+sstr(hh)+"_")
        fsst3 := systemfunc("bash -c 'ls "+tpath+sstr(hh)+"_*.nc 2> /dev/null'")
        if (.not.ismissing(fsst3(0))) then
           namelist_psl(gg+maxnumobs) =  names(gg)+" | "+tpath+sstr(hh)+"_*.nc | "+syear(gg)+" | "+eyear(gg)+" | "+names_EM(gg)
           break
        end if
        fsst4 := systemfunc("bash -c 'ls "+tpath+sstr(hh)+".*.nc 2> /dev/null'")     ; try a 4th method, looking for files starting with "$variable."
        if (.not.ismissing(fsst4(0))) then
           namelist_psl(gg+maxnumobs) =  names(gg)+" | "+tpath+sstr(hh)+".*.nc | "+syear(gg)+" | "+eyear(gg)+" | "+names_EM(gg)
           break
        end if
     end do
  end do  
  asciiwrite("namelist_byvar/namelist_psl",namelist_psl)
;------- TREFHT section----------------------------  
  namelist_trefht = new(nsim+maxnumobs,string)
  if (obsflag) then
     trefht_i = ind(vnamesB.eq."TREFHT")
     if (.not.ismissing(trefht_i(0))) then
        incr = dimsizes(trefht_i)
        do gg = 0,incr-1
           namelist_trefht(gg) = namesB(trefht_i(gg))+" | "+pathsB(trefht_i(gg))+" | "+syearB(trefht_i(gg))+" | "+eyearB(trefht_i(gg))+" | 0-Observations" 
        end do
        if (incr.lt.maxnumobs) then     ; fill in the missing obs rows with the first obs file, altering the name slightly for .nc write-outs
           if (.not.ismissing(namelist_trefht(0))) then
              nmiss = ind(ismissing(namelist_trefht(:maxnumobs-1)))
              do hh = nmiss(0),nmiss(dimsizes(nmiss)-1)
                 namelist_trefht(hh) = namesB(trefht_i(0))+"_"+hh+" | "+pathsB(trefht_i(0))+" | "+syearB(trefht_i(0))+" | "+eyearB(trefht_i(0))+" | 0-Observations"
              end do
              delete(nmiss)
           end if
        end if
        delete(incr)
     else
        print("Observational dataset is required for TREFHT. Please specify TREFHT dataset in namelist_obs. Observational datasets available on CVDP website.")
        exit
     end if
     delete(trefht_i)
  end if 
  
  if (case_sens.eq."True") then
     tstring1 = "TREFHT,tas,t_ref,T2"   ; list in order of likelihood/preference: CESM name, CMIP name, other
  else
     tstring1 = "TREFHT,tas,t_ref,T2"
  end if
  sstr := str_split(tstring1,",")

  do gg = 0,nsim-1
     do hh = 0,dimsizes(sstr)-1
        namelist_trefht(gg+maxnumobs) =  names(gg)+" | missing | "+syear(gg)+" | "+eyear(gg)+" | "+names_EM(gg)  ; set to missing as default
        fsst := systemfunc("bash -c 'ls "+paths(gg)+"*."+sstr(hh)+".*.nc 2> /dev/null'")   ; /dev/null suppresses all standard error output
        if (.not.ismissing(fsst(0))) then
           if (dimsizes(fsst).eq.1) then
              fsst@path = fsst
           else
              fsst@path = paths(gg)+"*."+sstr(hh)+".*.nc"
           end if
           namelist_trefht(gg+maxnumobs) =  names(gg)+" | "+fsst@path+" | "+syear(gg)+" | "+eyear(gg)+" | "+names_EM(gg)
           break
        else  ; try different method to find files
           tpath := str_sub_str(paths(gg),"/*/","/"+sstr(hh)+"/") 
           tpath = str_sub_str(tpath,"/*_","/"+sstr(hh)+"_")
           fsst2 := systemfunc("bash -c 'ls "+tpath+"*.nc 2> /dev/null'")
           if (.not.ismissing(fsst2(0))) then
              textval = True
              do jj = 0,dimsizes(fsst2)-1
                 u = addfile(fsst2(jj),"r")
                 if (str_match_bool(fsst2(jj),sstr(hh)).and.isfilevar(u,sstr(hh))) then   ; make sure all files identified have sstr(hh) in their file name and as a variable in the file
                 else
                    textval = False
                 end if
                 delete(u)
              end do
              if (textval) then
                 namelist_trefht(gg+maxnumobs) =  names(gg)+" | "+tpath+"*.nc | "+syear(gg)+" | "+eyear(gg)+" | "+names_EM(gg)
                 break
              end if
           end if
        end if
        tpath := str_sub_str(paths(gg),"/*/","/"+sstr(hh)+"/")    ; try a 3rd method, looking for files starting with "$variable_"
        tpath = str_sub_str(tpath,"/*_","/"+sstr(hh)+"_")
        fsst3 := systemfunc("bash -c 'ls "+tpath+sstr(hh)+"_*.nc 2> /dev/null'")
        if (.not.ismissing(fsst3(0))) then
           namelist_trefht(gg+maxnumobs) =  names(gg)+" | "+tpath+sstr(hh)+"_*.nc | "+syear(gg)+" | "+eyear(gg)+" | "+names_EM(gg)
           break
        end if
        fsst4 := systemfunc("bash -c 'ls "+tpath+sstr(hh)+".*.nc 2> /dev/null'")     ; try a 4th method, looking for files starting with "$variable."
        if (.not.ismissing(fsst4(0))) then
           namelist_trefht(gg+maxnumobs) =  names(gg)+" | "+tpath+sstr(hh)+".*.nc | "+syear(gg)+" | "+eyear(gg)+" | "+names_EM(gg)
           break
        end if
     end do
  end do   
  asciiwrite("namelist_byvar/namelist_trefht",namelist_trefht)  
;------- PRECT section--(more complicated due to PRECC+PRECL, + pr being a common 2 letter combination)------  
  namelist_prect = new(nsim+maxnumobs,string)
  if (obsflag) then
     prect_i = ind(vnamesB.eq."PRECT")
     if (.not.ismissing(prect_i(0))) then
        incr = dimsizes(prect_i)
        do gg = 0,incr-1
           namelist_prect(gg) = namesB(prect_i(gg))+" | "+pathsB(prect_i(gg))+" | "+syearB(prect_i(gg))+" | "+eyearB(prect_i(gg))+" | 0-Observations" 
        end do
        if (incr.lt.maxnumobs) then     ; fill in the missing obs rows with the first obs file, altering the name slightly for .nc write-ouprect
           if (.not.ismissing(namelist_prect(0))) then
              nmiss = ind(ismissing(namelist_prect(:maxnumobs-1)))
              do hh = nmiss(0),nmiss(dimsizes(nmiss)-1)
                 namelist_prect(hh) = namesB(prect_i(0))+"_"+hh+" | "+pathsB(prect_i(0))+" | "+syearB(prect_i(0))+" | "+eyearB(prect_i(0))+" | 0-Observations"
              end do
              delete(nmiss)
           end if
        end if
        delete(incr)
     else
        print("Observational dataset is required for PRECT. Please specify PRECT dataset in namelist_obs. Observational datasets available on CVDP website.")
        exit
     end if
     delete(prect_i)
  end if 

  if (case_sens.eq."True") then
     tstring1 = "PRECT,PRECC,pr,precip,prate,prcp"   ; list in order of likelihood/preference: CESM name, CMIP name, other
  else
     tstring1 = "PRECT,PRECC,pr,precip,prate,prcp"
  end if
  sstr := str_split(tstring1,",")

  do gg = 0,nsim-1
     do hh = 0,dimsizes(sstr)-1
        namelist_prect(gg+maxnumobs) =  names(gg)+" | missing | "+syear(gg)+" | "+eyear(gg)+" | "+names_EM(gg)  ; set to missing as default
        fsst := systemfunc("bash -c 'ls "+paths(gg)+"*."+sstr(hh)+".*.nc 2> /dev/null'")   ; /dev/null suppresses all standard error output
        if (.not.ismissing(fsst(0))) then
           if (sstr(hh).eq."PRECC") then   ; add PRECL to search string
              if (dimsizes(fsst).eq.1) then
                 fsst@path = str_sub_str(fsst,".PRECC.",".{PRECC,PRECL}.")
              else
                 fsst@path = str_sub_str(paths(gg)+"*."+sstr(hh)+".*.nc",".PRECC.",".{PRECC,PRECL}.")
              end if
              fsst@path = str_sub_str(fsst@path,"/PRECC/","/{PRECC,PRECL}/")
           else
              if (dimsizes(fsst).eq.1) then
                 fsst@path = fsst
              else
                 fsst@path = paths(gg)+"*."+sstr(hh)+".*.nc"
              end if
           end if
           namelist_prect(gg+maxnumobs) =  names(gg)+" | "+fsst@path+" | "+syear(gg)+" | "+eyear(gg)+" | "+names_EM(gg)
           break
        else    ; if files have not been found, try the following
           if (sstr(hh).eq."PRECC") then
              tstring = "{PRECC,PRECL}"
           else
              tstring = sstr(hh)
           end if
           tpath := str_sub_str(paths(gg),"/*/","/"+tstring+"/") 
           tpath = str_sub_str(tpath,"/*_","/"+tstring+"_")
           fsst2 := systemfunc("bash -c 'ls "+tpath+"*.nc 2> /dev/null'")
           if (.not.ismissing(fsst2(0))) then
              textval = True
              do jj = 0,dimsizes(fsst2)-1
                 u = addfile(fsst2(jj),"r")
                 if (sstr(hh).eq."PRECC") then
                    if ((str_match_bool(fsst2(jj),"PRECC").and.isfilevar(u,"PRECC")).or.(str_match_bool(fsst2(jj),"PRECL").and.isfilevar(u,"PRECL"))) then   ; make sure all files identified have PRECC 
                    else                                                                                                                                     ; or PRECL in their file name and within the file
                       textval = False
                    end if
                 else
                    if (str_match_bool(fsst2(jj),sstr(hh)).and.isfilevar(u,sstr(hh))) then   ; make sure all files identified have sstr(hh) in their file name and as a variable in the file
                    else
                       textval = False
                    end if
                 end if
                 delete(u)
              end do
              if (textval) then
                 namelist_prect(gg+maxnumobs) =  names(gg)+" | "+tpath+"*.nc | "+syear(gg)+" | "+eyear(gg)+" | "+names_EM(gg)
                 break
              end if
           end if
           delete([/tpath,tstring/])
        end if
        if (sstr(hh).eq."PRECC") then
           tstring = "{PRECC,PRECL}"
        else
           tstring = sstr(hh)
        end if
        tpath := str_sub_str(paths(gg),"/*/","/"+tstring+"/") 
        tpath = str_sub_str(tpath,"/*_","/"+tstring+"_")
        fsst3 := systemfunc("bash -c 'ls "+tpath+sstr(hh)+"_*.nc 2> /dev/null'")     ; try a 3rd method, looking for files starting with "$variable_"
        if (.not.ismissing(fsst3(0))) then
           namelist_prect(gg+maxnumobs) =  names(gg)+" | "+tpath+tstring+"_*.nc | "+syear(gg)+" | "+eyear(gg)+" | "+names_EM(gg)
           break
        end if
        fsst4 := systemfunc("bash -c 'ls "+tpath+sstr(hh)+".*.nc 2> /dev/null'")     ; try a 4th method, looking for files starting with "$variable."
        if (.not.ismissing(fsst4(0))) then
           namelist_prect(gg+maxnumobs) =  names(gg)+" | "+tpath+tstring+".*.nc | "+syear(gg)+" | "+eyear(gg)+" | "+names_EM(gg)
           break
        end if
     end do
  end do  
  asciiwrite("namelist_byvar/namelist_prect",namelist_prect)    
;------- MOC section----------------------------  
  namelist_moc = new(nsim+maxnumobs,string)
  if (obsflag) then
     moc_i = ind(vnamesB.eq."MOC")
     if (.not.ismissing(moc_i(0))) then
        incr = dimsizes(moc_i)
        do gg = 0,incr-1
           namelist_moc(gg) = namesB(moc_i(gg))+" | "+pathsB(moc_i(gg))+" | "+syearB(moc_i(gg))+" | "+eyearB(moc_i(gg))+" | 0-Observations" 
        end do
        if (incr.lt.maxnumobs) then     ; fill in the missing obs rows with the first obs file, altering the name slightly for .nc write-outs
           if (.not.ismissing(namelist_moc(0))) then
              nmiss = ind(ismissing(namelist_moc(:maxnumobs-1)))
              do hh = nmiss(0),nmiss(dimsizes(nmiss)-1)
                 namelist_moc(hh) = namesB(moc_i(0))+"_"+hh+" | "+pathsB(moc_i(0))+" | "+syearB(moc_i(0))+" | "+eyearB(moc_i(0))+" | 0-Observations"
              end do
              delete(nmiss)
           end if
        end if
        delete(incr)
     end if
     delete(moc_i)
  end if 

  if (case_sens.eq."True") then
     tstring1 = "MOC,msftmyz,msftmz,stfmmc"   ; list in order of likelihood/preference: CESM name, CMIP name, other
  else
     tstring1 = "MOC,msftmyz,msftmz,stfmmc"
  end if
  sstr := str_split(tstring1,",")

  do gg = 0,nsim-1
     do hh = 0,dimsizes(sstr)-1
        namelist_moc(gg+maxnumobs) =  names(gg)+" | missing | "+syear(gg)+" | "+eyear(gg)+" | "+names_EM(gg)  ; set to missing as default
        fsst := systemfunc("bash -c 'ls "+paths(gg)+"*."+sstr(hh)+".*.nc 2> /dev/null'")   ; /dev/null suppresses all standard error output
        if (.not.ismissing(fsst(0))) then
           if (dimsizes(fsst).eq.1) then
              fsst@path = fsst
           else
              fsst@path = paths(gg)+"*."+sstr(hh)+".*.nc"
           end if
           namelist_moc(gg+maxnumobs) =  names(gg)+" | "+fsst@path+" | "+syear(gg)+" | "+eyear(gg)+" | "+names_EM(gg)
           break
        else  ; try different method to find files
           tpath := str_sub_str(paths(gg),"/*/","/"+sstr(hh)+"/") 
           tpath = str_sub_str(tpath,"/*_","/"+sstr(hh)+"_")
           fsst2 := systemfunc("bash -c 'ls "+tpath+"*.nc 2> /dev/null'")
           if (.not.ismissing(fsst2(0))) then
              textval = True
              do jj = 0,dimsizes(fsst2)-1
                 u = addfile(fsst2(jj),"r")
                 if (str_match_bool(fsst2(jj),sstr(hh)).and.isfilevar(u,sstr(hh))) then   ; make sure all files identified have sstr(hh) in their file name and as a variable in the file
                 else
                    textval = False
                 end if
                 delete(u)
              end do
              if (textval) then
                 namelist_moc(gg+maxnumobs) =  names(gg)+" | "+tpath+"*.nc | "+syear(gg)+" | "+eyear(gg)+" | "+names_EM(gg)
                 break
              end if
           end if
        end if
        tpath := str_sub_str(paths(gg),"/*/","/"+sstr(hh)+"/")    ; try a 3rd method, looking for files starting with "$variable_"
        tpath = str_sub_str(tpath,"/*_","/"+sstr(hh)+"_")
        fsst3 := systemfunc("bash -c 'ls "+tpath+sstr(hh)+"_*.nc 2> /dev/null'")
        if (.not.ismissing(fsst3(0))) then
           namelist_moc(gg+maxnumobs) =  names(gg)+" | "+tpath+sstr(hh)+"_*.nc | "+syear(gg)+" | "+eyear(gg)+" | "+names_EM(gg)
           break
        end if
        fsst4 := systemfunc("bash -c 'ls "+tpath+sstr(hh)+".*.nc 2> /dev/null'")     ; try a 4th method, looking for files starting with "$variable."
        if (.not.ismissing(fsst4(0))) then
           namelist_moc(gg+maxnumobs) =  names(gg)+" | "+tpath+sstr(hh)+".*.nc | "+syear(gg)+" | "+eyear(gg)+" | "+names_EM(gg)
           break
        end if
     end do
  end do   
  asciiwrite("namelist_byvar/namelist_moc",namelist_moc) 
;------- SSH section----------------------------  
  namelist_ssh = new(nsim+maxnumobs,string)
  if (obsflag) then
     ssh_i = ind(vnamesB.eq."SSH")
     if (.not.ismissing(ssh_i(0))) then
        incr = dimsizes(ssh_i)
        do gg = 0,incr-1
           namelist_ssh(gg) = namesB(ssh_i(gg))+" | "+pathsB(ssh_i(gg))+" | "+syearB(ssh_i(gg))+" | "+eyearB(ssh_i(gg))+" | 0-Observations" 
        end do
        if (incr.lt.maxnumobs) then     ; fill in the missing obs rows with the first obs file, altering the name slightly for .nc write-outs
           if (.not.ismissing(namelist_ssh(0))) then
              nmiss = ind(ismissing(namelist_ssh(:maxnumobs-1)))
              do hh = nmiss(0),nmiss(dimsizes(nmiss)-1)
                 namelist_ssh(hh) = namesB(ssh_i(0))+"_"+hh+" | "+pathsB(ssh_i(0))+" | "+syearB(ssh_i(0))+" | "+eyearB(ssh_i(0))+" | 0-Observations" 
              end do
              delete(nmiss)
           end if
        end if
        delete(incr)
     end if
     delete(ssh_i)
  end if 

  if (case_sens.eq."True") then
     tstring1 = "SSH,zos"   ; list in order of likelihood/preference: CESM name, CMIP name, other
  else
     tstring1 = "SSH,zos"
  end if
  sstr := str_split(tstring1,",")

  do gg = 0,nsim-1
     do hh = 0,dimsizes(sstr)-1
        namelist_ssh(gg+maxnumobs) =  names(gg)+" | missing | "+syear(gg)+" | "+eyear(gg)+" | "+names_EM(gg)  ; set to missing as default
        fsst := systemfunc("bash -c 'ls "+paths(gg)+"*."+sstr(hh)+".*.nc 2> /dev/null'")   ; /dev/null suppresses all standard error output
        if (.not.ismissing(fsst(0))) then
           if (dimsizes(fsst).eq.1) then
              fsst@path = fsst
           else
              fsst@path = str_sub_str(paths(gg),"/*/","/"+sstr(hh)+"/")+"*."+sstr(hh)+".*.nc"
           end if
           namelist_ssh(gg+maxnumobs) =  names(gg)+" | "+fsst@path+" | "+syear(gg)+" | "+eyear(gg)+" | "+names_EM(gg)
           break
        else  ; try different method to find files
           tpath := str_sub_str(paths(gg),"/*/","/"+sstr(hh)+"/") 
           tpath = str_sub_str(tpath,"/*_","/"+sstr(hh)+"_")
           fsst2 := systemfunc("bash -c 'ls "+tpath+"*.nc 2> /dev/null'")
           if (.not.ismissing(fsst2(0))) then
              textval = True
              do jj = 0,dimsizes(fsst2)-1
                 u = addfile(fsst2(jj),"r")
                 if (str_match_bool(fsst2(jj),sstr(hh)).and.isfilevar(u,sstr(hh))) then   ; make sure all files identified have sstr(hh) in their file name and as a variable in the file
                 else
                    textval = False
                 end if
                 delete(u)
              end do
              if (textval) then
                 namelist_ssh(gg+maxnumobs) =  names(gg)+" | "+tpath+"*.nc | "+syear(gg)+" | "+eyear(gg)+" | "+names_EM(gg)
                 break
              end if
           end if
        end if
        tpath := str_sub_str(paths(gg),"/*/","/"+sstr(hh)+"/")    ; try a 3rd method, looking for files starting with "$variable_"
        tpath = str_sub_str(tpath,"/*_","/"+sstr(hh)+"_")
        fsst3 := systemfunc("bash -c 'ls "+tpath+sstr(hh)+"_*.nc 2> /dev/null'")
        if (.not.ismissing(fsst3(0))) then
           namelist_ssh(gg+maxnumobs) =  names(gg)+" | "+tpath+sstr(hh)+"_*.nc | "+syear(gg)+" | "+eyear(gg)+" | "+names_EM(gg)
           break
        end if
        fsst4 := systemfunc("bash -c 'ls "+tpath+sstr(hh)+".*.nc 2> /dev/null'")     ; try a 4th method, looking for files starting with "$variable."
        if (.not.ismissing(fsst4(0))) then
           namelist_ssh(gg+maxnumobs) =  names(gg)+" | "+tpath+sstr(hh)+".*.nc | "+syear(gg)+" | "+eyear(gg)+" | "+names_EM(gg)
           break
        end if
     end do
  end do   
  asciiwrite("namelist_byvar/namelist_ssh",namelist_ssh) 

;------- aice_nh section----------------------------  
  namelist_aice_nh = new(nsim+maxnumobs,string)
  if (obsflag) then
     aice_nh_i = ind(vnamesB.eq."aice_nh".or.vnamesB.eq."AICE_NH")
     if (.not.ismissing(aice_nh_i(0))) then
        incr = dimsizes(aice_nh_i)
        do gg = 0,incr-1
           namelist_aice_nh(gg) = namesB(aice_nh_i(gg))+" | "+pathsB(aice_nh_i(gg))+" | "+syearB(aice_nh_i(gg))+" | "+eyearB(aice_nh_i(gg))+" | 0-Observations" 
        end do
        if (incr.lt.maxnumobs) then     ; fill in the missing obs rows with the first obs file, altering the name slightly for .nc write-outs
           if (.not.ismissing(namelist_aice_nh(0))) then
              nmiss = ind(ismissing(namelist_aice_nh(:maxnumobs-1)))
              do hh = nmiss(0),nmiss(dimsizes(nmiss)-1)
                 namelist_aice_nh(hh) = namesB(aice_nh_i(0))+"_"+hh+" | "+pathsB(aice_nh_i(0))+" | "+syearB(aice_nh_i(0))+" | "+eyearB(aice_nh_i(0))+" | 0-Observations"
              end do
              delete(nmiss)
           end if
        end if
        delete(incr)
     end if
     delete(aice_nh_i)
  end if 

  if (case_sens.eq."True") then
     tstring1 = "aice_nh,aice,siconc,sic,CN"   ; list in order of likelihood/preference: CESM name, CMIP name, other
  else                                         ; aice_nh (CESM1 nomenclature used in some data) should be checked before aice 
     tstring1 = "aice_nh,aice,siconc,sic,CN"
  end if
  sstr := str_split(tstring1,",")

  do gg = 0,nsim-1
     do hh = 0,dimsizes(sstr)-1
        namelist_aice_nh(gg+maxnumobs) =  names(gg)+" | missing | "+syear(gg)+" | "+eyear(gg)+" | "+names_EM(gg) ; set to missing as default
        fsst := systemfunc("bash -c 'ls "+paths(gg)+"*."+sstr(hh)+".*.nc 2> /dev/null'")   ; /dev/null suppresses all standard error output
        if (.not.ismissing(fsst(0))) then
           if (dimsizes(fsst).eq.1) then
              fsst@path = fsst
           else
              fsst@path = paths(gg)+"*."+sstr(hh)+".*.nc"
           end if
           namelist_aice_nh(gg+maxnumobs) =  names(gg)+" | "+fsst@path+" | "+syear(gg)+" | "+eyear(gg)+" | "+names_EM(gg)
           break
        else  ; try different method to find files
           tpath := str_sub_str(paths(gg),"/*/","/"+sstr(hh)+"/") 
           tpath = str_sub_str(tpath,"/*_","/"+sstr(hh)+"_")
           fsst2 := systemfunc("bash -c 'ls "+tpath+"*.nc 2> /dev/null'")
           if (.not.ismissing(fsst2(0))) then
              textval = True
              do jj = 0,dimsizes(fsst2)-1
                 u = addfile(fsst2(jj),"r")
                 if (str_match_bool(fsst2(jj),sstr(hh)).and.isfilevar(u,sstr(hh))) then   ; make sure all files identified have sstr(hh) in their file name and as a variable in the file
                 else
                    textval = False
                 end if
                 delete(u)
              end do
              if (textval) then
                 namelist_aice_nh(gg+maxnumobs) =  names(gg)+" | "+tpath+"*.nc | "+syear(gg)+" | "+eyear(gg)+" | "+names_EM(gg)
                 break
              end if
           end if
        end if
        tpath := str_sub_str(paths(gg),"/*/","/"+sstr(hh)+"/")    ; try a 3rd method, looking for files starting with "$variable_"
        tpath = str_sub_str(tpath,"/*_","/"+sstr(hh)+"_")
        fsst3 := systemfunc("bash -c 'ls "+tpath+sstr(hh)+"_*.nc 2> /dev/null'")
        if (.not.ismissing(fsst3(0))) then
           namelist_aice_nh(gg+maxnumobs) =  names(gg)+" | "+tpath+sstr(hh)+"_*.nc | "+syear(gg)+" | "+eyear(gg)+" | "+names_EM(gg)
           break
        end if
        fsst4 := systemfunc("bash -c 'ls "+tpath+sstr(hh)+".*.nc 2> /dev/null'")     ; try a 4th method, looking for files starting with "$variable."
        if (.not.ismissing(fsst4(0))) then
           namelist_aice_nh(gg+maxnumobs) =  names(gg)+" | "+tpath+sstr(hh)+".*.nc | "+syear(gg)+" | "+eyear(gg)+" | "+names_EM(gg)
           break
        end if
     end do
  end do   
  asciiwrite("namelist_byvar/namelist_aice_nh",namelist_aice_nh) 
;------- aice_sh section----------------------------  
  namelist_aice_sh = new(nsim+maxnumobs,string)
  if (obsflag) then
     aice_sh_i = ind(vnamesB.eq."aice_sh".or.vnamesB.eq."AICE_SH")
     if (.not.ismissing(aice_sh_i(0))) then
        incr = dimsizes(aice_sh_i)
        do gg = 0,incr-1
           namelist_aice_sh(gg) = namesB(aice_sh_i(gg))+" | "+pathsB(aice_sh_i(gg))+" | "+syearB(aice_sh_i(gg))+" | "+eyearB(aice_sh_i(gg))+" | 0-Observations" 
        end do
        if (incr.lt.maxnumobs) then     ; fill in the missing obs rows with the first obs file, altering the name slightly for .nc write-outs
           if (.not.ismissing(namelist_aice_sh(0))) then
              nmiss = ind(ismissing(namelist_aice_sh(:maxnumobs-1)))
              do hh = nmiss(0),nmiss(dimsizes(nmiss)-1)
                 namelist_aice_sh(hh) = namesB(aice_sh_i(0))+"_"+hh+" | "+pathsB(aice_sh_i(0))+" | "+syearB(aice_sh_i(0))+" | "+eyearB(aice_sh_i(0))+" | 0-Observations"
              end do
              delete(nmiss)
           end if
        end if
        delete(incr)
     end if
     delete(aice_sh_i)
  end if 

  if (case_sens.eq."True") then
     tstring1 = "aice_sh,aice,siconc,sic,CN"   ; list in order of likelihood/preference: CESM name, CMIP name, other
  else                                         ; aice_sh (CESM1 nomenclature used in some data) should be checked before aice 
     tstring1 = "aice_sh,aice,siconc,sic,CN"
  end if
  sstr := str_split(tstring1,",")

  do gg = 0,nsim-1
     do hh = 0,dimsizes(sstr)-1
        namelist_aice_sh(gg+maxnumobs) =  names(gg)+" | missing | "+syear(gg)+" | "+eyear(gg)+" | "+names_EM(gg) ; set to missing as default
        fsst := systemfunc("bash -c 'ls "+paths(gg)+"*."+sstr(hh)+".*.nc 2> /dev/null'")   ; /dev/null suppresses all standard error output
        if (.not.ismissing(fsst(0))) then
           if (dimsizes(fsst).eq.1) then
              fsst@path = fsst
           else
              fsst@path = paths(gg)+"*."+sstr(hh)+".*.nc"
           end if
           namelist_aice_sh(gg+maxnumobs) =  names(gg)+" | "+fsst@path+" | "+syear(gg)+" | "+eyear(gg)+" | "+names_EM(gg)
           break
        else  ; try different method to find files
           tpath := str_sub_str(paths(gg),"/*/","/"+sstr(hh)+"/") 
           tpath = str_sub_str(tpath,"/*_","/"+sstr(hh)+"_")
           fsst2 := systemfunc("bash -c 'ls "+tpath+"*.nc 2> /dev/null'")
           if (.not.ismissing(fsst2(0))) then
              textval = True
              do jj = 0,dimsizes(fsst2)-1
                 u = addfile(fsst2(jj),"r")
                 if (str_match_bool(fsst2(jj),sstr(hh)).and.isfilevar(u,sstr(hh))) then   ; make sure all files identified have sstr(hh) in their file name and as a variable in the file
                 else
                    textval = False
                 end if
                 delete(u)
              end do
              if (textval) then
                 namelist_aice_sh(gg+maxnumobs) =  names(gg)+" | "+tpath+"*.nc | "+syear(gg)+" | "+eyear(gg)+" | "+names_EM(gg)
                 break
              end if
           end if
        end if
        tpath := str_sub_str(paths(gg),"/*/","/"+sstr(hh)+"/")    ; try a 3rd method, looking for files starting with "$variable_"
        tpath = str_sub_str(tpath,"/*_","/"+sstr(hh)+"_")
        fsst3 := systemfunc("bash -c 'ls "+tpath+sstr(hh)+"_*.nc 2> /dev/null'")
        if (.not.ismissing(fsst3(0))) then
           namelist_aice_sh(gg+maxnumobs) =  names(gg)+" | "+tpath+sstr(hh)+"_*.nc | "+syear(gg)+" | "+eyear(gg)+" | "+names_EM(gg)
           break
        end if
        fsst4 := systemfunc("bash -c 'ls "+tpath+sstr(hh)+".*.nc 2> /dev/null'")     ; try a 4th method, looking for files starting with "$variable."
        if (.not.ismissing(fsst4(0))) then
           namelist_aice_sh(gg+maxnumobs) =  names(gg)+" | "+tpath+sstr(hh)+".*.nc | "+syear(gg)+" | "+eyear(gg)+" | "+names_EM(gg)
           break
        end if
     end do
  end do    
  asciiwrite("namelist_byvar/namelist_aice_sh",namelist_aice_sh) 
;----------------------------------------------------------------------------
  if (obsflag) then
     delete([/vnamesB,namesB,pathsB,syearB,eyearB/])
  end if
  print("Finished: namelist.ncl")
end
