classdef MatchIDdataReader < handle
    %MatchIDReader - Matlab class to read the .csv matrix output generated
    %by the Digital Image Correlation (DIC) software MatchId
    %<https://www.matchidmbc.be/>
    %
    %Copyright - 2018 - Alberto Lavatelli <alberto.lavatelli@polimi.it> 
    %
    %Initialize class in this way:
    %        MiDReaderHandle=MatchIDdataReader('filename.csv')
    %the file name can be given as full path or local name. It can be a
    %single string or a cell array {1XN} of strings. 
    %
    %Method(s):
    %   ReadData() ---> it reads the csv file and returns a matrix. The
    %                   usage is quite simple: Mat= MiDReaderHandle.ReadData()
    %   ReadMultipleData() ---> it reads a list of csv file and returns a (MxNxJ)matrix. The
    %                   usage is quite simple: Mat= MiDReaderHandle.ReadMultipleData()
    %   SetFileName(path) ---> methods to change file(s) name you are
    %                          working on
    %   SetNaNString(string)--> you can put a custom NaN string          
    %
    % ==========================================================================
    % LICENSE and WARRANTY
    %    This program is free software: you can redistribute it and/or modify
    % it under the terms of the GNU General Public License as published by
    % the Free Software Foundation, either version 3 of the License, or
    % (at your option) any later version.
    %
    % This program is distributed in the hope that it will be useful,
    % but WITHOUT ANY WARRANTY; without even the implied warranty of
    % MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    % GNU General Public License for more details.
    %
    % You should have received a copy of the GNU General Public License
    % along with this program.  If not, see <https://www.gnu.org/licenses/>.
    
    properties
        MiDCsvFile %property to store filename data
        NaNStrDesc %property to store NaN string descriptor
    end
    
    methods (Access=public)
        %% Constructor
        %=================================================================
         function obj=MatchIDdataReader(filename)
             %Constructor of MatchIDdataReader class. Class is built upon
             %matrix csv output file name.
            obj.MiDCsvFile=filename;
            %get system NaN and write to properties
            NET.addAssembly('System.Globalization');
            RegClass=System.Globalization.NumberFormatInfo;
            obj.NaNStrDesc=RegClass.NaNSymbol.char;
         end
         %% Data read functions
         %=================================================================
         function DicOutput=ReadData(obj) %throw exception if you have multiple files
            if iscell(obj.MiDCsvFile)
               msgID = 'ReadData:MultipleFiles';
               msg = 'You cannot use read on multiple files. Try ReadMultipleData()';
               SingleFileException = MException(msgID,msg);
               throw(SingleFileException);
               DicMultOutput=zeros(2,2,2);
            else
                    %open csv file in read mode
                    fID=fopen(obj.MiDCsvFile,'r') ;
                    %initialize data
                    buf=[];
                    indx=1;
                       %Read csv file and dump to buffer
                        while not(feof(fID))
                            tline = fgetl(fID); %get line
                            LineCell=strsplit(tline,';'); %separate with semicol
                            Nn=size(LineCell,2)-1; %remember that last char is \n
                            pp=zeros(1,Nn); %initialize row scan
                            for kk=1:Nn
                                if strcmp(LineCell{kk},obj.NaNStrDesc) %parse NaN correctly
                                    pp(kk)=NaN;
                                else
                                    pp(kk)=obj.ReadNumberStringAsSystem(LineCell{kk}); %parse double correctly according to system separator
                                end
                            end
                            buf(indx,:)=pp'; %dump inside buffer
                            indx=indx+1;
                        end
                    fclose(fID);
                    DicOutput=buf; %dummy move, but nice to see
            end
         end
         %=================================================================
         function  DicMultOutput=ReadMultipleData(obj)
            if iscell(obj.MiDCsvFile)
               Nfiles=size(obj.MiDCsvFile,2);
               for i=1:Nfiles
                  disp(strjoin({'Reading file',obj.MiDCsvFile{i},'...'}))
                  DicMultOutput(:,:,i)=obj.ReadDataFunction(obj.MiDCsvFile{i});
               end
               
            else %throw exception if you have only one file
               msgID = 'ReadMultipleData:SingleFile';
               msg = 'You cannot use multiple read on a single file. Try ReadData()';
               SingleFileException = MException(msgID,msg);
               throw(SingleFileException);
               DicMultOutput=zeros(2,2,2);
            end
         end
         %=================================================================
         %% Set property functions
         %=================================================================
         function obj=SetFileName(obj,path)
             %Method to manipulate the path of the csv to read
            obj.MiDCsvFile=path; 
         end
         %=================================================================
         function obj=SetNaNString(obj,CustomNanString)
             %Method to manipulate the nan string
            obj.NaNStrDesc=CustomNanString;
         end
         %=================================================================
    end
    %% Private stuffs
    methods(Access=private)
        %=================================================================
        function DicOutputSingle=ReadDataFunction(obj,CustomFileName)
            %open csv file in read mode
            fID=fopen(CustomFileName,'r') ;
            %initialize data
            buf=[];
            indx=1;
               %Read csv file and dump to buffer
                while not(feof(fID))
                    tline = fgetl(fID); %get line
                    LineCell=strsplit(tline,';'); %separate with semicol
                    Nn=size(LineCell,2)-1; %remember that last char is \n
                    pp=zeros(1,Nn); %initialize row scan
                    for kk=1:Nn
                        if strcmp(LineCell{kk},obj.NaNStrDesc) %parse NaN correctly
                            pp(kk)=NaN;
                        else
                            pp(kk)=obj.ReadNumberStringAsSystem(LineCell{kk}); %parse double correctly according to system separator
                        end
                    end
                    buf(indx,:)=pp'; %dump inside buffer
                    indx=indx+1;
                end
            fclose(fID);
            DicOutputSingle=buf; %dummy move, but nice to see
         end
    end
    %=================================================================
    methods (Static,Access=private)
        %=================================================================
        function SysDoub=ReadNumberStringAsSystem(NumStr)
            nf = java.text.DecimalFormat;
            SysDoub=nf.parse(NumStr).doubleValue;
            clear('nf')
        end
        %=================================================================
    end
    
end

