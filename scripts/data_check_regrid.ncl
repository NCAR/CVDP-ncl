load "$CVDP_SCRIPTS/functions.ncl"

begin
  print("Starting: data_check_regrid.ncl")

  REGRID_TO_RES = getenv("REGRID_TO_RES")  
  REGRID_DIR    = getenv("REGRID_DIR")  

  nvarlist = (/"prect","psl","trefht","ts","aice_nh","aice_sh","ssh"/)
  nvarlist_cap = changeCaseChar(nvarlist)
  nvarlist_ctype = (/"atm","atm","atm","atm","ice","ice","ocn"/)

  vname_pr = (/"PRECC","PRECL","PRECT","pr","PPT","ppt","p","P","precip","PRECIP","tp","prcp","prate"/)

  delim = "|"
  maxnumobs  = 0
  if (fileexists("obs_maxnum")) then
     maxnumobs  = asciiread("obs_maxnum",(/1/),"integer")
  end if
  nsim = numAsciiRow("namelist_byvar/namelist_psl")   ; to get number of obs and model runs
  list_regrid = new((/nsim,dimsizes(nvarlist)/),logical)
  list_regrid = False
  do ee = maxnumobs,nsim-1  ; loop over each run
     do ff = 0,dimsizes(nvarlist)-1   ; loop over each variable from each run
        nsim2 = numAsciiRow("namelist_byvar/namelist_"+nvarlist(ff))
        na := asciiread("namelist_byvar/namelist_"+nvarlist(ff),(/nsim2/),"string")
        names := new(nsim,"string")
        paths := new(nsim,"string")
        do gg = 0,nsim-1
           names(gg) = str_strip(str_get_field(na(gg),1,delim))
           paths(gg) = str_strip(str_get_field(na(gg),2,delim))
        end do
;        print("Checking "+paths(ee))
        
        arr := data_check_2D(paths(ee),nvarlist_cap(ff))    ; check to see if input file has 2D arrays or not. 
        if (arr@is_2D.eq."True") then
           print("Need to regrid: "+paths(ee))
           list_regrid(ee,ff) = True
        else
           if (.not.isatt(arr,"is_all_missing")) then
              print("No need to regrid: "+paths(ee))
           end if
        end if
     end do
  end do
  if (any(list_regrid)) then
     print("Regridding to grid specified in "+REGRID_TO_RES)
  end if
  do ee = maxnumobs,nsim-1  ; loop over each run
     do ff = 0,dimsizes(nvarlist)-1   ; loop over each variable from each run
        if (list_regrid(ee,ff)) then
           a = addfile(REGRID_TO_RES,"r")
           nsim2 = numAsciiRow("namelist_byvar/namelist_"+nvarlist(ff))
           na := asciiread("namelist_byvar/namelist_"+nvarlist(ff),(/nsim2/),"string")
           names := new(nsim,"string")
           paths := new(nsim,"string")
           syear = new(nsim,"integer",-999)
           eyear = new(nsim,"integer",-999)
           names_EM = new(nsim,"string")
           EM_num = new(nsim,"integer",-999)
           do gg = 0,nsim-1
              names(gg) = str_strip(str_get_field(na(gg),1,delim))
              paths(gg) = str_strip(str_get_field(na(gg),2,delim))
              syear(gg) = stringtointeger(str_strip(str_get_field(na(gg),3,delim)))
              eyear(gg) = stringtointeger(str_strip(str_get_field(na(gg),4,delim)))
              temp      = str_split(str_strip(str_get_field(na(gg),5,delim)),"-")
              temp2     = tochar(str_strip(str_get_field(na(gg),5,delim)))
              if (tostring(temp2(0)).eq."-") then
                 EM_num(gg)    = toint(temp(0))*-1
              else
                 EM_num(gg)    = toint(temp(0))
              end if
              names_EM(gg)  = str_join(temp(1:),"-")
              delete([/temp,temp2/])
           end do
        
           InterpMethod = "bilinear"
           Opt                := True
           Opt@SrcTitle       = str_sub_str(str_squeeze(names(ee))," ","_")+" grid"   ; optional
           Opt@WgtFileName    = REGRID_DIR+str_sub_str(str_squeeze(names(ee))," ","_")+"/"+str_sub_str(str_squeeze(names(ee))," ","_")+"_"+nvarlist_ctype(ff)+"_to_.WgtFile_"+InterpMethod+".nc"
           Opt@SrcFileName    = getenv("OUTDIR")+"/SCRIP_grid_description.nc"         ; Name of source and
           Opt@SrcRegional    = False  ; will verify this below
