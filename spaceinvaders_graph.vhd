-- Listing 13.7
-- FPGA based game: Space Invaders  --
-- Writen by Samuel Viegas & Hugo Aquino --
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity spaceinvaders_graph is
   port(
      clk,reset:std_logic;
      btn:std_logic_vector(2 downto 0);
		dig1:std_logic_vector(3 downto 0);
      pixel_x,pixel_y:in std_logic_vector(9 downto 0);
      gra_still,alien_new_game_pos:in std_logic;
      graph_on,alien_hitted,spaceship_hitted,game_over:out std_logic;
		
      rgb:out std_logic_vector(2 downto 0)
   );
end spaceinvaders_graph;

architecture arch of spaceinvaders_graph is

	----------------------------------------------
	-- DISPLAY VARIABLES
   ----------------------------------------------
	
	signal pix_x, pix_y: unsigned(9 downto 0);
   constant MAX_X: integer:=640;
   constant MAX_Y: integer:=480;
	constant X_OFFSET:integer:=70;
			
	----------------------------------------------
	-- SPACESHIP ROM
   ----------------------------------------------
	
	constant SPACESHIP_X_SIZE: integer:=16*2;
	constant SPACESHIP_Y_SIZE: integer:=16*2;
	type rom_type is array (0 to 15,0 to 15) of std_logic_vector(2 downto 0);
	constant SPACESHIP:rom_type:=
   	(
		("000","000","000","000","000","000","000","100","100","000","000","000","000","000","000","000"),
		("000","000","000","000","000","000","000","100","100","000","000","000","000","000","000","000"),
		("000","000","000","000","000","000","111","111","111","111","000","000","000","000","000","000"),
		("000","000","000","000","000","000","111","111","111","111","000","000","000","000","000","000"),
		("000","000","000","100","000","000","111","111","111","111","000","000","100","000","000","000"),
		("000","000","000","100","000","000","111","111","111","111","000","000","100","000","000","000"),
		("000","000","000","111","000","000","111","100","100","111","000","000","111","000","000","000"),
		("100","000","000","111","000","000","100","100","100","100","000","000","111","000","000","100"),
		("100","000","000","111","001","111","100","111","111","100","111","001","111","000","000","100"),
		("100","000","000","001","001","111","111","111","111","111","111","001","001","000","000","100"),
		("111","000","111","111","111","111","111","111","111","111","111","111","111","111","000","111"),
		("111","111","111","111","111","111","100","111","111","100","111","111","111","111","111","111"),
		("111","111","111","111","111","100","100","111","111","100","100","111","111","111","111","111"),
		("111","111","111","000","000","100","100","111","111","100","100","000","000","111","111","111"),
		("001","001","000","000","000","100","100","111","111","100","100","000","000","000","001","001"),
		("001","000","000","000","000","000","000","111","111","000","000","000","000","000","000","001")
	);
	
	----------------------------------------------
	-- ALIEN A ROM
   ----------------------------------------------
	
	constant ALIEN_SIZE_X: integer:=16*2;
	constant ALIEN_SIZE_Y: integer:=16*2;
	type rom_type2 is array (0 to 15,0 to 15) of std_logic_vector(2 downto 0);
	constant ALIEN_A:rom_type2:=
   	(
		("000","000","000","000","000","000","000","000","000","000","000","000","000","000","000","000"),
		("000","000","000","011","011","000","000","000","000","000","000","011","011","000","000","000"),
		("000","000","000","011","011","011","000","000","000","000","011","011","011","000","000","000"),
		("000","000","000","000","011","011","000","000","000","000","011","011","000","000","000","000"),
		("000","000","000","000","000","011","011","011","011","011","011","000","000","000","000","000"),
		("000","000","000","000","000","011","000","011","011","000","011","000","000","000","000","000"),
		("000","000","000","000","011","011","000","011","011","000","011","011","000","000","000","000"),
		("000","000","000","011","011","011","011","011","011","011","011","011","011","000","000","000"),
		("000","000","011","011","011","011","011","011","011","011","011","011","011","011","000","000"),
		("000","011","011","011","011","011","011","011","011","011","011","011","011","011","011","000"),
		("000","011","011","000","011","011","011","011","011","011","011","011","000","011","011","000"),
		("000","011","011","000","011","011","000","000","000","000","011","011","000","011","011","000"),
		("000","011","011","000","011","011","000","000","000","000","011","011","000","011","011","000"),
		("000","000","000","000","011","011","000","000","000","000","011","011","000","000","000","000"),
		("000","000","000","000","011","011","000","000","000","000","011","011","000","000","000","000"),
		("000","000","000","000","000","000","000","000","000","000","000","000","000","000","000","000")
   	-- object is 16x16 instead of 14x14 to fill power of 2 matrix
	);
	
	----------------------------------------------
	-- ALIEN B ROM
   ----------------------------------------------
	
	constant ALIEN_B:rom_type2:=
   	(
		("000","000","000","000","000","000","000","000","000","000","000","000","000","000","000","000"),
		("000","000","000","000","000","000","101","101","101","101","000","000","000","000","000","000"),
		("000","000","000","101","101","101","101","101","101","101","101","101","101","000","000","000"),
		("000","101","101","101","101","101","101","101","101","101","101","101","101","101","101","000"),
		("000","101","101","101","101","101","101","101","101","101","101","101","101","101","101","000"),
		("000","101","101","101","000","000","000","101","101","000","000","000","101","101","101","000"),
		("000","101","101","101","000","000","000","101","101","000","000","000","101","101","101","000"),
		("000","101","101","101","101","101","101","101","101","101","101","101","101","101","101","000"),
		("000","101","101","101","101","101","101","101","101","101","101","101","101","101","101","000"),
		("000","000","000","000","000","101","101","000","000","101","101","000","000","000","000","000"),
		("000","000","000","000","000","101","101","000","000","101","101","000","000","000","000","000"),
		("000","000","000","101","101","000","000","101","101","000","000","101","101","000","000","000"),
		("000","000","000","101","101","000","000","101","101","000","000","101","101","000","000","000"),
		("000","101","101","000","000","000","000","000","000","000","000","000","000","101","101","000"),
		("000","101","101","000","000","000","000","000","000","000","000","000","000","101","101","000"),
		("000","000","000","000","000","000","000","000","000","000","000","000","000","000","000","000")
   	-- object is 16x16 instead of 14x14 to fill power of 2 matrix
	);
	
	----------------------------------------------
	-- UFO BOSS ROM
   ----------------------------------------------
	
	constant UFO_X_SIZE: integer:=32*2;
	constant UFO_Y_SIZE: integer:=32*2;
	type rom_type3 is array (0 to 31,0 to 31) of std_logic_vector(2 downto 0);
	constant UFO:rom_type3:=
   	(
		("000","000","000","000","000","000","000","000","000","000","000","000","000","111","111","111","111","111","111","000","000","000","000","000","000","000","000","000","000","000","000","000"),
		("000","000","000","000","000","000","000","000","000","000","000","111","111","000","000","000","000","000","000","111","111","000","000","000","000","000","000","000","000","000","000","000"),
		("000","000","000","000","000","000","000","000","000","111","111","000","000","000","000","000","000","000","000","000","000","111","111","000","000","000","000","000","000","000","000","000"),
		("000","000","000","000","000","000","000","111","111","000","000","000","010","010","010","010","010","010","010","010","000","000","000","111","111","000","000","000","000","000","000","000"),
		("000","000","000","000","000","111","111","000","000","000","010","010","010","010","010","010","010","010","010","010","010","010","000","000","000","111","111","000","000","000","000","000"),
		("000","000","000","000","111","000","000","000","000","010","010","010","010","010","010","010","010","010","010","010","010","010","010","000","000","000","000","111","000","000","000","000"),
		("000","000","000","000","111","000","000","000","010","010","010","010","010","010","010","010","010","010","010","010","010","010","010","010","000","000","000","111","000","000","000","000"),
		("000","000","000","111","000","000","000","010","010","010","010","010","010","010","010","010","010","010","010","010","010","010","010","010","010","000","000","000","111","000","000","000"),
		("000","000","000","111","000","000","000","010","010","010","010","010","010","010","010","010","010","010","010","010","010","010","010","010","010","000","000","000","111","000","000","000"),
		("000","000","111","000","000","000","010","010","010","010","010","010","010","010","010","010","010","010","010","010","010","010","010","010","010","010","000","000","000","111","000","000"),
		("000","000","111","000","000","000","010","010","000","000","000","000","010","010","010","010","010","010","010","010","000","000","000","000","010","010","000","000","000","111","000","000"),
		("000","000","111","000","000","000","010","010","000","000","000","000","000","010","010","010","010","010","010","000","000","000","000","000","010","010","000","000","000","111","000","000"),
		("000","000","111","000","000","000","010","010","000","000","000","000","000","000","010","010","010","010","000","000","000","000","000","000","010","010","000","000","000","111","000","000"),
		("000","000","111","000","000","000","000","010","010","000","000","000","000","000","000","010","010","000","000","000","000","000","000","010","010","000","000","000","000","111","000","000"),
		("000","000","111","000","000","000","000","010","010","010","000","000","000","000","000","010","010","000","000","000","000","000","010","010","010","000","000","000","000","111","000","000"),
		("000","000","111","000","000","000","000","000","010","010","010","010","000","000","000","010","010","000","000","000","010","010","010","010","000","000","000","000","000","111","000","000"),
		("000","000","111","000","000","000","000","000","010","010","010","010","010","010","010","010","010","010","010","010","010","010","010","010","000","000","000","000","000","111","000","000"),
		("000","000","111","000","000","000","000","000","000","010","010","010","010","010","010","010","010","010","010","010","010","010","010","000","000","000","000","000","000","111","000","000"),
		("000","000","111","000","000","000","000","000","000","000","010","010","010","010","010","010","010","010","010","010","010","010","000","000","000","000","000","000","000","111","000","000"),
		("000","000","111","000","000","000","000","000","000","000","000","010","010","010","010","010","010","010","010","010","010","000","000","000","000","000","000","000","000","111","000","000"),
		("000","000","111","000","000","000","000","000","000","000","000","000","010","010","010","010","010","010","010","010","000","000","000","000","000","000","000","000","000","111","000","000"),
		("000","000","111","000","000","000","000","000","000","000","000","000","000","010","010","010","010","010","010","000","000","000","000","000","000","000","000","000","000","111","000","000"),
		("000","000","111","000","010","010","010","010","000","000","000","000","000","000","010","010","010","010","000","000","000","000","000","000","010","010","010","010","000","111","000","000"),
		("000","111","111","000","010","100","100","010","000","000","000","000","000","000","000","000","000","000","000","000","000","000","000","000","010","100","100","010","000","111","111","000"),
		("111","111","111","111","111","111","111","111","111","111","111","111","111","111","111","111","111","111","111","111","111","111","111","111","111","111","111","111","111","111","111","111"),
		("111","001","001","111","001","111","001","111","001","111","001","111","001","111","001","111","001","111","001","111","001","111","001","111","001","111","001","111","001","111","001","111"),
		("111","100","111","100","111","100","111","100","111","100","111","100","111","100","111","100","111","100","111","100","111","100","111","100","111","100","111","100","111","100","100","111"),
		("111","111","001","111","001","111","001","111","001","111","001","111","001","111","001","111","001","111","001","111","001","111","001","111","001","111","001","111","001","111","111","111"),
		("000","111","111","100","110","110","110","110","100","100","100","100","100","100","110","110","110","110","100","100","100","100","100","100","110","110","110","110","100","111","111","000"),
		("000","000","111","111","111","110","110","111","111","111","111","111","111","111","111","110","110","111","111","111","111","111","111","111","111","110","110","111","111","111","000","000"),
		("000","000","000","000","111","110","110","111","000","000","000","000","000","000","111","110","110","111","000","000","000","000","000","000","111","110","110","111","000","000","000","000"),
		("000","000","000","000","110","110","110","110","000","000","000","000","000","000","110","110","110","110","000","000","000","000","000","000","110","110","110","110","000","000","000","000")
	);
	
	----------------------------------------------
	-- UFO BULLET ROM
   ----------------------------------------------
	
	constant UFO_BULLET_SIZE_X:integer:=8;
	constant UFO_BULLET_SIZE_Y:integer:=8;
	type rom_type4 is array (0 to 7,0 to 7) of std_logic_vector(2 downto 0);
	constant UFO_BULLET:rom_type4:=
   	(
		("000","000","100","100","100","100","000","000"),
		("000","100","100","100","100","100","100","000"),
		("100","100","100","100","100","100","100","100"),
		("100","100","100","100","100","100","100","100"),
		("100","100","100","100","100","100","100","100"),
		("100","100","100","100","100","100","100","100"),
		("000","100","100","100","100","100","100","000"),
		("000","000","100","100","100","100","000","000")
	);

	----------------------------------------------
	-- VARIABLES FOR REFR_TICK2 
   ----------------------------------------------	
	
	signal refr_tick:std_logic;
	signal refr_tick2:std_logic;
	constant CLK_MS_COUNT:integer:=50000000; --100hz tick
	signal t_reg,t_next:unsigned(28 downto 0); -- up to 100000000
	--2^27=134217728

	----------------------------------------------
	-- SHIELDS FOR THE SPACESHIP
   ----------------------------------------------	
	
	constant SHIELD_Y_T:integer:=400;
	constant SHIELD_Y_B:integer:=SHIELD_Y_T+8;
	constant SHIELD_2_X_L:integer:=290+X_OFFSET; ------ central shield
	constant SHIELD_2_X_R:integer:=SHIELD_2_X_L+60;------------------
	constant SHIELD_1_X_L:integer:=SHIELD_2_X_L-180; -- left shield
	constant SHIELD_1_X_R:integer:=SHIELD_1_X_L+60;-------------------
	constant SHIELD_3_X_L:integer:=SHIELD_2_X_L+180; -- right shield
	constant SHIELD_3_X_R:integer:=SHIELD_3_X_L+60;-------------------
	signal shield_1_on,shield_2_on,shield_3_on:std_logic;
	signal shield_rgb:std_logic_vector(2 downto 0);

	----------------------------------------------
	-- SPACESHIP SIGNALS
   ----------------------------------------------	
	
	signal SPACESHIP_Y_T,SPACESHIP_Y_B:unsigned(9 downto 0);
	signal SPACESHIP_X_R,SPACESHIP_X_L:unsigned(9 downto 0);
	signal spaceship_x_reg,spaceship_x_next:unsigned(9 downto 0);
	constant SPACESHIP_V:integer:=4;
	signal rom_spaceship_addr,rom_spaceship_col:unsigned(3 downto 0);
	signal rom_spaceship_bit:std_logic_vector(2 downto 0);
	signal ship_rgb:std_logic_vector(2 downto 0);
	signal ship_on:std_logic;
	
	----------------------------------------------
	-- UFO BOSS SIGNALS
   ----------------------------------------------	
	
	signal UFO_Y_T,UFO_Y_B:unsigned(9 downto 0);
	signal UFO_X_R,UFO_X_L:unsigned(9 downto 0);
	signal ufo_x_reg,ufo_x_next:unsigned(9 downto 0);
	signal rom_ufo_addr,rom_ufo_col:unsigned(4 downto 0);
	signal rom_ufo_bit:std_logic_vector(2 downto 0);
	signal ufo_rgb:std_logic_vector(2 downto 0);
	signal ufo_on:std_logic;
	constant UFO_V_P:unsigned(9 downto 0):=to_unsigned(1,10);
	constant UFO_V_N:unsigned(9 downto 0):=unsigned(to_signed(-1,10));
	signal ufo_vx_reg,ufo_vx_next:unsigned(9 downto 0);

	----------------------------------------------
	-- RANDOM SIGNALS FOR UFO BOSS
   ----------------------------------------------	
	
	signal rand_reg,rand_reg_next:std_logic_vector(9 downto 0);
	type state_type_rand is (rand_gen,rand_gen_wait);
	signal rand_state_reg,rand_state_next:state_type_rand;
	signal rand_on:std_logic;
	constant CONST_VALUE:integer:=20;
	
	----------------------------------------------
	-- ALL ALIENS
   ----------------------------------------------	
	
	--C = columns
	--L = lines
	--A1,B1,A2,B2.... aliens
	----------------------------------------------------------------------
	-------	  C1        C2       C3       C4       C5             -------
	------       ^        ^        ^        ^        ^              ------
	-----    |--------|--------|--------|--------|----------------   -----
	----     |        |        |        |        |                    ----     
	---      A1  ---  B2  ---  A3  ---  B4  ---  A5  ------->> L1      ---
   ----		 						                                       ----
	-----    B1  ---  A2  ---  B3  ---  A4  ---  B5  ------->> L2    -----
	------	  							                                  ------
	-------	 						                                    -------		
	----------------------------------------------------------------------
	
	
   	--variables relative to the lines
	signal ALIEN_L1_Y_T,ALIEN_L1_Y_B:unsigned(9 downto 0);
	signal ALIEN_L2_Y_T,ALIEN_L2_Y_B:unsigned(9 downto 0);
	signal OFFSET_LINE:unsigned(9 downto 0):=to_unsigned(40,10);
	signal OFFSET_SPACE_LINE:unsigned(9 downto 0):=to_unsigned(8,10);
	

	--alien columns
	signal ALIEN_C1_X_R,ALIEN_C1_X_L:unsigned(9 downto 0);
	signal ALIEN_C2_X_R,ALIEN_C2_X_L:unsigned(9 downto 0);
	signal ALIEN_C3_X_R,ALIEN_C3_X_L:unsigned(9 downto 0);
	signal ALIEN_C4_X_R,ALIEN_C4_X_L:unsigned(9 downto 0);
	signal ALIEN_C5_X_R,ALIEN_C5_X_L:unsigned(9 downto 0);
	signal OFFSET_C2:unsigned(9 downto 0):=to_unsigned(50,10);
	signal OFFSET_C3:unsigned(9 downto 0):=to_unsigned(100,10);
	signal OFFSET_C4:unsigned(9 downto 0):=to_unsigned(150,10);
	signal OFFSET_C5:unsigned(9 downto 0):=to_unsigned(200,10);
	

	--alien rom signals
	signal rom_alien_L1_addr:unsigned(3 downto 0);
	signal rom_alien_L2_addr:unsigned(3 downto 0);
	signal rom_alien_C1_col:unsigned(3 downto 0);
	signal rom_alien_C2_col:unsigned(3 downto 0);
	signal rom_alien_C3_col:unsigned(3 downto 0);
	signal rom_alien_C4_col:unsigned(3 downto 0);
	signal rom_alien_C5_col:unsigned(3 downto 0);
	
	
	--alien A1
	signal rom_alien_a1_bit:std_logic_vector(2 downto 0);
	signal alien_a1_rgb:std_logic_vector(2 downto 0);
	signal alien_a1_on:std_logic;
	
	--alien A2
	signal rom_alien_a2_bit:std_logic_vector(2 downto 0);
	signal alien_a2_rgb:std_logic_vector(2 downto 0);
	signal alien_a2_on:std_logic;

	--alien A3
	signal rom_alien_a3_bit:std_logic_vector(2 downto 0);
	signal alien_a3_rgb:std_logic_vector(2 downto 0);
	signal alien_a3_on:std_logic;
	
	--alien A4
	signal rom_alien_a4_bit:std_logic_vector(2 downto 0);
	signal alien_a4_rgb:std_logic_vector(2 downto 0);
	signal alien_a4_on:std_logic;	
	
	--alien A5
	signal rom_alien_a5_bit:std_logic_vector(2 downto 0);
	signal alien_a5_rgb:std_logic_vector(2 downto 0);
	signal alien_a5_on:std_logic;
	
	--alien B1
	signal rom_alien_b1_bit:std_logic_vector(2 downto 0);
   signal alien_b1_rgb:std_logic_vector(2 downto 0);
	signal alien_b1_on:std_logic;
	
	--alien B2
	signal rom_alien_b2_bit:std_logic_vector(2 downto 0);
   signal alien_b2_rgb:std_logic_vector(2 downto 0);
	signal alien_b2_on:std_logic;
	
	--alien B3
	signal rom_alien_b3_bit:std_logic_vector(2 downto 0);
   signal alien_b3_rgb:std_logic_vector(2 downto 0);
	signal alien_b3_on:std_logic;
	
	--alien B4
	signal rom_alien_b4_bit:std_logic_vector(2 downto 0);
   signal alien_b4_rgb:std_logic_vector(2 downto 0);
	signal alien_b4_on:std_logic;
	
	--alien B5
	signal rom_alien_b5_bit:std_logic_vector(2 downto 0);
   signal alien_b5_rgb:std_logic_vector(2 downto 0);
	signal alien_b5_on:std_logic;
	
   --Velocity and velocity regs	
	constant ALIEN_V_P:unsigned(9 downto 0):=to_unsigned(15,10);
	constant ALIEN_V_N:unsigned(9 downto 0):=unsigned(to_signed(-15,10));
	signal alien_vx_reg,alien_vx_next:unsigned(9 downto 0);

	--Aliens reg
	signal alien_x_reg,alien_x_next:unsigned(9 downto 0);	
	signal alien_y_reg,alien_y_next:unsigned(9 downto 0);
	
	type state_type2 is (inicio,go_esquerda,go_direita,stop_walk,stop_walk_wait,go_descer_linha);
	signal alien_state_reg,alien_state_next:state_type2;
	
	--Aliens live_reg
	signal alien_live_reg,alien_live_next:unsigned(9 downto 0);
	signal start_aliens:std_logic;
	
	----------------------------------------------
	-- HITS REG
   ----------------------------------------------
	
	signal alien_hitted_reg,alien_hitted_next:std_logic;
	signal spaceship_hitted_next:std_logic;

	----------------------------------------------
	-- UFO BULLET SIGNALS
   ----------------------------------------------	
	
	signal UFO_BULLET_Y_T,UFO_BULLET_Y_B:unsigned(9 downto 0);
	signal UFO_BULLET_X_R,UFO_BULLET_X_L:unsigned(9 downto 0);
	signal ufo_bullet_y_reg,ufo_bullet_y_next:unsigned(9 downto 0);
	signal rom_ufo_bullet_addr,rom_ufo_bullet_col:unsigned(2 downto 0);
	signal rom_ufo_bullet_bit,ufo_bullet_rgb:std_logic_vector(2 downto 0);
	signal ufo_bullet_on:std_logic;
	signal UFO_BULLET_V:integer;
	type state_type_b is (inicio_b,go_b);
	signal ufo_bullet_start,ufo_bullet_end,ufo_bullet_shield_1,ufo_bullet_shield_2,ufo_bullet_shield_3:std_logic;
	signal bullet_spaceship:std_logic;
	signal ufo_bullet_st_reg,ufo_bullet_st_next:state_type_b;	
	
	----------------------------------------------
	-- BULLET SIGNALS
   ----------------------------------------------
	
	signal bullet_x_l,bullet_x_r:unsigned(9 downto 0);
	signal bullet_y_t, bullet_y_b:unsigned(9 downto 0);
	constant BULLET_Y_SIZE:integer:=4;
	signal bullet_x_pos,bullet_y_pos,bullet_y_nextpos: unsigned(9 downto 0);
	signal BULLET_V:integer:=6;
	signal bullet_rgb:std_logic_vector(2 downto 0);
	signal bullet_on:std_logic;
	signal shoot_tick:std_logic; -- signal that indicates that btn(2) was pressed
	type state_type is (inicio,go);
	signal bullet_start,bullet_end,bullet_shield_1,bullet_shield_2,bullet_shield_3:std_logic;
	
	-- one bullet for each alien
	signal bullet_alien_b1,bullet_alien_b2,bullet_alien_b3,bullet_alien_b4,bullet_alien_b5,
			 bullet_alien_a1,bullet_alien_a2,bullet_alien_a3,bullet_alien_a4,bullet_alien_a5:std_logic;
			 
	-- bullet state register refresh
	signal bullet_state_reg,bullet_state_next:state_type;
	
