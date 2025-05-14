; Calculates a variety of sst indices, as well as hovmollers, spectra, 
; monthly standard deviations, running standard deviations, and spatial
; composites based on the nino3.4 index. 
;
; Variables used: ts, psl, pr and tas
;
load "$CVDP_SCRIPTS/functions.ncl"

begin
  print("Starting: sst.indices.ncl")
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
;---------PSL variable metadata------------------------------------------------------------
  nsim_psl = numAsciiRow("namelist_byvar/namelist_psl")
  na_psl = asciiread("namelist_byvar/namelist_psl",(/nsim_psl/),"string")
  names_psl = new(nsim_psl,"string")
  paths_psl = new(nsim_psl,"string")
  syear_psl = new(nsim_psl,"integer",-999)
  eyear_psl = new(nsim_psl,"integer",-999)

  do gg = 0,nsim_psl-1
     names_psl(gg) = str_strip(str_get_field(na_psl(gg),1,delim))
     paths_psl(gg) = str_strip(str_get_field(na_psl(gg),2,delim))
     syear_psl(gg) = stringtointeger(str_strip(str_get_field(na_psl(gg),3,delim)))
     eyear_psl(gg) = stringtointeger(str_strip(str_get_field(na_psl(gg),4,delim)))
  end do
  modname_psl = str_sub_str(names_psl," ","_")
  do ff = 0,dimsizes(modname_psl)-1
     do gg = 0,dimsizes(bc)-1
        modname_psl(ff) = str_sub_str(modname_psl(ff),bc(gg),"_")
     end do
  end do
  delete(na_psl)
  nyr_psl = eyear_psl-syear_psl+1  
;---------PR variable metadata------------------------------------------------------------
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
  wgt = (/1.,2.,1./)   
  wgt = wgt/sum(wgt)
  pi=4.*atan(1.0)
  rad=(pi/180.)
  val1 = .95
  val2 = .99

  do ee = 0,nsim-1
     fnt = getenv("OUTDIR")+modname(ee)+".cvdp_data.sst.indices."+syear(ee)+"-"+eyear(ee)+".nc"
     fnt2 = getenv("OUTDIR")+modname(ee)+".cvdp_data."+syear(ee)+"-"+eyear(ee)+".nc"
     f_test := read_cvdp_le_data(fnt,fnt2,"nino34")
     if (.not.isatt(f_test,"is_all_missing")) then
        continue
     end if

     sst := data_read_in(paths(ee),"TS",syear(ee),eyear(ee))    ; read in data, orient lats/lons correctly, set time coordinate variable up
     if (isatt(sst,"is_all_missing")) then
        delete(sst)
        continue
     end if 
     sst = where(sst.le.-1.8,-1.8,sst)    ; set all values below -1.8 to -1.8
     m = addfile("$NCARG_ROOT/lib/ncarg/data/cdf/landsea.nc","r")   ; mask out land (this is redundant for data that is already masked)
     sst = mask(sst,conform(sst,landsea_mask(m->LSMASK,sst&lat,sst&lon),(/1,2/)).ge.1,False)
     delete(m)  

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
           sst = remove_trend(sst,REMOVE_TREND_MODEL,ensemble_mean_read_in(sst,ENSEMBLE_MEAN_DIR+str_sub_str(names_EM(ee)," ","_"),EM_num(ee),"TS",syear,eyear,EM_num))
        end if
     end if
     if (isatt(sst,"is_all_missing")) then
        delete(sst)
        continue
     end if

     coswgt=cos(rad*sst&lat)
     coswgt!0 = "lat" 
     coswgt&lat= sst&lat        
     llats = -5.     ; nino3.4
     llatn = 5.
     llonw = 190.
     llone = 240.
     nino34 = wgt_areaave_Wrap(sst(:,{llats:llatn},{llonw:llone}),coswgt({llats:llatn}),1.0,0)  
     nino34@comment_cvdp = "area average domain ("+llats+":"+llatn+"N, "+llonw+":"+llone+"E)"
     nino34@units = sst@units
     nino34@long_name = "nino3.4 sst timeseries (monthly)"   
     nino34_regr := regCoef_n(nino34,sst,0,0)
     copy_VarMeta(sst(0,:,:),nino34_regr)
     nino34_regr@units = "C/C"
     nino34_regr@long_name = "nino3.4 timeseries sst regression pattern (monthly)"

     llats = -5.    ; nino3
     llatn = 5.
     llonw = 210.
     llone = 270.
     nino3 = wgt_areaave_Wrap(sst(:,{llats:llatn},{llonw:llone}),coswgt({llats:llatn}),1.0,0)  
     nino3@comment_cvdp = "area average domain ("+llats+":"+llatn+"N, "+llonw+":"+llone+"E)"
     copy_VarCoords(nino34,nino3)
     nino3@units = sst@units
     nino3@long_name = "nino3 sst timeseries (monthly)"    
     nino3_regr := regCoef_n(nino3,sst,0,0)
     copy_VarMeta(sst(0,:,:),nino3_regr)
     nino3_regr@units = "C/C"
     nino3_regr@long_name = "nino3 timeseries sst regression pattern (monthly)"
     
     llats = -5.    ; nino4
     llatn = 5.
     llonw = 160.
     llone = 210.
     nino4 = wgt_areaave_Wrap(sst(:,{llats:llatn},{llonw:llone}),coswgt({llats:llatn}),1.0,0)  
     nino4@comment_cvdp = "area average domain ("+llats+":"+llatn+"N, "+llonw+":"+llone+"E)"
     copy_VarCoords(nino34,nino4)
     nino4@units = sst@units
     nino4@long_name = "nino4 sst timeseries (monthly)"   
     nino4_regr := regCoef_n(nino4,sst,0,0)
     copy_VarMeta(sst(0,:,:),nino4_regr)
     nino4_regr@units = "C/C"
     nino4_regr@long_name = "nino4 timeseries sst regression pattern (monthly)"     

     llats = -10.    ; nino1+2
     llatn = 0.
     llonw = 270.
     llone = 280.
     nino12 = wgt_areaave_Wrap(sst(:,{llats:llatn},{llonw:llone}),coswgt({llats:llatn}),1.0,0)  
     nino12@comment_cvdp = "area average domain ("+llats+":"+llatn+"N, "+llonw+":"+llone+"E)"
     copy_VarCoords(nino34,nino12)
     nino12@units = sst@units
     nino12@long_name = "nino1+2 sst timeseries (monthly)"   
     nino12_regr := regCoef_n(nino12,sst,0,0)
     copy_VarMeta(sst(0,:,:),nino12_regr)
     nino12_regr@units = "C/C"
     nino12_regr@long_name = "nino1+2 timeseries sst regression pattern (monthly)"

     ssttemp = lonFlip(sst)   
     amm_n = wgt_areaave_Wrap(ssttemp(:,{5.:15.},{-50.:-20.}),coswgt({5.:15.}),1.0,0)      ;  Atlantic Meridional Mode
     amm_s = wgt_areaave_Wrap(ssttemp(:,{-15.:-5.},{-20.:10.}),coswgt({-15.:-5.}),1.0,0)
     amm = amm_n
     amm = (/ amm_n - amm_s /)
     delete([/amm_n,amm_s/])
     amm@comment_cvdp = "area average domain (5:15N, 50:20W) - (15:5S, 20W:10E)"
     copy_VarCoords(nino34,amm)
     amm@units = sst@units
     amm@long_name = "Atlantic Meridional Mode Index sst timeseries (monthly)"   
     amm_regr := regCoef_n(amm,sst,0,0)
     copy_VarMeta(sst(0,:,:),amm_regr)
     amm_regr@units = "C/C"
     amm_regr@long_name = "Atlantic Meridional Mode sst regression pattern (monthly)"

     llats = -3.    ;  Atlantic Nino (ATL3)
     llatn = 3.
     llonw = -20.
     llone = 0.
     atl3 = wgt_areaave_Wrap(ssttemp(:,{llats:llatn},{llonw:llone}),coswgt({llats:llatn}),1.0,0)  
     atl3@comment_cvdp = "area average domain ("+llats+":"+llatn+"N, "+llonw+":"+llone+"E)"
     copy_VarCoords(nino34,atl3)
     atl3@units = sst@units
     atl3@long_name = "Atlantic Nino Index sst timeseries (monthly)" 
     atl3_regr := regCoef_n(atl3,sst,0,0)
     copy_VarMeta(sst(0,:,:),atl3_regr)
     atl3_regr@units = "C/C"
     atl3_regr@long_name = "Atlantic Nino Index sst regression pattern (monthly)"  

     llats = 0.    ;  North Atlantic
     llatn = 60.
     llonw = -80.
     llone = 0.
     natl = wgt_areaave_Wrap(ssttemp(:,{llats:llatn},{llonw:llone}),coswgt({llats:llatn}),1.0,0)  
     natl@comment_cvdp = "area average domain ("+llats+":"+llatn+"N, "+llonw+":"+llone+"E)"
     copy_VarCoords(nino34,natl)
     natl@units = sst@units
     natl@long_name = "North Atlantic sst timeseries (monthly)" 
     natl_regr := regCoef_n(natl,sst,0,0)
     copy_VarMeta(sst(0,:,:),natl_regr)
     natl_regr@units = "C/C"
     natl_regr@long_name = "North Atlantic timeseries sst regression pattern (monthly)"  
  
     
     llats = -20.    ;  Tropical Southern Atlantic Index
     llatn = 0.
     llonw = -30.
     llone = 10.
     tsa = wgt_areaave_Wrap(ssttemp(:,{llats:llatn},{llonw:llone}),coswgt({llats:llatn}),1.0,0)  
     tsa@comment_cvdp = "area average domain ("+llats+":"+llatn+"N, "+llonw+":"+llone+"E)"
     copy_VarCoords(nino34,tsa)
     tsa@units = sst@units
     tsa@long_name = "Tropical Southern Atlantic sst timeseries (monthly)"     
     delete(ssttemp)
     tsa_regr := regCoef_n(tsa,sst,0,0)
     copy_VarMeta(sst(0,:,:),tsa_regr)
     tsa_regr@units = "C/C"
     tsa_regr@long_name = "Tropical Southern Atlantic timeseries sst regression pattern (monthly)"  
     
     llats = 5.5    ;  Tropical Northern Atlantic Index
     llatn = 23.5
     llonw = 302.5
     llone = 345.
     tna = wgt_areaave_Wrap(sst(:,{llats:llatn},{llonw:llone}),coswgt({llats:llatn}),1.0,0)  
     tna@comment_cvdp = "area average domain ("+llats+":"+llatn+"N, "+llonw+":"+llone+"E)"
     copy_VarCoords(nino34,tna)
     tna@units = sst@units
     tna@long_name = "Tropical Northern Atlantic sst timeseries (monthly)"  
     tna_regr := regCoef_n(tna,sst,0,0)
     copy_VarMeta(sst(0,:,:),tna_regr)
     tna_regr@units = "C/C"
     tna_regr@long_name = "Tropical Northern Atlantic timeseries sst regression pattern (monthly)"  

     llats = -15.    ;  Indian Ocean SST index
     llatn = 15.
     llonw = 40.
     llone = 110.
     tio = wgt_areaave_Wrap(sst(:,{llats:llatn},{llonw:llone}),coswgt({llats:llatn}),1.0,0)  
     tio@comment_cvdp = "area average domain ("+llats+":"+llatn+"N, "+llonw+":"+llone+"E)"
     copy_VarCoords(nino34,tio)
     tio@units = sst@units
     tio@long_name = "Tropical Indian Ocean sst timeseries (monthly)"   
     tio_regr := regCoef_n(tio,sst,0,0)
     copy_VarMeta(sst(0,:,:),tio_regr)
     tio_regr@units = "C/C"
     tio_regr@long_name = "Tropical Indian Ocean timeseries sst regression pattern (monthly)"  
     
                     ; Indian Ocean Dipole Index http://www.bom.gov.au/climate/IOD/about_IOD.shtml
     iod = wgt_areaave_Wrap(sst(:,{-10.:10.},{50.:70.}),coswgt({-10.:10.}),1.0,0) - wgt_areaave(sst(:,{-10.:0.},{90.:110.}),coswgt({-10.:0.}),1.0,0)  
     iod@comment_cvdp = "area average domain (-10:10N, 50:70E) - (-10:0N, 90:110E)"
     copy_VarCoords(nino34,iod)
     iod@units = sst@units
     iod@long_name = "Indian Ocean Dipole Index (monthly)"  
       ; iod pattern regressions done below
    
     socn = wgt_areaave_Wrap(sst(:,{-70.:-50.},:),coswgt({-70.:-50.}),1.0,0) 
     socn@comment_cvdp = "area average domain (-70:-50N, 0:360E)"
     copy_VarCoords(nino34,socn)
     socn@units = sst@units
     socn@long_name = "Southern Ocean Index (monthly)"   
     socn_regr := regCoef_n(socn,sst,0,0)
     copy_VarMeta(sst(0,:,:),socn_regr)
     socn_regr@units = "C/C"
     socn_regr@long_name = "Southern Ocean Index sst regression pattern (monthly)"  
     delete(coswgt)
;------------------------------------------------------------------------------------------
;  Pacific Meridional Modes
  
     sst_CW = SqrtCosWeight(sst)
  
     evecv = eofunc(sst_CW({lat|-20:20},{lon|220:290},time|:),2,75)
     pcts  = eofunc_ts_n(sst_CW(:,{-20:20},{220:290}),evecv,False,0)
     pc1   = dim_standardize(pcts(0,:),0) 
     finsst0 = regCoef_n(pc1,sst,0,0)
     finsst0_sc = sst
     finsst0_sc = finsst0_sc@_FillValue
     do hh = 0,dimsizes(sst&time)-1
        finsst0_sc(hh,:,:) = (/ finsst0*pc1(hh) /)
     end do

     sstresid = sst - finsst0_sc   ; subtract out ENSO
     copy_VarMeta(sst,sstresid)
     delete([/evecv,pcts,pc1,finsst0,finsst0_sc,sst_CW/])

     sstresid_CW = SqrtCosWeight(sstresid)
     evecv = eofunc(sstresid_CW({lat|-20:30},{lon|175:265},time|:),2,75)
     pcts  = eofunc_ts_n(sstresid_CW(:,{-20:30},{175:265}),evecv,False,0)
     npmm   = dim_standardize(pcts(0,:),0) 
     npmm_pattern = regCoef_n(npmm,sstresid,0,0)
     copy_VarMeta(sst(0,:,:),npmm_pattern)
     copy_VarCoords(nino34,npmm)
     npmm@units = "1"
     npmm@long_name = "North Pacific Meridional Mode (monthly)"   
     npmm@comment_cvdp = "1st EOF of SST-residual (-20:30N, 175:265E)"

     npmm_pattern@long_name = "North Pacific Meridional Mode sst regression pattern (monthly)"
     if (npmm_pattern({22},{240}).lt.0) then
        npmm = npmm*-1.
        npmm_pattern = npmm_pattern*-1.
     end if
     delete([/evecv,pcts/])

     evecv = eofunc(sstresid_CW({lat|-35:-20},{lon|180:290},time|:),2,75)
     pcts  = eofunc_ts_n(sstresid_CW(:,{-35:-20},{180:290}),evecv,False,0)
     spmm   = dim_standardize(pcts(0,:),0) 
     spmm_pattern := regCoef_n(spmm,sstresid,0,0)
     copy_VarMeta(sst(0,:,:),spmm_pattern)
     copy_VarCoords(nino34,spmm)
     spmm@units = "1"
     spmm@long_name = "South Pacific Meridional Mode (monthly)"   
     spmm@comment_cvdp = "1st EOF of SST-residual (-35:-20N, 180:290E)"
     spmm_pattern@long_name = "South Pacific Meridional Mode sst regression pattern (monthly)"
     if (spmm_pattern({-25},{280}).lt.0) then
        spmm = spmm*-1.
        spmm_pattern = spmm_pattern*-1.
     end if
     delete([/evecv,pcts,sstresid_CW,sstresid/])
;------------------------------------------------------------------------------------------
;  Nino3.4 monthly standard deviation
;
     nino34_mon_sd = new(12,typeof(nino34))
     
     do hh = 0,11
        nino34_mon_sd(hh) = (/ dim_stddev(nino34(hh::12)) /)
     end do
     nino34_mon_sd@units = "C"
     nino34_mon_sd@detrend_option = nino34@detrend_option
     time_mon2 = ispan(0,11,1)
     time_mon2@units = "months since 0000-01-01 00:00:00"
     time_mon2@long_name = "Time"
     time_mon2@standard_name = "time"
     time_mon2@calendar = "standard"
     time_mon2!0 = "time_mon2"
     time_mon2&time_mon2 = time_mon2
     nino34_mon_sd!0 = "time_mon2"
     nino34_mon_sd&time_mon2 = time_mon2
     delete(time_mon2)
;--------------------------------------------------------------------
;  Spatial Hovmoller composites (SST/ZOS)

     nino34T := wgt_runave(nino34,wgt,1)     ; for use in ENSO composites / hovmuellers / running standard deviations
     nino34_ndj := nino34T(11:dimsizes(nino34T)-13:12)   ; cannot count last 1yr as spatial composite uses +1yrs data betond NDJ..  
     nino34_ndj!0 = "time"
     nino34_ndj&time = ispan(syear(ee),eyear(ee)-1,1)    

     nino34_ndj = dim_standardize(nino34_ndj,0)

     if (nyr(ee).ge.15) then   ; 15+yrs required for hovmollers
        sstr = sst(:,{-3:3},{120:280})                        ; ENSO hovmuellers based on NDJ nino34
        finsst_hi := sstr(:60,0,:)    ; for Jan-2 -> Jan+3
        finsst_hi!0 = "time"
        finsst_hi&time = ispan(0,60,1)
        finsst_hi = 0.
        finsst_lo := finsst_hi
        finsst_mid := finsst_hi
        cntr_hi = 0
        cntr_lo = 0
        cntr_mid = 0
        cntr_lo@_FillValue = default_fillvalue(typeof(cntr_lo)) 
        cntr_mid@_FillValue = default_fillvalue(typeof(cntr_mid)) 
        cntr_hi@_FillValue = default_fillvalue(typeof(cntr_hi)) 

        plot_flag = check_years_match(syear(ee),syear_zos(ee),eyear(ee),eyear_zos(ee))
        f_test := read_cvdp_le_data(fnt,fnt2,"nino34_hov_elnino_zos")
        arr_zos := data_read_in_ocean(paths_zos(ee),"SSH",syear_zos(ee),eyear_zos(ee))
        if (plot_flag.eq.0.and.isatt(f_test,"is_all_missing").and..not.isatt(arr_zos,"is_all_missing")) then  ; if years of the two variables match, if the metrics haven't already been calculated, 

           arr_zos = rmMonAnnCycTLL(arr_zos) 
           if (ee.le.(numobs-1)) then   
              arr_zos = remove_trend(arr_zos,REMOVE_TREND_OBS,new(1,float))
           else
              if (REMOVE_TREND_MODEL.eq."30yrRunningMean".or.REMOVE_TREND_MODEL.eq."LinearTrend".or.REMOVE_TREND_MODEL.eq."QuadraticTrend".or.REMOVE_TREND_MODEL.eq."None") then
                 arr_zos = remove_trend(arr_zos,REMOVE_TREND_MODEL,new(1,float))
              end if
              if (REMOVE_TREND_MODEL.eq."rmGMST_EM") then
                 arr_zos = remove_trend(arr_zos,REMOVE_TREND_MODEL,ensemble_mean_read_in(arr_zos,ENSEMBLE_MEAN_DIR+str_sub_str(names_EM(ee)," ","_"),EM_num(ee),"TREFHT",syear,eyear,EM_num))
              end if
              if (REMOVE_TREND_MODEL.eq."rmEM") then
                 arr_zos = remove_trend(arr_zos,REMOVE_TREND_MODEL,ensemble_mean_read_in(arr_zos,ENSEMBLE_MEAN_DIR+str_sub_str(names_EM(ee)," ","_"),EM_num(ee),"ssh",syear_zos,eyear_zos,EM_num))
              end if
           end if

           if (isatt(arr_zos,"coordinates")) then   ; curvilinear 
              InterpMethod = "bilinear"
              Opt                := True
              Opt@SrcTitle       = names_zos(ee)+" grid"   ; optional
              Opt@WgtFileName    = "tmp_to_ssti.WgtFile_"+InterpMethod+".nc"
              Opt@SrcFileName    = getenv("OUTDIR")+"/ssti.SCRIP_grid_description.nc"         ; Name of source and
              Opt@SrcRegional    = True  ; will verify this below

              Opt@SrcGridType    = "curvilinear"
              Opt@ForceOverwrite = True
              Opt@InterpMethod   = InterpMethod
              Opt@RemoveSrcFile  = True                  ; remove SCRIP grid destination files
              Opt@RemoveDstFile  = True 
              Opt@NoPETLog       = True
              Opt@DstGridType    = "rectilinear"
              Opt@DstRegional    = False
              Opt@DstGridLat     := sst&lat
              Opt@DstGridLon     := sst&lon
              Opt@DstFileName    = getenv("OUTDIR")+Opt@DstGridType+".ssti.SCRIP_grid_description.nc" 
              if (any(ismissing(sst))) then
                 Opt@DstMask2D  := where(ismissing(sst(0,:,:)),0,1)  ; set SrcMask2D option to indicate the missing values 
              end if
              zos2 = ESMF_regrid(arr_zos, Opt)
              if (isfilepresent2(Opt@WgtFileName)) then
                 system("rm "+Opt@WgtFileName)
              end if
           else
              zos2 = linint2_Wrap(arr_zos&nlon,arr_zos&nlat,arr_zos,True,sst&lon,sst&lat,0)
           end if
     
           zosr = zos2(:,{-3:3},{120:280})                        ; ENSO hovmuellers based on NDJ nino34
           finzos_hi := zosr(:60,0,:)    ; for Jan-2 -> Jan+3
           finzos_hi!0 = "time"
           finzos_hi&time = ispan(0,60,1)
           finzos_hi = 0.
           finzos_lo  := finzos_hi
           finzos_mid := finzos_hi
           delete([/arr_zos,zos2/])
        end if
           
        mocntr = 24   ; note: if this is set at 24 gg should start at 2
        do gg = 2,dimsizes(nino34_ndj)-3   ; remember that Dec is month 11. End @ -3 because we need to grab + 3 yrs and 1 month from there (nino34_ndj already ends at eyear-1)
           if (.not.ismissing(nino34_ndj(gg))) then    ; note that finsst_* indices 24:52 (Jan+0 -> May +2) are all that is shown in the hovmoller plots 
              if (nino34_ndj(gg).ge.1.) then
                 finsst_hi = (/ finsst_hi+dim_avg_n(sstr(mocntr-24:mocntr+36,:,:),1) /)    ; nino34_ndj value is at sstr index mocntr+11     
                 if (isvar("zosr")) then
                    finzos_hi = (/ finzos_hi+dim_avg_n(zosr(mocntr-24:mocntr+36,:,:),1) /)    ; nino34_ndj value is at zosr index mocntr+11     
                 end if
                 cntr_hi = cntr_hi+1
              end if
              if (nino34_ndj(gg).ge.-0.5.and.nino34_ndj(gg).le.0.5) then
                 finsst_mid = (/ finsst_mid+dim_avg_n(sstr(mocntr-24:mocntr+36,:,:),1) /)     
                 if (isvar("zosr")) then
                    finzos_mid = (/ finzos_mid+dim_avg_n(zosr(mocntr-24:mocntr+36,:,:),1) /)    ; nino34_ndj value is at zosr index mocntr+11     
                 end if     
                 cntr_mid = cntr_mid+1
              end if
              if (nino34_ndj(gg).le.-1.) then
                 finsst_lo = (/ finsst_lo+dim_avg_n(sstr(mocntr-24:mocntr+36,:,:),1) /)    
                 if (isvar("zosr")) then
                    finzos_lo = (/ finzos_lo+dim_avg_n(zosr(mocntr-24:mocntr+36,:,:),1) /)    ; nino34_ndj value is at zosr index mocntr+11     
                 end if        
                 cntr_lo = cntr_lo+1
              end if
           end if
           mocntr = mocntr+12
        end do
        delete([/sstr,mocntr/])
        if (isvar("zosr")) then
           delete(zosr)
        end if

        cntr_hi  = where(cntr_hi.eq.0, cntr_hi@_FillValue, cntr_hi)
        cntr_mid = where(cntr_mid.eq.0,cntr_mid@_FillValue,cntr_mid)
        cntr_lo  = where(cntr_lo.eq.0, cntr_lo@_FillValue, cntr_lo)
        finsst_hi  = (/ finsst_hi/cntr_hi /)
        finsst_mid = (/ finsst_mid/cntr_mid /)
        finsst_lo  = (/ finsst_lo/cntr_lo /)
        if (isvar("finzos_hi")) then           
           finzos_hi  = (/ finzos_hi/cntr_hi /)
           finzos_mid = (/ finzos_mid/cntr_mid /)
           finzos_lo  = (/ finzos_lo/cntr_lo /)
        end if

        hov_hi := (/ finsst_hi(24:52,:) /)  ; 24:52 runs from Jan+0->May+2 and matches range shown in plot
        time_mon1 = ispan(0,28,1)
        time_mon1@units = "months since 0000-01-01 00:00:00"
        time_mon1@long_name = "Time"
        time_mon1@standard_name = "time"
        time_mon1@calendar = "standard"
        time_mon1!0 = "time_mon1"
        time_mon1&time_mon1 = time_mon1
        hov_hi!0 = "time_mon1"
        hov_hi&time_mon1 = time_mon1
        longitude = finsst_hi&lon
        longitude@standard_name = "longitude"
        hov_hi!1 = "longitude"
        hov_hi&longitude = longitude
        hov_hi@units = "C"
        hov_lo := (/ finsst_lo(24:52,:) /)  ; 24:52 runs from Jan+0->May+2 and matches range shown in plot
        copy_VarMeta(hov_hi,hov_lo)    
        hov_hi@number_of_events = cntr_hi
        hov_lo@number_of_events = cntr_lo
        hov_hi@detrend_option = finsst_hi@detrend_option
        hov_lo@detrend_option = finsst_lo@detrend_option

        if (isvar("finzos_hi")) then           
           hov_hi_zos := (/ finzos_hi(24:52,:) /)  ; 24:52 runs from Jan+0->May+2 and matches range shown in plot
           hov_hi_zos!0 = "time_mon1"
           hov_hi_zos&time_mon1 = time_mon1
           hov_hi_zos!1 = "longitude"
           hov_hi_zos&longitude = longitude
           hov_hi_zos@units = finzos_hi@units
           hov_lo_zos := (/ finzos_lo(24:52,:) /)  ; 24:52 runs from Jan+0->May+2 and matches range shown in plot
           copy_VarMeta(hov_hi_zos,hov_lo_zos)    
           hov_hi_zos@number_of_events = cntr_hi
           hov_lo_zos@number_of_events = cntr_lo
           hov_hi_zos@detrend_option = finzos_hi@detrend_option
           hov_lo_zos@detrend_option = finzos_lo@detrend_option
           delete([/finzos_hi,finzos_mid,finzos_lo/])
        end if
        delete([/time_mon1,longitude/])
     end if
