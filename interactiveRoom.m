function interactiveRoom(vertices, roomCentre, height, x, y)
    % Function to interactively place source and listener in a 3D room
    assignin('base', 'placement_confirmed', false);

    % === Initial positions for markers ===
    source_pos = roomCentre + [1, 0, 0];
    listener_pos = roomCentre - [1, 0, 0];

    % === Plot initial room ===
    figure('Position', [100 100 1000 700]);
    hold on;
    axis equal;
    xlabel('X (m)');
    ylabel('Y (m)');
    zlabel('Z (m)');
    title('Place Source and Listener');
    view(3);
    grid on;

    num_points = size(vertices, 1) / 2;
    faces = zeros(4, 4);
    for i = 1:4
        j = mod(i, 4) + 1;
        faces(i,:) = [i, j, j+num_points, i+num_points];
    end

    shape_opacity = 0.35;

    % Draw room walls
    for i = 1:4
        idx = faces(i,:);
        patch('Vertices', vertices, 'Faces', idx, ...
              'FaceColor', [0.7 0.8 1], 'EdgeColor', 'k', 'FaceAlpha', shape_opacity);
    end
    patch('Vertices', vertices, 'Faces', fliplr(1:num_points), ...
          'FaceColor', [0.4 0.6 0.9], 'EdgeColor', 'k', 'FaceAlpha', shape_opacity);
    patch('Vertices', vertices, 'Faces', (1:num_points) + num_points, ...
          'FaceColor', [0.6 0.7 1], 'EdgeColor', 'k', 'FaceAlpha', shape_opacity);

    % === Plot initial source/listener markers ===
    source_marker = plot3(source_pos(1), source_pos(2), source_pos(3), 'ro', ...
                          'MarkerSize', 10, 'MarkerFaceColor', 'r');
    listener_marker = plot3(listener_pos(1), listener_pos(2), listener_pos(3), 'bs', ...
                            'MarkerSize', 10, 'MarkerFaceColor', 'b');

    % === Define bounds ===
    margin = 0.1;
    xlim_room = [min(x)-margin, max(x)+margin];
    ylim_room = [min(y)-margin, max(y)+margin];
    zlim_room = [0, height];

    % === Create UI panel for sliders ===
    panel = uipanel('Title','Source & Listener Position','FontSize',12,...
        'BackgroundColor','white','Position',[.75 .05 .2 .9]);

    slider_labels = {'X', 'Y', 'Z'};
    entities = {'Source', 'Listener'};
    sliders = struct();
    
    label_height = 0.025;
    slider_height = 0.04;
    vertical_gap = 0.015;
    block_height = label_height + slider_height + vertical_gap;
    
    % Place all 6 sliders starting from here
    start_y = 0.92;

    for ei = 1:2
        entity = entities{ei};
        for ai = 1:3
            axis_label = slider_labels{ai};
            idx = 3 * (ei - 1) + ai - 1;
    
            % Calculate positions
            y_slider = start_y - idx * block_height;
            y_label = y_slider + slider_height + 0.005;  % Slight offset above slider
    
            % Label
            uicontrol(panel, 'Style', 'text', ...
                'String', sprintf('%s %s', entity, axis_label), ...
                'Units', 'normalized', ...
                'Position', [0.1, y_label, 0.8, label_height], ...
                'BackgroundColor', 'white', ...
                'FontSize', 9, 'HorizontalAlignment', 'left');
    
            % Slider
            sliders.(entity).(axis_label) = uicontrol(panel, 'Style', 'slider', ...
                'Units', 'normalized', ...
                'Position', [0.1, y_slider, 0.8, slider_height], ...
                'Min', eval([lower(axis_label) 'lim_room(1)']), ...
                'Max', eval([lower(axis_label) 'lim_room(2)']), ...
                'Value', (strcmp(entity, 'Source') * source_pos(ai) + ...
                          strcmp(entity, 'Listener') * listener_pos(ai)), ...
                'Callback', @(src, ~) updatePin());
        end
    end

% Confirm button nicely spaced under sliders
% Confirm button nicely spaced under sliders
uicontrol('Parent', panel, 'Style', 'pushbutton', 'String', 'Confirm', ...
    'Units', 'normalized', ...
    'Position', [0.1, 0.02, 0.8, 0.05], ...
    'FontSize', 10, ...
    'Callback', @(src,~) confirmAndClose());

% === Add this nested function ===
    function confirmAndClose()
        updatePin();  % Refresh current positions
        assignin('base', 'placement_confirmed', true);

        % Get current slider values
        sx = sliders.Source.X.Value;
        sy = sliders.Source.Y.Value;
        lx = sliders.Listener.X.Value;
        ly = sliders.Listener.Y.Value;

        % Check if both source and listener are inside the floor polygon
        isSourceInside = inpolygon(sx, sy, x, y);
        isListenerInside = inpolygon(lx, ly, x, y);

        if ~isSourceInside || ~isListenerInside
            msgbox('Error: Source or Listener is outside the room perimeter. Please reposition.', ...
                   'Invalid Placement', 'error');
            return;  % Do not close GUI or resume script
        end

        % All valid — resume script and close GUI
        uiresume(gcf);
        close(gcf);
    end

    % Display position labels

    updatePin();  % Initial update

    % === Nested callback ===
    function updatePin()
        sx = sliders.Source.X.Value;
        sy = sliders.Source.Y.Value;
        sz = sliders.Source.Z.Value;
        lx = sliders.Listener.X.Value;
        ly = sliders.Listener.Y.Value;
        lz = sliders.Listener.Z.Value;

        set(source_marker, 'XData', sx, 'YData', sy, 'ZData', sz);
        set(listener_marker, 'XData', lx, 'YData', ly, 'ZData', lz);

        % Export to base workspace
        assignin('base', 'final_source_position', [sx, sy, sz]);
        assignin('base', 'final_listener_position', [lx, ly, lz]);
    end
end