; This script calculates various metrics scores. 
;
load "$CVDP_SCRIPTS/functions.ncl"

begin
  print("Starting: metrics.ncl")
  OUTDIR = getenv("OUTDIR")  
  OBS = getenv("OBS")
  RUNSTYLE = getenv("RUNSTYLE") 
  IM_COMMAND = getenv("IM_COMMAND")

  if (OBS.eq."False") then
    print("metrics.ncl: Reference data not present.")
    print("Exiting: metrics.ncl")    
  end if

  nclver = stringtochar(get_ncl_version())   ; check NCL version to turn off error messages
  num0 = toint(tostring(nclver(0)))    
  num1 = toint(tostring(nclver(2)))
  errmsg = True
  if (num0.le.5) then
     errmsg = False
  end if
  if (num0.eq.6) then
     if (num1.le.4) then
        errmsg = False
     else
        errmsg = True
     end if
  end if  
  if (num0.ge.7) then
     errmsg = True
  end if
  delete([/num0,num1/])

;---------------------
  nsim  = numAsciiRow("namelist_byvar/namelist_ts")
  na    = asciiread("namelist_byvar/namelist_ts",(/nsim/),"string")
  names = new(nsim,"string")
  syear = new(nsim,"integer",-999)
  eyear = new(nsim,"integer",-999)
  names_EM = new(nsim,"string")
  EM_num = new(nsim,"integer",-999)
  delim = "|"

  do ee = 0,nsim-1
     names(ee) = str_strip(str_get_field(na(ee),1,delim))
     syear(ee) = stringtointeger(str_strip(str_get_field(na(ee),3,delim)))
     eyear(ee) = stringtointeger(str_strip(str_get_field(na(ee),4,delim)))
     temp      = str_split(str_strip(str_get_field(na(ee),5,delim)),"-")
     EM_num(ee)    = toint(temp(0))
     names_EM(ee)  = str_join(temp(1:),"-")
     delete(temp)
  end do
  modname = str_sub_str(names," ","_")
  bc = (/"/","'","(",")"/)
  do ff = 0,dimsizes(modname)-1
     do ee = 0,dimsizes(bc)-1
        modname(ff) = str_sub_str(modname(ff),bc(ee),"_")
     end do
  end do
  numobs = num(EM_num.eq.0) 

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
;---------------------------------------------------------------------------------------------------------
  cr = "~C~"

  varlist = (/"nino34_spacomp_tas_djf1","nino34_spacomp_psl_djf1","nino34_hov_elnino","nino34_hov_lanina",\
               "amv_pattern_lowpass_mon","pdv_pattern_mon","nao_pattern_jfm","pna_pattern_djf",\
               "sam_pattern_djf","sst_spatialstddev_ann","pr_spatialstddev_ann"/)
  varlist_obs = varlist
  ncol_labels = (/"ENSO TAS (DJF~S~+1~N~)","ENSO PSL (DJF~S~+1~N~)","El Nin~H-13V2F35~D~FV-2H3F21~o Hovmo~H-14V2F35~H~FV-2H3~ller",\
                  "La Nin~H-13V2F35~D~FV-2H3F21~a Hovmo~H-14V2F35~H~FV-2H3~ller","AMV Low-Pass","PDV", \
                     "NAO (JFM)","PNA (DJF)","SAM (DJF)","SST std dev (Ann)","PR std dev (Ann)","Mean Score"/) 

  ncol_rms_units = (/"~S~o~N~C","hPa","~S~o~N~C","~S~o~N~C","~S~o~N~C","~S~o~N~C","hPa","hPa","hPa","~S~o~N~C","mm day~S~-1~N~",""/)
  varlist_fn = (/"sst.indices.tas","sst.indices.psl","sst.indices","sst.indices","amv",\
                 "pdv","nao","pna_npo","sam_psa","sst.mean_stddev","pr.mean_stddev"/)   
  domain = (/"global","global","hov","hov","globalA","global","NHext","NHext","SHext","global","global"/)
  variable = (/"tas","psl","sst","sst","sst","sst","psl","psl","psl","sst","pr"/)

  finobs0_rmssf  = new(dimsizes(varlist),double,9.99)   ; calculate spatial RMS for the first OBS dataset for each metric (following Deser et al 2020)
  do cc = 0,dimsizes(varlist)-1   
     if (variable(cc).eq."tas") then
        syearT = syear_tas(0)
        eyearT = eyear_tas(0)
        modnameT = modname_tas(0)
     end if
     if (variable(cc).eq."sst") then
        syearT = syear(0)
        eyearT = eyear(0)
        modnameT = modname(0)
     end if
     if (variable(cc).eq."psl") then
        syearT = syear_psl(0)
        eyearT = eyear_psl(0)
        modnameT = modname_psl(0)
     end if
     if (variable(cc).eq."pr") then
        syearT = syear_pr(0)
        eyearT = eyear_pr(0)
        modnameT = modname_pr(0)
     end if

     fnt = getenv("OUTDIR")+modnameT+".cvdp_data."+varlist_fn(cc)+"."+syearT+"-"+eyearT+".nc"
     fnt2 = getenv("OUTDIR")+modnameT+".cvdp_data."+syearT+"-"+eyearT+".nc"
     obs0 := read_cvdp_le_data(fnt,fnt2,varlist_obs(cc))
     if (isatt(obs0,"is_all_missing")) then
        continue
     end if
     if (domain(cc).ne."hov") then
        clat_obs0 := cos(0.01745329*obs0&lat)
        clat_obs0!0 = "lat"
        clat_obs0&lat = obs0&lat
     end if
     if (domain(cc).eq."global") then
        finobs0_rmssf(cc) = (/ sqrt(wgt_areaave(obs0^2,clat_obs0,1.0,0)) /)
     end if
     if (domain(cc).eq."globalA") then
        finobs0_rmssf(cc) = (/ sqrt(wgt_areaave(obs0({-63:65},:)^2,clat_obs0({-63:65}),1.0,0)) /)
     end if
     if (domain(cc).eq."NHext") then
        finobs0_rmssf(cc) = (/ sqrt(wgt_areaave(obs0({20:},:)^2,clat_obs0({20:}),1.0,0)) /)
     end if
     if (domain(cc).eq."SHext") then
        finobs0_rmssf(cc) = (/ sqrt(wgt_areaave(obs0({:-20},:)^2,clat_obs0({:-20}),1.0,0)) /)
     end if
     if (domain(cc).eq."hov") then
        finobs0_rmssf(cc) = (/ sqrt(wgt_areaave(obs0^2,1.0,1.0,0)) /)
     end if
  end do
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
  nEM            = max(EM_num)
  finpc_EM      = new((/nEM,dimsizes(varlist)+1/),double,9.99)
  finrms_EM     = finpc_EM
  finEM_names   = new(nEM,string)
  finname_mod   = new(nsim-1,string)
  finpc         = new((/nsim-1,dimsizes(varlist)+1/),double,9.99)
  finrms        = finpc
  dimquery = dimsizes(finpc)
  do dd = 0,dimsizes(varlist)-1  
     if (variable(dd).eq."tas") then
        syearT = syear_tas(0)
        eyearT = eyear_tas(0)
        modnameT = modname_tas(0)
     end if
     if (variable(dd).eq."sst") then
        syearT = syear(0)
        eyearT = eyear(0)
        modnameT = modname(0)
     end if
     if (variable(dd).eq."psl") then
        syearT = syear_psl(0)
        eyearT = eyear_psl(0)
        modnameT = modname_psl(0)
     end if
     if (variable(dd).eq."pr") then
        syearT = syear_pr(0)
        eyearT = eyear_pr(0)
        modnameT = modname_pr(0)
     end if

     fnt = getenv("OUTDIR")+modnameT+".cvdp_data."+varlist_fn(dd)+"."+syearT+"-"+eyearT+".nc"
     fnt2 = getenv("OUTDIR")+modnameT+".cvdp_data."+syearT+"-"+eyearT+".nc"
     obs0 := read_cvdp_le_data(fnt,fnt2,varlist_obs(dd))
     if (isatt(obs0,"is_all_missing")) then
        continue
     end if
     cntr_EM = 0
     cntr = 1
     if (numobs.ge.2) then     ; plot obs #2-
        if (.not.isvar("finname_obs")) then
           finname_obs := new((/numobs-1,dimsizes(varlist)/),string)
        end if
        do ff = 1,numobs-1
           if (variable(dd).eq."tas") then
              syearT = syear_tas(cntr)
              eyearT = eyear_tas(cntr)
              modnameT = modname_tas(cntr)
           end if
           if (variable(dd).eq."sst") then
              syearT = syear(cntr)
              eyearT = eyear(cntr)
              modnameT = modname(cntr)
           end if
           if (variable(dd).eq."psl") then
              syearT = syear_psl(cntr)
              eyearT = eyear_psl(cntr)
              modnameT = modname_psl(cntr)
           end if
           if (variable(dd).eq."pr") then
              syearT = syear_pr(cntr)
              eyearT = eyear_pr(cntr)
              modnameT = modname_pr(cntr)
           end if

           finname_obs(ff-1,dd) = (/ modnameT /)

           fnt = getenv("OUTDIR")+modnameT+".cvdp_data."+varlist_fn(dd)+"."+syearT+"-"+eyearT+".nc"
           fnt2 = getenv("OUTDIR")+modnameT+".cvdp_data."+syearT+"-"+eyearT+".nc"
           arr := read_cvdp_le_data(fnt,fnt2,varlist_obs(dd))
           if (isatt(arr,"is_all_missing")) then 
              cntr = cntr+1
              continue
           end if

           if (domain(dd).eq."hov") then
              obs0_rg := arr
              obs0_rg  = obs0_rg@_FillValue 
              do hh = 0,dimsizes(arr&time_mon1)-1
                 obs0_rg(hh,:) = (/ linint1(obs0&longitude,obs0(hh,:),False,arr&longitude,0) /)
              end do
           else
              clat := cos(0.01745329*arr&lat)
              clat!0 = "lat"
              clat&lat = arr&lat
              obs0_rg := linint2_Wrap(obs0&lon,obs0&lat,obs0,True,arr&lon,arr&lat,0)
           end if

           if (domain(dd).eq."global") then
              finpc(ff-1,dd)  = (/ pattern_cor(obs0_rg,arr,clat,0)  /)
              finrms(ff-1,dd) = (/ wgt_arearmse(obs0_rg,arr,clat,1.0,0)  /)
           end if
           if (domain(dd).eq."globalA") then
              finpc(ff-1,dd)  = (/ pattern_cor(obs0_rg({-63:65},:),arr({-63:65},:),clat({-63:65}),0)  /)
              finrms(ff-1,dd) = (/ wgt_arearmse(obs0_rg({-63:65},:),arr({-63:65},:),clat({-63:65}),1.0,0)  /)
           end if
           if (domain(dd).eq."NHext") then
              finpc(ff-1,dd)  = (/ pattern_cor(obs0_rg({20:},:),arr({20:},:),clat({20:}),0)  /)
              finrms(ff-1,dd) = (/ wgt_arearmse(obs0_rg({20:},:),arr({20:},:),clat({20:}),1.0,0)  /)
           end if
           if (domain(dd).eq."SHext") then
              finpc(ff-1,dd)  = (/ pattern_cor(obs0_rg({:-20},:),arr({:-20},:),clat({:-20}),0)  /)
              finrms(ff-1,dd) = (/ wgt_arearmse(obs0_rg({:-20},:),arr({:-20},:),clat({:-20}),1.0,0)  /)
           end if
           if (domain(dd).eq."hov") then
              finpc(ff-1,dd)  = (/ pattern_cor(obs0_rg,arr,1.0,0)  /)
              finrms(ff-1,dd) = (/ wgt_arearmse(obs0_rg,arr,1.0,1.0,0)  /)
           end if
           cntr = cntr+1
        end do
     end if
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
     do gg = 1,nEM   ; operate on each ensemble mean
        nens = num(EM_num.eq.gg) ; determines how many model simulations in each ensemble
        cntr_ens := ind(EM_num.eq.gg)   ; cntr_ens(hh) are the indices where each ensemble member of an ensemble reside 
        if (ismissing(finEM_names(gg-1))) then
           finEM_names(gg-1) = names_EM(cntr_ens(0))   
        end if
        do hh = 0,nens-1
           modname_mod = modname(cntr_ens(hh))
           syear_mod = syear(cntr_ens(hh))
           eyear_mod = eyear(cntr_ens(hh))
           names_mod = names(cntr_ens(hh))
           names_EM_mod = names_EM(cntr_ens(hh))
           if (ismissing(finname_mod(cntr_ens(hh)-1))) then
              finname_mod(cntr_ens(hh)-1) = (/ names_mod /)
           end if
           fnt = getenv("OUTDIR")+modname_mod+".cvdp_data."+varlist_fn(dd)+"."+syear_mod+"-"+eyear_mod+".nc"
           fnt2 = getenv("OUTDIR")+modname_mod+".cvdp_data."+syear_mod+"-"+eyear_mod+".nc"
           arr := read_cvdp_le_data(fnt,fnt2,varlist(dd))
           if (isatt(arr,"is_all_missing")) then 
              continue
           end if

           if (domain(dd).eq."hov") then
              obs0_rg := arr
              obs0_rg  = obs0_rg@_FillValue 
              do ii = 0,dimsizes(arr&time_mon1)-1
                 obs0_rg(ii,:) = (/ linint1(obs0&longitude,obs0(ii,:),False,arr&longitude,0) /)
              end do
           else
              clat := cos(0.01745329*arr&lat)
              clat!0 = "lat"
              clat&lat = arr&lat
              obs0_rg := linint2_Wrap(obs0&lon,obs0&lat,obs0,True,arr&lon,arr&lat,0)
           end if
           if (domain(dd).eq."global") then
              finpc(cntr_ens(hh)-1,dd)  = (/ pattern_cor(obs0_rg,arr,clat,0)  /)
              finrms(cntr_ens(hh)-1,dd) = (/ wgt_arearmse(obs0_rg,arr,clat,1.0,0)  /)
           end if
           if (domain(dd).eq."globalA") then
              finpc(cntr_ens(hh)-1,dd)  = (/ pattern_cor(obs0_rg({-63:65},:),arr({-63:65},:),clat({-63:65}),0)  /)
              finrms(cntr_ens(hh)-1,dd) = (/ wgt_arearmse(obs0_rg({-63:65},:),arr({-63:65},:),clat({-63:65}),1.0,0)  /)
           end if
           if (domain(dd).eq."NHext") then
              finpc(cntr_ens(hh)-1,dd)  = (/ pattern_cor(obs0_rg({20:},:),arr({20:},:),clat({20:}),0)  /)
              finrms(cntr_ens(hh)-1,dd) = (/ wgt_arearmse(obs0_rg({20:},:),arr({20:},:),clat({20:}),1.0,0)  /)
           end if
           if (domain(dd).eq."SHext") then
              finpc(cntr_ens(hh)-1,dd)  = (/ pattern_cor(obs0_rg({:-20},:),arr({:-20},:),clat({:-20}),0)  /)
              finrms(cntr_ens(hh)-1,dd) = (/ wgt_arearmse(obs0_rg({:-20},:),arr({:-20},:),clat({:-20}),1.0,0)  /)
           end if
           if (domain(dd).eq."hov") then
              finpc(cntr_ens(hh)-1,dd)  = (/ pattern_cor(obs0_rg,arr,1.0,0)  /)
              finrms(cntr_ens(hh)-1,dd) = (/ wgt_arearmse(obs0_rg,arr,1.0,1.0,0)  /)
           end if
        end do   

        cntr_ens = cntr_ens - 1    ; now using cntr_ens to reference arrays where the first obs is stripped out (finpc/finrms)
        finrms_EM(gg-1,dd) = (/ avg(finrms(cntr_ens,dd)) /)

        pc_z := finpc(cntr_ens,dd)
        pc_z = pc_z@_FillValue
        do ii = 0,nens-1   ; use Fisher's z-transformation to translate r->z
           valpc = finpc(cntr_ens(ii),dd)
           valpc = where(valpc.eq.1.0,1.001,valpc)   ; needed when pattern correlation = 1.0
           pc_z(ii) = 0.5*(log( (1+valpc) / (1-valpc) ))
        end do
        finpc_EM(gg-1,dd) = (/ ((2.71828^(2*avg(pc_z)))-1)/ ((2.71828^(2*avg(pc_z)))+1) /)  ; reverse process and convert z-avg -> r.
     end do   ; gg loop (each EM)
  end do   ; dd loop (each metric)
