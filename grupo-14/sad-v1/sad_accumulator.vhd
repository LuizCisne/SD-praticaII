LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY sad_accumulator IS
    GENERIC (
        N : INTEGER := 14  -- Número de bits para o cálculo da SAD
    );
    PORT (
        clk, rst : IN std_logic;       -- Relógio e reset
        zsoma, csoma, csad_reg : IN std_logic; -- Sinais de controle
        soma_in : IN std_logic_vector(N-1 DOWNTO 0);  -- Entrada para o valor a somar
        sad_out : OUT std_logic_vector(N-1 DOWNTO 0)  -- Saída do valor acumulado de SAD
    );
END ENTITY sad_accumulator;

ARCHITECTURE rtl OF sad_accumulator IS
    SIGNAL mux_out : std_logic_vector(N-1 DOWNTO 0);        -- Saída do Mux
    SIGNAL soma_result : std_logic_vector(N DOWNTO 0);      -- Resultado do somador com 1 bit extra como std_logic_vector
    SIGNAL sad_reg : std_logic_vector(N-1 DOWNTO 0);        -- Registrador para o valor acumulado de SAD
    SIGNAL carry_out : std_logic;                           -- Sinal de carry out do somador (não utilizado aqui)

BEGIN

    -- Instância do Mux para selecionar entre 0 e o valor acumulado
    mux_inst : ENTITY work.mux2para1
        GENERIC MAP (N => N)
        PORT MAP (
            sel => zsoma,
            a => (OTHERS => '0'),  -- Seleciona 0
            b => soma_result(N-1 DOWNTO 0),          -- Seleciona o valor atual do registrador SAD
            y => mux_out
        );

    -- Instância do Somador para acumular o valor de SAD
    somador_inst : ENTITY work.somador
        GENERIC MAP (N => N)
        PORT MAP (
            A => unsigned(sad_reg),               -- Converte mux_out para unsigned
            B => unsigned(soma_in),               -- Converte soma_in para unsigned
            S => soma_result(N-1 DOWNTO 0),       -- Trunca soma_result para N bits como std_logic_vector
            cout => carry_out                     -- Carry out (não utilizado, mas necessário para a interface)
        );

    -- Registrador para armazenar o valor acumulado de SAD
    sad_reg_inst : ENTITY work.registrador
        GENERIC MAP (N => N)
        PORT MAP (
            clk => clk,
            rst => rst,
            carga => csoma,
            D => mux_out,       -- Usando o resultado truncado de soma_result
            Q => sad_reg
        );

    -- Saída final conectada ao valor do registrador SAD
    sad_out <= sad_reg;

END ARCHITECTURE rtl;
