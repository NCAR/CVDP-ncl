; Calculates MOC means/standard deviations, AMOC EOF1/PC1, 
; regressions onto AMOC PC1, and lag correlations vs. AMV
;
; Variables used: moc, ts, tas, zos
;
load "$CVDP_SCRIPTS/functions.ncl"

begin
  print("Starting: amoc.ncl")

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

  pi=4.*atan(1.0)
  rad=(pi/180.)

  nsim = numAsciiRow("namelist_byvar/namelist_moc")
  na = asciiread("namelist_byvar/namelist_moc",(/nsim/),"string")
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
;-------TAS variable metadata------------------------------------
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
;---------TS variable metadata------------------------------------------------------------
  nsim_ts = numAsciiRow("namelist_byvar/namelist_ts")
  na_ts = asciiread("namelist_byvar/namelist_ts",(/nsim_ts/),"string")
  names_ts = new(nsim_ts,"string")
  paths_ts = new(nsim_ts,"string")
  syear_ts = new(nsim_ts,"integer",-999)
  eyear_ts = new(nsim_ts,"integer",-999)

  do gg = 0,nsim_ts-1
     names_ts(gg) = str_strip(str_get_field(na_ts(gg),1,delim))
     paths_ts(gg) = str_strip(str_get_field(na_ts(gg),2,delim))
     syear_ts(gg) = stringtointeger(str_strip(str_get_field(na_ts(gg),3,delim)))
     eyear_ts(gg) = stringtointeger(str_strip(str_get_field(na_ts(gg),4,delim)))
  end do
  modname_ts = str_sub_str(names_ts," ","_")
  do ff = 0,dimsizes(modname_ts)-1
     do gg = 0,dimsizes(bc)-1
        modname_ts(ff) = str_sub_str(modname_ts(ff),bc(gg),"_")
     end do
  end do
  delete(na_ts)
  nyr_ts = eyear_ts-syear_ts+1  
;---------ZOS variable metadata------------------------------------------------------------
  nsim_zos = numAsciiRow("namelist_byvar/namelist_ssh")
  na_zos = asciiread("namelist_byvar/namelist_ssh",(/nsim_zos/),"string")
  names_zos = new(nsim_zos,"string")
  paths_zos = new(nsim_zos,"string")
  syear_zos = new(nsim_zos,"integer",-999)
  eyear_zos = new(nsim_zos,"integer",-999)

  do gg = 0,nsim_zos-1
     names_zos(gg) = str_strip(str_get_field(na_zos(gg),1,delim))
     paths_zos(gg) = str_strip(str_get_field(na_zos(gg),2,delim))
     syear_zos(gg) = stringtointeger(str_strip(str_get_field(na_zos(gg),3,delim)))
     eyear_zos(gg) = stringtointeger(str_strip(str_get_field(na_zos(gg),4,delim)))
  end do
  modname_zos = str_sub_str(names_zos," ","_")
  do ff = 0,dimsizes(modname_zos)-1
     do gg = 0,dimsizes(bc)-1
        modname_zos(ff) = str_sub_str(modname_zos(ff),bc(gg),"_")
     end do
  end do
  delete(na_zos)
  nyr_zos = eyear_zos-syear_zos+1  
;-------------------------------------------------------------------------------
  iopt = 0    ; spectra options
  val1 = .95
  val2 = .99
  pct = 0.1  

  do ee = 0,nsim-1    
     fnt = getenv("OUTDIR")+modname(ee)+".cvdp_data.amoc."+syear(ee)+"-"+eyear(ee)+".nc"
     fnt2 = getenv("OUTDIR")+modname(ee)+".cvdp_data."+syear(ee)+"-"+eyear(ee)+".nc"
     f_test := read_cvdp_le_data(fnt,fnt2,"amoc_pattern_ann")
     if (.not.isatt(f_test,"is_all_missing")) then
        continue
     end if
     mocT := data_read_in_ocean_MOC(paths(ee),"MOC",syear(ee),eyear(ee))    ; read in data, orient coordinates correctly, set time coordinate variable up        
     if (isatt(mocT,"is_all_missing")) then
        delete(mocT)
        continue
     end if 
;-----------------------------------------------------------------------------------
;    compute annual means and standard deviations
;-----------------------------------------------------------------------------------         
     moc_ann := runave_n_Wrap(mocT,12,0,0)                             
     moc_mean_ann := dim_avg_n_Wrap(moc_ann(5::12,:,:),0)
     mocT = rmMonAnnCycTLL(mocT) 

     if (ee.le.(numobs-1)) then   
        mocT = remove_trend(mocT,REMOVE_TREND_OBS,new(1,float))
     else
        if (REMOVE_TREND_MODEL.eq."30yrRunningMean".or.REMOVE_TREND_MODEL.eq."LinearTrend".or.REMOVE_TREND_MODEL.eq."QuadraticTrend".or.REMOVE_TREND_MODEL.eq."None") then
           mocT = remove_trend(mocT,REMOVE_TREND_MODEL,new(1,float))
        end if
        if (REMOVE_TREND_MODEL.eq."rmGMST_EM") then
           mocT = remove_trend(mocT,REMOVE_TREND_MODEL,ensemble_mean_read_in(mocT,ENSEMBLE_MEAN_DIR+str_sub_str(names_EM(ee)," ","_"),EM_num(ee),"TREFHT",syear,eyear,EM_num))
        end if
        if (REMOVE_TREND_MODEL.eq."rmEM") then
           mocT = remove_trend(mocT,REMOVE_TREND_MODEL,ensemble_mean_read_in(mocT,ENSEMBLE_MEAN_DIR+str_sub_str(names_EM(ee)," ","_"),EM_num(ee),"moc",syear,eyear,EM_num))
        end if
     end if
     if (isatt(mocT,"is_all_missing")) then
        delete(mocT)
        continue
     end if

     moc_ann2 := runave_n_Wrap(mocT,12,0,0)
     moc_sd_ann := dim_stddev_n_Wrap(moc_ann2(5::12,:,:),0)         
     copy_VarMeta(mocT(0,:,:),moc_sd_ann)     
     delete(moc_ann2)

     moc_sd_ann = where(moc_sd_ann.lt.0.001,moc_sd_ann@_FillValue,moc_sd_ann)
     moc_mean_ann = where(ismissing(moc_sd_ann),moc_mean_ann@_FillValue,moc_mean_ann) 
;-----------------------------------------------------------------------------------
;    compute AMOC EOF1
;-----------------------------------------------------------------------------------  
     lat := tofloat(mocT&lat)
     lev := tofloat(mocT&lev)
     ny := dimsizes(lat)
     nz := dimsizes(lev)

     temp = runave_n_Wrap(mocT,12,0,0)   ; form annual averages
     amoc := temp(5::12,:,:)
     delete([/temp,mocT/])
     
     atl_begin := ind_nearest_coord (-33.0, lat, 0)          ; set missing values based on variance, and mask Atlantic south of 33S
     vareps = 1.e-6
     amocvar = conform(amoc,dim_variance_n_Wrap(amoc,0),(/1,2/))
     amoc@_FillValue = 1.e20
     amoc(:,:,0:atl_begin-1) = amoc@_FillValue
     amoc = where(amocvar.lt.vareps,amoc@_FillValue,amoc)
     delete(amocvar)     

     dlat = lat           ; Compute latitudinal weights (in meters)
     rEarth = 6.37122e8 		; Earth radius in m
     do iy=0,ny-1
        if (iy.gt.0.and.iy.lt.ny-1) then
           dy0 = (lat(iy)-lat(iy-1))/2.0
           dy1 = (lat(iy+1)-lat(iy))/2.0
           dlat(iy) = (dy0+dy1)*rEarth
           delete(dy0)
           delete(dy1)
        end if
        if (iy.eq.0) then
           dy1 = (lat(iy+1)-lat(iy))/2.0
           dlat(iy) = (2.*dy1)*rEarth
           delete(dy1)
        end if
        if (iy.eq.ny-1) then
           dy0 = (lat(iy)-lat(iy-1))/2.0
           dlat(iy) = (2.*dy0)*rEarth
           delete(dy0)
        end if
     end do
    
     dz = lev        ; compute vertical weights (in meters)
     do iz=0,nz-1
        if (iz.gt.0.and.iz.lt.nz-1) then
           dz(iz) = (lev(iz)-lev(iz-1))/2.0 + (lev(iz+1)-lev(iz))/2.0
        end if
        if (iz.eq.0) then
           dz(iz) = (lev(iz+1)-lev(iz))/2.0
        end if
        if (iz.eq.nz-1) then
           dz(iz) = (lev(iz)-lev(iz-1))/2.0
        end if
     end do
     
     test = dlat(0)*dz(0)
     wgt    = new((/nz,ny/),typeof(test))      ; weight the data
     delete(test)
     do iz=0,nz-1
        do iy=0,ny-1
           wgt(iz,iy) = dlat(iy)*dz(iz)
        end do
     end do
     amocW   = amoc*conform(amoc, wgt, (/1,2/))  ; same units as "amoc"
     delete(wgt)
     copy_VarMeta(amoc,amocW)
     amocW@long_name = "area weighted "+amoc@long_name

     workeof    = eofunc_Wrap(amocW(lev|:,lat|:,time|:), 3, 75)
     workeof_ts = eofunc_ts_Wrap (amocW(lev|:,lat|:,time|:), workeof, False)
     delete(amocW)
     amoc_pc_ann := dim_standardize(workeof_ts(0,:),0)
     amoc_pc_ann@detrend_option = amoc@detrend_option
     moc_reg_ann := amoc(0,:,:)
     moc_reg_ann = (/ regCoef(amoc_pc_ann,amoc(lev|:,lat|:,time|:)) /)
     sig_pcv := eofunc_north2(workeof@pcvar,dimsizes(amoc_pc_ann),False)
     if (sig_pcv(0)) then    ; if True then significant
        moc_reg_ann@pcvar = tofloat(sprintf("%4.1f", workeof@pcvar(0)))+"%*"
     else
        moc_reg_ann@pcvar = tofloat(sprintf("%4.1f", workeof@pcvar(0)))+"%"
     end if
     delete([/atl_begin,lat,lev,dz,dlat,amoc,workeof,workeof_ts,ny,nz,sig_pcv/])
     if (max(moc_reg_ann&lev).ge.2000) then
        if (.not.ismissing(moc_reg_ann({2000.},{38}))) then
           if (moc_reg_ann({2000.},{38}).lt.0) then   ; arbitrary attempt to make all plots have the same sign..
              moc_reg_ann = moc_reg_ann*-1.
              amoc_pc_ann = amoc_pc_ann*-1.
           end if
        end if
     end if
     TIME := ispan(syear(ee),eyear(ee),1)
     TIME@units = "YYYY"
     TIME@long_name = "time"
     TIME@standard_name = "time"
     TIME@calendar = "standard"
     TIME!0 = "TIME"
     TIME&TIME = TIME

     amoc_pc_ann!0 = "TIME"
     amoc_pc_ann&TIME = TIME
     amoc_pc_ann@long_name = "AMOC pc1 timeseries (annual)"
     lat_amoc := moc_reg_ann&lat
     lat_amoc!0 = "lat_amoc"
     lat_amoc&lat_amoc = lat_amoc
     delete(moc_reg_ann&lat)
     moc_reg_ann!1 = "lat_amoc"
     moc_reg_ann&lat_amoc = lat_amoc
     delete(moc_mean_ann&lat)
     moc_mean_ann!1 = "lat_amoc"
     moc_mean_ann&lat_amoc = lat_amoc
     delete(moc_sd_ann&lat)
     moc_sd_ann!1 = "lat_amoc"
     moc_sd_ann&lat_amoc = lat_amoc
;-----------------------------------------------------------------------------------
; Regress ts onto AMOC PC1 and form AMV index
;-----------------------------------------------------------------------------------
     if (check_years_match(syear(ee),syear_ts(ee),eyear(ee),eyear_ts(ee)).eq.0) then
        sst := data_read_in(paths_ts(ee),"TS",syear_ts(ee),eyear_ts(ee))
        
        sst = where(sst.le.-1.8,-1.8,sst)
        d = addfile("$NCARG_ROOT/lib/ncarg/data/cdf/landsea.nc","r")   
        sst = mask(sst,conform(sst,landsea_mask(d->LSMASK,sst&lat,sst&lon),(/1,2/)).ge.1,False)
        delete(d)

        sst = rmMonAnnCycTLL(sst) 

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
              sst = remove_trend(sst,REMOVE_TREND_MODEL,ensemble_mean_read_in(sst,ENSEMBLE_MEAN_DIR+str_sub_str(names_EM(ee)," ","_"),EM_num(ee),"TS",syear_ts,eyear_ts,EM_num))
           end if
        end if
        temp = runave_n_Wrap(sst,12,0,0)   ; form annual averages
        sst_ann = temp(5::12,:,:)
        delete([/temp,sst/])

        sst_reg_ann := (/ regCoef(amoc_pc_ann,sst_ann(lat|:,lon|:,time|:)) /)   ; SST regression onto AMOC PC1
        copy_VarMeta(sst_ann(0,:,:),sst_reg_ann)

;        Compute AMO timeseries
        sst_ann = lonFlip(sst_ann)   ; orient longitudes from -180:180 (set to 0:360 in data_read_in function) for AMO calculation
        coswgt=cos(rad*sst_ann&lat)
        coswgt!0 = "lat"
        coswgt&lat= sst_ann&lat
        natl_aa =   wgt_areaave(sst_ann(:,{0:60},{-80:0}),coswgt({0.:60.}),1.0,0)
        global_aa = wgt_areaave(sst_ann(:,{-60:60},:),coswgt({-60.:60.}),1.0,0)
     
        AMO := new((/dimsizes(natl_aa)/),"float",-999.)    ; timeseries plot
        AMO!0 = "time"
        AMO&time = sst_ann&time
        AMO = (/ natl_aa - global_aa /)
        delete([/coswgt,natl_aa,global_aa,sst_ann/])
     end if
;-----------------------------------------------------------------------------------
; Regress tas onto AMOC PC1
;-----------------------------------------------------------------------------------
     if (check_years_match(syear(ee),syear_tas(ee),eyear(ee),eyear_tas(ee)).eq.0) then
        tas := data_read_in(paths_tas(ee),"TREFHT",syear_tas(ee),eyear_tas(ee))     

        tas = rmMonAnnCycTLL(tas) 

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
     
        temp = runave_n_Wrap(tas,12,0,0)   ; form annual averages
        tas_ann = temp(5::12,:,:)
        delete([/temp,tas/])

        tas_reg_ann := (/ regCoef(amoc_pc_ann,tas_ann(lat|:,lon|:,time|:)) /)  ; TAS regression onto AMOC PC1
        copy_VarMeta(tas_ann(0,:,:),tas_reg_ann)
        delete(tas_ann)
     end if    
;-----------------------------------------------------------------------------------
; Regress zos onto AMOC PC1
;-----------------------------------------------------------------------------------
     if (check_years_match(syear(ee),syear_zos(ee),eyear(ee),eyear_zos(ee)).eq.0) then
        zos := data_read_in_ocean(paths_zos(ee),"SSH",syear_zos(ee),eyear_zos(ee))  
        if (.not.isatt(zos,"is_all_missing")) then
           zos = rmMonAnnCycTLL(zos) 

           if (ee.le.(numobs-1)) then   
              zos = remove_trend(zos,REMOVE_TREND_OBS,new(1,float))
           else
              if (REMOVE_TREND_MODEL.eq."30yrRunningMean".or.REMOVE_TREND_MODEL.eq."LinearTrend".or.REMOVE_TREND_MODEL.eq."QuadraticTrend".or.REMOVE_TREND_MODEL.eq."None") then
                 zos = remove_trend(zos,REMOVE_TREND_MODEL,new(1,float))
              end if
              if (REMOVE_TREND_MODEL.eq."rmGMST_EM") then
                 zos = remove_trend(zos,REMOVE_TREND_MODEL,ensemble_mean_read_in(zos,ENSEMBLE_MEAN_DIR+str_sub_str(names_EM(ee)," ","_"),EM_num(ee),"TREFHT",syear,eyear,EM_num))
              end if
              if (REMOVE_TREND_MODEL.eq."rmEM") then
                 zos = remove_trend(zos,REMOVE_TREND_MODEL,ensemble_mean_read_in(zos,ENSEMBLE_MEAN_DIR+str_sub_str(names_EM(ee)," ","_"),EM_num(ee),"ssh",syear_zos,eyear_zos,EM_num))
              end if
           end if
     
           temp = runave_n_Wrap(zos,12,0,0)   ; form annual averages
           zos_ann = temp(5::12,:,:)
           delete([/temp/])

           zos_reg_ann := (/ regCoef_n(amoc_pc_ann,zos_ann,0,0) /)  ; TAS regression onto AMOC PC1
           copy_VarMeta(zos_ann(0,:,:),zos_reg_ann)
           delete(zos_ann)
        end if
        delete(zos)
     end if    
