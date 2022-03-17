%%  2019-09-07
%   Read CSV or Excel production sheet
%   Rig 1 and Rig 2 scripts only differ in stage position template used.

%   Rig 1: 'Pnumbera-date_CenterPositions80.STG'
%   Rig 2: 'Rig2_Pnumbera-date_CenterPositions80.STG'

%% OPEN GUI TO SELECT PRODUCTION SHEET FILE and enter Info

[filename, path, indx] = uigetfile(...
    {'*.csv';'*.xlsx';'*.xls';'*.*'},...
    'Select a .csv, .xlsx, or .xls file');

[check_filepath, check_name, check_ext] = fileparts(filename);
check_type = string(check_ext);

% input dialog section
prompt1 = {'Enter imaging date:', 'Enter protocol or project (e.g. ArcLight96f, iGABASnFR):',...
    'Enter the total number of plates in the production sheet:', 'Output Path: '};
title = 'Input information';
dims = [1 35];
definput = {'yyyymmdd','iGABASnFR','28','E:\_dataToday'};
answer = inputdlg(prompt1,title,dims,definput);

% 20190228-rig2modifications
answerDate = answer{1,1};
answerProt = answer{2,1};
answerPnum = answer{3,1};
answerPath = answer{4,1};

if isequal(filename, 0)
    disp('User selected Cancel')
else
    disp(['User selected ', fullfile(path, filename), ' and filter index: ', num2str(indx)])
end

% make container folder for plate folders

% destfolder = strcat(answer{1,1}, '_', answer{2,1}, '_raw');
destfolder = strcat(fullfile(answerPath, answerDate), '_', answerProt, '_raw');

% imagingfolder = string(fullfile(path,destfolder));
mkdir(destfolder);
disp(['Created folder: ', char(destfolder)])

% stage list container folder
% stagelistfolder = destfolder;
% mkdir(stagelistfolder);

% prompt2 = 'Number of complete 96-well plates (must have constructs in order)? ';
% plateNumber = input(prompt2);
plateNumber = str2num(answer{3,1});


