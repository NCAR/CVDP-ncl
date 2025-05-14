; Create all CVDP web pages.
;
load "$CVDP_SCRIPTS/functions.ncl"

begin
  print("Starting: webpage1.ncl")

  OUTDIR      = getenv("OUTDIR") 
  VERSION     = getenv("VERSION")
  CLIMO_SYEAR = getenv("CLIMO_SYEAR")
  CLIMO_EYEAR = getenv("CLIMO_EYEAR")
  OBS         = getenv("OBS")
  REMOVE_TREND_OBS = getenv("REMOVE_TREND_OBS") 
  REMOVE_TREND_MODEL = getenv("REMOVE_TREND_MODEL") 

  varilA = (/"None", "LinearTrend", "30yrRunningMean", "rmGMST_EM", "rmEM","QuadraticTrend"/)
  varilB = (/"a trend removal method is not employed.","a linear trend is removed for each month.",\
             "a weighted running mean is applied by month using low-pass filter weights from the IPCC-AR4. (The 30 weights can be found within the functions.ncl file under the remove_trend function.) "+\
             "The weighted 30-yr low pass smoothed array is subtracted from the raw array, effectively removing the long-term trend.",\ 
             "the ensemble mean global mean tas array is regressed upon the variable relevant for that particular metric, and then the regression map is scaled by the value of the ensemble mean global mean tas value at each timestep. "+\
             "This new scaled regression array is then subtracted from the raw array to effectively remove the long-term trend.","the ensemble mean is removed at every timestep.","a quadratic trend is removed for each month."/)
  rt_obs = varilB(ind(varilA.eq.REMOVE_TREND_OBS))
  rt_model = varilB(ind(varilA.eq.REMOVE_TREND_MODEL))

  quote = str_get_dq()
;----------------------------------------------------------------------------
;--   Create metrics webpages
;----------------------------------------------------------------------------
  if (isfilepresent2(OUTDIR+"metrics.txt")) then
     txt = new(500,"string")  
     quote = str_get_dq()
  
     txt(0) = "<HTML><HEAD><TITLE>Climate Variability Diagnostics Package</TITLE><STYLE>"
     txt(1) = "body {background-color: WhiteSmoke; font-family: Verdana, Geneva, sans-serif}"
     txt(2) = "img.title {width:990; height:105; align:left}"
     txt(3) = "p.subtitle1 {font-size:15pt; color:gray}"
     txt(4) = "p.subtitle {font-size:20pt; color:black; text-align:center; font-weight:bold}"
     txt(5) = "p.btext {font-size:12pt; text-align:left}"
     txt(6) = "p.btext2 {font-size:9pt; text-align:left}"
     txt(7) = "td {text-align:center; font-size:12pt}"
     txt(8) = "td.s1 {text-align:left; font-size:11pt}"
     txt(9) = "CAPTION {text-align:left; font-size:14pt; font-weight:bold}"
     txt(10) = "</STYLE></HEAD><BODY>"
     txt(11) = "<img class=title src="+quote+"cas-cvdp.png"+quote+" alt="+quote+"CVDP logo"+quote+">"
     txt(12)= "<TABLE width='990' border=0 cellpadding=6>"
     txt(13) = "<tr><td width='350'><p class=btext><a href="+quote+"index.html"+quote+">Back to Diagnostics Plots</a></p></td>"
     txt(14) = "<td><h2 class="+quote+"text-center"+quote+">"+webtitle+"</h2></td></tr></table><hr width=990 align=left><p class=subtitle1>Metrics Table</p>" 
     
     z = asciiread(OUTDIR+"metrics.txt",(/-1/),"string")
     nlines = dimsizes(z)
     txt(24) = "<PRE>"
     do gg = 0,nlines-1
        txt(25+gg) = z(gg)
     end do
     txt(25+nlines) = "</PRE>"
     txt(25+nlines+1) = "<p class=btext><a href="+quote+"namelist_obs"+quote+">Reference Data Used</a></p>"
     txt(25+nlines+2) = "Created "+systemfunc("date")
     txt(25+nlines+3) = "<p class=btext2>CVDP Version "+VERSION+"</p><p class=btext2>Trend Removal: "+REMOVE_TREND_OBS+" (Obs) | "+REMOVE_TREND_MODEL+" (Model)</p></body></html>"
  
     tt = ind(.not.ismissing(txt))
     txt2 = txt(:tt(dimsizes(tt)-1)+1)
     txt2 = where(ismissing(txt2),"",txt2)
     asciiwrite(OUTDIR+"metrics.html",txt2)
     delete([/txt,txt2,tt,z/])
  end if 

  txt := new(500,"string")  
  txt(0) = "<HTML><HEAD><TITLE>Climate Variability Diagnostics Package</TITLE><STYLE>"
  txt(1) = "body {background-color: WhiteSmoke; font-family: Verdana, Geneva, sans-serif}"
  txt(2) = "img.title {width:990; height:105; align:left}"
  txt(3) = "p.subtitle1 {font-size:20pt; color:darkgray}"
  txt(4) = "p.subtitle {font-size:20pt; color:black; text-align:center; font-weight:bold}"
  txt(5) = "p.btext {font-size:12pt; text-align:left}"
  txt(6) = "p.btext2 {font-size:9pt; text-align:left}"
  txt(7) = "td {text-align:center; font-size:12pt}"
  txt(8) = "td.s1 {text-align:left; font-size:11pt}"
  txt(9) = "td.tablehdr {text-align:center; font-size:17pt}"
  txt(10) = "CAPTION {text-align:left; font-size:14pt; font-weight:bold}"
  txt(11) = "</STYLE></HEAD><BODY>"
  txt(12) = "<img class="+quote+"img-fluid"+quote+" src="+quote+"cas-cvdp.png"+quote+" alt="+quote+"CVDP logo"+quote+">"
  txt(13)= "<TABLE width='990' border=0 cellpadding=6>"
  txt(14) = "<tr><td width='30'><p class=btext>Go to:</p></td><td class=s1 width='380'><a href="+quote+"methodology.html"+quote+">Methodology and Definitions</a><br><a href="+quote+"index.html"+quote+">Diagnostics Plots</a><br><hr>"

  txt(27) = "<p class=btext><a href="+quote+"namelist_obs"+quote+">Reference Data Used</a></p>"
  txt(28) = "<p class=btext><a href="+quote+"metrics.txt"+quote+">Individual Metrics (ascii table)</a></p>"
  txt(30) = "Created "+systemfunc("date")
  txt(31) = "<p class=btext2>Individual Member Mode</p></body></html>"

  sort_txt2 = (/"Namelist (default)","Namelist (Alphabetically)","ENSO TAS","ENSO PSL","El Ni&ntilde;o Hovm&ouml;ller","La Ni&ntilde;a Hovm&ouml;ller","AMV Low Pass","PDV","NAO","PNA","SAM","SST std dev","PR std dev","Mean Score"/)

  imcreate = False
  if (isfilepresent2(OUTDIR+"metrics.table_1.gif")) then  ; create sorted individual run metrics table pages
     imcreate = True
     sort_txt = (/"<a href="+quote+"metrics.table_0.html"+quote+">Namelist (default)</a> | ","<a href="+quote+"metrics.table_1.html"+quote+">Namelist (Alphabetically)</a> | ","<a href="+quote+"metrics.table_2.html"+quote+">ENSO TAS</a> | ","<a href="+quote+"metrics.table_3.html"+quote+">ENSO PSL</a> | ", \
                  "<a href="+quote+"metrics.table_4.html"+quote+">El Ni&ntilde;o Hovm&ouml;ller</a><br>","<a href="+quote+"metrics.table_5.html"+quote+">La Ni&ntilde;a Hovm&ouml;ller</a> | ","<a href="+quote+"metrics.table_6.html"+quote+">AMV Low-Pass</a> | ","<a href="+quote+"metrics.table_7.html"+quote+">PDV</a> | ", \
                  "<a href="+quote+"metrics.table_8.html"+quote+">NAO</a> | ","<a href="+quote+"metrics.table_9.html"+quote+">PNA</a> | ","<a href="+quote+"metrics.table_10.html"+quote+">SAM</a> | ","<a href="+quote+"metrics.table_11.html"+quote+">SST std dev</a> | ", \
                  "<a href="+quote+"metrics.table_12.html"+quote+">PR std dev</a> | ","<a href="+quote+"metrics.table_13.html"+quote+">Mean Score</a>"/)

     sort_txtA = (/"<a href="+quote+"metrics.table_14.html"+quote+">Namelist (default)</a> | ","<a href="+quote+"metrics.table_15.html"+quote+">Namelist (Alphabetically)</a> | ","<a href="+quote+"metrics.table_16.html"+quote+">ENSO TAS</a> | ","<a href="+quote+"metrics.table_17.html"+quote+">ENSO PSL</a> | ", \
                  "<a href="+quote+"metrics.table_18.html"+quote+">El Ni&ntilde;o Hovm&ouml;ller</a><br>","<a href="+quote+"metrics.table_19.html"+quote+">La Ni&ntilde;a Hovm&ouml;ller</a> | ","<a href="+quote+"metrics.table_20.html"+quote+">AMV Low-Pass</a> | ","<a href="+quote+"metrics.table_21.html"+quote+">PDV</a> | ", \
                  "<a href="+quote+"metrics.table_22.html"+quote+">NAO</a> | ","<a href="+quote+"metrics.table_23.html"+quote+">PNA</a> | ","<a href="+quote+"metrics.table_24.html"+quote+">SAM</a> | ","<a href="+quote+"metrics.table_25.html"+quote+">SST std dev</a> | ", \
                  "<a href="+quote+"metrics.table_26.html"+quote+">PR std dev</a> | ","<a href="+quote+"metrics.table_27.html"+quote+">Mean Score</a>"/)

     strarr = new(14,string)
     strarr = " | "
     strarr(13) = " "
     do gg = 0,13    ; Individual Pattern Correlation

           txt(17) = "Individual Metrics Tables: <b>Correlations</b> | <a href="+quote+"metrics.table_"+(gg+14)+".html"+quote+">RMS</a></td>"   
           txt(18) = "<td><h2 class="+quote+"text-center"+quote+">"+webtitle+"</h2></td></tr></table><hr width=990 align=left>"
           sort_txtT = sort_txt
           sort_txtT(gg) = "<b>"+sort_txt2(gg)+"</b>"+strarr(gg)
           txt(24) = "<p class=subtitle1><b>Pattern Correlation Metrics (Individual)</b></p>"
           txt(25) = "<TABLE width='900' border=0 cellpadding=16><tr><td width=50><b>Sort By:</b></td><td>"+str_concat(sort_txtT)+"</td></tr></table>" 
           txt(26) = "<img width=980 src="+quote+"metrics.table_"+gg+".gif"+quote+" />"
           tt = ind(.not.ismissing(txt))
           txt2 = txt(:tt(dimsizes(tt)-1)+1)
           txt2 = where(ismissing(txt2),"",txt2)
           asciiwrite(OUTDIR+"metrics.table_"+gg+".html",txt2)
           delete([/txt2,tt,sort_txtT/])
     end do

     
     do gg = 0,13    ; Individual RMS
           txt(17) = "Individual Metrics Tables: <a href="+quote+"metrics.table_"+(gg)+".html"+quote+">Correlations</a> | <b>RMS</b></td>"   
           txt(18) = "<td><h2 class="+quote+"text-center"+quote+">"+webtitle+"</h2></td></tr></table><hr width=990 align=left>"
           sort_txtT = sort_txtA
           sort_txtT(gg) = "<b>"+sort_txt2(gg)+"</b>"+strarr(gg)
           txt(24) = "<p class=subtitle1><b>RMS Metrics (Individual)</b></p>"
           txt(25) = "<TABLE width='900' border=0 cellpadding=16><tr><td width=50><b>Sort By:</b></td><td>"+str_concat(sort_txtT)+"</td></tr></table>"
           txt(26) = "<img width=980 src="+quote+"metrics.table_"+(gg+14)+".gif"+quote+" />"
           tt = ind(.not.ismissing(txt))
           txt2 = txt(:tt(dimsizes(tt)-1)+1)
           txt2 = where(ismissing(txt2),"",txt2)
           asciiwrite(OUTDIR+"metrics.table_"+(gg+14)+".html",txt2)
           delete([/txt2,tt/])
     end do
  end if
