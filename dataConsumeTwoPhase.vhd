----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07.04.2020 16:48:04
-- Design Name: 
-- Module Name: dataConsume - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
Frank is testing

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
type state_type is (IDLE, FETCH,WAIT_DATA,SEND_DATA,DATA_READY);
signal currentstate,nextstate : state_type;
signal byteReg: std_logic_vector(7 downto 0);
signal ctrlIn_delayed, ctrlIn_detected, ctrlOut_reg: std_logic;
signal numWords_bcd1,numWords_bcd2,numWords_bcd3,mag: integer;
signal bytecount: integer ; -- counts number of bits read : 
begin
receiver_nextState: process(currentState, ctrlIn_detected, start) 
begin
	 -- assign defaults at the beginning to avoid assigning in every branch
    ctrlOut <= '0'; 
    case currentState is
        when IDLE => 
            if start = '1' then
                nextState <= FETCH;
            else 
                nextState <= IDLE;
            end if; 
        when FETCH =>
        ctrlOut_reg <= not ctrlOut_reg;
        nextState <= WAIT_DATA; 
        when WAIT_DATA => 
            if ctrlIn_Detected <= '1' then
                nextState <= SEND_DATA;
            else 
                nextState <= WAIT_DATA;
            end if;
        when SEND_DATA =>
        nextState <= DATA_READY;
        when DATA_READY =>
        nextState <= IDLE;
        end case;
        
end process;

dataReg:	process (clk)
  begin
   if rising_edge(clk) then
		if reset ='1' then
			byteReg <= (others => '0');
		else
			if currentState = SEND_DATA then
				byteReg <= data; 
			end if;
		end if;  
	end if;	
  end process;
 
dataLatch:	process (clk)
  begin
    if rising_edge(clk) then
		if reset ='1' then
			byteReg <= (others => '1');
			dataReady <= '0';
		else
			if currentState = DATA_READY then -- update output lines, signal data is valid
				byte <= byteReg; 
				dataReady <= '1';
			end if;	
      end if;
    end if;  
  end process;
  
seqdone : process (clk)
  begin
	if rising_edge(clk) then
		if reset ='1' then
			byteCount <= 0;
		else	 
			if currentState = DATA_READY then
				
		if byteCount 
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
numWords_bcd1<=TO_INTEGER(unsigned(numWords_bcd(2)));
numWords_bcd2<=TO_INTEGER(unsigned(numWords_bcd(1)));
numWords_bcd3<=TO_INTEGER(unsigned(numWords_bcd(0)));
mag<= numWords_bcd3 + (numWords_bcd2 *10) + (numWords_bcd1*100);
end Behavioral;
