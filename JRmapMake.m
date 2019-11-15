classdef JRmapMake
    %JR_MAPMAKE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        results
        unit
        image
        key
        recorders
        window
        filepath
        imglon
        imglat
        lonlim
        latlim
    end
    
    methods
          
        function obj=JRmapMake(h,key, data, distance)
            R = 6.3781*(10.^6);
            %Find max long min long
            meanLong =  mean(data(:,2));
            obj.lonlim = [meanLong - rad2deg(distance/R) meanLong + rad2deg(distance/R)];
            
            %Find max lat min lat
            meanLat = mean(data(:,1));
            obj.latlim = [meanLat - rad2deg(distance/R) meanLat + rad2deg(distance/R)];
            
            h.XLim=obj.lonlim;
            h.YLim=obj.latlim;
            hold(h,'on');
            plot_google_map('Axis',h,'MapScale', 1, 'maptype', 'satellite', 'showLabels', 0, 'APIKey', key, 'AutoAxis', 1);
            plot(h,data(:,2)', data(:,1)' , '.r', 'MarkerSize', 20);
            hold(h,'off');
        end
    end
end