;-----------------------------------------------------------------------------------
; Compute AMOC/AMV lead/lags
;-----------------------------------------------------------------------------------
     if (nyr(ee).ge.90.and.isvar("AMO")) then    ; need a minimum number of years to compute lead/lag correlations
        nwt = 51
        pda = 15            ; longest period
        pdb = 1            ; shortest period
        fca = 1./pda       ;  ==> lowest allowed frequency
        fcb = 1./pdb       ;  ==> highest allowed frequency
        ihp = 0            ;  0 ==> low pass filter, fcb ignored
        nsigma = 1.
        twgt = filwgts_lanczos (nwt, ihp, fca, fcb, nsigma)
        AMO_wgt = wgt_runave_Wrap(AMO,twgt,0)
        amoc_pc_ann_wgt = wgt_runave_Wrap(amoc_pc_ann,twgt,0)

        mxlag = 15
        x_Lead_y = esccr(amoc_pc_ann_wgt,AMO_wgt,mxlag)
        y_Lead_x = esccr(AMO_wgt,amoc_pc_ann_wgt,mxlag)    ; switch the order of the series
     
        ccr = new ( 2*mxlag+1, float)    
        ccr(0:mxlag-1) = (/ y_Lead_x(1:mxlag:-1) /)  ; "negative lag", -1 reverses order
        ccr(mxlag:)    = (/ x_Lead_y(0:mxlag) /)     ; "positive lag"
        time_lag_cor := ispan(mxlag*-1,mxlag,1)
        time_lag_cor@units = "months since 0000-01-01 00:00:00"
        time_lag_cor@long_name = "Time"
        time_lag_cor@standard_name = "time"
        time_lag_cor@calendar = "standard"
        time_lag_cor!0 = "time_lag_cor"
        time_lag_cor&time_lag_cor = time_lag_cor
        ccr@detrend_option = amoc_pc_ann@detrend_option
        ccr!0 = "time_lag_cor"
        ccr&time_lag_cor = time_lag_cor
        ccr@long_name = "AMOC AMV lead lag correlation"
        ccr@detrend_option = amoc_pc_ann@detrend_option
        delete([/x_Lead_y,y_Lead_x,AMO_wgt,amoc_pc_ann_wgt,twgt,AMO/])
     end if
;-----------------------------------------------------------------------------------
; Compute AMOC spectra
;-----------------------------------------------------------------------------------
     jave = (1*nyr(ee))/100   ; calculate spectra of AMOC PC1
     if (jave.eq.0) then
       jave = 1
     end if   
     if (.not.any(ismissing(amoc_pc_ann))) then
        sdof = specx_anal(amoc_pc_ann,iopt,jave,pct)
        splt1 := specx_ci(sdof,val1,val2)
        splt1!0 = "ncurves"
        splt1&ncurves = ispan(0,3,1)
        splt1&ncurves@long_name = "power spectra curves"
        splt1&ncurves@units = "1"
        splt1!1 = "frequency2"
        splt1&frequency2 = sdof@frq
        splt1&frequency2@long_name = "power spectra frequency"
        splt1&frequency2@units = "1"
        splt1@detrend_option = amoc_pc_ann@detrend_option
        splt1@units_info = "df refers to frequency interval; data are standardized so there are no physical units"
        splt1@units = "1/df"
        splt1@info = "(0,:)=spectrum,(1,:)=Markov red noise spectrum, (2,:)="+val1+"% confidence bound for Markhov, (3,:)="+val2+"% confidence bound for Markhov"
        delete([/sdof/])
     end if
;-----------------------------------------------------------------------------------
; Write out data
;-----------------------------------------------------------------------------------
     z = addfile(fnt,"c")
     set_global_ncfile_attributes(z,names(ee),syear(ee),eyear(ee),getenv("VERSION"))
     if (isvar("splt1")) then
        z->$(/"amoc_spectra_ann"/)$ = set_varAtts(splt1,"AMOC (monthly) power spectra, Markov spectrum and confidence curves","","")   
        delete(splt1)
     end if
     if (isvar("ccr")) then
        z->$(/"amoc_amv_lag_cor"/)$ = set_varAtts(ccr,"","1","")
        delete(ccr)
     end if
     z->$(/"amoc_timeseries_ann"/)$ = set_varAtts(amoc_pc_ann,"","1","")
     z->$(/"amoc_mean_ann"/)$   = set_varAtts(moc_mean_ann,"AMOC mean (annual)","","") 
     z->$(/"amoc_stddev_ann"/)$ = set_varAtts(moc_sd_ann,"AMOC standard deviation (annual)","","")
     z->$(/"amoc_pattern_ann"/)$    = set_varAtts(moc_reg_ann,"AMOC regression onto AMOC principal component timeseries (annual)","","") 
     delete([/z,amoc_pc_ann,moc_mean_ann,moc_sd_ann,moc_reg_ann/])

     if (isvar("sst_reg_ann")) then
        z = addfile(getenv("OUTDIR")+modname_ts(ee)+".cvdp_data.amoc.ts."+syear_ts(ee)+"-"+eyear_ts(ee)+".nc","c")
        set_global_ncfile_attributes(z,names_ts(ee),syear_ts(ee),eyear_ts(ee),getenv("VERSION"))
        z->$(/"amoc_sst_regression_ann"/)$ = set_varAtts(sst_reg_ann,"sst regression onto AMOC principal component timeseries (annual)","","") 
        delete([/z,sst_reg_ann/]) 
     end if
     if (isvar("tas_reg_ann")) then
        z = addfile(getenv("OUTDIR")+modname_tas(ee)+".cvdp_data.amoc.tas."+syear_tas(ee)+"-"+eyear_tas(ee)+".nc","c")
        set_global_ncfile_attributes(z,names_tas(ee),syear_tas(ee),eyear_tas(ee),getenv("VERSION"))
        z->$(/"amoc_tas_regression_ann"/)$ = set_varAtts(tas_reg_ann,"tas regression onto AMOC principal component timeseries (annual)","","") 
        delete([/z,tas_reg_ann/]) 
     end if
     if (isvar("zos_reg_ann")) then
        z = addfile(getenv("OUTDIR")+modname_zos(ee)+".cvdp_data.amoc.zos."+syear_zos(ee)+"-"+eyear_zos(ee)+".nc","c")
        set_global_ncfile_attributes(z,names_zos(ee),syear_zos(ee),eyear_zos(ee),getenv("VERSION"))
        if (isatt(zos_reg_ann,"lat2d")) then    ; if there is a lat2d there will be a lon2d
           LAT2D = zos_reg_ann@lat2d
           LON2D = zos_reg_ann@lon2d
           delete([/zos_reg_ann@lat2d,zos_reg_ann@lon2d/])
           copy_VarCoords(zos_reg_ann,LAT2D)
           copy_VarCoords(zos_reg_ann,LON2D)
           z->$(/"lat2d_ocean"/)$ = set_varAtts(LAT2D,"ocean grid 2-dimensional latitudes","degrees_north","")
           z->$(/"lon2d_ocean"/)$ = set_varAtts(LON2D,"ocean grid 2-dimensional longitudes","degrees_east","")
           delete([/LAT2D,LON2D/])
           zos_reg_ann@coordinates ="lat2d_ocean lon2d_ocean"
        end if  
        z->$(/"amoc_zos_regression_ann"/)$ = set_varAtts(zos_reg_ann,"zos regression onto AMOC principal component timeseries (annual)","","") 
        delete([/z,zos_reg_ann/]) 
     end if

  end do

  if (CREATE_GRAPHICS.eq."False") then
     print("Finished: amoc.ncl")
     exit
  end if 
;========================================================================
  wks_type = OUTPUT_TYPE
  if (wks_type.eq."png") then
     wks_type@wkWidth = 1500*PNG_SCALE
     wks_type@wkHeight = 1500*PNG_SCALE
  end if

  pres = True
  pres@vpHeightF = 0.6
  pres@vpWidthF = 0.6
  pres@trYMinF = 0.
  pres@trXMinF = 0.0
  pres@trXMaxF = 0.25
  pres@gsnFrame      = False
  pres@gsnDraw       = False
  
  pres@tmXBLabelDeltaF = -.8
  pres@tmXTLabelDeltaF = -.8
  pres@pmLegendDisplayMode    = "Never"
  pres@xyDashPatterns      = (/0,0,0,0/)
  pres@xyMonoLineThickness = False
  pres@xyLineColors        = (/"foreground","red","blue","green"/)       
  pres@xyLabelMode = "custom"
  pres@xyLineLabelFontColors = pres@xyLineColors 
  pres@xyExplicitLabels = (/"","",val1*100+"%",val2*100+"%"/)
  if (wks_type.eq."png") then
     pres@xyLineThicknessF = 3.5
  else
     pres@xyLineThicknessF = 1.75
  end if
  pres@tmXTOn = True
  pres@tmYROn = False
  pres@tmXTLabelsOn = True
  pres@tmXUseBottom = False
  pres@tmXTMode   = "Explicit"  
  pres@tmXTValues = (/.02,.05,.10,.143,.20,.25,.3333,.50/)
  pres@tmXTLabels = (/"50","20","10","7","5","4","3","2"/)           
  pres@tmYLMode = "Explicit"
  pres@tmXTLabelFontHeightF = 0.021
  pres@tmXBLabelFontHeightF = 0.021
  pres@tmYLLabelFontHeightF = 0.021
  pres@tiYAxisString = "Power ( / cycles mo~S~-1~N~)"              ; yaxis
  pres@tiXAxisString = "Frequency (cycles mo~S~-1~N~)"
  pres@tiMainString = ""
  pres@txFontHeightF = 0.025
  pres@xyLineLabelFontHeightF = 0.022
  pres@tiXAxisFontHeightF = 0.025
  pres@tiYAxisFontHeightF = 0.025
  pres@tiMainFontHeightF = 0.03
  pres@gsnRightStringOrthogonalPosF = -0.135

  pres_sumA = pres   ; for summary ensemble mean line plot
  pres_sumA@xyCurveDrawOrder = "PreDraw"
  if (wks_type.eq."png") then
     pres_sumA@xyLineThicknessF = 16.
  else
     pres_sumA@xyLineThicknessF = 3.
  end if

  pres2 = pres
  pres2@xyLineColors        := (/"transparent","transparent"/)       
  pres2@xyCurveDrawOrder = "PreDraw"
  pres2@xyDashPattern      = 0
  pres2@gsnXYOpacities = 0.7
  pres2@xyLineColor = "transparent"

  txres = True
  txres@txFontHeightF = 0.010

  panres = True
  panres@gsnMaximize = True  
  panres@gsnPaperOrientation = "portrait"
  panres@gsnMainPanelFontHeightF = 0.013
  panres@gsnPanelBottom = 0.05
  ncol = floattointeger(sqrt(nsim))
  nrow = (nsim/ncol)+mod(nsim,ncol)
  nEM = max(EM_num)
  ncolE = floattointeger(sqrt(nEM+1))   ; +1 for the summary plot
  nrowE = ((nEM+1)/ncolE)+mod(nEM+1,ncolE)

  panres2 = panres
  panres2@gsnFrame = False
  panres2@gsnMaximize = False

  csubtitle_color = set_subtitle_colors(max(EM_num))

  variname := (/"amoc_spectra_ann"/)
  variname_obs := (/"amoc_spectra_ann"/)
  outputname = "amoc.powspec"

  wks = gsn_open_wks(wks_type,getenv("OUTDIR")+"amoc.powspec")

  plot_indmem      = new(nsim,"graphic")
  plot_obs_overlay = new(nsim,"graphic")
  if (nEM.ge.1) then
     plot_summary     = new(nEM,"graphic")    ; for ensemble plots to show the 10-90% range
     plot_summary2    = new(nEM,"graphic")    ; for ensemble plots to show the 25-75% range
     plot_obs_summary = new(nEM,"graphic")    ; for ensemble plots to show the 1st observational dataset
     plot_summary_em  = new(nEM,"graphic")    ; for ensemble plots to show ensemble mean
     plot_sum        := new(nEM,"graphic")    ; for individual panel in ensemble plots showing each ensemble mean
  end if
  YMaxF := new(1,double)

  numobs = num(EM_num.eq.0) 
  if (numobs.eq.0) then
     fnt = getenv("OUTDIR")+"obs.cvdp_data.amoc."+syear(0)+"-"+eyear(0)+".nc"
     fnt2 = getenv("OUTDIR")+"obs.cvdp_data."+syear(0)+"-"+eyear(0)+".nc"
     cntr = 0
  else
     fnt = getenv("OUTDIR")+modname(0)+".cvdp_data.amoc."+syear(0)+"-"+eyear(0)+".nc"
     fnt2 = getenv("OUTDIR")+modname(0)+".cvdp_data."+syear(0)+"-"+eyear(0)+".nc"
     cntr = 1
  end if
  obs0 := read_cvdp_le_data(fnt,fnt2,variname_obs)
  if (isatt(obs0,"is_all_missing")) then
     obs0New = new((/4,11/),float)
     copy_VarAtts(obs0,obs0New)
     obs0 := obs0New
     delete(obs0New)
     obs0!1 = "frequency2"
     obs0&frequency2 = fspan(0,0.1,11)
  else
     pres = powspec_set_yaxis(max(obs0(0,:)),pres)
  end if

  if (wks_type.eq."png") then
     pres@xyLineThicknesses   = (/7.5,2.,1.,1./) 
  else
     pres@xyLineThicknesses   = (/2.5,1.5,1.,1./) 
  end if

  pres@gsnLeftString = ""  
  pres@gsnCenterString = names(0)   
  pres@gsnRightString = syear(0)+"-"+eyear(0)+"   "  
  plot_indmem(0) = gsn_csm_xy(wks,obs0&frequency2,obs0,pres)
  cntr_EM = 0

  if (numobs.ge.2) then     ; plot obs #2-
     do ff = 1,numobs-1
        fnt = getenv("OUTDIR")+modname(cntr)+".cvdp_data.amoc."+syear(cntr)+"-"+eyear(cntr)+".nc"
        fnt2 = getenv("OUTDIR")+modname(cntr)+".cvdp_data."+syear(cntr)+"-"+eyear(cntr)+".nc"
        arr := read_cvdp_le_data(fnt,fnt2,variname_obs)
        if (isatt(arr,"is_all_missing")) then
           cntr = cntr+1
           continue
        end if
        pres@xyLineColors        = (/"foreground","red","blue","green"/)      
        pres = powspec_set_yaxis(max((/max(obs0(0,:)),max(arr(0,:))/)),pres)
        pres@gsnCenterString = names(cntr)   
        pres@gsnRightString = syear(cntr)+"-"+eyear(cntr)+"   " 
        plot_indmem(cntr) = gsn_csm_xy(wks,arr&frequency2,arr,pres)
        pres@xyCurveDrawOrder = "PreDraw"
        pres@xyLineColors        = (/"gray50","black","black","black"/)
        plot_obs_overlay(cntr)   = gsn_csm_xy(wks,obs0&frequency2,obs0(0,:),pres)
        overlay(plot_indmem(cntr),plot_obs_overlay(cntr))
        delete([/arr,pres@xyCurveDrawOrder/])
        cntr = cntr+1
     end do
  end if

  do gg = nEMm,nEM   ; operate on each ensemble mean (or individual member)
     if (gg.eq.0) then
        continue
     end if
     nens = num(EM_num.eq.gg) ; determines how many model simulations in each ensemble
     cntr_ens := ind(EM_num.eq.gg)   ; cntr_ens(hh) are the indices where each ensemble member of an ensemble reside 
     do hh = 0,nens-1
        modname_mod = modname(cntr_ens(hh))
        syear_mod = syear(cntr_ens(hh))
        eyear_mod = eyear(cntr_ens(hh))
        names_mod = names(cntr_ens(hh))
        names_EM_mod = names_EM(cntr_ens(hh))

        fnt = getenv("OUTDIR")+modname_mod+".cvdp_data.amoc."+syear_mod+"-"+eyear_mod+".nc"
        fnt2 = getenv("OUTDIR")+modname_mod+".cvdp_data."+syear_mod+"-"+eyear_mod+".nc"
        arr := read_cvdp_le_data(fnt,fnt2,variname)
        if (isatt(arr,"is_all_missing")) then
           cntr = cntr+1
           continue
        end if
        if (.not.isvar("arr_store")) then  ; create an array to house all members, to be used to calculate EM
           arr_store = new((/nens,dimsizes(arr&frequency2)/),typeof(arr))
           arr_store!0 = "ensmem"
           arr_store!1 = "frequency2"
           arr_store&frequency2 = arr&frequency2
           arr_store@nens = 0
           copy_VarAtts(arr,arr_store)

           syear_em0 = syear_mod
           eyear_em0 = eyear_mod
           showyr = True
        end if
        if (showyr) then
           if (syear_em0.ne.syear_mod.or.eyear_em0.ne.eyear_mod.and.showyr) then
              showyr = False
           end if
        end if
        arr_store(hh,:) = (/ arr(0,:) /) 
        arr_store@nens = arr_store@nens +1
        if (gg.ge.1) then
           pres@gsnCenterStringFontColor = csubtitle_color(gg-1)
        end if
        pres@xyLineColors        = (/"foreground","red","blue","green"/)      
        pres = powspec_set_yaxis(max((/max(obs0(0,:)),max(arr(0,:))/)),pres)
        pres@gsnCenterString = names_mod   
        pres@gsnRightString = syear_mod+"-"+eyear_mod+"   "
        plot_indmem(cntr) = gsn_csm_xy(wks,arr&frequency2,arr,pres)
        pres@xyCurveDrawOrder = "PreDraw"
        pres@xyLineColors        = (/"gray50","black","black","black"/)
        plot_obs_overlay(cntr)   = gsn_csm_xy(wks,obs0&frequency2,obs0(0,:),pres)
        overlay(plot_indmem(cntr),plot_obs_overlay(cntr))
        delete([/arr,pres@xyCurveDrawOrder/])
        cntr = cntr+1
     end do
     if (nEM.eq.0) then   ; in individual member mode (runstyle=1)
        if (isvar("arr_store")) then
           delete(arr_store)
        end if
        continue
     end if
     if (.not.isvar("arr_store")) then
        cntr_EM = cntr_EM+1
        continue
     end if
     delete([/pres@xyLineColors,pres@gsnCenterStringFontColor/])

     arr_EM := dim_avg_n_Wrap(arr_store,0)
     arr_range1 := define_arr_range_array(arr_EM,1) 
     arr_range2 := define_arr_range_array(arr_EM,2) 
     do zz = 0,dimsizes(arr_EM)-1
        ds := boxplot_stat(arr_store(:,zz))
        arr_range1(0,zz) = (/ ds(1) /)
        arr_range1(1,zz) = (/ ds(3) /)
        arr_range2(0,zz) = (/ ds(0) /)
        arr_range2(1,zz) = (/ ds(4) /)
     end do
     pres2@gsnLeftString = ""
     if (showyr) then
        pres2@gsnRightString = syear_em0+"-"+eyear_em0+"   " 
     else
        pres2@gsnRightString = (eyear_em0-syear_em0+1)+"yrs   " 
     end if
     delete([/syear_em0,eyear_em0,showyr/])

     YMaxF = tofloat(max((/YMaxF,max(arr_EM),max(obs0(0,:))/)))

     pres_sumA@xyLineColors = (/csubtitle_color(gg-1),"black","black","black"/)
     plot_sum(cntr_EM) = gsn_csm_xy(wks,arr_EM&frequency2,arr_EM,pres_sumA)
     pres2@gsnXYFillColors = (/30/356.,144/256.,1.,0.25/)  ;"dodgerblue"
     if (all(ismissing(arr_range2(0,:)))) then   ; The following resources result in NCL crashing on plot creation if data all missing
        delete(pres2@gsnXYFillColors)
     end if
     pres2@gsnCenterStringFontColor = csubtitle_color(gg-1)
     pres2@gsnCenterString = names_EM_mod +" ("+nens+" Members)"    
     pres@gsnRightString = ""
     pres2 = powspec_set_yaxis(max((/max(obs0(0,:)),max(arr_range2(1,:)),max(arr_EM)/)),pres2)
     pres = powspec_set_yaxis(max((/max(obs0(0,:)),max(arr_range2(1,:)),max(arr_EM)/)),pres)
     plot_summary(cntr_EM) = gsn_csm_xy(wks,arr_range2&frequency2,arr_range2,pres2)
     pres2@gsnXYFillColors = (/30/356.,144/256.,1.,0.5/)  ;"dodgerblue"
     if (all(ismissing(arr_range1(0,:)))) then   ; The following resources result in NCL crashing on plot creation if data all missing
        delete(pres2@gsnXYFillColors)
     end if
     plot_summary2(cntr_EM) = gsn_csm_xy(wks,arr_range1&frequency2,arr_range1,pres2)
     pres_sumA@xyLineColors        = (/"dodgerblue4","black","black","black"/)
     plot_summary_em(cntr_EM) = gsn_csm_xy(wks,arr_EM&frequency2,arr_EM,pres_sumA)
     pres_sumA@xyLineColors        = (/"gray50","black","black","black"/)
     plot_obs_summary(cntr_EM) = gsn_csm_xy(wks,obs0&frequency2,obs0(0,:),pres_sumA)
     overlay(plot_summary(cntr_EM),plot_summary2(cntr_EM))
     overlay(plot_summary(cntr_EM),plot_obs_summary(cntr_EM))
     overlay(plot_summary(cntr_EM),plot_summary_em(cntr_EM))
     if (isfilepresent2(getenv("OUTDIR")+str_sub_str(names_EM_mod," ","_")+"_EM.cvdp_data.amoc."+syear_mod+"-"+eyear_mod+".nc")) then
        z = addfile(getenv("OUTDIR")+str_sub_str(names_EM_mod," ","_")+"_EM.cvdp_data.amoc."+syear_mod+"-"+eyear_mod+".nc","w")
     else
        z = addfile(getenv("OUTDIR")+str_sub_str(names_EM_mod," ","_")+"_EM.cvdp_data.amoc."+syear_mod+"-"+eyear_mod+".nc","c")
        set_global_ncfile_attributes(z,names_EM_mod,syear_mod,eyear_mod,getenv("VERSION"))
     end if
     z->$(/variname+"_em"/)$ = set_varAtts(arr_EM,arr_EM@long_name+" Ensemble Mean","","")
     z->$(/variname+"_2575range"/)$ = set_varAtts(arr_range1,arr_EM@long_name+" 25/75% range","","")
     z->$(/variname+"_1090range"/)$ = set_varAtts(arr_range2,arr_EM@long_name+" 10/90% range","","")
     delete([/arr_store,arr_EM,arr_range1,arr_range2,z/])
     cntr_EM = cntr_EM+1
  end do
  panres@txString = "AMOC PC1 Power Spectra (Annual)"
  gsn_panel2(wks,plot_indmem,(/nrow,ncol/),panres)

  pres_sumA@xyCurveDrawOrder = "PostDraw"
  pres_sumA@xyLineColors        = (/"gray50","black","black","black"/)
  pres_sumA@gsnCenterString = "Ensemble Mean Summary"
  pres_sumA@gsnRightString = ""
  plot_obs := gsn_csm_xy(wks,obs0&frequency2,obs0(0,:),pres_sumA)

  if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
     YMaxF = YMaxF + (YMaxF*.05)
     plot_final := new(nEM+1,graphic)
     plot_final(:nEM-1) = plot_summary
     ii_ind := id_firstvalid_ind(plot_sum)
     if (.not.ismissing(ii_ind)) then
        overlay(plot_sum(ii_ind),plot_obs)
        do ii = ii_ind,nEM-1
           if (.not.ismissing(plot_sum(ii)).and.ii.ne.ii_ind) then
              overlay(plot_sum(ii_ind),plot_sum(ii))
           end if
        end do       
        setvalues plot_sum(ii_ind)
           "trYMaxF" : YMaxF
        end setvalues
        plot_final(nEM)    = plot_sum(ii_ind)
     end if
     panres2@gsnPanelMainPosYF = set_panel_title_YF(nEM+1,pres)
     panres2@gsnPanelMainString = "Ensemble Summary: AMOC PC1 Power Spectra (Annual)"
     gsn_panel2(wks,plot_final,(/nrowE,ncolE/),panres2)
     if (numobs.ne.0) then
        gsn_text_ndc(wks,names(0)+" "+syear(0)+"-"+eyear(0),0.5,panres2@gsnPanelMainPosYF-.02,txres)
     end if
     frame(wks)
     delete([/txres,plot_summary/])
  end if
  delete([/wks,plot_indmem,pres,pres2/])

  if (wks_type.eq."png") then
     if (nEM.lt.1) then   
        system("mv "+OUTDIR+"amoc.powspec.png "+OUTDIR+outputname+".indmem.png")
     else
        system("mv "+OUTDIR+"amoc.powspec.000001.png "+OUTDIR+outputname+".indmem.png")
        system("mv "+OUTDIR+"amoc.powspec.000002.png "+OUTDIR+outputname+".summary.png")
        if (PNG_SCALE_SUMMARY.ne.100) then
           system(IM_COMMAND+" "+OUTDIR+outputname+".summary.png -resize "+PNG_SCALE_SUMMARY+"% "+OUTDIR+outputname+".summary.png")
        end if
     end if
  else
     system("psplit "+OUTDIR+"amoc.powspec.ps "+OUTDIR+"amoc.powspec")
     system("mv "+OUTDIR+"amoc.powspec0001.ps "+OUTDIR+outputname+".indmem.ps")
     if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
        system("mv "+OUTDIR+"amoc.powspec0002.ps "+OUTDIR+outputname+".summary.ps")
     end if
     system("rm "+OUTDIR+"amoc.powspec.ps")
  end if
