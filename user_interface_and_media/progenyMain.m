clc; clear;

% Splash Screen
splashFig = figure('Name', 'Room Geometry Tool', ...
    'NumberTitle', 'off', ...
    'MenuBar', 'none', ...
    'ToolBar', 'none', ...
    'Color', 'white', ...
    'Position', [500 400 600 450]);

[img, map, lengths] = imread('progenytitle.png');
mask = double(lengths) / 255;

% Display
axes('Parent', splashFig, 'Position', [0.1 0.78 0.8 0.15]);
imshow(img, 'InitialMagnification', 'fit');

hImg = findobj(gca, 'Type', 'image');
set(hImg, 'AlphaData', mask);
axis off;

% About Text
aboutText = {
    'This software is based on Jeffrey Borish’s 1984 pseudocode ''Extension of the Image Model to Arbitrary Polyhedra'', and makes it possible to model early reflections in convex polygonal extrusions. It is best used in conjunction with ray tracing and statistical decay models.'
    ''
    'The application can assist in reconstructing a closed polygonal geometry from a set of angular constraints and n-2 fixed side lengths. The algorithm that achieves this was contributed by Daniel Bold of Trinity College, Oxford.'
    ''
    'If you have any queries, please email dominicbassett04@gmail.com.';
};

uicontrol('Style', 'text', ...
    'Parent', splashFig, ...
    'String', aboutText, ...
    'FontSize', 11, ...
    'ForegroundColor', [0.1 0.2 0.3], ...
    'BackgroundColor', 'white', ...
    'Units', 'normalized', ...
    'Position', [0.08 0.35 0.84 0.35], ...
    'HorizontalAlignment', 'left');

setappdata(splashFig, 'Continue', false);

% Continue Button
uicontrol('Style', 'pushbutton', ...
    'Parent', splashFig, ...
    'String', 'Continue', ...
    'FontSize', 12, ...
    'FontWeight', 'bold', ...
    'BackgroundColor', [0.1 0.2 0.3], ...
    'ForegroundColor', 'white', ...
    'Units', 'normalized', ...
    'Position', [0.4 0.12 0.2 0.08], ...
    'Callback', @(src,~) uiresume(gcbf));


% BCU Logo

img = imread('birmingham-city-university-5152_list.png');
mask = ~(img(:,:,1) < 10 & img(:,:,2) < 10 & img(:,:,3) < 10);
axes('Parent', splashFig, 'Position', [0.7 0.01 0.25 0.15]);
imshow(img, 'InitialMagnification', 'fit');
hold on;

% Overlay alpha mask
hImg = findobj(gca, 'Type', 'image');
set(hImg, 'AlphaData', double(mask));
axis off;

uiwait(splashFig);
close(splashFig);

% Clear old source/listener/image source data from base workspace if they exist
if evalin('base', 'exist(''final_source_position'', ''var'')')
    evalin('base', 'clear final_source_position');
end
if evalin('base', 'exist(''final_listener_position'', ''var'')')
    evalin('base', 'clear final_listener_position');
end
if evalin('base', 'exist(''image_sources'', ''var'')')
    evalin('base', 'clear image_sources');
end

prompt = {'Please give your project title:'};
dlgTitle = 'User Input';
numLines = [1 40];
defaultAnswer = {'My Room'};

answer = inputdlg(prompt, dlgTitle, numLines, defaultAnswer);

if ~isempty(answer)
    userText = answer{1};
else
    userText = 'Untitled Room';
end

shapeConfirmed = false;

