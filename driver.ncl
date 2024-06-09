; CVDP driver script. To run the CVDP at the command line type: ncl driver.ncl
; To run the CVDP at the command line, put it in background mode, and write the terminal output
; to a file named file.out, type: ncl driver.ncl >&! file.out &
; 
;=====================================================================================================
  runstyle = 2        ; See online documentation! runstyle 2 requires additional column of data in namelist.
                      ; 1 = Individual simulations mode. This is equivalent to running previous versions of the CVDP.
                      ; 2 = Ensemble mode. This is similar to running version 1.0 of the CVDP-LE.

  outdir            = "/project/diag/Comparison1/"   ; Set location of output files   (must end in a "/")
  webpage_title     = "Title goes here"      ; Set webpage title                                                                
  remove_trend_obs  = "QuadraticTrend"       ; valid options are None, LinearTrend, QuadraticTrend, 30yrRunningMean   (see documentation)
  remove_trend_model= "QuadraticTrend"       ; valid options are None, LinearTrend, QuadraticTrend, 30yrRunningMean, rmGMST_EM, rmEM  (see documentation)
  ensemble_mean_dir = "/project/cas/CVDP-EM_ncl/"     ; directory where the ensemble means should be located when remove_trend_model = "rmGMST_EM" or "rmEM"
   
  namelists_only       = "False"             ; Set to True to only create the variable namelists. Useful upon running the package for the first time to 
                                             ; verify that the correct files are being selected by the package. (See files in namelist_byvar/ directory)
                                             ; Set to False to run the entire package. 
                                             
  create_graphics      = "True"              ; True = Create graphics from individual reference dataset/simulation metrics. Create ensemble mean metrics and netCDF files.  
                                             ; False = Calculate individual reference dataset/simulation metrics and exit. 

  max_num_tasks = 3                          ; Sets how many CVDP NCL scripts can be run at once. (If unsure set to 3.)     
  
  modular =  "False"                                      ; True = Run only those CVDP scripts specified in modular_list. False = Run all CVDP scripts (Default)
  modular_list = "amoc,amv,pr.trends_timeseries,ipv"     ; Example: modular_list = "amoc,amv,pr.trends_timeseries,ipv"   For a list of available scripts see complete_list at line 57. 

  zp = "scripts/"                            ; directory path of CVDP NCL scripts. (must end in a "/")
                                             ; Examples: "scripts/" if all code is local, or on NCAR's CGD or CISL systems: "~asphilli/CESM-diagnostics/CVDP/Release/v6.0.0/scripts/"
                                             ; Regardless of this setting the following files should be in one directory: namelist, driver.ncl, and namelist_obs. 
                                             ; If pointing to code in ~asphilli make sure the driver script version #s match between this script and the script in ~asphilli.  

  png_scale         = 2.0                    ; Set the output .png size. Value between .1->5.  Any value > 1 (< 1) increases (decreases) png size. 
                                             ; When output_type = "png" a value of 1 will result in a png sized 1500 (H) x 1500 (W) before automatic cropping of white space
                                             ; When output_type = "ps"  a value of 1 will result in a png density setting of 144 before automatic cropping of white space
  
  tar_output        = "False"                ; True = tar up all output in outdir and remove individual files, False = do not                                      
                                             ; Note: All files in outdir will be tarred up and then removed from the outdir directory. 
