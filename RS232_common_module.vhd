library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

-- RS232 SERIAL COMMUNICATION MODULE (115.2KHz)
-- You can use this module directly by instantiating it as a component in your top module
-- This module sends the DATAIN vector (7 downto 0) to the serial port using RS-232 Protocol
-- For this purpose you need to use the clk8Khz signal and rising_edge clock of this signal you need to send new DATAIN to this module

entity RS232 is
	generic( pow				: integer := 16; 		 
				inc				: integer := 151;  -- For baud tick generation (for 115.2K 	pow=16 inc=151)
				nofTest			: integer := 21;   -- Number of 21 samples will be transmitted in the testVector
				nofData			: integer := 128;  -- PLEASE MODIFY this number accoording to the number of samples you will transmit
				MCLK_CYCLE		: integer := 3124; -- used to generate 8Khz clk
				SCLK_CYCLE		: integer := 1; 	 -- used in generating sclk
				WAIT_CYCLE		: integer := 6);	 -- for 115.2K WAIT_CYCLE=6  
	-- Ports
	port (clkrs232					:	in 	std_logic;	-- 50 Mhz clock
			tx_start				:	in		std_logic;  -- transmit (tx) enable pin
			test_mode			:	in 	std_logic;  -- test mode switch
			DATAIN				:	in		std_logic_vector (7 downto 0); -- to be transmitted data vector
			--clk8Khz				:	out	std_logic;	-- 8KHz clk_out
			txd					:	out	std_logic); -- serial out pin
end RS232;

architecture Behavioral of RS232 is

-- CONSTANT RAM DATA FOR TEST MODE ----------------------------------------------
-- if test_mode='1', below constant data is sent to the txd pin
	type arr is array (0 to 20) of integer range -128 to 127;
	constant tempRAM:arr:=(-100,-90,-80,-70,-60,-50,-40,-30,-20,-10,0,10,20,30,40,50,60,70,80,90,100);

-- SIGNALS
signal	flag		:	std_logic:='0';	-- control signal
signal	acc		:	std_logic_vector((pow) downto 0):=(others => '0');

-- CLK
signal 	mclk		:	std_logic:='0';
signal	clk_baud	:	std_logic:='0';

-- TX OPERATION SIGNALS
signal buff_in		: 	std_logic_vector (7 downto 0);
signal tmp_txd		:	std_logic:='1';
type state_type is (START,s1,s2,s3,s4,s5,s6,s7,s8,STOP);  --type of state machine.
signal state: state_type := START;  --current and next state declaration.

begin

-- BAUD TICK GENERATION
-- This process is used to generate 115.2K baud tick that means 
-- serial bits are transmitted with rising edge of generated clk_baud (115.2K)
process (clkrs232)

begin

	if	(rising_edge(clkrs232)) then
		if (flag='1') then
				acc<="01111011110111100"; -- for 115.2K acc <= "01111011110111100";
		else
				acc <= std_logic_vector(to_unsigned((to_integer(unsigned(acc((pow-1) downto 0))) + inc),(pow+1)));
		end if;
	end if;
end process;
clk_baud<=acc(pow);	--baud tick genaration is provided with the carry out signal.


-- 8KHz CLK GENERATION 
-- This process is used to generate an 8KHz clock signal
-- This clock signal is assigned as output port so that it will be used in the top module
-- 8-Bit DAta stored in the BLOCK ram will be given to this module using 8KHz clock. 
process (clkrs232)
variable count: integer range 0 to MCLK_CYCLE:=0;
begin
	if	(rising_edge(clkrs232)) then
		if (count=MCLK_CYCLE) then
			mclk<=not(mclk);		
			count:=0;
		else
			count:=count+1;
		end if;
	end if;
end process;
--clk8Khz<=mclk;


-- DATA BUFFERING PROCESS
-- This process stores the DATAIN or tempRAM (used in test mode) in buff_in
-- Generate flag signal (8Khz baud thic) for the generation 
process (clkrs232)
	variable cntTest: integer range 0 to 2*MCLK_CYCLE:=0;
	variable cntData: integer range 0 to 2*MCLK_CYCLE:=0;
	variable indData: integer range 0 to nofData+1:=0; -- DATA index
	variable indTest: integer range 0 to nofTest+1:=0; -- DATA index
begin
	if rising_edge (clkrs232) then
		if tx_start = '1' then
		
			if test_mode='1' then -- TEST MODE OPERATION
				cntData:=0;
				indData:=0;
				if indTest=nofTest then
					indTest:=0;
				else
					if cntTest=0 then
						buff_in<=std_logic_vector(to_signed(tempRAM(indTest),8)); -- test data buffered
						flag<='1'; -- baud_clk reset
						cntTest:=1; --next state
					else
						flag<='0'; -- enables the clk baud
						cntTest:=cntTest+1;
						if cntTest=2*MCLK_CYCLE then
							cntTest:=0;				-- new data is coming
							indTest:=indTest+1;  -- inrement array index
						end if;
					end if;
				end if;
				
			else	-- DATA MODE OPERATION
				cntTest:=0;
				indTest:=0;
				if indData=nofData then
					indData:=0;
				else
					if cntData=0 then
						buff_in<=DATAIN; --data is buffered
						flag<='1'; -- baud_clk reset
						cntData:=1; --next state
					else
						flag<='0'; -- enables the clk baud
						cntData:=cntData+1;
						if cntData=2*MCLK_CYCLE then
							cntData:=0;				-- new data is coming
							indData:=indData+1;  -- inrement array index
						end if;
					end if;
				end if;
			end if;
		else
			cntTest:=0;
			cntData:=0;
			flag<='0'; 
			indTest:=0;
			indData:=0;			
		end if;
	end if;		
end process;

-- SERIAL TX OPERATION
-- This process is used to transmit buff_in (or DATAIN signal) in a serial manner using RS-232 protocol
-- Start bit + 8 bit data + Stop bit
-- with clk_baud signal (115.2KHz) 
process (clk_baud)
variable counter: integer range 0 to WAIT_CYCLE:=0;
begin
	if (rising_edge(clk_baud)) then
		if (tx_start='1') then		
		  case state is    	  
			-- START BIT
			  when START =>	tmp_txd<='0'; 				state <= s1;    
			-- DATA BITS
			  when 	 s1 =>   tmp_txd<=buff_in(0); 	state <= s2;			
			  when 	 s2 =>   tmp_txd<=buff_in(1); 	state <= s3;			
			  when 	 s3 =>   tmp_txd<=buff_in(2); 	state <= s4;		
			  when 	 s4 =>   tmp_txd<=buff_in(3); 	state <= s5;		
			  when 	 s5 =>   tmp_txd<=buff_in(4); 	state <= s6;		
			  when 	 s6 =>   tmp_txd<=buff_in(5); 	state <= s7;		
			  when 	 s7 =>   tmp_txd<=buff_in(6); 	state <= s8;		
			  when 	 s8 =>   tmp_txd<=buff_in(7); 	state <=STOP;		  
			-- STOP BIT  
			  when STOP  =>	tmp_txd<='1';	
			-- WAIT FOR THE NEXT DATA  
					counter:=counter+1;		
					if (counter=WAIT_CYCLE) then
						state<=START;
						counter:=0;
					else
						state<=STOP;
					end if;			
			 when others =>	tmp_txd<='1';	state<= STOP;
			end case;
		else
			state<=START;
			counter:=0;
			tmp_txd<='1';
		end if; 
	end if;
end process;
txd<=tmp_txd; -- serial out


end Behavioral;

