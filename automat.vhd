library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity automat2 is
   port(
    clk: in std_logic;
    reset: in std_logic;
	 reset_product: in std_logic;
	 withdraw_money: in std_logic;
	 blik: in std_logic;
	 blik_status: in std_logic;
    coin: in std_logic;
	 coin_value_vector: in std_logic_vector(2 downto 0);
    dispense: buffer std_logic;
	 error_output_code: buffer std_logic_vector(1 downto 0);
    product_selected: in std_logic_vector(2 downto 0);
	 sugar_selected: in std_logic_vector(1 downto 0);
	 coin5_out: out integer;
	 coin2_out: out integer;
	 coin1_out: out integer;
	 product_hex: out std_logic_vector(6 downto 0);
	 change_hex: out std_logic_vector(6 downto 0);
	 money_hex: out std_logic_vector(6 downto 0)
  );
end automat2;

architecture behavior of automat2 is
	component seven_seg is
        port (
            input_hex: in std_logic_vector(3 downto 0);
            output_hex: out std_logic_vector(6 downto 0)
        );
    end component;
  type state_type is (IDLE, SELECT_DRINK, SELECT_SUGAR, INSERT_MONEY, CHECK_INGREDIENTS, BLIK_PAYMENT, PREPARE_DRINK, DISPENSE_MONEY, DROP_COINS);
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
  type error_code is (NONE, LACK_OF_IGREDIENTS, LACK_OF_MONEY, LIMIT_OF_MONEY);
  type error_codes is array (error_code) of std_logic_vector(1 downto 0);
  signal state: state_type;
  signal coin_count: integer range 0 to 15;
  signal coin_value: integer range 0 to 5;
  type coin_magazine_type is array (integer range 1 to 5) of integer;
  signal selected_drink: drink_type;
  signal sugar_amount: sugar_type;
  signal should_withdraw_money: std_logic;
  signal hex_product_int : std_logic_vector(3 downto 0);
  signal hex_money_int : std_logic_vector(3 downto 0);
  signal hex_change_int : std_logic_vector(3 downto 0);
  
  -- trza ogarnac nadpisywanie bo tu nie ma referencji
  procedure check_and_substract_ingredients(
    selected_drink : in drink_type;
    sugar_amount : in sugar_type;
    ingredients_store : inout ingredient_types;
    enough_ingredients : out boolean
) is
    variable needed_ingredients : ingredient_types;
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
    enough_ingredients := true;
    for i in needed_ingredients'range loop
      if ingredients_store(i) < needed_ingredients(i) then
        enough_ingredients := false;
        return;
      end if;
    end loop;
    -- Substract the ingredients from the store
    for i in needed_ingredients'range loop
        ingredients_store(i) := ingredients_store(i) - needed_ingredients(i);
    end loop;
end procedure;
  
