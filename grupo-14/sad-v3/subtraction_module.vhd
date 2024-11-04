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
