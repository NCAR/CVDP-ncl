; Calculates monthly SO index, regression pattern
;
; Variables used: psl
;
load "$CVDP_SCRIPTS/functions.ncl"

begin
  print("Starting: soi.ncl")
  CREATE_GRAPHICS  = getenv("CREATE_GRAPHICS")  
  PNG_SCALE        = tofloat(getenv("PNG_SCALE"))
  OUTPUT_TYPE      = getenv("OUTPUT_TYPE") 
  COLORMAP         = getenv("COLORMAP")
  OUTDIR           = getenv("OUTDIR") 
  PNG_SCALE_SUMMARY = tofloat(getenv("PNG_SCALE_SUMMARY"))
  REMOVE_TREND_OBS = getenv("REMOVE_TREND_OBS") 
  REMOVE_TREND_MODEL = getenv("REMOVE_TREND_MODEL") 
  ENSEMBLE_MEAN_DIR = getenv("ENSEMBLE_MEAN_DIR")
  MONTHLY_MODES = getenv("MONTHLY_MODES")
  IM_COMMAND = getenv("IM_COMMAND")
  
  nsim = numAsciiRow("namelist_byvar/namelist_psl")

  na = asciiread("namelist_byvar/namelist_psl",(/nsim/),"string")
  names = new(nsim,"string")
  paths = new(nsim,"string")
  syear = new(nsim,"integer",-999)
  eyear = new(nsim,"integer",-999)
  names_EM = new(nsim,"string")
  EM_num = new(nsim,"integer",-999)
  delim = "|"

  do ee = 0,nsim-1
     names(ee) = str_strip(str_get_field(na(ee),1,delim))
     paths(ee) = str_strip(str_get_field(na(ee),2,delim))
     syear(ee) = stringtointeger(str_strip(str_get_field(na(ee),3,delim)))
     eyear(ee) = stringtointeger(str_strip(str_get_field(na(ee),4,delim)))
     temp      = str_split(str_strip(str_get_field(na(ee),5,delim)),"-")
     temp2     = tochar(str_strip(str_get_field(na(ee),5,delim)))
     if (tostring(temp2(0)).eq."-") then
        EM_num(ee)    = toint(temp(0))*-1
     else
        EM_num(ee)    = toint(temp(0))
     end if
     names_EM(ee)  = str_join(temp(1:),"-")
     delete([/temp,temp2/])
  end do
  modname = str_sub_str(names," ","_")
  bc = (/"/","'","(",")"/)
  do ff = 0,dimsizes(modname)-1
     do ee = 0,dimsizes(bc)-1
        modname(ff) = str_sub_str(modname(ff),bc(ee),"_")
     end do
  end do
  nyr = eyear-syear+1
  nyr_max = max(nyr)
  nEM = max(EM_num)
  nEMm = min(EM_num)
  numobs = num(EM_num.eq.0) 
