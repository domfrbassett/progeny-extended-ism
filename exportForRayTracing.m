function exportForRayTracing(image_sources, vertices, all_faces, P, L, h_os, ... 
    absorption_profiles, face_profile_indices, ... 
    preDelayTime)

    c = 343;  % Speed of sound in m/s
    
    % Process geometry
    roomData.vertices = vertices;
    roomData.faces = cellfun(@(f) f(:)', all_faces, 'UniformOutput', false);
    roomData.material_indices = face_profile_indices;
    roomData.absorption_profiles = absorption_profiles;
    
    % Source and listener
    roomData.source = P;
    roomData.listener = L;

    % Process image source data
    numSources = numel(image_sources);
    isData = struct([]);
    for i = 1:numSources
        s = image_sources(i);
        isData(i).index = s.index;
        isData(i).order = s.order;
        isData(i).position = s.position;
        isData(i).parent_index = s.parent_index;
        isData(i).created_by = s.created_by;
        
        d = norm(s.position - L);  % Distance
        isData(i).path_length = d;
        isData(i).arrival_time = d / c;
        isData(i).amplitudes = h_os(i,:);  % Energy across bands
    end

    roomData.image_sources = isData;
    roomData.pre_delay_seconds = preDelayTime;

    % Ask for file path
    [file, path] = uiputfile('early_reflections.json', 'Save ISM Export File');
    if isequal(file, 0)
        disp('Export cancelled.');
        return;
    end
    
    % Encode and write to JSON
    jsonStr = jsonencode(roomData, 'PrettyPrint', true);
    fid = fopen(fullfile(path, file), 'w');
    fwrite(fid, jsonStr, 'char');
    fclose(fid);
    
    msgbox('Export complete!', 'Success');
end