; Calculates SIC hemispheric linear trends and timeseries
;
; Variables used: sic
;
load "$CVDP_SCRIPTS/functions.ncl"

begin
  print("Starting: siconc.trends_timeseries.ncl")
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
  time_mon2 = ispan(0,11,1)
  time_mon2@units = "months since 0000-01-01 00:00:00"
  time_mon2@long_name = "Time"
  time_mon2@standard_name = "time"
  time_mon2@calendar = "standard"
  time_mon2!0 = "time_mon2"
  time_mon2&time_mon2 = time_mon2

  hemi = (/"nh","sh"/)
  hemi_long = (/"Northern Hemisphere","Southern Hemisphere"/)

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
;---------------------------------------------------
     do ee = 0,nsim-1
        fnt = getenv("OUTDIR")+modname(ee)+".cvdp_data.siconc.trends_timeseries."+syear(ee)+"-"+eyear(ee)+".nc"
        fnt2 = getenv("OUTDIR")+modname(ee)+".cvdp_data."+syear(ee)+"-"+eyear(ee)+".nc"
        f_test := read_cvdp_le_data(fnt,fnt2,"siconc_"+hemi(dd)+"_trends_ann")
        if (.not.isatt(f_test,"is_all_missing")) then
           continue
        end if
        arr = data_read_in_ice(paths(ee),"aice_"+hemi(dd),syear(ee),eyear(ee))    ; read in data, orient lats/lons correctly, set time coordinate variable up
        if (isatt(arr,"is_all_missing")) then
           delete(arr)
           continue
        end if  

        finarr = calculate_trends(rmMonAnnCycTLL(arr))   
        if (hemi(dd).eq."sh") then
           finarr!1 = "j2"
           finarr!2 = "i2"
        end if
        if (isatt(finarr,"area")) then
           delete(finarr@area)
        end if