; --- each pc/rms calculated for each metric, now calculate mean scores for each observation/model
  finrms_norm = finrms ; normalize the individual metric rms scores by the first observational dataset's spatial rms value
  finrms_norm = finrms_norm@_FillValue   
  do dd = 0,dimsizes(varlist)-1  
;     if (.not.any(ismissing(finrms(:,dd)))) then   ; if one metric for model A is missing, do not compute model A mean rms 
        finrms_norm(:,dd) = (/ finrms(:,dd)/(finobs0_rmssf(dd)) /)
;     end if
  end do
  do ss = 0,dimquery(0)-1
     if (.not.any(ismissing(finrms_norm(ss,:dimsizes(varlist)-1)))) then
        finrms(ss,dimsizes(varlist)) = (/ dim_avg(finrms_norm(ss,:)) /)
     end if
  end do
  delete(finrms_norm) 

  finpc = where(finpc.eq.1, 1.001,finpc)
  finpcT := 0.5*(log( (1+finpc) / (1-finpc) ))
  do ss = 0,dimquery(0)-1
     if (.not.any(ismissing(finpcT(ss,:dimsizes(varlist)-1)))) then
        finpc(ss,dimsizes(varlist)) = (/ ((2.71828^(2*avg(finpcT(ss,:))))-1)/ ((2.71828^(2*avg(finpcT(ss,:))))+1) /) 
     end if
  end do