;-------------------------------------------------------------------------------------------------------------------
; Autocorrelation plotting section
;
  xyres = True
  xyres@gsnDraw = False
  xyres@gsnFrame = False
  xyres@vpHeightF = 0.4
  xyres@vpWidthF = 0.6
  xyres@gsnYRefLine = 0.0
  xyres@gsnYRefLineColor = "gray42"
  xyres@gsnXRefLine = 0.0
  xyres@gsnXRefLineColor = "gray42"
  xyres@tiYAxisString = ""
  xyres@tiMainOn = False
  xyres@trXMinF = -15
  xyres@trXMaxF = 15
  xyres@trYMinF = -1.05
  xyres@trYMaxF = 1.05
  if (wks_type.eq."png") then
     xyres@xyLineThicknessF = 7.5
  else
     xyres@xyLineThicknessF = 2.5
  end if
  xyres@xyLineColor = "royalblue"
  xyres@tmYLMode = "Explicit"
  xyres@tmYLValues = (/-1,-0.5,0,0.5,1/)
  xyres@tmYLLabels = (/"-1","-0.5","0","0.5","1"/)
  xyres@tmYLMinorValues = fspan(-1,1,9)
  xyres@tmXBMode = "Explicit"
  xyres@tmXBValues = ispan(-15,15,5)
  xyres@tmXBLabels = xyres@tmXBValues
  xyres@tmXBLabelFontHeightF = 0.021
  xyres@tmYLLabelFontHeightF = 0.021
  xyres@gsnLeftStringFontHeightF = 0.021
  xyres@gsnCenterStringFontHeightF = 0.025
  xyres@gsnRightStringFontHeightF = 0.021    
  xyres@gsnLeftStringOrthogonalPosF = -1.01
  xyres@gsnRightStringOrthogonalPosF = -1.01
  xyres@gsnLeftStringParallelPosF = 0.01
  xyres@gsnRightStringParallelPosF = 0.99
  xyres@gsnLeftString = "AMV Leads"
  xyres@gsnCenterString = ""
  xyres@gsnRightString = "AMOC PC1 Leads"

  xyres_obs = xyres
  xyres_obs@xyLineColor = "gray62"
  xyres_obs@xyCurveDrawOrder = "PreDraw"

  xyres2 = xyres
  delete([/xyres2@xyLineColor/])
  xyres2@xyLineColors        := (/"transparent","transparent"/)       
  xyres2@xyCurveDrawOrder = "PreDraw"
  xyres2@xyDashPattern      = 0
  xyres2@gsnXYOpacities = 0.7
  xyres2@xyLineColor = "transparent"

  txres = True
  txres@txFontHeightF = 0.010

  wks = gsn_open_wks(wks_type,getenv("OUTDIR")+"amoc_amv.leadlag")
  plot_indmem      := new(nsim,"graphic")
  plot_obs_overlay := new(nsim,"graphic")
  if (nEM.ge.1) then
     plot_summary     := new(nEM,"graphic")    ; for ensemble plots to show the 10-90% range
     plot_summary2    := new(nEM,"graphic")    ; for ensemble plots to show the 25-75% range
     plot_obs_summary := new(nEM,"graphic")    ; for ensemble plots to show the 1st observational dataset
     plot_summary_em  := new(nEM,"graphic")    ; for ensemble plots to show ensemble mean
     plot_sum         := new(nEM,"graphic")    ; for individual panel in ensemble plots showing each ensemble mean
  end if

  variname := (/"amoc_amv_lag_cor"/)
  variname_obs := (/"amoc_amv_lag_cor"/)
  outputname = "amoc_amv.leadlag.ann"

  numobs = num(EM_num.eq.0) 
  if (numobs.eq.0) then
     fnt = getenv("OUTDIR")+"obs.cvdp_data.amoc."+syear(0)+"-"+eyear(0)+".nc"
     fnt2 = getenv("OUTDIR")+"obs.cvdp_data."+syear(0)+"-"+eyear(0)+".nc"
     cntr = 0
  else
     fnt = getenv("OUTDIR")+modname(0)+".cvdp_data.amoc."+syear(0)+"-"+eyear(0)+".nc"
     fnt2 = getenv("OUTDIR")+modname(0)+".cvdp_data."+syear(0)+"-"+eyear(0)+".nc"
     cntr = 1
  end if
  obs0 := read_cvdp_le_data(fnt,fnt2,variname_obs)
  if (isatt(obs0,"is_all_missing")) then
     obs0New = new(6,float)
     copy_VarAtts(obs0,obs0New)
     obs0 := obs0New
     delete(obs0New)
     obs0!0 = "time_lag_cor"
     obs0&time_lag_cor = ispan(0,50,10)
  end if

  xyres@gsnCenterString = names(0)   
  xyres@gsnRightString = "      "+syear(0)+"-"+eyear(0)+"~C~AMOC PC1 Leads"  

  if (.not.isatt(obs0,"is_all_missing")) then
     plot_indmem(0) = gsn_csm_xy(wks,obs0&time_lag_cor,obs0,xyres)   ; plot first observational set
  end if
  cntr_EM = 0
  if (numobs.ge.2) then     ; plot obs #2-
     do ff = 1,numobs-1
        if (wks_type.eq."png") then
           xyres@xyLineThicknessF = 3.5
           xyres_obs@xyLineThicknessF = 3.5
        else
           xyres@xyLineThicknessF = 1.75
           xyres_obs@xyLineThicknessF = 1.75
        end if
        fnt = getenv("OUTDIR")+modname(cntr)+".cvdp_data.amoc."+syear(cntr)+"-"+eyear(cntr)+".nc"
        fnt2 = getenv("OUTDIR")+modname(cntr)+".cvdp_data."+syear(cntr)+"-"+eyear(cntr)+".nc"
        arr := read_cvdp_le_data(fnt,fnt2,variname_obs)
        if (isatt(arr,"is_all_missing")) then
           cntr = cntr+1
           continue
        end if
        xyres@gsnCenterString = names(cntr)   
        xyres@gsnRightString = "            "+syear(cntr)+"-"+eyear(cntr)+"~C~AMOC PC1 Leads"  
        plot_indmem(cntr) = gsn_csm_xy(wks,arr&time_lag_cor,arr,xyres)
        if (.not.isatt(obs0,"is_all_missing")) then
           plot_obs_overlay(cntr)   = gsn_csm_xy(wks,obs0&time_lag_cor,obs0,xyres_obs)
           overlay(plot_indmem(cntr),plot_obs_overlay(cntr))
        end if
        cntr = cntr+1
     end do
  end if
  do gg = nEMm,nEM   ; operate on each ensemble mean (or individual member)
     if (gg.eq.0) then
        continue
     end if
     if (wks_type.eq."png") then
        xyres@xyLineThicknessF = 3.5
        xyres_obs@xyLineThicknessF = 3.5
     else
        xyres@xyLineThicknessF = 1.75
        xyres_obs@xyLineThicknessF = 1.75
     end if
     xyres@xyLineColor        = "royalblue"
     nens = num(EM_num.eq.gg) ; determines how many model simulations in each ensemble
     cntr_ens := ind(EM_num.eq.gg)   ; cntr_ens(hh) are the indices where each ensemble member of an ensemble reside 
     do hh = 0,nens-1
        modname_mod = modname(cntr_ens(hh))
        syear_mod = syear(cntr_ens(hh))
        eyear_mod = eyear(cntr_ens(hh))
        names_mod = names(cntr_ens(hh))
        names_EM_mod = names_EM(cntr_ens(hh))

        fnt = getenv("OUTDIR")+modname_mod+".cvdp_data.amoc."+syear_mod+"-"+eyear_mod+".nc"
        fnt2 = getenv("OUTDIR")+modname_mod+".cvdp_data."+syear_mod+"-"+eyear_mod+".nc"
        arr := read_cvdp_le_data(fnt,fnt2,variname)
        if (isatt(arr,"is_all_missing")) then
           cntr = cntr+1
           continue
        end if
        if (gg.ge.1) then
           xyres@gsnCenterStringFontColor = csubtitle_color(gg-1)
        end if
        xyres@gsnCenterString = names_mod  
        xyres@gsnRightString = "            "+syear_mod+"-"+eyear_mod+"~C~AMOC PC1 Leads"   
        plot_indmem(cntr) = gsn_csm_xy(wks,arr&time_lag_cor,arr,xyres)
        if (.not.isatt(obs0,"is_all_missing")) then
           plot_obs_overlay(cntr)   = gsn_csm_xy(wks,obs0&time_lag_cor,obs0,xyres_obs)
           overlay(plot_indmem(cntr),plot_obs_overlay(cntr))
        end if
        if (.not.isvar("arr_store")) then
           arr_store = new((/nens,dimsizes(arr)/),typeof(arr))
           arr_store!0 = "ensmem"
           arr_store!1 = "time_lag_cor"
           arr_store&time_lag_cor = arr&time_lag_cor
           arr_store@nens = 0
           copy_VarAtts(arr,arr_store)

           syear_em0 = syear_mod
           eyear_em0 = eyear_mod
           showyr = True
        end if
        if (showyr) then
           if (syear_em0.ne.syear_mod.or.eyear_em0.ne.eyear_mod.and.showyr) then
              showyr = False
           end if
        end if
        arr_store(hh,:) = (/ arr /) 
        arr_store@nens = arr_store@nens +1
        cntr = cntr+1
     end do
     if (nEM.eq.0) then   ; in individual member mode (runstyle=1)
        if (isvar("arr_store")) then
           delete([/arr_store/])
        end if
        continue
     end if
     if (wks_type.eq."png") then
        xyres@xyLineThicknessF = 12.
        xyres_obs@xyLineThicknessF = 12.
     else
        xyres@xyLineThicknessF = 5.5
        xyres_obs@xyLineThicknessF = 5.5
     end if

     if (.not.isvar("arr_store")) then
        cntr_EM = cntr_EM+1
        continue
     end if
     arr_EM := dim_avg_n_Wrap(arr_store,0)
     arr_range1 := define_arr_range_array(arr_EM,1) 
     arr_range2 := define_arr_range_array(arr_EM,2) 
     do zz = 0,dimsizes(arr_EM)-1
        ds := boxplot_stat(arr_store(:,zz))
        arr_range1(0,zz) = (/ ds(1) /)
        arr_range1(1,zz) = (/ ds(3) /)
        arr_range2(0,zz) = (/ ds(0) /)
        arr_range2(1,zz) = (/ ds(4) /)
     end do

     xyres2@gsnLeftString = ""
     if (showyr) then
        xyres2@gsnRightString = "            "+syear_em0+"-"+eyear_em0+"~C~AMOC PC1 Leads"   
     else
        xyres2@gsnRightString = "               "+(eyear_em0-syear_em0+1)+"yrs~C~AMOC PC1 Leads"  
     end if
     delete([/syear_em0,eyear_em0,showyr/])

     xyres2@gsnCenterString = names_EM_mod +" ("+nens+" Members)"  
     xyres2@gsnCenterStringFontColor = csubtitle_color(gg-1)  
     xyres_obs@xyLineColor        = csubtitle_color(gg-1)
     xyres_obs@gsnCenterString = "Ensemble Mean Summary"
     plot_sum(cntr_EM) = gsn_csm_xy(wks,arr_EM&time_lag_cor,arr_EM,xyres_obs)
     xyres_obs@gsnCenterString = ""

     xyres2@gsnXYFillColors = (/30/356.,144/256.,1.,0.25/)  ;"dodgerblue"    
     if (all(ismissing(arr_range2(0,:)))) then   ; The following resources result in NCL crashing on plot creation if data all missing
        delete(xyres2@gsnXYFillColors)
     end if
     plot_summary(cntr_EM) = gsn_csm_xy(wks,arr_EM&time_lag_cor,arr_range2,xyres2)
     xyres2@gsnXYFillColors = (/30/356.,144/256.,1.,0.5/)  ;"dodgerblue"     
     if (all(ismissing(arr_range1(0,:)))) then   ; The following resources result in NCL crashing on plot creation if data all missing
        delete(xyres2@gsnXYFillColors)
     end if
     plot_summary2(cntr_EM) = gsn_csm_xy(wks,arr_EM&time_lag_cor,arr_range1,xyres2)
     xyres_obs@xyLineColor        = "dodgerblue4"
     plot_summary_em(cntr_EM) = gsn_csm_xy(wks,arr_EM&time_lag_cor,arr_EM,xyres_obs)
     xyres_obs@xyLineColor        = "gray50"
     plot_obs_summary(cntr_EM) = gsn_csm_xy(wks,obs0&time_lag_cor,obs0,xyres_obs)
     overlay(plot_summary(cntr_EM),plot_summary2(cntr_EM))
     overlay(plot_summary(cntr_EM),plot_obs_summary(cntr_EM))
     overlay(plot_summary(cntr_EM),plot_summary_em(cntr_EM))
     if (isfilepresent2(getenv("OUTDIR")+str_sub_str(names_EM_mod," ","_")+"_EM.cvdp_data.amoc."+syear_mod+"-"+eyear_mod+".nc")) then
        z = addfile(getenv("OUTDIR")+str_sub_str(names_EM_mod," ","_")+"_EM.cvdp_data.amoc."+syear_mod+"-"+eyear_mod+".nc","w")
     else
        z = addfile(getenv("OUTDIR")+str_sub_str(names_EM_mod," ","_")+"_EM.cvdp_data.amoc."+syear_mod+"-"+eyear_mod+".nc","c")
        set_global_ncfile_attributes(z,names_EM_mod,syear_mod,eyear_mod,getenv("VERSION"))
     end if
     z->$(/variname+"_em"/)$ = set_varAtts(arr_EM,arr_EM@long_name+" Ensemble Mean","","")
     z->$(/variname+"_2575range"/)$ = set_varAtts(arr_range1,arr_EM@long_name+" 25/75% range","","")
     z->$(/variname+"_1090range"/)$ = set_varAtts(arr_range2,arr_EM@long_name+" 10/90% range","","")
     delete([/arr_store,arr_EM,arr_range1,arr_range2,z/])
     cntr_EM = cntr_EM+1
  end do
  panres@txString = "AMV / AMOC PC1 Lag Correlation (Annual)"
  gsn_panel2(wks,plot_indmem,(/nrow,ncol/),panres)

  xyres_obs@xyCurveDrawOrder = "PostDraw"
  xyres_obs@xyLineColor        = "gray50"
  xyres_obs@gsnCenterString = "Ensemble Mean Summary"
  xyres_obs@gsnRightString = ""
  if (.not.isatt(obs0,"is_all_missing")) then
     plot_obs := gsn_csm_xy(wks,obs0&time_lag_cor,obs0,xyres_obs)
  end if

  if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
     plot_final := new(nEM+1,graphic)
     plot_final(:nEM-1) = plot_summary
     ii_ind := id_firstvalid_ind(plot_sum)
     if (.not.ismissing(ii_ind)) then
        if (.not.isatt(obs0,"is_all_missing")) then
           overlay(plot_sum(ii_ind),plot_obs)
        end if
        do ii = ii_ind,nEM-1 
           if (.not.ismissing(plot_sum(ii)).and.ii.ne.ii_ind) then
              overlay(plot_sum(ii_ind),plot_sum(ii))
           end if
        end do      
        plot_final(nEM)    = plot_sum(0)
     end if

     panres2@gsnPanelMainPosYF = set_panel_title_YF(nEM,xyres)
     panres2@gsnPanelMainString = "Ensemble Summary: AMV / AMOC PC1 Lag Correlation (Annual)"
     gsn_panel2(wks,plot_final,(/nrowE,ncolE/),panres2)
     if (numobs.ne.0) then  
        gsn_text_ndc(wks,names(0)+" "+syear(0)+"-"+eyear(0),0.5,panres2@gsnPanelMainPosYF-.02,txres)
     end if
     frame(wks)
     delete([/plot_summary,txres,plot_final/])
  end if
  delete([/wks,plot_indmem,xyres,xyres_obs,xyres2,panres,panres2/])

  if (wks_type.eq."png") then
     if (nEM.lt.1) then  
        if (fileexists(OUTDIR+"amoc_amv.leadlag.png")) then
           system("mv "+OUTDIR+"amoc_amv.leadlag.png "+OUTDIR+outputname+".indmem.png")
        end if
     else
        if (fileexists(OUTDIR+"amoc_amv.leadlag.000001.png")) then
           system("mv "+OUTDIR+"amoc_amv.leadlag.000001.png "+OUTDIR+outputname+".indmem.png")
           system("mv "+OUTDIR+"amoc_amv.leadlag.000002.png "+OUTDIR+outputname+".summary.png")
           if (PNG_SCALE_SUMMARY.ne.100) then
              system(IM_COMMAND+" "+OUTDIR+outputname+".summary.png -resize "+PNG_SCALE_SUMMARY+"% "+OUTDIR+outputname+".summary.png")
           end if
        end if
     end if
  else
     if (fileexists(OUTDIR+"amoc_amv.leadlag.ps")) then
        system("psplit "+OUTDIR+"amoc_amv.leadlag.ps "+OUTDIR+"amoc_amv.leadlag")
        system("mv "+OUTDIR+"amoc_amv.leadlag0001.ps "+OUTDIR+outputname+".indmem.ps")
        if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
           system("mv "+OUTDIR+"amoc_amv.leadlag0002.ps "+OUTDIR+outputname+".summary.ps")
        end if
        system("rm "+OUTDIR+"amoc_amv.leadlag.ps")
     end if
  end if