;--------------------------------------------------------------
  do ee = 0,nsim-1    ; compute SOI
     fnt = getenv("OUTDIR")+modname(ee)+".cvdp_data.so."+syear(ee)+"-"+eyear(ee)+".nc"
     fnt2 = getenv("OUTDIR")+modname(ee)+".cvdp_data."+syear(ee)+"-"+eyear(ee)+".nc"
     f_test := read_cvdp_le_data(fnt,fnt2,"so_pattern_ann")
     if (.not.isatt(f_test,"is_all_missing")) then
        continue
     end if
     arr = data_read_in(paths(ee),"PSL",syear(ee),eyear(ee))    ; read in data, orient lats/lons correctly, set time coordinate variable up
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
           arr = remove_trend(arr,REMOVE_TREND_MODEL,ensemble_mean_read_in(arr,ENSEMBLE_MEAN_DIR+str_sub_str(names_EM(ee)," ","_"),EM_num(ee),"PSL",syear,eyear,EM_num))
        end if
     end if
     if (isatt(arr,"is_all_missing")) then
        delete(arr)
        continue
     end if

     arr_west := calculate_areaavg(arr,-30,0,70,170)
     arr_east := calculate_areaavg(arr,-30,0,200,280)
     soi := (/ arr_west - arr_east /)
     soi@units = arr@units
     soi@detrend_option = arr@detrend_option
     soi!1 = "TIME"
     soi&TIME = ispan(syear(ee),eyear(ee),1)
     soi&TIME@units = "YYYY"
     soi&TIME@long_name = "time"
     soi&TIME@standard_name = "time"
     soi&TIME@calendar = "standard"

     arr_3mo := runave_n_Wrap(arr,3,0,0)
     arr_3mo(0,:,:) = (/ dim_avg_n(arr(:1,:,:),0) /)
     arr_12mo := runave_n_Wrap(arr,12,0,0)
     finarr := arr(:6,:,:)
     finarr = finarr@_FillValue
     finarr@units = "hPa/hPa"
     si = (/0,1,3,6,7,9/)
     do hh = 0,5
        finarr(hh,:,:) = (/ regCoef_n(soi(hh,:),arr_3mo(si(hh)::12,:,:),0,0) /)
     end do
     finarr(6,:,:) = (/ regCoef_n(soi(6,:),arr_12mo(5::12,:,:),0,0) /)
     
     z = addfile(fnt,"c")
     set_global_ncfile_attributes(z,names(ee),syear(ee),eyear(ee),getenv("VERSION"))

     z->$(/"so_timeseries_djf"/)$ = set_varAtts(soi(0,:),"Southern Oscillation Index (DJF)","","")
     z->$(/"so_timeseries_jfm"/)$ = set_varAtts(soi(1,:),"Southern Oscillation Index (JFM)","","")
     z->$(/"so_timeseries_mam"/)$ = set_varAtts(soi(2,:),"Southern Oscillation Index (MAM)","","")
     z->$(/"so_timeseries_jja"/)$ = set_varAtts(soi(3,:),"Southern Oscillation Index (JJA)","","")
     z->$(/"so_timeseries_jas"/)$ = set_varAtts(soi(4,:),"Southern Oscillation Index (JAS)","","")
     z->$(/"so_timeseries_son"/)$ = set_varAtts(soi(5,:),"Southern Oscillation Index (SON)","","")
     z->$(/"so_timeseries_ann"/)$ = set_varAtts(soi(6,:),"Southern Oscillation Index (ANN)","","")
     z->$(/"so_pattern_djf"/)$    = set_varAtts(finarr(0,:,:),"Southern Oscillation spatial pattern (DJF)","","")
     z->$(/"so_pattern_jfm"/)$    = set_varAtts(finarr(1,:,:),"Southern Oscillation spatial pattern (JFM)","","")
     z->$(/"so_pattern_mam"/)$    = set_varAtts(finarr(2,:,:),"Southern Oscillation spatial pattern (MAM)","","")
     z->$(/"so_pattern_jja"/)$    = set_varAtts(finarr(3,:,:),"Southern Oscillation spatial pattern (JJA)","","")
     z->$(/"so_pattern_jas"/)$    = set_varAtts(finarr(4,:,:),"Southern Oscillation spatial pattern (JAS)","","")
     z->$(/"so_pattern_son"/)$    = set_varAtts(finarr(5,:,:),"Southern Oscillation spatial pattern (SON)","","")
     z->$(/"so_pattern_ann"/)$    = set_varAtts(finarr(6,:,:),"Southern Oscillation spatial pattern (ANN)","","")
     delete([/soi,arr_3mo,arr_12mo,arr_west,arr_east/])

     if (MONTHLY_MODES.eq."True")then
        pi = 4.*atan(1.0)
        rad = (pi/180.)
        coswgt:=cos(rad*arr&lat)
        coswgt!0 = "lat"
        coswgt&lat= arr&lat
        arr_west_mon = wgt_areaave(arr(:,{-30:0},{70:170}),coswgt({-30:0}),1.0,0)
        arr_east_mon = wgt_areaave(arr(:,{-30:0},{200:280}),coswgt({-30:0}),1.0,0)
        soi_mon = (/ arr_west_mon - arr_east_mon /)
        soi_mon!0 = "time"
        soi_mon&time = arr&time
        soi_mon@detrend_option = arr@detrend_option
        finarr_mon = regCoef_n(soi_mon,arr,0,0)
        copy_VarMeta(arr(0,:,:),finarr_mon)
        finarr_mon@units = "hPa/hPa"
        z->$(/"so_timeseries_mon"/)$ = set_varAtts(soi_mon,"Southern Oscillation Index (mon)","","")
        z->$(/"so_pattern_mon"/)$    = set_varAtts(finarr_mon,"Southern Oscillation spatial pattern (mon)","","")
        delete([/pi,rad,coswgt,arr_west_mon,arr_east_mon,soi_mon,finarr_mon/])
     end if
     delete([/fnt,fnt2,finarr,z,arr/])
  end do  

  if (CREATE_GRAPHICS.eq."False") then
     print("Finished: soi.ncl")
     exit
  end if   
