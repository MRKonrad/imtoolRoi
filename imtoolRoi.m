function [hFig] = imtoolRoi(input, outputVariableName)
% imtoolRoi imtool extended to 3rd dimension and ROI functionalities.
%   hFig = imtoolRoi(data, outputVariableName)
%
% INPUT:
%  data - 3d matrix
%  outputVariableName name of the outpu variable in the base workspace
%
% OUTPUT:
%  hFig - figure handle
%
% EXAMPLE OF USE:
%  %% prepare data
%  load mri;
%  D3D = squeeze(D); % 3dims not 4
%  %% prepare matlab path (you can manually add imtoolRoi to matlab path)
%  addpath(genpath('..\imtoolRoi')) 
%  %% run
%  hFig = imtoolRoi(D3D, 'outputSavedHere');
%  %% use next 2 lines if you want to save output variable to a file
%  waitfor(hFig); % optional, needed for saving
%  save('myFile.mat','outputSavedHere')
%
%   author: Konrad Werys (konradwerys@gmail.com)
%
%   See also imtool

if isstruct(input)
    userData = input;
    data = userData.data;
else
    userData.data = input;
    userData.currentImage = 1;

    userData.contours.endo = cell(1,userData.nImages);
    userData.contours.epi = cell(1,userData.nImages);
    userData.contoursInterp.endo = cell(1,userData.nImages);
    userData.contoursInterp.epi = cell(1,userData.nImages);

    userData.nPontsInterp = 25;
end

hFig = imtool(data(:,:,1),[]);

userData.hFig = hFig;  
userData.nImages = size(data,3);
userData.hImage = findobj(userData.hFig,'Type','image');
userData.hAxes = findobj(userData.hFig,'Type','axes');
userData.hEndo = [];
userData.hEpi = [];
userData.hImPoly = [];
userData.hText = text(userData.hAxes, 1, 1, '', 'Color', 'red','verticalalignment', 'top', 'horizontalalignment','left');
userData.outputVariableName = outputVariableName;
userData.needsRefresh = true;
userData.isprocessing = false;

userData = redraw(userData);

set(userData.hFig, 'UserData', userData);
set(userData.hFig, 'WindowKeyPressFcn',@myKeyPressFcn)
set(userData.hFig, 'CloseRequestFcn',@myCloseRequestFcn)

    function myKeyPressFcn(this, evnt)
        ud = this.UserData;
        
        if ud.isprocessing, return, end
        ud.isprocessing = true; 
        set(ud.hFig, 'UserData', ud); % needed for the previous line to work
        
        keyPressed = evnt.Key;
        modifierPressed = evnt.Modifier;
        switch keyPressed
            
            case 'rightarrow'
                ud.currentImage = mod(ud.currentImage, ud.nImages) + 1;
                ud.needsRefresh = true;
                
            case 'leftarrow'
                ud.currentImage = mod(ud.currentImage - 2, ud.nImages) + 1;
                ud.needsRefresh = true;
                
            case '1'
                points = ud.contours.endo{ud.currentImage};
                if isempty(points)
                    ud.hImPoly = impoly;
                else
                    delete(ud.hEndo)
                    ud.hImPoly = impoly(ud.hAxes, points);
                    wait(ud.hImPoly);
                end
                points = ud.hImPoly.getPosition;
                
                ud.contours.endo{ud.currentImage} = points;
                ud.contoursInterp.endo{ud.currentImage} = points;
                
                if exist('interparc','file')
                    ud.contoursInterp.endo{ud.currentImage} = interparc(userData.nPontsInterp, [points(:,1); points(1,1)], [points(:,2); points(1,2)], 'spline');
                end

                delete(ud.hImPoly)
                ud.needsRefresh = true;
                
            case '2'
                points = ud.contours.epi{ud.currentImage};
                if isempty(points)
                    ud.hImPoly = impoly;
                else
                    delete(ud.hEpi)
                    ud.hImPoly = impoly(ud.hAxes, points);
                    wait(ud.hImPoly);
                end
                points = ud.hImPoly.getPosition;
                ud.contours.epi{ud.currentImage} = points;
                ud.contoursInterp.epi{ud.currentImage} = points;
                if exist('interparc','file')
                    ud.contoursInterp.epi{ud.currentImage} = interparc(userData.nPontsInterp, [points(:,1); points(1,1)], [points(:,2); points(1,2)], 'spline');
                end
                
                delete(ud.hImPoly)
                ud.needsRefresh = true;
                
            case 'c'
                if strcmp(modifierPressed, 'control') 
                    assignin('base', 'imToolRoiClipboard', ud);
                end
                
            case 'v'
                if strcmp(modifierPressed, 'control')
                    temp = evalin('base','imToolRoiClipboard');
                    if isfield(temp, 'contours')
                        if isfield(temp.contours, 'endo')
                            ud.contours.endo{ud.currentImage} = temp.contours.endo{temp.currentImage};
                            ud.contoursInterp.endo{ud.currentImage} = temp.contoursInterp.endo{temp.currentImage};
                        end
                        if isfield(temp.contours, 'epi')
                            ud.contours.epi{ud.currentImage} = temp.contours.epi{temp.currentImage};
                            ud.contoursInterp.epi{ud.currentImage} = temp.contoursInterp.epi{temp.currentImage};
                        end
                    end 
                    ud.needsRefresh = true;
                end
                
            case 'delete'
                ud.contours.endo = cell(1,ud.nImages);
                ud.contours.epi = cell(1,ud.nImages);
                ud.contoursInterp.endo = cell(1,ud.nImages);
                ud.contoursIntrep.epi = cell(1,ud.nImages);
                ud.needsRefresh = true;
        end
        
        ud = redraw(ud);
        ud.isprocessing = false;
        set(ud.hFig, 'UserData', ud);
             
    end

    function [ud] = redraw(ud)
        
        if ud.needsRefresh
            set(ud.hImage, 'CData', ud.data(:,:,ud.currentImage));
            
            % text
            ud.hText.String = sprintf('%d/%d',ud.currentImage,ud.nImages);
            
            % endo
            delete(ud.hEndo)
            endo = ud.contoursInterp.endo{ud.currentImage};
            if ~isempty(endo)
                hold(ud.hAxes, 'on') 
                ud.hEndo = line(ud.hAxes, [endo(:,1); endo(1,1)], [endo(:,2); endo(1,2)], 'Color', 'red');
                hold(ud.hAxes, 'off') 
            end
            
            % epi
            delete(ud.hEpi)
            epi = ud.contoursInterp.epi{ud.currentImage};
            if ~isempty(epi)
                hold(ud.hAxes, 'on') 
                ud.hEpi = line(ud.hAxes, [epi(:,1); epi(1,1)], [epi(:,2); epi(1,2)], 'Color', 'green');
                hold(ud.hAxes, 'off') 
            end
            
            ud.needsRefresh = false;
        end
    end

    function myCloseRequestFcn(this, evnt)
        ud = this.UserData;
        % save
        assignin('base', ud.outputVariableName, ud);
        % clear the clipboard data
        evalin( 'base', 'clear imToolRoiClipboard' )
        disp('Bye bye!')
        delete(ud.hFig)
    end

end