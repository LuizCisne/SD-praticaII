LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY sad_controle IS
    GENERIC (
        B : POSITIVE := 8; -- Número de bits por amostra
        N : POSITIVE := 64; -- Número de amostras por bloco
        P : POSITIVE := 1   -- Número de amostras de cada bloco lidas em paralelo
    );
    PORT (
        clk : IN STD_LOGIC;      -- Clock
        enable : IN STD_LOGIC;   -- Iniciar
        reset : IN STD_LOGIC;    -- Reset
        menor : IN STD_LOGIC;    -- Sinal de comparação menor
        read_mem : OUT STD_LOGIC; -- Sinal de leitura da memória
        done : OUT STD_LOGIC;    -- Sinal de pronto
        zi : OUT STD_LOGIC;      -- Enable para o mux contador
        ci : OUT STD_LOGIC;      -- Enable para o registrador do contador
        cpA : OUT STD_LOGIC;     -- Enable para o registrador A
        cpB : OUT STD_LOGIC;     -- Enable para o registrador B
        zsoma : OUT STD_LOGIC;   -- Enable para o mux soma
        csoma : OUT STD_LOGIC;   -- Enable para o registrador soma
        csad_reg : OUT STD_LOGIC -- Enable para o registrador SAD
    );
END ENTITY sad_controle;

ARCHITECTURE Behavior OF sad_controle IS
    TYPE Estado IS (S0, S1, S2, S3, S4, S5);
    SIGNAL EstadoAtual, ProximoEstado : Estado;

BEGIN
    PROCESS (enable, menor, EstadoAtual)
    BEGIN
        CASE EstadoAtual IS
            WHEN S0 => 
                done <= '1';
                zi <= '1';
                zsoma <= '0';
                ci <= '0';
                csoma <= '0';
                read_mem <= '0';
                cpA <= '0';
                cpB <= '0';
                csad_reg <= '0';

                IF enable = '1' THEN
                    ProximoEstado <= S1;
                ELSE
                    ProximoEstado <= S0;
                END IF;

            WHEN S1 => 
                done <= '0';
                zi <= '1';
                zsoma <= '0';
                ci <= '1';
                csoma <= '1';
                read_mem <= '0';
                cpA <= '0';
                cpB <= '0';
                csad_reg <= '0';

                ProximoEstado <= S2;

            WHEN S2 => 
                done <= '0';
                zi <= '0';
                zsoma <= '0';
                ci <= '0';
                csoma <= '0';
                read_mem <= '0';
                cpA <= '0';
                cpB <= '0';
                csad_reg <= '0';

                IF menor = '1' THEN
                    ProximoEstado <= S3;
                ELSE
                    ProximoEstado <= S5;
                END IF;

            WHEN S3 => 
                done <= '0';
                zi <= '0';
                zsoma <= '0';
                ci <= '0';
                csoma <= '0';
                read_mem <= '1';
                cpA <= '1';
                cpB <= '1';
                csad_reg <= '0';

                ProximoEstado <= S4;

            WHEN S4 => 
                done <= '0';
                zi <= '0';
                zsoma <= '1';
                ci <= '1';
                csoma <= '1';
                read_mem <= '0';
                cpA <= '0';
                cpB <= '0';
                csad_reg <= '0';

                ProximoEstado <= S2;

            WHEN S5 => 
                done <= '0';
                zi <= '0';
                zsoma <= '0';
                ci <= '0';
                csoma <= '0';
                read_mem <= '0';
                cpA <= '0';
                cpB <= '0';
                csad_reg <= '1';

                ProximoEstado <= S0;
        END CASE;
    END PROCESS;

    PROCESS (reset, clk)
    BEGIN
        IF reset = '1' THEN
            EstadoAtual <= S0;
        ELSIF rising_edge(clk) THEN
            EstadoAtual <= ProximoEstado;
        END IF;
    END PROCESS;
END Behavior;
