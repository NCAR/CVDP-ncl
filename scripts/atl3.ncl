; Calculates the ATL3 pattern, timeseries, and spectra.
;
; Variables used: ts, pr, tas
;
load "$CVDP_SCRIPTS/functions.ncl"

begin
  print("Starting: atl3.ncl")

  CREATE_GRAPHICS  = getenv("CREATE_GRAPHICS")
  PNG_SCALE        = tofloat(getenv("PNG_SCALE"))
  OUTPUT_TYPE      = getenv("OUTPUT_TYPE")
  COLORMAP         = getenv("COLORMAP")
  OUTDIR           = getenv("OUTDIR")
  PNG_SCALE_SUMMARY = tofloat(getenv("PNG_SCALE_SUMMARY"))
  REMOVE_TREND_OBS = getenv("REMOVE_TREND_OBS")
  REMOVE_TREND_MODEL = getenv("REMOVE_TREND_MODEL")
  ENSEMBLE_MEAN_DIR = getenv("ENSEMBLE_MEAN_DIR")
  IM_COMMAND = getenv("IM_COMMAND")
  OPT_CLIMO        = getenv("OPT_CLIMO")
  CLIMO_SYEAR      = toint(getenv("CLIMO_SYEAR"))
  CLIMO_EYEAR      = toint(getenv("CLIMO_EYEAR"))

  pi=4.*atan(1.0)
  rad=(pi/180.)

  nsim = numAsciiRow("namelist_byvar/namelist_ts")
  na = asciiread("namelist_byvar/namelist_ts",(/nsim/),"string")
  names = new(nsim,"string")
  paths = new(nsim,"string")
  syear = new(nsim,"integer",-999)
  eyear = new(nsim,"integer",-999)
  names_EM = new(nsim,"string")
  EM_num = new(nsim,"integer",-999)
  delim = "|"

  do gg = 0,nsim-1
     names(gg) = str_strip(str_get_field(na(gg),1,delim))
     paths(gg) = str_strip(str_get_field(na(gg),2,delim))
     syear(gg) = stringtointeger(str_strip(str_get_field(na(gg),3,delim)))
     eyear(gg) = stringtointeger(str_strip(str_get_field(na(gg),4,delim)))
     temp      = str_split(str_strip(str_get_field(na(gg),5,delim)),"-")
     temp2 = tochar(str_strip(str_get_field(na(gg),5,delim)))
     if (tostring(temp2(0)).eq."-") then
        EM_num(gg)    = toint(temp(0))*-1
     else
        EM_num(gg)    = toint(temp(0))
     end if
     names_EM(gg)  = str_join(temp(1:),"-")
     delete([/temp,temp2/])
  end do
  modname = str_sub_str(names," ","_")
  bc = (/"/","'","(",")"/)
  do ff = 0,dimsizes(modname)-1
     do gg = 0,dimsizes(bc)-1
        modname(ff) = str_sub_str(modname(ff),bc(gg),"_")
     end do
  end do
  nyr = eyear-syear+1
  nyr_max = max(nyr)
  nEM = max(EM_num)
  nEMm = min(EM_num)
  numobs = num(EM_num.eq.0)

;---------TAS variable metadata-------------------------------------------------
  nsim_tas = numAsciiRow("namelist_byvar/namelist_trefht")
  na_tas = asciiread("namelist_byvar/namelist_trefht",(/nsim_tas/),"string")
  names_tas = new(nsim_tas,"string")
  paths_tas = new(nsim_tas,"string")
  syear_tas = new(nsim_tas,"integer",-999)
  eyear_tas = new(nsim_tas,"integer",-999)

  do gg = 0,nsim_tas-1
     names_tas(gg) = str_strip(str_get_field(na_tas(gg),1,delim))
     paths_tas(gg) = str_strip(str_get_field(na_tas(gg),2,delim))
     syear_tas(gg) = stringtointeger(str_strip(str_get_field(na_tas(gg),3,delim)))
     eyear_tas(gg) = stringtointeger(str_strip(str_get_field(na_tas(gg),4,delim)))
  end do
  modname_tas = str_sub_str(names_tas," ","_")
  do ff = 0,dimsizes(modname_tas)-1
     do gg = 0,dimsizes(bc)-1
        modname_tas(ff) = str_sub_str(modname_tas(ff),bc(gg),"_")
     end do
  end do
  delete(na_tas)
  nyr_tas = eyear_tas-syear_tas+1

;---------PR variable metadata--------------------------------------------------
  nsim_pr = numAsciiRow("namelist_byvar/namelist_prect")
  na_pr = asciiread("namelist_byvar/namelist_prect",(/nsim_pr/),"string")
  names_pr = new(nsim_pr,"string")
  paths_pr = new(nsim_pr,"string")
  syear_pr = new(nsim_pr,"integer",-999)
  eyear_pr = new(nsim_pr,"integer",-999)

  do gg = 0,nsim_pr-1
     names_pr(gg) = str_strip(str_get_field(na_pr(gg),1,delim))
     paths_pr(gg) = str_strip(str_get_field(na_pr(gg),2,delim))
     syear_pr(gg) = stringtointeger(str_strip(str_get_field(na_pr(gg),3,delim)))
     eyear_pr(gg) = stringtointeger(str_strip(str_get_field(na_pr(gg),4,delim)))
  end do
  modname_pr = str_sub_str(names_pr," ","_")
  do ff = 0,dimsizes(modname_pr)-1
     do gg = 0,dimsizes(bc)-1
        modname_pr(ff) = str_sub_str(modname_pr(ff),bc(gg),"_")
     end do
  end do
  delete(na_pr)
  nyr_pr = eyear_pr-syear_pr+1
