clear

Game = Engine('settings.json');

Game.InitWindow;

while ~Game.Over
    Game.Update;
end

Game.CloseWindow;