;          Opt@SrcGridType    = "curvilinear"
           Opt@ForceOverwrite = True
           Opt@InterpMethod   = InterpMethod
           Opt@RemoveSrcFile  = True                  ; remove SCRIP grid destination files
           Opt@RemoveDstFile  = True 
           Opt@NoPETLog       = True
           Opt@DstGridType    = "rectilinear"
           Opt@DstFileName    = Opt@DstGridType+".SCRIP_grid_description.nc" 
           Opt@DstRegional    = False
           latn = (/"lat","LAT","latitude","LATITUDE"/)
           lonn = (/"lon","LON","longitude","LONGITUDE"/)
           do mm = 0,dimsizes(latn)-1
              if (isfilevar(a,latn(mm))) then
                 Opt@DstGridLat     := a->$latn(mm)$
                 break
              end if
           end do
           do mm = 0,dimsizes(lonn)-1
              if (isfilevar(a,lonn(mm))) then
                 Opt@DstGridLon     := a->$lonn(mm)$
                 break
              end if
           end do

           Opt2 := True
           nfiles := systemfunc("bash -c 'ls "+paths(ee)+" 2> /dev/null'")   ; /dev/null suppresses all standard error output
           if (.not.ismissing(nfiles(0))) then
              do gg = 0,dimsizes(nfiles)-1
                 arr := data_check_2D(nfiles(gg),nvarlist_cap(ff))   ; read in 2D (time x ncol) data identified at line 33 above for regridding.
                 if (isatt(arr,"is_2D")) then
                    delete(arr@is_2D)
                 end if
                 if (isatt(arr,"original_variable_name")) then
                    vn_save = arr@original_variable_name
                    delete(arr@original_variable_name)
                 else
                    vn_save = nvarlist(ff)
                 end if
                 if (nvarlist_ctype(ff).eq."ice".or.nvarlist_ctype(ff).eq."ocn") then
                    Opt@SrcMask2D        = where(.not.ismissing(arr(0,:)),1,0)  ; land/ocean mask
                 else
                    if (isatt(Opt,"SrcMask2D")) then
                       delete(Opt@SrcMask2D)
                    end if
                 end if
                 Opt@SrcGridLat      = arr@lat                  ; source grid
                 Opt@SrcGridLon      = arr@lon
                 strsp = str_split(nfiles(gg),"/")
                 outdir = REGRID_DIR+str_sub_str(str_squeeze(names(ee))," ","_")+"/"+vn_save+"/"
                 if (.not.isfilepresent2(outdir)) then
                    system("mkdir -p "+outdir)
                 end if
                 outname = outdir+strsp(dimsizes(strsp)-1)

                 if (.not.isatt(arr,"is_all_missing")) then
                    if (.not.isfilepresent(outname)) then
                       print("Regridding "+nfiles(gg)+"->"+outname)
                       delete([/arr@lat,arr@lon/])
                       if (.not.isfilepresent(Opt@WgtFileName)) then
                          arr_rg := ESMF_regrid(arr, Opt)
                       else
                          arr_rg := ESMF_regrid_with_weights(arr,Opt@WgtFileName,Opt2)
                       end if
                       b := addfile(outname,"c")
                       b@source = "Regridded using ESMF_regrid within CVDP"
                       b@original_file = nfiles(gg)
                       if (nvarlist_cap(ff).eq."PRECT") then   ; needed as not sure if variable name is PRECC, PRECL or something else
                          z = addfile(nfiles(gg),"r")
                          do hh = 0,dimsizes(vname_pr)-1
                             if (isfilevar(z,vname_pr(hh))) then
                                b->$vname_pr(hh)$ = arr_rg
                                break
                             end if
                          end do
                       else
                          b->$vn_save$ = arr_rg
                       end if
                    end if
                 end if
              end do

              if (vn_save.eq."PRECL") then
                 outdir = str_sub_str(outdir,"/PRECL/","/{PRECC,PRECL}/")
              end if

              paths_spl := str_split(paths(ee),"/")
              na_m := na
              if (ismissing(EM_num(ee))) then
                 na_m(ee) = names(ee)+" | "+outdir+paths_spl(dimsizes(paths_spl)-1)+" | "+syear(ee)+" | "+eyear(ee) 
              else
                 na_m(ee) = names(ee)+" | "+outdir+paths_spl(dimsizes(paths_spl)-1)+" | "+syear(ee)+" | "+eyear(ee)+" | "+EM_num(ee)+"-"+names_EM(ee)
              end if
              asciiwrite("namelist_byvar/namelist_"+nvarlist(ff)+"_mod",na_m)
              system("mv namelist_byvar/namelist_"+nvarlist(ff)+"_mod namelist_byvar/namelist_"+nvarlist(ff))
           end if
        end if
     end do
  end do
  print("Finished: data_check_regrid.ncl")
end

