; Calculates SIC hemispheric means and standard deviations
;
; Variables used: sic
;
load "$CVDP_SCRIPTS/functions.ncl"

begin
  print("Starting: siconc.mean_stddev.ncl")
  
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

  delim = "|"
  hemi = (/"sh","nh"/)
  hemi_long = (/"Southern Hemisphere","Northern Hemisphere"/)

  do dd = 0,dimsizes(hemi)-1   
     nsim := numAsciiRow("namelist_byvar/namelist_aice_"+hemi(dd))
     na := asciiread("namelist_byvar/namelist_aice_"+hemi(dd),(/nsim/),"string")
     names := new(nsim,"string")
     paths := new(nsim,"string")
     syear := new(nsim,"integer",-999)
     eyear := new(nsim,"integer",-999)
     names_EM := new(nsim,"string")
     EM_num := new(nsim,"integer",-999)

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
     modname := str_sub_str(names," ","_")
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

     do ee = 0,nsim-1
        fnt = getenv("OUTDIR")+modname(ee)+".cvdp_data.siconc.mean_stddev."+syear(ee)+"-"+eyear(ee)+".nc"
        fnt2 = getenv("OUTDIR")+modname(ee)+".cvdp_data."+syear(ee)+"-"+eyear(ee)+".nc"
        f_test := read_cvdp_le_data(fnt,fnt2,"siconc_"+hemi(dd)+"_spatialstddev_ann")
        if (.not.isatt(f_test,"is_all_missing")) then
           continue
        end if

        arr = data_read_in_ice(paths(ee),"aice_"+hemi(dd),syear(ee),eyear(ee))    ; read in data, orient lats/lons correctly, set time coordinate variable up
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
              arr = remove_trend(arr,REMOVE_TREND_MODEL,ensemble_mean_read_in(arr,ENSEMBLE_MEAN_DIR+str_sub_str(names_EM(ee)," ","_"),EM_num(ee),"aice_"+hemi(dd),syear,eyear,EM_num))
           end if
        end if
        if (isatt(arr,"is_all_missing")) then
           delete([/arr,finarr/])
           continue
        end if
        finarrSD = calculate_stddev(arr)
        if (hemi(dd).eq."sh") then
           finarr!1 = "j2"
           finarr!2 = "i2"
           finarrSD!1 = "j2"
           finarrSD!2 = "i2"
        end if
        if (isfilepresent2(fnt)) then
           z = addfile(fnt,"w")
        else
           z = addfile(fnt,"c")
        end if
        set_global_ncfile_attributes(z,names(ee),syear(ee),eyear(ee),getenv("VERSION"))
        if (isatt(finarr,"lat2d")) then    ; if there is a lat2d there will be a lon2d
           LAT2D = finarr@lat2d
           LON2D = finarr@lon2d
           delete([/finarr@lat2d,finarr@lon2d,finarrSD@lat2d,finarrSD@lon2d/])
           copy_VarCoords(finarr(0,:,:),LAT2D)
           copy_VarCoords(finarr(0,:,:),LON2D)
           z->$(/"lat2d_ice_"+hemi(dd)/)$ = set_varAtts(LAT2D,hemi_long(dd)+" ice grid 2-dimensional latitudes","","")
           z->$(/"lon2d_ice_"+hemi(dd)/)$ = set_varAtts(LON2D,hemi_long(dd)+" ice grid 2-dimensional longitudes","","")
           delete([/LAT2D,LON2D/])
           finarr@coordinates ="lat2d_ice_"+hemi(dd)+" lon2d_ice_"+hemi(dd)
           finarrSD@coordinates ="lat2d_ice_"+hemi(dd)+" lon2d_ice_"+hemi(dd)
        end if  
        if (isatt(finarr,"area")) then
           delete(finarr@area)
           delete(finarrSD@area)
        end if
        z->$(/"siconc_"+hemi(dd)+"_spatialmean_djf"/)$    = set_varAtts(finarr(0,:,:),hemi_long(dd)+" siconc climatology (DJF)","","")
        z->$(/"siconc_"+hemi(dd)+"_spatialmean_jfm"/)$    = set_varAtts(finarr(1,:,:),hemi_long(dd)+" siconc climatology (JFM)","","")
        z->$(/"siconc_"+hemi(dd)+"_spatialmean_mam"/)$    = set_varAtts(finarr(2,:,:),hemi_long(dd)+" siconc climatology (MAM)","","")
        z->$(/"siconc_"+hemi(dd)+"_spatialmean_jja"/)$    = set_varAtts(finarr(3,:,:),hemi_long(dd)+" siconc climatology (JJA)","","")
        z->$(/"siconc_"+hemi(dd)+"_spatialmean_jas"/)$    = set_varAtts(finarr(4,:,:),hemi_long(dd)+" siconc climatology (JAS)","","")
        z->$(/"siconc_"+hemi(dd)+"_spatialmean_son"/)$    = set_varAtts(finarr(5,:,:),hemi_long(dd)+" siconc climatology (SON)","","")
        z->$(/"siconc_"+hemi(dd)+"_spatialmean_ann"/)$    = set_varAtts(finarr(6,:,:),hemi_long(dd)+" siconc climatology (annual)","","")     
        z->$(/"siconc_"+hemi(dd)+"_spatialstddev_djf"/)$  = set_varAtts(finarrSD(0,:,:),hemi_long(dd)+" siconc standard deviation (DJF)","","")
        z->$(/"siconc_"+hemi(dd)+"_spatialstddev_jfm"/)$  = set_varAtts(finarrSD(1,:,:),hemi_long(dd)+" siconc standard deviation (JFM)","","")
        z->$(/"siconc_"+hemi(dd)+"_spatialstddev_mam"/)$  = set_varAtts(finarrSD(2,:,:),hemi_long(dd)+" siconc standard deviation (MAM)","","")
        z->$(/"siconc_"+hemi(dd)+"_spatialstddev_jja"/)$  = set_varAtts(finarrSD(3,:,:),hemi_long(dd)+" siconc standard deviation (JJA)","","")
        z->$(/"siconc_"+hemi(dd)+"_spatialstddev_jas"/)$  = set_varAtts(finarrSD(4,:,:),hemi_long(dd)+" siconc standard deviation (JAS)","","")
        z->$(/"siconc_"+hemi(dd)+"_spatialstddev_son"/)$  = set_varAtts(finarrSD(5,:,:),hemi_long(dd)+" siconc standard deviation (SON)","","")
        z->$(/"siconc_"+hemi(dd)+"_spatialstddev_ann"/)$  = set_varAtts(finarrSD(6,:,:),hemi_long(dd)+" siconc standard deviation (annual)","","")
        delete([/z,arr,finarr,finarrSD/])
     end do ; ee loop
  end do    ; dd loop

  if (CREATE_GRAPHICS.eq."False") then
     print("Finished: siconc.mean_stddev.ncl")
     exit
  end if 
