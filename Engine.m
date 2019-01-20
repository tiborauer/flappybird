classdef Engine < handle
    
    properties (Access=private)
        DAYTIME = [8 19] % Daylight between 8 and 19:59
        
        SIMULATE = 1 % Use mouse
        
        STAGE = struct(... % sizes in proportion
            'GRAVITY', 1e-5, ...
            'Floor_Y', [], ...
            'Floor_Height', 0.1, ...
            'Floor_Cycle', 24, ... % length of pattern to repeat
            'nTubes', 2, ...
            'Threshold_Size', [0.05 0.1], ...
            'Text_Size', 0.1 ...
            );
        
        Tubes = TubeClass.empty
        
        Bird = BirdClass.empty
        
        Feedback 
        
        dThreshold = 0
        
        Window = []
        Resolution
        
        Textures
        
        tId
    end
    
    properties (Dependent)
        Over
        Score
        Clock
        FPS
    end
    
    methods
        function obj = Engine
            global parameters
            parameters.Gravity = obj.STAGE.GRAVITY;
            parameters.Speed = 0;
            parameters.frameNo = 0;
            parameters.nTubesPassed = 0;
        end
        
        function CloseWindow(obj)
            if ~obj.SIMULATE
                ShowCursor;
            end
            Screen(obj.Window, 'Close');

            fprintf('[INFO] Score: %2.3f\n',obj.Score)
            fprintf('[INFO] FPS: %2.3f\n',obj.FPS)
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
            
            obj.STAGE.Text_Size = obj.STAGE.Text_Size * obj.Resolution(2); 
            Screen('TextFont', obj.Window, 'Calibri');
            Screen('TextSize', obj.Window, obj.STAGE.Text_Size);
            Screen('TextStyle', obj.Window, 1); % bold
            
            % Bird
            obj.Bird = BirdClass(obj.Window,sprites.Bird);
            
            % Tubes
            for t = 1:obj.STAGE.nTubes
                if t == 1
                    tX = 0;
                else
                    tX = tX + round(obj.Resolution(1)/obj.STAGE.nTubes); 
                end
                obj.Tubes(t) = TubeClass(obj.Window,sprites.Tube,round(4*...
                        (obj.Bird.Size(2) + ...
                        obj.Resolution(2)*(obj.Bird.Jump_Duration/2+1)*parameters.Gravity)),...
                        [tX obj.STAGE.Floor_Y]);
            end
            
            obj.STAGE.Threshold_Size = round(obj.STAGE.Threshold_Size.*obj.Resolution);
            obj.Feedback = FeedbackClass(obj.Resolution(2)/2,21,obj.STAGE.Threshold_Size(2)/2);
            
            if obj.SIMULATE
                SetMouse(obj.STAGE.Threshold_Size(1)*obj.Resolution(1)/2,obj.Resolution(2)/2,obj.Window);
            else
                HideCursor;
            end
        end
        
        function Update(obj)
            global parameters
            
            if ~parameters.frameNo, obj.tId = tic; end
            parameters.frameNo = parameters.frameNo + 1;
            
            % Background
            Screen(obj.Window,'DrawTexture',obj.Textures.Background);
            
            % Bird
            if obj.SIMULATE
                [~, mY] = GetMouse(obj.Window);
                act = obj.Resolution(2)/2-mY;
            end
            fb = obj.Feedback.Transform(act-obj.dThreshold/2);
            if fb > 0
                if ~parameters.Speed, parameters.Speed = round(obj.Resolution(1)/1000); end  % Start
                obj.dThreshold = obj.Resolution(2)/2-mY;
                obj.Feedback.SetPlateau(obj.STAGE.Threshold_Size(2)/2+obj.dThreshold/2);
            elseif fb < 0
                if obj.dThreshold, obj.Feedback.SetPlateau(obj.STAGE.Threshold_Size(2)/2); end
                obj.dThreshold = 0;
            end
%             if ~mod(parameters.frameNo,120), obj.Bird.JumpOnset = NaN; end      % New Jump in every 2 second if above Threshold       
            obj.Bird.Update(fb);
            
            % Tubes
            for t = 1:numel(obj.Tubes)
                obj.Tubes(t).Update;
%                 Screen(obj.Window,'FrameRect',[255 0 0],obj.Tubes(t).GapRect,3); % QC: Gap Rect
            end

            % Floor
            Screen(obj.Window,'DrawTexture',obj.Textures.Floor,[mod(parameters.frameNo*parameters.Speed, obj.STAGE.Floor_Cycle) 0 mod(parameters.frameNo*parameters.Speed, obj.STAGE.Floor_Cycle)+obj.Resolution(1) obj.Textures.Floor_Size(2)],...
                [0 obj.STAGE.Floor_Y obj.Resolution(1) obj.Resolution(2)]);
            
            % Threshold
            Screen(obj.Window,'FillRect',[255 255 255]*0.5,[0 (obj.Resolution(2)-obj.STAGE.Threshold_Size(2))/2-obj.dThreshold ...
                obj.STAGE.Threshold_Size(1) (obj.Resolution(2)+obj.STAGE.Threshold_Size(2))/2])
%             % QC
%             Screen(obj.Window,'FrameRect',[255 255 255]*1,[0 obj.Resolution(2)/2-obj.dThreshold/2-obj.Feedback.getPlateauX ...
%                 obj.STAGE.Threshold_Size(1) obj.Resolution(2)/2-obj.dThreshold/2+obj.Feedback.getPlateauX])
            
            % Score
            txt = sprintf('%d --> %d | %d',act,fb,obj.Score);
            DrawFormattedText(obj.Window,txt,'center',obj.Resolution(2));

            Screen(obj.Window,'Flip');
        end
        
        function val = get.Over(obj)
            
            val = false;
            
            % collision
            tubesInProximity = arrayfun(@(tube) obj.Bird.XY(1)+obj.Bird.Size(1) >= tube.XY(1) && obj.Bird.XY(1) <= tube.XY(1)+tube.Size(1), obj.Tubes);
            if any(tubesInProximity)
                val = obj.Bird.XY(2)+obj.Bird.Size(2) >= obj.Tubes(tubesInProximity).GapRect(4) || obj.Bird.XY(2) <= obj.Tubes(tubesInProximity).GapRect(2);
            end
            
            % fall
            val = val || (obj.Bird.XY(2) + obj.Bird.Size(2) >= obj.STAGE.Floor_Y); 
            
            % fly over
            val = val || (obj.Bird.XY(2) < 0); 
        end
        
        function val = get.Score(obj)
            global parameters
            val = sum(arrayfun(@(x) x.XY(1)+x.Size(1) < obj.Bird.XY(1) ,obj.Tubes)) + parameters.nTubesPassed;
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
