classdef LogClass < handle
    properties(Access=private)
    
        Stack
    
    end
    
    methods
        
        function obj = LogClass(varargin)
            v(1:2:nargin*2-1) = varargin;
            for i = 1:nargin, c{i} = {}; end
            v(2:2:nargin*2) = c;
            obj.Stack = struct(v{:});
        end
        
        function Put(obj,varargin)
            f = fieldnames(obj.Stack);
            
            if nargin-1 < numel(f), varargin{end+1} = ''; end
            
            ind = strcmp({obj.Stack.Name},varargin{1});
            if ~any(ind), ind = numel(obj.Stack)+1; end
            
            for i = 1:numel(f)
                obj.Stack(ind(1)).(f{i}) = varargin{i};
            end
        end
        
        function val = Get(obj,name,field)
             ind = strcmp({obj.Stack.Name},name);
             if any(ind)
                 val = obj.Stack(ind);
                 if nargin == 3, val = val.(field); end
             else
                 val = [];
             end
        end
        
    end
end