;========================================================================
  wks_type = OUTPUT_TYPE
  if (wks_type.eq."png") then
     wks_type@wkWidth = 1500*PNG_SCALE
     wks_type@wkHeight = 1500*PNG_SCALE
  end if

  res = True       ; spatial plot resource list
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
  res@gsnRightStringParallelPosF = 0.96
  res@gsnLeftStringFontHeightF = 0.014
  res@gsnCenterStringFontHeightF = 0.018
  res@gsnRightStringFontHeightF = 0.014
  res@gsnLeftString = ""
  res@gsnCenterString = ""
  res@gsnRightString = ""

  res2 = res    ; spatial differences resource list

  tres = res    ; p-value plot resource list
  copy_VarAtts(retrieve_summary_res(),tres)

  res@cnLevels = fspan(-4,4,17)
  res2@cnLevels = fspan(-4,4,17)
  if (COLORMAP.eq.0) then
     res@cnFillPalette = "ncl_default"
     res2@cnFillPalette = "ncl_default"
  end if
  if (COLORMAP.eq.1) then
     res@cnFillPalette = "BlueDarkRed18"
     res2@cnFillPalette = "BlueDarkRed18"
  end if 

  panres = True   ; panel resource list for individual simulations
  panres@gsnMaximize = True  
  panres@gsnPaperOrientation = "portrait"
  panres@gsnPanelLabelBar = True
  panres@gsnPanelYWhiteSpacePercent = 3.0
  panres@pmLabelBarHeightF = 0.05
  panres@pmLabelBarWidthF = 0.65
  panres@pmLabelBarOrthogonalPosF = -0.02
  panres@lbTitleOn = False
  panres@lbBoxLineColor = "gray70"
  panres@txFontHeightF = 0.016
  panres@gsnPanelBottom = 0.05
  panres@lbLabelFontHeightF = 0.013
  panres@lbLabelStride = 1
  panres@lbTitleOn = True
  panres@lbTitleFontHeightF = panres@lbLabelFontHeightF
  panres@lbTitlePosition = "Bottom"
  ncol = floattointeger(sqrt(nsim))
  nrow = (nsim/ncol)+mod(nsim,ncol)

  panres2 = panres     ; summary panel resource list
  panres2@gsnMaximize = False
  panres2@gsnPanelLabelBar = False
  panres2@pmLabelBarHeightF = 0.05
  panres2@pmLabelBarWidthF = 0.3
  panres2@lbTitleOn = False

  variname = (/"so_pattern_djf","so_pattern_jfm","so_pattern_mam","so_pattern_jja","so_pattern_jas","so_pattern_son","so_pattern_ann"/)
  variname_obs := variname
  variname_title = new(dimsizes(variname),string)
  variname_title = "SO Pattern"
  variname_title_seas = (/"DJF","JFM","MAM","JJA","JAS","SON","ANN"/)

  csubtitle_color = set_subtitle_colors(max(EM_num))
  nEM = max(EM_num)
  do dd = 0,dimsizes(variname)-1
     wks = gsn_open_wks(wks_type,getenv("OUTDIR")+"so")
     plot_indmem      = new(nsim,"graphic")
     plot_indmem_diff = new(nsim,"graphic")
     if (nEM.ge.1) then
        plot_summary     = new((nEM*4),"graphic")
     end if
     if (numobs.eq.0) then  ; if observations were not specified, set dummy file names, resulting in empty obs0 array
        fnt = getenv("OUTDIR")+"obs.cvdp_data.so."+syear(0)+"-"+eyear(0)+".nc"
        fnt2 = getenv("OUTDIR")+"obs.cvdp_data."+syear(0)+"-"+eyear(0)+".nc"
        cntr = 0
     else
        fnt = getenv("OUTDIR")+modname(0)+".cvdp_data.so."+syear(0)+"-"+eyear(0)+".nc"
        fnt2 = getenv("OUTDIR")+modname(0)+".cvdp_data."+syear(0)+"-"+eyear(0)+".nc"
        cntr = 1
     end if
     obs0 := read_cvdp_le_data(fnt,fnt2,variname_obs(dd))
     res@gsnCenterStringFontColor = "black"
     res2@gsnCenterStringFontColor = "black"
     res@lbLabelBarOn = False
     res2@lbLabelBarOn = False
     tres@lbLabelBarOn = False
     res@gsnLeftString = syear(0)+"-"+eyear(0) 
     res@gsnRightString = ""  ; obs0@units
     res@gsnCenterString = names(0)    
     plot_indmem(0) = gsn_csm_contour_map(wks,obs0,res)
     cntr_EM = 0
     if (numobs.ge.2) then     ; plot obs #2-
        do ff = 1,numobs-1
           fnt = getenv("OUTDIR")+modname(cntr)+".cvdp_data.so."+syear(cntr)+"-"+eyear(cntr)+".nc"
           fnt2 = getenv("OUTDIR")+modname(cntr)+".cvdp_data."+syear(cntr)+"-"+eyear(cntr)+".nc"
           arr := read_cvdp_le_data(fnt,fnt2,variname_obs(dd))
           if (isatt(arr,"is_all_missing")) then 
              cntr = cntr+1
              continue
           end if
           obs0_rg = linint2_Wrap(obs0&lon,obs0&lat,obs0,True,arr&lon,arr&lat,0)
           obs_diff = arr
           obs_diff = (/ arr - obs0_rg /)

           res@gsnLeftString = syear(cntr)+"-"+eyear(cntr) 
           res@gsnRightString = "r="+pattern_correlation(obs0_rg,arr)
           res@gsnCenterString = names(cntr)   
           plot_indmem(cntr) = gsn_csm_contour_map(wks,arr,res)
           res2@gsnLeftString = ""   ;syear(cntr)+"-"+eyear(cntr) 
           res2@gsnRightString = ""  ; arr@units
           res2@gsnCenterString = names(cntr)+"-"+names(0)
           plot_indmem_diff(cntr) = gsn_csm_contour_map(wks,obs_diff,res2)
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

           fnt = getenv("OUTDIR")+modname_mod+".cvdp_data.so."+syear_mod+"-"+eyear_mod+".nc"
           fnt2 = getenv("OUTDIR")+modname_mod+".cvdp_data."+syear_mod+"-"+eyear_mod+".nc"
           arr := read_cvdp_le_data(fnt,fnt2,variname(dd))
           if (isatt(arr,"is_all_missing")) then 
              cntr = cntr+1
              continue
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
           panres@lbTitleString = arr@units

           if (.not.isvar("obs0_rg")) then  
              obs0_rg = linint2_Wrap(obs0&lon,obs0&lat,obs0,True,arr&lon,arr&lat,0)
           end if
           obs_diff = arr
           obs_diff = (/ arr - obs0_rg /)

           res@gsnLeftString = syear_mod+"-"+eyear_mod
           res@gsnRightString = "r="+pattern_correlation(obs0_rg,arr)
           res@gsnCenterString = names_mod
           plot_indmem(cntr) = gsn_csm_contour_map(wks,arr,res)
           res2@gsnLeftString = "" ;syear(cntr)+"-"+eyear(cntr) 
           res2@gsnRightString = ""  ; ""  ; arr@units
           res2@gsnCenterString = names_mod+"-"+names(0)  
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
        res2@lbTitleString = res@lbTitleString  

        res@gsnLeftString = syear(0)+"-"+eyear(0) 
        res@gsnRightString = ""  ; obs0@units
        res@gsnCenterString = names(0)    
        plot_summary(cntr_EM+1) = gsn_csm_contour_map(wks,obs0,res)

        if (showyr) then
           res@gsnLeftString = syear_em0+"-"+eyear_em0 
        else
           res@gsnLeftString = (eyear_em0-syear_em0+1)+"yrs" 
        end if
        delete([/syear_em0,eyear_em0,showyr/])

        res@gsnRightString = "r="+pattern_correlation(obs0_rg,arr_EM)
        res@gsnCenterString = names_EM_mod +" ("+arr_store@nens+" Members)"                   
        plot_summary(cntr_EM) = gsn_csm_contour_map(wks,arr_EM,res)
        obs_diff = arr_EM
        obs_diff = (/ arr_EM - obs0_rg /)
        res2@gsnLeftString = ""
        res2@gsnCenterString = names_EM_mod+" - "+names(0)  
        res2@gsnRightString = ""  ; arr_EM@units
        plot_summary(cntr_EM+2) = gsn_csm_contour_map(wks,obs_diff,res2)

        p_val = calculate_pval(obs0_rg,arr_store)
        tres@gsnCenterString = "Rank of "+names(0)+" within Ensemble" 
        tres@gsnRightString = calculate_area_in_range(p_val,10,90)+"%"
        plot_summary(cntr_EM+3) = gsn_csm_contour_map(wks,p_val,tres)
        fno = getenv("OUTDIR")+str_sub_str(names_EM_mod," ","_")+"_EM.cvdp_data.soi."+syear_mod+"-"+eyear_mod+".nc"
        if (isfilepresent2(fno)) then
           z = addfile(fno,"w")
        else
           z = addfile(fno,"c")
           set_global_ncfile_attributes(z,names_EM_mod,syear_mod,eyear_mod,getenv("VERSION"))
        end if
        z->$(/variname(dd)+"_em"/)$         = set_varAtts(arr_EM,arr_EM@long_name+" Ensemble Mean","","")
        z->$(/variname(dd)+"_em_diffobs"/)$ = set_varAtts(obs_diff,obs_diff@long_name+" Ensemble Mean difference from "+names(0),"","")           
        z->$(/variname(dd)+"_pval"/)$       = set_varAtts(p_val,arr_EM@long_name+" p-val statistic","%","")   
        delete([/p_val,arr_store,obs0_rg,z,obs_diff,arr_EM/])
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
        system("mv "+OUTDIR+"so.000001.png "+OUTDIR+variname(dd)+".indmem.png")
        system("mv "+OUTDIR+"so.000002.png "+OUTDIR+variname(dd)+".indmemdiff.png")
        if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
           system("mv "+OUTDIR+"so.000003.png "+OUTDIR+variname(dd)+".summary.png")
           if (PNG_SCALE_SUMMARY.ne.100) then
              system(IM_COMMAND+" "+OUTDIR+variname(dd)+".summary.png -resize "+PNG_SCALE_SUMMARY+"% "+OUTDIR+variname(dd)+".summary.png")
           end if
        end if
     else
        system("psplit "+OUTDIR+"so.ps "+OUTDIR+"so")
        system("mv "+OUTDIR+"so0001.ps "+OUTDIR+variname(dd)+".indmem.ps")
        system("mv "+OUTDIR+"so0002.ps "+OUTDIR+variname(dd)+".indmemdiff.ps")
        if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
           system("mv "+OUTDIR+"so0003.ps "+OUTDIR+variname(dd)+".summary.ps")
        end if
        system("rm "+OUTDIR+"so.ps")
     end if
  end do
  delete([/panres,panres2/])
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
  xyres@gsnCenterStringOrthogonalPosF = -1.0
  xyres@gsnCenterStringParallelPosF = 0.05
  xyres@gsnRightStringOrthogonalPosF = xyres@gsnLeftStringOrthogonalPosF
  xyres@vpHeightF = 0.25
  xyres@vpWidthF = 0.7
  xyres@gsnLeftString = ""     
  xyres@gsnCenterString = ""
  xyres@gsnRightString = ""
     
  xyres2 = xyres     ; for observational line overlays in individual panels
  xyres2@xyLineColor = "gray60"

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

  ncolE = floattointeger(sqrt(nEM+1))   ; +1 for the summary plot
  nrowE = ((nEM+1)/ncolE)+mod(nEM+1,ncolE)

  variname := (/"so_timeseries_djf","so_timeseries_jfm","so_timeseries_mam",\
                "so_timeseries_jja","so_timeseries_jas","so_timeseries_son","so_timeseries_ann"/)
  variname_obs := variname
  variname_sv := variname
  variname_title = "SO Timeseries"

  do dd = 0,dimsizes(variname)-1
     wks = gsn_open_wks(wks_type,getenv("OUTDIR")+"so.timeseries")
     plot_indmem      := new(nsim,"graphic")   ; for individual obs/models
     plot_obs_overlay := new(nsim,"graphic")   ; for obs overlaid onto individual models
     if (nEM.ge.1) then
        plot_summary     := new(nEM,"graphic")    ; for ensemble plots  to show the 2 std dev range
        plot_summary1    := new(nEM,"graphic")    ; for ensemble plots to show the 1 std dev range
        plot_summary2    := new(nEM,"graphic")    ; for ensemble plots to show the ensemble mean
        plot_summary_obs_overlay := new(nEM,"graphic")  ; for ensemble plots to show overlaid obs
        plot_sum         := new(nEM,"graphic")    ; for individual panel in ensemble plots showing each ensemble mean
        plot_sum2        := new(nEM,"graphic")    ; for individual panel in ensemble plots showing each ensemble 10-90% range     
     end if
     XMinF := new(1,double)    ; used for summary timeseries plot showing all ensemble means
     XMaxF := new(1,double)
     YMinF := new(1,double)
     YMaxF := new(1,double)

     if (numobs.eq.0) then
        fnt = getenv("OUTDIR")+"obs.cvdp_data.so."+syear(0)+"-"+eyear(0)+".nc"
        fnt2 = getenv("OUTDIR")+"obs.cvdp_data."+syear(0)+"-"+eyear(0)+".nc"
        cntr = 0
     else
        fnt = getenv("OUTDIR")+modname(0)+".cvdp_data.so."+syear(0)+"-"+eyear(0)+".nc"
        fnt2 = getenv("OUTDIR")+modname(0)+".cvdp_data."+syear(0)+"-"+eyear(0)+".nc"
        cntr = 1
     end if
     obs0 := read_cvdp_le_data(fnt,fnt2,variname_obs(dd))
     obs0!0 = "time"
     if (isatt(obs0,"is_all_missing")) then 
        obs0New = new(eyear(0)-syear(0)+1,float)
        copy_VarAtts(obs0,obs0New)
        obs0 := obs0New
        obs0!0 = "time"
        obs0&time = ispan(syear(0),eyear(0),1)
        delete(obs0New)
     end if
     xyres@gsnLeftStringFontColor = "black"
     xyres2@gsnLeftStringFontColor = "black"
     if (isatt(xyres,"trYMinF")) then
        delete([/xyres@trYMinF,xyres@trYMaxF/])
     end if
     xyres@trXMinF = syear(0)-.5
     xyres@trXMaxF = eyear(0)+0.5
     xyres@gsnLeftString = names(0)
     if (all(ismissing(obs0))) then
        obs_val = "Insufficient Coverage"
        ztxt = ""
     else
        ztxt = "Linear trend = "
        tttt := dtrend_msg(ispan(0,dimsizes(obs0&time)-1,1),obs0,False,True)   
        obs_val := decimalPlaces(tttt@slope*dimsizes(obs0&time),2,True)+obs0@units+" "+nyr(0)+"yr~S~-1~N~"
     end if
     xyres@gsnRightString = obs_val+" "+nyr(0)+"yr~S~-1~N~"
     plot_indmem(0) = gsn_csm_xy(wks,ispan(syear(0),eyear(0),1),obs0,xyres)
     xyres2A@gsnLeftString = "Ensemble Mean Summary"
     plot_obs := gsn_csm_xy(wks,ispan(syear(0),eyear(0),1),obs0,xyres2A)
     cntr_EM = 0
     if (numobs.ge.2) then     ; plot obs #2-
        do ff = 1,numobs-1
           fnt = getenv("OUTDIR")+modname(cntr)+".cvdp_data.so."+syear(cntr)+"-"+eyear(cntr)+".nc"
           fnt2 = getenv("OUTDIR")+modname(cntr)+".cvdp_data."+syear(cntr)+"-"+eyear(cntr)+".nc"
           arr := read_cvdp_le_data(fnt,fnt2,variname_obs(dd))
           arr!0 = "time"
           if (isatt(arr,"is_all_missing")) then 
              cntr = cntr+1
              continue
           end if
           xyres@trXMinF = syear(cntr)-.5
           xyres@trXMaxF = eyear(cntr)+0.5
           xyres@trYMinF = min((/min(obs0),min(arr)/))-dim_stddev(arr)/2.
           xyres@trYMaxF = max((/max(obs0),max(arr)/))+dim_stddev(arr)/2.
           tttt := dtrend_msg(ispan(0,dimsizes(arr&time)-1,1),arr,False,True)   
           xyres@gsnLeftString = names(cntr)
           xyres@gsnRightString = decimalPlaces(tttt@slope*dimsizes(arr&time),2,True)+arr@units+" "+nyr(cntr)+"yr~S~-1~N~"
           plot_indmem(cntr) = gsn_csm_xy(wks,ispan(syear(cntr),eyear(cntr),1),arr,xyres)
           plot_obs_overlay(cntr) = gsn_csm_xy(wks,ispan(syear(0),eyear(0),1),obs0,xyres2)
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

           fnt = getenv("OUTDIR")+modname_mod+".cvdp_data.so."+syear_mod+"-"+eyear_mod+".nc"
           fnt2 = getenv("OUTDIR")+modname_mod+".cvdp_data."+syear_mod+"-"+eyear_mod+".nc"
           arr := read_cvdp_le_data(fnt,fnt2,variname(dd))
           arr!0 = "time"
           if (isatt(arr,"is_all_missing")) then 
              cntr = cntr+1
              continue
           end if
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
           plot_indmem(cntr) = gsn_csm_xy(wks,ispan(syear_mod,eyear_mod,1),arr,xyres)
           plot_obs_overlay(cntr) = gsn_csm_xy(wks,ispan(syear(0),eyear(0),1),obs0,xyres2)
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

        XMinF = min((/XMinF,min(arr_EM&time)/))
        XMaxF = max((/XMaxF,max(arr_EM&time)/))
        YMinF = min((/YMinF,min(arr_EM),min(obs0)/))
        YMaxF = max((/YMaxF,max(arr_EM),max(obs0)/))

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
        xyres3_sum@gsnRightString = decimalPlaces(stats(0)*dimsizes(arr_EM),2,True)+"/"+decimalPlaces(tttt@slope*dimsizes(arr_EM),2,True)+"/"+decimalPlaces(stats(4)*dimsizes(arr_EM),2,True)+" "+arr_EM@units+" "+(max(arr_EM&time)-min(arr_EM&time)+1)+"yr~S~-1~N~"
        plot_summary(cntr_EM) = gsn_csm_xy(wks,ispan(min(arr_EM&time),max(arr_EM&time),1),arr_range2,xyres3_sum)
        plot_summary1(cntr_EM) = gsn_csm_xy(wks,ispan(min(arr_EM&time),max(arr_EM&time),1),arr_range1,xyres3b_sum)
        plot_summary2(cntr_EM) = gsn_csm_xy(wks,ispan(min(arr_EM&time),max(arr_EM&time),1),arr_EM,xyres_sum)
        plot_summary_obs_overlay(cntr_EM) = gsn_csm_xy(wks,ispan(syear(0),eyear(0),1),obs0,xyres2_sum)
        plot_sum(cntr_EM) = gsn_csm_xy(wks,ispan(min(arr_EM&time),max(arr_EM&time),1),arr_EM,xyres_sumA)
        overlay(plot_summary(cntr_EM),plot_summary1(cntr_EM))
        overlay(plot_summary(cntr_EM),plot_summary_obs_overlay(cntr_EM))
        overlay(plot_summary(cntr_EM),plot_summary2(cntr_EM))

        fout = getenv("OUTDIR")+str_sub_str(names_EM_mod," ","_")+"_EM.cvdp_data.soi."+syear_mod+"-"+eyear_mod+".nc"
        if (isfilepresent2(fout)) then
           z = addfile(fout,"w")
        else
           z = addfile(fout,"c")
           set_global_ncfile_attributes(z,names_EM_mod,syear_mod,eyear_mod,getenv("VERSION"))
        end if
        arr_EM!0 = "TIME"
        arr_range1!1 = "TIME"        
        arr_range2!1 = "TIME"
        z->$(/variname(dd)+"_em"/)$ = set_varAtts(arr_EM,arr_EM@long_name+" Ensemble Mean","","")
        z->$(/variname(dd)+"_2575range"/)$ = set_varAtts(arr_range1,arr_EM@long_name+" 25/75% range","","")
        z->$(/variname(dd)+"_1090range"/)$ = set_varAtts(arr_range2,arr_EM@long_name+" 10/90% range","","")
        delete([/z,tttt,ssss,arr_store/])
        cntr_EM = cntr_EM+1
     end do
     panres3@txString = variname_title(dd)+" ("+variname_title_seas(dd)+")"
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
        panres4@gsnPanelMainString = "Ensemble Summary: "+variname_title(dd)+" ("+variname_title_seas(dd)+")"
        gsn_panel2(wks,plot_final,(/nrowE,ncolE/),panres4)
        if (numobs.ne.0) then  
           gsn_text_ndc(wks,names(0)+" "+syear(0)+"-"+eyear(0)+", "+ztxt+obs_val,0.5,panres4@gsnPanelMainPosYF-.025,txres)
        end if
        frame(wks)
     end if
     delete(wks)

     if (wks_type.eq."png") then
        if (nEM.lt.1) then   ; in ensemble mode (runstyle=2)
           system("mv "+OUTDIR+"so.timeseries.png "+OUTDIR+variname(dd)+".indmem.png")
        else
           system("mv "+OUTDIR+"so.timeseries.000001.png "+OUTDIR+variname(dd)+".indmem.png")
           system("mv "+OUTDIR+"so.timeseries.000002.png "+OUTDIR+variname(dd)+".summary.png")
           if (PNG_SCALE_SUMMARY.ne.100) then
              system(IM_COMMAND+" "+OUTDIR+variname(dd)+".summary.png -resize "+PNG_SCALE_SUMMARY+"% "+OUTDIR+variname(dd)+".summary.png")
           end if
        end if
     else
        system("psplit "+OUTDIR+"so.timeseries.ps "+OUTDIR+"so.timeseries")
        system("mv "+OUTDIR+"so.timeseries0001.ps "+OUTDIR+variname(dd)+".indmem.ps")
        if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
           system("mv "+OUTDIR+"so.timeseries0002.ps "+OUTDIR+variname(dd)+".summary.ps")
        end if
        system("rm "+OUTDIR+"so.timeseries.ps")
     end if
  end do
  print("Finished: soi.ncl")
end



