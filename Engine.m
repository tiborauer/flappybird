classdef Engine < handle
    
    properties
        Speed = 1
    end
    
    properties (Access=private)
        DAYTIME = [8 19] % Daylight between 8 and 19:59
        
        SIMULATE = 1
        
        STAGE = struct(... % sizes in proportion
            'Floor_Height', 0.1,...
            'Floor_Cycle', 24, ...
            'Bird_Size', 0.05, ...
            'Bird_FlapSpeed', 0.1, ...
            'ThresholdXY', [0.05 0.01] ...
            );
        
        Window = []
        Resolution
        
        Sprites
        Textures
        
        tId
        frameNo = 0
    end
    
    properties (Dependent)
        Clock
        FPS
    end
    
    methods
        function obj = Engine
            obj.Sprites = load(fullfile(fileparts(mfilename('fullpath')),'sprites.mat'));
        end
        
        function CloseWindow(obj)
            Screen(obj.Window, 'Close');
        end
        
        function InitWindow(obj)
            Screen('Preference', 'SkipSyncTests', 1);
            scr = max(Screen('Screens'));
            [obj.Window, rect] = Screen('OpenWindow', scr, WhiteIndex(scr)); 
            obj.Resolution = [rect(3)-rect(1) rect(4)-rect(2)];
            
            Screen(obj.Window,'BlendFunction',GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            
            CData = imresize(obj.Sprites.Background.CData,obj.Resolution(2)/size(obj.Sprites.Background.CData,1));
            t = clock;
            obj.Textures.Background = Screen(obj.Window, 'MakeTexture' ,repmat(CData(:,:,:,(t(4) < obj.DAYTIME(1) || t(4) > obj.DAYTIME(2))+1),...
                1,ceil(obj.Resolution(1)/size(CData,2))));
            
            floorX = ceil(obj.Resolution(2)*obj.STAGE.Floor_Height);
            mag = round(floorX/size(obj.Sprites.Floor.CData,1));
            obj.STAGE.Floor_Cycle = obj.STAGE.Floor_Cycle*mag;
            CData = imresize(obj.Sprites.Floor.CData,mag);
            obj.Textures.Floor_Rect = [0 0 (ceil(obj.Resolution(1)/size(CData,2))+1)*size(CData,2) size(CData,1)];
            obj.Textures.Floor = Screen(obj.Window, 'MakeTexture' ,repmat(CData,1,ceil(obj.Resolution(1)/size(CData,2))+1)); % leave room for offset
            
            birdX = ceil(obj.Resolution(2)*obj.STAGE.Bird_Size);
            mag = round(birdX/size(obj.Sprites.Bird.CData,1));
            obj.Textures.Bird_Rect = [0 0 mag*size(obj.Sprites.Bird.CData,2) mag*size(obj.Sprites.Bird.CData,1)];
            CData = imresize(obj.Sprites.Bird.CData,mag);
            Alpha = imresize(obj.Sprites.Bird.Alpha,mag);
            for f = 1:size(CData,4)
                fCData = CData(:,:,:,f);
                fCData(:,:,4) = Alpha(:,:,1,f)*255;
                obj.Textures.Bird(f) = Screen(obj.Window, 'MakeTexture' ,fCData);
            end
            
            SetMouse(obj.STAGE.ThresholdXY(1)*obj.Resolution(1)/2,obj.Resolution(2)/2,obj.Window);
        end
        
        function Refresh(obj)
            if ~obj.frameNo, obj.tId = tic; end
            obj.frameNo = obj.frameNo + 1;
            
            % Stage
            Screen(obj.Window,'DrawTexture',obj.Textures.Background);
            Screen(obj.Window,'DrawTexture',obj.Textures.Floor,[mod(obj.frameNo*obj.Speed, obj.STAGE.Floor_Cycle) 0 mod(obj.frameNo*obj.Speed, obj.STAGE.Floor_Cycle)+obj.Resolution(1) obj.Textures.Floor_Rect(4)],[0 floor(obj.Resolution(2)*(1-obj.STAGE.Floor_Height)) obj.Resolution(1) obj.Resolution(2)]);
            
            % Threshold
            Screen(obj.Window,'FillRect',[255 255 255]*0.5,[0 (1-obj.STAGE.ThresholdXY(2))*obj.Resolution(2)/2 obj.STAGE.ThresholdXY(1)*obj.Resolution(1) (1+obj.STAGE.ThresholdXY(2))*obj.Resolution(2)/2])
            
            % Bird
            Screen(obj.Window,'DrawTexture',obj.Textures.Bird(mod(ceil(obj.frameNo*obj.Speed*obj.STAGE.Bird_FlapSpeed)-1,numel(obj.Textures.Bird))+1),[],...
                [(obj.Resolution(1)-obj.Textures.Bird_Rect(3))/2 (obj.Resolution(2)-obj.Textures.Bird_Rect(4))/2 ...
                (obj.Resolution(1)-obj.Textures.Bird_Rect(3))/2+obj.Textures.Bird_Rect(3) (obj.Resolution(2)-obj.Textures.Bird_Rect(4))/2+obj.Textures.Bird_Rect(4)]);

            Screen(obj.Window,'Flip');
        end
        
        function val = get.Clock(obj)
            if ~obj.frameNo, val = 0;
            else, val = toc(obj.tId); end
        end
        
        function val = get.FPS(obj)
            val = obj.frameNo/obj.Clock;
        end
        
    end
    
end
