classdef FlappyBird
    properties
        
    end
    
    methods
        function obj = FlappyBird
            
        end
        
        function Close(obj)
        end
    end
    
    methods (Access=private)
        function stl_KeyPressFcn(hObject, eventdata, handles)
            curKey = get(hObject, 'CurrentKey');
            switch true
                case strcmp(curKey, 'escape')
                    obj.Close;
            end
        end
        function stl_CloseReqFcn(hObject, eventdata, handles)
            obj.Close;
        end
    end
end