begin
  hex1: seven_seg port map (input_hex => hex_product_int, output_hex => product_hex);
  hex2: seven_seg port map (input_hex => hex_change_int, output_hex => change_hex);
  hex3: seven_seg port map (input_hex => hex_money_int, output_hex => money_hex);
  process(clk, reset, reset_product)
  variable loop_iterations: integer := 0;
  variable coin5_change: integer := 0;
  variable coin2_change: integer := 0;
  variable coin1_change: integer := 0;
  variable change_left: integer := 0;
  variable has_enough_ingredients: boolean;

  variable drink_menu: drink_prices := (
   NONE => 15,
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
	FOAMED_MILK => 1, -- dla latte nie da sie zrobic
	SUGAR => 20,
	CACAO => 6,
	GREEN_TEA => 12,
	BLACK_TEA => 12,
	ESPRESSO => 16
  );
  variable error_output_codes: error_codes := (
	NONE => "00",
   LACK_OF_MONEY => "01",
	LACK_OF_IGREDIENTS => "10",
	LIMIT_OF_MONEY => "11"
  );
  variable coins_magazine: coin_magazine_type := (
	5 => 3,
	4 => 0,
	3 => 0,
	2 => 1,
	1 => 4
  );
  begin
  if (reset = '1') then
    state <= IDLE;
	 dispense <= 'U';
    coin_count <= 0;
	 coin_value <= 0;
	 selected_drink <= NONE;
	 sugar_amount <= NONE;
  elsif (reset_product = '1') then
    state <= SELECT_DRINK;
    selected_drink <= NONE;
	 sugar_amount <= NONE;
  elsif (withdraw_money = '1') then
	should_withdraw_money <= '1';
	state <= DISPENSE_MONEY;
  elsif (clk'event and clk = '1') then
    case state is
      when IDLE =>
        if (coin = '1' or blik = '1') then
          state <= INSERT_MONEY;
		  elsif (product_selected /= "UUU") then
			 state <= SELECT_DRINK;
        end if;
		when INSERT_MONEY =>
        if (coin = '1') then
			 case coin_value_vector is
           when "001" => coin_value <= 1;
           when "010" => coin_value <= 2;
			  when "101" => coin_value <= 5;
			  when others => coin_value <= 0;
          end case;
			 
			 if (coin_value > 0) then
				if (coin_count + coin_value > 15) then 
					error_output_code <= error_output_codes(LIMIT_OF_MONEY);
					state <= DISPENSE_MONEY;
				else
					coin_count <= coin_count + coin_value;
					coins_magazine(coin_value) := coins_magazine(coin_value) + 1;
					coin_value <= 0;
					hex_money_int <= std_logic_vector(to_unsigned(coin_count, 4));
					state <= INSERT_MONEY;
				end if;
			 end if;
		  elsif (blik = '1') then
			 coin_count <= drink_menu(selected_drink);
			 state <= SELECT_DRINK;
        elsif (error_output_code = error_output_codes(LACK_OF_MONEY) and coin_count < drink_menu(selected_drink)) then
		    state <= INSERT_MONEY;
		  else
          state <= SELECT_DRINK;
        end if;
      when SELECT_DRINK =>
        if (coin = '1' or (blik = '1' and coin_count = 0)) then
          state <= INSERT_MONEY;
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
			 
			 hex_product_int <= std_logic_vector(to_unsigned(drink_menu(selected_drink), 4));
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
			check_and_substract_ingredients(selected_drink, sugar_amount, ingredients_store, has_enough_ingredients);
			if(has_enough_ingredients) then
				if (blik = '1') then
					state <= BLIK_PAYMENT;
				else
					state <= PREPARE_DRINK;
				end if;
			else
				error_output_code <= error_output_codes(LACK_OF_IGREDIENTS);
				dispense <= '0';
				state <= DISPENSE_MONEY;
			end if;
		when BLIK_PAYMENT =>	
			if (blik_status = '1') then
				dispense <= '1';
				state <= DISPENSE_MONEY;
			else
				error_output_code <= error_output_codes(LACK_OF_MONEY);
				dispense <= '0';
				state <= DISPENSE_MONEY;
			end if;
		when PREPARE_DRINK => 
			dispense <= '1';
			state <= DISPENSE_MONEY;
		when DISPENSE_MONEY =>
			if (error_output_code = error_output_codes(LIMIT_OF_MONEY)) then 
				change_left := coin_value;
				coin_value <= 0;
				state <= DROP_COINS;
			elsif (blik = '1') then
				coin_count <= 0;
				change_left := 0;
			elsif (dispense = '0' or should_withdraw_money = '1') then
			  change_left := coin_count;
			  coin_count <= 0;
			  coin_value <= 0;
			  state <= DROP_COINS;
			else
			  change_left := coin_count - drink_menu(selected_drink);
			  state <= DROP_COINS;
			end if;
		when DROP_COINS =>
				hex_change_int <= std_logic_vector(to_unsigned(change_left, 4));
				loop_iterations := 0;
				while (change_left > 0 and coins_magazine(5) > 0 and change_left - 5 >= 0) loop
					if (loop_iterations = 10) then
						exit;
					end if;
					loop_iterations := loop_iterations + 1;
					coin5_change := coin5_change + 1;
					change_left := change_left - 5;
					coins_magazine(5) := coins_magazine(5) - 1;
				end loop;

				loop_iterations := 0;
				while (change_left > 0 and coins_magazine(2) > 0 and change_left - 2 >= 0) loop
					if (loop_iterations = 10) then
						exit;
					end if;
					loop_iterations := loop_iterations + 1;
					coin2_change := coin2_change + 1;
					change_left := change_left - 2;
					coins_magazine(2) := coins_magazine(2) - 1;
				end loop;

				loop_iterations := 0;
				while (change_left > 0 and coins_magazine(1) > 0 and change_left - 1 >= 0) loop
					if (loop_iterations = 10) then
						exit;
					end if;
					loop_iterations := loop_iterations + 1;
					coin1_change := coin1_change + 1;
					change_left := change_left - 1;
					coins_magazine(1) := coins_magazine(1) - 1;
				end loop;
				
			coin5_out <= coin5_change;
			coin2_out <= coin2_change;
			coin1_out <= coin1_change;
			
			if (should_withdraw_money = '1') then
				should_withdraw_money <= '0';
				state <= INSERT_MONEY;
			elsif (error_output_code = error_output_codes(LIMIT_OF_MONEY)) then
				error_output_code <= error_output_codes(NONE);
				state <= INSERT_MONEY;
			end if;
		end case;
  end if;
  end process;
end behavior;
