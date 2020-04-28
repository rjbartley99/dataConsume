----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07.04.2020 16:48:04
-- Design Name: 
-- Module Name: dataConsume - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: dataConsume.vhd
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.common_pack.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity dataConsume is
    Port (clk:		in std_logic;
		reset:		in std_logic; -- synchronous reset
		start: in std_logic; -- goes high to signal data transfer
		numWords_bcd: in BCD_ARRAY_TYPE(2 downto 0);
		ctrlIn: in std_logic;
		ctrlOut: out std_logic;
		data: in std_logic_vector(7 downto 0);
		dataReady: out std_logic;
		byte: out std_logic_vector(7 downto 0);
		seqDone: out std_logic;
		maxIndex: out BCD_ARRAY_TYPE(2 downto 0);
		dataResults: out CHAR_ARRAY_TYPE(0 to RESULT_BYTE_NUM-1) -- index 3 holds the peak
    );
end dataConsume;

architecture Behavioral of dataConsume is
type state_type is (IDLE,FETCH,WAIT_DATA,DATA_READY,RECIEVE_DATA,SEQ_DONE);
signal currentstate,nextstate : state_type;
signal data_reg: CHAR_ARRAY_TYPE(6 downto 0);
signal byteReg: CHAR_ARRAY_TYPE(3 downto 0);
signal ctrlIn_delayed, ctrlIn_detected, ctrlOut_reg,numWordCount,Peakdetect,enable_peakcount,Reset_Peakcount: std_logic;
signal numWords: BCD_ARRAY_TYPE(2 downto 0);
signal numWords_int,bytecount: integer range 0 to 999;
signal PeakCount: integer range 0 to 4;
begin
retriever_nextState: process(currentState,start,ctrlIn_Detected,numWordCount) 
begin
	 -- assign defaults at the beginning to avoid assigning in every branch
    case currentState is
        when IDLE => 
            if start = '1' then
                nextState <= FETCH;
            else 
                nextState <= IDLE;
            end if; 
        when FETCH =>
        nextState <= WAIT_DATA; 
        when WAIT_DATA => 
            if ctrlIn_Detected <= '1' then
                nextState <= RECIEVE_DATA;
            else 
                nextState <= WAIT_DATA;
            end if;
        when RECIEVE_DATA =>
            nextState <= DATA_READY;
        when DATA_READY =>
        if numWordcount = '1' then 
            nextState <= SEQ_DONE;
            elsif start ='1' then
                nextState <= FETCH; 
            else 
                nextState <= DATA_READY;
            end if;
        when SEQ_DONE =>
        nextState <= IDLE;
        when others =>
        nextState <= IDLE;
        end case;       
end process;

twophase: process(clk)
Begin
    if rising_edge(clk) then 
        if reset='1' then
            ctrlOut_reg<='0';
        else
            if currentState = FETCH then
                ctrlOut_reg <= not ctrlOut_reg;
            else
                ctrlOut_reg<= ctrlOut_reg;
            
            end if;
        end if;
end if;
end process;

ctrlOutput:	process (currentState)
begin 
case currentState IS
 when DATA_READY => -- update output lines, signal data is valid 
	dataReady <= '1';
	byte <= byteReg(3);
 when SEQ_DONE =>
    seqDone <= '1';
    dataResults<=data_Reg;
 when others =>
    dataReady <='0';
    seqDone <= '0';
  end case;

end process;

dataShift: process(clk)
begin
if rising_edge(clk) then  
   if reset = '1' then
   for j in 0 to 3 loop
    byteReg(j) <= (others => '0');
    end loop;
    else 
        if currentState = RECIEVE_DATA then
             byteReg <= data & byteReg(3 downto 1);
        elsif currentState = Idle then 
            for k in 0 to 3 loop
            byteReg(k) <= (others => '0');
            end loop;
        end if;
    end if;
end if;
end process;

dataLatch: process(clk)
begin
if rising_edge(clk) then  
   if reset = '1' then
   for i in 0 to 6 loop
    data_reg(i) <= (others => '0');
    end loop;
    else 
        if peakDetect = '1' then 
        data_reg(3 downto 0) <= byteReg;
        elsif PeakCount = 3 then 
            data_Reg(6 downto 4) <= byteReg(3 downto 1);
    end if;
  end if;
 end if;
 end process;

signaloutput: process(reset,PeakDetect,PeakCount) 
begin
    if reset = '1' then 
        enable_PeakCount <= '0';
        reset_PeakCount <= '0';
    else    
        if Peakdetect ='1' then 
            Enable_peakCount <= '1';
         else 
            if PeakCount = 3 then
                Enable_peakCount<='0';
                Reset_PeakCount <= '1';
            else
                Reset_PeakCount<='0';
            end if;
       end if;
      end if;
 end process;

dataCounter: process(clk) 
begin 
if rising_edge(clk) then
    if reset = '1' or PeakDetect = '1' then 
        PeakCount<=0;
     else  
        if reset_peakCount = '1' then 
            peakCount<=0;
        else
            if Enable_PeakCount = '1' then 
                if currentState = RECIEVE_DATA then 
                    PeakCount<=PeakCount+1;
                end if;
        end if;
        end if;
     end if;
 end if;
end process;        
comparator: process(byteReg,data_reg,reset) 
begin
Peakdetect <= '0';
if TO_INTEGER(unsigned(byteReg(3))) > TO_INTEGER(unsigned(data_reg(3))) then 
    Peakdetect <= '1';
end if;
end process;
       
numword: process(numwords)
Begin
numWords_int<=100*TO_INTEGER(unsigned(numwords(2)))+10*TO_INTEGER(unsigned(numwords(1)))+TO_INTEGER(unsigned(numwords(0)));
end process;

maxcount: process(byteCount,numWords_int)
begin 
 if (bytecount = numWords_int) then 
            numWordCount <= '1';
     else 
        numWordCount <= '0';
end if;

end process;

byte_counting_process : process (clk)
  begin
	if rising_edge(clk) then
		if reset ='1' then
			byteCount <= 0;
		else 	
		    if (byteCount = numWords_int) then
		      byteCount <= 0;
		     elsif currentState = RECIEVE_DATA then
				    byteCount <= byteCount + 1;
				else 
				    byteCount <= byteCount;
				end if;
			end if;
		end if;
 end process;

stateRegister:	process (clk)
  begin
		if rising_edge (clk) then
			if (reset = '1') then
				currentState <= IDLE;
			else
				currentState <= nextState;
			end if;	
		end if;
	end process;
  delay_CtrlIn: process(clk)     
  begin
    if rising_edge(clk) then
      ctrlIn_delayed <= ctrlIn;
    end if;
  end process;  
ctrlIn_detected <= ctrlIn xor ctrlIn_delayed;
ctrlOut <= ctrlOut_reg;
numWords<=numwords_bcd;
end Behavioral;