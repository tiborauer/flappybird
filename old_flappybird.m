function old_flappybird

%% System Variables:
GameVer = '1.0';          % The first full playable game

%% Constant Definitions:
GAME.SPEED = [];
GAME.MAX_FRAME_SKIP = [];

GAME.RESOLUTION = [];       % Game Resolution, default at [256 144]
GAME.FLOOR_TOP_Y = [];      % The y position of upper crust of the floor.
GAME.N_UPDATES_PER_SEC = [];
GAME.FRAME_DURATION = [];
GAME.GRAVITY = 0.1356; %0.15; %0.2; %1356;  % empirical gravity constant

TUBE.N_TUBE = [];
TUBE.MIN_HEIGHT = [];       % The minimum height of a tube
TUBE.H_SPACE = [];           % Horizontal spacing between two tubs
TUBE.V_SPACE = [];           % Vertical spacing between two tubs
TUBE.WIDTH   = [];            % The 'actual' width of the detection box
TUBE.MAX_VOffset = [];

GAMEPLAY.RIGHT_X_FIRST_TUBE = [];  % Xcoord of the right edge of the 1st tube

ShowFPS = true;
SHOWFPS_FRAMES = 5;
%% Handles
ScoreInfoForeHdl = [];
ScoreInfoBackHdl = [];
MainFigureHdl = [];
MainAxesHdl = [];
MainCanvasHdl = [];
BirdSpriteHdl = [];
TubeSpriteHdl = [];
BeginInfoHdl = [];
FloorSpriteHdl = [];
ScoreInfoHdl = [];
GameOverHdl = [];
FloorAxesHdl = [];
%% Game Parameters
MainAxesInitPos = []; % The initial position of the axes IN the figure
MainAxesSize = [];

InGameParams.CurrentBkg = 1;
InGameParams.CurrentBird = 1;

Flags.IsGameStarted = true;     %
Flags.IsFirstTubeAdded = false; % Has the first tube been added to TubeLayer
Flags.ResetFloorTexture = true; % Result the pointer for the floor texture
Flags.PreGame = true;
Flags.NextTubeReady = true;
CloseReq = false;

FlyKeyNames = {'space', 'return', 'uparrow', 'w'};
FlyKeyStatus = false; %(size(FlyKeyNames));
FlyKeyValid = true(size(FlyKeyNames));      %
%% Canvases:
MainCanvas = [];

% The scroll layer for the tubes
TubeLayer.Alpha = [];
TubeLayer.CData = [];


%% RESOURCES:
Sprites = [];

%% Positions:
Bird.COLLIDE_MASK = [];
Bird.INIT_SCREEN_POS = [45 100];                    % In [x y] order;
Bird.WorldX = [];
Bird.ScreenPos = []; %[45 100];   % Center = The 9th element horizontally (1based)
% And the 6th element vertically
Bird.Angle = 0;
Bird.XGRID = [];
Bird.YGRID = [];
Bird.CurFrame = 1;
Bird.SpeedY = 0;
Bird.LastHeight = 0;

SinYRange = 44;
SinYPos = [];
SinY = [];

Score = 0;

Tubes.FrontP = 1;              % 1-3
Tubes.ScreenX = []; % The middle of each tube
Tubes.VOffset = [];

Best = 0;
%% -- Game Logic --
initVariables();
initWindow();

if ShowFPS
    fps_text_handle = text(10,10, 'FPS:60.0', 'Visible', 'off');
    var_text_handle = text(10,20, '', 'Visible', 'off'); % Display a variable
    total_frame_update = 0;
end

