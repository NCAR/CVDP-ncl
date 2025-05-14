; Calculates precipitation global means and standard deviations
;
; Variables used: pr
;
load "$CVDP_SCRIPTS/functions.ncl"

begin
  print("Starting: pr.mean_stddev.ncl")
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
  
  nsim = numAsciiRow("namelist_byvar/namelist_prect")

  na = asciiread("namelist_byvar/namelist_prect",(/nsim/),"string")
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
;  print(EM_num+" "+names_EM)
  nEM = max(EM_num)
  nEMm = min(EM_num)
  numobs = num(EM_num.eq.0) 
  
  do ee = 0,nsim-1
     fnt = getenv("OUTDIR")+modname(ee)+".cvdp_data.pr.mean_stddev."+syear(ee)+"-"+eyear(ee)+".nc"
     fnt2 = getenv("OUTDIR")+modname(ee)+".cvdp_data."+syear(ee)+"-"+eyear(ee)+".nc"
     f_test := read_cvdp_le_data(fnt,fnt2,"pr_spatialstddev_ann")
     if (.not.isatt(f_test,"is_all_missing")) then
        continue
     end if

     arr = data_read_in(paths(ee),"PRECT",syear(ee),eyear(ee))    ; read in data, orient lats/lons correctly, set time coordinate variable up
     finarr = calculate_means(arr)

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
           arr = remove_trend(arr,REMOVE_TREND_MODEL,ensemble_mean_read_in(arr,ENSEMBLE_MEAN_DIR+str_sub_str(names_EM(ee)," ","_"),EM_num(ee),"PRECT",syear,eyear,EM_num))
        end if
     end if
     if (isatt(arr,"is_all_missing")) then
        delete([/arr,finarr/])
        continue
     end if
     finarrSD = calculate_stddev(arr)

     z = addfile(fnt,"c")
     set_global_ncfile_attributes(z,names(ee),syear(ee),eyear(ee),getenv("VERSION"))

     z->$(/"pr_spatialmean_djf"/)$     = set_varAtts(finarr(0,:,:),"pr climatology (DJF)","","")
     z->$(/"pr_spatialmean_jfm"/)$     = set_varAtts(finarr(1,:,:),"pr climatology (JFM)","","")
     z->$(/"pr_spatialmean_mam"/)$     = set_varAtts(finarr(2,:,:),"pr climatology (MAM)","","")
     z->$(/"pr_spatialmean_jja"/)$     = set_varAtts(finarr(3,:,:),"pr climatology (JJA)","","")
     z->$(/"pr_spatialmean_jas"/)$     = set_varAtts(finarr(4,:,:),"pr climatology (JAS)","","")
     z->$(/"pr_spatialmean_son"/)$     = set_varAtts(finarr(5,:,:),"pr climatology (SON)","","")
     z->$(/"pr_spatialmean_ann"/)$     = set_varAtts(finarr(6,:,:),"pr climatology (annual)","","")     
     z->$(/"pr_spatialstddev_djf"/)$   = set_varAtts(finarrSD(0,:,:),"pr standard deviation (DJF)","","")
     z->$(/"pr_spatialstddev_jfm"/)$   = set_varAtts(finarrSD(1,:,:),"pr standard deviation (JFM)","","")
     z->$(/"pr_spatialstddev_mam"/)$   = set_varAtts(finarrSD(2,:,:),"pr standard deviation (MAM)","","")
     z->$(/"pr_spatialstddev_jja"/)$   = set_varAtts(finarrSD(3,:,:),"pr standard deviation (JJA)","","")
     z->$(/"pr_spatialstddev_jas"/)$   = set_varAtts(finarrSD(4,:,:),"pr standard deviation (JAS)","","")
     z->$(/"pr_spatialstddev_son"/)$   = set_varAtts(finarrSD(5,:,:),"pr standard deviation (SON)","","")
     z->$(/"pr_spatialstddev_ann"/)$   = set_varAtts(finarrSD(6,:,:),"pr standard deviation (annual)","","")
     delete([/z,arr,finarr,finarrSD/])
  end do

  if (CREATE_GRAPHICS.eq."False") then
     print("Finished: pr.mean_stddev.ncl")
     exit
  end if 
