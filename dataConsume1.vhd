----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 16.04.2020 13:31:43
-- Design Name: 
-- Module Name: dataConsume1 - Behavioral
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


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.common_pack.ALL
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

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
type state_type is (IDLE, WAIT_DATA,RECIEVE,LOAD_RIGHT,LOAD_LEFT,DATA_READY);
signal currentstate,nextstate : state_type;
signal ctrlIn_delayed, ctrlIn_detected, ctrlOut_reg: std_logic;

begin
receiver_nextState: process(currentState, ctrlIn_detected, start) 
begin
	 -- assign defaults at the beginning to avoid assigning in every branch
 
    case currentState is
        when IDLE => 
            if start <= '1' then
                nextState <= WAIT_DATA;
            else 
                nextState <= IDLE;
            end if; 
        when WAIT_DATA =>
        if ctrlIn_Detected <= '1' then
        nextState <= RECIEVE; 
        end if;
        when RECIEVE => 
            if peakCompare <= '1' then
                nextState <= LOAD_RIGHT;
            elseif regCount <='3' then
                nextState <= LOAD_LEFT;
            else 
                nextState <= WAIT_DATA;
            end if;
        when LOAD_LEFT =>
            if numWordCount <= '1' then 
                nextState <= DATA_READY;
            else 
                nextState <= WAIT_DATA;
            end if;
        when LOAD_RIGHT =>
            if numWordCount <='1' then 
                nextState <= DATA_READY;
            else
                nextState <= WAIT_DATA;
            end if;
        when DATA_READY =>
        nextState <= IDLE;
        end case;
        
end process;
delay_CtrlIn: process(clk)     
  begin
    if rising_edge(clk) then
      ctrlIn_delayed <= ctrlIn;
    end if;
  end process;  
ctrlIn_detected <= ctrlIn xor ctrlIn_delayed;

end Behavioral;