;------------------------------------------------------------------------------------------
     z = addfile(fnt,"c")
     set_global_ncfile_attributes(z,names(ee),syear(ee),eyear(ee),getenv("VERSION"))

     z->$(/"nino34"/)$ = set_varAtts(nino34,"","","")
     z->$(/"nino12"/)$ = set_varAtts(nino12,"","","")
     z->$(/"nino3"/)$  = set_varAtts(nino3,"","","")
     z->$(/"nino4"/)$  = set_varAtts(nino4,"","","")
     z->$(/"north_tropical_atlantic"/)$ = set_varAtts(tna,"","","")
     z->$(/"north_atlantic"/)$ = set_varAtts(natl,"","","")
     z->$(/"south_tropical_atlantic"/)$ = set_varAtts(tsa,"","","")
     z->$(/"tropical_indian_ocean"/)$ = set_varAtts(tio,"","","")
     z->$(/"indian_ocean_dipole"/)$ = set_varAtts(iod,"","","")
     z->$(/"southern_ocean"/)$ = set_varAtts(socn,"","","")
     z->$(/"atlantic_meridional_mode"/)$ = set_varAtts(amm,"","","")
     z->$(/"atlantic_nino"/)$ = set_varAtts(atl3,"","","")
     z->$(/"north_pacific_meridional_mode"/)$ = set_varAtts(npmm,"","","")
     z->$(/"south_pacific_meridional_mode"/)$ = set_varAtts(spmm,"","","")

     z->$(/"nino34_pattern_mon"/)$ = set_varAtts(nino34_regr,"","","")
     z->$(/"nino12_pattern_mon"/)$ = set_varAtts(nino12_regr,"","","")
     z->$(/"nino3_pattern_mon"/)$  = set_varAtts(nino3_regr,"","","")
     z->$(/"nino4_pattern_mon"/)$  = set_varAtts(nino4_regr,"","","")
     z->$(/"north_tropical_atlantic_pattern_mon"/)$ = set_varAtts(tna_regr,"","","")
     z->$(/"north_atlantic_pattern_mon"/)$ = set_varAtts(natl_regr,"","","")
     z->$(/"south_tropical_atlantic_pattern_mon"/)$ = set_varAtts(tsa_regr,"","","")
     z->$(/"tropical_indian_ocean_pattern_mon"/)$ = set_varAtts(tio_regr,"","","")
     z->$(/"southern_ocean_pattern_mon"/)$ = set_varAtts(socn_regr,"","","")
     z->$(/"atlantic_meridional_mode_pattern_mon"/)$ = set_varAtts(amm_regr,"","","")
     z->$(/"atlantic_nino_pattern_mon"/)$ = set_varAtts(atl3_regr,"","","")
     z->$(/"north_pacific_meridional_mode_pattern_mon"/)$ = set_varAtts(npmm_pattern,"","","")
     z->$(/"south_pacific_meridional_mode_pattern_mon"/)$ = set_varAtts(spmm_pattern,"","","")

     z->$(/"nino34_monthly_stddev"/)$ = set_varAtts(nino34_mon_sd,"nino3.4 monthly standard deviation","","")
     if (nyr(ee).ge.15) then
        z->$(/"nino34_hov_elnino"/)$ = set_varAtts(hov_hi,"nino3.4 El Nino Hovmoller sst composite","","")
        z->$(/"nino34_hov_lanina"/)$ = set_varAtts(hov_lo,"nino3.4 La Nina Hovmoller sst composite","","")
        delete([/hov_hi,hov_lo/])
     end if 
     delete([/nino3,nino4,nino12,amm,atl3,tsa,tna,tio,socn,natl,npmm,spmm,npmm_pattern,spmm_pattern,nino34_regr,nino12_regr,nino3_regr,nino4_regr,tna_regr,natl_regr,tsa_regr,tio_regr,socn_regr,amm_regr,atl3_regr/])    ; iod used below
;-----------------------------------------------------------------------------------------
;   nino3.4 running standard deviations
;
     if (nyr(ee).ge.35) then    ; need a minimum number of years to compute running nino3.4 standard deviations
        nino34a := nino34T
        nino34a!0 = "time"
        nino34a&time = nino34&time
        sd_run := nino34a
        sd_run  = sd_run@_FillValue
        sd_run@units = nino34@units
        sd_run@long_name = "nino3.4 30yr running standard deviation"
        do gg = 180,dimsizes(nino34a)-180
           sd_run(gg) = (/ dim_stddev(nino34a(gg-180:gg+179)) /)
        end do
        z->$(/"nino34_runstddev"/)$ = set_varAtts(sd_run,"","","")
     end if
;-----------------------------------------------------------------------------------------
;   nino3.4 spatial composites (sst, tas, psl, pr) and IOD regressions

     hicntr = 0
     locntr = 0
     hiyr = new(dimsizes(nino34_ndj&time),integer)
     loyr = hiyr
     do hh = 0,dimsizes(nino34_ndj)-1
        if (.not.ismissing(nino34_ndj(hh))) then
           if (nino34_ndj(hh).ge.1) then
              hiyr(hicntr) = nino34_ndj&time(hh)
              hicntr = hicntr+1
           end if
           if (nino34_ndj(hh).le.-1) then
              loyr(locntr) = nino34_ndj&time(hh)
              locntr = locntr+1
           end if
        end if
     end do 
     if (hicntr.eq.0) then     ; for simulations with climatological SSTs
        highyr := hiyr(0)
     else
        highyr := hiyr(:hicntr-1)
     end if
     if (locntr.eq.0) then
        lowyr := loyr(0)
     else
        lowyr := loyr(:locntr-1)
     end if
     delete([/loyr,locntr,hiyr,hicntr/])

     do hh = 0,4     ; for each variable: sst, tas, psl, pr, zos
        if (hh.eq.0) then
           plot_flag = 0
           arr := sst
        end if
        if (hh.eq.1) then 
           plot_flag = check_years_match(syear(ee),syear_tas(ee),eyear(ee),eyear_tas(ee))
           fnt = getenv("OUTDIR")+modname_tas(ee)+".cvdp_data.sst.indices.tas."+syear_tas(ee)+"-"+eyear_tas(ee)+".nc"
           f_test := read_cvdp_le_data(fnt,fnt2,"nino34_spacomp_tas_mam1")
           arr := data_read_in(paths_tas(ee),"TREFHT",syear_tas(ee),eyear_tas(ee))
        end if
        if (hh.eq.2) then 
           plot_flag = check_years_match(syear(ee),syear_psl(ee),eyear(ee),eyear_psl(ee))
           fnt = getenv("OUTDIR")+modname_psl(ee)+".cvdp_data.sst.indices.psl."+syear_psl(ee)+"-"+eyear_psl(ee)+".nc"
           f_test := read_cvdp_le_data(fnt,fnt2,"nino34_spacomp_psl_mam1")
           arr := data_read_in(paths_psl(ee),"PSL",syear_psl(ee),eyear_psl(ee))
        end if
        if (hh.eq.3) then 
           plot_flag = check_years_match(syear(ee),syear_pr(ee),eyear(ee),eyear_pr(ee))
           fnt = getenv("OUTDIR")+modname_pr(ee)+".cvdp_data.sst.indices.pr."+syear_pr(ee)+"-"+eyear_pr(ee)+".nc"
           f_test := read_cvdp_le_data(fnt,fnt2,"nino34_spacomp_pr_mam1")
           arr := data_read_in(paths_pr(ee),"PRECT",syear_pr(ee),eyear_pr(ee))
        end if
        if (hh.eq.4) then 
           plot_flag = check_years_match(syear(ee),syear_zos(ee),eyear(ee),eyear_zos(ee))
           fnt = getenv("OUTDIR")+modname_zos(ee)+".cvdp_data.sst.indices.zos."+syear_zos(ee)+"-"+eyear_zos(ee)+".nc"
           f_test := read_cvdp_le_data(fnt,fnt2,"nino34_spacomp_zos_mam1")
           arr := data_read_in_ocean(paths_zos(ee),"SSH",syear_zos(ee),eyear_zos(ee))
        end if

        if (plot_flag.eq.0.and.isatt(f_test,"is_all_missing").and..not.isatt(arr,"is_all_missing")) then  ; if years of the two variables match, if the metrics haven't already been calculated, 
           yyyymm := cd_calendar(arr&time,-1)                                                            ; and if the data array that needs to be read in (arr) is not all missing, proceed
           tmin = yyyymm(0)/100                                           ; convert time from CF-conforming to YYYYMM              
           tmax = yyyymm(dimsizes(yyyymm)-1)/100
           delete(arr&time)
           arr&time = fspan(tmin*1.,(tmax*1.)+(11/12.),dimsizes(yyyymm))  ; then convert time from YYYYMM->YYYY.frac

           if (hh.ge.1) then   ; 0 = SST, where the annual cycle has already been removed and detrending option has been applied
              arr = rmMonAnnCycTLL(arr) 

              if (ee.le.(numobs-1)) then   
                 arr = remove_trend(arr,REMOVE_TREND_OBS,new(1,float))
              else
                 if (REMOVE_TREND_MODEL.eq."30yrRunningMean".or.REMOVE_TREND_MODEL.eq."LinearTrend".or.REMOVE_TREND_MODEL.eq."QuadraticTrend".or.REMOVE_TREND_MODEL.eq."None") then
                    arr = remove_trend(arr,REMOVE_TREND_MODEL,new(1,float))
                 end if
                 if (REMOVE_TREND_MODEL.eq."rmGMST_EM") then
                    arr = remove_trend(arr,REMOVE_TREND_MODEL,ensemble_mean_read_in(arr,ENSEMBLE_MEAN_DIR+str_sub_str(names_EM(ee)," ","_"),EM_num(ee),"TREFHT",syear,eyear,EM_num))
                 end if
                 if (REMOVE_TREND_MODEL.eq."rmEM") then
                    if (hh.eq.1) then
                       arr = remove_trend(arr,REMOVE_TREND_MODEL,ensemble_mean_read_in(arr,ENSEMBLE_MEAN_DIR+str_sub_str(names_EM(ee)," ","_"),EM_num(ee),"TREFHT",syear_tas,eyear_tas,EM_num))
                    end if
                    if (hh.eq.2) then
                       arr = remove_trend(arr,REMOVE_TREND_MODEL,ensemble_mean_read_in(arr,ENSEMBLE_MEAN_DIR+str_sub_str(names_EM(ee)," ","_"),EM_num(ee),"PSL",syear_psl,eyear_psl,EM_num))
                    end if
                    if (hh.eq.3) then
                       arr = remove_trend(arr,REMOVE_TREND_MODEL,ensemble_mean_read_in(arr,ENSEMBLE_MEAN_DIR+str_sub_str(names_EM(ee)," ","_"),EM_num(ee),"PRECT",syear_pr,eyear_pr,EM_num))
                    end if
                    if (hh.eq.4) then
                       arr = remove_trend(arr,REMOVE_TREND_MODEL,ensemble_mean_read_in(arr,ENSEMBLE_MEAN_DIR+str_sub_str(names_EM(ee)," ","_"),EM_num(ee),"ssh",syear_zos,eyear_zos,EM_num))
                    end if
                    if (isatt(arr,"is_all_missing")) then
                       continue
                    end if 
                 end if
              end if
           end if

           iod_regr:= regCoef_n(iod,arr,0,0)
           copy_VarMeta(arr(0,:,:),iod_regr)
           iod_regr@units = "C/C"

           arr = runave_n_Wrap(arr,3,0,0)
           arr(0,:,:) = (/ dim_avg_n(arr(:1,:,:),0) /)

           sc_arr_hi := arr(:23,:,:)
           sc_arr_hi  = sc_arr_hi@_FillValue
           sc_arr_lo := sc_arr_hi
           n34sc_arr := sc_arr_hi
           if (dimsizes(highyr).ge.2) then
              do ii = 0,23
                 tt = ii/12.
                 sc_arr_hi(ii,:,:) = (/ dim_avg_n(arr({highyr+tt},:,:),0) /)
              end do
           end if
           if (dimsizes(lowyr).ge.2) then
              do ii = 0,23
                 tt = ii/12.
                 sc_arr_lo(ii,:,:) = (/ dim_avg_n(arr({lowyr+tt},:,:),0) /)
              end do
           end if          
           n34sc_arr = (/ sc_arr_hi - sc_arr_lo /)
           n34sc_arr@number_of_elnino_events = dimsizes(highyr)
           n34sc_arr@number_of_lanina_events = dimsizes(lowyr)

           sc_arr_hi@number_of_elnino_events = dimsizes(highyr)

           sc_arr_lo@number_of_lanina_events = dimsizes(lowyr)

           if (hh.ne.4) then
              n34sc_arr&lat@standard_name = "latitude"
              n34sc_arr&lon@standard_name = "longitude"
              sc_arr_hi&lat@standard_name = "latitude"
              sc_arr_hi&lon@standard_name = "longitude"
              sc_arr_lo&lat@standard_name = "latitude"
              sc_arr_lo&lon@standard_name = "longitude"
           end if

           if (hh.eq.0) then
              z->$(/"nino34_spacomp_sst_jja0"/)$ = set_varAtts(n34sc_arr(6,:,:),"nino3.4 sst EN-LN spatial composite (JJA+0)","","")
              z->$(/"nino34_spacomp_sst_son0"/)$ = set_varAtts(n34sc_arr(9,:,:),"nino3.4 sst EN-LN spatial composite (SON+0)","","")
              z->$(/"nino34_spacomp_sst_djf1"/)$ = set_varAtts(n34sc_arr(12,:,:),"nino3.4 sst EN-LN spatial composite (DJF+1)","","")
              z->$(/"nino34_spacomp_sst_mam1"/)$ = set_varAtts(n34sc_arr(15,:,:),"nino3.4 sst EN-LN spatial composite (MAM+1)","","")

              z->$(/"nino34_elnino_spacomp_sst_jja0"/)$ = set_varAtts(sc_arr_hi(6,:,:),"nino3.4 sst El Nino spatial composite (JJA+0)","","")
              z->$(/"nino34_elnino_spacomp_sst_son0"/)$ = set_varAtts(sc_arr_hi(9,:,:),"nino3.4 sst El Nino spatial composite (SON+0)","","")
              z->$(/"nino34_elnino_spacomp_sst_djf1"/)$ = set_varAtts(sc_arr_hi(12,:,:),"nino3.4 sst El Nino spatial composite (DJF+1)","","")
              z->$(/"nino34_elnino_spacomp_sst_mam1"/)$ = set_varAtts(sc_arr_hi(15,:,:),"nino3.4 sst El Nino spatial composite (MAM+1)","","")

              z->$(/"nino34_lanina_spacomp_sst_jja0"/)$ = set_varAtts(sc_arr_lo(6,:,:),"nino3.4 sst La Nina spatial composite (JJA+0)","","")
              z->$(/"nino34_lanina_spacomp_sst_son0"/)$ = set_varAtts(sc_arr_lo(9,:,:),"nino3.4 sst La Nina spatial composite (SON+0)","","")
              z->$(/"nino34_lanina_spacomp_sst_djf1"/)$ = set_varAtts(sc_arr_lo(12,:,:),"nino3.4 sst La Nina spatial composite (DJF+1)","","")
              z->$(/"nino34_lanina_spacomp_sst_mam1"/)$ = set_varAtts(sc_arr_lo(15,:,:),"nino3.4 sst La Nina spatial composite (MAM+1)","","")

              z->$(/"indian_ocean_dipole_pattern_mon"/)$  = set_varAtts(iod_regr,"Indian Ocean Dipole Index sst regression pattern (monthly)","","")
           end if
           if (hh.ge.1) then
              z_arr = addfile(fnt,"c")
              z_arr@source = "NCAR Climate Analysis Section's Climate Variability Diagnostics Package - LE v"+getenv("VERSION")
              z_arr@Conventions = "CF-1.6"
           end if
           if (hh.eq.1) then
              z_arr@notes = "Data from "+names_tas(ee)+" from "+syear_tas(ee)+"-"+eyear_tas(ee)
              z_arr@climatology = syear_tas(ee)+"-"+eyear_tas(ee)+" climatology removed prior to all calculations (other than means)"
              z_arr->$(/"nino34_spacomp_tas_jja0"/)$ = set_varAtts(n34sc_arr(6,:,:),"nino3.4 tas EN-LN spatial composite (JJA+0)","","")
              z_arr->$(/"nino34_spacomp_tas_son0"/)$ = set_varAtts(n34sc_arr(9,:,:),"nino3.4 tas EN-LN spatial composite (SON+0)","","")
              z_arr->$(/"nino34_spacomp_tas_djf1"/)$ = set_varAtts(n34sc_arr(12,:,:),"nino3.4 tas EN-LN spatial composite (DJF+1)","","")
              z_arr->$(/"nino34_spacomp_tas_mam1"/)$ = set_varAtts(n34sc_arr(15,:,:),"nino3.4 tas EN-LN spatial composite (MAM+1)","","") 

              z_arr->$(/"nino34_elnino_spacomp_tas_jja0"/)$ = set_varAtts(sc_arr_hi(6,:,:),"nino3.4 tas El Nino spatial composite (JJA+0)","","")
              z_arr->$(/"nino34_elnino_spacomp_tas_son0"/)$ = set_varAtts(sc_arr_hi(9,:,:),"nino3.4 tas El Nino spatial composite (SON+0)","","")
              z_arr->$(/"nino34_elnino_spacomp_tas_djf1"/)$ = set_varAtts(sc_arr_hi(12,:,:),"nino3.4 tas El Nino spatial composite (DJF+1)","","")
              z_arr->$(/"nino34_elnino_spacomp_tas_mam1"/)$ = set_varAtts(sc_arr_hi(15,:,:),"nino3.4 tas El Nino spatial composite (MAM+1)","","")

              z_arr->$(/"nino34_lanina_spacomp_tas_jja0"/)$ = set_varAtts(sc_arr_lo(6,:,:),"nino3.4 tas La Nina spatial composite (JJA+0)","","")
              z_arr->$(/"nino34_lanina_spacomp_tas_son0"/)$ = set_varAtts(sc_arr_lo(9,:,:),"nino3.4 tas La Nina spatial composite (SON+0)","","")
              z_arr->$(/"nino34_lanina_spacomp_tas_djf1"/)$ = set_varAtts(sc_arr_lo(12,:,:),"nino3.4 tas La Nina spatial composite (DJF+1)","","")
              z_arr->$(/"nino34_lanina_spacomp_tas_mam1"/)$ = set_varAtts(sc_arr_lo(15,:,:),"nino3.4 tas La Nina spatial composite (MAM+1)","","") 

              z_arr->$(/"indian_ocean_dipole_tas_regression_mon"/)$  = set_varAtts(iod_regr,"Indian Ocean Dipole Index tas regression pattern (monthly)","","")
           end if
           if (hh.eq.2) then
              z_arr@notes = "Data from "+names_psl(ee)+" from "+syear_psl(ee)+"-"+eyear_psl(ee)
              z_arr@climatology = syear_psl(ee)+"-"+eyear_psl(ee)+" climatology removed prior to all calculations (other than means)"
              z_arr->$(/"nino34_spacomp_psl_jja0"/)$ = set_varAtts(n34sc_arr(6,:,:),"nino3.4 psl EN-LN spatial composite (JJA+0)","","")
              z_arr->$(/"nino34_spacomp_psl_son0"/)$ = set_varAtts(n34sc_arr(9,:,:),"nino3.4 psl EN-LN spatial composite (SON+0)","","")
              z_arr->$(/"nino34_spacomp_psl_djf1"/)$ = set_varAtts(n34sc_arr(12,:,:),"nino3.4 psl EN-LN spatial composite (DJF+1)","","")
              z_arr->$(/"nino34_spacomp_psl_mam1"/)$ = set_varAtts(n34sc_arr(15,:,:),"nino3.4 psl EN-LN spatial composite (MAM+1)","","")  

              z_arr->$(/"nino34_elnino_spacomp_psl_jja0"/)$ = set_varAtts(sc_arr_hi(6,:,:),"nino3.4 psl El Nino spatial composite (JJA+0)","","")
              z_arr->$(/"nino34_elnino_spacomp_psl_son0"/)$ = set_varAtts(sc_arr_hi(9,:,:),"nino3.4 psl El Nino spatial composite (SON+0)","","")
              z_arr->$(/"nino34_elnino_spacomp_psl_djf1"/)$ = set_varAtts(sc_arr_hi(12,:,:),"nino3.4 psl El Nino spatial composite (DJF+1)","","")
              z_arr->$(/"nino34_elnino_spacomp_psl_mam1"/)$ = set_varAtts(sc_arr_hi(15,:,:),"nino3.4 psl El Nino spatial composite (MAM+1)","","")

              z_arr->$(/"nino34_lanina_spacomp_psl_jja0"/)$ = set_varAtts(sc_arr_lo(6,:,:),"nino3.4 psl La Nina spatial composite (JJA+0)","","")
              z_arr->$(/"nino34_lanina_spacomp_psl_son0"/)$ = set_varAtts(sc_arr_lo(9,:,:),"nino3.4 psl La Nina spatial composite (SON+0)","","")
              z_arr->$(/"nino34_lanina_spacomp_psl_djf1"/)$ = set_varAtts(sc_arr_lo(12,:,:),"nino3.4 psl La Nina spatial composite (DJF+1)","","")
              z_arr->$(/"nino34_lanina_spacomp_psl_mam1"/)$ = set_varAtts(sc_arr_lo(15,:,:),"nino3.4 psl La Nina spatial composite (MAM+1)","","") 

              z_arr->$(/"indian_ocean_dipole_psl_regression_mon"/)$  = set_varAtts(iod_regr,"Indian Ocean Dipole Index psl regression pattern (monthly)","","")
           end if
           if (hh.eq.3) then
              z_arr@notes = "Data from "+names_pr(ee)+" from "+syear_pr(ee)+"-"+eyear_pr(ee)
              z_arr@climatology = syear_pr(ee)+"-"+eyear_pr(ee)+" climatology removed prior to all calculations (other than means)"
              z_arr->$(/"nino34_spacomp_pr_jja0"/)$ = set_varAtts(n34sc_arr(6,:,:),"nino3.4 pr EN-LN spatial composite (JJA+0)","","")
              z_arr->$(/"nino34_spacomp_pr_son0"/)$ = set_varAtts(n34sc_arr(9,:,:),"nino3.4 pr EN-LN spatial composite (SON+0)","","")
              z_arr->$(/"nino34_spacomp_pr_djf1"/)$ = set_varAtts(n34sc_arr(12,:,:),"nino3.4 pr EN-LN spatial composite (DJF+1)","","")
              z_arr->$(/"nino34_spacomp_pr_mam1"/)$ = set_varAtts(n34sc_arr(15,:,:),"nino3.4 pr EN-LN spatial composite (MAM+1)","","")  

              z_arr->$(/"nino34_elnino_spacomp_pr_jja0"/)$ = set_varAtts(sc_arr_hi(6,:,:),"nino3.4 pr El Nino spatial composite (JJA+0)","","")
              z_arr->$(/"nino34_elnino_spacomp_pr_son0"/)$ = set_varAtts(sc_arr_hi(9,:,:),"nino3.4 pr El Nino spatial composite (SON+0)","","")
              z_arr->$(/"nino34_elnino_spacomp_pr_djf1"/)$ = set_varAtts(sc_arr_hi(12,:,:),"nino3.4 pr El Nino spatial composite (DJF+1)","","")
              z_arr->$(/"nino34_elnino_spacomp_pr_mam1"/)$ = set_varAtts(sc_arr_hi(15,:,:),"nino3.4 pr El Nino spatial composite (MAM+1)","","")

              z_arr->$(/"nino34_lanina_spacomp_pr_jja0"/)$ = set_varAtts(sc_arr_lo(6,:,:),"nino3.4 pr La Nina spatial composite (JJA+0)","","")
              z_arr->$(/"nino34_lanina_spacomp_pr_son0"/)$ = set_varAtts(sc_arr_lo(9,:,:),"nino3.4 pr La Nina spatial composite (SON+0)","","")
              z_arr->$(/"nino34_lanina_spacomp_pr_djf1"/)$ = set_varAtts(sc_arr_lo(12,:,:),"nino3.4 pr La Nina spatial composite (DJF+1)","","")
              z_arr->$(/"nino34_lanina_spacomp_pr_mam1"/)$ = set_varAtts(sc_arr_lo(15,:,:),"nino3.4 pr La Nina spatial composite (MAM+1)","","") 

              z_arr->$(/"indian_ocean_dipole_pr_regression_mon"/)$  = set_varAtts(iod_regr,"Indian Ocean Dipole Index pr regression pattern (monthly)","","")
           end if
           if (hh.eq.4) then
              z_arr@notes = "Data from "+names_zos(ee)+" from "+syear_zos(ee)+"-"+eyear_zos(ee)
              z_arr@climatology = syear_zos(ee)+"-"+eyear_zos(ee)+" climatology removed prior to all calculations (other than means)"

              if (isatt(n34sc_arr,"lat2d")) then    ; if there is a lat2d there will be a lon2d
                 LAT2D = n34sc_arr@lat2d
                 LON2D = n34sc_arr@lon2d
                 delete([/n34sc_arr@lat2d,n34sc_arr@lon2d,sc_arr_hi@lat2d,sc_arr_hi@lon2d,sc_arr_lo@lat2d,sc_arr_lo@lon2d,iod_regr@lat2d,iod_regr@lon2d/])
                 copy_VarCoords(n34sc_arr(0,:,:),LAT2D)
                 copy_VarCoords(n34sc_arr(0,:,:),LON2D)
                 z_arr->$(/"lat2d_ocean"/)$ = set_varAtts(LAT2D,"ocean grid 2-dimensional latitudes","degrees_north","")
                 z_arr->$(/"lon2d_ocean"/)$ = set_varAtts(LON2D,"ocean grid 2-dimensional longitudes","degrees_east","")
                 delete([/LAT2D,LON2D/])
                 n34sc_arr@coordinates ="lat2d_ocean lon2d_ocean"
                 sc_arr_hi@coordinates ="lat2d_ocean lon2d_ocean"
                 sc_arr_lo@coordinates ="lat2d_ocean lon2d_ocean"
                 iod_regr@coordinates  ="lat2d_ocean lon2d_ocean"
              end if  
              if (isvar("hov_hi_zos")) then
                 z_arr->$(/"nino34_hov_elnino_zos"/)$ = set_varAtts(hov_hi_zos,"nino3.4 El Nino Hovmoller zos composite","","")
                 z_arr->$(/"nino34_hov_lanina_zos"/)$ = set_varAtts(hov_lo_zos,"nino3.4 La Nina Hovmoller zos composite","","")
                 delete([/hov_hi_zos,hov_lo_zos/])
              end if
              z_arr->$(/"nino34_spacomp_zos_jja0"/)$ = set_varAtts(n34sc_arr(6,:,:),"nino3.4 zos EN-LN spatial composite (JJA+0)","","")
              z_arr->$(/"nino34_spacomp_zos_son0"/)$ = set_varAtts(n34sc_arr(9,:,:),"nino3.4 zos EN-LN spatial composite (SON+0)","","")
              z_arr->$(/"nino34_spacomp_zos_djf1"/)$ = set_varAtts(n34sc_arr(12,:,:),"nino3.4 zos EN-LN spatial composite (DJF+1)","","")
              z_arr->$(/"nino34_spacomp_zos_mam1"/)$ = set_varAtts(n34sc_arr(15,:,:),"nino3.4 zos EN-LN spatial composite (MAM+1)","","")  

              z_arr->$(/"nino34_elnino_spacomp_zos_jja0"/)$ = set_varAtts(sc_arr_hi(6,:,:),"nino3.4 zos El Nino spatial composite (JJA+0)","","")
              z_arr->$(/"nino34_elnino_spacomp_zos_son0"/)$ = set_varAtts(sc_arr_hi(9,:,:),"nino3.4 zos El Nino spatial composite (SON+0)","","")
              z_arr->$(/"nino34_elnino_spacomp_zos_djf1"/)$ = set_varAtts(sc_arr_hi(12,:,:),"nino3.4 zos El Nino spatial composite (DJF+1)","","")
              z_arr->$(/"nino34_elnino_spacomp_zos_mam1"/)$ = set_varAtts(sc_arr_hi(15,:,:),"nino3.4 zos El Nino spatial composite (MAM+1)","","")

              z_arr->$(/"nino34_lanina_spacomp_zos_jja0"/)$ = set_varAtts(sc_arr_lo(6,:,:),"nino3.4 zos La Nina spatial composite (JJA+0)","","")
              z_arr->$(/"nino34_lanina_spacomp_zos_son0"/)$ = set_varAtts(sc_arr_lo(9,:,:),"nino3.4 zos La Nina spatial composite (SON+0)","","")
              z_arr->$(/"nino34_lanina_spacomp_zos_djf1"/)$ = set_varAtts(sc_arr_lo(12,:,:),"nino3.4 zos La Nina spatial composite (DJF+1)","","")
              z_arr->$(/"nino34_lanina_spacomp_zos_mam1"/)$ = set_varAtts(sc_arr_lo(15,:,:),"nino3.4 zos La Nina spatial composite (MAM+1)","","") 

              z_arr->$(/"indian_ocean_dipole_zos_regression_mon"/)$  = set_varAtts(iod_regr,"Indian Ocean Dipole Index zos regression pattern (monthly)","","")
           end if
           delete([/iod_regr/])
           if (hh.ge.1) then
              delete(z_arr)
           end if
        end if
     end do
     delete([/iod/])
