library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity automat is
  port(
    clk: in std_logic;
    reset: in std_logic;
    coin: in std_logic; -- wrzucanie pieniedzy, jak jest slider w gore to klikiem dodajemy
    dispense: out std_logic; -- sygnal czy zrobiono
    product_selected: in std_logic_vector(2 downto 0); -- sygnal produktu
	 sugar_selected: in std_logic_vector(1 downto 0) -- sygnal ilosci cukru
  );
end automat;

architecture behavior of automat is
  type state_type is (IDLE, SELECT_DRINK, SELECT_SUGAR, INSERT_MONEY, DISPENSE_DRINK);
  type drink_type is (NONE, COFFEE, GREEN_TEA, WATER, MILK, BLACK_TEA, ESPRESSO, LATTE);
  type drink_prices is array (drink_type) of integer;
  type sugar_type is (NONE, LOW, MEDIUM, HIGH);
  signal state: state_type;
  signal coin_count: integer range 0 to 10;
  signal selected_drink: drink_type;
  signal sugar_amount: sugar_type;
begin
  process(clk, reset)
  variable drink_menu: drink_prices := ( -- pod procesem
   NONE => 0,
	COFFEE => 4,
	GREEN_TEA => 3,
	WATER => 1,
	MILK => 2,
	BLACK_TEA => 3,
	ESPRESSO => 3,
	LATTE => 4
  );
  begin
  if (reset = '1') then
    state <= IDLE;
    coin_count <= 0;
	 selected_drink <= NONE;
	 sugar_amount <= NONE;
  elsif (clk'event and clk = '1') then
   
	
    case state is
      when IDLE =>
        if (coin = '1') then
          state <= INSERT_MONEY;
          coin_count <= coin_count + 1;
        end if;
      when SELECT_DRINK =>
        if (coin = '1') then
          state <= INSERT_MONEY;
          coin_count <= coin_count + 1;
        elsif (product_selected /= "000") then
          
          case product_selected is
			  when "000" => selected_drink <= NONE;
           when "001" => selected_drink <= COFFEE;
           when "010" => selected_drink <= GREEN_TEA;
           when "011" => selected_drink <= WATER;
           when "100" => selected_drink <= MILK;
           when "101" => selected_drink <= BLACK_TEA;
           when "110" => selected_drink <= ESPRESSO;
           when "111" => selected_drink <= LATTE;
			  when others => selected_drink <= NONE;
          end case;
		
          state <= SELECT_SUGAR;
        end if;
      when SELECT_SUGAR =>
        if (coin = '1') then
          state <= INSERT_MONEY;
          coin_count <= coin_count + 1;
		  else 
		    
				case sugar_selected is
              when "00" => sugar_amount <= NONE;
              when "01" => sugar_amount <= LOW;
              when "10" => sugar_amount <= MEDIUM;
              when "11" => sugar_amount <= HIGH;
				  when others => sugar_amount <= NONE;
          end case;
        end if;
      when INSERT_MONEY =>
        if (coin = '1') then
          state <= INSERT_MONEY;
          coin_count <= coin_count + 1;
        else
          state <= DISPENSE_DRINK;
        end if;
      when DISPENSE_DRINK =>
         if (coin_count >= drink_menu(selected_drink)) then
				dispense <= '1';
				state <= IDLE;
				coin_count <= 0;
				selected_drink <= NONE;
				sugar_amount <= NONE;
end if;

end case;
	
	
	
  end if;
  end process;
end behavior;
	
  
  
		