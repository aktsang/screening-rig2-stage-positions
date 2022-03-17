    %% look for spaces in construct list

    
    % Now that construct names are read and stored in refName, check for space
    % characters. Spaces are simply removed and text concatenated.
    
    % loop through all constructs
    for z = 1:size(refName,2)
        
        % initial assignment
        newrefName = refName{z};
        
        % create a logical array showing locations of spaces in the refName
        check_space{z} = isspace(refName{z});
        
        % generate an array showing locations of nonzero elements in
        % original name
        space_loc1= find(check_space{z});
        
        if size(space_loc1,2) > 0
            for za = 1:size(space_loc1,2)
                % locate spaces again as the string changes.
                space_loc2 = find(isspace(newrefName));
                if size(space_loc2,2) > 1
                    newrefName = eraseBetween(newrefName,space_loc2(za), space_loc2(za));
                else
                    newrefName = eraseBetween(newrefName,space_loc2, space_loc2);
                end
                operation_performed = 1;
            end
        else
            operation_performed = 0;
        end
        
        if operation_performed == 1
            refName{z} = newrefName;
        end
    end