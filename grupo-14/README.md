
# **Atividade Prática II**

## **Autor(es):**
- Luiz Augusto Feiten Cisne (20204846)
- Miguel Sória da Luz (22100860)

## **Data:**
- 03/11/2024

---

## **Sumário**

1. [Introdução](#introdução)
2. [Visão Geral do Projeto](#visão-geral-do-projeto)
3. [Descrição dos Módulos](#descrição-dos-módulos)
    - [Módulo 1: Camada de Registradores](#módulo-1-nome-do-módulo)
    - [Módulo 2: Camada de Subtração](#módulo-2-nome-do-módulo)
    - [Módulo 3: Camada de valor Absoluto](#módulo-3-nome-do-módulo)
    - [Módulo 4: Arvore de Somas](#módulo-4-nome-do-módulo)
    - [Módulo 5: Acumulador Da Sad](#módulo-5-nome-do-módulo)
    - [Módulo 6: Acumulador De endereços](#módulo-6-nome-do-módulo)
    - [Módulo 7: Bloco de Controle](#módulo-7-nome-do-módulo)
    - [Módulo 8: Bloco Operativo](#módulo-8-nome-do-módulo)
    - [Módulo 9: SAD](#módulo-9-nome-do-módulo)
4. [Simulações e Resultados](#simulações-e-resultados)
5. [Conclusão](#conclusão)


---

## **Introdução**

Nesse projeto tentamos realizar o desafio de fazer uma SAD genérica, que seira suficiente para compreender ambas as versões da SAD(v1. e v3.). Mas infelizmente o projeto não foi fácil e não conseguimos uma implementação perfeita. Nossa implementação funciona razoavelmente bem mas tem dois defeitos. Ela dá overflow pra valores muito autos de amostras de 32 bits. E não funciona para valores impares de amostras sendo lidas em paralelo Infelizmente Não conseguimos achar uma solução funcional, visto que seria necessário fazer um ajuste com uma logica genérica que seira um pouco mais complexa para a implementação. 
	     

## **Visão Geral do Projeto**

O projeto implementa uma SAD muito parecida com a vista nas aula da parte teórica. Ela é composta em essência por 9 módulos, sendo alguns deles divididos em camadas usando uma abordagem horizontal da logica de construção para facilitar a depuração e a reutilização dos blocos mais tarde em projetos futuros. Quanto ao caminho dos dados eles são tratados da seguinte maneira: primeiro são armazenados na camada de registradores, depois são subtraídos na camada de subtração e tem seu valor ajustado para valores positivos na camada de valores absolutos, em seguida vão para a árvore de somas e agora quase no final da cadeia  tem seus novos valores acumulados no acumulador de valores da Sad e por fim são armazenados no registrador que deve estar ligado a um outro sistema digital.    

## **Descrição dos Módulos**

### **Módulo 1: Camada de Registradores**
- **Nome do Arquivo: sample_registers_layer** 
- **Função:** Armazena os valores originais das amostras candidatas  e originais, onde são dividas em _b_ bits correspondendo a _P_ pares de amostras originais e candidatas. Elas são segmentadas para que possam caber nos registadores 		
- **Entradas:**
  - *Sample_ori:* Amostra original  
  - *Sample_can:* Amostra candidata 
- **Saídas:**
  - * pA_segments: * corresponde a uma parte da amostra original de um par específico.
  - * pB_segments:* corresponde a uma parte da amostra original de um par específico.

- **Código VHDL:**
```vhdl
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY sample_registers_layer IS
    GENERIC (
        B : INTEGER := 8;  -- Número de bits por amostra
        P : INTEGER := 4   -- Número de pares de amostras
    );
    PORT (
        clk : IN std_logic;
        rst : IN std_logic;
        carga : IN std_logic;
        pA_in : IN std_logic_vector(P*B-1 DOWNTO 0);  -- Entradas concatenadas para amostras de pA
        pB_in : IN std_logic_vector(P*B-1 DOWNTO 0);  -- Entradas concatenadas para amostras de pB
        pA_out : OUT std_logic_vector(P*B-1 DOWNTO 0); -- Saída concatenada das amostras de pA
        pB_out : OUT std_logic_vector(P*B-1 DOWNTO 0)  -- Saída concatenada das amostras de pB
    );
END ENTITY sample_registers_layer;

ARCHITECTURE rtl OF sample_registers_layer IS
    -- Sinais para conectar as saídas de cada registrador instanciado
    SIGNAL reg_pA : std_logic_vector(P*B-1 DOWNTO 0);
    SIGNAL reg_pB : std_logic_vector(P*B-1 DOWNTO 0);
    
BEGIN
    -- Gerar instâncias do componente `registrador` para cada par de amostras
    gen_registers : FOR i IN 0 TO P-1 GENERATE
        -- Instância para cada registro de pA
        pA_reg_inst : ENTITY work.registrador
            GENERIC MAP (N => B)
            PORT MAP (
                clk => clk,
                rst => rst,
                carga => carga,
                D => pA_in((i+1)*B-1 DOWNTO i*B), -- Parte correspondente de pA_in
                Q => reg_pA((i+1)*B-1 DOWNTO i*B) -- Parte correspondente de pA_out
            );

        -- Instância para cada registro de pB
        pB_reg_inst : ENTITY work.registrador
            GENERIC MAP (N => B)
            PORT MAP (
                clk => clk,
                rst => rst,
                carga => carga,
                D => pB_in((i+1)*B-1 DOWNTO i*B), -- Parte correspondente de pB_in
                Q => reg_pB((i+1)*B-1 DOWNTO i*B) -- Parte correspondente de pB_out
            );
    END GENERATE gen_registers;

    -- Atribuir os sinais internos aos sinais de saída
    pA_out <= reg_pA;
    pB_out <= reg_pB;

```
- **Instanciação:**

 ```vhdl
  -- Instância do módulo de subtração usando as saídas segmentadas de pA e pB
    subtraction_inst : ENTITY work.subtraction_module
        GENERIC MAP (
            N => B,
            P => P
        )
        PORT MAP (
            pA => pA_segments,  -- Conectar a saída segmentada pA_segments como entrada
            pB => pB_segments,  -- Conectar a saída segmentada pB_segments como entrada
            diff => diff        -- Saída de 9 bits por subtração
        );
```
 

### **Módulo 2: Camada de Subtração**
- **Nome do Arquivo: subtraction_module** 
- **Função:** É responsável por fazer as subtrações das amostras que  entram no bloco.
- **Entradas:**
  - * pA_segments*:  divide o vetor Pa em seguimentos;
  - * pB_segments  :* divide o vetor Pb em seguimentos. 
- **Saídas:**
  - *diff: * Vetor contendo as diferenças calculadas entre cada par de amostras de pA e pB. Cada diferença tem B+1 bits (um bit extra para o sinal).
- **Código VHDL:**
```vhdl
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY subtraction_module IS
    GENERIC (
        N : INTEGER := 8;  -- Número de bits por entrada
        P : INTEGER := 4   -- Número de pares de entradas
    );
    PORT (
        pA, pB : IN std_logic_vector(P*N-1 DOWNTO 0);  -- Vetores concatenados de entradas
        diff : OUT std_logic_vector(P*(N+1)-1 DOWNTO 0)    -- Vetor de saídas com as diferenças (9 bits)
    );
END ENTITY subtraction_module;

ARCHITECTURE rtl OF subtraction_module IS
BEGIN
    gen_diff : FOR i IN 0 TO P-1 GENERATE
        -- Subtração: pA[i] - pB[i], com 9 bits para acomodar o bit de sinal
        diff_proc : PROCESS (pA, pB)
        BEGIN
            diff((i+1)*(N+1)-1 DOWNTO i*(N+1)) <= 
                std_logic_vector(resize(signed(pA((i+1)*N-1 DOWNTO i*N)), N+1) - 
                                 resize(signed(pB((i+1)*N-1 DOWNTO i*N)), N+1));
        END PROCESS;
    END GENERATE gen_diff;

END ARCHITECTURE rtl;

```
### **Módulo 3: Camada de valor Absoluto**
- **Nome do Arquivo: absolute** 
- **Função:**   É a parte que faz a operação de modulo do vetor de saída da camada de subtração, após a operação o resultado é truncado _B_ bits, tirando o bit de sinal 
- **Entradas:**
  - *diff:* Vetor que é partido e vai para cada um dos blocos específicos . 
  
- **Saídas:**
  - *abs_out:* O valor absoluto da diferença, truncado para B bits.


### **Módulo 4:  Arvore de Somas**
- **Nome do Arquivo: adderTree** 
- **Função:**Fazer a soma dos valores absolutos, afim de gerar uma soma parcial. O somador em árvore recebe _P_ valores e realiza uma adição parcial  
- **Entradas:**
  - *inputs:* Vetor contendo o valores absolutos já truncados .
  
- **Saídas:**
  - *sum_out:* A soma dos valores absolutos das diferenças .


### **Módulo 5: Acumulador Da Sad**
- **Nome do Arquivo:** 
- **Função:** Descreva a função principal do módulo.
- **Entradas:**
  - *soma_in:* Valor gerado pela árvore de soma, é um valor parcial 
  - *clk:* Sinal do relógio
  - *rst:* sinal de reinicio 
  - *zsoma:* Sinal de controle do multiplexador que decide entre somar o novo valor ou manter o valor atual do 	   acumulador.
  - *csoma:* Controle do registrador de soma. Habilita o carregamento do novo valor na próxima borda do relógio, caso o sinal esteja ativo
  - *csad_reg:* Sinal de controle para armazenar o resultado final no registrador de saída.
- **Saídas:**
  - *sad_out* Saída que fornece o valor acumulado total de SAD

### **Módulo 6: Acumulador De endereços**
- **Nome do Arquivo: address_accumulator** 
- **Função:** Descreva a função principal do módulo.
- **Entradas:**
  - *clk:*  É o clock do SAD, chamado de ck nas aulas teóricas, responsável pela sincronização e o quão eficiente (rápido) a SAD vai ser;
  - *rst:* sinal de reinicio 
  - *zi:* É um sinal de enable (carga) para o multiplexador que está “encadeado” ao registrador “i”. Quando seu valor é 1, ele faz com que um dado de 7 bits com valor lógico baixo cheguem no registrador “i”, e quando 0, faz com que o dado vindo do somador do acumulador chegue nesse mesmo registrador;
  - *ci:* É um sinal de enable para o registrador “i”, do acumulador, liberando o armazenamento dos dados que chegam nesse registrador;
  - *carga:* é um sinal de controle que determina quando o valor atual no acumulador deve ser atualizado com uma nova entrada.
- **Saídas:**
  - *address:* Endereço atualizado que aponta para o próximo par de amostras.
  - *menor:* Sinal que tem uma função de controle mas na verdade é gerado pelo bloco operativo, mais especificamente, é o bit mais significativo do registrador “i” que fica no acumulador, chamado de “Address accumulator” em nosso código. Sua funcionalidade se dá em levar a informação de quando todos as amostras já passaram pelo processamento de soma das diferenças em módulo, e então estão prontas para serem armazenadas no registrador da SAD;



### **Módulo 7: Bloco de Controle**
- **Nome do Arquivo: sab_bc**
- **Função:** Envia sinais de controle para o bloco operativo realizar as operações na ordem e instantes corretos. 
- **Entradas:**
  - *clk:* É o clock do SAD, chamado de ck nas aulas teóricas, responsável pela sincronização e o quão eficiente (rápido) a SAD vai ser;
  - *enable:* Foi denominada de “iniciar” nas aulas teóricas. Esse sinal tem a função de dar início a SAD. Creio que um botão de ligar num aparelho eletrônico seja uma boa analogia para esse sinal;
  - *rst:* Reset tem a função de reiniciar a SAD, quando esse sinal tem valor alto ele faz com que a FSM volte para o estado inicial;
  - *menor:* Sinal que tem uma função de controle mas na verdade é gerado pelo bloco operativo, mais especificamente, é o bit mais significativo do registrador “i” que fica no acumulador, chamado de “Address accumulator” em nosso código. Sua funcionalidade se dá em levar a informação de quando todos as amostras já passaram pelo processamento de soma das diferenças em módulo, e então estão prontas para serem armazenadas no registrador da SAD; 
- **Saídas:**
  - *read_mem:* Chamada de “read” nas aulas teóricas, tem a função de habilitar a leitura da memória;
  - *done:* O sinal “done” é responsável por indicar quando o cálculo da SAD foi concluído;
  - *zi:* É um sinal de enable (carga) para o multiplexador que está “encadeado” ao registrador “i”. Quando seu valor é 1, ele faz com que um dado de 7 bits com valor lógico baixo cheguem no registrador “i”, e quando 0, faz com que o dado vindo do somador do acumulador chegue nesse mesmo registrador;
  - *ci:* É um sinal de enable para o registrador “i”, do acumulador, liberando o armazenamento dos dados que chegam nesse registrador;
  - *cpApB:* Sinal responsável por dar o sinal de carga, enable, aos registradores que armazenam as amostras das memórias A e B. Foi implementada sendo um vetor de tamanho variável P em nosso código;
  - *zsoma:* Sinal de enable do multiplexador que está anexado ao registrador chamado de “soma” nas aulas teóricas, seu funcionamento é análogo ao do sinal “zi”;
  - *csoma:* Sinal de enable do registrador “soma” das aulas teóricas, ele habilita a leitura de dados desse registrador;
  - *csad_reg:* É o sinal de carga do registrador que armazena os dados da soma das diferenças em módulo, tem valor lógico alto apenas no último estado da máquina de estados.
- **maquina de estados(tirada do quartus II Netlist viewer)**
![maquina de estados](https://i.imgur.com/iH2s6ko.png)

### **Módulo 8: Bloco Operativo**
- **Nome do Arquivo: sad_bo** 
- **Função:** É o bloco principal do _datapath_, onde são instanciados e conectados os componentes para que a sad funcione corretamente .

![Bloco Operativo](https://i.imgur.com/kznrcpA.png)


### **Módulo 9: Sad**
- **Nome do Arquivo: sad** 
- **Função:** É o bloco mais importante já que liga o controle ao _datapath_ e é quem de fato gera a sad, é a conclusão do sistema digital.

- **Diagrama de Blocos:**
  ![Sad completa](https://i.imgur.com/Pqf95OL.png)

## **Simulações e Resultados**
Durante as simulações podemos observar que para valores de muito grandes das amostras ocorre overflow, mas apenas com números muito grandes.  As analises de timing ocorrem sem grandes problemas e com valores dentro do esperado com __Fmax__ de 125.75MHz para _sadv1_ e de 104.24MHz para sadV3

Esse é o quadro de simulação do ModelSim 
![Diagrama do Módulo 1](https://i.imgur.com/29Lkncv.png)

## **Conclusão**
Sabemos que a atividade não está perfeita, mas visto que topamos fazer desafio de uma SAD genérica o resultado está razoável. Tivemos algumas dificuldades na hora de ligar os sinais dos componentes e de determinar a largura dos sinais, a instanciação de componentes em si não foi tão problemática. Acho que desenvolvemos alguns blocos bastante úteis como camada de subtração e de registadores. Infelizmente Não conseguimos marcar horários com o monitor da disciplina o que teria ajudado bastante mas por conta de choque de horários e outra atividades acadêmicas não foi possível. Mas queria agradecer ao professor por todo o suporte dentro e fora de sala que ajudou muito é foi crucial para a realização do trabalho.