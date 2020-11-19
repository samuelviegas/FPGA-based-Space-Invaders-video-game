-- Listing 13.6
-- FPGA based game: Space Invaders  --
-- Writen by Samuel Viegas & Hugo Aquino --
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
entity spaceinvaders_text is
   port(
      clk, reset: in std_logic;
      pixel_x, pixel_y: in std_logic_vector(9 downto 0);
      dig0, dig1: in std_logic_vector(3 downto 0);
      spaceship: in std_logic_vector(1 downto 0);
      text_on: out std_logic_vector(3 downto 0);
      text_rgb: out std_logic_vector(2 downto 0)
   );
end spaceinvaders_text;

architecture arch of spaceinvaders_text is
   signal pix_x, pix_y: unsigned(9 downto 0);
   signal rom_addr: std_logic_vector(10 downto 0);
   signal char_addr, char_addr_s, char_addr_r,
          char_addr_o: std_logic_vector(6 downto 0);
   signal row_addr, row_addr_s,row_addr_r,
          row_addr_o: std_logic_vector(3 downto 0);
   signal bit_addr, bit_addr_s,bit_addr_r,
          bit_addr_o: std_logic_vector(2 downto 0);
   signal font_word: std_logic_vector(7 downto 0);
   signal font_bit: std_logic;
   signal score_on,rule_on,over_on: std_logic;
   signal rule_rom_addr: unsigned(5 downto 0);
   type rule_rom_type is array (0 to 63) of
       std_logic_vector (6 downto 0);
   -- rull text ROM definition
   constant RULE_ROM: rule_rom_type :=
   (
      -- row 1
      "0000000", --
      "0000000", --
      "0000000", --
      "0000000", --
      "0000000", --
      "1010010", -- R
      "1010101", -- U
      "1001100", -- L
      "1000101", -- E
      "1010011", -- S
      "0111010", -- :
      "0000000", --
      "0000000", --
      "0000000", --
      "0000000", --
      "0000000", --
      -- row 2
		"0000000", --
      "1010101", -- U
      "1110011", -- s
      "1100101", -- e
      "0000000", --
      "1100010", -- b
      "1110100", -- t
      "1101110", -- n
		"0000000", --
      "0110000", -- 0
      "0111010", -- :
      "0110001", -- 1
      "0000000", -- 
      "1110100", -- t
      "1101111", -- o
      "0000000", --  
      -- row 3
		"0000000", --
      "1101101", -- m
      "1101111", -- o
      "1110110", -- v
      "1100101", -- e
      "0000000", --
      "1110011", -- s
      "1110000", -- p
      "1100001", -- a
      "1100011", -- c
      "1100101", -- e
      "1110011", -- s
      "1101000", -- h
      "1101001", -- i
		"1110000", -- p
		"0000000", --
      -- row 4
		"0100110", -- &
		"0000000", --
      "1100010", -- b
      "1110100", -- t
      "1101110", -- n
      "0000000", -- 
		"0110011", -- 3
		"0000000", -- 
      "1110100", -- t
      "1101111", -- o
      "0000000", --
      "1110011", -- s
      "1101000", -- h
      "1101111", -- o 
      "1101111", -- o
      "1110100"  -- t
   );
