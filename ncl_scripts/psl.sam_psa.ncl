; Calculates SAM, PSA1 and PSA2 (patterns and PC timeseries), as well as 
; regressions of those PC timeseries onto the land-masked TS field.
;
; Variables used: PSL and TS
; 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$CVDP_SCRIPTS/functions.ncl"

begin
  print("Starting: psl.sam_psa.ncl")
  
  SCALE_TIMESERIES = getenv("SCALE_TIMESERIES")  
  OUTPUT_DATA      = getenv("OUTPUT_DATA")  
  PNG_SCALE        = tofloat(getenv("PNG_SCALE"))
  OPT_CLIMO        = getenv("OPT_CLIMO")
  CLIMO_SYEAR      = toint(getenv("CLIMO_SYEAR"))
  CLIMO_EYEAR      = toint(getenv("CLIMO_EYEAR"))
  OUTPUT_TYPE      = getenv("OUTPUT_TYPE") 
  COMPUTE_MODES_MON = getenv("COMPUTE_MODES_MON")
  COLORMAP         = getenv("COLORMAP")  
  
  nsim = numAsciiRow("namelist_byvar/namelist_psl")
  na = asciiread("namelist_byvar/namelist_psl",(/nsim/),"string")
  names = new(nsim,"string")
  paths = new(nsim,"string")
  syear = new(nsim,"integer",-999)
  eyear = new(nsim,"integer",-999)
  delim = "|"

  do gg = 0,nsim-1
     names(gg) = str_strip(str_get_field(na(gg),1,delim))
     paths(gg) = str_strip(str_get_field(na(gg),2,delim))
     syear(gg) = stringtointeger(str_strip(str_get_field(na(gg),3,delim)))
     eyear(gg) = stringtointeger(str_strip(str_get_field(na(gg),4,delim)))
  end do
  nyr = eyear-syear+1
  nyr_max = max(nyr)

  pi=4.*atan(1.0)
  rad=(pi/180.)
  
;---------SST Regressions coding-------------------------------------------------
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
  delete(na_ts)
  nyr_ts = eyear_ts-syear_ts+1  
;-------------------------------------------------------------------------------------------------
    
  wks_type = OUTPUT_TYPE
  if (wks_type.eq."png") then
     wks_type@wkWidth = 1500*PNG_SCALE
     wks_type@wkHeight = 1500*PNG_SCALE
  end if
  
  wks_sam = gsn_open_wks(wks_type,getenv("OUTDIR")+"sam")
  wks_sam_ts = gsn_open_wks(wks_type,getenv("OUTDIR")+"sam.timeseries")
  
  wks_psa1 = gsn_open_wks(wks_type,getenv("OUTDIR")+"psa1")
  wks_psa1_ts = gsn_open_wks(wks_type,getenv("OUTDIR")+"psa1.timeseries")

  wks_psa2 = gsn_open_wks(wks_type,getenv("OUTDIR")+"psa2")
  wks_psa2_ts = gsn_open_wks(wks_type,getenv("OUTDIR")+"psa2.timeseries")
  
  if (COLORMAP.eq.0) then
     gsn_define_colormap(wks_sam,"ncl_default")   
     gsn_define_colormap(wks_sam_ts,"ncl_default")
     gsn_define_colormap(wks_psa1,"ncl_default")   
     gsn_define_colormap(wks_psa1_ts,"ncl_default")
     gsn_define_colormap(wks_psa2,"ncl_default")   
     gsn_define_colormap(wks_psa2_ts,"ncl_default")
  end if
  if (COLORMAP.eq.1) then
     gsn_define_colormap(wks_sam,"BlueDarkRed18")   
     gsn_define_colormap(wks_sam_ts,"ncl_default")
     gsn_define_colormap(wks_psa1,"BlueDarkRed18")   
     gsn_define_colormap(wks_psa1_ts,"ncl_default")
     gsn_define_colormap(wks_psa2,"BlueDarkRed18")   
     gsn_define_colormap(wks_psa2_ts,"ncl_default")
  end if
  
  map_sam_djf = new(nsim,"graphic")  
  map_sam_mam = new(nsim,"graphic")  
  map_sam_jja = new(nsim,"graphic")  
  map_sam_son = new(nsim,"graphic")  
  map_sam_ann = new(nsim,"graphic")  
  map_sam_mon = new(nsim,"graphic")  
  xy_sam_djf = new(nsim,"graphic")
  xy_sam_mam = new(nsim,"graphic")
  xy_sam_jja = new(nsim,"graphic")
  xy_sam_son = new(nsim,"graphic")
  xy_sam_ann = new(nsim,"graphic")
  xy_sam_mon = new(nsim,"graphic")
  reg_sam_djf = new(nsim,"graphic")  
  reg_sam_mam = new(nsim,"graphic")  
  reg_sam_jja = new(nsim,"graphic")  
  reg_sam_son = new(nsim,"graphic")  
  reg_sam_ann = new(nsim,"graphic")  
  reg_sam_mon = new(nsim,"graphic")  
  
  map_psa1_djf = new(nsim,"graphic")  
  map_psa1_mam = new(nsim,"graphic")  
  map_psa1_jja = new(nsim,"graphic")  
  map_psa1_son = new(nsim,"graphic")  
  map_psa1_ann = new(nsim,"graphic")  
  map_psa1_mon = new(nsim,"graphic")  
  xy_psa1_djf = new(nsim,"graphic")
  xy_psa1_mam = new(nsim,"graphic")
  xy_psa1_jja = new(nsim,"graphic")
  xy_psa1_son = new(nsim,"graphic")
  xy_psa1_ann = new(nsim,"graphic")
  xy_psa1_mon = new(nsim,"graphic")
  reg_psa1_djf = new(nsim,"graphic")  
  reg_psa1_mam = new(nsim,"graphic")  
  reg_psa1_jja = new(nsim,"graphic")  
  reg_psa1_son = new(nsim,"graphic")  
  reg_psa1_ann = new(nsim,"graphic")  
  reg_psa1_mon = new(nsim,"graphic")  
  
  map_psa2_djf = new(nsim,"graphic")  
  map_psa2_mam = new(nsim,"graphic")  
  map_psa2_jja = new(nsim,"graphic")  
  map_psa2_son = new(nsim,"graphic")  
  map_psa2_ann = new(nsim,"graphic")  
  map_psa2_mon = new(nsim,"graphic")  
  xy_psa2_djf = new(nsim,"graphic")
  xy_psa2_mam = new(nsim,"graphic")
  xy_psa2_jja = new(nsim,"graphic")
  xy_psa2_son = new(nsim,"graphic")
  xy_psa2_ann = new(nsim,"graphic")
  xy_psa2_mon = new(nsim,"graphic")
  reg_psa2_djf = new(nsim,"graphic")  
  reg_psa2_mam = new(nsim,"graphic")  
  reg_psa2_jja = new(nsim,"graphic")  
  reg_psa2_son = new(nsim,"graphic")  
  reg_psa2_ann = new(nsim,"graphic")  
  reg_psa2_mon = new(nsim,"graphic")  
  
  sstreg_frame = 1    ; sstreg_frame = flag to create regressions .ps/.png files. Created/used instead of sstreg_plot_flag
                      ; so that if sst regressions are not created for the last simulation listed that .ps/png files are created
  do ee = 0,nsim-1
;     print(paths(ee)+" "+syear(ee)+" "+eyear(ee)) 
     arr = data_read_in(paths(ee),"PSL",syear(ee),eyear(ee))    ; read in data, orient lats/lons correctly, set time coordinate variable up
     if (isatt(arr,"is_all_missing")) then
        delete(arr)
        continue
     end if 
     
     if (OPT_CLIMO.eq."Full") then
        arr = rmMonAnnCycTLL(arr)
     else
        check_custom_climo(names(ee),syear(ee),eyear(ee),CLIMO_SYEAR,CLIMO_EYEAR)
        temp_arr = arr
        delete(temp_arr&time)
        temp_arr&time = cd_calendar(arr&time,-1)
        climo = clmMonTLL(temp_arr({CLIMO_SYEAR*100+1:CLIMO_EYEAR*100+12},:,:))                 
        delete(temp_arr)
        arr   = calcMonAnomTLL(arr,climo) 
        delete(climo)
     end if

     arrT =  runave_n_Wrap(arr,3,0,0)               ; form DJF averages
     arrT(0,:,:) = (/ dim_avg_n(arr(:1,:,:),0) /)   
     arr_djf = arrT(0::12,:,:)
     arr_mam = arrT(3::12,:,:)
     arr_jja = arrT(6::12,:,:)                       ; form JJA averages
     arr_son = arrT(9::12,:,:)
     delete(arrT)
     
     arrV = runave_n_Wrap(arr,12,0,0)
     arr_ann = arrV(5::12,:,:)
     delete(arrV)
;          
;     arr_djf = (/ dtrend_msg_n(ispan(0,dimsizes(arr_djf&time)-1,1),arr_djf,True,False,0) /)
;     arr_mam = (/ dtrend_msg_n(ispan(0,dimsizes(arr_mam&time)-1,1),arr_mam,True,False,0) /)
;     arr_jja = (/ dtrend_msg_n(ispan(0,dimsizes(arr_jja&time)-1,1),arr_jja,True,False,0) /)
;     arr_son = (/ dtrend_msg_n(ispan(0,dimsizes(arr_son&time)-1,1),arr_son,True,False,0) /)
;     
;     arr_ann = (/ dtrend_msg_n(ispan(0,dimsizes(arr_ann&time)-1,1),arr_ann,True,False,0) /)
;     
;     arr_ndjfm = (/ dtrend_msg_n(ispan(0,dimsizes(arr_ndjfm&time)-1,1),arr_ndjfm,True,False,0) /)
;     
;     arr = (/ dtrend_msg_n(ispan(0,dimsizes(arr&time)-1,1),arr,True,False,0) /)
;---------SST Regressions coding-------------------------------------------------
     if (any(ismissing((/syear(ee),syear_ts(ee),eyear(ee),eyear_ts(ee)/)))) then
        sstreg_plot_flag = 1
     else
        if (syear(ee).eq.syear_ts(ee)) then     ; check that the start and end years match for ts, trefht, and psl
           if (eyear(ee).eq.eyear_ts(ee)) then
              sstreg_plot_flag = 0
           else
              sstreg_plot_flag = 1
           end if
        else
           sstreg_plot_flag = 1
        end if
     end if 

     if (sstreg_plot_flag.eq.0) then 
        ; print("Data to be read in: "+paths_ts(ee)+" from "+syear_ts(ee)+":"+eyear_ts(ee))
        sst = data_read_in(paths_ts(ee),"TS",syear_ts(ee),eyear_ts(ee))
        if (isatt(sst,"is_all_missing")) then
           sstreg_plot_flag = 1
           delete(sst)
        end if
        
        if (sstreg_plot_flag.eq.0) then     ; only continue if both PSL/TS fields are present
           sst = where(sst.le.-1.8,-1.8,sst)
           d = addfile("$NCARG_ROOT/lib/ncarg/data/cdf/landsea.nc","r")   
           basemap = d->LSMASK
           lsm = landsea_mask(basemap,sst&lat,sst&lon)
           sst = mask(sst,conform(sst,lsm,(/1,2/)).ge.1,False)
           delete(lsm)
           
           if (OPT_CLIMO.eq."Full") then
              sst = rmMonAnnCycTLL(sst)
           else
              check_custom_climo(names_ts(ee),syear_ts(ee),eyear_ts(ee),CLIMO_SYEAR,CLIMO_EYEAR)
              temp_arr = sst
              delete(temp_arr&time)
              temp_arr&time = cd_calendar(sst&time,1)
              climo = clmMonTLL(temp_arr({CLIMO_SYEAR*100+1:CLIMO_EYEAR*100+12},:,:))                 
              delete(temp_arr)
              sst   = calcMonAnomTLL(sst,climo) 
              delete(climo)
           end if
