classdef HT_Data
    %UNTITLED3 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        raw
        processed
        spectrogram
    end
    
    methods
        function obj = HT_Data(raw)
            obj.raw = raw;
            obj.processed = HT_Process(raw);
            obj.spectrogram = HT_Spectrogram(raw);
        end
        
        function outputArg = method1(obj,inputArg)
            outputArg = obj.Property1 + inputArg;
        end
    end
end