;---Options for unstructured data checking------------------------------------------------------------   
  regrid_check      = "False"                ; If True, check each file specified in namelist_byvar/* for unstructured grids. If unstructured 
                                             ; data is found, the files will  be regridded to the lat/lon grid specified in regrid_to_res. 
  regrid_to_res     = "/project/mojave/cesm2/PSL.206501-210012.nc" ; path to file containing variables lat (or LAT, latitude or LATITUDE) and lon
                                                                   ;  (or LON, longitude or LONGITUDE) representing the (rectilinear) destination grid.
  regrid_dir        = "/project/CVDP-regrid/"                      ; path to directory where regridded data will be placed. 

;---Less frequently used options----------------------------------------------------------------------                                             
  colormap          = 0                      ; 0 = default colormaps, 1 = colormaps better for color blindness.
  output_type       = "png"                  ; png = create png files, ps = create ps files as well as png files (for web viewing).  
  ncl_exec = "ncl"                           ; NCL executable command. This can be changed to a different path if needed, such as "/different/path/to/bin/ncl"                                                  
  machine_casesen = "True"                   ; True = Your filesystem is case sensitive  (Default), False = Your filesystem is case insensitive.

;========END USER MODIFICATIONS=======================================================================
  version = "6.0.0"

  print("Started: CVDP ("+systemfunc("date")+")")

  complete_list = "amv,sst.indices,siconc.trends_timeseries,psl.trends_timeseries,pdv,pr.trends_timeseries,"+\
                  "siconc.mean_stddev,soi,nam,nao,sam_psa,pna_npo,amoc,tas.trends_timeseries,ipv,"+\
                  "sst.mean_stddev,psl.mean_stddev,pr.mean_stddev,sst.trends_timeseries,tas.mean_stddev,zos.mean_stddev,zos.trends"

  if (runstyle.le.0.or.runstyle.ge.3) then
     print("runstyle can only be set to 1 or 2. Please alter the runstyle setting and submit again.")
     exit
  end if

  if (runstyle.eq.1) then
     olist = (/"None", "LinearTrend","QuadraticTrend", "30yrRunningMean"/)  
     mlist = (/"None", "LinearTrend","QuadraticTrend", "30yrRunningMean"/)
  else
     olist = (/"None", "LinearTrend", "QuadraticTrend", "30yrRunningMean"/)  
     mlist = (/"None", "LinearTrend", "QuadraticTrend", "30yrRunningMean", "rmGMST_EM", "rmEM"/)
  end if
  if (.not.any(olist.eq.remove_trend_obs)) then
     print("Valid options for remove_trend_obs for runstyle = "+runstyle+" are:  "+str_join(olist,", ")+". Reset remove_trend_obs and submit again.")
     exit
  end if
  if (.not.any(mlist.eq.remove_trend_model)) then
     print("Valid options for remove_trend_model for runstyle = "+runstyle+" are:  "+str_join(mlist,", ")+". Reset remove_trend_model and submit again.")
     exit
  end if 

  if (fileexists(outdir+"cvdp.tar")) then
     print(outdir+"cvdp.tar file is already present in outdir. If you wish to use previously computed metrics in this comparison, manually untar the cvdp.tar file before submitting this script. Exiting.")
     exit
  end if

  loadscript(zp+"functions.ncl")
  if (.not.isfilepresent2(outdir)) then
     system("mkdir -p "+outdir)
  end if

  pngsumscale = 100   ; scale down size of summary images
  if (png_scale.ge.2) then
     pngsumscale = 75
  end if
  obs                  = "True"              ; obs are required for atmospheric variables, so this is always set to "True"
  envvar_str = "   export OUTDIR="+outdir+";   export OBS="+obs+";   "+\
         "export CREATE_GRAPHICS="+create_graphics+";   export VERSION="+version+";   export PNG_SCALE="+png_scale+";   "+\
         "export OUTPUT_TYPE="+output_type+";   export MACHINE="+machine_casesen+";   export RUNSTYLE="+runstyle+";   "+\
         "export COLORMAP="+colormap+";   export CVDP_SCRIPTS="+zp+";   export PNG_SCALE_SUMMARY="+pngsumscale+";   "+\
         "export REMOVE_TREND_OBS="+remove_trend_obs+";   export REMOVE_TREND_MODEL="+remove_trend_model+";   "+\
         "export ENSEMBLE_MEAN_DIR="+ensemble_mean_dir+";   export MAX_TASKS="+max_num_tasks+";"  
  if (regrid_check.eq."True") then
     envvar_str = envvar_str+"   export REGRID_TO_RES="+regrid_to_res+";   export REGRID_DIR="+regrid_dir+";"     
  end if
  ncl_exec = ncl_exec+" -n -Q" 

  system(envvar_str + " "+str_sub_str(ncl_exec," -Q","")+" "+zp+"namelist.ncl")     ; create variable namelists
  if (namelists_only.eq."True") then
     if (isfilepresent2("namelist_byvar/namelist_ssh")) then
        print("Variable namelists have been created. Examine files in namelist_byvar/ directory to verify CVDP file selection.")
     end if
     print("Finished: CVDP ("+systemfunc("date")+")")
     exit
  end if 

  if (.not.isfilepresent2("namelist_byvar/namelist_ssh")) then   ; done in case namelist.ncl errors out and does not create namelists for each variable
     exit
  end if

  if (regrid_check.eq."True") then
     print("Checking model input for unstructured data")
     system(envvar_str + " "+str_sub_str(ncl_exec," -Q","")+" "+zp+"data_check_regrid.ncl")
  end if

  if (remove_trend_model.eq."rmGMST_EM".or.remove_trend_model.eq."rmEM") then
     print("Checking for presence of ensemble mean files")
     if (.not.isfilepresent2(ensemble_mean_dir)) then
        system("mkdir -p "+ensemble_mean_dir)
     end if
     system(envvar_str + " ncl "+zp+"ensemble_mean.calc.ncl")
     print("Ensemble mean calculations complete")
  end if

  if (modular.eq."True") then
     if (modular_list.ne."") then
        modular_list = str_sub_str(modular_list," ","")   ; remove spaces if present
        modular_list = str_sub_str(modular_list,",",".ncl,")   ; add .ncl in to end of each script name
        modular_list = modular_list+".ncl"                     ; add .ncl in to last script name
        modular_list = str_sub_str(modular_list,","," "+zp)
        system(envvar_str+" python "+zp+"runTasks.py "+zp+modular_list)
     end if
  else
     complete_list = str_sub_str(complete_list,",",".ncl,")   ; add .ncl in to end of each script name
     complete_list = complete_list+".ncl"                     ; add .ncl in to last script name
     complete_list = str_sub_str(complete_list,","," "+zp)
     system(envvar_str+" python "+zp+"runTasks.py "+zp+complete_list)		   
  end if

  system(envvar_str + " "+ncl_exec+" "+zp+"metrics.ncl")
  system(envvar_str + " "+ncl_exec+" "+zp+"ncfiles.append.ncl")
;--------------------------------------------
; Create webpages, finalize images and begin cleanup
;
  if (create_graphics.eq."True") then
     print("Creating webpages and finalizing images")
     image_finalize(outdir,output_type,max_num_tasks,zp,toint(144*png_scale))    ; trim whitespace, convert to .png (if necessary) and apply watermarks to images

     quote = str_get_dq()
     system("cp namelist_byvar/* "+outdir)
     system("cp namelist "+outdir)
     if (obs.eq."True") then
        system("cp namelist_obs "+outdir)
     end if

     system("   export OUTDIR="+outdir+";   export VERSION="+version+";   "+\
            "export REMOVE_TREND_OBS="+remove_trend_obs+";   export REMOVE_TREND_MODEL="+remove_trend_model+";   "+\
            "export OBS="+obs+";   export CVDP_SCRIPTS="+zp+"; "+ncl_exec+" 'webtitle="+quote+webpage_title+quote+"' "+zp+"webpage"+runstyle+".ncl")

     system("cp "+zp+"cas-cvdp.png "+outdir)
  else
     system("rm "+outdir+"*.gif")   ; remove metric graphics as images not requested
  end if

;--------------------------------------------
; Create tar file of output (if requested)
;
  if (tar_output.eq."True") then
     if (isfilepresent2(outdir+"cvdp.tar")) then
        system("rm "+outdir+"cvdp.tar")
     end if
     system("cd "+outdir+"; tar -cf cvdp.tar *")
     system("cd "+outdir+"; rm *.png *.ps *.txt *.html *.nc namelist*")
     print("tar file location: "+outdir+"cvdp.tar")
  end if

  print("Finished: CVDP ("+systemfunc("date")+")")
  
