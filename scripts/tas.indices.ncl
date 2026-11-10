; Calculates the tas area averages for the IPCC AR6 reference regions
; (Iturbide et al. 2020), plus global and latitude-band averages.
; Variables used: tas
;
load "$CVDP_SCRIPTS/functions.ncl"
load "$CVDP_SCRIPTS/extract_all_AR6_regions.ncl"

begin
  print("Starting: tas.indices.ncl [Using AR6 regions]")

  CREATE_GRAPHICS  = getenv("CREATE_GRAPHICS")
  PNG_SCALE        = tofloat(getenv("PNG_SCALE"))
  OUTPUT_TYPE      = getenv("OUTPUT_TYPE")
  COLORMAP         = getenv("COLORMAP")
  OUTDIR           = getenv("OUTDIR")
  OPT_CLIMO        = getenv("OPT_CLIMO")
  CLIMO_SYEAR      = toint(getenv("CLIMO_SYEAR"))
  CLIMO_EYEAR      = toint(getenv("CLIMO_EYEAR"))

  nsim = numAsciiRow("namelist_byvar/namelist_trefht")
  na = asciiread("namelist_byvar/namelist_trefht",(/nsim/),"string")
  names = new(nsim,"string")
  paths = new(nsim,"string")
  syear = new(nsim,"integer",-999)
  eyear = new(nsim,"integer",-999)
  delim = "|"

  names_EM = new(nsim,"string")
  EM_num = new(nsim,"integer",-999)

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
  delete(na)
  nEM = max(EM_num)
  modname = str_sub_str(names," ","_")
  bc = (/"/","'","(",")"/)
  do ff = 0,dimsizes(modname)-1
     do gg = 0,dimsizes(bc)-1
        modname(ff) = str_sub_str(modname(ff),bc(gg),"_")
     end do
  end do
  nyr = eyear-syear+1
  nyr_max = max(nyr)

  a = addfile("$CVDP_SCRIPTS/AR6_masks_1x1.nc","r")   ; the first region written is the first mask region,
  AR6_masks = a->AR6_masks                            ; used to detect previously computed simulations
  marker_var = "ipcc_"+str_get_field(AR6_masks@abbrevs(0),1,",")+"_tas"
  delete([/a,AR6_masks/])

;-------------------------------------------------------------------------------------------------
  do ee = 0,nsim-1
     fnt = OUTDIR+modname(ee)+".cvdp_data.tas.indices."+syear(ee)+"-"+eyear(ee)+".nc"
     fnt2 = OUTDIR+modname(ee)+".cvdp_data."+syear(ee)+"-"+eyear(ee)+".nc"
     f_test := read_cvdp_le_data(fnt,fnt2,marker_var)
     if (.not.isatt(f_test,"is_all_missing")) then
        continue
     end if

     tas = data_read_in(paths(ee),"TREFHT",syear(ee),eyear(ee))
     if (isatt(tas,"is_all_missing")) then
        delete(tas)
        continue
     end if

     if (OPT_CLIMO.eq."Full".or.(EM_num(ee).eq.0.and.((CLIMO_SYEAR.ge.0.and.(CLIMO_SYEAR.lt.syear(ee).or.CLIMO_EYEAR.gt.eyear(ee))).or.(CLIMO_SYEAR.lt.0.and.(eyear(ee)+CLIMO_SYEAR).lt.syear(ee))))) then   ; observations not covering the custom climatological period use their full record
        if (OPT_CLIMO.ne."Full") then
           print("Custom climatological period not covered by observational dataset "+names(ee)+" ("+syear(ee)+"-"+eyear(ee)+"): using its full record")
        end if
        climo = clmMonTLL(tas)
        tas = rmMonAnnCycTLL(tas)
     else
        check_custom_climo(names(ee),syear(ee),eyear(ee),CLIMO_SYEAR,CLIMO_EYEAR)
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
     end if
     ; no detrending is applied: the linear trend of each regional index is part of the
     ; diagnostic and is shown on the timeseries plots

     all_region_avgs = extract_all_AR6_regions(tas,False)     ; area averages of the anomalies and of the
     all_region_climos = extract_all_AR6_regions(climo,False) ; annual cycle for every AR6 region
     region_names = all_region_avgs@abbrevs
     long_names = all_region_avgs@region_names

     if (isfilepresent2(fnt)) then
        z = addfile(fnt,"w")
     else
        z = addfile(fnt,"c")
     end if
     set_global_ncfile_attributes(z,names(ee),syear(ee),eyear(ee),getenv("VERSION"))
     date = cd_calendar(tas&time,-1)
     date@long_name = "current date (YYYYMM)"
     if (isatt(date,"calendar")) then
        delete(date@calendar)
     end if
     date!0 = "time"
     date&time = tas&time
     date@units = "1"
     z->date = date
     delete(date)

     do reg_i = 0,dimsizes(region_names)-1
        tas_ind = all_region_avgs(reg_i,:)
        vname = "ipcc_"+region_names(reg_i)+"_tas"
        delete(tas_ind@region_names)
        delete(tas_ind@abbrevs)
        tas_ind@region_abbrev = region_names(reg_i)
        tas_ind@region_name = long_names(reg_i)
        tas_ind@comment = "Area average for "+long_names(reg_i)
        tas_ind@AnnCycle = (/all_region_climos(reg_i,:)/)
        z->$vname$ = set_varAtts(tas_ind,long_names(reg_i)+" area_avgd temperature","","")
        delete([/tas_ind,vname/])
     end do
     delete([/tas,climo,all_region_avgs,all_region_climos,region_names,long_names,z/])
  end do

