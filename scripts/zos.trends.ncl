; Calculates zos means and standard deviations
;
; Variables used: zos
;
load "$CVDP_SCRIPTS/functions.ncl"

begin
  print("Starting: zos.trends.ncl")
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

  nsim := numAsciiRow("namelist_byvar/namelist_ssh")
  na := asciiread("namelist_byvar/namelist_ssh",(/nsim/),"string")
  names := new(nsim,"string")
  paths := new(nsim,"string")
  syear := new(nsim,"integer",-999)
  eyear := new(nsim,"integer",-999)
  names_EM := new(nsim,"string")
  EM_num := new(nsim,"integer",-999)
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

  do ee = 0,nsim-1
     fnt = getenv("OUTDIR")+modname(ee)+".cvdp_data.zos.trends."+syear(ee)+"-"+eyear(ee)+".nc"
     fnt2 = getenv("OUTDIR")+modname(ee)+".cvdp_data."+syear(ee)+"-"+eyear(ee)+".nc"
     f_test := read_cvdp_le_data(fnt,fnt2,"zos_trends_ann")
     if (.not.isatt(f_test,"is_all_missing")) then
        continue
     end if

     arr = data_read_in_ocean(paths(ee),"SSH",syear(ee),eyear(ee))    ; read in data, orient lats/lons correctly, set time coordinate variable up
     if (isatt(arr,"is_all_missing")) then
        delete(arr)
        continue
     end if  
     arr = rmMonAnnCycTLL(arr) 

     finarr = calculate_trends(arr)   

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
        z->$(/"lat2d_ocean"/)$ = set_varAtts(LAT2D,"ocean grid 2-dimensional latitudes","degrees_north","")
        z->$(/"lon2d_ocean"/)$ = set_varAtts(LON2D,"ocean grid 2-dimensional longitudes","degrees_east","")
        delete([/LAT2D,LON2D/])
        finarr@coordinates ="lat2d_ocean lon2d_ocean"
     end if  
     z->$(/"zos_trends_djf"/)$     = set_varAtts(finarr(0,:,:),"zos linear trends (DJF)","","")
     z->$(/"zos_trends_jfm"/)$     = set_varAtts(finarr(1,:,:),"zos linear trends (JFM)","","")
     z->$(/"zos_trends_mam"/)$     = set_varAtts(finarr(2,:,:),"zos linear trends (MAM)","","")
     z->$(/"zos_trends_jja"/)$     = set_varAtts(finarr(3,:,:),"zos linear trends (JJA)","","")
     z->$(/"zos_trends_jas"/)$     = set_varAtts(finarr(4,:,:),"zos linear trends (JAS)","","")
     z->$(/"zos_trends_son"/)$     = set_varAtts(finarr(5,:,:),"zos linear trends (SON)","","")
     z->$(/"zos_trends_ann"/)$     = set_varAtts(finarr(6,:,:),"zos linear trends (annual)","","")
     delete([/z,finarr,arr/])
  end do    ; ee loop

  if (CREATE_GRAPHICS.eq."False") then
     print("Finished: zos.trends.ncl")
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
  res@mpLandFillColor = "gray75"  
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
  res@lbTitleOn = False
  res@lbTitleFontHeightF = res@lbLabelFontHeightF
  res@lbTitlePosition = "Bottom"
  res@cnNoDataLabelOn = False
  res@trGridType = "TriangularMesh"

  res@cnLevelSelectionMode = "ExplicitLevels"
  res@cnFillMode = "RasterFill"
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

  res2@cnLevels = (/-20,-16,-12,-8,-4,-2,-1,0,1,2,4,8,12,16,20/)
  if (COLORMAP.eq.0) then
     res@cnLevels = (/-24,-20,-16,-12,-8,-6,-4,-2,-1,0,1,2,4,6,8,12,16,20,24/)
     res@cnFillPalette = "ncl_default"
     res2@cnFillPalette = "ncl_default"
  end if
  if (COLORMAP.eq.1) then
     res@cnLevels = (/-16,-12,-10,-8,-6,-4,-2,0,2,4,6,8,10,12,16/)
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
  ncol = floattointeger(sqrt(nsim))
  nrow = (nsim/ncol)+mod(nsim,ncol)

  panres2 = panres     ; summary panel resource list
  panres2@gsnFrame = False
  panres2@gsnMaximize = False
  panres2@gsnPanelLabelBar = False
  panres2@lbTitleOn = False

  variname = (/"trends_djf","trends_jfm","trends_mam","trends_jja","trends_jas","trends_son","trends_ann"/)
  variname_obs = "zos_"+variname
  variname = "zos_"+variname
  variname_title = new(dimsizes(variname),string)
  variname_title = "ZOS Trends"
  variname_title_seas = (/"DJF","JFM","MAM","JJA","JAS","SON","ANN"/)
