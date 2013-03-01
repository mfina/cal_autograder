function responseSummary(ArrayStudents, LabX, labNoStr)

%remove special characters in LabX.assignment name
if length(LabX.assignmentName) == 1
    xlsName = [regexprep(LabX.assignmentName{1},'[^\w]','') , '.xlsx'];
else
    xlsName = ['Lab' labNoStr '_response_summary.xlsx']
end
% xlsName = [regexprep(ArrayStudents(1).studentSubmittedProblems{1}.problemDisplayName,'[^\w]','') , 'C.xls'];

numStudents = length(ArrayStudents);
numProblems = length(LabX.assignmentProblems);

% 3 columns with { SID | LAST NAME | FIRST NAME }
studentsColumn = {'SID', ArrayStudents.studentSID; 'LAST NAME', ArrayStudents.studentLastName; 'FIRST NAME', ArrayStudents.studentFirstName}';

delete(fullfile(pwd,xlsName));

%initialize spreadsheet to have as many sheets as problems
for P = 1:numProblems
    xlswrite(xlsName, studentsColumn, LabX.assignmentProblems{P}.problemFileName);
end

try
    
    [hactx, wb] = xlsinit(xlsName);
    
    for P = 1:numProblems
        
        numTestCases = length(LabX.assignmentProblems{P}.problemTestCases);
        sheetName = LabX.assignmentProblems{P}.problemFileName;
        
        freshSheet = ones(1,numTestCases);
        
        for S = 1:numStudents
            
            cellCol = 3;
            
            stud = ArrayStudents(S);
            
            if (stud.studentSubmittedProblems{P}.isProblemSubmitted == 1) & (strcmp(stud.studentGradedProblems{P}.problemStatus, 'GRADED')) & strcmpi(stud.studentSubmittedProblems{P}.problemFileName, sheetName)
                
                for T = 1:numTestCases
                    
                    if freshSheet(T) == 1;
                        tcName = stud.studentGradedProblems{P}.problemTestCaseResults{T}.originalTestCase.testCaseName;
                        range = sub2excel(1,cellCol + 1);
                        xlscolor(hactx, wb, xlsName, tcName, range, 'w', sheetName);
                        freshSheet(T) = 0;
                    end
                    
                    cellColor = 'r';
                    
                    maxTCPoints = stud.studentGradedProblems{P}.problemTestCaseResults{T}.originalTestCase.testCasePoints;
                    stuPoints = stud.studentGradedProblems{P}.problemTestCaseResults{T}.pointsAwarded;
                    
                    stuResponses = stud.studentGradedProblems{P}.problemTestCaseResults{T}.studentOutput;
                    
                    if (all(maxTCPoints == stuPoints)) & (sum(maxTCPoints ~= 0))
                        cellColor = 'g';
                        
                    elseif sum(maxTCPoints == 0)
                        cellColor = 'b';
                    end       
                    
                    if strcmpi(class(stuResponses), 'MException') %student error handling
                        stuResponses = {stuResponses.message};
                    end
                    
                    for R = 1:length(stuResponses)
                        
                        stuResponse = cprintf(stuResponses{R});
                        
                        if size(stuResponse,2) > 100
                            stuResponse = stuResponse(:,1:100);
                        end
                        
                        range = sub2excel(S+1, cellCol + 1);
                        
                        xlscolor(hactx, wb, xlsName, stuResponse, range, cellColor, sheetName);
                        
                        cellCol = cellCol + 1;
                        
                    end %stuResponses Cycle
                    
                end %cycle TCs
                
            else %not submitted
                
                range = sub2excel(S+1, cellCol + 1);
                
                xlscolor(hactx, wb, xlsName, '*Not Submitted*', range, 'y', sheetName);
                
            end %if submitted
            
        end %cycle through students
        
    end
    
catch
    
    status = xlsclose(hactx, wb, xlsName);
    error('Unable to continue generating responseSummary spreadsheet. Grades.csv and ScoreSummary spreadsheets are okay!')
%     keyboard
    
end

status = xlsclose(hactx, wb, xlsName);

end


%% subfunctions xlsinit, xlsclose, xlscolor, sub2excel


function [hactx, wb] = xlsinit(xlsName)


file = fullfile(pwd, xlsName);

%Open COM connection to Excel
hactx = actxserver('excel.application');

%Make excel hide alerts
set(hactx, 'DisplayAlerts', 0);

%Create the spreadsheet
wb = hactx.WorkBooks.Open(file);

sheets = hactx.ActiveWorkBook.Sheets;

%Remove "Sheet1" through "Sheet3" in workbook
for i = 1:2
    sheet = get(sheets,'Item',i);
    invoke(sheet,'Delete');
end

end

function [status] = xlsclose(hactx, wb, file)

%Obtain the full path name of the file
file = fullfile(pwd, file);

status = 0;

wb.SaveAs(file);
wb.Saved = 1;
wb.Close;
hactx.Quit;
hactx.delete;

status = 1;

end

function xlscolor(hactx, wb, file, data, range, BGcolor, sheetName)
% color = 'r' | 'g' | 'y' | 'b'

%Obtain the full path name of the file
file = fullfile(pwd, file);

%Select the appropriate range
sheets = hactx.ActiveWorkBook.Sheets;
sheet = get(sheets,'Item',sheetName);
invoke(sheet, 'Activate');
% hactx.Activesheet.name = sheetName;
ran = hactx.Activesheet.get('Range',range);

%write the data to the range
ran.value = data;

%The color is specified as an BGR triplet in hexadecimal notation
%RED = 0000FF
%BLUE= FF00FF
%GREEN=00FF00
%BLACK=000000
%WHITE=FFFFFF
switch lower(BGcolor)
    case 'r'
        colorHex = '0000FF';
    case 'g'
        colorHex = '00FF00';
    case 'y'
        colorHex = 'EEEE00';
    case 'b'
        colorHex = 'FF00FF';
    case 'w'
        colorHex = 'FFFFFF';
    otherwise
        error('BGcolor must be ''r'' ''g'' ''y'' ''w'' or ''b''')
        
end

ran.interior.Color=hex2dec(colorHex);
% ran.font.Color=hex2dec('FF0000'); %Blue


end

function alphaN = sub2excel(r, c)
% Converts (row, column) to 'alphaColumn' excel format
%   ex: (2,6) -> 'F2'

indx = [floor((c - 1)/26) + 64, rem(c - 1, 26) + 65];

if(indx(1) < 65)
    indx(1) = [];
end

%ASCII <3
alphaN = [char(indx), num2str(r)];

end