;-----------------------------------------------------------------------------------------
;   nino3.4 spectra

     iopt = 0                ; nino3.4 power spectra
     jave = (7*nyr(ee))/100
     pct = 0.1 
     spectra_mvf = False        ; missing value flag for nino3.4
     if (any(ismissing(nino34))) then     ; check for missing data                                                            
        spectra_mvf = True
     else
        sdof = specx_anal(nino34,iopt,jave,pct)
        mval = sum(1/(1.+((sdof@xlag1)^2)-((2*sdof@xlag1)*cos(6.28318*sdof@frq))))
        if (mval.eq.0) then ; check for cyclic data that results in sum of Markov elements = 0.
           spectra_mvf = True
        else
           splt1 = specx_ci(sdof,val1,val2)
           splt1!0 = "ncurves"
           splt1&ncurves = ispan(0,3,1)
           splt1&ncurves@long_name = "power spectra curves"
           splt1&ncurves@units = "1"
           splt1!1 = "frequency"
           splt1&frequency = sdof@frq
           splt1&frequency@long_name = "power spectra frequency"
           splt1&frequency@units = "1"
           splt1@units_info = "df refers to frequency interval"
           splt1@units = "C^2/df"
           splt1@comment_cvdp = "(0,:)=spectrum,(1,:)=Markov red noise spectrum, (2,:)="+val1+"% confidence bound for Markhov, (3,:)="+val2+"% confidence bound for Markhov"
           splt1@detrend_option = nino34@detrend_option
        end if
        delete([/iopt,jave,pct,mval/])
     end if
;-----------------------------------------------------------------------
;    nino3.4 wavelet analysis, autocorrelation

     if (spectra_mvf.eq.False) then
        N    = dimsizes(nino34)       
        mother  = 0
        param   = 6.0
        dt      = 1./12.            
        s0      = dt
        dj      = 1./12.
        jtot    = 1+floattointeger(((log10(N*dt/s0))/dj)/log10(2.))
        npad    = N
        nadof   = 0
        noise   = 1 
        siglvl  = .05
        isigtest= 0
        wave34 = wavelet(nino34,mother,dt,param,s0,dj,jtot,npad,noise,isigtest,siglvl,nadof)

        power34            = onedtond(wave34@power,(/jtot,N/))
        power34!0          = "period"                    
        power34&period     = wave34@period
        power34&period@long_name = "wavelet period"
        power34&period@units = "1"
        power34!1          = "time"                     
        power34&time       = nino34&time
        power34@units      = nino34@units+"^2"
        power34@detrend_option = nino34@detrend_option

        coi                = wave34@coi
        coi!0              = "time"
        coi&time           = nino34&time
        coi@units          = ""
        coi@long_name      = "wavelet cone of influence"


        sig34              = power34                       
        sig34              = power34/conform (power34,wave34@signif,0)
        sig34@long_name    = "wavelet significance"
        sig34@units        = ""

        delete([/N,mother,param,dt,s0,dj,jtot,npad,nadof,noise,siglvl,isigtest/])

        ac34 = esacr(nino34,48)
        time_mon3 = ispan(0,48,1)
        time_mon3@units = "months since 0000-01-01 00:00:00"
        time_mon3@long_name = "Time"
        time_mon3@standard_name = "time"
        time_mon3@calendar = "standard"
        time_mon3!0 = "time_mon3"
        time_mon3&time_mon3 = time_mon3
        ac34!0 = "time_mon3"
        ac34&time_mon3 = time_mon3
        ac34@units = "1"
        ac34@detrend_option = nino34@detrend_option
        z->$(/"nino34_spectra"/)$ = set_varAtts(splt1,"nino3.4 power spectra","","")
        z->$(/"nino34_autocorrelation"/)$ = set_varAtts(ac34,"nino3.4 autocorrelation","","")
        z->$(/"nino34_wavelet_power"/)$ = set_varAtts(power34,"nino3.4 wavelet power","","")
        z->$(/"nino34_wavelet_significance"/)$ = set_varAtts(sig34,"nino3.4 wavelet significance","","")
        z->$(/"nino34_wavelet_coi"/)$ = set_varAtts(coi,"nino3.4 wavelet cone of influence","","")
        delete([/splt1,sig34,power34,ac34,wave34,coi/])
     end if
     delete([/z,nino34/])
  end do

  if (CREATE_GRAPHICS.eq."False") then
     print("Finished: sst.indices.ncl")
     exit
  end if
;==========================================================================================
  wks_type = OUTPUT_TYPE
  if (wks_type.eq."png") then
     wks_type@wkWidth = 1500*PNG_SCALE
     wks_type@wkHeight = 1500*PNG_SCALE
  end if

  pres = True     ; individual simulation spectra resource list
  pres@vpHeightF = 0.6
  pres@vpWidthF = 0.6
  pres@trYMinF = 0.
  pres@trXMinF = 0.0
  pres@trXMaxF = 0.0832
  pres@tiYAxisString = "Power"              ; yaxis
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
  pres@tmXBMode   = "Explicit"            
  pres@tmXTValues = (/".00167",".00833",".01667",".02778",".0416",".0556",".0832"/)
  pres@tmXTLabels = (/"50","10","5","3","2","1.5","1"/)           
  pres@tmXBValues = (/".0",".01",".02",".03",".042",".056",".083"/)
  pres@tmXBLabels =  pres@tmXBValues
  pres@tmYLMode = "Explicit"
  pres@tmXTLabelFontHeightF = 0.021
  pres@tmXBLabelFontHeightF = 0.021
  pres@tmYLLabelFontHeightF = 0.021
  pres@tiYAxisString = "Power (~S~o~N~C~S~2~N~ / cycles mo~S~-1~N~)"              ; yaxis
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

  pres2 = pres   ; resource list for shaded range of spectra
  pres2@xyLineColors        := (/"transparent","transparent"/)       
  pres2@xyCurveDrawOrder = "PreDraw"
  pres2@xyDashPattern      = 0
  pres2@gsnXYOpacities = 0.7
  pres2@xyLineColor = "transparent"

  txres = True
  txres@txFontHeightF = 0.010
  txres@txFontColor = "gray60"

  panres = True   ; panel resource list for individual simulations
  panres@gsnMaximize = True  
  panres@gsnPaperOrientation = "portrait"
  panres@gsnMainPanelFontHeightF = 0.009
  panres@gsnPanelBottom = 0.05
  ncol = floattointeger(sqrt(nsim))
  nrow = (nsim/ncol)+mod(nsim,ncol)
  nEM = max(EM_num)
  ncolE = floattointeger(sqrt(nEM+1))   ; +1 for the summary plot
  nrowE = ((nEM+1)/ncolE)+mod(nEM+1,ncolE)
  panres2 = panres  ; summary plot panel resource list
  panres2@gsnFrame = False
  panres2@gsnMaximize = False
  panres2@gsnMainPanelFontHeightF = 0.007

  csubtitle_color = set_subtitle_colors(max(EM_num))

  wks = gsn_open_wks(wks_type,getenv("OUTDIR")+"nino34.powspec")

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

  if (numobs.eq.0) then
     fnt = getenv("OUTDIR")+"obs.cvdp_data.sst.indices."+syear(0)+"-"+eyear(0)+".nc"
     fnt2 = getenv("OUTDIR")+"obs.cvdp_data."+syear(0)+"-"+eyear(0)+".nc"
     cntr = 0
  else
     fnt = getenv("OUTDIR")+modname(0)+".cvdp_data.sst.indices."+syear(0)+"-"+eyear(0)+".nc"
     fnt2 = getenv("OUTDIR")+modname(0)+".cvdp_data."+syear(0)+"-"+eyear(0)+".nc"
     cntr = 1
  end if
  obs0 := read_cvdp_le_data(fnt,fnt2,"nino34_spectra")

  if (isatt(obs0,"is_all_missing")) then
     obs0New = new((/4,11/),float)
     copy_VarAtts(obs0,obs0New)
     obs0 := obs0New
     delete(obs0New)
     obs0!1 = "frequency"
     obs0&frequency = fspan(0,0.1,11)
  end if

  if (wks_type.eq."png") then
     pres@xyLineThicknesses   = (/7.5,2.,1.,1./) 
  else
     pres@xyLineThicknesses   = (/2.5,1.5,1.,1./) 
  end if
  if (.not.isatt(obs0,"is_all_missing")) then
    pres = powspec_set_yaxis(max(obs0(0,:)),pres)
  end if
  pres@gsnLeftString = ""  
  pres@gsnCenterString = names(0)   
  pres@gsnRightString = syear(0)+"-"+eyear(0)+"   "  
  plot_indmem(0) = gsn_csm_xy(wks,obs0&frequency,obs0,pres)
  cntr_EM = 0
  if (numobs.ge.2) then     ; plot obs #2-
     do ff = 1,numobs-1
        fnt = getenv("OUTDIR")+modname(cntr)+".cvdp_data.sst.indices."+syear(cntr)+"-"+eyear(cntr)+".nc"
        fnt2 = getenv("OUTDIR")+modname(cntr)+".cvdp_data."+syear(cntr)+"-"+eyear(cntr)+".nc"
        arr := read_cvdp_le_data(fnt,fnt2,"nino34_spectra")
        if (isatt(arr,"is_all_missing")) then
           cntr = cntr+1
           continue
        end if
        pres@xyLineColors        = (/"foreground","red","blue","green"/)      
        pres = powspec_set_yaxis(max((/max(obs0(0,:)),max(arr(0,:))/)),pres)
        pres@gsnCenterString = names(cntr)   
        pres@gsnRightString = syear(cntr)+"-"+eyear(cntr)+"   " 
        plot_indmem(cntr) = gsn_csm_xy(wks,arr&frequency,arr,pres)
        pres@xyCurveDrawOrder = "PreDraw"
        pres@xyLineColors        = (/"gray50","black","black","black"/)
        plot_obs_overlay(cntr)   = gsn_csm_xy(wks,obs0&frequency,obs0(0,:),pres)
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

        fnt = getenv("OUTDIR")+modname_mod+".cvdp_data.sst.indices."+syear_mod+"-"+eyear_mod+".nc"
        fnt2 = getenv("OUTDIR")+modname_mod+".cvdp_data."+syear_mod+"-"+eyear_mod+".nc"
        arr := read_cvdp_le_data(fnt,fnt2,"nino34_spectra")
        if (isatt(arr,"is_all_missing")) then
           cntr = cntr+1
           continue
        end if
        if (.not.isvar("arr_store")) then  ; create an array to house all members, to be used to calculate EM
           arr_store = new((/nens,dimsizes(arr&frequency)/),typeof(arr))
           arr_store!0 = "ensmem"
           arr_store!1 = "frequency"
           arr_store&frequency = arr&frequency
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
        arr_store@nens = arr_store@nens+1
        if (gg.ge.1) then
           pres@gsnCenterStringFontColor = csubtitle_color(gg-1)
        end if
        pres@xyLineColors        = (/"foreground","red","blue","green"/)      
        pres = powspec_set_yaxis(max((/max(obs0(0,:)),max(arr(0,:))/)),pres)
        pres@gsnCenterString = names_mod   
        pres@gsnRightString = syear_mod+"-"+eyear_mod+"   "
        plot_indmem(cntr) = gsn_csm_xy(wks,arr&frequency,arr,pres)
        pres@xyCurveDrawOrder = "PreDraw"
        pres@xyLineColors        = (/"gray50","black","black","black"/)
        plot_obs_overlay(cntr)   = gsn_csm_xy(wks,obs0&frequency,obs0(0,:),pres)
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

     pres2@gsnCenterStringFontColor = csubtitle_color(gg-1)
     pres2@gsnCenterString = names_EM_mod +" ("+arr_store@nens+" Members)"    
     pres@gsnRightString = ""
     pres2 = powspec_set_yaxis(max((/max(obs0(0,:)),max(arr_range2(1,:)),max(arr_EM)/)),pres2)
     pres = powspec_set_yaxis(max((/max(obs0(0,:)),max(arr_range2(1,:)),max(arr_EM)/)),pres)
     pres2@gsnXYFillColors = (/30/356.,144/256.,1.,0.25/)  ;"dodgerblue"
     if (all(ismissing(arr_range2(0,:)))) then  ; necessary as gsnXYFillColors causes NCL to fail when data all missing
        delete(pres2@gsnXYFillColors)
     end if
     plot_summary(cntr_EM) = gsn_csm_xy(wks,arr_range2&frequency,arr_range2,pres2)
     pres2@gsnXYFillColors = (/30/356.,144/256.,1.,0.5/)  ;"dodgerblue"
     if (all(ismissing(arr_range1(0,:)))) then  ; necessary as gsnXYFillColors causes NCL to fail when data all missing
        delete(pres2@gsnXYFillColors)
     end if
     plot_summary2(cntr_EM) = gsn_csm_xy(wks,arr_range1&frequency,arr_range1,pres2)
     pres_sumA@xyLineColors        = (/"dodgerblue4","black","black","black"/)
     plot_summary_em(cntr_EM) = gsn_csm_xy(wks,arr_EM&frequency,arr_EM,pres_sumA)
     pres_sumA@xyLineColors        = (/"gray50","black","black","black"/)
     plot_obs_summary(cntr_EM) = gsn_csm_xy(wks,obs0&frequency,obs0(0,:),pres_sumA)
     pres_sumA@xyLineColors = (/csubtitle_color(gg-1),"black","black","black"/)
     plot_sum(cntr_EM) = gsn_csm_xy(wks,arr_EM&frequency,arr_EM,pres_sumA)

     overlay(plot_summary(cntr_EM),plot_summary2(cntr_EM))
     overlay(plot_summary(cntr_EM),plot_obs_summary(cntr_EM))
     overlay(plot_summary(cntr_EM),plot_summary_em(cntr_EM))
     fout = getenv("OUTDIR")+str_sub_str(names_EM_mod," ","_")+"_EM.cvdp_data.sst.indices."+syear_mod+"-"+eyear_mod+".nc"
     if (isfilepresent2(fout)) then
        z = addfile(fout,"w")
     else
        z = addfile(fout,"c")
        set_global_ncfile_attributes(z,names_EM_mod,syear_mod,eyear_mod,getenv("VERSION"))
     end if
     z->$(/"nino34_spectra_em"/)$ = set_varAtts(arr_EM,arr_EM@long_name+" Ensemble Mean","","")
     z->$(/"nino34_spectra_2575range"/)$ = set_varAtts(arr_range1,arr_EM@long_name+" 25/75% range","","")
     z->$(/"nino34_spectra_1090range"/)$ = set_varAtts(arr_range2,arr_EM@long_name+" 10/90% range","","")
     delete([/arr_store,arr_EM,arr_range1,arr_range2/])
     cntr_EM = cntr_EM+1
  end do
  panres@txString = "Nin~H-13V2F35~D~FV-2H3F21~o3.4 SST Power Spectra (Monthly)"
  gsn_panel2(wks,plot_indmem,(/nrow,ncol/),panres)

  if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
     pres_sumA@xyCurveDrawOrder = "PostDraw"
     pres_sumA@xyLineColors        = (/"gray50","black","black","black"/)
     pres_sumA@gsnCenterString = "Ensemble Mean Summary"
     pres_sumA@gsnRightString = ""
     plot_obs := gsn_csm_xy(wks,obs0&frequency,obs0(0,:),pres_sumA)
     YMaxF = YMaxF + (YMaxF*.05)
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
           "trYMaxF" : YMaxF
        end setvalues
        plot_final(nEM)    = plot_sum(ii_ind)
     end if
     panres2@gsnPanelMainPosYF = set_panel_title_YF(nEM+1,pres)
     panres2@gsnPanelMainString = "Ensemble Summary: "+"Nin~H-13V2F35~D~FV-2H3F21~o3.4 SST Power Spectra (Monthly)"
     gsn_panel2(wks,plot_final,(/nrowE,ncolE/),panres2)
     if (numobs.ne.0) then  
        gsn_text_ndc(wks,names(0)+" "+syear(0)+"-"+eyear(0),0.5,panres2@gsnPanelMainPosYF-.02,txres)
     end if
     frame(wks)
     delete(plot_summary)
  end if
  delete([/wks,plot_indmem,pres,pres2,txres/])

  if (wks_type.eq."png") then
     if (nEM.lt.1) then   ; in ensemble mode (runstyle=2)
        system("mv "+OUTDIR+"nino34.powspec.png "+OUTDIR+"nino34.powspec.indmem.png")
     else
        system("mv "+OUTDIR+"nino34.powspec.000001.png "+OUTDIR+"nino34.powspec.indmem.png")
        system("mv "+OUTDIR+"nino34.powspec.000002.png "+OUTDIR+"nino34.powspec.summary.png")
        if (PNG_SCALE_SUMMARY.ne.100) then
           system(IM_COMMAND+" "+OUTDIR+"nino34.powspec.summary.png -resize "+PNG_SCALE_SUMMARY+"% "+OUTDIR+"nino34.powspec.summary.png")
        end if
     end if
  else
     system("psplit "+OUTDIR+"nino34.powspec.ps "+OUTDIR+"nino34.powspec")
     system("mv "+OUTDIR+"nino34.powspec0001.ps "+OUTDIR+"nino34.powspec.indmem.ps")
     if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
        system("mv "+OUTDIR+"nino34.powspec0002.ps "+OUTDIR+"nino34.powspec.summary.ps")
     end if
     system("rm "+OUTDIR+"nino34.powspec.ps")
  end if
;-------------------------------------------------------------------------------------------------------------------
; Autocorrelation plotting section
;
  xyres = True
  xyres@gsnDraw = False
  xyres@gsnFrame = False
  xyres@vpHeightF = 0.6
  xyres@vpWidthF = 0.6
  xyres@gsnYRefLine = 0.0
  xyres@gsnYRefLineColor = "gray42"
  xyres@tiYAxisString = ""
  xyres@tiMainOn = False
  xyres@trXMinF = 0.0
  xyres@trXMaxF = 48.0
  xyres@trYMinF = -1.05
  xyres@trYMaxF = 1.05
  if (wks_type.eq."png") then
     xyres@xyLineThicknessF = 7.5
  else
     xyres@xyLineThicknessF = 2.5
  end if
  xyres@xyLineColor = "black"
  xyres@gsnAboveYRefLineColor = "firebrick2"
  xyres@gsnBelowYRefLineColor = "dodgerblue3"
  xyres@tmYLMode = "Explicit"
  xyres@tmYLValues := (/-1,-0.5,0,0.5,1/)
  xyres@tmYLLabels := (/"-1","-0.5","0","0.5","1"/)
  xyres@tmYLMinorValues = fspan(-1,1,9)
  xyres@tmXBMode = "Explicit"
  xyres@tmXBValues = (/0,12,24,36,48/)
  xyres@tmXBLabels = (/"0","12","24","36","48"/)
  xyres@tmXBLabelFontHeightF = 0.021
  xyres@tmYLLabelFontHeightF = 0.021
  xyres@gsnLeftStringFontHeightF = 0.025
  xyres@gsnCenterStringFontHeightF = 0.025
  xyres@gsnRightStringFontHeightF = 0.021    
  xyres@gsnRightStringOrthogonalPosF = -0.115
  xyres@gsnRightStringParallelPosF = 0.96
  xyres@gsnCenterStringOrthogonalPosF = 0.025
  xyres@gsnLeftString = ""
  xyres@gsnCenterString = ""
  xyres@gsnRightString = ""

  xyres_obs = xyres
  delete([/xyres_obs@gsnAboveYRefLineColor,xyres_obs@gsnBelowYRefLineColor/])
  xyres_obs@xyLineColor = "gray62"
  xyres_obs@xyCurveDrawOrder = "PreDraw"

  xyres2 = xyres
  delete([/xyres2@gsnAboveYRefLineColor,xyres2@gsnBelowYRefLineColor,xyres2@xyLineColor/])
  xyres2@xyLineColors        := (/"transparent","transparent"/)       
  xyres2@xyCurveDrawOrder = "PreDraw"
  xyres2@xyDashPattern      = 0
  xyres2@gsnXYOpacities = 0.7
  xyres2@xyLineColor = "transparent"


  txres = True
  txres@txFontHeightF = 0.010
  txres@txFontColor = "gray60"

  wks = gsn_open_wks(wks_type,getenv("OUTDIR")+"nino34.autocor")
  plot_indmem      := new(nsim,"graphic")
  plot_obs_overlay := new(nsim,"graphic")
  if (nEM.ge.1) then
     plot_summary     := new(nEM,"graphic")    ; for ensemble plots to show the 10-90% range
     plot_summary2    := new(nEM,"graphic")   ; for ensemble plots to show the 25-75% range
     plot_obs_summary := new(nEM,"graphic")    ; for ensemble plots to show the 1st observational dataset
     plot_summary_em  := new(nEM,"graphic")    ; for ensemble plots to show ensemble mean
     plot_sum         := new(nEM,"graphic")    ; for individual panel in ensemble plots showing each ensemble mean
  end if

  numobs = num(EM_num.eq.0) 
  if (numobs.eq.0) then
     fnt = getenv("OUTDIR")+"obs.cvdp_data.sst.indices."+syear(0)+"-"+eyear(0)+".nc"
     fnt2 = getenv("OUTDIR")+"obs.cvdp_data."+syear(0)+"-"+eyear(0)+".nc"
     cntr = 0
  else
     fnt = getenv("OUTDIR")+modname(0)+".cvdp_data.sst.indices."+syear(0)+"-"+eyear(0)+".nc"
     fnt2 = getenv("OUTDIR")+modname(0)+".cvdp_data."+syear(0)+"-"+eyear(0)+".nc"
     cntr = 1
  end if
  obs0 := read_cvdp_le_data(fnt,fnt2,"nino34_autocorrelation")
  if (isatt(obs0,"is_all_missing")) then
     obs0New = new(6,float)
     copy_VarAtts(obs0,obs0New)
     obs0 := obs0New
     delete(obs0New)
     obs0!0 = "time_mon3"
     obs0&time_mon3 = ispan(0,50,10)
  end if

  xyres@gsnCenterString = names(0)   
  xyres@gsnRightString = syear(0)+"-"+eyear(0)  
  plot_indmem(0) = gsn_csm_xy(wks,obs0&time_mon3,obs0,xyres)   ; plot first observational set
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
        fnt = getenv("OUTDIR")+modname(cntr)+".cvdp_data.sst.indices."+syear(cntr)+"-"+eyear(cntr)+".nc"
        fnt2 = getenv("OUTDIR")+modname(cntr)+".cvdp_data."+syear(cntr)+"-"+eyear(cntr)+".nc"
        arr := read_cvdp_le_data(fnt,fnt2,"nino34_autocorrelation")
        if (isatt(arr,"is_all_missing")) then
           cntr = cntr+1
           continue
        end if
        xyres@gsnCenterString = names(cntr)   
        xyres@gsnRightString = syear(cntr)+"-"+eyear(cntr)+"  " 
        plot_indmem(cntr) = gsn_csm_xy(wks,arr&time_mon3,arr,xyres)
        plot_obs_overlay(cntr)   = gsn_csm_xy(wks,obs0&time_mon3,obs0,xyres_obs)
        overlay(plot_indmem(cntr),plot_obs_overlay(cntr))
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
     xyres@xyLineColor        = "black"
     nens = num(EM_num.eq.gg) ; determines how many model simulations in each ensemble
     cntr_ens := ind(EM_num.eq.gg)   ; cntr_ens(hh) are the indices where each ensemble member of an ensemble reside 
     do hh = 0,nens-1
        modname_mod = modname(cntr_ens(hh))
        syear_mod = syear(cntr_ens(hh))
        eyear_mod = eyear(cntr_ens(hh))
        names_mod = names(cntr_ens(hh))
        names_EM_mod = names_EM(cntr_ens(hh))

        fnt = getenv("OUTDIR")+modname_mod+".cvdp_data.sst.indices."+syear_mod+"-"+eyear_mod+".nc"
        fnt2 = getenv("OUTDIR")+modname_mod+".cvdp_data."+syear_mod+"-"+eyear_mod+".nc"
        arr := read_cvdp_le_data(fnt,fnt2,"nino34_autocorrelation")
        if (isatt(arr,"is_all_missing")) then
           cntr = cntr+1
           continue
        end if
        if (gg.ge.1) then
           xyres@gsnCenterStringFontColor = csubtitle_color(gg-1)
        end if
        xyres@gsnCenterString = names_mod  
        xyres@gsnRightString = syear_mod+"-"+eyear_mod+"  " 
        plot_indmem(cntr) = gsn_csm_xy(wks,arr&time_mon3,arr,xyres)
        plot_obs_overlay(cntr)   = gsn_csm_xy(wks,obs0&time_mon3,obs0,xyres_obs)
        overlay(plot_indmem(cntr),plot_obs_overlay(cntr))

        if (.not.isvar("arr_store")) then
           arr_store = new((/nens,dimsizes(arr)/),typeof(arr))
           arr_store!0 = "ensmem"
           arr_store!1 = "time_mon3"
           arr_store&time_mon3 = arr&time_mon3
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
        arr_store@nens = arr_store@nens+1
        cntr = cntr+1
     end do

     if (wks_type.eq."png") then
        xyres@xyLineThicknessF = 12.
        xyres_obs@xyLineThicknessF = 12.
     else
        xyres@xyLineThicknessF = 5.5
        xyres_obs@xyLineThicknessF = 5.5
     end if
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

     xyres2@gsnLeftString = ""
     if (showyr) then
        xyres2@gsnRightString = syear_em0+"-"+eyear_em0 
     else
        xyres2@gsnRightString = (eyear_em0-syear_em0+1)+"yrs" 
     end if
     delete([/syear_em0,eyear_em0,showyr/])

     xyres2@gsnCenterString = names_EM_mod +" ("+arr_store@nens+" Members)"  
     xyres2@gsnCenterStringFontColor = csubtitle_color(gg-1)  
     xyres2@gsnXYFillColors = (/30/356.,144/256.,1.,0.25/)  ;"dodgerblue"
     if (all(ismissing(arr_range2(0,:)))) then  ; necessary as gsnXYFillColors causes NCL to fail when data all missing
        delete(xyres2@gsnXYFillColors)
     end if
     plot_summary(cntr_EM) = gsn_csm_xy(wks,arr_EM&time_mon3,arr_range2,xyres2)
     xyres2@gsnXYFillColors = (/30/356.,144/256.,1.,0.5/)  ;"dodgerblue"
     if (all(ismissing(arr_range1(0,:)))) then  ; necessary as gsnXYFillColors causes NCL to fail when data all missing
        delete(xyres2@gsnXYFillColors)
     end if
     plot_summary2(cntr_EM) = gsn_csm_xy(wks,arr_EM&time_mon3,arr_range1,xyres2)
     xyres_obs@xyLineColor        = "dodgerblue4"
     plot_summary_em(cntr_EM) = gsn_csm_xy(wks,arr_EM&time_mon3,arr_EM,xyres_obs)
     xyres_obs@xyLineColor        = "gray50"
     plot_obs_summary(cntr_EM) = gsn_csm_xy(wks,obs0&time_mon3,obs0,xyres_obs)
     xyres_obs@xyLineColor        = csubtitle_color(gg-1)
     plot_sum(cntr_EM) = gsn_csm_xy(wks,arr_EM&time_mon3,arr_EM,xyres_obs)

     if (.not.any(ismissing(arr_EM))) then
        overlay(plot_summary(cntr_EM),plot_summary2(cntr_EM))
        overlay(plot_summary(cntr_EM),plot_obs_summary(cntr_EM))
        overlay(plot_summary(cntr_EM),plot_summary_em(cntr_EM))
     end if
     fout = getenv("OUTDIR")+str_sub_str(names_EM_mod," ","_")+"_EM.cvdp_data.sst.indices."+syear_mod+"-"+eyear_mod+".nc"
     if (isfilepresent2(fout)) then
        z = addfile(fout,"w")
     else
        z = addfile(fout,"c")
        set_global_ncfile_attributes(z,names_EM_mod,syear_mod,eyear_mod,getenv("VERSION"))
     end if
     z->$(/"nino34_autocorrelation_em"/)$ = set_varAtts(arr_EM,arr_EM@long_name+" Ensemble Mean","","")
     z->$(/"nino34_autocorrelation_2575range"/)$ = set_varAtts(arr_range1,arr_EM@long_name+" 25/75% range","","")
     z->$(/"nino34_autocorrelation_1090range"/)$ = set_varAtts(arr_range2,arr_EM@long_name+" 10/90% range","","")
     delete([/arr_store,arr_EM,arr_range1,arr_range2/])
     cntr_EM = cntr_EM+1
  end do
  panres@txString =  "Nin~H-13V2F35~D~FV-2H3F21~o3.4 Autocorrelation (Monthly)"
  gsn_panel2(wks,plot_indmem,(/nrow,ncol/),panres)

  if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
     xyres_obs@xyCurveDrawOrder = "PostDraw"
     xyres_obs@xyLineColor        = "gray50"
     xyres_obs@gsnCenterString = "Ensemble Mean Summary"
     xyres_obs@gsnRightString = ""
     plot_obs := gsn_csm_xy(wks,obs0&time_mon3,obs0,xyres_obs)

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
        plot_final(:nEM-1) = plot_summary
        plot_final(nEM)    = plot_sum(0)
     end if
     panres2@gsnPanelMainPosYF = set_panel_title_YF(nEM,xyres)
     panres2@gsnPanelMainString = "Ensemble Summary: "+"Nin~H-13V2F35~D~FV-2H3F21~o3.4 Autocorrelation (Monthly)"
     gsn_panel2(wks,plot_final,(/nrowE,ncolE/),panres2)
     if (numobs.ne.0) then  
        gsn_text_ndc(wks,names(0)+" "+syear(0)+"-"+eyear(0),0.5,panres2@gsnPanelMainPosYF-.02,txres)
     end if
     frame(wks)
     delete([/plot_summary,plot_final/])
  end if
  delete([/wks,plot_indmem,xyres,xyres_obs,xyres2,txres/])

  if (wks_type.eq."png") then
     if (nEM.lt.1) then   ; in ensemble mode (runstyle=2)
        system("mv "+OUTDIR+"nino34.autocor.png "+OUTDIR+"nino34.autocor.indmem.png")
     else
        system("mv "+OUTDIR+"nino34.autocor.000001.png "+OUTDIR+"nino34.autocor.indmem.png")
        system("mv "+OUTDIR+"nino34.autocor.000002.png "+OUTDIR+"nino34.autocor.summary.png")
        if (PNG_SCALE_SUMMARY.ne.100) then
           system(IM_COMMAND+" "+OUTDIR+"nino34.autocor.summary.png -resize "+PNG_SCALE_SUMMARY+"% "+OUTDIR+"nino34.autocor.summary.png")
        end if
     end if
  else
     system("psplit "+OUTDIR+"nino34.autocor.ps "+OUTDIR+"nino34.autocor")
     system("mv "+OUTDIR+"nino34.autocor0001.ps "+OUTDIR+"nino34.autocor.indmem.ps")
     if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
        system("mv "+OUTDIR+"nino34.autocor0002.ps "+OUTDIR+"nino34.autocor.summary.ps")
     end if
     system("rm "+OUTDIR+"nino34.autocor.ps")
  end if
