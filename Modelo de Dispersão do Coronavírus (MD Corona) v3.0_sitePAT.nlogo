turtles-own
  [ sick?                ;; if true, the turtle is infectious
    estatico?            ;; se true a tartaruga fica parada durante a simulacao
    remaining-immunity   ;; how many weeks of immunity the turtle has left
    sick-time            ;; how long, in weeks, the turtle has been infectious
    age                  ;; how many weeks old the turtle is
]

globals
  [ infectado            ;; number os people infected
    %infectadoTotal      ;; what % of the population is infectious
    %immune              ;; what % of the population is immune
    numero-mortos        ;; contador para pessoas que morreram por acao da doenca apenas
    %numero-mortos       ;; % das pessoas que morreram por acao da doenca apenas
    reinfection-period   ;; periodo em dias para reintroduzir uma pessoa doente (simula transito de pessoas)
    reproduce-period     ;; quantidade de dias entre tentativas de reprodução
    lifespan             ;; the lifespan of a turtle
    chance-reproduce     ;; the probability of a turtle generating an offspring each tick
    carrying-capacity    ;; the number of turtles that can be in the world at one time
    immunity-duration    ;; how many weeks immunity lasts
    periodo-de-transmissão ;; for how long the person can contaminate
    número-de-pessoas    ;; converte densidade absoluta para numero de pessoas considerando a grade 40x40!
    taxa-transmissao     ;; recebe a taxa de transmissao com inpute de IDH e converte para porcentagem.
    chance-de-recuperação ;; defini a porcentagem de recuperacao da doenca
]

;; The setup is divided into four procedures
to setup
  clear-all
  setup-constants
  setup-turtles
  update-global-variables
  update-display
  reset-ticks
end

;; We create a variable number of turtles of which 10 are infectious,
;; and distribute them randomly
to setup-turtles
  create-turtles número-de-pessoas
    [ setxy random-xcor random-ycor
      set age random lifespan
      set sick-time 0
      set remaining-immunity 0
      set size 1.0  ;; easier to see
      set estatico? true ;; toda tartaruga e criada estatica
      get-healthy ]
  ask n-of 1 turtles    ;; number that begin infected
    [ get-sick ]
  ask n-of (número-de-pessoas * (1 - porcentagem-de-confinados / 100)) turtles
    [get-free]
end

to get-free
  set estatico? false
end

to get-locked-up
  set estatico? true
end

to get-sick ;; turtle procedure
  set sick? true
  set remaining-immunity 0
  set infectado infectado + 1
end

to get-healthy ;; turtle procedure
  set sick? false
  set remaining-immunity 0
  set sick-time 0
end

to become-immune ;; turtle procedure
  set sick? false
  set sick-time 0
  set remaining-immunity immunity-duration
end

;; This sets up basic constants of the model.
to setup-constants
  set lifespan 75 * 365      ;; 50 times 52 days = 50 years = 2600 weeks old
  set carrying-capacity 1000
  set chance-reproduce 1
  set periodo-de-transmissão 14
  set immunity-duration 365 ;; fixa em 1 ano
  set numero-mortos 0
  set reinfection-period 90
  set reproduce-period 360 ;; quantidade de dias entre tentativas de reprodução
  set número-de-pessoas 0.03531 * densidade-populacional
  set chance-de-recuperação 99.3
  ;; para ler a taxa de transmissao
  if IDH/IPC = "muito baixo" [set taxa-transmissao 46]
  if IDH/IPC = "baixo" [set taxa-transmissao 44]
  if IDH/IPC = "medio" [set taxa-transmissao 42]
  if IDH/IPC = "alto" [set taxa-transmissao 40]
  if IDH/IPC = "muito alto" [set taxa-transmissao 39]
end




to go
  ask turtles [
    get-older
    cond-move
    if sick? [ recover-or-die ]
    ifelse sick? [ infect ] [ maybe-reproduce ]
  ]
  if ticks mod reinfection-period = 0 [
    ask one-of turtles  [get-sick] ;; um individuo fica doente
  ]
  ;; início confinamento variável
  let num-confinados count turtles with [ estatico? ]
  let para-confinar ((count turtles) * (porcentagem-de-confinados / 100))
  let delta (para-confinar - num-confinados)
  ifelse delta > 0
    [ask n-of delta turtles with [ not estatico? ] [get-locked-up]]
    [ let minus-delta delta * (-1)
      ask n-of minus-delta turtles with [ estatico? ] [get-free]]
  ;; fim confinamento variável
  update-global-variables
  update-display
  tick
