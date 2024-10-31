LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL;

ENTITY adderTree IS
    GENERIC (
        N : POSITIVE := 8;  -- Número de bits de cada entrada
        P : POSITIVE := 8   -- Número de entradas a serem somadas
    );
    PORT (
        inputs : IN std_logic_vector((P*N)-1 DOWNTO 0);  -- Vetor de entradas concatenadas
        sum_out : OUT std_logic_vector(N+integer(ceil(log2(real(P))))-1 downto 0)
		 --sum_out : OUT std_logic_vector(INTEGER(ceil(log2(real((2**N)*(2**(ceil(log2(real(integer(P))))))))))-1 DOWNTO 0) 
		 -- Saída com largura de N+2 bits
    );
END ENTITY;

ARCHITECTURE rtl OF adderTree IS
    SIGNAL sum_total : unsigned(N+integer(ceil(log2(real(P))))-1 downto 0);  -- Acumulador para a soma total
	 SIGNAL total_left, total_right:std_LOGIC_Vector(N+integer(ceil(log2(real(P))))-2 downto 0);
BEGIN
	 sum_out <= std_logic_vector(sum_total);
    gen_sum: IF p = 2 GENERATE
	 FA : ENTITY work.adder_full_unsigned(rtl)
	 generic map(N => N)
	 port map (
		add1 => unsigned(inputs(N-1 downto 0)),
		add2 => unsigned(inputs((2*N)-1 downto N)),
		sum => sum_total
	 );
	 else genERATE
	 sum_left: entity work.adderTree(rtl)
	 generic map(N => N,
	p => (p/2)
	 )
	 port map(
	 inputs => inputs(inputs'left downto intEGER(inputs'length/2)),
	 sum_out => total_left
	 );
	  sum_right: entity work.adderTree(rtl)
	 generic map(N => N,
		p => (p/2)
	 )
	 port map(
	 inputs => inputs(intEGER(inputs'length/2)-1 downto 0),
	 sum_out => total_right
	 );
	 FA : ENTITY work.adder_full_unsigned(rtl)
	 generic map(N => N+integer(ceil(log2(real(P))))-1)
	 port map (
		add1 => unsigned(total_left),
		add2 => unsigned(total_right),
		sum => sum_total
	 );
	 end generate gen_sum;

	 
END ARCHITECTURE;
