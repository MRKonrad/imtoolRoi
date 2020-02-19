%% EXAMPLE OF USE:

%% prepare data
load mri;
D3D = squeeze(D); % 3dims not 4

%% prepare matlab path (you can manually add imtoolRoi to matlab path)
addpath(genpath('.'))

%% run
hFig = imtoolRoi(D3D, 'outputSavedHere.mat');