while ~shapeConfirmed

    useSolver = questdlg('Use polygon solver to generate shape?', ...
                         'Polygon Solver Option', ...
                         'Yes', 'No', 'Yes');
    
    if strcmp(useSolver, 'Yes')
    
        validAngles = false;

        while ~validAngles
            anglePrompt = sprintf(['Enter turn angles in degrees:\n' ...
                '- One angle per segment (before moving forward)\n' ...
                '- Winding direction: anticlockwise (left turns)\n\n' ...
                'Example: 81.3, 98.4, 108.7, 71.6']);
            
            angleStr = inputdlg(anglePrompt, ...
                                'Turn Angles (Left Turns, Degrees)', ...
                                [5 60], {'81.3, 98.4, 108.7, 71.6'});
        
            if isempty(angleStr)
                msgbox('Simulation cancelled by user.', 'Cancelled', 'warn');
                return; 
            end
            
            turns = str2num(angleStr{1});
        
            if isempty(turns)
                errordlg('Invalid input for turn angles. Please enter numeric values separated by commas.', 'Input Error');
                return;
            end
    
            numTurns = length(turns);
            if numTurns < 3
                notEnoughAngles = errordlg('You must enter at least 3 angles.', 'Input Error');
                uiwait(notEnoughAngles);
            else
                validAngles = true;
            end
        end

        prompt = cell(1, numTurns);
        default_vals = repmat({''}, 1, numTurns);

        if numTurns == 4
            default_vals{1} = '12.08';  % First side
            default_vals{4} = '5.08';   % Last side
        end

        for i = 1:numTurns
            prompt{i} = sprintf('Side %d length (leave blank if unknown):', i);
        end

        validInput = false;

        while ~validInput

            side_input = inputdlg(prompt, 'Side lengths', [1 50], default_vals);
    
            if isempty(side_input)
                msgbox('Simulation cancelled by user.', 'Cancelled', 'warn');
                return;
            end
            
            side_lengths = NaN(1, numTurns);
    
            for i = 1:numTurns
                valStr = strtrim(side_input{i});
                if isempty(valStr)
                    side_lengths(i) = NaN;
                else
                    val = str2double(valStr);
                    if ~isnan(val)
                        side_lengths(i) = val;
                    end
                end
            end

            numUnknown = sum(isnan(side_lengths));
    
            if numUnknown > 2
                notenough = errordlg('Insufficient side lengths provided. Please retry.', 'Input Error.');
                uiwait(notenough);
            else
                validInput = true;
            end
        end

        try
        
            all_lengths = close_polygon(turns, side_lengths);
            [corrected_sides, headings] = correct_sides(turns, all_lengths);
            lengths = corrected_sides;
        catch ME
            errordlg(['Error solving polygon: ' ME.message], 'Solver Error');
        end
    
    else
        % Prompt for turn angles
        anglePrompt = sprintf(['Enter turn angles in degrees:\n' ...
            '- One angle per segment (before moving forward)\n' ...
            '- Winding direction: anticlockwise (left turns)\n\n' ...
            'Example: 81.3, 98.4, 108.7, 71.6']);
    
        angleStr = inputdlg(anglePrompt, ...
                            'Turn Angles (Left Turns, Degrees)', ...
                            [5 60], {'81.3, 98.4, 108.7, 71.6'});
    
        if isempty(angleStr)
                msgbox('Simulation cancelled by user.', 'Cancelled', 'warn');
                return; 
        end
    
        turns = str2num(angleStr{1}); %#ok<ST2NM>
    
        if isempty(turns)
            errordlg('Invalid input for turn angles. Please enter numeric values separated by commas.', 'Input Error');
            continue;
        end
    
        % Prompt for segment lengths
        sidePrompt = sprintf(['Enter corresponding side lengths (same number as turn angles):\n' ...
                              'Example: 12.08, 10.91, 12.65, 5.08']);
        
        lengthStr = inputdlg(sidePrompt, ...
                             'Side Lengths', ...
                             [3 60], {'12.08, 10.91, 12.65, 5.08'});
    
        if isempty(lengthStr)
                msgbox('Simulation cancelled by user.', 'Cancelled', 'warn');
                return; 
        end
    
        lengths = str2num(lengthStr{1});
    
        if isempty(lengths) || length(lengths) ~= length(turns)
            errordlg('Number of side lengths must match number of turn angles, and all values must be numeric.', 'Input Error');
            continue;
        end
    
        while true
        leastSquares = questdlg( ...
            'Would you like to apply a constrained least-squares adjustment to correct side lengths and close the polygon?', ...
            'Polygon Adjustment', ...
            'Yes', 'No', 'Info', ...
            'Yes');  % Default is 'Yes'
    
            switch leastSquares
                case 'Yes'
                    [corrected_sides, headings] = correct_sides(turns, lengths);
                    lengths = corrected_sides;
    
                    N = length(lengths);
                    x = zeros(N+1, 1);
                    y = zeros(N+1, 1);
                    for i = 1:N
                        x(i+1) = x(i) + lengths(i) * cos(headings(i));
                        y(i+1) = y(i) + lengths(i) * sin(headings(i));
                    end
                
                    closure_error = sqrt((x(end) - x(1))^2 + (y(end) - y(1))^2);
                    tolerance = 1e-6;
    
                    if closure_error < tolerance
                        msg = sprintf('Polygon successfully closed.');
                        mg = msgbox(msg, 'Closure Check');
                        uiwait(mg);
                    else
                        msg = sprintf('Polygon did NOT close properly! This indicates residual measurement or rounding error.');
                        mg= errordlg(msg, 'Closure Check');
                        uiwait(mg);
                    end
    
                    break;
        
                case 'No'
                    uiwait(errordlg(['You have chosen to skip the least-squares adjustment.' newline newline ...
                              'Be aware: the polygon may not close properly. ', ...
                              'This can lead to critical errors in the geometry, image source generation, or reflection paths. ', ...
                              'Only continue if you''re confident your measurements are correct.'], ...
                             'Adjustment Skipped – Proceed With Caution'));
                    break;
        
                case 'Info'
                    uiwait(helpdlg( ...
                        ['Applies a constrained least-squares adjustment to close a polygon when side lengths contain minor measurement inaccuracies.' newline newline ...
                         'What it does:' newline ...
                         '- Fixes all turn angles' newline ...
                         '- Fixes the first side length' newline ...
                         '- Minimally adjusts the others to achieve closure'], ...
                        'About Least-Squares Polygon Adjustment'));
                    % After Info, loop continues to re-ask the question
            end
        end
    end
    
    % Initialise arrays
        x = zeros(1, 5);
        y = zeros(1, 5);
        angle = 0;  % Start facing along 0 degrees (east)
            
        % Walk through each segment
        for i = 1:4
            angle = angle + turns(i);  % update angle by turning left
            x(i+1) = x(i) + lengths(i) * cosd(angle);
            y(i+1) = y(i) + lengths(i) * sind(angle);
        end
    
    % Define extrusion height
    heightPrompt = {'Enter extrusion height (in meters):'};
    heightTitle = 'Extrusion Height';
    heightDefault = {'7.5'};
    
    heightAnswer = inputdlg(heightPrompt, heightTitle, [1 40], heightDefault);
    
    if isempty(heightAnswer)
        errordlg('No extrusion height entered. Simulation cancelled.', 'Input Error');
        return;
    end
    
    height = str2double(heightAnswer{1});
    
    if isnan(height) || height <= 0
        errordlg('Invalid height. Please enter a positive numeric value.', 'Input Error');
        return;
    end
    
    % Create bottom and top faces
    z_bottom = zeros(size(x));
    z_top = height * ones(size(x));
    
    % 3D Plotting
    figure;
    hold on;
    
    % Plot vertical sides (walls)
    for i = 1:4
        fill3([x(i), x(i+1), x(i+1), x(i)], ...
              [y(i), y(i+1), y(i+1), y(i)], ...
              [z_bottom(i), z_bottom(i+1), z_top(i+1), z_top(i)], ...
              [0.8 0.8 1]);  % Light blue
    end
    
    % Plot top face
    fill3(x, y, z_top, [0.6 0.6 0.9]);
    
    % Plot bottom face
    fill3(x, y, z_bottom, [0.3 0.3 0.6]);
    
    axis equal;
    xlabel('X (m)');
    ylabel('Y (m)');
    zlabel('Z (m)');
    title(userText);
    view(3);
    grid on;
    
    % Visual confirmation prompt
    choice = questdlg('Does the 3D room shape look correct?', ...
        'Model Confirmation', ...
        'Yes, continue', 'No, I need to fix it', 'Yes, continue');
    
    switch choice
        case 'Yes, continue'
            % Proceed
            shapeConfirmed = true;
            % uiresume(gcf);
            close(gcf);
        case 'No, I need to fix it'
            close(gcf);
    end
