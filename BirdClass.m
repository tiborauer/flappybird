classdef BirdClass < TexClass
    properties
        XY = []
        Size = 0.05
        
        JumpOnset = NaN
        Jump_Duration = 125 % Frame
    end
    
    properties(Access=private)
        dY = 0
        JumpY        
        
        FlapSpeed = 0.1
        
        Oscil_Resolution = 45
        Oscil_Amplitude = 0.02
        Oscil_toFlapRatio = 8        
    end
    
    methods
        function obj = BirdClass(window,sprites)
            obj = obj@TexClass(window);
            
            birdX = ceil(obj.Resolution(2)*obj.Size);
            mag = round(birdX/size(sprites.CData,1));
            obj.Size = [mag*size(sprites.CData,2) mag*size(sprites.CData,1)];
            CData = imresize(sprites.CData,mag);
            Alpha = imresize(sprites.Alpha,mag);
            for f = 1:size(CData,4)
                fCData = CData(:,:,:,f);
                fCData(:,:,4) = Alpha(:,:,1,f)*255;
                obj.Textures(f) = Screen(obj.Window, 'MakeTexture' ,fCData);
            end
            
            obj.XY = [(obj.Resolution(1)-obj.Size(1))/2 ...
                (obj.Resolution(2)-obj.Size(2))/2];
            
        end
        
        function Update(obj,fb)
            global parameters
            
            iFrame = obj.Textures(mod(ceil(parameters.frameNo*(parameters.Speed+0.5)*obj.FlapSpeed)-1,numel(obj.Textures))+1);
            if ~parameters.Speed
                oY = sin(linspace(0, 2*pi, obj.Oscil_Resolution))* obj.Resolution(2)*obj.Oscil_Amplitude;
                oY = oY(mod(ceil(parameters.frameNo*(parameters.Speed+0.5)*obj.FlapSpeed*obj.Oscil_toFlapRatio)-1,numel(oY))+1);
                angle = 0;
            else
                oY = 0;
                if fb
                    if isnan(obj.JumpOnset) || parameters.frameNo > (obj.JumpOnset+obj.Jump_Duration)
                        obj.JumpOnset = parameters.frameNo;
                        obj.JumpY = obj.XY(2);
                        obj.dY = -obj.Resolution(2)*(obj.Jump_Duration/2+1)*parameters.Gravity; 
                    end
                else
                    obj.JumpOnset = NaN;
                end
                obj.dY = obj.dY + obj.Resolution(2)*parameters.Gravity;
                obj.XY(2) = obj.XY(2) + obj.dY;
                angle = min(obj.dY*10, 90);
            end
            
            Screen(obj.Window,'DrawTexture',iFrame,[],[obj.XY(1) obj.XY(2)+oY obj.XY(1)+obj.Size(1) obj.XY(2)+oY+obj.Size(2)],angle);
            
        end
    end
end