;           sst = (/ dtrend_msg_n(ispan(0,dimsizes(sst&time)-1,1),sst,False,False,0) /)  
        
           sstT =  runave_n_Wrap(sst,3,0,0)               ; form DJF averages
           sstT(0,:,:) = (/ dim_avg_n(sst(:1,:,:),0) /)   
           sst_djf = sstT(0::12,:,:)
           sst_mam = sstT(3::12,:,:)
           sst_jja = sstT(6::12,:,:)                       ; form JJA averages
           sst_son = sstT(9::12,:,:)
           delete(sstT)
     
           sstV = runave_n_Wrap(sst,12,0,0)
           sst_ann = sstV(5::12,:,:)
           delete(sstV)
        end if
     end if    
;------------------------------------------------------------------
     arr_djf_CW = SqrtCosWeight(arr_djf)
     arr_mam_CW = SqrtCosWeight(arr_mam)
     arr_jja_CW = SqrtCosWeight(arr_jja)
     arr_son_CW = SqrtCosWeight(arr_son)
     arr_ann_CW = SqrtCosWeight(arr_ann)
     if (COMPUTE_MODES_MON.eq."True") then   
        arr_mon_CW = SqrtCosWeight(arr)
     else
        delete(arr)
        if (sstreg_plot_flag.eq.0) then
           delete(sst)
        end if
     end if    