;-------------------------------------------------------------------------------------------------
  iopt = 0
  val1 = .95
  val2 = .99
  pct = 0.1

  d = addfile("$NCARG_ROOT/lib/ncarg/data/cdf/landsea.nc","r")   ; prepare land mask

  do ee = 0,nsim-1
     fnt = OUTDIR+modname(ee)+".cvdp_data.atl3."+syear(ee)+"-"+eyear(ee)+".nc"
     fnt2 = OUTDIR+modname(ee)+".cvdp_data."+syear(ee)+"-"+eyear(ee)+".nc"
     f_test := read_cvdp_le_data(fnt,fnt2,"atl3_pattern_mon")
     if (.not.isatt(f_test,"is_all_missing")) then
        continue
     end if

     sst = data_read_in(paths(ee),"TS",syear(ee),eyear(ee))    ; read in data, orient lats/lons correctly, set time coordinate variable up
     if (isatt(sst,"is_all_missing")) then
        delete(sst)
        continue
     end if
     sst = where(sst.le.-1.8,-1.8,sst)    ; set all values below -1.8 to -1.8
     sst = mask(sst,conform(sst,landsea_mask(d->LSMASK,sst&lat,sst&lon),(/1,2/)).ge.1,False)

     if (OPT_CLIMO.eq."Full".or.(EM_num(ee).eq.0.and.((CLIMO_SYEAR.ge.0.and.(CLIMO_SYEAR.lt.syear(ee).or.CLIMO_EYEAR.gt.eyear(ee))).or.(CLIMO_SYEAR.lt.0.and.(eyear(ee)+CLIMO_SYEAR).lt.syear(ee))))) then   ; observations not covering the custom climatological period use their full record
        if (OPT_CLIMO.ne."Full") then
           print("Custom climatological period not covered by observational dataset "+names(ee)+" ("+syear(ee)+"-"+eyear(ee)+"): using its full record")
        end if
        climo = clmMonTLL(sst)
        sst = rmMonAnnCycTLL(sst)
     else
        check_custom_climo(names(ee),syear(ee),eyear(ee),CLIMO_SYEAR,CLIMO_EYEAR)
        temp_arr = sst
        delete(temp_arr&time)
        temp_arr&time = cd_calendar(sst&time,-1)
        if (CLIMO_SYEAR.lt.0) then
           climo = clmMonTLL(temp_arr({(eyear(ee)+CLIMO_SYEAR)*100+1:(eyear(ee)+CLIMO_EYEAR)*100+12},:,:))
        else
           climo = clmMonTLL(temp_arr({CLIMO_SYEAR*100+1:CLIMO_EYEAR*100+12},:,:))
        end if
        delete(temp_arr)
        sst = calcMonAnomTLL(sst,climo)
     end if

     ;Detrend SSTs
     if (ee.le.(numobs-1)) then
        sst = remove_trend(sst,REMOVE_TREND_OBS,new(1,float))
     else
        if (REMOVE_TREND_MODEL.eq."30yrRunningMean".or.REMOVE_TREND_MODEL.eq."LinearTrend".or.REMOVE_TREND_MODEL.eq."QuadraticTrend".or.REMOVE_TREND_MODEL.eq."None") then
           sst = remove_trend(sst,REMOVE_TREND_MODEL,new(1,float))
        end if
        if (REMOVE_TREND_MODEL.eq."rmGMST_EM") then
           sst = remove_trend(sst,REMOVE_TREND_MODEL,ensemble_mean_read_in(sst,ENSEMBLE_MEAN_DIR+str_sub_str(names_EM(ee)," ","_"),EM_num(ee),"TREFHT",syear,eyear,EM_num))
        end if
        if (REMOVE_TREND_MODEL.eq."rmEM") then
           sst = remove_trend(sst,REMOVE_TREND_MODEL,ensemble_mean_read_in(sst,ENSEMBLE_MEAN_DIR+str_sub_str(names_EM(ee)," ","_"),EM_num(ee),"TS",syear,eyear,EM_num))
        end if
     end if

     coswgt=cos(rad*sst&lat)
     coswgt!0 = "lat"
     coswgt&lat= sst&lat
     ssttemp = lonFlip(sst)
     climo = lonFlip(climo)
     llats = -3.    ;  Atlantic Nino (ATL3)
     llatn = 3.
     llonw = -20.
     llone = 0.
     atl3_ts = wgt_areaave_Wrap(ssttemp(:,{llats:llatn},{llonw:llone}),coswgt({llats:llatn}),1.0,0)
     atl3_ts@AnnCycle = (/wgt_areaave(climo(:,{llats:llatn},{llonw:llone}),coswgt({llats:llatn}),1.0,0)/)
     delete([/ssttemp,climo/])
     atl3_ts@comment_cvdp = "area average domain ("+llats+":"+llatn+"N, "+llonw+":"+llone+"E)"
     atl3_ts@units = sst@units
     atl3_ts@long_name = "Atlantic Nino Index (monthly)"

     atl3 = sst(0,:,:)
     atl3 = atl3@_FillValue
     atl3 = (/ regCoef(atl3_ts,sst(lat|:,lon|:,time|:)) /)
     atl3@syear = syear(ee)
     atl3@eyear = eyear(ee)
     delete([/sst,coswgt/])

