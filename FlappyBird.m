clear

Game = Engine;

Game.InitWindow('windowed',[0 0 1200 900]);

while ~Game.Over
    Game.Update;
end

Game.CloseWindow;