end

to maybe-reproduce
  ;; Mude o valor de reproduce-period para determinar a
  ;; a cada quantos dias a pessoa pode se reproduzir
  if ticks mod reproduce-period = 0 [
   reproduce
  ]
end

to cond-new-host
  if ticks mod reinfection-period = 0
    [ hatch 1
      [ set age  20 * 360 ;; essa idade é meio arbitraria
        get-free
        lt 45 fd 1
        get-sick
      ]
    ]
end

to update-global-variables
  if count turtles > 0
    [ set %infectadoTotal (  infectado / número-de-pessoas) * 100
      set %immune (count turtles with [ immune? ] / número-de-pessoas) * 100
      set %numero-mortos (  numero-mortos / número-de-pessoas) * 100
  ]
end
;;et %infectadoTotal (  infectado / count turtles) * 100
to update-display
  ask turtles
    [ set shape "person" ;;  if shape != forma-pessoa-ou-bola [ set shape forma-pessoa-ou-bola ] ;; se quiser restabeleser person, b
      set color ifelse-value sick? [ red ] [ ifelse-value immune? [ grey ] [ green ] ] ]
end

;;Turtle counting variables are advanced.
to get-older ;; turtle procedure
  ;; Turtles die of old age once their age exceeds the
  ;; lifespan (set at 50 years in this model).
  set age age + 1
  if age > lifespan [ die ]
  if immune? [ set remaining-immunity remaining-immunity - 1 ]
  if sick? [ set sick-time sick-time + 1 ]
end

;; So move se turtle nao eh estatico
to cond-move
  if not estatico? [move]
end

;; Turtles move about at random.
to move ;; turtle procedure
  rt random 100
  lt random 100
  fd 1
end

