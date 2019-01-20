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
            obj.Distance = obj.MaxAct+halfPlateau;
            
            % Iterations
            % - ensure that fun(minimum) is rounded to minval
            sl = 0;
            while obj.cost_Slope(sl)
                sl = sl + 0.0001;
            end
            
            % - ensure plateau is not larger than specified
            fminbnd(@(dist) obj.cost_Distance(dist,halfPlateau), obj.MaxAct/2, obj.MaxAct*2);
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
        
        function x = getPlateauX(obj)
            for x = 0:obj.MaxAct
                if round((obj.Step-1)/2*obj.Functor(x)) > 0, break; end
            end
            x = x-1;
        end
    end
    
    methods(Access=private)
        function val = cost_Slope(obj,slope)
            obj.Slope = slope;
            val = abs(round((obj.Step-1)/2*obj.Functor(-obj.MaxAct)) - -(obj.Step-1)/2);
        end
        
        function val = cost_Distance(obj,dist,halfPlateau)
             obj.Distance = dist;
             val = abs(obj.getPlateauX - halfPlateau);
        end
    end
    
end