;------------------------------------
  if (any(isnan_ieee(finpc))) then
      replace_ieeenan (finpc, finpc@_FillValue, 0)
  end if

  do gg = 1,nEM   ; operate on each ensemble mean (averaging across ensemble members for ensemble mean values for each metric)
     nens = num(EM_num.eq.gg) ; determines how many model simulations in each ensemble
     cntr_ens := ind(EM_num.eq.gg)   ; cntr_ens(hh) are the indices where each ensemble member of an ensemble reside 
     cntr_ens = cntr_ens - 1    ; using cntr_ens to reference arrays where the first obs is stripped out (finpc/finrms)
     finrms_EM(gg-1,dimsizes(varlist)) = (/ avg(finrms(cntr_ens,dimsizes(varlist))) /)

;     if (.not.any(ismissing(finpc(cntr_ens,dimsizes(varlist))))) then   ; if any ensemble means are missing, do not calculate ensemble mean
        pc_z := finpc(cntr_ens,dimsizes(varlist))
        pc_z = pc_z@_FillValue
        do ii = 0,nens-1   ; use Fisher's z-transformation to translate r->z
           valpc = finpc(cntr_ens(ii),dimsizes(varlist))
;           valpc = where(valpc.eq.1.0,1.001,valpc) ; necessary when pattern correlation = 1.0 (not needed due to line 377)
           pc_z(ii) = 0.5*(log( (1+valpc) / (1-valpc) ))
        end do
        finpc_EM(gg-1,dimsizes(varlist)) = (/ ((2.71828^(2*avg(pc_z)))-1)/ ((2.71828^(2*avg(pc_z)))+1) /)  ; reverse process and convert z-avg -> r.
;     end if
  end do        
  if (any(isnan_ieee(finpc_EM))) then
      replace_ieeenan (finpc_EM, finpc_EM@_FillValue, 0)
  end if

  nsim = nsim - 1    ; first listed dataset is what all others are compared to, thus, output metrics table has nsim-1 column  

  if (isvar("finname_obs")) then   ; More than one observational comparison
     names_obs = finname_obs(:,0)

     do gg = 0,numobs-2   ; check to see if data names vary by variable, if so, they're observations and rename to generic label
        if (all(finname_obs(gg,0).eq.finname_obs(gg,1:))) then
           if (ismissing(finname_obs(gg,0))) then
              names_obs(gg) = "Reference "+(gg+2)
           else
              names_obs(gg) = finname_obs(gg,0)
           end if
        else
           names_obs(gg) = "Reference "+(gg+2)
        end if
     end do
     delete(finname_obs)

     names := finname_mod
     names(:dimsizes(names_obs)-1) = (/ names_obs /)
     delete(names_obs)
  else
     tempnames := names(1:)   ; only one observational comparison
     names := tempnames
     delete(tempnames)
  end if
  delete([/finname_mod/])

  patcor_rms = sprintf("%4.2f",finpc)+"/"+sprintf("%4.2f",finrms)
;  pc_score = sprintf("%4.2f",finpc(:,11))
;  rms_score = sprintf("%4.2f",finrms(:,11))
;======================================================================
; Create ensemble summary graphics
;
  csubtitle_color = set_subtitle_colors(dimsizes(names_EM))
  if (numobs.ge.2) then
     numbox = nEM+1
  else
     numbox = nEM+1
  end if
  names_EM2 = names_EM(1:)
  EM_num2 = EM_num(1:)
  
  yAxis = ispan(0,numbox+1,1)
  labarr = new(numbox+2,"string")         ;Prepare actual Y-axis labels...
  labarr(0) = ""
  labarr(numbox+1) = ""

  pres = True
  polyres = True                          ;Set up defaults
  polyres@gsLineThicknessF  = 3.5                          ; thickness of lines
  polyres@gsLineDashPattern = 0

  polyres2 = polyres   ; for ensemble mean bars
  polyres2@gsLineThicknessF  = 7.5 
  polyres2@gsLineDashPattern = 0
  polyres2@gsLineOpacityF = 0.5
  polyres3 = polyres2   ; for 10/90% bars
  polyres3@gsLineThicknessF  = 5.5 

  panres = True
  panres@gsnPanelYWhiteSpacePercent = 4.0

  wks_type = "png"    ; output png  
  wks_type@wkWidth = 1500   
  wks_type@wkHeight = 1500  
  if (nEM.le.3) then
     ph = .5
  end if
  if (nEM.ge.4.and.nEM.lt.7) then
     ph = .65
  end if
  if (nEM.ge.7.and.nEM.lt.10) then
     ph = .8
  end if
  if (nEM.ge.10) then
     ph = .9
  end if
  ofile = (/"ensemble_metrics_pc","ensemble_metrics_rms"/)
  dima = dimsizes(finpc_EM)
  finEM_10 = new((/2,dima(0),dima(1)/),typeof(finpc_EM))    ; pc,rms | number of ensembles | number of metrics
  finEM_90 = finEM_10  
  do jj = 0,1
     wks = gsn_open_wks(wks_type,OUTDIR+"table")
     if (jj.eq.0) then
        parr = finpc
        fin_EM = finpc_EM
     end if  
     if (jj.eq.1) then
        parr = finrms
        fin_EM = finrms_EM
     end if      
     plot := new(dimquery(1),graphic)
     do mm = 0,dimquery(1)-1
        if (jj.eq.0) then
           vxmin = min(parr(:,mm))-((max(parr(:,mm)) - min(parr(:,mm)))*.05)
           vxmax = 1.001
        end if
        if (jj.eq.1) then
           vxmin := -0.001
           vxmax := max(parr(:,mm))+((max(parr(:,mm)) - min(parr(:,mm)))*.05)
        end if
        
        if (ismissing(vxmin).or.ismissing(vxmax).or.vxmin.eq.vxmax) then
           continue
        end if

        if (jj.eq.0) then
           ncol_labels2 = ncol_labels(mm)
        end if
        if (jj.eq.1) then
           ncol_labels2 = ncol_labels(mm)+" ~Z60~"+ncol_rms_units(mm)
        end if

        plot(mm) = create "plot" logLinPlotClass wks
           "vpHeightF": ph
           "vpWidthF": 0.8
           "trYMinF" : min(yAxis)+0.25
           "trYMaxF" : max(yAxis)-0.25
           "trXMinF" : vxmin  ; or 0 for rms
           "trXMaxF" : vxmax   ; or 1.0 for pc
           "pmTickMarkDisplayMode" : "Always"
           "tmYLMode"   : "Explicit"
           "tmYLValues" : yAxis
           "tmYROn"  : False
           "tmXTOn"  : False
           "tmBorderLineColor" : "gray70"
           "tmXBMajorLineColor" : "gray70"
           "tmXBMinorLineColor" : "gray70"
           "tmYLMajorLineColor" : "gray70"
           "tmYLMinorLineColor" : "gray70"
           "tmXBLabelFontHeightF" : 0.028
           "tmYLLabelFontHeightF" : 0.028
           "pmTitleDisplayMode": "Always"                   ; allow titles
           "tiMainOn"     : True
           "tiMainString"   : ncol_labels2
           "tiMainFontHeightF" : 0.038
        end create
        dum := new(dimsizes(names),graphic)
        dumEM := new((/nEM,3/),graphic)
        cntr = 0
        ycoord = ispan(1,numbox,1)
        ycoord = ycoord(::-1)
        sti = 0
        polyres@gsLineColor       = "black"  
        labarr(numbox) = "Reference"
        if (numobs.ge.2) then
           do oo = 0,numobs-2
              sti = 1
              val = parr(cntr,mm)
              if (.not.ismissing(val)) then
                 dum(cntr) = gsn_add_polyline(wks,plot(mm),(/val,val/),(/ycoord(0)-.25,ycoord(0)+.25/),polyres)
              end if
              cntr = cntr+1
           end do
        end if
 
        cntr_em = 0
        do nn = 1,nEM
           ens_ind := ind(EM_num2.eq.nn)   ; 
           labarr(numbox-nn) = names_EM2(ens_ind(0))   ; 1st row of names_EM eliminated
           polyres@gsLineColor = csubtitle_color(cntr_em)
           polyres2@gsLineColor = csubtitle_color(cntr_em)
           polyres3@gsLineColor = csubtitle_color(cntr_em)
           stats := boxplot_stat(parr(ens_ind,mm))
           finEM_10(jj,cntr_em,mm) = stats(0)
           finEM_90(jj,cntr_em,mm) = stats(4)
           do oo = 0,dimsizes(ens_ind)-1
              val = parr(ens_ind(oo),mm)