;----------SAM/PSA1/PSA2 calculations----------------------------------------------------------------------     
     evecv = eofunc(arr_djf_CW({lat|:-20},lon|:,time|:),4,75)
     pcts = eofunc_ts(arr_djf_CW({lat|:-20},lon|:,time|:),evecv,False)  
     sam_pc_djf = dim_standardize(pcts(0,:),0)
     psa1_pc_djf = dim_standardize(pcts(1,:),0)
     psa2_pc_djf = dim_standardize(pcts(2,:),0)     
     sam_djf = arr_djf(0,:,:)
     sam_djf = (/ regCoef(sam_pc_djf,arr_djf(lat|:,lon|:,time|:)) /)
     psa1_djf = arr_djf(0,:,:)
     psa1_djf = (/ regCoef(psa1_pc_djf,arr_djf(lat|:,lon|:,time|:)) /)
     psa2_djf = arr_djf(0,:,:)
     psa2_djf = (/ regCoef(psa2_pc_djf,arr_djf(lat|:,lon|:,time|:)) /)
     if (sstreg_plot_flag.eq.0) then
        sam_sst_djf = sst_djf(0,:,:)
        sam_sst_djf = (/ regCoef(sam_pc_djf,sst_djf(lat|:,lon|:,time|:)) /)
        psa1_sst_djf = sst_djf(0,:,:)
        psa1_sst_djf = (/ regCoef(psa1_pc_djf,sst_djf(lat|:,lon|:,time|:)) /)
        psa2_sst_djf = sst_djf(0,:,:)
        psa2_sst_djf = (/ regCoef(psa2_pc_djf,sst_djf(lat|:,lon|:,time|:)) /)
        delete(sst_djf)
     end if     
     
     if (.not.ismissing(sam_djf({-85},{5}))) then
        if (sam_djf({-85},{5}).ge.0) then  ; arbitrary attempt to make all plots have the same sign..
           sam_djf = sam_djf*-1.
           sam_pc_djf = sam_pc_djf*-1.
           if (sstreg_plot_flag.eq.0) then
              sam_sst_djf = sam_sst_djf*-1.
           end if
        end if
     end if
     if (.not.ismissing(psa1_djf({-62},{270}))) then
        if (psa1_djf({-62},{270}).ge.0) then  ; arbitrary attempt to make all plots have the same sign..
           psa1_djf = psa1_djf*-1.
           psa1_pc_djf = psa1_pc_djf*-1.
           if (sstreg_plot_flag.eq.0) then
              psa1_sst_djf = psa1_sst_djf*-1.
           end if
        end if
     end if
     if (.not.ismissing(psa2_djf({-52},{150}))) then
        if (psa2_djf({-52},{150}).ge.0) then  ; arbitrary attempt to make all plots have the same sign..
           psa2_djf = psa2_djf*-1.
           psa2_pc_djf = psa2_pc_djf*-1.
           if (sstreg_plot_flag.eq.0) then
              psa2_sst_djf = psa2_sst_djf*-1.
           end if
        end if     
     end if
     sig_pcv = eofunc_north2(evecv@pcvar,dimsizes(sam_pc_djf),False)
     if (sig_pcv(0)) then    ; if True then significant
        sam_djf@pcvar = tofloat(sprintf("%4.1f", evecv@pcvar(0)))+"%*"
     else
        sam_djf@pcvar = tofloat(sprintf("%4.1f", evecv@pcvar(0)))+"%"
     end if
     if (sig_pcv(1)) then    ; if True then significant
        psa1_djf@pcvar = tofloat(sprintf("%4.1f", evecv@pcvar(1)))+"%*"
     else
        psa1_djf@pcvar = tofloat(sprintf("%4.1f", evecv@pcvar(1)))+"%"
     end if
     if (sig_pcv(2)) then    ; if True then significant
        psa2_djf@pcvar = tofloat(sprintf("%4.1f", evecv@pcvar(2)))+"%*"
     else
        psa2_djf@pcvar = tofloat(sprintf("%4.1f", evecv@pcvar(2)))+"%"
     end if
     delete(sig_pcv)    
     sam_pc_djf!0 = "TIME"
     sam_pc_djf&TIME = ispan(syear(ee),eyear(ee),1)
     sam_pc_djf&TIME@units = "YYYY"
     sam_pc_djf&TIME@long_same = "time"     
     
     copy_VarCoords(sam_pc_djf,psa1_pc_djf)
     copy_VarCoords(sam_pc_djf,psa2_pc_djf)  
     delete([/evecv,pcts/])
     
     evecv = eofunc(arr_mam_CW({lat|:-20},lon|:,time|:),4,75)
     pcts = eofunc_ts(arr_mam_CW({lat|:-20},lon|:,time|:),evecv,False)  
     sam_pc_mam = dim_standardize(pcts(0,:),0)
     psa1_pc_mam = dim_standardize(pcts(1,:),0)
     psa2_pc_mam = dim_standardize(pcts(2,:),0)     
     sam_mam = arr_mam(0,:,:)
     sam_mam = (/ regCoef(sam_pc_mam,arr_mam(lat|:,lon|:,time|:)) /)
     psa1_mam = arr_mam(0,:,:)
     psa1_mam = (/ regCoef(psa1_pc_mam,arr_mam(lat|:,lon|:,time|:)) /)
     psa2_mam = arr_mam(0,:,:)
     psa2_mam = (/ regCoef(psa2_pc_mam,arr_mam(lat|:,lon|:,time|:)) /)
     if (sstreg_plot_flag.eq.0) then
        sam_sst_mam = sst_mam(0,:,:)
        sam_sst_mam = (/ regCoef(sam_pc_mam,sst_mam(lat|:,lon|:,time|:)) /)
        psa1_sst_mam = sst_mam(0,:,:)
        psa1_sst_mam = (/ regCoef(psa1_pc_mam,sst_mam(lat|:,lon|:,time|:)) /)
        psa2_sst_mam = sst_mam(0,:,:)
        psa2_sst_mam = (/ regCoef(psa2_pc_mam,sst_mam(lat|:,lon|:,time|:)) /)
        delete(sst_mam)
     end if  
     
     if (.not.ismissing(sam_mam({-85},{5}))) then
        if (sam_mam({-85},{5}).ge.0) then  ; arbitrary attempt to make all plots have the same sign..
           sam_mam = sam_mam*-1.
           sam_pc_mam = sam_pc_mam*-1.
           if (sstreg_plot_flag.eq.0) then
              sam_sst_mam = sam_sst_mam*-1.
           end if
        end if
     end if
     if (.not.ismissing(psa1_mam({-62},{270}))) then
        if (psa1_mam({-62},{270}).ge.0) then  ; arbitrary attempt to make all plots have the same sign..
           psa1_mam = psa1_mam*-1.
           psa1_pc_mam = psa1_pc_mam*-1.
           if (sstreg_plot_flag.eq.0) then
              psa1_sst_mam = psa1_sst_mam*-1.
           end if
        end if
     end if
     if (.not.ismissing(psa2_mam({-52},{150}))) then
        if (psa2_mam({-52},{150}).ge.0) then  ; arbitrary attempt to make all plots have the same sign..
           psa2_mam = psa2_mam*-1.
           psa2_pc_mam = psa2_pc_mam*-1.
           if (sstreg_plot_flag.eq.0) then
              psa2_sst_mam = psa2_sst_mam*-1.
           end if
        end if     
     end if
     sig_pcv = eofunc_north2(evecv@pcvar,dimsizes(sam_pc_mam),False)
     if (sig_pcv(0)) then    ; if True then significant
        sam_mam@pcvar = tofloat(sprintf("%4.1f", evecv@pcvar(0)))+"%*"
     else
        sam_mam@pcvar = tofloat(sprintf("%4.1f", evecv@pcvar(0)))+"%"
     end if
     if (sig_pcv(1)) then    ; if True then significant
        psa1_mam@pcvar = tofloat(sprintf("%4.1f", evecv@pcvar(1)))+"%*"
     else
        psa1_mam@pcvar = tofloat(sprintf("%4.1f", evecv@pcvar(1)))+"%"
     end if
     if (sig_pcv(2)) then    ; if True then significant
        psa2_mam@pcvar = tofloat(sprintf("%4.1f", evecv@pcvar(2)))+"%*"
     else
        psa2_mam@pcvar = tofloat(sprintf("%4.1f", evecv@pcvar(2)))+"%"
     end if
     delete(sig_pcv)
     copy_VarCoords(sam_pc_djf,sam_pc_mam) 
     copy_VarCoords(sam_pc_djf,psa1_pc_mam)
     copy_VarCoords(sam_pc_djf,psa2_pc_mam)  
     delete([/evecv,pcts/])
     
     evecv = eofunc(arr_jja_CW({lat|:-20},lon|:,time|:),4,75)
     pcts = eofunc_ts(arr_jja_CW({lat|:-20},lon|:,time|:),evecv,False)  
     sam_pc_jja = dim_standardize(pcts(0,:),0)
     psa1_pc_jja = dim_standardize(pcts(1,:),0)
     psa2_pc_jja = dim_standardize(pcts(2,:),0)     
     sam_jja = arr_jja(0,:,:)
     sam_jja = (/ regCoef(sam_pc_jja,arr_jja(lat|:,lon|:,time|:)) /)
     psa1_jja = arr_jja(0,:,:)
     psa1_jja = (/ regCoef(psa1_pc_jja,arr_jja(lat|:,lon|:,time|:)) /)
     psa2_jja = arr_jja(0,:,:)
     psa2_jja = (/ regCoef(psa2_pc_jja,arr_jja(lat|:,lon|:,time|:)) /)
     if (sstreg_plot_flag.eq.0) then
        sam_sst_jja = sst_jja(0,:,:)
        sam_sst_jja = (/ regCoef(sam_pc_jja,sst_jja(lat|:,lon|:,time|:)) /)
        psa1_sst_jja = sst_jja(0,:,:)
        psa1_sst_jja = (/ regCoef(psa1_pc_jja,sst_jja(lat|:,lon|:,time|:)) /)
        psa2_sst_jja = sst_jja(0,:,:)
        psa2_sst_jja = (/ regCoef(psa2_pc_jja,sst_jja(lat|:,lon|:,time|:)) /)
        delete(sst_jja)
     end if  
     if (.not.ismissing(sam_jja({-85},{5}))) then
        if (sam_jja({-85},{5}).ge.0) then  ; arbitrary attempt to make all plots have the same sign..
           sam_jja = sam_jja*-1.
           sam_pc_jja = sam_pc_jja*-1.
           if (sstreg_plot_flag.eq.0) then
              sam_sst_jja = sam_sst_jja*-1.
           end if
        end if
     end if
     if (.not.ismissing(psa1_jja({-62},{270}))) then
        if (psa1_jja({-62},{270}).ge.0) then  ; arbitrary attempt to make all plots have the same sign..
           psa1_jja = psa1_jja*-1.
           psa1_pc_jja = psa1_pc_jja*-1.
           if (sstreg_plot_flag.eq.0) then
              psa1_sst_jja = psa1_sst_jja*-1.
           end if
        end if
     end if
     if (.not.ismissing(psa2_jja({-52},{150}))) then
        if (psa2_jja({-52},{150}).ge.0) then  ; arbitrary attempt to make all plots have the same sign..
           psa2_jja = psa2_jja*-1.
           psa2_pc_jja = psa2_pc_jja*-1.
           if (sstreg_plot_flag.eq.0) then
              psa2_sst_jja = psa2_sst_jja*-1.
           end if
        end if     
     end if
     sig_pcv = eofunc_north2(evecv@pcvar,dimsizes(sam_pc_jja),False)
     if (sig_pcv(0)) then    ; if True then significant
        sam_jja@pcvar = tofloat(sprintf("%4.1f", evecv@pcvar(0)))+"%*"
     else
        sam_jja@pcvar = tofloat(sprintf("%4.1f", evecv@pcvar(0)))+"%"
     end if
     if (sig_pcv(1)) then    ; if True then significant
        psa1_jja@pcvar = tofloat(sprintf("%4.1f", evecv@pcvar(1)))+"%*"
     else
        psa1_jja@pcvar = tofloat(sprintf("%4.1f", evecv@pcvar(1)))+"%"
     end if
     if (sig_pcv(2)) then    ; if True then significant
        psa2_jja@pcvar = tofloat(sprintf("%4.1f", evecv@pcvar(2)))+"%*"
     else
        psa2_jja@pcvar = tofloat(sprintf("%4.1f", evecv@pcvar(2)))+"%"
     end if
     delete(sig_pcv)
     copy_VarCoords(sam_pc_djf,sam_pc_jja) 
     copy_VarCoords(sam_pc_djf,psa1_pc_jja)
     copy_VarCoords(sam_pc_djf,psa2_pc_jja)  
     delete([/evecv,pcts/])
 
     evecv = eofunc(arr_son_CW({lat|:-20},lon|:,time|:),4,75)
     pcts = eofunc_ts(arr_son_CW({lat|:-20},lon|:,time|:),evecv,False)  
     sam_pc_son = dim_standardize(pcts(0,:),0)
     psa1_pc_son = dim_standardize(pcts(1,:),0)
     psa2_pc_son = dim_standardize(pcts(2,:),0)     
     sam_son = arr_son(0,:,:)
     sam_son = (/ regCoef(sam_pc_son,arr_son(lat|:,lon|:,time|:)) /)
     psa1_son = arr_son(0,:,:)
     psa1_son = (/ regCoef(psa1_pc_son,arr_son(lat|:,lon|:,time|:)) /)
     psa2_son = arr_son(0,:,:)
     psa2_son = (/ regCoef(psa2_pc_son,arr_son(lat|:,lon|:,time|:)) /)
     if (sstreg_plot_flag.eq.0) then
        sam_sst_son = sst_son(0,:,:)
        sam_sst_son = (/ regCoef(sam_pc_son,sst_son(lat|:,lon|:,time|:)) /)
        psa1_sst_son = sst_son(0,:,:)
        psa1_sst_son = (/ regCoef(psa1_pc_son,sst_son(lat|:,lon|:,time|:)) /)
        psa2_sst_son = sst_son(0,:,:)
        psa2_sst_son = (/ regCoef(psa2_pc_son,sst_son(lat|:,lon|:,time|:)) /)
        delete(sst_son)
     end if  
     if (.not.ismissing(sam_son({-85},{5}))) then
        if (sam_son({-85},{5}).ge.0) then  ; arbitrary attempt to make all plots have the same sign..
           sam_son = sam_son*-1.
           sam_pc_son = sam_pc_son*-1.
           if (sstreg_plot_flag.eq.0) then
              sam_sst_son = sam_sst_son*-1.
           end if
        end if
     end if
     if (.not.ismissing(psa1_son({-62},{270}))) then
        if (psa1_son({-62},{270}).ge.0) then  ; arbitrary attempt to make all plots have the same sign..
           psa1_son = psa1_son*-1.
           psa1_pc_son = psa1_pc_son*-1.
           if (sstreg_plot_flag.eq.0) then
              psa1_sst_son = psa1_sst_son*-1.
           end if
        end if
     end if
     if (.not.ismissing(psa2_son({-52},{150}))) then
        if (psa2_son({-52},{150}).ge.0) then  ; arbitrary attempt to make all plots have the same sign..
           psa2_son = psa2_son*-1.
           psa2_pc_son = psa2_pc_son*-1.
           if (sstreg_plot_flag.eq.0) then
              psa2_sst_son = psa2_sst_son*-1.
           end if
        end if     
     end if
     sig_pcv = eofunc_north2(evecv@pcvar,dimsizes(sam_pc_son),False)
     if (sig_pcv(0)) then    ; if True then significant
        sam_son@pcvar = tofloat(sprintf("%4.1f", evecv@pcvar(0)))+"%*"
     else
        sam_son@pcvar = tofloat(sprintf("%4.1f", evecv@pcvar(0)))+"%"
     end if
     if (sig_pcv(1)) then    ; if True then significant
        psa1_son@pcvar = tofloat(sprintf("%4.1f", evecv@pcvar(1)))+"%*"
     else
        psa1_son@pcvar = tofloat(sprintf("%4.1f", evecv@pcvar(1)))+"%"
     end if
     if (sig_pcv(2)) then    ; if True then significant
        psa2_son@pcvar = tofloat(sprintf("%4.1f", evecv@pcvar(2)))+"%*"
     else
        psa2_son@pcvar = tofloat(sprintf("%4.1f", evecv@pcvar(2)))+"%"
     end if
     delete(sig_pcv)
     copy_VarCoords(sam_pc_djf,sam_pc_son) 
     copy_VarCoords(sam_pc_djf,psa1_pc_son)
     copy_VarCoords(sam_pc_djf,psa2_pc_son)  
     delete([/evecv,pcts/])

     evecv = eofunc(arr_ann_CW({lat|:-20},lon|:,time|:),4,75)
     pcts = eofunc_ts(arr_ann_CW({lat|:-20},lon|:,time|:),evecv,False)  
     sam_pc_ann = dim_standardize(pcts(0,:),0)
     psa1_pc_ann = dim_standardize(pcts(1,:),0)
     psa2_pc_ann = dim_standardize(pcts(2,:),0)     
     sam_ann = arr_ann(0,:,:)
     sam_ann = (/ regCoef(sam_pc_ann,arr_ann(lat|:,lon|:,time|:)) /)
     psa1_ann = arr_ann(0,:,:)
     psa1_ann = (/ regCoef(psa1_pc_ann,arr_ann(lat|:,lon|:,time|:)) /)
     psa2_ann = arr_ann(0,:,:)
     psa2_ann = (/ regCoef(psa2_pc_ann,arr_ann(lat|:,lon|:,time|:)) /)
     if (sstreg_plot_flag.eq.0) then
        sam_sst_ann = sst_ann(0,:,:)
        sam_sst_ann = (/ regCoef(sam_pc_ann,sst_ann(lat|:,lon|:,time|:)) /)
        psa1_sst_ann = sst_ann(0,:,:)
        psa1_sst_ann = (/ regCoef(psa1_pc_ann,sst_ann(lat|:,lon|:,time|:)) /)
        psa2_sst_ann = sst_ann(0,:,:)
        psa2_sst_ann = (/ regCoef(psa2_pc_ann,sst_ann(lat|:,lon|:,time|:)) /)
        delete(sst_ann)
     end if  
     if (.not.ismissing(sam_ann({-85},{5}))) then
        if (sam_ann({-85},{5}).ge.0) then  ; arbitrary attempt to make all plots have the same sign..
           sam_ann = sam_ann*-1.
           sam_pc_ann = sam_pc_ann*-1.
           if (sstreg_plot_flag.eq.0) then
              sam_sst_ann = sam_sst_ann*-1.
           end if
        end if
     end if
     if (.not.ismissing(psa1_ann({-62},{270}))) then
        if (psa1_ann({-62},{270}).ge.0) then  ; arbitrary attempt to make all plots have the same sign..
           psa1_ann = psa1_ann*-1.
           psa1_pc_ann = psa1_pc_ann*-1.
           if (sstreg_plot_flag.eq.0) then
              psa1_sst_ann = psa1_sst_ann*-1.
           end if
        end if
     end if
     if (.not.ismissing(psa2_ann({-52},{150}))) then
        if (psa2_ann({-52},{150}).ge.0) then  ; arbitrary attempt to make all plots have the same sign..
           psa2_ann = psa2_ann*-1.
           psa2_pc_ann = psa2_pc_ann*-1.
           if (sstreg_plot_flag.eq.0) then
              psa2_sst_ann = psa2_sst_ann*-1.
           end if
        end if     
     end if
     sig_pcv = eofunc_north2(evecv@pcvar,dimsizes(sam_pc_ann),False)
     if (sig_pcv(0)) then    ; if True then significant
        sam_ann@pcvar = tofloat(sprintf("%4.1f", evecv@pcvar(0)))+"%*"
     else
        sam_ann@pcvar = tofloat(sprintf("%4.1f", evecv@pcvar(0)))+"%"
     end if
     if (sig_pcv(1)) then    ; if True then significant
        psa1_ann@pcvar = tofloat(sprintf("%4.1f", evecv@pcvar(1)))+"%*"
     else
        psa1_ann@pcvar = tofloat(sprintf("%4.1f", evecv@pcvar(1)))+"%"
     end if
     if (sig_pcv(2)) then    ; if True then significant
        psa2_ann@pcvar = tofloat(sprintf("%4.1f", evecv@pcvar(2)))+"%*"
     else
        psa2_ann@pcvar = tofloat(sprintf("%4.1f", evecv@pcvar(2)))+"%"
     end if
     delete(sig_pcv)
     copy_VarCoords(sam_pc_djf,sam_pc_ann) 
     copy_VarCoords(sam_pc_djf,psa1_pc_ann)
     copy_VarCoords(sam_pc_djf,psa2_pc_ann)  
     delete([/evecv,pcts/])
     
     if (COMPUTE_MODES_MON.eq."True") then     
        evecv = eofunc(arr_mon_CW({lat|:-20},lon|:,time|:),4,75)
        pcts = eofunc_ts(arr_mon_CW({lat|:-20},lon|:,time|:),evecv,False)  
        sam_pc_mon = dim_standardize(pcts(0,:),0)
        psa1_pc_mon = dim_standardize(pcts(1,:),0)
        psa2_pc_mon = dim_standardize(pcts(2,:),0)        
        sam_mon = arr(0,:,:)
        sam_mon = (/ regCoef(sam_pc_mon,arr(lat|:,lon|:,time|:)) /)
        psa1_mon = arr(0,:,:)
        psa1_mon = (/ regCoef(psa1_pc_mon,arr(lat|:,lon|:,time|:)) /)
        psa2_mon = arr(0,:,:)
        psa2_mon = (/ regCoef(psa2_pc_mon,arr(lat|:,lon|:,time|:)) /)
        if (sstreg_plot_flag.eq.0) then
           sam_sst_mon = sst(0,:,:)
           sam_sst_mon = (/ regCoef(sam_pc_mon,sst(lat|:,lon|:,time|:)) /)
           psa1_sst_mon = sst(0,:,:)
           psa1_sst_mon = (/ regCoef(psa1_pc_mon,sst(lat|:,lon|:,time|:)) /)
           psa2_sst_mon = sst(0,:,:)
           psa2_sst_mon = (/ regCoef(psa2_pc_mon,sst(lat|:,lon|:,time|:)) /)
           delete(sst)
        end if  
        if (.not.ismissing(sam_mon({-85},{5}))) then
           if (sam_mon({-85},{5}).ge.0) then  ; arbitrary attempt to make all plots have the same sign..
              sam_mon = sam_mon*-1.
              sam_pc_mon = sam_pc_mon*-1.
              if (sstreg_plot_flag.eq.0) then
                 sam_sst_mon = sam_sst_mon*-1.
              end if
           end if
        end if
        if (.not.ismissing(psa1_mon({-62},{270}))) then
           if (psa1_mon({-62},{270}).ge.0) then  ; arbitrary attempt to make all plots have the same sign..
              psa1_mon = psa1_mon*-1.
              psa1_pc_mon = psa1_pc_mon*-1.
              if (sstreg_plot_flag.eq.0) then
                 psa1_sst_mon = psa1_sst_mon*-1.
              end if
           end if
        end if
        if (.not.ismissing(psa2_mon({-52},{150}))) then
           if (psa2_mon({-52},{150}).ge.0) then  ; arbitrary attempt to make all plots have the same sign..
              psa2_mon = psa2_mon*-1.
              psa2_pc_mon = psa2_pc_mon*-1.
              if (sstreg_plot_flag.eq.0) then
                 psa2_sst_mon = psa2_sst_mon*-1.
              end if
           end if     
        end if
        sig_pcv = eofunc_north2(evecv@pcvar,dimsizes(sam_pc_mon),False)
        if (sig_pcv(0)) then    ; if True then significant
           sam_mon@pcvar = tofloat(sprintf("%4.1f", evecv@pcvar(0)))+"%*"
        else
           sam_mon@pcvar = tofloat(sprintf("%4.1f", evecv@pcvar(0)))+"%"
        end if
        if (sig_pcv(1)) then    ; if True then significant
           psa1_mon@pcvar = tofloat(sprintf("%4.1f", evecv@pcvar(1)))+"%*"
        else
           psa1_mon@pcvar = tofloat(sprintf("%4.1f", evecv@pcvar(1)))+"%"
        end if
        if (sig_pcv(2)) then    ; if True then significant
           psa2_mon@pcvar = tofloat(sprintf("%4.1f", evecv@pcvar(2)))+"%*"
        else
           psa2_mon@pcvar = tofloat(sprintf("%4.1f", evecv@pcvar(2)))+"%"
        end if
        delete(sig_pcv)
        sam_pc_mon!0 = "time"
        sam_pc_mon&time = arr&time   
        psa1_pc_mon!0 = "time"
        psa1_pc_mon&time = arr&time   
        psa2_pc_mon!0 = "time"
        psa2_pc_mon&time = arr&time   
        delete([/evecv,pcts,arr_mon_CW,arr/])
     end if
     delete([/arr_djf_CW,arr_mam_CW,arr_jja_CW,arr_son_CW,arr_ann_CW/])
     delete([/arr_djf,arr_mam,arr_jja,arr_son,arr_ann/])