% Main Game
while 1
    initGame();
    CurrentFrameNo = double(0);
    fall_to_bottom = false;
    gameover = false;
    stageStartTime = tic;
    FPS_lastTime = toc(stageStartTime);
    while 1
        loops = 0;
        curTime = toc(stageStartTime);
        while (curTime >= ((CurrentFrameNo) * GAME.FRAME_DURATION) && loops < GAME.MAX_FRAME_SKIP)
            
            if FlyKeyStatus  % If left key is pressed
                if ~gameover
                    Bird.SpeedY = -2.5; % -2.5;
                    FlyKeyStatus = false;
                    Bird.LastHeight = Bird.ScreenPos(2);
                    if Flags.PreGame
                        Flags.PreGame = false;
                        set(BeginInfoHdl, 'Visible','off');
                        set(ScoreInfoBackHdl, 'Visible','on');
                        set(ScoreInfoForeHdl, 'Visible','on');
                        Bird.ScrollX = 0;
                    end
                else
                    if Bird.SpeedY < 0
                        Bird.SpeedY = 0;
                    end
                end
            end
            if Flags.PreGame
                processCPUBird;
            else
                processBird;
                Bird.ScrollX = Bird.ScrollX + 1;
                if ~gameover
                    scrollTubes(GAME.SPEED);
                end
            end
            addScore;
            Bird.CurFrame = 3 - floor(double(mod(CurrentFrameNo, 9))/3);
            
            %% Cycling the Palette
            % Update the cycle variables
            collide = isCollide();
            if collide
                gameover = true;
            end
            CurrentFrameNo = CurrentFrameNo + 1;
            loops = loops + 1;
            frame_updated = true;
            
            % If the bird has fallen to the ground
            if Bird.ScreenPos(2) >= 200-5
                Bird.ScreenPos(2) = 200-5;
                gameover = true;
                if abs(Bird.Angle - pi/2) < 1e-3
                    fall_to_bottom = true;
                    FlyKeyStatus = false;
                end
            end
            
        end
        
        %% Redraw the frame if the world has been processed
        if frame_updated
            %         drawToMainCanvas();
            set(MainCanvasHdl, 'CData', MainCanvas(1:200,:,:));
            %         Bird.Angle = double(mod(CurrentFrameNo,360))*pi/180;
            if fall_to_bottom
                Bird.CurFrame = 2;
            end
            refreshBird();
            refreshTubes();
            if (~gameover)
                refreshFloor(CurrentFrameNo);
            end
            curScoreString = sprintf('%d',(Score));
            set(ScoreInfoForeHdl, 'String', curScoreString);
            set(ScoreInfoBackHdl, 'String', curScoreString);
            drawnow;
            frame_updated = false;
            c = toc(stageStartTime);
            if ShowFPS
                total_frame_update = total_frame_update + 1;
                varname = 'collide';%'Mario.curFrame';
                if mod(total_frame_update,SHOWFPS_FRAMES) == 0 % If time to update fps
                    set(fps_text_handle, 'String',sprintf('FPS: %.2f',SHOWFPS_FRAMES./(c-FPS_lastTime)));
                    FPS_lastTime = toc(stageStartTime);
                end
                set(var_text_handle, 'String', sprintf('%s = %.2f', varname, eval(varname)));
            end
        end
        if fall_to_bottom
            if Score > Best
                Best = Score;
                
                for i_save = 1:4     % Try saving four times if error occurs
                    try
                        save sprites.mat Best -append
                        break;
                    catch
                        continue;
                    end
                end     % If the error still persist even after four saves, then
                if i_save == 4
                    disp('FLAPPY_BIRD: Can''t save high score');
                end
            end
            score_report = {sprintf('Score: %d', Score), sprintf('Best: %d', Best)};
            set(ScoreInfoHdl, 'Visible','on', 'String', score_report);
            set(GameOverHdl, 'Visible','on');
            save sprites.mat Best -append
            if FlyKeyStatus
                FlyKeyStatus = false;
                break;
            end
        end
        
        if CloseReq
            delete(MainFigureHdl);
            return;
        end
    end
