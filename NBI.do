

*************  nbi 1: hogar en vivienda inadecuada *************/
*******************************************************************/
clear all
use enaho01-2021-100,clear

* creamos la variable xnbi1 que tendrá el valor de 1 cuando el hogar cumpla con el nivel crítico
* Hogares que habitan en viviendas cuyo material predominante es:
* - Paredes exteriores de estera (p102==8);
* - Piso de tierra y paredes exteriores de quincha, piedra con barro, madera u otros materiales; (p103==6 & (p102==5 | p102==6 | p102==7 | p102==9))
* - Hogares que habitan en viviendas improvisadas: Cartón, lata, ladrillos y adobes superpuestos, entre otros. (p101==6)

gen xnbi1= p102==8 | (p103==6 & (p102==5 | p102==6 | p102==7 | p102==9)) | (p101==6)   
sort conglome vivienda 
collapse (max) xnbi1, by(conglome vivienda)
save nbi1, replace


************* nbi 2: hogar en vivienda hacinada  **************/
******************************************************************/

*total de habitaciones por vivienda*/
use enaho01-2021-100, clear
gen tothab=p104 if p104!=0 & p104 !=. 
gen nhogar= real(substr(hogar,2,1))
sort conglome vivienda 
collapse (sum) tothab (max) nhogar if tothab !=., by(conglome vivienda)
save nbi2_1, replace

***total de miembros de la vivienda***
use enaho01-2021-200, clear
gen mieperho= p204==1 if p203 != 8 & p203 != 9 /* & p203 != 10 */
sort conglome vivienda
collapse (sum) mieperho, by(conglome vivienda)
rename  mieperho mieperviv
save mieperviv,replace

*** total de miembros del hogar***/
use enaho01-2021-200, clear
gen mieperho= p204== 1 if p203 != 8 & p203 != 9 & p203 != 10
sort conglome vivienda hogar 
collapse (sum) mieperho, by(conglome vivienda hogar)
save mieperho,replace

*miembros vivienda*/
use nbi2_1, clear
sort conglome vivienda
merge conglome vivienda using mieperviv
drop if _m==2
tab _m
drop _m

*ajuste omisión de habitaciones de la viviendas*/
replace tothab=nhogar if tothab==0 | tothab ==. 

*calculo del NBI2*/
gen  xnbi2=(mieperviv/tothab)>3.4 if mieperviv !=. & tothab !=0

sort conglome vivienda 
keep conglome vivienda xnbi2
save nbi2, replace


******* nbi 3: hogare en vivienda sin servicio higienico **********/
***********************************************************************/

use enaho01-2021-100, clear
* utilizamos la variable recodificada t111a */
gen xnbi3 =  t111a == 6 | t111a == 9  | t111a == 7  if result == 1 | result == 2
sort conglome vivienda hogar 
collapse (max)xnbi3, by(conglome vivienda hogar)
save nbi3, replace


**** nbi 4: hogar con niños que no asisten a la escuela ****/
***************************************************************/

use enaho01a-2021-300, clear

gen xnbi4= p208a >= 6 & p208a <= 12 & (p203 == 1 | p203 == 3 | p203 == 5 | p203 == 7) & p303==2 if real(mes)>=1 & real(mes)<= 3 

replace xnbi4 = p208a >= 6 & p208a <= 12 & (p203 == 1 | p203 == 3 | p203 == 5 | p203 == 7) & (p306 == 2 | (p306 == 1 & p307 == 2)) if real(mes) >= 4 & real(mes) <= 12 

sort conglome vivienda hogar
collapse (max)xnbi4, by(conglome vivienda hogar)
save nbi4,replace


********** nbi 5: hogar con alta dependencia economica ***********/
********************************************************************/

use enaho01a-2021-300, clear
keep if p203==1
gen edujef = ((p301a == 1 | p301a == 2) | (p301a == 3 & (p301b == 0 | p301b == 1 | p301b == 2)) | (p301a == 3 & (p301c == 1 | p301c == 2 | p301c == 3))) & p203==1 
keep conglome vivienda hogar edujef
sort conglome vivienda hogar 
save edujefe, replace

use enaho01a-2021-500.dta
gen ocu= real(p500i) > 0 & ocu500 == 1 & p204 == 1  & p203 != 8 & p203 !=9
sort conglome vivienda hogar 
collapse (sum)ocu, by(conglome vivienda hogar)
save ocu, replace

**************/
use enaho01-2021-100.dta
sort conglome vivienda hogar 
merge conglome vivienda hogar using ocu 
drop _merge

sort conglome vivienda hogar 
merge conglome vivienda hogar using edujefe
drop _merge

sort conglome vivienda hogar 
merge conglome vivienda hogar using mieperho
drop _merge

gen dep = mieperho if ocu==0
replace dep = (mieperho - ocu)/ocu if ocu > 0 & ocu !=.

gen xnbi5 = edujef == 1 & dep > 3 
sort conglome vivienda hogar 
keep conglome vivienda hogar xnbi5
save nbi5, replace


***************** juntando las nbis ******************/

use enaho01-2021-100, clear
sort conglome vivienda

merge conglome vivienda using nbi1
drop _merge
sort conglome vivienda 