; the region list for the ensemble means and the plots is taken from the variables actually
; written for the first available simulation, so that it also covers the global/latitude-band extras
  region_names := new(1,string)
  do ee = 0,nsim-1
     fnt = OUTDIR+modname(ee)+".cvdp_data.tas.indices."+syear(ee)+"-"+eyear(ee)+".nc"
     fnt2 = OUTDIR+modname(ee)+".cvdp_data."+syear(ee)+"-"+eyear(ee)+".nc"
     if (isfilepresent2(fnt)) then
        z = addfile(fnt,"r")
     else
        if (isfilepresent2(fnt2)) then
           z = addfile(fnt2,"r")
        else
           continue
        end if
     end if
     vnames = getfilevarnames(z)
     vind := str_match_ind_regex(vnames,"^ipcc_.*_tas$")
     if (.not.ismissing(vind(0))) then
        region_names := str_sub_str(str_sub_str(vnames(vind),"ipcc_",""),"_tas","")
        delete([/vnames,z/])
        break
     end if
     delete([/vnames,z/])
  end do
  if (ismissing(region_names(0))) then
     print("tas.indices.ncl: no regional indices found for any simulation, no output can be created.")
     print("Finished: tas.indices.ncl")
     exit
  end if

  if (nEM.ge.1) then     ; runstyle 2: create ensemble mean outputs from the member files
     do gg = 1,nEM
        emi := ind(EM_num.eq.gg)
        le = dimsizes(emi)-1
        ename = str_sub_str(names_EM(emi(0))," ","_")
        fnts := OUTDIR+modname(emi)+".cvdp_data.tas.indices."+syear(emi)+"-"+eyear(emi)+".nc"
        fnts2 := OUTDIR+modname(emi)+".cvdp_data."+syear(emi)+"-"+eyear(emi)+".nc"
        fno = OUTDIR+ename+"_EM.cvdp_data.tas.indices."+syear(emi(le))+"-"+eyear(emi(le))+".nc"
        zdone = False
        do reg_i = 0,dimsizes(region_names)-1
           vname = "ipcc_"+region_names(reg_i)+"_tas"
           em := read_ensemble_mean(fnts,fnts2,vname)
           if (isatt(em,"is_all_missing")) then
              continue
           end if
           if (.not.zdone) then
              if (isfilepresent2(fno)) then
                 z = addfile(fno,"w")
              else
                 z = addfile(fno,"c")
                 set_global_ncfile_attributes(z,names_EM(emi(0)),syear(emi(le)),eyear(emi(le)),getenv("VERSION"))
              end if
              zdone = True
           end if
           vname_em = vname+"_em"
           z->$vname_em$ = set_varAtts(em,em@long_name+" Ensemble Mean","","")
        end do
        if (zdone) then
           delete(z)
        end if
     end do
  end if

  if (CREATE_GRAPHICS.eq."False") then
     print("Finished: tas.indices.ncl")
     exit
  end if
