classdef FeedbackClass < handle
    
    properties(Access=private)
        MaxAct
        Step

        Slope
        Distance    % Distance between slopes
    end
    
    methods 
        function obj = FeedbackClass(maxAct, step, halfPlateau)
            
            if ~nargin
                maxAct = 100;
                step = 21;
                halfPlateau = 20;
            end
            
            obj.Calibrate(maxAct, step, halfPlateau);
        end
        
        function Calibrate(obj,maxAct, step, halfPlateau)
            obj.MaxAct = maxAct;
            obj.Step = step;
            
            % Initial
            sl = obj.MaxAct-halfPlateau;     % slope range
            obj.Slope = 6/sl;
            obj.Distance = sl+halfPlateau*2;
            
            % Iterations
            % - ensure that fun(minimum) is rounded to minval
            while round((obj.Step-1)/2*obj.Functor(-obj.MaxAct)) ~= -(obj.Step-1)/2
                obj.Slope = obj.Slope + 0.001;
            end
            
            % - ensure plateau is not larger than specified
            while (obj.getPlateauX - halfPlateau) > 0
                obj.Distance = obj.Distance - 2;
            end
        end
        
        function SetPlateau(obj,halfPlateau)
            obj.Calibrate(obj.MaxAct, obj.Step, halfPlateau);
        end
        
        function fb = Transform(obj,act)
            fb = round((obj.Step-1)/2*obj.Functor(act));
        end

        function y = Functor(obj,x)
            y = -1/(1+exp(obj.Slope*(x-(0-obj.Distance/2))))+1/(1+exp(-obj.Slope*(x-(0+obj.Distance/2))));
        end
%     end
%     
%     methods(Access=private)    
        function x = getPlateauX(obj)
            for x = 0:obj.MaxAct
                if round((obj.Step-1)/2*obj.Functor(x)) > 0, break; end
            end
            x = x-1;
        end
    end
    
end