;------------------------------------------------------------------------------------------------------
     if (sstreg_frame.eq.1.and.sstreg_plot_flag.eq.0) then    ; sstreg_frame = flag to create regressions .ps/.png files 
        sstreg_frame = 0
     end if          
;------------------------------------------------------------------------------------------------------
     if (OUTPUT_DATA.eq."True") then
        modname = str_sub_str(names(ee)," ","_")
        bc = (/"/","'","(",")"/)
        do gg = 0,dimsizes(bc)-1
           modname = str_sub_str(modname,bc(gg),"_")
        end do
        fn = getenv("OUTDIR")+modname+".cvdp_data.psl.sam_psa."+syear(ee)+"-"+eyear(ee)+".nc"
        if (.not.isfilepresent2(fn)) then
           z = addfile(fn,"c")
           z@source = "NCAR Climate Analysis Section's Climate Variability Diagnostics Package v"+getenv("VERSION")
           z@notes = "Data from "+names(ee)+" from "+syear(ee)+"-"+eyear(ee)
           if (OPT_CLIMO.eq."Full") then
              z@climatology = syear(ee)+"-"+eyear(ee)+" climatology removed prior to all calculations (other than means)"
           else
              z@climatology = CLIMO_SYEAR+"-"+CLIMO_EYEAR+" climatology removed prior to all calculations (other than means)"
           end if
        else
           z = addfile(fn,"w")
        end if
        z->sam_pc_djf = sam_pc_djf
        z->sam_pc_mam = sam_pc_mam
        z->sam_pc_jja = sam_pc_jja
        z->sam_pc_son = sam_pc_son
        z->sam_pc_ann = sam_pc_ann
        
        z->psa1_pc_djf = psa1_pc_djf
        z->psa1_pc_mam = psa1_pc_mam
        z->psa1_pc_jja = psa1_pc_jja
        z->psa1_pc_son = psa1_pc_son
        z->psa1_pc_ann = psa1_pc_ann
        
        z->psa2_pc_djf = psa2_pc_djf
        z->psa2_pc_mam = psa2_pc_mam
        z->psa2_pc_jja = psa2_pc_jja
        z->psa2_pc_son = psa2_pc_son
        z->psa2_pc_ann = psa2_pc_ann
        
        z->sam_djf = sam_djf
        z->sam_mam = sam_mam
        z->sam_jja = sam_jja
        z->sam_son = sam_son
        z->sam_ann = sam_ann
        
        z->psa1_djf = psa1_djf
        z->psa1_mam = psa1_mam
        z->psa1_jja = psa1_jja
        z->psa1_son = psa1_son
        z->psa1_ann = psa1_ann
        
        z->psa2_djf = psa2_djf
        z->psa2_mam = psa2_mam
        z->psa2_jja = psa2_jja
        z->psa2_son = psa2_son
        z->psa2_ann = psa2_ann

        if (COMPUTE_MODES_MON.eq."True") then   
           z->sam_pc_mon = sam_pc_mon
           z->psa1_pc_mon = psa1_pc_mon
           z->psa2_pc_mon = psa2_pc_mon
           z->sam_mon = sam_mon
           z->psa1_mon = psa1_mon
           z->psa2_mon = psa2_mon
        end if
        delete(z)
        delete([/modname,fn/])

        if (sstreg_plot_flag.eq.0) then
           modname = str_sub_str(names_ts(ee)," ","_")
           bc = (/"/","'","(",")"/)
           do gg = 0,dimsizes(bc)-1
              modname = str_sub_str(modname,bc(gg),"_")
           end do
           fn = getenv("OUTDIR")+modname+".cvdp_data.psl.sam_psa.ts."+syear_ts(ee)+"-"+eyear_ts(ee)+".nc"
           if (.not.isfilepresent2(fn)) then
              z = addfile(fn,"c")
              z@source = "NCAR Climate Analysis Section's Climate Variability Diagnostics Package v"+getenv("VERSION")
              z@notes = "Data from "+names_ts(ee)+" from "+syear_ts(ee)+"-"+eyear_ts(ee)
              if (OPT_CLIMO.eq."Full") then
                 z@climatology = syear_ts(ee)+"-"+eyear_ts(ee)+" climatology removed prior to all calculations (other than means)"
              else
                 z@climatology = CLIMO_SYEAR+"-"+CLIMO_EYEAR+" climatology removed prior to all calculations (other than means)"
              end if
           else
              z = addfile(fn,"w")
           end if
           z->sam_sst_regression_djf = sam_sst_djf
           z->sam_sst_regression_mam = sam_sst_mam
           z->sam_sst_regression_jja = sam_sst_jja
           z->sam_sst_regression_son = sam_sst_son
           z->sam_sst_regression_ann = sam_sst_ann
        
           z->psa1_sst_regression_djf = psa1_sst_djf
           z->psa1_sst_regression_mam = psa1_sst_mam
           z->psa1_sst_regression_jja = psa1_sst_jja
           z->psa1_sst_regression_son = psa1_sst_son
           z->psa1_sst_regression_ann = psa1_sst_ann
        
           z->psa2_sst_regression_djf = psa2_sst_djf
           z->psa2_sst_regression_mam = psa2_sst_mam
           z->psa2_sst_regression_jja = psa2_sst_jja
           z->psa2_sst_regression_son = psa2_sst_son
           z->psa2_sst_regression_ann = psa2_sst_ann
           if (COMPUTE_MODES_MON.eq."True") then   
              z->sam_sst_regression_mon = sam_sst_mon
              z->psa1_sst_regression_mon = psa1_sst_mon
              z->psa2_sst_regression_mon = psa2_sst_mon
           end if
           delete(z)
           delete([/modname,fn/])
        end if
     end if     
