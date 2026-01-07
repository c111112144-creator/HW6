library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity two_board is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           btn : in STD_LOGIC;
           RTX : inout STD_LOGIC;
           leds: out STD_LOGIC_VECTOR (7 downto 0));
end entity;

architecture Behavioral of two_board is
    signal slow_cnt  : unsigned(23 downto 0) := (others => '0');-- 控制速度
    signal tick      : std_logic := '0';
    signal led_reg   : std_logic_vector(7 downto 0);
    signal led_sim   : std_logic_vector(15 downto 0);
    signal ph        : std_logic := '0';
    signal flash_cnt : integer range 0 to 5 := 0;-- 計數閃爍次數
    signal io_out, io_in, io_oe : std_logic;
    type state_type is (stby, loss, launch, flashing, RM, LM);
    --signal state : state_type := loss;
    signal state : state_type := launch;
begin
RTX <= io_out when io_oe = '1' else 'Z';
    
clkcheck:process(clk,rst)
begin
    if rst = '0' then
            slow_cnt <= (others => '0');
            tick <= '0';
        elsif rising_edge(clk) then
            slow_cnt <= slow_cnt + 1;
            if slow_cnt = 0 then
                tick <= '1';
            else
                tick <= '0';
            end if;
        end if;
end process clkcheck;

FSM:process(clk,rst,btn,RTX)
begin
    if rst = '0' then
            led_sim <= "0000000000000001";
            led_reg <= "00000001";
            --led_reg <= "00000000";
            flash_cnt <= 0;
            state <= launch;
            --state <= loss;
            io_oe  <= '0';
            io_out <= '0';
            io_in <= '0';
        elsif rising_edge(clk) then
            if tick = '1' then
                case state is
                    when launch =>
                        io_oe  <= '0';
                        io_out <= '0';
                        ph <= '0';
                        flash_cnt <= 0;
                        led_reg <= "00000001";
                        if btn = '1' then
                            state <= LM;
                        end if;
                    when LM =>
                        ph <= '0';
                        if led_reg = "10000000" then
                            io_oe  <= '1';
                            io_out <= '1';
                            state <= stby;
                        else
                            led_reg <= std_logic_vector(shift_left(unsigned(led_reg), 1));
                        end if;
                    when RM =>
                        ph <= '0';
                        if led_reg = "00000001" then
                            if ph = '1' then
                                state <= LM;
                                ph <= '0';
                            else
                                state <= loss;
                                io_oe  <= '1';
                                io_out <= '1';
                            end if;
                        else
                            if ph = '1' then
                                state <= loss;
                                io_oe  <= '1';
                                io_out <= '1';
                            end if;
                            led_reg <= std_logic_vector(shift_right(unsigned(led_reg), 1));
                        end if;
                    when stby =>
                        ph <= '0';
                        led_reg <= "00000000";
                        io_oe  <= '0';
                        io_out <= '0';
                        led_sim <= "0000000000000001";
                        if led_sim = "1000000000000000" then
                            if io_in = '1' then
                                led_reg <= "10000000";
                                state <= RM;
                            else
                                state <= flashing;
                            end if;
                        else
                            if io_in = '1' then
                                state <= flashing;
                            else
                                led_sim <= std_logic_vector(shift_left(unsigned(led_sim), 1));
                            end if;
                        end if;
                    when flashing =>
                        flash_cnt <= flash_cnt + 1;
                        -- 閃爍顯示交替
                        if flash_cnt mod 2 = 0 then
                            led_reg <= "00001111";
                        else
                            led_reg <= "00000000";
                        end if;
                        if flash_cnt = 5 then
                            state <= launch;
                        end if;
                    when loss =>
                        led_reg <= "00000000";
                        ph <= '0';
                        io_oe  <= '0';
                        io_out <= '0';
                        if io_in = '1' then
                                led_reg <= "10000000";
                                state <= RM;
                        end if;
                end case;
            end if;
        end if;
    if btn = '1' then
        ph <= '1';
    end if;
    if io_oe = '0' then
        io_in <= RTX;
    end if;
end process FSM;

leds   <= led_reg;
end Behavioral;