;              print("mm = "+mm+" "+ens_ind(oo)+" val = "+val+" ycoord(nn)="+ycoord(nn))
              if (.not.ismissing(val)) then
                 dum(cntr) = gsn_add_polyline(wks,plot(mm),(/val,val/),(/ycoord(nn)-.25,ycoord(nn)+.25/),polyres)
              end if
              cntr = cntr+1
           end do
           if (.not.ismissing(stats(0))) then
              dumEM(cntr_em,0) = gsn_add_polyline(wks,plot(mm),(/stats(0),stats(0)/),(/ycoord(nn)-.38,ycoord(nn)+.38/),polyres3)   ; draw 10% index
           end if
           if (.not.ismissing(fin_EM(cntr_em,mm))) then
              dumEM(cntr_em,1) =  gsn_add_polyline(wks,plot(mm),(/fin_EM(cntr_em,mm),fin_EM(cntr_em,mm)/),(/ycoord(nn)-.45,ycoord(nn)+.45/),polyres2)    ; draw mean value
           end if
           if (.not.ismissing(stats(4))) then
              dumEM(cntr_em,2) = gsn_add_polyline(wks,plot(mm),(/stats(4),stats(4)/),(/ycoord(nn)-.38,ycoord(nn)+.38/),polyres3)    ; draw 90% index
           end if
           cntr_em = cntr_em+1
        end do
        pres@tmYLLabels := labarr
        attsetvalues(plot(mm),pres)
        dumname = unique_string("dum")
        plot@$dumname$ = dum
        dumname = unique_string("dum")
        plot@$dumname$ = dumEM
     end do
     gsn_panel(wks,plot,(/4,3/),panres)
     delete(wks)
     system(IM_COMMAND+" "+OUTDIR+"table."+wks_type+" -density 360 -trim +repage -bordercolor white -border 40 -transparent white "+OUTDIR+ofile(jj)+".gif")  
     system("rm "+OUTDIR+"table.png")
  end do
  delete([/pres,panres,polyres,polyres2/])
  delete([/finpc,finrms/])
;------------------------------------------------------------------------------------
; create ensemble mean ascii table and graphical tables
  patcor_rmsEM  = sprintf("%4.2f",finpc_EM)+"/"+sprintf("%4.2f",finrms_EM)
  patcor_rms10 = sprintf("%4.2f",finEM_10(0,:,:))+"/"+sprintf("%4.2f",finEM_10(1,:,:))   
  patcor_rms90 = sprintf("%4.2f",finEM_90(0,:,:))+"/"+sprintf("%4.2f",finEM_90(1,:,:))  
  
  nsimE = nEM*3
  patcor_rmsE = new((/nsimE,dimsizes(ncol_labels)/),string)
  namesE = new(nEM*3,string)
  cntr = 0
  do gg = 0,nEM-1
     patcor_rmsE(cntr,:) = (/ patcor_rms10(gg,:) /)
     patcor_rmsE(cntr+1,:) = (/ patcor_rmsEM(gg,:) /)
     patcor_rmsE(cntr+2,:) = (/ patcor_rms90(gg,:) /)
     namesE(cntr)   = finEM_names(gg)+" (10%)"
     namesE(cntr+1) = finEM_names(gg)+" (Avg)"
     namesE(cntr+2) = finEM_names(gg)+" (90%)"
     cntr = cntr+3
  end do

  testdim = dimsizes(tochar(namesE))
  spacer = ""
  do gg = 0,testdim(1)
     spacer = spacer+" "
  end do
  delete(testdim) 
  
  if (RUNSTYLE.ne."1") then
     header = (/"","Pattern Correlations/RMS Differences   Reference Dataset 1 vs. Ensemble Means",""/)
     write_table(OUTDIR+"metrics_EM.txt","w",[/header/],"%s")

     column_header1 = spacer+"   ENSO TAS   ENSO PSL   El Nino    La Nina     AMV LP      PDV        NAO        PNA        SAM     SST sigma   PR sigma    Mean  "
     column_header2 = spacer+"    (DJF+1)    (DJF+1)     Hov        Hov     (Monthly)  (Monthly)    (JFM)      (DJF)      (DJF)      (Ann)       (Ann)     Score  "
     column_header3 = spacer+"  ---------  ---------  ---------  ---------  ---------  ---------  ---------  ---------  ---------  ---------  ---------  ---------"

     write_table(OUTDIR+"metrics_EM.txt","a",[/column_header1/],"%s")
     write_table(OUTDIR+"metrics_EM.txt","a",[/column_header2/],"%s")
     write_table(OUTDIR+"metrics_EM.txt","a",[/column_header3/],"%s")
  
     spacer_char = tochar(spacer)
     do gg = 0,nEM*3-1
        spacer_char1 = spacer_char
        mname_char = tochar(namesE(gg))
        dimC = dimsizes(mname_char)
        spacer_char1(:dimC-1) = mname_char
        srow = tostring(spacer_char1)
        do hh = 0,dimsizes(ncol_labels)-1
           n1 := str_split(patcor_rmsE(gg,hh),"/")
           valp := n1(0)
           valr := n1(1)
           valp = where(valp.eq."9.99","----",valp)
           valr = where(valr.eq."9.99","----",valr)
           valp = where(valp.eq."-999.00","----",valp)
           valr = where(valr.eq."-999.00","----",valr)
           if (valp.eq."----") then
              srow = srow+"  "+valp+"/"+valr
           else
              if (tofloat(valp).ge.0) then
                 srow = srow+"  "+valp+"/"+valr
              else
                 srow = srow+" "+valp+"/"+valr
              end if   
           end if
        end do
