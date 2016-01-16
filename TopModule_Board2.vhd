library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TopModuleBoard2 is
port ( clkin2: in std_logic;
		 fft_in:in std_logic_vector(7 downto 0):= (others=>'0');	
		 FFTDVIN:in std_logic:='0';
		 DATAOUT:out std_logic:='0';
		 led:out std_logic:='0'
		 );
end TopModuleBoard2;

architecture Behavioral of TopModuleBoard2 is

COMPONENT RAM
  PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(12 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
END COMPONENT;

component RS232Module
	port (clkrs232					:	in 	std_logic;	-- 50 Mhz clock
			tx_start				:	in		std_logic;  -- transmit (tx) enable pin
			test_mode			:	in 	std_logic;  -- test mode switch
			DATAIN				:	in		std_logic_vector (7 downto 0); -- to be transmitted data vector
			txd					:	out	std_logic); -- serial out pin
end component;

signal clka :STD_LOGIC;
signal wea :STD_LOGIC_VECTOR(0 DOWNTO 0):= (others=>'1');
signal wea1 :STD_LOGIC_VECTOR(0 DOWNTO 0):= (others=>'0');
signal wea2 :STD_LOGIC_VECTOR(0 DOWNTO 0):= (others=>'0');
signal addra :STD_LOGIC_VECTOR(12 DOWNTO 0):= (others=>'0');
signal addra1 :STD_LOGIC_VECTOR(12 DOWNTO 0):= (others=>'0');
signal addra2 :STD_LOGIC_VECTOR(12 DOWNTO 0):= (others=>'0');
signal addra3 :STD_LOGIC_VECTOR(12 DOWNTO 0):= (others=>'0');
signal addra4 :STD_LOGIC_VECTOR(12 DOWNTO 0):= (others=>'0');
signal tempaddra:STD_LOGIC_VECTOR(12 DOWNTO 0):= (others=>'0');
signal dina :STD_LOGIC_VECTOR(7 DOWNTO 0):= (others=>'0');
signal dina1 :STD_LOGIC_VECTOR(7 DOWNTO 0):= (others=>'0');
signal dina2 :STD_LOGIC_VECTOR(7 DOWNTO 0):= (others=>'0');
signal douta :STD_LOGIC_VECTOR(7 DOWNTO 0):= (others=>'0');
signal douta1 :STD_LOGIC_VECTOR(7 DOWNTO 0):= (others=>'0');
signal douta2:STD_LOGIC_VECTOR(7 DOWNTO 0):= (others=>'0');


signal power1: std_logic_vector(7 downto 0):= (others=>'0');
signal power2: std_logic_vector(7 downto 0):= (others=>'0');
signal square: std_logic_vector(7 downto 0):= (others=>'0');
signal sum: std_logic_vector(7 downto 0):= (others=>'0');
signal feature: std_logic_vector(7 downto 0):= (others=>'0');
signal featureindex: std_logic_vector(12 downto 0):= (others=>'0');

signal clk8khz: std_logic:='0';
signal clk125: std_logic:='0';
signal clk100khz: std_logic:='0';
signal clk200khz: std_logic:='0';
signal ramclock: std_logic:='0';
signal read_enable:std_logic:='0';
signal featureenable: std_logic:='0';

signal clkrs232:std_logic:='0';	-- 50 Mhz clock
signal tx_start:std_logic:='0';  -- transmit (tx) enable pin
signal txd:std_logic:='0';
signal DATAIN:std_logic_vector (7 downto 0):=(others=>'0'); -- to be transmitted data vector
signal test_mode:std_logic:='0';  -- test mode switch

type powstates is (pows1,pows2,pows3,pows4,pows5,pows6,pows7,pows8,pows9);
signal currentpowst: powstates:= pows1;

type arraytype is array (0 to 39) of integer ;

signal one: arraytype := (0,0,0,0,3,0,5,0,16,0,30,0,17,0,0,8,0,36,0,39,0,19,0,32,
0,50,0,43,0,22,0,40,0,87,0,60,0,28,0,87);

signal two: arraytype := (0,0,7,0,5,0,21,0,58,0,70,5,37,32,31,17,11,18,0,13,0,14,
0,28,0,18,0,13,0,21,0,24,0,19,0,30,0,30,0,13);

signal three: arraytype := (0,0,0,0,5,0,15,0,20,0,9,0,5,20,20,9,0,9,0,19,0,34,0,18,
0,37,0,46,0,16,0,40,0,61,0,36,0,47,0,69);

signal four: arraytype := (0,0,0,0,1,0,0,0,6,0,20,0,14,2,2,3,0,8,0,22,0,16,0,3,0,
13,0,33,0,28,0,6,0,16,0,38,0,28,0,5);

signal five: arraytype := (0,0,0,0,5,0,19,0,14,0,40,0,38,2,2,14,0,18,0,37,0,48,0,34,
0,24,0,27,0,70,0,61,0,25,0,19,0,91,0,87);


type averagearray is array (0 to 39) of std_logic_vector(7 downto 0);
signal average: averagearray;

begin

RAMUNIT : RAM
  PORT MAP (
    clka => clka,
    wea => wea,
    addra => addra,
    dina => dina,
    douta => douta
  );
 
RS232UNIT : RS232Module
 PORT MAP (
		clkrs232=>clkrs232,
		tx_start=>tx_start,			
		test_mode=>test_mode,			
		DATAIN=>DATAIN,	
		txd=>txd	
); 

clka<=clk100khz;
clkrs232<=clkin2;
tx_start<=featureenable;
DATAOUT<=txd;

with read_enable select addra<=
					addra1 when '0',
					addra2 when others;

with read_enable select wea<=
					wea1 when '0',
					wea2 when others;
					
with read_enable select dina<=
					dina1 when '0',
					dina2 when others;		
					
--Clock Divider
process(clkin2)
variable count8: integer range 0 to 3124;	
variable count1: integer range 1 to 250;	
		begin
			if rising_edge(clkin2) then 
				if(count8 = 3124) then
					clk8khz <= NOT(clk8khz);
					count8:=0;
				else
					count8 := (count8+1);
				end if;
				
				if(count1 = 250) then
					clk100khz <= NOT(clk100khz);
					count1:=1;
				else
					count1 := (count1+1);
				end if;				
			end if;
end process;

--process(clk50khz)
--variable index: integer range 0 to 255:=0;
--begin
--if rising_edge(clk50khz)then
--	if index<256 then
--		fft_in<=CONV_STD_LOGIC_VECTOR(sample(index),8);
--		index:=index+1;
--	end if;
--	if index=255 then
--		index:=0;
--	end if;
--end if;
--end process;



process(clk100khz)
variable counter: integer range 1 to 3:=1;
variable c: integer range 0 to 5122:=0;
begin
	if rising_edge(clk100khz) then--dogrusu 100khz
	
		if FFTDVIN='1' and read_enable='0' then
			wea1<="1";
			if c<5122 then
				dina1<=fft_in;
				--leds<=fft_in;
				if c>4 then
					addra1<=STD_LOGIC_VECTOR(unsigned(addra1)+1);
				end if;
				c:=c+1;
			end if;
			
			if c=4950 then--4864
				read_enable<='1';
				led<='1';
			end if;
		end if;
		
		if (FFTDVIN='0')then
			wea1<="0";
		end if;
		
	end if;
end process;

--		if FFTDVIN='1' then
--			case currentfftst is 
--				when ffts1=>
--					wea<="1";
--					if c<5122 then
--						dina<=fft_in;
--						--leds<=fft_in;
--						if c>2 then
--							addra1<=addra1+1;
--						end if;
--						c:=c+1;
--					end if;
--					
--					if c=5122 then--4864
--						currentfftst<=ffts2;
--					end if;
--			
--				when ffts2=>
--					read_enable<='1';
--					led<='1';
--					currentfftst<=ffts3;
--				when ffts3=>
--					if (FFTDVIN='0')then
--						wea<="0";
--						currentfftst<=ffts4;
--					end if;
--				when ffts4=>
--			end case;
--		end if;



--RS232readingfrom RAM
--process(clk8khz)
--variable count3: integer range 0 to 5120:=0;
--begin
--if rising_edge(clk8khz)then
--
--	if read_enable='1' then
--		--wea2<="0";
--		if unsigned(addra2)<5120 then
--			addra2	<= STD_LOGIC_VECTOR(unsigned(addra2)+1);	
--			DATAIN<=douta;
--			--leds<=douta;
--			count3:=count3+1;
--		end if;
--	end if;
--end if;
--end process;




process(clk8khz)
variable c: integer range 0 to 128:=0;
variable counter: integer range 0 to 20:=0;
variable dataincount: integer range 0 to 39:=0;
variable number: integer range 1 to 6:=1;
begin
if rising_edge(clk8khz)then
	if read_enable='1' then
	
		case currentpowst is 
			
			when pows1=>
				if c<26 then
					power1<=STD_LOGIC_VECTOR(unsigned(power1)+unsigned(douta));
					addra2<= STD_LOGIC_VECTOR(unsigned(addra2)+1);
					c:=c+1;
				end if;
				if c=26 then
					tempaddra<=addra2;
					addra2<=STD_LOGIC_VECTOR(unsigned(featureindex));
					wea2<="1";
					c:=0;
					currentpowst<=pows2;
				end if;
					
			when pows2=>
				featureindex<=STD_LOGIC_VECTOR(unsigned(featureindex)+1);
				dina2<=power1;
				currentpowst<=pows3;
					
			when pows3=>	
				addra2<=tempaddra;
				power1<="00000000";
				wea2<="0";
				currentpowst<=pows4;
			
			when pows4=>
				currentpowst<=pows5;
				
			when pows5=>
				if c<102 then
					power2<=STD_LOGIC_VECTOR(unsigned(power2)+unsigned(douta));
					addra2<= STD_LOGIC_VECTOR(unsigned(addra2)+1);
					c:=c+1;					
				end if;
				if c=102 then
					tempaddra<=addra2;
					addra2<=STD_LOGIC_VECTOR(unsigned(featureindex));
					wea2<="1";
					currentpowst<=pows6;
					c:=0;
				end if;
				
			when pows6=>
				featureindex<=STD_LOGIC_VECTOR(unsigned(featureindex)+1);
				dina2<=power2;		
				currentpowst<=pows7;	
				
			when pows7=>
				addra2<=tempaddra;	
				power2<="00000000";
				wea2<="0";
				currentpowst<=pows8;
			when pows8=>
				counter:=counter+1;
				if counter>19 then
					addra2<= "0000000000000";
					featureenable<='1';
					currentpowst<=pows9;
				else
					addra2<= STD_LOGIC_VECTOR(unsigned(addra2)+132);
					currentpowst<=pows1;
				end if;
				
			when pows9=>
				if featureenable='1' then
					DATAIN<=douta;
					addra2<= STD_LOGIC_VECTOR(unsigned(addra2)+1);
					dataincount:=dataincount+1;
					
				end if;
				if dataincount>38 then
					DATAIN<="00000000";
				end if;
			end case;
	end if;
end if;
end process;

----Reading Feature vectors
--process(clk8khz)
--variable count3: integer range 0 to 39:=0;
--begin
--if rising_edge(clk8khz)then
--
--	if read_enable="11" then
--		--wea2<="0";
--		if unsigned(addra3)<39 then
--			addra3	<= STD_LOGIC_VECTOR(unsigned(addra3)+1);	
--			DATAIN<=douta2;
--			--leds<=douta2;
--			count3:=count3+1;
--		end if;
--	end if;
--end if;
--end process;








end Behavioral;