;-----------------------------------------------------------------------------------
; Create index.html
;
  txt := new(30000,"string")
  
  txt(0) = "<html><head><title>Climate Variability Diagnostics Package</title>"
  txt(1) = "<link rel="+quote+"stylesheet"+quote+" href="+quote+"https://stackpath.bootstrapcdn.com/bootstrap/4.1.3/css/bootstrap.min.css"+quote+" integrity="+quote+"sha384-MCw98/SFnGE8fJT3GXwEOngsV7Zt27NXFoaoApmYm81iuXoPkFOJwJ8ERdknLPMO"+quote+" crossorigin="+quote+"anonymous"+quote+">"
  txt(2) = "<script src="+quote+"https://code.jquery.com/jquery-3.3.1.slim.min.js"+quote+" integrity="+quote+"sha384-q8i/X+965DzO0rT7abK41JStQIAqVgRVzpbzo5smXKp4YfRvH+8abtTE1Pi6jizo"+quote+" crossorigin="+quote+"anonymous"+quote+"></script>"
  txt(3) = "<script src="+quote+"https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.14.3/umd/popper.min.js"+quote+" integrity="+quote+"sha384-ZMP7rVo3mIykV+2+9J3UJ46jBk0WLaUAdn689aCwoqbBJiSnjAK/l8WvCWPIPm49"+quote+" crossorigin="+quote+"anonymous"+quote+"></script>"
  txt(4) = "<script src="+quote+"https://stackpath.bootstrapcdn.com/bootstrap/4.1.3/js/bootstrap.min.js"+quote+" integrity="+quote+"sha384-ChfqqxuZUCnJSK3+MXmPNIyE6ZbWh2IMqE241rYiqJxyMiZ6OW/JmZQ5stwEULTy"+quote+" crossorigin="+quote+"anonymous"+quote+"></script>"
  txt(5) = "<script>function myFunction(event) {event.target.children[0].classList.toggle("+quote+"show"+quote+");}</script>"

  txt(11) = "<style>body {background-color: WhiteSmoke; font-family: Verdana, Geneva, sans-serif}"
  txt(12) = "img.title {width:990; height:105; align:left}"
  txt(13) = "p.subtitle {font-size:20pt; color:black; text-align:center; font-weight:bold}"
  txt(14) = "p.btext {font-size:11pt; text-align:left}"
  txt(15) = "font.s1 {font-size:13.5pt; text-align:left}"
  txt(17) = "td {text-align:center; font-size:12pt}"
  txt(18) = "td.s1 {text-align:left; font-size:11pt}"
  txt(19) = "td.s2 {border-bottom: 4px double darkgray}"
  txt(20) = "CAPTION {text-align:left; font-size:14pt; font-weight:bold}"
  txt(21) = ".popup {position: relative; display: inline-block; cursor: pointer; color: #007bff}"
  txt(22) = ".popup .popuptext {visibility: hidden; width: 400px; background-color: #E4F2F8; color: #545454; text-align: center; border-radius: 6px; padding: 8px 8px; position: absolute; z-index: 1; bottom: 125%; left: 50%; margin-left: -200px}"
  txt(23) = ".popup .show {visibility: visible; animation: fadeIn 1.5s}"
  txt(24) = "@keyframes fadeIn {from {opacity: 0;} to {opacity:1 ;}}"
  txt(25) = "</style></head>"

  txt(30) = "<body>"
  txt(31) = "<div class="+quote+"container"+quote+">"
	 txt(32) = "<div class="+quote+"row"+quote+">"
		txt(33) = "<img class="+quote+"img-fluid"+quote+" src="+quote+"cas-cvdp.png"+quote+" alt="+quote+"CVDP logo"+quote+">"
  txt(34) = "</div>"

  txt(40) = "<div class="+quote+"row"+quote+">"
		txt(41) = "<div class="+quote+"col"+quote+">"
		txt(42) = "<table class="+quote+"table my-0"+quote+">"
		txt(43) = "<tr>"
		txt(44) = "<td class="+quote+"text-left"+quote+">"
		txt(45) = "<ul class="+quote+"list-inline my-0"+quote+">"
		txt(46) = "<li class="+quote+"list-inline-item"+quote+"><a href="+quote+"methodology.html"+quote+">Methodology and Definitions</a></li><br>"

  if (isfilepresent2(OUTDIR+"metrics.table_0.html")) then
     btxt = "Metrics: <a href="+quote+"metrics.table_0.html"+quote+">Individual Tables</a></li><br>"
  else
     if (isfilepresent2(OUTDIR+"metrics.html")) then
        btxt = "Metrics: <a href="+quote+"metrics.html"+quote+">Individual Tables</a></li><br>"
     else
        btxt = ""
     end if
  end if
  if (btxt.eq."") then
     txt(48) = "Metrics Unavailable<br>"
  else
     txt(48) = btxt
  end if


		txt(49) = "<li class="+quote+"list-inline-item"+quote+">Namelists: <a href="+quote+"namelist_obs.html"+quote+">Input</a> | <a href="+quote+"namelist_msftmz.html"+quote+">Derived</a></li>"		
		txt(65) = "<li class="+quote+"list-inline-item"+quote+">Created: "+systemfunc("date")+"<br>CVDP Version "+VERSION+"<br>"
  txt(66) = "Trend Removal: <div class="+quote+"popup"+quote+" onclick="+quote+"myFunction(event)"+quote+">Reference<span class="+quote+"popuptext"+quote+" id="+quote+"myPopup"+quote+">"+rt_obs+"<br> &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;<i>Click link to close</i></span></div> |"
  txt(67) = "<div class="+quote+"popup"+quote+" onclick="+quote+"myFunction(event)"+quote+">Simulations<span class="+quote+"popuptext"+quote+" id="+quote+"myPopup"+quote+">"+rt_model+"<br> &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;<i>Click link to close</i></span></div></li>"
  txt(68) = "<p class=btext2>Individual Member Mode</p>"
		txt(70) = "</ul></td>"
		txt(83) = "</tr>"
		txt(84) = "</table>"
		txt(85) = "</div>"
		txt(86) = "<div class="+quote+"col align-self-center"+quote+">"
		txt(87) = "<h2 class="+quote+"text-center"+quote+">"+webtitle+"</h2>"
		txt(88) = "</div>"
	 txt(89) = "</div>"

  txt(100) = "<div class="+quote+"row"+quote+">"
  txt(101) = "<div class="+quote+"col"+quote+">"
  txt(102) = "<table class="+quote+"table table-striped table-bordered"+quote+">"
  txt(103) = "<h3 class="+quote+"display-6"+quote+">Climatological Averages</h3>"
  txt(104) = "<tr class="+quote+"d-flex"+quote+">"
  txt(105) = "<td class="+quote+"col"+quote+"><b>SST</b></td>"

  txt(110) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"sst_spatialmean_djf.indmem.png")) then
     txt(111) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#sst_mean_djf"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"sst_mean_djf"+quote+">DJF</a>" 
     txt(112) = "<div class="+quote+"collapse"+quote+" id="+quote+"sst_mean_djf"+quote+">"
     txt(113) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(114) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sst_spatialmean_djf.indmem.png","Indiv")+"</li>"
     txt(115) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sst_spatialmean_djf.indmemdiff.png","Bias")+"</li>"
     txt(117) = "</ul></div></td>"
  else
     txt(117) = "DJF</td>"
  end if

  txt(120) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"sst_spatialmean_jfm.indmem.png")) then
     txt(121) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#sst_mean_jfm"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"sst_mean_jfm"+quote+">JFM</a>" 
     txt(122) = "<div class="+quote+"collapse"+quote+" id="+quote+"sst_mean_jfm"+quote+">"
     txt(123) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(124) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sst_spatialmean_jfm.indmem.png","Indiv")+"</li>"
     txt(125) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sst_spatialmean_jfm.indmemdiff.png","Bias")+"</li>"
     txt(127) = "</ul></div></td>"
  else
     txt(127) = "JFM</td>"
  end if

  txt(130) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"sst_spatialmean_mam.indmem.png")) then
     txt(131) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#sst_mean_mam"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"sst_mean_mam"+quote+">MAM</a>" 
     txt(132) = "<div class="+quote+"collapse"+quote+" id="+quote+"sst_mean_mam"+quote+">"
     txt(133) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(134) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sst_spatialmean_mam.indmem.png","Indiv")+"</li>"
     txt(135) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sst_spatialmean_mam.indmemdiff.png","Bias")+"</li>"
     txt(137) = "</ul></div></td>"
  else
     txt(137) = "MAM</td>"
  end if

  txt(140) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"sst_spatialmean_jja.indmem.png")) then
     txt(141) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#sst_mean_jja"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"sst_mean_jja"+quote+">JJA</a>" 
     txt(142) = "<div class="+quote+"collapse"+quote+" id="+quote+"sst_mean_jja"+quote+">"
     txt(143) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(144) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sst_spatialmean_jja.indmem.png","Indiv")+"</li>"
     txt(145) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sst_spatialmean_jja.indmemdiff.png","Bias")+"</li>"
     txt(147) = "</ul></div></td>"
  else
     txt(147) = "JJA</td>"
  end if

  txt(150) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"sst_spatialmean_jas.indmem.png")) then
     txt(151) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#sst_mean_jas"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"sst_mean_jas"+quote+">JAS</a>" 
     txt(152) = "<div class="+quote+"collapse"+quote+" id="+quote+"sst_mean_jas"+quote+">"
     txt(153) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(154) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sst_spatialmean_jas.indmem.png","Indiv")+"</li>"
     txt(155) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sst_spatialmean_jas.indmemdiff.png","Bias")+"</li>"
     txt(157) = "</ul></div></td>"
  else
     txt(157) = "JAS</td>"
  end if

  txt(160) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"sst_spatialmean_son.indmem.png")) then
     txt(161) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#sst_mean_son"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"sst_mean_son"+quote+">SON</a>" 
     txt(162) = "<div class="+quote+"collapse"+quote+" id="+quote+"sst_mean_son"+quote+">"
     txt(163) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(164) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sst_spatialmean_son.indmem.png","Indiv")+"</li>"
     txt(165) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sst_spatialmean_son.indmemdiff.png","Bias")+"</li>"
     txt(167) = "</ul></div></td>"
  else
     txt(167) = "SON</td>"
  end if

  txt(170) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"sst_spatialmean_ann.indmem.png")) then
     txt(171) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#sst_mean_ann"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"sst_mean_ann"+quote+">ANN</a>" 
     txt(172) = "<div class="+quote+"collapse"+quote+" id="+quote+"sst_mean_ann"+quote+">"
     txt(173) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(174) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sst_spatialmean_ann.indmem.png","Indiv")+"</li>"
     txt(175) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sst_spatialmean_ann.indmemdiff.png","Bias")+"</li>"
     txt(177) = "</ul></div></td>"
  else
     txt(177) = "ANN</td>"
  end if
  txt(178) = "</tr>"

  txt(204) = "<tr class="+quote+"d-flex"+quote+">"
  txt(205) = "<td class="+quote+"col"+quote+"><b>TAS</b></td>"

  txt(210) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"tas_spatialmean_djf.indmem.png")) then
     txt(211) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#tas_mean_djf"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"tas_mean_djf"+quote+">DJF</a>" 
     txt(212) = "<div class="+quote+"collapse"+quote+" id="+quote+"tas_mean_djf"+quote+">"
     txt(213) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(214) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"tas_spatialmean_djf.indmem.png","Indiv")+"</li>"
     txt(215) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"tas_spatialmean_djf.indmemdiff.png","Bias")+"</li>"
     txt(217) = "</ul></div></td>"
  else
     txt(217) = "DJF</td>"
  end if

  txt(220) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"tas_spatialmean_jfm.indmem.png")) then
     txt(221) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#tas_mean_jfm"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"tas_mean_jfm"+quote+">JFM</a>" 
     txt(222) = "<div class="+quote+"collapse"+quote+" id="+quote+"tas_mean_jfm"+quote+">"
     txt(223) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(224) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"tas_spatialmean_jfm.indmem.png","Indiv")+"</li>"
     txt(225) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"tas_spatialmean_jfm.indmemdiff.png","Bias")+"</li>"
     txt(227) = "</ul></div></td>"
  else
     txt(227) = "JFM</td>"
  end if

  txt(230) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"tas_spatialmean_mam.indmem.png")) then
     txt(231) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#tas_mean_mam"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"tas_mean_mam"+quote+">MAM</a>" 
     txt(232) = "<div class="+quote+"collapse"+quote+" id="+quote+"tas_mean_mam"+quote+">"
     txt(233) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(234) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"tas_spatialmean_mam.indmem.png","Indiv")+"</li>"
     txt(235) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"tas_spatialmean_mam.indmemdiff.png","Bias")+"</li>"
     txt(237) = "</ul></div></td>"
  else
     txt(237) = "MAM</td>"
  end if

  txt(240) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"tas_spatialmean_jja.indmem.png")) then
     txt(241) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#tas_mean_jja"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"tas_mean_jja"+quote+">JJA</a>" 
     txt(242) = "<div class="+quote+"collapse"+quote+" id="+quote+"tas_mean_jja"+quote+">"
     txt(243) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(244) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"tas_spatialmean_jja.indmem.png","Indiv")+"</li>"
     txt(245) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"tas_spatialmean_jja.indmemdiff.png","Bias")+"</li>"
     txt(247) = "</ul></div></td>"
  else
     txt(247) = "JJA</td>"
  end if

  txt(250) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"tas_spatialmean_jas.indmem.png")) then
     txt(251) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#tas_mean_jas"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"tas_mean_jas"+quote+">JAS</a>" 
     txt(252) = "<div class="+quote+"collapse"+quote+" id="+quote+"tas_mean_jas"+quote+">"
     txt(253) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(254) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"tas_spatialmean_jas.indmem.png","Indiv")+"</li>"
     txt(255) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"tas_spatialmean_jas.indmemdiff.png","Bias")+"</li>"
     txt(257) = "</ul></div></td>"
  else
     txt(257) = "JAS</td>"
  end if

  txt(260) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"tas_spatialmean_son.indmem.png")) then
     txt(261) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#tas_mean_son"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"tas_mean_son"+quote+">SON</a>" 
     txt(262) = "<div class="+quote+"collapse"+quote+" id="+quote+"tas_mean_son"+quote+">"
     txt(263) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(264) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"tas_spatialmean_son.indmem.png","Indiv")+"</li>"
     txt(265) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"tas_spatialmean_son.indmemdiff.png","Bias")+"</li>"
     txt(267) = "</ul></div></td>"
  else
     txt(267) = "SON</td>"
  end if

  txt(270) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"tas_spatialmean_ann.indmem.png")) then
     txt(271) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#tas_mean_ann"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"tas_mean_ann"+quote+">ANN</a>" 
     txt(272) = "<div class="+quote+"collapse"+quote+" id="+quote+"tas_mean_ann"+quote+">"
     txt(273) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(274) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"tas_spatialmean_ann.indmem.png","Indiv")+"</li>"
     txt(275) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"tas_spatialmean_ann.indmemdiff.png","Bias")+"</li>"
     txt(277) = "</ul></div></td>"
  else
     txt(277) = "ANN</td>"
  end if
  txt(278) = "</tr>"

  txt(304) = "<tr class="+quote+"d-flex"+quote+">"
  txt(305) = "<td class="+quote+"col"+quote+"><b>PSL</b></td>"

  txt(310) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"psl_spatialmean_djf.indmem.png")) then
     txt(311) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#psl_mean_djf"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"psl_mean_djf"+quote+">DJF</a>" 
     txt(312) = "<div class="+quote+"collapse"+quote+" id="+quote+"psl_mean_djf"+quote+">"
     txt(313) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(314) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psl_spatialmean_djf.indmem.png","Indiv")+"</li>"
     txt(315) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psl_spatialmean_djf.indmemdiff.png","Bias")+"</li>"
     txt(317) = "</ul></div></td>"
  else
     txt(317) = "DJF</td>"
  end if

  txt(320) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"psl_spatialmean_jfm.indmem.png")) then
     txt(321) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#psl_mean_jfm"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"psl_mean_jfm"+quote+">JFM</a>" 
     txt(322) = "<div class="+quote+"collapse"+quote+" id="+quote+"psl_mean_jfm"+quote+">"
     txt(323) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(324) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psl_spatialmean_jfm.indmem.png","Indiv")+"</li>"
     txt(325) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psl_spatialmean_jfm.indmemdiff.png","Bias")+"</li>"
     txt(327) = "</ul></div></td>"
  else
     txt(327) = "JFM</td>"
  end if

  txt(330) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"psl_spatialmean_mam.indmem.png")) then
     txt(331) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#psl_mean_mam"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"psl_mean_mam"+quote+">MAM</a>" 
     txt(332) = "<div class="+quote+"collapse"+quote+" id="+quote+"psl_mean_mam"+quote+">"
     txt(333) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(334) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psl_spatialmean_mam.indmem.png","Indiv")+"</li>"
     txt(335) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psl_spatialmean_mam.indmemdiff.png","Bias")+"</li>"
     txt(337) = "</ul></div></td>"
  else
     txt(337) = "MAM</td>"
  end if

  txt(340) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"psl_spatialmean_jja.indmem.png")) then
     txt(341) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#psl_mean_jja"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"psl_mean_jja"+quote+">JJA</a>" 
     txt(342) = "<div class="+quote+"collapse"+quote+" id="+quote+"psl_mean_jja"+quote+">"
     txt(343) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(344) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psl_spatialmean_jja.indmem.png","Indiv")+"</li>"
     txt(345) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psl_spatialmean_jja.indmemdiff.png","Bias")+"</li>"
     txt(347) = "</ul></div></td>"
  else
     txt(347) = "JJA</td>"
  end if

  txt(350) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"psl_spatialmean_jas.indmem.png")) then
     txt(351) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#psl_mean_jas"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"psl_mean_jas"+quote+">JAS</a>" 
     txt(352) = "<div class="+quote+"collapse"+quote+" id="+quote+"psl_mean_jas"+quote+">"
     txt(353) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(354) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psl_spatialmean_jas.indmem.png","Indiv")+"</li>"
     txt(355) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psl_spatialmean_jas.indmemdiff.png","Bias")+"</li>"
     txt(357) = "</ul></div></td>"
  else
     txt(357) = "JAS</td>"
  end if

  txt(360) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"psl_spatialmean_son.indmem.png")) then
     txt(361) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#psl_mean_son"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"psl_mean_son"+quote+">SON</a>" 
     txt(362) = "<div class="+quote+"collapse"+quote+" id="+quote+"psl_mean_son"+quote+">"
     txt(363) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(364) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psl_spatialmean_son.indmem.png","Indiv")+"</li>"
     txt(365) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psl_spatialmean_son.indmemdiff.png","Bias")+"</li>"
     txt(367) = "</ul></div></td>"
  else
     txt(367) = "SON</td>"
  end if

  txt(370) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"psl_spatialmean_ann.indmem.png")) then
     txt(371) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#psl_mean_ann"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"psl_mean_ann"+quote+">ANN</a>" 
     txt(372) = "<div class="+quote+"collapse"+quote+" id="+quote+"psl_mean_ann"+quote+">"
     txt(373) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(374) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psl_spatialmean_ann.indmem.png","Indiv")+"</li>"
     txt(375) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psl_spatialmean_ann.indmemdiff.png","Bias")+"</li>"
     txt(377) = "</ul></div></td>"
  else
     txt(377) = "ANN</td>"
  end if
  txt(378) = "</tr>"

  txt(404) = "<tr class="+quote+"d-flex"+quote+">"
  txt(405) = "<td class="+quote+"col"+quote+"><b>PR</b></td>"

  txt(410) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"pr_spatialmean_djf.indmem.png")) then
     txt(411) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#pr_mean_djf"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"pr_mean_djf"+quote+">DJF</a>" 
     txt(412) = "<div class="+quote+"collapse"+quote+" id="+quote+"pr_mean_djf"+quote+">"
     txt(413) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(414) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pr_spatialmean_djf.indmem.png","Indiv")+"</li>"
     txt(415) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pr_spatialmean_djf.indmemdiff.png","Bias")+"</li>"
     txt(417) = "</ul></div></td>"
  else
     txt(417) = "DJF</td>"
  end if

  txt(420) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"pr_spatialmean_jfm.indmem.png")) then
     txt(421) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#pr_mean_jfm"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"pr_mean_jfm"+quote+">JFM</a>" 
     txt(422) = "<div class="+quote+"collapse"+quote+" id="+quote+"pr_mean_jfm"+quote+">"
     txt(423) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(424) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pr_spatialmean_jfm.indmem.png","Indiv")+"</li>"
     txt(425) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pr_spatialmean_jfm.indmemdiff.png","Bias")+"</li>"
     txt(427) = "</ul></div></td>"
  else
     txt(427) = "JFM</td>"
  end if

  txt(430) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"pr_spatialmean_mam.indmem.png")) then
     txt(431) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#pr_mean_mam"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"pr_mean_mam"+quote+">MAM</a>" 
     txt(432) = "<div class="+quote+"collapse"+quote+" id="+quote+"pr_mean_mam"+quote+">"
     txt(433) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(434) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pr_spatialmean_mam.indmem.png","Indiv")+"</li>"
     txt(435) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pr_spatialmean_mam.indmemdiff.png","Bias")+"</li>"
     txt(437) = "</ul></div></td>"
  else
     txt(437) = "MAM</td>"
  end if

  txt(440) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"pr_spatialmean_jja.indmem.png")) then
     txt(441) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#pr_mean_jja"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"pr_mean_jja"+quote+">JJA</a>" 
     txt(442) = "<div class="+quote+"collapse"+quote+" id="+quote+"pr_mean_jja"+quote+">"
     txt(443) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(444) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pr_spatialmean_jja.indmem.png","Indiv")+"</li>"
     txt(445) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pr_spatialmean_jja.indmemdiff.png","Bias")+"</li>"
     txt(447) = "</ul></div></td>"
  else
     txt(447) = "JJA</td>"
  end if

  txt(450) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"pr_spatialmean_jas.indmem.png")) then
     txt(451) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#pr_mean_jas"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"pr_mean_jas"+quote+">JAS</a>" 
     txt(452) = "<div class="+quote+"collapse"+quote+" id="+quote+"pr_mean_jas"+quote+">"
     txt(453) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(454) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pr_spatialmean_jas.indmem.png","Indiv")+"</li>"
     txt(455) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pr_spatialmean_jas.indmemdiff.png","Bias")+"</li>"
     txt(457) = "</ul></div></td>"
  else
     txt(457) = "JAS</td>"
  end if
  txt(460) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"pr_spatialmean_son.indmem.png")) then
     txt(461) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#pr_mean_son"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"pr_mean_son"+quote+">SON</a>" 
     txt(462) = "<div class="+quote+"collapse"+quote+" id="+quote+"pr_mean_son"+quote+">"
     txt(463) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(464) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pr_spatialmean_son.indmem.png","Indiv")+"</li>"
     txt(465) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pr_spatialmean_son.indmemdiff.png","Bias")+"</li>"
     txt(467) = "</ul></div></td>"
  else
     txt(467) = "SON</td>"
  end if

  txt(470) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"pr_spatialmean_ann.indmem.png")) then
     txt(471) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#pr_mean_ann"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"pr_mean_ann"+quote+">ANN</a>" 
     txt(472) = "<div class="+quote+"collapse"+quote+" id="+quote+"pr_mean_ann"+quote+">"
     txt(473) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(474) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pr_spatialmean_ann.indmem.png","Indiv")+"</li>"
     txt(475) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pr_spatialmean_ann.indmemdiff.png","Bias")+"</li>"
     txt(477) = "</ul></div></td>"
  else
     txt(477) = "ANN</td>"
  end if
  txt(478) = "</tr>"


  txt(507) = "<tr class="+quote+"d-flex"+quote+">"
  txt(508) = "<td class="+quote+"col"+quote+"><b>SICONC NH</b></td>"

  txt(510) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"siconc_nh_spatialmean_djf.indmem.png")) then
     txt(511) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#siconc_nh_mean_djf"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"siconc_nh_mean_djf"+quote+">DJF</a>" 
     txt(512) = "<div class="+quote+"collapse"+quote+" id="+quote+"siconc_nh_mean_djf"+quote+">"
     txt(513) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(514) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_nh_spatialmean_djf.indmem.png","Indiv")+"</li>"
     txt(515) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_nh_spatialmean_djf.indmemdiff.png","Bias")+"</li>"
     txt(517) = "</ul></div></td>"
  else
     txt(517) = "DJF</td>"
  end if

  txt(520) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"siconc_nh_spatialmean_jfm.indmem.png")) then
     txt(521) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#siconc_nh_mean_jfm"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"siconc_nh_mean_jfm"+quote+">JFM</a>" 
     txt(522) = "<div class="+quote+"collapse"+quote+" id="+quote+"siconc_nh_mean_jfm"+quote+">"
     txt(523) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(524) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_nh_spatialmean_jfm.indmem.png","Indiv")+"</li>"
     txt(525) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_nh_spatialmean_jfm.indmemdiff.png","Bias")+"</li>"
     txt(527) = "</ul></div></td>"
  else
     txt(527) = "JFM</td>"
  end if

  txt(530) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"siconc_nh_spatialmean_mam.indmem.png")) then
     txt(531) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#siconc_nh_mean_mam"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"siconc_nh_mean_mam"+quote+">MAM</a>" 
     txt(532) = "<div class="+quote+"collapse"+quote+" id="+quote+"siconc_nh_mean_mam"+quote+">"
     txt(533) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(534) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_nh_spatialmean_mam.indmem.png","Indiv")+"</li>"
     txt(535) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_nh_spatialmean_mam.indmemdiff.png","Bias")+"</li>"
     txt(537) = "</ul></div></td>"
  else
     txt(537) = "MAM</td>"
  end if

  txt(540) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"siconc_nh_spatialmean_jja.indmem.png")) then
     txt(541) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#siconc_nh_mean_jja"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"siconc_nh_mean_jja"+quote+">JJA</a>" 
     txt(542) = "<div class="+quote+"collapse"+quote+" id="+quote+"siconc_nh_mean_jja"+quote+">"
     txt(543) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(544) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_nh_spatialmean_jja.indmem.png","Indiv")+"</li>"
     txt(545) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_nh_spatialmean_jja.indmemdiff.png","Bias")+"</li>"
     txt(547) = "</ul></div></td>"
  else
     txt(547) = "JJA</td>"
  end if

  txt(550) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"siconc_nh_spatialmean_jas.indmem.png")) then
     txt(551) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#siconc_nh_mean_jas"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"siconc_nh_mean_jas"+quote+">JAS</a>" 
     txt(552) = "<div class="+quote+"collapse"+quote+" id="+quote+"siconc_nh_mean_jas"+quote+">"
     txt(553) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(554) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_nh_spatialmean_jas.indmem.png","Indiv")+"</li>"
     txt(555) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_nh_spatialmean_jas.indmemdiff.png","Bias")+"</li>"
     txt(557) = "</ul></div></td>"
  else
     txt(557) = "JAS</td>"
  end if

  txt(560) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"siconc_nh_spatialmean_son.indmem.png")) then
     txt(561) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#siconc_nh_mean_son"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"siconc_nh_mean_son"+quote+">SON</a>" 
     txt(562) = "<div class="+quote+"collapse"+quote+" id="+quote+"siconc_nh_mean_son"+quote+">"
     txt(563) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(564) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_nh_spatialmean_son.indmem.png","Indiv")+"</li>"
     txt(565) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_nh_spatialmean_son.indmemdiff.png","Bias")+"</li>"
     txt(567) = "</ul></div></td>"
  else
     txt(567) = "SON</td>"
  end if

  txt(570) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"siconc_nh_spatialmean_ann.indmem.png")) then
     txt(571) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#siconc_nh_mean_ann"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"siconc_nh_mean_ann"+quote+">ANN</a>" 
     txt(572) = "<div class="+quote+"collapse"+quote+" id="+quote+"siconc_nh_mean_ann"+quote+">"
     txt(573) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(574) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_nh_spatialmean_ann.indmem.png","Indiv")+"</li>"
     txt(575) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_nh_spatialmean_ann.indmemdiff.png","Bias")+"</li>"
     txt(577) = "</ul></div></td>"
  else
     txt(577) = "ANN</td>"
  end if
  txt(578) = "</tr>"

  txt(604) = "<tr class="+quote+"d-flex"+quote+">"
  txt(605) = "<td class="+quote+"col"+quote+"><b>SICONC SH</b></td>"

  txt(610) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"siconc_sh_spatialmean_djf.indmem.png")) then
     txt(611) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#siconc_sh_mean_djf"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"siconc_sh_mean_djf"+quote+">DJF</a>" 
     txt(612) = "<div class="+quote+"collapse"+quote+" id="+quote+"siconc_sh_mean_djf"+quote+">"
     txt(613) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(614) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_sh_spatialmean_djf.indmem.png","Indiv")+"</li>"
     txt(615) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_sh_spatialmean_djf.indmemdiff.png","Bias")+"</li>"
     txt(617) = "</ul></div></td>"
  else
     txt(617) = "DJF</td>"
  end if

  txt(620) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"siconc_sh_spatialmean_jfm.indmem.png")) then
     txt(621) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#siconc_sh_mean_jfm"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"siconc_sh_mean_jfm"+quote+">JFM</a>" 
     txt(622) = "<div class="+quote+"collapse"+quote+" id="+quote+"siconc_sh_mean_jfm"+quote+">"
     txt(623) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(624) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_sh_spatialmean_jfm.indmem.png","Indiv")+"</li>"
     txt(625) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_sh_spatialmean_jfm.indmemdiff.png","Bias")+"</li>"
     txt(627) = "</ul></div></td>"
  else
     txt(627) = "JFM</td>"
  end if

  txt(630) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"siconc_sh_spatialmean_mam.indmem.png")) then
     txt(631) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#siconc_sh_mean_mam"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"siconc_sh_mean_mam"+quote+">MAM</a>" 
     txt(632) = "<div class="+quote+"collapse"+quote+" id="+quote+"siconc_sh_mean_mam"+quote+">"
     txt(633) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(634) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_sh_spatialmean_mam.indmem.png","Indiv")+"</li>"
     txt(635) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_sh_spatialmean_mam.indmemdiff.png","Bias")+"</li>"
     txt(637) = "</ul></div></td>"
  else
     txt(637) = "MAM</td>"
  end if

  txt(640) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"siconc_sh_spatialmean_jja.indmem.png")) then
     txt(641) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#siconc_sh_mean_jja"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"siconc_sh_mean_jja"+quote+">JJA</a>" 
     txt(642) = "<div class="+quote+"collapse"+quote+" id="+quote+"siconc_sh_mean_jja"+quote+">"
     txt(643) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(644) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_sh_spatialmean_jja.indmem.png","Indiv")+"</li>"
     txt(645) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_sh_spatialmean_jja.indmemdiff.png","Bias")+"</li>"
     txt(647) = "</ul></div></td>"
  else
     txt(647) = "JJA</td>"
  end if

  txt(650) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"siconc_sh_spatialmean_jas.indmem.png")) then
     txt(651) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#siconc_sh_mean_jas"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"siconc_sh_mean_jas"+quote+">JAS</a>" 
     txt(652) = "<div class="+quote+"collapse"+quote+" id="+quote+"siconc_sh_mean_jas"+quote+">"
     txt(653) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(654) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_sh_spatialmean_jas.indmem.png","Indiv")+"</li>"
     txt(655) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_sh_spatialmean_jas.indmemdiff.png","Bias")+"</li>"
     txt(657) = "</ul></div></td>"
  else
     txt(657) = "JAS</td>"
  end if

  txt(660) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"siconc_sh_spatialmean_son.indmem.png")) then
     txt(661) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#siconc_sh_mean_son"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"siconc_sh_mean_son"+quote+">SON</a>" 
     txt(662) = "<div class="+quote+"collapse"+quote+" id="+quote+"siconc_sh_mean_son"+quote+">"
     txt(663) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(664) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_sh_spatialmean_son.indmem.png","Indiv")+"</li>"
     txt(665) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_sh_spatialmean_son.indmemdiff.png","Bias")+"</li>"
     txt(667) = "</ul></div></td>"
  else
     txt(667) = "SON</td>"
  end if

  txt(670) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"siconc_sh_spatialmean_ann.indmem.png")) then
     txt(671) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#siconc_sh_mean_ann"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"siconc_sh_mean_ann"+quote+">ANN</a>" 
     txt(672) = "<div class="+quote+"collapse"+quote+" id="+quote+"siconc_sh_mean_ann"+quote+">"
     txt(673) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(674) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_sh_spatialmean_ann.indmem.png","Indiv")+"</li>"
     txt(675) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_sh_spatialmean_ann.indmemdiff.png","Bias")+"</li>"
     txt(677) = "</ul></div></td>"
  else
     txt(677) = "ANN</td>"
  end if
  txt(678) = "</tr>"

  txt(704) = "<tr class="+quote+"d-flex"+quote+">"
  txt(705) = "<td class="+quote+"col"+quote+"><b>ZOS</b></td>"

  txt(710) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"zos_spatialmean_djf.indmem.png")) then
     txt(711) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#zos_mean_djf"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"zos_mean_djf"+quote+">DJF</a>" 
     txt(712) = "<div class="+quote+"collapse"+quote+" id="+quote+"zos_mean_djf"+quote+">"
     txt(713) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(714) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"zos_spatialmean_djf.indmem.png","Indiv")+"</li>"
     txt(715) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"zos_spatialmean_djf.indmemdiff.png","Bias")+"</li>"
     txt(717) = "</ul></div></td>"
  else
     txt(717) = "DJF</td>"
  end if

  txt(720) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"zos_spatialmean_jfm.indmem.png")) then
     txt(721) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#zos_mean_jfm"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"zos_mean_jfm"+quote+">JFM</a>" 
     txt(722) = "<div class="+quote+"collapse"+quote+" id="+quote+"zos_mean_jfm"+quote+">"
     txt(723) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(724) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"zos_spatialmean_jfm.indmem.png","Indiv")+"</li>"
     txt(725) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"zos_spatialmean_jfm.indmemdiff.png","Bias")+"</li>"
     txt(727) = "</ul></div></td>"
  else
     txt(727) = "JFM</td>"
  end if

  txt(730) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"zos_spatialmean_mam.indmem.png")) then
     txt(731) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#zos_mean_mam"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"zos_mean_mam"+quote+">MAM</a>" 
     txt(732) = "<div class="+quote+"collapse"+quote+" id="+quote+"zos_mean_mam"+quote+">"
     txt(733) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(734) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"zos_spatialmean_mam.indmem.png","Indiv")+"</li>"
     txt(735) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"zos_spatialmean_mam.indmemdiff.png","Bias")+"</li>"
     txt(737) = "</ul></div></td>"
  else
     txt(737) = "MAM</td>"
  end if

  txt(740) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"zos_spatialmean_jja.indmem.png")) then
     txt(741) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#zos_mean_jja"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"zos_mean_jja"+quote+">JJA</a>" 
     txt(742) = "<div class="+quote+"collapse"+quote+" id="+quote+"zos_mean_jja"+quote+">"
     txt(743) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(744) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"zos_spatialmean_jja.indmem.png","Indiv")+"</li>"
     txt(745) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"zos_spatialmean_jja.indmemdiff.png","Bias")+"</li>"
     txt(747) = "</ul></div></td>"
  else
     txt(747) = "JJA</td>"
  end if

  txt(750) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"zos_spatialmean_jas.indmem.png")) then
     txt(751) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#zos_mean_jas"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"zos_mean_jas"+quote+">JAS</a>" 
     txt(752) = "<div class="+quote+"collapse"+quote+" id="+quote+"zos_mean_jas"+quote+">"
     txt(753) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(754) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"zos_spatialmean_jas.indmem.png","Indiv")+"</li>"
     txt(755) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"zos_spatialmean_jas.indmemdiff.png","Bias")+"</li>"
     txt(757) = "</ul></div></td>"
  else
     txt(757) = "JAS</td>"
  end if

  txt(760) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"zos_spatialmean_son.indmem.png")) then
     txt(761) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#zos_mean_son"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"zos_mean_son"+quote+">SON</a>" 
     txt(762) = "<div class="+quote+"collapse"+quote+" id="+quote+"zos_mean_son"+quote+">"
     txt(763) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(764) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"zos_spatialmean_son.indmem.png","Indiv")+"</li>"
     txt(765) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"zos_spatialmean_son.indmemdiff.png","Bias")+"</li>"
     txt(767) = "</ul></div></td>"
  else
     txt(767) = "SON</td>"
  end if

  txt(770) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"zos_spatialmean_ann.indmem.png")) then
     txt(771) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#zos_mean_ann"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"zos_mean_ann"+quote+">ANN</a>" 
     txt(772) = "<div class="+quote+"collapse"+quote+" id="+quote+"zos_mean_ann"+quote+">"
     txt(773) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(774) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"zos_spatialmean_ann.indmem.png","Indiv")+"</li>"
     txt(775) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"zos_spatialmean_ann.indmemdiff.png","Bias")+"</li>"
     txt(777) = "</ul></div></td>"
  else
     txt(777) = "ANN</td>"
  end if
  txt(778) = "</tr>"
  txt(780) = "</table></div></div>"

  txt(1100) = "<div class="+quote+"row"+quote+">"
  txt(1101) = "<div class="+quote+"col"+quote+">"
  txt(1102) = "<table class="+quote+"table table-striped table-bordered"+quote+">"
  txt(1103) = "<h3 class="+quote+"display-6"+quote+">Standard Deviations</h3>"
  txt(1104) = "<tr class="+quote+"d-flex"+quote+">"
  txt(1105) = "<td class="+quote+"col"+quote+"><b>SST</b></td>"

  txt(1110) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"sst_spatialstddev_djf.indmem.png")) then
     txt(1111) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#sst_stddev_djf"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"sst_stddev_djf"+quote+">DJF</a>" 
     txt(1112) = "<div class="+quote+"collapse"+quote+" id="+quote+"sst_stddev_djf"+quote+">"
     txt(1113) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1114) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sst_spatialstddev_djf.indmem.png","Indiv")+"</li>"
     txt(1115) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sst_spatialstddev_djf.indmemdiff.png","Bias")+"</li>"
     txt(1117) = "</ul></div></td>"
  else
     txt(1117) = "DJF</td>"
  end if

  txt(1120) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"sst_spatialstddev_jfm.indmem.png")) then
     txt(1121) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#sst_stddev_jfm"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"sst_stddev_jfm"+quote+">JFM</a>" 
     txt(1122) = "<div class="+quote+"collapse"+quote+" id="+quote+"sst_stddev_jfm"+quote+">"
     txt(1123) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1124) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sst_spatialstddev_jfm.indmem.png","Indiv")+"</li>"
     txt(1125) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sst_spatialstddev_jfm.indmemdiff.png","Bias")+"</li>"
     txt(1127) = "</ul></div></td>"
  else
     txt(1127) = "JFM</td>"
  end if

  txt(1130) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"sst_spatialstddev_mam.indmem.png")) then
     txt(1131) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#sst_stddev_mam"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"sst_stddev_mam"+quote+">MAM</a>" 
     txt(1132) = "<div class="+quote+"collapse"+quote+" id="+quote+"sst_stddev_mam"+quote+">"
     txt(1133) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1134) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sst_spatialstddev_mam.indmem.png","Indiv")+"</li>"
     txt(1135) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sst_spatialstddev_mam.indmemdiff.png","Bias")+"</li>"
     txt(1137) = "</ul></div></td>"
  else
     txt(1137) = "MAM</td>"
  end if

  txt(1140) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"sst_spatialstddev_jja.indmem.png")) then
     txt(1141) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#sst_stddev_jja"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"sst_stddev_jja"+quote+">JJA</a>" 
     txt(1142) = "<div class="+quote+"collapse"+quote+" id="+quote+"sst_stddev_jja"+quote+">"
     txt(1143) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1144) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sst_spatialstddev_jja.indmem.png","Indiv")+"</li>"
     txt(1145) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sst_spatialstddev_jja.indmemdiff.png","Bias")+"</li>"
     txt(1147) = "</ul></div></td>"
  else
     txt(1147) = "JJA</td>"
  end if

  txt(1150) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"sst_spatialstddev_jas.indmem.png")) then
     txt(1151) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#sst_stddev_jas"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"sst_stddev_jas"+quote+">JAS</a>" 
     txt(1152) = "<div class="+quote+"collapse"+quote+" id="+quote+"sst_stddev_jas"+quote+">"
     txt(1153) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1154) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sst_spatialstddev_jas.indmem.png","Indiv")+"</li>"
     txt(1155) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sst_spatialstddev_jas.indmemdiff.png","Bias")+"</li>"
     txt(1157) = "</ul></div></td>"
  else
     txt(1157) = "JAS</td>"
  end if

  txt(1160) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"sst_spatialstddev_son.indmem.png")) then
     txt(1161) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#sst_stddev_son"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"sst_stddev_son"+quote+">SON</a>" 
     txt(1162) = "<div class="+quote+"collapse"+quote+" id="+quote+"sst_stddev_son"+quote+">"
     txt(1163) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1164) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sst_spatialstddev_son.indmem.png","Indiv")+"</li>"
     txt(1165) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sst_spatialstddev_son.indmemdiff.png","Bias")+"</li>"
     txt(1167) = "</ul></div></td>"
  else
     txt(1167) = "SON</td>"
  end if

  txt(1170) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"sst_spatialstddev_ann.indmem.png")) then
     txt(1171) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#sst_stddev_ann"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"sst_stddev_ann"+quote+">ANN</a>" 
     txt(1172) = "<div class="+quote+"collapse"+quote+" id="+quote+"sst_stddev_ann"+quote+">"
     txt(1173) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1174) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sst_spatialstddev_ann.indmem.png","Indiv")+"</li>"
     txt(1175) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sst_spatialstddev_ann.indmemdiff.png","Bias")+"</li>"
     txt(1177) = "</ul></div></td>"
  else
     txt(1177) = "ANN</td>"
  end if
  txt(1178) = "</tr>"


  txt(1204) = "<tr class="+quote+"d-flex"+quote+">"
  txt(1205) = "<td class="+quote+"col"+quote+"><b>TAS</b></td>"

  txt(1210) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"tas_spatialstddev_djf.indmem.png")) then
     txt(1211) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#tas_stddev_djf"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"tas_stddev_djf"+quote+">DJF</a>" 
     txt(1212) = "<div class="+quote+"collapse"+quote+" id="+quote+"tas_stddev_djf"+quote+">"
     txt(1213) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1214) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"tas_spatialstddev_djf.indmem.png","Indiv")+"</li>"
     txt(1215) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"tas_spatialstddev_djf.indmemdiff.png","Bias")+"</li>"
     txt(1217) = "</ul></div></td>"
  else
     txt(1217) = "DJF</td>"
  end if

  txt(1220) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"tas_spatialstddev_jfm.indmem.png")) then
     txt(1221) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#tas_stddev_jfm"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"tas_stddev_jfm"+quote+">JFM</a>" 
     txt(1222) = "<div class="+quote+"collapse"+quote+" id="+quote+"tas_stddev_jfm"+quote+">"
     txt(1223) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1224) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"tas_spatialstddev_jfm.indmem.png","Indiv")+"</li>"
     txt(1225) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"tas_spatialstddev_jfm.indmemdiff.png","Bias")+"</li>"
     txt(1227) = "</ul></div></td>"
  else
     txt(1227) = "JFM</td>"
  end if

  txt(1230) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"tas_spatialstddev_mam.indmem.png")) then
     txt(1231) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#tas_stddev_mam"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"tas_stddev_mam"+quote+">MAM</a>" 
     txt(1232) = "<div class="+quote+"collapse"+quote+" id="+quote+"tas_stddev_mam"+quote+">"
     txt(1233) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1234) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"tas_spatialstddev_mam.indmem.png","Indiv")+"</li>"
     txt(1235) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"tas_spatialstddev_mam.indmemdiff.png","Bias")+"</li>"
     txt(1237) = "</ul></div></td>"
  else
     txt(1237) = "MAM</td>"
  end if

  txt(1240) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"tas_spatialstddev_jja.indmem.png")) then
     txt(1241) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#tas_stddev_jja"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"tas_stddev_jja"+quote+">JJA</a>" 
     txt(1242) = "<div class="+quote+"collapse"+quote+" id="+quote+"tas_stddev_jja"+quote+">"
     txt(1243) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1244) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"tas_spatialstddev_jja.indmem.png","Indiv")+"</li>"
     txt(1245) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"tas_spatialstddev_jja.indmemdiff.png","Bias")+"</li>"
     txt(1247) = "</ul></div></td>"
  else
     txt(1247) = "JJA</td>"
  end if

  txt(1250) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"tas_spatialstddev_jas.indmem.png")) then
     txt(1251) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#tas_stddev_jas"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"tas_stddev_jas"+quote+">JAS</a>" 
     txt(1252) = "<div class="+quote+"collapse"+quote+" id="+quote+"tas_stddev_jas"+quote+">"
     txt(1253) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1254) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"tas_spatialstddev_jas.indmem.png","Indiv")+"</li>"
     txt(1255) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"tas_spatialstddev_jas.indmemdiff.png","Bias")+"</li>"
     txt(1257) = "</ul></div></td>"
  else
     txt(1257) = "JAS</td>"
  end if

  txt(1260) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"tas_spatialstddev_son.indmem.png")) then
     txt(1261) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#tas_stddev_son"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"tas_stddev_son"+quote+">SON</a>" 
     txt(1262) = "<div class="+quote+"collapse"+quote+" id="+quote+"tas_stddev_son"+quote+">"
     txt(1263) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1264) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"tas_spatialstddev_son.indmem.png","Indiv")+"</li>"
     txt(1265) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"tas_spatialstddev_son.indmemdiff.png","Bias")+"</li>"
     txt(1267) = "</ul></div></td>"
  else
     txt(1267) = "SON</td>"
  end if

  txt(1270) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"tas_spatialstddev_ann.indmem.png")) then
     txt(1271) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#tas_stddev_ann"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"tas_stddev_ann"+quote+">ANN</a>" 
     txt(1272) = "<div class="+quote+"collapse"+quote+" id="+quote+"tas_stddev_ann"+quote+">"
     txt(1273) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1274) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"tas_spatialstddev_ann.indmem.png","Indiv")+"</li>"
     txt(1275) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"tas_spatialstddev_ann.indmemdiff.png","Bias")+"</li>"
     txt(1277) = "</ul></div></td>"
  else
     txt(1277) = "ANN</td>"
  end if
  txt(1278) = "</tr>"

  txt(1304) = "<tr class="+quote+"d-flex"+quote+">"
  txt(1305) = "<td class="+quote+"col"+quote+"><b>PSL</b></td>"

  txt(1310) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"psl_spatialstddev_djf.indmem.png")) then
     txt(1311) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#psl_stddev_djf"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"psl_stddev_djf"+quote+">DJF</a>" 
     txt(1312) = "<div class="+quote+"collapse"+quote+" id="+quote+"psl_stddev_djf"+quote+">"
     txt(1313) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1314) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psl_spatialstddev_djf.indmem.png","Indiv")+"</li>"
     txt(1315) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psl_spatialstddev_djf.indmemdiff.png","Bias")+"</li>"
     txt(1317) = "</ul></div></td>"
  else
     txt(1317) = "DJF</td>"
  end if

  txt(1320) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"psl_spatialstddev_jfm.indmem.png")) then
     txt(1321) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#psl_stddev_jfm"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"psl_stddev_jfm"+quote+">JFM</a>" 
     txt(1322) = "<div class="+quote+"collapse"+quote+" id="+quote+"psl_stddev_jfm"+quote+">"
     txt(1323) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1324) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psl_spatialstddev_jfm.indmem.png","Indiv")+"</li>"
     txt(1325) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psl_spatialstddev_jfm.indmemdiff.png","Bias")+"</li>"
     txt(1327) = "</ul></div></td>"
  else
     txt(1327) = "JFM</td>"
  end if

  txt(1330) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"psl_spatialstddev_mam.indmem.png")) then
     txt(1331) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#psl_stddev_mam"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"psl_stddev_mam"+quote+">MAM</a>" 
     txt(1332) = "<div class="+quote+"collapse"+quote+" id="+quote+"psl_stddev_mam"+quote+">"
     txt(1333) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1334) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psl_spatialstddev_mam.indmem.png","Indiv")+"</li>"
     txt(1335) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psl_spatialstddev_mam.indmemdiff.png","Bias")+"</li>"
     txt(1337) = "</ul></div></td>"
  else
     txt(1337) = "MAM</td>"
  end if

  txt(1340) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"psl_spatialstddev_jja.indmem.png")) then
     txt(1341) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#psl_stddev_jja"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"psl_stddev_jja"+quote+">JJA</a>" 
     txt(1342) = "<div class="+quote+"collapse"+quote+" id="+quote+"psl_stddev_jja"+quote+">"
     txt(1343) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1344) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psl_spatialstddev_jja.indmem.png","Indiv")+"</li>"
     txt(1345) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psl_spatialstddev_jja.indmemdiff.png","Bias")+"</li>"
     txt(1347) = "</ul></div></td>"
  else
     txt(1347) = "JJA</td>"
  end if

  txt(1350) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"psl_spatialstddev_jas.indmem.png")) then
     txt(1351) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#psl_stddev_jas"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"psl_stddev_jas"+quote+">JAS</a>" 
     txt(1352) = "<div class="+quote+"collapse"+quote+" id="+quote+"psl_stddev_jas"+quote+">"
     txt(1353) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1354) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psl_spatialstddev_jas.indmem.png","Indiv")+"</li>"
     txt(1355) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psl_spatialstddev_jas.indmemdiff.png","Bias")+"</li>"
     txt(1357) = "</ul></div></td>"
  else
     txt(1357) = "JAS</td>"
  end if

  txt(1360) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"psl_spatialstddev_son.indmem.png")) then
     txt(1361) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#psl_stddev_son"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"psl_stddev_son"+quote+">SON</a>" 
     txt(1362) = "<div class="+quote+"collapse"+quote+" id="+quote+"psl_stddev_son"+quote+">"
     txt(1363) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1364) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psl_spatialstddev_son.indmem.png","Indiv")+"</li>"
     txt(1365) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psl_spatialstddev_son.indmemdiff.png","Bias")+"</li>"
     txt(1367) = "</ul></div></td>"
  else
     txt(1367) = "SON</td>"
  end if

  txt(1370) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"psl_spatialstddev_ann.indmem.png")) then
     txt(1371) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#psl_stddev_ann"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"psl_stddev_ann"+quote+">ANN</a>" 
     txt(1372) = "<div class="+quote+"collapse"+quote+" id="+quote+"psl_stddev_ann"+quote+">"
     txt(1373) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1374) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psl_spatialstddev_ann.indmem.png","Indiv")+"</li>"
     txt(1375) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psl_spatialstddev_ann.indmemdiff.png","Bias")+"</li>"
     txt(1377) = "</ul></div></td>"
  else
     txt(1377) = "ANN</td>"
  end if
  txt(1378) = "</tr>"

  txt(1404) = "<tr class="+quote+"d-flex"+quote+">"
  txt(1405) = "<td class="+quote+"col"+quote+"><b>PR</b></td>"

  txt(1410) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"pr_spatialstddev_djf.indmem.png")) then
     txt(1411) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#pr_stddev_djf"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"pr_stddev_djf"+quote+">DJF</a>" 
     txt(1412) = "<div class="+quote+"collapse"+quote+" id="+quote+"pr_stddev_djf"+quote+">"
     txt(1413) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1414) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pr_spatialstddev_djf.indmem.png","Indiv")+"</li>"
     txt(1415) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pr_spatialstddev_djf.indmemdiff.png","Bias")+"</li>"
     txt(1417) = "</ul></div></td>"
  else
     txt(1417) = "DJF</td>"
  end if

  txt(1420) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"pr_spatialstddev_jfm.indmem.png")) then
     txt(1421) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#pr_stddev_jfm"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"pr_stddev_jfm"+quote+">JFM</a>" 
     txt(1422) = "<div class="+quote+"collapse"+quote+" id="+quote+"pr_stddev_jfm"+quote+">"
     txt(1423) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1424) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pr_spatialstddev_jfm.indmem.png","Indiv")+"</li>"
     txt(1425) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pr_spatialstddev_jfm.indmemdiff.png","Bias")+"</li>"
     txt(1427) = "</ul></div></td>"
  else
     txt(1427) = "JFM</td>"
  end if

  txt(1430) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"pr_spatialstddev_mam.indmem.png")) then
     txt(1431) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#pr_stddev_mam"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"pr_stddev_mam"+quote+">MAM</a>" 
     txt(1432) = "<div class="+quote+"collapse"+quote+" id="+quote+"pr_stddev_mam"+quote+">"
     txt(1433) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1434) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pr_spatialstddev_mam.indmem.png","Indiv")+"</li>"
     txt(1435) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pr_spatialstddev_mam.indmemdiff.png","Bias")+"</li>"
     txt(1437) = "</ul></div></td>"
  else
     txt(1437) = "MAM</td>"
  end if

  txt(1440) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"pr_spatialstddev_jja.indmem.png")) then
     txt(1441) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#pr_stddev_jja"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"pr_stddev_jja"+quote+">JJA</a>" 
     txt(1442) = "<div class="+quote+"collapse"+quote+" id="+quote+"pr_stddev_jja"+quote+">"
     txt(1443) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1444) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pr_spatialstddev_jja.indmem.png","Indiv")+"</li>"
     txt(1445) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pr_spatialstddev_jja.indmemdiff.png","Bias")+"</li>"
     txt(1447) = "</ul></div></td>"
  else
     txt(1447) = "JJA</td>"
  end if

  txt(1450) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"pr_spatialstddev_jas.indmem.png")) then
     txt(1451) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#pr_stddev_jas"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"pr_stddev_jas"+quote+">JAS</a>" 
     txt(1452) = "<div class="+quote+"collapse"+quote+" id="+quote+"pr_stddev_jas"+quote+">"
     txt(1453) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1454) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pr_spatialstddev_jas.indmem.png","Indiv")+"</li>"
     txt(1455) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pr_spatialstddev_jas.indmemdiff.png","Bias")+"</li>"
     txt(1457) = "</ul></div></td>"
  else
     txt(1457) = "JAS</td>"
  end if

  txt(1460) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"pr_spatialstddev_son.indmem.png")) then
     txt(1461) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#pr_stddev_son"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"pr_stddev_son"+quote+">SON</a>" 
     txt(1462) = "<div class="+quote+"collapse"+quote+" id="+quote+"pr_stddev_son"+quote+">"
     txt(1463) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1464) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pr_spatialstddev_son.indmem.png","Indiv")+"</li>"
     txt(1465) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pr_spatialstddev_son.indmemdiff.png","Bias")+"</li>"
     txt(1467) = "</ul></div></td>"
  else
     txt(1467) = "SON</td>"
  end if

  txt(1470) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"pr_spatialstddev_ann.indmem.png")) then
     txt(1471) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#pr_stddev_ann"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"pr_stddev_ann"+quote+">ANN</a>" 
     txt(1472) = "<div class="+quote+"collapse"+quote+" id="+quote+"pr_stddev_ann"+quote+">"
     txt(1473) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1474) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pr_spatialstddev_ann.indmem.png","Indiv")+"</li>"
     txt(1475) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pr_spatialstddev_ann.indmemdiff.png","Bias")+"</li>"
     txt(1477) = "</ul></div></td>"
  else
     txt(1477) = "ANN</td>"
  end if
  txt(1478) = "</tr>"

  txt(1508) = "<tr class="+quote+"d-flex"+quote+">"
  txt(1509) = "<td class="+quote+"col"+quote+"><b>SICONC NH</b></td>"

  txt(1510) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"siconc_nh_spatialstddev_djf.indmem.png")) then
     txt(1511) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#siconc_nh_stddev_djf"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"siconc_nh_stddev_djf"+quote+">DJF</a>" 
     txt(1512) = "<div class="+quote+"collapse"+quote+" id="+quote+"siconc_nh_stddev_djf"+quote+">"
     txt(1513) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1514) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_nh_spatialstddev_djf.indmem.png","Indiv")+"</li>"
     txt(1515) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_nh_spatialstddev_djf.indmemdiff.png","Bias")+"</li>"
     txt(1517) = "</ul></div></td>"
  else
     txt(1517) = "DJF</td>"
  end if

  txt(1520) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"siconc_nh_spatialstddev_jfm.indmem.png")) then
     txt(1521) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#siconc_nh_stddev_jfm"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"siconc_nh_stddev_jfm"+quote+">JFM</a>" 
     txt(1522) = "<div class="+quote+"collapse"+quote+" id="+quote+"siconc_nh_stddev_jfm"+quote+">"
     txt(1523) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1524) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_nh_spatialstddev_jfm.indmem.png","Indiv")+"</li>"
     txt(1525) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_nh_spatialstddev_jfm.indmemdiff.png","Bias")+"</li>"
     txt(1527) = "</ul></div></td>"
  else
     txt(1527) = "JFM</td>"
  end if

  txt(1530) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"siconc_nh_spatialstddev_mam.indmem.png")) then
     txt(1531) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#siconc_nh_stddev_mam"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"siconc_nh_stddev_mam"+quote+">MAM</a>" 
     txt(1532) = "<div class="+quote+"collapse"+quote+" id="+quote+"siconc_nh_stddev_mam"+quote+">"
     txt(1533) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1534) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_nh_spatialstddev_mam.indmem.png","Indiv")+"</li>"
     txt(1535) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_nh_spatialstddev_mam.indmemdiff.png","Bias")+"</li>"
     txt(1537) = "</ul></div></td>"
  else
     txt(1537) = "MAM</td>"
  end if

  txt(1540) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"siconc_nh_spatialstddev_jja.indmem.png")) then
     txt(1541) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#siconc_nh_stddev_jja"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"siconc_nh_stddev_jja"+quote+">JJA</a>" 
     txt(1542) = "<div class="+quote+"collapse"+quote+" id="+quote+"siconc_nh_stddev_jja"+quote+">"
     txt(1543) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1544) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_nh_spatialstddev_jja.indmem.png","Indiv")+"</li>"
     txt(1545) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_nh_spatialstddev_jja.indmemdiff.png","Bias")+"</li>"
     txt(1547) = "</ul></div></td>"
  else
     txt(1547) = "JJA</td>"
  end if

  txt(1550) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"siconc_nh_spatialstddev_jas.indmem.png")) then
     txt(1551) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#siconc_nh_stddev_jas"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"siconc_nh_stddev_jas"+quote+">JAS</a>" 
     txt(1552) = "<div class="+quote+"collapse"+quote+" id="+quote+"siconc_nh_stddev_jas"+quote+">"
     txt(1553) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1554) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_nh_spatialstddev_jas.indmem.png","Indiv")+"</li>"
     txt(1555) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_nh_spatialstddev_jas.indmemdiff.png","Bias")+"</li>"
     txt(1557) = "</ul></div></td>"
  else
     txt(1557) = "JAS</td>"
  end if

  txt(1560) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"siconc_nh_spatialstddev_son.indmem.png")) then
     txt(1561) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#siconc_nh_stddev_son"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"siconc_nh_stddev_son"+quote+">SON</a>" 
     txt(1562) = "<div class="+quote+"collapse"+quote+" id="+quote+"siconc_nh_stddev_son"+quote+">"
     txt(1563) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1564) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_nh_spatialstddev_son.indmem.png","Indiv")+"</li>"
     txt(1565) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_nh_spatialstddev_son.indmemdiff.png","Bias")+"</li>"
     txt(1567) = "</ul></div></td>"
  else
     txt(1567) = "SON</td>"
  end if

  txt(1570) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"siconc_nh_spatialstddev_ann.indmem.png")) then
     txt(1571) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#siconc_nh_stddev_ann"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"siconc_nh_stddev_ann"+quote+">ANN</a>" 
     txt(1572) = "<div class="+quote+"collapse"+quote+" id="+quote+"siconc_nh_stddev_ann"+quote+">"
     txt(1573) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1574) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_nh_spatialstddev_ann.indmem.png","Indiv")+"</li>"
     txt(1575) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_nh_spatialstddev_ann.indmemdiff.png","Bias")+"</li>"
     txt(1577) = "</ul></div></td>"
  else
     txt(1577) = "ANN</td>"
  end if
  txt(1578) = "</tr>"

  txt(1604) = "<tr class="+quote+"d-flex"+quote+">"
  txt(1605) = "<td class="+quote+"col"+quote+"><b>SICONC SH</b></td>"

  txt(1610) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"siconc_sh_spatialstddev_djf.indmem.png")) then
     txt(1611) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#siconc_sh_stddev_djf"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"siconc_sh_stddev_djf"+quote+">DJF</a>" 
     txt(1612) = "<div class="+quote+"collapse"+quote+" id="+quote+"siconc_sh_stddev_djf"+quote+">"
     txt(1613) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1614) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_sh_spatialstddev_djf.indmem.png","Indiv")+"</li>"
     txt(1615) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_sh_spatialstddev_djf.indmemdiff.png","Bias")+"</li>"
     txt(1617) = "</ul></div></td>"
  else
     txt(1617) = "DJF</td>"
  end if

  txt(1620) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"siconc_sh_spatialstddev_jfm.indmem.png")) then
     txt(1621) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#siconc_sh_stddev_jfm"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"siconc_sh_stddev_jfm"+quote+">JFM</a>" 
     txt(1622) = "<div class="+quote+"collapse"+quote+" id="+quote+"siconc_sh_stddev_jfm"+quote+">"
     txt(1623) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1624) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_sh_spatialstddev_jfm.indmem.png","Indiv")+"</li>"
     txt(1625) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_sh_spatialstddev_jfm.indmemdiff.png","Bias")+"</li>"
     txt(1627) = "</ul></div></td>"
  else
     txt(1627) = "JFM</td>"
  end if

  txt(1630) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"siconc_sh_spatialstddev_mam.indmem.png")) then
     txt(1631) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#siconc_sh_stddev_mam"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"siconc_sh_stddev_mam"+quote+">MAM</a>" 
     txt(1632) = "<div class="+quote+"collapse"+quote+" id="+quote+"siconc_sh_stddev_mam"+quote+">"
     txt(1633) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1634) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_sh_spatialstddev_mam.indmem.png","Indiv")+"</li>"
     txt(1635) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_sh_spatialstddev_mam.indmemdiff.png","Bias")+"</li>"
     txt(1637) = "</ul></div></td>"
  else
     txt(1637) = "MAM</td>"
  end if

  txt(1640) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"siconc_sh_spatialstddev_jja.indmem.png")) then
     txt(1641) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#siconc_sh_stddev_jja"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"siconc_sh_stddev_jja"+quote+">JJA</a>" 
     txt(1642) = "<div class="+quote+"collapse"+quote+" id="+quote+"siconc_sh_stddev_jja"+quote+">"
     txt(1643) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1644) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_sh_spatialstddev_jja.indmem.png","Indiv")+"</li>"
     txt(1645) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_sh_spatialstddev_jja.indmemdiff.png","Bias")+"</li>"
     txt(1647) = "</ul></div></td>"
  else
     txt(1647) = "JJA</td>"
  end if

  txt(1650) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"siconc_sh_spatialstddev_jas.indmem.png")) then
     txt(1651) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#siconc_sh_stddev_jas"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"siconc_sh_stddev_jas"+quote+">JAS</a>" 
     txt(1652) = "<div class="+quote+"collapse"+quote+" id="+quote+"siconc_sh_stddev_jas"+quote+">"
     txt(1653) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1654) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_sh_spatialstddev_jas.indmem.png","Indiv")+"</li>"
     txt(1655) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_sh_spatialstddev_jas.indmemdiff.png","Bias")+"</li>"
     txt(1657) = "</ul></div></td>"
  else
     txt(1657) = "JAS</td>"
  end if

  txt(1660) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"siconc_sh_spatialstddev_son.indmem.png")) then
     txt(1661) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#siconc_sh_stddev_son"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"siconc_sh_stddev_son"+quote+">SON</a>" 
     txt(1662) = "<div class="+quote+"collapse"+quote+" id="+quote+"siconc_sh_stddev_son"+quote+">"
     txt(1663) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1664) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_sh_spatialstddev_son.indmem.png","Indiv")+"</li>"
     txt(1665) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_sh_spatialstddev_son.indmemdiff.png","Bias")+"</li>"
     txt(1667) = "</ul></div></td>"
  else
     txt(1667) = "SON</td>"
  end if

  txt(1670) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"siconc_sh_spatialstddev_ann.indmem.png")) then
     txt(1671) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#siconc_sh_stddev_ann"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"siconc_sh_stddev_ann"+quote+">ANN</a>" 
     txt(1672) = "<div class="+quote+"collapse"+quote+" id="+quote+"siconc_sh_stddev_ann"+quote+">"
     txt(1673) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1674) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_sh_spatialstddev_ann.indmem.png","Indiv")+"</li>"
     txt(1675) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_sh_spatialstddev_ann.indmemdiff.png","Bias")+"</li>"
     txt(1677) = "</ul></div></td>"
  else
     txt(1677) = "ANN</td>"
  end if
  txt(1678) = "</tr>"


  txt(1704) = "<tr class="+quote+"d-flex"+quote+">"
  txt(1705) = "<td class="+quote+"col"+quote+"><b>ZOS</b></td>"

  txt(1710) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"zos_spatialstddev_djf.indmem.png")) then
     txt(1711) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#zos_stddev_djf"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"zos_stddev_djf"+quote+">DJF</a>" 
     txt(1712) = "<div class="+quote+"collapse"+quote+" id="+quote+"zos_stddev_djf"+quote+">"
     txt(1713) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1714) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"zos_spatialstddev_djf.indmem.png","Indiv")+"</li>"
     txt(1715) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"zos_spatialstddev_djf.indmemdiff.png","Bias")+"</li>"
     txt(1717) = "</ul></div></td>"
  else
     txt(1717) = "DJF</td>"
  end if

  txt(1720) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"zos_spatialstddev_jfm.indmem.png")) then
     txt(1721) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#zos_stddev_jfm"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"zos_stddev_jfm"+quote+">JFM</a>" 
     txt(1722) = "<div class="+quote+"collapse"+quote+" id="+quote+"zos_stddev_jfm"+quote+">"
     txt(1723) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1724) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"zos_spatialstddev_jfm.indmem.png","Indiv")+"</li>"
     txt(1725) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"zos_spatialstddev_jfm.indmemdiff.png","Bias")+"</li>"
     txt(1727) = "</ul></div></td>"
  else
     txt(1727) = "JFM</td>"
  end if

  txt(1730) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"zos_spatialstddev_mam.indmem.png")) then
     txt(1731) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#zos_stddev_mam"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"zos_stddev_mam"+quote+">MAM</a>" 
     txt(1732) = "<div class="+quote+"collapse"+quote+" id="+quote+"zos_stddev_mam"+quote+">"
     txt(1733) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1734) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"zos_spatialstddev_mam.indmem.png","Indiv")+"</li>"
     txt(1735) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"zos_spatialstddev_mam.indmemdiff.png","Bias")+"</li>"
     txt(1737) = "</ul></div></td>"
  else
     txt(1737) = "MAM</td>"
  end if

  txt(1740) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"zos_spatialstddev_jja.indmem.png")) then
     txt(1741) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#zos_stddev_jja"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"zos_stddev_jja"+quote+">JJA</a>" 
     txt(1742) = "<div class="+quote+"collapse"+quote+" id="+quote+"zos_stddev_jja"+quote+">"
     txt(1743) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1744) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"zos_spatialstddev_jja.indmem.png","Indiv")+"</li>"
     txt(1745) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"zos_spatialstddev_jja.indmemdiff.png","Bias")+"</li>"
     txt(1747) = "</ul></div></td>"
  else
     txt(1747) = "JJA</td>"
  end if

  txt(1750) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"zos_spatialstddev_jas.indmem.png")) then
     txt(1751) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#zos_stddev_jas"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"zos_stddev_jas"+quote+">JAS</a>" 
     txt(1752) = "<div class="+quote+"collapse"+quote+" id="+quote+"zos_stddev_jas"+quote+">"
     txt(1753) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1754) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"zos_spatialstddev_jas.indmem.png","Indiv")+"</li>"
     txt(1755) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"zos_spatialstddev_jas.indmemdiff.png","Bias")+"</li>"
     txt(1757) = "</ul></div></td>"
  else
     txt(1757) = "JAS</td>"
  end if

  txt(1760) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"zos_spatialstddev_son.indmem.png")) then
     txt(1761) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#zos_stddev_son"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"zos_stddev_son"+quote+">SON</a>" 
     txt(1762) = "<div class="+quote+"collapse"+quote+" id="+quote+"zos_stddev_son"+quote+">"
     txt(1763) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1764) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"zos_spatialstddev_son.indmem.png","Indiv")+"</li>"
     txt(1765) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"zos_spatialstddev_son.indmemdiff.png","Bias")+"</li>"
     txt(1767) = "</ul></div></td>"
  else
     txt(1767) = "SON</td>"
  end if

  txt(1770) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"zos_spatialstddev_ann.indmem.png")) then
     txt(1771) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#zos_stddev_ann"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"zos_stddev_ann"+quote+">ANN</a>" 
     txt(1772) = "<div class="+quote+"collapse"+quote+" id="+quote+"zos_stddev_ann"+quote+">"
     txt(1773) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(1774) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"zos_spatialstddev_ann.indmem.png","Indiv")+"</li>"
     txt(1775) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"zos_spatialstddev_ann.indmemdiff.png","Bias")+"</li>"
     txt(1777) = "</ul></div></td>"
  else
     txt(1777) = "ANN</td>"
  end if
  txt(1778) = "</tr>"
  txt(1780) = "</table></div></div>"


  txt(2100) = "<div class="+quote+"row"+quote+">"
  txt(2101) = "<div class="+quote+"col"+quote+">"
  txt(2102) = "<table class="+quote+"table table-striped table-bordered"+quote+">"
  txt(2103) = "<h3 class="+quote+"display-6"+quote+">Linear Trends</h3>"
  txt(2104) = "<tr class="+quote+"d-flex"+quote+">"
  txt(2105) = "<td class="+quote+"col"+quote+"><b>SST</b></td>"

  txt(2110) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"sst_trends_djf.indmem.png")) then
     txt(2111) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#sst_trends_djf"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"sst_trends_djf"+quote+">DJF</a>" 
     txt(2112) = "<div class="+quote+"collapse"+quote+" id="+quote+"sst_trends_djf"+quote+">"
     txt(2113) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2114) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sst_trends_djf.indmem.png","Indiv")+"</li>"
     txt(2115) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sst_trends_djf.indmemdiff.png","Bias")+"</li>"
     txt(2117) = "</ul></div></td>"
  else
     txt(2117) = "DJF</td>"
  end if

  txt(2120) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"sst_trends_jfm.indmem.png")) then
     txt(2121) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#sst_trends_jfm"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"sst_trends_jfm"+quote+">JFM</a>" 
     txt(2122) = "<div class="+quote+"collapse"+quote+" id="+quote+"sst_trends_jfm"+quote+">"
     txt(2123) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2124) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sst_trends_jfm.indmem.png","Indiv")+"</li>"
     txt(2125) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sst_trends_jfm.indmemdiff.png","Bias")+"</li>"
     txt(2127) = "</ul></div></td>"
  else
     txt(2127) = "JFM</td>"
  end if

  txt(2130) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"sst_trends_mam.indmem.png")) then
     txt(2131) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#sst_trends_mam"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"sst_trends_mam"+quote+">MAM</a>" 
     txt(2132) = "<div class="+quote+"collapse"+quote+" id="+quote+"sst_trends_mam"+quote+">"
     txt(2133) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2134) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sst_trends_mam.indmem.png","Indiv")+"</li>"
     txt(2135) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sst_trends_mam.indmemdiff.png","Bias")+"</li>"
     txt(2137) = "</ul></div></td>"
  else
     txt(2137) = "MAM</td>"
  end if

  txt(2140) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"sst_trends_jja.indmem.png")) then
     txt(2141) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#sst_trends_jja"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"sst_trends_jja"+quote+">JJA</a>" 
     txt(2142) = "<div class="+quote+"collapse"+quote+" id="+quote+"sst_trends_jja"+quote+">"
     txt(2143) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2144) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sst_trends_jja.indmem.png","Indiv")+"</li>"
     txt(2145) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sst_trends_jja.indmemdiff.png","Bias")+"</li>"
     txt(2147) = "</ul></div></td>"
  else
     txt(2147) = "JJA</td>"
  end if

  txt(2150) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"sst_trends_jas.indmem.png")) then
     txt(2151) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#sst_trends_jas"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"sst_trends_jas"+quote+">JAS</a>" 
     txt(2152) = "<div class="+quote+"collapse"+quote+" id="+quote+"sst_trends_jas"+quote+">"
     txt(2153) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2154) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sst_trends_jas.indmem.png","Indiv")+"</li>"
     txt(2155) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sst_trends_jas.indmemdiff.png","Bias")+"</li>"
     txt(2157) = "</ul></div></td>"
  else
     txt(2157) = "JAS</td>"
  end if

  txt(2160) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"sst_trends_son.indmem.png")) then
     txt(2161) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#sst_trends_son"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"sst_trends_son"+quote+">SON</a>" 
     txt(2162) = "<div class="+quote+"collapse"+quote+" id="+quote+"sst_trends_son"+quote+">"
     txt(2163) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2164) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sst_trends_son.indmem.png","Indiv")+"</li>"
     txt(2165) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sst_trends_son.indmemdiff.png","Bias")+"</li>"
     txt(2167) = "</ul></div></td>"
  else
     txt(2167) = "SON</td>"
  end if

  txt(2170) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"sst_trends_ann.indmem.png")) then
     txt(2171) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#sst_trends_ann"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"sst_trends_ann"+quote+">ANN</a>" 
     txt(2172) = "<div class="+quote+"collapse"+quote+" id="+quote+"sst_trends_ann"+quote+">"
     txt(2173) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2174) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sst_trends_ann.indmem.png","Indiv")+"</li>"
     txt(2175) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sst_trends_ann.indmemdiff.png","Bias")+"</li>"
     txt(2177) = "</ul></div></td>"
  else
     txt(2177) = "ANN</td>"
  end if
  txt(2178) = "</tr>"

  txt(2204) = "<tr class="+quote+"d-flex"+quote+">"
  txt(2205) = "<td class="+quote+"col"+quote+"><b>TAS</b></td>"

  txt(2210) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"tas_trends_djf.indmem.png")) then
     txt(2211) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#tas_trends_djf"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"tas_trends_djf"+quote+">DJF</a>" 
     txt(2212) = "<div class="+quote+"collapse"+quote+" id="+quote+"tas_trends_djf"+quote+">"
     txt(2213) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2214) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"tas_trends_djf.indmem.png","Indiv")+"</li>"
     txt(2215) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"tas_trends_djf.indmemdiff.png","Bias")+"</li>"
     txt(2217) = "</ul></div></td>"
  else
     txt(2217) = "DJF</td>"
  end if

  txt(2220) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"tas_trends_jfm.indmem.png")) then
     txt(2221) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#tas_trends_jfm"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"tas_trends_jfm"+quote+">JFM</a>" 
     txt(2222) = "<div class="+quote+"collapse"+quote+" id="+quote+"tas_trends_jfm"+quote+">"
     txt(2223) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2224) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"tas_trends_jfm.indmem.png","Indiv")+"</li>"
     txt(2225) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"tas_trends_jfm.indmemdiff.png","Bias")+"</li>"
     txt(2227) = "</ul></div></td>"
  else
     txt(2227) = "JFM</td>"
  end if

  txt(2230) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"tas_trends_mam.indmem.png")) then
     txt(2231) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#tas_trends_mam"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"tas_trends_mam"+quote+">MAM</a>" 
     txt(2232) = "<div class="+quote+"collapse"+quote+" id="+quote+"tas_trends_mam"+quote+">"
     txt(2233) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2234) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"tas_trends_mam.indmem.png","Indiv")+"</li>"
     txt(2235) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"tas_trends_mam.indmemdiff.png","Bias")+"</li>"
     txt(2237) = "</ul></div></td>"
  else
     txt(2237) = "MAM</td>"
  end if

  txt(2240) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"tas_trends_jja.indmem.png")) then
     txt(2241) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#tas_trends_jja"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"tas_trends_jja"+quote+">JJA</a>" 
     txt(2242) = "<div class="+quote+"collapse"+quote+" id="+quote+"tas_trends_jja"+quote+">"
     txt(2243) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2244) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"tas_trends_jja.indmem.png","Indiv")+"</li>"
     txt(2245) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"tas_trends_jja.indmemdiff.png","Bias")+"</li>"
     txt(2247) = "</ul></div></td>"
  else
     txt(2247) = "JJA</td>"
  end if

  txt(2250) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"tas_trends_jas.indmem.png")) then
     txt(2251) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#tas_trends_jas"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"tas_trends_jas"+quote+">JAS</a>" 
     txt(2252) = "<div class="+quote+"collapse"+quote+" id="+quote+"tas_trends_jas"+quote+">"
     txt(2253) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2254) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"tas_trends_jas.indmem.png","Indiv")+"</li>"
     txt(2255) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"tas_trends_jas.indmemdiff.png","Bias")+"</li>"
     txt(2257) = "</ul></div></td>"
  else
     txt(2257) = "JAS</td>"
  end if

  txt(2260) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"tas_trends_son.indmem.png")) then
     txt(2261) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#tas_trends_son"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"tas_trends_son"+quote+">SON</a>" 
     txt(2262) = "<div class="+quote+"collapse"+quote+" id="+quote+"tas_trends_son"+quote+">"
     txt(2263) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2264) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"tas_trends_son.indmem.png","Indiv")+"</li>"
     txt(2265) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"tas_trends_son.indmemdiff.png","Bias")+"</li>"
     txt(2267) = "</ul></div></td>"
  else
     txt(2267) = "SON</td>"
  end if

  txt(2270) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"tas_trends_ann.indmem.png")) then
     txt(2271) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#tas_trends_ann"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"tas_trends_ann"+quote+">ANN</a>" 
     txt(2272) = "<div class="+quote+"collapse"+quote+" id="+quote+"tas_trends_ann"+quote+">"
     txt(2273) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2274) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"tas_trends_ann.indmem.png","Indiv")+"</li>"
     txt(2275) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"tas_trends_ann.indmemdiff.png","Bias")+"</li>"
     txt(2277) = "</ul></div></td>"
  else
     txt(2277) = "ANN</td>"
  end if
  txt(2278) = "</tr>"

  txt(2304) = "<tr class="+quote+"d-flex"+quote+">"
  txt(2305) = "<td class="+quote+"col"+quote+"><b>PSL</b></td>"

  txt(2310) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"psl_trends_djf.indmem.png")) then
     txt(2311) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#psl_trends_djf"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"psl_trends_djf"+quote+">DJF</a>" 
     txt(2312) = "<div class="+quote+"collapse"+quote+" id="+quote+"psl_trends_djf"+quote+">"
     txt(2313) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2314) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psl_trends_djf.indmem.png","Indiv")+"</li>"
     txt(2315) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psl_trends_djf.indmemdiff.png","Bias")+"</li>"
     txt(2317) = "</ul></div></td>"
  else
     txt(2317) = "DJF</td>"
  end if

  txt(2320) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"psl_trends_jfm.indmem.png")) then
     txt(2321) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#psl_trends_jfm"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"psl_trends_jfm"+quote+">JFM</a>" 
     txt(2322) = "<div class="+quote+"collapse"+quote+" id="+quote+"psl_trends_jfm"+quote+">"
     txt(2323) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2324) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psl_trends_jfm.indmem.png","Indiv")+"</li>"
     txt(2325) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psl_trends_jfm.indmemdiff.png","Bias")+"</li>"
     txt(2327) = "</ul></div></td>"
  else
     txt(2327) = "JFM</td>"
  end if

  txt(2330) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"psl_trends_mam.indmem.png")) then
     txt(2331) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#psl_trends_mam"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"psl_trends_mam"+quote+">MAM</a>" 
     txt(2332) = "<div class="+quote+"collapse"+quote+" id="+quote+"psl_trends_mam"+quote+">"
     txt(2333) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2334) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psl_trends_mam.indmem.png","Indiv")+"</li>"
     txt(2335) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psl_trends_mam.indmemdiff.png","Bias")+"</li>"
     txt(2337) = "</ul></div></td>"
  else
     txt(2337) = "MAM</td>"
  end if

  txt(2340) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"psl_trends_jja.indmem.png")) then
     txt(2341) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#psl_trends_jja"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"psl_trends_jja"+quote+">JJA</a>" 
     txt(2342) = "<div class="+quote+"collapse"+quote+" id="+quote+"psl_trends_jja"+quote+">"
     txt(2343) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2344) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psl_trends_jja.indmem.png","Indiv")+"</li>"
     txt(2345) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psl_trends_jja.indmemdiff.png","Bias")+"</li>"
     txt(2347) = "</ul></div></td>"
  else
     txt(2347) = "JJA</td>"
  end if

  txt(2350) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"psl_trends_jas.indmem.png")) then
     txt(2351) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#psl_trends_jas"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"psl_trends_jas"+quote+">JAS</a>" 
     txt(2352) = "<div class="+quote+"collapse"+quote+" id="+quote+"psl_trends_jas"+quote+">"
     txt(2353) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2354) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psl_trends_jas.indmem.png","Indiv")+"</li>"
     txt(2355) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psl_trends_jas.indmemdiff.png","Bias")+"</li>"
     txt(2357) = "</ul></div></td>"
  else
     txt(2357) = "JAS</td>"
  end if

  txt(2360) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"psl_trends_son.indmem.png")) then
     txt(2361) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#psl_trends_son"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"psl_trends_son"+quote+">SON</a>" 
     txt(2362) = "<div class="+quote+"collapse"+quote+" id="+quote+"psl_trends_son"+quote+">"
     txt(2363) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2364) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psl_trends_son.indmem.png","Indiv")+"</li>"
     txt(2365) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psl_trends_son.indmemdiff.png","Bias")+"</li>"
     txt(2367) = "</ul></div></td>"
  else
     txt(2367) = "SON</td>"
  end if

  txt(2370) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"psl_trends_ann.indmem.png")) then
     txt(2371) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#psl_trends_ann"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"psl_trends_ann"+quote+">ANN</a>" 
     txt(2372) = "<div class="+quote+"collapse"+quote+" id="+quote+"psl_trends_ann"+quote+">"
     txt(2373) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2374) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psl_trends_ann.indmem.png","Indiv")+"</li>"
     txt(2375) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psl_trends_ann.indmemdiff.png","Bias")+"</li>"
     txt(2377) = "</ul></div></td>"
  else
     txt(2377) = "ANN</td>"
  end if
  txt(2378) = "</tr>"

  txt(2404) = "<tr class="+quote+"d-flex"+quote+">"
  txt(2405) = "<td class="+quote+"col"+quote+"><b>PR</b></td>"

  txt(2410) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"pr_trends_djf.indmem.png")) then
     txt(2411) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#pr_trends_djf"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"pr_trends_djf"+quote+">DJF</a>" 
     txt(2412) = "<div class="+quote+"collapse"+quote+" id="+quote+"pr_trends_djf"+quote+">"
     txt(2413) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2414) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pr_trends_djf.indmem.png","Indiv")+"</li>"
     txt(2415) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pr_trends_djf.indmemdiff.png","Bias")+"</li>"
     txt(2417) = "</ul></div></td>"
  else
     txt(2417) = "DJF</td>"
  end if

  txt(2420) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"pr_trends_jfm.indmem.png")) then
     txt(2421) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#pr_trends_jfm"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"pr_trends_jfm"+quote+">JFM</a>" 
     txt(2422) = "<div class="+quote+"collapse"+quote+" id="+quote+"pr_trends_jfm"+quote+">"
     txt(2423) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2424) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pr_trends_jfm.indmem.png","Indiv")+"</li>"
     txt(2425) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pr_trends_jfm.indmemdiff.png","Bias")+"</li>"
     txt(2427) = "</ul></div></td>"
  else
     txt(2427) = "JFM</td>"
  end if

  txt(2430) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"pr_trends_mam.indmem.png")) then
     txt(2431) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#pr_trends_mam"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"pr_trends_mam"+quote+">MAM</a>" 
     txt(2432) = "<div class="+quote+"collapse"+quote+" id="+quote+"pr_trends_mam"+quote+">"
     txt(2433) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2434) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pr_trends_mam.indmem.png","Indiv")+"</li>"
     txt(2435) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pr_trends_mam.indmemdiff.png","Bias")+"</li>"
     txt(2437) = "</ul></div></td>"
  else
     txt(2437) = "MAM</td>"
  end if

  txt(2440) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"pr_trends_jja.indmem.png")) then
     txt(2441) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#pr_trends_jja"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"pr_trends_jja"+quote+">JJA</a>" 
     txt(2442) = "<div class="+quote+"collapse"+quote+" id="+quote+"pr_trends_jja"+quote+">"
     txt(2443) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2444) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pr_trends_jja.indmem.png","Indiv")+"</li>"
     txt(2445) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pr_trends_jja.indmemdiff.png","Bias")+"</li>"
     txt(2447) = "</ul></div></td>"
  else
     txt(2447) = "JJA</td>"
  end if

  txt(2450) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"pr_trends_jas.indmem.png")) then
     txt(2451) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#pr_trends_jas"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"pr_trends_jas"+quote+">JAS</a>" 
     txt(2452) = "<div class="+quote+"collapse"+quote+" id="+quote+"pr_trends_jas"+quote+">"
     txt(2453) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2454) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pr_trends_jas.indmem.png","Indiv")+"</li>"
     txt(2455) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pr_trends_jas.indmemdiff.png","Bias")+"</li>"
     txt(2457) = "</ul></div></td>"
  else
     txt(2457) = "JAS</td>"
  end if



  txt(2460) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"pr_trends_son.indmem.png")) then
     txt(2461) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#pr_trends_son"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"pr_trends_son"+quote+">SON</a>" 
     txt(2462) = "<div class="+quote+"collapse"+quote+" id="+quote+"pr_trends_son"+quote+">"
     txt(2463) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2464) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pr_trends_son.indmem.png","Indiv")+"</li>"
     txt(2465) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pr_trends_son.indmemdiff.png","Bias")+"</li>"
     txt(2467) = "</ul></div></td>"
  else
     txt(2467) = "SON</td>"
  end if

  txt(2470) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"pr_trends_ann.indmem.png")) then
     txt(2471) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#pr_trends_ann"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"pr_trends_ann"+quote+">ANN</a>" 
     txt(2472) = "<div class="+quote+"collapse"+quote+" id="+quote+"pr_trends_ann"+quote+">"
     txt(2473) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2474) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pr_trends_ann.indmem.png","Indiv")+"</li>"
     txt(2475) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pr_trends_ann.indmemdiff.png","Bias")+"</li>"
     txt(2477) = "</ul></div></td>"
  else
     txt(2477) = "ANN</td>"
  end if
  txt(2478) = "</tr>"


  txt(2607) = "<tr class="+quote+"d-flex"+quote+">"
  txt(2608) = "<td class="+quote+"col"+quote+"><b>SICONC NH</b></td>"

  txt(2610) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"siconc_nh_trends_djf.indmem.png")) then
     txt(2611) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#siconc_nh_trends_djf"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"siconc_nh_trends_djf"+quote+">DJF</a>" 
     txt(2612) = "<div class="+quote+"collapse"+quote+" id="+quote+"siconc_nh_trends_djf"+quote+">"
     txt(2613) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2614) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_nh_trends_djf.indmem.png","Indiv")+"</li>"
     txt(2615) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_nh_trends_djf.indmemdiff.png","Bias")+"</li>"
     txt(2617) = "</ul></div></td>"
  else
     txt(2617) = "DJF</td>"
  end if

  txt(2620) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"siconc_nh_trends_jfm.indmem.png")) then
     txt(2621) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#siconc_nh_trends_jfm"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"siconc_nh_trends_jfm"+quote+">JFM</a>" 
     txt(2622) = "<div class="+quote+"collapse"+quote+" id="+quote+"siconc_nh_trends_jfm"+quote+">"
     txt(2623) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2624) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_nh_trends_jfm.indmem.png","Indiv")+"</li>"
     txt(2625) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_nh_trends_jfm.indmemdiff.png","Bias")+"</li>"
     txt(2627) = "</ul></div></td>"
  else
     txt(2627) = "JFM</td>"
  end if

  txt(2630) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"siconc_nh_trends_mam.indmem.png")) then
     txt(2631) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#siconc_nh_trends_mam"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"siconc_nh_trends_mam"+quote+">MAM</a>" 
     txt(2632) = "<div class="+quote+"collapse"+quote+" id="+quote+"siconc_nh_trends_mam"+quote+">"
     txt(2633) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2634) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_nh_trends_mam.indmem.png","Indiv")+"</li>"
     txt(2635) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_nh_trends_mam.indmemdiff.png","Bias")+"</li>"
     txt(2637) = "</ul></div></td>"
  else
     txt(2637) = "MAM</td>"
  end if

  txt(2640) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"siconc_nh_trends_jja.indmem.png")) then
     txt(2641) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#siconc_nh_trends_jja"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"siconc_nh_trends_jja"+quote+">JJA</a>" 
     txt(2642) = "<div class="+quote+"collapse"+quote+" id="+quote+"siconc_nh_trends_jja"+quote+">"
     txt(2643) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2644) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_nh_trends_jja.indmem.png","Indiv")+"</li>"
     txt(2645) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_nh_trends_jja.indmemdiff.png","Bias")+"</li>"
     txt(2647) = "</ul></div></td>"
  else
     txt(2647) = "JJA</td>"
  end if

  txt(2650) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"siconc_nh_trends_jas.indmem.png")) then
     txt(2651) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#siconc_nh_trends_jas"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"siconc_nh_trends_jas"+quote+">JAS</a>" 
     txt(2652) = "<div class="+quote+"collapse"+quote+" id="+quote+"siconc_nh_trends_jas"+quote+">"
     txt(2653) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2654) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_nh_trends_jas.indmem.png","Indiv")+"</li>"
     txt(2655) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_nh_trends_jas.indmemdiff.png","Bias")+"</li>"
     txt(2657) = "</ul></div></td>"
  else
     txt(2657) = "JAS</td>"
  end if

  txt(2660) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"siconc_nh_trends_son.indmem.png")) then
     txt(2661) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#siconc_nh_trends_son"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"siconc_nh_trends_son"+quote+">SON</a>" 
     txt(2662) = "<div class="+quote+"collapse"+quote+" id="+quote+"siconc_nh_trends_son"+quote+">"
     txt(2663) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2664) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_nh_trends_son.indmem.png","Indiv")+"</li>"
     txt(2665) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_nh_trends_son.indmemdiff.png","Bias")+"</li>"
     txt(2667) = "</ul></div></td>"
  else
     txt(2667) = "SON</td>"
  end if

  txt(2670) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"siconc_nh_trends_ann.indmem.png")) then
     txt(2671) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#siconc_nh_trends_ann"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"siconc_nh_trends_ann"+quote+">ANN</a>" 
     txt(2672) = "<div class="+quote+"collapse"+quote+" id="+quote+"siconc_nh_trends_ann"+quote+">"
     txt(2673) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2674) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_nh_trends_ann.indmem.png","Indiv")+"</li>"
     txt(2675) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_nh_trends_ann.indmemdiff.png","Bias")+"</li>"
     txt(2677) = "</ul></div></td>"
  else
     txt(2677) = "ANN</td>"
  end if
  txt(2678) = "</tr>"

  txt(2704) = "<tr class="+quote+"d-flex"+quote+">"
  txt(2705) = "<td class="+quote+"col"+quote+"><b>SICONC SH</b></td>"

  txt(2710) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"siconc_sh_trends_djf.indmem.png")) then
     txt(2711) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#siconc_sh_trends_djf"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"siconc_sh_trends_djf"+quote+">DJF</a>" 
     txt(2712) = "<div class="+quote+"collapse"+quote+" id="+quote+"siconc_sh_trends_djf"+quote+">"
     txt(2713) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2714) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_sh_trends_djf.indmem.png","Indiv")+"</li>"
     txt(2715) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_sh_trends_djf.indmemdiff.png","Bias")+"</li>"
     txt(2717) = "</ul></div></td>"
  else
     txt(2717) = "DJF</td>"
  end if

  txt(2720) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"siconc_sh_trends_jfm.indmem.png")) then
     txt(2721) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#siconc_sh_trends_jfm"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"siconc_sh_trends_jfm"+quote+">JFM</a>" 
     txt(2722) = "<div class="+quote+"collapse"+quote+" id="+quote+"siconc_sh_trends_jfm"+quote+">"
     txt(2723) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2724) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_sh_trends_jfm.indmem.png","Indiv")+"</li>"
     txt(2725) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_sh_trends_jfm.indmemdiff.png","Bias")+"</li>"
     txt(2727) = "</ul></div></td>"
  else
     txt(2727) = "JFM</td>"
  end if

  txt(2730) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"siconc_sh_trends_mam.indmem.png")) then
     txt(2731) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#siconc_sh_trends_mam"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"siconc_sh_trends_mam"+quote+">MAM</a>" 
     txt(2732) = "<div class="+quote+"collapse"+quote+" id="+quote+"siconc_sh_trends_mam"+quote+">"
     txt(2733) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2734) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_sh_trends_mam.indmem.png","Indiv")+"</li>"
     txt(2735) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_sh_trends_mam.indmemdiff.png","Bias")+"</li>"
     txt(2737) = "</ul></div></td>"
  else
     txt(2737) = "MAM</td>"
  end if

  txt(2740) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"siconc_sh_trends_jja.indmem.png")) then
     txt(2741) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#siconc_sh_trends_jja"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"siconc_sh_trends_jja"+quote+">JJA</a>" 
     txt(2742) = "<div class="+quote+"collapse"+quote+" id="+quote+"siconc_sh_trends_jja"+quote+">"
     txt(2743) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2744) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_sh_trends_jja.indmem.png","Indiv")+"</li>"
     txt(2745) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_sh_trends_jja.indmemdiff.png","Bias")+"</li>"
     txt(2747) = "</ul></div></td>"
  else
     txt(2747) = "JJA</td>"
  end if

  txt(2750) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"siconc_sh_trends_jas.indmem.png")) then
     txt(2751) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#siconc_sh_trends_jas"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"siconc_sh_trends_jas"+quote+">JAS</a>" 
     txt(2752) = "<div class="+quote+"collapse"+quote+" id="+quote+"siconc_sh_trends_jas"+quote+">"
     txt(2753) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2754) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_sh_trends_jas.indmem.png","Indiv")+"</li>"
     txt(2755) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_sh_trends_jas.indmemdiff.png","Bias")+"</li>"
     txt(2757) = "</ul></div></td>"
  else
     txt(2757) = "JAS</td>"
  end if

  txt(2760) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"siconc_sh_trends_son.indmem.png")) then
     txt(2761) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#siconc_sh_trends_son"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"siconc_sh_trends_son"+quote+">SON</a>" 
     txt(2762) = "<div class="+quote+"collapse"+quote+" id="+quote+"siconc_sh_trends_son"+quote+">"
     txt(2763) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2764) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_sh_trends_son.indmem.png","Indiv")+"</li>"
     txt(2765) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_sh_trends_son.indmemdiff.png","Bias")+"</li>"
     txt(2767) = "</ul></div></td>"
  else
     txt(2767) = "SON</td>"
  end if

  txt(2770) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"siconc_sh_trends_ann.indmem.png")) then
     txt(2771) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#siconc_sh_trends_ann"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"siconc_sh_trends_ann"+quote+">ANN</a>" 
     txt(2772) = "<div class="+quote+"collapse"+quote+" id="+quote+"siconc_sh_trends_ann"+quote+">"
     txt(2773) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2774) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_sh_trends_ann.indmem.png","Indiv")+"</li>"
     txt(2775) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"siconc_sh_trends_ann.indmemdiff.png","Bias")+"</li>"
     txt(2777) = "</ul></div></td>"
  else
     txt(2777) = "ANN</td>"
  end if
  txt(2778) = "</tr>"



  txt(2804) = "<tr class="+quote+"d-flex"+quote+">"
  txt(2805) = "<td class="+quote+"col"+quote+"><b>ZOS</b></td>"

  txt(2810) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"zos_trends_djf.indmem.png")) then
     txt(2811) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#zos_trends_djf"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"zos_trends_djf"+quote+">DJF</a>" 
     txt(2812) = "<div class="+quote+"collapse"+quote+" id="+quote+"zos_trends_djf"+quote+">"
     txt(2813) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2814) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"zos_trends_djf.indmem.png","Indiv")+"</li>"
     txt(2815) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"zos_trends_djf.indmemdiff.png","Bias")+"</li>"
     txt(2817) = "</ul></div></td>"
  else
     txt(2817) = "DJF</td>"
  end if

  txt(2820) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"zos_trends_jfm.indmem.png")) then
     txt(2821) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#zos_trends_jfm"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"zos_trends_jfm"+quote+">JFM</a>" 
     txt(2822) = "<div class="+quote+"collapse"+quote+" id="+quote+"zos_trends_jfm"+quote+">"
     txt(2823) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2824) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"zos_trends_jfm.indmem.png","Indiv")+"</li>"
     txt(2825) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"zos_trends_jfm.indmemdiff.png","Bias")+"</li>"
     txt(2827) = "</ul></div></td>"
  else
     txt(2827) = "JFM</td>"
  end if

  txt(2830) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"zos_trends_mam.indmem.png")) then
     txt(2831) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#zos_trends_mam"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"zos_trends_mam"+quote+">MAM</a>" 
     txt(2832) = "<div class="+quote+"collapse"+quote+" id="+quote+"zos_trends_mam"+quote+">"
     txt(2833) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2834) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"zos_trends_mam.indmem.png","Indiv")+"</li>"
     txt(2835) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"zos_trends_mam.indmemdiff.png","Bias")+"</li>"
     txt(2837) = "</ul></div></td>"
  else
     txt(2837) = "MAM</td>"
  end if

  txt(2840) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"zos_trends_jja.indmem.png")) then
     txt(2841) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#zos_trends_jja"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"zos_trends_jja"+quote+">JJA</a>" 
     txt(2842) = "<div class="+quote+"collapse"+quote+" id="+quote+"zos_trends_jja"+quote+">"
     txt(2843) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2844) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"zos_trends_jja.indmem.png","Indiv")+"</li>"
     txt(2845) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"zos_trends_jja.indmemdiff.png","Bias")+"</li>"
     txt(2847) = "</ul></div></td>"
  else
     txt(2847) = "JJA</td>"
  end if

  txt(2850) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"zos_trends_jas.indmem.png")) then
     txt(2851) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#zos_trends_jas"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"zos_trends_jas"+quote+">JAS</a>" 
     txt(2852) = "<div class="+quote+"collapse"+quote+" id="+quote+"zos_trends_jas"+quote+">"
     txt(2853) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2854) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"zos_trends_jas.indmem.png","Indiv")+"</li>"
     txt(2855) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"zos_trends_jas.indmemdiff.png","Bias")+"</li>"
     txt(2857) = "</ul></div></td>"
  else
     txt(2857) = "JAS</td>"
  end if

  txt(2860) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"zos_trends_son.indmem.png")) then
     txt(2861) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#zos_trends_son"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"zos_trends_son"+quote+">SON</a>" 
     txt(2862) = "<div class="+quote+"collapse"+quote+" id="+quote+"zos_trends_son"+quote+">"
     txt(2863) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2864) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"zos_trends_son.indmem.png","Indiv")+"</li>"
     txt(2865) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"zos_trends_son.indmemdiff.png","Bias")+"</li>"
     txt(2867) = "</ul></div></td>"
  else
     txt(2867) = "SON</td>"
  end if

  txt(2870) = "<td class="+quote+"col"+quote+">"
  if (isfilepresent2(OUTDIR+"zos_trends_ann.indmem.png")) then
     txt(2871) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#zos_trends_ann"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"zos_trends_ann"+quote+">ANN</a>" 
     txt(2872) = "<div class="+quote+"collapse"+quote+" id="+quote+"zos_trends_ann"+quote+">"
     txt(2873) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(2874) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"zos_trends_ann.indmem.png","Indiv")+"</li>"
     txt(2875) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"zos_trends_ann.indmemdiff.png","Bias")+"</li>"
     txt(2877) = "</ul></div></td>"
  else
     txt(2877) = "ANN</td>"
  end if
  txt(2878) = "</tr>"
  txt(2880) = "</table></div></div>"


  txt(3100) = "<div class="+quote+"row"+quote+">"
  txt(3101) = "<div class="+quote+"col"+quote+">"
  txt(3102) = "<table class="+quote+"table table-bordered"+quote+">"
  txt(3103) = "<h3 class="+quote+"display-6"+quote+">Coupled Modes of Variability</h3>"
  txt(3104) = "<tr>"
  txt(3105) = "<td rowspan=4><b>ENSO</b></td>"
  

  txt(3190) = "<td>Spatial Composites</td>"
  txt(3191) = "<td colspan=2><table bordercolor=WhiteSmoke cellpadding=0 cellspacing=0><tr>"
  txt(3192) = "<td>El Ni&ntilde;o - La Ni&ntilde;a<br>SST/TAS/PSL<br>"

  if (isfilepresent2(OUTDIR+"nino34.spatialcomp.indmem.jja0.png")) then
     txt(3201) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nino34_spatialcomp_jja0"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nino34_spatialcomp_jja0"+quote+">JJA<sup>0</sup></a> " 
     txt(3202) = "<div class="+quote+"collapse"+quote+" id="+quote+"nino34_spatialcomp_jja0"+quote+">"
     txt(3203) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(3204) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.indmem.jja0.png","Indiv")+"</li>"
     txt(3205) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.indmemdiff.jja0.png","Bias")+"</li>"
     txt(3207) = "</ul></div>"
  else
     txt(3207) = "JJA<sup>0</sup>"
  end if

  if (isfilepresent2(OUTDIR+"nino34.spatialcomp.indmem.son0.png")) then
     txt(3211) = " <a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nino34_spatialcomp_son0"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nino34_spatialcomp_son0"+quote+">SON<sup>0</sup></a> " 
     txt(3212) = "<div class="+quote+"collapse"+quote+" id="+quote+"nino34_spatialcomp_son0"+quote+">"
     txt(3213) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(3214) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.indmem.son0.png","Indiv")+"</li>"
     txt(3215) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.indmemdiff.son0.png","Bias")+"</li>"
     txt(3217) = "</ul></div>"
  else
     txt(3217) = " SON<sup>0</sup>"
  end if

  if (isfilepresent2(OUTDIR+"nino34.spatialcomp.indmem.djf1.png")) then
     txt(3221) = " <a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nino34_spatialcomp_djf1"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nino34_spatialcomp_djf1"+quote+">DJF<sup>1</sup></a> " 
     txt(3222) = "<div class="+quote+"collapse"+quote+" id="+quote+"nino34_spatialcomp_djf1"+quote+">"
     txt(3223) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(3224) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.indmem.djf1.png","Indiv")+"</li>"
     txt(3225) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.indmemdiff.djf1.png","Bias")+"</li>"
     txt(3227) = "</ul></div>"
  else
     txt(3227) = " DJF<sup>1</sup>"
  end if

  if (isfilepresent2(OUTDIR+"nino34.spatialcomp.indmem.mam1.png")) then
     txt(3231) = " <a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nino34_spatialcomp_mam1"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nino34_spatialcomp_mam1"+quote+">MAM<sup>1</sup></a> " 
     txt(3232) = "<div class="+quote+"collapse"+quote+" id="+quote+"nino34_spatialcomp_mam1"+quote+">"
     txt(3233) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(3234) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.indmem.mam1.png","Indiv")+"</li>"
     txt(3235) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.indmemdiff.mam1.png","Bias")+"</li>"
     txt(3237) = "</ul></div></td>"
  else
     txt(3237) = " MAM<sup>1</sup></td>"
  end if

  txt(3250) = "<td>El Ni&ntilde;o - La Ni&ntilde;a<br>PR<br>"
  if (isfilepresent2(OUTDIR+"nino34.spatialcomp.pr.indmem.jja0.png")) then
     txt(3251) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nino34_spatialcomp_pr_jja0"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nino34_spatialcomp_pr_jja0"+quote+">JJA<sup>0</sup></a> " 
     txt(3252) = "<div class="+quote+"collapse"+quote+" id="+quote+"nino34_spatialcomp_pr_jja0"+quote+">"
     txt(3253) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(3254) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.pr.indmem.jja0.png","Indiv")+"</li>"
     txt(3255) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.pr.indmemdiff.jja0.png","Bias")+"</li>"
     txt(3257) = "</ul></div>"
  else
     txt(3257) = "JJA<sup>0</sup>"
  end if

  if (isfilepresent2(OUTDIR+"nino34.spatialcomp.pr.indmem.son0.png")) then
     txt(3261) = " <a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nino34_spatialcomp_pr_son0"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nino34_spatialcomp_pr_son0"+quote+">SON<sup>0</sup></a> " 
     txt(3262) = "<div class="+quote+"collapse"+quote+" id="+quote+"nino34_spatialcomp_pr_son0"+quote+">"
     txt(3263) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(3264) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.pr.indmem.son0.png","Indiv")+"</li>"
     txt(3265) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.pr.indmemdiff.son0.png","Bias")+"</li>"
     txt(3267) = "</ul></div>"
  else
     txt(3267) = " SON<sup>0</sup>"
  end if

  if (isfilepresent2(OUTDIR+"nino34.spatialcomp.pr.indmem.djf1.png")) then
     txt(3271) = " <a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nino34_spatialcomp_pr_djf1"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nino34_spatialcomp_pr_djf1"+quote+">DJF<sup>1</sup></a> " 
     txt(3272) = "<div class="+quote+"collapse"+quote+" id="+quote+"nino34_spatialcomp_pr_djf1"+quote+">"
     txt(3273) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(3274) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.pr.indmem.djf1.png","Indiv")+"</li>"
     txt(3275) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.pr.indmemdiff.djf1.png","Bias")+"</li>"
     txt(3277) = "</ul></div>"
  else
     txt(3277) = " DJF<sup>1</sup>"
  end if

  if (isfilepresent2(OUTDIR+"nino34.spatialcomp.pr.indmem.mam1.png")) then
     txt(3281) = " <a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nino34_spatialcomp_pr_mam1"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nino34_spatialcomp_pr_mam1"+quote+">MAM<sup>1</sup></a> " 
     txt(3282) = "<div class="+quote+"collapse"+quote+" id="+quote+"nino34_spatialcomp_pr_mam1"+quote+">"
     txt(3283) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(3284) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.pr.indmem.mam1.png","Indiv")+"</li>"
     txt(3285) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.pr.indmemdiff.mam1.png","Bias")+"</li>"
     txt(3287) = "</ul></div></td>"
  else
     txt(3287) = " MAM<sup>1</sup></td>"
  end if




  txt(3350) = "<td>El Ni&ntilde;o - La Ni&ntilde;a<br>ZOS<br>"
  if (isfilepresent2(OUTDIR+"nino34.spatialcomp.zos.indmem.jja0.png")) then
     txt(3351) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nino34_spatialcomp_zos_jja0"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nino34_spatialcomp_zos_jja0"+quote+">JJA<sup>0</sup></a> " 
     txt(3352) = "<div class="+quote+"collapse"+quote+" id="+quote+"nino34_spatialcomp_zos_jja0"+quote+">"
     txt(3353) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(3354) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.zos.indmem.jja0.png","Indiv")+"</li>"
     txt(3355) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.zos.indmemdiff.jja0.png","Bias")+"</li>"
     txt(3357) = "</ul></div>"
  else
     txt(3357) = "JJA<sup>0</sup>"
  end if

  if (isfilepresent2(OUTDIR+"nino34.spatialcomp.zos.indmem.son0.png")) then
     txt(3361) = " <a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nino34_spatialcomp_zos_son0"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nino34_spatialcomp_zos_son0"+quote+">SON<sup>0</sup></a> " 
     txt(3362) = "<div class="+quote+"collapse"+quote+" id="+quote+"nino34_spatialcomp_zos_son0"+quote+">"
     txt(3363) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(3364) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.zos.indmem.son0.png","Indiv")+"</li>"
     txt(3365) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.zos.indmemdiff.son0.png","Bias")+"</li>"
     txt(3367) = "</ul></div>"
  else
     txt(3367) = " SON<sup>0</sup>"
  end if

  if (isfilepresent2(OUTDIR+"nino34.spatialcomp.zos.indmem.djf1.png")) then
     txt(3371) = " <a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nino34_spatialcomp_zos_djf1"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nino34_spatialcomp_zos_djf1"+quote+">DJF<sup>1</sup></a> " 
     txt(3372) = "<div class="+quote+"collapse"+quote+" id="+quote+"nino34_spatialcomp_zos_djf1"+quote+">"
     txt(3373) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(3374) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.zos.indmem.djf1.png","Indiv")+"</li>"
     txt(3375) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.zos.indmemdiff.djf1.png","Bias")+"</li>"
     txt(3377) = "</ul></div>"
  else
     txt(3377) = " DJF<sup>1</sup>"
  end if

  if (isfilepresent2(OUTDIR+"nino34.spatialcomp.zos.indmem.mam1.png")) then
     txt(3381) = " <a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nino34_spatialcomp_zos_mam1"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nino34_spatialcomp_zos_mam1"+quote+">MAM<sup>1</sup></a> " 
     txt(3382) = "<div class="+quote+"collapse"+quote+" id="+quote+"nino34_spatialcomp_zos_mam1"+quote+">"
     txt(3383) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(3384) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.zos.indmem.mam1.png","Indiv")+"</li>"
     txt(3385) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.zos.indmemdiff.mam1.png","Bias")+"</li>"
     txt(3387) = "</ul></div></td></tr>"
  else
     txt(3387) = " MAM<sup>1</sup></td></tr>"
  end if





  txt(3491) = "<tr><td>El Ni&ntilde;o SST/TAS/PSL<br>"
  if (isfilepresent2(OUTDIR+"nino34.spatialcomp.elnino.indmem.jja0.png")) then
     txt(3501) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nino34_spatialcomp_elnino_jja0"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nino34_spatialcomp_elnino_jja0"+quote+">JJA<sup>0</sup></a> " 
     txt(3502) = "<div class="+quote+"collapse"+quote+" id="+quote+"nino34_spatialcomp_elnino_jja0"+quote+">"
     txt(3503) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(3504) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.elnino.indmem.jja0.png","Indiv")+"</li>"
     txt(3505) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.elnino.indmemdiff.jja0.png","Bias")+"</li>"
     txt(3507) = "</ul></div>"
  else
     txt(3507) = "JJA<sup>0</sup>"
  end if

  if (isfilepresent2(OUTDIR+"nino34.spatialcomp.elnino.indmem.son0.png")) then
     txt(3511) = " <a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nino34_spatialcomp_elnino_son0"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nino34_spatialcomp_elnino_son0"+quote+">SON<sup>0</sup></a> " 
     txt(3512) = "<div class="+quote+"collapse"+quote+" id="+quote+"nino34_spatialcomp_elnino_son0"+quote+">"
     txt(3513) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(3514) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.elnino.indmem.son0.png","Indiv")+"</li>"
     txt(3515) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.elnino.indmemdiff.son0.png","Bias")+"</li>"
     txt(3517) = "</ul></div>"
  else
     txt(3517) = " SON<sup>0</sup>"
  end if

  if (isfilepresent2(OUTDIR+"nino34.spatialcomp.elnino.indmem.djf1.png")) then
     txt(3521) = " <a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nino34_spatialcomp_elnino_djf1"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nino34_spatialcomp_elnino_djf1"+quote+">DJF<sup>1</sup></a> " 
     txt(3522) = "<div class="+quote+"collapse"+quote+" id="+quote+"nino34_spatialcomp_elnino_djf1"+quote+">"
     txt(3523) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(3524) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.elnino.indmem.djf1.png","Indiv")+"</li>"
     txt(3525) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.elnino.indmemdiff.djf1.png","Bias")+"</li>"
     txt(3527) = "</ul></div>"
  else
     txt(3527) = " DJF<sup>1</sup>"
  end if

  if (isfilepresent2(OUTDIR+"nino34.spatialcomp.elnino.indmem.mam1.png")) then
     txt(3531) = " <a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nino34_spatialcomp_elnino_mam1"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nino34_spatialcomp_elnino_mam1"+quote+">MAM<sup>1</sup></a> " 
     txt(3532) = "<div class="+quote+"collapse"+quote+" id="+quote+"nino34_spatialcomp_elnino_mam1"+quote+">"
     txt(3533) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(3534) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.elnino.indmem.mam1.png","Indiv")+"</li>"
     txt(3535) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.elnino.indmemdiff.mam1.png","Bias")+"</li>"
     txt(3537) = "</ul></div></td>"
  else
     txt(3537) = " MAM<sup>1</sup></td>"
  end if

  txt(3550) = "<td>El Ni&ntilde;o PR<br>"
  if (isfilepresent2(OUTDIR+"nino34.spatialcomp.elnino.pr.indmem.jja0.png")) then
     txt(3551) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nino34_spatialcomp_elnino_pr_jja0"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nino34_spatialcomp_elnino_pr_jja0"+quote+">JJA<sup>0</sup></a> " 
     txt(3552) = "<div class="+quote+"collapse"+quote+" id="+quote+"nino34_spatialcomp_elnino_pr_jja0"+quote+">"
     txt(3553) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(3554) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.elnino.pr.indmem.jja0.png","Indiv")+"</li>"
     txt(3555) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.elnino.pr.indmemdiff.jja0.png","Bias")+"</li>"
     txt(3557) = "</ul></div>"
  else
     txt(3557) = "JJA<sup>0</sup>"
  end if

  if (isfilepresent2(OUTDIR+"nino34.spatialcomp.elnino.pr.indmem.son0.png")) then
     txt(3561) = " <a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nino34_spatialcomp_elnino_pr_son0"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nino34_spatialcomp_elnino_pr_son0"+quote+">SON<sup>0</sup></a> " 
     txt(3562) = "<div class="+quote+"collapse"+quote+" id="+quote+"nino34_spatialcomp_elnino_pr_son0"+quote+">"
     txt(3563) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(3564) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.elnino.pr.indmem.son0.png","Indiv")+"</li>"
     txt(3565) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.elnino.pr.indmemdiff.son0.png","Bias")+"</li>"
     txt(3567) = "</ul></div>"
  else
     txt(3567) = " SON<sup>0</sup>"
  end if

  if (isfilepresent2(OUTDIR+"nino34.spatialcomp.elnino.pr.indmem.djf1.png")) then
     txt(3571) = " <a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nino34_spatialcomp_elnino_pr_djf1"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nino34_spatialcomp_elnino_pr_djf1"+quote+">DJF<sup>1</sup></a> " 
     txt(3572) = "<div class="+quote+"collapse"+quote+" id="+quote+"nino34_spatialcomp_elnino_pr_djf1"+quote+">"
     txt(3573) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(3574) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.elnino.pr.indmem.djf1.png","Indiv")+"</li>"
     txt(3575) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.elnino.pr.indmemdiff.djf1.png","Bias")+"</li>"
     txt(3577) = "</ul></div>"
  else
     txt(3577) = " DJF<sup>1</sup>"
  end if

  if (isfilepresent2(OUTDIR+"nino34.spatialcomp.elnino.pr.indmem.mam1.png")) then
     txt(3581) = " <a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nino34_spatialcomp_elnino_pr_mam1"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nino34_spatialcomp_elnino_pr_mam1"+quote+">MAM<sup>1</sup></a> " 
     txt(3582) = "<div class="+quote+"collapse"+quote+" id="+quote+"nino34_spatialcomp_elnino_pr_mam1"+quote+">"
     txt(3583) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(3584) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.elnino.pr.indmem.mam1.png","Indiv")+"</li>"
     txt(3585) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.elnino.pr.indmemdiff.mam1.png","Bias")+"</li>"
     txt(3587) = "</ul></div></td>"
  else
     txt(3587) = " MAM<sup>1</sup></td>"
  end if

  txt(3650) = "<td>El Ni&ntilde;o ZOS<br>"
  if (isfilepresent2(OUTDIR+"nino34.spatialcomp.elnino.zos.indmem.jja0.png")) then
     txt(3651) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nino34_spatialcomp_elnino_zos_jja0"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nino34_spatialcomp_elnino_zos_jja0"+quote+">JJA<sup>0</sup></a> " 
     txt(3652) = "<div class="+quote+"collapse"+quote+" id="+quote+"nino34_spatialcomp_elnino_zos_jja0"+quote+">"
     txt(3653) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(3654) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.elnino.zos.indmem.jja0.png","Indiv")+"</li>"
     txt(3655) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.elnino.zos.indmemdiff.jja0.png","Bias")+"</li>"
     txt(3657) = "</ul></div>"
  else
     txt(3657) = "JJA<sup>0</sup>"
  end if

  if (isfilepresent2(OUTDIR+"nino34.spatialcomp.elnino.zos.indmem.son0.png")) then
     txt(3661) = " <a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nino34_spatialcomp_elnino_zos_son0"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nino34_spatialcomp_elnino_zos_son0"+quote+">SON<sup>0</sup></a> " 
     txt(3662) = "<div class="+quote+"collapse"+quote+" id="+quote+"nino34_spatialcomp_elnino_zos_son0"+quote+">"
     txt(3663) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(3664) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.elnino.zos.indmem.son0.png","Indiv")+"</li>"
     txt(3665) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.elnino.zos.indmemdiff.son0.png","Bias")+"</li>"
     txt(3667) = "</ul></div>"
  else
     txt(3667) = " SON<sup>0</sup>"
  end if

  if (isfilepresent2(OUTDIR+"nino34.spatialcomp.elnino.zos.indmem.djf1.png")) then
     txt(3671) = " <a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nino34_spatialcomp_elnino_zos_djf1"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nino34_spatialcomp_elnino_zos_djf1"+quote+">DJF<sup>1</sup></a> " 
     txt(3672) = "<div class="+quote+"collapse"+quote+" id="+quote+"nino34_spatialcomp_elnino_zos_djf1"+quote+">"
     txt(3673) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(3674) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.elnino.zos.indmem.djf1.png","Indiv")+"</li>"
     txt(3675) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.elnino.zos.indmemdiff.djf1.png","Bias")+"</li>"
     txt(3677) = "</ul></div>"
  else
     txt(3677) = " DJF<sup>1</sup>"
  end if

  if (isfilepresent2(OUTDIR+"nino34.spatialcomp.elnino.zos.indmem.mam1.png")) then
     txt(3681) = " <a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nino34_spatialcomp_elnino_zos_mam1"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nino34_spatialcomp_elnino_zos_mam1"+quote+">MAM<sup>1</sup></a> " 
     txt(3682) = "<div class="+quote+"collapse"+quote+" id="+quote+"nino34_spatialcomp_elnino_zos_mam1"+quote+">"
     txt(3683) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(3684) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.elnino.zos.indmem.mam1.png","Indiv")+"</li>"
     txt(3685) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.elnino.zos.indmemdiff.mam1.png","Bias")+"</li>"
     txt(3687) = "</ul></div></td></tr>"
  else
     txt(3687) = " MAM<sup>1</sup></td></tr>"
  end if


  txt(3691) = "<tr><td>La Ni&ntilde;a SST/TAS/PSL<br>"
  if (isfilepresent2(OUTDIR+"nino34.spatialcomp.lanina.indmem.jja0.png")) then
     txt(3701) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nino34_spatialcomp_lanina_jja0"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nino34_spatialcomp_lanina_jja0"+quote+">JJA<sup>0</sup></a> " 
     txt(3702) = "<div class="+quote+"collapse"+quote+" id="+quote+"nino34_spatialcomp_lanina_jja0"+quote+">"
     txt(3703) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(3704) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.lanina.indmem.jja0.png","Indiv")+"</li>"
     txt(3705) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.lanina.indmemdiff.jja0.png","Bias")+"</li>"
     txt(3707) = "</ul></div>"
  else
     txt(3707) = "JJA<sup>0</sup>"
  end if

  if (isfilepresent2(OUTDIR+"nino34.spatialcomp.lanina.indmem.son0.png")) then
     txt(3711) = " <a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nino34_spatialcomp_lanina_son0"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nino34_spatialcomp_lanina_son0"+quote+">SON<sup>0</sup></a> " 
     txt(3712) = "<div class="+quote+"collapse"+quote+" id="+quote+"nino34_spatialcomp_lanina_son0"+quote+">"
     txt(3713) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(3714) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.lanina.indmem.son0.png","Indiv")+"</li>"
     txt(3715) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.lanina.indmemdiff.son0.png","Bias")+"</li>"
     txt(3717) = "</ul></div>"
  else
     txt(3717) = " SON<sup>0</sup>"
  end if

  if (isfilepresent2(OUTDIR+"nino34.spatialcomp.lanina.indmem.djf1.png")) then
     txt(3721) = " <a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nino34_spatialcomp_lanina_djf1"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nino34_spatialcomp_lanina_djf1"+quote+">DJF<sup>1</sup></a> " 
     txt(3722) = "<div class="+quote+"collapse"+quote+" id="+quote+"nino34_spatialcomp_lanina_djf1"+quote+">"
     txt(3723) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(3724) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.lanina.indmem.djf1.png","Indiv")+"</li>"
     txt(3725) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.lanina.indmemdiff.djf1.png","Bias")+"</li>"
     txt(3727) = "</ul></div>"
  else
     txt(3727) = " DJF<sup>1</sup>"
  end if

  if (isfilepresent2(OUTDIR+"nino34.spatialcomp.lanina.indmem.mam1.png")) then
     txt(3731) = " <a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nino34_spatialcomp_lanina_mam1"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nino34_spatialcomp_lanina_mam1"+quote+">MAM<sup>1</sup></a> " 
     txt(3732) = "<div class="+quote+"collapse"+quote+" id="+quote+"nino34_spatialcomp_lanina_mam1"+quote+">"
     txt(3733) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(3734) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.lanina.indmem.mam1.png","Indiv")+"</li>"
     txt(3735) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.lanina.indmemdiff.mam1.png","Bias")+"</li>"
     txt(3737) = "</ul></div></td>"
  else
     txt(3737) = " MAM<sup>1</sup></td>"
  end if

  txt(3750) = "<td>La Ni&ntilde;a PR<br>"
  if (isfilepresent2(OUTDIR+"nino34.spatialcomp.lanina.pr.indmem.jja0.png")) then
     txt(3751) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nino34_spatialcomp_lanina_pr_jja0"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nino34_spatialcomp_lanina_pr_jja0"+quote+">JJA<sup>0</sup></a> " 
     txt(3752) = "<div class="+quote+"collapse"+quote+" id="+quote+"nino34_spatialcomp_lanina_pr_jja0"+quote+">"
     txt(3753) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(3754) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.lanina.pr.indmem.jja0.png","Indiv")+"</li>"
     txt(3755) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.lanina.pr.indmemdiff.jja0.png","Bias")+"</li>"
     txt(3757) = "</ul></div>"
  else
     txt(3757) = "JJA<sup>0</sup>"
  end if

  if (isfilepresent2(OUTDIR+"nino34.spatialcomp.lanina.pr.indmem.son0.png")) then
     txt(3761) = " <a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nino34_spatialcomp_lanina_pr_son0"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nino34_spatialcomp_lanina_pr_son0"+quote+">SON<sup>0</sup></a> " 
     txt(3762) = "<div class="+quote+"collapse"+quote+" id="+quote+"nino34_spatialcomp_lanina_pr_son0"+quote+">"
     txt(3763) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(3764) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.lanina.pr.indmem.son0.png","Indiv")+"</li>"
     txt(3765) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.lanina.pr.indmemdiff.son0.png","Bias")+"</li>"
     txt(3767) = "</ul></div>"
  else
     txt(3767) = " SON<sup>0</sup>"
  end if

  if (isfilepresent2(OUTDIR+"nino34.spatialcomp.lanina.pr.indmem.djf1.png")) then
     txt(3771) = " <a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nino34_spatialcomp_lanina_pr_djf1"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nino34_spatialcomp_lanina_pr_djf1"+quote+">DJF<sup>1</sup></a> " 
     txt(3772) = "<div class="+quote+"collapse"+quote+" id="+quote+"nino34_spatialcomp_lanina_pr_djf1"+quote+">"
     txt(3773) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(3774) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.lanina.pr.indmem.djf1.png","Indiv")+"</li>"
     txt(3775) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.lanina.pr.indmemdiff.djf1.png","Bias")+"</li>"
     txt(3777) = "</ul></div>"
  else
     txt(3777) = " DJF<sup>1</sup>"
  end if

  if (isfilepresent2(OUTDIR+"nino34.spatialcomp.lanina.pr.indmem.mam1.png")) then
     txt(3781) = " <a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nino34_spatialcomp_lanina_pr_mam1"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nino34_spatialcomp_lanina_pr_mam1"+quote+">MAM<sup>1</sup></a> " 
     txt(3782) = "<div class="+quote+"collapse"+quote+" id="+quote+"nino34_spatialcomp_lanina_pr_mam1"+quote+">"
     txt(3783) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(3784) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.lanina.pr.indmem.mam1.png","Indiv")+"</li>"
     txt(3785) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.lanina.pr.indmemdiff.mam1.png","Bias")+"</li>"
     txt(3787) = "</ul></div></td>"
  else
     txt(3787) = " MAM<sup>1</sup></td>"
  end if


  txt(3850) = "<td>La Ni&ntilde;a ZOS<br>"
  if (isfilepresent2(OUTDIR+"nino34.spatialcomp.lanina.zos.indmem.jja0.png")) then
     txt(3851) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nino34_spatialcomp_lanina_zos_jja0"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nino34_spatialcomp_lanina_zos_jja0"+quote+">JJA<sup>0</sup></a> " 
     txt(3852) = "<div class="+quote+"collapse"+quote+" id="+quote+"nino34_spatialcomp_lanina_zos_jja0"+quote+">"
     txt(3853) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(3854) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.lanina.zos.indmem.jja0.png","Indiv")+"</li>"
     txt(3855) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.lanina.zos.indmemdiff.jja0.png","Bias")+"</li>"
     txt(3857) = "</ul></div>"
  else
     txt(3857) = "JJA<sup>0</sup>"
  end if

  if (isfilepresent2(OUTDIR+"nino34.spatialcomp.lanina.zos.indmem.son0.png")) then
     txt(3861) = " <a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nino34_spatialcomp_lanina_zos_son0"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nino34_spatialcomp_lanina_zos_son0"+quote+">SON<sup>0</sup></a> " 
     txt(3862) = "<div class="+quote+"collapse"+quote+" id="+quote+"nino34_spatialcomp_lanina_zos_son0"+quote+">"
     txt(3863) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(3864) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.lanina.zos.indmem.son0.png","Indiv")+"</li>"
     txt(3865) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.lanina.zos.indmemdiff.son0.png","Bias")+"</li>"
     txt(3867) = "</ul></div>"
  else
     txt(3867) = " SON<sup>0</sup>"
  end if

  if (isfilepresent2(OUTDIR+"nino34.spatialcomp.lanina.zos.indmem.djf1.png")) then
     txt(3871) = " <a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nino34_spatialcomp_lanina_zos_djf1"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nino34_spatialcomp_lanina_zos_djf1"+quote+">DJF<sup>1</sup></a> " 
     txt(3872) = "<div class="+quote+"collapse"+quote+" id="+quote+"nino34_spatialcomp_lanina_zos_djf1"+quote+">"
     txt(3873) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(3874) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.lanina.zos.indmem.djf1.png","Indiv")+"</li>"
     txt(3875) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.lanina.zos.indmemdiff.djf1.png","Bias")+"</li>"
     txt(3877) = "</ul></div>"
  else
     txt(3877) = " DJF<sup>1</sup>"
  end if

  if (isfilepresent2(OUTDIR+"nino34.spatialcomp.lanina.zos.indmem.mam1.png")) then
     txt(3881) = " <a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nino34_spatialcomp_lanina_zos_mam1"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nino34_spatialcomp_lanina_zos_mam1"+quote+">MAM<sup>1</sup></a> " 
     txt(3882) = "<div class="+quote+"collapse"+quote+" id="+quote+"nino34_spatialcomp_lanina_zos_mam1"+quote+">"
     txt(3883) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(3884) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.lanina.zos.indmem.mam1.png","Indiv")+"</li>"
     txt(3885) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.spatialcomp.lanina.zos.indmemdiff.mam1.png","Bias")+"</li>"
     txt(3887) = "</ul></div></td></tr>"
  else
     txt(3887) = " MAM<sup>1</sup></td></tr>"
  end if

  txt(3890) = "<tr>"
  txt(4500) = "<td>"
  if (isfilepresent2(OUTDIR+"nino34.hov.elnino.indmem.png")) then
     txt(4501) = "El Ni&ntilde;o Hovm&ouml;ller<br><a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nino34_hov_elnino"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nino34_hov_elnino"+quote+">SST</a> " 
     txt(4502) = "<div class="+quote+"collapse"+quote+" id="+quote+"nino34_hov_elnino"+quote+">"
     txt(4503) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(4504) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.hov.elnino.indmem.png","Indiv")+"</li>"
     txt(4505) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.hov.elnino.indmemdiff.png","Bias")+"</li>"
     txt(4507) = "</ul></div>"
     txt(4508) = " <a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nino34_hov_elnino_zos"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nino34_hov_elnino_zos"+quote+">ZOS</a> " 
     txt(4509) = "<div class="+quote+"collapse"+quote+" id="+quote+"nino34_hov_elnino_zos"+quote+">"
     txt(4510) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(4511) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.hov.elnino.zos.indmem.png","Indiv")+"</li>"
     txt(4512) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.hov.elnino.zos.indmemdiff.png","Bias")+"</li>"
     txt(4513) = "</ul></div></td>"
  else
     txt(4513) = "El Ni&ntilde;o Hovm&ouml;ller</td>"
  end if
  txt(4520) = "<td>"
  if (isfilepresent2(OUTDIR+"nino34.hov.lanina.indmem.png")) then
     txt(4521) = "La Ni&ntilde;a Hovm&ouml;ller<br><a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nino34_hov_lanina"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nino34_hov_lanina"+quote+">SST</a> " 
     txt(4522) = "<div class="+quote+"collapse"+quote+" id="+quote+"nino34_hov_lanina"+quote+">"
     txt(4523) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(4524) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.hov.lanina.indmem.png","Indiv")+"</li>"
     txt(4525) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.hov.lanina.indmemdiff.png","Bias")+"</li>"
     txt(4527) = "</ul></div>"
     txt(4528) = " <a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nino34_hov_lanina_zos"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nino34_hov_lanina_zos"+quote+">ZOS</a> " 
     txt(4529) = "<div class="+quote+"collapse"+quote+" id="+quote+"nino34_hov_lanina_zos"+quote+">"
     txt(4530) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(4531) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.hov.lanina.zos.indmem.png","Indiv")+"</li>"
     txt(4532) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.hov.lanina.zos.indmemdiff.png","Bias")+"</li>"
     txt(4533) = "</ul></div></td><td> </td></tr>"
  else
     txt(4533) = "La Ni&ntilde;a Hovm&ouml;ller</td><td> </td></tr>"
  end if
  txt(4543) = "</table></td></tr>"


  txt(4599) = "<tr>"
  txt(4600) = "<td rowspan=3>Ni&ntilde;o3.4</td>"
  txt(4601) = "<td>"+table_link_setup(OUTDIR,"nino34.timeseries.indmem.png","Timeseries")+"</td>"
  txt(4610) = "<td>"+table_link_setup(OUTDIR,"nino34.monstddev.indmem.png","Monthly Std. Dev.")+"</td></tr>"
  txt(4611) = "<tr><td>"+table_link_setup(OUTDIR,"nino34.powspec.indmem.png","Power Spectra")+"</td>"
  txt(4612) = "<td>"
  if (isfilepresent2(OUTDIR+"nino34.wavelet.indmem.png")) then
     txt(4613) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nino34_wavelet"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nino34_wavelet"+quote+">Wavelet</a> " 
     txt(4614) = "<div class="+quote+"collapse"+quote+" id="+quote+"nino34_wavelet"+quote+">"
     txt(4615) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(4616) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.wavelet.indmem.png","Indiv")+"</li>"
     txt(4617) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34.wavelet.indmemdiff.png","Bias")+"</li>"
     txt(4618) = "</ul></div>"
  else
     txt(4613) = "Wavelet"
  end if
  txt(4619) = "</td></tr>" 
  txt(4620) = "<tr><td>"+table_link_setup(OUTDIR,"nino34.autocor.indmem.png","Autocorrelation")+"</td>"
  txt(4621) = "<td>"+table_link_setup(OUTDIR,"nino34_runstddev.timeseries.indmem.png","Running Standard Deviation")+"</td></tr>"


  txt(5196) = "<tr>"
  txt(5197) = "<td rowspan=2><b>AMV</b></td>"
  txt(5198) = "<td>Regr: "
  if (isfilepresent2(OUTDIR+"amv.indmem.png")) then
     txt(5199) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#amo"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"amo"+quote+">SST</a> " 
     txt(5200) = "<div class="+quote+"collapse"+quote+" id="+quote+"amo"+quote+">"
     txt(5201) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(5202) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"amv.indmem.png","Indiv")+"</li>"
     txt(5203) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"amv.indmemdiff.png","Bias")+"</li>"
     txt(5205) = "</ul></div>"
  else
     txt(5205) = "SST "
  end if
  if (isfilepresent2(OUTDIR+"amv.tassstreg.indmem.png")) then
     txt(5210) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#amv_tassstreg"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"amv_tassstreg"+quote+">TAS</a> " 
     txt(5211) = "<div class="+quote+"collapse"+quote+" id="+quote+"amv_tassstreg"+quote+">"
     txt(5212) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(5213) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"amv.tassstreg.indmem.png","Indiv")+"</li>"
     txt(5214) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"amv.tassstreg.indmemdiff.png","Bias")+"</li>"
     txt(5216) = "</ul></div>"
  else
     txt(5210) = "TAS "
  end if
  if (isfilepresent2(OUTDIR+"amv.prreg.indmem.png")) then
     txt(5220) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#amv_prreg"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"amv_prreg"+quote+">PR</a> " 
     txt(5221) = "<div class="+quote+"collapse"+quote+" id="+quote+"amv_prreg"+quote+">"
     txt(5222) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(5223) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"amv.prreg.indmem.png","Indiv")+"</li>"
     txt(5224) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"amv.prreg.indmemdiff.png","Bias")+"</li>"
     txt(5226) = "</ul></div>"
  else
     txt(5220) = "PR "
  end if
  if (isfilepresent2(OUTDIR+"amv.zosreg.indmem.png")) then
     txt(5230) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#amv_zosreg"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"amv_zosreg"+quote+">ZOS</a> " 
     txt(5231) = "<div class="+quote+"collapse"+quote+" id="+quote+"amv_zosreg"+quote+">"
     txt(5232) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(5233) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"amv.zosreg.indmem.png","Indiv")+"</li>"
     txt(5234) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"amv.zosreg.indmemdiff.png","Bias")+"</li>"
     txt(5236) = "</ul></div></td>"
  else
     txt(5230) = "ZOS</td>"
  end if


  txt(5250) = "<td>"+table_link_setup(OUTDIR,"amv_timeseries_mon.indmem.png","Timeseries")+"</td>"
  txt(5251) = "<td rowspan=2>"+table_link_setup(OUTDIR,"amv.powspec.indmem.png","Power Spectra")+"</td></tr>"

  txt(5268) = "<tr><td>Regr LP: "
  if (isfilepresent2(OUTDIR+"amv.lp.indmem.png")) then
     txt(5269) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#amv_lp"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"amv_lp"+quote+">SST</a> " 
     txt(5270) = "<div class="+quote+"collapse"+quote+" id="+quote+"amv_lp"+quote+">"
     txt(5271) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(5272) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"amv.lp.indmem.png","Indiv")+"</li>"
     txt(5273) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"amv.lp.indmemdiff.png","Bias")+"</li>"
     txt(5275) = "</ul></div>"
  else
     txt(5275) = "SST "
  end if
  if (isfilepresent2(OUTDIR+"amv.lp.tassstreg.indmem.png")) then
     txt(5280) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#amv_lp_tassstreg"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"amv_lp_tassstreg"+quote+">TAS</a> " 
     txt(5281) = "<div class="+quote+"collapse"+quote+" id="+quote+"amv_lp_tassstreg"+quote+">"
     txt(5282) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(5283) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"amv.lp.tassstreg.indmem.png","Indiv")+"</li>"
     txt(5284) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"amv.lp.tassstreg.indmemdiff.png","Bias")+"</li>"
     txt(5286) = "</ul></div>"
  else
     txt(5280) = "TAS "
  end if
  if (isfilepresent2(OUTDIR+"amv.lp.prreg.indmem.png")) then
     txt(5290) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#amv_lp_prreg"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"amv_lp_prreg"+quote+">PR</a> " 
     txt(5291) = "<div class="+quote+"collapse"+quote+" id="+quote+"amv_lp_prreg"+quote+">"
     txt(5292) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(5293) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"amv.lp.prreg.indmem.png","Indiv")+"</li>"
     txt(5294) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"amv.lp.prreg.indmemdiff.png","Bias")+"</li>"
     txt(5296) = "</ul></div>"
  else
     txt(5290) = "PR "
  end if
  if (isfilepresent2(OUTDIR+"amv.lp.zosreg.indmem.png")) then
     txt(5300) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#amv_lp_zosreg"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"amv_lp_zosreg"+quote+">ZOS</a> " 
     txt(5301) = "<div class="+quote+"collapse"+quote+" id="+quote+"amv_lp_zosreg"+quote+">"
     txt(5302) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(5303) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"amv.lp.zosreg.indmem.png","Indiv")+"</li>"
     txt(5304) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"amv.lp.zosreg.indmemdiff.png","Bias")+"</li>"
     txt(5306) = "</ul></div></td>"
  else
     txt(5300) = "ZOS</td>"
  end if
  txt(5315) = "<td>"+table_link_setup(OUTDIR,"amv_timeseries_lowpass_mon.indmem.png","Timeseries")+"</td></tr>"

  txt(5496) = "<tr>"
  txt(5497) = "<td><b>PDV</b></td>"
  txt(5498) = "<td>Regr: "
  if (isfilepresent2(OUTDIR+"pdv.indmem.png")) then
     txt(5499) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#pdo"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"pdo"+quote+">SST</a> " 
     txt(5500) = "<div class="+quote+"collapse"+quote+" id="+quote+"pdo"+quote+">"
     txt(5501) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(5502) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pdv.indmem.png","Indiv")+"</li>"
     txt(5503) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pdv.indmemdiff.png","Bias")+"</li>"
     txt(5505) = "</ul></div>"
  else
     txt(5505) = "SST "
  end if
  if (isfilepresent2(OUTDIR+"pdv.tassstreg.indmem.png")) then
     txt(5510) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#pdv_tassstreg"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"pdv_tassstreg"+quote+">TAS</a> " 
     txt(5511) = "<div class="+quote+"collapse"+quote+" id="+quote+"pdv_tassstreg"+quote+">"
     txt(5512) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(5513) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pdv.tassstreg.indmem.png","Indiv")+"</li>"
     txt(5514) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pdv.tassstreg.indmemdiff.png","Bias")+"</li>"
     txt(5516) = "</ul></div>"
  else
     txt(5510) = "TAS "
  end if
  if (isfilepresent2(OUTDIR+"pdv.prreg.indmem.png")) then
     txt(5520) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#pdv_prreg"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"pdv_prreg"+quote+">PR</a> " 
     txt(5521) = "<div class="+quote+"collapse"+quote+" id="+quote+"pdv_prreg"+quote+">"
     txt(5522) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(5523) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pdv.prreg.indmem.png","Indiv")+"</li>"
     txt(5524) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pdv.prreg.indmemdiff.png","Bias")+"</li>"
     txt(5526) = "</ul></div>"
  else
     txt(5520) = "PR "
  end if

  if (isfilepresent2(OUTDIR+"pdv.zosreg.indmem.png")) then
     txt(5530) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#pdv_zosreg"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"pdv_zosreg"+quote+">ZOS</a> " 
     txt(5531) = "<div class="+quote+"collapse"+quote+" id="+quote+"pdv_zosreg"+quote+">"
     txt(5532) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(5533) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pdv.zosreg.indmem.png","Indiv")+"</li>"
     txt(5534) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pdv.zosreg.indmemdiff.png","Bias")+"</li>"
     txt(5536) = "</ul></div></td>"
  else
     txt(5530) = "ZOS</td>"
  end if
  txt(5550) = "<td>"+table_link_setup(OUTDIR,"pdv_timeseries_mon.indmem.png","Timeseries")+"</td>"
  txt(5551) = "<td>"+table_link_setup(OUTDIR,"pdv.powspec.indmem.png","Power Spectra")+"</td></tr>"

  txt(5596) = "<tr>"
  txt(5597) = "<td rowspan=2><b>IPV</b></td>"
  txt(5598) = "<td>Standard: "
  if (isfilepresent2(OUTDIR+"ipv.indmem.png")) then
     txt(5599) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#ipv"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"ipv"+quote+">SST</a> " 
     txt(5600) = "<div class="+quote+"collapse"+quote+" id="+quote+"ipv"+quote+">"
     txt(5601) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(5602) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"ipv.indmem.png","Indiv")+"</li>"
     txt(5603) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"ipv.indmemdiff.png","Bias")+"</li>"
     txt(5605) = "</ul></div>"
  else
     txt(5605) = "SST "
  end if
  if (isfilepresent2(OUTDIR+"ipv.tassstreg.indmem.png")) then
     txt(5610) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#ipv_tassstreg"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"ipv_tassstreg"+quote+">TAS</a> " 
     txt(5611) = "<div class="+quote+"collapse"+quote+" id="+quote+"ipv_tassstreg"+quote+">"
     txt(5612) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(5613) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"ipv.tassstreg.indmem.png","Indiv")+"</li>"
     txt(5614) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"ipv.tassstreg.indmemdiff.png","Bias")+"</li>"
     txt(5616) = "</ul></div>"
  else
     txt(5610) = "TAS "
  end if
  if (isfilepresent2(OUTDIR+"ipv.prreg.indmem.png")) then
     txt(5620) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#ipv_prreg"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"ipv_prreg"+quote+">PR</a> " 
     txt(5621) = "<div class="+quote+"collapse"+quote+" id="+quote+"ipv_prreg"+quote+">"
     txt(5622) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(5623) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"ipv.prreg.indmem.png","Indiv")+"</li>"
     txt(5624) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"ipv.prreg.indmemdiff.png","Bias")+"</li>"
     txt(5626) = "</ul></div>"
  else
     txt(5620) = "PR "
  end if
  if (isfilepresent2(OUTDIR+"ipv.zosreg.indmem.png")) then
     txt(5630) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#ipv_zosreg"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"ipv_zosreg"+quote+">ZOS</a> " 
     txt(5631) = "<div class="+quote+"collapse"+quote+" id="+quote+"ipv_zosreg"+quote+">"
     txt(5632) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(5633) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"ipv.zosreg.indmem.png","Indiv")+"</li>"
     txt(5634) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"ipv.zosreg.indmemdiff.png","Bias")+"</li>"
     txt(5636) = "</ul></div></td>"
  else
     txt(5630) = "ZOS</td>"
  end if
  txt(5650) = "<td>"+table_link_setup(OUTDIR,"ipv_timeseries_mon.indmem.png","Timeseries")+"</td>"
  txt(5651) = "<td>"+table_link_setup(OUTDIR,"ipv.powspec.indmem.png","Power Spectra")+"</td></tr>"

  txt(5660) = "<td>Henley: "
  if (isfilepresent2(OUTDIR+"ipv.henley.indmem.png")) then
     txt(5661) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#ipvh"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"ipvh"+quote+">SST</a> " 
     txt(5662) = "<div class="+quote+"collapse"+quote+" id="+quote+"ipvh"+quote+">"
     txt(5663) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(5664) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"ipv.henley.indmem.png","Indiv")+"</li>"
     txt(5665) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"ipv.henley.indmemdiff.png","Bias")+"</li>"
     txt(5666) = "</ul></div>"
  else
     txt(5661) = "SST "
  end if
  if (isfilepresent2(OUTDIR+"ipv.henley.tassstreg.indmem.png")) then
     txt(5670) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#ipvh_tassstreg"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"ipvh_tassstreg"+quote+">TAS</a> " 
     txt(5671) = "<div class="+quote+"collapse"+quote+" id="+quote+"ipvh_tassstreg"+quote+">"
     txt(5672) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(5673) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"ipv.henley.tassstreg.indmem.png","Indiv")+"</li>"
     txt(5674) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"ipv.henley.tassstreg.indmemdiff.png","Bias")+"</li>"
     txt(5676) = "</ul></div>"
  else
     txt(5670) = "TAS "
  end if
  if (isfilepresent2(OUTDIR+"ipv.henley.prreg.indmem.png")) then
     txt(5680) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#ipvh_prreg"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"ipvh_prreg"+quote+">PR</a> " 
     txt(5681) = "<div class="+quote+"collapse"+quote+" id="+quote+"ipvh_prreg"+quote+">"
     txt(5682) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(5683) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"ipv.henley.prreg.indmem.png","Indiv")+"</li>"
     txt(5684) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"ipv.henley.prreg.indmemdiff.png","Bias")+"</li>"
     txt(5686) = "</ul></div>"
  else
     txt(5680) = "PR "
  end if
  if (isfilepresent2(OUTDIR+"ipv.henley.zosreg.indmem.png")) then
     txt(5690) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#ipvh_zosreg"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"ipvh_zosreg"+quote+">ZOS</a> " 
     txt(5691) = "<div class="+quote+"collapse"+quote+" id="+quote+"ipvh_zosreg"+quote+">"
     txt(5692) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(5693) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"ipv.henley.zosreg.indmem.png","Indiv")+"</li>"
     txt(5694) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"ipv.henley.zosreg.indmemdiff.png","Bias")+"</li>"
     txt(5696) = "</ul></div></td>"
  else
     txt(5690) = "ZOS</td>"
  end if
  txt(5698) = "<td>"+table_link_setup(OUTDIR,"ipv_henley_timeseries_mon.indmem.png","Timeseries")+"</td>"
  txt(5699) = "<td>"+table_link_setup(OUTDIR,"ipv.henley.powspec.indmem.png","Power Spectra")+"</td></tr>"

  txt(5700) = "<tr><td rowspan=3><b>AMOC</b></td><td>"
  if (isfilepresent2(OUTDIR+"amoc.mean.ann.indmem.png")) then
     txt(5701) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#amoc_mean_ann"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"amoc_mean_ann"+quote+">Means</a> " 
     txt(5702) = "<div class="+quote+"collapse"+quote+" id="+quote+"amoc_mean_ann"+quote+">"
     txt(5703) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(5704) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"amoc.mean.ann.indmem.png","Indiv")+"</li>"
     txt(5705) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"amoc.mean.ann.indmemdiff.png","Bias")+"</li>"
     txt(5706) = "</ul></div></td>"
  else
     txt(5701) = "Means</td>"
  end if

  txt(5710) = "<td>"
  if (isfilepresent2(OUTDIR+"amoc.stddev.ann.indmem.png")) then
     txt(5711) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#amoc_stddev_ann"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"amoc_stddev_ann"+quote+">Standard Deviations</a> " 
     txt(5712) = "<div class="+quote+"collapse"+quote+" id="+quote+"amoc_stddev_ann"+quote+">"
     txt(5713) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(5714) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"amoc.stddev.ann.indmem.png","Indiv")+"</li>"
     txt(5715) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"amoc.stddev.ann.indmemdiff.png","Bias")+"</li>"
     txt(5716) = "</ul></div></td>"
  else
     txt(5711) = "Standard Deviations</td>"
  end if

  txt(5720) = "<td>"
  if (isfilepresent2(OUTDIR+"amoc.pattern.ann.indmem.png")) then
     txt(5721) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#amoc_pattern_ann"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"amoc_pattern_ann"+quote+">Patterns</a> " 
     txt(5722) = "<div class="+quote+"collapse"+quote+" id="+quote+"amoc_pattern_ann"+quote+">"
     txt(5723) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(5724) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"amoc.pattern.ann.indmem.png","Indiv")+"</li>"
     txt(5725) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"amoc.pattern.ann.indmemdiff.png","Bias")+"</li>"
     txt(5726) = "</ul></div></td>"
  else
     txt(5721) = "Patterns</td></tr>"
  end if

  txt(5730) = "<tr><td>"+table_link_setup(OUTDIR,"amoc.timeseries.ann.indmem.png","Timeseries")+"</td><td>"
  if (isfilepresent2(OUTDIR+"amoc.tassstreg.ann.indmem.png")) then
     txt(5731) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#amoc_tassstreg_ann"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"amoc_tassstreg_ann"+quote+">SST/TAS Regressions</a> " 
     txt(5732) = "<div class="+quote+"collapse"+quote+" id="+quote+"amoc_tassstreg_ann"+quote+">"
     txt(5733) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(5734) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"amoc.tassstreg.ann.indmem.png","Indiv")+"</li>"
     txt(5735) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"amoc.tassstreg.ann.indmemdiff.png","Bias")+"</li>"
     txt(5736) = "</ul></div></td>"
  else
     txt(5731) = "SST/TAS Regressions</td>"
  end if

  txt(5740) = "<td>"
  if (isfilepresent2(OUTDIR+"amoc.zosreg.ann.indmem.png")) then
     txt(5741) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#amoc_zosreg_ann"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"amoc_zosreg_ann"+quote+">ZOS Regressions</a> " 
     txt(5742) = "<div class="+quote+"collapse"+quote+" id="+quote+"amoc_zosreg_ann"+quote+">"
     txt(5743) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(5744) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"amoc.zosreg.ann.indmem.png","Indiv")+"</li>"
     txt(5745) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"amoc.zosreg.ann.indmemdiff.png","Bias")+"</li>"
     txt(5746) = "</ul></div></td></tr>"
  else
     txt(5741) = "ZOS Regressions</td></tr>"
  end if

  txt(5750) = "<tr><td>"+table_link_setup(OUTDIR,"amoc.powspec.indmem.png","Spectra")+"</td>"
  txt(5751) = "<td colspan=2>"+table_link_setup(OUTDIR,"amoc_amv.leadlag.ann.indmem.png","AMV/AMOC Lag Correlations")+"</td></tr>"
  txt(5799) = "</table></div></div>"


  txt(5800) = "<div class="+quote+"row"+quote+">"
  txt(5801) = "<div class="+quote+"col"+quote+">"
  txt(5802) = "<table class="+quote+"table table-striped table-bordered"+quote+">"
  txt(5803) = "<h3 class="+quote+"display-6"+quote+">Atmospheric Modes of Variability</h3>"

  txt(5809) = "<tr><td rowspan=2><b>SO</b></td>"
  txt(5810) = "<td>Patterns</td><td>"
  if (isfilepresent2(OUTDIR+"so_pattern_djf.indmem.png")) then
     txt(5811) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#so_pattern_djf"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"so_pattern_djf"+quote+">DJF</a>" 
     txt(5812) = "<div class="+quote+"collapse"+quote+" id="+quote+"so_pattern_djf"+quote+">"
     txt(5813) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(5814) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"so_pattern_djf.indmem.png","Indiv")+"</li>"
     txt(5815) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"so_pattern_djf.indmemdiff.png","Bias")+"</li>"
     txt(5817) = "</ul></div></td>"
  else
     txt(5817) = "DJF</td>"
  end if

  txt(5820) = "<td>"
  if (isfilepresent2(OUTDIR+"so_pattern_jfm.indmem.png")) then
     txt(5821) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#so_pattern_jfm"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"so_pattern_jfm"+quote+">JFM</a>" 
     txt(5822) = "<div class="+quote+"collapse"+quote+" id="+quote+"so_pattern_jfm"+quote+">"
     txt(5823) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(5824) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"so_pattern_jfm.indmem.png","Indiv")+"</li>"
     txt(5825) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"so_pattern_jfm.indmemdiff.png","Bias")+"</li>"
     txt(5827) = "</ul></div></td>"
  else
     txt(5827) = "JFM</td>"
  end if

  txt(5830) = "<td>"
  if (isfilepresent2(OUTDIR+"so_pattern_mam.indmem.png")) then
     txt(5831) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#so_pattern_mam"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"so_pattern_mam"+quote+">MAM</a>" 
     txt(5832) = "<div class="+quote+"collapse"+quote+" id="+quote+"so_pattern_mam"+quote+">"
     txt(5833) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(5834) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"so_pattern_mam.indmem.png","Indiv")+"</li>"
     txt(5835) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"so_pattern_mam.indmemdiff.png","Bias")+"</li>"
     txt(5837) = "</ul></div></td>"
  else
     txt(5837) = "MAM</td>"
  end if

  txt(5840) = "<td>"
  if (isfilepresent2(OUTDIR+"so_pattern_jja.indmem.png")) then
     txt(5841) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#so_pattern_jja"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"so_pattern_jja"+quote+">JJA</a>" 
     txt(5842) = "<div class="+quote+"collapse"+quote+" id="+quote+"so_pattern_jja"+quote+">"
     txt(5843) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(5844) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"so_pattern_jja.indmem.png","Indiv")+"</li>"
     txt(5845) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"so_pattern_jja.indmemdiff.png","Bias")+"</li>"
     txt(5847) = "</ul></div></td>"
  else
     txt(5847) = "JJA</td>"
  end if

  txt(5850) = "<td>"
  if (isfilepresent2(OUTDIR+"so_pattern_jas.indmem.png")) then
     txt(5851) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#so_pattern_jas"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"so_pattern_jas"+quote+">JAS</a>" 
     txt(5852) = "<div class="+quote+"collapse"+quote+" id="+quote+"so_pattern_jas"+quote+">"
     txt(5853) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(5854) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"so_pattern_jas.indmem.png","Indiv")+"</li>"
     txt(5855) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"so_pattern_jas.indmemdiff.png","Bias")+"</li>"
     txt(5857) = "</ul></div></td>"
  else
     txt(5857) = "JAS</td>"
  end if

  txt(5860) = "<td>"
  if (isfilepresent2(OUTDIR+"so_pattern_son.indmem.png")) then
     txt(5861) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#so_pattern_son"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"so_pattern_son"+quote+">SON</a>" 
     txt(5862) = "<div class="+quote+"collapse"+quote+" id="+quote+"so_pattern_son"+quote+">"
     txt(5863) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(5864) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"so_pattern_son.indmem.png","Indiv")+"</li>"
     txt(5865) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"so_pattern_son.indmemdiff.png","Bias")+"</li>"
     txt(5867) = "</ul></div></td>"
  else
     txt(5867) = "SON</td>"
  end if

  txt(5870) = "<td>"
  if (isfilepresent2(OUTDIR+"so_pattern_ann.indmem.png")) then
     txt(5871) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#so_pattern_ann"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"so_pattern_ann"+quote+">ANN</a>" 
     txt(5872) = "<div class="+quote+"collapse"+quote+" id="+quote+"so_pattern_ann"+quote+">"
     txt(5873) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(5874) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"so_pattern_ann.indmem.png","Indiv")+"</li>"
     txt(5875) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"so_pattern_ann.indmemdiff.png","Bias")+"</li>"
     txt(5877) = "</ul></div></td></tr>"
  else
     txt(5877) = "ANN</td></tr>"
  end if
  txt(5881) = "<tr><td>Timeseries</td>"
  txt(5882) = "<td>"+table_link_setup(OUTDIR,"so_timeseries_djf.indmem.png","DJF")+"</td>"
  txt(5883) = "<td>"+table_link_setup(OUTDIR,"so_timeseries_jfm.indmem.png","JFM")+"</td>"
  txt(5884) = "<td>"+table_link_setup(OUTDIR,"so_timeseries_mam.indmem.png","MAM")+"</td>"
  txt(5885) = "<td>"+table_link_setup(OUTDIR,"so_timeseries_jja.indmem.png","JJA")+"</td>"
  txt(5886) = "<td>"+table_link_setup(OUTDIR,"so_timeseries_jas.indmem.png","JAS")+"</td>"
  txt(5887) = "<td>"+table_link_setup(OUTDIR,"so_timeseries_son.indmem.png","SON")+"</td>"
  txt(5888) = "<td>"+table_link_setup(OUTDIR,"so_timeseries_ann.indmem.png","ANN")+"</td></tr>"

  txt(5909) = "<tr><td rowspan=2><b>NAM</b></td>"
  txt(5910) = "<td>Patterns</td><td>"
  if (isfilepresent2(OUTDIR+"nam_pattern_djf.indmem.png")) then
     txt(5911) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nam_pattern_djf"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nam_pattern_djf"+quote+">DJF</a>" 
     txt(5912) = "<div class="+quote+"collapse"+quote+" id="+quote+"nam_pattern_djf"+quote+">"
     txt(5913) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(5914) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nam_pattern_djf.indmem.png","Indiv")+"</li>"
     txt(5915) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nam_pattern_djf.indmemdiff.png","Bias")+"</li>"
     txt(5917) = "</ul></div></td>"
  else
     txt(5917) = "DJF</td>"
  end if

  txt(5920) = "<td>"
  if (isfilepresent2(OUTDIR+"nam_pattern_jfm.indmem.png")) then
     txt(5921) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nam_pattern_jfm"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nam_pattern_jfm"+quote+">JFM</a>" 
     txt(5922) = "<div class="+quote+"collapse"+quote+" id="+quote+"nam_pattern_jfm"+quote+">"
     txt(5923) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(5924) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nam_pattern_jfm.indmem.png","Indiv")+"</li>"
     txt(5925) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nam_pattern_jfm.indmemdiff.png","Bias")+"</li>"
     txt(5927) = "</ul></div></td>"
  else
     txt(5927) = "JFM</td>"
  end if

  txt(5930) = "<td>"
  if (isfilepresent2(OUTDIR+"nam_pattern_mam.indmem.png")) then
     txt(5931) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nam_pattern_mam"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nam_pattern_mam"+quote+">MAM</a>" 
     txt(5932) = "<div class="+quote+"collapse"+quote+" id="+quote+"nam_pattern_mam"+quote+">"
     txt(5933) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(5934) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nam_pattern_mam.indmem.png","Indiv")+"</li>"
     txt(5935) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nam_pattern_mam.indmemdiff.png","Bias")+"</li>"
     txt(5937) = "</ul></div></td>"
  else
     txt(5937) = "MAM</td>"
  end if

  txt(5940) = "<td>"
  if (isfilepresent2(OUTDIR+"nam_pattern_jja.indmem.png")) then
     txt(5941) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nam_pattern_jja"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nam_pattern_jja"+quote+">JJA</a>" 
     txt(5942) = "<div class="+quote+"collapse"+quote+" id="+quote+"nam_pattern_jja"+quote+">"
     txt(5943) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(5944) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nam_pattern_jja.indmem.png","Indiv")+"</li>"
     txt(5945) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nam_pattern_jja.indmemdiff.png","Bias")+"</li>"
     txt(5947) = "</ul></div></td>"
  else
     txt(5947) = "JJA</td>"
  end if

  txt(5950) = "<td>"
  if (isfilepresent2(OUTDIR+"nam_pattern_jas.indmem.png")) then
     txt(5951) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nam_pattern_jas"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nam_pattern_jas"+quote+">JAS</a>" 
     txt(5952) = "<div class="+quote+"collapse"+quote+" id="+quote+"nam_pattern_jas"+quote+">"
     txt(5953) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(5954) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nam_pattern_jas.indmem.png","Indiv")+"</li>"
     txt(5955) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nam_pattern_jas.indmemdiff.png","Bias")+"</li>"
     txt(5957) = "</ul></div></td>"
  else
     txt(5957) = "JAS</td>"
  end if

  txt(5960) = "<td>"
  if (isfilepresent2(OUTDIR+"nam_pattern_son.indmem.png")) then
     txt(5961) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nam_pattern_son"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nam_pattern_son"+quote+">SON</a>" 
     txt(5962) = "<div class="+quote+"collapse"+quote+" id="+quote+"nam_pattern_son"+quote+">"
     txt(5963) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(5964) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nam_pattern_son.indmem.png","Indiv")+"</li>"
     txt(5965) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nam_pattern_son.indmemdiff.png","Bias")+"</li>"
     txt(5967) = "</ul></div></td>"
  else
     txt(5967) = "SON</td>"
  end if

  txt(5970) = "<td>"
  if (isfilepresent2(OUTDIR+"nam_pattern_ann.indmem.png")) then
     txt(5971) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nam_pattern_ann"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nam_pattern_ann"+quote+">ANN</a>" 
     txt(5972) = "<div class="+quote+"collapse"+quote+" id="+quote+"nam_pattern_ann"+quote+">"
     txt(5973) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(5974) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nam_pattern_ann.indmem.png","Indiv")+"</li>"
     txt(5975) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nam_pattern_ann.indmemdiff.png","Bias")+"</li>"
     txt(5977) = "</ul></div></td></tr>"
  else
     txt(5977) = "ANN</td></tr>"
  end if
  txt(5981) = "<tr><td>Timeseries</td>"
  txt(5982) = "<td>"+table_link_setup(OUTDIR,"nam_timeseries_djf.indmem.png","DJF")+"</td>"
  txt(5983) = "<td>"+table_link_setup(OUTDIR,"nam_timeseries_jfm.indmem.png","JFM")+"</td>"
  txt(5984) = "<td>"+table_link_setup(OUTDIR,"nam_timeseries_mam.indmem.png","MAM")+"</td>"
  txt(5985) = "<td>"+table_link_setup(OUTDIR,"nam_timeseries_jja.indmem.png","JJA")+"</td>"
  txt(5986) = "<td>"+table_link_setup(OUTDIR,"nam_timeseries_jas.indmem.png","JAS")+"</td>"
  txt(5987) = "<td>"+table_link_setup(OUTDIR,"nam_timeseries_son.indmem.png","SON")+"</td>"
  txt(5988) = "<td>"+table_link_setup(OUTDIR,"nam_timeseries_ann.indmem.png","ANN")+"</td></tr>"

  txt(6109) = "<tr><td rowspan=2><b>NAO</b></td>"
  txt(6110) = "<td>Patterns</td><td>"
  if (isfilepresent2(OUTDIR+"nao_pattern_djf.indmem.png")) then
     txt(6111) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nao_pattern_djf"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nao_pattern_djf"+quote+">DJF</a>" 
     txt(6112) = "<div class="+quote+"collapse"+quote+" id="+quote+"nao_pattern_djf"+quote+">"
     txt(6113) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(6114) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nao_pattern_djf.indmem.png","Indiv")+"</li>"
     txt(6115) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nao_pattern_djf.indmemdiff.png","Bias")+"</li>"
     txt(6117) = "</ul></div></td>"
  else
     txt(6117) = "DJF</td>"
  end if

  txt(6120) = "<td>"
  if (isfilepresent2(OUTDIR+"nao_pattern_jfm.indmem.png")) then
     txt(6121) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nao_pattern_jfm"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nao_pattern_jfm"+quote+">JFM</a>" 
     txt(6122) = "<div class="+quote+"collapse"+quote+" id="+quote+"nao_pattern_jfm"+quote+">"
     txt(6123) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(6124) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nao_pattern_jfm.indmem.png","Indiv")+"</li>"
     txt(6125) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nao_pattern_jfm.indmemdiff.png","Bias")+"</li>"
     txt(6127) = "</ul></div></td>"
  else
     txt(6127) = "JFM</td>"
  end if

  txt(6130) = "<td>"
  if (isfilepresent2(OUTDIR+"nao_pattern_mam.indmem.png")) then
     txt(6131) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nao_pattern_mam"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nao_pattern_mam"+quote+">MAM</a>" 
     txt(6132) = "<div class="+quote+"collapse"+quote+" id="+quote+"nao_pattern_mam"+quote+">"
     txt(6133) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(6134) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nao_pattern_mam.indmem.png","Indiv")+"</li>"
     txt(6135) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nao_pattern_mam.indmemdiff.png","Bias")+"</li>"
     txt(6137) = "</ul></div></td>"
  else
     txt(6137) = "MAM</td>"
  end if

  txt(6140) = "<td>"
  if (isfilepresent2(OUTDIR+"nao_pattern_jja.indmem.png")) then
     txt(6141) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nao_pattern_jja"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nao_pattern_jja"+quote+">JJA</a>" 
     txt(6142) = "<div class="+quote+"collapse"+quote+" id="+quote+"nao_pattern_jja"+quote+">"
     txt(6143) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(6144) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nao_pattern_jja.indmem.png","Indiv")+"</li>"
     txt(6145) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nao_pattern_jja.indmemdiff.png","Bias")+"</li>"
     txt(6147) = "</ul></div></td>"
  else
     txt(6147) = "JJA</td>"
  end if

  txt(6150) = "<td>"
  if (isfilepresent2(OUTDIR+"nao_pattern_jas.indmem.png")) then
     txt(6151) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nao_pattern_jas"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nao_pattern_jas"+quote+">JAS</a>" 
     txt(6152) = "<div class="+quote+"collapse"+quote+" id="+quote+"nao_pattern_jas"+quote+">"
     txt(6153) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(6154) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nao_pattern_jas.indmem.png","Indiv")+"</li>"
     txt(6155) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nao_pattern_jas.indmemdiff.png","Bias")+"</li>"
     txt(6157) = "</ul></div></td>"
  else
     txt(6157) = "JAS</td>"
  end if

  txt(6160) = "<td>"
  if (isfilepresent2(OUTDIR+"nao_pattern_son.indmem.png")) then
     txt(6161) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nao_pattern_son"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nao_pattern_son"+quote+">SON</a>" 
     txt(6162) = "<div class="+quote+"collapse"+quote+" id="+quote+"nao_pattern_son"+quote+">"
     txt(6163) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(6164) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nao_pattern_son.indmem.png","Indiv")+"</li>"
     txt(6165) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nao_pattern_son.indmemdiff.png","Bias")+"</li>"
     txt(6167) = "</ul></div></td>"
  else
     txt(6167) = "SON</td>"
  end if

  txt(6170) = "<td>"
  if (isfilepresent2(OUTDIR+"nao_pattern_ann.indmem.png")) then
     txt(6171) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nao_pattern_ann"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nao_pattern_ann"+quote+">ANN</a>" 
     txt(6172) = "<div class="+quote+"collapse"+quote+" id="+quote+"nao_pattern_ann"+quote+">"
     txt(6173) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(6174) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nao_pattern_ann.indmem.png","Indiv")+"</li>"
     txt(6175) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nao_pattern_ann.indmemdiff.png","Bias")+"</li>"
     txt(6177) = "</ul></div></td></tr>"
  else
     txt(6177) = "ANN</td></tr>"
  end if
  txt(6181) = "<tr><td>Timeseries</td>"
  txt(6182) = "<td>"+table_link_setup(OUTDIR,"nao_timeseries_djf.indmem.png","DJF")+"</td>"
  txt(6183) = "<td>"+table_link_setup(OUTDIR,"nao_timeseries_jfm.indmem.png","JFM")+"</td>"
  txt(6184) = "<td>"+table_link_setup(OUTDIR,"nao_timeseries_mam.indmem.png","MAM")+"</td>"
  txt(6185) = "<td>"+table_link_setup(OUTDIR,"nao_timeseries_jja.indmem.png","JJA")+"</td>"
  txt(6186) = "<td>"+table_link_setup(OUTDIR,"nao_timeseries_jas.indmem.png","JAS")+"</td>"
  txt(6187) = "<td>"+table_link_setup(OUTDIR,"nao_timeseries_son.indmem.png","SON")+"</td>"
  txt(6188) = "<td>"+table_link_setup(OUTDIR,"nao_timeseries_ann.indmem.png","ANN")+"</td></tr>"

  txt(6309) = "<tr><td rowspan=2><b>SAM</b></td>"
  txt(6310) = "<td>Patterns</td><td>"
  if (isfilepresent2(OUTDIR+"sam_pattern_djf.indmem.png")) then
     txt(6311) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#sam_pattern_djf"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"sam_pattern_djf"+quote+">DJF</a>" 
     txt(6312) = "<div class="+quote+"collapse"+quote+" id="+quote+"sam_pattern_djf"+quote+">"
     txt(6313) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(6314) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sam_pattern_djf.indmem.png","Indiv")+"</li>"
     txt(6315) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sam_pattern_djf.indmemdiff.png","Bias")+"</li>"
     txt(6317) = "</ul></div></td>"
  else
     txt(6317) = "DJF</td>"
  end if

  txt(6320) = "<td>"
  if (isfilepresent2(OUTDIR+"sam_pattern_jfm.indmem.png")) then
     txt(6321) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#sam_pattern_jfm"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"sam_pattern_jfm"+quote+">JFM</a>" 
     txt(6322) = "<div class="+quote+"collapse"+quote+" id="+quote+"sam_pattern_jfm"+quote+">"
     txt(6323) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(6324) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sam_pattern_jfm.indmem.png","Indiv")+"</li>"
     txt(6325) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sam_pattern_jfm.indmemdiff.png","Bias")+"</li>"
     txt(6327) = "</ul></div></td>"
  else
     txt(6327) = "JFM</td>"
  end if

  txt(6330) = "<td>"
  if (isfilepresent2(OUTDIR+"sam_pattern_mam.indmem.png")) then
     txt(6331) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#sam_pattern_mam"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"sam_pattern_mam"+quote+">MAM</a>" 
     txt(6332) = "<div class="+quote+"collapse"+quote+" id="+quote+"sam_pattern_mam"+quote+">"
     txt(6333) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(6334) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sam_pattern_mam.indmem.png","Indiv")+"</li>"
     txt(6335) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sam_pattern_mam.indmemdiff.png","Bias")+"</li>"
     txt(6337) = "</ul></div></td>"
  else
     txt(6337) = "MAM</td>"
  end if

  txt(6340) = "<td>"
  if (isfilepresent2(OUTDIR+"sam_pattern_jja.indmem.png")) then
     txt(6341) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#sam_pattern_jja"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"sam_pattern_jja"+quote+">JJA</a>" 
     txt(6342) = "<div class="+quote+"collapse"+quote+" id="+quote+"sam_pattern_jja"+quote+">"
     txt(6343) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(6344) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sam_pattern_jja.indmem.png","Indiv")+"</li>"
     txt(6345) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sam_pattern_jja.indmemdiff.png","Bias")+"</li>"
     txt(6347) = "</ul></div></td>"
  else
     txt(6347) = "JJA</td>"
  end if

  txt(6350) = "<td>"
  if (isfilepresent2(OUTDIR+"sam_pattern_jas.indmem.png")) then
     txt(6351) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#sam_pattern_jas"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"sam_pattern_jas"+quote+">JAS</a>" 
     txt(6352) = "<div class="+quote+"collapse"+quote+" id="+quote+"sam_pattern_jas"+quote+">"
     txt(6353) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(6354) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sam_pattern_jas.indmem.png","Indiv")+"</li>"
     txt(6355) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sam_pattern_jas.indmemdiff.png","Bias")+"</li>"
     txt(6357) = "</ul></div></td>"
  else
     txt(6357) = "JAS</td>"
  end if

  txt(6360) = "<td>"
  if (isfilepresent2(OUTDIR+"sam_pattern_son.indmem.png")) then
     txt(6361) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#sam_pattern_son"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"sam_pattern_son"+quote+">SON</a>" 
     txt(6362) = "<div class="+quote+"collapse"+quote+" id="+quote+"sam_pattern_son"+quote+">"
     txt(6363) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(6364) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sam_pattern_son.indmem.png","Indiv")+"</li>"
     txt(6365) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sam_pattern_son.indmemdiff.png","Bias")+"</li>"
     txt(6367) = "</ul></div></td>"
  else
     txt(6367) = "SON</td>"
  end if

  txt(6370) = "<td>"
  if (isfilepresent2(OUTDIR+"sam_pattern_ann.indmem.png")) then
     txt(6371) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#sam_pattern_ann"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"sam_pattern_ann"+quote+">ANN</a>" 
     txt(6372) = "<div class="+quote+"collapse"+quote+" id="+quote+"sam_pattern_ann"+quote+">"
     txt(6373) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(6374) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sam_pattern_ann.indmem.png","Indiv")+"</li>"
     txt(6375) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"sam_pattern_ann.indmemdiff.png","Bias")+"</li>"
     txt(6377) = "</ul></div></td></tr>"
  else
     txt(6377) = "ANN</td></tr>"
  end if
  txt(6381) = "<tr><td>Timeseries</td>"
  txt(6382) = "<td>"+table_link_setup(OUTDIR,"sam_timeseries_djf.indmem.png","DJF")+"</td>"
  txt(6383) = "<td>"+table_link_setup(OUTDIR,"sam_timeseries_jfm.indmem.png","JFM")+"</td>"
  txt(6384) = "<td>"+table_link_setup(OUTDIR,"sam_timeseries_mam.indmem.png","MAM")+"</td>"
  txt(6385) = "<td>"+table_link_setup(OUTDIR,"sam_timeseries_jja.indmem.png","JJA")+"</td>"
  txt(6386) = "<td>"+table_link_setup(OUTDIR,"sam_timeseries_jas.indmem.png","JAS")+"</td>"
  txt(6387) = "<td>"+table_link_setup(OUTDIR,"sam_timeseries_son.indmem.png","SON")+"</td>"
  txt(6388) = "<td>"+table_link_setup(OUTDIR,"sam_timeseries_ann.indmem.png","ANN")+"</td></tr>"

  txt(6509) = "<tr><td rowspan=2><b>PNA</b></td>"
  txt(6510) = "<td>Patterns</td><td>"
  if (isfilepresent2(OUTDIR+"pna_pattern_djf.indmem.png")) then
     txt(6511) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#pna_pattern_djf"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"pna_pattern_djf"+quote+">DJF</a>" 
     txt(6512) = "<div class="+quote+"collapse"+quote+" id="+quote+"pna_pattern_djf"+quote+">"
     txt(6513) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(6514) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pna_pattern_djf.indmem.png","Indiv")+"</li>"
     txt(6515) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pna_pattern_djf.indmemdiff.png","Bias")+"</li>"
     txt(6517) = "</ul></div></td>"
  else
     txt(6517) = "DJF</td>"
  end if

  txt(6520) = "<td>"
  if (isfilepresent2(OUTDIR+"pna_pattern_jfm.indmem.png")) then
     txt(6521) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#pna_pattern_jfm"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"pna_pattern_jfm"+quote+">JFM</a>" 
     txt(6522) = "<div class="+quote+"collapse"+quote+" id="+quote+"pna_pattern_jfm"+quote+">"
     txt(6523) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(6524) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pna_pattern_jfm.indmem.png","Indiv")+"</li>"
     txt(6525) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pna_pattern_jfm.indmemdiff.png","Bias")+"</li>"
     txt(6527) = "</ul></div></td>"
  else
     txt(6527) = "JFM</td>"
  end if

  txt(6530) = "<td>"
  if (isfilepresent2(OUTDIR+"pna_pattern_mam.indmem.png")) then
     txt(6531) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#pna_pattern_mam"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"pna_pattern_mam"+quote+">MAM</a>" 
     txt(6532) = "<div class="+quote+"collapse"+quote+" id="+quote+"pna_pattern_mam"+quote+">"
     txt(6533) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(6534) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pna_pattern_mam.indmem.png","Indiv")+"</li>"
     txt(6535) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pna_pattern_mam.indmemdiff.png","Bias")+"</li>"
     txt(6537) = "</ul></div></td>"
  else
     txt(6537) = "MAM</td>"
  end if

  txt(6540) = "<td>"
  if (isfilepresent2(OUTDIR+"pna_pattern_jja.indmem.png")) then
     txt(6541) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#pna_pattern_jja"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"pna_pattern_jja"+quote+">JJA</a>" 
     txt(6542) = "<div class="+quote+"collapse"+quote+" id="+quote+"pna_pattern_jja"+quote+">"
     txt(6543) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(6544) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pna_pattern_jja.indmem.png","Indiv")+"</li>"
     txt(6545) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pna_pattern_jja.indmemdiff.png","Bias")+"</li>"
     txt(6547) = "</ul></div></td>"
  else
     txt(6547) = "JJA</td>"
  end if

  txt(6550) = "<td>"
  if (isfilepresent2(OUTDIR+"pna_pattern_jas.indmem.png")) then
     txt(6551) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#pna_pattern_jas"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"pna_pattern_jas"+quote+">JAS</a>" 
     txt(6552) = "<div class="+quote+"collapse"+quote+" id="+quote+"pna_pattern_jas"+quote+">"
     txt(6553) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(6554) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pna_pattern_jas.indmem.png","Indiv")+"</li>"
     txt(6555) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pna_pattern_jas.indmemdiff.png","Bias")+"</li>"
     txt(6557) = "</ul></div></td>"
  else
     txt(6557) = "JAS</td>"
  end if

  txt(6560) = "<td>"
  if (isfilepresent2(OUTDIR+"pna_pattern_son.indmem.png")) then
     txt(6561) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#pna_pattern_son"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"pna_pattern_son"+quote+">SON</a>" 
     txt(6562) = "<div class="+quote+"collapse"+quote+" id="+quote+"pna_pattern_son"+quote+">"
     txt(6563) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(6564) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pna_pattern_son.indmem.png","Indiv")+"</li>"
     txt(6565) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pna_pattern_son.indmemdiff.png","Bias")+"</li>"
     txt(6567) = "</ul></div></td>"
  else
     txt(6567) = "SON</td>"
  end if

  txt(6570) = "<td>"
  if (isfilepresent2(OUTDIR+"pna_pattern_ann.indmem.png")) then
     txt(6571) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#pna_pattern_ann"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"pna_pattern_ann"+quote+">ANN</a>" 
     txt(6572) = "<div class="+quote+"collapse"+quote+" id="+quote+"pna_pattern_ann"+quote+">"
     txt(6573) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(6574) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pna_pattern_ann.indmem.png","Indiv")+"</li>"
     txt(6575) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"pna_pattern_ann.indmemdiff.png","Bias")+"</li>"
     txt(6577) = "</ul></div></td></tr>"
  else
     txt(6577) = "ANN</td></tr>"
  end if
  txt(6581) = "<tr><td>Timeseries</td>"
  txt(6582) = "<td>"+table_link_setup(OUTDIR,"pna_timeseries_djf.indmem.png","DJF")+"</td>"
  txt(6583) = "<td>"+table_link_setup(OUTDIR,"pna_timeseries_jfm.indmem.png","JFM")+"</td>"
  txt(6584) = "<td>"+table_link_setup(OUTDIR,"pna_timeseries_mam.indmem.png","MAM")+"</td>"
  txt(6585) = "<td>"+table_link_setup(OUTDIR,"pna_timeseries_jja.indmem.png","JJA")+"</td>"
  txt(6586) = "<td>"+table_link_setup(OUTDIR,"pna_timeseries_jas.indmem.png","JAS")+"</td>"
  txt(6587) = "<td>"+table_link_setup(OUTDIR,"pna_timeseries_son.indmem.png","SON")+"</td>"
  txt(6588) = "<td>"+table_link_setup(OUTDIR,"pna_timeseries_ann.indmem.png","ANN")+"</td></tr>"

  txt(6709) = "<tr><td rowspan=2><b>NPO</b></td>"
  txt(6710) = "<td>Patterns</td><td>"
  if (isfilepresent2(OUTDIR+"npo_pattern_djf.indmem.png")) then
     txt(6711) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#npo_pattern_djf"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"npo_pattern_djf"+quote+">DJF</a>" 
     txt(6712) = "<div class="+quote+"collapse"+quote+" id="+quote+"npo_pattern_djf"+quote+">"
     txt(6713) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(6714) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"npo_pattern_djf.indmem.png","Indiv")+"</li>"
     txt(6715) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"npo_pattern_djf.indmemdiff.png","Bias")+"</li>"
     txt(6717) = "</ul></div></td>"
  else
     txt(6717) = "DJF</td>"
  end if

  txt(6720) = "<td>"
  if (isfilepresent2(OUTDIR+"npo_pattern_jfm.indmem.png")) then
     txt(6721) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#npo_pattern_jfm"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"npo_pattern_jfm"+quote+">JFM</a>" 
     txt(6722) = "<div class="+quote+"collapse"+quote+" id="+quote+"npo_pattern_jfm"+quote+">"
     txt(6723) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(6724) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"npo_pattern_jfm.indmem.png","Indiv")+"</li>"
     txt(6725) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"npo_pattern_jfm.indmemdiff.png","Bias")+"</li>"
     txt(6727) = "</ul></div></td>"
  else
     txt(6727) = "JFM</td>"
  end if

  txt(6730) = "<td>"
  if (isfilepresent2(OUTDIR+"npo_pattern_mam.indmem.png")) then
     txt(6731) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#npo_pattern_mam"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"npo_pattern_mam"+quote+">MAM</a>" 
     txt(6732) = "<div class="+quote+"collapse"+quote+" id="+quote+"npo_pattern_mam"+quote+">"
     txt(6733) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(6734) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"npo_pattern_mam.indmem.png","Indiv")+"</li>"
     txt(6735) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"npo_pattern_mam.indmemdiff.png","Bias")+"</li>"
     txt(6737) = "</ul></div></td>"
  else
     txt(6737) = "MAM</td>"
  end if

  txt(6740) = "<td>"
  if (isfilepresent2(OUTDIR+"npo_pattern_jja.indmem.png")) then
     txt(6741) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#npo_pattern_jja"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"npo_pattern_jja"+quote+">JJA</a>" 
     txt(6742) = "<div class="+quote+"collapse"+quote+" id="+quote+"npo_pattern_jja"+quote+">"
     txt(6743) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(6744) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"npo_pattern_jja.indmem.png","Indiv")+"</li>"
     txt(6745) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"npo_pattern_jja.indmemdiff.png","Bias")+"</li>"
     txt(6747) = "</ul></div></td>"
  else
     txt(6747) = "JJA</td>"
  end if

  txt(6750) = "<td>"
  if (isfilepresent2(OUTDIR+"npo_pattern_jas.indmem.png")) then
     txt(6751) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#npo_pattern_jas"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"npo_pattern_jas"+quote+">JAS</a>" 
     txt(6752) = "<div class="+quote+"collapse"+quote+" id="+quote+"npo_pattern_jas"+quote+">"
     txt(6753) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(6754) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"npo_pattern_jas.indmem.png","Indiv")+"</li>"
     txt(6755) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"npo_pattern_jas.indmemdiff.png","Bias")+"</li>"
     txt(6757) = "</ul></div></td>"
  else
     txt(6757) = "JAS</td>"
  end if

  txt(6760) = "<td>"
  if (isfilepresent2(OUTDIR+"npo_pattern_son.indmem.png")) then
     txt(6761) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#npo_pattern_son"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"npo_pattern_son"+quote+">SON</a>" 
     txt(6762) = "<div class="+quote+"collapse"+quote+" id="+quote+"npo_pattern_son"+quote+">"
     txt(6763) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(6764) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"npo_pattern_son.indmem.png","Indiv")+"</li>"
     txt(6765) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"npo_pattern_son.indmemdiff.png","Bias")+"</li>"
     txt(6767) = "</ul></div></td>"
  else
     txt(6767) = "SON</td>"
  end if

  txt(6770) = "<td>"
  if (isfilepresent2(OUTDIR+"npo_pattern_ann.indmem.png")) then
     txt(6771) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#npo_pattern_ann"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"npo_pattern_ann"+quote+">ANN</a>" 
     txt(6772) = "<div class="+quote+"collapse"+quote+" id="+quote+"npo_pattern_ann"+quote+">"
     txt(6773) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(6774) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"npo_pattern_ann.indmem.png","Indiv")+"</li>"
     txt(6775) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"npo_pattern_ann.indmemdiff.png","Bias")+"</li>"
     txt(6777) = "</ul></div></td></tr>"
  else
     txt(6777) = "ANN</td></tr>"
  end if
  txt(6781) = "<tr><td>Timeseries</td>"
  txt(6782) = "<td>"+table_link_setup(OUTDIR,"npo_timeseries_djf.indmem.png","DJF")+"</td>"
  txt(6783) = "<td>"+table_link_setup(OUTDIR,"npo_timeseries_jfm.indmem.png","JFM")+"</td>"
  txt(6784) = "<td>"+table_link_setup(OUTDIR,"npo_timeseries_mam.indmem.png","MAM")+"</td>"
  txt(6785) = "<td>"+table_link_setup(OUTDIR,"npo_timeseries_jja.indmem.png","JJA")+"</td>"
  txt(6786) = "<td>"+table_link_setup(OUTDIR,"npo_timeseries_jas.indmem.png","JAS")+"</td>"
  txt(6787) = "<td>"+table_link_setup(OUTDIR,"npo_timeseries_son.indmem.png","SON")+"</td>"
  txt(6788) = "<td>"+table_link_setup(OUTDIR,"npo_timeseries_ann.indmem.png","ANN")+"</td></tr>"

  txt(6909) = "<tr><td rowspan=2><b>PSA1</b></td>"
  txt(6910) = "<td>Patterns</td><td>"
  if (isfilepresent2(OUTDIR+"psa1_pattern_djf.indmem.png")) then
     txt(6911) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#psa1_pattern_djf"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"psa1_pattern_djf"+quote+">DJF</a>" 
     txt(6912) = "<div class="+quote+"collapse"+quote+" id="+quote+"psa1_pattern_djf"+quote+">"
     txt(6913) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(6914) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psa1_pattern_djf.indmem.png","Indiv")+"</li>"
     txt(6915) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psa1_pattern_djf.indmemdiff.png","Bias")+"</li>"
     txt(6917) = "</ul></div></td>"
  else
     txt(6917) = "DJF</td>"
  end if

  txt(6920) = "<td>"
  if (isfilepresent2(OUTDIR+"psa1_pattern_jfm.indmem.png")) then
     txt(6921) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#psa1_pattern_jfm"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"psa1_pattern_jfm"+quote+">JFM</a>" 
     txt(6922) = "<div class="+quote+"collapse"+quote+" id="+quote+"psa1_pattern_jfm"+quote+">"
     txt(6923) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(6924) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psa1_pattern_jfm.indmem.png","Indiv")+"</li>"
     txt(6925) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psa1_pattern_jfm.indmemdiff.png","Bias")+"</li>"
     txt(6927) = "</ul></div></td>"
  else
     txt(6927) = "JFM</td>"
  end if

  txt(6930) = "<td>"
  if (isfilepresent2(OUTDIR+"psa1_pattern_mam.indmem.png")) then
     txt(6931) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#psa1_pattern_mam"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"psa1_pattern_mam"+quote+">MAM</a>" 
     txt(6932) = "<div class="+quote+"collapse"+quote+" id="+quote+"psa1_pattern_mam"+quote+">"
     txt(6933) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(6934) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psa1_pattern_mam.indmem.png","Indiv")+"</li>"
     txt(6935) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psa1_pattern_mam.indmemdiff.png","Bias")+"</li>"
     txt(6937) = "</ul></div></td>"
  else
     txt(6937) = "MAM</td>"
  end if

  txt(6940) = "<td>"
  if (isfilepresent2(OUTDIR+"psa1_pattern_jja.indmem.png")) then
     txt(6941) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#psa1_pattern_jja"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"psa1_pattern_jja"+quote+">JJA</a>" 
     txt(6942) = "<div class="+quote+"collapse"+quote+" id="+quote+"psa1_pattern_jja"+quote+">"
     txt(6943) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(6944) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psa1_pattern_jja.indmem.png","Indiv")+"</li>"
     txt(6945) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psa1_pattern_jja.indmemdiff.png","Bias")+"</li>"
     txt(6947) = "</ul></div></td>"
  else
     txt(6947) = "JJA</td>"
  end if

  txt(6950) = "<td>"
  if (isfilepresent2(OUTDIR+"psa1_pattern_jas.indmem.png")) then
     txt(6951) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#psa1_pattern_jas"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"psa1_pattern_jas"+quote+">JAS</a>" 
     txt(6952) = "<div class="+quote+"collapse"+quote+" id="+quote+"psa1_pattern_jas"+quote+">"
     txt(6953) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(6954) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psa1_pattern_jas.indmem.png","Indiv")+"</li>"
     txt(6955) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psa1_pattern_jas.indmemdiff.png","Bias")+"</li>"
     txt(6957) = "</ul></div></td>"
  else
     txt(6957) = "JAS</td>"
  end if

  txt(6960) = "<td>"
  if (isfilepresent2(OUTDIR+"psa1_pattern_son.indmem.png")) then
     txt(6961) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#psa1_pattern_son"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"psa1_pattern_son"+quote+">SON</a>" 
     txt(6962) = "<div class="+quote+"collapse"+quote+" id="+quote+"psa1_pattern_son"+quote+">"
     txt(6963) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(6964) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psa1_pattern_son.indmem.png","Indiv")+"</li>"
     txt(6965) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psa1_pattern_son.indmemdiff.png","Bias")+"</li>"
     txt(6967) = "</ul></div></td>"
  else
     txt(6967) = "SON</td>"
  end if

  txt(6970) = "<td>"
  if (isfilepresent2(OUTDIR+"psa1_pattern_ann.indmem.png")) then
     txt(6971) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#psa1_pattern_ann"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"psa1_pattern_ann"+quote+">ANN</a>" 
     txt(6972) = "<div class="+quote+"collapse"+quote+" id="+quote+"psa1_pattern_ann"+quote+">"
     txt(6973) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(6974) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psa1_pattern_ann.indmem.png","Indiv")+"</li>"
     txt(6975) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psa1_pattern_ann.indmemdiff.png","Bias")+"</li>"
     txt(6977) = "</ul></div></td></tr>"
  else
     txt(6977) = "ANN</td></tr>"
  end if
  txt(6981) = "<tr><td>Timeseries</td>"
  txt(6982) = "<td>"+table_link_setup(OUTDIR,"psa1_timeseries_djf.indmem.png","DJF")+"</td>"
  txt(6983) = "<td>"+table_link_setup(OUTDIR,"psa1_timeseries_jfm.indmem.png","JFM")+"</td>"
  txt(6984) = "<td>"+table_link_setup(OUTDIR,"psa1_timeseries_mam.indmem.png","MAM")+"</td>"
  txt(6985) = "<td>"+table_link_setup(OUTDIR,"psa1_timeseries_jja.indmem.png","JJA")+"</td>"
  txt(6986) = "<td>"+table_link_setup(OUTDIR,"psa1_timeseries_jas.indmem.png","JAS")+"</td>"
  txt(6987) = "<td>"+table_link_setup(OUTDIR,"psa1_timeseries_son.indmem.png","SON")+"</td>"
  txt(6988) = "<td>"+table_link_setup(OUTDIR,"psa1_timeseries_ann.indmem.png","ANN")+"</td></tr>"

  txt(7109) = "<tr><td rowspan=2><b>PSA2</b></td>"
  txt(7110) = "<td>Patterns</td><td>"
  if (isfilepresent2(OUTDIR+"psa2_pattern_djf.indmem.png")) then
     txt(7111) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#psa2_pattern_djf"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"psa2_pattern_djf"+quote+">DJF</a>" 
     txt(7112) = "<div class="+quote+"collapse"+quote+" id="+quote+"psa2_pattern_djf"+quote+">"
     txt(7113) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(7114) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psa2_pattern_djf.indmem.png","Indiv")+"</li>"
     txt(7115) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psa2_pattern_djf.indmemdiff.png","Bias")+"</li>"
     txt(7117) = "</ul></div></td>"
  else
     txt(7117) = "DJF</td>"
  end if

  txt(7120) = "<td>"
  if (isfilepresent2(OUTDIR+"psa2_pattern_jfm.indmem.png")) then
     txt(7121) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#psa2_pattern_jfm"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"psa2_pattern_jfm"+quote+">JFM</a>" 
     txt(7122) = "<div class="+quote+"collapse"+quote+" id="+quote+"psa2_pattern_jfm"+quote+">"
     txt(7123) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(7124) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psa2_pattern_jfm.indmem.png","Indiv")+"</li>"
     txt(7125) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psa2_pattern_jfm.indmemdiff.png","Bias")+"</li>"
     txt(7127) = "</ul></div></td>"
  else
     txt(7127) = "JFM</td>"
  end if

  txt(7130) = "<td>"
  if (isfilepresent2(OUTDIR+"psa2_pattern_mam.indmem.png")) then
     txt(7131) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#psa2_pattern_mam"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"psa2_pattern_mam"+quote+">MAM</a>" 
     txt(7132) = "<div class="+quote+"collapse"+quote+" id="+quote+"psa2_pattern_mam"+quote+">"
     txt(7133) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(7134) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psa2_pattern_mam.indmem.png","Indiv")+"</li>"
     txt(7135) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psa2_pattern_mam.indmemdiff.png","Bias")+"</li>"
     txt(7137) = "</ul></div></td>"
  else
     txt(7137) = "MAM</td>"
  end if

  txt(7140) = "<td>"
  if (isfilepresent2(OUTDIR+"psa2_pattern_jja.indmem.png")) then
     txt(7141) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#psa2_pattern_jja"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"psa2_pattern_jja"+quote+">JJA</a>" 
     txt(7142) = "<div class="+quote+"collapse"+quote+" id="+quote+"psa2_pattern_jja"+quote+">"
     txt(7143) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(7144) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psa2_pattern_jja.indmem.png","Indiv")+"</li>"
     txt(7145) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psa2_pattern_jja.indmemdiff.png","Bias")+"</li>"
     txt(7147) = "</ul></div></td>"
  else
     txt(7147) = "JJA</td>"
  end if

  txt(7150) = "<td>"
  if (isfilepresent2(OUTDIR+"psa2_pattern_jas.indmem.png")) then
     txt(7151) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#psa2_pattern_jas"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"psa2_pattern_jas"+quote+">JAS</a>" 
     txt(7152) = "<div class="+quote+"collapse"+quote+" id="+quote+"psa2_pattern_jas"+quote+">"
     txt(7153) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(7154) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psa2_pattern_jas.indmem.png","Indiv")+"</li>"
     txt(7155) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psa2_pattern_jas.indmemdiff.png","Bias")+"</li>"
     txt(7157) = "</ul></div></td>"
  else
     txt(7157) = "JAS</td>"
  end if

  txt(7160) = "<td>"
  if (isfilepresent2(OUTDIR+"psa2_pattern_son.indmem.png")) then
     txt(7161) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#psa2_pattern_son"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"psa2_pattern_son"+quote+">SON</a>" 
     txt(7162) = "<div class="+quote+"collapse"+quote+" id="+quote+"psa2_pattern_son"+quote+">"
     txt(7163) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(7164) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psa2_pattern_son.indmem.png","Indiv")+"</li>"
     txt(7165) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psa2_pattern_son.indmemdiff.png","Bias")+"</li>"
     txt(7167) = "</ul></div></td>"
  else
     txt(7167) = "SON</td>"
  end if

  txt(7170) = "<td>"
  if (isfilepresent2(OUTDIR+"psa2_pattern_ann.indmem.png")) then
     txt(7171) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#psa2_pattern_ann"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"psa2_pattern_ann"+quote+">ANN</a>" 
     txt(7172) = "<div class="+quote+"collapse"+quote+" id="+quote+"psa2_pattern_ann"+quote+">"
     txt(7173) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(7174) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psa2_pattern_ann.indmem.png","Indiv")+"</li>"
     txt(7175) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"psa2_pattern_ann.indmemdiff.png","Bias")+"</li>"
     txt(7177) = "</ul></div></td></tr>"
  else
     txt(7177) = "ANN</td></tr>"
  end if
  txt(7181) = "<tr><td>Timeseries</td>"
  txt(7182) = "<td>"+table_link_setup(OUTDIR,"psa2_timeseries_djf.indmem.png","DJF")+"</td>"
  txt(7183) = "<td>"+table_link_setup(OUTDIR,"psa2_timeseries_jfm.indmem.png","JFM")+"</td>"
  txt(7184) = "<td>"+table_link_setup(OUTDIR,"psa2_timeseries_mam.indmem.png","MAM")+"</td>"
  txt(7185) = "<td>"+table_link_setup(OUTDIR,"psa2_timeseries_jja.indmem.png","JJA")+"</td>"
  txt(7186) = "<td>"+table_link_setup(OUTDIR,"psa2_timeseries_jas.indmem.png","JAS")+"</td>"
  txt(7187) = "<td>"+table_link_setup(OUTDIR,"psa2_timeseries_son.indmem.png","SON")+"</td>"
  txt(7188) = "<td>"+table_link_setup(OUTDIR,"psa2_timeseries_ann.indmem.png","ANN")+"</td></tr>"
  txt(7500) = "</table></div></div>"

  txt(16000) = "<div class="+quote+"row"+quote+">"
  txt(16001) = "<div class="+quote+"col"+quote+">"
  txt(16002) = "<table class="+quote+"table table-striped table-bordered"+quote+">"
  txt(16003) = "<h3 class="+quote+"display-6"+quote+">Global Timeseries</h3>"

  txt(16010) = "<tr class="+quote+"d-flex"+quote+">"
  txt(16011) = "<td class="+quote+"col"+quote+"><b>SST</b></td>"
  txt(16012) = "<td class="+quote+"col"+quote+">"+table_link_setup(OUTDIR,"sst_global_avg_djf.indmem.png","DJF")+"</td>"
  txt(16013) = "<td class="+quote+"col"+quote+">"+table_link_setup(OUTDIR,"sst_global_avg_jfm.indmem.png","JFM")+"</td>"
  txt(16014) = "<td class="+quote+"col"+quote+">"+table_link_setup(OUTDIR,"sst_global_avg_mam.indmem.png","MAM")+"</td>"
  txt(16015) = "<td class="+quote+"col"+quote+">"+table_link_setup(OUTDIR,"sst_global_avg_jja.indmem.png","JJA")+"</td>"
  txt(16016) = "<td class="+quote+"col"+quote+">"+table_link_setup(OUTDIR,"sst_global_avg_jas.indmem.png","JAS")+"</td>"
  txt(16017) = "<td class="+quote+"col"+quote+">"+table_link_setup(OUTDIR,"sst_global_avg_son.indmem.png","SON")+"</td>"
  txt(16018) = "<td class="+quote+"col"+quote+">"+table_link_setup(OUTDIR,"sst_global_avg_ann.indmem.png","ANN")+"</td>"
  txt(16019) = "</tr>"

  txt(16020) = "<tr class="+quote+"d-flex"+quote+">"
  txt(16021) = "<td class="+quote+"col"+quote+"><b>TAS</b></td>"
  txt(16022) = "<td class="+quote+"col"+quote+">"+table_link_setup(OUTDIR,"tas_global_avg_djf.indmem.png","DJF")+"</td>"
  txt(16023) = "<td class="+quote+"col"+quote+">"+table_link_setup(OUTDIR,"tas_global_avg_jfm.indmem.png","JFM")+"</td>"
  txt(16024) = "<td class="+quote+"col"+quote+">"+table_link_setup(OUTDIR,"tas_global_avg_mam.indmem.png","MAM")+"</td>"
  txt(16025) = "<td class="+quote+"col"+quote+">"+table_link_setup(OUTDIR,"tas_global_avg_jja.indmem.png","JJA")+"</td>"
  txt(16026) = "<td class="+quote+"col"+quote+">"+table_link_setup(OUTDIR,"tas_global_avg_jas.indmem.png","JAS")+"</td>"
  txt(16027) = "<td class="+quote+"col"+quote+">"+table_link_setup(OUTDIR,"tas_global_avg_son.indmem.png","SON")+"</td>"
  txt(16028) = "<td class="+quote+"col"+quote+">"+table_link_setup(OUTDIR,"tas_global_avg_ann.indmem.png","ANN")+"</td>"
  txt(16029) = "</tr>"

  txt(16040) = "<tr class="+quote+"d-flex"+quote+">"
  txt(16041) = "<td class="+quote+"col"+quote+"><b>PR</b></td>"
  txt(16042) = "<td class="+quote+"col"+quote+">"+table_link_setup(OUTDIR,"pr_global_avg_djf.indmem.png","DJF")+"</td>"
  txt(16043) = "<td class="+quote+"col"+quote+">"+table_link_setup(OUTDIR,"pr_global_avg_jfm.indmem.png","JFM")+"</td>"
  txt(16044) = "<td class="+quote+"col"+quote+">"+table_link_setup(OUTDIR,"pr_global_avg_mam.indmem.png","MAM")+"</td>"
  txt(16045) = "<td class="+quote+"col"+quote+">"+table_link_setup(OUTDIR,"pr_global_avg_jja.indmem.png","JJA")+"</td>"
  txt(16046) = "<td class="+quote+"col"+quote+">"+table_link_setup(OUTDIR,"pr_global_avg_jas.indmem.png","JAS")+"</td>"
  txt(16047) = "<td class="+quote+"col"+quote+">"+table_link_setup(OUTDIR,"pr_global_avg_son.indmem.png","SON")+"</td>"
  txt(16048) = "<td class="+quote+"col"+quote+">"+table_link_setup(OUTDIR,"pr_global_avg_ann.indmem.png","ANN")+"</td>"
  txt(16049) = "</tr>"
  txt(16050) = "<tr class="+quote+"d-flex"+quote+">"
  txt(16051) = "<td class="+quote+"col"+quote+"><b>PR<br>(land-only)</b></td>"
  txt(16052) = "<td class="+quote+"col"+quote+">"+table_link_setup(OUTDIR,"pr_global_avg_land_djf.indmem.png","DJF")+"</td>"
  txt(16053) = "<td class="+quote+"col"+quote+">"+table_link_setup(OUTDIR,"pr_global_avg_land_jfm.indmem.png","JFM")+"</td>"
  txt(16054) = "<td class="+quote+"col"+quote+">"+table_link_setup(OUTDIR,"pr_global_avg_land_mam.indmem.png","MAM")+"</td>"
  txt(16055) = "<td class="+quote+"col"+quote+">"+table_link_setup(OUTDIR,"pr_global_avg_land_jja.indmem.png","JJA")+"</td>"
  txt(16056) = "<td class="+quote+"col"+quote+">"+table_link_setup(OUTDIR,"pr_global_avg_land_jas.indmem.png","JAS")+"</td>"
  txt(16057) = "<td class="+quote+"col"+quote+">"+table_link_setup(OUTDIR,"pr_global_avg_land_son.indmem.png","SON")+"</td>"
  txt(16058) = "<td class="+quote+"col"+quote+">"+table_link_setup(OUTDIR,"pr_global_avg_land_ann.indmem.png","ANN")+"</td>"
  txt(16059) = "</tr>"
  txt(16077) = "</tr></table></div></div>"



  txt(17500) = "<div class="+quote+"row"+quote+">"
  txt(17501) = "<div class="+quote+"col"+quote+">"
  txt(17502) = "<table class="+quote+"table table-striped table-bordered"+quote+">"
  txt(17503) = "<h3 class="+quote+"display-6"+quote+">Regional Timeseries</h3>"
  txt(17504) = "<tr class="+quote+"d-flex"+quote+">"
  txt(17510) = "<td class="+quote+"col"+quote+"><b>Atlantic SST Meridional Mode</b><br>"+table_link_setup(OUTDIR,"atlantic_meridional_mode.timeseries.indmem.png","Timeseries")+" &nbsp;"
  if (isfilepresent2(OUTDIR+"atlantic_meridional_mode_pattern.indmem.png")) then
     txt(17511) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#amm_pattern"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"amm_pattern"+quote+">Patterns</a>" 
     txt(17512) = "<div class="+quote+"collapse"+quote+" id="+quote+"amm_pattern"+quote+">"
     txt(17513) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(17514) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"atlantic_meridional_mode_pattern.indmem.png","Indiv")+"</li>"
     txt(17515) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"atlantic_meridional_mode_pattern.indmemdiff.png","Bias")+"</li>"
     txt(17516) = "</ul></div></td>"
  else
     txt(17516) = "Patterns</td>"
  end if  

  txt(17520) = "<td class="+quote+"col"+quote+"><b>Atlantic Ni&ntilde;o SST</b><br>"+table_link_setup(OUTDIR,"atlantic_nino.timeseries.indmem.png","Timeseries")+" &nbsp;"
  if (isfilepresent2(OUTDIR+"atlantic_nino_pattern.indmem.png")) then
     txt(17521) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#atln_pattern"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"atln_pattern"+quote+">Patterns</a>" 
     txt(17522) = "<div class="+quote+"collapse"+quote+" id="+quote+"atln_pattern"+quote+">"
     txt(17523) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(17524) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"atlantic_nino_pattern.indmem.png","Indiv")+"</li>"
     txt(17525) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"atlantic_nino_pattern.indmemdiff.png","Bias")+"</li>"
     txt(17526) = "</ul></div></td>"
  else
     txt(17526) = "Patterns</td>"
  end if  

  txt(17530) = "<td class="+quote+"col"+quote+"><b>North Atlantic SST</b><br>"+table_link_setup(OUTDIR,"north_atlantic.timeseries.indmem.png","Timeseries")+" &nbsp;"
  if (isfilepresent2(OUTDIR+"north_atlantic_pattern.indmem.png")) then
     txt(17531) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#natl_pattern"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"natl_pattern"+quote+">Patterns</a>" 
     txt(17532) = "<div class="+quote+"collapse"+quote+" id="+quote+"natl_pattern"+quote+">"
     txt(17533) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(17534) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"north_atlantic_pattern.indmem.png","Indiv")+"</li>"
     txt(17535) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"north_atlantic_pattern.indmemdiff.png","Bias")+"</li>"
     txt(17536) = "</ul></div></td>"
  else
     txt(17536) = "Patterns</td>"
  end if  

  txt(17540) = "<td class="+quote+"col"+quote+"><b>Tropical North Atlantic SST</b><br>"+table_link_setup(OUTDIR,"north_tropical_atlantic.timeseries.indmem.png","Timeseries")+" &nbsp;"
  if (isfilepresent2(OUTDIR+"north_tropical_atlantic_pattern.indmem.png")) then
     txt(17541) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nta_pattern"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nta_pattern"+quote+">Patterns</a>" 
     txt(17542) = "<div class="+quote+"collapse"+quote+" id="+quote+"nta_pattern"+quote+">"
     txt(17543) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(17544) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"north_tropical_atlantic_pattern.indmem.png","Indiv")+"</li>"
     txt(17545) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"north_tropical_atlantic_pattern.indmemdiff.png","Bias")+"</li>"
     txt(17546) = "</ul></div></td>"
  else
     txt(17546) = "Patterns</td>"
  end if  

  txt(17550) = "<td class="+quote+"col"+quote+"><b>Tropical South Atlantic SST</b><br>"+table_link_setup(OUTDIR,"south_tropical_atlantic.timeseries.indmem.png","Timeseries")+" &nbsp;"
  if (isfilepresent2(OUTDIR+"south_tropical_atlantic_pattern.indmem.png")) then
     txt(17551) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#sta_pattern"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"sta_pattern"+quote+">Patterns</a>" 
     txt(17552) = "<div class="+quote+"collapse"+quote+" id="+quote+"sta_pattern"+quote+">"
     txt(17553) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(17554) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"south_tropical_atlantic_pattern.indmem.png","Indiv")+"</li>"
     txt(17555) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"south_tropical_atlantic_pattern.indmemdiff.png","Bias")+"</li>"
     txt(17556) = "</ul></div></td></tr>"
  else
     txt(17556) = "Patterns</td></tr>"
  end if  

  txt(17560) = "<tr class="+quote+"d-flex"+quote+"><td class="+quote+"col"+quote+"><b>ni&ntilde;o1+2 SST</b><br>"+table_link_setup(OUTDIR,"nino12.timeseries.indmem.png","Timeseries")+"&nbsp; "
  if (isfilepresent2(OUTDIR+"nino12_pattern.indmem.png")) then
     txt(17561) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nino12_pattern"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nino12_pattern"+quote+">Patterns</a>" 
     txt(17562) = "<div class="+quote+"collapse"+quote+" id="+quote+"nino12_pattern"+quote+">"
     txt(17563) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(17564) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino12_pattern.indmem.png","Indiv")+"</li>"
     txt(17565) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino12_pattern.indmemdiff.png","Bias")+"</li>"
     txt(17566) = "</ul></div></td>"
  else
     txt(17566) = "Patterns</td>"
  end if  

  txt(17570) = "<td class="+quote+"col"+quote+"><b>ni&ntilde;o3 SST</b><br>"+table_link_setup(OUTDIR,"nino3.timeseries.indmem.png","Timeseries")+" &nbsp;"
  if (isfilepresent2(OUTDIR+"nino3_pattern.indmem.png")) then
     txt(17571) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nino3_pattern"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nino3_pattern"+quote+">Patterns</a>" 
     txt(17572) = "<div class="+quote+"collapse"+quote+" id="+quote+"nino3_pattern"+quote+">"
     txt(17573) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(17574) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino3_pattern.indmem.png","Indiv")+"</li>"
     txt(17575) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino3_pattern.indmemdiff.png","Bias")+"</li>"
     txt(17576) = "</ul></div></td>"
  else
     txt(17576) = "Patterns</td>"
  end if  

  txt(17580) = "<td class="+quote+"col"+quote+"><b>ni&ntilde;o3.4 SST</b><br>"+table_link_setup(OUTDIR,"nino34.timeseries.indmem.png","Timeseries")+" &nbsp;"
  if (isfilepresent2(OUTDIR+"nino34_pattern.indmem.png")) then
     txt(17581) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nino34_pattern"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nino34_pattern"+quote+">Patterns</a>" 
     txt(17582) = "<div class="+quote+"collapse"+quote+" id="+quote+"nino34_pattern"+quote+">"
     txt(17583) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(17584) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34_pattern.indmem.png","Indiv")+"</li>"
     txt(17585) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino34_pattern.indmemdiff.png","Bias")+"</li>"
     txt(17586) = "</ul></div></td>"
  else
     txt(17586) = "Patterns</td>"
  end if  

  txt(17590) = "<td class="+quote+"col"+quote+"><b>ni&ntilde;o4 SST</b><br>"+table_link_setup(OUTDIR,"nino4.timeseries.indmem.png","Timeseries")+" &nbsp;"
  if (isfilepresent2(OUTDIR+"nino4_pattern.indmem.png")) then
     txt(17591) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#nino4_pattern"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"nino4_pattern"+quote+">Patterns</a>" 
     txt(17592) = "<div class="+quote+"collapse"+quote+" id="+quote+"nino4_pattern"+quote+">"
     txt(17593) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(17594) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino4_pattern.indmem.png","Indiv")+"</li>"
     txt(17595) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"nino4_pattern.indmemdiff.png","Bias")+"</li>"
     txt(17596) = "</ul></div></td></tr>"
  else
     txt(17596) = "Patterns</td></tr>"
  end if  
  txt(17600) = "<tr class="+quote+"d-flex"+quote+"><td class="+quote+"col"+quote+"><b>North Pacific PSL Index (NPI)</b><br>"+table_link_setup(OUTDIR,"north_pacific_index_ndjfm.indmem.png","Timeseries")+" &nbsp;"
  if (isfilepresent2(OUTDIR+"north_pacific_index_pattern_ndjfm.indmem.png")) then
     txt(17601) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#npi_pattern"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"npi_pattern"+quote+">Patterns</a>" 
     txt(17602) = "<div class="+quote+"collapse"+quote+" id="+quote+"npi_pattern"+quote+">"
     txt(17603) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(17604) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"north_pacific_index_pattern_ndjfm.indmem.png","Indiv")+"</li>"
     txt(17605) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"north_pacific_index_pattern_ndjfm.indmemdiff.png","Bias")+"</li>"
     txt(17606) = "</ul></div></td>"
  else
     txt(17606) = "Patterns</td>"
  end if  
  txt(17610) = "<td class="+quote+"col"+quote+"><b>North Pacific SST Meridional Mode</b><br>"+table_link_setup(OUTDIR,"north_pacific_meridional_mode.timeseries.indmem.png","Timeseries")+" &nbsp;"
  if (isfilepresent2(OUTDIR+"north_pacific_meridional_mode_pattern.indmem.png")) then
     txt(17611) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#npmm_pattern"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"npmm_pattern"+quote+">Patterns</a>" 
     txt(17612) = "<div class="+quote+"collapse"+quote+" id="+quote+"npmm_pattern"+quote+">"
     txt(17613) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(17614) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"north_pacific_meridional_mode_pattern.indmem.png","Indiv")+"</li>"
     txt(17615) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"north_pacific_meridional_mode_pattern.indmemdiff.png","Bias")+"</li>"
     txt(17616) = "</ul></div></td>"
  else
     txt(17616) = "Patterns</td>"
  end if  
  txt(17620) = "<td class="+quote+"col"+quote+"><b>South Pacific SST Meridional Mode</b><br>"+table_link_setup(OUTDIR,"south_pacific_meridional_mode.timeseries.indmem.png","Timeseries")+" &nbsp;"
  if (isfilepresent2(OUTDIR+"south_pacific_meridional_mode_pattern.indmem.png")) then
     txt(17621) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#spmm_pattern"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"spmm_pattern"+quote+">Patterns</a>" 
     txt(17622) = "<div class="+quote+"collapse"+quote+" id="+quote+"spmm_pattern"+quote+">"
     txt(17623) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(17624) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"south_pacific_meridional_mode_pattern.indmem.png","Indiv")+"</li>"
     txt(17625) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"south_pacific_meridional_mode_pattern.indmemdiff.png","Bias")+"</li>"
     txt(17626) = "</ul></div></td></tr>"
  else
     txt(17626) = "Patterns</td></tr>"
  end if  
  txt(17630) = "<tr class="+quote+"d-flex"+quote+"><td class="+quote+"col"+quote+"><b>Indian Ocean SST Dipole</b><br>"+table_link_setup(OUTDIR,"indian_ocean_dipole.timeseries.indmem.png","Timeseries")+" &nbsp;"
  if (isfilepresent2(OUTDIR+"indian_ocean_dipole_pattern.indmem.png")) then
     txt(17631) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#iod_pattern"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"iod_pattern"+quote+">Patterns</a>" 
     txt(17632) = "<div class="+quote+"collapse"+quote+" id="+quote+"iod_pattern"+quote+">"
     txt(17633) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(17634) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"indian_ocean_dipole_pattern.indmem.png","Indiv")+"</li>"
     txt(17635) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"indian_ocean_dipole_pattern.indmemdiff.png","Bias")+"</li>"
     txt(17636) = "</ul></div></td>"
  else
     txt(17636) = "Patterns</td>"
  end if  
  txt(17640) = "<td class="+quote+"col"+quote+"><b>Tropical Indian Ocean SST</b><br>"+table_link_setup(OUTDIR,"tropical_indian_ocean.timeseries.indmem.png","Timeseries")+" &nbsp;"
  if (isfilepresent2(OUTDIR+"tropical_indian_ocean_pattern.indmem.png")) then
     txt(17641) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#tio_pattern"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"tio_pattern"+quote+">Patterns</a>" 
     txt(17642) = "<div class="+quote+"collapse"+quote+" id="+quote+"tio_pattern"+quote+">"
     txt(17643) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(17644) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"tropical_indian_ocean_pattern.indmem.png","Indiv")+"</li>"
     txt(17645) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"tropical_indian_ocean_pattern.indmemdiff.png","Bias")+"</li>"
     txt(17646) = "</ul></div></td>"
  else
     txt(17646) = "Patterns</td>"
  end if  
  txt(17650) = "<td class="+quote+"col"+quote+"><b>Southern Ocean SST</b><br>"+table_link_setup(OUTDIR,"southern_ocean.timeseries.indmem.png","Timeseries")+" &nbsp;"
  if (isfilepresent2(OUTDIR+"southern_ocean_pattern.indmem.png")) then
     txt(17651) = "<a class="+quote+"collapse-link"+quote+" data-toggle="+quote+"collapse"+quote+" href="+quote+"#so_pattern"+quote+" role="+quote+"button"+quote+" aria-expanded="+quote+"false"+quote+" aria-controls="+quote+"so_pattern"+quote+">Patterns</a>" 
     txt(17652) = "<div class="+quote+"collapse"+quote+" id="+quote+"so_pattern"+quote+">"
     txt(17653) = "<ul class="+quote+"list-inline my-0"+quote+">"
     txt(17654) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"southern_ocean_pattern.indmem.png","Indiv")+"</li>"
     txt(17655) = "<li class="+quote+"list-inline-item"+quote+">"+table_link_setup_le(OUTDIR,"southern_ocean_pattern.indmemdiff.png","Bias")+"</li>"
     txt(17656) = "</ul></div></td></tr>"
  else
     txt(17656) = "Patterns</td></tr>"
  end if  
  txt(17660) = "</table></div></div>"

  txt(18700) = "<div class="+quote+"row"+quote+">"
  txt(18701) = "<div class="+quote+"col"+quote+">"
  txt(18702) = "<table class="+quote+"table table-striped table-bordered"+quote+">"
  txt(18703) = "<h3 class="+quote+"display-6"+quote+">Sea Ice Extent Timeseries</h3>"
  txt(18705) = "<tr><td rowspan=2><b>NH</b></td>"
  txt(18706) = "<td>"+table_link_setup(OUTDIR,"siconc_nh_extent_djf.indmem.png","DJF")+"</td>"
  txt(18707) = "<td>"+table_link_setup(OUTDIR,"siconc_nh_extent_jfm.indmem.png","JFM")+"</td>"
  txt(18708) = "<td>"+table_link_setup(OUTDIR,"siconc_nh_extent_mam.indmem.png","MAM")+"</td>"
  txt(18709) = "<td>"+table_link_setup(OUTDIR,"siconc_nh_extent_jja.indmem.png","JJA")+"</td>"
  txt(18710) = "<td>"+table_link_setup(OUTDIR,"siconc_nh_extent_jas.indmem.png","JAS")+"</td>"
  txt(18711) = "<td>"+table_link_setup(OUTDIR,"siconc_nh_extent_son.indmem.png","SON")+"</td>"
  txt(18712) = "<td>"+table_link_setup(OUTDIR,"siconc_nh_extent_ann.indmem.png","ANN")+"</td></tr>"
  txt(18716) = "<tr><td>"+table_link_setup(OUTDIR,"siconc_nh_extent_feb.indmem.png","Feb")+"</td>"
  txt(18717) = "<td>"+table_link_setup(OUTDIR,"siconc_nh_extent_mar.indmem.png","Mar")+"</td>"
  txt(18718) = "<td>"+table_link_setup(OUTDIR,"siconc_nh_extent_sep.indmem.png","Sep")+"</td>"
  txt(18719) = "<td>"+table_link_setup(OUTDIR,"siconc_nh_extent_oct.indmem.png","Oct")+"</td>"
  txt(18720) = "<td>"+table_link_setup(OUTDIR,"siconc_nh_extent_mon.indmem.png","Monthly")+"</td>"
  txt(18721) = "<td>"+table_link_setup(OUTDIR,"siconc_nh_extent_anom_mon.indmem.png","Monthly Anomalies")+"</td>"
  txt(18722) = "<td>"+table_link_setup(OUTDIR,"siconc_nh_extent.climo.indmem.png","Climatology")+"</td></tr>"
  txt(18725) = "<tr><td rowspan=2><b>SH</b></td>"
  txt(18726) = "<td>"+table_link_setup(OUTDIR,"siconc_sh_extent_djf.indmem.png","DJF")+"</td>"
  txt(18727) = "<td>"+table_link_setup(OUTDIR,"siconc_sh_extent_jfm.indmem.png","JFM")+"</td>"
  txt(18728) = "<td>"+table_link_setup(OUTDIR,"siconc_sh_extent_mam.indmem.png","MAM")+"</td>"
  txt(18729) = "<td>"+table_link_setup(OUTDIR,"siconc_sh_extent_jja.indmem.png","JJA")+"</td>"
  txt(18730) = "<td>"+table_link_setup(OUTDIR,"siconc_sh_extent_jas.indmem.png","JAS")+"</td>"
  txt(18731) = "<td>"+table_link_setup(OUTDIR,"siconc_sh_extent_son.indmem.png","SON")+"</td>"
  txt(18732) = "<td>"+table_link_setup(OUTDIR,"siconc_sh_extent_ann.indmem.png","ANN")+"</td></tr>"
  txt(18736) = "<tr><td>"+table_link_setup(OUTDIR,"siconc_sh_extent_feb.indmem.png","Feb")+"</td>"
  txt(18737) = "<td>"+table_link_setup(OUTDIR,"siconc_sh_extent_mar.indmem.png","Mar")+"</td>"
  txt(18738) = "<td>"+table_link_setup(OUTDIR,"siconc_sh_extent_sep.indmem.png","Sep")+"</td>"
  txt(18739) = "<td>"+table_link_setup(OUTDIR,"siconc_sh_extent_oct.indmem.png","Oct")+"</td>"
  txt(18740) = "<td>"+table_link_setup(OUTDIR,"siconc_sh_extent_mon.indmem.png","Monthly")+"</td>"
  txt(18741) = "<td>"+table_link_setup(OUTDIR,"siconc_sh_extent_anom_mon.indmem.png","Monthly Anomalies")+"</td>"
  txt(18742) = "<td>"+table_link_setup(OUTDIR,"siconc_sh_extent.climo.indmem.png","Climatology")+"</td></tr>"
  txt(18743) = "</table></div></div>"

  txt(19000) = "</div></body></html>"

  tt := ind(.not.ismissing(txt))
  txt2 := txt(:tt(dimsizes(tt)-1)+1)
  tt2 := ind(.not.ismissing(txt2))
  txt3 := txt2(tt2)
  asciiwrite(OUTDIR+"index.html",txt3)
  delete([/txt,tt,tt2,txt2,txt3/])
