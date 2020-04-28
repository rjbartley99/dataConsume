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
type state_type is (IDLE,REQUEST_DATA,WAIT_DATA,DATA_READY,SEQ_DONE);
signal currentstate,nextstate : state_type;
signal byteReg: std_logic_vector(7 downto 0);
signal ctrlIn_delayed, ctrlIn_detected, ctrlOut_reg,numWordCount: std_logic;
signal numWords: BCD_ARRAY_TYPE(2 downto 0);
signal numWords_int,bytecount: integer range 0 to 999;
begin

StateTransitions: process(currentState,start,ctrlIn_Detected,numWordCount,currentState,byteReg) 
begin
	 -- assign defaults at the beginning to avoid assigning in every branch
	 
    case currentState is
    
        
        when IDLE => 
        dataReady <='0';
        seqDone <= '0';
            if start = '1' then
            --Start two phase protocol
                nextState <= REQUEST_DATA;
            else 
            --Wait for start = 1
                nextState <= IDLE;
            end if; 
        
           
        when REQUEST_DATA =>
        dataReady <='0';
        seqDone <= '0';
        --Change CtrlOut and proceed to wait for change in CtrlIn
        nextState <= WAIT_DATA; 
        
        
        when WAIT_DATA => 
        dataReady <='0';
        seqDone <= '0';    
            if ctrlIn_Detected <= '1' then
            --Data on byte line is valid
                nextState <= DATA_READY;
            else 
            --Wait for change in CtrlIn
                nextState <= WAIT_DATA;
            end if;
            
        when DATA_READY =>
            byte <= byteReg;
	        dataReady <= '1';
            if numWordcount = '1' then
            --Byte Number = NumWords
                nextState <= SEQ_DONE;
            elsif start ='1' then
            --Requests another byte
                nextState <= REQUEST_DATA; 
            else 
            --Halts data retrieval while Command Processor communicates with PC
                nextState <= DATA_READY;
            end if;
            
        when SEQ_DONE =>
        seqDone <= '1';
        --Restarts System
        nextState <= IDLE;
        
        when others =>
        dataReady <='0';
        seqDone <= '0';
        nextState <= IDLE;
        end case;       
end process;


RequestData: process(clk)
Begin
    if rising_edge(clk) then 
        if reset='1' then
            ctrlOut_reg<='0';
        else
            if currentState = REQUEST_DATA then
            --Change in CtrlOut to start hand-shaking process
                ctrlOut_reg <= not ctrlOut_reg;
            else
            --No change in CtrlOut
                ctrlOut_reg<= ctrlOut_reg;
            
            end if;
        end if;
end if;
end process;





TakeDataFromGen: process(clk)
begin
if rising_edge(clk) then  
   if reset = '1' then
    byteReg <= (others => '0');
    else 
       byteReg <= data;
    end if;
end if;
end process;

       
NumWordsToIniteger: process(numwords)
Begin
--Convert BCD to integer
numWords_int<=100*TO_INTEGER(unsigned(numwords(2)))+10*TO_INTEGER(unsigned(numwords(1)))+TO_INTEGER(unsigned(numwords(0)));
end process;


SequenceComplete: process(byteCount,numWords_int)
begin 
 if (bytecount = numWords_int) then
 --Byte Number = NumWords 
            numWordCount <= '1';
     else
     --Byte Number /= NumWords
        numWordCount <= '0';
end if;
end process;


ByteCounter : process (clk)
  begin
	if rising_edge(clk) then
		if reset ='1' then
		--Rest counter
			byteCount <= 0;
		else 	
		    if (byteCount = numWords_int) then
		    --Reset Counter
		      byteCount <= 0;
		    elsif currentState = WAIT_DATA then
				   if ctrlIn_Detected <= '1' then
				   --New valid byte received
				    byteCount <= byteCount + 1;
				   else 
				   --Wait for new byte
				    byteCount <= byteCount;
				   end if;
			end if;
		end if;
	end if;	
  end process;


StateRegister:	process (clk)
  begin
		if rising_edge (clk) then
			if (reset = '1') then
				currentState <= IDLE;
			else
				currentState <= nextState;
			end if;	
		end if;
	end process;
	
	
Delay_CtrlIn: process(clk)     
  begin
    if rising_edge(clk) then
      ctrlIn_delayed <= ctrlIn;
    end if;
  end process;  
  
--High if CtrlIn changes 
ctrlIn_detected <= ctrlIn xor ctrlIn_delayed;
--Output to dataGen
ctrlOut <= ctrlOut_reg;
--Sends input to be converted to integer
numWords<=numwords_bcd;

end Behavioral;
