; Calculates ensemble means for every variable and input ensemble for use in other scripts.
;
; Confirmed that pr, psl, tas, ts and ssh ensemble means match between this script and ensemble_mean.calc.py
;
; Variables used: ts, psl, pr, tas, siconc, zos, msftmyz
;
load "$CVDP_SCRIPTS/functions.ncl"

begin
  print("Starting: ensemble_mean.calc.ncl")
  ENSEMBLE_MEAN_DIR = getenv("ENSEMBLE_MEAN_DIR")
  REMOVE_TREND_MODEL = getenv("REMOVE_TREND_MODEL") 

  setfileoption("nc","format","netcdf4")
  if (REMOVE_TREND_MODEL.eq."rmGMST_EM") then
     vlist = "trefht"   ; only need tas ensemble means for this option
  else
     vlist = (/"prect","psl","trefht","ts","ssh","aice_nh","aice_sh","moc"/)
  end if

  do dd = 0,dimsizes(vlist)-1
     nsim := numAsciiRow("namelist_byvar/namelist_"+vlist(dd))

     na := asciiread("namelist_byvar/namelist_"+vlist(dd),(/nsim/),"string")
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
        EM_num(gg)    = toint(temp(0))
        names_EM(gg)  = str_join(temp(1:),"-")
        delete(temp)
     end do
     modname := str_sub_str(names," ","_")
     bc = (/"/","'","(",")"/)
     do ff = 0,dimsizes(modname)-1
        do gg = 0,dimsizes(bc)-1
           modname(ff) = str_sub_str(modname(ff),bc(gg),"_")
        end do
     end do

     nEM = max(EM_num)
     do gg = 1,nEM   ; operate on each ensemble mean
        nens = num(EM_num.eq.gg) ; determines how many model simulations in each ensemble
        cntr_ens := ind(EM_num.eq.gg)   ; cntr_ens(hh) are the indices where each ensemble member of an ensemble reside 

        fno = ENSEMBLE_MEAN_DIR+str_sub_str(names_EM(cntr_ens(0))," ","_")+".cvdp_data."+vlist(dd)+".ensemble_mean."+sprinti("%0.4i", syear(cntr_ens(0)))+"01-"+sprinti("%0.4i", eyear(cntr_ens(0)))+"12.nc"

        if (fileexists(fno)) then
           continue
        end if
        print("Creating "+fno)  
        do hh = 0,nens-1   
           modname_mod = modname(cntr_ens(hh))
           syear_mod = syear(cntr_ens(hh))
           eyear_mod = eyear(cntr_ens(hh))
           names_mod = names(cntr_ens(hh))
           names_EM_mod = names_EM(cntr_ens(hh))
           paths_mod = paths(cntr_ens(hh))

           if (vlist(dd).eq."psl".or.vlist(dd).eq."prect".or.vlist(dd).eq."trefht".or.vlist(dd).eq."ts") then
              arr := data_read_in(paths_mod,changeCaseChar(vlist(dd)),syear_mod,eyear_mod)    ; read in data, orient lats/lons correctly, set time coordinate variable up
              if (vlist(dd).eq."ts") then
                 arr = where(arr.le.-1.8,-1.8,arr)    ; set all values below -1.8 to -1.8
              end if
           end if
           if (vlist(dd).eq."ssh") then
              arr := data_read_in_ocean(paths_mod,changeCaseChar(vlist(dd)),syear_mod,eyear_mod)    ; read in data, orient lats/lons correctly, set time coordinate variable up
              ttxt = "ocean"
              ttxt2 = ttxt
           end if
           if (vlist(dd).eq."moc") then
              arr := data_read_in_ocean_MOC(paths_mod,changeCaseChar(vlist(dd)),syear_mod,eyear_mod)    ; read in data, orient lats/lons correctly, set time coordinate variable up
           end if
           if (vlist(dd).eq."aice_nh".or.vlist(dd).eq."aice_sh") then
              arr := data_read_in_ice(paths_mod,vlist(dd),syear_mod,eyear_mod)    ; read in data, orient lats/lons correctly, set time coordinate variable up
              if (vlist(dd).eq."aice_nh") then
                 ttxt = "ice_nh"
              else
                 ttxt = "ice_sh"
              end if
              ttxt2 = "ice"

              arr_ice_sie := arr
              arr_ice_sie = (/ where(arr_ice_sie.ge.15,1.,0.) /)      ; done for siconc.trends_timeseries.ncl
           end if

           if (isatt(arr,"is_all_missing")) then
              continue
           end if 

           arr = rmMonAnnCycTLL(arr)   ; remove annual cycle of each member first
           if (vlist(dd).eq."aice_nh".or.vlist(dd).eq."aice_sh") then
              arr_ice_sie = rmMonAnnCycTLL(arr_ice_sie)   ; remove annual cycle of each member first
           end if

           if (hh.eq.0) then
              em = arr
              em = 0.
              em_cntr = em
              if (vlist(dd).eq."aice_nh".or.vlist(dd).eq."aice_sh") then
                 em_ice_sie = em
              end if
           end if
           em = (/ em+where(ismissing(arr),0,arr) /)
           em_cntr = em_cntr+where(ismissing(arr),0,1)
           if (vlist(dd).eq."aice_nh".or.vlist(dd).eq."aice_sh") then
              em_ice_sie = (/ em_ice_sie+where(ismissing(arr_ice_sie),0,arr_ice_sie) /)
           end if
        end do  ; hh loop
        if (isvar("em")) then