;        srow = srow+"  "+pc_score(gg)+"/"+rms_score(gg)     
        write_table(OUTDIR+"metrics_EM.txt","a",[/srow/],"%s")
        delete([/spacer_char1,dimC,mname_char,srow/])
     end do
     delete([/spacer_char/])
  end if


  if (nsimE.le.255) then
     namesE!0 = "sim"
     namesE&sim = ispan(0,nsimE-1,1)
     patcorE = new((/nsimE,12/),typeof(patcor_rmsE))
     rmsE = patcorE
     do gg = 0,nsimE-1
        do hh = 0,dimsizes(ncol_labels)-1
           n1 = str_split(patcor_rmsE(gg,hh),"/")
           patcorE(gg,hh) = n1(0)
           rmsE(gg,hh) = n1(1)
        end do
     end do
     patcorE!0 = "sim"
     patcorE&sim = ispan(0,nsimE-1,1)
     copy_VarCoords(patcorE,rmsE)
     patcorE = where(patcorE.eq."9.99","----",patcorE)
     rmsE = where(rmsE.eq."9.99","----",rmsE)
     patcorE = where(patcorE.eq."-999.00","----",patcorE)
     rmsE = where(rmsE.eq."-999.00","----",rmsE)

     ncols = 12
     nrows = nsimE
     col_width  = 1./ncols
     row_width  = 1./nrows
     col_width2 = col_width/2.
     row_width2 = row_width/2.
  
     fcolors = new(dimsizes(patcorE),"integer")
     colors = (/7,12,17,22,27,33,37,42,47,53,59,65/)
     cnLevels = (/0.5,0.55,0.60,0.65,0.7,0.75,0.8,0.85,0.9,0.95,0.99/)
     do gg = 0,dimsizes(cnLevels)
        if (gg.eq.0) then
           fcolors = where(patcorE.lt.cnLevels(0),colors(0),fcolors)
        end if
        if (gg.ge.1.and.gg.lt.dimsizes(cnLevels)) then
           fcolors = where(patcorE.lt.cnLevels(gg).and.patcorE.ge.cnLevels(gg-1),colors(gg),fcolors)
        end if
        if (gg.eq.dimsizes(cnLevels)) then
           fcolors = where(patcorE.ge.cnLevels(gg-1),colors(gg),fcolors)
        end if
     end do
     fcolors = where(patcorE.eq."----",75,fcolors)
  
     fcolorsR = new(dimsizes(rmsE),"integer")
     colorsR = (/65,59,53,47,42,37,33,27,22,17,12,7/)
     cnLevelsR = (/.05,.1,.2,.3,.4,.5,.6,.7,.8,.9,1./)
     do gg = 0,dimsizes(cnLevelsR)
        if (gg.eq.0) then
           fcolorsR = where(rmsE.lt.cnLevelsR(0),colorsR(0),fcolorsR)
        end if
        if (gg.ge.1.and.gg.lt.dimsizes(cnLevelsR)) then
           fcolorsR = where(rmsE.lt.cnLevelsR(gg).and.rmsE.ge.cnLevelsR(gg-1),colorsR(gg),fcolorsR)
        end if
        if (gg.eq.dimsizes(cnLevelsR)) then
            fcolorsR = where(rmsE.ge.cnLevelsR(gg-1),colorsR(gg),fcolorsR)
        end if
     end do
     fcolorsR = where(rmsE.eq."----",75,fcolorsR)