;---------TAS Regressions coding-------------------------------------------------
     plot_flag := check_years_match(syear(ee),syear_tas(ee),eyear(ee),eyear_tas(ee))
     if (plot_flag.eq.0) then
        tas = data_read_in(paths_tas(ee),"TREFHT",syear_tas(ee),eyear_tas(ee))
        if (.not.isatt(tas,"is_all_missing")) then
           tas = mask(tas,conform(tas,landsea_mask(d->LSMASK,tas&lat,tas&lon),(/1,2/)).eq.0,False)

           if (OPT_CLIMO.eq."Full".or.(EM_num(ee).eq.0.and.((CLIMO_SYEAR.ge.0.and.(CLIMO_SYEAR.lt.syear_tas(ee).or.CLIMO_EYEAR.gt.eyear_tas(ee))).or.(CLIMO_SYEAR.lt.0.and.(eyear_tas(ee)+CLIMO_SYEAR).lt.syear_tas(ee))))) then   ; observations not covering the custom climatological period use their full record
              if (OPT_CLIMO.ne."Full") then
                 print("Custom climatological period not covered by observational dataset "+names_tas(ee)+" ("+syear_tas(ee)+"-"+eyear_tas(ee)+"): using its full record")
              end if
              tas = rmMonAnnCycTLL(tas)
           else
              check_custom_climo(names_tas(ee),syear_tas(ee),eyear_tas(ee),CLIMO_SYEAR,CLIMO_EYEAR)
              temp_arr = tas
              delete(temp_arr&time)
              temp_arr&time = cd_calendar(tas&time,-1)
              if (CLIMO_SYEAR.lt.0) then
                 climo = clmMonTLL(temp_arr({(eyear(ee)+CLIMO_SYEAR)*100+1:(eyear(ee)+CLIMO_EYEAR)*100+12},:,:))
              else
                 climo = clmMonTLL(temp_arr({CLIMO_SYEAR*100+1:CLIMO_EYEAR*100+12},:,:))
              end if
              delete(temp_arr)
              tas = calcMonAnomTLL(tas,climo)
              delete(climo)
           end if

           if (ee.le.(numobs-1)) then
              tas = remove_trend(tas,REMOVE_TREND_OBS,new(1,float))
           else
              if (REMOVE_TREND_MODEL.eq."30yrRunningMean".or.REMOVE_TREND_MODEL.eq."LinearTrend".or.REMOVE_TREND_MODEL.eq."QuadraticTrend".or.REMOVE_TREND_MODEL.eq."None") then
                 tas = remove_trend(tas,REMOVE_TREND_MODEL,new(1,float))
              end if
              if (REMOVE_TREND_MODEL.eq."rmGMST_EM") then
                 tas = remove_trend(tas,REMOVE_TREND_MODEL,ensemble_mean_read_in(tas,ENSEMBLE_MEAN_DIR+str_sub_str(names_EM(ee)," ","_"),EM_num(ee),"TREFHT",syear,eyear,EM_num))
              end if
              if (REMOVE_TREND_MODEL.eq."rmEM") then
                 tas = remove_trend(tas,REMOVE_TREND_MODEL,ensemble_mean_read_in(tas,ENSEMBLE_MEAN_DIR+str_sub_str(names_EM(ee)," ","_"),EM_num(ee),"TREFHT",syear_tas,eyear_tas,EM_num))
              end if
           end if

           finreg_tas = tas(0,:,:)
           finreg_tas = (/ regCoef(atl3_ts,tas(lat|:,lon|:,time|:))  /)
           delete(tas)

           fnt_tas = OUTDIR+modname_tas(ee)+".cvdp_data.atl3.tas."+syear_tas(ee)+"-"+eyear_tas(ee)+".nc"
           if (isfilepresent2(fnt_tas)) then
              z_tas = addfile(fnt_tas,"w")
           else
              z_tas = addfile(fnt_tas,"c")
           end if
           set_global_ncfile_attributes(z_tas,names_tas(ee),syear_tas(ee),eyear_tas(ee),getenv("VERSION"))
           z_tas->atl3_tas_regression_mon = set_varAtts(finreg_tas,"tas regression onto ATL3 timeseries (monthly)","","")
           delete([/finreg_tas,z_tas,fnt_tas/])
        else
           delete(tas)
        end if
     end if

