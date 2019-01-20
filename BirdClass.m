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
        
        Angle_toSpeed = 30
    end
    
    methods
        function obj = BirdClass(window,sprite)
            obj = obj@TexClass(window);
            
            birdS = ceil(obj.Resolution(2)*obj.Size);
            mag = round(birdS/size(sprite.CData,1));
            obj.Size = [mag*size(sprite.CData,2) mag*size(sprite.CData,1)];
            CData = imresize(sprite.CData,mag);
            Alpha = imresize(sprite.Alpha,mag);
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
            
            oY = 0;
            angle = 0;
            
            iFrame = obj.Textures(mod(ceil(parameters.frameNo*(parameters.Speed+0.5)*obj.FlapSpeed)-1,numel(obj.Textures))+1);
            if ~fb && ~obj.isJumping % Oscillate
                oY = sin(linspace(0, 2*pi, obj.Oscil_Resolution))* obj.Resolution(2)*obj.Oscil_Amplitude;
                oY = oY(mod(ceil(parameters.frameNo*0.5*obj.FlapSpeed*obj.Oscil_toFlapRatio)-1,numel(oY))+1);
                obj.dY = 0;
                obj.JumpOnset = NaN;
            else
                if fb > 0 % Jump
                    if ~obj.isJumping
                        obj.JumpOnset = parameters.frameNo;
                        obj.JumpY = obj.XY(2);
                        obj.dY = -obj.Resolution(2)*(obj.Jump_Duration+1)*parameters.Gravity; % to jump back to baseline: -obj.Resolution(2)*(obj.Jump_Duration+1)*parameters.Gravity;
                    end
                elseif fb < 0
                    obj.JumpOnset = NaN;
                end
                
                obj.dY = obj.dY + obj.Resolution(2)*parameters.Gravity;
                obj.XY(2) = obj.XY(2) + obj.dY;
                angle = min(obj.dY*obj.Angle_toSpeed, 90);
            end
            
            Screen(obj.Window,'DrawTexture',iFrame,[],[obj.XY(1) obj.XY(2)+oY obj.XY(1)+obj.Size(1) obj.XY(2)+oY+obj.Size(2)],angle);
            
        end
        
        function val = isJumping(obj)
            global parameters
            
            val = ~isnan(obj.JumpOnset) && parameters.frameNo <= (obj.JumpOnset+obj.Jump_Duration);
        end
    end
end

