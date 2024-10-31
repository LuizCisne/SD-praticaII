LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL;

ENTITY sad IS
    GENERIC (
        B : POSITIVE := 8;  -- Número de bits por amostra
        N : POSITIVE := 64; -- Número de amostras por bloco
        P : POSITIVE := 4   -- Número de amostras lidas em paralelo
    );
    PORT (
        clk : IN std_logic;     -- Relógio
        enable : IN std_logic;  -- Habilita o cálculo
        reset : IN std_logic;   -- Reset
        sample_ori : IN std_logic_vector(P*B-1 DOWNTO 0);  -- Amostras originais
        sample_can : IN std_logic_vector(P*B-1 DOWNTO 0);  -- Amostras candidatas
        read_mem : OUT std_logic;  -- Sinal para leitura de memória
        address : OUT std_logic_vector(integer(ceil(log2(real(N))))-1 DOWNTO 0);  -- Endereço da memória
        sad_value : OUT std_logic_vector(B+integer(ceil(log2(real(N))))-1 DOWNTO 0);  -- Valor final do SAD (ajustado automaticamente)
        done: OUT std_logic  -- Sinaliza o término da operação
    );
END ENTITY sad;

ARCHITECTURE arch OF sad IS

    -- Sinais de controle do bloco `sad_bc`
    SIGNAL carga, done_signal, zi, ci, zsoma, csoma, csad_reg : std_logic;
    SIGNAL cpApB : std_logic_vector(P-1 DOWNTO 0);  -- Vetor de controle para os registradores de memória

    -- Sinais internos
    SIGNAL abs_sum : std_logic_vector(B+integer(ceil(log2(real(N))))-1 DOWNTO 0);  -- Saída do bloco sad_bo ajustada automaticamente

BEGIN

    -- Instância do bloco de controle sad_bc
    sad_bc_inst : ENTITY work.sad_bc
        GENERIC MAP (
            B => B,
            N => N,
            P => P
        )
        PORT MAP (
            clk => clk,
            enable => enable,
            reset => reset,
            menor => '0',         
            read_mem => read_mem,
            done => done_signal,
            zi => zi,
            ci => ci,
            cpApB => cpApB,
            zsoma => zsoma,
            csoma => csoma,
            csad_reg => csad_reg
        );

    -- Instância do bloco operacional sad_bo
    sad_bo_inst : ENTITY work.sad_bo
        GENERIC MAP (
            B => B,
            P => P,
            N => N
        )
        PORT MAP (
            clk => clk,
            rst => reset,       -- Conectando o reset
            carga => csad_reg,  -- Usando o controle de carga do bloco de controle
            sample_ori => sample_ori,
            sample_can => sample_can,
            abs_sum => abs_sum
        );

    -- Atribuindo as saídas principais
    sad_value <= abs_sum;    -- Atribuir o valor de SAD final à saída
    done <= done_signal;      -- Sinal de término da operação

END ARCHITECTURE arch;
