clear all
close all
clc
%% Read csv dir
dirlist=dir('test_data\*.csv');
Nf=size(dirlist,1);

for i=1:Nf
   DicFiles{i}=strcat(dirlist(i).folder,'\',dirlist(i).name); 
end


%% Create class instance
MiDReadHandle=MatchIDdataReader(DicFiles);
DicData=MiDReadHandle.ReadMultipleData();