library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Pong is
    Port (
		clk : in STD_LOGIC;
		up1, down1, up2, down2 : in STD_LOGIC;
		hsync_out : out STD_LOGIC;
		vsync_out : out STD_LOGIC;
		red_out : out STD_LOGIC;
		green_out : out STD_LOGIC;
		blue_out : out STD_LOGIC
	);
end Pong;

architecture Behavioral of Pong is
-----------------------------------------------------------------VGA
signal halfClock : STD_LOGIC;
signal horizontalPosition : integer range 0 to 800 := 0;
signal verticalPosition : integer range 0 to 521 := 0;
signal hsyncEnable : STD_LOGIC;
signal vsyncEnable : STD_LOGIC;
-------------------------------------------------------------------
signal photonX : integer range 0 to 640 := 0;
signal photonY : integer range 0 to 480 := 0;
-------------------------------------------------------------------Direcciones de paleta
constant leftPaddleX : integer := 25;
signal leftPaddleY : integer range 0 to 480 := 240;
constant rightPaddleX : integer := 615;
signal rightPaddleY : integer range 0 to 480 := 240;
signal rightPaddleDirection : integer := 0;
signal leftPaddleDirection : integer := 0;
------------------------------------------------------------------- Dimensione y limites
signal paddleHalfHeight : integer range 0 to 50 := 30;
constant paddleHalfWidth : integer := 6;

constant leftPaddleBackX : integer := leftPaddleX-paddleHalfWidth;
constant leftPaddleFrontX : integer := leftPaddleX+paddleHalfWidth;
constant rightPaddleFrontX : integer := rightPaddleX-paddleHalfWidth;
constant rightPaddleBackX : integer := rightPaddleX+paddleHalfWidth;
constant paddleBottomLimit : integer := 474;
constant paddleTopLimit : integer := 4;
------------------------------------------------------------------------- Color
signal color : STD_LOGIC_VECTOR (2 downto 0) := "000";
------------------------------------------------------------------------- Velocidad
signal ballMovementClockCounter : integer range 0 to 1000000 := 0;
signal ballMovementClock : STD_LOGIC := '0';
signal paddleMovementClockCounter : integer range 0 to 1000000 := 0;
signal paddleMovementClock : STD_LOGIC := '0';

constant ballMaxSpeed : integer := 8;
signal ballX : integer range -100 to 640 := 320;
signal ballY : integer range -100 to 480 := 240;
signal ballSpeedX : integer range -100 to 100 := 1;
signal ballSpeedY : integer range -100 to 100 := 1;
---------------------------------------------------------------------------- reinicio de bola
signal resetBall : STD_LOGIC := '0';
signal resetCounter : integer range 0 to 101 := 0;
-------------------------------------------------------------------------- letras
constant leftLetter : integer := 179;
constant rightLetter : integer := 359;
constant lifeBarWidth : integer := 100;
constant lifeBarHeight : integer := 3;


begin
-------------------------------------------------------- Controles direccion paletas
	process (clk, up1, down1)
	begin 
	if clk'event and clk = '1' then
		if up1 = '0' and down1 = '0' then
			leftPaddleDirection <= 0;
		elsif up1 = '0' and down1 = '1' then
			leftPaddleDirection <= 1;
		elsif down1 = '0' and up1 = '1' then
			leftPaddleDirection <= -1;
			end if;
		 if up2 = '0' and down2 = '0' then
			rightPaddleDirection <= 0;
		elsif up2 = '0' and down2 = '1' then
			rightPaddleDirection <= 1;
		elsif down2 = '0' and up2 = '1' then
			rightPaddleDirection <= -1;
		end if;
		end if;
	
	end process;
	
---------------------------------------------------- mitad de reloj
 process(clk)
	begin
	
		if clk'event and clk = '1' then
			halfClock <= not halfClock;
		end if;
	end process;
	
---------------------------------------------------------- la bola se mueve al pulso del reloj y se detiene al borde del vga
	process(clk)
	begin
		if clk'event and clk = '1' then
			ballMovementClockCounter <= ballMovementClockCounter + 1;
			
			if (ballMovementClockCounter = 800000) then
				ballMovementClock <= not ballMovementClock;
				ballMovementClockCounter <= 0;
			end if;
		end if;
	end process;
	
---------------------------------------------------------- la paleta se mueve al pulso del reloj y se detiene al borde del vga
 process(clk)
	begin
		if clk'event and clk = '1' then
			paddleMovementClockCounter <= paddleMovementClockCounter + 1;
			
			if (paddleMovementClockCounter = 100000) then
				paddleMovementClock <= not paddleMovementClock;
				paddleMovementClockCounter <= 0;
			end if;
		end if;
	end process;
------------------------------------------------------------ posision vga
 process(halfClock)
	begin
		if halfClock'event and halfClock = '1' then
			if horizontalPosition = 800 then
				horizontalPosition <= 0;
				verticalPosition <= verticalPosition + 1;
				
				if verticalPosition = 521 then
					verticalPosition <= 0;
				else
					verticalPosition <= verticalPosition + 1;
				end if;
			else
				horizontalPosition <= horizontalPosition + 1;
			end if;
		end if;
	end process;
------------------------------------------------------------------- ubicacion del mapa
 process(halfClock, horizontalPosition, verticalPosition)
	begin
		if halfClock'event and halfClock = '1' then
			if horizontalPosition > 0 and horizontalPosition < 97 then
				hsyncEnable <= '0';
			else
				hsyncEnable <= '1';
			end if;
			
			if verticalPosition > 0 and verticalPosition < 3 then
				vsyncEnable <= '0';
			else
				vsyncEnable <= '1';
			end if;
		end if;
	end process ;
