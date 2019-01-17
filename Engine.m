classdef Engine < handle
    properties (Access=private)
        DAYTIME = [8 19] % Daylight between 8 and 19:59
        
        Window = []
        Resolution
        
        Sprites
        Textures
    end
    
    methods
        function obj = Engine
            obj.Sprites = load(fullfile(fileparts(mfilename('fullpath')),'sprites.mat'));
        end
        
        function CloseWindow(obj)
            Screen(obj.Window, 'Close');
        end
        
        function InitWindow(obj)
            scr = max(Screen('Screens'));
            [obj.Window, obj.Resolution] = Screen('OpenWindow', scr, WhiteIndex(scr));
            
            Screen(obj.Window,'BlendFunction',GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            
            bgY = size(obj.Sprites.Background.CData,1)/obj.Resolution(4)*obj.Resolution(3);
            obj.Textures.Background(1) = Screen(obj.Window, 'MakeTexture' ,repmat(obj.Sprites.Background.CData(:,:,:,1),1,ceil(bgY/size(obj.Sprites.Background.CData,2))));
            obj.Textures.Background(2) = Screen(obj.Window, 'MakeTexture' ,repmat(obj.Sprites.Background.CData(:,:,:,2),1,ceil(bgY/size(obj.Sprites.Background.CData,2))));
            
            obj.Textures.Floor = 
        end
        
        function Refresh(obj)
            t = clock;
            Screen(obj.Window,'DrawTexture',obj.Textures.Background((t(4) < obj.DAYTIME(1) || t(4) > obj.DAYTIME(2))+1),[],obj.Resolution);
            Screen(obj.Window,'Flip');
        end
    end
    
end
