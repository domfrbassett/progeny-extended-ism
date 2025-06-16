% function side_lengths = close_polygon(turn_angles, L1, Ln)
%     % Solve polygon side lengths to achieve closure using a linear system
%     % Inputs:
%     %   turn_angles - vector of N turn angles (degrees)
%     %   L1          - fixed length of the first side
%     %   Ln          - fixed length of the last side
%     % Output:
%     %   side_lengths - Nx1 vector of side lengths
% 
%     N = length(turn_angles);
%     if N < 3
%         error('Polygon must have at least 3 sides.');
%     end
% 
%     % Compute absolute headings
%     headings = zeros(1, N);
%     angle = 0;
%     for i = 1:N
%         angle = angle + turn_angles(i);
%         headings(i) = mod(angle, 360);
%     end
% 
%     % Direction vectors
%     dx = cosd(headings);
%     dy = sind(headings);
% 
%     % Build system for unknown sides: L2 to L(N-1)
%     A = [dx(2:end-1); dy(2:end-1)];         % 2 x (N-2)
%     b = -L1 * [dx(1); dy(1)] - Ln * [dx(end); dy(end)];
% 
%     % Solve for unknown sides
%     L_unknown = A \ b;
% 
%     % Combine all side lengths
%     side_lengths = [L1; L_unknown; Ln];
% end

function side_lengths_out = close_polygon_general(turn_angles, side_lengths)
    % CLOSE_POLYGON_GENERAL
    % Solve for 2 missing side lengths in a closed polygon using angles and known side lengths.
    %
    % Inputs:
    %   turn_angles   - 1×N vector of internal turn angles (degrees)
    %   side_lengths  - 1×N vector of side lengths (use NaN for unknowns)
    %
    % Output:
    %   side_lengths_out - 1×N vector with missing values filled in

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