;----------------------------------------------------------------------------
; Namelist pages
  txt := new(500,"string")  
  
  txt(0) = "<HTML><HEAD><TITLE>Climate Variability Diagnostics Package</TITLE><STYLE>"
  txt(1) = "body {background-color: WhiteSmoke; font-family: Verdana, Geneva, sans-serif}"
  txt(2) = "img.title {width:990; height:105; align:left}"
  txt(3) = "p.subtitle1 {font-size:20pt; color:darkgray}"
  txt(4) = "p.subtitle {font-size:20pt; color:black; text-align:center; font-weight:bold}"
  txt(5) = "p.btext {font-size:12pt; text-align:left}"
  txt(6) = "p.btext2 {font-size:9pt; text-align:left}"
  txt(7) = "p.c {font-size:9pt; text-align:left, white-space:pre}"
  txt(9) = "td.s1 {text-align:left; font-size:11pt}"
  
  txt(20) = "td {text-align:center; font-size:12pt}"
  txt(21) = "td.s1 {text-align:left; font-size:11pt}"
  txt(22) = "td.tablehdr {text-align:center; font-size:17pt}"
  txt(23) = "CAPTION {text-align:left; font-size:14pt; font-weight:bold}"
  txt(24) = "</STYLE></HEAD><BODY>"
  txt(25) = "<img class="+quote+"img-fluid"+quote+" src="+quote+"cas-cvdp.png"+quote+" alt="+quote+"CVDP logo"+quote+">"
  txt(26)= "<TABLE width='990' border=0 cellpadding=6>"
  txt(27) = "<tr><td width='30'><p class=btext>Go to:</p></td><td class=s1 width='380'><a href="+quote+"methodology.html"+quote+">Methodology and Definitions</a><br><a href="+quote+"index.html"+quote+">Diagnostics Plots</a><br><hr>"

  txt(28) = "Input Namelists: <b>Reference Data</b> | <a href="+quote+"namelist_simulations.html"+quote+">Simulations</a><br>"
  txt(29) = "Derived Namelists: <a href="+quote+"namelist_msftmz.html"+quote+">MSFTMZ</a> | <a href="+quote+"namelist_pr.html"+quote+">PR</a> | <a href="+quote+"namelist_psl.html"+quote+">PSL</a> | "
  txt(30) = "<br><a href="+quote+"namelist_siconc_nh.html"+quote+">SICONC NH</a> | <a href="+quote+"namelist_siconc_sh.html"+quote+">SICONC SH</a> | <a href="+quote+"namelist_tas.html"+quote+">TAS</a> |"