;- - - - - - - - - - - - - - - - - - - - - - - - - - 
        if (isatt(arr,"area")) then
           arr = (/ where(arr.ge.15,1.,0.) /)  ; ice extent calculation (all cells greater than 15% treated as 100% covered)

           climo := clmMonTLL(arr)
           arr = calcMonAnomTLL(arr,climo)
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
                 arr = remove_trend(arr,REMOVE_TREND_MODEL,ensemble_mean_read_in(arr,ENSEMBLE_MEAN_DIR+str_sub_str(names_EM(ee)," ","_"),EM_num(ee),"aice_"+hemi(dd)+"_sie",syear,eyear,EM_num))
              end if
           end if

           do ff = 0,1   ; 0 = anomalies, 1 = no-anomalies where climo added back in 
              if (ff.eq.1) then   ; add the climo back in after detrending method applied
                 do ii = 0,dimsizes(arr&time)-1,12
                    arr(ii:ii+11,:,:) = (/ arr(ii:ii+11,:,:) + climo /)
                 end do
              end if
              area3d = arr@area
              area3d_c = conform(arr,area3d,(/1,2/))
              arr_sum = arr

              arr_sum = arr_sum*area3d_c
              wgts = arr_sum(0,:,:)
              wgts = 1.
              arr_sum_monT = arr_sum(:,0,0)   ; preallocate array to retain metadata
              arr_sum_monT = (/ wgt_areasum2(arr_sum,wgts,0) /)

              delete([/arr_sum_monT@area/])
              if (isatt(arr_sum_monT,"lat2d")) then
                 delete([/arr_sum_monT@lat2d,arr_sum_monT@lon2d/])
              end if
              if (isatt(arr_sum_monT,"i")) then
                 delete([/arr_sum_monT@i,arr_sum_monT@j/])
              end if
              if (hemi(dd).eq."nh".and.isatt(arr,"pole_hole_area")) then   ; special attribute set up to account for pole hole in grids. NSIDC assumes hole is 100% ice covered as of Jan 2016 
                 ph_area = todouble(arr_sum_monT@pole_hole_area)  ; format: start YYYYMM, end YYYYMM, area, start YYYYMM, end YYYYMM, area, etc.
                 dimZ_ph = dimsizes(ph_area)/3                       ; only used for Northern Hemisphere
                 temp_area_arr = arr_sum_monT
                 temp_area_arr&time = tofloat(cd_calendar(arr_sum_monT&time,1))
                 do gg = 0,dimZ_ph-1
                    print("gg = "+gg)
                    print(temp_area_arr({ph_area(gg*3):ph_area(gg*3+1)}))
                    temp_area_arr({ph_area(gg*3):ph_area(gg*3+1)}) = temp_area_arr({ph_area(gg*3):ph_area(gg*3+1)}) + tofloat(ph_area(gg*3+2))
                    print(temp_area_arr({ph_area(gg*3):ph_area(gg*3+1)}))
                 end do
                 arr_sum_monT = (/ temp_area_arr /)
                 delete([/ph_area,dimZ_ph,temp_area_arr/])
                 arr_sum_monT@pole_hole_area_included = True
              end if                
              arr_sum_monT = arr_sum_monT/1.e12
              arr_sum_monT@units = "10^12 m2"
              arr_sum_monT@long_name = "sea_ice_extent"
              if (isatt(arr_sum_monT,"coordinates")) then
                 delete(arr_sum_monT@coordinates)
              end if
              delete([/arr_sum,area3d,area3d_c,wgts/])
          
              if (ff.eq.0) then
                 arr_sie_mon_anom = arr_sum_monT
              end if
              if (ff.eq.1) then
                 arr_sum_mon = arr_sum_monT
              end if
              delete(arr_sum_monT)
           end do

           arr_sie_climo = new(12,typeof(arr_sum_mon))
           copy_VarAtts(arr_sum_mon,arr_sie_climo)
           arr_sie_climo!0 = "time_mon2"
           arr_sie_climo&time_mon2 = time_mon2
           do gg = 0,11
              arr_sie_climo(gg) = (/ avg(arr_sum_mon(gg::12)) /)
           end do   

           arr_sie_bymon := new((/12,nyr(ee)/),typeof(arr_sum_mon))
           arr_sie_bymon!1 = "TIME"
           arr_sie_bymon&TIME = ispan(syear(ee),eyear(ee),1)
           arr_sie_bymon&TIME@units = "YYYY"
           arr_sie_bymon&TIME@long_name = "time"
           arr_sie_bymon&TIME@standard_name = "time"
           arr_sie_bymon&TIME@calendar = "standard"

           copy_VarAtts(arr_sum_mon,arr_sie_bymon)
           do gg = 0,11
              arr_sie_bymon(gg,:) = (/ arr_sum_mon(gg::12) /)
           end do 

           arr_sie_seas := new((/7,nyr(ee)/),typeof(arr_sum_mon))
           arr_sie_seas!1 = "TIME"
           arr_sie_seas&TIME = ispan(syear(ee),eyear(ee),1)
           arr_sie_seas&TIME@units = "YYYY"
           arr_sie_seas&TIME@long_name = "time"
           arr_sie_seas&TIME@standard_name = "time"
           arr_sie_seas&TIME@calendar = "standard"
           copy_VarAtts(arr_sum_mon,arr_sie_seas)        

           temp := runave_Wrap(arr_sum_mon,3,0)
           arr_sie_seas(0,:) = (/ temp(0::12) /)
           arr_sie_seas(1,:) = (/ temp(1::12) /)
           arr_sie_seas(2,:) = (/ temp(3::12) /)
           arr_sie_seas(3,:) = (/ temp(6::12) /)
           arr_sie_seas(4,:) = (/ temp(7::12) /)
           arr_sie_seas(5,:) = (/ temp(9::12) /)
           temp := runave_Wrap(arr_sum_mon,12,0)
           arr_sie_seas(6,:) = (/ temp(5::12) /)
           delete(temp)
        end if
        delete(arr)    ; note that arr is set to 0/1's in sea ice extent coding above (in case code is added beyond here in future).

        if (isfilepresent2(fnt)) then
           z = addfile(fnt,"w")
        else
           z = addfile(fnt,"c")
        end if
        set_global_ncfile_attributes(z,names(ee),syear(ee),eyear(ee),getenv("VERSION"))
        if (isatt(finarr,"lat2d")) then    ; if there is a lat2d there will be a lon2d
           LAT2D = finarr@lat2d
           LON2D = finarr@lon2d
           delete([/finarr@lat2d,finarr@lon2d/])
           copy_VarCoords(finarr(0,:,:),LAT2D)
           copy_VarCoords(finarr(0,:,:),LON2D)
           z->$(/"lat2d_ice_"+hemi(dd)/)$ = set_varAtts(LAT2D,hemi_long(dd)+" ice grid 2-dimensional latitudes","","")
           z->$(/"lon2d_ice_"+hemi(dd)/)$ = set_varAtts(LON2D,hemi_long(dd)+" ice grid 2-dimensional longitudes","","")
           delete([/LAT2D,LON2D/])
           finarr@coordinates ="lat2d_ice_"+hemi(dd)+" lon2d_ice_"+hemi(dd)
        end if  
        if (isvar("arr_sie_seas")) then
           z->$(/"siconc_"+hemi(dd)+"_extent_climo"/)$      = set_varAtts( arr_sie_climo,hemi_long(dd)+" siconc extent climatology ","","")
 
           z->$(/"siconc_"+hemi(dd)+"_extent_mon"/)$      = set_varAtts(arr_sum_mon,hemi_long(dd)+" siconc extent timeseries (monthly)","","")
           z->$(/"siconc_"+hemi(dd)+"_extent_anom_mon"/)$ = set_varAtts(arr_sie_mon_anom,hemi_long(dd)+" siconc extent anomaly timeseries (monthly)","","")

           z->$(/"siconc_"+hemi(dd)+"_extent_feb"/)$    = set_varAtts(arr_sie_bymon(1,:),hemi_long(dd)+" siconc extent timeseries (February)","","")
           z->$(/"siconc_"+hemi(dd)+"_extent_mar"/)$    = set_varAtts(arr_sie_bymon(2,:),hemi_long(dd)+" siconc extent timeseries (March)","","")
           z->$(/"siconc_"+hemi(dd)+"_extent_sep"/)$    = set_varAtts(arr_sie_bymon(8,:),hemi_long(dd)+" siconc extent timeseries (September)","","")
           z->$(/"siconc_"+hemi(dd)+"_extent_oct"/)$    = set_varAtts(arr_sie_bymon(9,:),hemi_long(dd)+" siconc extent timeseries (October)","","")

           z->$(/"siconc_"+hemi(dd)+"_extent_djf"/)$    = set_varAtts(arr_sie_seas(0,:),hemi_long(dd)+" siconc extent timeseries (DJF)","","")
           z->$(/"siconc_"+hemi(dd)+"_extent_jfm"/)$    = set_varAtts(arr_sie_seas(1,:),hemi_long(dd)+" siconc extent timeseries (JFM)","","")
           z->$(/"siconc_"+hemi(dd)+"_extent_mam"/)$    = set_varAtts(arr_sie_seas(2,:),hemi_long(dd)+" siconc extent timeseries (MAM)","","")
           z->$(/"siconc_"+hemi(dd)+"_extent_jja"/)$    = set_varAtts(arr_sie_seas(3,:),hemi_long(dd)+" siconc extent timeseries (JJA)","","")
           z->$(/"siconc_"+hemi(dd)+"_extent_jas"/)$    = set_varAtts(arr_sie_seas(4,:),hemi_long(dd)+" siconc extent timeseries (JAS)","","")
           z->$(/"siconc_"+hemi(dd)+"_extent_son"/)$    = set_varAtts(arr_sie_seas(5,:),hemi_long(dd)+" siconc extent timeseries (SON)","","")
           z->$(/"siconc_"+hemi(dd)+"_extent_ann"/)$    = set_varAtts(arr_sie_seas(6,:),hemi_long(dd)+" siconc extent timeseries (annual)","","")
           delete([/arr_sie_seas,arr_sie_climo,arr_sum_mon,arr_sie_mon_anom,arr_sie_bymon/])
        end if
        z->$(/"siconc_"+hemi(dd)+"_trends_djf"/)$    = set_varAtts(finarr(0,:,:),hemi_long(dd)+" siconc linear trends (DJF)","","")
        z->$(/"siconc_"+hemi(dd)+"_trends_jfm"/)$    = set_varAtts(finarr(1,:,:),hemi_long(dd)+" siconc linear trends (JFM)","","")
        z->$(/"siconc_"+hemi(dd)+"_trends_mam"/)$    = set_varAtts(finarr(2,:,:),hemi_long(dd)+" siconc linear trends (MAM)","","")
        z->$(/"siconc_"+hemi(dd)+"_trends_jja"/)$    = set_varAtts(finarr(3,:,:),hemi_long(dd)+" siconc linear trends (JJA)","","")
        z->$(/"siconc_"+hemi(dd)+"_trends_jas"/)$    = set_varAtts(finarr(4,:,:),hemi_long(dd)+" siconc linear trends (JAS)","","")
        z->$(/"siconc_"+hemi(dd)+"_trends_son"/)$    = set_varAtts(finarr(5,:,:),hemi_long(dd)+" siconc linear trends (SON)","","")
        z->$(/"siconc_"+hemi(dd)+"_trends_ann"/)$    = set_varAtts(finarr(6,:,:),hemi_long(dd)+" siconc linear trends (annual)","","")     
        delete([/z,finarr/])
     end do ; ee loop
  end do    ; dd loop

  if (CREATE_GRAPHICS.eq."False") then
     print("Finished: siconc.trends_stddev.ncl")
     exit
  end if 