;---------PR Regressions coding-------------------------------------------------
     plot_flag := check_years_match(syear(ee),syear_pr(ee),eyear(ee),eyear_pr(ee))
     if (plot_flag.eq.0) then
        pr = data_read_in(paths_pr(ee),"PRECT",syear_pr(ee),eyear_pr(ee))
        if (.not.isatt(pr,"is_all_missing")) then
           if (OPT_CLIMO.eq."Full".or.(EM_num(ee).eq.0.and.((CLIMO_SYEAR.ge.0.and.(CLIMO_SYEAR.lt.syear_pr(ee).or.CLIMO_EYEAR.gt.eyear_pr(ee))).or.(CLIMO_SYEAR.lt.0.and.(eyear_pr(ee)+CLIMO_SYEAR).lt.syear_pr(ee))))) then   ; observations not covering the custom climatological period use their full record
              if (OPT_CLIMO.ne."Full") then
                 print("Custom climatological period not covered by observational dataset "+names_pr(ee)+" ("+syear_pr(ee)+"-"+eyear_pr(ee)+"): using its full record")
              end if
              pr = rmMonAnnCycTLL(pr)
           else
              check_custom_climo(names_pr(ee),syear_pr(ee),eyear_pr(ee),CLIMO_SYEAR,CLIMO_EYEAR)
              temp_arr = pr
              delete(temp_arr&time)
              temp_arr&time = cd_calendar(pr&time,-1)
              if (CLIMO_SYEAR.lt.0) then
                 climo = clmMonTLL(temp_arr({(eyear(ee)+CLIMO_SYEAR)*100+1:(eyear(ee)+CLIMO_EYEAR)*100+12},:,:))
              else
                 climo = clmMonTLL(temp_arr({CLIMO_SYEAR*100+1:CLIMO_EYEAR*100+12},:,:))
              end if
              delete(temp_arr)
              pr = calcMonAnomTLL(pr,climo)
              delete(climo)
           end if

           if (ee.le.(numobs-1)) then
              pr = remove_trend(pr,REMOVE_TREND_OBS,new(1,float))
           else
              if (REMOVE_TREND_MODEL.eq."30yrRunningMean".or.REMOVE_TREND_MODEL.eq."LinearTrend".or.REMOVE_TREND_MODEL.eq."QuadraticTrend".or.REMOVE_TREND_MODEL.eq."None") then
                 pr = remove_trend(pr,REMOVE_TREND_MODEL,new(1,float))
              end if
              if (REMOVE_TREND_MODEL.eq."rmGMST_EM") then
                 pr = remove_trend(pr,REMOVE_TREND_MODEL,ensemble_mean_read_in(pr,ENSEMBLE_MEAN_DIR+str_sub_str(names_EM(ee)," ","_"),EM_num(ee),"TREFHT",syear,eyear,EM_num))
              end if
              if (REMOVE_TREND_MODEL.eq."rmEM") then
                 pr = remove_trend(pr,REMOVE_TREND_MODEL,ensemble_mean_read_in(pr,ENSEMBLE_MEAN_DIR+str_sub_str(names_EM(ee)," ","_"),EM_num(ee),"PRECT",syear_pr,eyear_pr,EM_num))
              end if
           end if

           finreg_pr = pr(0,:,:)
           finreg_pr = (/ regCoef(atl3_ts,pr(lat|:,lon|:,time|:))  /)
           delete(pr)

           fnt_pr = OUTDIR+modname_pr(ee)+".cvdp_data.atl3.pr."+syear_pr(ee)+"-"+eyear_pr(ee)+".nc"
           if (isfilepresent2(fnt_pr)) then
              z_pr = addfile(fnt_pr,"w")
           else
              z_pr = addfile(fnt_pr,"c")
           end if
           set_global_ncfile_attributes(z_pr,names_pr(ee),syear_pr(ee),eyear_pr(ee),getenv("VERSION"))
           z_pr->atl3_pr_regression_mon = set_varAtts(finreg_pr,"pr regression onto ATL3 timeseries (monthly)","","")
           delete([/finreg_pr,z_pr,fnt_pr/])
        else
           delete(pr)
        end if
     end if

