
*** Diagonal invertida (\), Combinación en Windows: ALT + 92 ***
*** Comillas simples (`a'), Combinación en Windows: ALT + 96 ***

********************************************************************************
cls

gl drive "D:\james_rodas\OneDrive\Projects\SHCP_DirectorAreaDPP\P-CSP\Resultados_ENOE"
*gl drive "C:\Users\rodas\OneDrive\Projects\SHCP_DirectorAreaDPP\P-CSP\Resultados_ENOE"

*** CALCULOS personas por sectores 3 digitos

foreach year in /*22 23 24*/ 25 {
	foreach trim in /*1 2 3*/ 4 {
		foreach group in 1d 2d 3d 4d {
	
use "$drive/data_out/U_SDC1C2_Y20`year'T0`trim'", clear

drop if eda>98
drop if eda<15

tab sex [fw=fac_tri_sdem], mis

tab clase1 [fw=fac_tri_sdem], mis
tab clase2 [fw=fac_tri_sdem], mis

gen ocup = (clase1 == 1 & clase2 == 1)
gen ocuptil = (ocup == 1 & emp_ppal == 1)
gen ocuptosi = (ocup == 1 & tue_ppal == "1")

tab ocup [fw=fac_tri_sdem], mis
tab ocuptil [fw=fac_tri_sdem] if ocup == 1, mis
tab ocuptosi [fw=fac_tri_sdem] if ocup == 1, mis

rename ingocup ingocup_ori
gen ingocup_missing = ingocup_ori 
replace ingocup_missing = . if ingocup_ori == 0

destring scian, gen(scian2d)
replace scian2d = . if scian == "0"

destring p4a, gen(scian4d)

tab scian2d sex [fw=fac_tri_sdem], mis

destring p3, generate(sinco4d)

gen sinco1d = real(substr(p3, 1, 1))
gen sinco2d = real(substr(p3, 1, 2))
gen sinco3d = real(substr(p3, 1, 3))

tab sinco1d sex [fw=fac_tri_sdem], mis

destring anios_esc, generate(escol2d)
replace escol2d = . if anios_esc == "99"

gen edad2d = eda
replace edad2d = . if eda == 98

***** STEM Professions								

* WARNING: for this data extraction the clasification drops out medical sciences from S, and adds economics and finances to S.
destring cs_p14_c, gen(carr_id) force

* Equivalent construction to match with 2021 2nd quarter's data (period of carreer clasification update in ENOE to match with SEP)
gen carr_gpo_1 = substr(cs_p14_c,2,3) if carr_id <99999
gen carr_gpo_2 = substr(cs_p14_c,1,4) if carr_id >99999
gen carr_gpo3 = ""
replace carr_gpo3 = carr_gpo_1 if carr_id <99999
replace carr_gpo3 = carr_gpo_2 if carr_id >99999

gen carr_gpo = ""
* S: Science
replace carr_gpo = "s0" if (carr_gpo3 == "314" | carr_gpo3 == "413") 				// Finance and economic sciences
replace carr_gpo = "s1" if (carr_gpo3 == "511" | carr_gpo3 == "512" | /// 
							carr_gpo3 == "513" | carr_gpo3 == "510")   				// Environmental and biological sciences
replace carr_gpo = "s2" if (carr_gpo3 == "521" | carr_gpo3 == "523" | ///
							carr_gpo3 == "520" | carr_gpo3 == "522")				// Physics & chemestry sciences
replace carr_gpo = "s3" if (carr_gpo3 == "911" | carr_gpo3 == "912" | /// 
							carr_gpo3 == "913") 									// Medical sciences
* T: Technology
replace carr_gpo = "t1" if (carr_gpo3 == "611" | carr_gpo3 == "613" | /// 
							carr_gpo3 == "612" | carr_gpo3 == "610") 				// TICs innovation
replace carr_gpo = "t2" if (carr_gpo3 == "621" | carr_gpo3 == "622" | ///
							carr_gpo3 == "623" | carr_gpo3 == "620") 				// TICs implementation
* E: Engeeniers
replace carr_gpo = "e1" if (carr_gpo3 == "711" | carr_gpo3 == "712" | ///
							carr_gpo3 == "713" | carr_gpo3 == "714" | ///
							carr_gpo3 == "715" | carr_gpo3 == "716" | ///
							carr_gpo3 == "717" | carr_gpo3 == "710")  				// Mecatronich, chemical and similar engineering
replace carr_gpo = "e2" if (carr_gpo3 == "721" | carr_gpo3 == "722" | ///
							carr_gpo3 == "723" | carr_gpo3 == "724" | ///
							carr_gpo3 == "720") 									// Processes and manufacturing
* M: Mathematics
replace carr_gpo = "m1" if (carr_gpo3 == "531" | carr_gpo3 == "532")				// Mathematics

* Reagrupar las profesiones STEM en grandes grupos
gen stem_list = ""
replace stem_list = "1_S" 	if (carr_gpo == "s0" | carr_gpo == "s1" | carr_gpo == "s2" /*| carr_gpo == "s3"*/)
replace stem_list = "2_T" 	if (carr_gpo == "t1" | carr_gpo == "t2")
replace stem_list = "3_E" 	if (carr_gpo == "e1" | carr_gpo == "e2")
replace stem_list = "4_M" if (carr_gpo == "m1")	
replace stem_list = "0_NoSTEM" if stem_list == ""

gen stem_group = ""
replace stem_group = "1_STEM" if stem_list != "0_NoSTEM"
replace stem_group = "2_NoSTEM" if stem_list == "0_NoSTEM"

tab stem_group clase2 [fw=fac_tri_sdem], mis

***** Limitando el grupo de analisis

keep if stem_group == "1_STEM" & ocup == 1

preserve
collapse (sum) ocup ocuptil (mean) edad2d escol2d (median) ingreso=ingocup_missing [fw=fac_tri_sdem], by(year qtr sinco`group')
drop if sinco == .
gen sex = 0
tempfile base
save `base', replace
restore

collapse (sum) ocup ocuptil (mean) edad2d escol2d (median) ingreso=ingocup_missing [fw=fac_tri_sdem], by(year qtr sex sinco`group')
drop if sinco == .
append using `base'
format ocup ocuptil ingreso %15.0fc
sort year qtr sex sinco
gen til = 100*(ocuptil/ocup)
order year qtr sex sinco

save "$drive/data_out/zcalculos_Y20`year'T0`trim'_`group'_stem", replace
export excel using "$drive/data_out/_ENOE_SINCO_stem.xlsx", sheet("sinco_Y20`year'T0`trim'_`group'_stem") firstrow(variables) sheetreplace

		}
	}
}

******************************
******************************
******************************

use "$drive/data_out/zcalculos_Y2024T04_1d", clear
gen x=1
foreach year in 23 24 {
	foreach trim in 1 2 3 4 {
		append using "$drive/data_out/zcalculos_Y20`year'T0`trim'_1d"
	}
}
tab x, mis
drop if x==1
drop x
save "$drive/data_out/zcalculos_1d_all", replace

export excel using "$drive/data_out/_ENOE_SINCO_stem.xlsx", sheet("sinco_1d_stem_all") firstrow(variables) sheetreplace

******************************
******************************
******************************

local extract_folder "$drive\data_out"
cd "`extract_folder'"
local archivos : dir . files "zcalculos_*.dta"
foreach f in `archivos' {
    erase "`f'"
}