end
    function initVariables()
        Sprites = load('sprites.mat');
        GAME.SPEED = 1;
        GAME.SCALE = 4; % Magnification (1-4)
        GAME.MAX_FRAME_SKIP = 5;
        res = get(0,'ScreenSize');
        GAME.RESOLUTION = res([4 3])/GAME.SCALE;
        GAME.FLOOR_HEIGHT = 56;
        GAME.FLOOR_TOP_Y = GAME.RESOLUTION(1) - GAME.FLOOR_HEIGHT + 1;
        GAME.N_UPDATE_PERSEC = 60;
        GAME.FRAME_DURATION = 1/GAME.N_UPDATE_PERSEC;
        
        TUBE.H_SPACE = 160;           % Horizontal spacing between two tubs
        TUBE.V_SPACE = 48;           % Vertical spacing between two tubs
        TUBE.WIDTH   = 24;            % The 'actual' width of the detection box
        TUBE.MIN_HEIGHT = 36;
        TUBE.MAX_VOffset = 105;

        TUBE.N_TUBE = ceil(GAME.RESOLUTION(2)/TUBE.H_SPACE);
        
        %TUBE.RANGE_HEIGHT_DOWN;      % Sorry you just don't have a choice
        GAMEPLAY.RIGHT_X_FIRST_TUBE = GAME.RESOLUTION(2)+300;  % Xcoord of the right edge of the 1st tube
        
        %% Handles
        MainFigureHdl = [];
        MainAxesHdl = [];
        
        %% Game Parameters
        MainAxesInitPos = [0 0]; %[0.1 0.1]; % The initial position of the axes IN the figure
        MainAxesSize = [GAME.RESOLUTION(2) GAME.RESOLUTION(1)-GAME.FLOOR_HEIGHT];
        
        %% Canvases:
        MainCanvas = uint8(zeros([GAME.RESOLUTION 3]));
        
        bird_size = Sprites.Bird.Size;
        [Bird.XGRID, Bird.YGRID] = meshgrid(-ceil(bird_size(2)/2):floor(bird_size(2)/2), ...
            ceil(bird_size(1)/2):-1:-floor(bird_size(1)/2));
        Bird.COLLIDE_MASK = false(12,12);
        [tempx, tempy] = meshgrid(linspace(-1,1,12));
        Bird.COLLIDE_MASK = (tempx.^2 + tempy.^2) <= 1;
        
        
        Bird.OSCIL_RANGE = [128 4]; % [YPos, Amplitude]
        
        Bird.ScreenPos = GAME.RESOLUTION(2)/2;
        SinY = Bird.OSCIL_RANGE(1) + sin(linspace(0, 2*pi, SinYRange))* Bird.OSCIL_RANGE(2);
        SinYPos = 1;
        Best = Sprites.Best;    % Best Score
    end