;---------------------------------------------------------------------------------------------
     jave = (3*nyr(ee))/100
     if (jave.eq.0) then
        jave = 1
     end if

     if (isfilepresent2(fnt)) then
        z = addfile(fnt,"w")
     else
        z = addfile(fnt,"c")
     end if
     set_global_ncfile_attributes(z,names(ee),syear(ee),eyear(ee),getenv("VERSION"))
     z->atl3_pattern_mon = set_varAtts(atl3,"ATL3 spatial pattern (monthly)","","")
     z->atl3_timeseries_mon = set_varAtts(atl3_ts,atl3_ts@long_name,"","")
     if (.not.any(ismissing(atl3_ts))) then
        sdof = specx_anal(atl3_ts,iopt,jave,pct)
        splt1 = specx_ci(sdof,val1,val2)
        splt1!0 = "ncurves"
        splt1&ncurves = ispan(0,3,1)
        splt1&ncurves@long_name = "power spectra curves"
        splt1&ncurves@units = "1"
        splt1!1 = "frequency"
        splt1&frequency = sdof@frq
        splt1&frequency@units = "1"
        splt1@units_info = "df refers to frequency interval; data are standardized so there are no physical units"
        splt1@units = "1/df"
        splt1@info = "(0,:)=spectrum,(1,:)=Markov red noise spectrum, (2,:)="+val1*100+"% confidence bound for Markhov, (3,:)="+val2*100+"% confidence bound for Markhov"
        z->atl3_spectra = set_varAtts(splt1,"ATL3 (monthly) power spectra, Markov spectrum and confidence curves","","")
        delete([/sdof,splt1/])
     end if
     delete([/z,atl3,atl3_ts,jave/])
  end do

  if (nEM.ge.1) then     ; runstyle 2: create ensemble mean outputs from the member files
     do gg = 1,nEM
        emi := ind(EM_num.eq.gg)
        le = dimsizes(emi)-1
        ename = str_sub_str(names_EM(emi(0))," ","_")
        fnts := OUTDIR+modname(emi)+".cvdp_data.atl3."+syear(emi)+"-"+eyear(emi)+".nc"
        fnts2 := OUTDIR+modname(emi)+".cvdp_data."+syear(emi)+"-"+eyear(emi)+".nc"
        em := read_ensemble_mean(fnts,fnts2,"atl3_pattern_mon")
        if (.not.isatt(em,"is_all_missing")) then
           fno = OUTDIR+ename+"_EM.cvdp_data.atl3."+syear(emi(le))+"-"+eyear(emi(le))+".nc"
           if (isfilepresent2(fno)) then
              z = addfile(fno,"w")
           else
              z = addfile(fno,"c")
              set_global_ncfile_attributes(z,names_EM(emi(0)),syear(emi(le)),eyear(emi(le)),getenv("VERSION"))
           end if
           z->atl3_pattern_mon_em = set_varAtts(em,"ATL3 spatial pattern (monthly) Ensemble Mean","","")
           em := read_ensemble_mean(fnts,fnts2,"atl3_spectra")
           if (.not.isatt(em,"is_all_missing")) then
              z->atl3_spectra_em = set_varAtts(em,"ATL3 (monthly) power spectra Ensemble Mean","","")
           end if
           delete(z)
        end if
        fnts := OUTDIR+modname_tas(emi)+".cvdp_data.atl3.tas."+syear_tas(emi)+"-"+eyear_tas(emi)+".nc"
        fnts2 := OUTDIR+modname_tas(emi)+".cvdp_data."+syear_tas(emi)+"-"+eyear_tas(emi)+".nc"
        em := read_ensemble_mean(fnts,fnts2,"atl3_tas_regression_mon")
        if (.not.isatt(em,"is_all_missing")) then
           fno = OUTDIR+ename+"_EM.cvdp_data.atl3.tas."+syear_tas(emi(le))+"-"+eyear_tas(emi(le))+".nc"
           if (isfilepresent2(fno)) then
              z = addfile(fno,"w")
           else
              z = addfile(fno,"c")
              set_global_ncfile_attributes(z,names_EM(emi(0)),syear_tas(emi(le)),eyear_tas(emi(le)),getenv("VERSION"))
           end if
           z->atl3_tas_regression_mon_em = set_varAtts(em,"tas regression onto ATL3 timeseries (monthly) Ensemble Mean","","")
           delete(z)
        end if
        fnts := OUTDIR+modname_pr(emi)+".cvdp_data.atl3.pr."+syear_pr(emi)+"-"+eyear_pr(emi)+".nc"
        fnts2 := OUTDIR+modname_pr(emi)+".cvdp_data."+syear_pr(emi)+"-"+eyear_pr(emi)+".nc"
        em := read_ensemble_mean(fnts,fnts2,"atl3_pr_regression_mon")
        if (.not.isatt(em,"is_all_missing")) then
           fno = OUTDIR+ename+"_EM.cvdp_data.atl3.pr."+syear_pr(emi(le))+"-"+eyear_pr(emi(le))+".nc"
           if (isfilepresent2(fno)) then
              z = addfile(fno,"w")
           else
              z = addfile(fno,"c")
              set_global_ncfile_attributes(z,names_EM(emi(0)),syear_pr(emi(le)),eyear_pr(emi(le)),getenv("VERSION"))
           end if
           z->atl3_pr_regression_mon_em = set_varAtts(em,"pr regression onto ATL3 timeseries (monthly) Ensemble Mean","","")
           delete(z)
        end if
     end do
  end if

  if (CREATE_GRAPHICS.eq."False") then
     print("Finished: atl3.ncl")
     exit
  end if
;===========================================================================================================================================================
  wks_type = OUTPUT_TYPE
  if (wks_type.eq."png") then
     wks_type@wkWidth = 1500*PNG_SCALE
     wks_type@wkHeight = 1500*PNG_SCALE
  end if
  wks = gsn_open_wks(wks_type,getenv("OUTDIR")+"atl3")
  wks4 = gsn_open_wks(wks_type,getenv("OUTDIR")+"atl3.prreg")
  wks2 = gsn_open_wks(wks_type,getenv("OUTDIR")+"atl3.powspec")
  wks3 = gsn_open_wks(wks_type,getenv("OUTDIR")+"atl3.timeseries")

  map = new(nsim,"graphic")
  map_sst = new(nsim,"graphic")
  map_tasreg = new(nsim,"graphic")
  map_prreg = new(nsim,"graphic")
  pspec = new(nsim,"graphic")
  xyplot = new(nsim,"graphic")
  if (isfilepresent2("obs_ts")) then
     pspec_obs = new(nsim,"graphic")
  end if

  tasreg_frame = 1    ; *reg_frame = flag to create regressions .ps/.png files
  prreg_frame  = 1

  do ee = 0,nsim-1
     fnt = OUTDIR+modname(ee)+".cvdp_data.atl3."+syear(ee)+"-"+eyear(ee)+".nc"
     fnt2 = OUTDIR+modname(ee)+".cvdp_data."+syear(ee)+"-"+eyear(ee)+".nc"
     atl3 := read_cvdp_le_data(fnt,fnt2,"atl3_pattern_mon")
     if (isatt(atl3,"is_all_missing")) then
        continue
     end if
     atl3_ts := read_cvdp_le_data(fnt,fnt2,"atl3_timeseries_mon")

     spectra_mvf = any(ismissing(atl3_ts))
     spectra_mvf_obs = True
     if (isfilepresent2("obs_ts").and.ee.eq.0.and..not.spectra_mvf) then
        spectra_mvf_obs = False
        splt1_obs := read_cvdp_le_data(fnt,fnt2,"atl3_spectra")
     end if

     tasreg_plot_flag = 1
     fnt_tas = OUTDIR+modname_tas(ee)+".cvdp_data.atl3.tas."+syear_tas(ee)+"-"+eyear_tas(ee)+".nc"
     fnt2_tas = OUTDIR+modname_tas(ee)+".cvdp_data."+syear_tas(ee)+"-"+eyear_tas(ee)+".nc"
     finreg_tas := read_cvdp_le_data(fnt_tas,fnt2_tas,"atl3_tas_regression_mon")
     if (.not.isatt(finreg_tas,"is_all_missing")) then
        tasreg_plot_flag = 0
     end if

     prreg_plot_flag = 1
     fnt_pr = OUTDIR+modname_pr(ee)+".cvdp_data.atl3.pr."+syear_pr(ee)+"-"+eyear_pr(ee)+".nc"
     fnt2_pr = OUTDIR+modname_pr(ee)+".cvdp_data."+syear_pr(ee)+"-"+eyear_pr(ee)+".nc"
     finreg_pr := read_cvdp_le_data(fnt_pr,fnt2_pr,"atl3_pr_regression_mon")
     if (.not.isatt(finreg_pr,"is_all_missing")) then
        prreg_plot_flag = 0
     end if

     if (tasreg_frame.eq.1.and.tasreg_plot_flag.eq.0) then
        tasreg_frame = 0
     end if
     if (prreg_frame.eq.1.and.prreg_plot_flag.eq.0) then
        prreg_frame = 0
     end if
