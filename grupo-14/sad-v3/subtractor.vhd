LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY subtractor IS
    GENERIC (N : INTEGER := 8);  -- Número de bits por entrada
    PORT (
        a, b : IN std_logic_vector(N-1 DOWNTO 0);  -- Entradas
        result : OUT std_logic_vector(N DOWNTO 0)  -- Saída da subtração com N+1 bits
    );
END ENTITY subtractor;

ARCHITECTURE behavior OF subtractor IS
BEGIN
    -- Subtração direta com extensão de sinal
    result <= std_logic_vector(signed('0' & a) - signed('0' & b));
END ARCHITECTURE behavior;