merge conglome vivienda using nbi2
drop _merge
sort conglome vivienda  hogar 

merge conglome vivienda hogar using nbi3
drop _merge
sort conglome vivienda  hogar 

merge conglome vivienda hogar using nbi4
drop _merge
sort conglome vivienda  hogar 

merge conglome vivienda hogar using nbi5
drop _merge

* reemplazamos las nbi por missiing cuando result>=3 */

recode xnbi1 (0=.) (1=.) if result>=3 
recode xnbi2 (0=.) (1=.) if result>=3 
recode xnbi3 (0=.) (1=.) if result>=3
recode xnbi4 (0=.) (1=.) if result>=3
recode xnbi5 (0=.) (1=.) if result>=3 

* etiquetamos variables y valores */

label var xnbi1 "hogar en vivienda inadecuada"
label define xnbi1 1 "vivienda inadecuada" 0 "vivienda adecuada"
label val  xnbi1 xnbi1

label var xnbi2 "hogar en vivienda hacinada"
label define xnbi2 1 "vivienda hacinada" 0 "vivienda no hacinada"
label val xnbi2 xnbi2

label var xnbi3 "Hogar en vivienda sin servicio higiénico"
label define xnbi3 1 "vivienda  sin servicio higienico" 0 "vivienda  con servicio higienico"
label val xnbi3 xnbi3

label var xnbi4 "hogar con niños que no asisten  a la escuela"
label define xnbi4 1 "hogar con niños que no asisten a la  escuela" 0 "hogar con niños que asisten a la escuela"
label val xnbi4 xnbi4

label var xnbi5 "hogar con alta dependencia economica"
label define xnbi5 1 "hogar con alta dependencia economica" 0 "hogar sin alta dependencia economica"
label val xnbi5 xnbi5

* Calculamos la incidencia de pobreza total y extrema con base en NBI */
************************************************************************

keep if result==1 | result==2
g sum_nbi=xnbi1+xnbi2+xnbi3+xnbi4+xnbi5

g pobre_total=0
replace pobre_total=1 if sum_nbi>=1

g pobre_extremo=0
replace pobre_extremo=1 if sum_nbi>=2

save, replace

* traemos las variables factor07, mieperho y pobreza del archivo sumaria-2021 */ 

use sumaria-2021, clear
sort conglome vivienda hogar
save, replace

use enaho01-2021-100, clear
sort conglome vivienda hogar
save, replace

merge 1:1 conglome vivienda hogar using sumaria-2021, keepus(mieperho factor07 pobreza)
save, replace

* definimos el diseño de la muestra

g facpob=factor07*mieperho
svyset conglome [pw=facpob], strata(estrato)

* calculamos la incidencia de pobreza

svy: mean pobre_total pobre_extremo



/* Crear variable departamento */

g dep=substr(ubigeo,1,2)
destring dep, replace
label define dep ///
1 "Amazonas" /// 
2 "Ancash" ///
3 "Apurímac" ///
4 "Arequipa" ///
5 "Ayacucho" ///
6 "Cajamarca" ///
7 "Prov. Const. del Callao" ///
8 "Cusco" ///
9 "Huancavelica" ///
10 "Huánuco" ///
11 "Ica" ///
12 "Junín" ///
13 "La Libertad" ///
14 "Lambayeque" ///
15 "Lima" ///
16 "Loreto" ///
17 "Madre de Dios" ///
18 "Moquegua" ///
19 "Pasco" ///
20 "Piura" ///
21 "Puno" ///
22 "San Martín" ///
23 "Tacna" ///
24 "Tumbes" ///
25 "Ucayali", replace

label value dep dep
label var dep "departamento"


/* Cuadro con la estimación de Pobreza Total por departamento */

collect clear

forvalues i = 1/25 {
    quietly: collect _r_b _r_se _r_ci: svy: mean pobre_total if dep==`i' 
}

collect style cell result[_r_b _r_se _r_ci], nformat(%8.5f)
collect label levels result _r_b "Incidencia", modify
collect label levels cmdset ///
1 "Amazonas" /// 
2 "Ancash" ///
3 "Apurímac" ///
4 "Arequipa" ///
5 "Ayacucho" ///
6 "Cajamarca" ///
7 "Prov. Const. del Callao" ///
8 "Cusco" ///
9 "Huancavelica" ///
10 "Huánuco" ///
11 "Ica" ///
12 "Junín" ///
13 "La Libertad" ///
14 "Lambayeque" ///
15 "Lima" ///
16 "Loreto" ///
17 "Madre de Dios" ///
18 "Moquegua" ///
19 "Pasco" ///
20 "Piura" ///
21 "Puno" ///
22 "San Martín" ///
23 "Tacna" ///
24 "Tumbes" ///
25 "Ucayali", modify

collect layout (cmdset) (result)


* Metodo Integrado LP vs NBI

g pobre_lp=pobreza<=2
g pobre_nbi=sum_nbi>=1
label var pobre_lp "Pobreza por LP"
label var pobre_nbi "Pobreza por NBI"
label define pobre 1 "Pobre" 0 "No pobre"
label value pobre_lp pobre
label value pobre_nbi pobre

svyset conglome [pw=facpob], strata(estrato)
svy: tab pobre_nbi pobre_lp, se ci cv