;--------------------------------------------------------------------------------------------
     if (nsimE.ge.80.and.nsimE.lt.179) then
        wks_type@wkWidth = 2500    
        wks_type@wkHeight = 2500  
     end if
     if (nsimE.ge.180) then
        wks_type@wkWidth = 4000    
        wks_type@wkHeight = 4000  
     end if
     wks = gsn_open_wks(wks_type,OUTDIR+"table")  ; send graphics to PNG file
     gsn_merge_colormaps(wks,"cmp_b2r","gsltod") 

     resb                         = True    ; resource list for blank plot that gsn_table will be overlaid on
     resb@gsnDraw                 = False
     resb@gsnFrame                = False
     resb@vpXF                    = 0.3  
     title_loc = (/.185,0.075,.185,0.05/)   ; default x/y ndc values for location of plot title and subtitle
     b_int                        = 0.0
     if (nsimE.le.32) then
        resb@vpWidthF                = 0.59
        resb@vpYF                    = 0.825
        resb@vpHeightF               = nsimE*0.025
        if (resb@vpHeightF.lt..175) then    ; set a minimum height
           resb@vpHeightF = .175
        end if
       resb@tmXTLabelFontHeightF    = 0.0125       
       resb@tmXTMajorLengthF = 0.009
     end if
     if (nsimE.ge.33.and.nsimE.lt.80) then
        resb@vpWidthF                = 0.59
        resb@vpYF                    = 0.865
        resb@vpHeightF               = 0.8601
        resb@tmXTLabelFontHeightF    = 0.0085
        resb@tmXTMajorLengthF        = 0.009
     end if
     if (nsimE.ge.80.and.nsimE.lt.109) then
        resb@vpWidthF                = 0.59
        resb@vpYF                    = 0.865
        resb@vpHeightF               = 0.8602
        resb@tmXTLabelFontHeightF    = 0.0065
        resb@tmXTMajorLengthF = 0.009
        b_int                        = .00185
     end if
     if (nsimE.ge.109.and.nsimE.lt.150) then
        resb@vpWidthF                = 0.425
        resb@vpYF                    = 0.865
        resb@vpHeightF               = 0.8603
        resb@tmXTLabelFontHeightF    = 0.0045
        resb@tmXTMajorLengthF = 0.0065
        title_loc = (/.085,0.035,.085,0.025/)
        b_int                        = .002
     end if
     if (nsimE.ge.150) then
        resb@vpWidthF                = 0.25
        resb@vpYF                    = 0.865
        resb@vpHeightF               = 0.8604
        resb@tmXTLabelFontHeightF    = 0.0025
        resb@tmXTMajorLengthF = 0.0045
        title_loc = (/.07,0.02,.07,0.0125/)
        b_int                        = .002
     end if
     resb@tmYLMajorLengthF = resb@tmXTMajorLengthF
     resb@tmXTMajorOutwardLengthF = resb@tmXTMajorLengthF
     resb@tmYLMajorOutwardLengthF = resb@tmXTMajorLengthF
     resb@tmXTMajorLineColor = "gray55"
     resb@tmYLMajorLineColor = resb@tmXTMajorLineColor
     resb@tmXTLabelFont = 21
     resb@tmXTMode                = "Explicit"    ; Explicitly label X axis. The blank plot goes from 0 to 1, by default.
     resb@tmXTValues              = fspan(col_width2,1.-col_width2,ncols)

     resb@tmXTLabels              = ncol_labels
     resb@tmXTOn                  = True
     resb@tmXUseBottom = False
     resb@tmXTLabelsOn = True
     resb@tmXBOn = False
     resb@tmXTLabelAngleF         = 70.
     resb@tmXTLabelJust           = "CenterLeft"

     resb@tmYLMode                = "Explicit"
     resb@tmYLValues              = fspan(row_width2,1.-row_width2,nrows)
     resb@tmYLLabelFontHeightF    = resb@tmXTLabelFontHeightF           
     resb@tmYROn                  = False
     resb@tiMainOn = False
   
     resT = True
     resT@gsLineThicknessF = 2.0
     resT@gsLineColor = resb@tmXTMajorLineColor
     resT@txFontHeightF = resb@tmXTLabelFontHeightF
     resT@gsFillOpacityF = 0.5
     resT@tfPolyDrawOrder = "PreDraw"

     polyres = True
     polyres@gsLineColor      = "gray25"
     polyres@gsLineThicknessF = 8.0
     polyres@gsLineDashPattern = 0
     polyres@tfPolyDrawOrder = "PostDraw"

     tres = True
     tres@txFontHeightF = resb@tmYLLabelFontHeightF*1.2
     tres@txJust = "CenterLeft"

     tres2 = tres
     tres2@txFontHeightF = resb@tmYLLabelFontHeightF*0.8
     do gg = 0,13
        namesF = namesE
        patcorF = patcorE
        if (gg.eq.0) then
           int_s = namesF&sim
           s_txt = ""
        end if
        if (gg.eq.1) then    ; sort names
           namesF = str_upper(namesF)    ; make all model names uppercase so sqsort sorts like this: A,b,C instead of this: A,C,b
           sqsort(namesF)
           int_s = namesF&sim
           namesF = namesE(int_s)
           s_txt = "Namelist (Alphab.)"
        end if
        if (gg.ge.2) then
           patcorT = patcorF(:,gg-2)
           sqsort(patcorT)
           int_s = patcorT&sim(::-1)
           namesF = namesE(int_s)
           delete(patcorT)
           s_txt = ncol_labels(gg-2)
        end if
        resb@tmYLLabels              = namesF(::-1)  ; this resource takes labels in reverse order as gsn_table
        blank = gsn_csm_blank_plot(wks,resb)
        add_labelbar_mt(wks,blank,colors,""+decimalPlaces(cnLevels,2,True))   ; Attach labelbar
        if (gg.eq.2) then
           dum = gsn_add_polyline(wks,blank,(/.002,.083333,.083333,.002,.002/),(/.002-b_int,.002-b_int,.998+b_int,.998+b_int,.002-b_int/),polyres)
        end if
        if (gg.ge.3.and.gg.le.12) then
           dum = gsn_add_polyline(wks,blank,(/(gg-2)*.083333,(gg-1)*.083333,(gg-1)*.083333,(gg-2)*.083333,(gg-2)*.083333/),(/.002-b_int,.002-b_int,.998+b_int,.998+b_int,.002-b_int/),polyres)
        end if
        if (gg.eq.13) then
           dum = gsn_add_polyline(wks,blank,(/(gg-2)*.083333,.998,.998,(gg-2)*.083333,(gg-2)*.083333/),(/.002-b_int,.002-b_int,.998+b_int,.998+b_int,.002-b_int/),polyres)
        end if
   
        getvalues blank
          "vpXF"      : vpx
          "vpYF"      : vpy  ;    Get position and size of the blank plot so we can
          "vpWidthF"  : vpw  ;    be sure to draw the table in same location.
          "vpHeightF" : vph
        end getvalues   
        x = (/vpx,vpx+vpw/)
        y = (/vpy-vph,vpy/)

        resT@gsFillColor = fcolors(int_s,:)

        if (.not.errmsg) then    ; turn off error messages output from gsn_table if NCL v6.4.0 or older
           err = NhlGetErrorObjectId()
           setvalues err
              "errPrint" : "False"
           end setvalues
        end if
        gsn_table(wks,dimsizes(patcorF),x,y,patcorF(int_s,:),resT) 
        if (.not.errmsg) then
           setvalues err
              "errPrint" : "True"
           end setvalues
        end if
        gsn_text_ndc(wks,"Pattern Correlations",resb@vpXF-title_loc(0),resb@vpYF+title_loc(1),tres)
        if (s_txt.ne."") then
           gsn_text_ndc(wks,"Sorted by: "+s_txt,resb@vpXF-title_loc(2),resb@vpYF+title_loc(3),tres2)
        end if
        draw(blank)
        frame(wks)
        delete([/namesF,patcorF,int_s/])
     end do

     resb@tmXTLabels = ncol_labels+cr+"  ~Z60~"+ncol_rms_units
     do gg = 0,13
        namesF = namesE
        rmsF = rmsE
        if (gg.eq.0) then
           int_s = namesF&sim
           s_txt = ""
        end if
        if (gg.eq.1) then    ; sort names
           namesF = str_upper(namesF)    ; make all model names uppercase so sqsort sorts like this: A,b,C instead of this: A,C,b
           sqsort(namesF)
           int_s = namesF&sim
           namesF = namesE(int_s)
           s_txt = "Name"
        end if
        if (gg.ge.2) then
           rmsT = rmsF(:,gg-2)
           rmsT = where(rmsT.eq."----","1000",rmsT)  ; make sure values of ---- get put to bottom of sorted list 
           sqsort(rmsT)
           rmsT = where(rmsT.eq."1000","----",rmsT)  ; make sure values of ---- get put to bottom of sorted list    
           int_s = rmsT&sim
           namesF = namesE(int_s)
           delete(rmsT)
           s_txt = ncol_labels(gg-2)
        end if
        resb@tmYLLabels              = namesF(::-1)  ; this resource takes labels in reverse order as gsn_table
        blank = gsn_csm_blank_plot(wks,resb)
        add_labelbar_mt(wks,blank,colorsR,""+decimalPlaces(cnLevelsR,2,True))   ; Attach labelbar
        if (gg.eq.2) then
           dum = gsn_add_polyline(wks,blank,(/.002,.083333,.083333,.002,.002/),(/.002-b_int,.002-b_int,.998+b_int,.998+b_int,.002-b_int/),polyres)
        end if
        if (gg.ge.3.and.gg.le.12) then
           dum = gsn_add_polyline(wks,blank,(/(gg-2)*.083333,(gg-1)*.083333,(gg-1)*.083333,(gg-2)*.083333,(gg-2)*.083333/),(/.002-b_int,.002-b_int,.998+b_int,.998+b_int,.002-b_int/),polyres)
        end if
        if (gg.eq.13) then
           dum = gsn_add_polyline(wks,blank,(/(gg-2)*.083333,.998,.998,(gg-2)*.083333,(gg-2)*.083333/),(/.002-b_int,.002-b_int,.998+b_int,.998+b_int,.002-b_int/),polyres)
        end if

        getvalues blank
          "vpXF"      : vpx
          "vpYF"      : vpy  ;    Get position and size of the blank plot so we can
          "vpWidthF"  : vpw  ;    be sure to draw the table in same location.
          "vpHeightF" : vph
        end getvalues
        x = (/vpx,vpx+vpw/)
        y = (/vpy-vph,vpy/)
        resT@gsFillColor = fcolorsR(int_s,:)
        if (.not.errmsg) then    ; turn off error messages output from gsn_table if NCL v6.4.0 or older
           err = NhlGetErrorObjectId()
           setvalues err
              "errPrint" : "False"
           end setvalues
        end if
        gsn_table(wks,dimsizes(rmsF),x,y,rmsF(int_s,:),resT)
        if (.not.errmsg) then
           setvalues err
              "errPrint" : "True"
           end setvalues
        end if
        gsn_text_ndc(wks,"RMS Differences",resb@vpXF-title_loc(0),resb@vpYF+title_loc(1),tres)
        if (s_txt.ne."") then
           gsn_text_ndc(wks,"Sorted by: "+s_txt,resb@vpXF-title_loc(2),resb@vpYF+title_loc(3),tres2)
        end if
        draw(blank)
        frame(wks)
        delete([/namesF,rmsF,int_s/])
     end do
     delete(wks)
     fils = systemfunc("ls "+OUTDIR+"table*.png")
     do gg = 0,dimsizes(fils)-1
        system(IM_COMMAND+" "+fils(gg)+" -density 144 -trim +repage -bordercolor white -border 20 -transparent white "+OUTDIR+"metrics.table_"+gg+"E.gif")  
     end do
     system("rm "+OUTDIR+"table*.png")
  end if
  delete([/patcor_rmsE,namesE,nsimE,resb,resT/])

;=====================================================================================================================
; Begin individual metrics section
;

  testdim = dimsizes(tochar(names))
  spacer = ""
  do gg = 0,testdim(1)
     spacer = spacer+" "
  end do
  delete(testdim)     
;  pc_score = where(pc_score.eq." nan","----",pc_score)  ; needed for when the nan's come out of the z-transform (likey due to numerous pattern correlations = 1) (not needed anymor
  
  header = (/"","Pattern Correlations/RMS Differences   Reference Dataset 1 vs. Simulation(s)",""/)
  write_table(OUTDIR+"metrics.txt","w",[/header/],"%s")

  column_header1 = spacer+"   ENSO TAS   ENSO PSL   El Nino    La Nina     AMV LP      PDV        NAO        PNA        SAM     SST sigma   PR sigma    Mean  "
  column_header2 = spacer+"    (DJF+1)    (DJF+1)     Hov        Hov     (Monthly)  (Monthly)    (JFM)      (DJF)      (DJF)      (Ann)       (Ann)     Score  "
  column_header3 = spacer+"  ---------  ---------  ---------  ---------  ---------  ---------  ---------  ---------  ---------  ---------  ---------  ---------"

  write_table(OUTDIR+"metrics.txt","a",[/column_header1/],"%s")
  write_table(OUTDIR+"metrics.txt","a",[/column_header2/],"%s")
  write_table(OUTDIR+"metrics.txt","a",[/column_header3/],"%s")
  
  spacer_char = tochar(spacer)
  do gg = 0,nsim-1
     spacer_char1 = spacer_char
     mname_char = tochar(names(gg))
     dimC = dimsizes(mname_char)
     spacer_char1(:dimC-1) = mname_char
     srow = tostring(spacer_char1)
     do hh = 0,dimsizes(ncol_labels)-1
        n1 := str_split(patcor_rms(gg,hh),"/")
        valp := n1(0)
        valr := n1(1)
        valp = where(valp.eq."9.99","----",valp)
        valr = where(valr.eq."9.99","----",valr)
        if (valp.eq."----") then
           srow = srow+"  "+valp+"/"+valr
        else
           if (tofloat(valp).ge.0) then
              srow = srow+"  "+valp+"/"+valr
           else
              srow = srow+" "+valp+"/"+valr
           end if   
        end if
     end do