;-------------------------------------------------------------------------------------------------------------------
;    monthly nino3.4 standard deviations plotting section
;
  xyres = True
  xyres@gsnDraw = False
  xyres@gsnFrame = False
  xyres@gsnYRefLine = 0.0
  xyres@gsnYRefLineColor = "gray42"
  xyres@xyLineColor = "gray62"
  xyres@trXMinF = 0.5
  xyres@trXMaxF = 12.5
  xyres@vpWidthF = 0.65
  xyres@vpHeightF = 0.35
  xyres@trYMinF = 0.2
  xyres@trYMaxF = 2.0
  xyres@gsnAboveYRefLineColor = "gray50"
  xyres@xyLineColor = "black"
  xyres@gsnXYBarChart = True
  xyres@gsnXYBarChartBarWidth = 0.75
  xyres@tmXBMode    = "Explicit"        ; explicit labels
  xyres@tmXBValues     = ispan(1,12,1)
  xyres@tmXBLabels = (/"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"/)
  xyres@tmXTOn = False
  if (wks_type.eq."png") then
     xyres@xyLineThicknessF = .75  
  else
     xyres@xyLineThicknessF = .5  
  end if   
  xyres@tiYAxisOn = False
  xyres@tiMainOn = False
  xyres@tmXBLabelFontHeightF = 0.015
  xyres@tmYLLabelFontHeightF = 0.015
  xyres@gsnLeftStringFontHeightF = 0.0175     
  xyres@gsnCenterStringFontHeightF = 0.0175     
  xyres@gsnRightStringFontHeightF = 0.013
  xyres@gsnCenterStringOrthogonalPosF = .02
  xyres@gsnRightStringOrthogonalPosF = -0.1
     
  polyres = True
  polyres@gsLineColor = "orange"
  polyres@gsLineThicknessF = 5.5   ; orange lines should be slightly wider than the bars (which are .75 wide)

  bres            = True                         ; plot mods desired
  bres@trXMinF = 0.
  bres@trXMaxF = 13.
  bres@vpWidthF = 0.65
  bres@vpHeightF = 0.35
  bres@trYMinF = 0.2
  bres@trYMaxF = 2.0
  bres@tmYLLabelFontHeightF = 0.018
  bres@tmXBLabelFontHeightF = 0.018
  bres@tmXBLabels = (/"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"/)
  bres@tmXTOn = False
  bres@tiMainFont = "Helvetica"
  bres@tiMainString = ""
  bres@tiMainFontHeightF = 0.02
  bres@tiMainOffsetYF = -0.01
  llres                   = True			
  llres@gsLineThicknessF  = 6.                 ; line thickness 
  llres@gsLineDashPattern = 0
  opti          = True			
  opti@boxWidth = .65				; Width of box (x units)
  colors = new(12,string)
  colors = "black"
  opti@boxColors = colors

  polyres = True
  polyres@gsLineColor = "orange"

  txres = True
  txres@txFontHeightF = 0.010
  txres@txFontColor = polyres@gsLineColor

  wks = gsn_open_wks(wks_type,getenv("OUTDIR")+"nino34.monstddev")
  plot_indmem      = new(nsim,"graphic")
  polyline_overlay = new((/nsim,12/),"graphic")
  if (nEM.ge.1) then
     plot_summary     = new(nEM,"graphic")
     polyline_overlay_em = new((/nEM,12/),"graphic")
  end if
  numobs = num(EM_num.eq.0) 
  if (numobs.eq.0) then
     fnt = getenv("OUTDIR")+"obs.cvdp_data.sst.indices."+syear(0)+"-"+eyear(0)+".nc"
     fnt2 = getenv("OUTDIR")+"obs.cvdp_data."+syear(0)+"-"+eyear(0)+".nc"
     cntr = 0
  else
     fnt = getenv("OUTDIR")+modname(0)+".cvdp_data.sst.indices."+syear(0)+"-"+eyear(0)+".nc"
     fnt2 = getenv("OUTDIR")+modname(0)+".cvdp_data."+syear(0)+"-"+eyear(0)+".nc"
     cntr = 1
  end if
  obs0 := read_cvdp_le_data(fnt,fnt2,"nino34_monthly_stddev")
  if (isatt(obs0,"is_all_missing")) then
     obs0New = new(12,float)
     copy_VarAtts(obs0,obs0New)
     obs0 := obs0New
     delete(obs0New)
  end if
  xyres@gsnCenterStringFontColor = polyres@gsLineColor
  xyres@gsnRightStringFontColor = "black"
  xyres@gsnCenterString = names(0)   
  xyres@gsnRightString = syear(0)+"-"+eyear(0)+"  "  
  plot_indmem(0) = gsn_csm_xy(wks,ispan(1,12,1),obs0,xyres)   ; plot first observational set

  xyres@gsnCenterStringFontColor = "black"
  xyres@gsnRightStringFontColor = "black"
  cntr_EM = 0
  polyres@gsLineThicknessF = 5.5
  if (numobs.ge.2) then     ; plot obs #2-
     do ff = 1,numobs-1
        fnt = getenv("OUTDIR")+modname(cntr)+".cvdp_data.sst.indices."+syear(cntr)+"-"+eyear(cntr)+".nc"
        fnt2 = getenv("OUTDIR")+modname(cntr)+".cvdp_data."+syear(cntr)+"-"+eyear(cntr)+".nc"
        arr := read_cvdp_le_data(fnt,fnt2,"nino34_monthly_stddev")
        if (isatt(arr,"is_all_missing")) then
           cntr = cntr+1
           continue
        end if
        xyres@gsnCenterString = names(cntr)   
        xyres@gsnRightString = syear(cntr)+"-"+eyear(cntr)+"  " 
        plot_indmem(cntr) = gsn_csm_xy(wks,ispan(1,12,1),arr,xyres)
        
        if (.not.isatt(obs0,"is_all_missing")) then
           do hh = 0,11
              polyline_overlay(cntr,hh)   = gsn_add_polyline(wks,plot_indmem(cntr),(/(hh+1)-.4,(hh+1)+.4/),(/obs0(hh),obs0(hh)/),polyres)
           end do
        end if
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

        fnt = getenv("OUTDIR")+modname_mod+".cvdp_data.sst.indices."+syear_mod+"-"+eyear_mod+".nc"
        fnt2 = getenv("OUTDIR")+modname_mod+".cvdp_data."+syear_mod+"-"+eyear_mod+".nc"
        arr := read_cvdp_le_data(fnt,fnt2,"nino34_monthly_stddev")
        if (isatt(arr,"is_all_missing")) then
           cntr = cntr+1
           continue
        end if
        if (gg.ge.1) then
           xyres@gsnCenterStringFontColor = csubtitle_color(gg-1)
        end if
        xyres@gsnCenterString = names_mod  
        xyres@gsnRightString = syear_mod+"-"+eyear_mod+"  "
        plot_indmem(cntr) = gsn_csm_xy(wks,ispan(1,12,1),arr,xyres)
        polyres@gsLineThicknessF = 5.5
        if (.not.isatt(obs0,"is_all_missing")) then
           do ii = 0,11
              polyline_overlay(cntr,ii)   = gsn_add_polyline(wks,plot_indmem(cntr),(/(ii+1)-.4,(ii+1)+.4/),(/obs0(ii),obs0(ii)/),polyres)
           end do
        end if

        if (.not.isvar("arr_store")) then
           arr_store = new((/nens,dimsizes(arr)/),typeof(arr))
           arr_store!0 = "ensmem"
           arr_store!1 = "time_mon2"
           arr_store&time_mon2 = arr&time_mon2
           arr_store@nens = 0
           copy_VarAtts(arr,arr_store)
           syear_em0 = syear_mod
           eyear_em0 = eyear_mod
        end if
        arr_store(hh,:) = (/ arr /) 
        arr_store@nens = arr_store@nens+1
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
     arrEM := new((/12,5/),typeof(arr_store))
     arrEM!0 = "time_mon2"
     arrEM&time_mon2 = arr_store&time_mon2
     arrEM!1 = "ncurves4"
     arrEM&ncurves4 = ispan(0,4,1)
     arrEM&ncurves4@long_name = "10/25/50/75/90% threshold"
     arrEM&ncurves4@units = "C"
     do ii = 0,11
        ds := boxplot_stat(arr_store(:,ii))
        arrEM(ii,:) =  (/ds(0),ds(1),dim_avg(arr_store(:,ii)),ds(3),ds(4)/)
     end do
     bres@tiMainFontColor = csubtitle_color(gg-1)
     bres@tiMainString = names_EM_mod+" "+syear_mod+"-"+eyear_mod+" ("+arr_store@nens+" Members)"
     plot_summary(cntr_EM) = boxplot(wks,ispan(1,12,1),arrEM,opti,bres,llres)	
     polyres@gsLineThicknessF = 7.5
     if (.not.isatt(obs0,"is_all_missing")) then
        do jj = 0,11
           polyline_overlay_em(cntr_EM,jj)   = gsn_add_polyline(wks,plot_summary(cntr_EM),(/(jj+1)-.4,(jj+1)+.4/),(/obs0(jj),obs0(jj)/),polyres)
        end do
     end if
     fout = getenv("OUTDIR")+str_sub_str(names_EM_mod," ","_")+"_EM.cvdp_data.sst.indices."+syear_mod+"-"+eyear_mod+".nc"
     if (isfilepresent2(fout)) then
        z = addfile(fout,"w")
     else
        z = addfile(fout,"c")
        set_global_ncfile_attributes(z,names_EM_mod,syear_mod,eyear_mod,getenv("VERSION"))
     end if
     z->$(/"nino34_monthly_stddev_stats"/)$ = set_varAtts(arrEM,"","","")
     delete([/arr_store,arrEM,z/])
     cntr_EM = cntr_EM+1
  end do
  panres@txString = "Nin~H-13V2F35~D~FV-2H3F21~o3.4 Standard Deviation (Monthly)"
  gsn_panel2(wks,plot_indmem,(/nrow,ncol/),panres)

  if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
     panres2@gsnPanelMainString = "Ensemble Summary: "+"Nin~H-13V2F35~D~FV-2H3F21~o3.4 Standard Deviation (Monthly)"
     panres2@gsnPanelXWhiteSpacePercent = 3.0
     panres2@gsnPanelYWhiteSpacePercent = 3.0
     panres2@gsnPanelTop = 0.94
     panres2@gsnPanelMainPosYF = set_panel_title_YF(nEM-1,xyres)
     gsn_panel2(wks,plot_summary,(/nrowE,ncolE/),panres2)
     if (numobs.ne.0) then  
        gsn_text_ndc(wks,names(0)+" "+syear(0)+"-"+eyear(0),0.5,panres2@gsnPanelMainPosYF-.02,txres)
     end if
     frame(wks)
     delete([/plot_summary/])
  end if
  delete([/wks,plot_indmem,xyres,opti,bres,llres,polyres,polyline_overlay,panres,panres2/])

  if (wks_type.eq."png") then
     if (nEM.lt.1) then   ; in ensemble mode (runstyle=2)
        system("mv "+OUTDIR+"nino34.monstddev.png "+OUTDIR+"nino34.monstddev.indmem.png")
     else
        system("mv "+OUTDIR+"nino34.monstddev.000001.png "+OUTDIR+"nino34.monstddev.indmem.png")
        system("mv "+OUTDIR+"nino34.monstddev.000002.png "+OUTDIR+"nino34.monstddev.summary.png")
        if (PNG_SCALE_SUMMARY.ne.100) then
           system(IM_COMMAND+" "+OUTDIR+"nino34.monstddev.summary.png -resize "+PNG_SCALE_SUMMARY+"% "+OUTDIR+"nino34.monstddev.summary.png")
        end if
     end if
  else
     system("psplit "+OUTDIR+"nino34.monstddev.ps "+OUTDIR+"nino34.monstddev")
     system("mv "+OUTDIR+"nino34.monstddev0001.ps "+OUTDIR+"nino34.monstddev.indmem.ps")
     if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
        system("mv "+OUTDIR+"nino34.monstddev0002.ps "+OUTDIR+"nino34.monstddev.summary.ps")
     end if
     system("rm "+OUTDIR+"nino34.monstddev.ps")
  end if
