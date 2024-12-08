library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;


entity fp_add_sub_testbench is
end entity fp_add_sub_testbench;

architecture fp_add_sub_testbench_arch of fp_add_sub_testbench is
    constant TCK:           time := 20 ns; 
    constant DELAY:         natural := 2; 
    constant WORD_SIZE_T:   natural := 28; 
    constant NE:            natural := 8; 
    constant NF:            natural := 19;
    
    signal tb_rst: std_logic;
    signal tb_clk: std_logic := '0';
    signal tb_add_sub  : std_logic := '0';
    signal x_file: unsigned(WORD_SIZE_T-1 downto 0) := (others => '0');
    signal y_file: unsigned(WORD_SIZE_T-1 downto 0) := (others => '0');
    signal z_file: unsigned(WORD_SIZE_T-1 downto 0) := (others => '0');
    signal z_del: unsigned(WORD_SIZE_T-1 downto 0) := (others => '0');
    signal z_duv: std_logic_vector(WORD_SIZE_T-1 downto 0) := (others => '0');
    signal z_del_aux: std_logic_vector(WORD_SIZE_T-1 downto 0):= (others => '0');
    signal ciclos: integer := 0;
    signal errores: integer := 0;
    file datos: text open read_mode is "../tb/fadd_19_8.txt";


begin
    tb_rst <= '0', '1' after 1 ns, '0' after 20 ns;
    
    -- Generacion del clock del sistema
    tb_clk <= not(tb_clk) after TCK / 2; -- reloj
    
    Test_Sequence: process
        variable l: line;
        variable ch: character := ' ';
        variable aux: integer;
    begin
        while not(endfile(datos)) loop
            wait until rising_edge(tb_clk);
            -- solo para debugging
            ciclos <= ciclos + 1;
            -- se lee una linea del archivo de valores de prueba
            readline(datos, l);
            -- se extrae un entero de la linea
            read(l, aux);
            -- se carga el valor del operando A
            x_file <= to_unsigned(aux, WORD_SIZE_T);
            -- se lee un caracter (es el espacio)
            read(l, ch);
            -- se lee otro entero de la linea
            read(l, aux);
            -- se carga el valor del operando B
            y_file <= to_unsigned(aux, WORD_SIZE_T);
            -- se lee otro caracter (es el espacio)
            read(l, ch);
            -- se lee otro entero
            read(l, aux);
            -- se carga el valor de salida (resultado)
            z_file <= to_unsigned(aux, WORD_SIZE_T);
        end loop;

        -- se cierra del archivo
        file_close(datos);
        wait for TCK * (DELAY + 1);
        -- se aborta la simulacion (fin del archivo)
        assert false report "Fin de la simulacion" severity failure;
    end process Test_Sequence;

    -- Instanciacion del DUV
    DUV: entity work.fp_add_sub
        generic map(
            NE => NE,
            NF => NF
        )
        port map(
            rst => tb_rst,
            clk => tb_clk,
            add_sub => tb_add_sub,
            x => std_logic_vector(x_file),
            y => std_logic_vector(y_file),
            z => z_duv
        );
    del: entity work.delay_gen
        generic map(
            N => WORD_SIZE_T,
            DELAY => DELAY
        )
        port map(
            clk => tb_clk,
            rst => tb_rst,
            A => std_logic_vector(z_file),
            B => z_del_aux
        );
    z_del <= unsigned(z_del_aux);
    
    -- Verificacion de la condicion
    verificacion: process(tb_clk)
    begin
        if rising_edge(tb_clk) then
            assert to_integer(z_del) = to_integer(unsigned(z_duv)) report
                "Error: Salida del DUV no coincide con referencia (salida del duv = " &
                integer'image(to_integer(unsigned(z_duv))) &
                ", salida del archivo = " &
                integer'image(to_integer(z_del)) & ")"
                severity warning;
            if to_integer(z_del) /= to_integer(unsigned(z_duv)) then
                errores <= errores + 1;
            end if;
        end if;
    end process;
end architecture fp_add_sub_testbench_arch;

