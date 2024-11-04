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

END ARCHITECTURE rtl;
