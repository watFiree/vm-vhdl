library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity automat2 is
  port(
    clk: in std_logic;
    reset: in std_logic;
	 reset_product: in std_logic;
    coin: in std_logic; -- wrzucanie pieniedzy, jak jest slider w gore to klikiem dodajemy
    dispense: buffer std_logic; -- sygnal czy zrobiono
	 error_output_code: buffer std_logic_vector(1 downto 0);
	 money_left: out std_logic_vector(2 downto 0); -- reszta
    product_selected: in std_logic_vector(2 downto 0); -- sygnal produktu
	 sugar_selected: in std_logic_vector(1 downto 0) -- sygnal ilosci cukru
  );
end automat2;

architecture behavior of automat2 is
  type state_type is (IDLE, SELECT_DRINK, SELECT_SUGAR, INSERT_MONEY, CHECK_INGREDIENTS, PREPARE_DRINK, DISPENSE_MONEY);
  type drink_type is (NONE,
  WATER, -- 1 WATER
  ESPRESSO, -- 2 ESSPRESSO, 1 WATER i cukier w zaleznosci od wyboru
  GREEN_TEA, -- 1 GREEN_TEA, 1 WATER i cukier w zaleznosci od wyboru
  CHOCOLATE, -- 1 COCOA, 1 MILK i cukier w zaleznosci od wyboru
  MILK, -- 1 MILK i cukier w zaleznosci od wyboru
  BLACK_TEA, -- 1 BLACK_TEA, 1 WATER i cukier w zaleznosci od wyboru
  LATTE_MACCHIATO, -- 1 ESSPRESSO, 1 MILK i cukier w zaleznosci od wyboru
  LATTE -- 1 ESSPRESSO, 1 MILK, 1 FOAMED_MILK i cukier w zaleznosci od wyboru
  );
  type drink_prices is array (drink_type) of integer;
  type sugar_type is (NONE, LOW, MEDIUM, HIGH);
  type ingredient_type is (WATER, MILK, FOAMED_MILK, SUGAR, CACAO, GREEN_TEA, BLACK_TEA, ESPRESSO);
  type ingredient_types is array (ingredient_type) of integer;
  type error_code is (NONE, LACK_OF_IGREDIENTS, LACK_OF_MONEY);
  type error_codes is array (error_code) of std_logic_vector(1 downto 0);
  signal state: state_type;
  signal coin_count: integer range 0 to 7;
  signal selected_drink: drink_type;
  signal sugar_amount: sugar_type;
  
  function enough_ingredients(selected_drink: drink_type; sugar_amount: sugar_type; ingredients_store: ingredient_types) return boolean is
  variable needed_ingredients: ingredient_types;
  begin
    case selected_drink is
      when WATER => needed_ingredients(WATER) := 1;
      when ESPRESSO => needed_ingredients(WATER) := 1; needed_ingredients(ESPRESSO) := 1;
      when GREEN_TEA => needed_ingredients(WATER) := 1; needed_ingredients(GREEN_TEA) := 1;
      when CHOCOLATE => needed_ingredients(MILK) := 1; needed_ingredients(CACAO) := 1;
      when MILK => needed_ingredients(MILK) := 1;
      when BLACK_TEA => needed_ingredients(WATER) := 1; needed_ingredients(BLACK_TEA) := 1;
      when LATTE_MACCHIATO => needed_ingredients(MILK) := 1; needed_ingredients(ESPRESSO) := 1;
      when LATTE => needed_ingredients(MILK) := 1; needed_ingredients(FOAMED_MILK) := 1; needed_ingredients(ESPRESSO) := 1;
      when NONE => null;
    end case;

    -- Add sugar to needed ingredients based on sugar_amount
    case sugar_amount is
      when LOW => needed_ingredients(SUGAR) := 1;
      when MEDIUM => needed_ingredients(SUGAR) := 2;
      when HIGH => needed_ingredients(SUGAR) := 3;
      when NONE => needed_ingredients(SUGAR) := 0;
    end case;
    
    -- Check if there are enough ingredients in the store
    for i in needed_ingredients'range loop
      if ingredients_store(i) < needed_ingredients(i) then
        return false;
      end if;
    end loop;
    return true;
  end enough_ingredients;
  