;  txt(31) = "<a href="+quote+"namelist_ts.html"+quote+">TS</a></td><td><p class=subtitle>"+webtitle+"</p></td></tr></table><hr width=990 align=left>"
  txt(31) = "<a href="+quote+"namelist_ts.html"+quote+">TS</a> | <a href="+quote+"namelist_zos.html"+quote+">ZOS</a></td><td><h2 class="+quote+"text-center"+quote+">"+webtitle+"</h2></td></tr></table><hr width=990 align=left>"
  txt(32) = "<p class=subtitle1>Input Namelist: Reference Data</p>" 
  z := asciiread(OUTDIR+"namelist_obs",(/-1/),"string")
  nlines = dimsizes(z)
  txt(33) = "<p class=c>"
  do gg = 0,nlines-1
     txt(33+gg) = z(gg)+"<br>"
  end do
  txt(34+nlines) = "</p>"
  txt(34+nlines+1) = "Created "+systemfunc("date")
  txt(34+nlines+2) = "<p class=btext2>CVDP Version "+VERSION+"</p></body></html>"
  tt := ind(.not.ismissing(txt))
  txt2 := txt(:tt(dimsizes(tt)-1)+1)
  txt2 = where(ismissing(txt2),"",txt2)
  asciiwrite(OUTDIR+"namelist_obs.html",txt2)
  txt(28:) = txt@_FillValue

  txt(28) = "Input Namelists: <a href="+quote+"namelist_obs.html"+quote+">Reference Data</a> | <b>Simulations</b><br>"
  txt(29) = "Derived Namelists: <a href="+quote+"namelist_msftmz.html"+quote+">MSFTMZ</a> | <a href="+quote+"namelist_pr.html"+quote+">PR</a> | <a href="+quote+"namelist_psl.html"+quote+">PSL</a> | "
  txt(30) = "<br><a href="+quote+"namelist_siconc_nh.html"+quote+">SICONC NH</a> | <a href="+quote+"namelist_siconc_sh.html"+quote+">SICONC SH</a> | <a href="+quote+"namelist_tas.html"+quote+">TAS</a> |"
  txt(31) = "<a href="+quote+"namelist_ts.html"+quote+">TS</a> | <a href="+quote+"namelist_zos.html"+quote+">ZOS</a></td><td><h2 class="+quote+"text-center"+quote+">"+webtitle+"</h2></td></tr></table><hr width=990 align=left>"
  txt(32) = "<p class=subtitle1>Input Namelist: Simulations</p>" 
  z := asciiread(OUTDIR+"namelist",(/-1/),"string")
  nlines = dimsizes(z)
  txt(33) = "<p class=c>"
  do gg = 0,nlines-1
     txt(33+gg) = z(gg)+"<br>"
  end do
  txt(34+nlines) = "</p>"
  txt(34+nlines+1) = "Created "+systemfunc("date")
  txt(34+nlines+2) = "<p class=btext2>CVDP Version "+VERSION+"</p></body></html>"
  tt := ind(.not.ismissing(txt))
  txt2 := txt(:tt(dimsizes(tt)-1)+1)
  txt2 = where(ismissing(txt2),"",txt2)
  asciiwrite(OUTDIR+"namelist_simulations.html",txt2)
  txt(28:) = txt@_FillValue

  txt(28) = "Input Namelists: <a href="+quote+"namelist_obs.html"+quote+">Reference Data</a> | <a href="+quote+"namelist_simulations.html"+quote+">Simulations</a><br>"
  txt(29) = "Derived Namelists: <b>MSFTMZ</b> | <a href="+quote+"namelist_pr.html"+quote+">PR</a> | <a href="+quote+"namelist_psl.html"+quote+">PSL</a> | "
  txt(30) = "<br><a href="+quote+"namelist_siconc_nh.html"+quote+">SICONC NH</a> | <a href="+quote+"namelist_siconc_sh.html"+quote+">SICONC SH</a> | <a href="+quote+"namelist_tas.html"+quote+">TAS</a> |"
  txt(31) = "<a href="+quote+"namelist_ts.html"+quote+">TS</a> | <a href="+quote+"namelist_zos.html"+quote+">ZOS</a></td><td><h2 class="+quote+"text-center"+quote+">"+webtitle+"</h2></td></tr></table><hr width=990 align=left>"
  txt(32) = "<p class=subtitle1>Derived Namelist: MSFTMZ</p>" 
  z := asciiread(OUTDIR+"namelist_moc",(/-1/),"string")
  nlines = dimsizes(z)
  txt(33) = "<p class=c>"
  do gg = 0,nlines-1
     txt(33+gg) = z(gg)+"<br>"
  end do
  txt(34+nlines) = "</p>"
  txt(34+nlines+1) = "Created "+systemfunc("date")
  txt(34+nlines+2) = "<p class=btext2>CVDP Version "+VERSION+"</p></body></html>"
  tt := ind(.not.ismissing(txt))
  txt2 := txt(:tt(dimsizes(tt)-1)+1)
  txt2 = where(ismissing(txt2),"",txt2)
  asciiwrite(OUTDIR+"namelist_msftmz.html",txt2)

  txt(28) = "Input Namelists: <a href="+quote+"namelist_obs.html"+quote+">Reference Data</a> | <a href="+quote+"namelist_simulations.html"+quote+">Simulations</a><br>"
  txt(29) = "Derived Namelists: <a href="+quote+"namelist_msftmz.html"+quote+">MSFTMZ</a> | <b>PR</b> | <a href="+quote+"namelist_psl.html"+quote+">PSL</a> | "
  txt(30) = "<br><a href="+quote+"namelist_siconc_nh.html"+quote+">SICONC NH</a> | <a href="+quote+"namelist_siconc_sh.html"+quote+">SICONC SH</a> | <a href="+quote+"namelist_tas.html"+quote+">TAS</a> |"
  txt(31) = "<a href="+quote+"namelist_ts.html"+quote+">TS</a> | <a href="+quote+"namelist_zos.html"+quote+">ZOS</a></td><td><h2 class="+quote+"text-center"+quote+">"+webtitle+"</h2></td></tr></table><hr width=990 align=left>"
  txt(32) = "<p class=subtitle1>Derived Namelist: PR</p>" 
  z := asciiread(OUTDIR+"namelist_prect",(/-1/),"string")
  nlines = dimsizes(z)
  txt(33) = "<p class=c>"
  do gg = 0,nlines-1
     txt(33+gg) = z(gg)+"<br>"
  end do
  txt(34+nlines) = "</p>"
  txt(34+nlines+1) = "Created "+systemfunc("date")
  txt(34+nlines+2) = "<p class=btext2>CVDP Version "+VERSION+"</p></body></html>"
  tt := ind(.not.ismissing(txt))
  txt2 := txt(:tt(dimsizes(tt)-1)+1)
  txt2 = where(ismissing(txt2),"",txt2)
  asciiwrite(OUTDIR+"namelist_pr.html",txt2)

  txt(28) = "Input Namelists: <a href="+quote+"namelist_obs.html"+quote+">Reference Data</a> | <a href="+quote+"namelist_simulations.html"+quote+">Simulations</a><br>"
  txt(29) = "Derived Namelists: <a href="+quote+"namelist_msftmz.html"+quote+">MSFTMZ</a> | <a href="+quote+"namelist_pr.html"+quote+">PR</a> | <b>PSL</b> | "
  txt(30) = "<br><a href="+quote+"namelist_siconc_nh.html"+quote+">SICONC NH</a> | <a href="+quote+"namelist_siconc_sh.html"+quote+">SICONC SH</a> | <a href="+quote+"namelist_tas.html"+quote+">TAS</a> |"
  txt(31) = "<a href="+quote+"namelist_ts.html"+quote+">TS</a> | <a href="+quote+"namelist_zos.html"+quote+">ZOS</a></td><td><h2 class="+quote+"text-center"+quote+">"+webtitle+"</h2></td></tr></table><hr width=990 align=left>"
  txt(32) = "<p class=subtitle1>Derived Namelist: PSL</p>" 
  z := asciiread(OUTDIR+"namelist_psl",(/-1/),"string")
  nlines = dimsizes(z)
  txt(33) = "<p class=c>"
  do gg = 0,nlines-1
     txt(33+gg) = z(gg)+"<br>"
  end do
  txt(34+nlines) = "</p>"
  txt(34+nlines+1) = "Created "+systemfunc("date")
  txt(34+nlines+2) = "<p class=btext2>CVDP Version "+VERSION+"</p></body></html>"
  tt := ind(.not.ismissing(txt))
  txt2 := txt(:tt(dimsizes(tt)-1)+1)
  txt2 = where(ismissing(txt2),"",txt2)
  asciiwrite(OUTDIR+"namelist_psl.html",txt2)

  txt(28) = "Input Namelists: <a href="+quote+"namelist_obs.html"+quote+">Reference Data</a> | <a href="+quote+"namelist_simulations.html"+quote+">Simulations</a><br>"
  txt(29) = "Derived Namelists: <a href="+quote+"namelist_msftmz.html"+quote+">MSFTMZ</a> | <a href="+quote+"namelist_pr.html"+quote+">PR</a> | <a href="+quote+"namelist_psl.html"+quote+">PSL</a> | "
  txt(30) = "<br><b>SICONC NH</b> | <a href="+quote+"namelist_siconc_sh.html"+quote+">SICONC SH</a> | <a href="+quote+"namelist_tas.html"+quote+">TAS</a> |"
  txt(31) = "<a href="+quote+"namelist_ts.html"+quote+">TS</a> | <a href="+quote+"namelist_zos.html"+quote+">ZOS</a></td><td><h2 class="+quote+"text-center"+quote+">"+webtitle+"</h2></td></tr></table><hr width=990 align=left>"
  txt(32) = "<p class=subtitle1>Derived Namelist: SICONC NH</p>" 
  z := asciiread(OUTDIR+"namelist_aice_nh",(/-1/),"string")
  nlines = dimsizes(z)
  txt(33) = "<p class=c>"
  do gg = 0,nlines-1
     txt(33+gg) = z(gg)+"<br>"
  end do
  txt(34+nlines) = "</p>"
  txt(34+nlines+1) = "Created "+systemfunc("date")
  txt(34+nlines+2) = "<p class=btext2>CVDP Version "+VERSION+"</p></body></html>"
  tt := ind(.not.ismissing(txt))
  txt2 := txt(:tt(dimsizes(tt)-1)+1)
  txt2 = where(ismissing(txt2),"",txt2)
  asciiwrite(OUTDIR+"namelist_siconc_nh.html",txt2)

  txt(28) = "Input Namelists: <a href="+quote+"namelist_obs.html"+quote+">Reference Data</a> | <a href="+quote+"namelist_simulations.html"+quote+">Simulations</a><br>"
  txt(29) = "Derived Namelists: <a href="+quote+"namelist_msftmz.html"+quote+">MSFTMZ</a> | <a href="+quote+"namelist_pr.html"+quote+">PR</a> | <a href="+quote+"namelist_psl.html"+quote+">PSL</a> | "
  txt(30) = "<br><a href="+quote+"namelist_siconc_nh.html"+quote+">SICONC NH</a> | <b>SICONC SH</b> | <a href="+quote+"namelist_tas.html"+quote+">TAS</a> |"
  txt(31) = "<a href="+quote+"namelist_ts.html"+quote+">TS</a> | <a href="+quote+"namelist_zos.html"+quote+">ZOS</a></td><td><h2 class="+quote+"text-center"+quote+">"+webtitle+"</h2></td></tr></table><hr width=990 align=left>"
  txt(32) = "<p class=subtitle1>Derived Namelist: SICONC SH</p>" 
  z := asciiread(OUTDIR+"namelist_aice_sh",(/-1/),"string")
  nlines = dimsizes(z)
  txt(33) = "<p class=c>"
  do gg = 0,nlines-1
     txt(33+gg) = z(gg)+"<br>"
  end do
  txt(34+nlines) = "</p>"
  txt(34+nlines+1) = "Created "+systemfunc("date")
  txt(34+nlines+2) = "<p class=btext2>CVDP Version "+VERSION+"</p></body></html>"
  tt := ind(.not.ismissing(txt))
  txt2 := txt(:tt(dimsizes(tt)-1)+1)
  txt2 = where(ismissing(txt2),"",txt2)
  asciiwrite(OUTDIR+"namelist_siconc_sh.html",txt2)

  txt(28) = "Input Namelists: <a href="+quote+"namelist_obs.html"+quote+">Reference Data</a> | <a href="+quote+"namelist_simulations.html"+quote+">Simulations</a><br>"
  txt(29) = "Derived Namelists: <a href="+quote+"namelist_msftmz.html"+quote+">MSFTMZ</a> | <a href="+quote+"namelist_pr.html"+quote+">PR</a> | <a href="+quote+"namelist_psl.html"+quote+">PSL</a> | "
  txt(30) = "<br><a href="+quote+"namelist_siconc_nh.html"+quote+">SICONC NH</a> | <a href="+quote+"namelist_siconc_sh.html"+quote+">SICONC SH</a> | <b>TAS</b> |"
  txt(31) = "<a href="+quote+"namelist_ts.html"+quote+">TS</a> | <a href="+quote+"namelist_zos.html"+quote+">ZOS</a></td><td><h2 class="+quote+"text-center"+quote+">"+webtitle+"</h2></td></tr></table><hr width=990 align=left>"
  txt(32) = "<p class=subtitle1>Derived Namelist: TAS</p>" 
  z := asciiread(OUTDIR+"namelist_trefht",(/-1/),"string")
  nlines = dimsizes(z)
  txt(33) = "<p class=c>"
  do gg = 0,nlines-1
     txt(33+gg) = z(gg)+"<br>"
  end do
  txt(34+nlines) = "</p>"
  txt(34+nlines+1) = "Created "+systemfunc("date")
  txt(34+nlines+2) = "<p class=btext2>CVDP Version "+VERSION+"</p></body></html>"
  tt := ind(.not.ismissing(txt))
  txt2 := txt(:tt(dimsizes(tt)-1)+1)
  txt2 = where(ismissing(txt2),"",txt2)
  asciiwrite(OUTDIR+"namelist_tas.html",txt2)

  txt(28) = "Input Namelists: <a href="+quote+"namelist_obs.html"+quote+">Reference Data</a> | <a href="+quote+"namelist_simulations.html"+quote+">Simulations</a><br>"
  txt(29) = "Derived Namelists: <a href="+quote+"namelist_msftmz.html"+quote+">MSFTMZ</a> | <a href="+quote+"namelist_pr.html"+quote+">PR</a> | <a href="+quote+"namelist_psl.html"+quote+">PSL</a> | "
  txt(30) = "<br><a href="+quote+"namelist_siconc_nh.html"+quote+">SICONC NH</a> | <a href="+quote+"namelist_siconc_sh.html"+quote+">SICONC SH</a> | <a href="+quote+"namelist_tas.html"+quote+">TAS</a> |"
  txt(31) = "<b>TS</b> | <a href="+quote+"namelist_zos.html"+quote+">ZOS</a></td><td><h2 class="+quote+"text-center"+quote+">"+webtitle+"</h2></td></tr></table><hr width=990 align=left>"
  txt(32) = "<p class=subtitle1>Derived Namelist: TS</p>" 
  z := asciiread(OUTDIR+"namelist_ts",(/-1/),"string")
  nlines = dimsizes(z)
  txt(33) = "<p class=c>"
  do gg = 0,nlines-1
     txt(33+gg) = z(gg)+"<br>"
  end do
  txt(34+nlines) = "</p>"
  txt(34+nlines+1) = "Created "+systemfunc("date")
  txt(34+nlines+2) = "<p class=btext2>CVDP Version "+VERSION+"</p></body></html>"
  tt := ind(.not.ismissing(txt))
  txt2 := txt(:tt(dimsizes(tt)-1)+1)
  txt2 = where(ismissing(txt2),"",txt2)
  asciiwrite(OUTDIR+"namelist_ts.html",txt2)

  txt(28) = "Input Namelists: <a href="+quote+"namelist_obs.html"+quote+">Reference Data</a> | <a href="+quote+"namelist_simulations.html"+quote+">Simulations</a><br>"
  txt(29) = "Derived Namelists: <a href="+quote+"namelist_msftmz.html"+quote+">MSFTMZ</a> | <a href="+quote+"namelist_pr.html"+quote+">PR</a> | <a href="+quote+"namelist_psl.html"+quote+">PSL</a> | "
  txt(30) = "<br><a href="+quote+"namelist_siconc_nh.html"+quote+">SICONC NH</a> | <a href="+quote+"namelist_siconc_sh.html"+quote+">SICONC SH</a> | <a href="+quote+"namelist_tas.html"+quote+">TAS</a> |"
  txt(31) = "<a href="+quote+"namelist_ts.html"+quote+">TS</a> | <b>ZOS</b></td><td><h2 class="+quote+"text-center"+quote+">"+webtitle+"</h2></td></tr></table><hr width=990 align=left>"
  txt(32) = "<p class=subtitle1>Derived Namelist: ZOS</p>" 
  z := asciiread(OUTDIR+"namelist_ssh",(/-1/),"string")
  nlines = dimsizes(z)
  txt(33) = "<p class=c>"
  do gg = 0,nlines-1
     txt(33+gg) = z(gg)+"<br>"
  end do
  txt(34+nlines) = "</p>"
  txt(34+nlines+1) = "Created "+systemfunc("date")
  txt(34+nlines+2) = "<p class=btext2>CVDP Version "+VERSION+"</p></body></html>"
  tt := ind(.not.ismissing(txt))
  txt2 := txt(:tt(dimsizes(tt)-1)+1)
  txt2 = where(ismissing(txt2),"",txt2)
  asciiwrite(OUTDIR+"namelist_zos.html",txt2)

