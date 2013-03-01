function RunInfiniteLoop(obj, event)
    
    obj
    event

    I = 0;

    display('Entering while loop');
    
    while I < 10
        
        display(I);
        I = I + 1;
        pause(1);
        
    end
    
end