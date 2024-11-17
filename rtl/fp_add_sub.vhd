library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fp_sum_subs is
    generic (
        NE: natural := 8;
        NF: natural := 23
    );
    port (
        rst:      in std_logic;
        clk:      in std_logic;
        sum_sub:  in std_logic;
        x:        in std_logic_vector(NF+NE downto 0);
        y:        in std_logic_vector(NF+NE downto 0);
        z:        out std_logic_vector(NF+NE downto 0)
    );
end fp_sum_subs;

architecture behavioral of fp_sum_subs is
    constant ZERO_E:        std_logic_vector(NE-1 downto 0) := (others => '0');
    constant ZERO_F:        std_logic_vector(NF-1 downto 0) := (others => '0');
    constant E_MIN:         signed(NE downto 0) := to_signed(0, NE+1);
    constant E_MAX:         signed(NE downto 0) := to_signed(2**(NE)-2, NE+1);
    signal x_reg :          std_logic_vector(NF+NE downto 0);
    signal y_reg :          std_logic_vector(NF+NE downto 0);
    signal sum_sub_reg:     std_logic:= '0';
    signal sx :             std_logic:= '0';
    signal ex :             signed(NE-1 downto 0);
    signal fx :             std_logic_vector(NF-1 downto 0);
    signal mx :             unsigned(NF downto 0);
    signal ex_ext :         signed(NE downto 0);
    signal sy :             std_logic:= '0';
    signal ey :             signed(NE-1 downto 0);
    signal fy :             std_logic_vector(NF-1 downto 0);
    signal my :             unsigned(NF downto 0);
    signal ey_ext :         signed(NE downto 0);
    signal exp_diff:        signed(NE downto 0);
    signal abs_exp_diff :   unsigned(NE downto 0);
    signal mz :             unsigned(2**NE + NF downto 0);
    signal mz_shifted :     unsigned(2**NE + NF downto 0);
    signal sz :             std_logic:= '0';
    signal ez :             signed(NE-1 downto 0);
    signal fz :             std_logic_vector(NF-1 downto 0);
    signal my_p_nt_a:       unsigned(NF + 2**NE-1 downto 0);
    signal mx_p_t_a:        unsigned(NF + 2**NE-1 downto 0);
    signal mx_p :           unsigned(NF downto 0);
    signal my_p :           unsigned(NF downto 0);
    signal c_x:             std_logic:= '0';
    signal c_y:             std_logic:= '0';
    signal ca2_mx_p:        unsigned(NF + 2**NE downto 0);
    signal ca2_my_p:        unsigned(NF + 2**NE downto 0);
    signal mx_ext:          unsigned(2**NE + NF downto 0);
    signal my_ext:          unsigned(2**NE + NF downto 0);
    signal sum_m_ext:       unsigned(2**NE + NF downto 0);
    signal selector :       std_logic_vector(3 downto 0);
    signal shift:           natural;
    signal fz_p:            unsigned(NF-1 downto 0);
    signal ez_p :           signed(NE-1 downto 0);
    signal ez_not_sat :     signed(NE downto 0);
    

    function first_one_index (a_signal: std_logic_vector) return natural is
        variable index		 : natural ;
        variable index_found : boolean := False;
    begin
        for i in a_signal'high downto a_signal'low loop
            if a_signal(i) = '1' and index_found = False then
                 index := i;
                 index_found := True;
            end if;
        end loop;
        if index < 0 then
            index := 0;
        end if;
        return index;
    end function;      