;----------------------------------------------------------------------------
;--   Create calculation description webpage
;----------------------------------------------------------------------------
  txt(4) = "p.subtitle {font-size:20pt; color:black; text-align:left; font-weight:bold}"
  txt(20) = "td {text-align:left; font-size:12pt}"
  txt(27) = "<tr><td width='30'><p class=btext>Go to:</p></td><td class=s1 width='380'><a href="+quote+"index.html"+quote+">Diagnostics Plots</a><td><h2 class="+quote+"text-center"+quote+">Methodology and Definitions</h2></td></tr></table>"
  txt(28:) = txt@_FillValue
  
  txt(30) = "<p class=subtitle>General Notes</p>"
  txt(31) = "<TABLE width='800' border=1 frame=void rules=all cellpadding=6 bordercolor=darkgray>"
  txt(32) = "<tr><td><ul><li>ts (CESM equivalent = TS) is surface ("+quote+"skin"+quote+") temperature and is used in lieu of sea surface temperatures (SSTs), tas (TREFHT) is 2m air temperature."
  txt(33) = "<li>pr (PRECC+PRECL or PRECT) is total precipitation , psl (PSL) is sea level pressure, siconc (aice) is sea ice concentration, msftmz (MOC) is the ocean meridional overturning mass streamfunction, and zos (SSH) is the sea surface height above geoid."
  txt(34) = "<li>The annual cycle is removed prior to every calculation by subtracting the long-term monthly means. Exception: The annual cycle is not removed for Climatological Averages and Sea Ice Extent Timeseries (except those entitled "+quote+"Monthly Anomalies"+quote+")."
  txt(35) = "<li>The long-term trend removal is performed for each month separately after the annual cycle is removed (if necessary) for all metrics except Climatological Averages, Linear Trends and Sea Ice Extent Timeseries (except those entitled "+quote+"Monthly Anomalies"+quote+"). The choice of detrending method is set by the user for 1) data specified in the input namelist_obs file (usually observational data) and 2) data specified in the namelist file (usually model data). For this specific comparison the creator specified the following detrending methods: For specified namelist_obs data, "+rt_obs+" For specified namelist data, "+rt_model
  txt(36) = "<li>Area-averages use cosine of latitude weighting."
  txt(37) = "<li>For visual clarity, the y-axis range <i>may</i> differ amongst individual panels on a particular plot."
  txt(39) = "<li>Power Spectra: The best-fit first-order Markov red noise spectrum (red curve) and its 95% (blue curve) and 99% (green curve) confidence bounds are shown on each panel. Top X-axis shows the period (in years), and the bottom X-axis shows the frequency (cycles/mo). If calculated, the observational spectrum is overlaid in gray on each model spectrum. The spectra are displayed in variance-conserving form." 
  txt(40) = "<li>Wavelet Analysis: A wavelet transform is computed using a Morlet wavelet with a wavenumber of 6. Areas significant at the 95% based on a chi-square test are stippled and the “cone of influence” is hatched. See Torrence, C. and G. P. Compo, 1998: A Practical Guide to Wavelet Analysis. Bull. Amer. Meteor. Soc., 79, 61-78. doi: 10.1175/1520-0477(1998)079<0061:APGTWA>2.0.CO;2."
  txt(42) = "<li>Metrics Tables: Area-weighted pattern correlations and rms differences are calculated between observations and each model simulation (regridded to match the observational grid) for 11 climate metrics. The Total Score column shows the average of the 11 pattern correlations (Z-transformed) and rms differences. The following domains are used to compute the pattern correlations and rms differences: Standard deviations, ENSO and PDV: Global;  AMV: 63&deg;S:65&deg;N; El Nino and La Nina Hovm&ouml;llers: entire longitude/temporal range shown, NAM/NAO (20:90&deg;N) and SAM (20:90&deg;S)."
  txt(43) = "<li>EOF significance: If an eigenvalue is significantly separated from neighboring values a star is appended to the percent variance explained on the plot. Significance is calculated following North et al. (MWR, 1982)."
  txt(44) = "<li>Ice Extent: The area (km<sup>2</sup>) of siconc values greater than or equal to 15%. For data sets with a northern hemisphere pole hole the CVDP looks for an attribute named pole_hole_area that is attached to the AREA variable in the netCDF file. The format of pole_hole_area should be start month (YYYYMM), end month (YYYYMM), area value, (repeat as necessary). If pole_hole_area is detected the CVDP will add the area value to the calculated northern hemisphere ice extent timeseries from the specified start month to the specified end month, and a * is placed after the dataset name in the ice extent plots."    
  txt(45) = "<li>The ensemble mean of a given metric is computed as the average across the individual members.</li>"
  txt(46) = "<li>Regional timeseries patterns are created by regressing SST (PSL) anomalies in degrees C (hPa) onto the index time series.</li>"
  txt(47) = "<li>For more information on observational datasets and climate indices, see the <a href="+quote+"http://climatedataguide.ucar.edu/"+quote+" target="+quote+"_blank"+quote+">Climate Data Guide</a>.</ul>"
  txt(48) = "</td></tr></table>"

  txt(49) = "<p class=subtitle>Modes of Variability</p>"
  txt(50) = "<TABLE width='800' border=1 frame=void rules=all cellpadding=6 bordercolor=darkgray>"
  txt(51) = "<tr><td><b>ENSO Spatial Composites</b></td>"
  txt(52) = "<td>El Ni&ntilde;o (La Ni&ntilde;a) events are defined based on the December value of the Nino34 SST Index (smoothed with a 3-point binomial filter) greater than or equal to 1 (less than or equal to -1) standard deviation. The number of El Ni&ntilde;o/La Ni&ntilde;a events composited is indicated in the subtitle located to the upper right of each panel. TS/TAS/PSL composites: Temperatures are color shaded and in units of Celsius. Sea level pressure is contoured from -16 to 16hPa by 2hPa; negative contours are dashed. PR composites: Precipitation is color shaded and is in units of mm/day. See Deser, C., A. S. Phillips, R. A. Tomas, Y. Okumura, M. A. Alexander, A. Capotondi, J. D. Scott, Y. -O. Kwon, and M. Ohba (2012), ENSO and Pacific Decadal Variability in Community Climate System Model Version 4. Journal of Climate, 25, 2622-2651, doi: 10.1175/JCLI-D-11-00301.1.</td></tr>"   
  txt(53) = "<tr><td><b>El Ni&ntilde;o and La Ni&ntilde;a Hovm&ouml;llers</b></td>"
  txt(54) = "<td>El Ni&ntilde;o (La Ni&ntilde;a) events are defined based on the December value of the Nino34 SST Index (smoothed with a 3-point binomial filter) greater than or equal to 1 (less than or equal to -1) standard deviation. The number of El Ni&ntilde;o/La Ni&ntilde;a events composited is indicated in the subtitle located to the upper right of each panel. Meridional averages are calculated by averaging from 3&deg;S:3&deg;N, and spatial patterns are formed by compositing from Jan year 0 to May year 2. See Deser, C., A. S. Phillips, R. A. Tomas, Y. Okumura, M. A. Alexander, A. Capotondi, J. D. Scott, Y. -O. Kwon, and M. Ohba (2012), ENSO and Pacific Decadal Variability in Community Climate System Model Version 4. Journal of Climate, 25, 2622-2651, doi: 10.1175/JCLI-D-11-00301.1.</td></tr>"  

  txt(55) = "<tr><td><b>PDV</b> (Pacific Decadal Variability)</td>"  
  txt(56) = "<td>Monthly index timeseries defined as the leading principal component (PC) of North Pacific (20:70&deg;N, 110&deg;E:100&deg;W) area-weighted SST anomalies. Pattern created by regressing SST anomalies (in Celsius) at each grid box onto the normalized PC timeseries. Low pass-filtered timeseries (black curve) is based on a 61-month running mean. See Deser, C., M. A. Alexander, S. -P. Xie, and A. S. Phillips (2010), Sea surface temperature variability: patterns and mechanisms. <i>Ann. Rev. Mar. Sci.</i>, 2010.2, 115-143, doi:10.1146/annurev-marine-120408-151453. Also see Mantua, N. J., S. R. Hare, Y. Zhang, J. M. Wallace, and R. Francis (1997), A Pacific interdecadal climate oscillation with impacts on salmon production. <i>Bull. Amer. Met. Soc.</i>, 1069-1079. For more information on the PDV see the <a href="+quote+"https://climatedataguide.ucar.edu/climate-data/pacific-decadal-oscillation-pdo-definition-and-indices?qt-climatedatasetmaintabs=1"+quote+" target="+quote+"_blank"+quote+">Climate Data Guide</a>.</td></tr>"
  txt(57) = "<tr><td><b>IPV (Standard)</b> (Interdecadal Pacific Variability)</td>"  
  txt(58) = "<td>Monthly index timeseries defined as the leading principal component (PC) of 13yr low pass filtered Pacific (40&deg;S:60&deg;N, 110&deg;E:70&deg;W) area-weighted SST anomalies.  Pattern created by regressing SST anomalies (in Celsius) at each grid box onto the normalized PC timeseries. At least 40 years of data are required for the standard IPV index to be calculated. See Meehl, G.A. and A. Hu (2007), Megadroughts in the Indian Monsoon Region and Southwest North America and a Mechanism for Associated Multidecadal Pacific Sea Surface Temperature Anomalies, Journal of Climate, 19, 1605-1623, doi: 10.1175/JCLI3675.1.</td></tr>"
  txt(59) = "<tr><td><b>IPV (Henley)</b> (Interdecadal Pacific Variability)</td>"  
  txt(60) = "<td>Monthly index timeseries defined as the area-weighted SST anomalies averaged over the central tropical Pacific (10&deg;S:10&deg;N, 170&deg;E:90&deg;W) minus the average of the area-weighted SST anomalies averaged over the north (25&deg;:45&deg;N, 140&deg;E:145&deg;W) and south (15&deg;:50&deg;S, 150&deg;E:160&deg;W) Pacific. Pattern created by regressing SST anomalies (in Celsius) at each grid box onto the timeseries. See Henley, B.J., J. Gergis, D.J. Karoly, S. Power, J. Kennedy and C.K. Folland (2015), A Tripole Index for the Interdecadal Pacific Oscillation, <i>Clim. Dyn.</i>, 45, 3077-3090, doi: 10.1007/s00382-015-2525-1.</td></tr>"

  txt(61) = "<tr><td><b>AMV</b> (Atlantic Multidecadal Variability)</td>"  
  txt(62) = "<td>Monthly index timeseries defined as area-weighted SST anomalies averaged over the North Atlantic (0:60&deg;N, 80&deg;W:0&deg;E). Pattern created by regressing SST anomalies onto the index timeseries and smoothing with a 9-point spatial filter. Low pass-filtered timeseries (black curve superimposed on the monthly timeseries) is based on a 61-month running mean. Low-pass filtered regression maps ("+quote+"Regr LP"+quote+") use a 10-year running mean on both the index timeseries and the field being regressed. For more information on the definition of AMV in a changing background climate, see Deser C. and A. S. Phillips (2023), Spurious Indo-Pacific connections to internal Atlantic Multidecadal Variability introduced by the global temperature residual method. Geophys. Res. Lett., 50, e2022GL100574, doi: 10.1029/2022GL100574. For more information on the AMV see the <a href="+quote+"https://climatedataguide.ucar.edu/climate-data/atlantic-multi-decadal-oscillation-amo?qt-climatedatasetmaintabs=1"+quote+" target="+quote+"_blank"+quote+">Climate Data Guide</a>.</td></tr>"
  txt(63) = "<tr><td><b>AMOC</b></td>"
  txt(64) = "<td>The Atlantic Meridional Overturning Circulation (AMOC) is defined as the leading Principal Component (PC) time series of annual mean oceanic meridional mass transport (Sv) in the Atlantic sector (33&deg;S-90&deg;N) following Danabasoglu et al. (2012). Here we use annual averages instead of monthly values. The AMOC patterns are created by regressing the AMOC anomalies (in Sv) onto the normalized PC timeseries. The SST/TAS patterns are created by regressing TAS/SST anomalies (in Celsius) at each grid box over the globe onto the normalized AMOC PC timeseries. A 15-point low-pass Lanczos filter is applied to the AMOC PC (and AMV) timeseries prior to computing lead/lag correlations, with a minimum of 90 years of data required. See Danabasoglu, G., S. G. Yeager, Y. -O. Kwon, J. J. Tribbia, A. S. Phillips, and J. W. Hurrell (2012), Variability of the Atlantic Meridional Overturning Circulation in CCSM4. J. Climate, 25, 5153-5172, doi: 10.1175/JCLI-D-11-00463.1.<br><br>For CCSM4 and CESM1, the MOC variable is read in, the Eulerian Mean, Eddy-Induced and Submeso components are summed, and the Atlantic Ocean + Mediterranean Sea + Labrador Sea + GIN Sea + Arctic Ocean + Hudson Bay transport region is selected. For CCSM2 and CCSM3 the same transport region is selected but only the Eulerian Mean component is used as that is all that is available. For CMIP5 (CMIP6) data the msftmyz (msftmz) variable is read in and the atlantic_arctic_ocean basin is used. For CMIP3 data, the stfmmc variable is read in and the atlantic_ocean geo_region is used.</td></tr>" 
  txt(65) = "<tr><td><b>SO</b></td>"
  txt(66) = "<td>The Southern Oscillation Index is defined as the difference between area-averaged PSL anomalies (in hPa) computed over 30&deg;S:0&deg;N, 70:170&deg;E and area-averaged PSL anomalies computed over 30&deg;S:0&deg;N, 160:80&deg;W. Pattern created by regressing global PSL anomalies (in hPa) onto the timeseries. See Deser, C. and J. M. Wallace (1990), Large-scale atmospheric circulation features of warm and cold episodes in the Tropical Pacific. J. Climate, 3, 1254-1281, doi: 10.1175/1520-0442(1990)003<1254:LSACFO>2.0.CO;2.</td></tr>"
  txt(67) = "<tr><td><b>NAM</b> (Northern Annular Mode)</td>"  
  txt(68) = "<td>Seasonal/annual PSL averages are formed, square root of the cosine of the latitude weighting is applied, and then the leading EOF and associated principal component (PC) timeseries are computed over 20:90&deg;N, 0:360&deg;E. Pattern created by regressing global PSL anomalies (in hPa) onto normalized PC timeseries. Based on Hurrell, J. W., and C. Deser (2009), North Atlantic climate variability: The role of the North Atlantic Oscillation. <i>J. Mar. Syst.</i>, 78, 28-41, doi:10.1016/j.jmarsys.2008.11.026. Also see Thompson, D. W. J., and J. M. Wallace, 2000: Annular modes in the extratropical circulation. Part I: Month-to-month variability. Journal of Climate, 13, 1000-1016.</td></tr>"  
  txt(69) = "<tr><td><b>NAO</b> (North Atlantic Oscillation)</td>"  
  txt(70) = "<td>Seasonal/annual PSL averages are formed, square root of the cosine of latitude weighting is applied, and then the leading EOF and associated principal component (PC) timeseries are computed over 20:80&deg;N, 90&deg;W:40&deg;E. Pattern created by regressing global PSL anomalies (in hPa) onto normalized PC timeseries. Based on Hurrell, J. W. and C. Deser (2009), North Atlantic climate variability: The role of the North Atlantic Oscillation. <i>J. Mar. Syst.</i>, 78, 28-41, doi:10.1016/j.jmarsys.2008.11.026. For more information on the NAO see the <a href="+quote+"https://climatedataguide.ucar.edu/climate-data/hurrell-north-atlantic-oscillation-nao-index-pc-based?qt-climatedatasetmaintabs=1"+quote+" target="+quote+"_blank"+quote+">Climate Data Guide</a>.</td></tr>"  
  txt(71) = "<tr><td><b>SAM/PSA1/PSA2</b> (Southern Annular Mode, Pacific South American Patterns 1/2)</td>"  
  txt(72) = "<td>Seasonal/annual PSL averages are formed, square root of the cosine of latitude weighting is applied, and then the 1st (SAM), 2nd (PSA1) and 3rd (PSA2) EOFs and associated principal component (PC) timeseries are computed over 20:90&deg;S, 0:360&deg;E. Patterns created by regressing global PSL anomalies (in hPa) onto normalized PC timeseries. SAM calculation based on Thompson, D. W. J. and J.M. Wallace, (2000), Annular modes in the extratropical circulation. Part I: Month-to-month variability. Journal of Climate, 13, 1000-1016.</td></tr>"  
  txt(73) = "<tr><td><b>PNA/NPO</b> (Pacific North American Pattern, North Pacific Oscillation)</td>" 
  txt(74) = "<td>Seasonal/annual PSL averages are formed, the square root of the cosine of the latitude weighting is applied, and then the 1st (PNA) and 2nd (NPO) EOFs and associated principal component (PC) timeseries are computed over 20:85&deg;N, 120&deg;E:120&deg;W. Patterns created by regressing global PSL anomalies (in hPa) onto normalized PC timeseries.</td></tr>" 
  txt(75) = "</table>"
  
  txt(89) = "<p class=subtitle>Climate Indices</p>"
  txt(91) = "<TABLE width='800' border=1 frame=void rules=all cellpadding=6 bordercolor=darkgray>"
  txt(92) = "<tr><td><b>Atlantic SST Meridional Mode</b></td>"
  txt(93) = "<td>Defined as the difference between area-averaged SST anomalies (in Celsius) computed over 5:15&deg;N, 20:50&deg;W and area-averaged SST anomalies computed over 5:15&deg;S, 20&degW:10&deg;E.  See Doi, T., T. Tozuka and T. Yamagata (2009), Interannual variability of the Guinea Dome and its possible link with the Atlantic Meridional Mode. Climate Dynamics, 33, 985-998, doi:10.1007/s00382-009-0574-z.</td></tr>"
  txt(94) = "<tr><td><b>Atlantic Ni&ntilde;o SST</b></td>"
  txt(95) = "<td>Area-averaged SST anomalies (in Celsius) computed over 3&deg;S:3&deg;N, 20&deg;W:0&deg;E. See Zebiak, S. E. (1993), Air–sea interaction in the equatorial Atlantic region. Journal of Climate, 6, 1567–1586.</td></tr>"
  txt(96) = "<tr><td><b>North Atlantic SST</b></td>"
  txt(97) = "<td>Area-averaged SST anomalies (in Celsius) computed over 0&deg;:60&deg;N, 90&deg;W:0&deg;E. </td></tr>"
  txt(98) = "<tr><td><b>Tropical North Atlantic SST</b></td>"
  txt(99) = "<td>Area-averaged SST anomalies (in Celsius) computed over 5.5:23.5&deg;N, 15:57.5&deg;W. See Enfield, D.B., A.M. Mestas, D.A. Mayer, and L. Cid-Serrano (1999), How ubiquitous is the dipole relationship in tropical Atlantic sea surface temperatures?, JGR-O, 104, 7841-7848.</td></tr>"
  txt(100) = "<tr><td><b>Tropical South Atlantic SST</b></td>"
  txt(101) = "<td>Area-averaged SST anomalies (in Celsius) computed over 0:20&deg;S, 30&deg;W:10&deg;E. See Enfield, D.B., A.M. Mestas, D.A. Mayer, and L. Cid-Serrano (1999), How ubiquitous is the dipole relationship in tropical Atlantic sea surface temperatures?, JGR-O, 104, 7841-7848.</td></tr>"
  txt(102) = "<tr><td><b>ni&ntilde;o1+2</b></td>"
  txt(103) = "<td>Area-averaged SST anomalies (in Celsius) computed over 0:10&deg;S, 80:90&deg;W. </td></tr>"
  txt(104) = "<tr><td><b>ni&ntilde;o3</b></td>"
  txt(105) = "<td>Area-averaged SST anomalies (in Celsius) computed over 5&deg;S:5&deg;N, 90:150&deg;W. See Rasmusson E. M. and T. H. Carpenter (1982), Variations in Tropical Sea Surface Temperature and Surface Wind Fields Associated with the Southern Oscillation/El Niño, Monthly Weather Review, 110, 354 – 384, https://doi.org/10.1175/1520-0493(1982)110<0354:VITSST>2.0.CO;2.</td></tr>"
  txt(106) = "<tr><td><b>ni&ntilde;o3.4</b></td>"
  txt(107) = "<td>Area-averaged SST anomalies (in Celsius) computed over 5&deg;S:5&deg;N, 120:170&deg;W. See Rasmusson E. M. and T. H. Carpenter (1982), Variations in Tropical Sea Surface Temperature and Surface Wind Fields Associated with the Southern Oscillation/El Niño, Monthly Weather Review, 110, 354 – 384, https://doi.org/10.1175/1520-0493(1982)110<0354:VITSST>2.0.CO;2.</td></tr>"
  txt(108) = "<tr><td><b>ni&ntilde;o4</b></td>"
  txt(109) = "<td>Area-averaged SST anomalies (in Celsius) computed over 5&deg;S:5&deg;N, 160&deg;E:150&deg;W. </td></tr>"
  txt(110) = "<tr><td><b>NPI</b> (North Pacific PSL Index)</td>"
  txt(111) = "<td>Winter (December-March) average PSL anomalies (in hPa) area-averaged over 30&deg;:65&deg;N, 160&deg;E:140&deg;W. Based on Trenberth, K. E. and J. W. Hurrell (1994), Decadal atmosphere-ocean variations in the Pacific, <i>Climate Dynamics</i>, 9, 303-319.</td></tr>"    

  txt(120) = "<tr><td><b>North Pacific Meridional Mode</b></td>"
  txt(121) = "<td>See Chiang, J. C. H. and D. J. Vimont (2004), Analogous Pacific and Atlantic Meridional Modes of Tropical Atmosphere–Ocean Variability. Journal of Climate, 17, 4143–4158, doi: 10.1175/jcli4953.1.</td></tr>"
  txt(122) = "<tr><td><b>South Pacific Meridional Mode</b></td>"
  txt(123) = "<td>See Zhang, H., A. Clement and P. Di Nezio (2014), The South Pacific Meridional Mode: A Mechanism for ENSO-like Variability. Journal of Climate, 27, 769–783, doi: 10.1175/jcli-d-13-00082.1.</td></tr>"
  txt(124) = "<tr><td><b>Indian Ocean SST Dipole</b></td>"
  txt(125) = "<td>Defined as the difference between area-averaged SST anomalies (in Celsius) computed over 10&deg;S:10&deg;N, 50:70&deg;E and area-averaged SST anomalies computed over 0:10&deg;S, 90:110&deg;E.  See: Saji, N.H., B. N. Goswami, P. N. Vinayachandran, and T. Yamagata (1999), A dipole mode in the tropical Indian Ocean, Nature, 401, 360-363.</td></tr>"
  txt(126) = "<tr><td><b>Tropical Indian Ocean SST</b></td>"
  txt(127) = "<td>Area-averaged SST anomalies (in Celsius) computed over 15&deg;S:15&deg;N, 40:110&deg;E. </td></tr>"
  txt(128)= "<tr><td><b>Southern Ocean SST</b></td>"
  txt(129)= "<td>Area-averaged SST anomalies (in Celsius) computed over 50&deg;:70&deg;S, 0:360&deg;E. </td></tr>"
  txt(130) = "</table>"
  txt(131) = ""
 
  txt(142) = "<br>Created "+systemfunc("date")
  txt(143) = "<p class=btext>CVDP Version "+VERSION+"</p>"
  txt(144) = "</body></html>"
  
  tt := ind(.not.ismissing(txt))
  txt2 := txt(:tt(dimsizes(tt)-1)+1)
  txt2 = where(ismissing(txt2),"",txt2)
  asciiwrite(OUTDIR+"methodology.html",txt2)
  delete([/tt,txt,txt2/])

  print("Finished: webpage1.ncl")  
end