;==========================================================================================
  wks_type = OUTPUT_TYPE
  if (wks_type.eq."png") then
     wks_type@wkWidth = 1500*PNG_SCALE
     wks_type@wkHeight = 1500*PNG_SCALE
  end if

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
  res@cnMissingValFillColor = "gray90"

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
  res@gsnRightString = ""
  res@gsnLeftString = ""

  res2 = res     ; stddev differences resource list
  sres = res     ; means resource list
  sres2 = sres   ; mean differences resource list

  tres = res    ; p-value plot resource list
  copy_VarAtts(retrieve_summary_res(),tres)

  if (COLORMAP.eq.0) then
     res@cnLevels = (/.2,.4,.6,1.0,1.5,2.0,2.5,3.5/)   
     res2@cnLevels = (/-2.5,-2,-1.5,-1,-0.5,-0.25,-0.1,0,0.1,0.25,0.5,1,1.5,2,2.5/) ;fspan(-4,4,17)

     sres@cnLevels = (/0.5,1,2,3,4,5,6,7,8,9,10,12,14,16,18/)
     sres2@cnLevels = (/-8,-6,-4,-2,-1,-0.5,0.,0.5,1,2,4,6,8/)
     cmap = read_colormap_file("precip3_16lev")
     res@cnFillPalette = cmap((/0,2,4,6,8,10,12,14,16/),:) 
     delete(cmap)
     res2@cnFillPalette = "MPL_RdYlGn"
     sres@cnFillPalette = "precip3_16lev"
     sres2@cnFillPalette = "MPL_RdYlGn"
  end if
  if (COLORMAP.eq.1) then
     res@cnLevels = (/.2,.4,.6,1.0,1.5,2.0,2.5,3.5/)   
     res2@cnLevels = (/-2,-1.5,-1,-0.5,-0.25,-0.1,0,0.1,0.25,0.5,1,1.5,2/)
     sres@cnLevels = (/0.5,1,2,3,4,5,6,7,8,9,10,12,14,16,18/)
     sres2@cnLevels = (/-10,-8,-6,-4,-2,-1,-0.5,0.,0.5,1,2,4,6,8,10/)
     cmap = read_colormap_file("cb_rainbow")
     res@cnFillPalette = cmap((/33,45,61,77,93,109,122,153,173/),:) 
     res2@cnFillPalette = "BlueDarkRed18"
     sres@cnFillPalette = "BlueDarkRed18"
     sres2@cnFillPalette = "BlueDarkRed18"
  end if 

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
  ncol = floattointeger(sqrt(nsim))
  nrow = (nsim/ncol)+mod(nsim,ncol)

  panres2 = panres   ; summary panel resource list
  panres2@gsnFrame = False
  panres2@gsnMaximize = False
  panres2@gsnPanelLabelBar = False
  panres2@lbTitleOn = False

  variname = (/"mean_djf","mean_jfm","mean_mam","mean_jja","mean_jas","mean_son","mean_ann",\
               "stddev_djf","stddev_jfm","stddev_mam","stddev_jja","stddev_jas","stddev_son","stddev_ann"/)
  variname_obs = "pr_spatial"+variname
  variname = "pr_spatial"+variname
  variname_title = variname
  variname_title(:6) = "PR Climatologies"
  variname_title(7:) = "PR Standard Deviations"
  variname_title_seas = (/"DJF","JFM","MAM","JJA","JAS","SON","ANN","DJF","JFM","MAM","JJA","JAS","SON","ANN"/)

  csubtitle_color = set_subtitle_colors(max(EM_num))
  do dd = 0,dimsizes(variname)-1
     wks = gsn_open_wks(wks_type,getenv("OUTDIR")+"pr.mean_stddev")
     plot_indmem      = new(nsim,"graphic")
     plot_indmem_diff = new(nsim,"graphic")
     if (nEM.ge.1) then
        plot_summary     = new((nEM*4),"graphic")
     end if

     if (dd.le.6) then
        qres = sres    ; mean resource list
        qres2 = sres2  ; mean diff resource list
     else
        qres = res     ; stddev resource list
        qres2 = res2
     end if

     numobs = num(EM_num.eq.0) 
     if (numobs.eq.0) then  ; if observations were not specified, set dummy file names, resulting in empty obs0 array
        fnt = getenv("OUTDIR")+"obs.cvdp_data.pr.mean_stddev."+syear(0)+"-"+eyear(0)+".nc"  
        fnt2 = getenv("OUTDIR")+"obs.cvdp_data."+syear(0)+"-"+eyear(0)+".nc"
        cntr = 0
     else
        fnt = getenv("OUTDIR")+modname(0)+".cvdp_data.pr.mean_stddev."+syear(0)+"-"+eyear(0)+".nc"
        fnt2 = getenv("OUTDIR")+modname(0)+".cvdp_data."+syear(0)+"-"+eyear(0)+".nc"
        cntr = 1
     end if
     obs0 := read_cvdp_le_data(fnt,fnt2,variname_obs(dd))
     qres@gsnCenterStringFontColor = "black"
     qres2@gsnCenterStringFontColor = "black"
     qres@gsnLeftString = syear(0)+"-"+eyear(0) 
     qres@gsnRightString = ""  ; obs0@units
     qres@gsnCenterString = names(0)    
     plot_indmem(0) = gsn_csm_contour_map(wks,obs0,qres)
     cntr_EM = 0
     if (numobs.ge.2) then     ; plot obs #2-
        do ff = 1,numobs-1
           fnt = getenv("OUTDIR")+modname(cntr)+".cvdp_data.pr.mean_stddev."+syear(cntr)+"-"+eyear(cntr)+".nc"
           fnt2 = getenv("OUTDIR")+modname(cntr)+".cvdp_data."+syear(cntr)+"-"+eyear(cntr)+".nc"
           arr := read_cvdp_le_data(fnt,fnt2,variname_obs(dd))
           if (isatt(arr,"is_all_missing")) then 
              cntr = cntr+1
              continue
           end if
           obs0_rg = linint2_Wrap(obs0&lon,obs0&lat,obs0,True,arr&lon,arr&lat,0)
           obs_diff = arr
           obs_diff = (/ arr - obs0_rg /)

           qres@gsnLeftString = syear(cntr)+"-"+eyear(cntr) 
           qres@gsnRightString = "r="+pattern_correlation(obs0_rg,arr)
           qres@gsnCenterString = names(cntr)   
           plot_indmem(cntr) = gsn_csm_contour_map(wks,arr,qres)
           qres2@gsnLeftString = ""   ;syear(cntr)+"-"+eyear(cntr) 
           qres2@gsnRightString = ""  ; arr@units
           qres2@gsnCenterString = names(cntr)+"-"+names(0)
           plot_indmem_diff(cntr) = gsn_csm_contour_map(wks,obs_diff,qres2)
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
;        print("For gg = "+gg+", cntr_ens = "+cntr_ens)
        do hh = 0,nens-1
           modname_mod = modname(cntr_ens(hh))
           syear_mod = syear(cntr_ens(hh))
           eyear_mod = eyear(cntr_ens(hh))
           names_mod = names(cntr_ens(hh))
           names_EM_mod = names_EM(cntr_ens(hh))
