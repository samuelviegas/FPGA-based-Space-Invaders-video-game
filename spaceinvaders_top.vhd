-- Listing 13.10
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity spaceinvaders_top is
   port(
      clock, reset: in std_logic;
      btn: in std_logic_vector (2 downto 0);
		ps2d, ps2c: in  std_logic;
      hsync,vsync,led:out std_logic;
      rgb: out   std_logic_vector (2 downto 0);
	  outred: out std_logic_vector(2 downto 0);
	  outgreen: out std_logic_vector(2 downto 0);
	  outblue: out std_logic_vector(1 downto 0)
   );
end spaceinvaders_top;

architecture arch of spaceinvaders_top is
   type state_type is (newgame, play, newship, over);
   signal state_reg, state_next: state_type;	
   signal clk: std_logic;
	signal video_on, pixel_tick: std_logic;
   signal pixel_x, pixel_y: std_logic_vector (9 downto 0);
   signal graph_on, gra_still,alien_hitted,spaceship_hitted,game_over,alien_new_game_pos:std_logic;
   signal text_on: std_logic_vector(3 downto 0);
   signal graph_rgb, text_rgb: std_logic_vector(2 downto 0);
   signal rgb_reg, rgb_next: std_logic_vector(2 downto 0);
   signal dig0, dig1: std_logic_vector(3 downto 0);
   signal d_inc, d_clr: std_logic;
   signal timer_tick, timer_start, timer_up: std_logic;
   signal spaceship_reg, spaceship_next: unsigned(1 downto 0);
   signal spaceship: std_logic_vector(1 downto 0);
	signal kb_not_empty, kb_buf_empty: std_logic;
	signal key_code, ascii_code: std_logic_vector(7 downto 0);
	signal keys: std_logic_vector (2 downto 0);
begin

   -- instantiate clock manager unit
	-- this unit converts the 25MHz input clock to the expected 50MHz clock
	ClockManager_unit: entity work.clockmanager 
	  port map(
		CLKIN_IN => clock,
		RST_IN => reset,
		CLK2X_OUT => clk,
		LOCKED_OUT => led);

   -- instantiate video synchonization unit
   vga_sync_unit: entity work.vga_sync
      port map(clk=>clk, reset=>reset,
               hsync=>hsync, vsync=>vsync,
               pixel_x=>pixel_x, pixel_y=>pixel_y,
               video_on=>video_on, p_tick=>pixel_tick);
   -- instantiate text module
   spaceship <= std_logic_vector(spaceship_reg);  --type conversion
   text_unit: entity work.spaceinvaders_text
      port map(clk=>clk, reset=>reset,
               pixel_x=>pixel_x, pixel_y=>pixel_y,
               dig0=>dig0, dig1=>dig1, spaceship=>spaceship,
               text_on=>text_on, text_rgb=>text_rgb);
   -- instantiate graph module
   graph_unit: entity work.spaceinvaders_graph
      port map(clk=>clk, reset=>reset, btn=>keys,
              pixel_x=>pixel_x, pixel_y=>pixel_y,dig1=>dig1,
              gra_still=>gra_still,alien_hitted=>alien_hitted,
				  spaceship_hitted=>spaceship_hitted,game_over=>game_over,
              graph_on=>graph_on,rgb=>graph_rgb,alien_new_game_pos=>alien_new_game_pos);
   -- instantiate 2 sec timer
   timer_tick <=  -- 60 Hz tick
      '1' when pixel_x="0000000000" and
               pixel_y="0000000000" else
      '0';
   timer_unit: entity work.timer
      port map(clk=>clk, reset=>reset,
               timer_tick=>timer_tick,
               timer_start=>timer_start,
               timer_up=>timer_up);
					
   -- instantiate 2-digit decade counter
   counter_unit: entity work.m100_counter
      port map(clk=>clk, reset=>reset,
               d_inc=>d_inc, d_clr=>d_clr,
               dig0=>dig0, dig1=>dig1);
					
	-- instantiate keyboard module				
	kb_code_unit: entity work.kb_code(arch)
      port map(clk=>clk, reset=>reset, ps2d=>ps2d, ps2c=>ps2c,
               rd_key_code=>kb_not_empty, key_code1=>key_code,
               kb_buf_empty=>kb_buf_empty);
					
	key2a_unit: entity work.key2ascii(arch)
      port map(key_code=>key_code, ascii_code=>ascii_code);
		
	keys(0)<='1' when ascii_code="01000100" or btn(0)='1' else '0'; -- D key
	keys(1)<='1' when ascii_code="01000001" or btn(1)='1' else '0'; -- A key
	keys(2)<='1' when ascii_code="00100000" or btn(2)='1' else '0'; -- Space
	
   -- registers
   process (clk,reset)
   begin
      if reset='1' then
         state_reg <= newgame;
         spaceship_reg <= (others=>'0');
         rgb_reg <= (others=>'0');
      elsif (clk'event and clk='1') then
         state_reg <= state_next;
         spaceship_reg <= spaceship_next;
         if (pixel_tick='1') then
           rgb_reg <= rgb_next;
         end if;
      end if;
   end process;
	
   -- fsmd next-state logic
   process(btn,alien_hitted,spaceship_hitted,timer_up,state_reg,
           spaceship_reg,spaceship_next)
   begin
      gra_still <= '1';
      timer_start <='0';
      d_inc <= '0';
      d_clr <= '0';
      state_next <= state_reg;
      spaceship_next <= spaceship_reg;
      case state_reg is
         when newgame =>
            spaceship_next <= "11";    -- three spaceships
            d_clr <= '1';         -- clear score
				alien_new_game_pos<='1';  
            if (keys /= "000") then -- button pressed
               state_next <= play;
               spaceship_next <= spaceship_reg - 1;
            end if;
         when play =>
				alien_new_game_pos<='0';
            gra_still <= '0';    -- animated screen
            if alien_hitted='1' then
               d_inc <= '1';     -- increment score
				elsif spaceship_hitted='1' then
               if (spaceship_reg=0) then
						timer_start<='1';
                  state_next <= over;
               else
						timer_start<='1';
                  state_next <= newship;
						spaceship_next <= spaceship_reg - 1;
               end if;
					elsif game_over='1' then
						timer_start<='1';
						state_next <= over;
            end if;			
         when newship =>
            -- wait for 2 sec and until button pressed
            if  timer_up='1' and (keys /= "000") then
              state_next <= play;
            end if;
         when over =>
            -- wait for 2 sec to display game over
            if timer_up='1' then
                state_next <= newgame;
            end if;
       end case;
   end process;
   -- rgb multiplexing circuit
   process(state_reg,video_on,graph_on,graph_rgb,
           text_on,text_rgb)
   begin
      if video_on='0' then
         rgb_next <= "000"; -- blank the edge/retrace
      else
         -- display score, rule or game over
         if (text_on(3)='1') or
            (state_reg=newgame and text_on(1)='1') or -- rule
            (state_reg=over and text_on(0)='1') then
            rgb_next <= text_rgb;
         elsif graph_on='1'  then -- display graph
           rgb_next <= graph_rgb;
         else
           rgb_next <= "000"; -- black background
         end if;
      end if;
   end process;
   outred <= rgb_reg(2) & rgb_reg(2) & rgb_reg(2);
   outgreen <= rgb_reg(1) & rgb_reg(1) & rgb_reg(1);
   outblue <= rgb_reg(0) & rgb_reg(0);
   rgb <= rgb_reg;
end arch;