;---ENSO TAS/SST/PSL Spatial Composite plotting section---------------------------------------------------------------------------
  res = True      ; spatial plot resource list
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
  res@gsnRightStringParallelPosF = 1.03
  res@gsnLeftStringFontHeightF = 0.014
  res@gsnCenterStringFontHeightF = 0.018
  res@gsnRightStringFontHeightF = 0.012
  res@gsnLeftString = ""
  res@gsnCenterString = ""
  res@gsnRightString = ""

  tres = res    ; p-value plot resource list
  copy_VarAtts(retrieve_summary_res(),tres)
  delete(tres@cnMissingValFillColor)

  res2 = res    ; spatial differences resource list
  if (COLORMAP.eq.0) then
     res@cnFillPalette = "ncl_default"
  end if
  if (COLORMAP.eq.1) then
     res@cnFillPalette = "BlueDarkRed18"
  end if 
  res@cnLevels = (/-4,-3,-2,-1.5,-1,-.5,-.25,0,.25,.5,1,1.5,2,3.,4/) 
  res@cnExplicitLabelBarLabelsOn = True
  res@lbLabelStrings = (/"-4","-3","-2","-1.5","-1","-.5","-.25","0",".25",".5","1","1.5","2","3","4"/)  
  res@lbLabelStride = 1
  res2@cnLevels = res@cnLevels
  res2@lbLabelStrings = res@lbLabelStrings
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

  res5 = res3          ; PSL resources
  res5@cnFillOn       = False
  res5@cnLinesOn      = True
  res5@cnLineColor    = "black"
  res5@cnLineLabelsOn = False  
  res5@cnLevelSelectionMode = "ExplicitLevels"
  res5@cnInfoLabelOn = False
  res5@tiMainOn = False      
  res5@cnLineDashSegLenF = 0.08
  res5@gsnDraw = False
  res5@gsnFrame = False
  res5@gsnLeftString = ""
  res5@gsnRightString = ""
  res5@gsnCenterString = ""
  if (wks_type.eq."png") then
     res5@cnLineThicknessF = 3.
  else
     res5@cnLineThicknessF = 1.25
  end if
  res5@cnLevels := ispan(-16,16,2)

  res6 = res5          ; PSL difference resources
  res6@cnLevels := ispan(-16,16,1)

  tres2 = res3    ; p-value plots
  copy_VarAtts(retrieve_summary_res(),tres2)
  tres2@gsnCenterString = ""
  delete(tres2@cnMissingValFillColor)

  panres = True   ; panel resource list for individual simulations
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

  panres2 = True     ; summary panel resource list
  panres2@gsnPaperOrientation = "portrait"
  panres2@gsnPanelLabelBar = False
  panres2@gsnPanelYWhiteSpacePercent = 3.0
  panres2@txFontHeightF = 0.016
  panres2@gsnPanelBottom = 0.05

  variname = (/"nino34_spacomp_var_","nino34_spacomp_var_","nino34_spacomp_var_","nino34_spacomp_var_",\
               "nino34_elnino_spacomp_var_","nino34_elnino_spacomp_var_","nino34_elnino_spacomp_var_","nino34_elnino_spacomp_var_",\
               "nino34_lanina_spacomp_var_","nino34_lanina_spacomp_var_","nino34_lanina_spacomp_var_","nino34_lanina_spacomp_var_"/)
  variname_seas = (/"jja0","son0","djf1","mam1","jja0","son0","djf1","mam1","jja0","son0","djf1","mam1"/)
  variname = variname+variname_seas

  variname_title_seas = (/"(JJA~S~0~N~)","(SON~S~0~N~)","(DJF~S~+1~N~)","(MAM~S~+1~N~)",\
                          "(JJA~S~0~N~)","(SON~S~0~N~)","(DJF~S~+1~N~)","(MAM~S~+1~N~)",\
                          "(JJA~S~0~N~)","(SON~S~0~N~)","(DJF~S~+1~N~)","(MAM~S~+1~N~)"/)
  variname_panel_title_subs = new(12,string)
  variname_panel_title_subs(:3) = "El Nin~H-13V2F35~D~FV-2H3F21~o - La Nin~H-13V2F35~D~FV-2H3F21~a"
  variname_panel_title_subs(4:7) = "El Nin~H-13V2F35~D~FV-2H3F21~o"
  variname_panel_title_subs(8:) = "La Nin~H-13V2F35~D~FV-2H3F21~a"
  fnaddsub = (/"","","","",".elnino",".elnino",".elnino",".elnino",".lanina",".lanina",".lanina",".lanina"/) ; add to workstation output file name

  do dd = 0,dimsizes(variname)-1
     varinameF = variname(dd)

     wks = gsn_open_wks(wks_type,getenv("OUTDIR")+"nino34_spacomp")
     res5@gsnContourNegLineDashPattern  = NhlNewDashPattern(wks,"$_$_$_$_$_$_$_$_$_")
     res6@gsnContourNegLineDashPattern  = NhlNewDashPattern(wks,"$_$_$_$_$_$_$_$_$_")

     plot_indmem      := new(nsim,"graphic")
     plot_indmem_diff := new(nsim,"graphic")
     plot_indmem_ov      := new(nsim,"graphic")
     plot_indmem_diff_ov := new(nsim,"graphic")
     plot_indmem_ov2     := new(nsim,"graphic")    ; PSL differences overlay
     plot_indmem_diff_ov2:= new(nsim,"graphic")
     if (nEM.ge.1) then
        plot_summary     := new((nEM*5),"graphic")
        plot_summary_ov     := new((nEM*5),"graphic")
        plot_summary_ov2    := new((nEM*5),"graphic")
     end if
     numobs = num(EM_num.eq.0) 
     if (numobs.eq.0) then
        fnt = getenv("OUTDIR")+"obs.cvdp_data.sst.indices.tas."+syear_tas(0)+"-"+eyear_tas(0)+".nc"      
        fnt2 = getenv("OUTDIR")+"obs.cvdp_data."+syear_tas(0)+"-"+eyear_tas(0)+".nc"
        obs0 := read_cvdp_le_data(fnt,fnt2,str_sub_str(varinameF,"var","tas"))
        fnt = getenv("OUTDIR")+"obs.cvdp_data.sst.indices."+syear(0)+"-"+eyear(0)+".nc"
        fnt2 = getenv("OUTDIR")+"obs.cvdp_data."+syear(0)+"-"+eyear(0)+".nc"
        sst0 := read_cvdp_le_data(fnt,fnt2,str_sub_str(varinameF,"var","sst"))
        fnt = getenv("OUTDIR")+"obs.cvdp_data.sst.indices.psl."+syear_psl(0)+"-"+eyear_psl(0)+".nc"     
        fnt2 = getenv("OUTDIR")+"obs.cvdp_data."+syear_psl(0)+"-"+eyear_psl(0)+".nc"
        psl0 := read_cvdp_le_data(fnt,fnt2,str_sub_str(varinameF,"var","psl"))
        cntr = 0
     else
        fnt = getenv("OUTDIR")+modname_tas(0)+".cvdp_data.sst.indices.tas."+syear_tas(0)+"-"+eyear_tas(0)+".nc"      
        fnt2 = getenv("OUTDIR")+modname_tas(0)+".cvdp_data."+syear_tas(0)+"-"+eyear_tas(0)+".nc"
        obs0 := read_cvdp_le_data(fnt,fnt2,str_sub_str(varinameF,"var","tas"))
        fnt = getenv("OUTDIR")+modname(0)+".cvdp_data.sst.indices."+syear(0)+"-"+eyear(0)+".nc"
        fnt2 = getenv("OUTDIR")+modname(0)+".cvdp_data."+syear(0)+"-"+eyear(0)+".nc"
        sst0 := read_cvdp_le_data(fnt,fnt2,str_sub_str(varinameF,"var","sst"))
        fnt = getenv("OUTDIR")+modname_psl(0)+".cvdp_data.sst.indices.psl."+syear_psl(0)+"-"+eyear_psl(0)+".nc"     
        fnt2 = getenv("OUTDIR")+modname_psl(0)+".cvdp_data."+syear_psl(0)+"-"+eyear_psl(0)+".nc"
        psl0 := read_cvdp_le_data(fnt,fnt2,str_sub_str(varinameF,"var","psl"))
        cntr = 1
     end if

     m = addfile("$NCARG_ROOT/lib/ncarg/data/cdf/landsea.nc","r")     ; mask ocean for TAS array
     obs0 = mask(obs0,landsea_mask(m->LSMASK,obs0&lat,obs0&lon).eq.0,False)

     res@gsnCenterStringFontColor = "black"
     res2@gsnCenterStringFontColor = "black"
     res@gsnRightStringParallelPosF = 1.01
     res@gsnRightStringOrthogonalPosF = -0.07
     res@lbLabelBarOn = False
     res2@lbLabelBarOn = False
     tres@lbLabelBarOn = False
     res@gsnLeftString = syear_tas(0)+"-"+eyear_tas(0) 
     res@gsnRightString = set_subtitle_enso_numevents(obs0,"Tot")
     res@gsnCenterString = names(0)+" / "+names_tas(0)+" / "+names_psl(0)      
     plot_indmem(0) = gsn_csm_contour_map(wks,obs0,res)
     plot_indmem_ov(0) = gsn_csm_contour(wks,sst0,res3)
     plot_indmem_ov2(0) = gsn_csm_contour(wks,psl0,res5)
     overlay(plot_indmem(0),plot_indmem_ov(0))
     overlay(plot_indmem(0),plot_indmem_ov2(0))
     cntr_EM = 0
     if (numobs.ge.2) then     ; plot obs #2-
        do ff = 1,numobs-1
           fnt = getenv("OUTDIR")+modname_tas(cntr)+".cvdp_data.sst.indices.tas."+syear_tas(cntr)+"-"+eyear_tas(cntr)+".nc"
           fnt2 = getenv("OUTDIR")+modname_tas(cntr)+".cvdp_data."+syear_tas(cntr)+"-"+eyear_tas(cntr)+".nc"
           arr := read_cvdp_le_data(fnt,fnt2,str_sub_str(varinameF,"var","tas"))
           fnt = getenv("OUTDIR")+modname(cntr)+".cvdp_data.sst.indices."+syear(cntr)+"-"+eyear(cntr)+".nc"
           fnt2 = getenv("OUTDIR")+modname(cntr)+".cvdp_data."+syear(cntr)+"-"+eyear(cntr)+".nc"
           sst := read_cvdp_le_data(fnt,fnt2,str_sub_str(varinameF,"var","sst"))
           if (isatt(sst,"is_all_missing")) then 
              cntr = cntr+1
              continue
           end if
           fnt = getenv("OUTDIR")+modname_psl(cntr)+".cvdp_data.sst.indices.psl."+syear_psl(cntr)+"-"+eyear_psl(cntr)+".nc"
           fnt2 = getenv("OUTDIR")+modname_psl(cntr)+".cvdp_data."+syear_psl(cntr)+"-"+eyear_psl(cntr)+".nc"
           psl := read_cvdp_le_data(fnt,fnt2,str_sub_str(varinameF,"var","psl"))

           m = addfile("$NCARG_ROOT/lib/ncarg/data/cdf/landsea.nc","r")     ; mask ocean for TAS array
           arr = mask(arr,landsea_mask(m->LSMASK,arr&lat,arr&lon).eq.0,False)

           obs0_rg = linint2_Wrap(obs0&lon,obs0&lat,obs0,True,arr&lon,arr&lat,0)
           obs_diff = arr
           obs_diff = (/ arr - obs0_rg /)
           sst0_rg = linint2_Wrap(sst0&lon,sst0&lat,sst0,True,sst&lon,sst&lat,0)
           sst_diff = sst   
           sst_diff = (/ sst - sst0_rg /)   
           psl0_rg = linint2_Wrap(psl0&lon,psl0&lat,psl0,True,psl&lon,psl&lat,0)
           psl_diff = psl   
           psl_diff = (/ psl - psl0_rg /)   

           res@gsnLeftString = syear_tas(cntr)+"-"+eyear_tas(cntr)
           res@gsnCenterString = names(cntr)+" / "+names_tas(cntr)+" / "+names_psl(cntr)
           res@gsnRightString = set_subtitle_enso_numevents(arr,"Tot")+"~C~   r="+pattern_correlation(sst0_rg,sst)+"/"+pattern_correlation(obs0_rg,arr)+"/"+pattern_correlation(psl0_rg,psl)
           plot_indmem(cntr) = gsn_csm_contour_map(wks,sst,res)
           plot_indmem_ov(cntr)  = gsn_csm_contour(wks,arr,res3)
           plot_indmem_ov2(cntr) = gsn_csm_contour(wks,psl,res5)
           overlay(plot_indmem(cntr),plot_indmem_ov(cntr))
           overlay(plot_indmem(cntr),plot_indmem_ov2(cntr))
           res2@gsnLeftString = ""  
           res2@gsnRightString = ""
           res2@gsnCenterString = names(cntr)+"/"+names_tas(cntr)+"/"+names_psl(cntr)+" -~C~"+names(0)+"/"+names_tas(0)+"/"+names_psl(0)
           plot_indmem_diff(cntr) = gsn_csm_contour_map(wks,sst_diff,res2)   
           plot_indmem_diff_ov(cntr) = gsn_csm_contour(wks,obs_diff,res4)
           plot_indmem_diff_ov2(cntr) = gsn_csm_contour(wks,psl_diff,res6)
           overlay(plot_indmem_diff(cntr),plot_indmem_diff_ov(cntr))
           overlay(plot_indmem_diff(cntr),plot_indmem_diff_ov2(cntr))
           delete([/arr,obs_diff,obs0_rg,sst_diff,sst0_rg,psl0_rg,psl_diff,sst,psl/])
           cntr = cntr+1
        end do
     end if
     varinameF = variname(dd)

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
           modname_mod_sst = modname(cntr_ens(hh))
           syear_mod_sst = syear(cntr_ens(hh))
           eyear_mod_sst = eyear(cntr_ens(hh))
           names_mod_sst = names(cntr_ens(hh))
           modname_mod_psl = modname_psl(cntr_ens(hh))
           syear_mod_psl = syear_psl(cntr_ens(hh))
           eyear_mod_psl = eyear_psl(cntr_ens(hh))
           names_mod_psl = names_psl(cntr_ens(hh))
   
           fnt = getenv("OUTDIR")+modname_mod+".cvdp_data.sst.indices.tas."+syear_mod+"-"+eyear_mod+".nc"
           fnt2 = getenv("OUTDIR")+modname_mod+".cvdp_data."+syear_mod+"-"+eyear_mod+".nc"
           arr := read_cvdp_le_data(fnt,fnt2,str_sub_str(varinameF,"var","tas"))

           fnt = getenv("OUTDIR")+modname_mod_sst+".cvdp_data.sst.indices."+syear_mod_sst+"-"+eyear_mod_sst+".nc"
           fnt2 = getenv("OUTDIR")+modname_mod_sst+".cvdp_data."+syear_mod+"-"+eyear_mod+".nc"
           sst := read_cvdp_le_data(fnt,fnt2,str_sub_str(varinameF,"var","sst"))

           if (isatt(sst,"is_all_missing")) then 
              cntr = cntr+1
              continue
           end if
           fnt = getenv("OUTDIR")+modname_mod_psl+".cvdp_data.sst.indices.psl."+syear_mod_psl+"-"+eyear_mod_psl+".nc"
           fnt2 = getenv("OUTDIR")+modname_mod_psl+".cvdp_data."+syear_mod+"-"+eyear_mod+".nc"
           psl := read_cvdp_le_data(fnt,fnt2,str_sub_str(varinameF,"var","psl"))

           m = addfile("$NCARG_ROOT/lib/ncarg/data/cdf/landsea.nc","r")     ; mask ocean for TAS array
           arr = mask(arr,landsea_mask(m->LSMASK,arr&lat,arr&lon).eq.0,False)

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
 
              arr_store_psl = new((/nens,dimsizes(psl&lat),dimsizes(psl&lon)/),typeof(psl))
              arr_store_psl!0 = "ensmem"
              arr_store_psl!1 = "lat"
              arr_store_psl&lat = psl&lat
              arr_store_psl!2 = "lon"
              arr_store_psl&lon = psl&lon
              arr_store_psl@nens = 0
              copy_VarAtts(psl,arr_store_psl)
   
              arr_store_events_E = new(nens,float)
              arr_store_events_L = new(nens,float)      

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
              arr_store@nens = arr_store@nens+1
           end if
           if (.not.isatt(sst,"is_all_missing")) then
              arr_store_sst(hh,:,:) = (/ sst /)
              arr_store_sst@nens = arr_store_sst@nens+1
           end if
           if (.not.isatt(psl,"is_all_missing")) then
              arr_store_psl(hh,:,:) = (/ psl /)
              arr_store_psl@nens = arr_store_psl@nens+1
           end if
           if (isatt(arr,"number_of_elnino_events")) then
              arr_store_events_E(hh) = arr@number_of_elnino_events
           end if
           if (isatt(arr,"number_of_lanina_events")) then
              arr_store_events_L(hh) = arr@number_of_lanina_events
           end if

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

           if (.not.isvar("psl0_rg")) then  
              psl0_rg = linint2_Wrap(psl0&lon,psl0&lat,psl0,True,psl&lon,psl&lat,0)
           end if
           psl_diff = psl
           if (.not.isatt(psl,"is_all_missing")) then
              psl_diff = (/ psl - psl0_rg /)
           end if

           res@gsnLeftString   = syear_mod+"-"+eyear_mod
           res@gsnRightString  = set_subtitle_enso_numevents(arr,"Tot")+"~C~   r="+pattern_correlation(sst0_rg,sst)+"/"+pattern_correlation(obs0_rg,arr)+"/"+pattern_correlation(psl0_rg,psl)
           res@gsnCenterString = names_mod
           plot_indmem(cntr) = gsn_csm_contour_map(wks,arr,res)
           plot_indmem_ov(cntr) = gsn_csm_contour(wks,sst,res3)
           plot_indmem_ov2(cntr) = gsn_csm_contour(wks,psl,res5)
           overlay(plot_indmem(cntr),plot_indmem_ov(cntr))
           overlay(plot_indmem(cntr),plot_indmem_ov2(cntr))
           panres@lbTitleString = arr@units

           res2@gsnLeftString = "" 
           res2@gsnRightString = ""
           res2@gsnCenterString = names_mod+" - "+names(0)+"/"+names_tas(0)+"/"+names_psl(0)
           plot_indmem_diff(cntr) = gsn_csm_contour_map(wks,obs_diff,res2)
           plot_indmem_diff_ov(cntr) = gsn_csm_contour(wks,sst_diff,res4)
           plot_indmem_diff_ov2(cntr) = gsn_csm_contour(wks,psl_diff,res6)
           overlay(plot_indmem_diff(cntr),plot_indmem_diff_ov(cntr))
           overlay(plot_indmem_diff(cntr),plot_indmem_diff_ov2(cntr))
           delete([/arr,obs_diff,sst_diff,psl_diff,sst,psl/])
           cntr = cntr+1
        end do
        if (nEM.eq.0) then   ; in individual member mode (runstyle=1)
           if (isvar("arr_store")) then
              delete(arr_store)
           end if
           if (isvar("obs0_rg")) then
              delete(obs0_rg)
           end if
           if (isvar("arr_store_sst")) then
              delete(arr_store_sst)
           end if
           if (isvar("sst0_rg")) then
              delete(sst0_rg)
           end if
           if (isvar("arr_store_psl")) then
              delete(arr_store_psl)
           end if
           if (isvar("psl0_rg")) then
              delete(psl0_rg)
           end if
           continue
        end if
        if (.not.isvar("arr_store")) then
           cntr_EM = cntr_EM+5
           continue
        end if
   
        if (lbFlag) then
           res@lbLabelBarOn = True
           res2@lbLabelBarOn = True
           tres@lbLabelBarOn = True
        end if
        arr_EM = dim_avg_n_Wrap(arr_store,0)
        arr_sst_EM = dim_avg_n_Wrap(arr_store_sst,0)
        arr_psl_EM = dim_avg_n_Wrap(arr_store_psl,0)
   
        res@gsnCenterStringFontColor = "black"
        res2@gsnCenterStringFontColor = "black"

        res@gsnRightStringParallelPosF = 1.01
        res@gsnRightStringOrthogonalPosF = -0.07
        res@lbTitleString = arr_EM@units   
        res@gsnLeftString = syear_tas(0)+"-"+eyear_tas(0) 
        res@gsnRightString = set_subtitle_enso_numevents(obs0,"Tot")
        res@gsnCenterString = names(0)+"/"+names_tas(0)+"/"+names_psl(0) 
        plot_summary(cntr_EM+1) = gsn_csm_contour_map(wks,obs0,res)
        plot_summary_ov(cntr_EM+1) = gsn_csm_contour(wks,sst0,res3)
        plot_summary_ov2(cntr_EM+1) = gsn_csm_contour(wks,psl0,res5)
        overlay(plot_summary(cntr_EM+1),plot_summary_ov(cntr_EM+1))
        overlay(plot_summary(cntr_EM+1),plot_summary_ov2(cntr_EM+1))
   
        if (showyr) then
           res@gsnLeftString = syear_em0+"-"+eyear_em0 
        else
           res@gsnLeftString = (eyear_em0-syear_em0+1)+"yrs" 
        end if
        delete([/syear_em0,eyear_em0,showyr/])
   
        res@gsnCenterStringFontColor = csubtitle_color(gg-1)
        res@gsnRightStringParallelPosF = 1.03
        res@gsnRightStringOrthogonalPosF = -0.97
        res@gsnRightString = ""
        if (.not.all(ismissing(arr_store_events_E))) then
           if (.not.all(ismissing(arr_store_events_L))) then
              res@gsnRightString = decimalPlaces(avg(arr_store_events_E),0,True)+" EN/"+decimalPlaces(avg(arr_store_events_L),0,True)+" LN Avg~C~"+\
                             "   "+sum(arr_store_events_E)+" EN/"+sum(arr_store_events_E)+" LN Tot~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~"+\
                             "   r="+pattern_correlation(sst0_rg,arr_sst_EM)+"/"+pattern_correlation(obs0_rg,arr_EM)+"/"+pattern_correlation(psl0_rg,arr_psl_EM)
           else
              res@gsnRightString = decimalPlaces(avg(arr_store_events_E),0,True)+" EN Avg/"+sum(arr_store_events_E)+" EN Tot~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~"+\
                             "   r="+pattern_correlation(sst0_rg,arr_sst_EM)+"/"+pattern_correlation(obs0_rg,arr_EM)+"/"+pattern_correlation(psl0_rg,arr_psl_EM)
           end if
        else
           if (.not.all(ismissing(arr_store_events_L))) then
              res@gsnRightString = decimalPlaces(avg(arr_store_events_L),0,True)+" LN Avg/"+sum(arr_store_events_L)+" LN Tot~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~"+\
                             "   r="+pattern_correlation(sst0_rg,arr_sst_EM)+"/"+pattern_correlation(obs0_rg,arr_EM)+"/"+pattern_correlation(psl0_rg,arr_psl_EM)
           end if
        end if

        res@gsnCenterString = names_EM_mod +" ("+arr_store_sst@nens+"/"+arr_store@nens+"/"+arr_store_psl@nens+" Members)"            
        plot_summary(cntr_EM) = gsn_csm_contour_map(wks,arr_EM,res)
        plot_summary_ov(cntr_EM) = gsn_csm_contour(wks,arr_sst_EM,res3)
        plot_summary_ov2(cntr_EM) = gsn_csm_contour(wks,arr_psl_EM,res5)
        overlay(plot_summary(cntr_EM),plot_summary_ov(cntr_EM))
        overlay(plot_summary(cntr_EM),plot_summary_ov2(cntr_EM))
        res@gsnRightStringParallelPosF = 1.01
        res@gsnRightStringOrthogonalPosF = -0.07

        obs_diff = arr_EM
        obs_diff = (/ arr_EM - obs0_rg /)
        sst_diff = arr_sst_EM
        sst_diff = (/ arr_sst_EM - sst0_rg /)
        psl_diff = arr_psl_EM
        psl_diff = (/ arr_psl_EM - psl0_rg /)
        res2@lbTitleString = arr_EM@units
        res2@gsnLeftString = ""
        res2@gsnCenterString = names_EM_mod+" - "+names(0)+"/"+names_tas(0)+"/"+names_psl(0)
        res2@gsnRightString = ""
        res2@lbTitleString = arr_EM@units   
        plot_summary(cntr_EM+2) = gsn_csm_contour_map(wks,obs_diff,res2)
        plot_summary_ov(cntr_EM+2) = gsn_csm_contour(wks,sst_diff,res4)
        plot_summary_ov2(cntr_EM+2) = gsn_csm_contour(wks,psl_diff,res6)
        overlay(plot_summary(cntr_EM+2),plot_summary_ov(cntr_EM+2))
        overlay(plot_summary(cntr_EM+2),plot_summary_ov2(cntr_EM+2))
   
        tres@lbTitleString = "%"
        p_val = calculate_pval(obs0_rg,arr_store)
        tres@gsnRightStringParallelPosF = 1.025
        tres@gsnLeftString = "SST/TAS" 
        tres@gsnCenterString = "Rank of "+names(0)+"/"+names_tas(0)+" within Ensemble"   
        p_val2 = calculate_pval(sst0_rg,arr_store_sst)
        tres@gsnRightStringParallelPosF = .985
        tres@gsnRightString = calculate_area_in_range(p_val2,10,90)+" /"+calculate_area_in_range(p_val,10,90)+"%"
        p_val3 = calculate_pval(psl0_rg,arr_store_psl)

        plot_summary(cntr_EM+3) = gsn_csm_contour_map(wks,p_val2,tres)
        plot_summary_ov(cntr_EM+3) = gsn_csm_contour(wks,p_val,tres2)
        overlay(plot_summary(cntr_EM+3),plot_summary_ov(cntr_EM+3))
        tres@gsnLeftString = "PSL" 
        tres@gsnCenterString = "Rank of "+names_psl(0)+" within Ensemble"   
        tres@gsnRightString = calculate_area_in_range(p_val3,10,90)+"%"
        plot_summary(cntr_EM+4) = gsn_csm_contour_map(wks,p_val3,tres)

   
        fno = getenv("OUTDIR")+str_sub_str(names_EM_mod," ","_")+"_EM.cvdp_data.sst.indices.tas."+syear_mod+"-"+eyear_mod+".nc"
        if (isfilepresent2(fno)) then
           z = addfile(fno,"w")
        else
           z = addfile(fno,"c")
           set_global_ncfile_attributes(z,names_EM_mod,syear_mod,eyear_mod,getenv("VERSION"))
        end if
        z->$(/str_sub_str(varinameF,"var","tas")+"_em"/)$ = set_varAtts(arr_EM,arr_EM@long_name+" Ensemble Mean","","")
        z->$(/str_sub_str(varinameF,"var","tas")+"_em_diffobs"/)$ = set_varAtts(obs_diff,obs_diff@long_name+" Ensemble Mean difference from "+names_tas(0),"","")           
        z->$(/str_sub_str(varinameF,"var","tas")+"_pval"/)$ = set_varAtts(p_val,arr_EM@long_name+" p-val statistic","%","")   
        delete(z)

        fno = getenv("OUTDIR")+str_sub_str(names_EM_mod," ","_")+"_EM.cvdp_data.sst.indices."+syear_mod_sst+"-"+eyear_mod_sst+".nc"
        if (isfilepresent2(fno)) then
           z = addfile(fno,"w")
        else
           z = addfile(fno,"c")
           set_global_ncfile_attributes(z,names_EM_mod,syear_mod_sst,eyear_mod_sst,getenv("VERSION"))
        end if
        z->$(/str_sub_str(varinameF,"var","sst")+"_em"/)$ = set_varAtts(arr_sst_EM,arr_sst_EM@long_name+" Ensemble Mean","","")
        z->$(/str_sub_str(varinameF,"var","sst")+"_em_diffobs"/)$ = set_varAtts(sst_diff,sst_diff@long_name+" Ensemble Mean difference from "+names(0),"","")           
        z->$(/str_sub_str(varinameF,"var","sst")+"_pval"/)$ = set_varAtts(p_val2,arr_sst_EM@long_name+" p-val statistic","%","")   
        delete(z)

        fno = getenv("OUTDIR")+str_sub_str(names_EM_mod," ","_")+"_EM.cvdp_data.sst.indices.psl."+syear_mod_psl+"-"+eyear_mod_psl+".nc"
        if (isfilepresent2(fno)) then
           z = addfile(fno,"w")
        else
           z = addfile(fno,"c")
           set_global_ncfile_attributes(z,names_EM_mod,syear_mod_psl,eyear_mod_psl,getenv("VERSION"))
        end if
        z->$(/str_sub_str(varinameF,"var","psl")+"_em"/)$ = set_varAtts(arr_psl_EM,arr_psl_EM@long_name+" Ensemble Mean","","")
        z->$(/str_sub_str(varinameF,"var","psl")+"_em_diffobs"/)$ = set_varAtts(psl_diff,psl_diff@long_name+" Ensemble Mean difference from "+names_psl(0),"","")           
        z->$(/str_sub_str(varinameF,"var","psl")+"_pval"/)$ = set_varAtts(p_val2,arr_psl_EM@long_name+" p-val statistic","%","")   
        delete([/arr_store,arr_store_sst,arr_store_psl,obs0_rg,obs_diff,arr_EM,z,arr_sst_EM,arr_psl_EM,sst_diff,sst0_rg,psl_diff,psl0_rg,p_val,p_val2,p_val3/])
        delete([/arr_store_events_E,arr_store_events_L/])
        cntr_EM = cntr_EM+5
     end do
     panres@txString = variname_panel_title_subs(dd)+" Spatial Composite SST,TAS,PSL "+variname_title_seas(dd)
     gsn_panel2(wks,plot_indmem,(/nrow,ncol/),panres)
     
     panres@txString = variname_panel_title_subs(dd)+" Spatial Composite Differences SST,TAS,PSL "+variname_title_seas(dd)
     gsn_panel2(wks,plot_indmem_diff,(/nrow,ncol/),panres)

     if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
        panres2@txString = "Ensemble Summary: "+variname_panel_title_subs(dd)+" Spatial Composite SST,TAS,PSL "+variname_title_seas(dd)
        panres2@gsnPanelXWhiteSpacePercent = 3.0
        gsn_panel2(wks,plot_summary,(/nEM,5/),panres2)
        delete(panres2@gsnPanelXWhiteSpacePercent)
     end if
     delete(wks)

     if (wks_type.eq."png") then
        system("mv "+OUTDIR+"nino34_spacomp.000001.png "+OUTDIR+"nino34.spatialcomp"+fnaddsub(dd)+".indmem."+variname_seas(dd)+".png")
        system("mv "+OUTDIR+"nino34_spacomp.000002.png "+OUTDIR+"nino34.spatialcomp"+fnaddsub(dd)+".indmemdiff."+variname_seas(dd)+".png")
        if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
           system("mv "+OUTDIR+"nino34_spacomp.000003.png "+OUTDIR+"nino34.spatialcomp"+fnaddsub(dd)+".summary."+variname_seas(dd)+".png")
           if (PNG_SCALE_SUMMARY.ne.100) then
              system(IM_COMMAND+" "+OUTDIR+"nino34.spatialcomp"+fnaddsub(dd)+".summary."+variname_seas(dd)+".png -resize "+PNG_SCALE_SUMMARY+"% "+OUTDIR+"nino34.spatialcomp"+fnaddsub(dd)+".summary."+variname_seas(dd)+".png")
           end if
        end if
     else
        system("psplit "+OUTDIR+"nino34_spacomp.ps "+OUTDIR+"nino34.spatialcomp")
        system("mv "+OUTDIR+"nino34_spatialcomp0001.ps "+OUTDIR+"nino34.spatialcomp"+fnaddsub(dd)+".indmem."+variname_seas(dd)+".ps")
        system("mv "+OUTDIR+"nino34_spatialcomp0002.ps "+OUTDIR+"nino34.spatialcomp"+fnaddsub(dd)+".indmemdiff."+variname_seas(dd)+".ps")
        if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
           system("mv "+OUTDIR+"nino34_spatialcomp0003.ps "+OUTDIR+"nino34.spatialcomp"+fnaddsub(dd)+".summary."+variname_seas(dd)+".ps")
        end if
        system("rm "+OUTDIR+"nino34_spacomp.ps")
     end if
  end do
;---ENSO ZOS Spatial Composite plotting section---------------------------------------------------------------------------
  if (isatt(res,"lbLabelStrings")) then
     delete(res@lbLabelStrings)
  end if
  if (isatt(res2,"lbLabelStrings")) then
     delete(res2@lbLabelStrings)
  end if
  res@cnExplicitLabelBarLabelsOn = False
  if (COLORMAP.eq.0) then
     res@cnLevels := ispan(-24,24,3)   
  end if
  if (COLORMAP.eq.1) then
     res@cnLevels := ispan(-21,21,3)
  end if 
  res2@cnLevels := ispan(-14,14,2)
  res2@cnFillPalette := res@cnFillPalette
  res@cnMissingValFillColor = "gray90"
  res2@cnMissingValFillColor = "gray90"
  res@trGridType = "TriangularMesh"
  res2@trGridType = "TriangularMesh"

  res@gsnRightStringOrthogonalPosF = -0.07
  res@gsnRightStringParallelPosF = 1.025
  do dd = 0,dimsizes(variname)-1
     varinameF = variname(dd)

     wks = gsn_open_wks(wks_type,getenv("OUTDIR")+"nino34_spacomp")
     plot_indmem      := new(nsim,"graphic")
     plot_indmem_diff := new(nsim,"graphic")
     if (nEM.ge.1) then
        plot_summary     := new((nEM*4),"graphic")
     end if
     numobs = num(EM_num.eq.0) 
     if (numobs.eq.0) then
        fnt = getenv("OUTDIR")+"obs.cvdp_data.sst.indices."+syear_zos(0)+"-"+eyear_zos(0)+".nc"      
        fnt2 = getenv("OUTDIR")+"obs.cvdp_data."+syear_zos(0)+"-"+eyear_zos(0)+".nc"
        cntr = 0
     else
        fnt = getenv("OUTDIR")+modname_zos(0)+".cvdp_data.sst.indices.zos."+syear_zos(0)+"-"+eyear_zos(0)+".nc"      
        fnt2 = getenv("OUTDIR")+modname_zos(0)+".cvdp_data."+syear_zos(0)+"-"+eyear_zos(0)+".nc"
        cntr = 1
     end if
     obs0 := read_cvdp_le_data(fnt,fnt2,str_sub_str(varinameF,"var","zos"))

     res@gsnCenterStringFontColor = "black"
     res2@gsnCenterStringFontColor = "black"
     res@lbLabelBarOn = False
     res2@lbLabelBarOn = False
     tres@lbLabelBarOn = False
     res@gsnLeftString = syear_zos(0)+"-"+eyear_zos(0) 
     res@gsnRightString = set_subtitle_enso_numevents(obs0,"Tot")
     res@gsnCenterString = names_zos(0)     
     plot_indmem(0) = gsn_csm_contour_map(wks,obs0,res)

;----Identify type of grid the first observational dataset is on and set appropriate ESMF options
     InterpMethod = "bilinear"
     Opt                := True
     Opt@SrcTitle       = names(0)+" grid"   ; optional
     Opt@WgtFileName    = modname(0)+"_to_ssti.WgtFile_"+InterpMethod+".nc"
     Opt@SrcFileName    = getenv("OUTDIR")+"/obs0.ssti.SCRIP_grid_description.nc"         ; Name of source and
     Opt@SrcRegional    = True  ; will verify this below

     if (isatt(obs0,"coordinates")) then   ; curvilinear 
        Opt@SrcGridType    = "curvilinear"
        if (max(obs0@lat2d)-min(obs0@lat2d).gt.100) then
           Opt@SrcRegional    = False
        end if
     else
        Opt@SrcGridType    = "rectilinear"
        Opt@SrcRegional    = False
     end if
     Opt@ForceOverwrite = True
     Opt@InterpMethod   = InterpMethod
     Opt@RemoveSrcFile  = True                  ; remove SCRIP grid destination files
     Opt@RemoveDstFile  = True 
     Opt@NoPETLog       = True

     cntr_EM = 0
     if (numobs.ge.2) then     ; plot obs #2-
        do ff = 1,numobs-1
           fnt = getenv("OUTDIR")+modname_zos(cntr)+".cvdp_data.sst.indices.zos."+syear_zos(cntr)+"-"+eyear_zos(cntr)+".nc"
           fnt2 = getenv("OUTDIR")+modname_zos(cntr)+".cvdp_data."+syear_zos(cntr)+"-"+eyear_zos(cntr)+".nc"
           arr := read_cvdp_le_data(fnt,fnt2,str_sub_str(varinameF,"var","zos"))
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
              Opt@DstGridLat     := arr&nlat
              Opt@DstGridLon     := arr&nlon
           end if

           Opt@DstFileName    = getenv("OUTDIR")+Opt@DstGridType+".ssti.SCRIP_grid_description.nc" 
           if (any(ismissing(obs0))) then
              Opt@DstMask2D  := where(ismissing(arr),0,1)  ; set SrcMask2D option to indicate the missing values 
           end if
           obs0_rg = ESMF_regrid(obs0, Opt)

           res@gsnLeftString = ""
           res@gsnRightString = set_subtitle_enso_numevents(arr,"Tot")   ;+"~C~   r="+pattern_correlation(obs0_rg,arr)
           res@gsnCenterString = names_zos(cntr)
           plot_indmem(cntr) = gsn_csm_contour_map(wks,arr,res)

           dim0 = dimsizes(arr)
           dim1 = dimsizes(obs0_rg)
           if (dim0(0).eq.dim1(0).and.dim0(1).eq.dim1(1)) then
              obs_diff = (/ arr - obs0_rg /)
           end if
           copy_VarMeta(arr,obs_diff)

           res2@gsnLeftString = ""   
           res2@gsnRightString = ""
           res2@gsnCenterString = names_zos(cntr)+" - "+names_zos(0)
           plot_indmem_diff(cntr) = gsn_csm_contour_map(wks,obs_diff,res2)   
           delete([/arr,obs_diff,obs0_rg/])
           cntr = cntr+1
        end do
     end if

     varinameF = variname(dd)
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
   
           fnt = getenv("OUTDIR")+modname_mod+".cvdp_data.sst.indices.zos."+syear_mod+"-"+eyear_mod+".nc"
           fnt2 = getenv("OUTDIR")+modname_mod+".cvdp_data."+syear_mod+"-"+eyear_mod+".nc"
           arr := read_cvdp_le_data(fnt,fnt2,str_sub_str(varinameF,"var","zos"))
           if (isatt(arr,"is_all_missing")) then
              continue
              cntr = cntr+1
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
              Opt@DstGridLat     := arr&nlat
              Opt@DstGridLon     := arr&nlon
           end if

           Opt@DstFileName    = getenv("OUTDIR")+Opt@DstGridType+".ssti.SCRIP_grid_description.nc" 
           if (any(ismissing(obs0))) then
              Opt@DstMask2D  := where(ismissing(arr),0,1)  ; set SrcMask2D option to indicate the missing values 
           end if
           if (.not.isvar("obs0_rg")) then  
              obs0_rg = ESMF_regrid(obs0, Opt)
           end if

           dim0 = dimsizes(arr)
           dim1 = dimsizes(obs0_rg)
           if (dim0(0).eq.dim1(0).and.dim0(1).eq.dim1(1)) then
              obs_diff = (/ arr - obs0_rg /)
           end if
           copy_VarMeta(arr,obs_diff)

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

              arr_store_events_E = new(nens,float)
              arr_store_events_L = new(nens,float) 

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
           arr_store(hh,:,:) = (/ arr /)
           arr_store@nens = arr_store@nens+1
           if (isatt(arr,"number_of_elnino_events")) then
              arr_store_events_E(hh) = arr@number_of_elnino_events
           end if
           if (isatt(arr,"number_of_lanina_events")) then
              arr_store_events_L(hh) = arr@number_of_lanina_events
           end if

           res@gsnLeftString   = syear_mod+"-"+eyear_mod
           res@gsnRightString = set_subtitle_enso_numevents(arr,"Tot")    ;+"~C~   r="+pattern_correlation(obs0_rg,arr)
           res@gsnCenterString = names_mod
           plot_indmem(cntr) = gsn_csm_contour_map(wks,arr,res)
           panres@lbTitleString = arr@units

           res2@gsnLeftString = "" 
           res2@gsnRightString = "" 
           res2@gsnCenterString = names_mod+" - "+names_zos(0)
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
        arr_EM = dim_avg_n_Wrap(arr_store,0)
   
        res@gsnCenterStringFontColor = "black"
        res2@gsnCenterStringFontColor = "black"
        res@lbTitleString = arr_EM@units   
   
        res@gsnLeftString = syear_zos(0)+"-"+eyear_zos(0) 
        res@gsnRightString = set_subtitle_enso_numevents(obs0,"Tot")
        res@gsnCenterString = names_zos(0)    
        plot_summary(cntr_EM+1) = gsn_csm_contour_map(wks,obs0,res)
   
        if (showyr) then
           res@gsnLeftString = syear_em0+"-"+eyear_em0 
        else
           res@gsnLeftString = (eyear_em0-syear_em0+1)+"yrs" 
        end if
        delete([/syear_em0,eyear_em0,showyr/])

        res@gsnRightStringOrthogonalPosF = -0.97
        res@gsnCenterStringFontColor = csubtitle_color(gg-1)
        res@gsnRightString = ""
        if (.not.all(ismissing(arr_store_events_E))) then
           if (.not.all(ismissing(arr_store_events_L))) then
              res@gsnRightString = decimalPlaces(avg(arr_store_events_E),0,True)+" EN/"+decimalPlaces(avg(arr_store_events_L),0,True)+" LN Avg~C~"+\
                             "   "+sum(arr_store_events_E)+" EN/"+sum(arr_store_events_E)+" LN Tot"  ;~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~"+\
;                             "   r="+pattern_correlation(obs0_rg,arr_EM)
           else
              res@gsnRightString = decimalPlaces(avg(arr_store_events_E),0,True)+" EN Avg/"+sum(arr_store_events_E)+" EN Tot" ;~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~"+\
;                             "   r="+pattern_correlation(obs0_rg,arr_EM)
           end if
        else
           if (.not.all(ismissing(arr_store_events_L))) then
              res@gsnRightString = decimalPlaces(avg(arr_store_events_L),0,True)+" LN Avg/"+sum(arr_store_events_L)+" LN Tot"  ;~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~"+\
;                             "   r="+pattern_correlation(obs0_rg,arr_EM)
           end if
        end if
        res@gsnCenterString = names_EM_mod +" ("+arr_store@nens+" Members)"
        plot_summary(cntr_EM) = gsn_csm_contour_map(wks,arr_EM,res)
        res@gsnRightStringOrthogonalPosF = -0.07
        obs_diff = arr_EM
        obs_diff = (/ arr_EM - obs0_rg /)
        res2@gsnLeftString = ""
        res2@gsnCenterString = names_EM_mod+" - "+names_zos(0)
        res2@gsnRightString = ""
        plot_summary(cntr_EM+2) = gsn_csm_contour_map(wks,obs_diff,res2)
   
        p_val := calculate_pval(obs0_rg,arr_store)
        tres@gsnLeftString = "ZOS" 
        tres@gsnRightString = ""  ;calculate_area_in_range(p_val,10,90)+"%"
        tres@gsnCenterString = "Rank of "+names_zos(0)+" within Ensemble"   
        plot_summary(cntr_EM+3) = gsn_csm_contour_map(wks,p_val,tres)
   
        fno = getenv("OUTDIR")+str_sub_str(names_EM_mod," ","_")+"_EM.cvdp_data.sst.indices.zos."+syear_mod+"-"+eyear_mod+".nc"
        if (isfilepresent2(fno)) then
           z = addfile(fno,"w")
        else
           z = addfile(fno,"c")
           set_global_ncfile_attributes(z,names_EM_mod,syear_mod,eyear_mod,getenv("VERSION"))
        end if
        if (isatt(arr_EM,"lat2d")) then
           LAT2D := arr_EM@lat2d
           LON2D := arr_EM@lon2d
           delete([/arr_EM@lat2d,arr_EM@lon2d,obs_diff@lat2d,obs_diff@lon2d,p_val@lat2d,p_val@lon2d/])
           copy_VarCoords(arr_EM,LAT2D)
           copy_VarCoords(arr_EM,LON2D)
           z->$(/"lat2d_ocean"/)$ = set_varAtts(LAT2D,"ocean grid 2-dimensional latitudes","degrees_north","")
           z->$(/"lon2d_ocean"/)$ = set_varAtts(LON2D,"ocean grid 2-dimensional longitudes","degrees_east","")
           arr_EM@coordinates ="lat2d_ocean lon2d_ocean"
           obs_diff@coordinates ="lat2d_ocean lon2d_ocean"
           p_val@coordinates ="lat2d_ocean lon2d_ocean"
        end if
        z->$(/"nino34_spacomp_zos_"+variname_seas(dd)+"_em"/)$ = set_varAtts(arr_EM,arr_EM@long_name+" Ensemble Mean","","")
        z->$(/"nino34_spacomp_zos_"+variname_seas(dd)+"_em_diffobs"/)$ = set_varAtts(obs_diff,obs_diff@long_name+" Ensemble Mean difference from "+names_zos(0),"","")           
        z->$(/"nino34_spacomp_zos_"+variname_seas(dd)+"_pval"/)$ = set_varAtts(p_val,arr_EM@long_name+" p-val statistic","%","")   
        delete([/arr_store,obs0_rg,obs_diff,arr_EM,z,p_val,arr_store_events_E,arr_store_events_L/])
        cntr_EM = cntr_EM+4
     end do
     if (isfilepresent2(Opt@WgtFileName)) then
        system("rm "+Opt@WgtFileName)
     end if

     panres@txString = variname_panel_title_subs(dd)+" Spatial Composite ZOS "+variname_title_seas(dd)
     gsn_panel2(wks,plot_indmem,(/nrow,ncol/),panres)
     
     panres@txString = variname_panel_title_subs(dd)+" Spatial Composite Differences ZOS "+variname_title_seas(dd)
     gsn_panel2(wks,plot_indmem_diff,(/nrow,ncol/),panres)

     if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
        panres2@txString = "Ensemble Summary: "+variname_panel_title_subs(dd)+" Spatial Composite ZOS "+variname_title_seas(dd)
        panres2@gsnPanelXWhiteSpacePercent = 3.0
        gsn_panel2(wks,plot_summary,(/nEM,4/),panres2)
        delete(panres2@gsnPanelXWhiteSpacePercent)
     end if
     delete(wks)

     if (wks_type.eq."png") then
        system("mv "+OUTDIR+"nino34_spacomp.000001.png "+OUTDIR+"nino34.spatialcomp"+fnaddsub(dd)+".zos.indmem."+variname_seas(dd)+".png")
        system("mv "+OUTDIR+"nino34_spacomp.000002.png "+OUTDIR+"nino34.spatialcomp"+fnaddsub(dd)+".zos.indmemdiff."+variname_seas(dd)+".png")
        if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
           system("mv "+OUTDIR+"nino34_spacomp.000003.png "+OUTDIR+"nino34.spatialcomp"+fnaddsub(dd)+".zos.summary."+variname_seas(dd)+".png")
           if (PNG_SCALE_SUMMARY.ne.100) then
              system(IM_COMMAND+" "+OUTDIR+"nino34.spatialcomp"+fnaddsub(dd)+".zos.summary."+variname_seas(dd)+".png -resize "+PNG_SCALE_SUMMARY+"% "+OUTDIR+"nino34.spatialcomp"+fnaddsub(dd)+".pr.summary."+variname_seas(dd)+".png")
           end if
        end if
     else
        system("psplit "+OUTDIR+"nino34_spacomp.ps "+OUTDIR+"nino34.spacomp")
        system("mv "+OUTDIR+"nino34.spacomp0001.ps "+OUTDIR+"nino34.spatialcomp"+fnaddsub(dd)+".zos.indmem."+variname_seas(dd)+".ps")
        system("mv "+OUTDIR+"nino34.spacomp0002.ps "+OUTDIR+"nino34.spatialcomp"+fnaddsub(dd)+".zos.indmemdiff."+variname_seas(dd)+".ps")
        if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
           system("mv "+OUTDIR+"nino34.spacomp0003.ps "+OUTDIR+"nino34.spatialcomp"+fnaddsub(dd)+".zos.summary."+variname_seas(dd)+".ps")
        end if
        system("rm "+OUTDIR+"nino34_spacomp.ps")
     end if
  end do
