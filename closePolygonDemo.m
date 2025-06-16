% Demonstration of Linear system for polygon closure with 2 degrees of 
% freedom

clc; clear;

% Inputs
turns = [81.3, 98.4, 108.7, 71.6];   % turtle-style left turns
L1 = 12.08;                          % known first side
L4 = 5.08;                           % known last side

% Compute absolute headings
n = 4;                               % number of sides
headings = zeros(1, n);              % heading angles
angle = 0;                           % start facing east

% Accumulate heading angles using turn angles (turtle geometry)
for i = 1:n
    angle = angle + turns(i);
    headings(i) = mod(angle, 360);  % wrap to 0,360
end

% Build linear system for unknown side lengths
dx = cosd(headings);
dy = sind(headings);

% Construct the system Ax = b to enforce closure condition
A = [dx(2), dx(3), dx(4);
     dy(2), dy(3), dy(4)];
b = -L1 * [dx(1); dy(1)];           % Move first vector to RHS


% Reduced system
A2 = A(:,1:2);             % 2x2 for L2, L3
b2 = b - A(:,3) * L4;      % adjusted RHS

L2_L3 = A2 \ b2;           % exact solution

% Final side lengths
lengths = [L1, L2_L3', L4];

% Trace the polygon vertices
x = zeros(1, n+1);
y = zeros(1, n+1);
for i = 1:n
    x(i+1) = x(i) + lengths(i) * cosd(headings(i));
    y(i+1) = y(i) + lengths(i) * sind(headings(i));
end

% Plot
figure;
plot(x, y, '-o', 'LineWidth', 2);
axis equal;
grid on;
title('Polygon Closure');
xlabel('X (m)');
ylabel('Y (m)');

% Annotate lengths
hold on;
for i = 1:n
    midx = (x(i)+x(i+1))/2;
    midy = (y(i)+y(i+1))/2;
    text(midx, midy, sprintf('%.2f m', lengths(i)), 'Color', 'b', 'FontSize', 10);
end

% Output
disp('Solved side lengths:');
disp(lengths);
fprintf('Closure error: Δx = %.6f, Δy = %.6f\n', x(end)-x(1), y(end)-y(1));