;==========================================================================================
  wks_type = OUTPUT_TYPE
  if (wks_type.eq."png") then
     wks_type@wkWidth = 1500*PNG_SCALE
     wks_type@wkHeight = 1500*PNG_SCALE
  end if

  res = True      ; spatial plot resource list
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
  res@lbTitleOn = False
  res@lbTitleFontHeightF = res@lbLabelFontHeightF
  res@lbTitlePosition = "Bottom"
  res@cnNoDataLabelOn = False

  res@gsnLeftStringOrthogonalPosF = -0.11
  res@gsnLeftStringParallelPosF = .005
  res@gsnRightStringOrthogonalPosF = -0.05
  res@gsnRightStringParallelPosF = 0.96
  res@gsnLeftStringFontHeightF = 0.014
  res@gsnCenterStringFontHeightF = 0.018
  res@gsnRightStringFontHeightF = 0.014
  res@gsnRightString = ""
  res@gsnLeftString = ""

  res2 = res   ; spatial differences resource list
  res2@cnConstFEnableFill = True
  res2@cnConstFLabelOn = False

  tres = res    ; p-value plots
  copy_VarAtts(retrieve_summary_res(),tres)

  res2@cnLevels = (/-40,-30,-25,-20,-15,-10,-5,0,5,10,15,20,25,30,40/)
  if (COLORMAP.eq.0) then
     res@cnLevels = (/-90,-70,-50,-45,-40,-35,-30,-25,-20,-15,-10,-5,0,5,10,15,20,25,30,35,40,45,50,70,90/)
     res@cnFillPalette = "ncl_default"
     res2@cnFillPalette = "ncl_default"
  end if
  if (COLORMAP.eq.1) then
     res@cnLevels = (/-40,-30,-25,-20,-15,-10,-5,0,5,10,15,20,25,30,40/)
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
  panres@lbBoxLineColor = "gray70"
  panres@txFontHeightF = 0.016
  panres@gsnPanelBottom = 0.05
  panres@lbLabelFontHeightF = 0.013
  panres@lbLabelStride = 1
  panres@lbTitleOn = False

  panres2 = panres     ; summary panel resource list
  panres2@gsnFrame = False
  panres2@gsnMaximize = False
  panres2@gsnPanelLabelBar = False
  panres2@lbTitleOn = False

  do cc = 0,dimsizes(hemi)-1  
     variname = (/"trends_djf","trends_jfm","trends_mam","trends_jja","trends_jas","trends_son","trends_ann"/)
     variname_obs = "siconc_"+hemi(cc)+"_"+variname 
     variname = "siconc_"+hemi(cc)+"_"+variname  
     variname_title = "siconc Trends"
     variname_title_seas = (/"DJF","JFM","MAM","JJA","JAS","SON","ANN"/)

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
     ncolE = floattointeger(sqrt(nEM+1))   ; +1 for the summary plot
     nrowE = ((nEM+1)/ncolE)+mod(nEM+1,ncolE)
;- - - - - - - - - - - 
     csubtitle_color = set_subtitle_colors(max(EM_num))
     do dd =   0,dimsizes(variname)-1  
        wks = gsn_open_wks(wks_type,getenv("OUTDIR")+"siconc.trends_timeseries")
        plot_indmem      = new(nsim,"graphic")
        plot_indmem_diff = new(nsim,"graphic")
        if (nEM.ge.1) then
           plot_summary     = new((nEM*4),"graphic")
        end if

        res@gsnPolar  = changeCaseChar(hemi(cc))
        res2@gsnPolar = res@gsnPolar
        tres@gsnPolar  = res@gsnPolar
        tres@lbLabelBarOn = False
        if (hemi(cc).eq."nh") then
           if (isatt(res,"mpMaxLatF")) then
              delete([/res@mpMaxLatF,res2@mpMaxLatF,tres@mpMaxLatF/])
           end if
           res@mpMinLatF  = 40.
           res2@mpMinLatF = 40.
           tres@mpMinLatF  = 40.
        else
           if (isatt(res,"mpMinLatF")) then
              delete([/res@mpMinLatF,res2@mpMinLatF,tres@mpMinLatF/])
           end if
           res@mpMaxLatF  = -40.
           res2@mpMaxLatF = -40.
           tres@mpMaxLatF  = -40.
        end if
        res@lbLabelBarOn = False
        res2@lbLabelBarOn = False
        tres@lbLabelBarOn = False

        numobs = num(EM_num.eq.0) 
        if (numobs.eq.0) then  ; if observations were not specified, set dummy file names, resulting in empty obs0 array
           fnt = getenv("OUTDIR")+"obs.cvdp_data.siconc.trends_timeseries."+syear(0)+"-"+eyear(0)+".nc"  
           fnt2 = getenv("OUTDIR")+"obs.cvdp_data."+syear(0)+"-"+eyear(0)+".nc"
           cntr = 0
        else
           fnt = getenv("OUTDIR")+modname(0)+".cvdp_data.siconc.trends_timeseries."+syear(0)+"-"+eyear(0)+".nc"
           fnt2 = getenv("OUTDIR")+modname(0)+".cvdp_data."+syear(0)+"-"+eyear(0)+".nc"
           cntr = 1
        end if
        obs0 := read_cvdp_le_data(fnt,fnt2,variname_obs(dd))
        obs0!0 = "j"
        obs0!1 = "i"
  
        obs0b := where(obs0.eq.0,obs0@_FillValue,obs0)  ; create two versions of obs0: One where obs0 values of 0 are masked (for individual plots)
        copy_VarMeta(obs0,obs0b)    ; and one where obs0 values of 0 are not masked (for difference plots) 

        res@gsnCenterStringFontColor = "black"
        res2@gsnCenterStringFontColor = "black"
        res@gsnLeftString = syear(0)+"-"+eyear(0)+" ~C~"+obs0b@units 
        res@gsnRightString = ""  
        res@gsnCenterString = names(0)    
        plot_indmem(0) = gsn_csm_contour_map(wks,obs0b,res)

