LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY sad_bc IS
	GENERIC (

		B : POSITIVE := 8; -- número de bits por amostra

		N : POSITIVE := 64; -- número de amostras por bloco
		P : POSITIVE := 1 -- número de amostras de cada bloco lidas em paralelo

	);
	PORT (
		clk : IN STD_LOGIC; -- ck
		enable : IN STD_LOGIC; -- iniciar
		reset : IN STD_LOGIC; -- reset
		menor : IN STD_LOGIC; -- menor
		read_mem : OUT STD_LOGIC; -- read
		done : OUT STD_LOGIC; -- pronto
		zi : OUT STD_LOGIC; -- enable mux contador (obs: enable e carga sao sinonimos)
		ci : OUT STD_LOGIC; -- enable reg contador
		cpApB : OUT STD_LOGIC_VECTOR(P - 1 DOWNTO 0); -- enable dos reg memoria // vetor com o tamanho da quantidade de regs necessarios para memoria
		zsoma : OUT STD_LOGIC; -- enable mux soma
		csoma : OUT STD_LOGIC; -- enable reg soma
		csad_reg : OUT STD_LOGIC -- enable sad_reg
 
	);
END ENTITY sad_bc;

ARCHITECTURE Behavior OF sad_bc IS
	TYPE Estado IS (S0, S1, S2, S3, S4, S5);
	SIGNAL EstadoAtual, ProximoEstado : Estado;
 
BEGIN
	PROCESS (enable, menor, EstadoAtual)
	BEGIN
		CASE EstadoAtual IS
			WHEN S0 => 
 
				done <= '1';
				zi <= '1';
				zsoma <= '1';
				ci <= '0';
				csoma <= '0';
				read_mem <= '0';
				cpApB <= (OTHERS => '0');
				csad_reg <= '0';
 
				IF enable = '1' THEN
					ProximoEstado <= S1;
				ELSE
					ProximoEstado <= S0;
				END IF;
 
			WHEN S1 => 
 
				done <= '0';
				zi <= '1';
				zsoma <= '1';
				ci <= '0';
				csoma <= '0';
				read_mem <= '0';
				cpApB <= (OTHERS => '0');
				csad_reg <= '0';
 
				ProximoEstado <= S2;
 
			WHEN S2 => 
 
				done <= '0';
				zi <= '1';
				zsoma <= '1';
				ci <= '0';
				csoma <= '0';
				read_mem <= '0';
				cpApB <= (OTHERS => '0');
				csad_reg <= '0';
 
				IF menor = '1' THEN
					ProximoEstado <= S5;
				ELSE
					ProximoEstado <= S3;
				END IF;
 
			WHEN S3 => 
 
				done <= '0';
				zi <= '0';
				zsoma <= '0';
				ci <= '0';
				csoma <= '0';
				read_mem <= '1';
				cpApB <= (OTHERS => '1');
				csad_reg <= '0';
 
				ProximoEstado <= S3;
 
			WHEN S4 => 
 
				done <= '0';
				zi <= '0';
				zsoma <= '0';
				ci <= '1';
				csoma <= '1';
				read_mem <= '0';
				cpApB <= (OTHERS => '0');
				csad_reg <= '0';
 
				ProximoEstado <= S2;
 
			WHEN S5 => 
 
				done <= '0';
				zi <= '0';
				zsoma <= '0';
				ci <= '0';
				csoma <= '0';
				read_mem <= '0';
				cpApB <= (OTHERS => '0');
				csad_reg <= '1';
 
				ProximoEstado <= S0;
		END CASE;
	END PROCESS;
 
	PROCESS (reset, clk)
		BEGIN
			IF reset = '1' THEN
				EstadoAtual <= S0;
			ELSIF (rising_edge(clk)) THEN
				EstadoAtual <= ProximoEstado;
			END IF;
		END PROCESS; 
END Behavior;