--------------------------------------------------------------------------------------------------------------------------	
----------------------         PROCESS'S BEGINNING        ---------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------

begin	

	---------------------------------------------------------------------------------
	-- instantiate debounce circuit for shoot button
   ---------------------------------------------------------------------------------
   debounce_unit0: entity work.debounce
   port map(clk=>clk,reset=>reset,sw=>btn(2),db_level=>open,db_tick=>shoot_tick);
	---------------------------------------------------------------------------------
	
	-- Defines Y-axis limits for the spaceship movement
	SPACESHIP_Y_T<=to_unsigned(428,10);
	SPACESHIP_Y_B<=to_unsigned(460,10);
	
	-- Defines Y-axis limits for the ufo movement
	UFO_Y_T<=to_unsigned(60,10);
	UFO_Y_B<=to_unsigned(124,10);
	
   -- registers
   process (clk,reset)
   begin
      if reset='1' then		
			t_reg <= (OTHERS=>'0');
			alien_live_reg<=(OTHERS=>'1');
			alien_y_reg<=(OTHERS=>'0');
			ufo_vx_reg<=("0000000010");
			alien_vx_reg<=("0000000010");
			rand_reg<=("0010110101"); -- seed for pseudo random generator
			ufo_x_reg<=(OTHERS=>'0');
			alien_x_reg<=(OTHERS=>'0');
			spaceship_x_reg<=to_unsigned(SPACESHIP_X_SIZE+X_OFFSET,10);
			bullet_state_reg<=inicio;
			alien_state_reg<=inicio;
			ufo_bullet_st_reg<=inicio_b;
			rand_state_reg<=rand_gen;
			bullet_y_pos<=to_unsigned(432-BULLET_Y_SIZE,10); -- 432=SPACESHIP_Y_T + 4, so that the bullet "appears" inside the spaceship
			ufo_bullet_y_reg<=to_unsigned(124-BULLET_Y_SIZE,10); -- 124=UFO_Y_T + 8 , so that the bullet "appears" inside the ufo
			
      elsif (clk'event and clk='1') then
			
			ufo_x_reg<=ufo_x_next;
			spaceship_x_reg<=spaceship_x_next;
			alien_x_reg<=alien_x_next;
			bullet_state_reg<=bullet_state_next;
			bullet_y_pos<=bullet_y_nextpos;
			ufo_bullet_st_reg<=ufo_bullet_st_next;
			ufo_bullet_y_reg<=ufo_bullet_y_next;
			ufo_vx_reg<=ufo_vx_next;
			alien_vx_reg<=alien_vx_next;
			alien_live_reg<=alien_live_next;
			alien_y_reg<=alien_y_next;
			t_reg <= t_next;
			alien_state_reg<=alien_state_next;
			rand_state_reg<=rand_state_next;
--			rand_reg_next<=rand_reg;

      end if;
   end process;
   pix_x <= unsigned(pixel_x)+X_OFFSET;
   pix_y <= unsigned(pixel_y);
   refr_tick <= '1' when (pix_y=481) and (pix_x=71) else
					 '0';	-- 71 is the offset value on x-axis
				 
	------------------------------------------------			 
	--Shift Register	to make refr_tick 2times slower		 
	------------------------------------------------

	process(t_reg,t_next)
	begin
	 refr_tick2<='0';	
	 t_next <= t_reg;
		if (t_reg = CLK_MS_COUNT-1) then -- 0,5sec tick
			t_next <= (OTHERS=>'0');
			refr_tick2<='1';
		else
			t_next <= t_reg + 1;
		end if;
	end process;
							 
	----------------------------------------------
	-- bullet screen
   ----------------------------------------------
	
	bullet_x_l <= bullet_x_r-BULLET_Y_SIZE;
	bullet_y_t <= bullet_y_pos;
   bullet_y_b <= bullet_y_t + BULLET_Y_SIZE - 1;
   bullet_on <=
      '1' when (pix_x>=bullet_x_l) and (pix_x<=bullet_x_r) and
               (bullet_y_t<=pix_y) and (pix_y<=bullet_y_b) else
      '0';

	----------------------------------------------
	-- UFO BULLET SCREEN
   ----------------------------------------------
	
	UFO_BULLET_X_L<=UFO_BULLET_X_R-UFO_BULLET_SIZE_X-1;
	UFO_BULLET_Y_T<=ufo_bullet_y_reg;
   UFO_BULLET_Y_B<=ufo_bullet_y_reg+UFO_BULLET_SIZE_Y-1;
	rom_ufo_bullet_addr<=pix_y(2 downto 0)-UFO_BULLET_Y_T(2 downto 0);
   rom_ufo_bullet_col<=pix_x(2 downto 0)-UFO_BULLET_X_L(2 downto 0);
	rom_ufo_bullet_bit<=UFO_BULLET(to_integer(rom_ufo_bullet_addr),to_integer(rom_ufo_bullet_col));
   ufo_bullet_on<=
      '1' when 
					(pix_x>=UFO_BULLET_X_L) and (pix_x<=UFO_BULLET_X_R) and
					(UFO_BULLET_Y_T<=pix_y) and (pix_y<=UFO_BULLET_Y_B) and (rom_ufo_bullet_bit/="000")
					else
      '0'; 
	
	----------------------------------------------
	-- spaceship screen
   ---------------------------------------------- 
	
	rom_spaceship_addr<=pix_y(4 downto 1)-SPACESHIP_Y_T(4 downto 1);
   rom_spaceship_col<=pix_x(4 downto 1)-SPACESHIP_X_L(4 downto 1);
	rom_spaceship_bit<=SPACESHIP(to_integer(rom_spaceship_addr),to_integer(rom_spaceship_col));
   SPACESHIP_X_L<=spaceship_x_reg;
   SPACESHIP_X_R<=spaceship_x_reg+SPACESHIP_X_SIZE-1;
   ship_on<=
      		'1' when 
					(pix_x>=SPACESHIP_X_L) and (pix_x<=SPACESHIP_X_R) and
					(SPACESHIP_Y_T<=pix_y) and (pix_y<=SPACESHIP_Y_B) else
      		'0';
					ship_rgb <= rom_spaceship_bit; 
	
	----------------------------------------------
	-- UFO screen
   ---------------------------------------------- 
	
	rom_ufo_addr<=pix_y(5 downto 1)-UFO_Y_T(5 downto 1);
   rom_ufo_col<=pix_x(5 downto 1)-UFO_X_L(5 downto 1);
	rom_ufo_bit<=UFO(to_integer(rom_ufo_addr),to_integer(rom_ufo_col));
  	UFO_X_L<=ufo_x_reg;
  	UFO_X_R<=ufo_x_reg+UFO_X_SIZE-1;
   ufo_on<=
      		'1' when 
					(pix_x>=UFO_X_L) and (pix_x<=UFO_X_R) and
					(UFO_Y_T<=pix_y) and (pix_y<=UFO_Y_B) and (rom_ufo_bit/="000") 
					else
      		'0';
					ufo_rgb <= rom_ufo_bit; 
	
	
	----------------------------------------------
	-- ALIENS screen
   ---------------------------------------------- 
	
	--roms columns lines
	rom_alien_L1_addr<=pix_y(4 downto 1)-ALIEN_L1_Y_T(4 downto 1);
	rom_alien_L2_addr<=pix_y(4 downto 1)-ALIEN_L2_Y_T(4 downto 1);

   rom_alien_C1_col<=pix_x(4 downto 1)-ALIEN_C1_X_L(4 downto 1);
	rom_alien_C2_col<=pix_x(4 downto 1)-ALIEN_C2_X_L(4 downto 1);
   rom_alien_C3_col<=pix_x(4 downto 1)-ALIEN_C3_X_L(4 downto 1);
	rom_alien_C4_col<=pix_x(4 downto 1)-ALIEN_C4_X_L(4 downto 1);
	rom_alien_C5_col<=pix_x(4 downto 1)-ALIEN_C5_X_L(4 downto 1);

	ALIEN_L1_Y_T<=alien_y_reg;
	ALIEN_L1_Y_B<=ALIEN_L1_Y_T+ALIEN_SIZE_Y-1;
	ALIEN_L2_Y_T<=ALIEN_L1_Y_B+OFFSET_SPACE_LINE;
	ALIEN_L2_Y_B<=ALIEN_L2_Y_T+ALIEN_SIZE_Y-1;
	
	ALIEN_C1_X_L<=alien_x_reg;
   ALIEN_C1_X_R<=ALIEN_C1_X_L+ALIEN_SIZE_X-1;
	ALIEN_C2_X_L<=ALIEN_C1_X_L+OFFSET_C2;
   ALIEN_C2_X_R<=alien_x_reg+OFFSET_C2+ALIEN_SIZE_X-1;
	ALIEN_C3_X_L<=alien_x_reg+OFFSET_C3;
   ALIEN_C3_X_R<=alien_x_reg+OFFSET_C3+ALIEN_SIZE_X-1;
	ALIEN_C4_X_L<=alien_x_reg+OFFSET_C4;
   ALIEN_C4_X_R<=alien_x_reg+OFFSET_C4+ALIEN_SIZE_X-1;
	ALIEN_C5_X_L<=alien_x_reg+OFFSET_C5;
   ALIEN_C5_X_R<=alien_x_reg+OFFSET_C5+ALIEN_SIZE_X-1;
	
	
	--alien a1 on
	rom_alien_a1_bit<=ALIEN_A(to_integer(rom_alien_L1_addr),to_integer(rom_alien_C1_col));
   alien_a1_on<=
      		'1' when 
					(pix_x>=ALIEN_C1_X_L) and (pix_x<=ALIEN_C1_X_R) and
					(ALIEN_L1_Y_T<=pix_y) and (pix_y<=ALIEN_L1_Y_B) and
					(rom_alien_a1_bit/="000") else
      		'0';
					alien_a1_rgb <= rom_alien_a1_bit; 
	
	-- alien b1 on
	rom_alien_b1_bit<=ALIEN_B(to_integer(rom_alien_L2_addr),to_integer(rom_alien_C1_col));
   alien_b1_on<=
      		'1' when 
					(pix_x>=ALIEN_C1_X_L) and (pix_x<=ALIEN_C1_X_R) and
					(ALIEN_L2_Y_T<=pix_y) and (pix_y<=ALIEN_L2_Y_B) and 
					(rom_alien_b1_bit/="000") else
      		'0';
					alien_b1_rgb <= rom_alien_b1_bit;

	-- alien a2 on
	rom_alien_a2_bit<=ALIEN_A(to_integer(rom_alien_L2_addr),to_integer(rom_alien_C2_col));
   alien_a2_on<=
      		'1' when 
					(pix_x>=ALIEN_C2_X_L) and (pix_x<=ALIEN_C2_X_R) and
					(ALIEN_L2_Y_T<=pix_y) and (pix_y<=ALIEN_L2_Y_B) and
					(rom_alien_a2_bit/="000") else
      		'0';
					alien_a2_rgb <= rom_alien_a2_bit; 
					
	-- alien b2 on
	rom_alien_b2_bit<=ALIEN_B(to_integer(rom_alien_L1_addr),to_integer(rom_alien_C2_col));
   alien_b2_on<=
      		'1' when 
					(pix_x>=ALIEN_C2_X_L) and (pix_x<=ALIEN_C2_X_R) and
					(ALIEN_L1_Y_T<=pix_y) and (pix_y<=ALIEN_L1_Y_B) and
					(rom_alien_b2_bit/="000") else
				'0';
					alien_b2_rgb <= rom_alien_b2_bit;
					
	-- alien a3 on
	rom_alien_a3_bit<=ALIEN_A(to_integer(rom_alien_L1_addr),to_integer(rom_alien_C3_col));
   alien_a3_on<=
      		'1' when 
					(pix_x>=ALIEN_C3_X_L) and (pix_x<=ALIEN_C3_X_R) and
					(ALIEN_L1_Y_T<=pix_y) and (pix_y<=ALIEN_L1_Y_B) and
					(rom_alien_a3_bit/="000") else
      		'0';
					alien_a3_rgb <= rom_alien_a3_bit;

	-- alien b3 on
	rom_alien_b3_bit<=ALIEN_B(to_integer(rom_alien_L2_addr),to_integer(rom_alien_C3_col));
   alien_b3_on<=
      		'1' when 
					(pix_x>=ALIEN_C3_X_L) and (pix_x<=ALIEN_C3_X_R) and
					(ALIEN_L2_Y_T<=pix_y) and (pix_y<=ALIEN_L2_Y_B) and
					(rom_alien_b3_bit/="000") else
				'0';
					alien_b3_rgb <= rom_alien_b3_bit;

	-- alien a4 on
	rom_alien_a4_bit<=ALIEN_A(to_integer(rom_alien_L2_addr),to_integer(rom_alien_C4_col));
   alien_a4_on<=
      		'1' when 
					(pix_x>=ALIEN_C4_X_L) and (pix_x<=ALIEN_C4_X_R) and
					(ALIEN_L2_Y_T<=pix_y) and (pix_y<=ALIEN_L2_Y_B) and
					(rom_alien_a4_bit/="000") else
      		'0';
					alien_a4_rgb <= rom_alien_a4_bit;
	
	-- alien b4 on
	rom_alien_b4_bit<=ALIEN_B(to_integer(rom_alien_L1_addr),to_integer(rom_alien_C4_col));
   alien_b4_on<=
      		'1' when 
					(pix_x>=ALIEN_C4_X_L) and (pix_x<=ALIEN_C4_X_R) and
					(ALIEN_L1_Y_T<=pix_y) and (pix_y<=ALIEN_L1_Y_B) and
					(rom_alien_b4_bit/="000") else
				'0';
					alien_b4_rgb <= rom_alien_b4_bit;

	-- alien a5 on
	rom_alien_a5_bit<=ALIEN_A(to_integer(rom_alien_L1_addr),to_integer(rom_alien_C5_col));
   alien_a5_on<=
      		'1' when 
					(pix_x>=ALIEN_C5_X_L) and (pix_x<=ALIEN_C5_X_R) and
					(ALIEN_L1_Y_T<=pix_y) and (pix_y<=ALIEN_L1_Y_B) and
					(rom_alien_a5_bit/="000") else
      		'0';
					alien_a5_rgb <= rom_alien_a5_bit;
	
	-- alien b4 on
	rom_alien_b5_bit<=ALIEN_B(to_integer(rom_alien_L2_addr),to_integer(rom_alien_C5_col));
   alien_b5_on<=
      		'1' when 
					(pix_x>=ALIEN_C5_X_L) and (pix_x<=ALIEN_C5_X_R) and
					(ALIEN_L2_Y_T<=pix_y) and (pix_y<=ALIEN_L2_Y_B) and
					(rom_alien_b5_bit/="000") else
				'0';
					alien_b5_rgb <= rom_alien_b5_bit;
	
 			
	----------------------------------------------
	-- shields screen
   ---------------------------------------------- 
	
	--shield 1
	  shield_1_on <=
      '1' when (SHIELD_1_X_L<=pix_x) and (pix_x<=SHIELD_1_X_R) and
					(SHIELD_Y_T<=pix_y) and (pix_y<=SHIELD_Y_B) else
      '0';	
	--shield 2
	  shield_2_on <=
      '1' when (SHIELD_2_X_L<=pix_x) and (pix_x<=SHIELD_2_X_R) and
					(SHIELD_Y_T<=pix_y) and (pix_y<=SHIELD_Y_B) else
      '0';
	--shield 3
	  shield_3_on <=
      '1' when (SHIELD_3_X_L<=pix_x) and (pix_x<=SHIELD_3_X_R) and
					(SHIELD_Y_T<=pix_y) and (pix_y<=SHIELD_Y_B) else
      '0';	
		shield_rgb<="010"; --green		

	---------------------------------------------------------
	-- RANDOM NUMBER GENERATOR FOR THE APPERANCE OF THE UFO
   ---------------------------------------------------------	

	process(refr_tick,rand_state_reg)
	begin
		rand_state_next<=rand_state_reg;
		rand_reg_next<=rand_reg;
		case rand_state_reg is
			when rand_gen=>
				rand_reg_next<=(rand_reg(0) xor rand_reg(4))&(rand_reg(9 downto 1));
				rand_state_next<=rand_gen_wait;
			when rand_gen_wait=>		
				if refr_tick='1' then
					rand_state_next<=rand_gen;	
				end if;
		end case;			
	end process;

	--   rand2_on<='0';
	rand_on<='1' when (unsigned(rand_reg)>=to_unsigned(CONST_VALUE,10)) else '0';
		
	----------------------------------------------
	-- STATE MACHINE -- BULLET POSITION
   ----------------------------------------------
	
   process(refr_tick,BULLET_V,SPACESHIP_X_L,bullet_y_pos,bullet_state_reg,bullet_start,bullet_end,bullet_shield_1,bullet_shield_2,bullet_shield_3,
			  bullet_alien_b1,bullet_alien_b2,bullet_alien_b3,bullet_alien_b4,bullet_alien_b5,
			  bullet_alien_a1,bullet_alien_a2,bullet_alien_a3,bullet_alien_a4,bullet_alien_a5)
   begin
      bullet_state_next<=bullet_state_reg;
		bullet_y_nextpos<=bullet_y_pos;
      case bullet_state_reg is
         when inicio=>
				  bullet_y_nextpos<= to_unsigned(428-BULLET_Y_SIZE,10); -- 428=SPACESHIP_Y_T
				  bullet_x_r <= SPACESHIP_X_L+(SPACESHIP_X_SIZE/2)+(BULLET_Y_SIZE/2)-1; --bullet aligned with the center of the spaceship
				  bullet_rgb<="000"; -- in the bullet's initial position we assigned it the black color, so you can't see it on the tip of the spaceship
				  if bullet_start= '1' then
					  bullet_state_next <= go;
              end if;
         when go =>
				bullet_rgb<="111"; -- when the bullet is fired we assigned it the white color, because now we want to see it
				if refr_tick='1' then -- the bullet moves to its next position along with screen refresh time
				   bullet_y_nextpos<=bullet_y_pos-BULLET_V;
				else
				   bullet_y_nextpos<=bullet_y_pos;
				end if;	
				if bullet_end='1' then -- the bullet reached the top of the screen without hitting anything
						bullet_state_next<=inicio;
				elsif bullet_shield_1='1' then --the bullet hitted the shield 1
						bullet_state_next<=inicio;
				elsif bullet_shield_2='1' then --the bullet hitted the shield 2
						bullet_state_next<=inicio;
				elsif bullet_shield_3='1' then --the bullet hitted the shield 3
						bullet_state_next<=inicio;
				-- the bullet hitted on of the aliens
				elsif (bullet_alien_b1='1' or bullet_alien_b2='1' or bullet_alien_b3='1' or bullet_alien_b4='1' or bullet_alien_b5='1' or
					bullet_alien_a1='1' or bullet_alien_a2='1' or bullet_alien_a3='1' or bullet_alien_a4='1' or bullet_alien_a5='1')
					then
						bullet_state_next<=inicio;		
				end if;
      end case;
   end process;
	bullet_start<='1' when shoot_tick='1' and (bullet_y_t>BULLET_V) else '0';
	bullet_end<='1' when (bullet_y_t<10) else '0';
	bullet_shield_1<='1' when (bullet_x_l<=SHIELD_1_X_R) and (bullet_x_r>=SHIELD_1_X_L) and (bullet_y_t<=SHIELD_Y_B) else '0';
	bullet_shield_2<='1' when (bullet_x_l<=SHIELD_2_X_R) and (bullet_x_r>=SHIELD_2_X_L) and (bullet_y_t<=SHIELD_Y_B) else '0';
	bullet_shield_3<='1' when (bullet_x_l<=SHIELD_3_X_R) and (bullet_x_r>=SHIELD_3_X_L) and (bullet_y_t<=SHIELD_Y_B) else '0';

	bullet_alien_a1<='1' when (alien_a1_on='1' and alien_live_reg(0)='1' and bullet_on='1') else '0';
	bullet_alien_a2<='1' when (alien_a2_on='1' and alien_live_reg(6)='1' and bullet_on='1') else '0';
	bullet_alien_a3<='1' when (alien_a3_on='1' and alien_live_reg(2)='1' and bullet_on='1') else '0';
	bullet_alien_a4<='1' when (alien_a4_on='1' and alien_live_reg(8)='1' and bullet_on='1') else '0';
	bullet_alien_a5<='1' when (alien_a5_on='1' and alien_live_reg(4)='1' and bullet_on='1') else '0';

	bullet_alien_b1<='1' when (alien_b1_on='1' and alien_live_reg(5)='1' and bullet_on='1') else '0';
	bullet_alien_b2<='1' when (alien_b2_on='1' and alien_live_reg(1)='1' and bullet_on='1') else '0';
	bullet_alien_b3<='1' when (alien_b3_on='1' and alien_live_reg(7)='1' and bullet_on='1') else '0';
	bullet_alien_b4<='1' when (alien_b4_on='1' and alien_live_reg(3)='1' and bullet_on='1') else '0';
	bullet_alien_b5<='1' when (alien_b5_on='1' and alien_live_reg(9)='1' and bullet_on='1') else '0';

	----------------------------------------------
	-- STATE MACHINE -- UFO BULLET POSITION
   ----------------------------------------------
	
   process(ufo_bullet_st_reg,ufo_bullet_start,ufo_bullet_end)
   begin
      ufo_bullet_st_next<=ufo_bullet_st_reg;
		ufo_bullet_y_next<=ufo_bullet_y_reg;
      case ufo_bullet_st_reg is
         when inicio_b=>
				  UFO_BULLET_X_R<=UFO_X_L+(UFO_X_SIZE/2)+(UFO_BULLET_SIZE_Y/2)-1; --bullet aligned in the center of the ufo	
				  ufo_bullet_y_next<= to_unsigned(124+UFO_BULLET_SIZE_Y,10); -- 124=UFO_Y_T
				  ufo_bullet_rgb<="000"; -- in the bullet's initial position we assigned it the black color, so you can't see it on the bottom of the ufo
				  if ufo_bullet_start='1' then
					  ufo_bullet_st_next<=go_b;
              end if;
         when go_b =>
				ufo_bullet_rgb<=rom_ufo_bullet_bit;
				if refr_tick='1' then
				   ufo_bullet_y_next<=ufo_bullet_y_reg+UFO_BULLET_V;
				else
				   ufo_bullet_y_next<=ufo_bullet_y_reg;
				end if;	
				if ufo_bullet_end='1' then -- the bullet reached the bottom of the screen without hitting anything
						ufo_bullet_st_next<=inicio_b;
				elsif ufo_bullet_shield_1='1' then --the bullet hitted the shield 1
						ufo_bullet_st_next<=inicio_b;
				elsif ufo_bullet_shield_2='1' then --the bullet hitted the shield 2
						ufo_bullet_st_next<=inicio_b;
				elsif ufo_bullet_shield_3='1' then --the bullet hitted the shield 3
						ufo_bullet_st_next<=inicio_b;
				elsif spaceship_hitted_next='1' then --the bullet hitted the spaceship
						ufo_bullet_st_next<=inicio_b;
				end if;
      end case;
   end process;
	ufo_bullet_start<='1' when rand_on='1' and (ufo_bullet_y_t>UFO_BULLET_V) else '0';
	ufo_bullet_end<='1' when (ufo_bullet_y_t<10) else '0';
	ufo_bullet_shield_1<='1' when (ufo_bullet_x_l<=SHIELD_1_X_R) and (ufo_bullet_x_r>=SHIELD_1_X_L) and (ufo_bullet_y_b>=SHIELD_Y_T) else '0'; 
	ufo_bullet_shield_2<='1' when (ufo_bullet_x_l<=SHIELD_2_X_R) and (ufo_bullet_x_r>=SHIELD_2_X_L) and (ufo_bullet_y_b>=SHIELD_Y_T) else '0';
	ufo_bullet_shield_3<='1' when (ufo_bullet_x_l<=SHIELD_3_X_R) and (ufo_bullet_x_r>=SHIELD_3_X_L) and (ufo_bullet_y_b>=SHIELD_Y_T) else '0';
	spaceship_hitted_next<='1' when (ufo_bullet_x_l<=SPACESHIP_X_R) and (ufo_bullet_x_r>=SPACESHIP_X_L) and (ufo_bullet_y_b>=SPACESHIP_Y_T) else '0';
	spaceship_hitted<='1' when spaceship_hitted_next='1' else '0';	
	
	----------------------------------------------
	-- UFO BULLET VELOCITY AND RESTART ALIENS
	----------------------------------------------
	
	process(dig1,UFO_BULLET_V)
	begin		
		case dig1 is
			when "0000"=>UFO_BULLET_V<=2; -- score between 0 and 10
			when "0001"=>UFO_BULLET_V<=3; -- score between 10 and 20
			when "0010"=>UFO_BULLET_V<=4; -- score between 20 and 30
			when "0011"=>UFO_BULLET_V<=5; -- score between 30 and 40
			when others=>UFO_BULLET_V<=6; -- score above 40			
		end case;	
	end process;
					
	----------------------------------------------
	-- ALIENS HIT SHIELD
   ----------------------------------------------
	game_over<='1' when ((alien_a1_on='1') or (alien_a2_on='1') or (alien_a3_on='1') or
						(alien_a4_on='1') or (alien_a5_on='1') or (alien_b1_on='1') or
						(alien_b2_on='1') or (alien_b3_on='1') or (alien_b4_on='1') or
						(alien_b5_on='1')) and ((shield_1_on='1') or (shield_2_on='1') or
						(shield_3_on='1')) else '0';
						
	----------------------------------------------
	-- NEW SPACESHIP POSITION
   ----------------------------------------------
	
   process(spaceship_x_reg,SPACESHIP_X_L,SPACESHIP_X_R,refr_tick,btn,gra_still)
   begin
      spaceship_x_next <= spaceship_x_reg; -- no move
      if gra_still='1' then  --initial position of spaceship
         spaceship_x_next<=to_unsigned(((MAX_X-SPACESHIP_X_SIZE)/2)+X_OFFSET,10);
      elsif refr_tick='1' then
         if btn(1)='1' and SPACESHIP_X_L >= (SPACESHIP_V+X_OFFSET) then
            spaceship_x_next <= spaceship_x_reg - SPACESHIP_V; -- move left
         elsif btn(0)='1' and SPACESHIP_X_R < (MAX_X+X_OFFSET-SPACESHIP_V) then
            spaceship_x_next <= spaceship_x_reg + SPACESHIP_V; -- move right
         end if;
      end if;
   end process;

	----------------------------------------------
	-- NEW UFO X-POSITION
   ----------------------------------------------
	
	-- 0=> ufo appears from inside the "wall"
	ufo_x_next<=to_unsigned(400,10) when gra_still='1' else 
   ufo_x_reg+ufo_vx_reg when refr_tick='1' else ufo_x_reg;	
	ufo_vx_next<=ufo_vx_reg;
	
	----------------------------------------------
	-- STATE MACHINE -- ALIEN POSITIONS
   ----------------------------------------------
	
   process(refr_tick2,ALIEN_C1_X_L,ALIEN_C5_X_R,alien_y_next,alien_y_reg,alien_x_next,alien_x_reg,alien_vx_next,alien_vx_reg,
	alien_state_next,alien_state_reg)
   begin
		alien_x_next<=alien_x_reg;
		alien_y_next<=alien_y_reg;
      alien_state_next<=alien_state_reg;
		alien_vx_next <= alien_vx_reg;	
		if refr_tick2='1'  then
		alien_x_next<=alien_x_reg+alien_vx_reg;	
		end if;
		if alien_new_game_pos='1' then alien_state_next<=inicio; 
		end if;
		if start_aliens='1' then alien_state_next<=inicio; 
		end if;
		
		case alien_state_reg is
		
			when inicio=>
				alien_y_next<=to_unsigned(150,10);
				alien_x_next<=to_unsigned(((MAX_X/2)+X_OFFSET-130),10);
				alien_vx_next<=ALIEN_V_N;
				alien_state_next<=go_esquerda;
			when go_esquerda=>
				alien_vx_next<=ALIEN_V_N;
				if ( ((alien_live_reg(0)='1') or (alien_live_reg(5)='1')) and (ALIEN_C1_X_L <= 10+X_OFFSET) ) then --reach left with column 1
					alien_state_next<=go_direita;
				elsif ( ((alien_live_reg(1)='1') or (alien_live_reg(6)='1')) and (ALIEN_C2_X_L <= 10+X_OFFSET) ) then --reach left with column 2
					alien_state_next<=go_direita;
				elsif ( ((alien_live_reg(2)='1') or (alien_live_reg(7)='1')) and (ALIEN_C3_X_L <= 10+X_OFFSET) ) then --reach left with column 3
					alien_state_next<=go_direita;
				elsif ( ((alien_live_reg(3)='1') or (alien_live_reg(8)='1')) and (ALIEN_C4_X_L <= 10+X_OFFSET) ) then --reach left with column 4
					alien_state_next<=go_direita;
				elsif ( ((alien_live_reg(4)='1') or (alien_live_reg(9)='1')) and (ALIEN_C5_X_L <= 10+X_OFFSET) ) then --reach left with column 5
					alien_state_next<=go_direita;
				end if;
				
			when go_direita=>
				alien_vx_next<=ALIEN_V_P;
				if ( ((alien_live_reg(4)='1') or (alien_live_reg(9)='1')) and (ALIEN_C5_X_R >= 630+X_OFFSET) ) then --reach right with column 5
					alien_state_next<=stop_walk;
				elsif ( ((alien_live_reg(3)='1') or (alien_live_reg(8)='1')) and (ALIEN_C4_X_R >= 630+X_OFFSET) ) then --reach right with column 4
					alien_state_next<=stop_walk;
				elsif ( ((alien_live_reg(2)='1') or (alien_live_reg(7)='1')) and (ALIEN_C3_X_R >= 630+X_OFFSET) ) then --reach right with column 3
					alien_state_next<=stop_walk;
				elsif ( ((alien_live_reg(1)='1') or (alien_live_reg(6)='1')) and (ALIEN_C2_X_R >= 630+X_OFFSET) ) then --reach right with column 2
					alien_state_next<=stop_walk;
				elsif ( ((alien_live_reg(0)='1') or (alien_live_reg(5)='1')) and (ALIEN_C1_X_R >= 630+X_OFFSET) ) then --reach right with column 1
					alien_state_next<=stop_walk;
				end if;	
					
			when stop_walk=>
				  alien_vx_next<=to_unsigned(0,10);
				  alien_state_next<=stop_walk_wait;	
					
			when stop_walk_wait=>
				  if refr_tick2='1' then
						alien_state_next<=go_descer_linha;
				  end if;
					
			when go_descer_linha=>
					alien_y_next<=alien_y_reg+to_unsigned(15,10);
					alien_state_next<=go_esquerda;
			
		end case;		
   end process;

   ----------------------------------------------
	-- alien set to dead if hitted
	-- alien_hitted
   ----------------------------------------------
	
	process(bullet_on,alien_a1_on,alien_a2_on,alien_a3_on,alien_a4_on,alien_a5_on,
			  alien_b1_on,alien_b2_on,alien_b3_on,alien_b4_on,alien_b5_on,alien_live_next,alien_live_reg)
	begin
			
		if alien_live_reg=("0000000000") then
			--if all aliens are dead it means that we need to level up
			--so we revive all the aliens so they appear on the screen again
			start_aliens<='1';
			alien_live_next<=(OTHERS=>'1');
		else
			alien_live_next<=alien_live_reg;	
			start_aliens<='0';
		end if;	
		
		if bullet_on='1' then
		
			if (alien_a1_on='1' and alien_live_reg(0)='1') then
				 alien_live_next(0)<='0';
				 alien_hitted<='1';
			elsif (alien_a2_on='1' and alien_live_reg(6)='1') then
				alien_live_next(6)<='0';
				alien_hitted<='1';
			elsif (alien_a3_on='1' and alien_live_reg(2)='1') then
				alien_live_next(2)<='0';
				alien_hitted<='1';
			elsif (alien_a4_on='1' and alien_live_reg(8)='1') then
				alien_live_next(8)<='0';
				alien_hitted<='1';				
			elsif (alien_a5_on='1' and alien_live_reg(4)='1') then
				alien_live_next(4)<='0';
				alien_hitted<='1';					
			elsif (alien_b1_on='1' and alien_live_reg(5)='1') then
				alien_live_next(5)<='0';
				alien_hitted<='1';
			elsif (alien_b2_on='1' and alien_live_reg(1)='1') then
				alien_live_next(1)<='0';
				alien_hitted<='1';
			elsif (alien_b3_on='1' and alien_live_reg(7)='1') then
				alien_live_next(7)<='0';
				alien_hitted<='1';
			elsif (alien_b4_on='1' and alien_live_reg(3)='1') then
				alien_live_next(3)<='0';
				alien_hitted<='1';
			elsif (alien_b5_on='1' and alien_live_reg(9)='1') then
				alien_live_next(9)<='0';
				alien_hitted<='1';
			else alien_hitted<='0';
			end if;
		else alien_hitted<='0';
		end if;
	end process;

	----------------------------------------------
	-- rgb multiplexing circuit
   ----------------------------------------------
	
   process(bullet_on,bullet_rgb,ship_on,ship_rgb,ufo_on,ufo_rgb,
			  ufo_bullet_on,ufo_bullet_rgb,
			  shield_1_on,shield_2_on,shield_3_on,shield_rgb,
			  alien_live_next,alien_live_reg,
			  alien_a1_on,alien_a1_rgb,
			  alien_a2_on,alien_a2_rgb,
			  alien_a3_on,alien_a3_rgb,
			  alien_a4_on,alien_a4_rgb,
			  alien_a5_on,alien_a5_rgb,
			  alien_b1_on,alien_b1_rgb,
	        alien_b2_on,alien_b2_rgb,
			  alien_b3_on,alien_b3_rgb,
	        alien_b4_on,alien_b4_rgb,	  
	        alien_b5_on,alien_b5_rgb)
   begin
		if bullet_on='1' then
			rgb<=bullet_rgb;
		elsif ufo_bullet_on='1' then
			rgb<=ufo_bullet_rgb;
		elsif shield_1_on='1' then
         rgb<=shield_rgb;
		elsif shield_2_on='1' then
         rgb<=shield_rgb;
		elsif shield_3_on='1' then
         rgb<=shield_rgb;			
		elsif ship_on='1' then
			rgb<=ship_rgb;
		elsif ufo_on='1' then
			rgb<=ufo_rgb;			
		elsif (alien_a1_on='1' and alien_live_reg(0)='1') then
			rgb<=alien_a1_rgb;
		elsif (alien_a2_on='1' and alien_live_reg(6)='1') then
			rgb<=alien_a2_rgb;
		elsif (alien_a3_on='1' and alien_live_reg(2)='1') then
			rgb<=alien_a3_rgb;
		elsif (alien_a4_on='1' and alien_live_reg(8)='1') then
			rgb<=alien_a4_rgb;	
		elsif (alien_a5_on='1' and alien_live_reg(4)='1') then
			rgb<=alien_a5_rgb;					
		elsif (alien_b1_on='1' and alien_live_reg(5)='1') then
			rgb<=alien_b1_rgb;
		elsif (alien_b2_on='1' and alien_live_reg(1)='1') then
			rgb<=alien_b2_rgb;
		elsif (alien_b3_on='1' and alien_live_reg(7)='1') then
			rgb<=alien_b3_rgb;
		elsif (alien_b4_on='1' and alien_live_reg(3)='1') then
			rgb<=alien_b4_rgb;
		elsif (alien_b5_on='1' and alien_live_reg(9)='1') then
			rgb<=alien_b5_rgb;			
      else
         rgb<="000"; -- black background
      end if;
   end process;
	
   -- new graphic_on signal
   graph_on <= bullet_on or ufo_bullet_on or ship_on or ufo_on or shield_1_on or shield_2_on or shield_3_on or 
					alien_a1_on or alien_a2_on or alien_a3_on or alien_a4_on or alien_a5_on or
					alien_b1_on or alien_b2_on or alien_b3_on or alien_b4_on or alien_b5_on;
end arch;