;----Identify type of grid the first observational dataset is on and set appropriate ESMF options
        InterpMethod = "bilinear"
        Opt                := True
        Opt@SrcTitle       = names(0)+" grid"   ; optional
        Opt@WgtFileName    = modname(0)+"_sitt.WgtFile_"+InterpMethod+".nc"
        Opt@SrcFileName    = getenv("OUTDIR")+"/obs0.sitt.SCRIP_grid_description.nc"         ; Name of source and
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
              fnt = getenv("OUTDIR")+modname(cntr)+".cvdp_data.siconc.trends_timeseries."+syear(cntr)+"-"+eyear(cntr)+".nc"
              fnt2 = getenv("OUTDIR")+modname(cntr)+".cvdp_data."+syear(cntr)+"-"+eyear(cntr)+".nc"
              arr := read_cvdp_le_data(fnt,fnt2,variname_obs(dd))
              arr!0 = "j"
              arr!1 = "i"

              if (isatt(arr,"is_all_missing")) then
                 cntr = cntr+1
                 continue
              end if

              arrb  := where(arr.eq.0,arr@_FillValue,arr)  ; create two versions of arr: One where arr values of 0 are masked (for individual plots)
              copy_VarMeta(arr,arrb)    ; and one where arr values of 0 are not masked (for difference plots) 

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

              Opt@DstFileName    = getenv("OUTDIR")+Opt@DstGridType+".sitt.SCRIP_grid_description.nc" 
              if (any(ismissing(obs0))) then
                 Opt@DstMask2D  := where(ismissing(arr),0,1)  ; set SrcMask2D option to indicate the missing values 
              end if

              res@gsnLeftString = syear(cntr)+"-"+eyear(cntr)+" ~C~"+arrb@units   
              res@gsnRightString = ""  
              res@gsnCenterString = names(cntr)   
              plot_indmem(cntr) = gsn_csm_contour_map(wks,arrb,res)
              obs0_rg = ESMF_regrid(obs0, Opt)

              obs_diff = arr
              obs_diff = obs_diff@_FillValue
              dim0 = dimsizes(arr)
              dim1 = dimsizes(obs0_rg)
              if (dim0(0).eq.dim1(0).and.dim0(1).eq.dim1(1)) then
                 obs_diff = (/ arr - obs0_rg /)
              end if
              res2@gsnLeftString = ""   
              res2@gsnRightString = ""  
              res2@gsnCenterString = names(cntr)+"-"+names(0)
              plot_indmem_diff(cntr) = gsn_csm_contour_map(wks,obs_diff,res2)
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

              fnt = getenv("OUTDIR")+modname_mod+".cvdp_data.siconc.trends_timeseries."+syear_mod+"-"+eyear_mod+".nc"
              fnt2 = getenv("OUTDIR")+modname_mod+".cvdp_data."+syear_mod+"-"+eyear_mod+".nc"
              arr := read_cvdp_le_data(fnt,fnt2,variname(dd))
              arr!0 = "j"
              arr!1 = "i"

              if (isatt(arr,"is_all_missing")) then
                 cntr = cntr+1
                 continue
              end if

              arrb := where(arr.eq.0,arr@_FillValue,arr)  ; create two versions of arr: One where arr values of 0 are masked (for individual plots)
              copy_VarMeta(arr,arrb)    ; and one where arr values of 0 are not masked (for difference plots) 

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
              Opt@DstFileName    = getenv("OUTDIR")+Opt@DstGridType+".sitt.SCRIP_grid_description.nc" 
              if (any(ismissing(obs0))) then
                 Opt@DstMask2D  := where(ismissing(arr),0,1)  ; set SrcMask2D option to indicate the missing values 
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
                 res@gsnCenterStringFontColor = csubtitle_color(gg-1)
                 res2@gsnCenterStringFontColor = csubtitle_color(gg-1)
              end if
              arr_store(hh,:,:) = (/ arr /)
              arr_store@nens = arr_store@nens+1

              res@gsnLeftString = syear_mod+"-"+eyear_mod+" ~C~"+arrb@units   
              res@gsnRightString = ""  
              res@gsnCenterString = names_mod 
              plot_indmem(cntr) = gsn_csm_contour_map(wks,arrb,res)
              res2@gsnLeftString = "" 
              res2@gsnRightString = "" 
              res2@gsnCenterString = names_mod+"-"+names(0)
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
              plot_indmem_diff(cntr) = gsn_csm_contour_map(wks,obs_diff,res2)
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

           arr_EMb  = where(arr_EM.eq.0,arr_EM@_FillValue,arr_EM)  ; create two versions of arr: One where arr values of 0 are masked (for individual plots)
           copy_VarMeta(arr_EM,arr_EMb)    ; and one where arr values of 0 are not masked (for difference plots) 

           res@gsnCenterStringFontColor = "black"
           res2@gsnCenterStringFontColor = "black"

           if (lbFlag) then
              res@lbLabelBarOn = True
              res2@lbLabelBarOn = True
              tres@lbLabelBarOn = True

              res@lbTitleString = arr_EM@units   
              res2@lbTitleString = res@lbTitleString  
           end if

           res@gsnLeftString = syear(0)+"-"+eyear(0)+" ~C~"+obs0b@units   
           res@gsnRightString = ""  
           res@gsnCenterString = names(0)  
           plot_summary(cntr_EM+1) = gsn_csm_contour_map(wks,obs0b,res)

           if (showyr) then
              res@gsnLeftString = syear_em0+"-"+eyear_em0+" ~C~"+arr_EM@units   
           else
              res@gsnLeftString = (eyear_em0-syear_em0+1)+"yrs ~C~"+arr_EM@units   
           end if
           delete([/syear_em0,eyear_em0,showyr/])
           res@gsnCenterStringFontColor = csubtitle_color(gg-1)
           res@gsnRightString = ""  
           res@gsnCenterString = names_EM_mod +" ("+arr_store@nens+" Members)"                   
           plot_summary(cntr_EM) = gsn_csm_contour_map(wks,arr_EMb,res)
           obs_diff = arr_EM
           obs_diff = obs_diff@_FillValue
           dim0 = dimsizes(arr_EM)
           dim1 = dimsizes(obs0_rg)
           if (dim0(0).eq.dim1(0).and.dim0(1).eq.dim1(1)) then
              obs_diff = (/ arr_EM - obs0_rg /)
           end if
           res2@gsnLeftString = ""
           res2@gsnCenterString = names_EM_mod+" - "+names(0)  
           res2@gsnRightString = "" 
           plot_summary(cntr_EM+2) = gsn_csm_contour_map(wks,obs_diff,res2)

           p_val = calculate_pval(obs0_rg,arr_store)
           tres@gsnLeftString = "%"
           tres@gsnCenterString = "Rank of "+names(0)+" within Ensemble" 
           tres@gsnRightString = ""  ;calculate_area_in_range(p_val,10,90)+"%"
           plot_summary(cntr_EM+3) = gsn_csm_contour_map(wks,p_val,tres)

           fout = getenv("OUTDIR")+str_sub_str(names_EM_mod," ","_")+"_EM.cvdp_data.siconc.trends_timeseries."+syear_mod+"-"+eyear_mod+".nc"
           if (isfilepresent2(fout)) then
              z = addfile(fout,"w")
           else
              z = addfile(fout,"c")
              set_global_ncfile_attributes(z,names_EM_mod,syear_mod,eyear_mod,getenv("VERSION"))
           end if
           if (isatt(arr_EMb,"lat2d")) then    ; if there is a lat2d there will be a lon2d
              LAT2D = arr_EMb@lat2d
              LON2D = arr_EMb@lon2d
              delete([/arr_EMb@lat2d,arr_EMb@lon2d,obs_diff@lat2d,obs_diff@lon2d,p_val@lat2d,p_val@lon2d/])
              copy_VarCoords(arr_EMb,LAT2D)
              copy_VarCoords(arr_EMb,LON2D)
              if (hemi(cc).eq."sh") then
                 LAT2D!0 = "j2"
                 LAT2D!1 = "i2"
                 LON2D!0 = "j2"
                 LON2D!1 = "i2"
              end if
              z->$(/"lat2d_ice_"+hemi(cc)/)$ = set_varAtts(LAT2D,hemi_long(cc)+" ice grid 2-dimensional latitudes","","")
              z->$(/"lon2d_ice_"+hemi(cc)/)$ = set_varAtts(LON2D,hemi_long(cc)+" ice grid 2-dimensional longitudes","","")
              delete([/LAT2D,LON2D/])
              arr_EMb@coordinates ="lat2d_ice_"+hemi(cc)+" lon2d_ice_"+hemi(cc)
              obs_diff@coordinates ="lat2d_ice_"+hemi(cc)+" lon2d_ice_"+hemi(cc)
              p_val@coordinates ="lat2d_ice_"+hemi(cc)+" lon2d_ice_"+hemi(cc)
           end if 
           if (hemi(cc).eq."sh") then
              arr_EMb!0 = "j2"
              arr_EMb!1 = "i2"
              obs_diff!0 = "j2"
              obs_diff!1 = "i2"
              p_val!0 = "j2"
              p_val!1 = "i2"
           end if
           z->$(/variname(dd)+"_em"/)$ = set_varAtts(arr_EMb,arr_EMb@long_name+" Ensemble Mean","","")
           z->$(/variname(dd)+"_em_diffobs"/)$ = set_varAtts(obs_diff,obs_diff@long_name+" Ensemble Mean difference from "+names(0),"","")        
           z->$(/variname(dd)+"_pval"/)$ = set_varAtts(p_val,arr_EMb@long_name+" p-val statistic","%","")     

           delete([/obs_diff,arr_EM,dim0,dim1,arr_EMb,p_val,arr_store,obs0_rg/])
           if (isfilepresent2(Opt@WgtFileName)) then
              system("rm "+Opt@WgtFileName)
           end if
           cntr_EM = cntr_EM+4
        end do
        panres@txString = variname_title+" ("+variname_title_seas(dd)+")"
        gsn_panel2(wks,plot_indmem,(/nrow,ncol/),panres)

        panres@txString = variname_title+" Differences ("+variname_title_seas(dd)+")"
        gsn_panel2(wks,plot_indmem_diff,(/nrow,ncol/),panres)

        if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
           panres2@txString = "Ensemble Summary: "+variname_title+" ("+variname_title_seas(dd)+")"
           gsn_panel2(wks,plot_summary,(/nEM,4/),panres2)
           frame(wks)
           delete([/plot_summary/])
        end if
        delete([/plot_indmem,plot_indmem_diff,wks,Opt/])

        if (wks_type.eq."png") then
           system("mv "+OUTDIR+"siconc.trends_timeseries.000001.png "+OUTDIR+variname(dd)+".indmem.png")
           system("mv "+OUTDIR+"siconc.trends_timeseries.000002.png "+OUTDIR+variname(dd)+".indmemdiff.png")
           if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
              system("mv "+OUTDIR+"siconc.trends_timeseries.000003.png "+OUTDIR+variname(dd)+".summary.png")
              if (PNG_SCALE_SUMMARY.ne.100) then
                 system(IM_COMMAND+" "+OUTDIR+variname(dd)+".summary.png -resize "+PNG_SCALE_SUMMARY+"% "+OUTDIR+variname(dd)+".summary.png")
              end if
           end if
        else
           system("psplit "+OUTDIR+"siconc.trends_timeseries.ps "+OUTDIR+"siconc.trends_timeseries")
           system("mv "+OUTDIR+"siconc.trends_timeseries0001.ps "+OUTDIR+variname(dd)+".indmem.ps")
           system("mv "+OUTDIR+"siconc.trends_timeseries0002.ps "+OUTDIR+variname(dd)+".indmemdiff.ps")
           if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
              system("mv "+OUTDIR+"siconc.trends_timeseries0003.ps "+OUTDIR+variname(dd)+".summary.ps")
           end if
           system("rm "+OUTDIR+"siconc.trends_timeseries.ps")
        end if
     end do  ; dd do loop
  end do     ; cc do loop
  delete([/panres,panres2,res,res2,tres/])