;---Timeseries plotting section--------------------------------------------------------------------------------------------
  xyres = True    ; individual obs/model line plot resource list
  xyres@gsnDraw = False
  xyres@gsnFrame = False
  xyres@gsnYRefLine = 0.0
  xyres@gsnYRefLineColor = "gray42"
     
  if (wks_type.eq."png") then
     xyres@xyLineThicknessF = 4.
  else
     xyres@xyLineThicknessF = 2.
  end if
  xyres@xyLineColor = "royalblue"
  xyres@tiYAxisString = ""
  xyres@tmXBLabelFontHeightF = 0.015
  xyres@tmYLLabelFontHeightF = 0.015
  xyres@gsnLeftStringFontHeightF = 0.0175     
  xyres@gsnCenterStringFontHeightF = 0.0135   
  xyres@gsnRightStringFontHeightF = xyres@gsnCenterStringFontHeightF  
  xyres@gsnLeftStringOrthogonalPosF = 0.025
  xyres@gsnCenterStringOrthogonalPosF = 0.036
  xyres@gsnRightStringOrthogonalPosF = xyres@gsnLeftStringOrthogonalPosF
  xyres@gsnCenterStringParallelPosF = 0.65
  xyres@vpHeightF = 0.25
  xyres@vpWidthF = 0.7
  xyres@gsnLeftString = ""     
  xyres@gsnCenterString = ""
  xyres@gsnRightString = ""
     
  xyres2 = xyres     ; for observational line overlays in individual panels
  xyres2@xyLineColor = "gray60"
  xyres2@xyCurveDrawOrder = "PreDraw"

  xyres_sum = xyres
  xyres_sum@xyLineColor        = "dodgerblue2"
  xyres_sum@gsnCenterStringFontColor = "black"

  xyres2_sum = xyres2   ; for observational line overlays in ensemble panels

  if (wks_type.eq."png") then
     xyres_sum@xyLineThicknessF = 16.
     xyres2_sum@xyLineThicknessF = 16.
  else
     xyres_sum@xyLineThicknessF = 3.
     xyres2_sum@xyLineThicknessF = 3.
  end if

  xyres2A = xyres2   ; for observational line overlays in ensemble mean summary
  xyres2A@xyLineThicknessF = xyres_sum@xyLineThicknessF

  xyres_sumA = xyres   ; for summary ensemble mean line plot
  xyres_sumA@xyLineThicknessF = xyres_sum@xyLineThicknessF  

  xyres3_sum = xyres_sum   ; resource list for shaded 2 std dev range
  xyres3_sum@gsnXYFillColors = (/30/356.,144/256.,1.,0.25/)  ;"dodgerblue"
  xyres3_sum@xyLineColors        := (/"transparent","transparent"/)       
  xyres3_sum@xyDashPattern      = 0
  xyres3_sum@xyLineColor = "transparent"
  xyres3_sum@gsnRightStringFontColor = "black"

  xyres3b_sum = xyres3_sum   ; resource list for shaded 1 std dev range
  xyres3b_sum@gsnXYFillColors = (/30/356.,144/256.,1.,0.5/)  ;"dodgerblue"

  panres3 = True  ; panel resource list for individual member plots
  panres3@gsnMaximize = True  
  panres3@gsnPaperOrientation = "portrait"
  panres3@gsnMainPanelFontHeightF = 0.016
  panres3@gsnPanelBottom = 0.05
  panres3@gsnPanelYWhiteSpacePercent = 2.5

  panres4 = panres3  ; panel resource list for ensemble plots
  panres4@gsnMainPanelFontHeightF = 0.014
  panres4@gsnMaximize = False
  panres4@gsnFrame = False
  panres4@gsnPanelTop = 0.94
  panres4@gsnPanelXWhiteSpacePercent = 3.0
  panres4@gsnPanelYWhiteSpacePercent = 3.0

  txres = True
  txres@txFontHeightF = 0.010
  txres@txFontColor = xyres2@xyLineColor

  variname := (/"amoc_timeseries_ann"/)
  variname_obs := "amoc_timeseries_ann"
  variname_title := (/"AMOC PC1 (Annual)"/)

  do dd = 0,dimsizes(variname)-1
     wks = gsn_open_wks(wks_type,getenv("OUTDIR")+"amoc.timeseries")
     plot_indmem      := new(nsim,"graphic")   ; for individual obs/models
     plot_obs_overlay := new(nsim,"graphic")   ; for obs overlaid onto individual models
     if (nEM.ge.1) then
        plot_summary     := new(nEM,"graphic")    ; for ensemble plots  to show the 10-90% range
        plot_summary1    := new(nEM,"graphic")    ; for ensemble plots to show the 25-75% range
        plot_summary2    := new(nEM,"graphic")    ; for ensemble plots to show the ensemble mean
        plot_summary_obs_overlay := new(nEM,"graphic")  ; for ensemble plots to show overlaid obs
        plot_sum         := new(nEM,"graphic")    ; for individual panel in ensemble plots showing each ensemble mean
     end if
     XMinF := new(1,double)    ; used for summary timeseries plot showing all ensemble means
     XMaxF := new(1,double)
     YMinF := new(1,double)
     YMaxF := new(1,double)

     numobs = num(EM_num.eq.0) 
     if (numobs.eq.0) then
        fnt = getenv("OUTDIR")+"obs.cvdp_data.amoc."+syear(0)+"-"+eyear(0)+".nc"
        fnt2 = getenv("OUTDIR")+"obs.cvdp_data."+syear(0)+"-"+eyear(0)+".nc"
        cntr = 0
     else
        fnt = getenv("OUTDIR")+modname(0)+".cvdp_data.amoc."+syear(0)+"-"+eyear(0)+".nc"
        fnt2 = getenv("OUTDIR")+modname(0)+".cvdp_data."+syear(0)+"-"+eyear(0)+".nc"
        cntr = 1
     end if
     obs0 := read_cvdp_le_data(fnt,fnt2,variname_obs(dd))
     if (isatt(obs0,"is_all_missing")) then 
        obs0New = new((eyear(0)-syear(0)+1),float)
        copy_VarAtts(obs0,obs0New)
        obs0 := obs0New
        obs0!0 = "time"
        obs0&time = ispan(syear(0),eyear(0),1)
        delete(obs0New)
     end if
     obs0!0 = "time"
     obs0&time = ispan(syear(0),eyear(0),1)
     xyres@gsnLeftStringFontColor = "black"
     xyres2@gsnLeftStringFontColor = "black"
     if (isatt(xyres,"trYMinF")) then
        delete([/xyres@trYMinF,xyres@trYMaxF/])
     end if
     xyres@trXMinF = syear(0)-.5
     xyres@trXMaxF = eyear(0)+1.5
     xyres@gsnLeftString = names(0)
     if (all(ismissing(obs0))) then
        obs_val = "Insufficient Coverage"
        ztxt = ""
     else
        ztxt = "Linear trend = "
        tttt := dtrend_msg(ispan(0,dimsizes(obs0&time)-1,1),obs0,False,True)   
        obs_val := decimalPlaces(tttt@slope*dimsizes(obs0&time),2,True)+obs0@units+" "+nyr(0)+"yr~S~-1~N~"
     end if
     xyres@gsnRightString = obs_val
     plot_indmem(0) = gsn_csm_xy(wks,obs0&time,obs0,xyres)
     xyres2A@gsnLeftString = "Ensemble Mean Summary"
     plot_obs := gsn_csm_xy(wks,obs0&time,obs0,xyres2A)
     cntr_EM = 0
     if (numobs.ge.2) then     ; plot obs #2-
        do ff = 1,numobs-1
           fnt = getenv("OUTDIR")+modname(cntr)+".cvdp_data.amoc."+syear(cntr)+"-"+eyear(cntr)+".nc"
           fnt2 = getenv("OUTDIR")+modname(cntr)+".cvdp_data."+syear(cntr)+"-"+eyear(cntr)+".nc"
           arr := read_cvdp_le_data(fnt,fnt2,variname_obs(dd))
           if (isatt(arr,"is_all_missing")) then 
              cntr = cntr+1
              continue
           end if
           arr!0 = "time"
           arr&time = ispan(syear(cntr),eyear(cntr),1)
           xyres@trXMinF = syear(cntr)-.5
           xyres@trXMaxF = eyear(cntr)+0.5
           xyres@trYMinF = min((/min(obs0),min(arr)/))-dim_stddev(arr)/2.
           xyres@trYMaxF = max((/max(obs0),max(arr)/))+dim_stddev(arr)/2.
           tttt := dtrend_msg(ispan(0,dimsizes(arr&time)-1,1),arr,False,True)   
           xyres@gsnLeftString = names(cntr)
           xyres@gsnRightString = decimalPlaces(tttt@slope*dimsizes(arr&time),2,True)+arr@units+" "+nyr(cntr)+"yr~S~-1~N~"
           plot_indmem(cntr) = gsn_csm_xy(wks,arr&time,arr,xyres)
           plot_obs_overlay(cntr) = gsn_csm_xy(wks,obs0&time,obs0,xyres2)
           overlay(plot_indmem(cntr),plot_obs_overlay(cntr))
           delete([/arr,tttt/])
           cntr = cntr+1
        end do
     end if
     do gg = nEMm,nEM   ; operate on each ensemble mean (or individual member)
        if (gg.eq.0) then
           continue
        end if
        nens = num(EM_num.eq.gg) ; determines how many model simulations in each ensemble
        cntr_ens := ind(EM_num.eq.gg)   ; cntr_ens(hh) are the indices where each ensemble member of an ensemble reside 

        do hh = 0,nens-1
           modname_mod = modname(cntr_ens(hh))
           syear_mod = syear(cntr_ens(hh))
           eyear_mod = eyear(cntr_ens(hh))
           names_mod = names(cntr_ens(hh))
           names_EM_mod = names_EM(cntr_ens(hh))

           fnt = getenv("OUTDIR")+modname_mod+".cvdp_data.amoc."+syear_mod+"-"+eyear_mod+".nc"
           fnt2 = getenv("OUTDIR")+modname_mod+".cvdp_data."+syear_mod+"-"+eyear_mod+".nc"
           arr := read_cvdp_le_data(fnt,fnt2,variname(dd))
           if (isatt(arr,"is_all_missing")) then 
              cntr = cntr+1
              continue
           end if
           arr!0 = "time"
           arr&time = ispan(syear_mod,eyear_mod,1)
           if (.not.isvar("arr_store")) then  ; create an array to house all members, to be used to calculate EM
              arr_store := new((/nens,dimsizes(arr&time)/),typeof(arr))
              arr_store!0 = "ensmem"
              arr_store!1 = "time"
              arr_store&time = arr&time
              arr_store@nens = 0
              copy_VarAtts(arr,arr_store)

              syear_em0 = syear_mod
              eyear_em0 = eyear_mod
              showyr = True
           end if
           if (showyr) then
              if (syear_em0.ne.syear_mod.or.eyear_em0.ne.eyear_mod.and.showyr) then
                 showyr = False
              end if
           end if
           arr_store(hh,:) = (/ arr /)
           arr_store@nens = arr_store@nens +1
           if (gg.ge.1) then
              xyres@gsnLeftStringFontColor = csubtitle_color(gg-1)
              xyres2@gsnLeftStringFontColor = csubtitle_color(gg-1)
           end if
           xyres@trXMinF = syear_mod-.5
           xyres@trXMaxF = eyear_mod+0.5
           xyres@trYMinF = min((/min(obs0),min(arr)/))-dim_stddev(arr)/2.
           xyres@trYMaxF = max((/max(obs0),max(arr)/))+dim_stddev(arr)/2.
           tttt := dtrend_msg(ispan(0,dimsizes(arr&time)-1,1),arr,False,True)   
           xyres@gsnLeftString = names_mod
           xyres@gsnRightString = decimalPlaces(tttt@slope*dimsizes(arr&time),2,True)+arr@units+" "+nyr(cntr)+"yr~S~-1~N~"
           plot_indmem(cntr) = gsn_csm_xy(wks,arr&time,arr,xyres)
           plot_obs_overlay(cntr) = gsn_csm_xy(wks,obs0&time,obs0,xyres2)
           overlay(plot_indmem(cntr),plot_obs_overlay(cntr))
           delete([/arr,tttt/])
           cntr = cntr+1
        end do
        if (nEM.eq.0) then   ; in individual member mode (runstyle=1)
           if (isvar("arr_store")) then
              delete(arr_store)
           end if
           continue
        end if
        if (.not.isvar("arr_store")) then
           cntr_EM = cntr_EM+1
           continue
        end if
        arr_EM := dim_avg_n_Wrap(arr_store,0)
        arr_range1 := define_arr_range_array(arr_EM,1) 
        arr_range2 := define_arr_range_array(arr_EM,2) 
        do zz = 0,dimsizes(arr_EM)-1
           ds := boxplot_stat(arr_store(:,zz))
           arr_range1(0,zz) = (/ ds(1) /)
           arr_range1(1,zz) = (/ ds(3) /)
           arr_range2(0,zz) = (/ ds(0) /)
           arr_range2(1,zz) = (/ ds(4) /)
        end do

        xyres3_sum@trXMinF := min(arr_EM&time)-.5
        xyres3_sum@trXMaxF := max(arr_EM&time)+0.5
        xyres3_sum@trYMinF = (/ min((/min(arr_EM),min(obs0),min(arr_range2)/))-dim_stddev(arr_EM)/2. /)
        xyres3_sum@trYMaxF = (/ max((/max(arr_EM),max(obs0),max(arr_range2)/))+dim_stddev(arr_EM)/2. /)

        XMinF = tofloat(min((/XMinF,min(arr_EM&time)/)))
        XMaxF = tofloat(max((/XMaxF,max(arr_EM&time)/)))
        YMinF = tofloat(min((/YMinF,min(arr_EM),min(obs0)/)))
        YMaxF = tofloat(max((/YMaxF,max(arr_EM),max(obs0)/)))
        
        xyres3_sum@gsnXYFillColors = (/30/356.,144/256.,1.,0.25/)  ;"dodgerblue"
        xyres3b_sum@gsnXYFillColors = (/30/356.,144/256.,1.,0.5/)  ;"dodgerblue"
        if (all(ismissing(arr_range2(0,:)))) then  ; necessary as gsnXYFillColors causes NCL to fail when data all missing
           delete(xyres3_sum@gsnXYFillColors)
           delete(xyres3b_sum@gsnXYFillColors)
        end if
        ssss := dtrend_msg(ispan(0,dimsizes(arr_store&time)-1,1),arr_store,False,True)
        tttt := dtrend_msg(ispan(0,dimsizes(arr_EM&time)-1,1),arr_EM,False,True)  
        xyres_sum@gsnLeftString = names_EM_mod +" ("+arr_store@nens+" Members)"   
        xyres_sum@gsnLeftStringFontColor = csubtitle_color(gg-1)
        xyres_sumA@xyLineColor = csubtitle_color(gg-1)
        xyres_sum@gsnCenterString = calculate_percent_in_range(obs0,arr_range2)+"%"
        ss_slope := ssss@slope
        ss_slope@_FillValue = arr_store@_FillValue
        stats := boxplot_stat(ss_slope)
        xyres3_sum@gsnRightString = decimalPlaces(stats(0)*dimsizes(arr_EM),2,True)+"/"+decimalPlaces(tttt@slope*dimsizes(arr_EM),2,True)+"/"+decimalPlaces(stats(4)*dimsizes(arr_EM),2,True)+" "+arr_EM@units+" "+(dimsizes(arr_EM)/12)+"yr~S~-1~N~"
        plot_summary(cntr_EM) = gsn_csm_xy(wks,arr_range2&time,arr_range2,xyres3_sum)
        plot_summary1(cntr_EM) = gsn_csm_xy(wks,arr_range1&time,arr_range1,xyres3b_sum)
        plot_summary2(cntr_EM) = gsn_csm_xy(wks,arr_EM&time,arr_EM,xyres_sum)
        plot_summary_obs_overlay(cntr_EM) = gsn_csm_xy(wks,obs0&time,obs0,xyres2_sum)
        xyres_sumA@gsnLeftString = "Ensemble Mean Summary"
        plot_sum(cntr_EM) = gsn_csm_xy(wks,arr_EM&time,arr_EM,xyres_sumA)
        overlay(plot_summary(cntr_EM),plot_summary1(cntr_EM))
        overlay(plot_summary(cntr_EM),plot_summary_obs_overlay(cntr_EM))
        overlay(plot_summary(cntr_EM),plot_summary2(cntr_EM))

        arr_EM!0 = "TIME"
        arr_range1!1 = "TIME"
        arr_range2!1 = "TIME"

        if (isfilepresent2(getenv("OUTDIR")+str_sub_str(names_EM_mod," ","_")+"_EM.cvdp_data.amoc."+syear_mod+"-"+eyear_mod+".nc")) then
           z = addfile(getenv("OUTDIR")+str_sub_str(names_EM_mod," ","_")+"_EM.cvdp_data.amoc."+syear_mod+"-"+eyear_mod+".nc","w")
        else
           z = addfile(getenv("OUTDIR")+str_sub_str(names_EM_mod," ","_")+"_EM.cvdp_data.amoc."+syear_mod+"-"+eyear_mod+".nc","c")
           set_global_ncfile_attributes(z,names_EM_mod,syear_mod,eyear_mod,getenv("VERSION"))
        end if
        z->$(/variname(dd)+"_em"/)$ = set_varAtts(arr_EM,arr_EM@long_name+" Ensemble Mean","","")
        z->$(/variname(dd)+"_2575range"/)$ = set_varAtts(arr_range1,arr_EM@long_name+" 25/75% range","","")
        z->$(/variname(dd)+"_1090range"/)$ = set_varAtts(arr_range2,arr_EM@long_name+" 10/90% range","","")
        delete([/arr_EM,tttt,ssss,arr_store,z/])
        cntr_EM = cntr_EM+1
     end do
     panres3@txString = variname_title(dd)
     gsn_panel2(wks,plot_indmem,(/nrow,ncol/),panres3)

     if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
        YMinF = YMinF - ((YMaxF - YMinF)*.05)
        YMaxF = YMaxF + ((YMaxF - YMinF)*.05)
        plot_final := new(nEM+1,graphic)
        plot_final(:nEM-1) = plot_summary
        ii_ind := id_firstvalid_ind(plot_sum)
        if (.not.ismissing(ii_ind)) then
           if (.not.ismissing(plot_obs)) then
              overlay(plot_sum(ii_ind),plot_obs)
           end if
           do ii = ii_ind,nEM-1 
              if (.not.ismissing(plot_sum(ii)).and.ii.ne.ii_ind) then
                 overlay(plot_sum(ii_ind),plot_sum(ii))
              end if
           end do     
           setvalues plot_sum(ii_ind)
              "trXMinF" : XMinF-0.5
              "trXMaxF" : XMaxF+0.5
              "trYMinF" : YMinF
              "trYMaxF" : YMaxF
           end setvalues
           plot_final(nEM)    = plot_sum(ii_ind)
        end if
        panres4@gsnPanelMainPosYF = set_panel_title_YF(nEM+1,xyres)
        panres4@gsnPanelMainString = "Ensemble Summary: "+variname_title(dd)
        gsn_panel2(wks,plot_final,(/nrowE,ncolE/),panres4)
        if (numobs.ne.0) then  
           gsn_text_ndc(wks,names(0)+" "+syear(0)+"-"+eyear(0)+", "+ztxt+obs_val,0.5,panres4@gsnPanelMainPosYF-.025,txres)
        end if
        frame(wks)
     end if
     delete(wks)

     if (wks_type.eq."png") then
        if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
           system("mv "+OUTDIR+"amoc.timeseries.000001.png "+OUTDIR+str_sub_str(variname(dd),"_",".")+".indmem.png")
           system("mv "+OUTDIR+"amoc.timeseries.000002.png "+OUTDIR+str_sub_str(variname(dd),"_",".")+".summary.png")
           if (PNG_SCALE_SUMMARY.ne.100) then
              system(IM_COMMAND+" "+OUTDIR+str_sub_str(variname(dd),"_",".")+".summary.png -resize "+PNG_SCALE_SUMMARY+"% "+OUTDIR+str_sub_str(variname(dd),"_",".")+".summary.png")
           end if
        else
           system("mv "+OUTDIR+"amoc.timeseries.png "+OUTDIR+str_sub_str(variname(dd),"_",".")+".indmem.png")
        end if
     else
        if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
           system("psplit "+OUTDIR+"amoc.timeseries.ps "+OUTDIR+"amoc.timeseries")
           system("mv "+OUTDIR+"amoc.timeseries0001.ps "+OUTDIR+str_sub_str(variname(dd),"_",".")+".indmem.ps")
           system("mv "+OUTDIR+"amoc.timeseries0002.ps "+OUTDIR+str_sub_str(variname(dd),"_",".")+".summary.ps")
           system("rm "+OUTDIR+"amoc.timeseries.ps")
        else
           system("mv "+OUTDIR+"amoc.timeseries.ps "+OUTDIR+str_sub_str(variname(dd),"_",".")+".indmem.ps")
        end if
     end if
  end do