;     srow = srow+"  "+pc_score(gg)+"/"+rms_score(gg)     
     write_table(OUTDIR+"metrics.txt","a",[/srow/],"%s")
     delete([/spacer_char1,dimC,mname_char,srow/])
  end do
  delete([/spacer_char/])

; Create tables that are colored by value and sorted by value
; if there are less than 256 simulations+(number of observational datasets-1)
; (NCL can only create 255 tickmarks on one plot and each tickmark equals a 
;  model/obs below.)

  if (nsim.le.255) then
     names!0 = "sim"
     names&sim = ispan(0,nsim-1,1)
     patcor = new((/nsim,12/),typeof(patcor_rms))
     rms = patcor
     do gg = 0,nsim-1
        do hh = 0,dimsizes(ncol_labels)-1
;           if (hh.le.10) then
              n1 = str_split(patcor_rms(gg,hh),"/")
              patcor(gg,hh) = n1(0)
              rms(gg,hh) = n1(1)
;           else
;              patcor(gg,hh) = pc_score(gg)
;              rms(gg,hh) = rms_score(gg)
;           end if
        end do
     end do
;     delete([/pc_score,rms_score/])
     patcor!0 = "sim"
     patcor&sim = ispan(0,nsim-1,1)
     copy_VarCoords(patcor,rms)
     patcor = where(patcor.eq."9.99","----",patcor)
     rms = where(rms.eq."9.99","----",rms)

     ncols = 12
     nrows = nsim
     col_width  = 1./ncols
     row_width  = 1./nrows
     col_width2 = col_width/2.
     row_width2 = row_width/2.
  
     fcolors := new(dimsizes(patcor),"integer")
     colors = (/7,12,17,22,27,33,37,42,47,53,59,65/)
     cnLevels = (/0.5,0.55,0.60,0.65,0.7,0.75,0.8,0.85,0.9,0.95,0.99/)
     do gg = 0,dimsizes(cnLevels)
        if (gg.eq.0) then
           fcolors = where(patcor.lt.cnLevels(0),colors(0),fcolors)
        end if
        if (gg.ge.1.and.gg.lt.dimsizes(cnLevels)) then
           fcolors = where(patcor.lt.cnLevels(gg).and.patcor.ge.cnLevels(gg-1),colors(gg),fcolors)
        end if
        if (gg.eq.dimsizes(cnLevels)) then
           fcolors = where(patcor.ge.cnLevels(gg-1),colors(gg),fcolors)
        end if
     end do
     fcolors = where(patcor.eq."----",75,fcolors)
  
     fcolorsR := new(dimsizes(rms),"integer")
     colorsR = (/65,59,53,47,42,37,33,27,22,17,12,7/)
     cnLevelsR = (/.05,.1,.2,.3,.4,.5,.6,.7,.8,.9,1./)
     do gg = 0,dimsizes(cnLevelsR)
        if (gg.eq.0) then
           fcolorsR = where(rms.lt.cnLevelsR(0),colorsR(0),fcolorsR)
        end if
        if (gg.ge.1.and.gg.lt.dimsizes(cnLevelsR)) then
           fcolorsR = where(rms.lt.cnLevelsR(gg).and.rms.ge.cnLevelsR(gg-1),colorsR(gg),fcolorsR)
        end if
        if (gg.eq.dimsizes(cnLevelsR)) then
            fcolorsR = where(rms.ge.cnLevelsR(gg-1),colorsR(gg),fcolorsR)
        end if
     end do
     fcolorsR = where(rms.eq."----",75,fcolorsR)