begin
   pix_x <= unsigned(pixel_x);
   pix_y <= unsigned(pixel_y);
   -- instantiate font rom
   font_unit: entity work.font_rom
      port map(clk=>clk, reset=>reset, addr=>rom_addr, data=>font_word);

   ---------------------------------------------
   -- score region
   --  - display two-digit score, spaceship on top left
   --  - scale to 16-by-32 font
   --  - line 1, 21 chars: "Score:DD Spaceship:D"
   ---------------------------------------------
   score_on <=
      '1' when pix_y(9 downto 5)=0 and
               pix_x(9 downto 4)<21 else
      '0';
   row_addr_s <= std_logic_vector(pix_y(4 downto 1));
   bit_addr_s <= std_logic_vector(pix_x(3 downto 1));
   with pix_x(8 downto 4) select
     char_addr_s <=
        "1010011" when "00000", -- S 
        "1100011" when "00001", -- c 
        "1101111" when "00010", -- o 
        "1110010" when "00011", -- r 
        "1100101" when "00100", -- e 
        "0111010" when "00101", -- : 
        "011" & dig1 when "00110", -- digit 10
        "011" & dig0 when "00111", -- digit 1
        "0000000" when "01000",
        "0000000" when "01001",
        "1010011" when "01010", -- S 
        "1110000" when "01011", -- p 
        "1100001" when "01100", -- a 
        "1100011" when "01101", -- c 
		  "1100101" when "01110", -- e
		  "1010011" when "01111", -- S
		  "1101000" when "10000", -- h
		  "1101001" when "10001", -- i
		  "1110000" when "10010", -- p
        "0111010" when "10011", -- :
        "01100" & spaceship when others;

   ---------------------------------------------
   -- rule region
   --   - display rule (4-by-16 tiles)on center
   --   - rule text:
   --        Rule:
   --        Use two buttons
   --        to move spaceship
   --        left and right
   ---------------------------------------------
   rule_on <= '1' when pix_x(9 downto 7)=  "010" and
                       pix_y(9 downto 6)=  "0100"  else
              '0';
   row_addr_r <= std_logic_vector(pix_y(3 downto 0));
   bit_addr_r <= std_logic_vector(pix_x(2 downto 0));
   rule_rom_addr <= pix_y(5 downto 4) & pix_x(6 downto 3);
   char_addr_r <= RULE_ROM(to_integer(rule_rom_addr));
	
   ---------------------------------------------
   -- game over region
   --  - display }Game Over" on center
   --  - scale to 32-by-64 fonts
   ---------------------------------------------
   over_on <=
      '1' when pix_y(9 downto 6)=3 and
         5<= pix_x(9 downto 5) and pix_x(9 downto 5)<=13 else
      '0';
   row_addr_o <= std_logic_vector(pix_y(5 downto 2));
   bit_addr_o <= std_logic_vector(pix_x(4 downto 2));
   with pix_x(8 downto 5) select
     char_addr_o <=
        "1000111" when "0101", -- G x47
        "1100001" when "0110", -- a x61
        "1101101" when "0111", -- m x6d
        "1100101" when "1000", -- e x65
        "0000000" when "1001", --
        "1001111" when "1010", -- O x4f
        "1110110" when "1011", -- v x76
        "1100101" when "1100", -- e x65
        "1110010" when others; -- r x72
   ---------------------------------------------
   -- mux for font ROM addresses and rgb
   ---------------------------------------------
   process(score_on,rule_on,pix_x,pix_y,font_bit,
           char_addr_s,char_addr_r,char_addr_o,
           row_addr_s,row_addr_r,row_addr_o,
           bit_addr_s,bit_addr_r,bit_addr_o)
   begin
      text_rgb <= "000";  -- background, black
      if score_on='1' then
         char_addr <= char_addr_s;
         row_addr <= row_addr_s;
         bit_addr <= bit_addr_s;
         if font_bit='1' then
            text_rgb <= "111";
         end if;
      elsif rule_on='1' then
         char_addr <= char_addr_r;
         row_addr <= row_addr_r;
         bit_addr <= bit_addr_r;
         if font_bit='1' then
            text_rgb <= "111";
         end if;
      else -- game over
         char_addr <= char_addr_o;
         row_addr <= row_addr_o;
         bit_addr <= bit_addr_o;
         if font_bit='1' then
            text_rgb <= "111";
         end if;
      end if;
   end process;
	-- '0' => logo on
   text_on <= score_on & '0' & rule_on & over_on;
   ---------------------------------------------
   -- font rom interface
   ---------------------------------------------
   rom_addr <= char_addr & row_addr;
   font_bit <= font_word(to_integer(unsigned(not bit_addr)));
end arch;
