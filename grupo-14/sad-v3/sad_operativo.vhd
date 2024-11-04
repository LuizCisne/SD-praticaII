LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL;

ENTITY sad_operativo IS
    GENERIC (
        B : INTEGER := 8;   -- Número de bits por amostra
        P : INTEGER := 4;   -- Número de pares de entradas
        N : INTEGER := 64   -- Número de amostras por bloco
    );
    PORT (
        clk : IN std_logic;
        rst : IN std_logic;          -- Sinal de reset
        carga : IN std_logic;        -- Sinal de carga
        zi : IN std_logic;           -- Enable para o mux contador
        ci : IN std_logic;           -- Enable para o registrador do contador
        cpA : IN std_logic;          -- Controle do registrador A
        cpB : IN std_logic;          -- Controle do registrador B
        zsoma : IN std_logic;        -- Controle do mux da soma
        csoma : IN std_logic;        -- Controle do registrador da soma
        csad_reg : IN std_logic;     -- Controle para armazenar o resultado final da SAD
        sample_ori, sample_can : IN std_logic_vector(P*B-1 DOWNTO 0);  -- Vetores concatenados de entradas
        abs_sum : OUT std_logic_vector(B + integer(ceil(log2(real(N)))) - 1 DOWNTO 0);  -- Saída da soma absoluta
        menor : OUT std_logic;       -- Sinal de condição de parada para o BC
        address : OUT std_logic_vector(integer(ceil(log2(real(N/P))))-1 DOWNTO 0) -- Saída do endereço
    );
END ENTITY sad_operativo;

ARCHITECTURE rtl OF sad_operativo IS
    SIGNAL diff : std_logic_vector(P*(B+1)-1 DOWNTO 0);         -- Diferenças de 9 bits (8 bits + sinal)
    SIGNAL abs_out : std_logic_vector(P*(B)-1 DOWNTO 0);      -- Valores absolutos com 9 bits por diferença
    SIGNAL abs_truncated : std_logic_vector(P*B-1 DOWNTO 0);    -- Valores absolutos truncados para 8 bits
    SIGNAL soma_out : std_logic_vector(B + integer(ceil(log2(real(P)))) - 1 DOWNTO 0); -- Saída do somador de árvore
    SIGNAL addr_accum : std_logic_vector(integer(ceil(log2(real(N/P))))-1 DOWNTO 0);   -- Endereço acumulado
    SIGNAL sad_result : std_logic_vector(abs_sum'length-1 DOWNTO 0);                   -- Registrador de resultado SAD final

    -- Sinais para os registradores individuais de pA e pB
    SIGNAL pA_segments : std_logic_vector(P*B-1 DOWNTO 0);
    SIGNAL pB_segments : std_logic_vector(P*B-1 DOWNTO 0);

BEGIN

    -- Separar sample_ori e sample_can em P segmentos de B bits para registradores pA e pB
    gen_registers : FOR i IN 0 TO P - 1 GENERATE
        pA_inst : ENTITY work.registrador
            GENERIC MAP (N => B)
            PORT MAP (
                clk => clk,
                rst => rst,
                carga => cpA,
                D => sample_ori((i+1)*B-1 DOWNTO i*B), -- Segmento de B bits de sample_ori
                Q => pA_segments((i+1)*B-1 DOWNTO i*B) -- Saída de pA segmentada
            );

        pB_inst : ENTITY work.registrador
            GENERIC MAP (N => B)
            PORT MAP (
                clk => clk,
                rst => rst,
                carga => cpB,
                D => sample_can((i+1)*B-1 DOWNTO i*B), -- Segmento de B bits de sample_can
                Q => pB_segments((i+1)*B-1 DOWNTO i*B) -- Saída de pB segmentada
            );
    END GENERATE gen_registers;

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

    -- Geração das instâncias de valor absoluto para cada diferença calculada
    gen_abs : FOR i IN 0 TO P - 1 GENERATE
        abs_inst : ENTITY work.absolute
            GENERIC MAP(N => B)  -- 9 bits de entrada no absolute
            PORT MAP (
                a => diff((i+1)*(B+1)-1 DOWNTO i*(B+1)),  -- Entrada de 9 bits para cada instância de absolute
                s => abs_out((i+1)*(B)-1 DOWNTO i*(B))  -- Saída de 9 bits da operação absoluta
            );
    END GENERATE gen_abs;

   

    -- Instância do somador de árvore para somar os valores absolutos truncados
    adder_tree_inst : ENTITY work.adderTree
        GENERIC MAP (
            N => B,
            P => P
        )
        PORT MAP (
            inputs => abs_out,
            sum_out => soma_out  -- Ajuste de largura para coincidir com soma_out
        );

    -- Instância do acumulador de endereços com saída menor
    addr_accum_inst : ENTITY work.address_accumulator
        GENERIC MAP (
            N => N,
            P => P
        )
        PORT MAP (
            clk => clk,
            rst => rst,
            zi => zi,
            ci => ci,
            carga => carga,
            menor => menor,          -- Conectando menor para o BC
            address => addr_accum   -- Conectando address
        );

    -- Instância do acumulador SAD
    sad_accumulator_inst : ENTITY work.sad_accumulator
        GENERIC MAP (
            N => abs_sum'length
        )
        PORT MAP (
            clk => clk,
            rst => rst,
            zsoma => zsoma,
            csoma => csoma,
            csad_reg => csad_reg,
            soma_in => std_logic_vector(resize(unsigned(soma_out), abs_sum'length)), -- Ajuste de comprimento para abs_sum
            sad_out => sad_result     -- Resultado armazenado na saída temporária sad_result
        );

    -- Instância do registrador para armazenar o resultado final da SAD
    sad_reg_final : ENTITY work.registrador
        GENERIC MAP (N => abs_sum'length)
        PORT MAP (
            clk => clk,
            rst => rst,
            carga => csad_reg,
            D => sad_result,
            Q => abs_sum  -- Conectando à saída final abs_sum
        );

    -- Atribuição da saída de endereço
    address <= addr_accum;  -- Conectando addr_accum à saída address

END ARCHITECTURE rtl;
