classdef tests  < matlab.mixin.Copyable
    properties
        funcs
        
    end
    
    methods
        function obj = tests(funcs)
            obj.funcs = funcs;
        end
        
        function y = compute(obj,x)
            y = obj.funcs(x);
        end
        
    end
    
end