end

% Compute geometry for face normals
num_points = length(x);
floor_vertices = [x(:), y(:), z_bottom(:)];
ceiling_vertices = [x(:), y(:), z_top(:)];
vertices = [floor_vertices; ceiling_vertices];
roomCentre = mean(vertices, 1);

% Wall faces
faces = zeros(4, 4);
for i = 1:4
    j = mod(i,4) + 1;
    faces(i,:) = [i, j, j+num_points, i+num_points];
end

% All face vertex lists
wall_face_cells = mat2cell(faces, ones(4,1), 4);
floor_face_cell = {fliplr(1:num_points)};
ceiling_face_cell = {(1:num_points) + num_points};
all_faces = [wall_face_cells; floor_face_cell; ceiling_face_cell];
numFaces = numel(all_faces);

% Face centres and normals
all_centres = zeros(numFaces, 3);
all_normals = zeros(numFaces, 3);

for i = 1:numFaces
    idx = all_faces{i};
    pts = vertices(idx, :);
    fc = mean(pts, 1);
    v1 = pts(2,:) - pts(1,:);
    v2 = pts(3,:) - pts(1,:);
    n = cross(v1, v2);
    n = n / norm(n);
    if dot(n, roomCentre - fc) < 0
        n = -n;
    end
    all_centres(i, :) = fc;
    all_normals(i, :) = n;
end

% Call interactive GUI to place Source and Listener
% Loop until user confirms correct placement
confirmed = false;

