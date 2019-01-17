Game = Engine;

Game.InitWindow;
Game.Speed = 1;

while Game.Clock < 5
    Game.Refresh;
end

Game.CloseWindow;

fprintf('[INFO] FPS: %2.3f\n',Game.FPS)