;--------------------------------------------------------------------------------------------
     if (nsim.ge.80.and.nsim.lt.179) then
        wks_type@wkWidth = 2500    
        wks_type@wkHeight = 2500  
     end if
     if (nsim.ge.180) then
        wks_type@wkWidth = 4000    
        wks_type@wkHeight = 4000  
     end if
     wks = gsn_open_wks(wks_type,OUTDIR+"table")  ; send graphics to PNG file
     gsn_merge_colormaps(wks,"cmp_b2r","gsltod") 

     resb                         = True    ; resource list for blank plot that gsn_table will be overlaid on
     resb@gsnDraw                 = False
     resb@gsnFrame                = False
     resb@vpXF                    = 0.3  
     title_loc = (/.185,0.075,.185,0.05/)   ; default x/y ndc values for location of plot title and subtitle
     b_int                        = 0.0
     if (nsim.le.32) then
        resb@vpWidthF                = 0.59
        resb@vpYF                    = 0.825
        resb@vpHeightF               = nsim*0.025
        if (resb@vpHeightF.lt..175) then    ; set a minimum height
           resb@vpHeightF = .175
        end if
       resb@tmXTLabelFontHeightF    = 0.0125       
       resb@tmXTMajorLengthF = 0.009
     end if
     if (nsim.ge.33.and.nsim.lt.80) then
        resb@vpWidthF                = 0.59
        resb@vpYF                    = 0.865
        resb@vpHeightF               = 0.8601
        resb@tmXTLabelFontHeightF    = 0.0085
        resb@tmXTMajorLengthF        = 0.009
     end if
     if (nsim.ge.80.and.nsim.lt.109) then
        resb@vpWidthF                = 0.59
        resb@vpYF                    = 0.865
        resb@vpHeightF               = 0.8602
        resb@tmXTLabelFontHeightF    = 0.0065
        resb@tmXTMajorLengthF = 0.009
        b_int                        = .00185
     end if
     if (nsim.ge.109.and.nsim.lt.150) then
        resb@vpWidthF                = 0.425
        resb@vpYF                    = 0.865
        resb@vpHeightF               = 0.8603
        resb@tmXTLabelFontHeightF    = 0.0045
        resb@tmXTMajorLengthF = 0.0065
        title_loc = (/.085,0.035,.085,0.025/)
        b_int                        = .002
     end if
     if (nsim.ge.150) then
        resb@vpWidthF                = 0.25
        resb@vpYF                    = 0.865
        resb@vpHeightF               = 0.8604
        resb@tmXTLabelFontHeightF    = 0.0025
        resb@tmXTMajorLengthF = 0.0045
        title_loc = (/.07,0.02,.07,0.0125/)
        b_int                        = .002
     end if
     resb@tmYLMajorLengthF = resb@tmXTMajorLengthF
     resb@tmXTMajorOutwardLengthF = resb@tmXTMajorLengthF
     resb@tmYLMajorOutwardLengthF = resb@tmXTMajorLengthF
     resb@tmXTMajorLineColor = "gray55"
     resb@tmYLMajorLineColor = resb@tmXTMajorLineColor
     resb@tmXTLabelFont = 21
     resb@tmXTMode                = "Explicit"    ; Explicitly label X axis. The blank plot goes from 0 to 1, by default.
     resb@tmXTValues              = fspan(col_width2,1.-col_width2,ncols)

     resb@tmXTLabels              = ncol_labels
     resb@tmXTOn                  = True
     resb@tmXUseBottom = False
     resb@tmXTLabelsOn = True
     resb@tmXBOn = False
     resb@tmXTLabelAngleF         = 70.
     resb@tmXTLabelJust           = "CenterLeft"

     resb@tmYLMode                = "Explicit"
     if (nsim.gt.1) then
        resb@tmYLValues              = fspan(row_width2,1.-row_width2,nrows)
     else
        resb@tmYLValues              = row_width2
     end if
     resb@tmYLLabelFontHeightF    = resb@tmXTLabelFontHeightF           
     resb@tmYROn                  = False
     resb@tiMainOn = False
   
     resT = True
     resT@gsLineThicknessF = 2.0
     resT@gsLineColor = resb@tmXTMajorLineColor
     resT@txFontHeightF = resb@tmXTLabelFontHeightF
     resT@gsFillOpacityF = 0.5
     resT@tfPolyDrawOrder = "PreDraw"

     polyres = True
     polyres@gsLineColor      = "gray25"
     polyres@gsLineThicknessF = 8.0
     polyres@gsLineDashPattern = 0
     polyres@tfPolyDrawOrder = "PostDraw"

     tres = True
     tres@txFontHeightF = resb@tmYLLabelFontHeightF*1.2
     tres@txJust = "CenterLeft"

     tres2 = tres
     tres2@txFontHeightF = resb@tmYLLabelFontHeightF*0.8
     do gg = 0,13
        namesF = names
        patcorF = patcor
        if (gg.eq.0) then
           int_s = namesF&sim
           s_txt = ""
        end if
        if (gg.eq.1) then    ; sort names
           namesF = str_upper(namesF)    ; make all model names uppercase so sqsort sorts like this: A,b,C instead of this: A,C,b
           sqsort(namesF)
           int_s = namesF&sim
           namesF = names(int_s)
           s_txt = "Namelist (Alphab.)"
        end if
        if (gg.ge.2) then
           patcorT = patcorF(:,gg-2)
           sqsort(patcorT)
           int_s = patcorT&sim(::-1)
           namesF = names(int_s)
           delete(patcorT)
           s_txt = ncol_labels(gg-2)
        end if
        resb@tmYLLabels              = namesF(::-1)  ; this resource takes labels in reverse order as gsn_table
        blank = gsn_csm_blank_plot(wks,resb)
        add_labelbar_mt(wks,blank,colors,""+decimalPlaces(cnLevels,2,True))   ; Attach labelbar
        if (gg.eq.2) then
           dum = gsn_add_polyline(wks,blank,(/.002,.083333,.083333,.002,.002/),(/.002-b_int,.002-b_int,.998+b_int,.998+b_int,.002-b_int/),polyres)
        end if
        if (gg.ge.3.and.gg.le.12) then
           dum = gsn_add_polyline(wks,blank,(/(gg-2)*.083333,(gg-1)*.083333,(gg-1)*.083333,(gg-2)*.083333,(gg-2)*.083333/),(/.002-b_int,.002-b_int,.998+b_int,.998+b_int,.002-b_int/),polyres)
        end if
        if (gg.eq.13) then
           dum = gsn_add_polyline(wks,blank,(/(gg-2)*.083333,.998,.998,(gg-2)*.083333,(gg-2)*.083333/),(/.002-b_int,.002-b_int,.998+b_int,.998+b_int,.002-b_int/),polyres)
        end if
   
        getvalues blank
          "vpXF"      : vpx
          "vpYF"      : vpy  ;    Get position and size of the blank plot so we can
          "vpWidthF"  : vpw  ;    be sure to draw the table in same location.
          "vpHeightF" : vph
        end getvalues   
        x = (/vpx,vpx+vpw/)
        y = (/vpy-vph,vpy/)

        resT@gsFillColor := fcolors(int_s,:)

        if (.not.errmsg) then    ; turn off error messages output from gsn_table if NCL v6.4.0 or older
           err = NhlGetErrorObjectId()
           setvalues err
              "errPrint" : "False"
           end setvalues
        end if
        gsn_table(wks,dimsizes(patcorF),x,y,patcorF(int_s,:),resT) 
        if (.not.errmsg) then
           setvalues err
              "errPrint" : "True"
           end setvalues
        end if
        gsn_text_ndc(wks,"Pattern Correlations",resb@vpXF-title_loc(0),resb@vpYF+title_loc(1),tres)
        if (s_txt.ne."") then
           gsn_text_ndc(wks,"Sorted by: "+s_txt,resb@vpXF-title_loc(2),resb@vpYF+title_loc(3),tres2)
        end if
        draw(blank)
        frame(wks)
        delete([/namesF,patcorF,int_s/])
     end do

     resb@tmXTLabels = ncol_labels+cr+"  ~Z60~"+ncol_rms_units
     do gg = 0,13
        namesF = names
        rmsF = rms
        if (gg.eq.0) then
           int_s = namesF&sim
           s_txt = ""
        end if
        if (gg.eq.1) then    ; sort names
           namesF = str_upper(namesF)    ; make all model names uppercase so sqsort sorts like this: A,b,C instead of this: A,C,b
           sqsort(namesF)
           int_s = namesF&sim
           namesF = names(int_s)
           s_txt = "Name"
        end if
        if (gg.ge.2) then
           rmsT = rmsF(:,gg-2)
           rmsT = where(rmsT.eq."----","1000",rmsT)  ; make sure values of ---- get put to bottom of sorted list 
           sqsort(rmsT)
           rmsT = where(rmsT.eq."1000","----",rmsT)  ; make sure values of ---- get put to bottom of sorted list    
           int_s = rmsT&sim
           namesF = names(int_s)
           delete(rmsT)
           s_txt = ncol_labels(gg-2)
        end if
        resb@tmYLLabels              = namesF(::-1)  ; this resource takes labels in reverse order as gsn_table
        blank = gsn_csm_blank_plot(wks,resb)
        add_labelbar_mt(wks,blank,colorsR,""+decimalPlaces(cnLevelsR,2,True))   ; Attach labelbar
        if (gg.eq.2) then
           dum = gsn_add_polyline(wks,blank,(/.002,.083333,.083333,.002,.002/),(/.002-b_int,.002-b_int,.998+b_int,.998+b_int,.002-b_int/),polyres)
        end if
        if (gg.ge.3.and.gg.le.12) then
           dum = gsn_add_polyline(wks,blank,(/(gg-2)*.083333,(gg-1)*.083333,(gg-1)*.083333,(gg-2)*.083333,(gg-2)*.083333/),(/.002-b_int,.002-b_int,.998+b_int,.998+b_int,.002-b_int/),polyres)
        end if
        if (gg.eq.13) then
           dum = gsn_add_polyline(wks,blank,(/(gg-2)*.083333,.998,.998,(gg-2)*.083333,(gg-2)*.083333/),(/.002-b_int,.002-b_int,.998+b_int,.998+b_int,.002-b_int/),polyres)
        end if

        getvalues blank
          "vpXF"      : vpx
          "vpYF"      : vpy  ;    Get position and size of the blank plot so we can
          "vpWidthF"  : vpw  ;    be sure to draw the table in same location.
          "vpHeightF" : vph
        end getvalues
        x = (/vpx,vpx+vpw/)
        y = (/vpy-vph,vpy/)
        resT@gsFillColor = fcolorsR(int_s,:)
        if (.not.errmsg) then    ; turn off error messages output from gsn_table if NCL v6.4.0 or older
           err = NhlGetErrorObjectId()
           setvalues err
              "errPrint" : "False"
           end setvalues
        end if
        gsn_table(wks,dimsizes(rmsF),x,y,rmsF(int_s,:),resT)
        if (.not.errmsg) then
           setvalues err
              "errPrint" : "True"
           end setvalues
        end if
        gsn_text_ndc(wks,"RMS Differences",resb@vpXF-title_loc(0),resb@vpYF+title_loc(1),tres)
        if (s_txt.ne."") then
           gsn_text_ndc(wks,"Sorted by: "+s_txt,resb@vpXF-title_loc(2),resb@vpYF+title_loc(3),tres2)
        end if
        draw(blank)
        frame(wks)
        delete([/namesF,rmsF,int_s/])
     end do
     delete(wks)
     fils = systemfunc("ls "+OUTDIR+"table*.png")
     do gg = 0,dimsizes(fils)-1
        system(IM_COMMAND+" "+fils(gg)+" -density 144 -trim +repage -bordercolor white -border 20 -transparent white "+OUTDIR+"metrics.table_"+gg+".gif")  
     end do
     system("rm "+OUTDIR+"table*.png")
  end if
  delete([/patcor_rms,names,nsim/])
  print("Finished: metrics.ncl")
end
