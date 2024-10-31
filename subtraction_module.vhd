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
        diff : OUT std_logic_vector(P*N-1 DOWNTO 0)    -- Vetor de saídas com as diferenças
    );
END ENTITY;

ARCHITECTURE rtl OF subtraction_module IS
BEGIN
    gen_diff : FOR i IN 0 TO P-1 GENERATE
        -- Subtração: pA[i] - pB[i]
        diff_proc : PROCESS (pA, pB)
        BEGIN
            diff((i+1)*N-1 DOWNTO i*N) <= std_logic_vector(signed(pA((i+1)*N-1 DOWNTO i*N)) - signed(pB((i+1)*N-1 DOWNTO i*N)));
        END PROCESS;
    END GENERATE gen_diff;

END ARCHITECTURE;