;           print(modname_mod+" "+syear_mod+" "+eyear_mod+" "+names_mod+" "+names_EM_mod)

           fnt = getenv("OUTDIR")+modname_mod+".cvdp_data.pr.mean_stddev."+syear_mod+"-"+eyear_mod+".nc"
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
           if (syear_em0.ne.syear_mod.or.eyear_em0.ne.eyear_mod.and.showyr) then
              showyr = False
           else
              showyr = True
           end if
           if (gg.ge.1) then
              qres@gsnCenterStringFontColor = csubtitle_color(gg-1)
              qres2@gsnCenterStringFontColor = csubtitle_color(gg-1)
           end if

           arr_store(hh,:,:) = (/ arr /)
           arr_store@nens = arr_store@nens+1
           panres@lbTitleString = arr@units

           if (.not.isvar("obs0_rg")) then  
              obs0_rg = linint2_Wrap(obs0&lon,obs0&lat,obs0,True,arr&lon,arr&lat,0)
           end if
           obs_diff = arr
           obs_diff = (/ arr - obs0_rg /)

           qres@gsnLeftString = syear_mod+"-"+eyear_mod
           qres@gsnRightString = "r="+pattern_correlation(obs0_rg,arr)
           qres@gsnCenterString = names_mod
           plot_indmem(cntr) = gsn_csm_contour_map(wks,arr,qres)
           qres2@gsnLeftString = "" ;syear(cntr)+"-"+eyear(cntr) 
           qres2@gsnRightString = ""  ; arr@units
           qres2@gsnCenterString = names_mod+"-"+names(0)  
           plot_indmem_diff(cntr) = gsn_csm_contour_map(wks,obs_diff,qres2)
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
           qres2@lbLabelBarOn = True
           tres@lbLabelBarOn = True
        else
           qres@lbLabelBarOn = False
           qres2@lbLabelBarOn = False
           tres@lbLabelBarOn = False     
        end if
        arr_EM = dim_avg_n_Wrap(arr_store,0)

        qres@gsnCenterStringFontColor = "black"
        qres2@gsnCenterStringFontColor = "black"
        qres@lbTitleString = arr_EM@units   
        qres2@lbTitleString = qres@lbTitleString  

        qres@gsnLeftString = syear(0)+"-"+eyear(0) 
        qres@gsnRightString = ""  ; obs0@units
        qres@gsnCenterString = names(0)
        plot_summary(cntr_EM+1) = gsn_csm_contour_map(wks,obs0,qres)

        qres@gsnCenterStringFontColor = csubtitle_color(gg-1)
        if (showyr) then
           qres@gsnLeftString = syear_em0+"-"+eyear_em0 
        else
           qres@gsnLeftString = (eyear_em0-syear_em0+1)+"yrs" 
        end if
        delete([/syear_em0,eyear_em0,showyr/])
        qres@gsnCenterStringFontColor = csubtitle_color(gg-1)
        qres@gsnRightString = "r="+pattern_correlation(obs0_rg,arr_EM)
        qres@gsnCenterString = names_EM_mod +" ("+arr_store@nens+" Members)"                   
        plot_summary(cntr_EM) = gsn_csm_contour_map(wks,arr_EM,qres)
        obs_diff = arr_EM
        obs_diff = (/ arr_EM - obs0_rg /)
        qres2@gsnLeftString = ""
        qres2@gsnCenterString = names_EM_mod+" - "+names(0)  
        qres2@gsnRightString = arr_EM@units
        plot_summary(cntr_EM+2) = gsn_csm_contour_map(wks,obs_diff,qres2)

        p_val = calculate_pval(obs0_rg,arr_store)
        tres@gsnCenterString = "Rank of "+names(0)+" within Ensemble" 
        tres@gsnRightString = calculate_area_in_range(p_val,10,90)+"%"
        plot_summary(cntr_EM+3) = gsn_csm_contour_map(wks,p_val,tres)

        fout = getenv("OUTDIR")+str_sub_str(names_EM_mod," ","_")+"_EM.cvdp_data.pr.mean_stddev."+syear_mod+"-"+eyear_mod+".nc"
        if (isfilepresent2(fout)) then
           z = addfile(fout,"w")
        else
           z = addfile(fout,"c")
           set_global_ncfile_attributes(z,names_EM_mod,syear_mod,eyear_mod,getenv("VERSION"))
        end if
        z->$(/variname(dd)+"_em"/)$ = set_varAtts(arr_EM,arr_EM@long_name+" Ensemble Mean","","")
        z->$(/variname(dd)+"_em_diffobs"/)$ = set_varAtts(obs_diff,obs_diff@long_name+" Ensemble Mean difference from "+names(0),"","")        
        z->$(/variname(dd)+"_pval"/)$ = set_varAtts(p_val,arr_EM@long_name+" p-val statistic","%","")    
 
        delete([/p_val,arr_store,obs0_rg,obs_diff,arr_EM/])
        cntr_EM = cntr_EM+4
     end do
     panres@txString = variname_title(dd)+" ("+variname_title_seas(dd)+")"
     gsn_panel2(wks,plot_indmem,(/nrow,ncol/),panres)

     panres@txString = variname_title(dd)+" Differences ("+variname_title_seas(dd)+")"
     gsn_panel2(wks,plot_indmem_diff,(/nrow,ncol/),panres)

     if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
        panres2@txString = "Ensemble Summary: "+variname_title(dd)+" ("+variname_title_seas(dd)+")"
        gsn_panel2(wks,plot_summary,(/nEM,4/),panres2)
        frame(wks)
     end if
     delete([/wks/])

     if (wks_type.eq."png") then
        system("mv "+OUTDIR+"pr.mean_stddev.000001.png "+OUTDIR+variname(dd)+".indmem.png")
        system("mv "+OUTDIR+"pr.mean_stddev.000002.png "+OUTDIR+variname(dd)+".indmemdiff.png")
        if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
           system("mv "+OUTDIR+"pr.mean_stddev.000003.png "+OUTDIR+variname(dd)+".summary.png")
           if (PNG_SCALE_SUMMARY.ne.100) then
              system(IM_COMMAND+" "+OUTDIR+variname(dd)+".summary.png -resize "+PNG_SCALE_SUMMARY+"% "+OUTDIR+variname(dd)+".summary.png")
           end if
        end if
     else
        system("psplit "+OUTDIR+"pr.mean_stddev.ps "+OUTDIR+"pr.mean_stddev")
        system("mv "+OUTDIR+"pr.mean_stddev0001.ps "+OUTDIR+variname(dd)+".indmem.ps")
        system("mv "+OUTDIR+"pr.mean_stddev0002.ps "+OUTDIR+variname(dd)+".indmemdiff.ps")
        if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
           system("mv "+OUTDIR+"pr.mean_stddev0003.ps "+OUTDIR+variname(dd)+".summary.ps")
        end if
        system("rm "+OUTDIR+"pr.mean_stddev.ps")
     end if
  end do
  print("Finished: pr.mean_stddev.ncl")
end