%% --- Graphics Section ---
    function initWindow()
        % initWindow - initialize the main window, axes and image objects
        MainFigureHdl = figure('Name', ['Flappy Bird ' GameVer], ...
            'NumberTitle' ,'off', ...
            'Units', 'pixels', ...
            'WindowState', 'fullscreen',...
            'MenuBar', 'none', ...
            'ToolBar', 'none', ...
            'Renderer', 'OpenGL',...
            'Color',[0 0 0], ...
            'KeyPressFcn', @stl_KeyPressFcn, ...
            'WindowKeyPressFcn', @stl_KeyDown,...
            'WindowKeyReleaseFcn', @stl_KeyUp,...
            'CloseRequestFcn', @stl_CloseReqFcn);
        FloorAxesHdl = axes('Parent', MainFigureHdl, ...
            'Units', 'normalized',...
            'Position', [MainAxesInitPos, (1-MainAxesInitPos.*2) .* [1 GAME.FLOOR_HEIGHT/GAME.RESOLUTION(1)]], ...
            'color', [1 1 1], ...
            'XLim', [0 MainAxesSize(1)]-0.5, ...
            'YLim', [0 GAME.FLOOR_HEIGHT]-0.5, ...
            'YDir', 'reverse', ...
            'NextPlot', 'add', ...
            'Visible', 'on',...
            'XTick',[], 'YTick', []);
        MainAxesHdl = axes('Parent', MainFigureHdl, ...
            'Units', 'normalized',...
            'Position', [MainAxesInitPos + [0 (1-MainAxesInitPos(2).*2)*GAME.FLOOR_HEIGHT/GAME.RESOLUTION(1)], (1-MainAxesInitPos.*2).*[1 MainAxesSize(2)/GAME.RESOLUTION(1)]], ...
            'color', [1 1 1], ...
            'XLim', [0 MainAxesSize(1)]-0.5, ...
            'YLim', [0 MainAxesSize(2)]-0.5, ...
            'YDir', 'reverse', ...
            'NextPlot', 'add', ...
            'Visible', 'on', ...
            'XTick',[], ...
            'YTick',[]);
        
        
        MainCanvasHdl = image([0 MainAxesSize(1)-1], [0 MainAxesSize(2)-1], [],...
            'Parent', MainAxesHdl,...
            'Visible', 'on');
        TubeSpriteHdl = zeros(1,TUBE.N_TUBE);
        for i = 1:TUBE.N_TUBE
            TubeSpriteHdl(i) = image([0 TUBE.WIDTH], [0 GAME.RESOLUTION(1)+TUBE.MAX_VOffset], [],...
                'Parent', MainAxesHdl,...
                'Visible', 'on');
        end
        
        
        
        BirdSpriteHdl = surface(Bird.XGRID-100,Bird.YGRID-100, ...
            zeros(size(Bird.XGRID)), Sprites.Bird.CDataNan(:,:,:,1), ...
            'CDataMapping', 'direct',...
            'EdgeColor','none', ...
            'Visible','on', ...
            'Parent', MainAxesHdl);
        FloorSpriteHdl = image(0, 0,[],...
            'Parent', FloorAxesHdl, ...
            'Visible', 'on ');
        BeginInfoHdl = text(72, 100, 'Tap SPACE to begin', ...
            'FontName', 'Helvetica', 'FontSize', 20, 'HorizontalAlignment', 'center','Color',[.25 .25 .25], 'Visible','off');
        ScoreInfoBackHdl = text(72, 50, '0', ...
            'FontName', 'Helvetica', 'FontSize', 30, 'HorizontalAlignment', 'center','Color',[0,0,0], 'Visible','off');
        ScoreInfoForeHdl = text(70.5, 48.5, '0', ...
            'FontName', 'Helvetica', 'FontSize', 30, 'HorizontalAlignment', 'center', 'Color',[1 1 1], 'Visible','off');
        GameOverHdl = text(72, 70, 'GAME OVER', ...
            'FontName', 'Arial', 'FontSize', 20, 'HorizontalAlignment', 'center','Color',[1 0 0], 'Visible','off');
        
        ScoreInfoHdl = text(72, 110, 'Best', ...
            'FontName', 'Helvetica', 'FontSize', 20, 'FontWeight', 'Bold', 'HorizontalAlignment', 'center','Color',[1 1 1], 'Visible', 'off');
    end
    function initGame()
        % The scroll layer for the tubes
        TubeLayer.Alpha = false([GAME.RESOLUTION.*[1 2] 3]);
        TubeLayer.CData = uint8(zeros([GAME.RESOLUTION.*[1 2] 3]));
        
        Bird.Angle = 0;
        Score = 0;
        %TubeLayer.Alpha(GAME.FLOOR_TOP_Y:GAME.RESOLUTION(1), :, :) = true;
        Flags.ResetFloorTexture = true;
        SinYPos = 1;
        Flags.PreGame = true;
        %         scrollTubeLayer(GAME.RESOLUTION(2));   % Do it twice to fill the
        %         disp('mhaha');
        %         scrollTubeLayer(GAME.RESOLUTION(2));   % Entire tube layer
        drawToMainCanvas();
        set(MainCanvasHdl, 'CData', MainCanvas);
        set(BeginInfoHdl, 'Visible','on');
        set(ScoreInfoHdl, 'Visible','off');
        set(ScoreInfoBackHdl, 'Visible','off');
        set(ScoreInfoForeHdl, 'Visible','off');
        set(GameOverHdl, 'Visible','off');
        set(FloorSpriteHdl, 'CData',Sprites.Floor.CData);
        Tubes.FrontP = 1;              % 1-3
        Tubes.ScreenX = GAMEPLAY.RIGHT_X_FIRST_TUBE:TUBE.H_SPACE:GAMEPLAY.RIGHT_X_FIRST_TUBE+(TUBE.N_TUBE-1)*TUBE.H_SPACE; % The middle of each tube
        Tubes.VOffset = ceil(rand(1,3)*TUBE.MAX_VOffset);
        refreshTubes;
        for i = 1:TUBE.N_TUBE
            set(TubeSpriteHdl(i),'CData',Sprites.TubGap.CData,...
                'AlphaData',Sprites.TubGap.Alpha);
            redrawTube(i);
        end
        if ShowFPS
            set(fps_text_handle, 'Visible', 'on');
            set(var_text_handle, 'Visible', 'on'); % Display a variable
        end
    end
