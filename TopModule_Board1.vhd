
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TopModule is
port ( clkin: in std_logic;
       sclk: out std_logic;
       cs:out std_logic;
       sdata: in std_logic;
       vin: out std_logic;
		 starttalk:in std_logic;
		 fft_out:out std_logic_vector(7 downto 0):= (others=>'0');	
		 DATAOUT:out std_logic:='0';
		 FFTDV:out std_logic:='0';
		 clk200khzOUT:out std_logic:='0';
		 led:out std_logic:='0'
		 );
end TopModule;

architecture Behavioral of TopModule is

COMPONENT ram
  PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(12 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
END COMPONENT;

COMPONENT FFTCore
  PORT (
    clk : IN STD_LOGIC;
    start : IN STD_LOGIC;
    unload : IN STD_LOGIC;
    xn_re : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    xn_im : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    fwd_inv : IN STD_LOGIC;
    fwd_inv_we : IN STD_LOGIC;
    rfd : OUT STD_LOGIC;
    xn_index : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    busy : OUT STD_LOGIC;
    edone : OUT STD_LOGIC;
    done : OUT STD_LOGIC;
    dv : OUT STD_LOGIC;
    xk_index : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    xk_re : OUT STD_LOGIC_VECTOR(16 DOWNTO 0);
    xk_im : OUT STD_LOGIC_VECTOR(16 DOWNTO 0)
  );
END COMPONENT;

component RS232
	port (clkrs232					:	in 	std_logic;	-- 50 Mhz clock
			tx_start				:	in		std_logic;  -- transmit (tx) enable pin
			test_mode			:	in 	std_logic;  -- test mode switch
			DATAIN				:	in		std_logic_vector (7 downto 0); -- to be transmitted data vector
			--clk8Khz				:	out	std_logic;	-- 8KHz clk_out
			txd					:	out	std_logic); -- serial out pin
end component;			

signal data:std_logic_vector(11 downto 0):="000000000000";
signal clk125:std_logic:='0';
signal css:std_logic:='1';
signal clk8khz:std_logic:='0';
signal clk100khz:std_logic:='0';
signal clk200khz:std_logic:='0';
signal clk50khz:std_logic:='0';

signal M:std_logic_vector(13 downto 0):= (others=>'0');
signal addra : std_logic_vector(12 downto 0):= (others=>'0');
signal addra1 : std_logic_vector(12 downto 0):= (others=>'0');
signal addra2 : std_logic_vector(12 downto 0):= (others=>'0');
signal dina : std_logic_vector(7 downto 0):= (others=>'0');
signal wea : std_logic_vector(0 downto 0):= (others=>'0');
signal wea1 : std_logic_vector(0 downto 0):= (others=>'0');
signal wea2 : std_logic_vector(0 downto 0):= (others=>'0');
signal douta : std_logic_vector(7 downto 0);
signal clka : std_logic:='0';
signal read_enable:std_logic:='0';
signal contbit:std_logic:='1';
signal flag:std_logic:='0';
signal mult1 : std_logic_vector(23 downto 0):= (others=>'0');
signal mult2 : std_logic_vector(23 downto 0):= (others=>'0');

signal    clk : STD_LOGIC:='0';
signal    start : STD_LOGIC:='0';
signal    unload : STD_LOGIC:='0';
signal    xn_re : STD_LOGIC_VECTOR(7 DOWNTO 0):=(others=>'0');
signal    xn_im : STD_LOGIC_VECTOR(7 DOWNTO 0):=(others=>'0');
signal    fwd_inv :STD_LOGIC:='0';
signal    fwd_inv_we :STD_LOGIC:='0';
signal    rfd : STD_LOGIC:='0';
signal    xn_index :STD_LOGIC_VECTOR(7 DOWNTO 0);
signal    busy :STD_LOGIC:='0';
signal    edone :STD_LOGIC:='0';
signal    done : STD_LOGIC:='0';
signal    dv : STD_LOGIC:='0';
signal    xk_index :STD_LOGIC_VECTOR(7 DOWNTO 0);
signal    xk_re :STD_LOGIC_VECTOR(16 DOWNTO 0);
signal    xk_im :STD_LOGIC_VECTOR(16 DOWNTO 0);

signal clkrs232:std_logic:='0';	-- 50 Mhz clock
signal tx_start:std_logic:='0';  -- transmit (tx) enable pin
signal test_mode:std_logic:='0';  -- test mode switch
signal DATAIN:std_logic_vector (7 downto 0):=(others=>'0'); -- to be transmitted data vector
--signal clk8Khz:std_logic:='0';	-- 8KHz clk_out
signal txd:std_logic:='0'; -- serial out pin

signal flag1:std_logic:='0';

type arraytype is array (0 to 255) of integer ;

--dlmwrite('hamming.out',h); matlab command
signal hamming: arraytype := (5,5,5,5,5,5,5,5,5,5,6,6,6,6,6,7,7,7,7,8,
8,8,9,9,10,10,10,11,11,12,12,13,13,14,14,15,15,16,17,17,18,18,19,20,20,
21,22,22,23,24,24,25,26,26,27,28,28,29,30,31,31,32,33,34,34,35,36,36,37,
38,39,39,40,41,41,42,43,44,44,45,46,46,47,48,48,49,49,50,51,51,52,52,53,
53,54,55,55,56,56,57,57,57,58,58,59,59,59,60,60,60,61,61,61,62,62,62,62,
63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,62,62,
62,62,61,61,61,60,60,60,59,59,59,58,58,57,57,57,56,56,55,55,54,53,53,52,
52,51,51,50,49,49,48,48,47,46,46,45,44,44,43,42,41,41,40,39,39,38,37,36,
36,35,34,34,33,32,31,31,30,29,28,28,27,26,26,25,24,24,23,22,22,21,20,20,
19,18,18,17,17,16,15,15,14,14,13,13,12,12,11,11,10,10,10,9,9,8,8,8,7,7,7,
7,6,6,6,6,6,5,5,5,5,5,5,5,5,5,5);

type states is (state1,state2,state3);
signal currentst: states:= state1;

type fftstates is (ffts1,ffts2,ffts3,ffts4,ffts5);
signal currentfftst: fftstates:= ffts1;

type fftoutstates is (fftouts1,fftouts2);
signal currentfftoutst:fftoutstates:=fftouts1;

begin

RAMUNIT : RAM
  PORT MAP (
    clka => clka,
    wea => wea,
    addra => addra,
    dina => dina,
    douta => douta
 );

FFTUNIT : FFTCore
  PORT MAP (
    clk => clk,
    start => start,
    unload => unload,
    xn_re => xn_re,
    xn_im => xn_im,
    fwd_inv => fwd_inv,
    fwd_inv_we => fwd_inv_we,
    rfd => rfd,
    xn_index => xn_index,
    busy => busy,
    edone => edone,
    done => done,
    dv => dv,
    xk_index => xk_index,
    xk_re => xk_re,
    xk_im => xk_im
  );
  
 RS232UNIT : RS232
  PORT MAP (
			clkrs232=>clkrs232,
			tx_start=>tx_start,			
			test_mode=>test_mode,			
			DATAIN=>DATAIN,	
			txd=>txd	
 ); 
  
cs<=css;
vin <= '1';
clka<=clk125;
clk<=clk100khz;

clkrs232<=clkin;
tx_start<=read_enable;
DATAOUT<=txd;
FFTDV<=flag1;
--clk200khzOUT<=clk200khz;

with read_enable select addra<=
					addra1 when '0',
					addra2 when others;

with read_enable select wea<=
					wea1 when '0',
					wea2 when others;

process(clkin)
variable count: integer range 0 to 1;
variable count2: integer range 0 to 3124;	
variable count3: integer range 1 to 250;	
variable count4: integer range 1 to 125;	
		begin
			if rising_edge(clkin) then 
				if(count = 1) then
					clk125 <= NOT(clk125);--for ADC
					sclk <= clk125;
					count:=0;
				else
					count := (count+1);
				end if;
				
				if(count2 = 3124) then---For readin from RAM
					clk8khz <= NOT(clk8khz);
					count2:=0;
				else
					count2 := (count2+1);
				end if;
				
				if(count3 = 250) then--for FFT
					clk100khz <= NOT(clk100khz);
					count3:=1;
				else
					count3 := (count3+1);
				end if;
				
				if(count4 = 125) then--for Tranmission
					clk200khz <= NOT(clk200khz);
					count4:=1;
				else
					count4 := (count4+1);
				end if;
							
			end if;
end process;
					
process(clk125)--ADC Process
	variable count2: integer range 0 to 1256:=0;
	variable c: integer range 0 to 5121:=0;
	variable index:integer range 0 to 255:=0;
	begin 
	if rising_edge(clk125) then
		if starttalk='1' then
			count2:= count2+1;
			if count2 = 1 then
				css <= '0';
			elsif count2 > 5 and count2 < 18  then
				data (17-count2) <= sdata;
			elsif count2 = 18 then
				css <= '1';
				
				if (c<5120 )then--determine the threshold (130)
					wea1<="1";
					--Multiplication with hamming window
					if index<256 then
						M<=STD_LOGIC_VECTOR(signed(unsigned(data(11 downto 4))-"10000000")*hamming(index));
						
						if signed(M(13 downto 6))>30 then --Threshold Value
							flag<='1';
						end if;
						
						index:=index+1;
					else
						index:=0;
					end if;
					--Writing to ram
					if flag='1' then
						dina <= M(13 downto 6);
						addra1	<= STD_LOGIC_VECTOR(unsigned(addra1)+1);		
						c:=c+1;
					end if;
					--End of writing process
					if(c=5119) then
						read_enable<='1';
					end if;
				end if;
			elsif count2 = 1250 then
				count2 := 0;
			end if;
		end if;
	end if;
end process;

--process(clk8khz)
--variable count3: integer range 0 to 5120:=0;
--begin
--if rising_edge(clk8khz)then
--	if read_enable='1' then
--		wea2<="0";
--		if count3<5120 then
--			addra2	<= addra2+1;	
--			DATAIN<=douta;
--			count3:=count3+1;
--		end if;
--	end if;
--end if;
--end process;

----Reading from Ram
----FFT
process(clk100khz)
variable count3: integer range 0 to 1251:=0; 
variable cc: integer range 0 to 260:=0;
variable c2: integer range 0 to 265:=1;
variable addracount: integer range 1 to 5120:=1;
begin

if rising_edge (clk100khz) then
	if(read_enable='1' and addracount<5120)then
		case currentfftst is 
		when ffts1=>
			fwd_inv_we<='1';
			fwd_inv<='1';
			start<='1';				
			currentfftst<=ffts2;
			
		when ffts2=>
			fwd_inv_we<='0';
			fwd_inv<='0';
			start<='0';		
			wea2<="0";
			if count3<256 and busy = '0' then
				addra2	<= STD_LOGIC_VECTOR(unsigned(addra2)+1);
				addracount:=addracount+1;
				xn_re<=douta;
				count3:=count3+1;
			elsif(count3=256 and busy = '0') then
				count3:=0;
				currentfftst<=ffts3;
			end if;		

		when ffts3=>
			if(done='1') then	
				unload<='1';
				currentfftst<=ffts4;
			end if;
			
		when ffts4=>
			unload<='0';
			if(dv='1') then
				flag1<='1';
				led<='1';
				currentfftst<=ffts5;
				c2:=1;
			end if;
		when ffts5=>
			if c2=264 then---258
				flag1<='0';
				led<='0';
				currentfftst<=ffts1;
			else
				c2:=c2+1;
			end if;
		end case;
	end if;
end if;
end process;

--FFT result out process
process(clk200khz)
begin
if rising_edge(clk200khz) then
	if (flag1='1' and read_enable='1')then
		if contbit='1' then
			mult1<=STD_LOGIC_VECTOR(signed(xk_re(16 downto 5))*signed(xk_re(16 downto 5)));
			contbit<='0';
			fft_out<=STD_LOGIC_VECTOR(signed(mult1(17 downto 10))+signed(mult2(17 downto 10)));--17-10
		else
			mult2<=STD_LOGIC_VECTOR(signed(xk_im(16 downto 5))*signed(xk_im(16 downto 5)));
			contbit<='1';
		end if;
	end if;
end if;
end process;

end Behavioral;
