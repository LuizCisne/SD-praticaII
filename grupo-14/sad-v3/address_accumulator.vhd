LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL;

ENTITY address_accumulator IS
    GENERIC (
        N : INTEGER := 16;  -- Número de bits para o contador/endereço
		  P : INTEGER := 4
    );
    PORT (
        clk : IN std_logic;
        rst : IN std_logic;
        zi : IN std_logic;         -- Controle para o mux do contador
        ci : IN std_logic;         -- Controle para o registrador do contador
        carga : IN std_logic;      -- Sinal de carga
        menor : OUT std_logic;     -- Sinal que indica condição de parada (overflow)
        address : OUT std_logic_vector(integer(ceil(log2(real(N/P))))-1 DOWNTO 0)  -- Saída do endereço acumulado (4 bits para o endereço)
    );
END ENTITY address_accumulator;

ARCHITECTURE rtl OF address_accumulator IS
    CONSTANT REF : INTEGER := integer(ceil(log2(real(N / P))));
    SIGNAL mux_out : std_logic_vector(REF DOWNTO 0);      -- Saída do Mux (5 bits: menor + endereço)
    SIGNAL add_result : std_logic_vector(REF DOWNTO 0);   -- Resultado do somador como std_logic_vector
    SIGNAL reg_out : std_logic_vector(REF DOWNTO 0);      -- Saída do registrador
    
    SIGNAL sum_out : std_logic_vector(REF-1 DOWNTO 0);      -- Saída do somador (4 bits)
    SIGNAL cout_sum : std_logic;                            -- Carry out do somador

BEGIN

    -- Instância do Mux para selecionar entre 0 e o valor atual do registrador
    mux_inst : ENTITY work.mux2para1
        GENERIC MAP (N => REF+1)
        PORT MAP (
            sel => zi,
            b => std_LOGIC_VECTOR(to_unsigned(0,REF+1)),     -- Seleciona 0
            a => add_result,             -- Seleciona o valor atual do registrador
            y => mux_out
        );

    -- Instância do Somador para incrementar o valor do endereço
    somador_inst : ENTITY work.somador
        GENERIC MAP (N => REF)
        PORT MAP (
            A => unsigned(reg_out(REF-1 DOWNTO 0)),
            B => to_unsigned(1,REF),           -- Incremento constante de 1 convertido para `unsigned`
            S => sum_out,                       -- Conectado como std_logic_vector
            cout => cout_sum                    -- Carry out como sinal `menor`
        );

    -- Atribuição do resultado da soma
    add_result <= cout_sum & sum_out;

    -- Instância do Registrador para armazenar o valor atual do endereço
    reg_inst : ENTITY work.registrador
        GENERIC MAP (N => REF+1)
        PORT MAP (
            clk => clk,
            rst => rst,
            carga => ci,
            D => mux_out,                    -- Usa `add_result` como entrada
            Q => reg_out                        -- Saída para `reg_out`
        );

    -- Saída de endereço (4 bits menos significativos)
    address <= reg_out(REF-1 DOWNTO 0);

    -- O bit mais significativo do registrador define `menor`
    menor <= not(reg_out(REF));

END ARCHITECTURE rtl;