;========================================================================
     res = True
     res@mpProjection = "WinkelTripel"
     res@mpGeophysicalLineColor = "gray42"
     res@mpPerimOn    = False
     res@mpGridLatSpacingF =  90            ; change latitude  line spacing
     res@mpGridLonSpacingF = 180.           ; change longitude line spacing
     res@mpGridLineColor   = "transparent"  ; trick ncl into drawing perimeter
     res@mpGridAndLimbOn   = True           ; turn on lat/lon lines
     res@mpFillOn = False
     res@mpCenterLonF = 210.
     res@mpOutlineOn = True
     res@gsnDraw      = False
     res@gsnFrame     = False
     res@vpYF = 0.95
     res@vpHeightF = 0.3
     res@vpXF = 0.2
     res@vpWidthF = 0.6

     res@cnLevelSelectionMode = "ExplicitLevels"
     if (COLORMAP.eq."0") then
        res@cnLevels = fspan(-.65,.65,27)
        res@cnFillPalette = "ncl_default"
     end if
     if (COLORMAP.eq."1") then
        res@cnLevels = fspan(-.8,.8,17)
        res@cnFillPalette = "BlueDarkRed18"
     end if

     res@cnLineLabelsOn = False
     res@cnFillOn        = True
     res@cnLinesOn       = False
     res@lbLabelBarOn    = False

     res@gsnLeftStringOrthogonalPosF = -0.05
     res@gsnLeftStringParallelPosF = .005
     res@gsnRightStringOrthogonalPosF = -0.05
     res@gsnRightStringParallelPosF = 0.96
     res@gsnRightString = ""
     res@gsnLeftString = ""
     res@gsnLeftStringFontHeightF = 0.014
     res@gsnCenterStringFontHeightF = 0.018
     res@gsnRightStringFontHeightF = 0.014
     res@gsnLeftString = syear(ee)+"-"+eyear(ee)
     res@gsnCenterString = names(ee)
     if (wks_type.eq."png") then
        res@mpGeophysicalLineThicknessF = 2.
     else
        res@mpGeophysicalLineThicknessF = 1.
     end if

     res4 = res    ; res4 = pr regression resources
     delete(res4@cnLevels)
     if (COLORMAP.eq."0") then
        res4@cnLevels = (/-5,-4,-3,-2,-1,-.75,-.5,-.25,-.1,0,.1,.25,.5,.75,1,2,3,4,5/)
        res4@cnFillPalette = "MPL_BrBG"
     else
        res4@cnLevels = (/-3,-2,-1,-.5,-.1,0,.1,.5,1,2,3/)
        res4@cnFillPalette = "BrownBlue12"
     end if

     res2 = True   ; res2 = tas regression resources
     res2@gsnDraw      = False
     res2@gsnFrame     = False
     res2@cnLevelSelectionMode = "ExplicitLevels"
     res2@cnLevels = res@cnLevels
     res2@cnFillPalette = res@cnFillPalette
     res2@cnLineLabelsOn = False
     res2@cnFillOn        = True
     res2@cnLinesOn       = False
     res2@cnFillMode = "AreaFill"
     res2@lbLabelBarOn    = False
     res2@cnInfoLabelOn = False
     res2@gsnRightString = ""
     res2@gsnLeftString = ""
     res2@gsnCenterString = ""
     res2@gsnAddCyclic = True

     map(ee) = gsn_csm_contour_map(wks,atl3,res)

     if (tasreg_plot_flag.eq.0) then
        if (names(ee).eq.names_tas(ee)) then
           res@gsnCenterString = names(ee)
        else
           res@gsnCenterString = names(ee)+" / "+names_tas(ee)
        end if
        map_sst(ee) = gsn_csm_contour_map(wks,atl3,res)
        map_tasreg(ee) = gsn_csm_contour(wks,finreg_tas,res2)
        overlay(map_sst(ee),map_tasreg(ee))
     end if

     if (prreg_plot_flag.eq.0) then
        res4@gsnCenterString = names_pr(ee)
        map_prreg(ee) = gsn_csm_contour_map(wks4,finreg_pr,res4)
     end if

     pres = True
     pres@vpXF = 0.07
     pres@trYMinF = 0.
     pres@trXMinF = 0.0
     pres@trXMaxF = 0.0832
     pres@tiYAxisString = "Power"              ; yaxis
     pres@xyLineColor   =  "black"
     pres@gsnFrame      = False
     pres@gsnDraw       = False

     pres@tmXBLabelDeltaF = -.8
     pres@tmXTLabelDeltaF = -.8
     pres@pmLegendDisplayMode    = "Never"
     pres@xyLineThicknesses   = (/3.5,2.,1.,1./)
     pres@xyDashPatterns      = (/0,0,0,0/)
     pres@xyLineColors        = (/"foreground","red","blue","green"/)
     pres@xyLabelMode = "custom"
     pres@xyLineLabelFontColors = pres@xyLineColors
     pres@xyExplicitLabels = (/"","",val1*100+"%",val2*100+"%"/)
     pres@tmXTOn = True
     pres@tmYROn = False
     pres@tmXTLabelsOn = True
     pres@tmXUseBottom = False
     pres@tmXTMode   = "Explicit"
     pres@tmXBMode   = "Explicit"
     pres@tmXTValues = (/".00167",".00833",".01667",".02778",".0416",".0556",".0832"/)
     pres@tmXTLabels = (/"50","10","5","3","2","1.5","1"/)
     pres@tmXBValues = (/".0",".01",".02",".03",".042",".056",".083"/)
     pres@tmXBLabels =     pres@tmXBValues
     pres@tmXTLabelFontHeightF = 0.018
     pres@tmXBLabelFontHeightF = 0.018
     pres@tmYLLabelFontHeightF = 0.018
     pres@tiYAxisString = "Variance"
     pres@tiXAxisString = "Frequency (cycles mo~S~-1~N~)"
     pres@tiMainString = ""
     pres@txFontHeightF = 0.015
     pres@xyLineLabelFontHeightF = 0.022
     pres@tiXAxisFontHeightF = 0.025
     pres@tiYAxisFontHeightF = 0.025
     pres@tiMainFontHeightF = 0.03
     pres@gsnRightStringOrthogonalPosF = -0.115

     pres@tiMainOn = False
     pres@gsnCenterString = "Period (years)"
     pres@gsnCenterStringFontHeightF =    pres@tiYAxisFontHeightF
     pres@gsnRightStringFontHeightF  =    pres@tiYAxisFontHeightF - 0.005
     pres@gsnRightString = syear(ee)+"-"+eyear(ee)+"  "
     pres@gsnLeftString = ""
     if (wks_type.eq."png") then
        pres@xyLineThicknessF   = 3.5
     else
        pres@xyLineThicknessF   = 1.5
     end if
     pres@gsnCenterString = names(ee)
     if (.not.spectra_mvf) then
        splt1 := read_cvdp_le_data(fnt,fnt2,"atl3_spectra")
        pres@trYMaxF = max(splt1(0,:))*1.1
        pspec(ee) = gsn_csm_xy(wks2,splt1&frequency,splt1,pres)
        if (isfilepresent2("obs_ts").and.ee.ge.1.and..not.spectra_mvf_obs) then
           pres@xyLineColors        = (/"gray70","black","black","black"/)
           pres@xyCurveDrawOrder = "PreDraw"
           pres@gsnCenterString = ""
           pres@gsnRightString = ""
           pspec_obs(ee) = gsn_csm_xy(wks2,splt1_obs&frequency,splt1_obs(0,:),pres)
           overlay(pspec(ee),pspec_obs(ee))
           delete(pres@xyCurveDrawOrder)
        end if
     end if

     xyres = True
     xyres@gsnDraw = False
     xyres@gsnFrame = False
     xyres@gsnRightString = ""
     xyres@gsnLeftString = ""
     xyres@gsnYRefLine = 0.0
     xyres@gsnYRefLineColor = "gray42"
     xyres@gsnXYBarChart = False
     xyres@gsnAboveYRefLineColor = 185
     xyres@gsnBelowYRefLineColor = 35
     xyres@xyLineThicknessF = 0.1
     xyres@xyLineColor = "gray70"
     xyres@tiYAxisString = ""
     if (nsim.le.5) then
        xyres@tmXBLabelFontHeightF = 0.0125
        xyres@tmYLLabelFontHeightF = 0.0125
        xyres@gsnStringFontHeightF = 0.017
     else
        xyres@tmXBLabelFontHeightF = 0.018
        xyres@tmYLLabelFontHeightF = 0.018
        xyres@gsnStringFontHeightF = 0.024
     end if
     xyres@gsnCenterStringOrthogonalPosF = 0.025
     xyres@vpXF = 0.05
     xyres@vpHeightF = 0.15
     xyres@vpWidthF = 0.9
     xyres@gsnCenterString = ""

     xyres@trXMinF = syear(ee)-.5
     xyres@trXMaxF = eyear(ee)+1.5

     xyres@gsnCenterString = names(ee)
     xyplot(ee) = gsn_csm_xy(wks3,fspan(syear(ee),eyear(ee)+.91667,dimsizes(atl3_ts)),atl3_ts,xyres)

     delete([/atl3_ts,res,pres,xyres/])     ; val1/val2 are loop-invariant (set once before the loops)
  end do

  panres = True
  panres@gsnMaximize = True
  panres@gsnPaperOrientation = "portrait"
  panres@gsnPanelLabelBar = True
  panres@gsnPanelYWhiteSpacePercent = 3.0
  panres@pmLabelBarHeightF = 0.05
  panres@pmLabelBarWidthF = 0.55
  panres@lbTitleOn = False
  panres@lbBoxLineColor = "gray70"
  panres@lbLabelFontHeightF = 0.013
  if (nsim.le.4) then
     if (nsim.eq.1) then
        panres@txFontHeightF = 0.022
        panres@gsnPanelBottom = 0.50
     else
        panres@txFontHeightF = 0.0145
        panres@gsnPanelBottom = 0.50
     end if
  else
     panres@txFontHeightF = 0.016
     panres@gsnPanelBottom = 0.05
  end if
  panres@txString = "ATL3 (Monthly)"
  ncol = floattointeger(sqrt(nsim))
  nrow = (nsim/ncol)+mod(nsim,ncol)
  gsn_panel2(wks,map,(/nrow,ncol/),panres)

  if (tasreg_frame.eq.0) then
     panres@txString = "ATL3 SST/TAS Regressions (Monthly)"
     gsn_panel2(wks,map_sst,(/nrow,ncol/),panres)
  end if
  delete(wks)

  if (prreg_frame.eq.0) then
     panres@txString = "ATL3 PR Regressions (Monthly)"
     gsn_panel2(wks4,map_prreg,(/nrow,ncol/),panres)
  end if
  delete(wks4)

  delete(panres@gsnPanelLabelBar)
  panres@txString = "ATL3 (Monthly)"
  gsn_panel2(wks2,pspec,(/nrow,ncol/),panres)
  delete(wks2)

  if (nsim.le.12) then
     lp = (/nsim,1/)
  else
     lp = (/nrow,ncol/)
  end if
  panres@txString = "ATL3 (Monthly)"
  gsn_panel2(wks3,xyplot,lp,panres)
  delete(wks3)

  if (nEM.ge.1) then     ; runstyle 2: ensemble summary figures (EM / reference / difference / rank)
     if (COLORMAP.eq."0") then
        patlev := fspan(-.65,.65,27)
        patpal = "ncl_default"
        prlev := (/-5.,-4,-3,-2,-1,-.75,-.5,-.25,-.1,0,.1,.25,.5,.75,1,2,3,4,5/)
        prpal = "MPL_BrBG"
     else
        patlev := fspan(-.8,.8,17)
        patpal = "BlueDarkRed18"
        prlev := (/-3.,-2,-1,-.5,-.1,0,.1,.5,1,2,3/)
        prpal = "BrownBlue12"
     end if
     ensemble_summary_figure("atl3_pattern_mon","atl3.", \
            OUTDIR+modname+".cvdp_data.atl3."+syear+"-"+eyear+".nc", \
            OUTDIR+modname+".cvdp_data."+syear+"-"+eyear+".nc", \
            names,syear,eyear,paths,names_EM,EM_num,nEM,patlev,patpal,patlev,patpal,"ATL3 Pattern (Monthly)",wks_type)
     ensemble_summary_figure("atl3_tas_regression_mon","atl3.tas.", \
            OUTDIR+modname_tas+".cvdp_data.atl3.tas."+syear_tas+"-"+eyear_tas+".nc", \
            OUTDIR+modname_tas+".cvdp_data."+syear_tas+"-"+eyear_tas+".nc", \
            names_tas,syear_tas,eyear_tas,paths_tas,names_EM,EM_num,nEM,patlev,patpal,patlev,patpal,"ATL3 TAS Regression (Monthly)",wks_type)
     ensemble_summary_figure("atl3_pr_regression_mon","atl3.pr.", \
            OUTDIR+modname_pr+".cvdp_data.atl3.pr."+syear_pr+"-"+eyear_pr+".nc", \
            OUTDIR+modname_pr+".cvdp_data."+syear_pr+"-"+eyear_pr+".nc", \
            names_pr,syear_pr,eyear_pr,paths_pr,names_EM,EM_num,nEM,prlev,prpal,prlev,prpal,"ATL3 PR Regression (Monthly)",wks_type)
     delete([/patlev,prlev/])
  end if

  delete([/map,pspec,syear,eyear,nyr,nyr_max,lp/])
;--------------------------------------------------------------------------------------------------
  if (wks_type.eq."png") then
     if (tasreg_frame.eq.0) then
        system("mv "+OUTDIR+"atl3.000001.png "+OUTDIR+"atl3.png")
        system("mv "+OUTDIR+"atl3.000002.png "+OUTDIR+"atl3.tasreg.png")
     end if
  else
     if (tasreg_frame.eq.0) then
        system("psplit "+OUTDIR+"atl3.ps "+OUTDIR+"atl3_nn")
        system("mv "+OUTDIR+"atl3_nn0001.ps "+OUTDIR+"atl3.ps")
        system("mv "+OUTDIR+"atl3_nn0002.ps "+OUTDIR+"atl3.tasreg.ps")
     end if
  end if
  print("Finished: atl3.ncl")
end
