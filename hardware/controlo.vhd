library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity controlo is
  port ( 
    add1, add2 : out  std_logic_vector (10 downto 0);
    start, clk, rst : in  std_logic;
    finished_reading : in std_logic;
    executing : out  std_logic;
    freq_ram_enable : out std_logic;
    freq_ram_wenable : out std_logic;
    queue_ram_enable : out std_logic;
    queue_ram_wenable : out std_logic;	 
    adding_nodes : out std_logic;
    qAddFinish : in std_logic;
    qTree : out std_logic;
    final_queue : in std_logic
  );
end controlo;

architecture Behavioral of controlo is
  type fsm_states is (s_initial, s_transit1, s_end, s_exec, s_last_exec, s_readChar, s_saveFreq,
                      s_queue_init, s_queueFinish, s_treeSeek, s_treeJoinAdd);
  signal currstate, nextstate: fsm_states;
  signal count_en, end_of_counting, s_qAddFinish : std_logic;
  signal count : std_logic_vector (10 downto 0);
  constant countEND : std_logic_vector (10 downto 0) := (others => '1');
begin
  end_of_counting <= '1' when finished_reading = '1' else '0';
  s_qAddFinish <= '1' when qAddFinish = '1' else '0';

  state_reg: process (clk, rst)
  begin
    if rst = '1' then
      currstate <= s_initial ;
    elsif clk'event and clk = '1' then
      currstate <= nextstate ;
    end if ;
  end process;

	OUTPUT_DECODE: process (currstate)
  begin
    --insert statements to decode internal output signals
    --below is simple example
    executing <= '0';
    count_en <= '0';
    freq_ram_wenable <= '0';
    freq_ram_enable <= '0';
    adding_nodes <= '0';	 
    queue_ram_enable <= '0';
    queue_ram_wenable <= '0';
    qTree <= '0';
		
    if currstate = s_initial then
      -- empty
 	 elsif currstate = s_exec then
			-- empty
	 elsif currstate = s_readChar then
	   count_en <= '1';
      freq_ram_enable <= '1';
		  
	 elsif currstate = s_saveFreq then
      freq_ram_wenable <= '1';
      freq_ram_enable <= '1';

	 elsif currstate = s_transit1 then
		freq_ram_enable <= '1';
			
	 elsif currstate = s_queue_init then
		freq_ram_enable <= '1';
		adding_nodes <= '1';
      queue_ram_enable <= '1';
		queue_ram_wenable <= '1';
		  
	 elsif currstate = s_queueFinish then
	   freq_ram_enable <= '1';
      queue_ram_enable <= '1';
		queue_ram_wenable <= '1';
		  
    elsif currstate = s_treeSeek then
      queue_ram_enable <= '1';
      qTree <= '1';
    
    elsif currstate = s_treeJoinAdd then
      queue_ram_enable <= '1';
      queue_ram_wenable <= '1';
      qTree <= '1';        
      
    elsif currstate = s_last_exec then
      count_en <= '1';
      
    else

    end if;
   end process;
 
   nextstate_DECODE: process (currstate, start, end_of_counting, s_qAddFinish, final_queue)
   begin
      --declare default state for nextstate to avoid latches
      nextstate <= currstate;

      case (currstate) is
      when s_initial =>
        if start='1' then
              nextstate <= s_exec ;
				end if;
				
      -- Estados de leitura de ficheiro
      when s_exec =>
        nextstate <= s_readChar;

      when s_readChar =>
        if end_of_counting = '1' then
          nextstate <= s_transit1;
			  else
          nextstate <= s_savefreq;
			  end if;
			  
      when s_saveFreq =>
        nextstate <= s_readChar;
				
			when s_transit1 =>
				nextstate <= s_queue_init;
      -- Fim Estados de leitura de ficheiro
      
      -- Estados da queue		
      when s_queue_init =>
        if s_qAddFinish = '1' then
          nextstate <= s_queueFinish;
        else
					 nextstate <= s_queue_init;
        end if;
				
      when s_queueFinish =>
        nextstate <= s_treeSeek;

      when s_treeSeek =>
        if final_queue = '0' then 
          nextstate <= s_treeSeek;
        else
          nextstate <= s_treeJoinAdd;
        end if;

      when s_treeJoinAdd =>
        nextstate <= s_treeSeek;
        -- Fim estados da queue		
		
      when s_last_exec =>
        nextstate <= s_end;
				
			when s_end =>
				
      end case;      
   end process;

  process (clk, rst)
  begin
    if rst='1' then
      count <= (others => '0');
    elsif clk='1' and clk'event then
      if count_en='1' then
        if end_of_counting = '0' then
          count <= count + 1;
        end if;
      end if;
    end if;
  end process;

  -- add1 provides first address counter.
  -- add2 is add1 delayed by one clock cycle.
  add1 <= count;
  process (clk)
  begin
    if clk='1' and clk'event then
      add2 <= count;
    end if;
  end process;
end Behavioral;
