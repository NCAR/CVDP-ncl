; Calculates the monsoon rainfall, using either the AR6 definitions (IPCC WG1 AR6 Annex V)
; or AR5 definitions. This is somewhat of a replicate of the ESMValTool monsoon routine,
; with some slightly different assumptions about variability.
; Variables used: pr
;
load "$CVDP_SCRIPTS/functions.ncl"

begin
  AR6_DEFS=True ;True uses the regions defined by Iturbide et al (2020)

  if AR6_DEFS then
    ; This uses the domains outlined in Cherchi et al (2021, IPCC WG1 AR6 Annex V)
    ; The inclusion criteria is that the "annual range (local summer minus local winter) of precipitation is greater than 2.5 mm day-1 (Kitoh et al., 2013)"
    ; The masks are some odd shapes (and also only defined over land), and need to read in from a file
    ; Equatorial America and Southern Africa are included despite not being proper monsoon regions
    print("Starting: monsoon.ncl [Using AR6 Definitions]")
  else
    ; This uses the "global monsoon domain" of Wang et al. (2011).
    ; The inclusion criteria is that 55% of rain falls in summer, and that the summer rainfall is 2mm/day greater than the winter rainfall
    ; All of the boxes are rectangles, but only defined over land
    print("Starting: monsoon.ncl [Using AR5 Definitions]")
  end if

  CREATE_GRAPHICS  = getenv("CREATE_GRAPHICS")
  PNG_SCALE        = tofloat(getenv("PNG_SCALE"))
  OUTPUT_TYPE      = getenv("OUTPUT_TYPE")
  COLORMAP         = getenv("COLORMAP")
  OUTDIR           = getenv("OUTDIR")
  OPT_CLIMO        = getenv("OPT_CLIMO")
  CLIMO_SYEAR      = toint(getenv("CLIMO_SYEAR"))
  CLIMO_EYEAR      = toint(getenv("CLIMO_EYEAR"))

  nsim = numAsciiRow("namelist_byvar/namelist_prect")
  na = asciiread("namelist_byvar/namelist_prect",(/nsim/),"string")
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
  pi=4.*atan(1.0)

  d = addfile("$NCARG_ROOT/lib/ncarg/data/cdf/landsea.nc","r")   ; prepare land mask (the
  basemap = d->LSMASK                                            ; named monsoon domains are
  delete(d)                                                      ; only defined over land)

  if AR6_DEFS then
     a = addfile("$CVDP_SCRIPTS/AR6_masks_1x1.nc","r")
     AR6_masks = a->AR6_monsoons
     domain_names = AR6_masks@abbrevs
     domain_longnames = AR6_masks@monsoon_names
     domain_numbers = AR6_masks@number
     delete(a)
  else
     ;Set up the variables to define the separate monsoons.
     ;Not as easy as you'd think as NAF crosses Greenwich and EAS is cut out of SAS.
     domain_names=(/"NAMS","SAMS","NAF","SAF","SAS","EAS","AUSMC"/)
     domain_lats=(/(/0.,40./),(/-40.,0./),(/0.,40./),(/-40.,0./),(/0.,40./),(/20.,40./),(/-40.,0./)/)
     domain_lons=(/(/240.,300./),(/270.,330./),(/-30.,60./),(/0.,60./),(/60.,150./),(/60.,150./),(/90.,150./)/)
  end if

