LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL;

ENTITY sad_bo IS
    GENERIC (
        B : INTEGER := 8;   -- Número de bits por amostra
        P : INTEGER := 4;   -- Número de pares de entradas
        N : INTEGER := 64   -- Número de amostras por bloco
    );
    PORT (
        clk : IN std_logic;
        rst : IN std_logic;          -- Sinal de reset
        carga : IN std_logic;        -- Sinal de carga
        sample_ori, sample_can : IN std_logic_vector(P*B-1 DOWNTO 0);  -- Vetores concatenados de entradas
        abs_sum : OUT std_logic_vector(B+integer(ceil(log2(real(N))))-1 DOWNTO 0)  -- Saída da soma absoluta
    );
END ENTITY;

ARCHITECTURE rtl OF sad_bo IS
    SIGNAL diff : std_logic_vector(P*B-1 DOWNTO 0);         -- Diferenças de N bits
    SIGNAL abs_out : std_logic_vector(B+integer(ceil(log2(real(N))))-1 DOWNTO 0);      -- Valores absolutos das diferenças com largura N
    SIGNAL soma_out : std_logic_vector(B+integer(ceil(log2(real(N))))-1 DOWNTO 0); -- Soma das diferenças absolutas

    -- Sinais para o acumulador de endereços, acumulador das somas e registrador da SAD
    SIGNAL addr_accum : std_logic_vector(integer(ceil(log2(real(N))))-1 DOWNTO 0);
    SIGNAL sum_accum : std_logic_vector(B+integer(ceil(log2(real(N))))-1 DOWNTO 0);
    SIGNAL sad_reg : std_logic_vector(B+integer(ceil(log2(real(N))))-1 DOWNTO 0);

BEGIN

    -- Instância do módulo de subtração
    subtraction_inst : ENTITY work.subtraction_module
        GENERIC MAP (
            N => B,
            P => P
        )
        PORT MAP (
            pA => sample_ori,
            pB => sample_can,
            diff => diff
        );

    -- Geração das instâncias de valor absoluto para cada diferença calculada
    gen_abs : FOR i IN 0 TO P-1 GENERATE
        abs_inst : ENTITY work.absolute
            GENERIC MAP(N => B)
            PORT MAP (
                a => diff((i+1)*B-1 DOWNTO i*B),                 -- Entrada da diferença de N bits
                s => abs_out((i+1)*B-1 DOWNTO i*B)               -- Saída do valor absoluto de N bits
            );
    END GENERATE gen_abs;

    -- Instância do somador de árvore para somar os valores absolutos
    adder_tree_inst : ENTITY work.adderTree
        GENERIC MAP (
            N => B,
            P => P
        )
        PORT MAP (
            inputs => abs_out,
            sum_out => soma_out
        );

    -- Instância do acumulador de endereços
    addr_accum_inst : ENTITY work.acumulador
        GENERIC MAP (
            N => integer(ceil(log2(real(N)))) -- Número de bits para representar o endereço
        )
        PORT MAP (
            clk => clk,
            rst => rst,          -- Passando o reset para o acumulador
            carga => carga,       -- Passando o sinal de carga
            sel => '1',           -- Ativa o acumulador
            a => std_logic_vector(to_unsigned(1, addr_accum'length)),  -- Incremento de 1 no endereço
            b => addr_accum,      -- Valor atual do endereço
            q_out => addr_accum   -- Saída do acumulador de endereços
        );

    -- Instância do acumulador das somas
    sum_accum_inst : ENTITY work.acumulador
        GENERIC MAP (
            N => B+integer(ceil(log2(real(N)))) -- Número de bits da soma acumulada
        )
        PORT MAP (
            clk => clk,
            rst => rst,          -- Passando o reset para o acumulador
            carga => carga,       -- Passando o sinal de carga
            sel => '1',           -- Ativa o acumulador
            a => soma_out,        -- Resultado do somador de árvore
            b => sum_accum,       -- Valor atual da soma acumulada
            q_out => sum_accum    -- Saída do acumulador das somas
        );

    -- Instância do registrador para o valor final SAD com reset e carga
    sad_reg_inst : ENTITY work.registrador
        GENERIC MAP (
            N => sad_reg'length -- Largura do registrador SAD
        )
        PORT MAP (
            clk => clk,
            rst => rst,         -- Conectando o reset
            carga => carga,     -- Conectando o sinal de carga
            D => sum_accum,     -- Entrada é a soma acumulada
            Q => sad_reg        -- Saída do registrador SAD
        );

    -- Atribuir a saída final
    abs_sum <= sad_reg;  -- SAD final armazenado no registrador

END ARCHITECTURE;