;-----------------------------------------------------------------------------
; Timeseries plotting section
;
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
  xyres@gsnRightStringOrthogonalPosF = 0.036
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

  do cc = 0,dimsizes(hemi)-1  
     variname := (/"extent_mon","extent_anom_mon","extent_feb","extent_mar","extent_sep","extent_oct",\
               "extent_djf","extent_jfm","extent_mam","extent_jja","extent_jas","extent_son","extent_ann"/)
     variname_obs := "siconc_"+hemi(cc)+"_"+variname  
     variname = "siconc_"+hemi(cc)+"_"+variname  
     variname_title := variname
     variname_title(0) = "siconc "+changeCaseChar(hemi(cc))+" Extent"
     variname_title(1) = "siconc "+changeCaseChar(hemi(cc))+" Extent Anomalies"
     variname_title(2:) = "siconc "+changeCaseChar(hemi(cc))+" Extent"
     variname_title_seas := (/"Monthly","Monthly","Feb","Mar","Sep","Oct","DJF","JFM","MAM","JJA","JAS","SON","ANN"/)

;- - - - - - - - - - - 
     nsim := numAsciiRow("namelist_byvar/namelist_aice_"+hemi(cc))
     na := asciiread("namelist_byvar/namelist_aice_"+hemi(cc),(/nsim/),"string")
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

     ncolE = floattointeger(sqrt(nEM+1))   ; +1 for the summary plot
     nrowE = ((nEM+1)/ncolE)+mod(nEM+1,ncolE)