;-------------------------------------------------------------------------------------------------
  do ee = 0,nsim-1
     fnt = OUTDIR+modname(ee)+".cvdp_data.monsoon."+syear(ee)+"-"+eyear(ee)+".nc"
     fnt2 = OUTDIR+modname(ee)+".cvdp_data."+syear(ee)+"-"+eyear(ee)+".nc"
     f_test := read_cvdp_le_data(fnt,fnt2,"monsoon_domain")
     if (.not.isatt(f_test,"is_all_missing")) then
        continue
     end if

     pr = data_read_in(paths(ee),"PRECT",syear(ee),eyear(ee))
     if (isatt(pr,"is_all_missing")) then
        delete(pr)
        continue
     end if

     if (OPT_CLIMO.eq."Full".or.(EM_num(ee).eq.0.and.((CLIMO_SYEAR.ge.0.and.(CLIMO_SYEAR.lt.syear(ee).or.CLIMO_EYEAR.gt.eyear(ee))).or.(CLIMO_SYEAR.lt.0.and.(eyear(ee)+CLIMO_SYEAR).lt.syear(ee))))) then   ; observations not covering the custom climatological period use their full record
        if (OPT_CLIMO.ne."Full") then
           print("Custom climatological period not covered by observational dataset "+names(ee)+" ("+syear(ee)+"-"+eyear(ee)+"): using its full record")
        end if
        climo_pr = clmMonTLL(pr)
     else
        check_custom_climo(names(ee),syear(ee),eyear(ee),CLIMO_SYEAR,CLIMO_EYEAR)
        temp_arr = pr
        delete(temp_arr&time)
        temp_arr&time = cd_calendar(pr&time,-1)
        if (CLIMO_SYEAR.lt.0) then
           climo_pr = clmMonTLL(temp_arr({(eyear(ee)+CLIMO_SYEAR)*100+1:(eyear(ee)+CLIMO_EYEAR)*100+12},:,:))
        else
           climo_pr = clmMonTLL(temp_arr({CLIMO_SYEAR*100+1:CLIMO_EYEAR*100+12},:,:))
        end if
        delete(temp_arr)
     end if

     coswgt=NormCosWgtGlobe(pr&lat)
     coswgt!0="lat"
     coswgt&lat=pr&lat
     area=climo_pr(0,:,:)                     ;set up array with lat/lon metadata
     area=(/conform(area,tofloat(coswgt),0)/)
     area=area*(4*pi*6371.22^2)/sum(area)     ;results in area of grid boxes in km^2

     if (isfilepresent2(fnt)) then
        z = addfile(fnt,"w")
     else
        z = addfile(fnt,"c")
     end if
     set_global_ncfile_attributes(z,names(ee),syear(ee),eyear(ee),getenv("VERSION"))

     ;Now calculate the climatological global monsoon domain for plotting
     climo_Annual=dim_avg_n_Wrap(climo_pr,0)
     climo_MJJAS=dim_avg_n_Wrap(climo_pr(4:8,:,:),0)
     climo_NDJFM=climo_MJJAS
     climo_NDJFM=(/dim_avg_n((/climo_pr(0,:,:),climo_pr(1,:,:),climo_pr(2,:,:),\
             climo_pr(10,:,:),climo_pr(11,:,:)/),0)/)
     climo_summer=climo_MJJAS
     climo_summer({-90:0},:) = climo_NDJFM({-90:0},:)
     climo_winter=climo_NDJFM
     climo_winter({-90:0},:) = climo_MJJAS({-90:0},:)
     ;calculate the rain falling during the monsoon (i.e. pr_summer in monsoon domain)
     monsoon_domain=climo_summer
     if AR6_DEFS then
        monsoon_domain=where(((climo_summer-climo_winter).gt.2.5),climo_summer,climo_summer@_FillValue)
        z->monsoon_domain=set_varAtts(monsoon_domain,"Monsoon domain's rainfall","mm/day","climatology, after IPCC WG1 AR6 Annex V")
        delete([/climo_Annual,climo_MJJAS,climo_NDJFM,climo_summer,climo_winter,monsoon_domain,climo_pr/])
     else
        climo_intensity=climo_Annual
        climo_intensity=climo_summer-climo_winter
        monsoon_domain=where((climo_summer.gt.climo_Annual*0.55).and.(climo_intensity.gt.2),climo_summer,climo_summer@_FillValue)
        z->monsoon_domain=set_varAtts(monsoon_domain,"Monsoon domain's rainfall","mm/day","climatology, after IPCC AR5 Fig 14.1a")
        z->monsoon_intensity=set_varAtts(climo_intensity,"Seasonal rainfall intensity (summer-winter)","mm/day","climatology [used to calculated global monsoon domain]")
        z->monsoon_summer_rainrate=set_varAtts(climo_summer,"Summer (MJJAS) rainfall intensity","mm/day","climatology [used to calculated global monsoon domain]")
        delete([/climo_Annual,climo_MJJAS,climo_NDJFM,climo_summer,climo_winter,climo_intensity,monsoon_domain,climo_pr/])
     end if

     ; Now create some monsoon timeseries.
     ; Firstly need create the necessary fields to define monsoon rainfall (interannually)
     ; Using "USGS water years" of Nov-Oct. This means we lose a year from the front in the SH (as the ND do not exist for the first instance)
     ; [This wasn't a problem for the climatology, as we're effectively replaced the missing ND with
     ;  the climatological value: the difference is negligible and easier to code and compute].
     pr_ann_jandec=month_to_annual(pr,1)      ;use this routine to create an annual field with appropriate metadata
     pr_ann_jandec=(/pr_ann_jandec@_FillValue/)
     Annual=pr_ann_jandec
     NDJFM=pr_ann_jandec
     MJJAS=pr_ann_jandec
     f_yr=dimsizes(pr&time)-1                 ;final year of dataset
     pu_yr=dimsizes(pr&time)-13               ;penultimate year of dataset
     Annual(1:,:,:)=(/dim_avg_n_Wrap((/pr(10:pu_yr:12,:,:),pr(11:pu_yr:12,:,:),pr(12:f_yr:12,:,:),\
             pr(13:f_yr:12,:,:),pr(14:f_yr:12,:,:),pr(15:f_yr:12,:,:),\
             pr(16:f_yr:12,:,:),pr(17:f_yr:12,:,:),pr(18:f_yr:12,:,:),\
             pr(19:f_yr:12,:,:),pr(20:f_yr:12,:,:),pr(21:f_yr:12,:,:)/),0)/)
     NDJFM(1:,:,:)=(/dim_avg_n((/pr(10:pu_yr:12,:,:),pr(11:pu_yr:12,:,:),pr(12:f_yr:12,:,:),\
             pr(13:f_yr:12,:,:),pr(14:f_yr:12,:,:)/),0)/)
     MJJAS(1:,:,:)=(/dim_avg_n_Wrap((/pr(16::12,:,:),pr(17::12,:,:),pr(18::12,:,:),\
             pr(19::12,:,:),pr(20::12,:,:)/),0)/)
     pr_summer=MJJAS
     pr_summer(:,{-90:0},:) = NDJFM(:,{-90:0},:)   ;move from pure calendar years into NH/SH summers
     pr_winter=NDJFM
     pr_winter(:,{-90:0},:) = MJJAS(:,{-90:0},:)
     intensity=pr_summer-pr_winter
     ;calculate the rain falling during the monsoon (i.e. pr_summer in monsoon domain)
     monsoonrain=pr_summer
     monsoonarea=pr_ann_jandec
     if AR6_DEFS then
        monsoonrain=where(intensity.gt.2.5,pr_summer,pr_summer@_FillValue)
        monsoonarea=where(intensity.gt.2.5,conform(pr_ann_jandec,area,(/1,2/)),0)
     else
        monsoonrain=where((pr_summer.gt.Annual*0.55).and.(intensity.gt.2),pr_summer,pr_summer@_FillValue)
        monsoonarea=where((pr_summer.gt.Annual*0.55).and.(intensity.gt.2),conform(pr_ann_jandec,area,(/1,2/)),0)
     end if                                   ;Now I can create timeseries of monsoon area and rainfall every year
     delete([/pr_ann_jandec,Annual,NDJFM,MJJAS,pr_summer,pr_winter,intensity,f_yr,pu_yr/])

     ;write out the global monsoon timeseries to file
     TIME=ispan(syear(ee),eyear(ee),1)
     TIME@units="YYYY"
     TIME@long_name = "time"
     monsoon_area_global=dim_sum_n_Wrap(monsoonarea,(/1,2/))
     monsoon_area_global!0 = "TIME"
     monsoon_area_global&TIME = TIME
     z->monsoon_area_global=set_varAtts(monsoon_area_global,"Area of global monsoon domain","km2","Calculated after IPCC AR5 Fig 14.1a, but for each water year (i.e. Nov-Oct, labelled for end date)")
     monsoon_rain_global=wgt_areaave_Wrap(monsoonrain,coswgt,1.0,0)
     monsoon_rain_global!0 = "TIME"
     monsoon_rain_global&TIME = TIME
     z->monsoon_rain_global=set_varAtts(monsoon_rain_global,"rainfall over global monsoon domain","mm/day","averaged over summer for each water year (i.e. Nov-Oct, labelled for end date). After IPCC AR5 Fig 14.1a, but with annually varying domain.")
     delete([/monsoon_area_global,monsoon_rain_global/])

     ;The named monsoon domains are only defined over land...
     lsm = landsea_mask(basemap,pr&lat,pr&lon)
     monsoonrain = mask(monsoonrain,conform(monsoonrain,lsm,(/1,2/)).ne.1,False)
     monsoonarea = mask(monsoonarea,conform(monsoonarea,lsm,(/1,2/)).ne.1,False)
     delete(lsm)

     if AR6_DEFS then
        region_mask=landsea_mask(AR6_masks,pr&lat,pr&lon)   ;convert the monsoon region masks to this grid
        do reg_i=0,dimsizes(domain_names)-1
           this_rain=mask(monsoonrain,conform(monsoonrain,region_mask,(/1,2/)).eq.domain_numbers(reg_i),True)
           this_area=mask(monsoonarea,conform(monsoonarea,region_mask,(/1,2/)).eq.domain_numbers(reg_i),True)
           monsoon_area_ts=dim_sum_n_Wrap(this_area,(/1,2/))
           monsoon_area_ts!0 = "TIME"
           monsoon_area_ts&TIME = TIME
           monsoon_rain_ts=wgt_areaave_Wrap(this_rain,coswgt,1.0,0)
           monsoon_rain_ts!0 = "TIME"
           monsoon_rain_ts&TIME = TIME
           varname="monsoon_rain_"+domain_names(reg_i)
           z->$varname$ = set_varAtts(monsoon_rain_ts,"rainfall over "+domain_names(reg_i)+" domain","mm/day","averaged over summer for each water year (i.e. Nov-Oct, labelled for end date). After IPCC WG1 AR6 Annex V, but with annually varying domain.")
           varname="monsoon_area_"+domain_names(reg_i)
           z->$varname$=set_varAtts(monsoon_area_ts,"Area of "+domain_names(reg_i)+" monsoon domain","km2","Calculated after IPCC WG1 AR6 Annex V, but for each water year (i.e. Nov-Oct, labelled for end date)")
           delete([/this_rain,this_area,monsoon_area_ts,monsoon_rain_ts,varname/])
        end do
        delete(region_mask)
     else
        ;then loop over the actual monsoon domains. Taking area and averaged rain rate
        do reg_i=0,dimsizes(domain_names)-1
           if domain_names(reg_i).eq."SAS" then
              this_rain=monsoonrain(:,{domain_lats(reg_i,0):domain_lats(reg_i,1)},{domain_lons(reg_i,0):domain_lons(reg_i,1)})
              this_area=monsoonarea(:,{domain_lats(reg_i,0):domain_lats(reg_i,1)},{domain_lons(reg_i,0):domain_lons(reg_i,1)})
              SAS_mask=this_rain(0,:,:)
              SAS_mask=(/1/)
              SAS_mask({domain_lats(reg_i+1,0):},{domain_lons(reg_i+1,0):})=(/0/)
              this_rain=mask(this_rain,conform(this_rain,SAS_mask,(/1,2/)).eq.0,False)
              this_area=mask(this_area,conform(this_area,SAS_mask,(/1,2/)).eq.0,False)
              delete(SAS_mask)
           else
              if domain_names(reg_i).eq."NAF" then
                 ;NAF crosses Greenwich Meridian, so needs a lonFlip
                 tmp_rain=lonFlip(monsoonrain)
                 tmp_area=lonFlip(monsoonarea)
                 this_rain=tmp_rain(:,{domain_lats(reg_i,0):domain_lats(reg_i,1)},{domain_lons(reg_i,0):domain_lons(reg_i,1)})
                 this_area=tmp_area(:,{domain_lats(reg_i,0):domain_lats(reg_i,1)},{domain_lons(reg_i,0):domain_lons(reg_i,1)})
                 delete([/tmp_rain,tmp_area/])
              else
                 this_rain=monsoonrain(:,{domain_lats(reg_i,0):domain_lats(reg_i,1)},{domain_lons(reg_i,0):domain_lons(reg_i,1)})
                 this_area=monsoonarea(:,{domain_lats(reg_i,0):domain_lats(reg_i,1)},{domain_lons(reg_i,0):domain_lons(reg_i,1)})
              end if
           end if
           this_coswgt=coswgt({domain_lats(reg_i,0):domain_lats(reg_i,1)})
           monsoon_area_ts=dim_sum_n_Wrap(this_area,(/1,2/))
           monsoon_area_ts!0 = "TIME"
           monsoon_area_ts&TIME = TIME
           monsoon_rain_ts=wgt_areaave_Wrap(this_rain,this_coswgt,1.0,0)
           monsoon_rain_ts!0 = "TIME"
           monsoon_rain_ts&TIME = TIME
           varname="monsoon_rain_"+domain_names(reg_i)
           z->$varname$ = set_varAtts(monsoon_rain_ts,"rainfall over "+domain_names(reg_i)+" domain","mm/day","averaged over summer for each water year (i.e. Nov-Oct, labelled for end date). After IPCC AR5 Fig 14.3, but with annually varying domain.")
           varname="monsoon_area_"+domain_names(reg_i)
           z->$varname$=set_varAtts(monsoon_area_ts,"Area of "+domain_names(reg_i)+" monsoon domain","km2","Calculated after IPCC AR5 Fig 14.1a and Fig 14.3, but for each water year (i.e. Nov-Oct, labelled for end date)")
           delete([/this_coswgt,this_rain,this_area,monsoon_area_ts,monsoon_rain_ts,varname/])
        end do
     end if
     delete([/pr,coswgt,area,monsoonrain,monsoonarea,z,TIME/])
  end do

  if (nEM.ge.1) then     ; runstyle 2: create ensemble mean outputs from the member files
     emvars = array_append_record((/"monsoon_domain","monsoon_rain_global","monsoon_area_global"/), \
                                  array_append_record("monsoon_rain_"+domain_names,"monsoon_area_"+domain_names,0),0)
     do gg = 1,nEM
        emi := ind(EM_num.eq.gg)
        le = dimsizes(emi)-1
        ename = str_sub_str(names_EM(emi(0))," ","_")
        fnts := OUTDIR+modname(emi)+".cvdp_data.monsoon."+syear(emi)+"-"+eyear(emi)+".nc"
        fnts2 := OUTDIR+modname(emi)+".cvdp_data."+syear(emi)+"-"+eyear(emi)+".nc"
        fno = OUTDIR+ename+"_EM.cvdp_data.monsoon."+syear(emi(le))+"-"+eyear(emi(le))+".nc"
        zdone = False
        do vv = 0,dimsizes(emvars)-1
           em := read_ensemble_mean(fnts,fnts2,emvars(vv))
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
           vname_em = emvars(vv)+"_em"
           z->$vname_em$ = set_varAtts(em,em@long_name+" Ensemble Mean","","")
        end do
        if (zdone) then
           delete(z)
        end if
     end do
     delete(emvars)
  end if

  if (CREATE_GRAPHICS.eq."False") then
     print("Finished: monsoon.ncl")
     exit
  end if
