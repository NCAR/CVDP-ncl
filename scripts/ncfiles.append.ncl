; Concatenate all .nc files from same model/observational dataset 
; into a single .nc file.
;
begin
  print("Starting: ncfiles.append.ncl")

  OUTDIR      = getenv("OUTDIR")
  o = getenv("OBS")

  if (o.eq."True") then
     obsflag = True
  else
     obsflag = False
  end if

  nsim = numAsciiRow("namelist")
  na = asciiread("namelist",(/nsim/),"string")
  
  blankrow = ind(na.eq."")
  if (.not.any(ismissing(blankrow))) then
     goodrows = ind(na.ne."")
     na2 = na(goodrows)
     delete(na)
     na = na2
     delete(na2)
     nsim = dimsizes(na)
  end if     
  
  nentry = numAsciiCol("namelist")
  names = new(nsim,"string")
  syear = new(nsim,"integer",-999)
  eyear = new(nsim,"integer",-999)
    
  delim = "|"
  do gg = 0,nsim-1
     names(gg) = str_sub_str(str_sub_str(str_sub_str(str_sub_str(str_sub_str(str_strip(str_get_field(na(gg),1,delim))," ","_"),"/","_"),"'","_"),"(","_"),")","_")
     syear(gg) = stringtointeger(str_strip(str_get_field(na(gg),3,delim)))
     eyear(gg) = stringtointeger(str_strip(str_get_field(na(gg),4,delim)))
     if (str_get_field(na(gg),5,delim).ne."") then
        if (.not.isvar("names_EM")) then
           names_EM = new(nsim,"string")
        end if
        temp      = str_split(str_strip(str_get_field(na(gg),5,delim)),"-")
        names_EM(gg)  = str_join(temp(1:),"-")
        delete([/temp/])
     end if
  end do
;---------------------------------------
  do gg = 0,nsim-1
     fils := systemfunc("ls "+OUTDIR+names(gg)+".*.nc 2> /dev/null")
     if (.not.ismissing(fils(0))) then
        dimf  := dimsizes(fils)
        ofile := OUTDIR+names(gg)+".cvdp_data."+syear(gg)+"-"+eyear(gg)+".nc"
        if (dimf.eq.1) then
           if (fils(0).ne.ofile) then
              system("mv "+fils(0)+" "+ofile)
           end if
        else
           if (isfilepresent(ofile)) then                                    ; if file master is present append individual data files to file master.
              do hh = 0,dimf-1
                 if (fils(hh).ne.ofile) then
                    system("ncks -A -h "+fils(hh)+" "+ofile)
                 end if
              end do
              system("rm "+str_sub_str(str_join(fils," "),ofile,""))
           else                                                              ; if file master is not present, append individual data files to last file in list,
              do hh = 0,dimf-2                                               ; and when done move the last file to be the master file
                 system("ncks -A -h "+fils(hh)+" "+fils(dimf-1))             
              end do
              system("mv "+fils(dimf-1)+" "+ofile)
              if (dimsizes(fils).ge.2) then
                 system("rm "+str_sub_str(str_sub_str(str_join(fils," "),ofile,""),fils(dimf-1),""))   ; remove each script's file, but do not remove the master file (if present)
              end if
           end if
        end if
        system("ncks -O "+ofile+" "+ofile)   ; done to alphabetize output variable
     end if
  end do
  delete([/nsim,na,blankrow,nentry,names/])
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
; Combine all ensemble mean files for one ensemble mean into one file
;
  if (isvar("names_EM")) then
     names_EMus = get_unique_values(names_EM+" | "+syear+" | "+eyear)
     names_EMu = str_sub_str(str_strip(str_get_field(names_EMus,1,delim))," ","_")
     syearEM = str_strip(str_get_field(names_EMus,2,delim))
     eyearEM = str_strip(str_get_field(names_EMus,3,delim))

     do gg = 0,dimsizes(names_EMu)-1
        fils := systemfunc("ls "+OUTDIR+names_EMu(gg)+"_EM.*.nc 2> /dev/null")
        if (.not.ismissing(fils(0))) then
           dimf := dimsizes(fils)
           ofile := OUTDIR+names_EMu(gg)+"_EM.cvdp_data."+syearEM(gg)+"-"+eyearEM(gg)+".nc"
           if (dimf.eq.1) then
              if (fils(0).ne.ofile) then
                 system("mv "+fils(0)+" "+ofile)
              end if
           else
              if (isfilepresent(ofile)) then                                    ; if file master is present append individual data files to file master.
                 do hh = 0,dimf-1
                    if (fils(hh).ne.ofile) then
                       system("ncks -A -h "+fils(hh)+" "+ofile)
                    end if
                 end do
                 system("rm "+str_sub_str(str_join(fils," "),ofile,""))
              else                                                              ; if file master is not present, append individual data files to last file in list,
                 do hh = 0,dimf-2                                               ; and when done move the last file to be the master file
                    system("ncks -A -h "+fils(hh)+" "+fils(dimf-1))             
                 end do
                 system("mv "+fils(dimf-1)+" "+ofile)
                 if (dimsizes(fils).ge.2) then
                    system("rm "+str_sub_str(str_sub_str(str_join(fils," "),ofile,""),fils(dimf-1),""))   ; remove each script's file, but do not remove the master file (if present)
                 end if
              end if
           end if
           system("ncks -O "+ofile+" "+ofile)   ; done to alphabetize output variable
        end if
     end do
  end if
