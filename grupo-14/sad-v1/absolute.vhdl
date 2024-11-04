LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY absolute IS
    GENERIC (N : POSITIVE := 8);  -- Número de bits da entrada e da saída
    PORT (
        a : IN std_logic_vector(N DOWNTO 0);  -- Entrada de N bits
        s : OUT std_logic_vector(N-1 DOWNTO 0)  -- Saída de N bits (valor absoluto)
    );
END ENTITY absolute;

ARCHITECTURE arch OF absolute IS
    SIGNAL abst : signed(N DOWNTO 0);  -- Sinal intermediário para cálculo de valor absoluto
BEGIN
    abst <= abs(signed(a));  -- Calcula o valor absoluto de `a` como signed
    s <= std_logic_vector(abst(N-1 downto 0));  -- Converte para `std_logic_vector` e envia para saída `s`
END ARCHITECTURE arch;