function [] = connect4(figureNumber)

	% Miles Miller 2016
	%
	% Optional input is the figure number


	scale = 500; % set initial scale. Used for resizing of the window

	%define shared variables for nested function access
	% figure vars
	f=[];
	ax=[];
	% game vars
	player=[];
	grid=[];
	moves=[];
	win=[];
	laststart=[];
	% UI Controls
	starter = [];
	turn = [];
	score1 =[];
	score_1 = [];

	if(nargin==0) % checks if a figure number was provided
		figureNumber = 1;
	end
	figureSetup(figureNumber); % setup the window, axes, and buttons
	gameSetup(); % equivalent to "start a new game"



	function [] = figureSetup(fignum)
		% This function sets up the window used to play the game. It
		% creates the figure, axes, and other UI elements. 'fignum' is the
		% figure number used for the game

		s = get(0,'ScreenSize'); % used to center the initial window

		% Create Figure
		f = figure(fignum);
		f.SizeChangedFcn = ' ';
		clf
		f.MenuBar = 'none';
		f.Name = 'Connect Four';
		f.NumberTitle = 'off';
		f.Position = [(s(3)-651)/2 (s(4)-500)/2, 651 500];
		f.WindowButtonUpFcn = @mouseClick;
		f.SizeChangedFcn = @rescale;
		f.Resize = 'on';

		% Create Axes
		% The axes contains the actual board. It's easiest to "draw" on
		ax = axes('Parent',f);
		ax.Units = 'pixels';
		ax.Position = [1 500/14, 500 500*6/7];
		ax.XTick = [];
		ax.YTick = [];
		ax.YDir='reverse';
		ax.Box = 'off';


		% Create Buttons/UI
		% The ones needed in other functions are stored in variables. The
		% first line of each has a commented label. The '...' tells Matlab
		% that the code continues onto the next line. It's just for
		% formatting
		uicontrol(f,'Style','pushbutton',... % newgame button
			'Position',[506 350, 141 50],...
			'String','New Game',...
			'FontSize',14,...
			'Callback',@gameSetup);
		uicontrol(f,'Style','pushbutton',... % undo button
			'Position',[506 275, 141 50],...
			'String','Undo',...
			'FontSize',14,...
			'Callback',@undoMove);				
		score1 = uicontrol(f,'Style','text',... % scoreboard red
			'Position',[526 425, 40, 30],...
			'String','0',...
			'FontSize',17,...
			'BackgroundColor',0.85*ones(1,3),...
			'ForegroundColor',[1 0 0]);
		score_1 = uicontrol(f,'Style','text',...% scoreboard black
			'Position',[586 425, 40, 30],...
			'String','0',...
			'FontSize',17,...
			'BackgroundColor',0.85*ones(1,3));
		uicontrol(f,'Style','text',... % text above starter selection
			'Position',[511 101, 131 50],...
			'String','Who Starts:',...
			'FontSize',14);
		starter = uicontrol(f,'Style','popupmenu',... % starter selection
			'Position',[526 100, 101, 25],...
			'String',{'Alternate','Random','Winner','Loser'},...
			'FontSize',12);
		turn = uicontrol(f,'Style','text',... % turn indicator
			'Position',[551 200, 50 50],...
			'BackgroundColor',[0 0 0]);		
	end

	function [] = gameSetup(~,~)
		% Draw board
		cla
		patch([0.5 0.5 7.5 7.5], [0.5 6.5 6.5 0.5],[255 241 66]/255); % yellow background %255, 241, 66
		hold on
		[x,y] = meshgrid(1:7,1:6);
		x = reshape(x,[1,42]);
		y = reshape(y,[1,42]);
		plot(x,y,'o','MarkerFaceColor',[1 1 1],'MarkerEdgeColor','none','MarkerSize',40*scale/500,'Tag','Board') % adds the white circles
		axis equal

		% Initialize Game variables
		grid = zeros(6,7); % matrix representing the board. (1,1) is the top left of the board. "0=empty", "1=red", "-1=black"
		moves = []; % array that stores the column of each move
		win = false; % boolean of whether or not someone has won yet

		% Determine starting player
		v = starter.Value;
		% v==1 Alternate
		% v==2 Random
		% v==3 Winner, not actually needed. 'player' already has correct value
		% v==4 Loser
		if( v==2 )
			player = randi(2)*2-3;
		elseif( v==1 ) 
			if( isempty(laststart) )
				player = 1;
			else
				player = -laststart;						
			end
		elseif( v==4 )
			player = -player;
		end %if v==3, player=player;
		laststart = player; % Store who started incase 'Alternate' is used

		% Change turn indicator color to match
		turn.BackgroundColor = [sign(player+1) 0 0];

	end

	function [] = rescale(~,~)
		% Get new height and width of the figure
		h = f.Position(4); 
		w = f.Position(3);
		if(h/w<500/651) % determine if limited by height or width (check aspect ratio)
			s = h;
		else
			s = w*500/651;
		end

		edge = [f.Position(3) 0, f.Position(4) 0]; % array to be filled with bounds of things actually in the figure. [left, right, bottom, top]
		c = f.Children;
		for i=1:length(c)
			c(i).Position = c(i).Position*s/scale; % change size of all UI elements
			if( isa(c(i),'matlab.ui.control.UIControl') )
				c(i).FontSize = c(i).FontSize*s/scale; % change font size of text
			end

			% check if current Child makers any edge
			if(edge(1) > c(i).Position(1) ) 
				edge(1) = c(i).Position(1);
			end
			if(edge(2) < c(i).Position(1)+c(i).Position(3) ) 
				edge(2) = c(i).Position(1)+c(i).Position(3);
			end
			if(edge(3) > c(i).Position(2) ) 
				edge(3) = c(i).Position(2);
			end
			if(edge(4) < c(i).Position(2)+c(i).Position(4) ) 
				edge(4) = c(i).Position(2)+c(i).Position(4);
			end
		end

		% Centering UI within the figure
		leftOffset = (f.Position(3)-diff(edge(1:2)))/2 - edge(1);
		bottomOffset = (f.Position(4)-diff(edge(3:4)))/2 - edge(3);
		for i=1:length(c)
			c(i).Position(1) = c(i).Position(1) + leftOffset;
			c(i).Position(2) = c(i).Position(2) + bottomOffset;
		end

		% Change size of elements in the board
		c = ax.Children;
		for i=1:length(c)
			c(i).LineWidth = c(i).LineWidth*s/scale; % changes width of indicator lines
			c(i).MarkerSize = c(i).MarkerSize*s/scale; % changes circle size
		end


		scale = s; % store current height. Used for resizing and new elements
	end

	function [] = mouseClick(~,~)
		% This funciton is called anytime you click within the bounds of
		% the figure
		if(length(moves)==42 || win)
			return % do nothing if game is already over
		end

		a = 0:scale/7:scale; % this is the x-coords that separate the columns
		m = f.CurrentPoint; % gets mouse coordinates relative to figure
		m = m(1) - ax.Position(1); % readjust to axis position, delete y-coord

		x = find(m>a,1,'last'); % find which column it is within
		if( m<a(end) ) % check that it is actually within axes/the board

			y = find(grid(:,x)==0,1,'last'); % find the row where the piece lands
			if(isempty(y))
				return % do nothing if full column
			end

			moves(end+1) = x; %store column
			grid(y,x) = player; %fill matrix with move
			plot(x,y,'o','MarkerEdgeColor','none','MarkerSize',40*scale/500','MarkerFaceColor',[1*sign(player+1) 0 0]) % put piece on the board

			win = wincheck(y,x); % check for a win
			if(~win) % continue game
				% Change player and turn indicator
				player = -player;
				turn.BackgroundColor = [1*sign(player+1) 0 0];
			else
				% Update Scoreboard
				if(player==1)
					score1.String = num2str(1+str2num(score1.String));
				else
					score_1.String = num2str(1+str2num(score_1.String));
				end

				drawlines(y,x);
			end

		end
	end

	function [] = undoMove(~,~)
		% Takes back the last move
		if(~win && ~isempty(moves)) % only do it if no winner and there is actually a move to take back
			% Get position of piece
			x = moves(end);
			y = find(grid(:,x)~=0,1);

			% Remove from history
			grid(y,x) = 0;
			moves = moves(1:end-1);
			player = -player;
			turn.BackgroundColor = [1*sign(player+1) 0 0];

			% Find and delete piece from the board
			c = ax.Children;
			for i=1:length(c)
				if(isa(c(i),'matlab.graphics.chart.primitive.Line') && length(c(i).XData)==1 && c(i).XData==x && c(i).YData==y)
					delete(c(i));
					break
				end
			end


		end
	end

	function [winner] = wincheck(r,c)
		% Checks if the piece in row 'r' and column 'c' is a winning move
		p = grid(r,c); % get who played it
		winner = true; %assume true. 'return' will end the fcn and report that there is a winner

		if(r < 4 && sum(grid(r:r+3,c)) == 4*p) %check down
			return
		end
		% no need to check upwards, can't happen in connect 4

		x = c; %check left-right, 0 degrees
		while( x<8 && grid(r,x)==p) % move to one end of the line
			x=x+1;
		end
		x=x-1;
		count = 0;
		while( x>0 && grid(r,x)==p) % move to the other end and count
			x=x-1;
			count = count+1;
		end
		if(count >= 4)
			return
		end

		x = c; %check up-right/ 45 degrees
		y = r;
		while( x<8 && y>0 && grid(y,x)==p)% move to one end of the line
			x=x+1;
			y=y-1;
		end
		x=x-1;
		y=y+1;
		count = 0;
		while( x>0 && y<7 && grid(y,x)==p)% move to the other end and count
			x=x-1;
			y=y+1;
			count = count+1;
		end
		if(count >= 4)
			return
		end

		x = c; %check down-right/ -45 degrees
		y = r;
		while( x>0 && y>0 && grid(y,x)==p)% move to one end of the line
			x=x-1;
			y=y-1;
		end
		x=x+1;
		y=y+1;
		count = 0;
		while( x<8 && y<7 && grid(y,x)==p)% move to the other end and count
			x=x+1;
			y=y+1;
			count = count+1;
		end
		if(count >= 4)
			return
		end

		winner = false; % only reached if no win. Fcn ends and reports no winner
	end

	function [] = drawlines(r,c)
		% Draws the lines to show where someone wins. Code is almost
		% identical to wincheck(). 
		p = grid(r,c);
		if(r < 4 && sum(grid(r:r+3,c)) == 4*p) %check down
			line([c,c],[r, r+3],'LineWidth',7*scale/500);
		end

		x = c; %check left-right, 0 degrees
		while( x<8 && grid(r,x)==p)
			x=x+1;
		count = 0;
		end
		x=x-1;
		x2=x;
		while( x>0 && grid(r,x)==p)
			x=x-1;
			count = count+1;
		end
		if(count >= 4)
			line([x2 x+1], [r r],'LineWidth',7*scale/500);
		end

		x = c; %check up right/ 45 degrees
		y = r;
		while( x<8 && y>0 && grid(y,x)==p)
			x=x+1;
			y=y-1;
		end
		x=x-1;
		y=y+1;
		x2=x;
		y2=y;
		count = 0;
		while( x>0 && y<7 && grid(y,x)==p)
			x=x-1;
			y=y+1;
			count = count+1;
		end
		if(count >= 4)
			line([x2 x+1],[y2 y-1],'LineWidth',7*scale/500);
		end
	% 	
		x = c; %check down right/ -45 degrees
		y = r;
		while( x>0 && y>0 && grid(y,x)==p)
			x=x-1;
			y=y-1;
		end
		x=x+1;
		y=y+1;
		x2 = x;
		y2=y;
		count = 0;
		while( x<8 && y<7 && grid(y,x)==p)
			x=x+1;
			y=y+1;
			count = count+1;
		end
		if(count >= 4)
			line([x2 x-1],[y2 y-1],'LineWidth',7*scale/500);
		end
	end

end





















