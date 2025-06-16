function [corrected_sides, headings] = correct_sides(turn_angles, measured_sides)
    % Ensure inputs are column vectors
    turn_angles = deg2rad(turn_angles(:));
    s0 = measured_sides(:);
    
    N = length(turn_angles);

    % Compute absolute headings
    headings = zeros(N, 1);
    headings(1) = turn_angles(1);
    for i = 2:N
        headings(i) = mod(headings(i-1) + turn_angles(i), 2*pi);
    end

    % Equality constraints for closure
    Aeq = [cos(headings)'; sin(headings)'];  % 2 x N
    beq = [0; 0];

    % Fix first side
    Aeq_reduced = Aeq(:, 2:N);             % Only free variables
    beq_reduced = beq - Aeq(:,1) * s0(1);  % Adjust for fixed first side

    % Solve least squares problem
    f = -s0(2:N);  % Minimize (s - s0)' * (s - s0)
    H = eye(N-1);
    options = optimoptions('lsqlin','Display','off');
    s_free = lsqlin(H, -f, [], [], Aeq_reduced, beq_reduced, [], [], [], options);

    % Combine with fixed first side
    corrected_sides = [s0(1); s_free];
end