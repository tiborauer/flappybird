classdef TexClass < handle
    
    properties(Access=protected)
        Window
        Resolution
        
        Textures
    end
    
    methods
        function obj = TexClass(window)
            obj.Window = window;
            rect = Screen(obj.Window,'Rect');
            obj.Resolution = [rect(3)-rect(1) rect(4)-rect(2)];
        end
    end
end

