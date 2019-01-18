classdef TubeClass < TexClass
    properties
        XY = []
        Size = 0.1 % width relative to screen width
    end
    
    properties(Access=private)
        Max_VOffset = 1 % relative to gap, also a jitter between re-occurences of tubes
        VOffset
        Gap
    end
    
    properties(Dependent)
        GapRect
    end
    
    methods
        function obj = TubeClass(window, sprite,gap, XY)
            obj = obj@TexClass(window);
            
            obj.Max_VOffset = obj.Max_VOffset*gap;
            
            tubeX = ceil(obj.Resolution(1)*obj.Size);
            mag = round(tubeX/size(sprite.CData,2));
            tCData = imresize(sprite.CData,mag);
            tAlpha = imresize(sprite.Alpha,mag);
            
            tCData(:,:,4,:) = tAlpha(:,:,1,:)*255;
            
            ext = ceil(((obj.Resolution(1) + obj.Max_VOffset) - (size(tCData,1)*2+gap)) / 2); 
            if ext > 0
                CData = vertcat(...
                    repmat(tCData(1,:,:,2),ext,1),...
                    tCData(:,:,:,2),...
                    zeros(gap,size(tCData,2),4),...
                    tCData(:,:,:,1),...
                    repmat(tCData(1,:,:,2),ext,1) ...
                    );
            else
                CData = vertcat(...
                    tCData(-ext:end,:,:,2),...
                    zeros(gap,size(tCData,2),4),...
                    tCData(1:end-(-ext),:,:,1)...
                    );
            end
            
            obj.Size = [size(CData,2) size(CData,1)];
            obj.Textures = Screen(obj.Window, 'MakeTexture' ,CData);
            
            obj.XY = [obj.Resolution(1)+XY(1) -(obj.Resolution(2)-XY(2))];
            obj.VOffset = round((-1+rand*2-1)*obj.Max_VOffset/2);
            obj.Gap = [obj.XY(2)+size(tCData,1)+ext+1 obj.XY(2)+size(tCData,1)+ext+gap];
        end
        
        function Update(obj)
            global parameters
            
            obj.XY(1) = obj.XY(1) - parameters.Speed;
            if obj.XY(1) < -obj.Size(1)
                obj.XY(1) = obj.Resolution(1)+round(rand*obj.Max_VOffset);  % shift back to the beginning + jitter
                obj.VOffset = round((-1+rand*2-1)*obj.Max_VOffset/2);       % recalculate VOffset
                parameters.nTubesPassed = parameters.nTubesPassed + 1;      % correct for tubes passed by bird
            end 

            Screen(obj.Window,'DrawTexture',obj.Textures,[],[obj.XY(1) obj.XY(2)+obj.VOffset obj.XY(1)+obj.Size(1) obj.XY(2)+obj.VOffset+obj.Size(2)]);
        end
        
        function val = get.GapRect(obj)
            val = [obj.XY(1) obj.Gap(1)+obj.VOffset obj.XY(1)+obj.Size(1) obj.Gap(2)+obj.VOffset];
        end
    end
end