;==========================================================================================
  wks_type = OUTPUT_TYPE
  if (wks_type.eq."png") then
     wks_type@wkWidth = 1500*PNG_SCALE
     wks_type@wkHeight = 1500*PNG_SCALE
  end if

  res = True     ; spatial plot resource list
  res@mpGeophysicalLineColor = "gray42"
  if (wks_type.eq."png") then
     res@mpGeophysicalLineThicknessF = 2.  
  else
     res@mpGeophysicalLineThicknessF = 1.  
  end if         
  res@mpGridAndLimbOn = False
  res@mpLandFillColor  = "gray75"           
  res@mpFillDrawOrder  = "PostDraw"       
  res@mpPerimDrawOrder  = "PostDraw"     

  res@mpOutlineOn = True  
  res@mpCenterLonF = 0.
  res@gsnDraw      = False
  res@gsnFrame     = False
  res@gsnAddCyclic = True
  res@cnLevelSelectionMode = "ExplicitLevels"
  res@cnLineLabelsOn = False
  res@cnFillOn        = True
  res@cnLinesOn       = False
  res@cnFillMode = "RasterFill"
  res@trGridType = "TriangularMesh"

  res@pmLabelBarOrthogonalPosF = 0.03
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

  res2 = res    ; stddev differences resource list
  sres = res     ; means resource list
  sres2 = sres   ; mean differences resource list

  tres = res    ; p-value plot resource list
  copy_VarAtts(retrieve_summary_res(),tres)

  if (COLORMAP.eq.0) then
     res@cnLevels = (/4,8,12,16,20,24,28,32,36/)   
     res2@cnLevels = fspan(-10,10,21)

     sres@cnLevels = (/5,10,15,20,30,40,50,60,70,80,85,90,95,99/)
     sres2@cnLevels = fspan(-20,20,21)
     cmap := read_colormap_file("BkBlAqGrYeOrReViWh200")
     res@cnFillPalette = cmap((/40,27,78,93,103,118,138,159,168,191/),:) 
     res2@cnFillPalette = "ncl_default"
     sres@cnFillPalette = cmap((/50,40,32,22,63,78,93,103,118,138,153,159,168,182,191/),:) 
     sres2@cnFillPalette = "ncl_default"
     delete(cmap)
  end if
  if (COLORMAP.eq.1) then
     res@cnLevels = (/4,8,12,16,20,24,28,32,36/)
     res2@cnLevels = fspan(-1,1,11)
     sres@cnLevels = (/5,10,15,20,30,40,50,60,70,80,85,90,95,99/)
     sres2@cnLevels = fspan(-10,10,11)
     cmap := read_colormap_file("cb_rainbow")
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

  panres2 = panres     ; summary panel resource list
  panres2@gsnFrame = False
  panres2@gsnMaximize = False
  panres2@gsnPanelLabelBar = False
  panres2@lbTitleOn = False

  do cc = 0,dimsizes(hemi)-1  
     variname := (/"mean_djf","mean_jfm","mean_mam","mean_jja","mean_jas","mean_son","mean_ann",\
               "stddev_djf","stddev_jfm","stddev_mam","stddev_jja","stddev_jas","stddev_son","stddev_ann"/)
     variname_obs := "siconc_"+hemi(cc)+"_spatial"+variname  
     variname = "siconc_"+hemi(cc)+"_spatial"+variname  
     variname_title = variname
     variname_title(:6) = "siconc Climatologies"
     variname_title(7:) = "siconc Standard Deviations"
     variname_title_seas = (/"DJF","JFM","MAM","JJA","JAS","SON","ANN","DJF","JFM","MAM","JJA","JAS","SON","ANN"/)

