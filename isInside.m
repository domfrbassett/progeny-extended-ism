function inside = isInside(P, all_faces, all_centres, all_normals)
% Check if point P is inside 3D room volume (walls + floor + ceiling)
% Normal vector points inwards from plane towards P
% The vector from P to the face points in the opposite direction to
% the normal, i.e. dot(n, (fc - P) < 0
% Therefore dot(n, P - fc) should be > 0 if it is in the room

    % Check all faces including floor and ceiling
    for f = 1:length(all_faces)
        n = all_normals(f, :);
        fc = all_centres(f, :);

        dp = dot(n, (P - fc));

        if dp < 0
            inside = false;
            return
        end
    end
    inside = true;
end