begin
  process(clk, reset)
  variable drink_menu: drink_prices := (
   NONE => 1000,
	ESPRESSO => 4,
	GREEN_TEA => 3,
	CHOCOLATE => 3,
	WATER => 1,
	MILK => 2,
	BLACK_TEA => 3,
	LATTE_MACCHIATO => 3,
	LATTE => 4
  );
  variable ingredients_store: ingredient_types := (
   WATER => 1000000, -- nielimitowana ilosc
	MILK => 8,
	FOAMED_MILK => 0, -- dla latte nie da sie zrobic
	SUGAR => 20,
	CACAO => 6,
	GREEN_TEA => 12,
	BLACK_TEA => 12,
	ESPRESSO => 16
  );
  variable error_output_codes: error_codes := (
	NONE => "00",
   LACK_OF_MONEY => "01",
	LACK_OF_IGREDIENTS => "10"
  );
  begin
  if (reset = '1') then
    state <= IDLE;
    coin_count <= 0;
	 selected_drink <= NONE;
	 sugar_amount <= NONE;
  elsif (reset_product = '1') then
    state <= SELECT_DRINK;
    selected_drink <= NONE;
	 sugar_amount <= NONE;
  elsif (clk'event and clk = '1') then
    case state is
      when IDLE =>
        if (coin = '1') then
          state <= INSERT_MONEY;
          coin_count <= coin_count + 1;
        end if;
		when INSERT_MONEY =>
        if (coin = '1') then
          coin_count <= coin_count + 1;
			 state <= INSERT_MONEY;
        elsif (error_output_code = error_output_codes(LACK_OF_MONEY) and coin_count < drink_menu(selected_drink)) then
		    state <= INSERT_MONEY;
		  else
          state <= SELECT_DRINK;
        end if;
      when SELECT_DRINK =>
        if (coin = '1') then
          state <= INSERT_MONEY;
          coin_count <= coin_count + 1;
		  elsif (selected_drink /= NONE) then
		    if (coin_count >= drink_menu(selected_drink)) then
			   error_output_code <= error_output_codes(NONE);
				state <= SELECT_SUGAR;
			 else
			   error_output_code <= error_output_codes(LACK_OF_MONEY);
			   state <= INSERT_MONEY;
			 end if;
        elsif (product_selected /= "UUU") then     
          case product_selected is
			  when "000" => selected_drink <= WATER;
           when "001" => selected_drink <= ESPRESSO;
           when "010" => selected_drink <= GREEN_TEA;
           when "011" => selected_drink <= CHOCOLATE;
           when "100" => selected_drink <= MILK;
           when "101" => selected_drink <= BLACK_TEA;
           when "110" => selected_drink <= LATTE_MACCHIATO;
           when "111" => selected_drink <= LATTE;
			  when others => selected_drink <= NONE;
          end case;
        end if;
      when SELECT_SUGAR =>
		  if (sugar_selected /= "UU") then
				case sugar_selected is
              when "00" => sugar_amount <= NONE;
              when "01" => sugar_amount <= LOW;
              when "10" => sugar_amount <= MEDIUM;
              when "11" => sugar_amount <= HIGH;
				  when others => sugar_amount <= NONE;
				end case;
				state <= CHECK_INGREDIENTS;
        end if;
      when CHECK_INGREDIENTS =>
			if(enough_ingredients(selected_drink, sugar_amount, ingredients_store)) then
				state <= PREPARE_DRINK;
			else
				error_output_code <= error_output_codes(LACK_OF_IGREDIENTS);
				dispense <= '0';
				state <= DISPENSE_MONEY;
			end if;
		when PREPARE_DRINK => 
			-- tu cos trza pokazac lub chuj wie co
			-- wait for 200 ns;
			dispense <= '1';
			state <= DISPENSE_MONEY;
		when DISPENSE_MONEY =>
			if (dispense = '0') then
			  money_left <= std_logic_vector(to_unsigned(coin_count, 3));
			else
			  money_left <= std_logic_vector(to_unsigned(drink_menu(selected_drink) - coin_count, 3));
			end if;
		end case;
  end if;
  end process;
end behavior;