;---ENSO PR Spatial Composite plotting section---------------------------------------------------------------------------
  delete([/res@cnLevels,res2@cnLevels,res@cnFillPalette,res2@cnFillPalette,res@trGridType,res2@trGridType/]) 
  if (isatt(res,"lbLabelStrings")) then
     delete(res@lbLabelStrings)
  end if
  if (isatt(res2,"lbLabelStrings")) then
     delete(res2@lbLabelStrings)
  end if

  res@lbLabelFontHeightF = 0.018   ; make summary label bars labels a bit smaller to print additional labels
  res2@lbLabelFontHeightF = 0.018
  tres@lbLabelFontHeightF = 0.018

  if (COLORMAP.eq.0) then
     res@cnExplicitLabelBarLabelsOn = True
     res2@cnExplicitLabelBarLabelsOn = True
     res@cnLevels = (/-5,-4,-3,-2,-1,-.75,-.5,-.25,-.1,0,.1,.25,.5,.75,1,2,3,4,5/)  
     res@lbLabelStrings = (/"-5","-4","-3","-2","-1","-.75","-.5","-.25","-.1","0",".1",".25",".5",".75","1","2","3","4","5"/)
     res@cnFillPalette = "MPL_BrBG"  
     res2@lbLabelStrings = res@lbLabelStrings
  end if
  if (COLORMAP.eq.1) then
     res@cnLevels = (/-3,-2,-1,-.5,-.1,0,.1,.5,1,2,3/)
     res@cnFillPalette = "BrownBlue12"     
  end if 
  res2@cnLevels = res@cnLevels
  res2@cnFillPalette = res@cnFillPalette
  res@cnMissingValFillColor = "gray90"
  res2@cnMissingValFillColor = "gray90"

  res@gsnRightStringOrthogonalPosF = -0.07
  res@gsnRightStringParallelPosF = 1.025
  do dd = 0,dimsizes(variname)-1
     varinameF = str_sub_str(variname(dd),"nino34","nino34")

     wks = gsn_open_wks(wks_type,getenv("OUTDIR")+"nino34_spacomp")
     plot_indmem      := new(nsim,"graphic")
     plot_indmem_diff := new(nsim,"graphic")
     if (nEM.ge.1) then
        plot_summary     := new((nEM*4),"graphic")
     end if
     numobs = num(EM_num.eq.0) 
     if (numobs.eq.0) then
        fnt = getenv("OUTDIR")+"obs.cvdp_data.sst.indices.pr."+syear_pr(0)+"-"+eyear_pr(0)+".nc"      
        fnt2 = getenv("OUTDIR")+"obs.cvdp_data."+syear_pr(0)+"-"+eyear_pr(0)+".nc"
        cntr = 0
     else
        fnt = getenv("OUTDIR")+modname_pr(0)+".cvdp_data.sst.indices.pr."+syear_pr(0)+"-"+eyear_pr(0)+".nc"      
        fnt2 = getenv("OUTDIR")+modname_pr(0)+".cvdp_data."+syear_pr(0)+"-"+eyear_pr(0)+".nc"
        cntr = 1
     end if
     obs0 := read_cvdp_le_data(fnt,fnt2,str_sub_str(varinameF,"var","pr"))

     res@gsnCenterStringFontColor = "black"
     res2@gsnCenterStringFontColor = "black"
     res@lbLabelBarOn = False
     res2@lbLabelBarOn = False
     tres@lbLabelBarOn = False
     res@gsnLeftString = syear_pr(0)+"-"+eyear_pr(0) 
     res@gsnRightString = set_subtitle_enso_numevents(obs0,"Tot")
     res@gsnCenterString = names_pr(0)     
     plot_indmem(0) = gsn_csm_contour_map(wks,obs0,res)
     cntr_EM = 0
     if (numobs.ge.2) then     ; plot obs #2-
        do ff = 1,numobs-1
           fnt = getenv("OUTDIR")+modname_pr(cntr)+".cvdp_data.sst.indices.pr."+syear_pr(cntr)+"-"+eyear_pr(cntr)+".nc"
           fnt2 = getenv("OUTDIR")+modname_pr(cntr)+".cvdp_data."+syear_pr(cntr)+"-"+eyear_pr(cntr)+".nc"
           arr := read_cvdp_le_data(fnt,fnt2,str_sub_str(varinameF,"var","pr"))
           if (isatt(arr,"is_all_missing")) then 
              cntr = cntr+1
              continue
           end if

           obs0_rg = linint2_Wrap(obs0&lon,obs0&lat,obs0,True,arr&lon,arr&lat,0)
           obs_diff = arr
           obs_diff = (/ arr - obs0_rg /)

           res@gsnLeftString = ""
           res@gsnRightString = set_subtitle_enso_numevents(arr,"Tot")+"~C~   r="+pattern_correlation(obs0_rg,arr)
           res@gsnCenterString = names_pr(cntr)
           plot_indmem(cntr) = gsn_csm_contour_map(wks,arr,res)
           res2@gsnLeftString = ""   
           res2@gsnRightString = ""
           res2@gsnCenterString = names_pr(cntr)+" - "+names_pr(0)
           plot_indmem_diff(cntr) = gsn_csm_contour_map(wks,obs_diff,res2)   
           delete([/arr,obs_diff,obs0_rg/])
           cntr = cntr+1
        end do
     end if

     varinameF = variname(dd)
     do gg = nEMm,nEM   ; operate on each ensemble mean (or individual member)
        if (gg.eq.0) then
           continue
        end if
        lbFlag = summary_lb_flag(paths,EM_num,gg,nEM)  ; lbFlag set to True if summary labelbars should be drawn  
        nens = num(EM_num.eq.gg) ; determines how many model simulations in each ensemble
        cntr_ens := ind(EM_num.eq.gg)   ; cntr_ens(hh) are the indices where each ensemble member of an ensemble reside 
        do hh = 0,nens-1
           modname_mod = modname_pr(cntr_ens(hh))
           syear_mod = syear_pr(cntr_ens(hh))
           eyear_mod = eyear_pr(cntr_ens(hh))
           names_mod = names_pr(cntr_ens(hh))
           names_EM_mod = names_EM(cntr_ens(hh))
   
           fnt = getenv("OUTDIR")+modname_mod+".cvdp_data.sst.indices.pr."+syear_mod+"-"+eyear_mod+".nc"
           fnt2 = getenv("OUTDIR")+modname_mod+".cvdp_data."+syear_mod+"-"+eyear_mod+".nc"
           arr := read_cvdp_le_data(fnt,fnt2,str_sub_str(varinameF,"var","pr"))
           if (isatt(arr,"is_all_missing")) then
              continue
              cntr = cntr+1
           end if

           if (.not.isvar("arr_store")) then  ; create an array to house all members, to be used to calculate EM
              arr_store = new((/nens,dimsizes(arr&lat),dimsizes(arr&lon)/),typeof(arr))
              arr_store!0 = "ensmem"
              arr_store!1 = "lat"
              arr_store&lat = arr&lat
              arr_store!2 = "lon"
              arr_store&lon = arr&lon
              arr_store@nens = 0
              copy_VarAtts(arr,arr_store)

              arr_store_events_E = new(nens,float)
              arr_store_events_L = new(nens,float) 

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
           arr_store(hh,:,:) = (/ arr /)
           arr_store@nens = arr_store@nens+1
           if (isatt(arr,"number_of_elnino_events")) then
              arr_store_events_E(hh) = arr@number_of_elnino_events
           end if
           if (isatt(arr,"number_of_lanina_events")) then
              arr_store_events_L(hh) = arr@number_of_lanina_events
           end if

           if (.not.isvar("obs0_rg")) then  
              obs0_rg = linint2_Wrap(obs0&lon,obs0&lat,obs0,True,arr&lon,arr&lat,0)
           end if
           obs_diff = arr
           obs_diff = (/ arr - obs0_rg /)

           res@gsnLeftString   = syear_mod+"-"+eyear_mod
           res@gsnRightString = set_subtitle_enso_numevents(arr,"Tot")+"~C~   r="+pattern_correlation(obs0_rg,arr)
           res@gsnCenterString = names_mod
           plot_indmem(cntr) = gsn_csm_contour_map(wks,arr,res)
           panres@lbTitleString = arr@units

           res2@gsnLeftString = "" 
           res2@gsnRightString = "" 
           res2@gsnCenterString = names_mod+" - "+names_pr(0)
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
        arr_EM = dim_avg_n_Wrap(arr_store,0)
   
        res@gsnCenterStringFontColor = "black"
        res2@gsnCenterStringFontColor = "black"
        res@lbTitleString = arr_EM@units   
   
        res@gsnLeftString = syear_pr(0)+"-"+eyear_pr(0) 
        res@gsnRightString = set_subtitle_enso_numevents(obs0,"Tot")
        res@gsnCenterString = names_pr(0)    
        plot_summary(cntr_EM+1) = gsn_csm_contour_map(wks,obs0,res)
   
        if (showyr) then
           res@gsnLeftString = syear_em0+"-"+eyear_em0 
        else
           res@gsnLeftString = (eyear_em0-syear_em0+1)+"yrs" 
        end if
        delete([/syear_em0,eyear_em0,showyr/])

        res@gsnRightStringOrthogonalPosF = -0.97
        res@gsnCenterStringFontColor = csubtitle_color(gg-1)
        res@gsnRightString = ""
        if (.not.all(ismissing(arr_store_events_E))) then
           if (.not.all(ismissing(arr_store_events_L))) then
              res@gsnRightString = decimalPlaces(avg(arr_store_events_E),0,True)+" EN/"+decimalPlaces(avg(arr_store_events_L),0,True)+" LN Avg~C~"+\
                             "   "+sum(arr_store_events_E)+" EN/"+sum(arr_store_events_E)+" LN Tot~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~"+\
                             "   r="+pattern_correlation(obs0_rg,arr_EM)
           else
              res@gsnRightString = decimalPlaces(avg(arr_store_events_E),0,True)+" EN Avg/"+sum(arr_store_events_E)+" EN Tot~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~"+\
                             "   r="+pattern_correlation(obs0_rg,arr_EM)
           end if
        else
           if (.not.all(ismissing(arr_store_events_L))) then
              res@gsnRightString = decimalPlaces(avg(arr_store_events_L),0,True)+" LN Avg/"+sum(arr_store_events_L)+" LN Tot~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~~C~"+\
                             "   r="+pattern_correlation(obs0_rg,arr_EM)
           end if
        end if
        res@gsnCenterString = names_EM_mod +" ("+arr_store@nens+" Members)"
        plot_summary(cntr_EM) = gsn_csm_contour_map(wks,arr_EM,res)
        res@gsnRightStringOrthogonalPosF = -0.07
        obs_diff = arr_EM
        obs_diff = (/ arr_EM - obs0_rg /)
        res2@lbTitleString = arr_EM@units   
        res2@gsnLeftString = ""
        res2@gsnCenterString = names_EM_mod+" - "+names_pr(0)
        res2@gsnRightString = ""
        plot_summary(cntr_EM+2) = gsn_csm_contour_map(wks,obs_diff,res2)
   
        p_val := calculate_pval(obs0_rg,arr_store)
        tres@gsnLeftString = "PR" 
        tres@gsnCenterString = "Rank of "+names_pr(0)+" within Ensemble"   
        tres@gsnRightString = calculate_area_in_range(p_val,10,90)+"%"

        plot_summary(cntr_EM+3) = gsn_csm_contour_map(wks,p_val,tres)
   
        fno = getenv("OUTDIR")+str_sub_str(names_EM_mod," ","_")+"_EM.cvdp_data.sst.indices.pr."+syear_mod+"-"+eyear_mod+".nc"
        if (isfilepresent2(fno)) then
           z = addfile(fno,"w")
        else
           z = addfile(fno,"c")
           set_global_ncfile_attributes(z,names_EM_mod,syear_mod,eyear_mod,getenv("VERSION"))
        end if
        z->$(/"nino34_spacomp_pr_"+variname_seas(dd)+"_em"/)$ = set_varAtts(arr_EM,arr_EM@long_name+" Ensemble Mean","","")
        z->$(/"nino34_spacomp_pr_"+variname_seas(dd)+"_em_diffobs"/)$ = set_varAtts(obs_diff,obs_diff@long_name+" Ensemble Mean difference from "+names_pr(0),"","")           
        z->$(/"nino34_spacomp_pr_"+variname_seas(dd)+"_pval"/)$ = set_varAtts(p_val,arr_EM@long_name+" p-val statistic","%","")   
        delete([/arr_store,obs0_rg,obs_diff,arr_EM,z,p_val,arr_store_events_E,arr_store_events_L/])
        cntr_EM = cntr_EM+4
     end do
     panres@txString = variname_panel_title_subs(dd)+" Spatial Composite PR "+variname_title_seas(dd)
     gsn_panel2(wks,plot_indmem,(/nrow,ncol/),panres)
     
     panres@txString = variname_panel_title_subs(dd)+" Spatial Composite Differences PR "+variname_title_seas(dd)
     gsn_panel2(wks,plot_indmem_diff,(/nrow,ncol/),panres)

     if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
        panres2@txString = "Ensemble Summary: "+variname_panel_title_subs(dd)+" Spatial Composite PR "+variname_title_seas(dd)
        panres2@gsnPanelXWhiteSpacePercent = 3.0
        gsn_panel2(wks,plot_summary,(/nEM,4/),panres2)
        delete(panres2@gsnPanelXWhiteSpacePercent)
     end if
     delete(wks)

     if (wks_type.eq."png") then
        system("mv "+OUTDIR+"nino34_spacomp.000001.png "+OUTDIR+"nino34.spatialcomp"+fnaddsub(dd)+".pr.indmem."+variname_seas(dd)+".png")
        system("mv "+OUTDIR+"nino34_spacomp.000002.png "+OUTDIR+"nino34.spatialcomp"+fnaddsub(dd)+".pr.indmemdiff."+variname_seas(dd)+".png")
        if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
           system("mv "+OUTDIR+"nino34_spacomp.000003.png "+OUTDIR+"nino34.spatialcomp"+fnaddsub(dd)+".pr.summary."+variname_seas(dd)+".png")
           if (PNG_SCALE_SUMMARY.ne.100) then
              system(IM_COMMAND+" "+OUTDIR+"nino34.spatialcomp"+fnaddsub(dd)+".pr.summary."+variname_seas(dd)+".png -resize "+PNG_SCALE_SUMMARY+"% "+OUTDIR+"nino34.spatialcomp"+fnaddsub(dd)+".pr.summary."+variname_seas(dd)+".png")
           end if
        end if
     else
        system("psplit "+OUTDIR+"nino34_spacomp.ps "+OUTDIR+"nino34.spacomp")
        system("mv "+OUTDIR+"nino34.spacomp0001.ps "+OUTDIR+"nino34.spatialcomp"+fnaddsub(dd)+".pr.indmem."+variname_seas(dd)+".ps")
        system("mv "+OUTDIR+"nino34.spacomp0002.ps "+OUTDIR+"nino34.spatialcomp"+fnaddsub(dd)+".pr.indmemdiff."+variname_seas(dd)+".ps")
        if (nEM.ge.1) then   ; in ensemble mode (runstyle=2) 
           system("mv "+OUTDIR+"nino34.spacomp0003.ps "+OUTDIR+"nino34.spatialcomp"+fnaddsub(dd)+".pr.summary."+variname_seas(dd)+".ps")
        end if
        system("rm "+OUTDIR+"nino34_spacomp.ps")
     end if
  end do
