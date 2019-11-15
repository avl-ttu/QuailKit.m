function HT_Visual(data,classifier,dim,precision,showclass,colors)
%HT_Visual [Release 2017-04-06] visualizes data and classifier.
%
%   data: A table with each row containing a sample vector and the last
%   column containing class names.
%
%   classifier (optional): An structure with as many nested structures as
%   available boundaries, each with the mandatory fields: d, Algorithm and
%   SupportVectors.
%
%   dim (optional): An integer either 2 or 3 which indicates whether
%   HT_Visual will prefer 2D or 3D plots. If it is left empty it will
%   produce 3D plots when possible.
%
%   res (optional): The resolution of decision boundries. Sometimes it
%   having a higher resolution becomes important especially for some
%   nonlinear cases. Of course the higher resolutions need more time to
%   render. Any value between 0.01 and 0.001 should be fine. default: 1e-3.

%   © 2017 Hanif Tiznobake.

mode=nargin;
data_name=inputname(1);
data=sortrows(data,size(data,2));
x=table2array(data(:,1:end-1));
[N,l]=size(x);
[classes(:,1),temp,~]=unique(data(:,end));
classes(:,2:3)=array2table([(1:size(classes,1))',temp]);
classes(end,4)={N};
classes(1:end-1,4)=array2table(temp(2:end)-1);
classes.Properties.VariableNames={'Class' 'Label' 'From' 'To'};
if mode>1 && ~isempty(classifier) && showclass
    names=fieldnames(classifier);
end
cmap=lines;
cmap=cmap(1:7,:);
cmap2=colorcube;
cmap2=cmap2(1:40,:);
switch colors
    case 'Reverse'
        cmap=cmap(end:-1:1,:);
        cmap2=cmap2(end:-1:1,:);
    case 'Random'
        cmap=cmap(randperm(length(cmap)),:);
        cmap2=cmap2(randperm(length(cmap2)),:);
end
if mode<3 || isempty(dim)
    dim=3;
end
if l<3
    dim=2;
end
if mode<4 || isempty(precision)
    precision=1e-3;
end
features=data.Properties.VariableNames(1:end-1);
% figure('Name','Plot Matrix','NumberTitle','off');
% gplotmatrix(x,[],labels,cmap,'...',[],'off','grpbars',features,[]);
% title(data_name);
switch dim
    case 2
        p=nchoosek(1:l,2);
        prog=0;
        fprintf('\nRendering "%s"\n',data_name);
        for i=1:size(p,1)
            prog=prog+1;
            fprintf('\n\tGraph %2.0f of %2.0f: (%s, %s)\n',prog, ...
                size(p,1),char(features(p(i,1))), ...
                char(features(p(i,2))));
            figure('Name',sprintf('%s (Plot %d of %d)',data_name,i, ...
                size(p,1)),'NumberTitle','off');
            hold on
            for j=1:size(classes,1)
                scatter(x(classes.From(j):classes.To(j),p(i,1)), ...
                    x(classes.From(j):classes.To(j),p(i,2)),16, ...
                    cmap(rem(j-1,length(cmap))+1,:),'full','DisplayName', ...
                    char(classes.Class(j))');
            end
            title(data_name);
            xlabel(features(p(i,1)));
            ylabel(features(p(i,2)));
            ax=axis;
            axis manual
            if mode>1 && ~isempty(classifier) && showclass
                [performance,details]=HT_Test(data,classifier);
                index=details.detail.Status~=1;
                scatter(x(index,p(i,1)),x(index,p(i,2)),64, ...
                    'k','x','DisplayName',sprintf('Misclassified (%2.1f%%)',(1-performance)*100));
                [X,Y]=ndgrid(ax(1):(ax(2)-ax(1))*precision:ax(2), ...
                    ax(3):(ax(4)-ax(3))*precision:ax(4));
                for j=1:size(names,1)
                    temp1=[];
                    temp2=[];
                    temp3=sprintf('\n - C: %0.3g',classifier.(char(names(j,:))).C);
                    if classifier.(char(names(j,:))).Flag~=1
                        temp1=sprintf('\n>> Didn''t Converge <<');
                    end
                    if ~isempty(classifier.(char(names(j,:))).SoftMarginSymmetry)
                        if classifier.(char(names(j,:))).SoftMarginSymmetry
                            temp3=temp3+string(' (Symmetric)');
                        else
                            temp3=temp3+string(' (Non-Symmetric)');
                        end
                    end
                    if ~isempty(classifier.(char(names(j,:))).Parameters)
                        temp2=sprintf('\n - Parameter(s): %s', ...
                            strjoin(string(num2str( ...
                            classifier.(char(names(j,:))). ...
                            Parameters(:),'%0.2f')),', '));
                    end
                    if strcmpi(classifier.(char(names(j,:))).Algorithm,'SVM')
                        scatter(NaN,NaN,[],'Marker','none','DisplayName', ...
                            sprintf('-------------------------------------\n"%s"%s\n - Type: %s %s\n - Method: %s%s%s', ...
                            char(names(j,:)),temp1, ...
                            classifier.(char(names(j,:))).Type, ...
                            classifier.(char(names(j,:))).Algorithm, ...
                            classifier.(char(names(j,:))).Method,temp3,temp2));
                        if dim>=l
                            fprintf('\t\tBoundry %2.0f of %2.0f: %s\n',j, ...
                                size(names,1),char(names(j,:)));
                            F=classifier.(char(names(j,:))).d;
                            temp=size(reshape(X,[],1),1);
                            space=zeros(temp,l);
                            space(:,[p(i,1),p(i,2)])=[reshape( ...
                                X,[],1),reshape(Y,[],1)];
                            V=reshape(round(F(space),3),size(X));
                            contour(X,Y,V,[0,0], ...
                                'LineWidth',1.5,'LineColor',cmap2(j,:), ...
                                'DisplayName','   Decision Boundry');
                            if strcmp(classifier.(char(names(j,:))).Algorithm,'SVM')
                                contour(X,Y,V,[-1,1],'LineWidth', ...
                                    0.5,'LineColor',cmap2(j,:), ...
                                    'DisplayName','   Margin Boundry');
                            end
                        end
                        if strcmpi(data_name(end-4:end),'Train')
                            scatter(classifier.(char(names(j,:))). ...
                                SupportVectors(:,p(i,1)),classifier. ...
                                (char(names(j,:))).SupportVectors(:, ...
                                p(i,2)),32,cmap2(j,:),'DisplayName', ...
                                '   Support Vector');
                            if ~isempty(classifier.(char(names(j,:))).EdgeVectors)
                                scatter(classifier.(char(names(j,:))). ...
                                    EdgeVectors(:,p(i,1)),classifier. ...
                                    (char(names(j,:))).EdgeVectors(:, ...
                                    p(i,2)),64,cmap2(j,:),'DisplayName', ...
                                    '   Edge Vector');
                            end
                        end
                    end
                end
            end
            leg=legend('show','Location','northeastoutside');
            leg.Interpreter='none';
        end
    case 3
        p=nchoosek(1:l,3);
        prog=0;
        fprintf('\nRendering "%s"\n',data_name);
        for i=1:size(p,1)
            prog=prog+1;
            figure('Name',sprintf('%s (Plot %d of %d)',data_name,i, ...
                size(p,1)),'NumberTitle','off');
            hold on;
            fprintf('\n\tGraph %2.0f of %2.0f: (%s, %s, %s)\n',prog, ...
                size(p,1),char(features(p(i,1))),char(features(p(i, ...
                2))),char(features(p(i,3))));
            for j=1:size(classes,1)
                scatter3(x(classes.From(j):classes.To(j),p(i,1)), ...
                    x(classes.From(j):classes.To(j),p(i,2)), ...
                    x(classes.From(j):classes.To(j),p(i,3)), ...
                    16,cmap(rem(j-1,length(cmap))+1,:),'full','DisplayName',char(classes.Class(j)));
            end
            view(3);
            title(data_name);
            xlabel(features(p(i,1)));
            ylabel(features(p(i,2)));
            zlabel(features(p(i,3)));
            ax=axis;
            axis manual
            if mode>1 && ~isempty(classifier) && showclass
                [performance,details]=HT_Test(data,classifier);
                if strcmpi(data_name(end-3:end),'Test')
                    leg.Title=num2str(performance);
                end
                index=details.detail.Status~=1;
                scatter3(x(index,p(i,1)),x(index,p(i,2)),x(index,p(i,3)),64, ...
                    'k','x','DisplayName',sprintf('Misclassified (%2.1f%%)',(1-performance)*100));
                [X,Y,Z]=ndgrid(ax(1):(ax(2)-ax(1))*precision:ax(2), ...
                    ax(3):(ax(4)-ax(3))*precision:ax(4), ...
                    ax(5):(ax(6)-ax(5))*precision:ax(6));
                for j=1:size(names,1)
                    temp1=[];
                    temp2=[];
                    temp3=sprintf('\n - C: %.3g',classifier.(char(names(j,:))).C);
                    if classifier.(char(names(j,:))).Flag~=1
                        temp1=sprintf('\n>> Didn''t Converge <<');
                    end
                    if ~isempty(classifier.(char(names(j,:))).SoftMarginSymmetry)
                        if classifier.(char(names(j,:))).SoftMarginSymmetry
                            temp3=temp3+string(' (Symmetric)');
                        else
                            temp3=temp3+string(' (Non-Symmetric)');
                        end
                    end
                    if ~isempty(classifier.(char(names(j,:))).Parameters)
                        temp2=sprintf('\n - Parameter(s): %s', ...
                            strjoin(string(num2str( ...
                            classifier.(char(names(j,:))). ...
                            Parameters(:),'%0.2f')),', '));
                    end
                    if strcmpi(classifier.(char(names(j,:))).Algorithm,'SVM')
                        scatter(NaN,NaN,[],'Marker','none','DisplayName', ...
                            sprintf('-------------------------------------\n"%s"%s\n - Type: %s %s\n - Method: %s%s%s', ...
                            char(names(j,:)),temp1, ...
                            classifier.(char(names(j,:))).Type, ...
                            classifier.(char(names(j,:))).Algorithm, ...
                            classifier.(char(names(j,:))).Method,temp3,temp2));
                        if dim>=l
                            fprintf('\t\tBoundry %2.0f of %2.0f: %s\n',j, ...
                                size(names,1),char(names(j,:)));
                            F=classifier.(char(names(j,:))).d;
                            temp=size(reshape(X,[],1),1);
                            space=zeros(temp,l);
                            space(:,[p(i,1),p(i,2),p(i,3)])=[reshape( ...
                                X,[],1),reshape(Y,[],1),reshape(Z,[],1)];
                            V=reshape(round(F(space),3),size(X));
                            patch(isosurface(X,Y,Z,V,0),'FaceColor', ...
                                cmap2(j,:),'FaceAlpha',0.8,'LineStyle', ...
                                'none','DisplayName','Decision Boundry');
%                             if strcmp(classifier.(char(names(j,:))).Algorithm,'SVM')
%                                 patch(isosurface(X,Y,Z,V,-1),'FaceColor', ...
%                                     cmap2(j,:),'FaceAlpha',0.2,'LineStyle', ...
%                                     'none','DisplayName','Margin Boundry');
%                                 patch(isosurface(X,Y,Z,V,1),'FaceColor', ...
%                                     cmap2(j,:),'FaceAlpha',0.2,'LineStyle', ...
%                                     'none','DisplayName','Margin Boundry');
%                             end
                        end
                        if strcmpi(data_name(end-4:end),'Train')
                            scatter3( ...
                                classifier.(char(names(j,:))).SupportVectors( ...
                                :,p(i,1)),classifier.(char(names(j,:))) ...
                                .SupportVectors(:,p(i,2)),classifier.(char( ...
                                names(j,:))).SupportVectors(:,p(i,3)),36, ...
                                cmap2(j,:),'DisplayName','Support Vector');
                            if ~isempty(classifier.(char(names(j,:))).EdgeVectors)
                                scatter3( ...
                                    classifier.(char(names(j,:))).EdgeVectors( ...
                                    :,p(i,1)),classifier.(char(names(j,:))) ...
                                    .EdgeVectors(:,p(i,2)),classifier.(char( ...
                                    names(j,:))).EdgeVectors(:,p(i,3)),64, ...
                                    cmap2(j,:),'DisplayName','Edge Vector');
                            end
                        end
                    end 
                end
            end
            leg=legend('show','Location','northeastoutside');
            leg.Interpreter='none';
        end
end
end