;========================================================================
     res = True
     res@mpGeophysicalLineColor = "gray42"
     res@mpGeophysicalLineThicknessF = 2.     
     res@mpGridAndLimbOn = False
     res@mpFillOn = False
     res@mpOutlineOn = True  
     res@mpDataSetName = "Earth..4"
     res@gsnDraw      = False
     res@gsnFrame     = False
     res@cnLevelSelectionMode = "ExplicitLevels"
     res@cnLineLabelsOn = False
     res@cnFillOn        = True
     res@cnLinesOn       = False
     res@lbLabelBarOn    = False

     res@gsnLeftStringOrthogonalPosF = -0.03
     res@gsnLeftStringParallelPosF = .005
     res@gsnRightStringOrthogonalPosF = -0.03
     res@gsnRightStringParallelPosF = 0.96
     res@gsnRightString = ""
     res@gsnLeftString = ""
     if (nsim.le.5) then
        res@gsnLeftStringFontHeightF = 0.018
        res@gsnCenterStringFontHeightF = 0.022
        res@gsnRightStringFontHeightF = 0.018
     else
        res@gsnLeftStringFontHeightF = 0.024
        res@gsnCenterStringFontHeightF = 0.028
        res@gsnRightStringFontHeightF = 0.024     
     end if
     res@gsnPolar = "NH"     
     res@mpMinLatF    = 20.
     res@mpCenterLonF = 0.
     
     res@cnLevels = (/-7,-6,-5,-4,-3,-2,-1,0,1,2,3,4,5,6,7./)
     res@gsnLeftString = syear(ee)+"-"+eyear(ee)
     res@gsnCenterString = names(ee)
     
     if (isfilepresent2("obs_psl").and.ee.eq.0) then    ; for pattern correlation table. Save entire lat/lon array
        patcor_sam_djf = new((/nsim,dimsizes(sam_djf&lat),dimsizes(sam_djf&lon)/),typeof(sam_djf))
        patcor_sam_djf!1 = "lat"
        patcor_sam_djf&lat = sam_djf&lat
        patcor_sam_djf!2 = "lon"
        patcor_sam_djf&lon = sam_djf&lon
        patcor_sam_jja = patcor_sam_djf
        patcor_sam_ann = patcor_sam_djf
        patcor_psa1_djf = patcor_sam_djf
        patcor_psa1_jja = patcor_sam_djf
        patcor_psa1_ann = patcor_sam_djf
        patcor_psa2_djf = patcor_sam_djf
        patcor_psa2_jja = patcor_sam_djf
        patcor_psa2_ann = patcor_sam_djf
        patcor_sam_djf(ee,:,:) = (/ sam_djf /)
        patcor_sam_jja(ee,:,:) = (/ sam_jja /)
        patcor_sam_ann(ee,:,:) = (/ sam_ann /)
        patcor_psa1_djf(ee,:,:) = (/ psa1_djf /)
        patcor_psa1_jja(ee,:,:) = (/ psa1_jja /)
        patcor_psa1_ann(ee,:,:) = (/ psa1_ann /)
        patcor_psa2_djf(ee,:,:) = (/ psa2_djf /)
        patcor_psa2_jja(ee,:,:) = (/ psa2_jja /)
        patcor_psa2_ann(ee,:,:) = (/ psa2_ann /)
     end if
     if (isfilepresent2("obs_psl").and.ee.ge.1) then       
        patcor_sam_djf(ee,:,:) = (/ linint2(sam_djf&lon,sam_djf&lat,sam_djf,True,patcor_sam_djf&lon,patcor_sam_djf&lat,0) /)
        patcor_sam_jja(ee,:,:) = (/ linint2(sam_jja&lon,sam_jja&lat,sam_jja,True,patcor_sam_jja&lon,patcor_sam_jja&lat,0) /)
        patcor_sam_ann(ee,:,:) = (/ linint2(sam_ann&lon,sam_ann&lat,sam_ann,True,patcor_sam_ann&lon,patcor_sam_ann&lat,0) /)
        
        patcor_psa1_djf(ee,:,:) = (/ linint2(psa1_djf&lon,psa1_djf&lat,psa1_djf,True,patcor_psa1_djf&lon,patcor_psa1_djf&lat,0) /)
        patcor_psa1_jja(ee,:,:) = (/ linint2(psa1_jja&lon,psa1_jja&lat,psa1_jja,True,patcor_psa1_jja&lon,patcor_psa1_jja&lat,0) /)
        patcor_psa1_ann(ee,:,:) = (/ linint2(psa1_ann&lon,psa1_ann&lat,psa1_ann,True,patcor_psa1_ann&lon,patcor_psa1_ann&lat,0) /)
        
        patcor_psa2_djf(ee,:,:) = (/ linint2(psa2_djf&lon,psa2_djf&lat,psa2_djf,True,patcor_psa2_djf&lon,patcor_psa2_djf&lat,0) /)
        patcor_psa2_jja(ee,:,:) = (/ linint2(psa2_jja&lon,psa2_jja&lat,psa2_jja,True,patcor_psa2_jja&lon,patcor_psa2_jja&lat,0) /)
        patcor_psa2_ann(ee,:,:) = (/ linint2(psa2_ann&lon,psa2_ann&lat,psa2_ann,True,patcor_psa2_ann&lon,patcor_psa2_ann&lat,0) /)
     end if
     
     res@gsnPolar = "SH"     
     delete(res@mpMinLatF)
     res@mpMaxLatF    = -20.
     res@mpCenterLonF = 0.
     res@gsnLeftString = syear(ee)+"-"+eyear(ee)
     res@gsnCenterString = names(ee)
     res@gsnRightString = sam_djf@pcvar
     map_sam_djf(ee) = gsn_csm_contour_map_polar(wks_sam,sam_djf,res)
     res@gsnRightString = sam_mam@pcvar
     map_sam_mam(ee) = gsn_csm_contour_map_polar(wks_sam,sam_mam,res)
     res@gsnRightString = sam_jja@pcvar
     map_sam_jja(ee) = gsn_csm_contour_map_polar(wks_sam,sam_jja,res)
     res@gsnRightString = sam_son@pcvar
     map_sam_son(ee) = gsn_csm_contour_map_polar(wks_sam,sam_son,res)
     res@gsnRightString = sam_ann@pcvar
     map_sam_ann(ee) = gsn_csm_contour_map_polar(wks_sam,sam_ann,res)     
     delete([/sam_djf,sam_mam,sam_jja,sam_son,sam_ann/])
     if (COMPUTE_MODES_MON.eq."True") then                    
        res@gsnRightString = sam_mon@pcvar
        map_sam_mon(ee) = gsn_csm_contour_map_polar(wks_sam,sam_mon,res)
        delete([/sam_mon/])
     end if
     
     res@cnLevels = (/-4,-3,-2.5,-2,-1.5,-1,-0.5,0,0.5,1,1.5,2,2.5,3,4/)
     res@gsnRightString = psa1_djf@pcvar
     map_psa1_djf(ee) = gsn_csm_contour_map_polar(wks_psa1,psa1_djf,res)
     res@gsnRightString = psa1_mam@pcvar
     map_psa1_mam(ee) = gsn_csm_contour_map_polar(wks_psa1,psa1_mam,res)
     res@gsnRightString = psa1_jja@pcvar
     map_psa1_jja(ee) = gsn_csm_contour_map_polar(wks_psa1,psa1_jja,res)
     res@gsnRightString = psa1_son@pcvar
     map_psa1_son(ee) = gsn_csm_contour_map_polar(wks_psa1,psa1_son,res)
     res@gsnRightString = psa1_ann@pcvar
     map_psa1_ann(ee) = gsn_csm_contour_map_polar(wks_psa1,psa1_ann,res)     
     delete([/psa1_djf,psa1_mam,psa1_jja,psa1_son,psa1_ann/])
     if (COMPUTE_MODES_MON.eq."True") then                    
        res@gsnRightString = psa1_mon@pcvar
        map_psa1_mon(ee) = gsn_csm_contour_map_polar(wks_psa1,psa1_mon,res)
        delete([/psa1_mon/])
     end if
     
     res@gsnRightString = psa2_djf@pcvar
     map_psa2_djf(ee) = gsn_csm_contour_map_polar(wks_psa2,psa2_djf,res)
     res@gsnRightString = psa2_mam@pcvar
     map_psa2_mam(ee) = gsn_csm_contour_map_polar(wks_psa2,psa2_mam,res)
     res@gsnRightString = psa2_jja@pcvar
     map_psa2_jja(ee) = gsn_csm_contour_map_polar(wks_psa2,psa2_jja,res)
     res@gsnRightString = psa2_son@pcvar
     map_psa2_son(ee) = gsn_csm_contour_map_polar(wks_psa2,psa2_son,res)
     res@gsnRightString = psa2_ann@pcvar
     map_psa2_ann(ee) = gsn_csm_contour_map_polar(wks_psa2,psa2_ann,res)     
     delete([/psa2_djf,psa2_mam,psa2_jja,psa2_son,psa2_ann/])
     if (COMPUTE_MODES_MON.eq."True") then                    
        res@gsnRightString = psa2_mon@pcvar
        map_psa2_mon(ee) = gsn_csm_contour_map_polar(wks_psa2,psa2_mon,res)
        delete([/psa2_mon/])
     end if
     
     if (sstreg_plot_flag.eq.0) then
        res@cnLevels = fspan(-1.05,1.05,15)
        res@gsnRightString = ""
        reg_sam_djf(ee) = gsn_csm_contour_map_polar(wks_sam,sam_sst_djf,res)
        reg_sam_mam(ee) = gsn_csm_contour_map_polar(wks_sam,sam_sst_mam,res)
        reg_sam_jja(ee) = gsn_csm_contour_map_polar(wks_sam,sam_sst_jja,res)
        reg_sam_son(ee) = gsn_csm_contour_map_polar(wks_sam,sam_sst_son,res)
        reg_sam_ann(ee) = gsn_csm_contour_map_polar(wks_sam,sam_sst_ann,res)     
        delete([/sam_sst_djf,sam_sst_mam,sam_sst_jja,sam_sst_son,sam_sst_ann/])
        if (COMPUTE_MODES_MON.eq."True") then                    
           reg_sam_mon(ee) = gsn_csm_contour_map_polar(wks_sam,sam_sst_mon,res)
           delete([/sam_sst_mon/])
        end if
     
        reg_psa1_djf(ee) = gsn_csm_contour_map_polar(wks_psa1,psa1_sst_djf,res)
        reg_psa1_mam(ee) = gsn_csm_contour_map_polar(wks_psa1,psa1_sst_mam,res)
        reg_psa1_jja(ee) = gsn_csm_contour_map_polar(wks_psa1,psa1_sst_jja,res)
        reg_psa1_son(ee) = gsn_csm_contour_map_polar(wks_psa1,psa1_sst_son,res)
        reg_psa1_ann(ee) = gsn_csm_contour_map_polar(wks_psa1,psa1_sst_ann,res)     
        delete([/psa1_sst_djf,psa1_sst_mam,psa1_sst_jja,psa1_sst_son,psa1_sst_ann/])
        if (COMPUTE_MODES_MON.eq."True") then                    
           reg_psa1_mon(ee) = gsn_csm_contour_map_polar(wks_psa1,psa1_sst_mon,res)
           delete([/psa1_sst_mon/])
        end if
     
        reg_psa2_djf(ee) = gsn_csm_contour_map_polar(wks_psa2,psa2_sst_djf,res)
        reg_psa2_mam(ee) = gsn_csm_contour_map_polar(wks_psa2,psa2_sst_mam,res)
        reg_psa2_jja(ee) = gsn_csm_contour_map_polar(wks_psa2,psa2_sst_jja,res)
        reg_psa2_son(ee) = gsn_csm_contour_map_polar(wks_psa2,psa2_sst_son,res)
        reg_psa2_ann(ee) = gsn_csm_contour_map_polar(wks_psa2,psa2_sst_ann,res)     
        delete([/psa2_sst_djf,psa2_sst_mam,psa2_sst_jja,psa2_sst_son,psa2_sst_ann/])
        if (COMPUTE_MODES_MON.eq."True") then                    
           reg_psa2_mon(ee) = gsn_csm_contour_map_polar(wks_psa2,psa2_sst_mon,res)
           delete([/psa2_sst_mon/])
        end if
     end if
     delete(res@mpMaxLatF)

     xyres = True
     xyres@gsnDraw = False
     xyres@gsnFrame = False
     xyres@gsnXYBarChart = False
     xyres@gsnYRefLine = 0.0
     xyres@gsnYRefLineColor = "gray42"
     xyres@gsnAboveYRefLineColor = 185
     xyres@gsnBelowYRefLineColor = 35
     if (wks_type.eq."png") then  
        xyres@xyLineThicknessF = .5
     else
        xyres@xyLineThicknessF = .2
     end if
     xyres@xyLineColor = "gray52"
     xyres@tiYAxisString = ""
     xyres@tiXAxisString = ""
     if (nsim.le.5) then
        xyres@tmXBLabelFontHeightF = 0.0125
        xyres@tmYLLabelFontHeightF = 0.0125
        xyres@gsnStringFontHeightF = 0.017     
     else
        xyres@tmXBLabelFontHeightF = 0.018
        xyres@tmYLLabelFontHeightF = 0.018
        xyres@gsnStringFontHeightF = 0.024
     end if

     xyres@vpXF = 0.05
     xyres@vpHeightF = 0.15
     if (SCALE_TIMESERIES.eq."True") then
        xyres@vpWidthF = 0.9*((nyr(ee)*1.)/nyr_max)
     else
        xyres@vpWidthF = 0.9
     end if
     xyres@gsnLeftString = ""
     xyres@gsnRightString = ""
     xyres@trXMinF = syear(ee)-.5
     xyres@trXMaxF = eyear(ee)+1.5

     xyres@gsnCenterString = names(ee)
     
     xyresmon = xyres
     xyresmon@gsnXYBarChart = False            
     xyresmon@xyLineThicknessF = .1 

     xy_sam_djf(ee) = gsn_csm_xy(wks_sam_ts,fspan(syear(ee),eyear(ee),dimsizes(sam_pc_djf)),sam_pc_djf,xyres)   ; use standardized timeseries  
     xy_sam_mam(ee) = gsn_csm_xy(wks_sam_ts,fspan(syear(ee),eyear(ee),dimsizes(sam_pc_mam)),sam_pc_mam,xyres)   ; use standardized timeseries  
     xy_sam_jja(ee) = gsn_csm_xy(wks_sam_ts,fspan(syear(ee),eyear(ee),dimsizes(sam_pc_jja)),sam_pc_jja,xyres)   ; use standardized timeseries  
     xy_sam_son(ee) = gsn_csm_xy(wks_sam_ts,fspan(syear(ee),eyear(ee),dimsizes(sam_pc_son)),sam_pc_son,xyres)   ; use standardized timeseries  
     xy_sam_ann(ee) = gsn_csm_xy(wks_sam_ts,fspan(syear(ee),eyear(ee),dimsizes(sam_pc_ann)),sam_pc_ann,xyres)   ; use standardized timeseries  
     delete([/sam_pc_djf,sam_pc_mam,sam_pc_jja,sam_pc_son,sam_pc_ann/])
     if (COMPUTE_MODES_MON.eq."True") then   
        xy_sam_mon(ee) = gsn_csm_xy(wks_sam_ts,fspan(syear(ee),eyear(ee)+.91667,dimsizes(sam_pc_mon)),sam_pc_mon,xyresmon)   ; use standardized timeseries  
        delete([/sam_pc_mon/])
     end if

     xy_psa1_djf(ee) = gsn_csm_xy(wks_psa1_ts,fspan(syear(ee),eyear(ee),dimsizes(psa1_pc_djf)),psa1_pc_djf,xyres)   ; use standardized timeseries  
     xy_psa1_mam(ee) = gsn_csm_xy(wks_psa1_ts,fspan(syear(ee),eyear(ee),dimsizes(psa1_pc_mam)),psa1_pc_mam,xyres)   ; use standardized timeseries  
     xy_psa1_jja(ee) = gsn_csm_xy(wks_psa1_ts,fspan(syear(ee),eyear(ee),dimsizes(psa1_pc_jja)),psa1_pc_jja,xyres)   ; use standardized timeseries  
     xy_psa1_son(ee) = gsn_csm_xy(wks_psa1_ts,fspan(syear(ee),eyear(ee),dimsizes(psa1_pc_son)),psa1_pc_son,xyres)   ; use standardized timeseries  
     xy_psa1_ann(ee) = gsn_csm_xy(wks_psa1_ts,fspan(syear(ee),eyear(ee),dimsizes(psa1_pc_ann)),psa1_pc_ann,xyres)   ; use standardized timeseries  
     delete([/psa1_pc_djf,psa1_pc_mam,psa1_pc_jja,psa1_pc_son,psa1_pc_ann/])
     if (COMPUTE_MODES_MON.eq."True") then   
        xy_psa1_mon(ee) = gsn_csm_xy(wks_psa1_ts,fspan(syear(ee),eyear(ee)+.91667,dimsizes(psa1_pc_mon)),psa1_pc_mon,xyresmon)   ; use standardized timeseries  
        delete([/psa1_pc_mon/])
     end if

     xy_psa2_djf(ee) = gsn_csm_xy(wks_psa2_ts,fspan(syear(ee),eyear(ee),dimsizes(psa2_pc_djf)),psa2_pc_djf,xyres)   ; use standardized timeseries  
     xy_psa2_mam(ee) = gsn_csm_xy(wks_psa2_ts,fspan(syear(ee),eyear(ee),dimsizes(psa2_pc_mam)),psa2_pc_mam,xyres)   ; use standardized timeseries  
     xy_psa2_jja(ee) = gsn_csm_xy(wks_psa2_ts,fspan(syear(ee),eyear(ee),dimsizes(psa2_pc_jja)),psa2_pc_jja,xyres)   ; use standardized timeseries  
     xy_psa2_son(ee) = gsn_csm_xy(wks_psa2_ts,fspan(syear(ee),eyear(ee),dimsizes(psa2_pc_son)),psa2_pc_son,xyres)   ; use standardized timeseries  
     xy_psa2_ann(ee) = gsn_csm_xy(wks_psa2_ts,fspan(syear(ee),eyear(ee),dimsizes(psa2_pc_ann)),psa2_pc_ann,xyres)   ; use standardized timeseries  
     delete([/psa2_pc_djf,psa2_pc_mam,psa2_pc_jja,psa2_pc_son,psa2_pc_ann/])
     if (COMPUTE_MODES_MON.eq."True") then          
        xy_psa2_mon(ee) = gsn_csm_xy(wks_psa2_ts,fspan(syear(ee),eyear(ee)+.91667,dimsizes(psa2_pc_mon)),psa2_pc_mon,xyresmon)   ; use standardized timeseries  
        delete([/psa2_pc_mon/])
     end if 

     delete(sstreg_plot_flag)  
  end do
  
  if (isvar("clim_syear")) then
     delete(clim_syear)
  end if
  if (isvar("clim_eyear")) then
     delete(clim_eyear)
  end if
  
  if (isfilepresent2("obs_psl")) then    ; for pattern correlation table  
     clat = cos(0.01745329*patcor_sam_djf&lat)
     clat!0 = "lat"
     clat&lat = patcor_sam_djf&lat
     line3   = "                  "    ; Must be 18 characters long
     line4   = line3
     header = (/"","Pattern Correlations   Observations vs. Model(s)",""/)
     finpr_sam_djf  = "SAM (DJF)         "     
     do hh = 1,nsim-1
        dimY = dimsizes(tochar(names(hh)))
        nchar = dimY
        nchar = where(nchar.le.10,10,nchar)
        if (dimY.lt.10) then
           ntb = ""
           do ii = 0,10-dimY-1
              ntb = ntb+" "
           end do
           ntb = ntb+names(hh)
        else
           ntb = names(hh)
        end if
        
        ntc = ""
        do ii = 0,nchar-1
           ntc = ntc+"-"
        end do
        format2 = "%"+(nchar-5+1)+".2f"
        format3 = "%4.2f"
        line3 = line3+" "+ntb   
        line4 = line4+" "+ntc 
        if (all(ismissing(patcor_sam_djf(hh,{:-20},:)))) then
           finpr_sam_djf = finpr_sam_djf+sprintf(format2,9.99)+"/"+sprintf(format3,9.99)
        else
           finpr_sam_djf = finpr_sam_djf+sprintf(format2,(pattern_cor(patcor_sam_djf(0,{:-20},:),patcor_sam_djf(hh,{:-20},:),clat({:-20}),0)))+"/"+sprintf(format3,(dim_rmsd(ndtooned(NewCosWeight(patcor_sam_djf(0,{:-20},:))),ndtooned(NewCosWeight(patcor_sam_djf(hh,{:-20},:))))))
        end if        
     end do