;===========================================================================================================================================================

  wks_type = OUTPUT_TYPE
  if (wks_type.eq."png") then
     wks_type@wkWidth = 1500*PNG_SCALE
     wks_type@wkHeight = 1500*PNG_SCALE
  end if

  xyres = True
  xyres@gsnDraw = False
  xyres@gsnFrame = False
  xyres@gsnRightString = ""
  xyres@gsnLeftString = ""
  xyres@gsnYRefLine = 0.0
  xyres@gsnYRefLineColor = "gray42"
  xyres@xyLineColor = "gray62"
  xyres@gsnXYAboveFillColors = "red"
  xyres@gsnXYBelowFillColors = "blue"
  if (OUTPUT_TYPE.eq."png") then
     xyres@xyLineThicknessF = .75
  else
     xyres@xyLineThicknessF = .5
  end if
  xyres@tiYAxisString = ""
  if (nsim.le.5) then
     xyres@tmXBLabelFontHeightF = 0.0125
     xyres@tmYLLabelFontHeightF = 0.0125
     xyres@gsnLeftStringFontHeightF = 0.017
     xyres@gsnCenterStringFontHeightF = 0.017
     xyres@gsnRightStringFontHeightF = 0.013
  else
     xyres@tmXBLabelFontHeightF = 0.018
     xyres@tmYLLabelFontHeightF = 0.018
     xyres@gsnLeftStringFontHeightF = 0.024
     xyres@gsnCenterStringFontHeightF = 0.024
     xyres@gsnRightStringFontHeightF = 0.020
  end if
  xyres@vpHeightF = 0.3
  xyres@vpWidthF = 0.9
  xyres@gsnCenterString = ""
  xyres@tiMainOn = False
  xyres@gsnLeftStringOrthogonalPosF = 0.025
  xyres@gsnCenterStringOrthogonalPosF = xyres@gsnLeftStringOrthogonalPosF
  xyres@gsnRightStringOrthogonalPosF = xyres@gsnLeftStringOrthogonalPosF

  ncol = floattointeger(sqrt(nsim))
  nrow = (nsim/ncol)+mod(nsim,ncol)
  if (nsim.le.12) then
     lp = (/nsim,1/)
  else
     lp = (/nrow,ncol/)
  end if
  panres = True
  panres@gsnMaximize = True
  panres@gsnPaperOrientation = "portrait"
  panres@gsnPanelYWhiteSpacePercent = 3.0
  if (nsim.le.10) then
     panres@txFontHeightF = 0.016
  else
     panres@txFontHeightF = 0.012
  end if

  do reg_i = 0,dimsizes(region_names)-1
     vname = "ipcc_"+region_names(reg_i)+"_tas"
     wks_reg = gsn_open_wks(wks_type,OUTDIR+vname+".timeseries")
     xy_reg = new(nsim,"graphic")
     envelope = new(nsim,"graphic")
     title = vname

     do ee = 0,nsim-1
        fnt = OUTDIR+modname(ee)+".cvdp_data.tas.indices."+syear(ee)+"-"+eyear(ee)+".nc"
        fnt2 = OUTDIR+modname(ee)+".cvdp_data."+syear(ee)+"-"+eyear(ee)+".nc"
        tas_ind := read_cvdp_le_data(fnt,fnt2,vname)
        if (isatt(tas_ind,"is_all_missing")) then
           continue
        end if
        if (isatt(tas_ind,"comment")) then
           title = tas_ind@comment
        end if
        xyres@trXMinF = syear(ee)-.5
        xyres@trXMaxF = eyear(ee)+1.5
        xyres@gsnLeftString = names(ee)
        plot_index_timeseries(wks_reg,fspan(syear(ee),eyear(ee)+.91667,dimsizes(tas_ind)),tas_ind,12,"lightgoldenrod1",xyres,xy_reg,envelope,ee)
     end do

     if (.not.all(ismissing(xy_reg))) then
        panres@txString = title
        gsn_panel2(wks_reg,xy_reg,lp,panres)
     end if
     delete([/wks_reg,xy_reg,envelope,title,vname/])
  end do
  print("Finished: tas.indices.ncl")
end