;---SST timeseries regression plotting section---------------------------------------------------------------------------
  delete([/res@cnLevels,res2@cnLevels,res@cnFillPalette,res2@cnFillPalette/]) 
  if (isatt(res,"lbLabelStrings")) then
     delete(res@lbLabelStrings)
  end if
  if (isatt(res2,"lbLabelStrings")) then
     delete(res2@lbLabelStrings)
  end if

  res@cnExplicitLabelBarLabelsOn = False
  res2@cnExplicitLabelBarLabelsOn = False

  res@lbLabelFontHeightF = 0.018   ; make summary label bars labels a bit smaller to print additional labels
  res2@lbLabelFontHeightF = 0.018
  tres@lbLabelFontHeightF = 0.018

  if (COLORMAP.eq.0) then
     res@cnLevels = (/-2,-1.75,-1.5,-1.25,-1,-0.75,-0.5,-0.25,-0.1,0,0.1,0.25,.5,.75,1,1.25,1.5,1.75,2/)
     res@cnFillPalette = "ncl_default"
  end if
  if (COLORMAP.eq.1) then
     res@cnLevels = (/-1.75,-1.5,-1.25,-1,-0.75,-0.5,-0.25,0,0.25,0.5,0.75,1,1.25,1.5,1.75/)
     res@cnFillPalette = "BlueDarkRed18"
  end if 
  res2@cnLevels = res@cnLevels
  res2@cnFillPalette = res@cnFillPalette
  res@cnMissingValFillColor = "gray90"
  res2@cnMissingValFillColor = "gray90"

  res@gsnRightStringOrthogonalPosF = -0.07
  res@gsnRightStringParallelPosF = 1.025

  variname := (/"nino34","nino12","nino3","nino4","atlantic_meridional_mode","atlantic_nino",\
                "north_tropical_atlantic","south_tropical_atlantic","indian_ocean_dipole","tropical_indian_ocean",\
                "southern_ocean","north_atlantic","north_pacific_meridional_mode","south_pacific_meridional_mode"/)
  variname = variname+"_pattern_mon"

  variname_title := (/"Nin~H-13V2F35~D~FV-2H3F21~o3.4","Nin~H-13V2F35~D~FV-2H3F21~o1+2",\
                     "Nin~H-13V2F35~D~FV-2H3F21~o3","Nin~H-13V2F35~D~FV-2H3F21~o4",\
                     "Atlantic Meridional Mode","Atlantic Nin~H-13V2F35~D~FV-2H3F21~o3",\
                     "Tropical North Atlantic","Tropical South Atlantic",\
                     "Indian Ocean Dipole","Tropical Indian Ocean","Southern Ocean",\
                     "North Atlantic","North Pacific Meridional Mode","South Pacific Meridional Mode"/)
  variname_title = variname_title+" SST Regression Pattern"

  centerlon = (/210,210,210,210,0,0,0,0,80,80,210,0,210,210/)   ; where to center the longitudes for spatial plot 

  do dd = 0,dimsizes(variname)-1
     varinameF = variname(dd)

     res@mpCenterLonF = centerlon(dd)
     res2@mpCenterLonF = centerlon(dd)
     tres@mpCenterLonF = centerlon(dd)

     wks = gsn_open_wks(wks_type,getenv("OUTDIR")+"sst_regr_pattern")
     plot_indmem      := new(nsim,"graphic")
     plot_indmem_diff := new(nsim,"graphic")
     if (nEM.ge.1) then
        plot_summary     := new((nEM*4),"graphic")
     end if
     numobs = num(EM_num.eq.0) 
     if (numobs.eq.0) then
        fnt = getenv("OUTDIR")+"obs.cvdp_data.sst.indices."+syear(0)+"-"+eyear(0)+".nc"      
        fnt2 = getenv("OUTDIR")+"obs.cvdp_data."+syear(0)+"-"+eyear(0)+".nc"
        cntr = 0
     else
        fnt = getenv("OUTDIR")+modname(0)+".cvdp_data.sst.indices."+syear(0)+"-"+eyear(0)+".nc"      
        fnt2 = getenv("OUTDIR")+modname(0)+".cvdp_data."+syear(0)+"-"+eyear(0)+".nc"
        cntr = 1
     end if
     obs0 := read_cvdp_le_data(fnt,fnt2,varinameF)

     res@gsnCenterStringFontColor = "black"
     res2@gsnCenterStringFontColor = "black"
     res@lbLabelBarOn = False
     res2@lbLabelBarOn = False
     tres@lbLabelBarOn = False
     res@gsnLeftString = syear(0)+"-"+eyear(0) 
     res@gsnRightString = ""
     res@gsnCenterString = names(0)     
     plot_indmem(0) = gsn_csm_contour_map(wks,obs0,res)
     cntr_EM = 0
     if (numobs.ge.2) then     ; plot obs #2-
        do ff = 1,numobs-1
           fnt = getenv("OUTDIR")+modname(cntr)+".cvdp_data.sst.indices."+syear(cntr)+"-"+eyear(cntr)+".nc"
           fnt2 = getenv("OUTDIR")+modname(cntr)+".cvdp_data."+syear(cntr)+"-"+eyear(cntr)+".nc"
           arr := read_cvdp_le_data(fnt,fnt2,varinameF)
           if (isatt(arr,"is_all_missing")) then 
              cntr = cntr+1
              continue
           end if

           obs0_rg = linint2_Wrap(obs0&lon,obs0&lat,obs0,True,arr&lon,arr&lat,0)
           obs_diff = arr
           obs_diff = (/ arr - obs0_rg /)

           res@gsnLeftString = ""
           res@gsnRightString = ""
           res@gsnCenterString = names(cntr)
           plot_indmem(cntr) = gsn_csm_contour_map(wks,arr,res)
           res2@gsnLeftString = ""   
           res2@gsnRightString = ""
           res2@gsnCenterString = names(cntr)+" - "+names(0)
           plot_indmem_diff(cntr) = gsn_csm_contour_map(wks,obs_diff,res2)   
           delete([/arr,obs_diff,obs0_rg/])
           cntr = cntr+1
        end do
     end if

     varinameF = variname(dd)
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
   
           fnt = getenv("OUTDIR")+modname_mod+".cvdp_data.sst.indices."+syear_mod+"-"+eyear_mod+".nc"
           fnt2 = getenv("OUTDIR")+modname_mod+".cvdp_data."+syear_mod+"-"+eyear_mod+".nc"
           arr := read_cvdp_le_data(fnt,fnt2,varinameF)
           if (isatt(arr,"is_all_missing")) then
              continue
              cntr = cntr+1
           end if

           if (.not.isvar("arr_store")) then  ; create an array to house all members, to be used to calculate EM
              arr_store = new((/nens,dimsizes(arr&lat),dimsizes(arr&lon)/),typeof(arr))
              arr_store!0 = "ensmem"
              arr_store!1 = "lat"
              arr_store&lat = arr&lat
              arr_store!2 = "lon"
              arr_store&lon = arr&lon
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
           arr_store(hh,:,:) = (/ arr /)
           arr_store@nens = arr_store@nens+1

           if (.not.isvar("obs0_rg")) then  
              obs0_rg = linint2_Wrap(obs0&lon,obs0&lat,obs0,True,arr&lon,arr&lat,0)
           end if
           obs_diff = arr
           obs_diff = (/ arr - obs0_rg /)

           res@gsnLeftString  = syear_mod+"-"+eyear_mod
           res@gsnRightString = "r="+pattern_correlation(obs0_rg,arr)
           res@gsnCenterString = names_mod
           plot_indmem(cntr) = gsn_csm_contour_map(wks,arr,res)
           panres@lbTitleString = arr@units

           res2@gsnLeftString = "" 
           res2@gsnRightString = "" 
           res2@gsnCenterString = names_mod+" - "+names(0)
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
        arr_EM = dim_avg_n_Wrap(arr_store,0)
   
        res@gsnCenterStringFontColor = "black"
        res2@gsnCenterStringFontColor = "black"
        res@lbTitleString = arr_EM@units   
   
        res@gsnLeftString = syear(0)+"-"+eyear(0) 
        res@gsnRightString = ""
        res@gsnCenterString = names(0)    
        plot_summary(cntr_EM+1) = gsn_csm_contour_map(wks,obs0,res)
   
        if (showyr) then
           res@gsnLeftString = syear_em0+"-"+eyear_em0 
        else
           res@gsnLeftString = (eyear_em0-syear_em0+1)+"yrs" 
        end if
        delete([/syear_em0,eyear_em0,showyr/])

        res@gsnRightStringOrthogonalPosF = -0.97
        res@gsnCenterStringFontColor = csubtitle_color(gg-1)
        res@gsnRightString = ""
        res@gsnRightString = "r="+pattern_correlation(obs0_rg,arr_EM)
        res@gsnCenterString = names_EM_mod +" ("+arr_store@nens+" Members)"
        plot_summary(cntr_EM) = gsn_csm_contour_map(wks,arr_EM,res)
        res@gsnRightStringOrthogonalPosF = -0.07
        obs_diff = arr_EM
        obs_diff = (/ arr_EM - obs0_rg /)
        res2@lbTitleString = arr_EM@units   
        res2@gsnLeftString = ""
        res2@gsnCenterString = names_EM_mod+" - "+names(0)
        res2@gsnRightString = ""
        plot_summary(cntr_EM+2) = gsn_csm_contour_map(wks,obs_diff,res2)
   
        p_val := calculate_pval(obs0_rg,arr_store)
        tres@gsnLeftString = "" 
        tres@gsnCenterString = "Rank of "+names(0)+" within Ensemble"   
        tres@gsnRightString = calculate_area_in_range(p_val,10,90)+"%"

        plot_summary(cntr_EM+3) = gsn_csm_contour_map(wks,p_val,tres)
   
        fno = getenv("OUTDIR")+str_sub_str(names_EM_mod," ","_")+"_EM.cvdp_data.sst.indices."+syear_mod+"-"+eyear_mod+".nc"
        if (isfilepresent2(fno)) then
           z = addfile(fno,"w")
        else
           z = addfile(fno,"c")
           set_global_ncfile_attributes(z,names_EM_mod,syear_mod,eyear_mod,getenv("VERSION"))
        end if
        z->$(/varinameF+"_em"/)$ = set_varAtts(arr_EM,arr_EM@long_name+" Ensemble Mean","","")
        z->$(/varinameF+"_em_diffobs"/)$ = set_varAtts(obs_diff,obs_diff@long_name+" Ensemble Mean difference from "+names(0),"","")           
        z->$(/varinameF+"_pval"/)$ = set_varAtts(p_val,arr_EM@long_name+" p-val statistic","%","")   
        delete([/arr_store,obs0_rg,obs_diff,arr_EM,z,p_val/])
        cntr_EM = cntr_EM+4
     end do
     panres@txString = variname_title(dd)+" (Monthly)"
     gsn_panel2(wks,plot_indmem,(/nrow,ncol/),panres)
     
     panres@txString = variname_title(dd)+" Differences (Monthly)"
     gsn_panel2(wks,plot_indmem_diff,(/nrow,ncol/),panres)

     if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
        panres2@txString = "Ensemble Summary: "+variname_title(dd)+" (Monthly)"
        panres2@gsnPanelXWhiteSpacePercent = 3.0
        gsn_panel2(wks,plot_summary,(/nEM,4/),panres2)
        delete(panres2@gsnPanelXWhiteSpacePercent)
     end if
     delete(wks)

     if (wks_type.eq."png") then
        system("mv "+OUTDIR+"sst_regr_pattern.000001.png "+OUTDIR+str_sub_str(varinameF,"_mon","")+".indmem.png")
        system("mv "+OUTDIR+"sst_regr_pattern.000002.png "+OUTDIR+str_sub_str(varinameF,"_mon","")+".indmemdiff.png")
        if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
           system("mv "+OUTDIR+"sst_regr_pattern.000003.png "+OUTDIR+str_sub_str(varinameF,"_mon","")+".summary.png")
           if (PNG_SCALE_SUMMARY.ne.100) then
              system(IM_COMMAND+" "+OUTDIR+str_sub_str(varinameF,"_mon","")+".summary.png -resize "+PNG_SCALE_SUMMARY+"% "+OUTDIR+str_sub_str(varinameF,"_mon","")+".summary.png")
           end if
        end if
     else
        system("psplit "+OUTDIR+"sst_regr_pattern.ps "+OUTDIR+"sst_regr_pattern")
        system("mv "+OUTDIR+"sst_regr_pattern0001.ps "+OUTDIR+str_sub_str(varinameF,"_mon","")+".indmem.ps")
        system("mv "+OUTDIR+"sst_regr_pattern0002.ps "+OUTDIR+str_sub_str(varinameF,"_mon","")+".indmemdiff.ps")
        if (nEM.ge.1) then   ; in ensemble mode (runstyle=2) 
           system("mv "+OUTDIR+"sst_regr_pattern0003.ps "+OUTDIR+str_sub_str(varinameF,"_mon","")+".summary.ps")
        end if
        system("rm "+OUTDIR+"sst_regr_pattern.ps")
     end if
  end do
  delete([/res,res2,res3,res4,res5,res6,panres,panres2,tres2/])
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
  xyres@gsnRightStringOrthogonalPosF = xyres@gsnLeftStringOrthogonalPosF
  xyres@gsnCenterStringOrthogonalPosF = -1.0
  xyres@gsnCenterStringParallelPosF = 0.05
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
  panres3@gsnMainPanelFontHeightF = 0.010
  panres3@gsnPanelBottom = 0.05
  panres3@gsnPanelYWhiteSpacePercent = 2.5

  panres4 = panres3  ; panel resource list for ensemble plots
  panres4@gsnMainPanelFontHeightF = 0.008
  panres4@gsnMaximize = False
  panres4@gsnFrame = False
  panres4@gsnPanelTop = 0.94
  panres4@gsnPanelXWhiteSpacePercent = 3.0
  panres4@gsnPanelYWhiteSpacePercent = 3.0

  txres = True
  txres@txFontHeightF = 0.010
  txres@txFontColor = xyres2@xyLineColor

  variname := (/"nino34","nino12","nino3","nino4","atlantic_meridional_mode","atlantic_nino",\
                "north_tropical_atlantic","south_tropical_atlantic","indian_ocean_dipole","tropical_indian_ocean",\
                "southern_ocean","nino34_runstddev","north_atlantic","north_pacific_meridional_mode","south_pacific_meridional_mode"/)
  variname_title := (/"Nin~H-13V2F35~D~FV-2H3F21~o3.4","Nin~H-13V2F35~D~FV-2H3F21~o1+2",\
                     "Nin~H-13V2F35~D~FV-2H3F21~o3","Nin~H-13V2F35~D~FV-2H3F21~o4",\
                     "Atlantic Meridional Mode","Atlantic Nin~H-13V2F35~D~FV-2H3F21~o3",\
                     "Tropical North Atlantic","Tropical South Atlantic",\
                     "Indian Ocean Dipole","Tropical Indian Ocean","Southern Ocean","Nin~H-13V2F35~D~FV-2H3F21~o3.4 30yr Running Standard Deviations",\
                     "North Atlantic","North Pacific Meridional Mode","South Pacific Meridional Mode"/)
  variname_title = variname_title+" (Monthly)"

  do dd = 0,dimsizes(variname)-1
     varinameF = variname(dd)

     wks = gsn_open_wks(wks_type,getenv("OUTDIR")+"sst.tseries")
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
        fnt = getenv("OUTDIR")+"obs.cvdp_data.sst.indices."+syear(0)+"-"+eyear(0)+".nc"
        fnt2 = getenv("OUTDIR")+"obs.cvdp_data."+syear(0)+"-"+eyear(0)+".nc"
        cntr = 0
     else
        fnt = getenv("OUTDIR")+modname(0)+".cvdp_data.sst.indices."+syear(0)+"-"+eyear(0)+".nc"
        fnt2 = getenv("OUTDIR")+modname(0)+".cvdp_data."+syear(0)+"-"+eyear(0)+".nc"
        cntr = 1
     end if
     obs0 := read_cvdp_le_data(fnt,fnt2,varinameF)
     obs0!0 = "time"
     if (isatt(obs0,"is_all_missing")) then 
        obs0New = new((eyear(0)-syear(0)+1)*12,float)
        copy_VarAtts(obs0,obs0New)
        obs0 := obs0New
        obs0!0 = "time"
        delete(obs0New)
     end if
     obs0&time = fspan(syear(0),eyear(0)+.91667,nyr(0)*12)
     xyres@gsnLeftStringFontColor = "black"
     xyres2@gsnLeftStringFontColor = "black"
     xyres_sum@gsnLeftStringFontColor = "black"
     if (isatt(xyres,"trYMinF")) then
        delete([/xyres@trYMinF,xyres@trYMaxF/])
     end if
     xyres@trXMinF = syear(0)-.5
     xyres@trXMaxF = eyear(0)+1.5
     tttt := dtrend_msg(ispan(0,dimsizes(obs0&time)-1,1),obs0,False,True)   
     xyres@gsnLeftString = names(0)
     obs_val := decimalPlaces(tttt@slope*dimsizes(obs0&time),2,True)+obs0@units+" "+nyr(0)+"yr~S~-1~N~"
     xyres@gsnRightString = obs_val
     plot_indmem(0) = gsn_csm_xy(wks,obs0&time,obs0,xyres)
     xyres2A@gsnLeftString = "Ensemble Mean Summary"
     plot_obs := gsn_csm_xy(wks,obs0&time,obs0,xyres2A)
     cntr_EM = 0
     if (numobs.ge.2) then     ; plot obs #2-
        do ff = 1,numobs-1
           fnt = getenv("OUTDIR")+modname(cntr)+".cvdp_data.sst.indices."+syear(cntr)+"-"+eyear(cntr)+".nc"
           fnt2 = getenv("OUTDIR")+modname(cntr)+".cvdp_data."+syear(cntr)+"-"+eyear(cntr)+".nc"
           arr := read_cvdp_le_data(fnt,fnt2,varinameF)
           if (isatt(arr,"is_all_missing")) then 
              cntr = cntr+1
              continue
           end if
           arr!0 = "time"
           arr&time = fspan(syear(cntr),eyear(cntr)+.91667,nyr(cntr)*12)
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

     varinameF = variname(dd)
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

           fnt = getenv("OUTDIR")+modname_mod+".cvdp_data.sst.indices."+syear_mod+"-"+eyear_mod+".nc"
           fnt2 = getenv("OUTDIR")+modname_mod+".cvdp_data."+syear_mod+"-"+eyear_mod+".nc"
           arr := read_cvdp_le_data(fnt,fnt2,varinameF)
           if (isatt(arr,"is_all_missing")) then 
              cntr = cntr+1
              continue
           end if
           time_save := arr&time ; for ensemble mean time write out below
           arr!0 = "time"
           arr&time = fspan(syear_mod,eyear_mod+.91667,(eyear_mod-syear_mod+1)*12)
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
           arr_store@nens = arr_store@nens+1
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

        ssss := dtrend_msg(ispan(0,dimsizes(arr_store&time)-1,1),arr_store,False,True)
        tttt := dtrend_msg(ispan(0,dimsizes(arr_EM&time)-1,1),arr_EM,False,True)  
        xyres3_sum@gsnXYFillColors = (/30/356.,144/256.,1.,0.25/)  ;"dodgerblue"
        xyres3b_sum@gsnXYFillColors = (/30/356.,144/256.,1.,0.5/)  ;"dodgerblue"
        if (all(ismissing(arr_range2(0,:)))) then  ; necessary as gsnXYFillColors causes NCL to fail when data all missing
           delete(xyres3_sum@gsnXYFillColors)
           delete(xyres3b_sum@gsnXYFillColors)
        end if
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
        plot_sum(cntr_EM) = gsn_csm_xy(wks,arr_EM&time,arr_EM,xyres_sumA)
        overlay(plot_summary(cntr_EM),plot_summary1(cntr_EM))
        overlay(plot_summary(cntr_EM),plot_summary_obs_overlay(cntr_EM))
        overlay(plot_summary(cntr_EM),plot_summary2(cntr_EM))

        arr_EM&time = time_save
        arr_range1&time = time_save
        arr_range2&time = time_save

        fout = getenv("OUTDIR")+str_sub_str(names_EM_mod," ","_")+"_EM.cvdp_data.sst.indices."+syear_mod+"-"+eyear_mod+".nc"
        if (isfilepresent2(fout)) then
           z = addfile(fout,"w")
        else
           z = addfile(fout,"c")
           set_global_ncfile_attributes(z,names_EM_mod,syear_mod,eyear_mod,getenv("VERSION"))
        end if
        z->$(/varinameF+"_em"/)$ = set_varAtts(arr_EM,arr_EM@long_name+" Ensemble Mean","","")
        z->$(/varinameF+"_2575range"/)$ = set_varAtts(arr_range1,arr_EM@long_name+" 25/75% range","","")
        z->$(/varinameF+"_1090range"/)$ = set_varAtts(arr_range2,arr_EM@long_name+" 10/90% range","","")
        delete([/arr_EM,z,tttt,ssss,arr_store,time_save/])
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
           gsn_text_ndc(wks,names(0)+" "+syear(0)+"-"+eyear(0)+" trend = "+obs_val,0.5,panres4@gsnPanelMainPosYF-.025,txres)
        end if
        frame(wks)
     end if
     delete(wks)

     if (wks_type.eq."png") then
        if (nEM.lt.1) then  
           system("mv "+OUTDIR+"sst.tseries.png "+OUTDIR+variname(dd)+".timeseries.indmem.png")
        else
           system("mv "+OUTDIR+"sst.tseries.000001.png "+OUTDIR+variname(dd)+".timeseries.indmem.png")
           system("mv "+OUTDIR+"sst.tseries.000002.png "+OUTDIR+variname(dd)+".timeseries.summary.png")
           if (PNG_SCALE_SUMMARY.ne.100) then
              system(IM_COMMAND+" "+OUTDIR+variname(dd)+".timeseries.summary.png -resize "+PNG_SCALE_SUMMARY+"% "+OUTDIR+variname(dd)+".timeseries.summary.png")
           end if
        end if
     else
        system("psplit "+OUTDIR+"sst.tseries.ps "+OUTDIR+"sst.tseries")
        system("mv "+OUTDIR+"sst.tseries0001.ps "+OUTDIR+variname(dd)+".timeseries.indmem.ps")
        if (nEM.ge.1) then  
           system("mv "+OUTDIR+"sst.tseries0002.ps "+OUTDIR+variname(dd)+".timeseries.summary.ps")
        end if
        system("rm "+OUTDIR+"sst.tseries.ps")
     end if
  end do
;------Hovmoller plotting section--------------------------------------------------------------------------------------------------
  hres = True
  hres@vpHeightF = 0.45
  hres@vpWidthF = 0.35
  hres@gsnFrame = False
  hres@gsnDraw = False 
  
  hres@tmYLMode = "Explicit"
  hres@trYMinF = 0
  hres@trYMaxF = 28  
  hres@tmYLValues = ispan(0,28,4)
  hres@tmYLLabels = (/"Jan~S~0~N~","May~S~0~N~","Sep~S~0~N~","Jan~S~+1~N~", \
                     "May~S~+1~N~","Sep~S~+1~N~","Jan~S~+2~N~","May~S~+2~N~"/)    
  hres@tmYLMinorValues = ispan(24,52,2)               
  hres@tmYLLabelJust = "CenterCenter"               
  hres@tmYLLabelDeltaF = 1.3    ;0.05
  hres@cnFillOn = True
     
  hres@lbLabelBarOn = False
  
  hres@tiMainOn = True
  hres@cnInfoLabelOn = False
  hres@cnLinesOn = True
  hres@cnLevelSelectionMode = "ExplicitLevels"
  hres@cnLevels = (/-3,-2.5,-2,-1.5,-1,-.75,-.5,-.25,0,.25,.5,.75,1,1.5,2,2.5,3/)   ;fspan(-2.,2.,17)
  carr = new(dimsizes(hres@cnLevels),"string")
  carr = "transparent"
  carr(8) = "gray50"
  hres@cnMonoLineColor = False
  hres@cnLineColors = carr
  hres@cnLineLabelsOn = False
  hres@tmYLLabelFontHeightF = 0.014
  hres@tmXBLabelFontHeightF = 0.014
  hres@gsnMajorLonSpacing = 30.
  hres@gsnMinorLonSpacing = 10.
  hres@tiYAxisOn = False  
  if (wks_type.eq."png") then
     hres@cnLineThicknessF = 2.  
  else
     hres@cnLineThicknessF = 1.  
  end if

  hres@tiMainFontHeightF = 0.017
  hres@gsnLeftStringOrthogonalPosF = 0.025
  hres@gsnRightStringOrthogonalPosF = hres@gsnLeftStringOrthogonalPosF
  hres@gsnCenterStringOrthogonalPosF = -1.0
  hres@gsnCenterStringParallelPosF = 0.89
  hres@gsnCenterStringFontHeightF = 0.017
  hres@gsnLeftStringFontHeightF = 0.017
  hres@gsnRightStringFontHeightF = 0.017

  hres@gsnLeftString = ""
  hres@gsnCenterString= ""
  hres@gsnRightString = ""

  hres@lbLabelBarOn    = False
  hres@pmLabelBarWidthF = 0.4
  hres@pmLabelBarHeightF = 0.075
  hres@lbBoxLineColor = "gray70"
  hres@lbLabelFontHeightF = 0.02
  hres@lbLabelStride = 1
  hres@lbTitleOn = True
  hres@lbTitleFontHeightF = hres@lbLabelFontHeightF
  hres@lbTitlePosition = "Bottom"
  hres@cnNoDataLabelOn = False

  tres := hres    ; p-value plots
  copy_VarAtts(retrieve_summary_res(),tres)
  tres@tiMainString = tres@gsnCenterString
  tres@gsnCenterString = ""

  if (COLORMAP.eq.0) then
     hres@cnFillPalette = "ncl_default"
  end if
  if (COLORMAP.eq.1) then
     hres@cnFillPalette = "BlueDarkRed18"
  end if 
  hres2 = hres    ; Hovmoller differences
  hres2@cnLevels = hres@cnLevels

  panres = True
  panres@gsnMaximize = True  
  panres@gsnPaperOrientation = "portrait"
  panres@gsnPanelLabelBar = True
  panres@gsnPanelYWhiteSpacePercent = 3.0
  panres@pmLabelBarHeightF = 0.05
  panres@pmLabelBarWidthF = 0.5
  panres@lbBoxLineColor = "gray70"
  panres@txFontHeightF = 0.016
  panres@gsnPanelBottom = 0.05
  panres@lbLabelFontHeightF = 0.013
  panres@lbTitleOn = True
  panres@lbTitleFontHeightF = panres@lbLabelFontHeightF
  panres@lbTitlePosition = "Bottom"
  panres@lbLabelStride = 1

  panres2 = True
  panres2@gsnPaperOrientation = "portrait"
  panres2@gsnPanelLabelBar = False
  panres2@gsnPanelYWhiteSpacePercent = 3.0
  panres2@txFontHeightF = 0.016
  panres2@gsnPanelBottom = 0.05
  panres2@lbTitleOn = False

  variname := (/"nino34_hov_elnino","nino34_hov_lanina",\
                "nino34_hov_elnino_zos","nino34_hov_lanina_zos"/)
  fp2 := (/"sst.indices","sst.indices","sst.indices.zos","sst.indices.zos"/)
  etxt = (/"EN","LN"/)  ; for right substring title

  do dd = 0,dimsizes(variname)-1
     varinameF = str_sub_str(variname(dd),"nino34","nino34")

     if (dd.le.1) then
        mname := modname
        syea := syear
        eyea := eyear
        nam := names
     else
        mname := modname_zos
        syea := syear_zos
        eyea := eyear_zos
        nam := names_zos
     end if

     wks = gsn_open_wks(wks_type,getenv("OUTDIR")+"nino34.hov")
     plot_indmem      := new(nsim,"graphic")
     plot_indmem_diff := new(nsim,"graphic")
     if (nEM.ge.1) then
        plot_summary     := new((nEM*4),"graphic")
     end if
     numobs = num(EM_num.eq.0) 
     if (numobs.eq.0) then
        fnt = getenv("OUTDIR")+"obs.cvdp_data."+fp2(dd)+"."+syea(0)+"-"+eyea(0)+".nc"      
        fnt2 = getenv("OUTDIR")+"obs.cvdp_data."+syea(0)+"-"+eyea(0)+".nc"
        cntr = 0
     else
        fnt = getenv("OUTDIR")+mname(0)+".cvdp_data."+fp2(dd)+"."+syea(0)+"-"+eyea(0)+".nc"      
        fnt2 = getenv("OUTDIR")+mname(0)+".cvdp_data."+syea(0)+"-"+eyea(0)+".nc"
        cntr = 1
     end if
     obs0 := read_cvdp_le_data(fnt,fnt2,varinameF)
     obs0!0 = "time_mon1"
     obs0!1 = "longitude"

     if (dd.ge.2) then
        hres@cnLevels := ispan(-16,16,2)
        hres2@cnLevels := ispan(-8,8,1)
     end if

     hres@tiMainFontColor = "black"
     hres2@tiMainFontColor = "black"
     hres@lbLabelBarOn = False
     hres2@lbLabelBarOn = False
     tres@lbLabelBarOn = False
     hres@gsnLeftString = syea(0)+"-"+eyea(0) 
     hres@gsnCenterString = ""
     if (isatt(obs0,"number_of_events")) then
        hres@gsnRightString = obs0@number_of_events+" Tot"
     else
        hres@gsnRightString = ""
     end if
     hres@tiMainString = nam(0)     
     plot_indmem(0) = gsn_csm_hov(wks,obs0,hres)
     cntr_EM = 0
     if (numobs.ge.2) then     ; plot obs #2-
        do ff = 1,numobs-1
           fnt = getenv("OUTDIR")+mname(cntr)+".cvdp_data."+fp2(dd)+"."+syea(cntr)+"-"+eyea(cntr)+".nc"
           fnt2 = getenv("OUTDIR")+mname(cntr)+".cvdp_data."+syea(cntr)+"-"+eyea(cntr)+".nc"
           arr := read_cvdp_le_data(fnt,fnt2,varinameF)
           arr!0 = "time_mon1"
           arr!1 = "longitude"
           obs0_rg = linint2_Wrap(obs0&longitude,obs0&time_mon1,obs0,True,arr&longitude,arr&time_mon1,0)
           obs_diff = arr
           obs_diff = (/ arr - obs0_rg /)

           hres@gsnLeftString = syea(cntr)+"-"+eyea(cntr) 
           pc := pattern_cor(obs0_rg,arr,1.0,0)
           if (ismissing(pc)) then
              hres@gsnCenterString = ""
           else
              hres@gsnCenterString = "r="+sprintf("%4.2f",pc)
           end if
           if (isatt(arr,"number_of_events")) then
              hres@gsnRightString = arr@number_of_events+" Tot"
           else
              hres@gsnRightString = ""
           end if
           hres@tiMainString = nam(cntr)
           plot_indmem(cntr) = gsn_csm_hov(wks,arr,hres)
           hres2@gsnLeftString = ""  
           hres2@tiMainString = nam(cntr)+" - "+nam(0)
           hres2@gsnRightString = arr@units
           plot_indmem_diff(cntr) = gsn_csm_hov(wks,obs_diff,hres2)   
           delete([/arr,obs_diff,obs0_rg/])
           cntr = cntr+1
        end do
     end if

     varinameF = variname(dd)
     do gg = nEMm,nEM   ; operate on each ensemble mean (or individual member)
        if (gg.eq.0) then
           continue
        end if
        lbFlag = summary_lb_flag(paths,EM_num,gg,nEM)  ; lbFlag set to True if summary labelbars should be drawn  
        nens = num(EM_num.eq.gg) ; determines how many model simulations in each ensemble
        cntr_ens := ind(EM_num.eq.gg)   ; cntr_ens(hh) are the indices where each ensemble member of an ensemble hreside 
        do hh = 0,nens-1
           modname_mod = mname(cntr_ens(hh))
           syear_mod = syea(cntr_ens(hh))
           eyear_mod = eyea(cntr_ens(hh))
           names_mod = nam(cntr_ens(hh))
           names_EM_mod = names_EM(cntr_ens(hh))
   
           fnt = getenv("OUTDIR")+modname_mod+".cvdp_data."+fp2(dd)+"."+syear_mod+"-"+eyear_mod+".nc"
           fnt2 = getenv("OUTDIR")+modname_mod+".cvdp_data."+syear_mod+"-"+eyear_mod+".nc"
           arr := read_cvdp_le_data(fnt,fnt2,varinameF)
           if (isatt(arr,"is_all_missing")) then
              cntr = cntr+1
              continue
           end if
           arr!0 = "time_mon1"
           arr!1 = "longitude"

           if (.not.isvar("arr_store")) then  ; create an array to house all members, to be used to calculate EM
              arr_store = new((/nens,dimsizes(arr&time_mon1),dimsizes(arr&longitude)/),typeof(arr))
              arr_store!0 = "ensmem"
              arr_store!1 = "time_mon1"
              arr_store&time_mon1 = arr&time_mon1
              arr_store!2 = "longitude"
              arr_store&longitude = arr&longitude
              arr_store@nens = 0
              copy_VarAtts(arr,arr_store)
              arr_store_events = new(nens,float)

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
              hres@tiMainFontColor = csubtitle_color(gg-1)
              hres2@tiMainFontColor = csubtitle_color(gg-1)
           end if
           arr_store(hh,:,:) = (/ arr /)
           arr_store@nens = arr_store@nens+1
           arr_store_events(hh) = arr@number_of_events

           if (.not.isvar("obs0_rg")) then  
              if (isatt(obs0,"is_all_missing")) then
                 obs0_rg = arr
                 obs0_rg = obs0_rg@_FillValue
              else
                 obs0_rg = linint2_Wrap(obs0&longitude,obs0&time_mon1,obs0,True,arr&longitude,arr&time_mon1,0)
              end if
           end if
           obs_diff = arr
           obs_diff = (/ arr - obs0_rg /)

           pc := pattern_cor(obs0_rg,arr,1.0,0)
           if (ismissing(pc)) then
              hres@gsnCenterString = ""
           else
              hres@gsnCenterString = "r="+sprintf("%4.2f",pc)
           end if
           hres@gsnLeftString   = syear_mod+"-"+eyear_mod
           hres@gsnRightString = arr@number_of_events+" Tot"
           hres@tiMainString = names_mod
           plot_indmem(cntr) = gsn_csm_hov(wks,arr,hres)

           panres@lbTitleString = arr@units

           hres2@gsnLeftString = ""
           hres2@gsnRightString = "" 
           hres2@tiMainString = names_mod+" - "+names(0)

           plot_indmem_diff(cntr) = gsn_csm_hov(wks,obs_diff,hres2)
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
           hres@lbLabelBarOn = True
           hres2@lbLabelBarOn = True
           tres@lbLabelBarOn = True
        end if
        arr_EM = dim_avg_n_Wrap(arr_store,0)
   
        hres@tiMainFontColor = "black"
        hres2@tiMainFontColor = "black"

        hres@tiMainOn = True
        hres@lbTitleString = arr_EM@units
   
        hres@gsnLeftString = syea(0)+"-"+eyea(0) 
        hres@gsnCenterString = ""
        hres@gsnRightString = obs0@number_of_events+" Tot"
        hres@tiMainString = nam(0)
        plot_summary(cntr_EM+1) = gsn_csm_hov(wks,obs0,hres)
   
        hres@tiMainFontColor = csubtitle_color(gg-1)
        if (showyr) then
           hres@gsnLeftString = syear_em0+"-"+eyear_em0 
        else
           hres@gsnLeftString = (eyear_em0-syear_em0+1)+"yrs" 
        end if
        delete([/syear_em0,eyear_em0,showyr/])

        obs_diff = arr_EM
        obs_diff = (/ arr_EM - obs0_rg /)
        pc := pattern_cor(obs0_rg,arr_EM,1.0,0)
        if (ismissing(pc)) then
           hres@gsnCenterString = ""
        else
           hres@gsnCenterString = "r="+sprintf("%4.2f",pc)
        end if
        hres@gsnRightString = decimalPlaces(avg(arr_store_events),0,True)+" Avg/"+sum(arr_store_events)+" Tot"   ;+etxt(dd)  
        hres@tiMainString = names_EM_mod +" ("+arr_store@nens+" Members)"                         
        plot_summary(cntr_EM) = gsn_csm_hov(wks,arr_EM,hres)
        hres@gsnCenterString = ""

        hres2@lbTitleString = arr_EM@units
        hres2@gsnLeftString = ""
        hres2@tiMainString = names_EM_mod+" - "+nam(0)
        hres2@gsnRightString = "" 
        plot_summary(cntr_EM+2) = gsn_csm_hov(wks,obs_diff,hres2)
   
        p_val := calculate_pval(obs0_rg,arr_store)
        tres@lbTitleString = "%"
        p_val1D := ndtooned(p_val)
        p_val1D = where(p_val1D.ge.10.and.p_val1D.le.90,1,0)       
        tres@tiMainString = "Rank of "+names(0)+" within Ensemble" 
        tres@gsnRightString = sprintf("%4.0f",(sum(p_val1D)/dimsizes(p_val1D)*100.))+"%"
        plot_summary(cntr_EM+3) = gsn_csm_hov(wks,p_val,tres)
   
        fno = getenv("OUTDIR")+str_sub_str(names_EM_mod," ","_")+"_EM.cvdp_data.sst.indices."+syear_mod+"-"+eyear_mod+".nc"
        if (isfilepresent2(fno)) then
           z = addfile(fno,"w")
        else
           z = addfile(fno,"c")
           set_global_ncfile_attributes(z,names_EM_mod,syear_mod,eyear_mod,getenv("VERSION"))
        end if
        z->$(/varinameF+"_em"/)$ = set_varAtts(arr_EM,arr_EM@long_name+" Ensemble Mean","","")
        z->$(/varinameF+"_em_diffobs"/)$ = set_varAtts(obs_diff,obs_diff@long_name+" Ensemble Mean difference from "+names(0),"","")           
        z->$(/varinameF+"_pval"/)$ = set_varAtts(p_val,arr_EM@long_name+" p-val statistic","%","")   
        delete([/arr_store,obs0_rg,obs_diff,arr_EM,z,p_val,arr_store_events/])
        cntr_EM = cntr_EM+4
     end do

     if (varinameF.eq."nino34_hov_elnino") then
        panres@txString = "El Nin~H-13V2F35~D~FV-2H3F21~o Composite (3~S~o~N~S:3~S~o~N~N)"
        gsn_panel2(wks,plot_indmem,(/nrow,ncol/),panres)
        panres@txString = "El Nin~H-13V2F35~D~FV-2H3F21~o Composite Differences (3~S~o~N~S:3~S~o~N~N)"
        gsn_panel2(wks,plot_indmem_diff,(/nrow,ncol/),panres)
        if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
           panres2@txString = "Ensemble Summary: "+"El Nin~H-13V2F35~D~FV-2H3F21~o Composite (3~S~o~N~S:3~S~o~N~N)"
           panres2@gsnPanelXWhiteSpacePercent = 3.0
           gsn_panel2(wks,plot_summary,(/nEM,4/),panres2)
        end if
     end if
     if (varinameF.eq."nino34_hov_lanina") then
        panres@txString = "La Nin~H-13V2F35~D~FV-2H3F21~a Composite (3~S~o~N~S:3~S~o~N~N)"
        gsn_panel2(wks,plot_indmem,(/nrow,ncol/),panres)
        panres@txString = "La Nin~H-13V2F35~D~FV-2H3F21~a Composite Differences (3~S~o~N~S:3~S~o~N~N)"
        gsn_panel2(wks,plot_indmem_diff,(/nrow,ncol/),panres)
        if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
           panres2@txString = "Ensemble Summary: "+"La Nin~H-13V2F35~D~FV-2H3F21~a Composite (3~S~o~N~S:3~S~o~N~N)"
           panres2@gsnPanelXWhiteSpacePercent = 3.0
           gsn_panel2(wks,plot_summary,(/nEM,4/),panres2)
        end if
     end if
     if (varinameF.eq."nino34_hov_elnino_zos") then
        panres@txString = "El Nin~H-13V2F35~D~FV-2H3F21~o ZOS Composite (3~S~o~N~S:3~S~o~N~N)"
        gsn_panel2(wks,plot_indmem,(/nrow,ncol/),panres)
        panres@txString = "El Nin~H-13V2F35~D~FV-2H3F21~o ZOS Composite Differences (3~S~o~N~S:3~S~o~N~N)"
        gsn_panel2(wks,plot_indmem_diff,(/nrow,ncol/),panres)
        if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
           panres2@txString = "Ensemble Summary: "+"El Nin~H-13V2F35~D~FV-2H3F21~o ZOS Composite (3~S~o~N~S:3~S~o~N~N)"
           panres2@gsnPanelXWhiteSpacePercent = 3.0
           gsn_panel2(wks,plot_summary,(/nEM,4/),panres2)
        end if
     end if
     if (varinameF.eq."nino34_hov_lanina_zos") then
        panres@txString = "La Nin~H-13V2F35~D~FV-2H3F21~a ZOS Composite (3~S~o~N~S:3~S~o~N~N)"
        gsn_panel2(wks,plot_indmem,(/nrow,ncol/),panres)
        panres@txString = "La Nin~H-13V2F35~D~FV-2H3F21~a ZOS Composite Differences (3~S~o~N~S:3~S~o~N~N)"
        gsn_panel2(wks,plot_indmem_diff,(/nrow,ncol/),panres)
        if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
           panres2@txString = "Ensemble Summary: "+"La Nin~H-13V2F35~D~FV-2H3F21~a ZOS Composite (3~S~o~N~S:3~S~o~N~N)"
           panres2@gsnPanelXWhiteSpacePercent = 3.0
           gsn_panel2(wks,plot_summary,(/nEM,4/),panres2)
        end if
     end if
     if (isatt(panres2,"gsnPanelXWhiteSpacePercent")) then
        delete(panres2@gsnPanelXWhiteSpacePercent)
     end if
     delete(wks)

     if (wks_type.eq."png") then
        system("mv "+OUTDIR+"nino34.hov.000001.png "+OUTDIR+str_sub_str(variname(dd),"_",".")+".indmem.png")
        system("mv "+OUTDIR+"nino34.hov.000002.png "+OUTDIR+str_sub_str(variname(dd),"_",".")+".indmemdiff.png")
        if (nEM.ge.1) then   
           system("mv "+OUTDIR+"nino34.hov.000003.png "+OUTDIR+str_sub_str(variname(dd),"_",".")+".summary.png")
           if (PNG_SCALE_SUMMARY.ne.100) then
              system(IM_COMMAND+" "+OUTDIR+str_sub_str(variname(dd),"_",".")+".summary.png -resize "+PNG_SCALE_SUMMARY+"% "+OUTDIR+str_sub_str(variname(dd),"_",".")+".summary.png")
           end if
        end if
     else
        system("psplit "+OUTDIR+"nino34.hov.ps "+OUTDIR+"nino34.hovm")
        system("mv "+OUTDIR+"nino34.hovm0001.ps "+OUTDIR+str_sub_str(variname(dd),"_",".")+".indmem.ps")
        system("mv "+OUTDIR+"nino34.hovm0002.ps "+OUTDIR+str_sub_str(variname(dd),"_",".")+".indmemdiff.ps")
        if (nEM.ge.1) then  
           system("mv "+OUTDIR+"nino34.hovm0003.ps "+OUTDIR+str_sub_str(variname(dd),"_",".")+".summary.ps")
        end if
        system("rm "+OUTDIR+"nino34.hov.ps")
     end if
  end do
  delete([/panres,panres2/])