;- - - - - - - - - - - 
     nsim := numAsciiRow("namelist_byvar/namelist_aice_"+hemi(cc))
     na := asciiread("namelist_byvar/namelist_aice_"+hemi(cc),(/nsim/),"string")
     names := new(nsim,"string")
     paths := new(nsim,"string")
     syear := new(nsim,"integer",-999)
     eyear := new(nsim,"integer",-999)
     names_EM := new(nsim,"string")
     EM_num := new(nsim,"integer",-999)
     ncol = floattointeger(sqrt(nsim))
     nrow = (nsim/ncol)+mod(nsim,ncol)

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
     modname := str_sub_str(names," ","_")
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
;- - - - - - - - - - - 
     csubtitle_color = set_subtitle_colors(max(EM_num))
     do dd =   0,dimsizes(variname)-1  
        wks = gsn_open_wks(wks_type,getenv("OUTDIR")+"siconc.mean_stddev")
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
        qres@gsnPolar  = changeCaseChar(hemi(cc))
        qres2@gsnPolar = qres@gsnPolar
        tres@gsnPolar  = qres@gsnPolar
        tres@lbLabelBarOn = False
        if (hemi(cc).eq."nh") then
           if (isatt(tres,"mpMaxLatF")) then
              delete([/tres@mpMaxLatF/])
           end if
           qres@mpMinLatF  = 40.
           qres2@mpMinLatF = 40.
           tres@mpMinLatF  = 40.
        else
           if (isatt(tres,"mpMinLatF")) then
              delete([/tres@mpMinLatF/])
           end if
           qres@mpMaxLatF  = -40.
           qres2@mpMaxLatF = -40.
           tres@mpMaxLatF  = -40.
        end if
        numobs = num(EM_num.eq.0) 
        if (numobs.eq.0) then  ; if observations were not specified, set dummy file names, resulting in empty obs0 array
           fnt = getenv("OUTDIR")+"obs.cvdp_data.siconc.mean_stddev."+syear(0)+"-"+eyear(0)+".nc"  
           fnt2 = getenv("OUTDIR")+"obs.cvdp_data."+syear(0)+"-"+eyear(0)+".nc"
           cntr = 0
        else
           fnt = getenv("OUTDIR")+modname(0)+".cvdp_data.siconc.mean_stddev."+syear(0)+"-"+eyear(0)+".nc"
           fnt2 = getenv("OUTDIR")+modname(0)+".cvdp_data."+syear(0)+"-"+eyear(0)+".nc"
           cntr = 1
        end if

        obs0 := read_cvdp_le_data(fnt,fnt2,variname_obs(dd))
        obs0!0 = "j"
        obs0!1 = "i"

        if (dd.le.6) then   
           obs0 = where(obs0.lt.1,obs0@_FillValue,obs0)
        else
           obs0 = where(obs0.eq.0,obs0@_FillValue,obs0)
        end if
        qres@gsnCenterStringFontColor = "black"
        qres2@gsnCenterStringFontColor = "black"
        qres@gsnLeftString = syear(0)+"-"+eyear(0) 
        qres@gsnRightString = ""  ; obs0@units
        qres@gsnCenterString = names(0)    
        plot_indmem(0) = gsn_csm_contour_map(wks,obs0,qres)

