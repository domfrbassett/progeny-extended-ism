function image_sources = recurse(P, L, order, parent_face, max_order, all_faces, vertices, all_normals, all_centres, image_sources, path, max_distance, parent_index)

    if order >= max_order % Global recursion depth check - terminate when 
                          % max_order is reached
        return;
    end

    num_faces = length(all_faces);

    for f = 1:num_faces
        if f == parent_face
            continue;  % Avoid immediate re-reflection
        end

        h = all_normals(f, :);
        Fc = all_centres(f, :);

        % d = signed scalar projection of the vector from P to the face

        % Despite what Borish says in his method, an origin (p) is not 
        % neccessary to calculate d, which is defined in the document as 
        % d = p - dot(P, h);
        % d can just be calculated as d = dot(h, face_centre - P)

        d = dot(h, Fc - P);

        % The position vector of the image point (R) is given by: R = P + 
        % (2d*h)

        two_d = 2*d;
        R = P + (two_d * h);

        % Validity Check

        % If d >= 0 then the point P lies on or behind the face, relative 
        % to the direction of the normal h

        if d >= 0
            continue;
        end

        % Proximity Check

        % If the euclidian distance between L and R exceeds the max
        % distance, the reflected path is too long - we skip

        dirVec = L - R;
        distance_to_listener = norm(dirVec); % Calculate euclidian distance

        if distance_to_listener > max_distance
            continue;  % Skip
        end

        % Save image source data

        % Populate struct with useful data and metadata

        new_index = length(image_sources) + 1;
        new_entry.index = new_index;
        new_entry.parent_index = parent_index;
        new_entry.position = R;
        new_entry.order = order + 1;
        new_entry.created_by = f;
        new_entry.parent_position = P;
        new_entry.path = [path, f];

        % Debugging Info - can uncomment if you wish

        % disp(['--- Creating VS ', num2str(new_index), ' ---']);
        % disp(['  Order: ', num2str(order + 1)]);
        % disp(['  Parent index: ', num2str(parent_index)]);
        % disp(['  Parent position: ', mat2str(P)]);
        % disp(['  VS position (R): ', mat2str(R)]);
        % disp(['  Face ID: ', num2str(f)]);

        image_sources(end+1) = new_entry;

        % Recurse to next order, taking the new position as the source
        % position
        image_sources = recurse(R, L, order + 1, f, max_order, all_faces, vertices, all_normals, all_centres, image_sources, [path, f], max_distance, new_index);
    end
end