begin
    process(clk, rst)
    begin
        if rst = '1' then
            x_reg <= (others => '0');
            y_reg <= (others => '0');
            sum_sub_reg <= '0';
        elsif rising_edge(clk) then
            x_reg <= x;
            y_reg <= y;
            sum_sub_reg <= sum_sub;
        end if;
    end process;

    sx <= x_reg(NF+NE);
    fx <= x_reg(NF-1 downto 0);
    ex <= signed(x_reg(NF+NE-1 downto NF));

    sy <= y_reg(NF+NE);
    fy <= y_reg(NF-1 downto 0);
    ey <= signed(y_reg(NF+NE-1 downto NF));

    ex_ext <= '0' & ex;
    ey_ext <= '0' & ey;

    exp_diff <= ex_ext - ey_ext;
    
    abs_exp_diff <= unsigned(not(exp_diff) + 1) when exp_diff(NE) = '1' else
                unsigned(exp_diff);

    mx <= unsigned('1' & fx);
    my <= unsigned('1' & fy);

    mx_p <= mx when exp_diff(NE) = '0' else my;
    my_p <= my when exp_diff(NE) = '0' else mx;
       
    mx_p_t_a <= mx_p & to_unsigned(0, 2**NE-1);
                    
    my_p_nt_a <= to_unsigned(0, to_integer(abs_exp_diff)) & my_p &
                     to_unsigned(0, 2**NE-1- to_integer(abs_exp_diff));

    ca2_mx_p <= not('0' & mx_p_t_a) + 1;
    ca2_my_p <= not('0' & my_p_nt_a) + 1;

    selector <= sum_sub_reg & sx & sy & exp_diff(NE);
    process (selector)
    begin
        
        case (selector) is
            when "0000" =>  -- Suma, ambos positivos
                c_x <= '0';
                c_y <= '0';
            when "0001" =>  -- Suma, ambos positivos, swap
                c_x <= '0';
                c_y <= '0';
            when "0010" =>  -- Suma, primero positivo, segundo negativo
                c_x <= '0';
                c_y <= '1';
            when "0011" =>  -- Suma, primero positivo, segundo negativo, swap
                c_x <= '1';
                c_y <= '0';
            when "0100" =>  -- Suma, primero negativo, segundo positivo
                c_x <= '1';
                c_y <= '0';
            when "0101" =>  -- Suma, primero negativo, segundo positivo, swap
                c_x <= '0';
                c_y <= '1';
            when "0110" =>  -- Suma, primero negativo, segundo negativo
                c_x <= '1';
                c_y <= '1';
            when "0111" =>  -- Suma, primero negativo, segundo negativo, swap
                c_x <= '1';
                c_y <= '1';
            when "1000" =>  -- Resta, ambos positivos
                c_x <= '0';
                c_y <= '1';
            when "1001" =>  -- Resta, ambos positivos, swap
                c_x <= '1';
                c_y <= '0';
            when "1010" =>  -- Resta, primero positivo, segundo negativo
                c_x <= '0';
                c_y <= '0';
            when "1011" =>  -- Resta, primero positivo, segundo negativo, swap
                c_x <= '0';
                c_y <= '0';
            when "1100" =>  -- Resta, primero negativo, segundo positivo
                c_x <= '1';
                c_y <= '1';
            when "1101" =>  -- Resta, primero negativo, segundo positivo, swap
                c_x <= '1';
                c_y <= '1';
            when "1110" =>  -- Resta, primero negativo, segundo negativo
                c_x <= '1';
                c_y <= '0';
            when "1111" =>  -- Resta, primero negativo, segundo negativo, swap
                c_x <= '0';
                c_y <= '1';
            when others =>
                c_x <= '0';
                c_y <= '0';
        end case;
    end process;
       
    mx_ext <= ('0' & mx_p_t_a) when c_x = '0' else ca2_mx_p;
    my_ext <= ('0' & my_p_nt_a) when c_y = '0' else ca2_my_p;

    sum_m_ext <= mx_ext + my_ext;

    mz <=   sum_m_ext when sum_m_ext(2**NE + NF) = '0' else
             (not(sum_m_ext) + 1);
             
    shift <= 2**NE + NF - first_one_index(std_logic_vector(mz));
             
    mz_shifted <=  shift_left(mz, shift);
    
    fz_p <= mz_shifted(2**NE + NF - 1 downto 2**NE);-- viejo

    ez_p <= ex when exp_diff(NE) = '0' else ey;
    
    ez_not_sat <= resize(ez_p, NE+1) - resize(to_signed(shift, NE+1), NE+1);

    ez <= ez_not_sat(NE-1 downto 0) +1;
             
    sz <= sum_m_ext(2**NE + NF);
         
    fz <= std_logic_vector(fz_p);
             
    process(clk,rst)
    begin
        if rst='1' then
            z <= (others => '0');
        elsif rising_edge(clk) then
            z <= sz & std_logic_vector(ez) & fz;
        end if;
    end process;
 
end architecture behavioral;
