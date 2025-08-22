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

library IEEE;
use IEEE.STD_LOGIC_1164.ALL, IEEE.STD_LOGIC_ARITH.ALL, ieee.std_logic_unsigned.all;

entity LIFO is
  Generic (LIFO_SIZE: natural range 1 to 1024; DSIZE: natural range 1 to 64);
  Port (CLK, POP_CMD, PUSH_CMD: in STD_LOGIC;
        DIN: in std_logic_vector(DSIZE-1 downto 0);
        DOUT: out std_logic_vector(DSIZE-1 downto 0);
        EMPTY,FULL: out std_logic);
end LIFO;

architecture Behavioral of LIFO is
type ram_type is array (LIFO_SIZE-1 downto 0) of std_logic_vector(DSIZE-1 downto 0);
signal RAM: ram_type;
signal cnt: natural range 0 to LIFO_SIZE := 0;
signal top_idx: natural range 0 to LIFO_SIZE := 0;
begin
  DOUT<=(others=>'0') when cnt=0 else RAM(top_idx);
  EMPTY<='1' when cnt=0 else '0'; FULL<='1' when cnt=LIFO_SIZE else '0';
  process (CLK)
  begin
     if rising_edge(CLK) then
       if POP_CMD='1' and cnt/=0 then --pop
         if top_idx/=0 then top_idx<=top_idx-1; end if;
         cnt<=cnt-1;
       end if;
       if PUSH_CMD='1' and cnt/=LIFO_SIZE then --push
         if cnt=0
         then RAM(0)<=DIN; top_idx<=0;
         else RAM(top_idx+1)<=DIN; top_idx<=top_idx+1;
         end if;
         cnt<=cnt+1;
       end if;
     end if;
  end process;
end Behavioral;