%% Game Logic
    function processBird()
        Bird.ScreenPos(2) = Bird.ScreenPos(2) + Bird.SpeedY;
        Bird.SpeedY = Bird.SpeedY + GAME.GRAVITY;
        if Bird.SpeedY < 0
            Bird.Angle = max(Bird.Angle - pi/10, -pi/10);
        else
            if Bird.ScreenPos(2) < Bird.LastHeight
                Bird.Angle = -pi/10; %min(Bird.Angle + pi/100, pi/2);
            else
                Bird.Angle = min(Bird.Angle + pi/30, pi/2);
            end
        end
    end
    function processCPUBird() % Process the bird when the game is not started
        Bird.ScreenPos(2) = SinY(SinYPos);
        SinYPos = mod(SinYPos, SinYRange)+1;
    end
    function drawToMainCanvas()
        % Draw the scrolls and sprites to the main canvas
        
        % Redraw the background
        MainCanvas = Sprites.Bkg.CData(:,:,:,InGameParams.CurrentBkg);
        
        TubeFirstCData = TubeLayer.CData(:, 1:GAME.RESOLUTION(2), :);
        TubeFirstAlpha = TubeLayer.Alpha(:, 1:GAME.RESOLUTION(2), :);
        % Plot the first half of TubeLayer
        MainCanvas(TubeFirstAlpha) = ...
            TubeFirstCData (TubeFirstAlpha);
    end
    function scrollTubes(offset)
        Tubes.ScreenX = Tubes.ScreenX - offset;
        if Tubes.ScreenX(Tubes.FrontP) <=-TUBE.WIDTH
            Tubes.ScreenX(Tubes.FrontP) = Tubes.ScreenX(Tubes.FrontP) + TUBE.N_TUBE*TUBE.H_SPACE;
            Tubes.VOffset(Tubes.FrontP) = ceil(rand*TUBE.MAX_VOffset);
            redrawTube(Tubes.FrontP);
            Tubes.FrontP = mod((Tubes.FrontP),TUBE.N_TUBE)+1;
            Flags.NextTubeReady = true;
        end
    end

    function refreshTubes()
        % Refreshing Scheme 1: draw the entire tubes but only shows a part
        % of each
        for i = 1:TUBE.N_TUBE
            set(TubeSpriteHdl(i), 'XData', Tubes.ScreenX(i) + [0 TUBE.WIDTH]);
        end
    end

    function refreshFloor(frameNo)
        offset = mod(frameNo, 24);
        set(FloorSpriteHdl, 'XData', -offset);
    end

    function redrawTube(i)
        set(TubeSpriteHdl(i), 'YData', -(Tubes.VOffset(i)));
    end

%% --- Math Functions for handling Collision / Rotation etc. ---
    function collide_flag = isCollide()
        collide_flag = false;
        tubesInProximity = arrayfun(@(x) Bird.ScreenPos(1) >= x-5 && Bird.ScreenPos(1) <= x+5+TUBE.WIDTH, Tubes.ScreenX);
        if ~any(tubesInProximity), return; end
        
        GapY = [128 177] - (Tubes.VOffset(tubesInProximity));    % The upper and lower bound of the GAP, 0-based
        
        collide_flag = Bird.ScreenPos(2) < GapY(1)+4 || Bird.ScreenPos(2) > GapY(2)-4;
    end

    function addScore()
        if Tubes.ScreenX(Tubes.FrontP) < 40 && Flags.NextTubeReady
            Flags.NextTubeReady = false;
            Score = Score + 1;
        end
    end

    function refreshBird()
        % move bird to pos [X Y],
        % and rotate the bird surface by X degrees, anticlockwise = +
        cosa = cos(Bird.Angle);
        sina = sin(Bird.Angle);
        xrotgrid = cosa .* Bird.XGRID + sina .* Bird.YGRID;
        yrotgrid = sina .* Bird.XGRID - cosa .* Bird.YGRID;
        xtransgrid = xrotgrid + Bird.ScreenPos(1)-0.5;
        ytransgrid = yrotgrid + Bird.ScreenPos(2)-0.5;
        set(BirdSpriteHdl, 'XData', xtransgrid, ...
            'YData', ytransgrid, ...
            'CData', Sprites.Bird.CDataNan(:,:,:, Bird.CurFrame));
    end
%% -- Display Infos --


%% -- Callbacks --
    function stl_KeyUp(hObject, eventdata, handles)
        key = get(hObject,'CurrentKey');
        % Remark the released keys as valid
        FlyKeyValid = FlyKeyValid | strcmp(key, FlyKeyNames);
    end
    function stl_KeyDown(hObject, eventdata, handles)
        key = get(hObject,'CurrentKey');
        
        % Has to be both 'pressed' and 'valid';
        % Two key presses at the same time will be counted as 1 key press
        down_keys = strcmp(key, FlyKeyNames);
        FlyKeyStatus = any(FlyKeyValid & down_keys);
        FlyKeyValid = FlyKeyValid & (~down_keys);
    end
    function stl_KeyPressFcn(hObject, eventdata, handles)
        curKey = get(hObject, 'CurrentKey');
        switch true
            case strcmp(curKey, 'escape')
                CloseReq = true;
        end
    end
    function stl_CloseReqFcn(hObject, eventdata, handles)
        CloseReq = true;
    end
end