clear all; close all;

% Parameters
tid = 0;       % Time ID
px = 2;        % Number of processors in x direction
py = 3;        % Number of processors in y direction
nx_local = 600;  % Local grid size in x
ny_local = 600;  % Local grid size in y

% Calculate global grid dimensions
nx_global = nx_local * px;
ny_global = ny_local * py;

% Initialize global arrays
x_global = zeros(nx_global, 1);
y_global = zeros(ny_global, 1);
T_global = zeros(nx_global, ny_global);

% Read data from each processor and stitch together
for ix = 0:px-1
    for iy = 0:py-1
        proc_id = ix * py + iy;
        filename = sprintf('T_x_y_%06d_%04d.dat', tid, proc_id);
        
        % Read data from this processor
        data = dlmread(filename);
        
        % Extract local dimensions
        n_local = sqrt(size(data,1));
        
        % Extract x, y coordinates and temperature values
        x_local = data(1:n_local:n_local^2, 1);
        y_local = data(1:n_local, 2);
        T_local = reshape(data(:,3), [n_local, n_local]);
        
        % Calculate global indices
        i_start = ix * nx_local + 1;
        i_end = (ix + 1) * nx_local;
        j_start = iy * ny_local + 1;
        j_end = (iy + 1) * ny_local;
        
        % Store coordinates (only need to do this once per row/column)
        if iy == 0
            x_global(i_start:i_end) = x_local;
        end
        if ix == 0
            y_global(j_start:j_end) = y_local;
        end
        
        % Store temperature data
        T_global(i_start:i_end, j_start:j_end) = T_local;
    end
end

% Create contour plot
figure, clf
contourf(x_global, y_global, T_global', 'LineColor', 'none')
xlabel('x'), ylabel('y'), title(sprintf('t = %06d', tid));
xlim([-0.05 1.05]), ylim([-0.05 1.05]), caxis([-0.05 1.05]), colorbar
colormap('jet')
set(gca, 'FontSize', 14)
screen2jpeg(sprintf('cont_T_combined_%04d.png', tid))

% Create line plot along mid-y
figure, clf
Tmid = T_global(:, round(ny_global/2));
plot(x_global, Tmid, '-', 'LineWidth', 2)
xlabel('x'), ylabel('T'), title(sprintf('Profile along mid-y at t=%06d', tid))
xlim([-0.05 1.05])
set(gca, 'FontSize', 14)
screen2jpeg(sprintf('line_midy_T_combined_%04d.png', tid))

% Display information about the combined data
fprintf('Combined data from %d processors (%d x %d)\n', px*py, px, py);
fprintf('Global grid size: %d x %d\n', nx_global, ny_global);
fprintf('Output saved as cont_T_combined_%04d.png and line_midy_T_combined_%04d.png\n', tid, tid);
