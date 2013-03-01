function [studentFirstName, studentLastName, studentID] = ParseStudentFolder(studentPath)

studentLastName = regexp(studentPath, '\,', 'split');

studentFirstName = regexp(cell2mat(studentLastName(2)), '\(', 'split');

studentLastName = cell2mat(studentLastName(1));

studentID = regexp(cell2mat(studentFirstName(2)), '\)', 'split');

studentFirstName = cell2mat(regexp(cell2mat(studentFirstName(1)), ' ', 'split'));

studentID = str2double(cell2mat(studentID(1)));

end