;===========================================================================================================================================================
  wks_type = OUTPUT_TYPE
  if (wks_type.eq."png") then
     wks_type@wkWidth = 1500*PNG_SCALE
     wks_type@wkHeight = 1500*PNG_SCALE
  end if

  ;First plot the global monsoon domains on a map
  wks_domain=gsn_open_wks(wks_type,OUTDIR+"global_monsoon_domain")
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
  if (OUTPUT_TYPE.eq."png") then
     res@mpGeophysicalLineThicknessF = 2.
  else
     res@mpGeophysicalLineThicknessF = 1.
  end if
  res@gsnDraw      = False
  res@gsnFrame     = False
  res@cnLineLabelsOn = False
  res@cnFillOn        = True
  res@cnLinesOn       = False
  res@lbLabelBarOn    = False
  res@cnLevelSelectionMode = "ExplicitLevels"
  res@gsnLeftStringOrthogonalPosF = -0.05
  res@gsnLeftStringParallelPosF = .005
  res@gsnRightStringOrthogonalPosF = -0.05
  res@gsnRightStringParallelPosF = 0.96
  res@gsnRightString = ""
  res@gsnLeftString = ""
  res@gsnLeftStringFontHeightF = 0.014
  res@gsnCenterStringFontHeightF = 0.018
  res@gsnRightStringFontHeightF = 0.014
  res@cnLevels  = (/0.5,1,2,3,4,5,6,7,8,9,10,12,14,16,18/)
  if (COLORMAP.eq."0") then
     res@cnFillPalette = "precip3_16lev"
  else
     res@cnFillPalette = "BlueDarkRed18"
  end if

  map_domains = new(nsim,"graphic")
  do ee = 0,nsim-1
     fnt = OUTDIR+modname(ee)+".cvdp_data.monsoon."+syear(ee)+"-"+eyear(ee)+".nc"
     fnt2 = OUTDIR+modname(ee)+".cvdp_data."+syear(ee)+"-"+eyear(ee)+".nc"
     monsoon_domain := read_cvdp_le_data(fnt,fnt2,"monsoon_domain")
     if (isatt(monsoon_domain,"is_all_missing")) then
        continue
     end if
     res@gsnLeftString = syear(ee)+"-"+eyear(ee)
     res@gsnRightString = monsoon_domain@units
     res@gsnCenterString = names(ee)
     map_domains(ee)=gsn_csm_contour_map(wks_domain,monsoon_domain,res)
  end do
  panres = True
  panres@gsnMaximize = True
  panres@gsnPaperOrientation = "portrait"
  panres@gsnPanelLabelBar = True
  panres@gsnPanelYWhiteSpacePercent = 3.0
  panres@pmLabelBarHeightF = 0.05
  panres@pmLabelBarWidthF = 0.65
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
  panres@lbLabelFontHeightF = 0.013
  panres@lbLabelStride = 1
  ncol = floattointeger(sqrt(nsim))
  nrow = (nsim/ncol)+mod(nsim,ncol)
  panres@txString = "Global Monsoon Rainfall"
  gsn_panel2(wks_domain,map_domains,(/nrow,ncol/),panres)
  delete([/wks_domain,map_domains,panres,res/])

  if (nEM.ge.1) then     ; runstyle 2: ensemble summary figure (EM / reference / difference / rank)
     domlev := (/0.5,1,2,3,4,5,6,7,8,9,10,12,14,16,18/)
     if (COLORMAP.eq."0") then
        dompal = "precip3_16lev"
        domdifpal = "MPL_RdYlGn"
     else
        dompal = "BlueDarkRed18"
        domdifpal = "BlueDarkRed18"
     end if
     domdiflev := (/-8.,-6,-4,-2,-1,-0.5,0.,0.5,1,2,4,6,8/)
     ensemble_summary_figure("monsoon_domain","monsoon.", \
            OUTDIR+modname+".cvdp_data.monsoon."+syear+"-"+eyear+".nc", \
            OUTDIR+modname+".cvdp_data."+syear+"-"+eyear+".nc", \
            names,syear,eyear,paths,names_EM,EM_num,nEM,domlev,dompal,domdiflev,domdifpal,"Global Monsoon Rainfall",wks_type)
     delete([/domlev,domdiflev/])
  end if

