LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY somador IS
    GENERIC (
        N : POSITIVE -- Valor de bits da entrada
    );
    PORT (
        A : IN UNSIGNED (N-1 DOWNTO 0);                   -- Entrada A
        B : IN UNSIGNED (N-1 DOWNTO 0);                   -- Entrada B
        S : OUT STD_LOGIC_VECTOR (N-1 DOWNTO 0);          -- Saída S
        cout : OUT STD_LOGIC                              -- Saída carry out
    );
END ENTITY; -- Registrador de N bits

ARCHITECTURE arch OF somador IS
    SIGNAL soma: unsigned(N downto 0);
BEGIN
    soma <= resize(A, N + 1) + resize(B, N + 1);
    S <= STD_LOGIC_VECTOR(soma(N - 1 downto 0));
    cout <= soma(N);
END arch;