;------------------------------------------------
  if (obsflag) then

     nsim := numAsciiRow("namelist_byvar/namelist_psl")    ; each namelist_* namelist has the same number of observational datasets
     na := asciiread("namelist_byvar/namelist_psl",(/nsim/),"string")
  
     blankrow := ind(na.eq."")
     if (.not.any(ismissing(blankrow))) then
        goodrows = ind(na.ne."")
        na2 = na(goodrows)
        delete(na)
        na = na2
        delete([/na2,goodrows/])
        nsim = dimsizes(na)
     end if     
     EM_num := new(nsim,"integer",-999)    
     do gg = 0,nsim-1
        temp     := str_split(str_strip(str_get_field(na(gg),5,delim)),"-")
        temp      = str_split(str_strip(str_get_field(na(gg),5,delim)),"-")
        EM_num(gg)    = toint(temp(0))
     end do
     maxnumobs  = num(EM_num.eq.0) 

     namelist_files = (/"psl","prect","trefht","ts","moc","aice_nh","aice_sh"/)
     delim = "|"
     cntr = 0
     namesB := new(maxnumobs*dimsizes(namelist_files),string)
     do gg = 0,dimsizes(namelist_files)-1                    ; grab all observational dataset names from namelist_$var files
        na := asciiread("namelist_byvar/namelist_"+namelist_files(gg),(/maxnumobs/),"string")
        namesB(cntr:cntr+maxnumobs-1) = str_sub_str(str_sub_str(str_sub_str(str_sub_str(str_sub_str(str_strip(str_get_field(na,1,delim))," ","_"),"/","_"),"'","_"),"(","_"),")","_")
        cntr = cntr+maxnumobs
        delete(na)
     end do

     namesB = where(namesB.eq."",namesB@_FillValue,namesB)     ; for blank names set them to _FillValue
     if (any(namesB.eq."missing")) then
        namesB(str_match_ind(namesB,"missing")) = namesB@_FillValue ; check for any names containing "missing", set to _FillValue
     end if
     delete([/delim,cntr,namelist_files/])
     do gg = 0,dimsizes(namesB)-1
        if (.not.ismissing(namesB(gg))) then
           fils := systemfunc("ls "+OUTDIR+namesB(gg)+".cvdp_data.*.nc 2> /dev/null")
           if (.not.ismissing(fils(0))) then
              dimf = dimsizes(fils)
              fil0 = tochar(fils(0))
              suffix = tostring(fil0(dimsizes(fil0)-12:dimsizes(fil0)-1))
              delete(fil0)
              ofi = OUTDIR+namesB(gg)+".cvdp_data."+suffix
              if (dimf.ge.2) then
                 if (isfilepresent(ofi)) then                   ; if file master is present append individual data files to file master.
                    do hh = 0,dimf-1
                       if (fils(hh).ne.ofi) then
                          system("ncks -A -h "+fils(hh)+" "+ofi)
                       end if
                    end do
                    rfn = str_sub_str(str_join(fils," "),ofi,"")
                 else                                                        ; if file master is not present, append individual data files to last file in list,
                    do hh = 0,dimf-2                                         ; and when done move the last file to be the master file
                      system("ncks -A -h "+fils(hh)+" "+fils(dimf-1))
                    end do
                    system("mv "+fils(dimf-1)+" "+ofi)
                    rfn = str_sub_str(str_sub_str(str_join(fils," "),ofi,""),fils(dimf-1),"")
                 end if
                 if (.not.ismissing(rfn)) then
                    system("rm "+rfn)   ; remove each script's file, but do not remove the master file (if present)
                 end if
              else
                 if (fils(0).ne.ofi) then
                    system("mv "+fils(0)+" "+ofi)
                 end if
              end if
              system("ncks -O "+ofi+" "+ofi)   ; done to alphabetize output variable
              delete([/dimf,ofi/])
           end if
           delete(fils)
        end if
     end do
     delete([/namesB/])
  end if
  print("Finished: ncfiles.append.ncl")
end