;- - - - - - - - - - - 
  csubtitle_color = set_subtitle_colors(max(EM_num))
  nEM = max(EM_num)
  do dd =   0,dimsizes(variname)-1  
     wks = gsn_open_wks(wks_type,getenv("OUTDIR")+"zos.trends")
     plot_indmem      = new(nsim,"graphic")
     plot_indmem_diff = new(nsim,"graphic")
     if (nEM.ge.1) then
        plot_summary     = new((nEM*4),"graphic")
     end if

     qres = res     ; trends resource list
     qres2 = res2


     numobs = num(EM_num.eq.0) 
     if (numobs.eq.0) then  ; if observations were not specified, set dummy file names, resulting in empty obs0 array
        fnt = getenv("OUTDIR")+"obs.cvdp_data.zos.trends."+syear(0)+"-"+eyear(0)+".nc"  
        fnt2 = getenv("OUTDIR")+"obs.cvdp_data."+syear(0)+"-"+eyear(0)+".nc"
        cntr = 0
     else
        fnt = getenv("OUTDIR")+modname(0)+".cvdp_data.zos.trends."+syear(0)+"-"+eyear(0)+".nc"
        fnt2 = getenv("OUTDIR")+modname(0)+".cvdp_data."+syear(0)+"-"+eyear(0)+".nc"
        cntr = 1
     end if
     obs0 := read_cvdp_le_data(fnt,fnt2,variname_obs(dd))

     qres@gsnCenterStringFontColor = "black"
     qres2@gsnCenterStringFontColor = "black"
     qres@gsnLeftString = syear(0)+"-"+eyear(0)+" ~C~"+obs0@units
     qres@gsnRightString = ""  ; obs0@units
     qres@gsnCenterString = names(0)    
     if (.not.isatt(obs0,"is_all_missing")) then
        plot_indmem(0) = gsn_csm_contour_map(wks,obs0,qres)
     end if