;     
     if (dimsizes(tochar(line4)).ge.8190) then   ; system or fortran compiler limit
        print("Metrics table warning: Not creating metrics table as size of comparison results in a invalid ascii row size.")   
     else           
        write_table(getenv("OUTDIR")+"metrics.psl.sam_psa.txt","w",[/header/],"%s")
        write_table(getenv("OUTDIR")+"metrics.psl.sam_psa.txt","a",[/line3/],"%s")
        write_table(getenv("OUTDIR")+"metrics.psl.sam_psa.txt","a",[/line4/],"%s")  
        write_table(getenv("OUTDIR")+"metrics.psl.sam_psa.txt","a",[/finpr_sam_djf/],"%s")
     end if
     delete([/line3,line4,format2,format3,nchar,ntc,clat,patcor_sam_djf,patcor_sam_jja,patcor_sam_ann/])
     delete([/patcor_psa1_djf,patcor_psa1_jja,patcor_psa1_ann,patcor_psa2_djf,patcor_psa2_jja,patcor_psa2_ann,dimY,ntb,header/])
  end if 

  panres = True
  panres@gsnMaximize = True
  panres@gsnPaperOrientation = "portrait"
  panres@gsnPanelLabelBar = True
  panres@gsnPanelYWhiteSpacePercent = 3.0
  panres@pmLabelBarHeightF = 0.05
  panres@pmLabelBarWidthF = 0.55
  panres@lbTitleOn = False
  panres@lbBoxLineColor = "gray70"
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
  ncol = floattointeger(sqrt(nsim))
  nrow = (nsim/ncol)+mod(nsim,ncol) 
  
  panres@txString = "SAM (DJF)" 
  gsn_panel2(wks_sam,map_sam_djf,(/nrow,ncol/),panres)
  delete(map_sam_djf)
  panres@txString = "SAM (MAM)"
  gsn_panel2(wks_sam,map_sam_mam,(/nrow,ncol/),panres)
  delete(map_sam_mam)
  panres@txString = "SAM (JJA)"
  gsn_panel2(wks_sam,map_sam_jja,(/nrow,ncol/),panres)
  delete(map_sam_jja)
  panres@txString = "SAM (SON)"
  gsn_panel2(wks_sam,map_sam_son,(/nrow,ncol/),panres)
  delete(map_sam_son)
  panres@txString = "SAM (Annual)"
  gsn_panel2(wks_sam,map_sam_ann,(/nrow,ncol/),panres)
  delete(map_sam_ann)
  if (COMPUTE_MODES_MON.eq."True") then    
     panres@txString = "SAM (Monthly)"
     gsn_panel2(wks_sam,map_sam_mon,(/nrow,ncol/),panres)
     delete(map_sam_mon)
  end if
  
  if (sstreg_frame.eq.0) then
     panres@txString = "SAM SST Regressions (DJF)" 
     gsn_panel2(wks_sam,reg_sam_djf,(/nrow,ncol/),panres)
     delete(reg_sam_djf)
     panres@txString = "SAM SST Regressions (MAM)"
     gsn_panel2(wks_sam,reg_sam_mam,(/nrow,ncol/),panres)
     delete(reg_sam_mam)
     panres@txString = "SAM SST Regressions (JJA)"
     gsn_panel2(wks_sam,reg_sam_jja,(/nrow,ncol/),panres)
     delete(reg_sam_jja)
     panres@txString = "SAM SST Regressions (SON)"
     gsn_panel2(wks_sam,reg_sam_son,(/nrow,ncol/),panres)
     delete(reg_sam_son)
     panres@txString = "SAM SST Regressions (Annual)"
     gsn_panel2(wks_sam,reg_sam_ann,(/nrow,ncol/),panres)
     delete(reg_sam_ann)
     if (COMPUTE_MODES_MON.eq."True") then    
        panres@txString = "SAM SST Regressions (Monthly)"
        gsn_panel2(wks_sam,reg_sam_mon,(/nrow,ncol/),panres)
        delete(reg_sam_mon)
     end if
     delete(wks_sam)
  end if
  
  panres@txString = "PSA1 (DJF)" 
  gsn_panel2(wks_psa1,map_psa1_djf,(/nrow,ncol/),panres)
  delete(map_psa1_djf)
  panres@txString = "PSA1 (MAM)"
  gsn_panel2(wks_psa1,map_psa1_mam,(/nrow,ncol/),panres)
  delete(map_psa1_mam)
  panres@txString = "PSA1 (JJA)"
  gsn_panel2(wks_psa1,map_psa1_jja,(/nrow,ncol/),panres)
  delete(map_psa1_jja)
  panres@txString = "PSA1 (SON)"
  gsn_panel2(wks_psa1,map_psa1_son,(/nrow,ncol/),panres)
  delete(map_psa1_son)
  panres@txString = "PSA1 (Annual)"
  gsn_panel2(wks_psa1,map_psa1_ann,(/nrow,ncol/),panres)
  delete(map_psa1_ann)
  if (COMPUTE_MODES_MON.eq."True") then    
     panres@txString = "PSA1 (Monthly)"
     gsn_panel2(wks_psa1,map_psa1_mon,(/nrow,ncol/),panres)
     delete(map_psa1_mon)
  end if
  
  if (sstreg_frame.eq.0) then
     panres@txString = "PSA1 SST Regressions (DJF)" 
     gsn_panel2(wks_psa1,reg_psa1_djf,(/nrow,ncol/),panres)
     delete(reg_psa1_djf)
     panres@txString = "PSA1 SST Regressions (MAM)"
     gsn_panel2(wks_psa1,reg_psa1_mam,(/nrow,ncol/),panres)
     delete(reg_psa1_mam)
     panres@txString = "PSA1 SST Regressions (JJA)"
     gsn_panel2(wks_psa1,reg_psa1_jja,(/nrow,ncol/),panres)
     delete(reg_psa1_jja)
     panres@txString = "PSA1 SST Regressions (SON)"
     gsn_panel2(wks_psa1,reg_psa1_son,(/nrow,ncol/),panres)
     delete(reg_psa1_son)
     panres@txString = "PSA1 SST Regressions (Annual)"
     gsn_panel2(wks_psa1,reg_psa1_ann,(/nrow,ncol/),panres)
     delete(reg_psa1_ann)
     if (COMPUTE_MODES_MON.eq."True") then    
        panres@txString = "PSA1 SST Regressions (Monthly)"
        gsn_panel2(wks_psa1,reg_psa1_mon,(/nrow,ncol/),panres)
        delete(reg_psa1_mon)
     end if
     delete(wks_psa1)
  end if
  
  panres@txString = "PSA2 (DJF)" 
  gsn_panel2(wks_psa2,map_psa2_djf,(/nrow,ncol/),panres)
  delete(map_psa2_djf)
  panres@txString = "PSA2 (MAM)"
  gsn_panel2(wks_psa2,map_psa2_mam,(/nrow,ncol/),panres)
  delete(map_psa2_mam)
  panres@txString = "PSA2 (JJA)"
  gsn_panel2(wks_psa2,map_psa2_jja,(/nrow,ncol/),panres)
  delete(map_psa2_jja)
  panres@txString = "PSA2 (SON)"
  gsn_panel2(wks_psa2,map_psa2_son,(/nrow,ncol/),panres)
  delete(map_psa2_son)
  panres@txString = "PSA2 (Annual)"
  gsn_panel2(wks_psa2,map_psa2_ann,(/nrow,ncol/),panres)
  delete(map_psa2_ann)
  if (COMPUTE_MODES_MON.eq."True") then    
     panres@txString = "PSA2 (Monthly)"
     gsn_panel2(wks_psa2,map_psa2_mon,(/nrow,ncol/),panres)
     delete(map_psa2_mon)
  end if
  
  if (sstreg_frame.eq.0) then
     panres@txString = "PSA2 SST Regressions (DJF)" 
     gsn_panel2(wks_psa2,reg_psa2_djf,(/nrow,ncol/),panres)
     delete(reg_psa2_djf)
     panres@txString = "PSA2 SST Regressions (MAM)"
     gsn_panel2(wks_psa2,reg_psa2_mam,(/nrow,ncol/),panres)
     delete(reg_psa2_mam)
     panres@txString = "PSA2 SST Regressions (JJA)"
     gsn_panel2(wks_psa2,reg_psa2_jja,(/nrow,ncol/),panres)
     delete(reg_psa2_jja)
     panres@txString = "PSA2 SST Regressions (SON)"
     gsn_panel2(wks_psa2,reg_psa2_son,(/nrow,ncol/),panres)
     delete(reg_psa2_son)
     panres@txString = "PSA2 SST Regressions (Annual)"
     gsn_panel2(wks_psa2,reg_psa2_ann,(/nrow,ncol/),panres)
     delete(reg_psa2_ann)
     if (COMPUTE_MODES_MON.eq."True") then    
        panres@txString = "PSA2 SST Regressions (Monthly)"
        gsn_panel2(wks_psa2,reg_psa2_mon,(/nrow,ncol/),panres)
        delete(reg_psa2_mon)
     end if
     delete(wks_psa2)
  end if

  panres2 = True    
  if (nsim.le.5) then
     panres2@txFontHeightF = 0.024
  else
     panres2@txFontHeightF = 0.016
  end if  
  panres2@gsnMaximize = True
  panres2@gsnPaperOrientation = "portrait"
  if (SCALE_TIMESERIES.eq."True") then
     tt = ind(nyr.eq.nyr_max)
     panres2@gsnPanelScalePlotIndex = tt(0)
     delete(tt)  
  end if  
  if (nsim.le.12) then
     lp = (/nsim,1/)
  else
     lp = (/nrow,ncol/)  
  end if
  panres2@txString = "SAM (DJF)"
  gsn_panel2(wks_sam_ts,xy_sam_djf,lp,panres2)  
  delete(xy_sam_djf)
  panres2@txString = "SAM (MAM)"
  gsn_panel2(wks_sam_ts,xy_sam_mam,lp,panres2)  
  delete(xy_sam_mam)
  panres2@txString = "SAM (JJA)"
  gsn_panel2(wks_sam_ts,xy_sam_jja,lp,panres2)  
  delete(xy_sam_jja)
  panres2@txString = "SAM (SON)"
  gsn_panel2(wks_sam_ts,xy_sam_son,lp,panres2)  
  delete(xy_sam_son)
  panres2@txString = "SAM (Annual)"
  gsn_panel2(wks_sam_ts,xy_sam_ann,lp,panres2)  
  delete(xy_sam_ann)
  if (COMPUTE_MODES_MON.eq."True") then  
     panres2@txString = "SAM (Monthly)"
     gsn_panel2(wks_sam_ts,xy_sam_mon,lp,panres2)  
     delete(xy_sam_mon) 
  end if
  delete(wks_sam_ts)
    
  panres2@txString = "PSA1 (DJF)"
  gsn_panel2(wks_psa1_ts,xy_psa1_djf,lp,panres2)  
  delete(xy_psa1_djf)
  panres2@txString = "PSA1 (MAM)"
  gsn_panel2(wks_psa1_ts,xy_psa1_mam,lp,panres2)  
  delete(xy_psa1_mam)
  panres2@txString = "PSA1 (JJA)"
  gsn_panel2(wks_psa1_ts,xy_psa1_jja,lp,panres2)  
  delete(xy_psa1_jja)
  panres2@txString = "PSA1 (SON)"
  gsn_panel2(wks_psa1_ts,xy_psa1_son,lp,panres2)  
  delete(xy_psa1_son)
  panres2@txString = "PSA1 (Annual)"
  gsn_panel2(wks_psa1_ts,xy_psa1_ann,lp,panres2)  
  delete(xy_psa1_ann)
  if (COMPUTE_MODES_MON.eq."True") then  
     panres2@txString = "PSA1 (Monthly)"
     gsn_panel2(wks_psa1_ts,xy_psa1_mon,lp,panres2)  
     delete(xy_psa1_mon) 
  end if
  delete(wks_psa1_ts)
  
  panres2@txString = "PSA2 (DJF)"
  gsn_panel2(wks_psa2_ts,xy_psa2_djf,lp,panres2)  
  delete(xy_psa2_djf)
  panres2@txString = "PSA2 (MAM)"
  gsn_panel2(wks_psa2_ts,xy_psa2_mam,lp,panres2)  
  delete(xy_psa2_mam)
  panres2@txString = "PSA2 (JJA)"
  gsn_panel2(wks_psa2_ts,xy_psa2_jja,lp,panres2)  
  delete(xy_psa2_jja)
  panres2@txString = "PSA2 (SON)"
  gsn_panel2(wks_psa2_ts,xy_psa2_son,lp,panres2)  
  delete(xy_psa2_son)
  panres2@txString = "PSA2 (Annual)"
  gsn_panel2(wks_psa2_ts,xy_psa2_ann,lp,panres2)  
  delete(xy_psa2_ann)
  if (COMPUTE_MODES_MON.eq."True") then  
     panres2@txString = "PSA2 (Monthly)"
     gsn_panel2(wks_psa2_ts,xy_psa2_mon,lp,panres2)  
     delete(xy_psa2_mon) 
  end if
  delete(wks_psa2_ts)  