;- - - - - - - - - - - 
     csubtitle_color := set_subtitle_colors(max(EM_num))
     nEM = max(EM_num)
     do dd =   0,dimsizes(variname)-1  
        wks = gsn_open_wks(wks_type,getenv("OUTDIR")+"siconc.timeseries")
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

        XMinF := new(1,float)    ; used for summary timeseries plot showing all ensemble means
        XMaxF := new(1,float)
        YMinF := new(1,float)
        YMaxF := new(1,float)

        numobs = num(EM_num.eq.0) 
        if (numobs.eq.0) then
           fnt = getenv("OUTDIR")+"obs.cvdp_data.siconc.trends_timeseries."+syear(0)+"-"+eyear(0)+".nc"
           fnt2 = getenv("OUTDIR")+"obs.cvdp_data."+syear(0)+"-"+eyear(0)+".nc"
           cntr = 0
        else
           fnt = getenv("OUTDIR")+modname(0)+".cvdp_data.siconc.trends_timeseries."+syear(0)+"-"+eyear(0)+".nc"
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
        if (isatt(xyres,"trYMinF")) then
           delete([/xyres@trYMinF,xyres@trYMaxF/])
        end if

        if (dd.le.1) then   ; analyzing monthly timeseries
           if (isatt(obs0,"is_all_missing")) then 
              obs0_time := obs0&time   
           else
              obs0_time := cd_calendar(obs0&time,4)
           end if
        else
           obs0_time := obs0&time
        end if

        xyres@gsnLeftStringFontColor = "black"
        xyres2@gsnLeftStringFontColor = "black"
        xyres@trXMinF = syear(0)-.5
        xyres@trXMaxF = eyear(0)+0.5
        xyres@gsnLeftString = names(0)
        if (all(ismissing(obs0))) then
           obs_val = "Insufficient Coverage"
           ztxt = ""
        else
           ztxt = "Linear trend = "
           tttt := dtrend_msg(ispan(0,dimsizes(obs0&time)-1,1),obs0,False,True)   
           obs_val := decimalPlaces(tttt@slope*dimsizes(obs0&time),2,True)+" "+obs0@units+" "+nyr(0)+"yr~S~-1~N~"
        end if

        xyres@gsnRightString = obs_val
        plot_indmem(0) = gsn_csm_xy(wks,obs0_time,obs0,xyres)
        xyres2A@gsnLeftString = "Ensemble Mean Summary"
        plot_obs := gsn_csm_xy(wks,obs0_time,obs0,xyres2A)
        cntr_EM = 0
        if (numobs.ge.2) then     ; plot obs #2-
           do ff = 1,numobs-1
              fnt = getenv("OUTDIR")+modname(cntr)+".cvdp_data.siconc.trends_timeseries."+syear(cntr)+"-"+eyear(cntr)+".nc"
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
              if (dd.le.1) then   ; analyzing monthly timeseries
                 arr_time := cd_calendar(arr&time,4)
              else
                 arr_time := arr&time
              end if
              xyres@gsnLeftString = names(cntr)
              xyres@gsnRightString = decimalPlaces(tttt@slope*dimsizes(arr&time),2,True)+" "+arr@units+" "+nyr(cntr)+"yr~S~-1~N~"
              plot_indmem(cntr) = gsn_csm_xy(wks,arr_time,arr,xyres)
              plot_obs_overlay(cntr) = gsn_csm_xy(wks,obs0_time,obs0,xyres2)
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
              fnt = getenv("OUTDIR")+modname_mod+".cvdp_data.siconc.trends_timeseries."+syear_mod+"-"+eyear_mod+".nc"
              fnt2 = getenv("OUTDIR")+modname_mod+".cvdp_data."+syear_mod+"-"+eyear_mod+".nc"
              arr := read_cvdp_le_data(fnt,fnt2,variname(dd))
              if (isatt(arr,"is_all_missing")) then 
                 cntr = cntr+1
                 continue
              end if
              arr!0 = "time"
              time_save := arr&time   ; for ensemble means to be written out below
              if (dd.le.1) then   ; analyzing monthly timeseries
                 arr_time := tofloat(cd_calendar(arr&time,4))
              else
                 arr_time := arr&time
              end if

              if (.not.isvar("arr_store")) then  ; create an array to house all members, to be used to calculate EM
                 arr_store := new((/nens,dimsizes(arr&time)/),typeof(arr))
                 arr_store!0 = "ensmem"
                 arr_store!1 = "time"
                 arr_store&time = arr_time
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
              xyres@gsnRightString = decimalPlaces(tttt@slope*dimsizes(arr&time),2,True)+" "+arr@units+" "+nyr(cntr)+"yr~S~-1~N~"
              plot_indmem(cntr) = gsn_csm_xy(wks,arr_time,arr,xyres)
              plot_obs_overlay(cntr) = gsn_csm_xy(wks,obs0_time,obs0,xyres2)
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

           XMinF := min((/XMinF,min(arr_EM&time)/))
           XMaxF := max((/XMaxF,max(arr_EM&time)/))
           YMinF := min((/YMinF,min(arr_EM),min(obs0)/))
           YMaxF := max((/YMaxF,max(arr_EM),max(obs0)/))

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
           if (numobs.eq.0) then
              xyres_sum@gsnCenterString = ""
           else
              obs0z := obs0
              delete(obs0z&time)
              obs0z&time = obs0_time


              xyres_sum@gsnCenterString = calculate_percent_in_range(obs0z,arr_range2)+"%"
              delete(obs0z)
           end if
           ss_slope := ssss@slope
           ss_slope@_FillValue = arr_store@_FillValue
           stats := boxplot_stat(ss_slope)
           xyres3_sum@gsnRightString = decimalPlaces(stats(0)*dimsizes(arr_EM),2,True)+"/"+decimalPlaces(tttt@slope*dimsizes(arr_EM),2,True)+"/"+decimalPlaces(stats(4)*dimsizes(arr_EM),2,True)+" "+arr_EM@units+" "+dimsizes(arr_EM)+"yr~S~-1~N~"
           plot_summary(cntr_EM) = gsn_csm_xy(wks,arr_time,arr_range2,xyres3_sum)
           plot_summary1(cntr_EM) = gsn_csm_xy(wks,arr_time,arr_range1,xyres3b_sum)
           plot_summary2(cntr_EM) = gsn_csm_xy(wks,arr_time,arr_EM,xyres_sum)
           plot_summary_obs_overlay(cntr_EM) = gsn_csm_xy(wks,obs0_time,obs0,xyres2_sum)
           xyres_sumA@gsnLeftString = "Ensemble Mean Summary"
           plot_sum(cntr_EM) = gsn_csm_xy(wks,arr_time,arr_EM,xyres_sumA)
           overlay(plot_summary(cntr_EM),plot_summary1(cntr_EM))
           overlay(plot_summary(cntr_EM),plot_summary_obs_overlay(cntr_EM))
           overlay(plot_summary(cntr_EM),plot_summary2(cntr_EM))

           if (variname(dd).eq."siconc_nh_extent_mon".or.variname(dd).eq."siconc_sh_extent_mon".or.variname(dd).eq."siconc_nh_extent_anom_mon".or.variname(dd).eq."siconc_sh_extent_anom_mon".or.variname(dd).eq."siconc_nh_prime_extent_mon".or.variname(dd).eq."siconc_sh_prime_extent_mon".or.variname(dd).eq."siconc_nh_prime_extent_anom_mon".or.variname(dd).eq."siconc_sh_prime_extent_anom_mon") then
              arr_EM!0 = "time"
              arr_range1!1 = "time"
              arr_range2!1 = "time"
              arr_EM&time = time_save
              arr_range1&time = time_save
              arr_range2&time = time_save
           else
              arr_EM!0 = "TIME"
              arr_range1!1 = "TIME"
              arr_range2!1 = "TIME"
           end if

           fout = getenv("OUTDIR")+str_sub_str(names_EM_mod," ","_")+"_EM.cvdp_data.siconc.trends_timeseries."+syear_mod+"-"+eyear_mod+".nc"
           if (isfilepresent2(fout)) then
              z = addfile(fout,"w")
           else
              z = addfile(fout,"c")
              set_global_ncfile_attributes(z,names_EM_mod,syear_mod,eyear_mod,getenv("VERSION"))
           end if

           z->$(/variname(dd)+"_em"/)$ = set_varAtts(arr_EM,arr_EM@long_name+" Ensemble Mean","","")
           z->$(/variname(dd)+"_2575range"/)$ = set_varAtts(arr_range1,arr_EM@long_name+" 25/75% range","","")
           z->$(/variname(dd)+"_1090range"/)$ = set_varAtts(arr_range2,arr_EM@long_name+" 10/90% range","","")
           delete([/arr_EM,z,tttt,ssss,arr_store,time_save/])
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
              system("mv "+OUTDIR+"siconc.timeseries.png "+OUTDIR+variname(dd)+".indmem.png")
           else
              system("mv "+OUTDIR+"siconc.timeseries.000001.png "+OUTDIR+variname(dd)+".indmem.png")
              system("mv "+OUTDIR+"siconc.timeseries.000002.png "+OUTDIR+variname(dd)+".summary.png")
              if (PNG_SCALE_SUMMARY.ne.100) then
                 system(IM_COMMAND+" "+OUTDIR+variname(dd)+".summary.png -resize "+PNG_SCALE_SUMMARY+"% "+OUTDIR+variname(dd)+".summary.png")
              end if
           end if
        else
           system("psplit "+OUTDIR+"siconc.timeseries.ps "+OUTDIR+"siconc.timeseries")
           system("mv "+OUTDIR+"siconc.timeseries0001.ps "+OUTDIR+variname(dd)+".indmem.ps")
           if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
              system("mv "+OUTDIR+"siconc.timeseries0002.ps "+OUTDIR+variname(dd)+".summary.ps")
              system("rm "+OUTDIR+"siconc.timeseries.ps")
           end if
        end if
     end do
  end do
  delete([/xyres,xyres2,panres3,panres4/])