% Loop through all plates.
for m=1:plateNumber
    
    % Read in CenterPositions.STG template file in text format.
    fid2 = fopen('Rig2_Pnumbera-date_CenterPositions80.STG');
    outputText = textscan(fid2,'%s','delimiter','\n');
    fclose(fid2);
    
    % Read in construct names from GECIpipelineoperations files in xlsx or
    % csv format.
    
    if check_type == ('.xlsx')
        wksheet ='Lentiviral Production and Infec';
        [ndata headertext] = xlsread(filename,wksheet);
    elseif check_type == '.csv'
        fid1 = fopen(filename);
        refText = textscan(fid1,'%s','delimiter','\n');
        refNumberOfLines = length(refText{1});
        fclose(fid1);
    else
        disp('File type not supported, or other violating condition ocurred')
        return;
    end
    
    % Get plate date in yyyymmdd format from GECIpipelineoperations file
    % name.
    plateDate=strcat('20',filename(3:8));
    
    % Get names of constructs in ###dot### format from
    % GECIpipelineoperations file.  Matlab will use first column.
    
    if check_type == '.xlsx'
        refName = headertext(3:end,1)';
    elseif check_type == '.csv'
        for i=1:refNumberOfLines-2
            commas=findstr(refText{1,1}{i+2,1},',');
            refName{i}=refText{1,1}{i+2,1}(1:commas(1)-1);
        end
    end
    
    %% look for spaces in construct list
    
    % Now that construct names are read and stored in refName, check for space
    % characters. Spaces are simply removed and text concatenated.
    
    % loop through all constructs
    for z = 1:size(refName,2)
        
        % initial assignment
        newrefName = refName{z};
        
        % create a logical array showing locations of spaces in the refName
        % 0 means not a space
        % 1 means it is a space.
        check_space{z} = isspace(refName{z});
        
        % find the indexes of 1's in check_space{z}. The values here show
        % the character positions of spaces in the string. The size of this
        % array indicates the number of spaces found.
        space_loc1= find(check_space{z});
        
        % find() returns a null array if it finds no non-zero values, and
        % an array of size >= 1 if it finds non-zero values.
        if size(space_loc1,2) > 0
            % iterate for the number of spaces found
            for za = 1:size(space_loc1,2)
                % locate spaces again as the string changes.
                space_loc2 = find(isspace(newrefName));
                % delete the first space found on each iteration
                newrefName = eraseBetween(newrefName,space_loc2(1), space_loc2(1));
            end
            refName{z} = newrefName;
        end
        % convert Teonly, teonly, TeOnly, TEonly, to 'TEOnly'
        check_teonly = string(refName{z});
        if check_teonly == 'teonly' | check_teonly == 'Teonly' | ...
                check_teonly == 'TEonly' | check_teonly == 'TeOnly'
            
            refName{z} = 'TEOnly';
        end
    end
    
    % Get a list of the first or next 24 construct names.  Make a linear
    % vector of the 24 construct names repeated 4 and 4 times.
    subsetRefName1 = repmat(refName(((m-1)*24)+1:((m-1)*24)+12),1,8);
    subsetRefName2 = repmat(refName(((m-1)*24)+13:((m-1)*24)+24),1,8);
    
    % Replace the wildcard text in the CenterPositions.STG file with the
    % construct names, line by line.
    for j=1:48
        outputText{1,1}{j+4,1} = strrep(outputText{1,1}{j+4,1}, 'wildcard', subsetRefName1{1,j});
    end
    for j=49:96
        outputText{1,1}{j+4,1} = strrep(outputText{1,1}{j+4,1}, 'wildcard', subsetRefName2{1,j});
    end
    
    % Remove empty lines
    outputText{1,1}{1+4,1} = '';
    outputText{1,1}{12+4,1} = '';
    outputText{1,1}{13+4,1} = '';
    outputText{1,1}{24+4,1} = '';
    outputText{1,1}{25+4,1} = '';
    outputText{1,1}{36+4,1} = '';
    outputText{1,1}{37+4,1} = '';
    outputText{1,1}{48+4,1} = '';
    outputText{1,1}{49+4,1} = '';
    outputText{1,1}{60+4,1} = '';
    outputText{1,1}{61+4,1} = '';
    outputText{1,1}{72+4,1} = '';
    outputText{1,1}{73+4,1} = '';
    outputText{1,1}{84+4,1} = '';
    outputText{1,1}{85+4,1} = '';
    outputText{1,1}{96+4,1} = '';
    
    outputText{1,1}=reshape(outputText{1,1}(~cellfun(@isempty,outputText{1,1})),1,[])';
    
    % Reformat the plate number.
    plateNumberString = num2str(m);
    
    % Save the new CenterPositions.STG file without overwriting the
    % template file.
    
    stagelist = fullfile(destfolder,['P' plateNumberString 'a-' plateDate '_CenterPositions.STG']);
    
    %     myfile =fopen(['P' plateNumberString 'a-' plateDate '_CenterPositions.STG'],'w');
    myfile = fopen(stagelist, 'w');
    
    for k=1:4
        fprintf(myfile,'%s',char(outputText{1,1}(k)));
        fprintf(myfile,'\r\n');
    end
    for n=5:84
        fprintf(myfile,'%s',char(outputText{1,1}{n,1}));
        fprintf(myfile,'\r\n');
    end
    fclose(myfile);
    
    disp(['Created stage position list: ', char(stagelist)])
    
    %     mkdir (['P' plateNumberString 'a-' plateDate '_ArcLight96f']);
    imFolderName = strcat('P',plateNumberString,'a-',plateDate, '_', answer{2,1});
    plateFolderPath = fullfile(destfolder, imFolderName);
    mkdir(plateFolderPath);
    disp(['Created folder: ', char(plateFolderPath)])
    
end