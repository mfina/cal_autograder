function [] = student2txtfiles(assignment, student)

% find total points possible in this assignment
totalPoints = 0;
for p = 1:length(assignment.problem)
    for t = 1:length(assignment.problem(p).test)
        totalPoints = totalPoints + sum(assignment.problem(p).test(t).points);
    end
end

for s= 1:length(student)   
    
    % create a new text file for this student
    fid = fopen([student(s).student_name,'.txt'],'w');    
    
    % make function header
    fprintf(fid,'%s\n', student(s).student_name);
    fprintf(fid,'%s - %s\n', assignment.course, assignment.semester);
    fprintf(fid,'%s\n', assignment.professor);
    fprintf(fid,'Assignment #%d: %s\n\n', assignment.number, assignment.name);
    
    % designate total points of this student
    studentPoints = 0;
    
    % loop through problems
    for p = 1:length(assignment.problem)
        
        % print this problem title to text file
        fprintf(fid, 'Problem: %d\n\n', p);
       
        % problem points
        
        % check if this problem was not submitted, if not, then skip it
        switch student(s).results(p).status
            case 'not submitted'
                fprintf(fid,'\tNot Submitted or Incorrect Type Definition\n\n');
                continue
        end
        
        % if this problem was submitted, then loop through the test cases
        for t = 1:length(assignment.problem(p).test)
            
            % print this test case
            fprintf(fid,'\tTest %d.%d: %d/%d\n', p, t, sum(student(s).results(p).test(t).points), sum(assignment.problem(p).test(t).points));
            
            % increment student points
            studentPoints = studentPoints + sum(student(s).results(p).test(t).points);
            
        end
        
        fprintf(fid,'\n');
        
    end
    
    % print student final grade
    fprintf(fid, 'Total Score: %d/%d\n', studentPoints, totalPoints);
    
    % close file
    fclose(fid);
end

end % end student2txtfiles