;--------------------------------------------------------------------------------------------------
  OUTDIR = getenv("OUTDIR") 
  if (wks_type.eq."png") then       
     system("mv "+OUTDIR+"sam.000001.png "+OUTDIR+"sam.djf.png") 
     system("mv "+OUTDIR+"sam.000002.png "+OUTDIR+"sam.mam.png") 
     system("mv "+OUTDIR+"sam.000003.png "+OUTDIR+"sam.jja.png") 
     system("mv "+OUTDIR+"sam.000004.png "+OUTDIR+"sam.son.png") 
     system("mv "+OUTDIR+"sam.000005.png "+OUTDIR+"sam.ann.png")
     if (COMPUTE_MODES_MON.eq."True") then     
        system("mv "+OUTDIR+"sam.000006.png "+OUTDIR+"sam.mon.png")  
        if (sstreg_frame.eq.0) then
           system("mv "+OUTDIR+"sam.000007.png "+OUTDIR+"sam.sstreg.djf.png") 
           system("mv "+OUTDIR+"sam.000008.png "+OUTDIR+"sam.sstreg.mam.png") 
           system("mv "+OUTDIR+"sam.000009.png "+OUTDIR+"sam.sstreg.jja.png") 
           system("mv "+OUTDIR+"sam.000010.png "+OUTDIR+"sam.sstreg.son.png") 
           system("mv "+OUTDIR+"sam.000011.png "+OUTDIR+"sam.sstreg.ann.png")
           system("mv "+OUTDIR+"sam.000012.png "+OUTDIR+"sam.sstreg.mon.png")     
        end if
     else
        if (sstreg_frame.eq.0) then
           system("mv "+OUTDIR+"sam.000006.png "+OUTDIR+"sam.sstreg.djf.png") 
           system("mv "+OUTDIR+"sam.000007.png "+OUTDIR+"sam.sstreg.mam.png") 
           system("mv "+OUTDIR+"sam.000008.png "+OUTDIR+"sam.sstreg.jja.png") 
           system("mv "+OUTDIR+"sam.000009.png "+OUTDIR+"sam.sstreg.son.png") 
           system("mv "+OUTDIR+"sam.000010.png "+OUTDIR+"sam.sstreg.ann.png")
        end if
     end if
     
     system("mv "+OUTDIR+"psa1.000001.png "+OUTDIR+"psa1.djf.png") 
     system("mv "+OUTDIR+"psa1.000002.png "+OUTDIR+"psa1.mam.png") 
     system("mv "+OUTDIR+"psa1.000003.png "+OUTDIR+"psa1.jja.png") 
     system("mv "+OUTDIR+"psa1.000004.png "+OUTDIR+"psa1.son.png") 
     system("mv "+OUTDIR+"psa1.000005.png "+OUTDIR+"psa1.ann.png")
     if (COMPUTE_MODES_MON.eq."True") then     
        system("mv "+OUTDIR+"psa1.000006.png "+OUTDIR+"psa1.mon.png")  
        if (sstreg_frame.eq.0) then
           system("mv "+OUTDIR+"psa1.000007.png "+OUTDIR+"psa1.sstreg.djf.png") 
           system("mv "+OUTDIR+"psa1.000008.png "+OUTDIR+"psa1.sstreg.mam.png") 
           system("mv "+OUTDIR+"psa1.000009.png "+OUTDIR+"psa1.sstreg.jja.png") 
           system("mv "+OUTDIR+"psa1.000010.png "+OUTDIR+"psa1.sstreg.son.png") 
           system("mv "+OUTDIR+"psa1.000011.png "+OUTDIR+"psa1.sstreg.ann.png")
           system("mv "+OUTDIR+"psa1.000012.png "+OUTDIR+"psa1.sstreg.mon.png")     
        end if
     else
        if (sstreg_frame.eq.0) then
           system("mv "+OUTDIR+"psa1.000006.png "+OUTDIR+"psa1.sstreg.djf.png") 
           system("mv "+OUTDIR+"psa1.000007.png "+OUTDIR+"psa1.sstreg.mam.png") 
           system("mv "+OUTDIR+"psa1.000008.png "+OUTDIR+"psa1.sstreg.jja.png") 
           system("mv "+OUTDIR+"psa1.000009.png "+OUTDIR+"psa1.sstreg.son.png") 
           system("mv "+OUTDIR+"psa1.000010.png "+OUTDIR+"psa1.sstreg.ann.png")
        end if
     end if
     
     system("mv "+OUTDIR+"psa2.000001.png "+OUTDIR+"psa2.djf.png") 
     system("mv "+OUTDIR+"psa2.000002.png "+OUTDIR+"psa2.mam.png") 
     system("mv "+OUTDIR+"psa2.000003.png "+OUTDIR+"psa2.jja.png") 
     system("mv "+OUTDIR+"psa2.000004.png "+OUTDIR+"psa2.son.png") 
     system("mv "+OUTDIR+"psa2.000005.png "+OUTDIR+"psa2.ann.png")
     if (COMPUTE_MODES_MON.eq."True") then     
        system("mv "+OUTDIR+"psa2.000006.png "+OUTDIR+"psa2.mon.png")  
        if (sstreg_frame.eq.0) then
           system("mv "+OUTDIR+"psa2.000007.png "+OUTDIR+"psa2.sstreg.djf.png") 
           system("mv "+OUTDIR+"psa2.000008.png "+OUTDIR+"psa2.sstreg.mam.png") 
           system("mv "+OUTDIR+"psa2.000009.png "+OUTDIR+"psa2.sstreg.jja.png") 
           system("mv "+OUTDIR+"psa2.000010.png "+OUTDIR+"psa2.sstreg.son.png") 
           system("mv "+OUTDIR+"psa2.000011.png "+OUTDIR+"psa2.sstreg.ann.png")
           system("mv "+OUTDIR+"psa2.000012.png "+OUTDIR+"psa2.sstreg.mon.png")     
        end if
     else
        if (sstreg_frame.eq.0) then
           system("mv "+OUTDIR+"psa2.000006.png "+OUTDIR+"psa2.sstreg.djf.png") 
           system("mv "+OUTDIR+"psa2.000007.png "+OUTDIR+"psa2.sstreg.mam.png") 
           system("mv "+OUTDIR+"psa2.000008.png "+OUTDIR+"psa2.sstreg.jja.png") 
           system("mv "+OUTDIR+"psa2.000009.png "+OUTDIR+"psa2.sstreg.son.png") 
           system("mv "+OUTDIR+"psa2.000010.png "+OUTDIR+"psa2.sstreg.ann.png")
        end if
     end if
     
     system("mv "+OUTDIR+"sam.timeseries.000001.png "+OUTDIR+"sam.timeseries.djf.png") 
     system("mv "+OUTDIR+"sam.timeseries.000002.png "+OUTDIR+"sam.timeseries.mam.png") 
     system("mv "+OUTDIR+"sam.timeseries.000003.png "+OUTDIR+"sam.timeseries.jja.png") 
     system("mv "+OUTDIR+"sam.timeseries.000004.png "+OUTDIR+"sam.timeseries.son.png") 
     system("mv "+OUTDIR+"sam.timeseries.000005.png "+OUTDIR+"sam.timeseries.ann.png")
     if (COMPUTE_MODES_MON.eq."True") then     
        system("mv "+OUTDIR+"sam.timeseries.000006.png "+OUTDIR+"sam.timeseries.mon.png")     
     end if
     
     system("mv "+OUTDIR+"psa1.timeseries.000001.png "+OUTDIR+"psa1.timeseries.djf.png") 
     system("mv "+OUTDIR+"psa1.timeseries.000002.png "+OUTDIR+"psa1.timeseries.mam.png") 
     system("mv "+OUTDIR+"psa1.timeseries.000003.png "+OUTDIR+"psa1.timeseries.jja.png") 
     system("mv "+OUTDIR+"psa1.timeseries.000004.png "+OUTDIR+"psa1.timeseries.son.png") 
     system("mv "+OUTDIR+"psa1.timeseries.000005.png "+OUTDIR+"psa1.timeseries.ann.png")
     if (COMPUTE_MODES_MON.eq."True") then     
        system("mv "+OUTDIR+"psa1.timeseries.000006.png "+OUTDIR+"psa1.timeseries.mon.png")     
     end if
     
     system("mv "+OUTDIR+"psa2.timeseries.000001.png "+OUTDIR+"psa2.timeseries.djf.png") 
     system("mv "+OUTDIR+"psa2.timeseries.000002.png "+OUTDIR+"psa2.timeseries.mam.png") 
     system("mv "+OUTDIR+"psa2.timeseries.000003.png "+OUTDIR+"psa2.timeseries.jja.png") 
     system("mv "+OUTDIR+"psa2.timeseries.000004.png "+OUTDIR+"psa2.timeseries.son.png") 
     system("mv "+OUTDIR+"psa2.timeseries.000005.png "+OUTDIR+"psa2.timeseries.ann.png")
     if (COMPUTE_MODES_MON.eq."True") then     
        system("mv "+OUTDIR+"psa2.timeseries.000006.png "+OUTDIR+"psa2.timeseries.mon.png")     
     end if
  else     
     system("psplit "+OUTDIR+"sam.ps "+OUTDIR+"psl_sp")
     system("mv "+OUTDIR+"psl_sp0001.ps "+OUTDIR+"sam.djf.ps") 
     system("mv "+OUTDIR+"psl_sp0002.ps "+OUTDIR+"sam.mam.ps") 
     system("mv "+OUTDIR+"psl_sp0003.ps "+OUTDIR+"sam.jja.ps") 
     system("mv "+OUTDIR+"psl_sp0004.ps "+OUTDIR+"sam.son.ps") 
     system("mv "+OUTDIR+"psl_sp0005.ps "+OUTDIR+"sam.ann.ps") 
     if (COMPUTE_MODES_MON.eq."True") then     
        system("mv "+OUTDIR+"psl_sp0006.ps "+OUTDIR+"sam.mon.ps") 
        if (sstreg_frame.eq.0) then
           system("mv "+OUTDIR+"psl_sp0007.ps "+OUTDIR+"sam.sstreg.djf.ps") 
           system("mv "+OUTDIR+"psl_sp0008.ps "+OUTDIR+"sam.sstreg.mam.ps") 
           system("mv "+OUTDIR+"psl_sp0009.ps "+OUTDIR+"sam.sstreg.jja.ps") 
           system("mv "+OUTDIR+"psl_sp0010.ps "+OUTDIR+"sam.sstreg.son.ps") 
           system("mv "+OUTDIR+"psl_sp0011.ps "+OUTDIR+"sam.sstreg.ann.ps")
           system("mv "+OUTDIR+"psl_sp0012.ps "+OUTDIR+"sam.sstreg.mon.ps") 
        end if
     else
        if (sstreg_frame.eq.0) then
           system("mv "+OUTDIR+"psl_sp0006.ps "+OUTDIR+"sam.sstreg.djf.ps") 
           system("mv "+OUTDIR+"psl_sp0007.ps "+OUTDIR+"sam.sstreg.mam.ps") 
           system("mv "+OUTDIR+"psl_sp0008.ps "+OUTDIR+"sam.sstreg.jja.ps") 
           system("mv "+OUTDIR+"psl_sp0009.ps "+OUTDIR+"sam.sstreg.son.ps") 
           system("mv "+OUTDIR+"psl_sp0010.ps "+OUTDIR+"sam.sstreg.ann.ps")     
        end if
     end if
     
     system("psplit "+OUTDIR+"psa1.ps "+OUTDIR+"psl_sp")
     system("mv "+OUTDIR+"psl_sp0001.ps "+OUTDIR+"psa1.djf.ps") 
     system("mv "+OUTDIR+"psl_sp0002.ps "+OUTDIR+"psa1.mam.ps") 
     system("mv "+OUTDIR+"psl_sp0003.ps "+OUTDIR+"psa1.jja.ps") 
     system("mv "+OUTDIR+"psl_sp0004.ps "+OUTDIR+"psa1.son.ps") 
     system("mv "+OUTDIR+"psl_sp0005.ps "+OUTDIR+"psa1.ann.ps") 
     if (COMPUTE_MODES_MON.eq."True") then     
        system("mv "+OUTDIR+"psl_sp0006.ps "+OUTDIR+"psa1.mon.ps") 
        if (sstreg_frame.eq.0) then
           system("mv "+OUTDIR+"psl_sp0007.ps "+OUTDIR+"psa1.sstreg.djf.ps") 
           system("mv "+OUTDIR+"psl_sp0008.ps "+OUTDIR+"psa1.sstreg.mam.ps") 
           system("mv "+OUTDIR+"psl_sp0009.ps "+OUTDIR+"psa1.sstreg.jja.ps") 
           system("mv "+OUTDIR+"psl_sp0010.ps "+OUTDIR+"psa1.sstreg.son.ps") 
           system("mv "+OUTDIR+"psl_sp0011.ps "+OUTDIR+"psa1.sstreg.ann.ps")
           system("mv "+OUTDIR+"psl_sp0012.ps "+OUTDIR+"psa1.sstreg.mon.ps") 
        end if
     else
        if (sstreg_frame.eq.0) then
           system("mv "+OUTDIR+"psl_sp0006.ps "+OUTDIR+"psa1.sstreg.djf.ps") 
           system("mv "+OUTDIR+"psl_sp0007.ps "+OUTDIR+"psa1.sstreg.mam.ps") 
           system("mv "+OUTDIR+"psl_sp0008.ps "+OUTDIR+"psa1.sstreg.jja.ps") 
           system("mv "+OUTDIR+"psl_sp0009.ps "+OUTDIR+"psa1.sstreg.son.ps") 
           system("mv "+OUTDIR+"psl_sp0010.ps "+OUTDIR+"psa1.sstreg.ann.ps")     
        end if
     end if
     
     system("psplit "+OUTDIR+"psa2.ps "+OUTDIR+"psl_sp")
     system("mv "+OUTDIR+"psl_sp0001.ps "+OUTDIR+"psa2.djf.ps") 
     system("mv "+OUTDIR+"psl_sp0002.ps "+OUTDIR+"psa2.mam.ps") 
     system("mv "+OUTDIR+"psl_sp0003.ps "+OUTDIR+"psa2.jja.ps") 
     system("mv "+OUTDIR+"psl_sp0004.ps "+OUTDIR+"psa2.son.ps") 
     system("mv "+OUTDIR+"psl_sp0005.ps "+OUTDIR+"psa2.ann.ps") 
     if (COMPUTE_MODES_MON.eq."True") then     
        system("mv "+OUTDIR+"psl_sp0006.ps "+OUTDIR+"psa2.mon.ps") 
        if (sstreg_frame.eq.0) then
           system("mv "+OUTDIR+"psl_sp0007.ps "+OUTDIR+"psa2.sstreg.djf.ps") 
           system("mv "+OUTDIR+"psl_sp0008.ps "+OUTDIR+"psa2.sstreg.mam.ps") 
           system("mv "+OUTDIR+"psl_sp0009.ps "+OUTDIR+"psa2.sstreg.jja.ps") 
           system("mv "+OUTDIR+"psl_sp0010.ps "+OUTDIR+"psa2.sstreg.son.ps") 
           system("mv "+OUTDIR+"psl_sp0011.ps "+OUTDIR+"psa2.sstreg.ann.ps")
           system("mv "+OUTDIR+"psl_sp0012.ps "+OUTDIR+"psa2.sstreg.mon.ps") 
        end if
     else
        if (sstreg_frame.eq.0) then
           system("mv "+OUTDIR+"psl_sp0006.ps "+OUTDIR+"psa2.sstreg.djf.ps") 
           system("mv "+OUTDIR+"psl_sp0007.ps "+OUTDIR+"psa2.sstreg.mam.ps") 
           system("mv "+OUTDIR+"psl_sp0008.ps "+OUTDIR+"psa2.sstreg.jja.ps") 
           system("mv "+OUTDIR+"psl_sp0009.ps "+OUTDIR+"psa2.sstreg.son.ps") 
           system("mv "+OUTDIR+"psl_sp0010.ps "+OUTDIR+"psa2.sstreg.ann.ps")     
        end if
     end if

     system("psplit "+OUTDIR+"sam.timeseries.ps "+OUTDIR+"psl_sp")
     system("mv "+OUTDIR+"psl_sp0001.ps "+OUTDIR+"sam.timeseries.djf.ps") 
     system("mv "+OUTDIR+"psl_sp0002.ps "+OUTDIR+"sam.timeseries.mam.ps") 
     system("mv "+OUTDIR+"psl_sp0003.ps "+OUTDIR+"sam.timeseries.jja.ps") 
     system("mv "+OUTDIR+"psl_sp0004.ps "+OUTDIR+"sam.timeseries.son.ps") 
     system("mv "+OUTDIR+"psl_sp0005.ps "+OUTDIR+"sam.timeseries.ann.ps") 
     if (COMPUTE_MODES_MON.eq."True") then     
        system("mv "+OUTDIR+"psl_sp0006.ps "+OUTDIR+"sam.timeseries.mon.ps") 
     end if
     
     system("psplit "+OUTDIR+"psa1.timeseries.ps "+OUTDIR+"psl_sp")
     system("mv "+OUTDIR+"psl_sp0001.ps "+OUTDIR+"psa1.timeseries.djf.ps") 
     system("mv "+OUTDIR+"psl_sp0002.ps "+OUTDIR+"psa1.timeseries.mam.ps") 
     system("mv "+OUTDIR+"psl_sp0003.ps "+OUTDIR+"psa1.timeseries.jja.ps") 
     system("mv "+OUTDIR+"psl_sp0004.ps "+OUTDIR+"psa1.timeseries.son.ps") 
     system("mv "+OUTDIR+"psl_sp0005.ps "+OUTDIR+"psa1.timeseries.ann.ps") 
     if (COMPUTE_MODES_MON.eq."True") then     
        system("mv "+OUTDIR+"psl_sp0006.ps "+OUTDIR+"psa1.timeseries.mon.ps") 
     end if
     
     system("psplit "+OUTDIR+"psa2.timeseries.ps "+OUTDIR+"psl_sp")
     system("mv "+OUTDIR+"psl_sp0001.ps "+OUTDIR+"psa2.timeseries.djf.ps") 
     system("mv "+OUTDIR+"psl_sp0002.ps "+OUTDIR+"psa2.timeseries.mam.ps") 
     system("mv "+OUTDIR+"psl_sp0003.ps "+OUTDIR+"psa2.timeseries.jja.ps") 
     system("mv "+OUTDIR+"psl_sp0004.ps "+OUTDIR+"psa2.timeseries.son.ps") 
     system("mv "+OUTDIR+"psl_sp0005.ps "+OUTDIR+"psa2.timeseries.ann.ps") 
     if (COMPUTE_MODES_MON.eq."True") then     
        system("mv "+OUTDIR+"psl_sp0006.ps "+OUTDIR+"psa2.timeseries.mon.ps")    
     end if
     system("rm "+OUTDIR+"psa2.timeseries.ps "+OUTDIR+"psa1.timeseries.ps "+OUTDIR+"sam.timeseries.ps "+OUTDIR+"psa2.ps "+OUTDIR+"psa1.ps "+OUTDIR+"sam.ps")     
  end if
  print("Finished: psl.sam_psa.ncl")
end  
