--Copyright 2025 Andrey S. Ionisyan (anserion@gmail.com)
--Licensed under the Apache License, Version 2.0 (the "License");
--you may not use this file except in compliance with the License.
--You may obtain a copy of the License at
--    http://www.apache.org/licenses/LICENSE-2.0
--Unless required by applicable law or agreed to in writing, software
--distributed under the License is distributed on an "AS IS" BASIS,
--WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--See the License for the specific language governing permissions and
--limitations under the License.
------------------------------------------------------------------

library IEEE; use IEEE.STD_LOGIC_1164.ALL;

entity LIFO_top is
    Port (SYS_CLK,KEY1,KEY2,KEY3,KEY4,RESET: in STD_LOGIC;
          SMG_DATA : out  STD_LOGIC_VECTOR (7 downto 0);
          SCAN_SIG : out  STD_LOGIC_VECTOR (5 downto 0));
end LIFO_top;

architecture Behavioral of LIFO_top is
component CLK_GEN
  Generic (TICKS_PER_SIGNAL: natural);
  Port (CLK_IN,EN,RESET: in STD_LOGIC; CLK_OUT : out  STD_LOGIC);
end component;
component SMG_x16_driver is
    Port (clk,en: in std_logic; NUM_16x: in STD_LOGIC_VECTOR(23 downto 0); 
          mask_dp, mask_dig: in STD_LOGIC_VECTOR(5 downto 0);
          SEG: out STD_LOGIC_VECTOR(7 downto 0); DIG: out STD_LOGIC_VECTOR(5 downto 0));
end component;
component keys_supervisor
   Generic (debounce: in natural range 0 to 1023);
   Port (clk,en: in std_logic; key1,key2,key3,key4,reset: in std_logic; 
         key_code: out std_logic_vector(3 downto 0); RDY: out std_logic);
end component;
component LIFO is
  Generic (LIFO_SIZE: natural range 1 to 1023; DSIZE: natural range 1 to 64);
  Port (CLK, POP_CMD, PUSH_CMD: in STD_LOGIC;
        DIN: in std_logic_vector(DSIZE-1 downto 0);
        DOUT: out std_logic_vector(DSIZE-1 downto 0);
        EMPTY,FULL: out std_logic);
end component;

signal CLK, CLK_SMG: std_logic;
signal lifo_empty, lifo_full, lifo_pop, lifo_push: std_logic:='0';
signal lifo_in, lifo_out: std_logic_vector(3 downto 0):="0000";
signal put1, put2, put3, get1, get2, get3: std_logic_vector(3 downto 0):="0000";
signal key_code: std_logic_vector(3 downto 0):="0000";
signal key_ready: std_logic;

begin
  CLK_GEN_1MHz_chip: CLK_GEN generic map(50) port map(SYS_CLK,'1','0',CLK);
  CLK_GEN_10kHz_SMG: CLK_GEN generic map(5000) port map(SYS_CLK,'1','0',CLK_SMG);
  LIFO_chip: LIFO generic map(3,4)
                  port map(CLK,lifo_pop,lifo_push,lifo_in,lifo_out,lifo_empty,lifo_full);
                           SMG_x16_driver_chip: SMG_x16_driver port map(CLK_SMG, '1',
                           put1 & put2 & put3 & get1 & get2 & get3, 
                           "110111", "000000",SMG_DATA, SCAN_SIG);
  KEYS_driver: keys_supervisor generic map(500)
                               port map(CLK,'1',KEY1,KEY2,KEY3,KEY4,RESET,key_code,key_ready);
  process(CLK)
  variable fsm: natural range 0 to 31:=0;
  begin
    if rising_edge(CLK) then
      case fsm is
      when 0=>fsm:=1; lifo_in<="0000"; lifo_pop<='0'; lifo_push<='0';
      -----------------------------------------------------------------
      when 1=>if key_ready='0' then fsm:=2; end if;
      when 2=>if key_ready='1' then fsm:=3; put1<=key_code; end if;
      when 3=>if key_ready='0' then fsm:=4; end if;
      when 4=>if key_ready='1' then fsm:=5; put2<=key_code; end if;
      when 5=>if key_ready='0' then fsm:=6; end if;
      when 6=>if key_ready='1' then fsm:=7; put3<=key_code; end if;
      when 7=>if key_ready='0' then fsm:=8; end if;
      when 8=>if key_ready='1' and key_code="0111" then fsm:=9; end if;
      -----------------------------------------------------------------
      when 9=>fsm:=10;  lifo_in<=put1; lifo_push<='1'; lifo_pop<='0';
      when 10=>fsm:=11; lifo_in<=put2; lifo_push<='1'; lifo_pop<='0';
      when 11=>fsm:=12; lifo_in<=put3; lifo_push<='1'; lifo_pop<='0';
      when 12=>fsm:=13; lifo_push<='0'; lifo_pop<='0';
      -----------------------------------------------------------------
      when 13=>fsm:=14; lifo_push<='0'; lifo_pop<='1';
      when 14=>fsm:=15; get1<=lifo_out; lifo_push<='0'; lifo_pop<='1';
      when 15=>fsm:=16; get2<=lifo_out; lifo_push<='0'; lifo_pop<='1';
      when 16=>fsm:=1;  get3<=lifo_out; lifo_push<='0'; lifo_pop<='0';
      -----------------------------------------------------------------
      when others=>null;
      end case;
    end if;
  end process;
end Behavioral;