while ~confirmed
    % Ask user how they want to place the source/listener
    placementMethod = questdlg( ...
        'How would you like to place the source and listener?', ...
        'Placement Method', ...
        'Interactive GUI', 'Manual Input', 'Interactive GUI');

    % If user closed the dialog (pressed X), end the script
    if isempty(placementMethod)
        msgbox('Simulation cancelled by user.', 'Cancelled', 'warn');
        return;
    end

    switch placementMethod

        case 'Interactive GUI'
            % Launch interactive placement
            interactiveRoom(vertices, roomCentre, height, x, y);
            uiwait(gcf);  % Wait until user closes picker

            % Get positions from base workspace
            if evalin('base', 'placement_confirmed')
                P = evalin('base', 'final_source_position');
                L = evalin('base', 'final_listener_position');
                confirmed = true;
            else
                msgbox('Simulation cancelled by user.', 'Cancelled', 'warn');
                return;
            end

        case 'Manual Input'
            % Ask for manual entry
            prompt = {'Source X:', 'Source Y:', 'Source Z:', ...
                      'Listener X:', 'Listener Y:', 'Listener Z:'};
            dlgtitle = 'Enter coordinates';
            dims = [1 35];
            definput = {'0','0','1','1','1','1'};  % Default values
            answer = inputdlg(prompt, dlgtitle, dims, definput);

            if isempty(answer)
                % User cancelled input dialog
                continue;
            end

            % Convert input strings to numeric vectors
            coords = str2double(answer);

            if any(isnan(coords))
                errordlg('Invalid input. Please enter numeric values.','Input Error');
                continue;
            end

            P = reshape(coords(1:3), 1, []);
            L = reshape(coords(4:6), 1, []);

            % Check 2D XY positions are inside floor polygon
            source2D_inside = inpolygon(P(1), P(2), x, y);
            listener2D_inside = inpolygon(L(1), L(2), x, y);
        
            if ~source2D_inside || ~listener2D_inside
                outside = errordlg('Source or Listener is outside the room perimeter. Please re-enter.', ...
                         'Invalid Placement');
                uiwait(outside)
                continue;  % Restart loop
            end
    end

    % Replot geometry
    fig = figure;
    hold on;
    axis equal;
    xlabel('X (m)'); ylabel('Y (m)'); zlabel('Z (m)');
    title(userText);
    view(3); grid on;

    % Plot transparent room
    shape_opacity = 0.35;
    for i = 1:4
        idx = faces(i,:);
        patch('Vertices', vertices, 'Faces', idx, ...
              'FaceColor', [0.7 0.8 1], 'EdgeColor', 'k', 'FaceAlpha', shape_opacity);
    end
    patch('Vertices', vertices, 'Faces', fliplr(1:num_points), ...
          'FaceColor', [0.4 0.6 0.9], 'EdgeColor', 'k', 'FaceAlpha', shape_opacity);
    patch('Vertices', vertices, 'Faces', (1:num_points) + num_points, ...
          'FaceColor', [0.6 0.7 1], 'EdgeColor', 'k', 'FaceAlpha', shape_opacity);

    % Replot normals
    numWalls = 4;
    scale = 0.35;
    hNormals = quiver3( ...
        all_centres(1:numWalls,1), all_centres(1:numWalls,2), all_centres(1:numWalls,3), ...
        all_normals(1:numWalls,1), all_normals(1:numWalls,2), all_normals(1:numWalls,3), ...
        scale, 'r', 'LineWidth', 1.2);

    % Plot source/listener
    hSource = plot3(P(1), P(2), P(3), 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
    hListener = plot3(L(1), L(2), L(3), 'bs', 'MarkerSize', 10, 'MarkerFaceColor', 'b');

    % Add legend
    legend([hNormals, hSource, hListener], ...
           {'Wall normal', 'Source', 'Listener'}, ...
           'Location', 'bestoutside');

    % Ask user to confirm
    confirmChoice = questdlg( ...
        'Are the source and listener positions correct?', ...
        'Confirm Positions', ...
        'Yes, continue', 'No, redo placement', 'Yes, continue');

    if strcmp(confirmChoice, 'Yes, continue')
        confirmed = true;
        uiresume(gcf);
        close(gcf);
    else
        confirmed = false;
        close(gcf);  % Close current room plot
        continue;
    end
end

% Prompt for Max Reflection Order
defaultOrder = '4';
orderValid = false;
maxAllowedOrder = 10;

while ~orderValid
    % Prompt user
    orderStr = inputdlg( ...
        'Enter the maximum image source order (up to 5 at a push):', ...
        'Max Reflection Order', [1 50], {defaultOrder});

    if isempty(orderStr)
        msgbox('Simulation cancelled by user.', 'Cancelled', 'warn');
        return;
    end

    maxOrder = str2double(orderStr{1});

    % Validate numeric and range
    if isnan(maxOrder) || mod(maxOrder,1) ~= 0
        hErr = errordlg('Please enter a whole number.', 'Invalid Input');
        uiwait(hErr);
    elseif maxOrder < 1
        hErr = errordlg('Reflection order must be at least 1.', 'Too Low');
        uiwait(hErr);
    elseif maxOrder > maxAllowedOrder
        hErr = errordlg(sprintf('Maximum allowed order is %d (though this is not recommended). Please enter a lower value.', maxAllowedOrder), 'Too High');
        uiwait(hErr);
    elseif maxOrder > 4
        % Warn but allow override (up to 10)
        choice = questdlg( ...
        ['Reflection orders above 4 can significantly increase computation time and memory usage. ' ...
         'Higher-order reflections are less reliable in the image source method (ISM), ' ...
         'which assumes specular reflections and does not model diffusion or scattering.' newline newline ...
         'Do you want to proceed with this order?'], ...
        'Performance Warning', ...
        'Yes, continue', 'No, re-enter', 'No, re-enter');

        if strcmp(choice, 'Yes, continue')
            orderValid = true;
        end
        % If "No", loop again
    else
        orderValid = true;
    end
end

% Max Simulation Time
defaultTime = '0.5';
timeValid = false;
while ~timeValid
    timeStr = inputdlg( ...
        'Enter the maximum simulation time (in seconds):', ...
        'Max Time', [1 40], {defaultTime});
    
    if isempty(timeStr)
        msgbox('Simulation cancelled by user.', 'Cancelled', 'warn');
        return;
    end

    maxTime = str2double(timeStr{1});
    if isnan(maxTime) || maxTime <= 0
        hErr = errordlg('Please enter a positive number greater than 0.', 'Invalid Input');
        uiwait(hErr);  % Wait for user to close error popup
    else
        timeValid = true;
    end
end

% Confirm Tree Building Phase
buildChoice = questdlg( ...
    ['The simulation is now ready to build the image source tree.', newline, ...
     'This may take some time depending on the reflection order and room complexity.', newline, ...
     newline, ...
     'Do you want to begin building the tree now?'], ...
    'Begin Tree Building', ...
    'Yes, begin', 'Cancel', 'Yes, begin');

if strcmp(buildChoice, 'Cancel') || isempty(buildChoice)
    msgbox('Tree building cancelled by user.', 'Cancelled', 'warn');
    return;
end

% Populate tree
image_sources = propagate(P, L, maxOrder, all_faces, vertices, all_normals, all_centres, maxTime);

numInitial = numel(image_sources);
fprintf('After validity and proximity checks, %d image sources were generated.\n', numInitial);

doneWithVisuals = false;
nextStep = '';

while ~doneWithVisuals
    if ~exist('nextStep', 'var') || isempty(nextStep)
        % Only prompt if coming from the top or returning from a plot
        nextStep = questdlg( ...
            sprintf(['Tree building is complete. %d image sources were generated.', newline, ...
                     'What would you like to do next?'], numInitial), ...
            'Tree Building Complete', ...
            'View Sources', 'View Tree', 'Build IR', 'View Sources');

        if isempty(nextStep)
            return;  % User closed dialog
        end
    end

    switch nextStep
        case 'View Sources'
            % Plot 3D Sources
            positions = vertcat(image_sources.position);
            fig = figure('Name', 'Image Source Positions');
            hold on;
            axis equal;
            xlabel('X (m)'); ylabel('Y (m)'); zlabel('Z (m)');
            title('Image Source Positions');
            view(3); grid on;

            % Plot room geometry
            shape_opacity = 0.2;
            for i = 1:numel(all_faces)
                patch('Vertices', vertices, ...
                      'Faces', all_faces{i}, ...
                      'FaceColor', [0.7 0.8 1], ...
                      'EdgeColor', 'k', ...
                      'FaceAlpha', shape_opacity);
            end

            scatter3(positions(:,1), positions(:,2), positions(:,3), 30, 'm', 'filled');
            plot3(P(1), P(2), P(3), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
            plot3(L(1), L(2), L(3), 'bs', 'MarkerSize', 8, 'MarkerFaceColor', 'b');
            legend({'Image Sources', 'Real Source', 'Listener'}, 'Location', 'bestoutside');

            uiwait(fig);
            if isvalid(fig), close(fig); end
            nextStep = '';  % Return to menu

        case 'View Tree'
            % Build node labels: VS1, VS2, ...
            nodes = arrayfun(@(s) sprintf('VS%d', s.index), image_sources, 'UniformOutput', false);
        
            % Build edge list: parent → child
            edges = {};
            for i = 1:numel(image_sources)
                parent = image_sources(i).parent_index;
                if ~isnan(parent)
                    parent_label = sprintf('VS%d', parent);
                    child_label = sprintf('VS%d', image_sources(i).index);
                    edges(end+1, :) = {parent_label, child_label};
                end
            end
        
            % Create digraph
            G = digraph(edges(:,1), edges(:,2));
        
            % Assign node colors based on order
            orders = [image_sources.order];
            maxOrder = max(orders);
            cmap = turbo(maxOrder + 1);
            node_colors = cmap(orders + 1, :);  % 1-indexed colormap
        
            % Plot
            fig = figure('Name', 'Image Source Tree');
            h = plot(G, 'Layout', 'layered');
            h.MarkerSize = 7;
            h.NodeColor = node_colors;
            h.NodeLabel = {};  % hide VS# labels
            h.NodeCData = orders;  % color by order (enables colorbar)
            title('Image Source Tree');
            axis off;
        
            % Create hover tooltips
            tooltips = strings(1, numel(image_sources));
            for i = 1:numel(image_sources)
                s = image_sources(i);
                tip = sprintf('Index: %d\nOrder: %d\nParent: %s\nCreated by Face: %s\nPosition: [%.2f, %.2f, %.2f]', ...
                    s.index, ...
                    s.order, ...
                    num2str(s.parent_index), ...
                    num2str(s.created_by), ...
                    s.position(1), s.position(2), s.position(3));
                tooltips(i) = tip;
            end
        
            % Apply tooltips
            dt = h.DataTipTemplate;
            dt.DataTipRows = dataTipTextRow('Info', tooltips);
        
            % Add colourbar as legend for order
            colormap(cmap);
            clim([0 maxOrder]);
            cb = colorbar;
            ylabel(cb, 'Reflection Order');

            % Override tick labels
            cb.Ticks = 0:maxOrder;
            labels = arrayfun(@num2str, 0:maxOrder, 'UniformOutput', false);
            labels{1} = 'Source';  % change '0' to 'Source'
            cb.TickLabels = labels;

            datacursormode(fig);
            drawnow;
            uiwait(fig);
            if isvalid(fig)
                close(fig);
            end

            nextStep = '';  % Return to menu

        case 'Build IR'
            doneWithVisuals = true;  % Exit loop after this
    end
end

absorption_profiles = [
    0.01, 0.02, 0.06, 0.15, 0.25, 0.45; % Profile 1: Carpet
    0.0, 0.0, 0.23, 0.37, 0.5, 0.42; % Profile 2: Quadratic Residue Diffuser
    0.12, 0.09, 0.07, 0.05, 0.05, 0.04; % Profile 3: Perforated Gypsum
    0.05, 0.30, 0.80, 1.00, 1.02, 0.95; % Profile 4: Fibreglass Wall Panels
    0.08, 0.32, 0.99, 0.76, 0.34, 0.12; % Profile 5: Pageboard over 25mm fibreglass
    0.26, 0.97, 0.99, 0.66, 0.34, 0.14; % Profile 6: Pageboard over 50mm fibreglass
    0.49, 0.99, 0.99, 0.69, 0.37, 0.15; % Profile 7: Pageboard over 75mm fibreglass
    0.06, 0.2, 0.65, 0.9, 0.95, 0.98; % Profile 8: 25mm fibreglass board
    0.18, 0.76, 0.99, 0.99, 0.99, 0.99; % Profile 9: 50mm fibreglass board
    0.53, 0.99, 0.99, 0.99, 0.99, 0.99; % Profile 10: 75mm fibreglass board
    0.99, 0.99, 0.99, 0.99, 0.99, 0.97; % Profile 11: 100mm fibreglass board
    0.14, 0.35, 0.53, 0.75, 0.7, 0.6 % Profile 12: Drapery 18oz pleated
    0.15, 0.11, 0.04, 0.04, 0.07, 0.08 % Profile 13: Plasterboard 12mm in suspended ceiling grid
    0.26, 0.97, 0.99, 0.66, 0.34, 0.14 % Profile 14: Pageboard over 50mm fibreglass board
    0.73, 0.99,	0.99, 0.89, 0.52, 0.31 % Profile 15: Metal deck batts
    ];

air_absorption = [
    0, 0.00023023200184346, 0.0006905369974100628, 0.00115063006349480, 0.0022999361774467264, 0.006883951579066183
    ]; % For 20 degrees celsius and 50 percent humidity

num_faces = length(all_faces);
face_profile_indices = zeros(num_faces, 1);

% Material names
material_names = {
    'Carpet', 'Quadratic Residue Diffuser', 'Perforated Gypsum', ...
    'Fibreglass Wall Panels', 'Pageboard + 25mm Fibreglass', ...
    'Pageboard + 50mm Fibreglass', 'Pageboard + 75mm Fibreglass', ...
    '25mm Fibreglass Board', '50mm Fibreglass Board', '75mm Fibreglass Board', ...
    '100mm Fibreglass Board', 'Drapery 18oz Pleated', ...
    'Plasterboard 12mm (Ceiling Grid)', ...
    'Pageboard + 50mm Fibreglass Board (Alt)', 'Metal Deck Batts'
};

for i = 1:num_faces
    % Face label
    if i <= 4
        faceLabel = sprintf('Wall %d of 4', i);
    elseif i == 5
        faceLabel = 'Floor';
    elseif i == 6
        faceLabel = 'Ceiling';
    else
        faceLabel = sprintf('Face %d', i);
    end

    % Plot room with face i highlighted
    fig = figure('Name', sprintf('Select Material for %s', faceLabel));
    hold on;
    axis equal;
    xlabel('X (m)'); ylabel('Y (m)'); zlabel('Z (m)');
    title(sprintf('Face Assignment: %s', faceLabel));
    view(3); grid on;

    for j = 1:num_faces
        color = [0.5 0.7 1];  % blue for unselected
        if j == i
            color = [1 0.2 0.2];  % red highlight
        end
        patch('Vertices', vertices, ...
              'Faces', all_faces{j}, ...
              'FaceColor', color, ...
              'EdgeColor', 'k', ...
              'FaceAlpha', 0.35);
    end

    % Show the figure before dialog
    drawnow;

    % Prompt for material selection
    [sel, ok] = listdlg( ...
        'PromptString', sprintf('Select absorption profile for %s:', faceLabel), ...
        'ListString', material_names, ...
        'SelectionMode', 'single', ...
        'ListSize', [300 250], ...
        'Name', sprintf('Material for %s', faceLabel));

    close(fig);  % Close plot

    if ~ok
        msgbox('Operation cancelled by user.', 'Cancelled', 'warn');
        return;
    end

    face_profile_indices(i) = sel;
end

fs = 44100;
N = round(fs * maxTime);
c = 343;  % Speed of sound in m/s

numSources = length(image_sources);
dist = zeros(numSources, 1);        % Distances
delay = zeros(numSources, 1);     % Absolute delays
relative_delay = zeros(numSources, 1);  % Delays relative to direct path

% Compute all distances
for i = 1:numSources
    dist(i) = norm(image_sources(i).position - L);
end

% Compute direct delay (first image source)
direct_delay = dist(1) / c;
delay(1) = direct_delay;
relative_delay(1) = 0;

% Compute relative delays from 2 onward
for i = 2:numSources
    delay(i) = dist(i) / c;
    relative_delay(i) = delay(i) - direct_delay;
end

% Compute air attenuation across all sources and bands
% Assume air_absorption is a 1 x numBands vector (linear fractional loss per meter)
survival = 1 - air_absorption;   % 1 x numBands
g_air = survival .^ dist;          % [numSources x numBands], via implicit expansion

h_os = irBuilder(image_sources, L, fs, c, maxTime, absorption_profiles, face_profile_indices, air_absorption);

% Prompt user to choose how to process and plot the impulse response
chosenIR = questdlg( ...
    'How would you like to process the impulse response for plotting or saving?', ...
    'Impulse Response Type', ...
    'A-weighted broadband', 'Individual frequency bands', 'A-weighted broadband');

% Check for cancel or window close
if isempty(chosenIR)
    msgbox('No selection made. Operation cancelled.', 'Cancelled', 'warn');
    return;
end

% A-weighted broadband IR
if strcmp(chosenIR, 'A-weighted broadband')
    % Apply A-weighting and combine bands
    A_dB = [-16.2, -8.7, -3.2, 0, 1.2, 1.0];
    A_lin = 10.^(A_dB / 20);
    h_bb_os = sum(h_os .* A_lin, 2);

    % Normalize
    h_bb = h_bb_os / max(abs(h_bb_os) + eps);
    
    N = length(h_bb);
    time_axis = (0:N-1) / fs;  % Time vector in seconds
    figure;
    stem(time_axis, h_bb, 'Marker', 'none');
    xlabel('Time (s)');
    ylabel('Amplitude');
    title('Room Impulse Response using Image Source Method');
    grid on;

    h_bb = real(h_bb);
    h_for_predelay = abs(h_bb).^2;
    h_for_metrics = abs(h_bb);

elseif strcmp(chosenIR, 'Individual frequency bands')
    bandLabels = {'125 Hz', '250 Hz', '500 Hz', '1 kHz', '2 kHz', '4 kHz'};
    numBands = numel(bandLabels);
    time = (0:size(h_os,1)-1) / fs;

    selectedBands = true(1, numBands);
    checkboxHandles = gobjects(1, numBands);

    % Create interactive UI
    uiFig = uifigure('Name', 'Band Selector');
    uiFig.Position(3:4) = [850 500];

    ax = uiaxes(uiFig, 'Position', [260 80 560 380]);
    ax.XLabel.String = 'Time (s)';
    ax.YLabel.String = 'Amplitude';
    ax.Title.String = 'Impulse Response by Frequency Band';
    hold(ax, 'on');

    % Plot all lines and store handles
    lineHandles = gobjects(numBands, 1);
    colors = lines(numBands);
    for b = 1:numBands
        lineHandles(b) = plot(ax, time, h_os(:,b), ...
            'DisplayName', bandLabels{b}, ...
            'Color', colors(b,:), ...
            'Visible', 'on');
    end

    legend(ax, 'show');

    % Create checkboxes
    for b = 1:numBands
        bandIdx = b;  % Fix loop scope
        checkboxHandles(b) = uicheckbox(uiFig, ...
            'Text', bandLabels{bandIdx}, ...
            'Position', [20, 400 - (bandIdx-1)*40, 120, 30], ...
            'Value', true);

        % Attach callback with properly captured handle and index
        checkboxHandles(b).ValueChangedFcn = @(src, ~) set(lineHandles(bandIdx), 'Visible', ...
                                           conditionalVisibility(src.Value));
    end

    for b = 1:numBands
        selectedBands(b) = checkboxHandles(b).Value;
    end

    uiwait(uiFig);
    if isvalid(uiFig), close(uiFig); end

    acoustic_metrics = struct();

    for b = 1:numBands
        if ~selectedBands(b)
            continue;
        end
        
        h_band = h_os(:, b);
        h_abs = abs(h_band);
        h_energy_full = h_abs.^ 2;
        t_full = (0:length(h_band)-1)' / fs;

        % Pre-delay
        % Find sample indices of the two largest spikes
        [~, sortedIdx] = sort(h_energy_full, 'descend');
            
        firstSpike = min(sortedIdx(1:2));  % Get earlier of top 2 spikes as direct
        secondSpike = max(sortedIdx(1:2)); % Get later as first reflection (if sorted wrong way)
            
        % Predelay in samples and seconds
        preDelaySamples = secondSpike - firstSpike;
        preDelayTime = preDelaySamples / fs;

        % Onset trim
        onset_threshold = max(h_abs) * 10^(-40/ 20);
        onset_idx = find(h_abs >= onset_threshold, 1, 'first');
        h_trimmed = h_abs(onset_idx:end);
        h_energy = h_trimmed .^2;
        t_trimmed = (0:length(h_trimmed)-1)'/ fs;

        % Some of the metrics that rely on the ratio between early and late 
        % reflections only converge on an accurate result if the impulse response 
        % is above a certain length, which is more often not achievable than
        % achievable with this simulation, because it calculates only the first 4
        % or 5 orders of specular (directional) reflections and not the complete 
        % reverberant IR. This is achievable with image source method but only for 
        % very simple models where you can afford a greater number of orders of 
        % reflection.

        % C50
        i50 = min(round(0.050 * fs), length(h_energy));
        E_early = sum(h_energy(1:i50));
        E_late = sum(h_energy(i50+1:end));
        C50 = 10 * log10(E_early / (E_late + eps));

        % Direct-to-reverberant ratio (D/R)
        [~, direct_idx] = max(h_energy);  % or firstSpike if known
        window = round(0.002 * fs);  % 2 ms window around direct
        i1 = max(direct_idx - window, 1);
        i2 = min(direct_idx + window, length(h_energy));
        E_direct = sum(h_energy(i1:i2));
        E_reverb = sum(h_energy) - E_direct;
        DR_ratio = 10 * log10(E_direct / (E_reverb + eps));

        % Reflection Density
        threshold = max(h_energy) * 0.05;  % Only count above 5% of max
        num_spikes = sum(h_energy > threshold);
        density = num_spikes / 0.1;  % reflections per second

        % Temporal Centroid
        tc = sum(t_trimmed .* h_energy) / (sum(h_energy) + eps);

        % Compile table
        acoustic_metrics(b).Band = bandLabels{b};
        acoustic_metrics(b).C50 = C50;
        acoustic_metrics(b).PreDelay_s = preDelayTime;
        acoustic_metrics(b).DR_Ratio_dB = DR_ratio;
        acoustic_metrics(b).ReflectionDensity = density;
        acoustic_metrics(b).TemporalCentroid_s = tc;
    end
    resultsTable = struct2table(acoustic_metrics);
    disp(resultsTable);
end

doExport = questdlg( ...
    'Would you like to export data for use in ray tracing or hybrid workflows?', ...
    'Export Option', ...
    'Yes', 'No', 'Yes');

if strcmp(doExport, 'Yes')

    exportForRayTracing(image_sources, vertices, all_faces, P, L, h_os, ...
        absorption_profiles, face_profile_indices, ...
        preDelayTime);
end

% Helper for correct visibility string
function v = conditionalVisibility(val)
    if val
        v = 'on';
    else
        v = 'off';
    end
end