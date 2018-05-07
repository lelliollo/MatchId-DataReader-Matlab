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
               DicOutput=obj.ReadDataFunction(obj.MiDCsvFile);
            end
         end
         %=================================================================
         function  DicMultOutput=ReadMultipleData(obj)
            if iscell(obj.MiDCsvFile)
               Nfiles=size(obj.MiDCsvFile,2);
               Rows=zeros(Nfiles,1);
               Cols=Rows;
               for i=1:Nfiles
                  disp(strjoin({'Reading file',obj.MiDCsvFile{i},'...'}))
                  DicLocOut=obj.ReadDataFunction(obj.MiDCsvFile{i});
                  [Rows(i),Cols(i)]=size(DicLocOut);
                  %Message if things are missing
                  if not(Rows(i)==Rows(1))
                       msgID = 'ReadMultipleData:InconsistentRows';
                       msg = strjoin({'The number of row data between DIC output files is different!',...
                           'Expected',num2str(Rows(1)),'rows, but got',num2str(Rows(i))});
                       warning(msgID,msg)
                  end
                  if not(Cols(i)==Cols(1))
                       msgID = 'ReadMultipleData:InconsistentCols';
                       msg = strjoin({'The number of column data between DIC output files is different!',...
                           'Expected',num2str(Cols(1)),'columns, but got',num2str(Cols(i))});
                       warning(msgID,msg)                      
                  end
                  CorrectOut=obj.CorrectMatrixSize(DicLocOut,Rows(1),Cols(1));
                  DicMultOutput(:,:,i)=CorrectOut;
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
            Nn=[];
            indx=1;
               %Read csv file and dump to buffer
                while not(feof(fID))
                    tline = fgetl(fID); %get line
                    LineCell=strsplit(tline,';'); %separate with semicol
                    Nn(indx)=size(LineCell,2)-1; %remember that last char is \n
                    pp=zeros(1,Nn(indx)); %initialize row scan
                    for kk=1:Nn(indx)
                        if strcmp(LineCell{kk},obj.NaNStrDesc) %parse NaN correctly
                            pp(kk)=NaN;
                        else
                            pp(kk)=obj.ReadNumberStringAsSystem(LineCell{kk}); %parse double correctly according to system separator
                        end
                    end
                    LineToStore=obj.CorrectArraySize(pp',Nn(1));
                    buf(indx,:)=LineToStore; %dump inside buffer
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
        function NewArray=CorrectArraySize(ParData,NLength)
            L=length(ParData);
            if isempty(ParData) % Throw exception cause data is empty
               NewArray=NaN(NLength,1);
               msgID = 'CorrectArraySize:EmptyData';
               msg = 'The data vector is empty.. replacing with NaNs';
               warning(msgID,msg)
            else
                if L<NLength
                    NewArray=padarray(ParData,[NLength-L 0],NaN,'post');
                    disp('pippo')
                elseif L==NLength
                    NewArray=ParData;
                elseif L>NLength
                    NewArray=ParData(1:NLength);
                end
            end
        end
        %=================================================================
        function NewMat=CorrectMatrixSize(MatDat,Rows,Cols)
            [m,n]=size(MatDat);
            if m>Rows
               IntMat=MatDat(1:Rows,:); 
            elseif m==Rows
               IntMat=MatDat;
            elseif m<Rows
               IntMat=padarray(MatDat,[Rows-m 0],NaN,'post');
            end
            if n>Cols
               NewMat=IntMat(:,1:Cols); 
            elseif n==Cols
               NewMat=IntMat;
            elseif n<Cols
               NewMat=padarray(IntMat,[0 Cols-n],NaN,'post');
            end
        end
    end
    
end