;----Identify type of grid the first observational dataset is on and set appropriate ESMF options
     InterpMethod = "bilinear"
     Opt                := True
     Opt@SrcTitle       = names(0)+" grid"   ; optional
     Opt@WgtFileName    = modname(0)+"_to_zt.WgtFile_"+InterpMethod+".nc"
     Opt@SrcFileName    = getenv("OUTDIR")+"/obs0.zt.SCRIP_grid_description.nc"         ; Name of source and
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
           fnt = getenv("OUTDIR")+modname(cntr)+".cvdp_data.zos.trends."+syear(cntr)+"-"+eyear(cntr)+".nc"
           fnt2 = getenv("OUTDIR")+modname(cntr)+".cvdp_data."+syear(cntr)+"-"+eyear(cntr)+".nc"
           arr := read_cvdp_le_data(fnt,fnt2,variname_obs(dd))

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

           Opt@DstFileName    = getenv("OUTDIR")+Opt@DstGridType+".zt.SCRIP_grid_description.nc" 
           if (any(ismissing(obs0))) then
              Opt@DstMask2D  := where(ismissing(arr),0,1)  ; set SrcMask2D option to indicate the missing values 
           end if

           qres@gsnLeftString = syear(cntr)+"-"+eyear(cntr)+" ~C~"+arr@units   
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

           fnt = getenv("OUTDIR")+modname_mod+".cvdp_data.zos.trends."+syear_mod+"-"+eyear_mod+".nc"
           fnt2 = getenv("OUTDIR")+modname_mod+".cvdp_data."+syear_mod+"-"+eyear_mod+".nc"
           arr := read_cvdp_le_data(fnt,fnt2,variname(dd))

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
           Opt@DstFileName    = getenv("OUTDIR")+Opt@DstGridType+".zt.SCRIP_grid_description.nc" 
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

           qres@gsnLeftString = syear_mod+"-"+eyear_mod+" ~C~"+arr@units   
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
        else
           qres@lbTitleString = arr_EM@units   
           qres2@lbTitleString = qres@lbTitleString  
           tres@lbLabelBarOn = False     
        end if

        qres@gsnLeftString = syear(0)+"-"+eyear(0)+" ~C~"+obs0@units   
        qres@gsnRightString = ""
        qres@gsnCenterString = names(0)    
        plot_summary(cntr_EM+1) = gsn_csm_contour_map(wks,obs0,qres)

        if (showyr) then
           qres@gsnLeftString = syear_em0+"-"+eyear_em0+" ~C~"+arr_EM@units   
        else
           qres@gsnLeftString = (eyear_em0-syear_em0+1)+"yrs ~C~"+arr_EM@units   
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
        tres@gsnLeftString = "%"
        tres@gsnCenterString = "Rank of "+names(0)+" within Ensemble" 
        tres@gsnRightString = ""  ;calculate_area_in_range(p_val,10,90)+"%"
        plot_summary(cntr_EM+3) = gsn_csm_contour_map(wks,p_val,tres)
 
        fout = getenv("OUTDIR")+str_sub_str(names_EM_mod," ","_")+"_EM.cvdp_data.zos.trends."+syear_mod+"-"+eyear_mod+".nc"
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
           z->$(/"lat2d_ocean"/)$ = set_varAtts(LAT2D,"ocean grid 2-dimensional latitudes","","")
           z->$(/"lon2d_ocean"/)$ = set_varAtts(LON2D,"ocean grid 2-dimensional longitudes","","")
           delete([/LAT2D,LON2D/])
           arr_EM@coordinates ="lat2d_ocean lon2d_ocean"
           obs_diff@coordinates = "lat2d_ocean lon2d_ocean"
           p_val@coordinates = "lat2d_ocean lon2d_ocean"
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
        delete(plot_summary)
     end if
     delete([/plot_indmem,plot_indmem_diff,wks,Opt,qres,qres2/])

     if (wks_type.eq."png") then
        system("mv "+OUTDIR+"zos.trends.000001.png "+OUTDIR+variname(dd)+".indmem.png")
        system("mv "+OUTDIR+"zos.trends.000002.png "+OUTDIR+variname(dd)+".indmemdiff.png")
        if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
           system("mv "+OUTDIR+"zos.trends.000003.png "+OUTDIR+variname(dd)+".summary.png")
           if (PNG_SCALE_SUMMARY.ne.100) then
             system(IM_COMMAND+" "+OUTDIR+variname(dd)+".summary.png -resize "+PNG_SCALE_SUMMARY+"% "+OUTDIR+variname(dd)+".summary.png")
           end if
        end if
     else
        system("psplit "+OUTDIR+"zos.trends.ps "+OUTDIR+"zos.trends")
        system("mv "+OUTDIR+"zos.trends0001.ps "+OUTDIR+variname(dd)+".indmem.ps")
        system("mv "+OUTDIR+"zos.trends0002.ps "+OUTDIR+variname(dd)+".indmemdiff.ps")
        if (nEM.ge.1) then   ; in ensemble mode (runstyle=2)
           system("mv "+OUTDIR+"zos.trends0003.ps "+OUTDIR+variname(dd)+".summary.ps")
        end if
        system("rm "+OUTDIR+"zos.trends.ps")
     end if
  end do  ; dd do loop
  print("Finished: zos.trends.ncl")
end