;;;;Now plot the timeseries: one figure per (rain rate | area) x (global + each domain)
  xyres = True
  xyres@gsnDraw = False
  xyres@gsnFrame = False
  xyres@gsnRightString = ""
  xyres@gsnLeftString = ""
  xyres@gsnYRefLine = 0.0
  xyres@gsnYRefLineColor = "gray42"
  xyres@xyLineColor = "gray62"
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
  xyres@gsnXYAboveFillColors = "aquamarine4"
  xyres@gsnXYBelowFillColors = "peru"

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

  kinds = (/"rain","area"/)
  do kk = 0,dimsizes(kinds)-1
     do plot_i = 0,dimsizes(domain_names)
        if (plot_i.eq.0) then
           vname = "monsoon_"+kinds(kk)+"_global"
           if (kinds(kk).eq."rain") then
              vtitle = "Average summer rainfall over global monsoon domain (mm/day)"
           else
              vtitle = "Area of global monsoon domain (km2)"
           end if
        else
           vname = "monsoon_"+kinds(kk)+"_"+domain_names(plot_i-1)
           if (kinds(kk).eq."rain") then
              vtitle = "Average monsoon rainfall over "+domain_names(plot_i-1)+" domain (mm/day)"
           else
              vtitle = "Area of "+domain_names(plot_i-1)+" monsoon domain (km2)"
           end if
        end if
        wks_ts = gsn_open_wks(wks_type,OUTDIR+vname+".timeseries")
        xy_ts = new(nsim,"graphic")
        envelope = new(nsim,"graphic")
        do ee = 0,nsim-1
           fnt = OUTDIR+modname(ee)+".cvdp_data.monsoon."+syear(ee)+"-"+eyear(ee)+".nc"
           fnt2 = OUTDIR+modname(ee)+".cvdp_data."+syear(ee)+"-"+eyear(ee)+".nc"
           ts := read_cvdp_le_data(fnt,fnt2,vname)
           if (isatt(ts,"is_all_missing")) then
              continue
           end if
           xyres@trXMinF = syear(ee)-.5
           xyres@trXMaxF = eyear(ee)+1.5
           xyres@gsnLeftString = names(ee)
           plot_index_timeseries(wks_ts,ts&TIME,ts,1,"lightskyblue1",xyres,xy_ts,envelope,ee)
        end do
        if (.not.all(ismissing(xy_ts))) then
           panres@txString = vtitle
           gsn_panel2(wks_ts,xy_ts,lp,panres)
        end if
        delete([/wks_ts,xy_ts,envelope,vname,vtitle/])
     end do
  end do
  print("Finished: monsoon.ncl")
end
