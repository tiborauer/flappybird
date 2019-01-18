classdef Engine < handle
    
    properties (Access=private)
        DAYTIME = [8 19] % Daylight between 8 and 19:59
        
        SIMULATE = 1
        
        STAGE = struct(... % sizes in proportion
            'Floor_Y', [], ...
            'Floor_Height', 0.1, ...
            'Floor_Cycle', 24, ...
            'Threshold_Size', [0.05 0.02] ...
            );
        
        Tube
        
        Bird
        
        Window = []
        Resolution
        
        Textures
        
        tId
    end
    
    properties (Dependent)
        Over
        Clock
        FPS
    end
    
    methods
        function obj = Engine
            global parameters
            parameters.Gravity = 0.0001;
            parameters.Speed = 0;
            parameters.frameNo = 0;
        end
        
        function CloseWindow(obj)
            Screen(obj.Window, 'Close');
        end
        
        function InitWindow(obj,varargin)
            global parameters
            
            inpArgs = struct;
            for a = 1:2:numel(varargin)
                inpArgs.(varargin{a}) = varargin{a+1};
            end
            
            args = {};
            if isfield(inpArgs, 'windowed'), args{1} = inpArgs.windowed; end
            
            Screen('Preference', 'SkipSyncTests', 1);
            scr = max(Screen('Screens'));
            [obj.Window, rect] = Screen('OpenWindow', scr, WhiteIndex(scr), args{:}); 
            obj.Resolution = [rect(3)-rect(1) rect(4)-rect(2)];
            
            Screen(obj.Window,'BlendFunction',GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            
            sprites = load(fullfile(fileparts(mfilename('fullpath')),'sprites.mat'));
            
            % Stage
            CData = imresize(sprites.Background.CData,obj.Resolution(2)/size(sprites.Background.CData,1));
            t = clock;
            obj.Textures.Background = Screen(obj.Window, 'MakeTexture' ,repmat(CData(:,:,:,(t(4) < obj.DAYTIME(1) || t(4) > obj.DAYTIME(2))+1),...
                1,ceil(obj.Resolution(1)/size(CData,2))));

            floorX = ceil(obj.Resolution(2)*obj.STAGE.Floor_Height);
            mag = round(floorX/size(sprites.Floor.CData,1));
            obj.STAGE.Floor_Cycle = obj.STAGE.Floor_Cycle*mag;
            CData = imresize(sprites.Floor.CData,mag);
            obj.Textures.Floor_Size = [(ceil(obj.Resolution(1)/size(CData,2))+1)*size(CData,2) size(CData,1)];
            obj.Textures.Floor = Screen(obj.Window, 'MakeTexture' ,repmat(CData,1,ceil(obj.Resolution(1)/size(CData,2))+1)); % leave room for offset
            obj.STAGE.Floor_Y = floor(obj.Resolution(2)*(1-obj.STAGE.Floor_Height));
            
            % Bird
            obj.Bird = BirdClass(obj.Window,sprites.Bird);
            
            obj.Tube = TubeClass(2*obj.Resolution(2)*(obj.Bird.Jump_Duration/2+1)*parameters.Gravity);
            
            SetMouse(obj.STAGE.Threshold_Size(1)*obj.Resolution(1)/2,obj.Resolution(2)/2,obj.Window);
        end
        
        function Update(obj)
            global parameters
            
            if ~parameters.frameNo, obj.tId = tic; end
            parameters.frameNo = parameters.frameNo + 1;
            
            % Stage
            Screen(obj.Window,'DrawTexture',obj.Textures.Background);
            Screen(obj.Window,'DrawTexture',obj.Textures.Floor,[mod(parameters.frameNo*parameters.Speed, obj.STAGE.Floor_Cycle) 0 mod(parameters.frameNo*parameters.Speed, obj.STAGE.Floor_Cycle)+obj.Resolution(1) obj.Textures.Floor_Size(2)],...
                [0 obj.STAGE.Floor_Y obj.Resolution(1) obj.Resolution(2)]);
            
            % Threshold
            Screen(obj.Window,'FillRect',[255 255 255]*0.5,[0 (1-obj.STAGE.Threshold_Size(2))*obj.Resolution(2)/2 obj.STAGE.Threshold_Size(1)*obj.Resolution(1) (1+obj.STAGE.Threshold_Size(2))*obj.Resolution(2)/2])
            
            % Bird
            [~, mY] = GetMouse(obj.Window);
            fb = mY < (1-obj.STAGE.Threshold_Size(2))*obj.Resolution(2)/2;
            if fb, parameters.Speed = 1; end
            if ~mod(parameters.frameNo,120), obj.Bird.JumpOnset = NaN; end            
            obj.Bird.Update(fb);

            Screen(obj.Window,'Flip');
        end
        
        function val = get.Over(obj)
            val = obj.Bird.XY(2) + obj.Bird.Size(2) >= obj.STAGE.Floor_Y; % fallen
        end
        
        function val = get.Clock(obj)
            global parameters
            
            if ~parameters.frameNo, val = 0;
            else, val = toc(obj.tId); end
        end
        
        function val = get.FPS(obj)
            global parameters
            
            val = parameters.frameNo/obj.Clock;
        end
        
    end
    
end