;---AMOC TAS/SST Regressions plotting section---------------------------------------------------------------------------
  res = True
  res@mpProjection = "WinkelTripel"
  res@mpGeophysicalLineColor = "gray42"
  res@mpPerimOn    = False
  res@mpGridLatSpacingF =  90         ; change latitude  line spacing
  res@mpGridLonSpacingF = 180.        ; change longitude line spacing
  res@mpGridLineColor   = "transparent"  ; trick ncl into drawing perimeter
  res@mpGridAndLimbOn   = True        ; turn on lat/lon lines  
  res@mpFillOn = False
  res@mpCenterLonF = 210.
  res@mpOutlineOn = True  
  if (wks_type.eq."png") then
     res@mpGeophysicalLineThicknessF = 2.  
  else
     res@mpGeophysicalLineThicknessF = 1.  
  end if
  res@gsnDraw   = False
  res@gsnFrame  = False
  
  res@cnLineLabelsOn = False
  res@cnFillOn     = True
  res@cnLinesOn    = False

  res@lbLabelBarOn    = False
  res@pmLabelBarWidthF = 0.55
  res@pmLabelBarHeightF = 0.075
  res@lbBoxLineColor = "gray70"
  res@lbLabelFontHeightF = 0.02
  res@lbLabelStride = 1
  res@lbTitleOn = True
  res@lbTitleFontHeightF = res@lbLabelFontHeightF
  res@lbTitlePosition = "Bottom"
  res@cnNoDataLabelOn = False

  res@cnLevelSelectionMode = "ExplicitLevels"
  res@gsnLeftStringOrthogonalPosF = -0.05
  res@gsnLeftStringParallelPosF = .005
  res@gsnRightStringOrthogonalPosF = -0.05
  res@gsnRightStringParallelPosF = 0.995
  res@gsnLeftStringFontHeightF = 0.014
  res@gsnCenterStringFontHeightF = 0.018
  res@gsnRightStringFontHeightF = 0.014
  res@gsnLeftString = ""
  res@gsnCenterString = ""
  res@gsnRightString = ""

  tres = res    ; p-value plot resource list
  copy_VarAtts(retrieve_summary_res(),tres)
  delete(tres@cnMissingValFillColor)

  res2 = res    ; trend differences
  if (COLORMAP.eq.0) then
     res@cnFillPalette = "ncl_default"
  end if
  if (COLORMAP.eq.1) then
     res@cnFillPalette = "BlueDarkRed18"
  end if 
  res@cnLevels = fspan(-5.,5.,21)  
  res@lbLabelStride = 1
  res2@cnLevels = res@cnLevels
  res2@cnFillPalette = res@cnFillPalette

  res3 = True   ; res3 = tas regression resources for overlays    
  res3@gsnDraw      = False
  res3@gsnFrame     = False
  res3@cnLevelSelectionMode = "ExplicitLevels"
  res3@cnLevels = res@cnLevels
  res3@cnFillPalette = res@cnFillPalette

  res3@cnLineLabelsOn = False
  res3@cnFillOn        = True
  res3@cnLinesOn       = False
  res3@cnFillMode = "AreaFill"
  res3@lbLabelBarOn    = False
  res3@cnInfoLabelOn = False
  res3@gsnRightString = ""
  res3@gsnLeftString = "" 
  res3@gsnCenterString = ""   
  res3@gsnAddCyclic = True
  res3@cnNoDataLabelOn = False

  res4 = res3   ; res4 = tas regression differences resources for overlays
  res4@cnLevels := res2@cnLevels
  res4@cnFillPalette := res2@cnFillPalette

  tres2 = res3    ; p-value plots
  copy_VarAtts(retrieve_summary_res(),tres2)
  tres2@gsnCenterString = ""
  delete(tres2@cnMissingValFillColor)

  panres = True
  panres@gsnMaximize = True  
  panres@gsnPaperOrientation = "portrait"
  panres@gsnPanelLabelBar = True
  panres@gsnPanelYWhiteSpacePercent = 3.0
  panres@pmLabelBarHeightF = 0.05
  panres@pmLabelBarWidthF = 0.65
  panres@pmLabelBarOrthogonalPosF = -0.02
  panres@lbBoxLineColor = "gray70"
  panres@txFontHeightF = 0.016
  panres@gsnPanelBottom = 0.05
  panres@lbLabelFontHeightF = 0.013
  panres@lbLabelStride = 1
  panres@lbTitleOn = True
  panres@lbTitleFontHeightF = panres@lbLabelFontHeightF
  panres@lbTitlePosition = "Bottom"

  panres2 = True
  panres2@gsnPaperOrientation = "portrait"
  panres2@gsnPanelLabelBar = False
  panres2@gsnPanelYWhiteSpacePercent = 3.0
  panres2@txFontHeightF = 0.016
  panres2@gsnPanelBottom = 0.05

  variname = (/"amoc_var_regression_ann"/)
  variname_obs =(/"amoc_var_regression_ann"/)

  do dd = 0,dimsizes(variname)-1
     wks = gsn_open_wks(wks_type,getenv("OUTDIR")+"amoc_spareg")

     plot_indmem      := new(nsim,"graphic")
     plot_indmem_diff := new(nsim,"graphic")
     plot_indmem_ov      := new(nsim,"graphic")
     plot_indmem_diff_ov := new(nsim,"graphic")
     if (nEM.ge.1) then
        plot_summary     := new((nEM*4),"graphic")
        plot_summary_ov     := new((nEM*4),"graphic")
     end if
     numobs = num(EM_num.eq.0) 
     if (numobs.eq.0) then
        fnt = getenv("OUTDIR")+"obs.cvdp_data.amoc.tas."+syear_tas(0)+"-"+eyear_tas(0)+".nc"      
        fnt2 = getenv("OUTDIR")+"obs.cvdp_data."+syear_tas(0)+"-"+eyear_tas(0)+".nc"
        obs0 := read_cvdp_le_data(fnt,fnt2,str_sub_str(variname_obs(dd),"var","tas"))
        fnt = getenv("OUTDIR")+"obs.cvdp_data.amoc.ts."+syear(0)+"-"+eyear(0)+".nc"
        fnt2 = getenv("OUTDIR")+"obs.cvdp_data."+syear(0)+"-"+eyear(0)+".nc"
        sst0 := read_cvdp_le_data(fnt,fnt2,str_sub_str(variname_obs(dd),"var","sst"))
        cntr = 0
     else
        fnt = getenv("OUTDIR")+modname_tas(0)+".cvdp_data.amoc.tas."+syear_tas(0)+"-"+eyear_tas(0)+".nc"      
        fnt2 = getenv("OUTDIR")+modname_tas(0)+".cvdp_data."+syear_tas(0)+"-"+eyear_tas(0)+".nc"
        obs0 := read_cvdp_le_data(fnt,fnt2,str_sub_str(variname_obs(dd),"var","tas"))
        fnt = getenv("OUTDIR")+modname_ts(0)+".cvdp_data.amoc.ts."+syear(0)+"-"+eyear(0)+".nc"
        fnt2 = getenv("OUTDIR")+modname_ts(0)+".cvdp_data."+syear(0)+"-"+eyear(0)+".nc"
        sst0 := read_cvdp_le_data(fnt,fnt2,str_sub_str(variname_obs(dd),"var","sst"))
        cntr = 1
     end if
     m = addfile("$NCARG_ROOT/lib/ncarg/data/cdf/landsea.nc","r")     ; mask ocean for TAS array
     obs0 = mask(obs0,landsea_mask(m->LSMASK,obs0&lat,obs0&lon).eq.0,False)

     res@gsnCenterStringFontColor = "black"
     res2@gsnCenterStringFontColor = "black"
     res@lbLabelBarOn = False
     res2@lbLabelBarOn = False
     tres@lbLabelBarOn = False
     res@gsnLeftString = syear_tas(0)+"-"+eyear_tas(0) 
     res@gsnRightString = ""
     res@gsnCenterString = names_ts(0)+" / "+names_tas(0)      
     plot_indmem(0) = gsn_csm_contour_map(wks,obs0,res)
     plot_indmem_ov(0) = gsn_csm_contour(wks,sst0,res3)
     overlay(plot_indmem(0),plot_indmem_ov(0))

     cntr_EM = 0
     if (numobs.ge.2) then     ; plot obs #2-
        do ff = 1,numobs-1
           fnt = getenv("OUTDIR")+modname_tas(cntr)+".cvdp_data.amoc.tas."+syear_tas(cntr)+"-"+eyear_tas(cntr)+".nc"
           fnt2 = getenv("OUTDIR")+modname_tas(cntr)+".cvdp_data."+syear_tas(cntr)+"-"+eyear_tas(cntr)+".nc"
           arr := read_cvdp_le_data(fnt,fnt2,str_sub_str(variname_obs(dd),"var","tas"))
           if (isatt(arr,"is_all_missing")) then 
              cntr = cntr+1
              continue
           end if
           fnt = getenv("OUTDIR")+modname_ts(cntr)+".cvdp_data.amoc.ts."+syear(cntr)+"-"+eyear(cntr)+".nc"
           fnt2 = getenv("OUTDIR")+modname_ts(cntr)+".cvdp_data."+syear(cntr)+"-"+eyear(cntr)+".nc"
           sst := read_cvdp_le_data(fnt,fnt2,str_sub_str(variname_obs(dd),"var","sst"))

           m = addfile("$NCARG_ROOT/lib/ncarg/data/cdf/landsea.nc","r")     ; mask ocean for TAS array
           arr = mask(arr,landsea_mask(m->LSMASK,arr&lat,arr&lon).eq.0,False)

           res@gsnLeftString = syear_tas(cntr)+"-"+eyear_tas(cntr)
           res@gsnRightString = ""

           res@gsnCenterString = names_ts(cntr)+" / "+names_tas(cntr)
           res2@gsnLeftString = "" 
           res2@gsnRightString = ""
           res2@gsnCenterString = names_ts(cntr)+"/"+names_tas(cntr)+" -~C~"+names_ts(0)+"/"+names_tas(0)
           obs0_rg = linint2_Wrap(obs0&lon,obs0&lat,obs0,True,arr&lon,arr&lat,0)
           obs_diff = arr
           obs_diff = (/ arr - obs0_rg /)
           sst0_rg = linint2_Wrap(sst0&lon,sst0&lat,sst0,True,sst&lon,sst&lat,0)
           sst_diff = sst   
           sst_diff = (/ sst - sst0_rg /)   

           res@gsnRightString = pattern_correlation(sst0_rg,sst)+"/"+pattern_correlation(obs0_rg,arr)
           plot_indmem(cntr) = gsn_csm_contour_map(wks,sst,res)
           plot_indmem_ov(cntr)  = gsn_csm_contour(wks,arr,res3)
           overlay(plot_indmem(cntr),plot_indmem_ov(cntr))
           plot_indmem_diff(cntr) = gsn_csm_contour_map(wks,sst_diff,res2)   
           plot_indmem_diff_ov(cntr) = gsn_csm_contour(wks,obs_diff,res4)
           overlay(plot_indmem_diff(cntr),plot_indmem_diff_ov(cntr))
           delete([/arr,obs_diff,obs0_rg,sst_diff,sst0_rg,sst/])
           cntr = cntr+1
        end do
     end if
     do gg = nEMm,nEM   ; operate on each ensemble mean (or individual member)
        if (gg.eq.0) then
           continue
        end if
        lbFlag = summary_lb_flag(paths,EM_num,gg,nEM)  ; lbFlag set to True if summary labelbars should be drawn  
        nens = num(EM_num.eq.gg) ; determines how many model simulations in each ensemble
        cntr_ens := ind(EM_num.eq.gg)   ; cntr_ens(hh) are the indices where each ensemble member of an ensemble reside 
        do hh = 0,nens-1
           modname_mod = modname_tas(cntr_ens(hh))
           syear_mod = syear_tas(cntr_ens(hh))
           eyear_mod = eyear_tas(cntr_ens(hh))
           names_mod = names_tas(cntr_ens(hh))
           names_EM_mod = names_EM(cntr_ens(hh))
           modname_mod_sst = modname_ts(cntr_ens(hh))
           syear_mod_sst = syear_ts(cntr_ens(hh))
           eyear_mod_sst = eyear_ts(cntr_ens(hh))
           names_mod_sst = names_ts(cntr_ens(hh))
   
           fnt = getenv("OUTDIR")+modname_mod+".cvdp_data.amoc.tas."+syear_mod+"-"+eyear_mod+".nc"
           fnt2 = getenv("OUTDIR")+modname_mod+".cvdp_data."+syear_mod+"-"+eyear_mod+".nc"
           arr := read_cvdp_le_data(fnt,fnt2,str_sub_str(variname(dd),"var","tas"))
           if (isatt(arr,"is_all_missing")) then 
              cntr = cntr+1
              continue
           end if
           fnt = getenv("OUTDIR")+modname_mod_sst+".cvdp_data.amoc.ts."+syear_mod_sst+"-"+eyear_mod_sst+".nc"
           fnt2 = getenv("OUTDIR")+modname_mod_sst+".cvdp_data."+syear_mod+"-"+eyear_mod+".nc"
           sst := read_cvdp_le_data(fnt,fnt2,str_sub_str(variname(dd),"var","sst"))

           m = addfile("$NCARG_ROOT/lib/ncarg/data/cdf/landsea.nc","r")     ; mask ocean for TAS array
           arr = (/ mask(arr,landsea_mask(m->LSMASK,arr&lat,arr&lon).eq.0,False) /)

           if (.not.isvar("arr_store")) then  ; create an array to house all members, to be used to calculate EM
              arr_store = new((/nens,dimsizes(arr&lat),dimsizes(arr&lon)/),typeof(arr))
              arr_store!0 = "ensmem"
              arr_store!1 = "lat"
              arr_store&lat = arr&lat
              arr_store!2 = "lon"
              arr_store&lon = arr&lon
              arr_store@nens = 0
              copy_VarAtts(arr,arr_store)
   
              arr_store_sst = new((/nens,dimsizes(sst&lat),dimsizes(sst&lon)/),typeof(sst))
              arr_store_sst!0 = "ensmem"
              arr_store_sst!1 = "lat"
              arr_store_sst&lat = sst&lat
              arr_store_sst!2 = "lon"
              arr_store_sst&lon = sst&lon
              arr_store_sst@nens = 0
              copy_VarAtts(sst,arr_store_sst)
 
              syear_em0 = syear_mod
              eyear_em0 = eyear_mod
              showyr = True
           end if
           if (showyr) then
              if (syear_em0.ne.syear_mod.or.eyear_em0.ne.eyear_mod.and.showyr) then
                 showyr = False
              end if
           end if
           if (gg.ge.1) then
              res@gsnCenterStringFontColor = csubtitle_color(gg-1)
              res2@gsnCenterStringFontColor = csubtitle_color(gg-1)
           end if
           if (.not.isatt(arr,"is_all_missing")) then
              arr_store(hh,:,:) = (/ arr /)
              arr_store@nens = arr_store@nens +1
           end if
           if (.not.isatt(sst,"is_all_missing")) then
              arr_store_sst(hh,:,:) = (/ sst /)
              arr_store_sst@nens = arr_store_sst@nens +1
           end if
           panres@lbTitleString = arr@units

           res2@gsnLeftString = "" 
           res2@gsnRightString = ""
           res2@gsnCenterString = names_mod+" -~C~"+names(0)+"/"+names_tas(0) 
           if (.not.isvar("obs0_rg")) then  
              obs0_rg = linint2_Wrap(obs0&lon,obs0&lat,obs0,True,arr&lon,arr&lat,0)
           end if
           obs_diff = arr
           if (.not.isatt(arr,"is_all_missing")) then
              obs_diff = (/ arr - obs0_rg /)
           end if
           if (.not.isvar("sst0_rg")) then  
              sst0_rg = linint2_Wrap(sst0&lon,sst0&lat,sst0,True,sst&lon,sst&lat,0)
           end if
           sst_diff = sst
           if (.not.isatt(sst,"is_all_missing")) then
              sst_diff = (/ sst - sst0_rg /)
           end if

           res@gsnLeftString   = syear_mod+"-"+eyear_mod
           res@gsnRightString  = pattern_correlation(sst0_rg,sst)+"/"+pattern_correlation(obs0_rg,arr)
           res@gsnCenterString = names_mod
           plot_indmem(cntr) = gsn_csm_contour_map(wks,arr,res)
           plot_indmem_ov(cntr) = gsn_csm_contour(wks,sst,res3)
           overlay(plot_indmem(cntr),plot_indmem_ov(cntr))

           plot_indmem_diff(cntr) = gsn_csm_contour_map(wks,obs_diff,res2)
           plot_indmem_diff_ov(cntr) = gsn_csm_contour(wks,sst_diff,res4)
           overlay(plot_indmem_diff(cntr),plot_indmem_diff_ov(cntr))
           delete([/arr,obs_diff,sst_diff,sst/])
           cntr = cntr+1
        end do
        if (nEM.eq.0) then   ; in individual member mode (runstyle=1)
           if (isvar("arr_store")) then
              delete(arr_store)
           end if
           if (isvar("obs0_rg")) then
              delete(obs0_rg)
           end if
           if (isvar("sst0_rg")) then
              delete(sst0_rg)
           end if
           if (isvar("arr_store_sst")) then
              delete(arr_store_sst)
           end if
           continue
        end if
        if (.not.isvar("arr_store")) then
           cntr_EM = cntr_EM+4
           continue
        end if
        if (lbFlag) then
           res@lbLabelBarOn = True
           res2@lbLabelBarOn = True
           tres@lbLabelBarOn = True
        end if
        arr_EM := dim_avg_n_Wrap(arr_store,0)
        arr_sst_EM := dim_avg_n_Wrap(arr_store_sst,0)
   
        res@gsnCenterStringFontColor = "black"
        res2@gsnCenterStringFontColor = "black"

        res@lbTitleString = arr_EM@units   
        res@gsnLeftString = syear_tas(0)+"-"+eyear_tas(0) 
        res@gsnRightString = ""
        res@gsnCenterString = names(0)+"/"+names_tas(0)  ;"Observations ("+names(0)+"/"+names_tas(0)+")"     
        plot_summary(cntr_EM+1) = gsn_csm_contour_map(wks,obs0,res)
        plot_summary_ov(cntr_EM+1) = gsn_csm_contour(wks,sst0,res3)
        overlay(plot_summary(cntr_EM+1),plot_summary_ov(cntr_EM+1))
        if (showyr) then
           res@gsnLeftString = syear_em0+"-"+eyear_em0 
        else
           res@gsnLeftString = (eyear_em0-syear_em0+1)+"yrs" 
        end if
        delete([/syear_em0,eyear_em0,showyr/])
   
        res@gsnCenterStringFontColor = csubtitle_color(gg-1)
        res@gsnRightString = pattern_correlation(sst0_rg,arr_sst_EM)+"/"+pattern_correlation(obs0_rg,arr_EM)
        res@gsnCenterString = names_EM_mod +" ("+arr_store_sst@nens+"/"+arr_store@nens+" Members)"                                
        plot_summary(cntr_EM) = gsn_csm_contour_map(wks,arr_EM,res)
        plot_summary_ov(cntr_EM) = gsn_csm_contour(wks,arr_sst_EM,res3)
        overlay(plot_summary(cntr_EM),plot_summary_ov(cntr_EM))
        obs_diff = arr_EM
        obs_diff = (/ arr_EM - obs0_rg /)
        sst_diff = arr_sst_EM
        sst_diff = (/ arr_sst_EM - sst0_rg /)
        res2@lbTitleString = arr_EM@units
        res2@gsnLeftString = ""
        res2@gsnCenterString = names_EM_mod+" - "+names(0)+"/"+names_tas(0)
        res2@gsnRightString = ""
        plot_summary(cntr_EM+2) = gsn_csm_contour_map(wks,obs_diff,res2)
        plot_summary_ov(cntr_EM+2) = gsn_csm_contour(wks,sst_diff,res4)
        overlay(plot_summary(cntr_EM+2),plot_summary_ov(cntr_EM+2))
   
        tres@lbTitleString = "%"
        p_val = calculate_pval(obs0_rg,arr_store)
        tres@gsnRightStringParallelPosF = 1.025
        tres@gsnLeftString = "SST/TAS" 
        tres@gsnCenterString = "Rank of "+names(0)+"/"+names_tas(0)+" within Ensemble"   
        p_val2 = calculate_pval(sst0_rg,arr_store_sst)
        tres@gsnRightStringParallelPosF = .985
        tres@gsnRightString = calculate_area_in_range(p_val2,10,90)+" /"+calculate_area_in_range(p_val,10,90)+"%"
        plot_summary(cntr_EM+3) = gsn_csm_contour_map(wks,p_val2,tres)
        plot_summary_ov(cntr_EM+3) = gsn_csm_contour(wks,p_val,tres2)
        overlay(plot_summary(cntr_EM+3),plot_summary_ov(cntr_EM+3))
   
        fno = getenv("OUTDIR")+str_sub_str(names_EM_mod," ","_")+"_EM.cvdp_data.amoc.tas."+syear_mod+"-"+eyear_mod+".nc"
        if (isfilepresent2(fno)) then
           z = addfile(fno,"w")
        else
           z = addfile(fno,"c")
           set_global_ncfile_attributes(z,names_EM_mod,syear_mod,eyear_mod,getenv("VERSION"))
        end if
        z->$(/str_sub_str(variname(dd),"var","tas")+"_em"/)$ = set_varAtts(arr_EM,arr_EM@long_name+" Ensemble Mean","","")
        z->$(/str_sub_str(variname(dd),"var","tas")+"_em_diffobs"/)$ = set_varAtts(obs_diff,obs_diff@long_name+" Ensemble Mean difference from "+names_tas(0),"","")           
        z->$(/str_sub_str(variname(dd),"var","tas")+"_pval"/)$ = set_varAtts(p_val,arr_EM@long_name+" p-val statistic","%","")   
        delete(z)

        fno = getenv("OUTDIR")+str_sub_str(names_EM_mod," ","_")+"_EM.cvdp_data.amoc.ts."+syear_mod_sst+"-"+eyear_mod_sst+".nc"
        if (isfilepresent2(fno)) then
           z = addfile(fno,"w")
        else
           z = addfile(fno,"c")
           set_global_ncfile_attributes(z,names_EM_mod,syear_mod_sst,eyear_mod_sst,getenv("VERSION"))
        end if
        z->$(/str_sub_str(variname(dd),"var","sst")+"_em"/)$ = set_varAtts(arr_sst_EM,arr_sst_EM@long_name+" Ensemble Mean","","")
        z->$(/str_sub_str(variname(dd),"var","sst")+"_em_diffobs"/)$ = set_varAtts(sst_diff,sst_diff@long_name+" Ensemble Mean difference from "+names(0),"","")           
        z->$(/str_sub_str(variname(dd),"var","sst")+"_pval"/)$ = set_varAtts(p_val2,arr_sst_EM@long_name+" p-val statistic","%","")   
        delete([/arr_store,arr_store_sst,obs0_rg,obs_diff,arr_EM,z,arr_sst_EM,sst_diff,sst0_rg,p_val,p_val2/])
        cntr_EM = cntr_EM+4
     end do
     panres@txString = "AMOC SST/TAS Regressions (Annual)"
     gsn_panel2(wks,plot_indmem,(/nrow,ncol/),panres)
     
     panres@txString = "AMOC SST/TAS Regressions Differences (Annual)"
     gsn_panel2(wks,plot_indmem_diff,(/nrow,ncol/),panres)

     if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
        panres2@txString = "Ensemble Summary: AMOC SST/TAS Regressions (Annual)"
        panres2@gsnPanelXWhiteSpacePercent = 3.0
        gsn_panel2(wks,plot_summary,(/nEM,4/),panres2)
        delete(panres2@gsnPanelXWhiteSpacePercent)
     end if
     delete(wks)

     if (wks_type.eq."png") then
        system("mv "+OUTDIR+"amoc_spareg.000001.png "+OUTDIR+"amoc.tassstreg.ann.indmem.png")
        system("mv "+OUTDIR+"amoc_spareg.000002.png "+OUTDIR+"amoc.tassstreg.ann.indmemdiff.png")
        if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
           system("mv "+OUTDIR+"amoc_spareg.000003.png "+OUTDIR+"amoc.tassstreg.ann.summary.png")
           if (PNG_SCALE_SUMMARY.ne.100) then
              system(IM_COMMAND+" "+OUTDIR+"amoc.tassstreg.ann.summary.png -resize "+PNG_SCALE_SUMMARY+"% "+OUTDIR+"amoc.tassstreg.ann.summary.png")
           end if
        end if
     else
        system("psplit "+OUTDIR+"amoc_spareg.ps "+OUTDIR+"amoc_spareg")
        system("mv "+OUTDIR+"amoc_spareg0001.ps "+OUTDIR+"amoc.tassstreg.ann.indmem.ps")
        system("mv "+OUTDIR+"amoc_spareg0002.ps "+OUTDIR+"amoc.tassstreg.ann.indmemdiff.ps")
        if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
           system("mv "+OUTDIR+"amoc_spareg0003.ps "+OUTDIR+"amoc.tassstreg.ann.summary.ps")
           system("rm "+OUTDIR+"amoc_spareg.ps")
        end if
     end if
  end do