;           print(vlist(dd)+" "+names_EM_mod)
;           printMinMax(em_cntr,0)
           em_cntr = where(em_cntr.eq.0,em_cntr@_FillValue,em_cntr)
           em = (/ em/em_cntr /) 

           if (vlist(dd).eq."aice_nh".or.vlist(dd).eq."aice_sh") then
              em_ice_sie = (/ em_ice_sie/em_cntr /) 
           end if
           b = addfile(fno,"c")
           b@title = "Ensemble means of "+names_EM_mod+" "+vlist(dd)
           if (isatt(em,"lat2d")) then
              LAT2D = em@lat2d
              LON2D = em@lon2d
              delete([/em@lat2d,em@lon2d/])
              copy_VarCoords(em(0,:,:),LAT2D)
              copy_VarCoords(em(0,:,:),LON2D)
              b->$(/"lat2d_"+ttxt/)$ = set_varAtts(LAT2D,ttxt2+" grid 2-dimensional latitudes","degrees_north","")
              b->$(/"lon2d_"+ttxt/)$ = set_varAtts(LON2D,ttxt2+" grid 2-dimensional longitudes","degrees_east","")
              delete([/LAT2D,LON2D/])
              em@coordinates ="lat2d_"+ttxt+" lon2d_"+ttxt
           else
              if (iscoord(em,"lat").and.iscoord(em,"lon")) then
                 if (isatt(em&lon,"_FillValue")) then   ; because NCL does not like _FillValue for lat/lon coordinates
                    delete(em&lon@_FillValue)
                 end if
                 if (isatt(em&lat,"_FillValue")) then
                    delete(em&lat@_FillValue)
                 end if
              end if
           end if
           b->$vlist(dd)$ = em
           if (vlist(dd).eq."aice_nh".or.vlist(dd).eq."aice_sh") then
              arrsave := (/ em_ice_sie /)
              copy_VarMeta(em,arrsave)
              b->$(/vlist(dd)+"_sie"/)$ = arrsave
              delete([/em_ice_sie,arrsave/])
           end if
           delete([/em,em_cntr,b/])
        else
           print("Unable to create "+fno+", check "+vlist(dd)+" namelist if "+names_EM_mod+" ensemble is completely missing")
        end if
     end do  ; gg loop
  end do   ; dd loop
end



    
