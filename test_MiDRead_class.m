clear all
close all
clc
warning on
%Script to test the matchId reader class. - A. Lavatelli - 2018

%% Read csv dir
dirlist=dir('test_data_g2\*.csv');
Nf=size(dirlist,1);

for i=1:Nf
   DicFiles{i}=strcat(dirlist(i).folder,'\',dirlist(i).name); 
end

%%  Create class instance and read a single file
%create class instance with a single file name and its handle
MiDReadHandle=MatchIDdataReader(DicFiles{1});
MiDReadHandle.SetNaNString('Non un numero reale');
%read data
DicDataSingle=MiDReadHandle.ReadData();
%plot
figure
imagesc(DicDataSingle)
%% Read data from a file list
%tell the class to use a list of files
MiDReadHandle.SetFileName(DicFiles);
%read data
DicDataMult=MiDReadHandle.ReadMultipleData();
%plot them
figure
for i=1:Nf
   subplot(1,Nf,i)
   imagesc(DicDataMult(:,:,i))
   axis equal
end