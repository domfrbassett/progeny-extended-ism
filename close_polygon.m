function side_lengths_out = close_polygon(turn_angles, side_lengths)

    N = length(turn_angles);
    if N < 3
        error('Polygon must have at least 3 sides.');
    end
    if sum(isnan(side_lengths)) ~= 2
        errordlg(sprintf('Exactly 2 side lengths must be left blank (unknown). You have %d.', numUnknown), 'Input Error');
    end

    unknown_idx = find(isnan(side_lengths));

    % Compute cumulative headings
    headings = zeros(1, N);
    angle = 0;
    for i = 1:N
        angle = angle + turn_angles(i);
        headings(i) = mod(angle, 360);
    end

    dx = cosd(headings);
    dy = sind(headings);

    % Build vector sum of known sides
    bx = 0;
    by = 0;
    for i = 1:N
        if ~isnan(side_lengths(i))
            bx = bx + side_lengths(i) * dx(i);
            by = by + side_lengths(i) * dy(i);
        end
    end

    % Solve for the two unknowns
    A = [dx(unknown_idx(1)), dx(unknown_idx(2));
         dy(unknown_idx(1)), dy(unknown_idx(2))];
    b = -[bx; by];

    L_unknown = A \ b;

    % Plug into output
    side_lengths_out = side_lengths;
    side_lengths_out(unknown_idx) = L_unknown;
end