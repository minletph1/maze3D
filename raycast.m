classdef raycast < handle
properties
    maze
    view
    proj
    role
    htables
end

methods
    function obj=raycast(filename)
        maze = Maze(filename);
        obj.maze.m = maze;
        obj.maze.map = maze.map;
        maze_size = size(obj.maze.map);
        obj.maze.sizex = maze_size(2);
        obj.maze.sizey = maze_size(1);
        
        obj.view.field = 120;
        obj.view.points = -180;
        
        obj.proj.w = 1440;
        obj.proj.h = 900;
        obj.proj.dist = (obj.proj.w/2) * cot(deg2rad(obj.view.field/2));
        
        obj.role.posx = maze.origin(2);
        obj.role.posy = maze.origin(1);
        
        obj.htables = zeros(obj.proj.h);
        for i=1:obj.proj.h  %height to columns that is to be draw table
            obj.htables(i,(obj.proj.h/2-i/2+1):(obj.proj.h/2+i/2)) = 1;
        end
        colormap(flipud(pink(obj.proj.h)))
        obj.render_scene(obj.maze, obj.view, obj.proj, obj.role, obj.htables)
        set(gcf, 'KeyPressFcn',@obj.key_event)
    end
    function []=render_scene(obj, maze,view,proj,role,htables)
        ray.offset = atand(((-proj.w/2:proj.w/2-1) + 0.5)./ ...
            (proj.w/2/tand(view.field/2)));
        ray.offset = deg2rad(ray.offset);
        rays = deg2rad(view.points) + ray.offset;
        
        rays_sin = sin(rays);
        rays_cos = cos(rays);
        rays_tan = tan(rays);
        %==========================================================================
        %raycasting to wall
        
        %--------------------------------------------------------------------------
        %Horizontal walll
        up = rays_sin < 0;
        down = rays_sin > 0;
        
        nup = sum(up);
        ndown = sum(down);
        nhori = nup + ndown;
        
        %intersection
        yints_up = ceil(role.posy-1);
        yints_down = floor(role.posy+1);
        yints_hori(up) = yints_up .* ones(1,nup);
        xints_hori(up) = role.posx - (role.posy-yints_hori(up)) ./ rays_tan(up);
        yints_hori(down) = yints_down .* ones(1,ndown);
        xints_hori(down) = role.posx - (role.posy-yints_hori(down)) ./ rays_tan(down);
        
        %found flag
        found_ints_hori = false(1,nhori);
        not_found_ints_hori = ~found_ints_hori;
        impossible_ints_hori = false(1, nhori);
        
        %deisplacement
        x_displacement_hori(up) = -1 ./ rays_tan(up);
        x_displacement_hori(down) = 1 ./ rays_tan(down);
        
        while 1
            impossible_ints_hori(up & not_found_ints_hori) = ...
                (yints_up < 1) | ...
                (floor(xints_hori(not_found_ints_hori & up))+1<1) | ...
                (floor(xints_hori(not_found_ints_hori & up))+1>maze.sizex);
            impossible_ints_hori(down & not_found_ints_hori) = ...
                (yints_down >maze.sizey) | ...
                (floor(xints_hori(not_found_ints_hori & down))+1<1) | ...
                (floor(xints_hori(not_found_ints_hori & down))+1>maze.sizex);
            found_ints_hori = found_ints_hori | impossible_ints_hori;
            not_found_ints_hori = ~found_ints_hori;
            
            if all(found_ints_hori)
                break, end
            
            if yints_up>=1 && yints_up<=maze.sizey
                found_ints_hori(up & not_found_ints_hori) = ...
                    0 == maze.map(yints_up, floor(xints_hori(up&not_found_ints_hori)) + 1);
                not_found_ints_hori = ~found_ints_hori;
            end
            
            if yints_down>=0 && yints_down+1<=maze.sizey
                found_ints_hori(down & not_found_ints_hori) = ...
                    0 == maze.map(yints_down+1, floor(xints_hori(down&not_found_ints_hori)) + 1);
                not_found_ints_hori = ~found_ints_hori;
            end
            
            yints_up = yints_up-1;
            yints_hori(up & not_found_ints_hori) = yints_up;
            yints_down = yints_down + 1;
            yints_hori(down & not_found_ints_hori) = yints_down;
            
            xints_hori(not_found_ints_hori) = xints_hori(not_found_ints_hori) + ....
                x_displacement_hori(not_found_ints_hori);
        end
        yints_hori(impossible_ints_hori) = Inf;
        xints_hori(impossible_ints_hori) = Inf;
        
        %--------------------------------------------------------------------------
        %vertical wall
        
        left = rays_cos  <0;
        right = rays_cos > 0;
        
        nleft = sum(left);
        nright = sum(right);
        nvert = nleft + nright;
        
        %intersection
        xints_left = ceil(role.posx-1);
        xints_right = floor(role.posx+1);
        xints_vert(left) = xints_left .* ones(1,nleft);
        yints_vert(left) = role.posy - (role.posx - xints_vert(left)) .* rays_tan(left);
        xints_vert(right) = xints_right .* ones(1,nright);
        yints_vert(right) = role.posy - (role.posx - xints_vert(right)) .* rays_tan(right);
        
        %found flag
        found_ints_vert = false(1,nvert);
        not_found_ints_vert = ~found_ints_vert;
        impossible_ints_vert = false(1, nvert);
        
        %displacement
        y_displacement_vert(left) = rays_tan(left);
        y_displacement_vert(right) = -rays_tan(right);
        
        while 1
            impossible_ints_vert(left & not_found_ints_vert) = ...
                            (xints_left<1) | ...
                            (floor(yints_vert(not_found_ints_vert & left))+1 < 1) | ...
                            (floor(yints_vert(not_found_ints_vert & left))+1 >maze.sizey);
            impossible_ints_vert(right & not_found_ints_vert) =  ...
                                 (xints_right+1>maze.sizex)| ...
                                 (floor(yints_vert(not_found_ints_vert & right))+1 < 1) | ...
                                 (floor(yints_vert(not_found_ints_vert & right))+1 >maze.sizey);
            found_ints_vert = found_ints_vert | impossible_ints_vert;
            not_found_ints_vert = ~found_ints_vert;
            
            if all(found_ints_vert)
                break, end
            
            if xints_left >= 1 && xints_left <=maze.sizex
                found_ints_vert(left & not_found_ints_vert) = ...
                    0 == maze.map(floor(yints_vert(left&not_found_ints_vert)) + 1, xints_left);
                not_found_ints_vert = ~found_ints_vert;
            end
            
            if xints_right >= 0 && xints_right+1 <= maze.sizex
                found_ints_vert(right & not_found_ints_vert) = ...
                    0 == maze.map(floor(yints_vert(right&not_found_ints_vert)) + 1,xints_right+1);
                not_found_ints_vert = ~found_ints_vert;
            end
            
            xints_left = xints_left-1;
            xints_vert(left & not_found_ints_vert) = xints_left;
            xints_right = xints_right + 1;
            xints_vert(right & not_found_ints_vert) = xints_right;
            
            yints_vert(not_found_ints_vert) = yints_vert(not_found_ints_vert) + ....
                y_displacement_vert(not_found_ints_vert);
        end
        yints_vert(impossible_ints_vert) = Inf;
        xints_vert(impossible_ints_vert) = Inf;
        
        %--------------------------------------------------------------------------
        %combine horizontal and vertical
        dist_hori = sqrt((xints_hori-role.posx).^2 + (yints_hori-role.posy).^2);
        dist_vert = sqrt((xints_vert-role.posx).^2 + (yints_vert-role.posy).^2);
        distances = min([dist_hori;dist_vert]) .* cos(ray.offset); %fix fishbowl effect
        height = round(proj.dist ./  distances);
        height(height>proj.h) = proj.h;
        height(height<1) = 1;
        
        scene = htables(height,:)';
        scene = scene .* distances .* 100;
        
        image(scene);
        axis off
        
       % plot(1:length(height),height, ...
        %    1:length(distances),distances*120)
    end
    
    function []=key_event(obj, handle, data)
            if(strcmp(data.Key,'leftarrow'))
                obj.view.points = obj.view.points-10;
            elseif(strcmp(data.Key,'rightarrow'))
                obj.view.points = obj.view.points+10;
            elseif(strcmp(data.Key,'uparrow'))
                newy = obj.role.posy - 0.2*-sind(obj.view.points);
                newx = obj.role.posx + 0.2*cosd(obj.view.points); 
                if floor(newy)+1 > obj.maze.sizey ||  floor(newy)+1 < 1 ||...
                   floor(newx)+1 > obj.maze.sizex || floor(newx)+1 < 1
                     return
                end
                
                if obj.maze.map(floor(newy)+1,floor(newx)+1) == 0 
                    return
                end
                
                obj.role.posy = newy;
                obj.role.posx = newx;
            elseif(strcmp(data.Key,'downarrow'))
               newy = obj.role.posy +  0.2*-sind(obj.view.points);
               newx = obj.role.posx - 0.2*cosd(obj.view.points);
               if floor(newy)+1 > obj.maze.sizey ||  floor(newy)+1 < 1 ||...
                   floor(newx)+1 > obj.maze.sizex || floor(newx)+1 < 1
                     return
                end
               
               if obj.maze.map(floor(newy)+1,floor(newx)+1)==0
                    return
               end
               
               obj.role.posy = newy;
               obj.role.posx = newx;
            end
            obj.render_scene(obj.maze, obj.view, obj.proj, obj.role, obj.htables);
            if floor(obj.role.posy)+1 == obj.maze.m.final(1) && floor(obj.role.posx)+1 == obj.maze.m.final(2)
                text(round(obj.maze.sizex/4), round(obj.maze.sizey/4),'FINISH', 'FontSize', 36);
            end
            
    end
    end
end