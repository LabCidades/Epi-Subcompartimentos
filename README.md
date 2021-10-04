# Modelo COVID-19 Brasil

COVID-19 Modeling work at [UNINOVE](https://www.uninove.br) for Brazil.

Website at https://codatmo.github.io/UNINOVE_Brazil/.

## Team

* Senior Researcher: [Breck Baldwin](https://github.com/breckbaldwin)
* Lead Researcher: [Jose Storopoli](https://github.com/storopoli)
* Associate Researcher:  [Alessandra Pellini](https://github.com/acgpellini)
* Assistant Researcher: [Andre Santos](https://github.com/andrelmfsantos)
* Undergraduate Senior Assistant: [João Vinícius Vieira Nóia](https://github.com/vinivieiran)
* Undergraduate Assistants:
  * [Elias Noda](https://github.com/Elias-Noda)
  * [Paula Fraga](https://github.com/Paula-Fraga)
  * [Camila Brichta](https://github.com/camibrichta)
  * [Leandro dos Santos](https://github.com/leandrors91)
  * [Junior De Sousa Silva](https://github.com/juniorghostinthewires)

## Modelo Epidemiológico Compartimental Usando o Truque de Corrente Linear para COVID-19

### Abstract (in Portuguese)

Demonstrar o uso do truque de corrente linear (linear chain trick - LCT) em modelos epidemiológicos compartimentais para COVID-19. LCT modela tempos de espera em transições de compartimentos usando subcompartimentos com uma distribuição Erlang. MÉTODOS: Demonstramos LCT usando dados de óbitos por COVID-19, obtidos dos boletins das Secretarias Estaduais de Saúde desde 25/02/2020 até 04/05/2021. O modelo é composto por compartimentos: (S) susceptible, (E) exposed, (I) infectious, (R) recovered, (T) terminally ill, e (D) dead. Os compartimentos que usam LCT são E, I e T, dando origem a subcompartimentos E1, E2, I1, I2, T1, T2, recebendo a nomenclatura de SEEIITTD. A taxa de contaminação é modelada com funções lineares por partes para cada semana. O modelo foi elaborado e implementado usando estatística Bayesiana e solucionadores de equações diferenciais estocásticas com o software Stan. RESULTADOS: O modelo obteve taxa de erro de ±85 mortes semanais usando mortes previstas versus mortes reais. A mediana das medianas diárias das taxas de reprodução semanais é 1,03 e a mediana da taxa de letalidade global das 63 semanas é 0,99%. CONCLUSÕES: O LCT é uma técnica recente na literatura e prática epidemiológica de modelos compartimentais; porém, já é adotado por instituições como University of Cambridge e University of Liverpool. LCT implementa pressupostos de tempos de espera com uma distribuição Erlang ao decompor compartimentos em subcompartimentos, o que ocasiona pressupostos de tempo de espera com propriedades desejáveis: e.g. falta de memória fraca (weak memorylessness).

### Métodos

Fontes de Dados:
* Mortes: [Consórcio de Veículos da Imprensa](https://brasil.io/dataset/covid19/caso_full/)
* Terminalmente Doentes: [Internações por SRAG](https://opendatasus.saude.gov.br/dataset/bd-srag-2020)

Modelos Bayesianos epidemiológicos usando [`Stan`](https://mc-stan.org)