;----Identify type of grid the first observational dataset is on and set appropriate ESMF options
        InterpMethod = "bilinear"
        Opt                := True
        Opt@SrcTitle       = names(0)+" grid"   ; optional
        Opt@WgtFileName    = modname(0)+"_sms_.WgtFile_"+InterpMethod+".sims.nc"
        Opt@SrcFileName    = getenv("OUTDIR")+"/obs0.SCRIP_grid_description.sims.nc"         ; Name of source and
        Opt@SrcRegional    = True  ; will verify this below

        if (isatt(obs0,"coordinates")) then   ; curvilinear 
           Opt@SrcGridType    = "curvilinear"
           if (max(obs0@lat2d)-min(obs0@lat2d).gt.100) then
              Opt@SrcRegional    = False
           end if
        else
           Opt@SrcGridType    = "rectilinear"
           if ((max(obs0&j)-min(obs0&j)).gt.100) then
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
              fnt = getenv("OUTDIR")+modname(cntr)+".cvdp_data.siconc.mean_stddev."+syear(cntr)+"-"+eyear(cntr)+".nc"
              fnt2 = getenv("OUTDIR")+modname(cntr)+".cvdp_data."+syear(cntr)+"-"+eyear(cntr)+".nc"
              arr := read_cvdp_le_data(fnt,fnt2,variname_obs(dd))
              arr!0 = "j"
              arr!1 = "i"

              if (isatt(arr,"is_all_missing")) then
                 cntr = cntr+1
                 continue
              end if

              Opt@DstRegional    = True   ; set ESMF-regrid options
              if (isatt(arr,"coordinates")) then   ; curvilinear 
                 Opt@DstGridType    = "curvilinear"
                 Opt@DstGridLat     := arr@lat2d
                 Opt@DstGridLon     := arr@lon2d
                 if (max(arr@lat2d)-min(arr@lat2d).gt.100) then
                    Opt@DstRegional    = False
                 end if
              else
                 Opt@DstGridType    = "rectilinear"
                 if ((max(arr&j)-min(arr&j)).gt.100) then
                    Opt@DstRegional    = False
                 end if
                 Opt@DstGridLat     := arr&j
                 Opt@DstGridLon     := arr&i
              end if

              Opt@DstFileName    = getenv("OUTDIR")+Opt@DstGridType+".SCRIP_grid_description.sims.nc" 
              if (any(ismissing(obs0))) then
                 Opt@DstMask2D  := where(ismissing(arr),0,1)  ; set SrcMask2D option to indicate the missing values 
              end if

              if (dd.le.6) then
                 arr = where(arr.lt.1,arr@_FillValue,arr)
              else
                 arr = where(arr.eq.0,arr@_FillValue,arr)
              end if
              qres@gsnLeftString = syear(cntr)+"-"+eyear(cntr) 
              qres@gsnRightString = ""  
              qres@gsnCenterString = names(cntr)   
              plot_indmem(cntr) = gsn_csm_contour_map(wks,arr,qres)
              obs0_rg = ESMF_regrid(obs0, Opt)

              obs_diff = arr
              obs_diff = obs_diff@_FillValue
              dim0 = dimsizes(arr)
              dim1 = dimsizes(obs0_rg)
              if (dim0(0).eq.dim1(0).and.dim0(1).eq.dim1(1)) then
                 obs_diff = (/ arr - obs0_rg /)
              end if
              qres2@gsnLeftString = ""   
              qres2@gsnRightString = ""  
              qres2@gsnCenterString = names(cntr)+"-"+names(0)
              plot_indmem_diff(cntr) = gsn_csm_contour_map(wks,obs_diff,qres2)
              delete([/arr,obs_diff,obs0_rg,dim0,dim1/])
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
              modname_mod = modname(cntr_ens(hh))
              syear_mod = syear(cntr_ens(hh))
              eyear_mod = eyear(cntr_ens(hh))
              names_mod = names(cntr_ens(hh))
              names_EM_mod = names_EM(cntr_ens(hh))

              fnt = getenv("OUTDIR")+modname_mod+".cvdp_data.siconc.mean_stddev."+syear_mod+"-"+eyear_mod+".nc"
              fnt2 = getenv("OUTDIR")+modname_mod+".cvdp_data."+syear_mod+"-"+eyear_mod+".nc"
              arr := read_cvdp_le_data(fnt,fnt2,variname(dd))
              arr!0 = "j"
              arr!1 = "i"

              if (isatt(arr,"is_all_missing")) then
                 cntr = cntr+1
                 continue
              end if

              Opt@DstRegional    = True   ; set ESMF-regrid options
              if (isatt(arr,"coordinates")) then   ; curvilinear 
                 Opt@DstGridType    = "curvilinear"
                 Opt@DstGridLat     := arr@lat2d
                 Opt@DstGridLon     := arr@lon2d
                 if (max(arr@lat2d)-min(arr@lat2d).gt.100) then
                    Opt@DstRegional    = False
                 end if
              else
                 Opt@DstGridType    = "rectilinear"
                 if ((max(arr&j)-min(arr&j)).gt.100) then
                    Opt@DstRegional    = False
                 end if
                 dimNames = getvardimnames(arr)
                 Opt@DstGridLat     := arr&j
                 Opt@DstGridLon     := arr&i
                 delete(dimNames)
              end if
              Opt@DstFileName    = getenv("OUTDIR")+Opt@DstGridType+".SCRIP_grid_description.sims.nc" 
              if (any(ismissing(obs0))) then
                 Opt@DstMask2D  := where(ismissing(arr),0,1)  ; set SrcMask2D option to indicate the missing values 
              end if

              if (dd.le.6) then
                 arr = where(arr.lt.1,arr@_FillValue,arr)
              else
                 arr = where(arr.eq.0,arr@_FillValue,arr)
              end if
              if (.not.isvar("arr_store")) then  ; create an array to house all members, to be used to calculate EM
                 dimZ := dimsizes(arr)
                 arr_store = new((/nens,dimZ(0),dimZ(1)/),typeof(arr))
                 arr_store!0 = "ensmem"
                 arr_store!1 = "j"
                 arr_store!2 = "i"
                 if (Opt@DstGridType.eq."rectilinear") then
                    arr_store&j = arr&j
                    arr_store&i = arr&i
                 end if
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

              qres@gsnLeftString = syear_mod+"-"+eyear_mod 
              qres@gsnRightString = "" 
              qres@gsnCenterString = names_mod 

              plot_indmem(cntr) = gsn_csm_contour_map(wks,arr,qres)
              qres2@gsnLeftString = "" 
              qres2@gsnRightString = "" 
              qres2@gsnCenterString = names_mod+"-"+names(0)
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
              plot_indmem_diff(cntr) = gsn_csm_contour_map(wks,obs_diff,qres2)
              delete([/arr,obs_diff,dim0,dim1/])
              cntr = cntr+1
           end do
           if (nEM.eq.0) then   ; in individual member mode (runstyle=1)
              if (isvar("arr_store")) then
                 delete(arr_store)
              end if
              if (isvar("obs0_rg")) then
                 delete(obs0_rg)
              end if
              if (isfilepresent2(Opt@WgtFileName)) then
                 system("rm "+Opt@WgtFileName)
              end if
              continue
           end if
           if (.not.isvar("arr_store")) then
              cntr_EM = cntr_EM+4
              continue
           end if
           arr_EM = dim_avg_n_Wrap(arr_store,0)

           qres@gsnCenterStringFontColor = "black"
           qres2@gsnCenterStringFontColor = "black"

           if (lbFlag) then
              qres@lbLabelBarOn = True
              qres2@lbLabelBarOn = True
              tres@lbLabelBarOn = True

              qres@lbTitleString = arr_EM@units   
              qres2@lbTitleString = qres@lbTitleString  
           end if

           qres@gsnLeftString = syear(0)+"-"+eyear(0) 
           qres@gsnRightString = ""
           qres@gsnCenterString = names(0)   
           plot_summary(cntr_EM+1) = gsn_csm_contour_map(wks,obs0,qres)

           if (showyr) then
              qres@gsnLeftString = syear_em0+"-"+eyear_em0 
           else
              qres@gsnLeftString = (eyear_em0-syear_em0+1)+"yrs" 
           end if
           delete([/syear_em0,eyear_em0,showyr/])
           qres@gsnCenterStringFontColor = csubtitle_color(gg-1)
           qres@gsnRightString = "" 
           qres@gsnCenterString = names_EM_mod +" ("+arr_store@nens+" Members)"                   
           plot_summary(cntr_EM) = gsn_csm_contour_map(wks,arr_EM,qres)
           obs_diff = arr_EM
           obs_diff = obs_diff@_FillValue
           dim0 = dimsizes(arr_EM)
           dim1 = dimsizes(obs0_rg)
           if (dim0(0).eq.dim1(0).and.dim0(1).eq.dim1(1)) then
              obs_diff = (/ arr_EM - obs0_rg /)
           end if
           qres2@gsnLeftString = ""
           qres2@gsnCenterString = names_EM_mod+" - "+names(0) 
           qres2@gsnRightString = ""  
           plot_summary(cntr_EM+2) = gsn_csm_contour_map(wks,obs_diff,qres2)
           delete([/dim0,dim1/])

           p_val = calculate_pval(obs0_rg,arr_store)
           tres@gsnCenterString = "Rank of "+names(0)+" within Ensemble" 
           tres@gsnRightString = ""  ;calculate_area_in_range(p_val,10,90)+"%"
           plot_summary(cntr_EM+3) = gsn_csm_contour_map(wks,p_val,tres)
 
           fout = getenv("OUTDIR")+str_sub_str(names_EM_mod," ","_")+"_EM.cvdp_data.siconc.mean_stddev."+syear_mod+"-"+eyear_mod+".nc"
           if (isfilepresent2(fout)) then
              z = addfile(fout,"w")
           else
              z = addfile(fout,"c")
              set_global_ncfile_attributes(z,names_EM_mod,syear_mod,eyear_mod,getenv("VERSION"))
           end if
           if (isatt(arr_EM,"lat2d")) then
              LAT2D = arr_EM@lat2d
              LON2D = arr_EM@lon2d
              delete([/arr_EM@lat2d,arr_EM@lon2d,obs_diff@lat2d,obs_diff@lon2d,p_val@lat2d,p_val@lon2d/])
              copy_VarCoords(arr_EM,LAT2D)
              copy_VarCoords(arr_EM,LON2D)
              if (hemi(cc).eq."sh") then
                 LAT2D!0 = "j2"
                 LAT2D!1 = "i2"
                 LON2D!0 = "j2"
                 LON2D!1 = "i2"
              end if
              z->$(/"lat2d_ice_"+hemi(cc)/)$ = set_varAtts(LAT2D,hemi_long(cc)+" ice grid 2-dimensional latitudes","","")
              z->$(/"lon2d_ice_"+hemi(cc)/)$ = set_varAtts(LON2D,hemi_long(cc)+" ice grid 2-dimensional longitudes","","")
              delete([/LAT2D,LON2D/])
              arr_EM@coordinates ="lat2d_ice_"+hemi(cc)+" lon2d_ice_"+hemi(cc)
              obs_diff@coordinates ="lat2d_ice_"+hemi(cc)+" lon2d_ice_"+hemi(cc)
              p_val@coordinates ="lat2d_ice_"+hemi(cc)+" lon2d_ice_"+hemi(cc)
           end if 
           if (hemi(cc).eq."sh") then
              arr_EM!0 = "j2"
              arr_EM!1 = "i2"
              obs_diff!0 = "j2"
              obs_diff!1 = "i2"
              p_val!0 = "j2"
              p_val!1 = "i2"
           end if
           z->$(/variname(dd)+"_em"/)$ = set_varAtts(arr_EM,arr_EM@long_name+" Ensemble Mean","","")
           z->$(/variname(dd)+"_em_diffobs"/)$ = set_varAtts(obs_diff,obs_diff@long_name+" Ensemble Mean difference from "+names(0),"","")        
           z->$(/variname(dd)+"_pval"/)$ = set_varAtts(p_val,arr_EM@long_name+" p-val statistic","%","")     

           delete([/p_val,arr_store,obs0_rg,obs_diff,arr_EM/])
           if (isfilepresent2(Opt@WgtFileName)) then
              system("rm "+Opt@WgtFileName)
           end if
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
           delete([/plot_summary/])
        end if
        delete([/plot_indmem,plot_indmem_diff,wks,Opt,qres,qres2/])

        if (wks_type.eq."png") then
           system("mv "+OUTDIR+"siconc.mean_stddev.000001.png "+OUTDIR+variname(dd)+".indmem.png")
           system("mv "+OUTDIR+"siconc.mean_stddev.000002.png "+OUTDIR+variname(dd)+".indmemdiff.png")
           if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
              system("mv "+OUTDIR+"siconc.mean_stddev.000003.png "+OUTDIR+variname(dd)+".summary.png")
              if (PNG_SCALE_SUMMARY.ne.100) then
                 system(IM_COMMAND+" "+OUTDIR+variname(dd)+".summary.png -resize "+PNG_SCALE_SUMMARY+"% "+OUTDIR+variname(dd)+".summary.png")
              end if
           end if
        else
           system("psplit "+OUTDIR+"siconc.mean_stddev.ps "+OUTDIR+"siconc.mean_stddev")
           system("mv "+OUTDIR+"siconc.mean_stddev0001.ps "+OUTDIR+variname(dd)+".indmem.ps")
           system("mv "+OUTDIR+"siconc.mean_stddev0002.ps "+OUTDIR+variname(dd)+".indmemdiff.ps")
           if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
              system("mv "+OUTDIR+"siconc.mean_stddev0003.ps "+OUTDIR+variname(dd)+".summary.ps")
           end if
           system("rm "+OUTDIR+"siconc.mean_stddev.ps")
        end if
     end do  ; dd do loop
  end do     ; cc do loop
  print("Finished: siconc.mean_stddev.ncl")
end


