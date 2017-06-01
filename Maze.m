classdef Maze < handle
    % Load maze-file and solves maze problem
    properties
        map;
        
        height;
        width;
        
        origin;
        final;
        portal;
        paths;
    end
    
    properties(Constant = true, Access = protected)
       NEW_LINE = newline;
       WALL = 0;
       ROAD = 1;
       PORTAL = 2;
       FINAL = 8;
       ORIGIN = 9;
    end
    
    methods
        function p = get_paths(obj)
            if isempty(obj.paths)
                obj.paths = Maze.compute_paths(obj);
            end
            p = obj.paths;
        end
        
        function p = get_shortest_paths(obj)
            if isempty(obj.paths)
                obj.paths = Maze.compute_paths(obj);
            end
            p = obj.paths(1);
            for i=2:length(obj.paths)
                if obj.paths(i).length ~= p(1).length
                    break, end
                p = [p obj.paths(i)];
            end
        end
        
        function obj = Maze(filename)
            file = fopen(filename);
            map = fread(file);
            
            % if the last line doesn't end with newline
            if map(end) ~= Maze.NEW_LINE
                map = [map; Maze.NEW_LINE];
            end
            
            % reshape to one-row-per-line   
            width = find(map == Maze.NEW_LINE, 1); %length of line
            if ismac
                % for Mac plaform
                map = reshape(map, width, [])' - '0';
                map = map(:,1:end-1); %remove newline from map
            elseif ispc
                % for windows plaform
                map = [map; Maze.NEW_LINE]; %add a number for reshape
                map = reshape(map, width, [])' - '0';
                map = map(:,1:end-2); %remove newline from map
            else
                disp('Platform not supported')
            end
            
            [height, width] = size(map);
            
            [originrow, origincol] = find(map == Maze.ORIGIN);
            [finalrow,finalcol] = find(map == Maze.FINAL);
            [portalrow, portalcol] = find(map == Maze.PORTAL);
            
            obj.map = map;
            obj.height = height;
            obj.width = width;
            obj.origin = [originrow; origincol];
            obj.final = [finalrow; finalcol];
            obj.portal = [portalrow portalcol]';
            fclose(file);
        end
    end
    
    methods(Access = protected,Static = true)
        function paths=compute_paths(obj)
            %compute all the paths of maze
            paths = [];
            paths_queue = Queue();
            paths_queue.push(Path(obj.origin));
            while(~paths_queue.is_empty())
                path = paths_queue.pop();
                adjacent_cells = [];
                if(~isempty(obj.portal) && Path.equals(path.last(), obj.portal(:,1)))
                   if(~Path.equals(path.prelast(), obj.portal(:,2)))
                     % adjacent_cells = obj.portal(:,2);
                     % paths_queue.push(path.clone().add_not_count(obj.portal(:,2)))
                     paths_queue.putback(path.clone().add_not_count(obj.portal(:,2)))
                     continue
                   end
                elseif(~isempty(obj.portal) && Path.equals(path.last(), obj.portal(:,2)))
                   if(~Path.equals(path.prelast(), obj.portal(:,1)))
                       %adjacent_cells = obj.portal(:,1);
                       %paths_queue.push(path.clone().add_not_count(obj.portal(:,1)))
                       paths_queue.putback(path.clone().add_not_count(obj.portal(:,1)))
                       continue
                   end
                end
                
                %if isempty(adjacent_cells)
                   adjacent_cells = Maze.find_adjacent(obj,path.last());
                %end
                
                %adjacent_cells = Maze.find_adjacent(obj,path.last());
                for c = adjacent_cells(:,:)
                    if( Path.equals(c, obj.final))
                        paths = [paths; path.clone().add(c)];
                    elseif( ~path.is_cycle(c))
                        paths_queue.push(path.clone().add(c));
                    end
                end
            end
        end
        
        function adjacent = find_adjacent(obj, position)
            %find adjacent node of position
            adjacent = [];
            
            if(position(1)-1 > 0 && obj.map(position(1)-1,position(2)) ~= Maze.WALL) % top
                pos = [position(1)-1; position(2)];
                adjacent = [adjacent pos];
            end
            if(position(1)+1 <= obj.height && obj.map(position(1)+1, position(2)) ~= Maze.WALL) %down
                pos = [position(1)+1; position(2)];
                adjacent = [adjacent pos];
            end
            if(position(2)-1 > 0 && obj.map(position(1),position(2)-1) ~= Maze.WALL) %left
                pos = [position(1); position(2)-1];
                adjacent = [adjacent pos];
            end
            if(position(2)+1 <= obj.width && obj.map(position(1),position(2)+1) ~= Maze.WALL) %right
                pos = [position(1); position(2)+1];
                adjacent = [adjacent pos];
            end
            
        end
    end
end