;-------------------------------------------------------------------------------------------------------------------
;   siconc climatology plotting section
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
  bres@tmYLLabelFontHeightF = 0.018
  bres@tmXBLabelFontHeightF = 0.018
  bres@tmXBLabels = (/"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"/)
  bres@tmXTOn = False
  bres@tiMainFont = "Helvetica"
  bres@tiMainString = ""
  bres@tiMainFontHeightF = 0.02
  bres@tiMainOffsetYF = -0.005
  llres                   = True			
  llres@gsLineThicknessF  = 6.                 ; line thickness 
  llres@gsLineDashPattern = 0
  opti          = True			
  opti@boxWidth = .65				; Width of box (x units)
  colors = new(12,string)
  colors = "black"
  opti@boxColors = colors

  panres = True
  panres@gsnMaximize = True  
  panres@gsnPaperOrientation = "portrait"
  panres@gsnMainPanelFontHeightF = 0.009
  panres@gsnPanelBottom = 0.05

  panres2 = panres
  panres2@gsnFrame = False
  panres2@gsnMaximize = False
  panres2@gsnMainPanelFontHeightF = 0.007

  polyres = True
  polyres@gsLineColor = "orange"

  txres = True
  txres@txFontHeightF = 0.010
  txres@txFontColor = polyres@gsLineColor


  do cc = 0,dimsizes(hemi)-1  
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
     csubtitle_color := set_subtitle_colors(max(EM_num))

     wks = gsn_open_wks(wks_type,getenv("OUTDIR")+"siconc.trends_timeseries")
     plot_indmem      := new(nsim,"graphic")
     polyline_overlay := new((/nsim,12/),"graphic")
     if (nEM.ge.1) then
        plot_summary     := new(nEM,"graphic")
        polyline_overlay_em := new((/nEM,12/),"graphic")
     end if
     numobs = num(EM_num.eq.0) 
     if (numobs.eq.0) then
        fnt = getenv("OUTDIR")+"obs.cvdp_data.siconc.trends_timeseries."+syear(0)+"-"+eyear(0)+".nc"
        fnt2 = getenv("OUTDIR")+"obs.cvdp_data."+syear(0)+"-"+eyear(0)+".nc"
        cntr = 0
     else
        fnt = getenv("OUTDIR")+modname(0)+".cvdp_data.siconc.trends_timeseries."+syear(0)+"-"+eyear(0)+".nc"
        fnt2 = getenv("OUTDIR")+modname(0)+".cvdp_data."+syear(0)+"-"+eyear(0)+".nc"
        cntr = 1
     end if

     obs0 := read_cvdp_le_data(fnt,fnt2,"siconc_"+hemi(cc)+"_extent_climo")

     if (isatt(obs0,"is_all_missing")) then
        obs0New = new(12,float)
        copy_VarAtts(obs0,obs0New)
        obs0 := obs0New
        delete(obs0New)
     end if

     xyres@trYMaxF = max(obs0)*1.2
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
           fnt = getenv("OUTDIR")+modname(cntr)+".cvdp_data.siconc.trends_timeseries."+syear(cntr)+"-"+eyear(cntr)+".nc"
           fnt2 = getenv("OUTDIR")+modname(cntr)+".cvdp_data."+syear(cntr)+"-"+eyear(cntr)+".nc"
           arr := read_cvdp_le_data(fnt,fnt2,"siconc_"+hemi(cc)+"_extent_climo")
           if (isatt(arr,"is_all_missing")) then
              cntr = cntr+1
              continue
           end if
           xyres@trYMaxF = max((/max(obs0),max(arr)/))*1.2
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

           fnt = getenv("OUTDIR")+modname_mod+".cvdp_data.siconc.trends_timeseries."+syear_mod+"-"+eyear_mod+".nc"
           fnt2 = getenv("OUTDIR")+modname_mod+".cvdp_data."+syear_mod+"-"+eyear_mod+".nc"
           arr := read_cvdp_le_data(fnt,fnt2,"siconc_"+hemi(cc)+"_extent_climo")
           if (isatt(arr,"is_all_missing")) then
              cntr = cntr+1
              continue
           end if
           xyres@trYMaxF = max((/max(obs0),max(arr)/))*1.2
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
              delete([/arr_store/])
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
        arrEM&ncurves4@units = arr_store@units
        do ii = 0,11
           ds := boxplot_stat(arr_store(:,ii))
           arrEM(ii,:) =  (/ds(0),ds(1),dim_avg(arr_store(:,ii)),ds(3),ds(4)/)
        end do
        bres@trYMaxF = max((/max(obs0),max(arrEM)/))*1.1

        bres@tiMainFontColor = csubtitle_color(gg-1)
        bres@tiMainString = names_EM_mod+" "+syear_mod+"-"+eyear_mod+" ("+arr_store@nens+")"
        plot_summary(cntr_EM) = boxplot(wks,ispan(1,12,1),arrEM,opti,bres,llres)	

        polyres@gsLineThicknessF = 7.5
        if (.not.isatt(obs0,"is_all_missing")) then
           do jj = 0,11
              polyline_overlay_em(cntr_EM,jj)   = gsn_add_polyline(wks,plot_summary(cntr_EM),(/(jj+1)-.4,(jj+1)+.4/),(/obs0(jj),obs0(jj)/),polyres)
           end do
        end if

        fout = getenv("OUTDIR")+str_sub_str(names_EM_mod," ","_")+"_EM.cvdp_data.siconc.trends_timeseries."+syear_mod+"-"+eyear_mod+".nc"
        if (isfilepresent2(fout)) then
           z = addfile(fout,"w")
        else
           z = addfile(fout,"c")
           set_global_ncfile_attributes(z,names_EM_mod,syear_mod,eyear_mod,getenv("VERSION"))
        end if
        z->$(/"siconc_"+hemi(cc)+"_extent_climo_stats"/)$ = set_varAtts(arrEM,"","","")
        delete([/arr_store,arrEM/])
        cntr_EM = cntr_EM+1
     end do
     panres@txString = "siconc "+changeCaseChar(hemi(cc))+" Extent Climatology"
     gsn_panel2(wks,plot_indmem,(/nrow,ncol/),panres)

     if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
        panres2@gsnPanelMainString = "Ensemble Summary: siconc "+changeCaseChar(hemi(cc))+" Extent Climatology"
        panres2@gsnPanelXWhiteSpacePercent = 3.0
        panres2@gsnPanelYWhiteSpacePercent = 3.0
        panres2@gsnPanelTop = 0.94
        panres2@gsnPanelMainPosYF = set_panel_title_YF(nEM-1,xyres)
        gsn_panel2(wks,plot_summary,(/nrowE,ncolE/),panres2)
        if (numobs.ne.0) then
           gsn_text_ndc(wks,names(0)+" "+syear(0)+"-"+eyear(0),0.5,panres2@gsnPanelMainPosYF-.02,txres)
        end if
        frame(wks)
        delete(plot_summary)
     end if
     delete([/wks,plot_indmem/])

     if (wks_type.eq."png") then
        if (nEM.lt.1) then   ; in ensemble mode (runstyle=2)
           system("mv "+OUTDIR+"siconc.trends_timeseries.png "+OUTDIR+"siconc_"+hemi(cc)+"_extent.climo.indmem.png")
        else
           system("mv "+OUTDIR+"siconc.trends_timeseries.000001.png "+OUTDIR+"siconc_"+hemi(cc)+"_extent.climo.indmem.png")
           system("mv "+OUTDIR+"siconc.trends_timeseries.000002.png "+OUTDIR+"siconc_"+hemi(cc)+"_extent.climo.summary.png")
           if (PNG_SCALE_SUMMARY.ne.100) then
              system(IM_COMMAND+" "+OUTDIR+"siconc_"+hemi(cc)+"_extent.climo.summary.png -resize "+PNG_SCALE_SUMMARY+"% "+OUTDIR+"siconc_"+hemi(cc)+"_extent.climo.summary.png")
           end if
        end if
     else
        system("psplit "+OUTDIR+"siconc.trends_timeseries.ps "+OUTDIR+"siconc.trends_timeseries")
        system("mv "+OUTDIR+"siconc.trends_timeseries0001.ps "+OUTDIR+"siconc_"+hemi(cc)+"_extent.climo.indmem.ps")
        if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
           system("mv "+OUTDIR+"siconc.trends_timeseries0002.ps "+OUTDIR+"siconc_"+hemi(cc)+"_extent.climo.summary.ps")
        end if
        system("rm "+OUTDIR+"siconc.trends_timeseries.ps")
     end if
  end do
  delete([/xyres,opti,bres,llres,polyres,polyline_overlay,panres,panres2/])
  print("Finished: siconc.trends_timeseries.ncl")
end

