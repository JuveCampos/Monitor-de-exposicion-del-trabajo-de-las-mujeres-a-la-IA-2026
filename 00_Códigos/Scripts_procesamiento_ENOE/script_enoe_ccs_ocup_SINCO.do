
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

tab sinco3d sex [fw=fac_tri_sdem], mis
tab sinco2d sex [fw=fac_tri_sdem], mis
tab sinco1d sex [fw=fac_tri_sdem], mis

destring anios_esc, generate(escol2d)
replace escol2d = . if anios_esc == "99"

gen edad2d = eda
replace edad2d = . if eda == 98

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

save "$drive/data_out/zcalculos_Y20`year'T0`trim'_`group'", replace
export excel using "$drive/data_out/_ENOE_SINCO.xlsx", sheet("sinco_Y20`year'T0`trim'_`group'") firstrow(variables) sheetreplace

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

export excel using "$drive/data_out/_ENOE_SINCO.xlsx", sheet("sinco_1d_all") firstrow(variables) sheetreplace

******************************
******************************
******************************

local extract_folder "$drive\data_out"
cd "`extract_folder'"
local archivos : dir . files "zcalculos_*.dta"
foreach f in `archivos' {
    erase "`f'"
}