;---AMOC ZOS Regressions plotting section---------------------------------------------------------------------------
  res2 = res    ; regression differences
  if (COLORMAP.eq.0) then
     res@cnFillPalette = "ncl_default"
  end if
  if (COLORMAP.eq.1) then
     res@cnFillPalette = "BlueDarkRed18"
  end if 
  res@cnLevels := ispan(-7,7,1)  
  res@cnLevels := fspan(-3.5,3.5,15)  
  res@lbLabelStride = 1
  res2@cnLevels := res@cnLevels
  res2@cnFillPalette := res@cnFillPalette
  res@trGridType = "TriangularMesh"
  res2@trGridType = "TriangularMesh"

  variname = (/"amoc_var_regression_ann"/)
  variname_obs = (/"amoc_var_regression_ann"/)

  do dd = 0,dimsizes(variname)-1
     wks = gsn_open_wks(wks_type,getenv("OUTDIR")+"amoc_spareg")

     plot_indmem      := new(nsim,"graphic")
     plot_indmem_diff := new(nsim,"graphic")
     if (nEM.ge.1) then
        plot_summary     := new((nEM*4),"graphic")
     end if
     numobs = num(EM_num.eq.0) 
     if (numobs.eq.0) then
        fnt = getenv("OUTDIR")+"obs.cvdp_data.amoc.zos."+syear_zos(0)+"-"+eyear_zos(0)+".nc"      
        fnt2 = getenv("OUTDIR")+"obs.cvdp_data."+syear_zos(0)+"-"+eyear_zos(0)+".nc"
        obs0 := read_cvdp_le_data(fnt,fnt2,str_sub_str(variname_obs(dd),"var","zos"))
        cntr = 0
     else
        fnt = getenv("OUTDIR")+modname_zos(0)+".cvdp_data.amoc.zos."+syear_zos(0)+"-"+eyear_zos(0)+".nc"      
        fnt2 = getenv("OUTDIR")+modname_zos(0)+".cvdp_data."+syear_zos(0)+"-"+eyear_zos(0)+".nc"
        obs0 := read_cvdp_le_data(fnt,fnt2,str_sub_str(variname_obs(dd),"var","zos"))
        cntr = 1
     end if
     if (isatt(obs0,"is_all_missing")) then   ; done to assign proper dimension names to missing observational dataset
        obs0!0 = "nlat"
        obs0!1 = "nlon"
     end if

     res@gsnCenterStringFontColor = "black"
     res2@gsnCenterStringFontColor = "black"
     res@lbLabelBarOn = False
     res2@lbLabelBarOn = False
     tres@lbLabelBarOn = False
     res@gsnLeftString = syear_zos(0)+"-"+eyear_zos(0) 
     res@gsnRightString = ""
     res@gsnCenterString = names_ts(0)+" / "+names_zos(0)      
     plot_indmem(0) = gsn_csm_contour_map(wks,obs0,res)

