% 1. Load data from a file
% Change 'your_file.mat' to the actual name of your file
data = load('pos1_T37.mat');

% 2. Get the list of variables in the file
fields = fieldnames(data);
fprintf('The file contains the following top-level variables:\n');
disp(fields);

% 3. Function for deep inspection (prints nested structures)
inspectStructure(data, '');

function inspectStructure(S, prefix)
    % Get the field names of the current structure
    fields = fieldnames(S);

    for i = 1:length(fields)
        fieldName = fields{i};
        val = S.(fieldName);
        fullPath = [prefix, fieldName];

        % Print info about the current field
        fprintf('Path: %-25s | Type: %-10s | Size: %s\n', ...
            fullPath, class(val), mat2str(size(val)));

        % If the field is itself a structure, recurse deeper
        if isstruct(val)
            inspectStructure(val, [fullPath, '.']);
        end
    end
end