;; If a turtle is sick, it infects other turtles on the same patch.
;; Immune turtles don't get sick.
to infect ;; turtle procedure
  ask other turtles-here with [ not sick? and not immune? ]
    ;; [ if random-float 100 < chance-de-transmissão
    [ if random-float 100 < taxa-transmissao
      [ get-sick ] ]
end

;; Once the turtle has been sick long enough, it
;; either recovers (and becomes immune) or it dies.
to recover-or-die ;; turtle procedure
  if sick-time > periodo-de-transmissão                       ;; If the turtle has survived past the virus' duration, then
    [ ifelse random-float 100 < chance-de-recuperação   ;; either recover or die
      [ become-immune ]
      [ set numero-mortos numero-mortos + 1
        die ]
    ]
end

;; If there are less turtles than the carrying-capacity
;; then turtles can reproduce.
to reproduce
  if count turtles < carrying-capacity and random-float 100 < chance-reproduce
    [ hatch 1
      [ set age  360
        lt 45 fd 1
        get-healthy ] ]
end

to-report immune?
  report remaining-immunity > 0
end

to startup
  setup-constants ;; so that carrying-capacity can be used as upper bound of number-people slider
end


; Copyright 1998 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
243
102
505
365
-1
-1
6.2
1
10
1
1
1
0
1
1
1
-20
20
-20
20
1
1
1
ticks
30.0

BUTTON
242
53
367
97
Resetar
Setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
374
53
494
97
Iniciar/Parar
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

PLOT
520
105
860
398
População
dias
pessoas %
0.0
50.0
0.0
50.0
true
true
"" ""
PENS
"infectado" 1.0 0 -2674135 true "" "plot (count turtles with [ sick? ]) * 100 / número-de-pessoas "
"imune" 1.0 0 -7500403 true "" "plot (count turtles with [ immune? ]) * 100 / número-de-pessoas "

MONITOR
521
54
644
99
Total de infectados %
%infectadoTotal
1
1
11

MONITOR
647
54
732
99
imunidade %
%immune
1
1
11

MONITOR
804
54
859
99
dias
ticks
1
1
11

SLIDER
0
242
220
275
porcentagem-de-confinados
porcentagem-de-confinados
0
100
0.0
1
1
%
HORIZONTAL

MONITOR
735
54
801
99
mortos %
%numero-mortos
1
1
11

TEXTBOX
233
367
533
400
Copyright 2020 José Paulo Guedes Pinto, Patrícia Camargo Magalhães, Carlos da Silva dos Santos [CC BY-NC-SA 3.0]
10
0.0
1

TEXTBOX
0
0
220
33
1º PASSO: defina IPC na localidade usando a tabela abaixo
12
0.0
1

TEXTBOX
245
0
495
33
2º PASSO: aperte o botão Resetar e depois Iniciar/Parar
12
0.0
1

TEXTBOX
520
0
833
25
3º PASSO: Acompanhe a simulação no gráfico abaixo \n
12
0.0
1

CHOOSER
0
105
218
150
IDH/IPC
IDH/IPC
"muito alto" "alto" "medio" "baixo" "muito baixo"
4

SLIDER
0
56
220
89
densidade-populacional
densidade-populacional
4000
28000
14100.0
100
1
hab/Km2
HORIZONTAL

TEXTBOX
0
206
220
246
O confinamento pode mudar durante a simulação 
12
0.0
1

@#$#@#$#@
## O QUE É ISSO?

A construção desse modelo foi inspirada pelo sucesso da divulgação do estudo desenvolvido por Harry Stevens e publicado na página do jornal Washington Post dia 14 de Março de 2020 (https://www.washingtonpost.com/graphics/2020/world/corona-simulator/) onde o autor explora diferentes cenarios de atenuação e supressão social para conter o avanço do coronavírus. 

Para a construção do Modelo de Dispersão do Coronavírus (MD Corona), modificamos o modelo original Vírus (Wilensky, 1998) presente na biblioteca do software livre NetLogo (Wilensky, 1999). O modelo original foi inspirado pelo artigo de Yorke et al (1979) em que biólogos ecologistas sugeriram um número de fatores que poderiam influenciar a sobrevivência de um vírus com transmissão direta entre uma população. As modificações específicas que fazem parte do MD Corona serão destacadas abaixo.

## COMO ELE FUNCIONA
O simulador é iniciado com 3 parâmetros: densidade populacional, IDH e letalidade. A densidade populacional (mínimo 3400 ha/Km2 e máximo 34000 ha/Km^2) é convertida pelo modelo em número de pessoas que estarão distribuídas aleatoriamente no ambiente Entre essas pessoas uma está infectada desde o início.  O IDH (Índice de desenvolvimento Humano) ou IPC (Índice de proteção - COVID-19) tem 5 escalas  (muito alto, alto,  médio, baixo,  muito baixo) e é uma medida da vulnerabilidade do local. 
O modelo traduz cada elemento da escala em uma probabilidade efetiva de transmissão (quanto maior o IDH, menor a chance de transmissão) definida pela calibração com a cidade de Nova York e a escala de IDH como sendo: muito alto=55%, alto= 57%, médio=59%, baixo = 61%, muito baixo =63%. Por fim, a letalidade possui dois níveis: 1% e 2%. 

O parâmetro CONFINAMENTO permite parar uma porcentagem das pessoas no ambiente, o que reduz a velocidade da transmissão. Ele é dinâmico, ou seja, pode ser alterado durante a simulação sem a necessidade de resetar o simulador,  como ocorre quando modificamos os demais parâmetros. 
No modelo as pessoas morrem de infecção ou de idade (75 anos). Quando a população cai abaixo da "capacidade máxima" do ambiente (fixa em 1200 neste modelo), pessoas saudáveis podem produzir descendentes saudáveis (mas suscetíveis à contaminação). Outro fator importante é a introdução, a cada 90 dias, de um agente infectado pelo vírus, o que acabou por tornar o ambiente do modelo aberto e mais condizente com a realidade



### Rotatividade da população


À medida que os indivíduos morrem, alguns que morrerem serão infectados, outros serão suscetíveis e outros serão imunes. Todos os novos indivíduos que nascerem, substituindo os que morrerem, serão saudáveis e suscetíveis. As pessoas podem morrer do vírus, cujas chances são determinadas pelo slider CHANCE-DE-RECUPERAÇÃO, ou podem morrer de velhice.

Nesse modelo as pessoas morrem de velhice com 75 anos de idade. A taxa de reprodução 
é constante. A cada iteração, se a "capacidade máxima" não tiver sido atingida, cada indivíduo saudável têm 1% de chance de se reproduzir. 

A cada 90 dias uma pessoa infectada é introduzinda no ambiente.


### Grau de imunidade

Se uma pessoa for infectada  e se recuperar, o quão imune ela estará do vírus? 
Geralmente assumimos que a imunidade dura a vida inteira e é garantida, mas, em alguns casos, a imunidade desaparece com o tempo e a imunidade pode não ser absolutamente segura. Como no modelo original do Netlogo, a imunidade é segura, mas dura apenas um ano.

### Capacidade de transmissão

Com que facilidade o vírus se espalha? Alguns vírus com os quais estamos familiarizados se espalham com muita facilidade. Alguns vírus se espalham com pouco contato todas as vezes. Outros (o vírus HIV por exemplo, que é responsável pela Aids) requerem contato significativo, muitas vezes repedidas, antes da transmissão do vírus. Neste modelo, a capacidade de transmissão é determinada pelo IDH/IPC.

### Duração da janela de transmissão

Quanto tempo uma pessoa fica infectada antes de se recuperar ou morrer? Esse período de tempo é essencialmente a janela de oportunidade do vírus para transmissão para novos hospedeiros. Neste modelo, a duração da janela de transmissão é fixa em 18 dias.

### Confinamento
 E se ao invéz de circular livremente as pessoas ficassem paradas no ambiente? O confinamento das pessoas em suas casas é uma das medidas sugeridas para conter a transmissão do Corona vírus.  Essa variável não está presente no modelo original "Virus" do Netlogo. No MD Corona, o número de pessoas confinadas é determinado pelo slider PORCENTAGEM-DE-CONFINADOS. Note que essa varável pode ser alterada durante a simulação (sem precisar Resetar).

### Parâmetros relacionados ao código

Três parâmetros importantes deste modelo são definidos como constantes no código (consulte o procedimento `inicializar-constantes`). Eles podem ser expostos como sliders, se desejado. O tempo de vida das pessoas, definidas como turtles (tartarugas) no código,  é de 75 anos (expectativa de vida no Brasil em 2020), a capacidade máxima de pessoas do mundo é de 1200 e a taxa de natalidade é de 1 em 100 chances de se reproduzir por rodada quando o número de pessoas é menor que a capacidade de máxima. No modelo original do Netlogo a duração da imunidade também é constante e fixa em 52 semanas. No MD corona a imunidade é uma variável (definida acima).

## COMO USAR O MD CORONA

Cada "volta" representa um dia na escala de tempo deste modelo. Essa é uma importante modificação do modelo original do Netlogo em que a escala de tempo era definida em semanas.

O slider DESNSIDADE-POPULACIONAL define o número de pessoas entre 0 e 1200 que serão aleatóriamente distribuidas no ambiente.

A opção IDH/IPC (Indice de Proteção - COVID-19) determina a probabilidade de transmissão do vírus quando uma pessoa infectada e outra suscetível ocupar o mesmo sitio no ambiente. 

A opção LETALIDADE é o inverso da probabilidade de uma pessoa infectada se  recuperar e ficar imunidade. Ele pode de ser 1% ou 2%.


O botão RESETAR recomeça os gráficos e distribui aleatoriamente o número de pessoas (definida pela densidade populacional). Todas as pessoas, exceto 1, são consideradas saudáveis e suscetíveis ao vívus e definidas com a cor verde.  O programa fixa  1 pessoas inicialmente infectadas que são definidas pela cor vermelha. Todos com idades distribuídas aleatoriamente. O botão INICIAR/PARAR inicia a simulação e os gráficos e também para a simulação.

Quatro monitores de saída mostram a porcentagem da população infectada, a porcentagem imune, a porcentagem de mortos e o número de dias que se passaram. O gráfico mostra (em suas respectivas cores) o número de pessoas infectadas e imunes. 

## PARA PRESTAR ATENÇÃO 

As variáveis controladas pelos sliders interagem para influenciar a probabilidade de o vírus prosperar nessa população. Observe que, em todos os casos, essas variáveis devem criar um equilíbrio no qual haja um número adequado de receptores (pessoas) em potencial disponível para o vírus e o qual o vírus possa acessar adequadamente.

Freqüentemente haverá inicialmente uma explosão de infecção, já que ninguém na população é imune. Isso se aproxima do "surto" inicial de uma infecção viral em uma população, que geralmente tem conseqüências devastadoras para os seres humanos envolvidos. Logo, porém, o vírus se torna menos comum à medida que a dinâmica da população muda. O que finalmente acontece com o vírus é determinado pelos parâmetros.

Observe que os vírus que são muito bem sucedidos no início (infectando quase todo mundo) podem não sobreviver a longo prazo. Como todos os infectados geralmente morrem ou se tornam imunes como resultado, o número potencial de hospedeiros é frequentemente limitado.

## VISUALIZAÇÃO

A visualização em círculos do modelo vem das diretrizes apresentadas em
Kornhauser, D., Wilensky, U., & Rand, W. (2009).
 http://ccl.northwestern.edu/papers/2009/Kornhauser,Wilensky&Rand_DesignGuidelinesABMViz.pdf.


No nível básico, os impedimentos de percepção surgem quando excedemos as limitações do nosso baixo nível de sistema visual. Recursos visuais difíceis de distinguir podem desativar nossos recursos de processamento pré atentos. O processamento pré-atento podem ser dificultados por outros fenômenos cognitivos, como a interferência entre as características visuais (Healey 2006).

A visualização do círculo neste modelo deve facilitar a visualização de quando os agentes interagem porque é mais fácil se sobrepor entre os círculos do que entre as formas de "pessoas". Na visualização do círculo, os círculos são mesclados para criar novas formas compostas. Assim, é mais fácil perceber novas formas compostas na visualização de círculos.
A visualização do círculo facilita a sua visualização do que está acontecendo?

## MODELOS RELACIONADOS

* HIV
* Virus em uma rede

## CREDITOS E REFERÊNCIAS 

Este modelo pode mostrar uma visualização alternativa usando círculos para representar as pessoas. Ele usa técnicas de visualização conforme recomendado no artigo:
Kornhauser, D., Wilensky, U., & Rand, W. (2009). Design guidelines for agent based model visualization. Journal of Artificial Societies and Social Simulation, JASSS, 12(2), 1.

## COMO CITAR

Se você mencionar este modelo ou o software NetLogo numa publicação, pedimos para que inclua as citações abaixo.

Para o modelo Virus:

* Wilensky, U. (1998).  NetLogo Virus model.  http://ccl.northwestern.edu/netlogo/models/Virus.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Para o modelo MD Corona:

* Guedes Pinto, José Paulo; Magalhães, Patrícia; Santos Carlos Silva. (2020). Modelo de Dispersão Comunitária Coronavírus (MD Corona), Universidade Federal do ABC, São Bernardo do Campo, Brasil. 

Por favor cite o software NetLogo como:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2020 José Paulo Guedes Pinto, Patrícia Camargo Magalhães, Carlos da Silva dos Santos

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

Copyright 1998 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

Esse trabalho está sob a licença Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  Para ver uma cópia dessa licença visite: https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Liceças comercial também estão dispponíveis. Para indigar sobre isso, favor contactar Uri Wilensky at uri@northwestern.edu.

O modelo MD Corona foi criado para gerar dados para o working paper "Simulando a evolução da transmissão comunitária do coronavírus através do Modelo M D Corona." de autoria do José Paulo Guedes Pinto, Patrícia Magalhães e Carlos da Silva Santos. 2020.


This model was created as part of the project: CONNECTED MATHEMATICS: MAKING SENSE OF COMPLEX PHENOMENA THROUGH BUILDING OBJECT-BASED PARALLEL MODELS (OBPML).  The project gratefully acknowledges the support of the National Science Foundation (Applications of Advanced Technologies Program) -- grant numbers RED #9552950 and REC #9632612.

This model was converted to NetLogo as part of the projects: PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. The project gratefully acknowledges the support of the National Science Foundation (REPP & ROLE programs) -- grant numbers REC #9814682 and REC-0126227. Converted from StarLogoT to NetLogo, 2001.

<!-- 1998 2001 -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