;----Identify type of grid the first observational dataset is on and set appropriate ESMF options
     InterpMethod = "bilinear"
     Opt                := True
     Opt@SrcTitle       = names(0)+" grid"   ; optional
     Opt@WgtFileName    = modname(0)+"_amoc.WgtFile_"+InterpMethod+".nc"
     Opt@SrcFileName    = getenv("OUTDIR")+"/obs0.amoc.SCRIP_grid_description.nc"         ; Name of source and
     Opt@SrcRegional    = True  ; will verify this below

     if (isatt(obs0,"coordinates")) then   ; curvilinear 
        Opt@SrcGridType    = "curvilinear"
        if (max(obs0@lat2d)-min(obs0@lat2d).gt.100) then
           Opt@SrcRegional    = False
        end if
     else
        Opt@SrcGridType    = "rectilinear"
        if ((max(obs0&nlat)-min(obs0&nlat)).gt.100) then
           Opt@SrcRegional    = False
        end if
     end if
     Opt@ForceOverwrite = True
     Opt@InterpMethod   = InterpMethod
     Opt@RemoveSrcFile  = True                  ; remove SCRIP grid destination files
     Opt@RemoveDstFile  = True 
     Opt@NoPETLog       = True

     cntr_EM = 0
     if (numobs.ge.2) then     ; plot obs #2-
        do ff = 1,numobs-1
           fnt = getenv("OUTDIR")+modname_zos(cntr)+".cvdp_data.amoc.zos."+syear_zos(cntr)+"-"+eyear_zos(cntr)+".nc"
           fnt2 = getenv("OUTDIR")+modname_zos(cntr)+".cvdp_data."+syear_zos(cntr)+"-"+eyear_zos(cntr)+".nc"
           arr := read_cvdp_le_data(fnt,fnt2,str_sub_str(variname_obs(dd),"var","zos"))
           if (isatt(arr,"is_all_missing")) then 
              cntr = cntr+1
              continue
           end if

           if (isatt(arr,"coordinates")) then   ; curvilinear 
              Opt@DstGridType    = "curvilinear"
              Opt@DstGridLat     := arr@lat2d
              Opt@DstGridLon     := arr@lon2d
              if (max(arr@lat2d)-min(arr@lat2d).gt.100) then
                 Opt@DstRegional    = False
              end if
           else
              Opt@DstGridType    = "rectilinear"
              if ((max(arr&nlat)-min(arr&nlat)).gt.100) then
                 Opt@DstRegional    = False
              end if
              Opt@DstGridLat     := arr&nlat
              Opt@DstGridLon     := arr&nlon
           end if

           Opt@DstFileName    = getenv("OUTDIR")+Opt@DstGridType+".amoc.SCRIP_grid_description.nc" 
           if (any(ismissing(obs0))) then
              Opt@DstMask2D  := where(ismissing(arr),0,1)  ; set SrcMask2D option to indicate the missing values 
           end if

           res@gsnLeftString = syear_zos(cntr)+"-"+eyear_zos(cntr)
           res@gsnRightString = ""

           res@gsnCenterString = names_zos(cntr)
           res2@gsnLeftString = "" 
           res2@gsnRightString = ""
           res2@gsnCenterString = names_zos(cntr)+" -~C~"+names_ts(0)+"/"+names_zos(0)
           obs0_rg = ESMF_regrid(obs0, Opt)
           obs_diff = arr
           obs_diff = obs_diff@_FillValue
           dim0 = dimsizes(arr)
           dim1 = dimsizes(obs0_rg)
           if (dim0(0).eq.dim1(0).and.dim0(1).eq.dim1(1)) then
              obs_diff = (/ arr - obs0_rg /)
           end if

           res@gsnRightString = ""   ;pattern_correlation(obs0_rg,arr)
           plot_indmem(cntr) = gsn_csm_contour_map(wks,arr,res)
           plot_indmem_diff(cntr) = gsn_csm_contour_map(wks,obs_diff,res2)   
           delete([/arr,obs_diff,obs0_rg/])
           cntr = cntr+1
        end do
     end if
     if (isfilepresent2(Opt@WgtFileName)) then
        system("rm "+Opt@WgtFileName)
     end if
     do gg = nEMm,nEM   ; operate on each ensemble mean (or individual member)
        if (gg.eq.0) then
           continue
        end if
        lbFlag = summary_lb_flag(paths,EM_num,gg,nEM)  ; lbFlag set to True if summary labelbars should be drawn  
        nens = num(EM_num.eq.gg) ; determines how many model simulations in each ensemble
        cntr_ens := ind(EM_num.eq.gg)   ; cntr_ens(hh) are the indices where each ensemble member of an ensemble reside 
        do hh = 0,nens-1
           modname_mod = modname_zos(cntr_ens(hh))
           syear_mod = syear_zos(cntr_ens(hh))
           eyear_mod = eyear_zos(cntr_ens(hh))
           names_mod = names_zos(cntr_ens(hh))
           names_EM_mod = names_EM(cntr_ens(hh))
   
           fnt = getenv("OUTDIR")+modname_mod+".cvdp_data.amoc.zos."+syear_mod+"-"+eyear_mod+".nc"
           fnt2 = getenv("OUTDIR")+modname_mod+".cvdp_data."+syear_mod+"-"+eyear_mod+".nc"
           arr := read_cvdp_le_data(fnt,fnt2,str_sub_str(variname(dd),"var","zos"))
           if (isatt(arr,"is_all_missing")) then 
              cntr = cntr+1
              continue
           end if

           if (isatt(arr,"coordinates")) then   ; curvilinear 
              Opt@DstGridType    = "curvilinear"
              Opt@DstGridLat     := arr@lat2d
              Opt@DstGridLon     := arr@lon2d
              if (max(arr@lat2d)-min(arr@lat2d).gt.100) then
                 Opt@DstRegional    = False
              end if
           else
              Opt@DstGridType    = "rectilinear"
              Opt@DstRegional    = False
              dimNames = getvardimnames(arr)
              Opt@DstGridLat     := arr&nlat
              Opt@DstGridLon     := arr&nlon
              delete(dimNames)
           end if
           Opt@DstFileName    = getenv("OUTDIR")+Opt@DstGridType+".amoc.SCRIP_grid_description.nc" 
           if (any(ismissing(obs0))) then
              Opt@DstMask2D  := where(ismissing(arr),0,1)  ; set SrcMask2D option to indicate the missing values 
           end if

           if (.not.isvar("arr_store")) then  ; create an array to house all members, to be used to calculate EM
              dimZ := dimsizes(arr)
              arr_store = new((/nens,dimZ(0),dimZ(1)/),typeof(arr))
              arr_store!0 = "ensmem"
              arr_store!1 = "nlat"
              arr_store!2 = "nlon"
              if (Opt@DstGridType.eq."rectilinear") then
                 arr_store&nlat = arr&nlat
                 arr_store&nlon = arr&nlon
              end if
              arr_store@nens = 0
              copy_VarAtts(arr,arr_store)

              syear_em0 = syear_mod
              eyear_em0 = eyear_mod
              showyr = True
           end if
           if (showyr) then
              if (syear_em0.ne.syear_mod.or.eyear_em0.ne.eyear_mod.and.showyr) then
                 showyr = False
              end if
           end if
           if (gg.ge.1) then
              res@gsnCenterStringFontColor = csubtitle_color(gg-1)
              res2@gsnCenterStringFontColor = csubtitle_color(gg-1)
           end if
           if (.not.isatt(arr,"is_all_missing")) then
              arr_store(hh,:,:) = (/ arr /)
              arr_store@nens = arr_store@nens +1
           end if
           panres@lbTitleString = arr@units

           res2@gsnLeftString = "" 
           res2@gsnRightString = ""
           res2@gsnCenterString = names_mod+" -~C~"+names_zos(0) 
           if (.not.isvar("obs0_rg")) then  
              obs0_rg = ESMF_regrid(obs0, Opt)
           end if
           obs_diff = arr
           obs_diff = obs_diff@_FillValue
           dim0 = dimsizes(arr)
           dim1 = dimsizes(obs0_rg)
           if (dim0(0).eq.dim1(0).and.dim0(1).eq.dim1(1)) then
              obs_diff = (/ arr - obs0_rg /)
           end if

           res@gsnLeftString   = syear_mod+"-"+eyear_mod
           res@gsnRightString  = "" ;pattern_correlation(obs0_rg,arr)
           res@gsnCenterString = names_mod
           plot_indmem(cntr) = gsn_csm_contour_map(wks,arr,res)

           plot_indmem_diff(cntr) = gsn_csm_contour_map(wks,obs_diff,res2)
           delete([/arr,obs_diff/])
           cntr = cntr+1
        end do
        if (nEM.eq.0) then   ; in individual member mode (runstyle=1)
           if (isvar("arr_store")) then
              delete(arr_store)
           end if
           if (isvar("obs0_rg")) then
              delete(obs0_rg)
           end if
           continue
        end if
        if (.not.isvar("arr_store")) then
           cntr_EM = cntr_EM+4
           continue
        end if
   
        if (lbFlag) then
           res@lbLabelBarOn = True
           res2@lbLabelBarOn = True
           tres@lbLabelBarOn = True
        end if
        arr_EM := dim_avg_n_Wrap(arr_store,0)
   
        res@gsnCenterStringFontColor = "black"
        res2@gsnCenterStringFontColor = "black"

        res@lbTitleString = arr_EM@units   
        res@gsnLeftString = syear_zos(0)+"-"+eyear_zos(0) 
        res@gsnRightString = ""
        res@gsnCenterString = names_zos(0)   
        plot_summary(cntr_EM+1) = gsn_csm_contour_map(wks,obs0,res)
        if (showyr) then
           res@gsnLeftString = syear_em0+"-"+eyear_em0 
        else
           res@gsnLeftString = (eyear_em0-syear_em0+1)+"yrs" 
        end if
        delete([/syear_em0,eyear_em0,showyr/])
   
        res@gsnCenterStringFontColor = csubtitle_color(gg-1)
        res@gsnRightString = ""   ;pattern_correlation(obs0_rg,arr_EM)
        res@gsnCenterString = names_EM_mod +" ("+arr_store@nens+" Members)"                                
        plot_summary(cntr_EM) = gsn_csm_contour_map(wks,arr_EM,res)
        obs_diff = arr_EM
        obs_diff = obs_diff@_FillValue
        dim0 = dimsizes(arr_EM)
        dim1 = dimsizes(obs0_rg)
        if (dim0(0).eq.dim1(0).and.dim0(1).eq.dim1(1)) then
           obs_diff = (/ arr_EM - obs0_rg /)
        end if
        res2@lbTitleString = arr_EM@units
        res2@gsnLeftString = ""
        res2@gsnCenterString = names_EM_mod+" - "+names_zos(0)   
        res2@gsnRightString = ""
        plot_summary(cntr_EM+2) = gsn_csm_contour_map(wks,obs_diff,res2)
   
        tres@lbTitleString = "%"
        p_val = calculate_pval(obs0_rg,arr_store)
        tres@gsnRightStringParallelPosF = 1.025
        tres@gsnLeftString = "ZOS" 
        tres@gsnCenterString = "Rank of "+names_zos(0)+" within Ensemble"   
        tres@gsnRightStringParallelPosF = .985
        tres@gsnRightString = "" ;calculate_area_in_range(p_val,10,90)+"%"
        plot_summary(cntr_EM+3) = gsn_csm_contour_map(wks,p_val,tres)
   
        fno = getenv("OUTDIR")+str_sub_str(names_EM_mod," ","_")+"_EM.cvdp_data.amoc.zos."+syear_mod+"-"+eyear_mod+".nc"
        if (isfilepresent2(fno)) then
           z = addfile(fno,"w")
        else
           z = addfile(fno,"c")
           set_global_ncfile_attributes(z,names_EM_mod,syear_mod,eyear_mod,getenv("VERSION"))
        end if
        if (isatt(arr_EM,"lat2d")) then
           LAT2D = arr_EM@lat2d
           LON2D = arr_EM@lon2d
           delete([/arr_EM@lat2d,arr_EM@lon2d,obs_diff@lat2d,obs_diff@lon2d,p_val@lat2d,p_val@lon2d/])
           copy_VarCoords(arr_EM,LAT2D)
           copy_VarCoords(arr_EM,LON2D)
           z->$(/"lat2d_ocean"/)$ = set_varAtts(LAT2D,"ocean grid 2-dimensional latitudes","","")
           z->$(/"lon2d_ocean"/)$ = set_varAtts(LON2D,"ocean grid 2-dimensional longitudes","","")
           delete([/LAT2D,LON2D/])
           arr_EM@coordinates ="lat2d_ocean lon2d_ocean"
           obs_diff@coordinates = "lat2d_ocean lon2d_ocean"
           p_val@coordinates = "lat2d_ocean lon2d_ocean"
        end if 
        z->$(/str_sub_str(variname(dd),"var","zos")+"_em"/)$ = set_varAtts(arr_EM,arr_EM@long_name+" Ensemble Mean","","")
        z->$(/str_sub_str(variname(dd),"var","zos")+"_em_diffobs"/)$ = set_varAtts(obs_diff,obs_diff@long_name+" Ensemble Mean difference from "+names_zos(0),"","")           
        z->$(/str_sub_str(variname(dd),"var","zos")+"_pval"/)$ = set_varAtts(p_val,arr_EM@long_name+" p-val statistic","%","")   
        delete([/arr_store,obs0_rg,obs_diff,arr_EM,z,p_val/])
        cntr_EM = cntr_EM+4
     end do
     if (isfilepresent2(Opt@WgtFileName)) then
        system("rm "+Opt@WgtFileName)
     end if

     panres@txString = "AMOC ZOS Regressions (Annual)"
     gsn_panel2(wks,plot_indmem,(/nrow,ncol/),panres)
     
     panres@txString = "AMOC ZOS Regressions Differences (Annual)"
     gsn_panel2(wks,plot_indmem_diff,(/nrow,ncol/),panres)

     if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
        panres2@txString = "Ensemble Summary: AMOC ZOS Regressions (Annual)"
        panres2@gsnPanelXWhiteSpacePercent = 3.0
        gsn_panel2(wks,plot_summary,(/nEM,4/),panres2)
        delete(panres2@gsnPanelXWhiteSpacePercent)
     end if
     delete(wks)

     if (wks_type.eq."png") then
        system("mv "+OUTDIR+"amoc_spareg.000001.png "+OUTDIR+"amoc.zosreg.ann.indmem.png")
        system("mv "+OUTDIR+"amoc_spareg.000002.png "+OUTDIR+"amoc.zosreg.ann.indmemdiff.png")
        if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
           system("mv "+OUTDIR+"amoc_spareg.000003.png "+OUTDIR+"amoc.zosreg.ann.summary.png")
           if (PNG_SCALE_SUMMARY.ne.100) then
              system(IM_COMMAND+" "+OUTDIR+"amoc.zosreg.ann.summary.png -resize "+PNG_SCALE_SUMMARY+"% "+OUTDIR+"amoc.zosreg.ann.summary.png")
           end if
        end if
     else
        system("psplit "+OUTDIR+"amoc_spareg.ps "+OUTDIR+"amoc_spareg")
        system("mv "+OUTDIR+"amoc_spareg0001.ps "+OUTDIR+"amoc.zosreg.ann.indmem.ps")
        system("mv "+OUTDIR+"amoc_spareg0002.ps "+OUTDIR+"amoc.zosreg.ann.indmemdiff.ps")
        if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
           system("mv "+OUTDIR+"amoc_spareg0003.ps "+OUTDIR+"amoc.zosreg.ann.summary.ps")
        end if
        system("rm "+OUTDIR+"amoc_spareg.ps")
     end if
  end do
  delete([/res,res2,res3,res4,tres,tres2/])