;------Wavelet plotting section--------------------------------------------------------------------------------------------------
  wres = True
  wres@gsnDraw = False
  wres@gsnFrame = False
  wres@vpWidthF = 0.7
  wres@vpHeightF = 0.3
  wres@cnFillOn = True
  wres@cnLinesOn = False
  wres@cnLineLabelsOn = False
  wres@cnInfoLabelOn = False
  wres@trYReverse = True
  wres@trYMinF = 1.0
  wres@tmYLOn = True
  wres@tmYLMode = "Explicit"
  wres@cnLevelSelectionMode = "ExplicitLevels"
  wres@cnLevels = ispan(0,70,5)
  wres@tmXTLabelFontHeightF = 0.018
  wres@tmXBLabelFontHeightF = 0.018
  wres@tmYLLabelFontHeightF = 0.018
  wres@tiYAxisString = "Period (years)"
  wres@tiXAxisOn = False
  wres@lbLabelBarOn = False
  wres@gsnLeftString = ""
  wres@gsnCenterString = ""
  wres@gsnRightString = ""
  wres@gsnCenterStringOrthogonalPosF = 0.050
  wres@gsnLeftStringFontHeightF = 0.02
  wres@gsnCenterStringFontHeightF = 0.02
  wres@gsnRightStringFontHeightF = 0.02

  wres@pmLabelBarWidthF = 0.55
  wres@pmLabelBarHeightF = 0.075
  wres@lbBoxLineColor = "gray70"
  wres@lbLabelFontHeightF = 0.02
  wres@lbLabelStride = 1
  wres@lbTitleOn = True
  wres@lbTitleFontHeightF = wres@lbLabelFontHeightF
  wres@lbTitlePosition = "Bottom"

  tres := wres    ; p-value plots
  copy_VarAtts(retrieve_summary_res(),tres)

  if (COLORMAP.eq.0) then
     wres@cnFillPalette = "precip3_16lev"
  else
     wres@cnFillPalette = "cb_rainbow"
  end if

  wres2 = wres   ; Wavelet differences
  if (COLORMAP.eq.0) then
     wres2@cnFillPalette = "ncl_default"
  end if
  if (COLORMAP.eq.1) then
     wres2@cnFillPalette = "BlueDarkRed18"
  end if 
  wres2@cnLevels := ispan(-20,20,5)

  wsres = True                            ; res2 probability plots
  wsres@trYReverse          = True
  wsres@tmYLMode = "Explicit"
  wsres@gsnDraw             = False       ; Do not draw plot
  wsres@gsnFrame            = False       ; Do not advance frome
  wsres@cnLevelSelectionMode = "ManualLevels" ; set manual contour levels
  wsres@cnMinLevelValF      = 0.00        ; set min contour level
  wsres@cnMaxLevelValF      = 2.00        ; set max contour level
  wsres@cnLevelSpacingF     = 1.00        ; set contour spacing
  wsres@cnInfoLabelOn       = False
  wsres@cnLinesOn           = False       ; do not draw contour lines
  wsres@cnLineLabelsOn      = False       ; do not draw contour labels
  wsres@cnFillScaleF   = 0.5         ; add extra density
  wsres@cnFillDotSizeF = .0015
  wsres@gsnLeftString = ""
  wsres@gsnCenterString = ""
  wsres@gsnRightString = ""    

  wavecoi = True
  wavecoi@gsEdgeColor = "gray40"
  wavecoi@gsFillColor = wavecoi@gsEdgeColor
  if (wks_type.eq."png") then
     wavecoi@gsFillLineThicknessF = 2.0
     wavecoi@gsEdgeThicknessF = 2.0
  else
     wavecoi@gsFillLineThicknessF = 1.25
     wavecoi@gsEdgeThicknessF = 1.25
  end if
  wavecoi@gsFillIndex = 3
  wavecoi@gsFillScaleF = .65

  opt   = True
  opt@gsnShadeFillType = "pattern"
  opt@gsnShadeHigh     = 17

  panres = True
  panres@gsnMaximize = True  
  panres@gsnPaperOrientation = "portrait"
  panres@txFontHeightF = 0.016
  panres@gsnPanelBottom = 0.05
  panres@gsnPanelYWhiteSpacePercent = 3.0
  panres@gsnPanelXWhiteSpacePercent = 4.0
  panres@gsnPanelLabelBar = True
  panres@pmLabelBarHeightF = 0.05
  panres@pmLabelBarWidthF = 0.5
  panres@lbBoxLineColor = "gray70"
  panres@lbLabelFontHeightF = 0.013
  panres@lbTitleOn = True
  panres@lbTitleFontHeightF = panres@lbLabelFontHeightF
  panres@lbTitlePosition = "Bottom"
  panres@pmLabelBarOrthogonalPosF = -0.01

  panres2 = True
  panres2@gsnPaperOrientation = "portrait"
  panres2@gsnPanelLabelBar = False
  panres2@gsnPanelYWhiteSpacePercent = 3.0
  panres2@txFontHeightF = 0.016
  panres2@gsnPanelBottom = 0.05
  panres2@lbTitleOn = False

  wks = gsn_open_wks(wks_type,getenv("OUTDIR")+"nino34.wavelet")
  plot_indmem    := new(nsim,"graphic")
  plot_indmem_ov := new(nsim,"graphic")
  plot_indmem_diff := new(nsim,"graphic")
  if (nEM.ge.1) then
     plot_summary     := new((nEM*4),"graphic")
  end if
  numobs = num(EM_num.eq.0) 
  if (numobs.eq.0) then
     fnt = getenv("OUTDIR")+"obs.cvdp_data.sst.indices."+syear(0)+"-"+eyear(0)+".nc"
     fnt2 = getenv("OUTDIR")+"obs.cvdp_data."+syear(0)+"-"+eyear(0)+".nc"
     cntr = 0
  else
     fnt = getenv("OUTDIR")+modname(0)+".cvdp_data.sst.indices."+syear(0)+"-"+eyear(0)+".nc"
     fnt2 = getenv("OUTDIR")+modname(0)+".cvdp_data."+syear(0)+"-"+eyear(0)+".nc"
     cntr = 1
  end if
  obs0 := read_cvdp_le_data(fnt,fnt2,"nino34_wavelet_power")
  obs0_sig := read_cvdp_le_data(fnt,fnt2,"nino34_wavelet_significance")
  obs0@coi := read_cvdp_le_data(fnt,fnt2,"nino34_wavelet_coi")

  if (isatt(obs0,"is_all_missing")) then
     delete([/obs0,obs0_sig/])
     obs0 = new((/(eyear(0)-syear(0)+1)*12,11/),float)
     obs0!0 = "time"
     obs0!1 = "period"
     obs0&period = ispan(1,111,11)
     obs0@is_all_missing = True
     obs0_sig = obs0
  else
     delete([/obs0&time,obs0_sig&time/])
  end if
  obs0&time = fspan(syear(0),eyear(0)+.91667,nyr(0)*12)
  obs0_sig&time = obs0&time

  if (nyr(0).lt.200) then
     wres@tmYLValues := (/1,2,3,5,10,20,50,100,150/)
  else
     wres@tmYLValues := (/1,5,10,50,100,200,500,1000,2000,5000,10000/)
  end if
  wres@tmYLLabels := wres@tmYLValues
  wres@trYMaxF = (nyr(0)/2) - (nyr(0)*0.05)
  wres@gsnLeftString = syear(0)+"-"+eyear(0) 
  wres@gsnCenterString = names(0)
  wres@gsnRightString = ""
  plot_indmem(0) = gsn_csm_contour(wks,obs0,wres)
  plot_indmem(0) = ShadeCOI(wks,plot_indmem(0),obs0,obs0&time,wavecoi)
  plot_indmem_ov(0) = gsn_csm_contour(wks,obs0_sig,wsres)
  plot_indmem_ov(0) = gsn_contour_shade(plot_indmem_ov(0),0, 0.8, opt)
  overlay(plot_indmem(0),plot_indmem_ov(0))
  delete([/obs0_sig/])

  cntr_EM = 0
  if (numobs.ge.2) then     ; plot obs #2-
     do ff = 1,numobs-1
        fnt = getenv("OUTDIR")+modname(cntr)+".cvdp_data.sst.indices."+syear(cntr)+"-"+eyear(cntr)+".nc"
        fnt2 = getenv("OUTDIR")+modname(cntr)+".cvdp_data."+syear(cntr)+"-"+eyear(cntr)+".nc"
        arr     := read_cvdp_le_data(fnt,fnt2,"nino34_wavelet_power")
        arr_sig := read_cvdp_le_data(fnt,fnt2,"nino34_wavelet_significance")
        arr@coi := read_cvdp_le_data(fnt,fnt2,"nino34_wavelet_coi")
        delete([/arr&time,arr_sig&time/])
        arr&time = fspan(syear(cntr),eyear(cntr)+.91667,nyr(cntr)*12)
        arr_sig&time = arr&time
        if (isatt(arr,"is_all_missing")) then 
           cntr = cntr+1
           continue
        end if
        obs_rg = linint2_Wrap(obs0&time,obs0&period,obs0,True,arr&time,arr&period,0)
        obs_diff = arr
        obs_diff = (/ arr - obs_rg /)

        if (nyr(cntr).lt.200) then
           wres@tmYLValues := (/1,2,3,5,10,20,50,100,150/)
        else
           wres@tmYLValues := (/1,5,10,50,100,200,500,1000,2000,5000,10000/)
        end if
        wres@tmYLLabels := wres@tmYLValues
        wres@trYMaxF = (nyr(cntr)/2) - (nyr(cntr)*0.05)
        wres2@tmYLValues = wres@tmYLValues
        wres2@tmYLLabels = wres2@tmYLValues
        wres2@trYMaxF = wres@trYMaxF
        wres@gsnLeftString = syear(cntr)+"-"+eyear(cntr) 
        wres@gsnCenterString = names(cntr)
        pc := pattern_cor(obs_rg,arr,1.0,0)
        if (ismissing(pc)) then
           wres@gsnRightString = ""
        else
           wres@gsnRightString = "r="+sprintf("%4.2f",pc)
        end if
        plot_indmem(cntr) = gsn_csm_contour(wks,arr,wres)
        plot_indmem(cntr) = ShadeCOI(wks,plot_indmem(cntr),arr,arr&time,wavecoi)
        plot_indmem_ov(cntr) = gsn_csm_contour(wks,arr_sig,wsres)
        plot_indmem_ov(cntr) = gsn_contour_shade(plot_indmem_ov(cntr),0, 0.8, opt)
        overlay(plot_indmem(cntr),plot_indmem_ov(cntr))

        wres2@trYMaxF = (nyr(cntr)/2) - (nyr(cntr)*0.05)
        wres2@gsnLeftString = ""  
        wres2@gsnRightString = "" 
        wres2@gsnCenterString = names(cntr)+" - "+names(0)
        plot_indmem_diff(cntr) = gsn_csm_contour(wks,obs_diff,wres2)
        delete([/arr,obs_diff,obs_rg/])
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
        nyr_mod = nyr(cntr_ens(hh))

        fnt = getenv("OUTDIR")+modname_mod+".cvdp_data.sst.indices."+syear_mod+"-"+eyear_mod+".nc"
        fnt2 = getenv("OUTDIR")+modname_mod+".cvdp_data."+syear_mod+"-"+eyear_mod+".nc"
        arr     := read_cvdp_le_data(fnt,fnt2,"nino34_wavelet_power")
        arr_sig := read_cvdp_le_data(fnt,fnt2,"nino34_wavelet_significance")
        arr@coi := read_cvdp_le_data(fnt,fnt2,"nino34_wavelet_coi")
        if (isatt(arr,"is_all_missing")) then
           cntr = cntr+1
           continue
        end if
        delete(arr&time)
        arr&time = fspan(syear_mod,eyear_mod+.91667,(eyear_mod-syear_mod+1)*12)
        if (.not.isatt(arr_sig,"is_all_missing")) then
           delete([/arr_sig&time/])
           arr_sig&time = arr&time
        end if
        if (.not.isvar("arr_store")) then  ; create an array to house all members, to be used to calculate EM
           arr_store = new((/nens,dimsizes(arr&period),dimsizes(arr&time)/),typeof(arr))
           arr_store!0 = "ensmem"
           arr_store!1 = "period"
           arr_store&period = arr&period
           arr_store!2 = "time"
           arr_store&time = arr&time
           arr_store@nens = 0
           copy_VarAtts(arr,arr_store)
           arr_store_events = new(nens,float)

           syear_em0 = syear_mod
           eyear_em0 = eyear_mod
           showyr = True
        end if
        arr_store(hh,:,:) = (/ arr /)
        arr_store@nens = arr_store@nens+1

        if (.not.isvar("obs0_rg")) then  
           if (isatt(obs0,"is_all_missing")) then
              obs0_rg = arr
              obs0_rg = obs0_rg@_FillValue
           else
              obs0_rg = linint2_Wrap(obs0&time,obs0&period,obs0,True,arr&time,arr&period,0)
           end if
        end if
        obs_diff = arr
        obs_diff = (/ arr - obs0_rg /)

        if (nyr_mod.lt.200) then
           wres@tmYLValues := (/1,2,3,5,10,20,50,100,150/)
        else
           wres@tmYLValues := (/1,5,10,50,100,200,500,1000,2000,5000,10000/)
        end if
        wres@tmYLLabels  := wres@tmYLValues
        wres2@tmYLValues := wres@tmYLValues
        wres2@tmYLLabels := wres2@tmYLValues
        wres@trYMaxF = (nyr_mod/2) - (nyr_mod*0.05)
        if (gg.ge.1) then
           wres@gsnCenterStringFontColor = csubtitle_color(gg-1)
           wsres@gsnCenterStringFontColor = csubtitle_color(gg-1)
        end if
        wsres@tmYLValues := wres@tmYLValues 
        wsres@tmYLLabels := wres@tmYLLabels
        wres@gsnLeftString = syear(cntr)+"-"+eyear(cntr)  
        wres@gsnCenterString = names_mod
        pc := pattern_cor(obs0_rg,arr,1.0,0)
        if (ismissing(pc)) then
           wres@gsnRightString = ""
        else
           wres@gsnRightString = "r="+sprintf("%4.2f",pc)
        end if
        plot_indmem(cntr) = gsn_csm_contour(wks,arr,wres)
        if (.not.isatt(arr_sig,"is_all_missing")) then
           plot_indmem(cntr) = ShadeCOI(wks,plot_indmem(cntr),arr,arr&time,wavecoi)
           plot_indmem_ov(cntr) = gsn_csm_contour(wks,arr_sig,wsres)
           plot_indmem_ov(cntr) = gsn_contour_shade(plot_indmem_ov(cntr),0, 0.8, opt)
           overlay(plot_indmem(cntr),plot_indmem_ov(cntr))
        end if

        wres2@trYMaxF = (nyr_mod/2) - (nyr_mod*0.05)
        wres2@gsnLeftString = ""  
        wres2@gsnRightString = "" 
        wres2@gsnCenterString = names_mod+" - "+names(0)
        plot_indmem_diff(cntr) = gsn_csm_contour(wks,obs_diff,wres2)
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
        wres@lbLabelBarOn = True
        wres2@lbLabelBarOn = True
        tres@lbLabelBarOn = True
     end if

     arr_EM := dim_avg_n_Wrap(arr_store,0)
     panres@lbTitleString = arr_EM@units
   
     wres@lbTitleString = arr_EM@units
     wres2@lbTitleString = arr_EM@units

     wres@gsnCenterStringFontColor = "black"
     wres@gsnLeftString = syear(0)+"-"+eyear(0) 
     wres@gsnCenterString = names(0)
     plot_summary(cntr_EM+1) = gsn_csm_contour(wks,obs0,wres)
   
     wres@gsnCenterStringFontColor = csubtitle_color(gg-1)
     if (showyr) then
        wres@gsnLeftString = syear_em0+"-"+eyear_em0 
     else
        wres@gsnLeftString = (eyear_em0-syear_em0+1)+"yrs" 
     end if
     delete([/syear_em0,eyear_em0,showyr/])
     wres@gsnCenterString = names_EM_mod +" ("+arr_store@nens+" Members)" 
     pc := pattern_cor(obs0_rg,arr_EM,1.0,0)
     if (ismissing(pc)) then
        wres@gsnRightString = ""
     else
        wres@gsnRightString = "r="+sprintf("%4.2f",pc)
     end if                        
     plot_summary(cntr_EM) = gsn_csm_contour(wks,arr_EM,wres)
     obs_diff := arr_EM
     obs_diff = (/ arr_EM - obs0_rg /)
     wres2@trYMaxF = (nyr_mod/2) - (nyr_mod*0.05)
     wres2@gsnCenterString = names_EM_mod+" - "+names(0)
     wres2@gsnRightString = "" 
     plot_summary(cntr_EM+2) = gsn_csm_contour(wks,obs_diff,wres2)
   
     p_val := calculate_pval(obs0_rg,arr_store)
     if (nyr_mod.lt.200) then
        tres@tmYLValues := (/1,2,3,5,10,20,50,100,150/)
     else
        tres@tmYLValues := (/1,5,10,50,100,200,500,1000,2000,5000,10000/)
     end if
     tres@tmYLLabels  := tres@tmYLValues
     tres@trYMaxF = (nyr_mod/2) - (nyr_mod*0.05)
     p_val1D := ndtooned(p_val)
     p_val1D = where(p_val1D.ge.10.and.p_val1D.le.90,1,0)      
     tres@gsnCenterString = "Rank of "+names(0)+" within Ensemble"  
     tres@gsnRightString = sprintf("%4.0f",(sum(p_val1D)/dimsizes(p_val1D)*100.))+"%"
     plot_summary(cntr_EM+3) = gsn_csm_contour(wks,p_val,tres)
   
     fno = getenv("OUTDIR")+str_sub_str(names_EM_mod," ","_")+"_EM.cvdp_data.sst.indices."+syear_mod+"-"+eyear_mod+".nc"
     if (isfilepresent2(fno)) then
        z = addfile(fno,"w")
     else
        z = addfile(fno,"c")
        set_global_ncfile_attributes(z,names_EM_mod,syear_mod,eyear_mod,getenv("VERSION"))
     end if       
     z->$(/"nino34_wavelet_power_em"/)$ = set_varAtts(arr_EM,arr_EM@long_name+" Ensemble Mean","","")
     z->$(/"nino34_wavelet_power_em_diffobs"/)$ = set_varAtts(obs_diff,obs_diff@long_name+" Ensemble Mean difference from "+names(0),"","")           
     z->$(/"nino34_wavelet_power_pval"/)$ = set_varAtts(p_val,arr_EM@long_name+" p-val statistic","%","")   
     delete([/arr_store,obs0_rg,obs_diff,arr_EM,z,p_val,arr_store_events/])
     cntr_EM = cntr_EM+4
  end do
  panres@txString = "Nin~H-13V2F35~D~FV-2H3F21~o3.4 Wavelet (Monthly)" 
  gsn_panel2(wks,plot_indmem,(/nrow,ncol/),panres)
  panres@txString = "Nin~H-13V2F35~D~FV-2H3F21~o3.4 Wavelet Differences (Monthly)"
  gsn_panel2(wks,plot_indmem_diff,(/nrow,ncol/),panres)
  if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
     panres2@txString = "Ensemble Summary: "+"Nin~H-13V2F35~D~FV-2H3F21~o3.4 Wavelet (Monthly)"
     panres2@gsnPanelXWhiteSpacePercent = 3.0
     panres2@gsnPanelYWhiteSpacePercent = 8.0
     gsn_panel2(wks,plot_summary,(/nEM,4/),panres2)
  end if
  delete([/wks,panres,tres,panres2,wres,wres2,wsres,wavecoi/])

  if (wks_type.eq."png") then
     system("mv "+OUTDIR+"nino34.wavelet.000001.png "+OUTDIR+"nino34.wavelet.indmem.png")
     system("mv "+OUTDIR+"nino34.wavelet.000002.png "+OUTDIR+"nino34.wavelet.indmemdiff.png")
     if (nEM.ge.1) then  
        system("mv "+OUTDIR+"nino34.wavelet.000003.png "+OUTDIR+"nino34.wavelet.summary.png")
        if (PNG_SCALE_SUMMARY.ne.100) then
           system(IM_COMMAND+" "+OUTDIR+"nino34.wavelet.summary.png -resize "+PNG_SCALE_SUMMARY+"% "+OUTDIR+"nino34.wavelet.summary.png")
        end if
     end if
  else
     system("psplit "+OUTDIR+"nino34.wavelet.ps "+OUTDIR+"nino34.wavelet")
     system("mv "+OUTDIR+"nino34.wavelet0001.ps "+OUTDIR+"nino34.wavelet.indmem.ps")
     system("mv "+OUTDIR+"nino34.wavelet0002.ps "+OUTDIR+"nino34.wavelet.indmemdiff.ps")
     if (nEM.ge.1) then  
        system("mv "+OUTDIR+"nino34.wavelet0003.ps "+OUTDIR+"nino34.wavelet.summary.ps")
     end if
     system("rm "+OUTDIR+"nino34.wavelet.ps")
  end if

  print("Finished: sst.indices.ncl")
end