-------------------------------------------------------------------- Linea punteada
process(horizontalPosition, verticalPosition)
	begin
		photonX <= horizontalPosition - 144;
		photonY <= verticalPosition - 31;
	end process ;
-------------------------------------------------------------------- Color paletas
process(photonX, photonY, halfClock, leftPaddleY, paddleHalfHeight, rightPaddleY, ballY, ballX)
	begin
		if ((photonX >= leftPaddleBackX) and (photonX <= leftPaddleFrontX)
			and (photonY >= leftPaddleY - paddleHalfHeight) and (photonY <= leftPaddleY + paddleHalfHeight)) then
			color <= "100";
		elsif ((photonX >= rightPaddleFrontX) and (photonX <= rightPaddleBackX)
			and (photonY >= rightPaddleY - paddleHalfHeight) and (photonY <= rightPaddleY + paddleHalfHeight))then
			color <= "001";
---------------------------------------------------------------------color linea
		elsif (photonX = 319 and photonY mod 16 <= 10) then
			color <= "000";

---------------------------------------------------------------------color bola
		elsif (photonY >= ballY - 2 and photonY <= ballY + 2) and (photonX >= ballX - 2 and photonX <= ballX + 2) then
			color <= "000";
		elsif (photonY >= ballY - 3 and photonY <= ballY + 3) and (photonX >= ballX - 1 and photonX <= ballX + 1) then
			color <= "000";
		elsif (photonY >= ballY - 1 and photonY <= ballY + 1) and (photonX >= ballX - 3 and photonX <= ballX + 3) then
			color <= "000";
			
--------------------------------------------------------------------letra c

		elsif photonX >= 250 and photonX <= 310 and photonY >= 180 and photonY <= 190 then
			color <= "100";
		elsif photonX >= 250 and photonX <= 260 and photonY >= 190 and photonY <= 300 then
			color <= "100";
		elsif photonX >= 250 and photonX <= 310 and photonY >= 290 and photonY <= 300 then
			color <= "100";

--------------------------------------------------------------------letra l
		
		elsif photonX >= 330 and photonX <= 390 and photonY >= 290 and photonY <= 300 then
			color <= "001";
		elsif photonX >= 330 and photonX <= 340 and photonY >= 180 and photonY <= 300 then
			color <= "001";
---------------------------------------------------------------------color fondo
		else
			color <= "111";
		end if;
	end process ;
	
--------------------------------------------------------------------- control movimiento paleta izq/ limite con marco de pantalla
	process(paddleMovementClock)
	begin
		if paddleMovementClock'event and paddleMovementClock = '1' then
			if leftPaddleY + leftPaddleDirection < paddleBottomLimit - paddleHalfHeight 
				and leftPaddleY + leftPaddleDirection > paddleTopLimit + paddleHalfHeight then
				leftPaddleY <= leftPaddleY + leftPaddleDirection;
			end if;
		end if;
	end process;

--------------------------------------------------------------------- control movimiento paleta der/ limite con marco de pantalla
	process(paddleMovementClock)
	begin
		if paddleMovementClock'event and paddleMovementClock = '1' then
			if rightPaddleY + rightPaddleDirection < paddleBottomLimit - paddleHalfHeight 
				and rightPaddleY + rightPaddleDirection > paddleTopLimit + paddleHalfHeight then
				rightPaddleY <= rightPaddleY + rightPaddleDirection;
			end if;
		end if;
	end process;

--------------------------------------------------------------------- control movimiento pelota/ limite con marco de pantalla
process(ballMovementClock)
	begin
		if ballMovementClock'event and ballMovementClock='1' then
			if resetBall = '1' then
				if resetCounter = 100 then
					resetCounter <= 0;
					ballX <= 319;
					ballY <= 239;
					resetBall <= '0';
				else
					resetCounter <= resetCounter + 1;
				end if;
			else
				
				if ballX+4 > rightPaddleFrontX and ballX < rightPaddleBackX 
					and ballY+4 > rightPaddleY-paddleHalfHeight and ballY-4 < rightPaddleY+paddleHalfHeight then
					ballX <= rightPaddleFrontX - 4;
					ballSpeedY <= (ballY - rightPaddleY) / 8;
					ballSpeedX <= -ballMaxSpeed + ballSpeedY;
				elsif ballX-4 < leftPaddleFrontX and ballX > leftPaddleBackX
					and ballY+4 > leftPaddleY-paddleHalfHeight and ballY-4 < leftPaddleY+paddleHalfHeight then
					ballX <= leftPaddleFrontX + 4;
					ballSpeedY <= ((ballY - leftPaddleY) / 8);
					ballSpeedX <= ballMaxSpeed - ballSpeedY;
				elsif ballX + ballSpeedX < 4 then
					ballX <= -20;
					ballY <= -20;
					resetBall <= '1';
				elsif ballX + ballSpeedX > 635 then
					ballX <= -20;
					ballY <= -20;
					resetBall <= '1';
				else
					ballX <= ballX + ballSpeedX;
				end if;
				
				if ballY > 470 then
					ballY <= 470;
					ballSpeedY <= -ballSpeedY;
				elsif ballY < 10 then
					ballY <= 10;
					ballSpeedY <= -ballSpeedY;
				else
					ballY <= ballY + ballSpeedY;
				end if;
			end if;
		end if;
	end process;
	
-------------------------------------------------------controlador VGA
	process(photonX, photonY, halfClock)
	begin
		if halfClock'event and halfClock = '1' then
			hsync_out <= hsyncEnable;
			vsync_out <= vsyncEnable;
		
			if (photonX < 640 and photonY < 480) then
				red_out <= color(2);
				green_out <= color(1);
				blue_out <= color(0);
			else
				red_out <= '0';
				green_out <= '0';
				blue_out <= '0';
			end if;
		end if;
	end process;

end Behavioral;