;---AMOC Mean, Std dev and pattern plotting section---------------------------------------------------------------------------
  mocres                      = True                 ; AMOC mean resources
  mocres@gsnDraw		   = False		
  mocres@gsnFrame		   = False		
  mocres@cnFillOn             = True                 ; turn on color fill
  mocres@cnMissingValFillColor = "gray50"
  mocres@cnMissingValFillPattern = 0
  mocres@cnLinesOn            = True         
  mocres@cnLineLabelsOn 	   = False

  mocres@cnInfoLabelOn       = False       ; Turn off informational label
  mocres@cnLevelSelectionMode = "ExplicitLevels"	; manually set the contour levels
  mocres@tmXBLabelFontHeightF = 0.014
  mocres@tmYLLabelFontHeightF = 0.014
  mocres@gsnLeftStringFontHeightF   = 0.017
  mocres@gsnCenterStringFontHeightF = 0.020
  mocres@gsnRightStringFontHeightF  = 0.0155
  mocres@tiYAxisFontHeightF = mocres@tmXBLabelFontHeightF 
  mocres@gsnLeftStringOrthogonalPosF = -0.96
  mocres@gsnLeftStringParallelPosF = 0.80
     
  mocres@tmXBLabelsOn    = True
  mocres@tmXTLabelsOn    = False
  mocres@tmXTOn          = False
  mocres@tmYRLabelsOn    = False
  mocres@tmYROn          = False
  mocres@vpWidthF        = 0.6
  mocres@vpHeightF       = 0.4

  mocres@trYReverse               = True       ; reverses y-axis
  mocres@gsnYAxisIrregular2Linear = True
  mocres@gsnXAxisIrregular2Linear = True
  mocres@tiYAxisString= "depth (km)"
  mocres@tiXAxisString= ""
  mocres@gsnCenterString = ""
  mocres@trXMinF = 0.
  mocres@trXMaxF = 90.
  mocres@tmXBMode = "Explicit"
  mocres@tmXBValues = (/0.,30.,60.,90./)
  mocres@tmXBLabels = (/"0~S~o~N~N","30~S~o~N~N","60~S~o~N~N","90~S~o~N~N"/)

  mocres@lbLabelBarOn    = False
  mocres@pmLabelBarWidthF = 0.55
  mocres@pmLabelBarHeightF = 0.075
  mocres@lbBoxLineColor = "gray70"
  mocres@lbLabelFontHeightF = 0.02
  mocres@lbLabelStride = 1
  mocres@lbTitleOn = True
  mocres@lbTitleFontHeightF = mocres@lbLabelFontHeightF
  mocres@lbTitlePosition = "Bottom"
  mocres@cnNoDataLabelOn = False

  tres := mocres    ; p-value plot resource list
  copy_VarAtts(retrieve_summary_res(),tres)
  tres@cnLinesOn  = False
  tres@cnMissingValFillColor = "gray50"

  mocres_d = mocres   ; mean difference resource list
  mocres2 = mocres    ; standard deviation resource list
  mocres2_d = mocres  ; standard deviation differences resource list
  mocres3 = mocres    ; pattern resource list
  mocres3_d = mocres  ; pattern resource differences list

  mocres@cnMonoLineThickness = False
  mocres@cnMonoLineDashPattern = False

  mocres@cnLineThicknesses  = (/1,1,2,1,1,1,1,2,1,1,1,1,2,1,1,1,1/)
  mocres@cnLineDashPatterns = (/1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0/)
  mocres@cnLevels           = ispan(-4,28,2)
  mocres_d@cnLevels = ispan(-8,8,1)

  mocres2@cnLevels := (/.3,.5,1.0,1.5,2.0,2.5,3.0,4.0/) 
  mocres2_d@cnLevels = fspan(-1,1,11)

  if (COLORMAP.eq.0) then   ; use ncl_default colormap (=default) unless otherwise prescribed
     cmap := read_colormap_file("precip3_16lev")
     mocres2@cnFillPalette = cmap((/0,2,4,6,8,10,12,14,16/),:)   

     mocres3@cnLevels = fspan(-2,2,41)
     mocres3_d@cnLevels =  fspan(-2,2,41)  
  end if
  if (COLORMAP.eq.1) then
     mocres@cnFillPalette = "BlueDarkRed18"
     mocres_d@cnFillPalette = "BlueDarkRed18"

     cmap := read_colormap_file("cb_rainbow")
     mocres2@cnFillPalette = cmap((/21,33,45,61,77,93,109,122,153/),:)
     mocres2_d@cnFillPalette = "cb_rainbow"
     mocres3@cnFillPalette = "BlueDarkRed18"
     mocres3_d@cnFillPalette = "BlueDarkRed18"
     mocres3@cnLevels = fspan(-1.6,1.6,17)
     mocres3_d@cnLevels =  mocres3@cnLevels
  end if     

  variname := (/"amoc_mean_ann","amoc_stddev_ann","amoc_pattern_ann"/)
  variname_obs := (/"amoc_mean_ann","amoc_stddev_ann","amoc_pattern_ann"/)
  variname_title := (/"AMOC Means","AMOC Standard Deviations","AMOC EOF1"/)
  variname_title = variname_title
  variname_title_seas = (/"Annual","Annual","Annual"/)
  csubtitle_color = set_subtitle_colors(max(EM_num))
  nEM = max(EM_num)
  do dd = 0,dimsizes(variname)-1
     wks = gsn_open_wks(wks_type,getenv("OUTDIR")+"amoc")
     plot_indmem      = new(nsim,"graphic")
     plot_indmem_diff = new(nsim,"graphic")
     if (nEM.ge.1) then
        plot_summary     = new((nEM*4),"graphic")
        plot_summary_anno = new(nEM*4,"graphic")
     end if
     if (dd.eq.0) then
        qres   := mocres
        qres_d := mocres_d
     end if
     if (dd.eq.1) then
        qres   := mocres2
        qres_d := mocres2_d
     end if
     if (dd.eq.2) then
        qres   := mocres3
        qres_d := mocres3_d
     end if

     numobs = num(EM_num.eq.0) 
     if (numobs.eq.0) then
        fnt = getenv("OUTDIR")+"obs.cvdp_data.amoc."+syear(0)+"-"+eyear(0)+".nc"
        fnt2 = getenv("OUTDIR")+"obs.cvdp_data."+syear(0)+"-"+eyear(0)+".nc"
        cntr = 0
     else
        fnt = getenv("OUTDIR")+modname(0)+".cvdp_data.amoc."+syear(0)+"-"+eyear(0)+".nc"
        fnt2 = getenv("OUTDIR")+modname(0)+".cvdp_data."+syear(0)+"-"+eyear(0)+".nc"
        cntr = 1
     end if
     obs0 := read_cvdp_le_data(fnt,fnt2,variname_obs(dd))
     qres@gsnCenterStringFontColor = "black"
     qres_d@gsnCenterStringFontColor = "black"
     qres@gsnLeftString = syear(0)+"-"+eyear(0) 
     qres@gsnRightString = ""  
     qres@gsnCenterString = names(0)    
     plot_indmem(0) = gsn_csm_contour(wks,obs0,qres)

     cntr_EM = 0
     if (numobs.ge.2) then     ; plot obs #2-
        do ff = 1,numobs-1
           fnt = getenv("OUTDIR")+modname(cntr)+".cvdp_data.amoc."+syear(cntr)+"-"+eyear(cntr)+".nc"
           fnt2 = getenv("OUTDIR")+modname(cntr)+".cvdp_data."+syear(cntr)+"-"+eyear(cntr)+".nc"
           arr := read_cvdp_le_data(fnt,fnt2,variname_obs(dd))
           if (isatt(arr,"is_all_missing")) then 
              cntr = cntr+1
              continue
           end if
           qres@gsnLeftString = syear(cntr)+"-"+eyear(cntr) 
           qres@gsnRightString = ""  
           qres@gsnCenterString = names(cntr)   
           plot_indmem(cntr) = gsn_csm_contour(wks,arr,qres)
           qres_d@gsnLeftString = ""   
           qres_d@gsnRightString = ""  
           qres_d@gsnCenterString = names(cntr)+"-"+names(0)
           obs0_rg = linint2_Wrap(obs0&lat_amoc,obs0&lev,obs0,True,arr&lat_amoc,arr&lev,0)
           obs_diff = arr
           obs_diff = (/ arr - obs0_rg /)
           plot_indmem_diff(cntr) = gsn_csm_contour(wks,obs_diff,qres_d)     
           delete([/arr,obs_diff,obs0_rg/])
           cntr = cntr+1
        end do
     end if

     do gg = nEMm,nEM   ; operate on each ensemble mean (or individual member)
        if (gg.eq.0) then
           continue
        end if
        lbFlag = summary_lb_flag(paths,EM_num,gg,nEM)  ; lbFlag set to True if summary labelbars should be drawn
        nens = num(EM_num.eq.gg) ; determines how many model simulations in each ensemble
        cntr_ens := ind(EM_num.eq.gg)   ; cntr_ens(hh) are the indices where each ensemble member of an ensemble reside 
        do hh = 0,nens-1
           modname_mod = modname(cntr_ens(hh))
           syear_mod = syear(cntr_ens(hh))
           eyear_mod = eyear(cntr_ens(hh))
           names_mod = names(cntr_ens(hh))
           names_EM_mod = names_EM(cntr_ens(hh))

           fnt = getenv("OUTDIR")+modname_mod+".cvdp_data.amoc."+syear_mod+"-"+eyear_mod+".nc"
           fnt2 = getenv("OUTDIR")+modname_mod+".cvdp_data."+syear_mod+"-"+eyear_mod+".nc"
           arr := read_cvdp_le_data(fnt,fnt2,variname(dd))
           if (isatt(arr,"is_all_missing")) then 
              cntr = cntr+1
              continue
           end if
           if (.not.isvar("arr_store")) then  ; create an array to house all members, to be used to calculate EM
              arr_store = new((/nens,dimsizes(arr&lev),dimsizes(arr&lat_amoc)/),typeof(arr))
              arr_store!0 = "ensmem"
              arr_store!1 = "lev"
              arr_store&lev = arr&lev
              arr_store!2 = "lat_amoc"
              arr_store&lat_amoc = arr&lat_amoc
              arr_store@nens = 0
              copy_VarAtts(arr,arr_store)

              syear_em0 = syear_mod
              eyear_em0 = eyear_mod
              showyr = True
           end if
           if (syear_em0.ne.syear_mod.or.eyear_em0.ne.eyear_mod.and.showyr) then
              showyr = False
           else
              showyr = True
           end if
           if (gg.ge.1) then
              qres@gsnCenterStringFontColor = csubtitle_color(gg-1)
              qres_d@gsnCenterStringFontColor = csubtitle_color(gg-1)
           end if
           arr_store(hh,:,:) = (/ arr /)
           arr_store@nens = arr_store@nens +1
           panres@lbTitleString = arr@units

           qres@gsnLeftString = syear_mod+"-"+eyear_mod
           qres@gsnRightString = "" 
           qres@gsnCenterString = names_mod
           plot_indmem(cntr) = gsn_csm_contour(wks,arr,qres)
           qres_d@gsnLeftString = "" 
           qres_d@gsnRightString = ""  
           qres_d@gsnCenterString = names_mod+"-"+names(0)  
           if (.not.isvar("obs0_rg")) then  
              if (isatt(obs0,"is_all_missing")) then
                 obs0_rg = arr
                 obs0_rg = obs0_rg@_FillValue
              else
                 obs0_rg = linint2_Wrap(obs0&lat_amoc,obs0&lev,obs0,True,arr&lat_amoc,arr&lev,0)
              end if
           end if
           obs_diff = arr
           obs_diff = (/ arr - obs0_rg /)
           plot_indmem_diff(cntr) = gsn_csm_contour(wks,obs_diff,qres_d)
           delete([/arr,obs_diff/])
           cntr = cntr+1
        end do
        if (nEM.eq.0) then   ; in individual member mode (runstyle=1)
           if (isvar("arr_store")) then
              delete(arr_store)
           end if
           if (isvar("obs0_rg")) then
              delete(obs0_rg)
           end if
           continue
        end if
        if (.not.isvar("arr_store")) then
           cntr_EM = cntr_EM+4
           continue
        end if
        if (lbFlag) then
           qres@lbLabelBarOn = True
           qres_d@lbLabelBarOn = True
           tres@lbLabelBarOn = True
        else
           qres@lbLabelBarOn = False
           qres_d@lbLabelBarOn = False
           tres@lbLabelBarOn = False     
        end if
        arr_EM := dim_avg_n_Wrap(arr_store,0)

        qres@gsnCenterStringFontColor = "black"
        qres_d@gsnCenterStringFontColor = "black"
        qres@lbTitleString = arr_EM@units   
        qres_d@lbTitleString = qres@lbTitleString  

        qres@gsnLeftString = syear(0)+"-"+eyear(0) 
        qres@gsnRightString = ""  
        qres@gsnCenterString = names(0)   
        plot_summary(cntr_EM+1) = gsn_csm_contour(wks,obs0,qres)

        if (showyr) then
           qres@gsnLeftString = syear_em0+"-"+eyear_em0 
        else
           qres@gsnLeftString = (eyear_em0-syear_em0+1)+"yrs" 
        end if
        delete([/syear_em0,eyear_em0,showyr/])

        qres@gsnRightString = "" 
        qres@gsnCenterString = names_EM_mod +" ("+arr_store@nens+" Members)"                   
        plot_summary(cntr_EM) = gsn_csm_contour(wks,arr_EM,qres)
        obs_diff = arr_EM
        obs_diff = (/ arr_EM - obs0_rg /)
        qres_d@gsnLeftString = ""
        qres_d@gsnCenterString = names_EM_mod+" - "+names(0)
        qres_d@gsnRightString = ""  
        plot_summary(cntr_EM+2) = gsn_csm_contour(wks,obs_diff,qres_d)

        p_val = calculate_pval(obs0_rg,arr_store)
        tres@gsnRightString = ""  
        tres@gsnCenterString = "Rank of "+names(0)+" within Ensemble" 
        plot_summary(cntr_EM+3) = gsn_csm_contour(wks,p_val,tres)

        if (isfilepresent2(getenv("OUTDIR")+str_sub_str(names_EM_mod," ","_")+"_EM.cvdp_data.amoc."+syear_mod+"-"+eyear_mod+".nc")) then
           z = addfile(getenv("OUTDIR")+str_sub_str(names_EM_mod," ","_")+"_EM.cvdp_data.amoc."+syear_mod+"-"+eyear_mod+".nc","w")
        else
           z = addfile(getenv("OUTDIR")+str_sub_str(names_EM_mod," ","_")+"_EM.cvdp_data.amoc."+syear_mod+"-"+eyear_mod+".nc","c")
           set_global_ncfile_attributes(z,names_EM_mod,syear_mod,eyear_mod,getenv("VERSION"))
        end if
        z->$(/variname(dd)+"_em"/)$ = set_varAtts(arr_EM,arr_EM@long_name+" Ensemble Mean","","")
        z->$(/variname(dd)+"_em_diffobs"/)$ = set_varAtts(obs_diff,obs_diff@long_name+" Ensemble Mean difference from "+names(0),"","")           
        z->$(/variname(dd)+"_pval"/)$ = set_varAtts(p_val,arr_EM@long_name+" p-val statistic","%","")   
        delete([/p_val,arr_store,obs0_rg,obs_diff,arr_EM,z/])
        cntr_EM = cntr_EM+4
     end do
     panres@txString = variname_title(dd)+" ("+variname_title_seas(dd)+")"
     gsn_panel2(wks,plot_indmem,(/nrow,ncol/),panres)

     panres@txString = variname_title(dd)+" Differences ("+variname_title_seas(dd)+")"
     gsn_panel2(wks,plot_indmem_diff,(/nrow,ncol/),panres)

     if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
        panres2@txString = "Ensemble Summary: "+variname_title(dd)+" ("+variname_title_seas(dd)+")"
        gsn_panel2(wks,plot_summary,(/nEM,4/),panres2)
     end if
     delete(wks)

     if (wks_type.eq."png") then
        system("mv "+OUTDIR+"amoc.000001.png "+OUTDIR+str_sub_str(variname(dd),"_",".")+".indmem.png")
        system("mv "+OUTDIR+"amoc.000002.png "+OUTDIR+str_sub_str(variname(dd),"_",".")+".indmemdiff.png")
        if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
           system("mv "+OUTDIR+"amoc.000003.png "+OUTDIR+str_sub_str(variname(dd),"_",".")+".summary.png")
           if (PNG_SCALE_SUMMARY.ne.100) then
              system(IM_COMMAND+" "+OUTDIR+str_sub_str(variname(dd),"_",".")+".summary.png -resize "+PNG_SCALE_SUMMARY+"% "+OUTDIR+str_sub_str(variname(dd),"_",".")+".summary.png")
           end if
        end if
     else
        system("psplit "+OUTDIR+"amoc.ps "+OUTDIR+"amoc")
        system("mv "+OUTDIR+"amoc0001.ps "+OUTDIR+str_sub_str(variname(dd),"_",".")+".indmem.ps")
        system("mv "+OUTDIR+"amoc0002.ps "+OUTDIR+str_sub_str(variname(dd),"_",".")+".indmemdiff.ps")
        if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
           system("mv "+OUTDIR+"amoc0003.ps "+OUTDIR+str_sub_str(variname(dd),"_",".")+".summary.ps")
        end if
        system("rm "+OUTDIR+"amoc.ps")
     end if
  end do
  print("Finished: amoc.ncl")
end

